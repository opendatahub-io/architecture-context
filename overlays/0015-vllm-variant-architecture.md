---
id: "0015"
title: vLLM variant architecture — accelerator matrix, test suite structure, and RHAII boundary
status: active
created: 2026-06-13
affects:
  - vllm
  - odh-model-controller
  - opendatahub-tests
release:
  - "3.4"
  - "3.5"
  - "next"
provenance:
  - https://github.com/opendatahub-io/opendatahub-tests/tree/main/tests/model_serving/model_runtime/vllm
  - https://github.com/opendatahub-io/odh-model-controller/tree/main/config/runtimes
  - https://github.com/opendatahub-io/opendatahub-tests/pull/1679
  - https://github.com/opendatahub-io/opendatahub-tests/pull/1713
  - https://github.com/opendatahub-io/opendatahub-tests/pull/1704
  - https://github.com/opendatahub-io/opendatahub-tests/pull/1723
author: Imran Khalidi, Model Runtimes Team
superseded_by: null
---

## Fact

### Variant Matrix

vLLM ships as 7 platform templates in `odh-model-controller/config/runtimes/`, each targeting a different
accelerator or CPU architecture:

| Accelerator Type | Template Name | Image Owner | Resource Identifier |
|-----------------|---------------|-------------|---------------------|
| `nvidia` | `vllm-cuda-runtime-template` | RHAII | `nvidia.com/gpu` |
| `amd` | `vllm-rocm-runtime-template` | RHAII | `amd.com/gpu` |
| `gaudi` | `vllm-gaudi-runtime-template` | RHAII | `habana.ai/gaudi` |
| `spyre` | `vllm-spyre-x86-runtime-template` | IBM Spyre team (`red-hat-data-services/vllm-spyre`) | `ibm.com/spyre_pf` |
| `cpu_x86` | `vllm-cpu-x86-runtime-template` | IBM (`red-hat-data-services/vllm-cpu`) | CPU label |
| `cpu_power` | `vllm-cpu-power-runtime-template` | IBM Power team (`red-hat-data-services/vllm-cpu`, ppc64le) | CPU label |
| `cpu_z` | `vllm-cpu-z-runtime-template` | IBM Z team (`red-hat-data-services/vllm-cpu`, s390x) | CPU label |

Additional templates exist for multi-node (`vllm-multinode-template.yaml`) and Spyre ppc64le/s390x variants.

OOTB vLLM templates reference `registry.redhat.io` images by SHA256 digest (via operator `params.env`; GPU variants managed by RHAII, CPU/Spyre variants by IBM teams) — not floating tags. Digest alignment is verified by `image_validation/` tests in `opendatahub-tests`.

The `TEMPLATE_MAP` in `tests/model_serving/model_runtime/vllm/constant.py` resolves accelerator type to template:

```text
nvidia  -> vllm-cuda-runtime-template
amd     -> vllm-rocm-runtime-template
gaudi   -> vllm-gaudi-runtime-template
spyre   -> vllm-spyre-x86-runtime-template
cpu_x86 -> vllm-cpu-x86-runtime-template
cpu_power -> vllm-cpu-power-runtime-template
cpu_z   -> vllm-cpu-z-runtime-template
```

### RHAII Boundary

RHAII (Red Hat AI Inference) team owns:
- vLLM engine source code and GPU container image builds (CUDA, ROCm, Gaudi)
- Engine-level feature testing: TGIS protocol, multimodal inference, quantization (AWQ/Marlin),
  speculative decoding, tool calling, performance benchmarks

IBM teams own (via separate vLLM forks under `red-hat-data-services/`):
- `red-hat-data-services/vllm-cpu`: All CPU variant builds (x86, Power ppc64le, Z s390x)
  - IBM Power team handles ppc64le arch (VSX kernel optimizations)
  - IBM Z team handles s390x arch (VXE kernel optimizations)
  - x86 CPU variant also built from this fork
- `red-hat-data-services/vllm-spyre`: IBM Spyre accelerator variant

Model Runtimes team owns:
- RHOAI operator integration tests (does the runtime work correctly on the platform?)
- Storage backends: S3, PVC, OCI modelcar
- Deployment modes: RawDeployment with external routes
- Health probes: readiness and liveness validation
- CPU variant testing: x86, IBM Power, IBM Z (testing the operator integration, not the engine)
- Image validation: sha256 digests, registry.redhat.io sourcing

### Protocol: REST Only (No gRPC)

vLLM in RHOAI is **REST-only**. gRPC is NOT a supported protocol:
- All OOTB templates declare `opendatahub.io/apiProtocol: 'REST'`
- Entrypoint: `python -m vllm.entrypoints.openai.api_server` on port 8080
- Supported endpoints: `/v1/completions`, `/v1/chat/completions`, `/v1/models`, `/health`
- TGIS gRPC (port 8033) exists in some engine images but is NOT exposed in platform templates (RHAII scope)
- All Model Runtimes integration tests validate REST only

This contrasts with OVMS (REST + gRPC via `grpc-v2`) and Triton (REST + gRPC on port 9000).

### Removed Legacy Suites (PR #1679)

The following test directories were removed from `vllm/basic_model_deployment/` as they are now
covered by the RHAII team:

| Removed Suite | Reason |
|--------------|--------|
| `basic_model_deployment/` (multi-model tests) | RHAII covers full model deployment matrix |
| `multimodal/` (Granite Vision) | RHAII owns multimodal testing |
| `quantization/` (AWQ) | RHAII owns quantization validation |
| `speculative_decoding/` (draft, n-gram) | RHAII owns speculative decoding |
| `toolcalling/` (function calling) | RHAII owns tool calling tests |
| TGIS protocol tests | TGIS is RHAII scope |
| Serverless deployment tests | RHOAI exclusively uses RawDeployment |
| Legacy snapshot files (`__snapshots__/`) | Replaced by fuzzy validation |

### Current Test Directory Structure

```text
tests/model_serving/model_runtime/vllm/
├── conftest.py          # Main fixtures: serving_runtime, vllm_inference_service (external_route=True)
├── constant.py          # TEMPLATE_MAP, ACCELERATOR_IDENTIFIER, queries with keywords
├── utils.py             # run_raw_inference (external route), validate_raw_openai_inference_request
├── s3/                  # S3-backed raw deployment
│   ├── test_granite_7b_starter.py
│   └── test_llama3_8B_instruct.py
├── modelcar/            # OCI modelcar YAML-driven validation
│   ├── conftest.py      # pytest_generate_tests reads YAML config
│   ├── sample_modelcar_config.yaml
│   ├── test_modelvalidation.py
│   └── utils.py
├── pvc/                 # PVC-backed model storage
│   ├── conftest.py
│   └── test_vllm_pvc_inference.py
├── probes/              # Readiness/liveness probe validation
│   ├── conftest.py      # probes_serving_runtime with httpGet injection
│   ├── test_vllm_probes.py
│   └── utils.py         # VLLM_READINESS_PROBE, VLLM_LIVENESS_PROBE definitions
└── cpu/                 # CPU variant testing
    ├── cpu_x86/
    │   ├── conftest.py  # cpu_x86_serving_runtime, cpu_x86_inference_service
    │   ├── constant.py  # CPU_X86_ENV_VARIABLES, resources, serving args
    │   ├── test_vllm_cpu_s3_inference.py
    │   └── utils.py
    └── ibm_power_z/
        ├── conftest.py
        ├── constant.py  # bfloat16, 12 CPU / 64Gi resources
        ├── test_falcon3_7b_instruct.py
        ├── test_granite_3_1_8b_instruct.py
        ├── test_llama_3_2_1b_instruct.py
        ├── test_mistral_7b_instruct.py
        ├── test_phi_4.py
        └── utils.py
```

### Test Markers

| Marker | Scope | Requires |
|--------|-------|----------|
| `vllm_nvidia_single_gpu` | Single NVIDIA GPU tests | 1x `nvidia.com/gpu` |
| `vllm_nvidia_multi_gpu` | Multi-GPU NVIDIA tests | 2+ `nvidia.com/gpu` |
| `vllm_amd_gpu` | AMD ROCm GPU tests | 1x `amd.com/gpu` |
| `vllm_cpu_x86` | x86 CPU-only tests | x86 CPU accelerator |
| `vllm_cpu_power` | IBM Power CPU tests | Power CPU accelerator |
| `vllm_cpu_z` | IBM Z CPU tests | Z CPU accelerator |

### Inference Pattern: External Routes (REST Only)

All vLLM tests deploy with `external_route: True` and access REST inference via `get_exposed_isvc_url(isvc)`:

```text
InferenceService (external_route=True) -> ODH Model Controller creates Route
                                       -> status.url populated with external hostname
                                       -> Tests call get_exposed_isvc_url(isvc) -> base URL
                                       -> OpenAI-compatible REST requests to external URL
                                       -> /v1/completions, /v1/chat/completions, /v1/models
```

gRPC is NOT used — all vLLM tests are REST-only (OpenAI-compatible API).

The `run_raw_inference()` function uses `@retry(stop=stop_after_attempt(5), wait=wait_exponential(min=1, max=6))`
for resilience against transient route propagation delays.

Port-forwarding has been completely removed from vLLM tests (PR #1713). The `pod_name` parameter and
`vllm_pod_resource` fixture are no longer used for text inference.

### Validation Pattern: Fuzzy Keyword Matching

All vLLM tests use `validate_text_inference_fuzzy()` with keyword-based validation:

```python
COMPLETION_QUERY = [
    {"text": "List the top five breeds of dogs...", "keywords": ["dog", "breed", "labrador", ...]},
    ...
]
```

The 7-step validation pipeline:
1. Schema validation (OpenAI response format with `choices`)
2. Non-emptiness (minimum 3 words)
3. Content quality (regex for 2+ char alphabetic words, 30%+ alpha ratio)
4. Error detection (regex for traceback, CUDA error, OOM, segfault indicators)
5. Repetition detection (4-gram phrases max 3 repeats)
6. Keyword matching (at least one expected keyword in response)
7. Model info validation (list of dicts with `id` and `object` fields)

Snapshot comparison (`syrupy`) is only used when `CHECK_SNAPSHOT=true` env var is set (disabled by default).

### Probe Testing

The `probes/` suite validates that vLLM predictor pods have correctly functioning health probes:

| Probe | Path | Port | Initial Delay | Period | Timeout | Failure Threshold |
|-------|------|------|---------------|--------|---------|-------------------|
| Readiness | `/health` | 8080 | 120s | 10s | 10s | 12 |
| Liveness | `/health` | 8080 | 180s | 30s | 10s | 10 |

Probes are injected via `ServingRuntimeFromTemplate` `containers` kwarg onto `kserve-container`.
Tests verify: pod is Ready, probe httpGet spec exists, in-pod curl returns HTTP 200, no premature
container restarts during model load.

### YAML-Driven Modelcar Testing

The modelcar suite uses `sample_modelcar_config.yaml` to define test models dynamically:

```yaml
model-car:
  - name: granite-3.1-8b-instruct
    image: oci://registry.stage.redhat.io/rhelai1/modelcar-granite-3-1-8b-instruct:1.5
    model_output_type: text
    serving_arguments:
      args: ["--uvicorn-log-level=info", "--max-model-len=1024", "--trust-remote-code"]
      gpu_count: 1
  - name: whisper-large-v3
    image: oci://registry.redhat.io/rhelai1/modelcar-whisper-large-v2-w4a16-g128:1.5
    model_output_type: audio
  - name: embedding-gemma
    image: oci://registry.redhat.io/rhelai1/modelcar-embeddinggemma-300m:1.5
    model_output_type: embedding
```

`pytest_generate_tests()` in the modelcar `conftest.py` reads this YAML and generates parameterized
test cases for each model, supporting text, audio, and embedding output types.

### CPU Variant Resources

CPU variants use dedicated resource configurations:

| Variant | CPU Request | CPU Limit | Memory | Shared Memory | Key Env Vars |
|---------|------------|-----------|--------|---------------|--------------|
| x86 | 8 | 16 | 10-16Gi | 32Gi | `VLLM_CPU_KVCACHE_SPACE=4`, `OMP_NUM_THREADS=8`, `VLLM_WORKER_MULTIPROC_METHOD=spawn` |
| IBM Power/Z | 12 | 12 | 64Gi | 32Gi | bfloat16 serving args |

CPU x86 tests use small models (opt-125m, TinyLlama-1.1B) with `--enforce-eager --max-model-len=256`.
IBM Power/Z tests use larger instruct models (Falcon3-7B, Llama-3.2, Phi-4, Mistral-7B, Granite-3.1-8B)
with `--dtype=bfloat16`.

## Impact on Strategies

- Strategies involving new vLLM GPU accelerator support (CUDA, ROCm, Gaudi) must go to RHAII — they own those
  engine builds. Model Runtimes only tests the operator integration.
- Strategies for IBM CPU variants (x86, Power, Z) must coordinate with the respective IBM teams who maintain
  the `red-hat-data-services/vllm-cpu` fork. Model Runtimes tests integration only.
- Strategies for IBM Spyre must coordinate with the IBM Spyre team (`red-hat-data-services/vllm-spyre`).
- CPU variant strategies should follow the pattern established in PR #1723: new marker, new constant file with
  resources/env vars, new conftest with serving_runtime and inference_service fixtures, new test module.
- Any strategy proposing to add vLLM engine features (multimodal, tool calling, etc.) to the Model Runtimes test
  suite is out of scope — these are RHAII responsibility.
- Strategies for PVC, S3, or OCI modelcar storage improvements affect the Model Runtimes test suite directly.
- **gRPC support for vLLM is NOT in scope** — vLLM OOTB templates are REST-only (OpenAI API). Any gRPC
  strategy for vLLM (TGIS, KServe v2 gRPC) is RHAII engine scope, not Model Runtimes.

## Context

The vLLM test suite underwent a major refactoring in June 2026 (PR #1679) to remove RHAII-scope tests and establish
a clear boundary. Subsequent PRs (#1713, #1704, #1723, #1730) added external route inference, probe testing, CPU
variants, and multi-GPU support. The generated architecture docs for `vllm` do not reflect this team boundary or the
new test infrastructure. This overlay documents the current state and provides patterns for skills-based test case
generation.
