---
id: "0011"
title: KServe LLMInferenceService and llm-d integration architecture
status: active
created: 2026-05-19
affects:
  - kserve
  - odh-model-controller
  - llm-d-inference-scheduler
  - llm-d-router
  - llm-d-kv-cache
release:
  - "3.5"
  - "next"
provenance:
  - https://github.com/kserve/kserve/tree/master/pkg/apis/serving/v1alpha2
  - https://github.com/kserve/kserve/tree/master/pkg/controller/v1alpha2/llmisvc
  - https://github.com/llm-d/llm-d
  - https://github.com/opendatahub-io/odh-model-controller/tree/main/internal/controller/serving/llm
author: Pierangelo Di Pilato
superseded_by: null
---

## Fact

KServe v1alpha2 introduces **LLMInferenceService** (`serving.kserve.io/v1alpha2`, short name `llmisvc`), a purpose-built
CRD for LLM deployments that deeply integrates the **llm-d** distributed inference stack. Unlike the general-purpose
InferenceService (v1beta1), LLMInferenceService is designed exclusively for LLM workloads and natively manages the llm-d
router (EPP), disaggregated prefill/decode topology, multi-node LeaderWorkerSet deployments, and LLM-specific
autoscaling via the Workload Variant Autoscaler (WVA).

llm-d is a CNCF Sandbox project (founded by Red Hat, Google Cloud, IBM Research, CoreWeave, NVIDIA) providing
state-of-the-art distributed LLM inference serving on Kubernetes. Its core Go components live in separate repositories:
`llm-d-inference-scheduler` (EPP), `llm-d-kv-cache` (KV indexer/offloader), `llm-d-workload-variant-autoscaler` (WVA),
`llm-d-routing-sidecar` (P/D coordination), `llm-d-latency-predictor`, `llm-d-async`, and `batch-gateway`.

### CRD and API Surface

**LLMInferenceService** (`llminferenceservices.serving.kserve.io`) orchestrates creation of Deployments, Services,
LeaderWorkerSets, HTTPRoutes, InferencePools, ServiceAccounts, Roles, and autoscaling resources from a single CR. Key
spec fields:

| Field                            | Type                     | Purpose                                                 |
|----------------------------------|--------------------------|---------------------------------------------------------|
| `spec.model`                     | `LLMModelSpec`           | Model URI (`hf://`, `s3://`), name, LoRA adapter list   |
| `spec.template`                  | `PodSpec`                | Primary workload pod (decode in P/D mode)               |
| `spec.worker`                    | `PodSpec`                | Worker pods for multi-node (triggers LeaderWorkerSet)   |
| `spec.prefill`                   | `WorkloadSpec`           | Separate prefill workload (triggers disaggregated mode) |
| `spec.parallelism`               | `ParallelismSpec`        | Tensor, pipeline, data, expert parallelism settings     |
| `spec.replicas` / `spec.scaling` | mutually exclusive       | Static replicas vs. WVA autoscaling                     |
| `spec.router`                    | `RouterSpec`             | Networking: Gateway API, Ingress, and scheduler/EPP     |
| `spec.baseRefs`                  | `[]LocalObjectReference` | Config inheritance from LLMInferenceServiceConfig CRs   |

**LLMInferenceServiceConfig** (`llminferenceserviceconfigs.serving.kserve.io`) is a companion CRD acting as a reusable
configuration template. Multiple LLMInferenceService instances can reference configs via `spec.baseRefs`; the last
config in the list wins on conflicts, and inline spec fields always take highest precedence.

### Deployment Topologies

The controller supports three deployment topologies, selected implicitly by which spec fields are populated:

| Topology              | Trigger                         | Kubernetes Resources Created                                                                                                                                 |
|-----------------------|---------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Single-node**       | `spec.template` only            | Deployment + Service                                                                                                                                         |
| **Multi-node**        | `spec.template` + `spec.worker` | LeaderWorkerSet (head + workers) + Service                                                                                                                   |
| **Disaggregated P/D** | `spec.prefill` present          | Separate Deployment/LWS for prefill and decode, each independently scalable; decode pods include `llm-d-routing-sidecar` init container for P/D coordination |

In disaggregated mode, prefill and decode can each be single-node or multi-node independently.

### EPP / Scheduler Integration

When `spec.router.scheduler` is configured, the controller creates a complete llm-d EPP stack:

| Resource                 | Name Pattern                     | Purpose                                                                                 |
|--------------------------|----------------------------------|-----------------------------------------------------------------------------------------|
| Deployment               | `<name>-kserve-router-scheduler` | EPP pod (`llm-d-inference-scheduler` + optional tokenizer sidecar)                      |
| Service                  | EPP service name                 | gRPC (9002), health (9003), metrics (9090), ZMQ (5557)                                  |
| ServiceAccount           | `<name>-epp-sa`                  | EPP identity with credential propagation from main workload SA                          |
| Role                     | `<name>-epp-role`                | Read pods, InferencePools, InferenceObjectives, InferenceModels, EndpointSlices, Leases |
| RoleBinding              | `<name>-epp-rb`                  | Binds role to EPP SA                                                                    |
| ClusterRoleBinding       | `<ns>-<name>-epp-auth-rb`        | `system:auth-delegator` for `/metrics` auth                                             |
| InferencePool (v1)       | `<name>-inference-pool`          | `inference.networking.k8s.io/v1` pool targeting workload pods                           |
| InferencePool (v1alpha2) | `<name>-inference-pool`          | `inference.networking.x-k8s.io/v1alpha2` pool (coexists with v1)                        |

The EPP deployment uses `Recreate` strategy (not rolling update) because the EPP is stateful (prefix cache scorer
state). For HA (`replicas > 1`), leader election is auto-enabled via `--ha-enable-leader-election`.

Default scheduler configurations are managed in **KServe** — the KServe LLMInferenceService controller owns both the
default `EndpointPickerConfig` generation and the scheduler Deployment template (`config-llm-scheduler` preset). When no
explicit config is provided, the controller generates a default `EndpointPickerConfig` based on topology:

- **Standard**: `single-profile-handler` + `queue-scorer` (weight 2) + `prefix-cache-scorer` (weight 3) +
  `max-score-picker`
- **Disaggregated**: `disagg-headers-handler` + `prefill-filter`/`decode-filter` + `queue-scorer` +
  `prefix-cache-scorer` + `always-disagg-pd-decider` + `disagg-profile-handler`, with separate `prefill` and `decode`
  scheduling profiles

Custom configs can be provided inline (`spec.router.scheduler.config.inline`) or via ConfigMap reference (
`spec.router.scheduler.config.ref`).

#### Config Preservation Across Upgrades

The controller uses a 4-level priority hierarchy (`preserveSchedulerConfig()`) to decide which EndpointPickerConfig
the scheduler deployment receives. This ensures user-customized configs survive controller upgrades without manual
intervention:

| Priority    | Source                                | Behavior                                                                                          |
|-------------|---------------------------------------|---------------------------------------------------------------------------------------------------|
| 1 (highest) | `spec.router.scheduler.config.inline` | Always wins — overwrites whatever is on the cluster                                               |
| 2           | Template container args               | If the preset template already carries `--config-text`, returns nil (no-op, avoids duplication)   |
| 3           | Current deployment on cluster         | Reads `--config-text` from the *running* deployment's containers and carries it forward unchanged |
| 4 (lowest)  | Fresh default generation              | `schedulerConfigText()` generates a topology-appropriate default only if nothing else exists      |

Priority 3 is the upgrade-preservation mechanism: on each reconcile, the controller reads the existing scheduler
Deployment before deciding to generate a new config. A user who customized their config (or received migrations from
a previous upgrade) keeps that config intact unless they explicitly override it via inline spec.

#### Version Migrations

Migrations are applied as transforms on top of whichever config source was selected, in two stages:

**Unconditional migrations** (applied regardless of scheduler version):

| Migration                               | What it does                                                                                                |
|-----------------------------------------|-------------------------------------------------------------------------------------------------------------|
| `WithUdsTokenizerConfig`                | Injects UDS tokenizer socket path and model name into `precise-prefix-cache-scorer` plugin                  |
| `WithMigrateTokenProcessorConfig`       | Hoists `tokenProcessorConfig` from nested `indexerConfig` to top-level `parameters` (v0.6 schema fix)       |
| `WithMigrateBlockSizeToBlockSizeTokens` | Renames deprecated `blockSize` (character count) → `blockSizeTokens` (token count) in `prefix-cache-scorer` |

**Version-gated migrations** (only when scheduler image >= 0.7.0 — prevents v0.6 binaries from receiving config
they would reject):

| Migration                         | What it does                                                                                                                                                          |
|-----------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `extractDeprecatedMetricFlags`    | Strips 5 metric CLI flags hard-rejected by GIE v1.4.0 and saves values for re-injection into config YAML                                                              |
| `withMigrateDisaggHeadersHandler` | Plugin rename: `prefill-header-handler` → `disagg-headers-handler` (including `schedulingProfiles` references)                                                        |
| `withMigrateDisaggProfileHandler` | Renames `pd-profile-handler` → `disagg-profile-handler`, migrates `deciderPluginName` → `deciders` map; skips if non-zero `threshold` is present (no v0.7 equivalent) |
| `WithRemoveHashBlockSize`         | Removes deprecated `hashBlockSize` field from all plugins                                                                                                             |
| `withCoreMetricsExtractorPlugin`  | Injects `core-metrics-extractor` plugin with parameters extracted from the removed CLI flags                                                                          |

All migrations are idempotent — each checks whether the transformation has already been applied before modifying.
The version gate reads the scheduler container image tag annotation to determine the running version.

### Request Flow

```
Client -> Gateway (Envoy) -> ext-proc -> EPP (scores pods) -> Envoy forwards to selected pod -> vLLM -> Response
```

In disaggregated mode:

```
Client -> Gateway -> EPP -> Decode Pod -> llm-d-routing-sidecar -> Prefill Pod (prompt processing)
                                       -> KV transfer (NIXL + RDMA) -> Decode Pod (token generation) -> Response
```

The EPP evaluates pods using a plugin pipeline. Key scoring signals:

- Queue depth and running request count per pod
- KV-cache utilization percentage
- Prefix cache hit ratio (heuristic or precise via KV indexer)
- Predicted latency (TTFT/ITL) from XGBoost latency predictor sidecar (optional)

### Autoscaling

When `spec.scaling` is configured (mutually exclusive with `spec.replicas`), the controller creates:

| Resource                                     | Purpose                                           |
|----------------------------------------------|---------------------------------------------------|
| `VariantAutoscaling` CR (`llmd.ai/v1alpha1`) | WVA input: variant cost, min/max replicas         |
| `ServiceMonitor`                             | Prometheus scrape target for WVA metrics          |
| HPA or KEDA `ScaledObject`                   | Actuator that reads `wva_desired_replicas` metric |

Two actuator backends are supported:

- **HPA**: reads `wva_desired_replicas` via Kubernetes external metrics API; requires Prometheus Adapter
- **KEDA**: queries Prometheus directly via ScaledObject; no adapter needed; supports idle scale-down (
  `idleReplicaCount`), cooldown periods, and fallback replica counts

In disaggregated mode, prefill and decode have independent scaling configurations, each producing separate autoscaling
resource stacks.

### Networking and Routing

The `spec.router` section supports three mutually exclusive networking modes:

| Mode               | Resources                     | Notes                                                             |
|--------------------|-------------------------------|-------------------------------------------------------------------|
| **Gateway API**    | HTTPRoute + Gateway reference | Model-based routing via header matching; supports shared gateways |
| **Ingress**        | Kubernetes Ingress            | Bring-your-own or controller-managed                              |
| **Scheduler only** | InferencePool + EPP           | No external exposure, cluster-internal scheduling                 |

For Gateway API, the controller creates HTTPRoutes with rules matching `/v1/completions`, `/v1/chat/completions`, and
`/v1/responses` paths. When multiple LLMInferenceService instances share a Gateway, model-based routing uses a
configurable HTTP header (`x-model-id` by default) to dispatch requests to the correct InferencePool.

### Status and Condition Hierarchy

| Top-level         | Sub-conditions                                                                                   |
|-------------------|--------------------------------------------------------------------------------------------------|
| `Ready`           | Aggregates `WorkloadsReady` + `RouterReady`                                                      |
| `WorkloadsReady`  | `MainWorkloadReady`, `WorkerWorkloadReady`, `PrefillWorkloadReady`, `PrefillWorkerWorkloadReady` |
| `RouterReady`     | `SchedulerWorkloadReady`, `GatewaysReady`, `HTTPRoutesReady`, `InferencePoolReady`               |
| `PresetsCombined` | Configuration merge from baseRefs succeeded                                                      |

`status.url` is set to external address when available, falling back to cluster-local. `status.router` records observed
gateway topology and scheduler references.

### llm-d Advanced Capabilities (available via EPP config)

| Capability                 | Component                                             | Description                                                    |
|----------------------------|-------------------------------------------------------|----------------------------------------------------------------|
| Prefix-cache aware routing | EPP plugin `prefix-cache-scorer`                      | Heuristic routing to pods with cached prefixes                 |
| Precise prefix cache       | EPP plugin `precise-prefix-cache-scorer` + KV indexer | Event-driven KV state tracking; tokenizer sidecar required     |
| KV offloading              | `llm-d-kv-cache`                                      | Tiered storage: GPU HBM -> CPU RAM -> SSD                      |
| Predicted latency routing  | `llm-d-latency-predictor` sidecar                     | XGBoost model predicts ITL/TTFT per pod                        |
| Flow control               | EPP config `flowControl` section                      | Centralized request queuing, priority bands, fairness policies |
| Batch inference            | `batch-gateway` + `llm-d-async`                       | OpenAI-compatible `/v1/batches` API, async queue processing    |

### Container Images (current versions)

| Image                                     | Version | Role                           |
|-------------------------------------------|---------|--------------------------------|
| `ghcr.io/llm-d/llm-d-cuda`                | v0.6.0  | vLLM inference runtime (CUDA)  |
| `ghcr.io/llm-d/llm-d-inference-scheduler` | v0.7.1  | EPP scheduler                  |
| `ghcr.io/llm-d/llm-d-uds-tokenizer`       | v0.7.1  | Tokenizer sidecar (UDS socket) |
| `ghcr.io/llm-d/llm-d-routing-sidecar`     | v0.7.1  | P/D routing coordination       |

### LLMInferenceServiceConfig Presets (managed in KServe)

KServe ships 8 `LLMInferenceServiceConfig` CRs in `config/llmisvcconfig/` (deployed via Kustomize into the `kserve`
namespace). These presets define the default container specs, scheduler deployment, and routing configuration — they are
the authoritative source for default llm-d component images, ports, probes, and EPP sidecar composition:

| Template                                  | Purpose                                                 |
|-------------------------------------------|---------------------------------------------------------|
| `config-llm-template`                     | Standard single-node vLLM container                     |
| `config-llm-worker-data-parallel`         | Worker pod for multi-node data-parallel                 |
| `config-llm-prefill-template`             | Prefill container (disaggregated)                       |
| `config-llm-prefill-worker-data-parallel` | Prefill worker for multi-node prefill                   |
| `config-llm-decode-template`              | Decode container with routing sidecar                   |
| `config-llm-decode-worker-data-parallel`  | Decode worker with routing sidecar                      |
| `config-llm-router-route`                 | HTTPRoute template with model-based routing             |
| `config-llm-scheduler`                    | EPP Deployment template (scheduler + tokenizer sidecar) |

Templates use Go templating (`.ObjectMeta.Name`, `.GlobalConfig.*`, `.Spec.*`) and support RoCE networking
auto-detection, TLS cert injection, and multiple accelerator types.

### odh-model-controller: Kuadrant Security Integration for LLMInferenceService

The **odh-model-controller** (`internal/controller/serving/llm/`) extends the KServe LLMInferenceService lifecycle with
RHOAI-specific security and networking concerns via **Kuadrant** (`kuadrant.io`). This is implemented as two controllers
that run alongside the KServe LLMInferenceService controller and manage resources KServe does not own.

#### Two-Controller Architecture

| Controller                        | Primary Resource      | Named                    | Purpose                                                                  |
|-----------------------------------|-----------------------|--------------------------|--------------------------------------------------------------------------|
| **GatewayReconciler**             | `Gateway`             | `gateway-auth-bootstrap` | Creates EnvoyFilter + AuthPolicy on gateways used by LLMInferenceService |
| **LLMInferenceServiceReconciler** | `LLMInferenceService` | `llminferenceservice`    | Creates AuthPolicy on HTTPRoutes for per-service auth control            |

These controllers do not duplicate KServe's work — KServe manages Deployments, Services, InferencePools, and HTTPRoutes;
odh-model-controller manages the Kuadrant security layer on top of the Gateway API resources KServe creates.

#### GatewayReconciler — Gateway-Level Security Bootstrap

The GatewayReconciler watches Gateway resources and creates security resources when a gateway is "in use" by LLM
inference. A gateway is considered in-use if:

1. It is the default inference gateway (`openshift-ai-inference` in `openshift-ingress`, configurable via ConfigMap), OR
2. It is explicitly referenced by any LLMInferenceService (directly or via BaseRef configs), OR
3. It has the annotation `security.opendatahub.io/authorino-tls-bootstrap=true`

Resources created per gateway:

| Resource                                         | Name Pattern          | Condition                                                                        | Purpose                                                                                                                                                                                                                      |
|--------------------------------------------------|-----------------------|----------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **EnvoyFilter** (`networking.istio.io/v1alpha3`) | `<gateway>-authn-ssl` | Gateway in-use AND Authorino TLS enabled                                         | Configures Envoy to use TLS when communicating with Authorino authorization service. Points to `authorino-authorino-authorization.<kuadrant-ns>.svc.cluster.local:50051` using Kubernetes service CA. Priority -1 (highest). |
| **AuthPolicy** (`kuadrant.io/v1`)                | `<gateway>-authn`     | Gateway in-use AND not explicitly unmanaged AND not owned by platform controller | UserDefined auth policy with Kubernetes TokenReview + SubjectAccessReview. Injects `x-gateway-inference-fairness-id` and `x-gateway-inference-objective` response headers for downstream fairness/objective tracking.        |

The AuthPolicy is skipped for gateways with label `opendatahub.io/managed=false` or gateways owned by platform
controllers (e.g., GatewayConfig). The objective CEL expression is customizable via the
`inference.opendatahub.io/objective-expression` annotation on the gateway; the default extracts the namespace from the
ServiceAccount token or returns `"authenticated"`.

Watch sources that trigger gateway reconciliation:

- LLMInferenceService create/delete or gateway ref changes (including BaseRef changes)
- LLMInferenceServiceConfig gateway ref changes (propagated through services using that config)
- Namespace label changes (affects Selector-based `allowedRoutes` evaluation)
- Gateway annotation/label changes (`authorino-tls-bootstrap`, `opendatahub.io/managed`)

The controller enforces Gateway API namespace isolation: before creating resources, it evaluates each gateway listener's
`allowedRoutes` spec (`Same`, `All`, or `Selector`) against the LLMInferenceService namespace.

#### LLMInferenceServiceReconciler — Per-Service HTTPRoute Auth

The LLMInferenceServiceReconciler watches LLMInferenceService resources and manages AuthPolicy resources on their
HTTPRoutes. It:

1. Fetches the LLMInferenceService and merges specs from BaseRef configs (reuses KServe's `MergeSpecs`)
2. Resolves HTTPRoute names — from explicit `spec.router.route.http.refs` or the generated name `<name>-kserve-route`
3. Creates or deletes an AuthPolicy per HTTPRoute based on the auth annotation:

| Annotation                            | Value              | HTTPRoute AuthPolicy                                  | Effect                                                                                               |
|---------------------------------------|--------------------|-------------------------------------------------------|------------------------------------------------------------------------------------------------------|
| `security.opendatahub.io/enable-auth` | absent or `"true"` | Not created (or deleted if it existed)                | Gateway-level **UserDefined** policy applies — Kubernetes TokenReview + SubjectAccessReview required |
| `security.opendatahub.io/enable-auth` | `"false"`          | Created — **Anonymous** (`authpolicy_anonymous.yaml`) | Overrides gateway policy; unauthenticated access allowed                                             |

The default auth posture is **authenticated** (UserDefined). The gateway-level AuthPolicy requires a valid Kubernetes
token and performs SubjectAccessReview authorization. Only when `enable-auth=false` is explicitly annotated does an
Anonymous AuthPolicy get created on the HTTPRoute, overriding the gateway policy per Kuadrant's policy hierarchy. The
Anonymous AuthPolicy uses `anonymous: {}` authentication and injects `x-gateway-inference-fairness-id` and
`x-gateway-inference-objective` response headers with `"unauthenticated"` overrides.

The HTTPRoute AuthPolicy is owned by the LLMInferenceService (controller reference), so it is garbage-collected when the
service is deleted.

Additional watch triggers for global resync:

- `Kuadrant` (`kuadrant.io/v1beta1`) — any create/update/delete triggers reconciliation of all LLMInferenceService
  instances
- `Authorino` (`operator.authorino.kuadrant.io/v1beta1`) — same global resync behavior

#### Auth Flow Summary

```
Client -> Gateway (Envoy)
  -> EnvoyFilter (TLS to Authorino)
  -> AuthPolicy on Gateway (TokenReview + SubjectAccessReview) OR AuthPolicy on HTTPRoute (Anonymous)
  -> Authorino evaluates policy
  -> Headers injected: x-gateway-inference-fairness-id, x-gateway-inference-objective
  -> ext-proc -> EPP -> Model Server Pod -> Response
```

The two auth modes create a layered policy model:

- **Gateway-level AuthPolicy** (UserDefined): default policy requiring Kubernetes authentication; applies to all
  HTTPRoutes on the gateway unless overridden
- **HTTPRoute-level AuthPolicy** (Anonymous): opt-in override for individual services that should allow unauthenticated
  access; takes precedence over gateway policy per Kuadrant's policy hierarchy

#### Kuadrant Infrastructure Discovery

The controller discovers Kuadrant infrastructure dynamically:

- **Kuadrant namespace**: `KUADRANT_NAMESPACE` env var (default `kuadrant-system`), validated by listing Kuadrant CRs
- **Authorino TLS**: checks `Spec.Listener.Tls.Enabled` on the Authorino CR in the Kuadrant namespace; defaults to
  `true` (safe) if the CR cannot be read
- **Auth audiences**: reads from OpenShift `authentication.config.openshift.io` (audience list from cluster auth
  config), falls back to `https://kubernetes.default.svc`

### odh-model-controller: Gateway Discovery Server

The odh-model-controller ships a standalone HTTPS server (`server/`) that exposes a REST API for discovering which
Gateway API gateways are available to an LLMInferenceService in a given namespace. This server is consumed by the
RHOAI dashboard UI to populate gateway selection dropdowns when users create or edit LLMInferenceService resources.

#### API

**`GET /api/v1/gateways?namespace={namespace}`**

| Header          | Value                | Required |
|-----------------|----------------------|----------|
| `Authorization` | `Bearer {userToken}` | Yes      |

| Query Parameter | Validation         | Required |
|-----------------|--------------------|----------|
| `namespace`     | RFC 1123 DNS label | Yes      |

Response (200):

```json
{
  "gateways": [
    {
      "name": "gateway-name",
      "namespace": "gateway-namespace",
      "listener": "listener-name",
      "status": "Ready|NotReady|Unknown",
      "displayName": "From openshift.io/display-name annotation",
      "description": "From openshift.io/description annotation"
    }
  ]
}
```

Error responses: 400 (missing/invalid namespace, wrong method), 401 (missing token), 500 (discovery failure).
Unauthorized users receive 200 with an empty `gateways` array — not 403 — to avoid leaking namespace existence.

#### Discovery Flow

The discovery follows a three-step process using a dual-client architecture:

1. **RBAC check** (per-request user client): creates a `SelfSubjectAccessReview` to verify the caller can `create
   llminferenceservices` in the target namespace. This is the authorization gate — the server checks LLMInferenceService
   permissions, not Gateway read permissions.
2. **Gateway listing** (ServiceAccount client, cached via controller-runtime): lists all Gateway resources, optionally
   filtered by `GATEWAY_LABEL_SELECTOR`.
3. **Listener filtering**: for each gateway, evaluates the listener's `AllowedRoutes.Namespaces.From` policy against
   the target namespace:
    - `All` — any namespace allowed
    - `Same` (default when nil) — only the gateway's own namespace
    - `Selector` — matches target namespace labels against the selector (requires a namespace label fetch)

Gateway status is derived from conditions: `Ready` when both `Accepted` and `Programmed` are True, `NotReady` when
either is False, `Unknown` otherwise.

### OCP and Istio Platform Integration (`distro` build)

KServe uses Go build tags (`//go:build distro` vs `//go:build !distro`) to compile-time split between upstream and
OpenShift-specific behavior. The upstream build includes no-op stubs; the `distro` build activates OCP and Istio
integrations via four hooks called from the main reconciler:

| Hook                     | Reconciler Method                     | When Called                       | Purpose                                |
|--------------------------|---------------------------------------|-----------------------------------|----------------------------------------|
| Controller setup         | `extendControllerSetup()`             | `SetupWithManager` initialization | Registers Istio scheme + DR watch      |
| Gateway preconditions    | `ensureGatewayPreconditions()`        | Before HTTPRoute creation         | Blocks exposure without AuthPolicy CRD |
| Platform networking      | `reconcileRouterPlatformNetworking()` | After HTTPRoute reconciliation    | Creates Istio DestinationRules         |
| Workload TLS certificate | `createWorkloadCertificate()`         | During TLS cert creation          | Signs certs with OpenShift service-ca  |

#### Istio DestinationRules for TLS Origination

When the LLMInferenceService uses a gateway backed by an Istio-class GatewayClass, the controller creates three
DestinationRules to configure TLS origination from the Istio gateway to backend services. Without these, the gateway
cannot reach workloads and schedulers that serve TLS without injected Istio sidecars.

Istio gateway detection checks the GatewayClass controller name against:
`istio.io/gateway-controller`, `istio.io/unmanaged-gateway`, `openshift.io/gateway-controller/v1`.

| DestinationRule     | Name Pattern                 | Host                                                                                | TLS Mode | CA Verification                                                      | SNI                   |
|---------------------|------------------------------|-------------------------------------------------------------------------------------|----------|----------------------------------------------------------------------|-----------------------|
| **Workload**        | `<name>-kserve-workload-svc` | Workload Service FQDN                                                               | SIMPLE   | service-ca.crt (`ISTIO_CA_CERTIFICATE_PATH`)                         | Workload Service FQDN |
| **Scheduler (EPP)** | `<name>-kserve-scheduler`    | EPP Service FQDN                                                                    | SIMPLE   | InsecureSkipVerify=true (cert reload not yet supported by scheduler) | EPP Service FQDN      |
| **Shadow Service**  | `<name>-kserve-shadow-svc`   | Istio shadow service FQDN (auto-discovered via `istio.io/inferencepool-name` label) | SIMPLE   | InsecureSkipVerify=true (same limitation as scheduler)               | Workload Service FQDN |

The shadow service DestinationRule handles the service Istio automatically creates to back InferencePool resources.
Its SNI is set to the workload service hostname (not the shadow service) because the traffic ultimately reaches the
workload pods. When the shadow service hasn't been created yet by Istio, the DestinationRule reconciliation is skipped
and re-queued.

In **disaggregated prefill/decode mode**, the workload DestinationRule switches to `InsecureSkipVerify=true` (no CA
verification) because the routing sidecar doesn't yet support watching and auto-reloading certificates.

All DestinationRules are labeled with `llm-d.ai/managed=true` and use `ExportTo: ["*"]` for cross-namespace
visibility. They are garbage-collected via owner references when the LLMInferenceService is deleted, and are
automatically deleted when the gateway is not Istio-based or the runtime is force-stopped.

#### Gateway Preconditions — AuthPolicy CRD Check

Before creating any HTTPRoute, the distro build calls `ensureGatewayPreconditions()` to verify the AuthPolicy CRD
(`kuadrant.io/v1`) is available on the cluster. This prevents exposing LLM services without authentication
infrastructure:

- If the AuthPolicy CRD is **not installed** and `IsAuthEnabled()` returns true: the controller **deletes the
  HTTPRoute** and returns `ErrPreconditionNotMet` with the message "please install Red Hat Connectivity Link"
- `ErrPreconditionNotMet` is non-retryable — it sets the status condition but does not trigger infinite requeue
- The check can be disabled via `LLMISVC_AUTH_DISABLED=true` environment variable

This is complementary to the odh-model-controller Kuadrant integration: KServe's precondition check ensures the CRD
exists before creating routes; odh-model-controller then creates the actual AuthPolicy resources on those routes.

#### OpenShift service-ca Certificate Signing

On upstream builds, workload TLS certificates are self-signed. On OCP (`distro` build), the controller signs
certificates using the OpenShift service-ca:

1. Loads the CA certificate and private key from secret `signing-key` in namespace `openshift-service-ca`
   (configurable via `SERVICE_CA_SIGNING_SECRET_NAME` / `SERVICE_CA_SIGNING_SECRET_NAMESPACE`)
2. Generates a 4096-bit RSA key pair for the workload
3. Creates an X.509 certificate signed by the service-ca with:
    - `ExtKeyUsage: ServerAuth`
    - `SignatureAlgorithm: SHA256WithRSA`
    - Subject Alternative Names from workload DNS names and IPs
4. Returns the signed cert, private key, and CA cert (preferring `ca.crt` from the secret if present, falling
   back to `tls.crt`)

The CA key parser supports PKCS8 (RSA, ECDSA, Ed25519) and PKCS1 (RSA-only) formats.

#### Distro-Specific RBAC

The distro build adds RBAC markers for OCP resources the controller manages:

- `networking.istio.io/destinationrules` — get, list, watch, create, update, delete

#### Environment Variable Overrides

| Variable                              | Default                                                        | Purpose                                       |
|---------------------------------------|----------------------------------------------------------------|-----------------------------------------------|
| `LLMISVC_AUTH_DISABLED`               | `false`                                                        | Skip AuthPolicy CRD precondition check        |
| `ISTIO_CA_CERTIFICATE_PATH`           | `/var/run/secrets/kubernetes.io/serviceaccount/service-ca.crt` | CA cert path for workload DestinationRule TLS |
| `SERVICE_CA_SIGNING_SECRET_NAME`      | `signing-key`                                                  | OpenShift service-ca signing secret name      |
| `SERVICE_CA_SIGNING_SECRET_NAMESPACE` | `openshift-service-ca`                                         | Namespace of the service-ca signing secret    |

## Impact on Strategies

- The LLMInferenceService CRD is the primary API for LLM model serving in RHOAI 3.5+. Strategies targeting model serving
  should reference `llmisvc` rather than the general-purpose `InferenceService` for LLM workloads.
- Disaggregated prefill/decode is a first-class deployment topology with independent scaling per phase. Capacity
  planning strategies for large models (70B+) should consider P/D separation with independent GPU allocation.
- The EPP (Endpoint Picker) replaces generic load balancing for LLM pods. Strategies involving model serving performance
  should account for the EPP plugin pipeline (queue scoring, prefix cache affinity, predicted latency) rather than
  assuming round-robin or least-connections.
- Autoscaling uses WVA with HPA or KEDA as actuator, not standard CPU/memory HPA. Strategies involving scale-out should
  specify the actuator backend and note the Prometheus Adapter prerequisite for HPA mode.
- LLMInferenceServiceConfig enables centralized fleet configuration. Platform strategies can define organization-wide
  defaults (hardware presets, scheduler configs, TLS settings) as shared configs referenced by many LLMInferenceService
  instances.
- The controller manages version migrations automatically (v0.6 -> v0.7 plugin renames, metric flag extraction to
  `core-metrics-extractor`, `blockSize` -> `blockSizeTokens`). Upgrade strategies should not require manual EPP config
  changes.
- Gateway API with model-based routing enables multi-model serving on shared infrastructure. Multi-tenancy strategies
  should leverage the `x-model-id` header routing rather than deploying separate gateways per model.
- llm-d components are upstream CNCF projects with independent release cadences. Dependency and vulnerability tracking
  strategies must cover `llm-d-inference-scheduler`, `llm-d-kv-cache`, `llm-d-workload-variant-autoscaler`, and
  `llm-d-routing-sidecar` as separate supply-chain items.
- LLMInferenceService security is a split responsibility: KServe manages workloads and networking resources;
  odh-model-controller manages Kuadrant AuthPolicies and Istio EnvoyFilters. Strategies touching auth, access control,
  or multi-tenancy for LLM serving must account for both controllers.
- The default auth posture for LLMInferenceService is **authenticated** (Kubernetes TokenReview + SubjectAccessReview
  via the gateway-level UserDefined AuthPolicy). Anonymous access is opt-in via the
  `security.opendatahub.io/enable-auth=false` annotation. Security strategies should document this secure-by-default
  model.
- Kuadrant is a hard dependency for LLMInferenceService security on RHOAI. The odh-model-controller discovers Kuadrant
  and Authorino at runtime and triggers global resync when they change. Strategies involving Kuadrant upgrades or
  namespace changes must consider the LLM serving security impact.
- The fairness and objective headers (`x-gateway-inference-fairness-id`, `x-gateway-inference-objective`) injected by
  Kuadrant AuthPolicies are consumed downstream by the EPP for flow control and multi-tenant fairness. Strategies
  involving multi-tenant inference should trace the full path from AuthPolicy header injection through EPP flow control.
- The Gateway Discovery Server (`odh-model-controller/server/`) provides the RHOAI dashboard with RBAC-scoped gateway
  visibility — users only see gateways they can deploy LLMInferenceService to, respecting Gateway API listener namespace
  policies. Strategies involving custom gateways or multi-tenant gateway topologies should ensure gateways are labeled
  and listeners use appropriate `AllowedRoutes` policies for UI discoverability.
- On OCP, KServe creates Istio DestinationRules for TLS origination between the gateway and backend services. The
  scheduler and shadow service DRs use `InsecureSkipVerify=true` because the scheduler doesn't yet support certificate
  auto-reload. Strategies involving TLS hardening or certificate rotation should track upstream fix
  (gateway-api-inference-extension#1765) adoption.
- The `distro` build tag creates a compile-time split between upstream KServe and OCP-specific behavior. Strategies
  involving KServe upstream contributions must ensure OCP-specific code (Istio DRs, service-ca signing,
  AuthPolicy preconditions) remains behind `//go:build distro` and that corresponding no-op `!distro` stubs exist.
- KServe's `ensureGatewayPreconditions()` prevents HTTPRoute creation without the AuthPolicy CRD on OCP — a
  defense-in-depth measure complementing odh-model-controller's AuthPolicy management. Strategies for environments
  without Red Hat Connectivity Link must set `LLMISVC_AUTH_DISABLED=true` or the controller will block route creation.
- Workload TLS on OCP uses OpenShift service-ca signing rather than self-signed certificates. The controller reads the
  CA signing secret from `openshift-service-ca` namespace. Strategies involving namespace restrictions or network
  policies must allow the KServe controller cross-namespace read access to this secret.

## Context

The generated architecture docs describe each component in isolation: KServe's docs cover the v1beta1 InferenceService;
odh-model-controller's docs cover InferenceService-era security reconciliation; llm-d components have their own upstream
docs. None of them capture the cross-component integration — how KServe's LLMInferenceService controller orchestrates
llm-d's EPP, routing sidecar, and WVA; how odh-model-controller layers Kuadrant AuthPolicies and Istio EnvoyFilters on
top of KServe's Gateway API resources; how KServe's distro build creates Istio DestinationRules, and
service-ca-signed certificates on OCP; or how Kuadrant-injected fairness headers flow through the EPP for multi-tenant
flow control. This overlay bridges those gaps, providing the integration context needed for strategies and RFEs that
span LLM inference serving, disaggregated inference, intelligent request routing, Kuadrant-based security, OCP platform
integration, and LLM-specific autoscaling.
