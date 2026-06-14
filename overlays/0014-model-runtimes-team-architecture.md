---
id: "0014"
title: Model Runtimes team architecture — ownership, runtime lifecycle, and testing patterns
status: active
created: 2026-06-13
affects:
  - openvino_model_server
  - MLServer
  - vllm
  - odh-model-controller
  - kserve
  - opendatahub-tests
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

RHOAI exclusively uses **RawDeployment** mode (not Knative/Serverless). This means:
- No Knative Serving dependency (`serverless-operator` not required)
- KServe controller creates standard Kubernetes Deployments and Services directly
- ODH Model Controller handles OpenShift Route creation (Knative Routes are not used)
- `KServeDeploymentType.RAW_DEPLOYMENT` is the only mode used in test fixtures

Source: `utilities/constants.py` defines `KServeDeploymentType` enum; `odh-model-controller/architecture.md`
documents the RawDeployment-exclusive design decision.

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
|   (vLLM | OVMS | MLServer | Triton)                             |
|                                                                  |
|   Runs inference, exposes REST/gRPC endpoints                    |
|   HardwareProfile webhook injects GPU resource limits            |
+------------------------------------------------------------------+
```

Source: `odh-model-controller/architecture.md` full architecture description;
`odh-model-controller/controllers/` for controller implementations.

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
|  +---------------------+                                              |
|  | opendatahub-tests/  |                                              |
|  | model_runtime/      |                                              |
|  | (ALL runtime tests) |                                              |
|  +---------------------+                                              |
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
- **GPU support**: Via `onnxruntime-gpu` Python package swap:
  - Replace `onnxruntime` with `onnxruntime-gpu` in container
  - Configure CUDA/TensorRT execution providers
  - No separate container image needed (unlike vLLM's per-accelerator images)
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

#### vLLM

- **Category**: Out-of-the-box Supported (7 platform-shipped variant templates)
- **Templates** (all in `odh-model-controller/config/runtimes/`):
  | Template | Accelerator | Image Owner |
  |----------|-------------|-------------|
  | `vllm-cuda-runtime-template` | NVIDIA GPU | RHAII |
  | `vllm-rocm-runtime-template` | AMD GPU | RHAII |
  | `vllm-gaudi-runtime-template` | Intel Gaudi (Habana) | RHAII |
  | `vllm-spyre-x86-runtime-template` | IBM Spyre | IBM Spyre team (`red-hat-data-services/vllm-spyre`) |
  | `vllm-cpu-x86-runtime-template` | x86 CPU | IBM (`red-hat-data-services/vllm-cpu`) |
  | `vllm-cpu-power-runtime-template` | IBM Power CPU | IBM Power team (`red-hat-data-services/vllm-cpu`, ppc64le build) |
  | `vllm-cpu-z-runtime-template` | IBM Z CPU | IBM Z team (`red-hat-data-services/vllm-cpu`, s390x build) |

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

Source: `odh-model-controller/config/runtimes/vllm-*.yaml`; PR #1679 (RHAII scope separation)

### Protocol Support Matrix

| Runtime | REST | gRPC | API Style | Template Annotation |
|---------|------|------|-----------|---------------------|
| **vLLM** | Yes (port 8080) | **No** | OpenAI-compatible (`/v1/completions`, `/v1/chat/completions`) | `opendatahub.io/apiProtocol: 'REST'` |
| **OVMS** | Yes (port 8888) | Yes (port 8033) | KServe v2 inference protocol | `protocolVersions: [v2, grpc-v2]` |
| **MLServer** | Yes (port 8080) | Yes (port 8081) | KServe v2 inference protocol | `protocolVersions: [v2, grpc-v2]` |
| **Triton** | Yes (port 8080) | Yes (port 9000) | KServe v2 inference protocol | Defined inline in test CRD |

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
  - TensorFlow backend deprecated in 25.03, completely removed in 26.x+
  - Image version managed in `tests/model_serving/model_runtime/triton/constant.py`
- **Supported formats**: TensorRT, TensorFlow 1/2, ONNX, PyTorch (LibTorch), Triton (ensemble), XGBoost, Python, FIL (Forest Inference Library), DALI (GPU data pipeline), Keras
- **Protocols**: REST (port 8080, v2 inference) + gRPC (port 9000, KServe Predict V2)
- **Validation scope**: 7 model formats x 2 protocols = 14 test scenarios — this defines the support boundary
- **Model Runtimes sole responsibility**: Defining the validation scope and maintaining the test suite
- **Key distinction**: Customers deploy Triton as a "custom runtime" (create their own ServingRuntime CRD),
  but unlike truly custom runtimes, Red Hat has tested and verified it within the defined scope
- **gRPC tooling**: Uses `grpcurl` CLI with `grpc_predict_v2.proto` (stdin for payloads > 8KB)
- **Test location**: `tests/model_serving/model_runtime/triton/`
- **Not in image validation**: Absent from `image_validation/constant.py` `RUNTIME_CONFIGS` (confirms not platform-shipped)

Source: `opendatahub-tests/triton/constant.py`; NVIDIA Triton release notes; `odh-model-controller/config/runtimes/` (absence confirms)

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
- TensorFlow backend has limited shelf life (deprecated 25.03, removed 26.x+)

### Testing Modernization (Source: PRs #1667, #1713, #1704, #1720)

- New strategies should mandate: external routes (not port-forward), fuzzy validation (not snapshots),
  probe testing (readiness + liveness), type-safe assertions
- Triton migration to external routes is a pending modernization item
- OVMS/MLServer may adopt fuzzy validation for cross-hardware GPU testing

## Context

The existing generated architecture docs for `openvino_model_server`, `MLServer`, and `vllm` describe each component
in isolation but do not explain:
- (a) How they compose with KServe/ODH Model Controller in the RawDeployment-only model
- (b) The three-tier runtime taxonomy (out-of-the-box vs custom vs tested & verified)
- (c) Which team owns what (Model Runtimes vs RHAII vs Platform vs vendor)
- (d) The MLServer upstream orphan situation and Red Hat's sole maintenance burden
- (e) The current testing patterns and their recent shifts (6 major changes in 2026)
- (f) The HardwareProfile mechanism that eliminates Dashboard/Platform dependencies
- (g) Triton's unique position as a Tested & Verified runtime with bounded scope

This overlay bridges those gaps until the next architecture regeneration cycle incorporates these
cross-cutting concerns into the individual component docs.

Sources: `odh-model-controller/architecture.md`, PRs #1667/#1679/#1704/#1713/#1720/#1723,
`utilities/serving_runtime.py`, `utilities/inference_utils.py`, `conftest.py` (root),
`image_validation/constant.py`, RHAISTRAT-1868 analysis, Seldon liquidation context.
