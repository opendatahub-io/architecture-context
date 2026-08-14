---
id: "0023"
title: InferenceService networking patterns -- dual-protocol routing, gRPC readiness, and Model Runtimes template state
status: active
created: 2026-08-09
affects:
  - kserve
  - odh-model-controller
  - openvino_model_server
  - MLServer
  - vllm
release:
  - "3.4"
  - "3.5"
  - "next"
provenance:
  - https://github.com/kserve/kserve/pull/5451
  - https://github.com/kserve/kserve/pull/5342
  - https://github.com/opendatahub-io/kserve/pull/1436
  - https://github.com/opendatahub-io/kserve/pull/1445
  - https://github.com/opendatahub-io/odh-model-controller/blob/main/config/runtimes/
author: Imran Khalidi
superseded_by: null
---

## Fact

Overlay 0011 documents LLMInferenceService networking (Gateway API, HTTPRoute, EPP, Kuadrant auth).
This overlay documents the **InferenceService** (v1beta1) networking architecture -- the predictive /
classical ML deployment path that Model Runtimes team templates use. The two paths share KServe as
the controller but have distinct routing mechanisms, protocol support, and security integration
patterns.

### Dual-Protocol (REST + gRPC) Routing Mechanism

KServe [PR #5451](https://github.com/kserve/kserve/pull/5451) (merged 2026-04-28, released in
upstream v0.19.0, present in ODH fork via upstream sync) adds automatic dual-protocol routing for
Standard (RawDeployment) mode via Gateway API HTTPRoute. The mechanism has three stages:

**Stage 1 -- Service port classification** (`service_reconciler.go`):

`isGrpcPort()` detects gRPC-capable ports by checking whether the container port name contains
`"grpc"` or `"h2c"`. When a gRPC port is detected, `appProtocol` is set to `kubernetes.io/h2c`
on the corresponding Service port, signaling HTTP/2 upstream to the gateway.

```go
// isGrpcPort checks if the port is a grpc port or not by port name
func isGrpcPort(port corev1.ContainerPort) bool {
    if strings.Contains(port.Name, "grpc") || strings.Contains(port.Name, "h2c") {
        return true
    }
    return false
}
```

**Stage 2 -- Protocol port detection** (`httproute_reconciler.go`):

`detectServiceProtocolPorts()` queries the Service to extract REST and gRPC port information. It
reads `appProtocol` on each Service port to classify them. Returns `restPort`, `grpcPort` -- both
are zero if no ports of that type are found.

**Stage 3 -- HTTPRoute rule generation** (`httproute_reconciler.go`):

When both `restPort` and `grpcPort` are non-zero, the reconciler creates a single HTTPRoute with
**two rules**:
1. A gRPC-specific rule with two predicates: path matching
   `^/inference\.GRPCInferenceService/.*$` AND header matching `content-type: ^application/grpc.*`
   (regex), routed to the gRPC backend port -- placed first for specificity
2. A REST fallback rule routed to the REST backend port

When only a REST port is detected (no gRPC containerPort declared), a single-rule HTTPRoute is
created as before -- no behavioral change from pre-PR-5451 behavior.

Source: `pkg/controller/v1beta1/inferenceservice/reconcilers/service/service_reconciler.go`
(`isGrpcPort()`, `servicePort()`);
`pkg/controller/v1beta1/inferenceservice/reconcilers/ingress/httproute_reconciler.go`
(`detectServiceProtocolPorts()`, `createGRPCRouteMatches()`, `createHTTPRouteMatches()`)

### Trigger Condition -- containerPort Declaration

The gRPC containerPort **must** be declared in the ServingRuntime template's
`containers[].ports[]` list with a name containing `"grpc"` or `"h2c"`. If the containerPort is not declared,
KServe's Service reconciler never sees it, `isGrpcPort()` never triggers, `appProtocol` is never
set, and the HTTPRoute reconciler creates a REST-only route -- even if the runtime process is
listening on that port internally.

This is a **template-level enablement** for Standard (RawDeployment) mode, not a controller-level
feature gate. The `RawHTTPRouteReconciler` code is already complete. Enabling gRPC for a runtime
requires only adding the gRPC port declaration to the ServingRuntime template -- zero controller
changes for the Gateway API HTTPRoute path. Note: this mechanism applies only to Standard mode;
Serverless (Knative) mode uses VirtualService reconciliation, a separate code path not modified by
PR #5451.

### Protocol Support Matrix -- Current Template State

| Runtime | REST | gRPC (runtime process) | gRPC containerPort in Template | Externally Routable via gRPC | gRPC Protocol | Notes |
|---------|------|------------------------|-------------------------------|------------------------------|---------------|-------|
| **vLLM** | Yes (port 8080) | **No** | N/A | No | N/A | OpenAI-compatible API only (`/v1/completions`, `/v1/chat/completions`). No KServe v2 gRPC implementation. |
| **OVMS** | Yes (port 8888) | Yes (port 8001) | **Not declared** -- `--port=8001` configured in args but port absent from `containers[].ports[]` | **No** -- KServe cannot discover it | KServe v2 `inference.GRPCInferenceService` | Template declares `protocolVersions: [v2, grpc-v2]` confirming gRPC capability |
| **MLServer** | Yes (port 8080) | Yes (port 8081, default) | **Not declared** | **No** -- KServe cannot discover it | KServe v2 `inference.GRPCInferenceService` | MLServer starts gRPC on 8081 by default (upstream behavior); template declares only `protocolVersions: [v2]` (no `grpc-v2`) and no `MLSERVER_GRPC_PORT` env var |
| **Triton** | Yes (port 8080) | Yes (port 9000) | Declared in test CRD | Yes (Tested & Verified scope only) | KServe v2 `inference.GRPCInferenceService` | Defined inline in test CRD, not in OOTB template |

To enable external gRPC routing for OVMS and MLServer, the only change needed is adding a
containerPort entry with a `"grpc"`-containing name to each template:
- OVMS: `{name: "grpc", containerPort: 8001}`
- MLServer: `{name: "grpc", containerPort: 8081}` (MLServer listens on 8081 by default; add
  `MLSERVER_GRPC_PORT=8081` env var for explicitness, add `grpc-v2` to `protocolVersions`)

Source: `odh-model-controller/config/runtimes/ovms-kserve-template.yaml` (single port 8888);
`odh-model-controller/config/runtimes/mlserver-template.yaml` (single port 8080);
Triton test CRD in `opendatahub-tests/`

### vLLM gRPC -- Different Protocol, Not KServe v2

vLLM's gRPC implementation is architecturally distinct from the KServe v2 gRPC that OVMS and
MLServer implement:

| Aspect | OVMS / MLServer | vLLM |
|--------|-----------------|------|
| Protocol | KServe v2 `inference.GRPCInferenceService` (Predict, Explain, ModelReady) | SMG (Shepherd Model Gateway) `VllmEngine` protocol |
| Port | 8001 / 8081 | 50051 |
| Activation | Built-in, always available | Requires `pip install vllm[grpc]` (optional extra) |
| Streaming | `ModelStreamInfer` RPC (implemented in MLServer; not implemented in OVMS) | Native gRPC streaming via `VllmEngine` |
| KServe routing | Works with `isGrpcPort()` -> dual-protocol HTTPRoute | Would require custom HTTPRoute rules -- different service path (`/vllm.grpc.engine.VllmEngine/*`) from KServe v2 (`/inference.GRPCInferenceService/*`); same `application/grpc` content-type |

vLLM's OpenAI-compatible REST API (`/v1/completions`, `/v1/chat/completions`) with Server-Sent
Events (SSE) for token streaming is the production path for RHOAI. The SMG gRPC protocol is used
internally by components like the Shepherd Model Gateway orchestrator.

Source: [vllm-project/vllm `grpc_server.py`](https://github.com/vllm-project/vllm/blob/main/vllm/entrypoints/grpc_server.py);
[vllm-project/vllm `setup.py` extras_require](https://github.com/vllm-project/vllm/blob/main/setup.py)

### gRPC Streaming Feasibility (KServe v2)

KServe v2 inference protocol defines `ModelStreamInfer` for bidirectional streaming gRPC. Current
runtime implementation status:

| Runtime | `ModelInfer` (request/response) | `ModelStreamInfer` (streaming) |
|---------|---------------------------------|-------------------------------|
| OVMS | Implemented | Not implemented |
| MLServer | Implemented | Implemented (since RHOAI 3.3) |
| Triton | Implemented | Implemented upstream (outside T&V scope) |
| vLLM | N/A (different protocol) | N/A |

For predictive runtimes (OVMS, MLServer), request/response gRPC -- binary tensor payloads, lower
serialization overhead -- is immediately achievable with template-only changes. MLServer already
implements `ModelStreamInfer`, so streaming gRPC is also achievable with template changes alone.
OVMS does not implement `ModelStreamInfer`; streaming gRPC for OVMS would require upstream runtime
contributions.

Source: [KServe v2 inference protocol spec](https://github.com/kserve/kserve/blob/master/docs/predict-api/v2/required_api.md)

### gRPC Security -- CVE-2026-33186 and Auth Coverage

**CVE-2026-33186** (CWE-285) -- gRPC authorization bypass via missing leading slash in HTTP/2
`:path` pseudo-header. Fixed upstream in `google.golang.org/grpc` v1.79.3, integrated into KServe
v0.18.0 ([KServe PR #5342](https://github.com/kserve/kserve/pull/5342)). Present in the ODH fork
via upstream sync PRs
[#1436](https://github.com/opendatahub-io/kserve/pull/1436) (merged 2026-04-23) and
[#1445](https://github.com/opendatahub-io/kserve/pull/1445) (merged 2026-04-30). The fix is
included in RHOAI 3.4+ KServe images. Verify `google.golang.org/grpc` >= v1.79.3 in go.mod
before removing CVE remediation from strategy prerequisites.

**Kuadrant AuthPolicy coverage:** AuthPolicy targets Gateway API resources (HTTPRoute, Gateway,
GRPCRoute) -- it does not target OpenShift Route objects. KServe's dual-protocol approach creates
a single HTTPRoute with protocol-specific rules (gRPC path+content-type match + REST fallback).
A single AuthPolicy on that HTTPRoute covers both REST and gRPC traffic through the Gateway API
path. However, for InferenceService (v1beta1), external exposure is via OpenShift Route (created
by odh-model-controller), which is a separate entrypoint not covered by Kuadrant AuthPolicy.
Authentication on the OpenShift Route path is handled by `enable-auth` annotation and
Authorino-based AuthConfig (odh-model-controller reconciler), not Kuadrant. Strategies enabling
gRPC on InferenceService must verify that both the HTTPRoute path (Kuadrant AuthPolicy) and the
OpenShift Route path (Authorino AuthConfig) enforce auth on gRPC traffic.

Source: [kserve/kserve PR #5342](https://github.com/kserve/kserve/pull/5342);
[opendatahub-io/kserve PR #1436](https://github.com/opendatahub-io/kserve/pull/1436);
[opendatahub-io/kserve PR #1445](https://github.com/opendatahub-io/kserve/pull/1445)

### InferenceService vs LLMInferenceService Networking Comparison

| Aspect | InferenceService (this overlay) | LLMInferenceService ([overlay 0011](0011-kserve-llm-d-architecture.md)) |
|--------|--------------------------------|-------------------------------------------------------------------------|
| Route creator | ODH Model Controller (OpenShift Route) + KServe (HTTPRoute) | KServe (HTTPRoute + InferencePool) |
| Protocol routing | Dual-protocol via path regex (`^/inference\.GRPCInferenceService/.*$`) + content-type header match (`^application/grpc.*`) for gRPC; REST fallback rule | Single-protocol (REST) -- EPP handles routing, not content-type |
| Auth mechanism | Kuadrant AuthPolicy on HTTPRoute + Authorino AuthConfig on OpenShift Route (via `enable-auth` annotation, reconciled by odh-model-controller) | Kuadrant AuthPolicy on HTTPRoute + gateway-level UserDefined policy |
| Timeout control | `haproxy.router.openshift.io/timeout` annotation on OpenShift Route (30s default, see [overlay 0014](0014-model-runtimes-team-architecture.md)) | Gateway-level timeout configuration |
| Load balancing | Kubernetes Service (round-robin) | EPP plugin pipeline (queue scoring, prefix cache, predicted latency) |
| External exposure | OpenShift Route (via ODH-MC) | Gateway API HTTPRoute (via KServe) |

## Impact on Strategies

- The KServe controller already supports dual-protocol (REST + gRPC) routing for InferenceService
  in Standard (RawDeployment) mode via Gateway API HTTPRoute. Strategies proposing gRPC support for
  predictive runtimes should scope the work as **template-only changes** (adding containerPort
  declarations), not KServe controller development. Note: this applies to the HTTPRoute path only;
  Serverless (Knative) VirtualService routing is a separate code path.
- OVMS and MLServer natively support KServe v2 gRPC but their OOTB templates do not declare the
  gRPC containerPort. This is the sole reason gRPC is not externally routable today -- the runtime
  capability exists, the controller capability exists, only the template declaration is missing.
- vLLM uses a completely different gRPC protocol (SMG `VllmEngine`) from the KServe v2
  `inference.GRPCInferenceService` that OVMS and MLServer implement. Strategies should not assume
  a single gRPC enablement approach covers all runtimes -- vLLM gRPC is a separate effort with
  different protocol, port, and routing requirements.
- MLServer implements `ModelStreamInfer` (streaming gRPC), so strategies proposing gRPC streaming
  for MLServer workloads can scope this as template-only changes. OVMS does not implement
  `ModelStreamInfer`; strategies proposing streaming gRPC for OVMS workloads would require
  upstream runtime contributions.
- CVE-2026-33186 (gRPC authorization bypass) is already fixed in the ODH fork. Strategies do not
  need to include CVE remediation as a prerequisite for gRPC enablement.
- Kuadrant AuthPolicy covers both REST and gRPC traffic via the Gateway API HTTPRoute. However,
  InferenceService external exposure uses OpenShift Route (odh-model-controller), which is
  authenticated via Authorino AuthConfig, not Kuadrant. Strategies enabling gRPC must verify auth
  coverage on both entrypoints.
- The dual-protocol HTTPRoute uses `content-type: ^application/grpc.*` header matching to
  distinguish gRPC from REST. Strategies involving custom protocols or non-standard content types
  should verify compatibility with this matching rule.

## Context

Overlay 0011 comprehensively documents LLMInferenceService networking -- Gateway API integration,
EPP scheduling, Kuadrant security, Istio DestinationRules, and OCP platform integration. But the
InferenceService (v1beta1) networking path used by Model Runtimes team templates (OVMS, MLServer,
vLLM, Triton) has no equivalent documentation. The dual-protocol routing mechanism (merged
upstream April 2026, synced to ODH fork), the containerPort-driven enablement pattern, the
per-runtime protocol support matrix, the CVE fix status, and the streaming feasibility gap are all
architectural facts that live in code but are not captured in any generated architecture doc or
existing overlay.

Without this context, strategy pipelines evaluating gRPC support proposals will incorrectly scope
the work as a KServe controller feature when it is actually a template-level change. They may also
conflate vLLM's SMG gRPC protocol with the KServe v2 gRPC that predictive runtimes implement,
leading to incorrect dependency graphs and effort estimates.
