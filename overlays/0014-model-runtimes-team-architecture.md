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
- **GPU support**: Requires separate container image on `aipcc/cuda` base:
  - CPU base image (`aipcc/cpu`) does **NOT** include CUDA runtime libraries (`libcudart.so`)
  - `onnxruntime-gpu` will crash immediately on CPU base: `OSError: libcudart.so.12: cannot open shared object file`
  - Pattern: new Konflux pipeline producing `mlserver-onnx-gpu` image on `aipcc/cuda` base
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
  - TensorFlow backend deprecated and removed starting with 25.03 (v2.56.0)
  - The 25.02 pin is deliberate: the current test matrix requires the TensorFlow backend. No CVE support applies — Triton is not shipped with RHOAI (`registry.redhat.io` / CSV `relatedImages`); the image is sourced directly from NVIDIA (`nvcr.io`) for T&V validation only. Red Hat supports the deployment and integration layer (custom runtime via KServe), not the vendor image itself
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

| Template Name | Runtime | Accelerator | Model Formats | Multi-Model | Image Base | Pipeline |
|---|---|---|---|---|---|---|
| `ovms-kserve-template` | OVMS | Intel GPU / CPU | OpenVINO IR, ONNX, TF SavedModel, PaddlePaddle, PyTorch | No | `aipcc/cpu` | Existing |
| `mlserver-template` | MLServer | CPU only | LightGBM, ONNX, Sklearn, XGBoost | No (current) | `aipcc/cpu` | Existing |
| `mlserver-multi-model-template` | MLServer | CPU only | Same as above | **Yes** (repository mode) | `aipcc/cpu` | **Planned** |
| `mlserver-onnx-gpu-template` | MLServer | NVIDIA GPU | ONNX only | No | `aipcc/cuda` | **Planned** |
| `vllm-cuda-runtime-template` | vLLM | NVIDIA GPU | LLM (all vLLM-supported) | N/A (LLM) | `aipcc/cuda` | Existing |
| `vllm-rocm-runtime-template` | vLLM | AMD GPU | LLM | N/A | RHAII ROCm base | Existing |
| `vllm-gaudi-runtime-template` | vLLM | Intel Gaudi | LLM | N/A | RHAII Gaudi base | Existing |
| `vllm-spyre-x86-runtime-template` | vLLM | IBM Spyre | LLM | N/A | IBM Spyre base | Existing |
| `vllm-cpu-x86-runtime-template` | vLLM | x86 CPU | LLM | N/A | IBM CPU base | Existing |
| `vllm-cpu-power-runtime-template` | vLLM | IBM Power CPU | LLM | N/A | IBM Power base | Existing |
| `vllm-cpu-z-runtime-template` | vLLM | IBM Z CPU | LLM | N/A | IBM Z base | Existing |
| *(none — custom CR)* | Triton | NVIDIA GPU | TensorRT, TF, ONNX, PyTorch, XGBoost, Python, FIL, DALI, Keras | **Yes (native)** — model repository with dynamic load/unload | NVIDIA vendor | N/A (not shipped) |

#### Template Catalog Notes

- **"Planned" templates** are tracked in RHAISTRAT-1868 (GPU) and RHAISTRAT-2011 (multi-model).
- Template YAML lives in `odh-model-controller/config/runtimes/`.
- Each template requires: name, annotations (`opendatahub.io/dashboard`, `opendatahub.io/ootb`, `opendatahub.io/apiProtocol`), container spec, supported model formats, protocol versions.
- Adding a template is a **Model Runtimes-only operation** — see Cross-Team Dependency Decision Matrix above.
- Triton is Tested & Verified only; it has no platform template and is not shipped via `relatedImages`. However, Triton **natively supports multi-model** via its model repository — customers deploying Triton as a custom runtime can load multiple models. Red Hat supports the deployment/integration layer for this use case.

Source: `odh-model-controller/config/runtimes/`; RHAISTRAT-1868; RHAISTRAT-2011.

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
