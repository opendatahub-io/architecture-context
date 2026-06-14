---
id: "0016"
title: "NVIDIA Triton — Tested & Verified runtime architecture and validation scope"
status: active
created: 2026-06-13
affects:
  - opendatahub-tests
  - kserve
release:
  - "3.4"
  - "3.5"
  - "next"
provenance:
  - https://github.com/opendatahub-io/opendatahub-tests/tree/main/tests/model_serving/model_runtime/triton
  - https://github.com/opendatahub-io/opendatahub-tests/pull/1327
  - https://github.com/opendatahub-io/opendatahub-tests/pull/1435
  - https://github.com/opendatahub-io/opendatahub-tests/pull/1720
  - https://docs.nvidia.com/deeplearning/triton-inference-server/release-notes/
author: Imran Khalidi, Model Runtimes Team
superseded_by: null
---

## Fact

### Runtime Category: Tested & Verified

NVIDIA Triton Inference Server is classified as a **Tested & Verified** runtime in RHOAI:

- NOT shipped with RHOAI (not in CSV `relatedImages`, not in `registry.redhat.io`)
- NOT in `odh-model-controller/config/runtimes/` (no platform template exists)
- Deployed by customers as a **custom runtime** (they create their own ServingRuntime CRD)
- Red Hat tests and verifies it with a **defined validation scope**
- Support is limited to what falls within that validation scope

The validation scope defines the support boundary: what is tested is what is supported.
Model Runtimes team is solely responsible for defining, creating, and maintaining this scope.

### Image Management

```
Image: nvcr.io/nvidia/tritonserver:25.02-py3
Source: NVIDIA GPU Cloud registry (not Red Hat registry)
Pinned version rationale: 25.02 is the last release with TensorFlow backend
```

| Version | TensorFlow Status |
|---------|-------------------|
| 25.02 | Included (last release) |
| 25.03 | Deprecated |
| 26.x+ | Removed completely |

The image version is managed in `tests/model_serving/model_runtime/triton/constant.py`:

```
TRITON_IMAGE: str = "nvcr.io/nvidia/tritonserver:25.02-py3"
```

The `--triton-runtime-image` pytest option / `TRITON_RUNTIME_IMAGE` env var allows CI to override this.

### Defined Validation Scope

The following matrix defines what is tested and hence supported:

| Model Format | Model Name | REST | gRPC | Test Tier | GPU Required |
|-------------|------------|------|------|-----------|--------------|
| ONNX | densenetonnx | Yes | Yes | tier1 | No |
| PyTorch | resnet50 | Yes | Yes | tier1 | No |
| TensorFlow | inceptiongraphdef | Yes | Yes | smoke | No |
| Keras | resnet | Yes | Yes | tier1 | No |
| Python | python (custom) | Yes | Yes | tier1 | No |
| FIL (tree-based) | fil | Yes | Yes | tier1 | No |
| DALI (GPU pipeline) | daligpu | Yes | Yes | tier1 | Yes |

**Total: 7 model formats x 2 protocols = 14 validated test scenarios**

Anything outside this matrix (e.g., TensorRT-specific features, Triton ensemble pipelines beyond what is
tested, custom backends, dynamic batching configuration) is NOT validated and NOT supported under the
Tested & Verified designation.

### ServingRuntime Definition (Custom CRD)

Unlike out-of-the-box runtimes that use platform templates, Triton tests create the full ServingRuntime
spec inline via OpenShift Template objects:

```
Test conftest.py -> create_triton_template() -> OpenShift Template
                 -> ServingRuntimeFromTemplate -> namespace-scoped ServingRuntime
                 -> InferenceService -> KServe reconciles
```

The runtime spec includes:

| Field | REST Runtime | gRPC Runtime |
|-------|-------------|--------------|
| Name | `triton-rest-runtime` | `triton-grpc-runtime` |
| Port | 8080 (http1) | 9000 (h2c) |
| Shared memory | None | 2Gi `/dev/shm` |
| Protocol versions | `v2`, `grpc-v2` | `v2`, `grpc-v2` |
| Supported formats | tensorrt, tensorflow 1/2, onnx, pytorch, triton, xgboost, python | Same |
| Container args | `tritonserver --model-store=/mnt/models --http-port=8080 --allow-http=True` | `tritonserver --model-store=/mnt/models --grpc-port=9000 --allow-grpc=True` |

### Inference Access Pattern

Triton tests currently use **port-forwarding** (NOT yet migrated to external routes):

```
Pod name from get_pods_by_isvc_label() -> portforward.forward(pod, namespace, port, port)
  REST: requests.post(f"http://localhost:{port}/v2/models/{model}/infer", json=input_data)
  gRPC: grpcurl -plaintext -import-path <proto_dir> -proto grpc_predict_v2.proto localhost:port inference.GRPCInferenceService/ModelInfer
```

gRPC uses the `grpcurl` CLI tool with `utilities/manifests/common/grpc_predict_v2.proto`. For large
payloads (>8KB), input is passed via stdin from a temp file rather than inline `-d`.

Migration to external routes (following PR #1713 pattern) is pending.

### Validation Pattern

Triton uses top-k classification validation (not fuzzy text validation):

```
Response structure: {"outputs": [{"data": [0.123, 0.456, ...]}]}

1. Assert response is not empty
2. Assert response is a dict (type-safe, PR #1720)
3. Assert outputs list is non-empty
4. Assert first output is a dict (type-safe, PR #1720)
5. Handle gRPC: if rawOutputContents present, assert non-empty and return
6. Extract data array
7. Compute top_k = min(5, len(actual_data))  (flexible, PR #1720)
8. Sort indices by value descending, take top_k
9. Assert all indices are valid integers in range
```

### GPU Handling

| Accelerator | Identifier | Default |
|-------------|-----------|---------|
| NVIDIA | `nvidia.com/gpu` | Yes (fallback) |
| AMD | `amd.com/gpu` | Supported via mapping |

GPU resources are added to InferenceService when `gpu_count > 0`. The DALI model test is the only
test requiring GPU (marked `pytest.mark.gpu`). Other model format tests run on CPU.

### Resource Configuration

| Resource | Base (CPU) | Multi-GPU |
|----------|-----------|-----------|
| CPU requests | 1 | 1 |
| CPU limits | 2 | 2 |
| Memory requests | 2Gi | 2Gi |
| Memory limits | 4Gi | 4Gi |
| Shared memory | - | 16Gi `/dev/shm` |
| Temp volume | - | `/tmp` |
| Home volume | - | `/home/triton` |

### Test Structure

```
tests/model_serving/model_runtime/triton/
├── __init__.py
├── constant.py              # TRITON_IMAGE, ports, paths, TEMPLATE_MAP, RUNTIME_MAP, resources
└── basic_model_deployment/
    ├── __init__.py
    ├── conftest.py          # triton_serving_runtime, triton_inference_service, template fixtures
    ├── utils.py             # send_rest_request, send_grpc_request, run_triton_inference, validate
    ├── test_onnx_model.py
    ├── test_pytorch_model.py
    ├── test_tensorflow_model.py
    ├── test_keras_model.py
    ├── test_python_model.py
    ├── test_fil_model.py
    ├── test_dali_model.py
    ├── __snapshots__/       # JSON snapshot files (legacy, being replaced by flexible validation)
    └── kserve-triton-*-input.json  # Pre-built inference input payloads (REST + gRPC per format)
```

### Input Data Files

Each model format has pre-built JSON input payloads for both REST and gRPC:

```
kserve-triton-onnx-rest-input.json      kserve-triton-onnx-gRPC-input.json
kserve-triton-python-rest-input.json    kserve-triton-python-gRPC-input.json
kserve-keras-triton-resnet-rest-input.json  kserve-keras-triton-resnet-gRPC-input.json
kserve-triton-tensorflow-rest-input.json  kserve-triton-tensorflow-gRPC-input.json
kserve-triton-resnet-rest-input.json    kserve-triton-resnet-gRPC-input.json  (PyTorch)
kserve-triton-dali-rest-input.json      kserve-triton-dali-gRPC-input.json
kserve-triton-fil-rest-input.json       kserve-triton-fil-gRPC-input.json
```

### Key Fixes History

| PR | Date | Fix |
|----|------|-----|
| #1155 | 2026-03 | Handle None/empty accelerator type, default to NVIDIA |
| #1327 | 2026-03 | Update image to 25.02 for TensorFlow backend support |
| #1435 | 2026-04 | Adjust smoke/tier1 markers, add standard deployment utils |
| #1720 | 2026-06 | Add type-safety, flexible top-k, gRPC rawOutputContents handling |

## Impact on Strategies

- Strategies expanding Triton validation scope (new model formats, new protocols, new deployment modes) must
  be coordinated with Model Runtimes team as they define the support boundary.
- Strategies proposing Triton features outside the validated scope (e.g., dynamic batching, model ensembles,
  BLS) should explicitly note these are not covered by Tested & Verified designation.
- The TensorFlow backend deprecation means strategies relying on TF models via Triton have a limited shelf
  life — eventually the image will need to drop TF tests or find an alternative.
- Migration from port-forward to external routes is pending and should be included in test modernization strategies.

## Context

The generated architecture docs do not mention Triton because it is not a component in any `opendatahub-io` repository
(it lives in NVIDIA's registry). The test suite in `opendatahub-tests` is the sole artifact defining the Tested &
Verified boundary. This overlay documents that boundary, the testing patterns, and the custom runtime deployment
mechanism so that strategies and RFEs can correctly scope Triton-related work.
