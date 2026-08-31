---
id: "0014"
title: Model Runtimes team architecture — ownership, runtime lifecycle, and testing patterns
status: active
created: 2026-06-13
updated: 2026-08-09
affects:
  - openvino_model_server
  - MLServer
  - vllm
  - odh-model-controller
  - kserve
  - opendatahub-tests
  - autogluon
  - guardrails-detector-huggingface
release:
  - "3.4"
  - "3.5"
  - "next"
provenance:
  - https://github.com/opendatahub-io/opendatahub-tests/tree/main/tests/model_serving/model_runtime
  - https://github.com/opendatahub-io/odh-model-controller/tree/main/config/runtimes
  - https://github.com/opendatahub-io/odh-model-controller/blob/main/architecture.md
  - https://github.com/opendatahub-io/kserve
  - https://github.com/opendatahub-io/opendatahub-tests/blob/main/conftest.py
  - https://github.com/opendatahub-io/opendatahub-tests/blob/main/utilities/inference_utils.py
  - https://github.com/opendatahub-io/opendatahub-tests/blob/main/utilities/serving_runtime.py
  - https://github.com/opendatahub-io/opendatahub-tests/blob/main/utilities/constants.py
  - https://github.com/opendatahub-io/opendatahub-tests/pull/1667
  - https://github.com/opendatahub-io/opendatahub-tests/pull/1679
  - https://github.com/opendatahub-io/opendatahub-tests/pull/1704
  - https://github.com/opendatahub-io/opendatahub-tests/pull/1713
  - https://github.com/opendatahub-io/opendatahub-tests/pull/1720
  - https://github.com/opendatahub-io/opendatahub-tests/pull/1723
  - https://github.com/opendatahub-io/MLServer
  - https://github.com/opendatahub-io/openvino_model_server
  - https://github.com/SeldonIO/MLServer (orphaned upstream)
author: Imran Khalidi, Model Runtimes Team
superseded_by: null
---

## Fact

### KServe Integration

KServe provides the core model serving primitives for RHOAI. The platform uses the `opendatahub-io/kserve` fork
(not upstream `kserve/kserve`). Key CRDs defined in `pkg/apis/serving/`:

| CRD | API Version | Purpose | Scope |
|-----|-------------|---------|-------|
| `ServingRuntime` | `serving.kserve.io/v1alpha1` | Defines container image, supported model formats, protocol versions, resources | Namespace |
| `ClusterServingRuntime` | `serving.kserve.io/v1alpha1` | Cluster-wide runtime definitions (platform-managed) | Cluster |
| `InferenceService` | `serving.kserve.io/v1beta1` | References a ServingRuntime; adds storage URI, model format, resources, replicas | Namespace |
| `InferenceGraph` | `serving.kserve.io/v1alpha1` | Multi-model routing DAG (stub reconciliation in ODH Model Controller) | Namespace |
| `LLMInferenceService` | `serving.kserve.io/v1alpha2` | Purpose-built for LLM deployments with llm-d integration | Namespace |

**ClusterServingRuntime lifecycle:** The CRD includes a native `disabled` field
(`spec.disabled: true`) that prevents new InferenceService deployments from matching the runtime
while preserving existing ones. This is distinct from Dashboard's annotation-based disablement
pattern (`opendatahub.io/dashboard: "false"`). The `IsDisabled()` method returns the runtime
status, and KServe sets `InvalidSpec` with reason `RuntimeDisabled` if a disabled runtime is
referenced.

Source: `pkg/apis/serving/v1alpha1/servingruntime_types.go` (`Disabled *bool`);
`pkg/controller/v1beta1/inferenceservice/components/predictor.go` (status check)

**Historical context — why CSR was excluded:** ClusterServingRuntime was originally disabled in
ODH/RHOAI because of ModelMesh. When ModelMesh was active, CSRs caused persistent inference pods
to be created across all namespaces — a multi-tenancy problem where one team's cluster-wide
runtime definition would consume GPU resources in another team's namespace. With ModelMesh
archived (Feb 2025) and retired from RHOAI 3.x, this concern no longer applies. The CSR CRD is
being re-evaluated for RHOAI (RHAISTRAT-2173).

Source: RHAISTRAT-2173 investigation; ModelMesh archive context

RHOAI exclusively uses **RawDeployment** mode — also referred to as **Standard** mode in upstream
KServe documentation and newer test infrastructure (not Knative/Serverless). This means:
- No Knative Serving dependency (`serverless-operator` not required)
- KServe controller creates standard Kubernetes Deployments and Services directly
- ODH Model Controller handles OpenShift Route creation (Knative Routes are not used)
- `KServeDeploymentType.RAW_DEPLOYMENT` is the only mode used in test fixtures (upstream KServe
  and newer test code use the term "Standard" mode interchangeably)

Source: `utilities/constants.py` defines `KServeDeploymentType` enum; `odh-model-controller/architecture.md`
documents the RawDeployment-exclusive design decision.

#### Runtime Resolution Priority

When an InferenceService references a runtime by name, KServe resolves it with a two-step
fallback:

1. **Namespace first:** Look up a `ServingRuntime` with the given name in the InferenceService's
   namespace
2. **Cluster fallback:** If not found, look up a `ClusterServingRuntime` with the same name at
   cluster scope

The controller tracks which scope was matched via `isvc.Status.ServingRuntimeName` (namespace) or
`isvc.Status.ClusterServingRuntimeName` (cluster) — only one is set.

The `IsCrdAvailable()` guard in `SetupWithManager()` checks whether the ClusterServingRuntime CRD
is installed. If absent, the controller logs "The InferenceService controller won't watch
serving.kserve.io/v1alpha1/ClusterServingRuntime resources because the CRD is not available" and
skips the watch gracefully — no crash, no error.

**Current state in ODH/RHOAI:** ClusterServingRuntime CRD is disabled. The `IsCrdAvailable`
guard returns false, so the cluster-scope fallback is never reached. All runtime resolution
happens at namespace scope via ServingRuntime.

Source: `pkg/controller/v1beta1/inferenceservice/utils/utils.go` (`GetServingRuntime()`);
`pkg/controller/v1beta1/inferenceservice/components/predictor.go` (`reconcileModel()`);
`pkg/utils/utils.go` (`IsCrdAvailable()`)

### KServe + ODH Model Controller Layering

```
+------------------------------------------------------------------+
|                        User / Dashboard                           |
|   Creates InferenceService + selects ServingRuntime template      |
+------------------------------------------------------------------+
                              |
                              v
+------------------------------------------------------------------+
|                     KServe Controller                             |
|   (opendatahub-io/kserve)                                        |
|                                                                  |
|   Reconciles InferenceService into:                              |
|   - Deployment (predictor pod with runtime container)            |
|   - Service (ClusterIP, ports from SR spec)                      |
|   - Validates: name length, namespace protection                 |
|   - Injects: storage initializer (for S3/PVC/OCI sources)       |
+------------------------------------------------------------------+
                              |
                              v
+------------------------------------------------------------------+
|                   ODH Model Controller                            |
|   (opendatahub-io/odh-model-controller)                          |
|                                                                  |
|   Layers RHOAI-specific capabilities:                            |
|   - OpenShift Routes (TLS passthrough, edge termination)         |
|   - ServiceMonitors + PodMonitors (Prometheus scraping)          |
|   - CA bundle aggregation (trusted certificates injection)       |
|   - KEDA TriggerAuthentication (HPA/autoscaling)                 |
|   - NIM account lifecycle (NVIDIA NIM integration)               |
|   - Model Registry sync (model metadata propagation)             |
|   - ServingRuntime template management                           |
+------------------------------------------------------------------+
                              |
                              v
+------------------------------------------------------------------+
|                      Runtime Container                            |
|   (vLLM | OVMS | MLServer | AutoGluon | Triton | Guardrails HF) |
|                                                                  |
|   Runs inference, exposes REST/gRPC endpoints                    |
|   HardwareProfile webhook injects GPU resource limits            |
+------------------------------------------------------------------+
```

Source: `odh-model-controller/architecture.md` full architecture description;
`odh-model-controller/controllers/` for controller implementations.

**ODH Model Controller RBAC scope:** The `odh-model-controller-role` ClusterRole has RBAC rules
for namespace-scoped `servingruntimes` (create/get/list/update/watch + finalizers) but has **no
RBAC rules for `clusterservingruntimes`**. Enabling CSR support in ODH/RHOAI would require adding
RBAC rules for `clusterservingruntimes` to the controller's ClusterRole, plus watch and reconcile
logic for cluster-scoped resources.

The controller does have RBAC for `llminferenceserviceconfigs` (get/list/watch) and
`llminferenceservices` (get/list/patch/post/update/watch) — confirming it already watches both
deployment paths at the resource level.

Source: `config/rbac/role.yaml` (`odh-model-controller-role`)

#### OpenShift Route Timeout Behavior

ODH Model Controller sets route timeout via `haproxy.router.openshift.io/timeout` annotation
when creating OpenShift Routes for InferenceServices. The default per-component timeout is
**30 seconds** (`DefaultOpenshiftRouteTimeout`).

The controller calculates total timeout by **summing component timeouts**:
• Predictor only: 30s
• Predictor + Transformer: 60s
• Predictor + Transformer + Explainer: 90s

If the InferenceService has an explicit `haproxy.router.openshift.io/timeout` annotation, that
value overrides the calculated sum.

**Impact:** Long-running inference workloads (voice dialogues, diffusion image generation,
large-batch predictions) will hit the 30s default and receive HTTP 504 Gateway Timeout. These
workloads must set the route timeout annotation explicitly — either on the InferenceService (ODH
Model Controller propagates it) or directly on the Route.

Source: `internal/controller/constants/constants.go` (`DefaultOpenshiftRouteTimeout = 30`);
`internal/controller/utils/utils.go` (`SetOpenshiftRouteTimeoutForIsvc()`)

### Dual Deployment Path Architecture

RHOAI 3.4+ supports two parallel, GA-quality deployment paths for model serving. They are
non-overlapping — each targets a different workload category.

| Path | CRDs | Target Workloads | Template Mechanism | Routing |
|------|------|------------------|--------------------|---------|
| **Predictive / Classical ML** | ServingRuntime + InferenceService (v1beta1) | OVMS, MLServer, AutoGluon, vLLM (OpenAI API), Triton (T&V) | ServingRuntime templates in `config/runtimes/` with annotation-based Dashboard discovery | ODH Model Controller creates OpenShift Routes |
| **LLM / GenAI** | LLMInferenceServiceConfig + LLMInferenceService (v1alpha2) | vLLM with llm-d, disaggregated P/D, multi-node, LoRA | LLMInferenceServiceConfig CRs as reusable configuration templates (`spec.baseRefs`) | KServe creates Gateway API HTTPRoute + InferencePool |

RHOAI 3.4 documentation states that LLMInferenceServiceConfig "replaces custom ServingRuntime
definitions" for LLM workloads — confirming it as the migration target. However, ServingRuntime
is **NOT deprecated** and remains the GA path for predictive runtimes.

MaaS (Models-as-a-Service) is GA in RHOAI 3.4 and uses LLMInferenceService + ExternalModel as
the backend, further confirming the LLM path as the ecosystem direction for generative workloads.

**Deprecation chain for context:**
• Serverless (Knative) mode: deprecated RHOAI 2.25, retired 3.0
• ModelMesh: deprecated RHOAI 2.19, archived upstream Feb 2025, removal required for 3.x
• ServingRuntime / InferenceService: **NOT deprecated** — active GA path for predictive runtimes
• ClusterServingRuntime: CRD exists in KServe but is currently disabled in ODH/RHOAI (see above)

Source: RHOAI 3.4 product documentation; KServe v1alpha2 LLMInferenceService CRD;
[kserve/kserve ROADMAP.md](https://github.com/kserve/kserve/blob/master/ROADMAP.md)

### Component Ownership Map

```
+-----------------------------------------------------------------------+
|                         Model Runtimes Team                            |
|                                                                       |
|  +---------------------+  +---------------------+  +---------------+  |
|  | opendatahub-io/     |  | opendatahub-io/     |  | Runtime       |  |
|  | openvino_model_     |  | MLServer            |  | template YAML |  |
|  | server              |  | (carries AMD/ONNX)  |  | definitions   |  |
|  +---------------------+  +---------------------+  +---------------+  |
|                                                                       |
|  +---------------------+  +---------------------+                     |
|  | opendatahub-tests/  |  | AutoGluon runtime   |                     |
|  | model_runtime/      |  | template (OOTB,     |                     |
|  | (ALL runtime tests) |  |  tabular/timeseries) |                     |
|  +---------------------+  +---------------------+                     |
+-----------------------------------------------------------------------+

+-----------------------------------------------------------------------+
|                         TrustyAI Team                                  |
|                                                                       |
|  +----------------------------------+                                 |
|  | Guardrails Detector HF runtime   |                                 |
|  | (safety/content classification,  |                                 |
|  |  HF SequenceClassification)      |                                 |
|  +----------------------------------+                                 |
+-----------------------------------------------------------------------+

+-----------------------------------------------------------------------+
|                            RHAII Team                                  |
|                                                                       |
|  +---------------------------+  +----------------------------------+  |
|  | vLLM Engine Builds        |  | Engine Feature Testing           |  |
|  | (CUDA, ROCm, Gaudi)       |  | (multimodal, quant, spec-decode, |  |
|  | registry.redhat.io        |  |  tool calling, TGIS, perf)       |  |
|  +---------------------------+  +----------------------------------+  |
+-----------------------------------------------------------------------+

+-----------------------------------------------------------------------+
|                       IBM Teams (separate forks)                       |
|                                                                       |
|  +---------------------------+  +----------------------------------+  |
|  | red-hat-data-services/    |  | red-hat-data-services/           |  |
|  | vllm-cpu                  |  | vllm-spyre                       |  |
|  | (x86, Power ppc64le,      |  | (IBM Spyre accelerator)          |  |
|  |  Z s390x builds)          |  |                                  |  |
|  +---------------------------+  +----------------------------------+  |
|                                                                       |
|  IBM Power team: ppc64le arch (VSX kernels)                           |
|  IBM Z team: s390x arch (VXE kernels)                                 |
|  IBM Spyre team: Spyre accelerator integration                        |
+-----------------------------------------------------------------------+

+-----------------------------------------------------------------------+
|                       Platform / KServe Team                           |
|                                                                       |
|  +---------------------+  +---------------------+  +---------------+  |
|  | opendatahub-io/     |  | odh-model-controller|  | model_server/ |  |
|  | kserve (CRDs,       |  | (companion ctrler:  |  | kserve/ tests |  |
|  |  controllers,       |  |  Routes, monitoring,|  | (routes, auth |  |
|  |  webhooks)          |  |  auth, NIM, KEDA)   |  |  scaling)     |  |
|  +---------------------+  +---------------------+  +---------------+  |
+-----------------------------------------------------------------------+

+-----------------------------------------------------------------------+
|                            NVIDIA                                      |
|                                                                       |
|  +----------------------------------+                                 |
|  | nvcr.io/nvidia/tritonserver      |                                 |
|  | (vendor image, not Red Hat built) |                                 |
|  +----------------------------------+                                 |
+-----------------------------------------------------------------------+
```

### Runtime Deployment Paths

```
OUT-OF-THE-BOX PATH (OVMS, MLServer, vLLM):
============================================

  config/runtimes/*.yaml       Annotation-driven discovery:
  (kustomized into operator)   opendatahub.io/dashboard: "true"
         |                     opendatahub.io/ootb: "true"
         v
  +------------------+
  | OpenShift        |     applications_namespace (e.g., redhat-ods-applications)
  | Template         |     Dashboard reads templates from this namespace
  +------------------+
         |
         | ServingRuntimeFromTemplate (per user namespace)
         v
  +------------------+
  | ServingRuntime   |     Namespace-scoped, owned by user
  | (from template)  |     Image: registry.redhat.io (sha256 digest)
  +------------------+
         |
         | User creates InferenceService referencing this runtime
         v
  +------------------+
  | InferenceService |     storage_uri, model_format, resources, replicas
  +------------------+     external_route: true (for route creation)
         |
         | KServe Controller reconciles
         v
  +------------------+
  | Deployment +     |     Predictor pod with runtime container
  | Service          |     Storage initializer sidecar
  +------------------+
         |
         | ODH Model Controller augments
         v
  +------------------+
  | Route +          |     TLS passthrough route
  | ServiceMonitor + |     Prometheus scrape target
  | CA Bundle        |     Trusted CA injection
  +------------------+


TESTED & VERIFIED PATH (Triton):
=================================

  Test creates ServingRuntime CRD directly (no platform template)
  Image: nvcr.io/nvidia/tritonserver (vendor registry)
         |
         v
  +------------------+
  | ServingRuntime   |     Created by test fixture (not from template)
  | (custom CRD)    |     Defines: formats, ports, args, volumes
  +------------------+
         |
         | InferenceService references runtime
         v
  +------------------+         +------------------+         +------------------+
  | InferenceService | ------> | Deployment +     | ------> | Route +          |
  |                  |  KServe | Service          |  ODH MC | ServiceMonitor   |
  +------------------+         +------------------+         +------------------+
```

### HardwareProfile Mechanism

HardwareProfiles abstract GPU resource allocation from users. When an InferenceService is created:
1. User selects a HardwareProfile (e.g., "NVIDIA A100 40GB")
2. The `rhods-operator` admission webhook intercepts the ISVC creation
3. Webhook injects the appropriate resource limits (`nvidia.com/gpu: 1`) into the predictor container spec
4. Neither the user nor the Dashboard needs to know the raw resource identifier

This means new runtime templates do NOT need to hardcode GPU resources — the HardwareProfile webhook
handles injection automatically. Templates only need the annotation:
`opendatahub.io/recommended-accelerators: '["nvidia.com/gpu"]'`

Source: `rhods-operator` webhook; Dashboard HardwareProfile API.

**Known failure mode — GPU type mismatch:** If the ServingRuntime template specifies one
accelerator type (e.g., `nvidia.com/gpu` via annotation) but the InferenceService is created with
a different HardwareProfile (e.g., `amd.com/gpu`), KServe may assign BOTH accelerator types to
the predictor container's resource limits. This causes pod scheduling failure because the node
cannot satisfy two different accelerator requests simultaneously.

To avoid this, the GPU type in the ServingRuntime's `opendatahub.io/recommended-accelerators`
annotation must be consistent with the HardwareProfile selected at InferenceService creation time.
Dashboard enforces this by filtering HardwareProfile options based on the selected runtime
template's recommended accelerators.

Source: RHOAIENG-78154 (DiffusionGemma validation); `rhods-operator` webhook behavior

### Runtime Categories (Three-Tier Taxonomy)

RHOAI defines three categories of model serving runtimes:

| Category | Shipped in RHOAI | Support Level | Image Source | Template Location | Image Validation |
|----------|-----------------|---------------|--------------|-------------------|-----------------|
| **Out-of-the-box Supported** | Yes (CSV `relatedImages`) | Full Red Hat support | `registry.redhat.io` (sha256 digest) | `odh-model-controller/config/runtimes/` | Yes — `image_validation/` tests verify digests |
| **Custom Runtimes** | No | No specific support | User-provided | User creates ServingRuntime CRD | No |
| **Tested & Verified** | No | Limited to defined validation scope | Vendor registry (e.g., `nvcr.io`) | Test creates ServingRuntime CRD | No (vendor-managed) |

The image validation tests (`tests/model_serving/model_runtime/image_validation/`) verify that out-of-the-box
runtime images match expected sha256 digests from `registry.redhat.io`. The `RUNTIME_CONFIGS` list in
`constant.py` only contains OVMS, MLServer, and vLLM — confirming Triton is NOT platform-shipped.

Source: `tests/model_serving/model_runtime/image_validation/constant.py`

#### Runtime Maturity Progression

New runtime variants follow a staged progression before reaching full out-of-the-box status:

| Stage | What Ships | Template in `config/runtimes/` | Dashboard Visible | Support Level |
|-------|-----------|-------------------------------|-------------------|---------------|
| **Dev Preview** | Docs mention only — image available on `quay.io` or `registry.redhat.io` but no platform template | No | No (custom runtime via CLI only) | No support — experimental |
| **Tech Preview** | Platform template with `opendatahub.io/support-status: "tech-preview"` annotation | Yes | Yes (with Tech Preview badge) | Limited support per TP terms |
| **GA** | Full platform template with `opendatahub.io/ootb: "true"` annotation | Yes | Yes | Full Red Hat support |

Examples:
• vLLM CPU variants entered as Tech Preview before reaching GA
• Triton is a special case — Tested & Verified, not on this progression path

Source: RHAISTRAT-1486 (Rubin Day 0 Dev Preview pattern); RHAISTRAT-2493 (vLLM-Omni)

### Ownership Boundaries

| Component / Repo | Owner | Responsibility | Source |
|-----------------|-------|----------------|--------|
| `opendatahub-io/openvino_model_server` | Model Runtimes | OVMS midstream fork, container image, Intel GPU support | GitHub repo |
| `opendatahub-io/MLServer` | Model Runtimes | MLServer midstream fork (carries AMD + ONNX patches), container image | GitHub repo; upstream `SeldonIO/MLServer` is orphaned |
| `opendatahub-io/opendatahub-tests/tests/model_serving/model_runtime/` | Model Runtimes | All runtime integration tests (OVMS, MLServer, vLLM operator integration, Triton T&V) | GitHub tree |
| `opendatahub-io/odh-model-controller/config/runtimes/` | Model Runtimes + Platform | Runtime template YAML definitions (kustomized into operator deployment) | GitHub tree |
| `opendatahub-io/kserve` | KServe / Platform | Core CRDs (`ServingRuntime`, `InferenceService`, etc.), controllers, webhook validation | GitHub repo |
| `opendatahub-io/odh-model-controller` | Platform | Companion controller: Routes, ServiceMonitors, CA bundles, KEDA, NIM integration, Model Registry sync | `architecture.md` |
| vLLM container images (CUDA, ROCm, Gaudi) | RHAII | Engine builds (`registry.redhat.io`), engine-level feature testing | RHAII team backlog |
| vLLM container images (CPU x86, Power, Z) | IBM (separate vLLM fork: `red-hat-data-services/vllm-cpu`) | CPU variant engine builds, arch-specific optimizations (VSX for Power, VXE for Z) | IBM team backlog |
| vLLM container images (Spyre) | IBM Spyre team (`red-hat-data-services/vllm-spyre`) | IBM Spyre accelerator variant | IBM Spyre team backlog |
| `opendatahub-io/opendatahub-tests/tests/model_serving/model_server/kserve/` | Platform / KServe | Platform-layer tests: route reconciliation, storage backends, token auth, KEDA autoscaling, ISVC lifecycle, observability | GitHub tree |
| NVIDIA Triton image (`nvcr.io/nvidia/tritonserver`) | NVIDIA (vendor) | Image builds, backend maintenance, deprecation timeline | NVIDIA release notes |
| AutoGluon runtime image (`odh-kserve-autogluon-server`) | AutoML team | Runtime image, CVEs, Konflux builds, E2E tests, AIPCC packages, upstream development | `red-hat-data-services/kserve-autogluon-server`; RACI in RHOAIENG-61354 |
| AutoGluon template (`autogluon-runtime-template`) | Model Runtimes (template only) | ServingRuntime template enablement in odh-model-controller; Model Runtimes scope is template-only | `config/runtimes/autogluon-template.yaml`; RHOAIENG-63920 |
| Guardrails Detector HF (`hf-detector-template`) | TrustyAI | OOTB template, HF-based safety/content detection, text classification | `config/runtimes/hf-detector-template.yaml`; `trustyai-explainability/guardrails-detectors` |

### Runtime Matrix

#### OVMS (OpenVINO Model Server)

- **Category**: Out-of-the-box Supported
- **Repo**: `opendatahub-io/openvino_model_server` (midstream fork of `openvinotoolkit/model_server`)
- **Template**: `kserve-ovms` (`ovms-kserve-template.yaml` in `config/runtimes/`)
- **Image**: `registry.redhat.io` (sha256 pinned in CSV `relatedImages`)
- **Supported formats**: OpenVINO IR, ONNX, TensorFlow SavedModel, PaddlePaddle, PyTorch (via conversion)
- **GPU support**: Intel GPU only via `--target_device` argument
  - `--target_device=AUTO` (default): CPU auto-selected
  - `--target_device=GPU`: Intel integrated/discrete GPU
  - **CUDA plugin deprecated in RHOAI 3.4** — NVIDIA GPU acceleration is NOT supported via OVMS going forward
- **Default container args**: `--target_device=AUTO`, `--metrics_enable`, `--rest_port=8888`
- **Protocols**: REST (v2 inference protocol, port 8888) + gRPC (grpc-v2, port 8033)
- **Annotations**: `opendatahub.io/recommended-accelerators: '["nvidia.com/gpu"]'`
- **Test location**: `tests/model_serving/model_runtime/openvino/`

Source: `opendatahub-io/openvino_model_server` README; `odh-model-controller/config/runtimes/ovms-kserve-template.yaml`

#### MLServer

- **Category**: Out-of-the-box Supported
- **Repo**: `opendatahub-io/MLServer` (midstream fork of `SeldonIO/MLServer`)
- **Template**: `mlserver-runtime-template` (`mlserver-template.yaml` in `config/runtimes/`)
- **Image**: `registry.redhat.io` (sha256 pinned in CSV `relatedImages`)
- **Supported formats**: LightGBM, ONNX, Sklearn (scikit-learn), XGBoost
- **GPU support**: Ships as a separate OOTB template (`mlserver-cuda-runtime-template`) on `aipcc/cuda` base:
  - CPU base image (`aipcc/cpu`) does **NOT** include CUDA runtime libraries (`libcudart.so`)
  - `onnxruntime-gpu` will crash immediately on CPU base: `OSError: libcudart.so.12: cannot open shared object file`
  - `mlserver-cuda-runtime-template` uses `$(mlserver-cuda-image)` — a distinct image built on `aipcc/cuda`
  - Follows same model as vLLM (separate purpose-built images per accelerator)
  - CPU image remains unchanged — **not** a hybrid/unified build (CUDA payload adds ~500MB–1GB, unacceptable for air-gapped CPU-only deployments)
  - **AIPCC dependency**: `onnxruntime-gpu` must be available in the AIPCC CUDA collection. New package onboarding or restoration follows the standard AIPCC process (1–3 weeks). Strategy timelines must account for this.
- **Critical upstream context**:
  - Upstream community (`SeldonIO/MLServer` on GitHub) is **dead/orphaned**
  - Seldon (the parent company/sponsor) has been **liquidated**
  - No new releases, no community PRs merged, no maintainer activity
  - **AMD architecture support** (aarch64, ppc64le) is NOT in upstream
  - **ONNX model format support** (full ONNXRuntime integration) is NOT in upstream
  - Both AMD and ONNX support are added by Red Hat in `opendatahub-io/MLServer` midstream fork
  - Model Runtimes team carries these patches indefinitely with zero upstream community support
  - Implications: all MLServer bug fixes, security patches, and new features are Red Hat's sole burden
- **Test location**: `tests/model_serving/model_runtime/mlserver/`

Source: `opendatahub-io/MLServer` repo; `SeldonIO/MLServer` (last commit analysis); Seldon liquidation news

#### MLServer Multi-Model Architecture (Repository Mode)

MLServer includes a built-in multi-model capability via its `SchemalessModelRepository`. This is
shipped and functional in the RHOAI MLServer image today. However, no OOTB template currently
enables repository mode — the existing `mlserver-template` has `multiModel: false`. The planned
`mlserver-multi-model-template` would expose this as a platform capability. Until then,
multi-model via MLServer requires a custom ServingRuntime CRD.

**Storage layout convention:**
```text
/mnt/models/                          # MLSERVER_MODELS_DIR (PVC mount point)
├── sklearn-iris/
│   ├── model-settings.json           # {"name": "sklearn-iris", "implementation": "..."}
│   └── model.joblib
├── xgboost-mushroom/
│   ├── model-settings.json
│   └── model.bst
└── onnx-resnet/
    ├── model-settings.json
    └── model.onnx
```

**Key configuration:**
• `MLSERVER_MODELS_DIR=/mnt/models` — directory MLServer scans for model subdirectories
• Each model subdirectory must contain a `model-settings.json` with at minimum `name` and
  `implementation` fields
• MLServer auto-discovers models on startup via `SchemalessModelRepository` directory scanning

**V2 Repository API (dynamic model management):**
• `POST /v2/repository/models/{name}/load` — load a model dynamically after startup
• `POST /v2/repository/models/{name}/unload` — unload a model, freeing resources
• `POST /v2/repository/index` — list all discovered models and their states

**Worker process architecture:**
• MLServer runs model inference in `parallel_workers` child processes
• Worker failures are detected via SIGCHLD signal handling
• Each worker process loads its own copy of the model — memory scales linearly with workers

**Critical annotation for dynamic loading:**
The InferenceService must have `storage.kserve.io/readonly: "false"` to enable direct PVC mount.
Without this annotation, KServe's default behavior (`readonly: true`) copies PVC content to an
emptyDir at startup via the storage initializer. Models added to the PVC after startup would be
invisible because the emptyDir snapshot is stale.

Source: `opendatahub-io/MLServer` (`mlserver/repository.py`, `SchemalessModelRepository`);
KServe `pkg/constants/constants.go` (`StorageReadonlyAnnotationKey`);
KServe `pkg/webhook/admission/pod/storage_initializer_injector.go` (`GetStorageInitializerReadOnlyFlag()`)

#### Multi-Model Health Probes

Multi-model deployments must use **server-level** health endpoints, not model-level:

| Endpoint | Scope | Use For |
|----------|-------|---------|
| `GET /v2/health/ready` | Server | Readiness probe — server is ready to accept requests |
| `GET /v2/health/live` | Server | Liveness probe — server process is alive |
| `GET /v2/models/{name}/ready` | Single model | **NOT suitable for multi-model** — no single model name to probe |

When configuring `readinessProbe` and `livenessProbe` on a multi-model ServingRuntime template,
use `/v2/health/ready` and `/v2/health/live` respectively, NOT `/v2/models/{name}/ready`.

Source: KServe v2 inference protocol specification; MLServer health endpoint implementation

#### Multi-Model Scaling Constraints

Horizontal scaling (HPA) of multi-model InferenceServices requires **ReadWriteMany (RWX)**
storage class for the shared model PVC. Default `ReadWriteOnce (RWO)` PVCs can only be mounted
by pods on a single node — HPA scaling to pods on different nodes will fail with volume mount
errors.

| Storage Access Mode | HPA Scaling | Replicas on Same Node | Replicas on Different Nodes |
|--------------------|-----------|-----------------------|---------------------------|
| ReadWriteOnce (RWO) | Limited | Works (same node mount) | **Fails** (volume mount error) |
| ReadWriteMany (RWX) | Full | Works | Works |

Strategies proposing multi-model with autoscaling must specify RWX-capable storage class as a
prerequisite.

Source: Kubernetes PVC access mode semantics; RHAISTRAT-2011 multi-model scaling analysis

### Security Considerations (Multi-Model)

Multi-model deployments introduce security boundaries that single-model deployments do not have:

**V2 Management API exposure:**
The `load`/`unload` endpoints (`/v2/repository/models/*/load|unload`) are served on the **same
port** as inference endpoints. There is no auth separation between inference consumers (who should
only call `/v2/models/{name}/infer`) and model administrators (who manage the model lifecycle).
Any client with access to the inference endpoint can load or unload models.

**Shared-pod blast radius:**
All models in a multi-model deployment share the same pod, process namespace, and (in MLServer's
case) the same Python process tree. A model that crashes, consumes excessive memory, or has a
security vulnerability affects all other models in the same deployment.

**Mitigation context:**
These are inherent to the runtime-level multi-model pattern (MLServer, Triton). They are NOT
addressable by platform-layer changes (KServe, ODH Model Controller). Strategies proposing
multi-model deployments should document these constraints and assess whether the use case's
security requirements are compatible with shared-pod serving.

Source: RHAISTRAT-2011 multi-model security analysis; V2 inference protocol specification

#### vLLM

- **Category**: Out-of-the-box Supported (9 platform-shipped variant templates + fast-build overlays)
- **Templates** (all in `odh-model-controller/config/runtimes/vllm/`):

  | Template | Accelerator | Image Owner |
  |----------|-------------|-------------|
  | `vllm-cuda-runtime-template` | NVIDIA GPU | RHAII |
  | `vllm-rocm-runtime-template` | AMD GPU | RHAII |
  | `vllm-gaudi-runtime-template` | Intel Gaudi (Habana) | RHAII |
  | `vllm-multinode-runtime-template` | Multi-node (LeaderWorkerSet) | RHAII |
  | `vllm-spyre-x86-runtime-template` | IBM Spyre (x86) | IBM Spyre team (`red-hat-data-services/vllm-spyre`) |
  | `vllm-spyre-s390x-runtime-template` | IBM Spyre (s390x) | IBM Spyre team (`red-hat-data-services/vllm-spyre`) |
  | `vllm-spyre-ppc64le-runtime-template` | IBM Spyre (ppc64le) | IBM Spyre team (`red-hat-data-services/vllm-spyre`) |
  | `vllm-cpu-runtime-template` | CPU (generic) | IBM (`red-hat-data-services/vllm-cpu`) |
  | `vllm-cpu-x86-runtime-template` | x86 CPU | IBM (`red-hat-data-services/vllm-cpu`) |

  Additionally, a legacy ClusterServingRuntime exists at `config/runtimes/csr-kserve-vllm-v1.yaml`
  with `supportedModelFormats: [{name: vLLM}]`.

Source: `odh-model-controller/config/runtimes/vllm/kustomization.yaml`

- **RHAII boundary** (critical ownership split):
  - RHAII owns: vLLM engine source, CUDA/ROCm/Gaudi container image builds, engine-level features
    (TGIS protocol, multimodal inference, quantization AWQ/Marlin, speculative decoding, tool calling,
    performance benchmarks)
  - IBM teams own: CPU variant image builds (`red-hat-data-services/vllm-cpu` fork — x86, Power, Z),
    Spyre accelerator variant (`red-hat-data-services/vllm-spyre`)
  - Model Runtimes owns: RHOAI operator integration tests (does the runtime deploy correctly, serve inference
    via external routes, respond to probes, work with S3/PVC/OCI storage, function across accelerator variants)
- **Protocols**: OpenAI-compatible REST API only (`/v1/completions`, `/v1/chat/completions`, `/v1/models`, `/health`)
  - **gRPC is NOT supported** for vLLM in RHOAI OOTB templates
  - All templates declare `opendatahub.io/apiProtocol: 'REST'` and use `vllm.entrypoints.openai.api_server`
  - TGIS gRPC (port 8033) exists in some engine images but is RHAII scope, not exposed in platform templates
  - Contrast: OVMS and Triton support both REST and gRPC protocols
- **Test location**: `tests/model_serving/model_runtime/vllm/`

Source: `odh-model-controller/config/runtimes/vllm/*.yaml`; PR #1679 (RHAII scope separation)

#### Fast Build Rollout Pattern

RHOAI ships two "fast channel" variants of every vLLM template, generated via Kustomize overlays:

| Overlay Directory | Name Suffix | Annotation |
|-------------------|-------------|------------|
| `config/runtimes-fast-1/` | `-fast-1` | `opendatahub.io/fast-version: "1"` |
| `config/runtimes-fast-2/` | `-fast-2` | `opendatahub.io/fast-version: "2"` |

Each overlay takes all 9 base vLLM templates from `config/runtimes/vllm/`, adds the name suffix,
and applies two annotations:
• `opendatahub.io/fast-version: "<N>"` — identifies the fast channel
• `opendatahub.io/support-status: "unsupported"` — marks fast-channel builds as not GA-supported

This produces 9 (base) + 9 (fast-1) + 9 (fast-2) = **27 total vLLM template variants** shipped
in the operator. Fast-channel templates allow early access to new vLLM engine versions while the
stable templates remain on the GA-validated version.

Source: `odh-model-controller/config/runtimes-fast-1/kustomization.yaml`;
`odh-model-controller/config/runtimes-fast-2/kustomization.yaml`

#### Dashboard Model Format Constraint

Dashboard hardcodes `modelFormat: { name: 'vLLM' }` for all generative model types
(`ServingRuntimeModelType.GENERATIVE`). When the user selects "Generative" as the model type, the
Dashboard bypasses the model format selector entirely and returns `{ name: 'vLLM' }`. The model
format field is only visible for `PREDICTIVE` model types.

KServe validates `modelFormat.name` against `supportedModelFormats[].name` in the ServingRuntime
via exact string match. This means:
• New vLLM variant templates **MUST** use `name: vLLM` in their `supportedModelFormats` list to
  work with Dashboard without code changes
• Using a variant-specific name (e.g., `name: vLLM-Omni`, `name: vLLM-CPU`) would cause KServe
  validation to fail when deployed via Dashboard because the hardcoded format `vLLM` would not
  match
• CLI/kubectl deployments are unaffected — users specify the model format explicitly

Source: `packages/model-serving/src/components/deploymentWizard/fields/ModelFormatField.tsx`
(`useModelFormatField` hook, `modelType?.type === ServingRuntimeModelType.GENERATIVE` condition)

#### vLLM Runtime Arguments Injection

vLLM runtime arguments can be passed through two mechanisms depending on the deployment path:

| Deployment Path | Mechanism | Example |
|-----------------|-----------|---------|
| **ServingRuntime + InferenceService** | `VLLM_ADDITIONAL_ARGS` env var on the InferenceService container | `VLLM_ADDITIONAL_ARGS: "--max-model-len 4096 --enforce-eager"` |
| **LLMInferenceService** | Standard Kubernetes container `args` field (replaces image defaults per K8s semantics) | `args: ["--max-model-len", "4096", "--enforce-eager"]` |

The `VLLM_ADDITIONAL_ARGS` env var is parsed by the vLLM entrypoint and appended to the server
launch command. For LLMInferenceService, the container `args` replace the default image
entrypoint args per standard Kubernetes behavior — users must include all required arguments
when specifying custom args, as Kubernetes does not merge container args arrays.

**Key implication:** Model-specific parameters (e.g., `--max-model-len`, `--enforce-eager`,
`--dtype`, `--quantization`) do NOT require separate ServingRuntime templates. A single vLLM
template serves all model types — including non-autoregressive models like DiffusionGemma — with
model-specific config passed via args or env vars.

Source: vLLM entrypoint argument parsing; RHOAI 3.4 documentation (LLMInferenceService);
RHOAIENG-78154 (DiffusionGemma validation)

### Protocol Support Matrix

| Runtime | REST | gRPC | API Style | Template Annotation |
|---------|------|------|-----------|---------------------|
| **vLLM** | Yes (port 8080) | **No** | OpenAI-compatible (`/v1/completions`, `/v1/chat/completions`) | `opendatahub.io/apiProtocol: 'REST'` |
| **OVMS** | Yes (port 8888) | Yes (port 8033) | KServe v2 inference protocol | `protocolVersions: [v2, grpc-v2]` |
| **MLServer** | Yes (port 8080) | Yes (port 8081) | KServe v2 inference protocol | `protocolVersions: [v2, grpc-v2]` |
| **Triton** | Yes (port 8080) | Yes (port 9000) | KServe v2 inference protocol | Defined inline in test CRD |
| **AutoGluon** | Yes (port 8080) | **No** | KServe v1 + v2 (tabular only; timeseries is v1-only) | `protocolVersions: [v1, v2]` |
| **Guardrails HF** | Yes (port 8000) | **No** | Custom REST (uvicorn) | `opendatahub.io/apiProtocol: 'REST'` |

**Key facts about vLLM protocol limitation:**
- All vLLM OOTB templates use `python -m vllm.entrypoints.openai.api_server` — OpenAI REST only
- Engine images may internally support TGIS gRPC (port 8033) via `vllm_tgis_adapter`, but this is NOT
  exposed in platform ServingRuntime templates and is RHAII scope
- `red-hat-data-services/vllm-cpu` has a `VllmEngine` gRPC (port 50051) but not wired into OOTB templates
- Model Runtimes integration tests validate REST endpoints only for vLLM

Source: `odh-model-controller/config/runtimes/vllm-*.yaml` (all declare REST); PR #1679 (TGIS tests removed)

#### NVIDIA Triton

- **Category**: Tested & Verified (NOT out-of-the-box)
- **Template**: None — not in `odh-model-controller/config/runtimes/`; test creates ServingRuntime CRD directly
- **Image**: `nvcr.io/nvidia/tritonserver:25.02-py3` (from NVIDIA GPU Cloud, not `registry.redhat.io`)
  - Version 25.02 is pinned as the **last release** with TensorFlow backend included
  - TensorFlow backend deprecated and removed starting with 25.03 (v2.56.0)
  - The 25.02 pin is deliberate: the current test matrix requires the TensorFlow backend. No CVE support applies — Triton is not shipped with RHOAI (`registry.redhat.io` / CSV `relatedImages`); the image is sourced directly from NVIDIA (`nvcr.io`) for T&V validation only. Red Hat supports the deployment and integration layer (custom runtime via KServe), not the vendor image itself
  - Image version managed in `tests/model_serving/model_runtime/triton/constant.py`
- **Supported formats**: TensorRT, TensorFlow 1/2, ONNX, PyTorch (LibTorch), Triton (ensemble), XGBoost, Python, FIL (Forest Inference Library), DALI (GPU data pipeline), Keras
- **Protocols**: REST (port 8080, v2 inference) + gRPC (port 9000, KServe Predict V2)
- **Validation scope**: 7 model formats x REST protocol = 7 test scenarios — this defines the support boundary
  (gRPC protocol tests are currently skipped in the test suite; the original 7x2=14 matrix has been narrowed)
- **Model Runtimes sole responsibility**: Defining the validation scope and maintaining the test suite
- **Key distinction**: Customers deploy Triton as a "custom runtime" (create their own ServingRuntime CRD),
  but unlike truly custom runtimes, Red Hat has tested and verified it within the defined scope
- **gRPC tooling**: Uses `grpcurl` CLI with `grpc_predict_v2.proto` (stdin for payloads > 8KB)
- **Test location**: `tests/model_serving/model_runtime/triton/`
- **Not in image validation**: Absent from `image_validation/constant.py` `RUNTIME_CONFIGS` (confirms not platform-shipped)

Source: `opendatahub-tests/triton/constant.py`; NVIDIA Triton release notes; `odh-model-controller/config/runtimes/` (absence confirms)

#### AutoGluon

- **Category**: Out-of-the-box Supported (shipping 3.5 GA, pending RHOAIENG-82069 image fix verification)
- **STRAT lineage**: RHAISTRAT-1538 (from RHAIRFE-1482), under umbrella outcome RHAISTRAT-1066
  ("[Outcome] Enable AutoML"). STRAT was AI-generated via the Agentic SDLC Pipeline.
- **Template**: `autogluon-runtime-template` (`autogluon-template.yaml` in `config/runtimes/`)
- **Image**: `registry.redhat.io/rhoai/odh-kserve-autogluon-server-rhel9` (sha256 pinned in CSV
  `relatedImages`). Built via Konflux on `registry.redhat.io/rhai/base-image-cpu-rhel9` (AIPCC
  CPU base, UBI9). Python dependencies from Red Hat internal PyPI index.
- **AutoGluon version**: `1.5.0+rhaiv.5` (Red Hat-patched build from `opendatahub-io/autogluon` fork)
- **Supported formats**: `autogluon` (model format version "1", autoSelect enabled)
- **Supported predictor types**:

  | Predictor | Use Cases | Protocol Support |
  |-----------|-----------|-----------------|
  | `TabularPredictor` | Classification (binary/multiclass), regression, quantile prediction | REST v1 + v2 |
  | `TimeSeriesPredictor` | Time series forecasting (univariate + known covariates) | REST v1 only (v2 explicitly rejected) |

  The server auto-detects the predictor type at model load time: attempts
  `TimeSeriesPredictor.load()` first, falls back to `TabularPredictor.load()`. No user
  configuration needed.

- **Protocols**: REST only (port 8080). v1 + v2 for tabular, v1 only for time series.
  No gRPC support.
- **GPU support**: **CPU only** — the image is built on `aipcc/cpu` base with no CUDA dependencies.
  The template does not specify an `opendatahub.io/recommended-accelerators` annotation,
  consistent with its CPU-only image base. AutoGluon's TabularPredictor uses CPU-only inference
  (CatBoost, LightGBM, XGBoost, PyTorch/FastAI ensemble).
- **Multi-model**: Not supported (`multiModel: false`, explicitly out of scope in STRAT)
- **Resource requirements**: Requests cpu: 1, memory: 4Gi; Limits cpu: 4, memory: 8Gi
  (double the upstream KServe defaults — reflects AutoGluon's memory-intensive ensemble stacking)
- **Architectures**: x86_64, ppc64le, s390x, arm64
- **Security context**: `readOnlyRootFilesystem: true`, capabilities drop ALL, `/tmp` emptyDir
  for scratch space (AutoGluon's `SeasonalNaive` fallback requires writable directory)
- **Key environment variables**:
  - `PREDICT_PROBA=true` — returns per-class probability columns instead of label predictions
  - `AUTOGLUON_TS_ID_COLUMN` / `AUTOGLUON_TS_TIMESTAMP_COLUMN` — override time series column mapping
- **Version tolerance**: The server's `version_compat.py` module allows patch-level AutoGluon
  version mismatches (e.g., model saved with 1.5.0, served with 1.5.0+rhaiv.5)
- **Annotations**: `opendatahub.io/model-type: '["predictive"]'`, `opendatahub.io/apiProtocol: 'REST'`,
  `opendatahub.io/modelServingSupport: '["single"]'`
- **Key distinction**: First new OOTB predictive runtime added since the original trio (OVMS,
  MLServer, vLLM). AutoGluon is a first-party upstream KServe runtime (merged via
  [PR #5269](https://github.com/kserve/kserve/pull/5269), 2026-06-18, authored by Red Hat).
  The only OOTB runtime with dual protocol version support (v1 + v2).
- **Test location**: `tests/model_serving/model_runtime/autogluon/` (3 parametrized S3 tests
  via [PR #1794](https://github.com/opendatahub-io/opendatahub-tests/pull/1794)):

  | Test Case | Predictor | Protocol | Model | Storage |
  |-----------|-----------|----------|-------|---------|
  | `tabular-v2` | Tabular | v2 REST | Telco Churn (binary classification) | S3 |
  | `tabular-v1` | Tabular | v1 REST | Telco Churn (binary classification) | S3 |
  | `timeseries-v1` | Timeseries | v1 REST | Industry forecast | S3 |

  **Test gaps**: No PVC/OCI storage tests, no `predict_proba` tests, no quantile regression tests,
  no known covariates tests, no RawDeployment mode tests. AutoML team owns all E2E test authoring
  and maintenance per the RACI agreement.

Source: `odh-model-controller/config/runtimes/autogluon-template.yaml`; RHOAIENG-63920;
[KServe PR #5269](https://github.com/kserve/kserve/pull/5269);
[ODH-MC PR #844](https://github.com/opendatahub-io/odh-model-controller/pull/844)

#### AutoGluon Ownership Agreement (RACI)

A formal ownership matrix was established via RHOAIENG-61354 and signed off in May 2026:

| Responsibility | Owner | Team |
|---------------|-------|------|
| Core runtime development and upstream PR | AutoML team | AutoML |
| CVE management and SLAs for the runtime image | AutoML team | AutoML |
| Konflux/AIPCC coordination and image maintenance | AutoML team | AutoML |
| E2E test authoring and maintenance | AutoML team | AutoML |
| Integration into RHOAI quality gates | AutoML team | AutoML |
| Midstream fork archival (`opendatahub-io/kserve-autogluon-server`) | AutoML team | AutoML |
| Model artifacts migration to RH-managed S3 | AutoML team | AutoML |
| ServingRuntime template enablement in ODH/RHOAI | Model Runtimes | Model Runtimes |
| Upstream KServe PR review/coordination | KServe / Serving Orchestration | Serving Orchestration |

**Key agreement (Imran Khalidi, 2026-05-20 on RHAISTRAT-1538):** Model Runtimes scope is
"strictly limited to the Dashboard/UI integration, specifically adding the ServingRuntime
template, as well as reviewing and consulting on the upstream KServe PR."

**Template-only integration:** The Dashboard auto-discovers AutoGluon via existing annotation
scanning — no Dashboard code changes were needed. Nick Mazzitelli (2026-06-24): "if the
autogluon runtime is preinstalled it should just appear in existing deployment UIs for selection."

**Repository topology:**
- Upstream: `kserve/kserve` — server code at `python/autogluonserver/` (merged PR #5269)
- Midstream: `opendatahub-io/kserve-autogluon-server` (NOT archived despite RACI — status unclear)
- Downstream: `red-hat-data-services/kserve-autogluon-server` (Konflux build source)
- AutoGluon fork: `opendatahub-io/autogluon` (produces `1.5.0+rhaiv.X` releases)

**Known issue (3.5 GA):** RHOAIENG-82069 — template ships with midstream image reference
(`quay.io/opendatahub`) instead of downstream (`registry.redhat.io`). Causes ImagePullBackOff
on disconnected clusters. Fix PRs merged as of 2026-08-06 but not yet verified in a build.

Source: RHOAIENG-61354 (RACI document); RHAISTRAT-1538 comments

#### Guardrails Detector (Hugging Face)

- **Category**: Out-of-the-box Supported
- **Template**: `guardrails-detector-huggingface-serving-template` (`hf-detector-template.yaml` in `config/runtimes/`)
- **Image**: `registry.redhat.io` (sha256 pinned in CSV `relatedImages`)
- **Supported formats**: `guardrails-detector-hf-runtime` (Hugging Face `AutoModelsForSequenceClassification`)
- **Protocols**: REST (port 8000, uvicorn server — NOT KServe v2 protocol)
- **GPU support**: NVIDIA GPU recommended via `opendatahub.io/recommended-accelerators`
- **Purpose**: Safety and content detection — classifies text for risks (hateful speech, harmful content).
  Deployed alongside LLM inference endpoints as a guardrails layer.
- **Annotations**: `opendatahub.io/model-type: '["predictive"]'`, `opendatahub.io/apiProtocol: 'REST'`
- **Key distinction**: Uses `uvicorn` as the server entrypoint (not KServe's built-in server). Serves on
  port 8000 (unlike other runtimes on 8080). Metrics on port 8000 at `/metrics`.
- **Owner**: TrustyAI team (`trustyai-explainability/guardrails-detectors`)

Source: `odh-model-controller/config/runtimes/hf-detector-template.yaml`;
[trustyai-explainability/guardrails-detectors](https://github.com/trustyai-explainability/guardrails-detectors)

### Testing Patterns (Current State)

#### Shift 1: Fuzzy Validation Replaces Snapshot Comparison

| Aspect | Legacy (removed) | Current |
|--------|-----------------|---------|
| Method | `assert response == response_snapshot` (syrupy) | `validate_text_inference_fuzzy()` |
| Failure mode | Breaks across GPU types (FP precision) | Hardware-independent keyword matching |
| Maintenance | Snapshot files need regeneration per HW | Zero maintenance |
| PR | - | #1667 (amehtaja), #1641 |
| Applied to | - | vLLM (all suites) |
| Not yet applied | - | OVMS, MLServer, Triton (still use top-k) |

The 7-step fuzzy validation pipeline:
1. **Schema validation** — OpenAI response format with `choices[].message.content`
2. **Non-emptiness** — minimum 3 words in response content
3. **Content quality** — regex for 2+ char alphabetic words, 30%+ alpha character ratio
4. **Error detection** — regex scan for traceback, CUDA OOM, segfault, NaN indicators
5. **Repetition detection** — 4-gram phrase analysis, max 3 repeats allowed
6. **Keyword matching** — at least one expected keyword from query definition found in response
7. **Model info validation** — `/v1/models` returns list of dicts with `id` and `object` fields

For predictive runtimes (OVMS, MLServer, Triton), the pattern is top-k classification with PR #1720 improvements:
- `top_k = min(5, len(actual_data))` — flexible instead of hardcoded 5
- `isinstance()` type-safety assertions before field access
- `rawOutputContents` detection for gRPC binary responses

Source: PR #1667, PR #1720 (amehtaja); `tests/model_serving/model_runtime/utils.py`

#### Shift 2: External Routes Replace Port-Forwarding

| Aspect | Legacy (removed) | Current |
|--------|-----------------|---------|
| Access method | `portforward.forward(pod, ns, port, port)` | `get_exposed_isvc_url(isvc)` → Route URL |
| Realism | Pod-level (not enterprise) | Route-level (matches customer deployment) |
| Dependency | Pod name lookup, port management | ISVC `status.url` field |
| PR | - | #1713 (Raghul-M) |
| Applied to | - | vLLM (all suites) |
| Not yet applied | - | Triton (migration pending), OVMS, MLServer |

The new pattern requires `external_route: True` in InferenceService fixture parameters.
ODH Model Controller creates the OpenShift Route, and `status.url` is populated.
`get_exposed_isvc_url(isvc)` reads this field and returns the base URL for inference.

**Shared utility — does not determine test ownership.** `get_exposed_isvc_url()` lives in `utilities/inference_utils.py` and is used by both Model Runtimes tests (`model_runtime/`) and Platform/KServe tests (`model_server/kserve/`). PR #1713 was contributed by Model Runtimes but the utility is shared infrastructure. Test ownership is determined solely by the test directory: tests under `model_server/kserve/` belong to Platform/KServe, tests under `model_runtime/` belong to Model Runtimes. Importing `get_exposed_isvc_url()` or any other shared utility does not change ownership.

Source: PR #1713; `utilities/inference_utils.py` `get_exposed_isvc_url()` implementation

#### Shift 3: Probe Testing as First-Class Concern

New `vllm/probes/` suite (PR #1704, Raghul-M) validates readiness and liveness probes:

| Probe | Path | Port | Initial Delay | Period | Timeout | Failure Threshold |
|-------|------|------|---------------|--------|---------|-------------------|
| Readiness | `/health` | 8080 | 120s | 10s | 10s | 12 |
| Liveness | `/health` | 8080 | 180s | 30s | 10s | 10 |

Test methodology:
1. `ServingRuntimeFromTemplate` `containers` kwarg injects `httpGet` probes onto `kserve-container`
2. Verify pod reaches `Ready` state
3. Verify probe spec exists in pod spec (`readinessProbe.httpGet`, `livenessProbe.httpGet`)
4. Execute in-pod `curl` to probe endpoint, assert HTTP 200
5. Verify zero container restarts (no premature restarts during model loading)

Source: PR #1704; `tests/model_serving/model_runtime/vllm/probes/utils.py`

#### Shift 4: gRPC Response Handling (PR #1720)

gRPC inference responses can contain data in two formats:
- `rawOutputContents` / `raw_output_contents` — base64-encoded binary (Triton, OVMS gRPC)
- `outputs[].data` — float array (REST, some gRPC implementations)

Tests now detect and handle both:
```
if "rawOutputContents" in response or "raw_output_contents" in response:
    raw_contents = response.get("rawOutputContents") or response.get("raw_output_contents")
    assert raw_contents  # binary data present = valid response
    return  # skip top-k comparison (binary not directly comparable)
```

Source: PR #1720 (amehtaja); `tests/model_serving/model_runtime/triton/basic_model_deployment/utils.py`

#### Shift 5: vLLM Refactored to RHOAI Integration Only (PR #1679)

The vLLM test suite was completely restructured to remove RHAII-scope tests:

| Removed (RHAII scope) | Retained (Model Runtimes scope) |
|----------------------|--------------------------------|
| `basic_model_deployment/` (TGIS, multi-model) | `s3/` — S3 storage backend |
| `multimodal/` (Granite Vision) | `modelcar/` — OCI modelcar storage |
| `quantization/` (AWQ) | `pvc/` — PVC storage backend |
| `speculative_decoding/` | `probes/` — health probe validation |
| `toolcalling/` | `cpu/` — CPU variant testing |
| Serverless deployment tests | All use RawDeployment only |
| Legacy `__snapshots__/` files | Fuzzy validation (no snapshots) |

Source: PR #1679 (Raghul-M); current `tests/model_serving/model_runtime/vllm/` directory structure

#### Shift 6: CPU Variant Support (PR #1723)

New accelerator types added for CPU-only deployments:

| Variant | Marker | Key Env Vars | Resources |
|---------|--------|-------------|-----------|
| x86 | `vllm_cpu_x86` | `VLLM_CPU_KVCACHE_SPACE=4`, `OMP_NUM_THREADS=8`, `VLLM_WORKER_MULTIPROC_METHOD=spawn` | 8-16 CPU, 10-16Gi mem |
| IBM Power | `vllm_cpu_power` | bfloat16 dtype args | 12 CPU, 64Gi mem |
| IBM Z | `vllm_cpu_z` | bfloat16 dtype args | 12 CPU, 64Gi mem |

Source: PR #1723 (Raghul-M); `tests/model_serving/model_runtime/vllm/cpu/`

#### Shift 7: PVC Storage Tests Across All Runtimes (PRs #1897, #1898, #1931)

PVC storage backend coverage expanded from vLLM-only to all runtimes:

| Runtime | PVC Test Suite | PR |
|---------|---------------|-----|
| vLLM | `vllm/pvc/` (existing) | Pre-existing |
| MLServer | `mlserver/pvc/` | #1897 |
| OVMS | `openvino/pvc/` | #1898 |
| Triton | `triton/pvc/` | #1931 |

This establishes PVC as a first-class storage backend validated across all established runtimes
(vLLM, MLServer, OVMS, Triton). AutoGluon and Guardrails HF do not yet have PVC test coverage.

Source: PRs #1897, #1898, #1931

#### Shift 8: Accelerator-Specific Markers (PR #2117)

GPU test markers refined from generic `gpu` to accelerator-specific:

| Old Marker | New Markers |
|-----------|-------------|
| `vllm_gpu` (generic) | `vllm_nvidia` (NVIDIA GPU), `vllm_amd` (AMD GPU) |

This enables selective test execution per GPU vendor and prevents AMD tests from running on
NVIDIA-only clusters (and vice versa).

Source: PR #2117; `tests/model_serving/model_runtime/vllm/conftest.py`

### Dependencies Correction

**RHAISTRAT-1868 incorrectly identifies dependencies on Dashboard and Platform teams for GPU support.**
The actual mechanism requires NO code changes from these teams:

| Mechanism | How It Works | Who Changes It |
|-----------|-------------|----------------|
| Template discovery | Annotation-driven: `opendatahub.io/dashboard: "true"`, `opendatahub.io/ootb: "true"` | No one — Dashboard reads annotations automatically |
| Template deployment | Kustomize overlay in `odh-model-controller/config/runtimes/` | Model Runtimes (add YAML + kustomization entry) |
| GPU injection | HardwareProfile webhook on `rhods-operator` | No one — webhook injects GPU limits automatically |
| Route creation | ODH Model Controller watches ISVC with `external_route` annotation | No one — controller reconciles automatically |
| Image shipping | CSV `relatedImages` in operator bundle | Release Engineering (bundle build pipeline) |

To add a new out-of-the-box runtime template:
1. Create YAML file in `odh-model-controller/config/runtimes/` with annotations
2. Add to `kustomization.yaml` in the same directory
3. Add image to operator CSV `relatedImages`
4. Done — Dashboard discovers automatically, HardwareProfile handles GPU

Source: `odh-model-controller/config/runtimes/kustomization.yaml`; Dashboard annotation scanning logic

### Test Infrastructure

| Fixture / Option | Purpose | Source File |
|-----------------|---------|-------------|
| `--vllm-runtime-image` / `VLLM_RUNTIME_IMAGE` | Override vLLM container image for CI | `conftest.py` (root) |
| `--ovms-runtime-image` / `OVMS_RUNTIME_IMAGE` | Override OVMS container image for CI | `conftest.py` (root) |
| `--mlserver-runtime-image` / `MLSERVER_RUNTIME_IMAGE` | Override MLServer container image for CI | `conftest.py` (root) |
| `--triton-runtime-image` / `TRITON_RUNTIME_IMAGE` | Override Triton container image for CI | `conftest.py` (root) |
| `--supported-accelerator-type` / `SUPPORTED_ACCELERATOR_TYPE` | Target: nvidia, amd, gaudi, spyre, cpu_x86, cpu_power, cpu_z | `conftest.py` (root) |
| `ServingRuntimeFromTemplate` | Instantiate namespace-scoped SR from platform template | `utilities/serving_runtime.py` |
| `create_isvc()` | Create InferenceService (external_route, deployment_mode, resources, probes, replicas) | `utilities/inference_utils.py` |
| `get_exposed_isvc_url()` | Extract external route URL from ISVC `status.url` | `utilities/inference_utils.py` |
| `skip_if_no_supported_accelerator_type` | Skip test if cluster lacks required accelerator | `conftest.py` markers |
| `valid_aws_config` | Skip test if S3 credentials not configured | `conftest.py` markers |
| `kserve_health_check` | Gate tests on KServe + ODH MC deployment health | `model_server/kserve/conftest.py` |

### Key Test Utilities (Signatures)

```
ServingRuntimeFromTemplate(
    client, name, namespace, template_name, deployment_type,
    runtime_image=None, containers=None  # containers kwarg for probe injection
)

create_isvc(
    client, name, namespace, runtime, storage_uri, model_format,
    model_service_account=None, deployment_mode=KServeDeploymentType.RAW_DEPLOYMENT,
    external_route=True, resources=None, gpu_count=0, model_env_variables=None
)

get_exposed_isvc_url(isvc) -> str  # Returns "https://<route-host>"

validate_text_inference_fuzzy(
    completion_responses, queries, model_info,
    require_keywords=False, allow_empty_responses=True, min_valid_responses=1
)
```

Source: `utilities/serving_runtime.py`, `utilities/inference_utils.py`, `tests/model_serving/model_runtime/utils.py`

## Impact on Strategies

### Dependency Corrections (Source: RHAISTRAT-1868 analysis, odh-model-controller architecture)

- **FALSE**: "Dashboard team needs code changes for new runtime templates"
  - TRUTH: Dashboard discovers runtimes via annotations; zero code changes needed
  - Source: Dashboard annotation scanning in `odh-dashboard/backend/`

- **FALSE**: "Platform team delivers HardwareProfile changes for new runtimes"
  - TRUTH: HardwareProfile webhook is generic; it works with ANY runtime automatically
  - Source: `rhods-operator` webhook implementation

- **FALSE**: "OVMS supports NVIDIA GPU via CUDA plugin"
  - TRUTH: CUDA plugin is deprecated in RHOAI 3.4; OVMS is Intel GPU only going forward
  - Source: OVMS 2024.5+ release notes; `opendatahub-io/openvino_model_server` build config

### Scope Boundaries (Source: PR #1679, RHAII team structure)

- Strategies proposing vLLM engine features (multimodal, tool calling, speculative decoding, quantization) as
  Model Runtimes deliverables are **out of scope** — these are RHAII responsibility
- Model Runtimes vLLM scope is limited to: operator integration (deploy, serve, probe, storage, routes, variants)

### MLServer Risk (Source: SeldonIO/MLServer repo analysis, Seldon company liquidation)

- Strategies involving MLServer enhancements must account for zero upstream community support
- ALL patches (AMD arch, ONNX, security fixes) are carried solely by Model Runtimes team
- Long-term MLServer roadmap is entirely Red Hat's decision with no community input

### Triton Scope (Source: opendatahub-tests/triton/ test matrix)

- Triton support is bounded by the 7x2 validation matrix (7 formats, 2 protocols)
- Features outside this matrix (dynamic batching, BLS, custom backends, model ensembles beyond tested patterns)
  are NOT part of the Tested & Verified designation
- TensorFlow backend has limited shelf life (deprecated and removed from 25.03 onward) — the 25.02 pin is a deliberate test-matrix constraint, not a platform shipping decision. No CVE tracking applies to the NVIDIA-managed vendor image

### Testing Modernization (Source: PRs #1667, #1713, #1704, #1720)

- New strategies should mandate: external routes (not port-forward), fuzzy validation (not snapshots),
  probe testing (readiness + liveness), type-safe assertions
- Triton migration to external routes is a pending modernization item
- OVMS/MLServer may adopt fuzzy validation for cross-hardware GPU testing

### AIPCC Base Image Architecture (Serving Runtimes)

RHOAI serving runtime container images are built on top of **AIPCC (AI Platform Common Components)** base images. These bases determine the hardware capability ceiling of every image built on them. All Python dependencies must be sourced from the AIPCC pip index — **no direct pypi.org access is available in hermetic builds**.

#### Base Image Variants

| Base Image | Contents | Purpose | GPU Drivers |
|---|---|---|---|
| `aipcc/cpu` | Python runtime, OS packages, no CUDA | CPU-only inference (predictive + LLM CPU variants) | None |
| `aipcc/cuda` | Python runtime, OS packages, CUDA toolkit + `libcudart.so` | NVIDIA GPU inference | CUDA runtime libraries included |
| `aipcc/rocm` *(future)* | Python runtime, OS packages, ROCm toolkit | AMD GPU inference (not yet used for predictive runtimes) | ROCm runtime libraries |

**Architecture support:** AIPCC base images support multiple CPU architectures:

| Architecture | Status | Example Use |
|-------------|--------|-------------|
| x86_64 | GA | All current serving runtimes |
| aarch64/ARM | Available | NVIDIA Rubin (Vera Rubin GPU architecture) |
| ppc64le | Available | IBM Power vLLM CPU variant |
| s390x | Available | IBM Z vLLM CPU variant, IBM Spyre s390x |

Source: AIPCC fondue configuration; RHAISTRAT-1486 Rubin onboarding analysis

#### Key Architectural Constraints

- **Mutually exclusive bases** — `aipcc/cpu` and `aipcc/cuda` are separate, non-interchangeable base images. You **cannot** pip-install GPU support into a CPU base. The CUDA runtime libraries (`libcudart.so`, `libcublas.so`, etc.) are system-level shared objects that must exist in the base image.

- **Separate image pattern** — If a runtime needs GPU acceleration, it needs a **separate image** built on `aipcc/cuda`. This is the same pattern vLLM follows: `vllm-cuda-runtime` is a distinct image from any CPU variant. MLServer GPU (ONNX) must follow the same pattern.

- **Image size implications** — CUDA toolkit adds approximately 500MB–1GB to the image. Hybrid images (shipping both CPU and CUDA in one image) are **NOT acceptable** for air-gapped/disconnected deployments where image pull size is a hard constraint.

- **ROCm for predictive runtimes** — If AMD GPU acceleration is needed for predictive runtimes in the future, a new `aipcc/rocm` base would be required. This is not currently planned for MLServer or OVMS.

- **Hermetic build mandate** — All Python packages must be built and served from the AIPCC pip index with SHA256-pinned hashes. No `pip install` from pypi.org at build time. This is a security directive, not a preference.

#### AIPCC Package Onboarding Process

New Python dependencies require AIPCC onboarding before they can be consumed in any serving runtime image. This is a **1–3 week lead time** with the following steps:

1. Self-service pipeline submission (package request Jira ticket in AIPCC project)
2. Builder onboarding (AIPCC team configures source resolver)
3. Probe tests and build verification (AutoQA across all architecture variants)
4. Pipeline integration and QE validation
5. Production promotion

**Strategies proposing new Python dependencies MUST factor in this lead time.** It is not possible to "just add" a package at development time.

Source: AIPCC onboarding process; RHOAIENG-37768 (MLServer full integration journey); AIPCC-18708 (kserve-storage onboarding example).

#### Runtime-Specific AIPCC Status

| Runtime | Base Image | Hermetic Build Status | Automation | Notes |
|---|---|---|---|---|
| MLServer | `quay.io/aipcc/base-images/cpu` | **GA — fully hermetic** | Renovate auto-tracks base image; GitHub Actions generates hash-pinned requirements.txt | All 5 plugins (mlserver, lightgbm, onnx, sklearn, xgboost) onboarded |
| OVMS | UBI9 + upstream Bazel build | **Not hermetic** — Bazel + TF dependency incompatible with Konflux model | None (non-hermetic today) | Hermetic build pending upstream TensorFlow removal from OpenVINO |
| vLLM (all variants) | RHAIIS build (AIPCC infrastructure) | **GA** — built by AIPCC/RHAIIS team | RHOAI consumes via image override in operator CSV | RHOAI does **NOT** build vLLM images; they are consumed from `registry.redhat.io/rhaii/<image>` |
| KServe Storage Initializer | AIPCC base (in progress) | **In progress** | Packages in review (kserve-storage, hdfs, krbcontext, requests-kerberos) | modelscope has security audit concerns |

Source: RHOAIENG-67702 (OVMS hermetic build tracker); RHOAIENG-37768 (MLServer AIPCC integration); RHOAIENG-52861 (Renovate); RHOAIENG-66923 (vLLM consumption).

#### vLLM Image Consumption Model

RHOAI **does not build** vLLM images. All vLLM runtime images are built by the RHAIIS team using AIPCC infrastructure and consumed by RHOAI through image reference overrides in the operator CSV.

| Variant | Registry Path | Status |
|---|---|---|
| vLLM CUDA | `registry.redhat.io/rhaii/odh-vllm-rhel9` | GA |
| vLLM ROCm | `registry.redhat.io/rhaii/odh-vllm-rocm-rhel9` | GA |
| vLLM Spyre | `registry.redhat.io/rhaii/odh-vllm-spyre-rhel9` | GA (x86, s390x, ppc64le) |
| vLLM CPU | `registry.redhat.io/rhaii/odh-vllm-cpu-rhel9` | Tech Preview |
| vLLM Gaudi | `registry.redhat.io/rhaii/odh-vllm-gaudi-rhel9` | GA |
| vLLM-Omni | AIPCC base + Konflux | Dev Preview (multi-modal) |

Source: RHOAIENG-66923; RHOAIENG-53009; RHOAIENG-52392.

#### Anti-Patterns for Strategy Generation

Strategies MUST NOT propose:

| Anti-Pattern | Why It Fails |
|---|---|
| `pip install <package>` from pypi.org | Hermetic builds have no internet access; all wheels must come from AIPCC index |
| "Build vLLM from source" or "customize vLLM image" | vLLM images are consumed from RHAIIS; RHOAI has no vLLM build pipeline |
| "Use upstream OVMS directly" | Must use `odh-openvino-model-server` with Red Hat patches and (eventually) AIPCC dependencies |
| "Switch base image to Ubuntu/Alpine/custom" | All serving runtime base images must come from AIPCC or UBI per security directive |
| "Add new Python dependency" without AIPCC lead time | Onboarding takes 1–3 weeks; strategies must account for this in timeline |
| "Use OVMS hermetic build" today | OVMS hermetic build is **not yet available** — Bazel + TensorFlow dependency prevents Konflux hermetic model |

Source: AIPCC hermetic build mandate; security directive 2026; RHOAIENG-67702.

#### When a New Konflux Pipeline Is Required

| Scenario | New Konflux Pipeline? | Rationale |
|---|---|---|
| New image on a different base (e.g., `mlserver-onnx-gpu` on `aipcc/cuda`) | **Yes** | Different base image = different build pipeline |
| New architecture variant of existing image (e.g., ppc64le build) | **Yes** | Different build target architecture |
| Adding a Python package to an existing image on same base | No | Modify existing Dockerfile/pipeline |
| Updating base image version (e.g., `aipcc/cpu:3.4` → `aipcc/cpu:3.5`) | No | Existing pipeline, updated FROM |
| Adding a new model format backend to existing runtime | No | Same image, same base, same pipeline |

Source: AIPCC base image specification; Konflux pipeline architecture; vLLM multi-image pattern.

### Platform Constraints

#### Container Base / Host OS Decoupling

RHOAI serving runtime containers are built on **RHEL 9** base images (UBI9 or AIPCC/UBI9).
Starting with OCP 4.19, these containers run on **RHEL 10** worker nodes. The application stack
does NOT require a RHEL 10 rebuild — RHEL 9 userspace in containers runs on RHEL 10 kernel via
standard OCI compatibility.

**Impact on runtimes:** Any runtime that depends on host-level kernel features or GPU operator
behavior (e.g., NVIDIA GPU operator, Intel GPU operator) must validate that the operator functions
correctly on RHEL 10 nodes with RHEL 9 containers. This is a validation concern, not a rebuild
requirement.

Source: RHAISTRAT-1486 (RHAII for Rubin analysis); OCP 4.19 RHEL 10 transition

### Cross-Team Dependency Decision Matrix

This matrix defines, for each Model Runtimes action, whether other teams require PRs or code changes. Use this when writing or reviewing strategies to identify true dependencies.

| Model Runtimes Action | Dashboard Team | KServe/Platform Team | ODH Model Controller Team | Release Engineering |
|---|---|---|---|---|
| Add new ClusterServingRuntime template | No (annotation discovery) | No | No (auto-detected) | No |
| Add GPU variant of existing runtime | No | No (HardwareProfile is generic) | No | Yes (new Konflux pipeline if new base image) |
| Enable multi-model serving on a runtime | No (template auto-appears) | No (KServe is model-count agnostic) | No (V2 path routing is passthrough) | No |
| Add new model format to existing runtime | No | No | No | No (same image) |
| Change inference protocol (v1→v2) | Maybe (protocol display) | No | No | No |
| Add new storage backend type | No | Maybe (if new storage initializer needed) | Maybe (Connection API extension) | No |
| Add new autoscaling pattern | No | No | Yes (KEDA ScaledObject type) | No |
| Add OOTB template for vendor runtime | No | No | No | Yes (CSV `relatedImages` entry) |
| Ship new image (new accelerator) | No | No | No | Yes (new Konflux pipeline) |
| Add new Python dependency to runtime | No | No | No | **Yes** (AIPCC onboarding: 1–3 weeks lead time) |

#### Explanatory Notes

- **"No" means zero PRs needed** from that team — the action is fully self-contained within Model Runtimes (or Model Runtimes + Release Engineering).
- **Dashboard discovers runtimes via annotation** — the `opendatahub.io/dashboard: "true"` annotation on a ServingRuntime/ClusterServingRuntime template causes it to appear in the Dashboard UI automatically. No Dashboard code changes are needed.
- **HardwareProfile webhook is generic** — it injects GPU resource limits (`nvidia.com/gpu`, `amd.com/gpu`, etc.) based on the user's HardwareProfile selection. It works with ANY runtime without per-runtime configuration. Adding a new GPU-enabled runtime template does **not** require HardwareProfile changes.
- **KServe controller is model-count agnostic** — it manages the Deployment/Service/Route lifecycle for an InferenceService. It does not inspect or care how many models are loaded inside the container. Multi-model is transparent to KServe.
- **ODH Model Controller V2 path routing passes through** — request routing to the runtime container does not inspect model count. Multi-model path routing (e.g., `/v2/models/{name}/infer`) is handled by the runtime itself (e.g., MLServer repository mode), not the controller.
- **AIPCC/Release Engineering lead time** — Adding a new Python dependency is NOT instant. Package onboarding (1–3 weeks) involves builder setup, probe testing across all architecture variants, QE validation, and production promotion. Strategies must account for this in their timelines.

Source: `odh-model-controller/architecture.md`; Dashboard annotation scanning logic; `rhods-operator` HardwareProfile webhook; KServe controller InferenceService reconciliation; AIPCC onboarding process.

### KServe Deprecation & Multi-Model Landscape

Critical context for any strategy involving multi-model serving, TrainedModel CRD, kserve-agent, ModelMesh, or deployment mode selection.

#### KServe Community Health

| Attribute | Value |
|---|---|
| CNCF Maturity | **Incubating** (accepted September 2025) |
| Health Score (LFX) | **82/100 (Excellent)** |
| GitHub Stars | 5,575 (+31% YoY) |
| Total Contributors | 350+ (+29% YoY) |
| Contributing Organizations | 610 (+39% YoY) |
| Total Releases | 56 (accelerating) |

**Red Hat is the largest single-company contributor:** 6 of 16 maintainers (including 1 Project Lead: Yuan Tang, 1 Approver: Jooho Lee, 4 Reviewers). This gives Red Hat strongest single-company influence on upstream direction — relevant for strategy feasibility when proposing features that need upstream changes.

Source: https://github.com/kserve/kserve/blob/master/MAINTAINERS.md; https://www.cncf.io/projects/kserve/

#### KServe Release Cadence (Accelerating)

| Version | Date | Cycle | Theme |
|---|---|---|---|
| v0.19.0 | 2026-06-14 | ~6 weeks | LLMInferenceService maturation |
| v0.18.0 | 2026-04-29 | ~6 weeks | LoRA reconciliation, autoscaling |
| v0.17.0 | 2026-03-13 | ~4.5 months | LLMInferenceService webhook |
| v0.16.0 | 2025-11-03 | ~5 months | LLMInferenceService CRD introduction |
| v0.15.0 | 2025-05-27 | ~5 months | GenAI serving, model caching |

**6 releases in 7 months** (v0.15 → v0.19). Cadence accelerated from ~5 months to ~6 weeks, driven by rapid LLMInferenceService development.

Source: https://github.com/kserve/kserve/releases

#### TrainedModel CRD — **DO NOT USE**

| Attribute | Value |
|---|---|
| API | `serving.kserve.io/v1alpha1` — stuck at alpha since 2021 |
| Last meaningful code change | PR [#3758](https://github.com/kserve/kserve/pull/3758) — bug fix only, no feature work |
| Active development | **None** — maintainer confirmed: "no active development on TrainedModel" |
| Upstream roadmap | Explicitly states: *"Deprecate TrainedModel CRD"* |
| RHOAI integration | ZERO references in `odh-model-controller`, `odh-dashboard`, or `rhods-operator` |
| RawDeployment mode | TrainedModel reconciliation is **NOT functional** |
| Open issues (unresolved since 2021) | [#1589](https://github.com/kserve/kserve/issues/1589), [#1575](https://github.com/kserve/kserve/issues/1575) |

The replacement is NOT a single new CRD but rather integrating multi-model capabilities directly into InferenceService and LLMInferenceService:

| Use Case | Old (TrainedModel) | New Approach |
|---|---|---|
| Multiple models on one GPU | TrainedModel + kserve-agent | LLMInferenceService with LoRA adapters |
| Dynamic model loading | TrainedModel controller | Not yet implemented for InferenceService |
| High-density model serving | TrainedModel + ModelMesh | No direct replacement (ModelMesh **ARCHIVED**) |

Source: https://github.com/kserve/kserve/blob/master/ROADMAP.md; PR #3758 maintainer comment; KServe GitHub issues.

#### ModelMesh — **ARCHIVED**

| Attribute | Value |
|---|---|
| Upstream status | **Archived** (kserve/modelmesh repository) |
| Archive date | **February 2025** |
| Removed from KServe Helm chart | PR [#4243](https://github.com/kserve/kserve/pull/4243), merged 2025-02-16 |
| Reason | "ModelMesh is no longer actively developed" — maintainer confirmed "maintenance mode" |
| RHOAI status | **Deprecated since RHOAI 2.19**; removal required for RHOAI 3.x upgrade |
| Migration path | ModelMesh → Standard (RawDeployment) mode |
| ODH fork | [opendatahub-io/modelmesh-serving](https://github.com/opendatahub-io/modelmesh-serving) — some continued work, but no upstream maintainer engagement |

**Do NOT propose ModelMesh as an alternative for any serving strategy.** It is archived upstream with no path to revival.

Source: https://github.com/kserve/kserve/pull/4243; https://github.com/kserve/modelmesh; https://github.com/kserve/modelmesh-serving/issues/542

#### kserve-agent Sidecar — **NOT Compatible with RHOAI**

- `kserve-agent` imports `knative.dev/serving/pkg/queue` — a Knative Serving library dependency
- Injection is triggered by TrainedModel CRs in **Serverless mode only**
- RHOAI uses RawDeployment exclusively → kserve-agent injection preconditions are **never met**
- Not validated, not tested, not supported in RHOAI

Source: `kserve-agent` source code import analysis; RHOAI RawDeployment-only architecture.

#### LLMInferenceService — Strategic Future (v0.16 → v0.19)

LLMInferenceService is the purpose-built CRD for GenAI workloads, under rapid active development:

| Feature | Version Introduced | Status |
|---|---|---|
| LLMInferenceService CRD | v0.16 (Nov 2025) | GA-quality in v0.18+ |
| LoRA adapter support | v0.16, matured v0.18+ | **Implemented** — per-request adapter selection with ~1-5ms overhead |
| Disaggregated prefill/decode | v0.17+ | Active development |
| Multi-node inference (LWS-based) | v0.16+ | **Implemented** |
| Endpoint Picker (EPP) / intelligent routing | v0.17+ | **Implemented** |
| KV-cache offloading | v0.18+ | Active development |
| llm-d integration | v0.18+ | Active development (Red Hat co-lead) |

**Key insight:** Multi-model for LLMs is solved via LoRA adapters in LLMInferenceService. TrainedModel-style approaches are obsolete for LLM use cases.

Source: https://kserve.github.io/website/docs/next/concepts/architecture/control-plane-llmisvc; https://github.com/kserve/kserve/releases

#### InferenceGraph — **Alpha, No Graduation Timeline**

| Attribute | Value |
|---|---|
| API Version | `serving.kserve.io/v1alpha1` |
| Maturity | **Alpha** — not recommended for production |
| Router Types | Sequence, Switch, Ensemble, Splitter |
| RawDeployment support | Added v0.16 (previously Serverless-only) |
| Graduation timeline | **None committed** — "Graduate InferenceGraph" is a roadmap objective with all items "Planned" |

Planned but not implemented: replica/concurrency control, distributed tracing, gRPC support, standalone Transformer, traffic mirroring.

Source: https://github.com/kserve/kserve/blob/master/ROADMAP.md (Objective 4); https://kserve.github.io/website/docs/next/model-serving/inferencegraph/overview

#### RawDeployment (Standard Mode) Limitations

RHOAI uses RawDeployment exclusively. The following features are **Serverless-only** and **NOT available** in RHOAI:

| Feature | Serverless (Knative) | Standard (RawDeployment) | Why |
|---|---|---|---|
| **Scale-to-zero** | Yes | **Not supported** | Requires Knative Activator to buffer requests and wake pods |
| **Scale-from-zero** | Yes | Not supported | Requires Knative queue proxy first-request detection |
| **Request-based autoscaling** (RPS/concurrency) | Yes (KPA) | Only CPU/Memory HPA | KPA tracks per-pod concurrency via queue proxy |
| **Revision-based rollback** | Yes | Not supported | Knative maintains immutable revisions; Standard uses regular Deployments |
| **Request queuing** | Yes (Queue proxy) | Not available | Requests dropped if pods aren't ready |
| **Concurrency limiting** | Yes (containerConcurrency) | Not available | No queue proxy sidecar |
| **Canary traffic splitting** | Yes | Added v0.16 (Gateway API) | Functional but newer, less mature |

**RawDeployment advantages:** No cold start, multiple volume mounts, simpler networking (no Istio), lower resource overhead, better for GPU workloads.

Source: https://kserve.github.io/website/docs/install/dependencies; https://kserve.github.io/website/docs/concepts/architecture/control-plane

#### Correct Multi-Model Path for RHOAI (Predictive Workloads)

- MLServer ships with built-in repository mode (`SchemalessModelRepository`)
- `multiModel: true` in ServingRuntime spec enables multi-model at KServe level
- **V2 Repository API**: `POST /v2/repository/models/{name}/load|unload` for dynamic model management
- **Shared PVC** (`pvc://`) is a KServe-native storage scheme — no custom storage initializer needed
- **No kserve-agent, no TrainedModel CRD, no Platform/KServe controller changes** — template-only change
- Dashboard annotations: `opendatahub.io/modelServingSupport: '["multi"]'`
- Template auto-appears in Dashboard via annotation discovery (no Dashboard code changes)
- Triton also natively supports multi-model via its model repository when deployed as a custom ServingRuntime

Source: MLServer `SchemalessModelRepository` implementation; KServe `multiModel` spec field; V2 inference protocol specification; RHAISTRAT-2011 analysis.

### Serving Runtime Template Catalog (Existing + Planned)

Comprehensive reference of all RHOAI serving runtime templates — both existing and planned.

| Template Name | Runtime | Accelerator | Model Formats | Multi-Model | Image Base | Status |
|---|---|---|---|---|---|---|
| `ovms-kserve-template` | OVMS | Intel GPU / CPU | OpenVINO IR, ONNX, TF SavedModel, PaddlePaddle, PyTorch | No | `aipcc/cpu` | Existing |
| `mlserver-template` | MLServer | CPU only | LightGBM, ONNX, Sklearn, XGBoost | No (current) | `aipcc/cpu` | Existing |
| `mlserver-cuda-runtime-template` | MLServer | NVIDIA GPU | LightGBM, ONNX, Sklearn, XGBoost | No | `aipcc/cuda` | Existing (PR #873) |
| `mlserver-multi-model-template` | MLServer | CPU only | Same as above | **Yes** (repository mode) | `aipcc/cpu` | **Planned** |
| `autogluon-runtime-template` | AutoGluon | CPU only | AutoGluon (tabular, time series) | No | `aipcc/cpu` | Existing (3.5 GA, pending RHOAIENG-82069) |
| `guardrails-detector-huggingface-serving-template` | Guardrails HF | NVIDIA GPU | HF SequenceClassification | No | `aipcc/cpu` | Existing |
| `vllm-cuda-runtime-template` | vLLM | NVIDIA GPU | LLM (all vLLM-supported) | N/A (LLM) | `aipcc/cuda` | Existing |
| `vllm-rocm-runtime-template` | vLLM | AMD GPU | LLM | N/A | RHAII ROCm base | Existing |
| `vllm-gaudi-runtime-template` | vLLM | Intel Gaudi | LLM | N/A | RHAII Gaudi base | Existing |
| `vllm-multinode-runtime-template` | vLLM | Multi-node (LWS) | LLM | N/A | RHAII CUDA base | Existing |
| `vllm-spyre-x86-runtime-template` | vLLM | IBM Spyre (x86) | LLM | N/A | IBM Spyre base | Existing |
| `vllm-spyre-s390x-runtime-template` | vLLM | IBM Spyre (s390x) | LLM | N/A | IBM Spyre base | Existing |
| `vllm-spyre-ppc64le-runtime-template` | vLLM | IBM Spyre (ppc64le) | LLM | N/A | IBM Spyre base | Existing |
| `vllm-cpu-runtime-template` | vLLM | CPU (generic) | LLM | N/A | IBM CPU base | Existing |
| `vllm-cpu-x86-runtime-template` | vLLM | x86 CPU | LLM | N/A | IBM CPU base | Existing |
| *(none — custom CR)* | Triton | NVIDIA GPU | TensorRT, TF, ONNX, PyTorch, XGBoost, Python, FIL, DALI, Keras | **Yes (native)** — model repository with dynamic load/unload | NVIDIA vendor | N/A (not shipped) |

Additionally, three ClusterServingRuntime templates exist in `config/runtimes/` for Phase 1 CSR
support: `csr-kserve-vllm-v1.yaml`, `csr-kserve-mlserver-v1.yaml`, `csr-kserve-ovms-v1.yaml`.
These are not yet active — CSR is currently disabled in ODH/RHOAI.

#### Template Catalog Notes

- **"Planned" templates** are tracked in RHAISTRAT-1868 (GPU) and RHAISTRAT-2011 (multi-model).
- Template YAML lives in `odh-model-controller/config/runtimes/`.
- Each template requires: name, annotations (`opendatahub.io/dashboard`, `opendatahub.io/ootb`, `opendatahub.io/apiProtocol`), container spec, supported model formats, protocol versions.
- Adding a template is a **Model Runtimes-only operation** — see Cross-Team Dependency Decision Matrix above.
- Triton is Tested & Verified only; it has no platform template and is not shipped via `relatedImages`. However, Triton **natively supports multi-model** via its model repository — customers deploying Triton as a custom runtime can load multiple models. Red Hat supports the deployment/integration layer for this use case.
- AutoGluon is the first new OOTB predictive runtime since the original trio (OVMS, MLServer, vLLM). It is a first-party upstream KServe runtime ([PR #5269](https://github.com/kserve/kserve/pull/5269)). Model Runtimes scope is template-only — AutoML team owns the image, CVEs, tests, and all feature work (see AutoGluon RACI section above).
- Guardrails Detector HF is owned by the TrustyAI team, not Model Runtimes. It uses a distinct server architecture (uvicorn on port 8000) and is classified as a predictive model type for Dashboard purposes.
- The old `vllm-cpu-power-runtime-template` and `vllm-cpu-z-runtime-template` have been replaced by IBM Spyre-specific templates (`vllm-spyre-ppc64le`, `vllm-spyre-s390x`). CPU generic and CPU x86 remain.

Source: `odh-model-controller/config/runtimes/`; RHAISTRAT-1868; RHAISTRAT-2011; RHOAIENG-63920.

## Impact on Strategies — Additional Corrections

These supplement the dependency corrections and scope boundaries above.

**FALSE**: "Multi-model serving requires TrainedModel CRD and kserve-agent"
- **TRUTH**: TrainedModel is on upstream deprecation path (no active development since 2021, stuck at alpha); kserve-agent requires Knative (not available in RHOAI RawDeployment). Use MLServer repository mode instead.
- Source: KServe ROADMAP.md; kserve-agent source code imports; PR #3758 maintainer confirmation.

**FALSE**: "GPU support can be added via package swap in existing CPU container image"
- **TRUTH**: CPU base image (`aipcc/cpu`) does not include CUDA runtime libraries. A separate image on `aipcc/cuda` base is required. `onnxruntime-gpu` will crash with `OSError: libcudart.so.12: cannot open shared object file` on a CPU base.
- Source: AIPCC base image specification; `onnxruntime-gpu` runtime dependency on `libcudart.so`.

**FALSE**: "KServe/Platform team work is needed for multi-model support"
- **TRUTH**: KServe controller is model-count agnostic. It manages Deployment lifecycle without inspecting the model count inside the container. Multi-model is transparent to KServe.
- Source: KServe controller source; InferenceService reconciliation does not reference model count.

**FALSE**: "Dashboard team needs to build a multi-model management UI for this to work"
- **TRUTH**: New templates auto-appear in Dashboard via annotation discovery (`opendatahub.io/dashboard: "true"`). The bounded gap is that the deploy form is single-model optimized; CLI/kubectl works immediately without Dashboard changes. Dashboard UX enhancement for multi-model is a follow-on improvement, **not** a blocker.
- Source: Dashboard annotation scanning; deploy form UX is enhancement, not blocker.

**FALSE**: "We can build vLLM images ourselves"
- **TRUTH**: vLLM images are built by the RHAIIS team using AIPCC infrastructure and consumed by RHOAI via image reference overrides in the operator CSV (`registry.redhat.io/rhaii/<image>`). RHOAI has no vLLM build pipeline and strategies MUST NOT propose building vLLM from source.
- Source: RHOAIENG-66923; RHOAIENG-53009; RHOAIENG-52392.

**FALSE**: "Adding a new Python package is a simple pip install"
- **TRUTH**: Hermetic builds have no internet access. All Python packages must be onboarded to AIPCC (1–3 week lead time: self-service submission → builder onboarding → probe tests → QE → prod promotion). No direct pypi.org access at build time.
- Source: AIPCC hermetic build mandate; RHOAIENG-37768 integration timeline; AIPCC-18708 onboarding example.

**FALSE**: "ModelMesh is a viable alternative for multi-model serving"
- **TRUTH**: ModelMesh was **archived upstream in February 2025**. It was removed from the KServe Helm chart (PR #4243, merged 2025-02-16). It is deprecated in RHOAI since 2.19 and removal is required for RHOAI 3.x. There is no upstream maintenance or development.
- Source: https://github.com/kserve/modelmesh; https://github.com/kserve/kserve/pull/4243.

**FALSE**: "Scale-to-zero is available for serving runtimes"
- **TRUTH**: Scale-to-zero requires Knative Activator to buffer requests and wake pods. RHOAI uses RawDeployment (Standard) mode exclusively, which does **NOT** support scale-to-zero. Minimum replica count must be >= 1.
- Source: KServe dependencies matrix; RawDeployment mode architecture; Knative KPA documentation.

**FALSE**: "Auth token preservation or ServingRuntime reconciliation tests belong to Model Runtimes"
- **TRUTH**: Auth token tests, ServingRuntime reconciliation tests, route reconciliation, and ISVC lifecycle tests live in `opendatahub-tests/tests/model_serving/model_server/kserve/` and are owned by Platform/KServe team. Model Runtimes test scope (`opendatahub-tests/tests/model_serving/model_runtime/`) covers runtime deploy, serve, probe, storage, and variant testing only. Shared utilities like `get_exposed_isvc_url()` are used across both teams but do not transfer test ownership.
- Source: `opendatahub-tests/tests/model_serving/model_server/kserve/` (Platform/KServe); `opendatahub-tests/tests/model_serving/model_runtime/` (Model Runtimes); RHAISTRAT-2500 component misassignment incident.

## Context

The existing generated architecture docs for `openvino_model_server`, `MLServer`, and `vllm` describe each component
in isolation but do not explain:
- (a) How they compose with KServe/ODH Model Controller in the RawDeployment-only model
- (b) The three-tier runtime taxonomy (out-of-the-box vs custom vs tested & verified)
- (c) Which team owns what (Model Runtimes vs RHAII vs Platform vs vendor vs TrustyAI)
- (d) The MLServer upstream orphan situation and Red Hat's sole maintenance burden
- (e) The current testing patterns and their recent shifts (8 major changes in 2026)
- (f) The HardwareProfile mechanism that eliminates Dashboard/Platform dependencies
- (g) Triton's unique position as a Tested & Verified runtime with bounded scope
- (h) The dual deployment path architecture (ServingRuntime+ISVC vs LLMISConfig+LLMIS)
- (i) Multi-model serving architecture (MLServer repository mode, health probes, scaling, security)
- (j) KServe runtime resolution priority and ClusterServingRuntime lifecycle
- (k) ODH Model Controller RBAC scope and route timeout behavior
- (l) Dashboard model format hardcoding constraint for vLLM variants
- (m) vLLM fast-build rollout pattern and args injection mechanisms
- (n) Platform constraints (RHEL 9/10 container/host decoupling)
- (o) New runtimes: AutoGluon (tabular/time series) and Guardrails Detector HF (safety)

This overlay bridges those gaps until the next architecture regeneration cycle incorporates these
cross-cutting concerns into the individual component docs.

Sources: `odh-model-controller/architecture.md`, PRs #1667/#1679/#1704/#1713/#1720/#1723/#1897/#1898/#1931/#2117,
`utilities/serving_runtime.py`, `utilities/inference_utils.py`, `conftest.py` (root),
`image_validation/constant.py`, RHAISTRAT-1868/1929/2011/2173/2493/1486 investigations,
RHOAIENG-78154/63920, Seldon liquidation context.
