---
id: "0021"
title: RHAIIS Pipeline — vLLM Wheel Build Specification
status: active
created: 2026-07-15
affects:
  - platform
release:
  - "3.5"
provenance:
  - https://gitlab.com/redhat/rhel-ai/rhaiis/pipeline
author: Lance Barto
superseded_by: null
---

## Fact

`rhaiis/pipeline` is the **wheel build specification** for the Red Hat AI
Inference Server (RHAIIS, vLLM-based) and the Model Optimization (`model-opt`,
llmcompressor-based) toolchain. It declares per-hardware-variant which Python
packages to build and at what versions, then triggers the `builder` CI API to
execute those builds.

This repo does **not** publish packages to Pulp — that is handled separately by
`rhai/pipeline`. It contains no application code.

- **Product version:** `3.5`
- **Builder version pinned:** `v39.4.0` (3 minor versions ahead of `rhai/pipeline`'s `v39.1.0`; both well behind builder's latest `v42.0.2`)
- **Repeatable build mode:** `ENABLE_REPEATABLE_BUILD_MODE` is commented out
  for all variants on the main branch (not enabled); it is intended for release
  branches and must be uncommented when cutting a release branch.

### Variant Matrix

| Collection | Variant | Arch | vLLM Version | Torch | Notes |
|---|---|---|---|---|---|
| rhaiis | cuda13.0-ubi9 | x86_64, aarch64 | 0.24.0+rhaiv.5.cuda | 2.11.0 | NeuralMagic fork; cgraph-cuda13 extra; new `.cuda` local version suffix |
| rhaiis | rubin-ubi9 | x86_64, aarch64 | TBD (placeholder) | TBD | New; requirements not yet populated — awaiting Rubin CUDA stack |
| rhaiis | rocm7.14-ubi9 | x86_64 | 0.24.0+rhaiv.2 | 2.11.0 | NeuralMagic fork |
| rhaiis | cpu-ubi9 | x86_64 only | 0.24.0+rhaiv.2 | 2.11.0 | NeuralMagic fork; `zen` extra (unconditional — x86_64-only build) |
| rhaiis | gaudi-ubi9 | x86_64 | 0.24.0 | 2.11.0 | **Upstream vllm-project**, not NeuralMagic fork |
| rhaiis | spyre-ubi9 | x86_64, ppc64le, s390x | 0.24.0+rhaiv.3.spyre | 2.11.0 | IBM fork; sendnn packages |
| rhaiis | neuron-ubi9 | x86_64 | 0.16.0+rhaiv.12 | 2.9.1 | Significantly older; neuronx stack pinned with git hashes |
| rhaiis | tpu-ubi9 | x86_64 | 0.21.0+rhaiv.13.tpu | 2.10.0 | 3 vLLM minor releases behind CUDA |
| model-opt | cuda13.0-ubi9 | x86_64, aarch64 | N/A | 2.11.0 | llmcompressor 0.12.0 + speculators 0.6.0 |
| vllm-omni | cuda13.0-ubi9 | x86_64, aarch64 | 0.24.0+rhaiv.2 (+vllm-omni 0.24.0+rhaiv.1) | 2.11.0 | AIPCC-12521: AIPCC vllm-omni productization |

CUDA 13.0 rhaiis advanced to `0.24.0+rhaiv.5.cuda`; the new `.cuda` suffix
distinguishes the variant-specific patch level from the previously generic
`+rhaiv.N` format. ROCm, CPU, and vllm-omni remain at `+rhaiv.2`. Neuron
remains furthest behind (0.16.0 vs 0.24.0 mainstream, 8 minor releases).

Note: `cpu-ubi9` in this repo builds **x86_64 only** — no ppc64le or s390x
CI jobs are defined here, unlike `rhai/pipeline` which builds cpu-ubi9 on all
4 architectures.

### Package Content by Variant

**cuda13.0-ubi9** (most package-rich):
- `vllm[audio,tensorizer,cgraph-cuda13]==0.24.0+rhaiv.5.cuda`
- `vllm-bart-plugin==0.5.0` (INFERENG-6019: BART plugin for custom BART model support)
- FlashInfer: `flashinfer-cubin`, `flashinfer-jit-cache`, `flashinfer-python`
- llm-d / disaggregated inference: `nixl`, `nixl-cu13`, `deep_ep==2.0.0+rhaiv.0`,
  `pplx-kernels==0.0.1` (INFERENG-1925)
- `bitsandbytes`, `triton`, `timm>=1.0.17`, `numba` (AIPCC-5334);
  `xformers` (AIPCC-2152: aarch64 missing dependency)
- `opentelemetry-exporter-prometheus` (INFERENG-2949)
- Geospatial: `geobenchv2`, `terrakit`, `terratorch`, `torchgeo` (AIPCC-8393)
- CVE/security: `setuptools>=80.10.2` (AIPCC-9947), `aiohttp>=3.13.3`,
  `urllib3>=2.6.3` (INFERENG-4285)
- Constraints: `boto3==1.43.46` (INFERENG-4923: botocore/aiobotocore compat),
  `terrakit<0.2.0` (AIPCC-19339: tacoreader conflict), `numba==0.65.0`
  (INFERENG-6026: match vllm midstream requirement, prevent llvmlite conflict),
  `numpy<2.5` (AIPCC-28010: ABI compat)

**vllm-omni/cuda13.0-ubi9** (new collection):
- `vllm-omni==0.24.0+rhaiv.1` (AIPCC-12521: AIPCC vllm-omni productization)
- `vllm[audio,tensorizer,cgraph-cuda13]==0.24.0+rhaiv.2` (same extras as rhaiis CUDA)
- FlashInfer, `triton`, `xformers`, `bitsandbytes`, `timm>=1.0.17`, `numba`
- Constraints: same CVE/compat pins as rhaiis cuda13.0-ubi9

**rocm7.14-ubi9:**
- `vllm[audio,tensorizer]==0.24.0+rhaiv.2`
- `amd-aiter==0.1.13.post1` — AMD attention/iteration kernel (required)
- `flash-attn`, `triton`, `torch`, `torchaudio`, `torchvision`
- `timm>=1.0.17`, `bitsandbytes`, `numba` (AIPCC-5334)
- `opentelemetry-exporter-prometheus` (AIPCC-6630: pre-release-only on PyPI, must pin)
- Constraints: `grpcio==1.78.0` / `grpcio-reflection==1.78.0` (INFERENG-5970
  prevents version conflict), `yarl<1.24` (INFERENG-7300 avoids setuptools>=82
  requirement), `onnx>=1.21.0` (INFERENG-8010, CVE fix), `numba==0.65.0` (INFERENG-7932)

**cpu-ubi9** (x86_64 only in this repo):
- `vllm[audio,tensorizer,zen]==0.24.0+rhaiv.2` — `zen` extra (zentorch for AMD
  EPYC CPUs) is unconditional because this repo only builds x86_64; no
  platform-conditional form is needed
- `timm>=1.0.17`, geospatial stack (geobenchv2, terrakit, terratorch, torchgeo)
- `setuptools>=80.10.2`
- Constraints: `boto3==1.43.46` (INFERENG-4923: botocore/aiobotocore compat),
  `terrakit<0.2.0` (AIPCC-19339: tacoreader conflict), `aiohttp>=3.13.3`,
  `urllib3>=2.6.3` (INFERENG-4285 CVE), `matplotlib<3.11.0` (TEMP: build job fix)

**gaudi-ubi9** (structurally unique):
- Uses `vllm==0.24.0` + `vllm-gaudi==0.24.0` — **upstream `vllm-project/vllm`,
  not the NeuralMagic `nm-vllm-ent` fork** (no `+rhai` local version tag)
- Habana ecosystem: `habana-torch-plugin`, `habana-gpu-migration`, `habana-pyhlml`,
  `habana-torch-dataloader`, `intel-transformer-engine`, `neural-compressor-pt`
- `symengine` (undeclared habana-torch-plugin dependency)
- Renovate does **not** auto-update vLLM for this variant: the custom regex
  manager expects a `+rhai` local version tag that upstream Gaudi vLLM lacks,
  so no version match occurs (see Update Automation section)
- Constraints: `yarl<1.24`, `propcache<0.5` (AIPCC-21773: required until
  Cython>=3.2.0 is available)

**rubin-ubi9** (new, placeholder):
- Requirements file contains only a placeholder comment: "Packages will be
  populated in a follow-up MR once the Rubin CUDA stack is available."
- Jobs are defined in `.gitlab-ci.yml` for x86_64 and aarch64, but no packages
  will build until the requirements are populated.

**neuron-ubi9** (most constrained):
- `vllm[tensorizer]==0.16.0+rhaiv.12` + `vllm-neuron==0.5.1`
- `timm>=1.0.17`, `setuptools>=80.10.2`
- Full neuronx stack pinned with embedded git commit hashes in version strings:
  `torch==2.9.1`, `torch-neuronx==2.9.0.2.14.27725+e2ff0410`,
  `libneuronxla==2.2.16974.0+a550bfe0`, `neuronx-cc==2.25.3371.0+f524f7f8`,
  `neuronx-distributed==0.19.28093+fc70b593`,
  `neuronx-distributed-inference==0.10.17970+8548ba25`,
  `nki==0.4.0+25940409122.gd30719f9`, `torch-xla==2.9.0`,
  `torchcodec==0.9.1` (AIPCC-12191), `triton==3.5.1`
- Torch pinned at 2.9.1 (not 2.11.0 used by most other variants)
- Constraints-rules API is **disabled** (rule commented out) — all pins are
  explicit in `constraints.txt` (INFERENG-5249)
- Additional constraints: `transformers<5` (AIPCC-9443: vllm transitive dep),
  `prometheus-fastapi-instrumentator>=8.0.1` (INFERENG-8555),
  `yarl<1.24.2`, `urllib3>=2.6.3` (INFERENG-4285)

**spyre-ubi9** (multi-arch: ppc64le, s390x, x86_64):
- `vllm[tensorizer]==0.24.0+rhaiv.3.spyre`
- `sendnn-inference==2.3.1; platform_machine == 'ppc64le'` and
  `sendnn-inference==2.3.1; platform_machine == 's390x' or platform_machine == 'x86_64'`
  (AIPCC-18691: both guards resolve to 2.3.1; unified version, separate platform markers)
- `torch-sendnn==1.2.5`, `depyf`, `torchao`, `flash-linear-attention`,
  `pytest-asyncio`, `hf-xet`
- `torch-nnpa==1.5.0; platform_machine == 's390x'` (AIPCC-18989)
- `triton`, `intel-openmp`, `intel_cmplr_lib_ur` (x86_64 only)
- `llguidance` (AIPCC-27980: explicit to ensure install)
- `timm>=1.0.17`, `opentelemetry-exporter-prometheus; platform_machine != 's390x'`
  (excluded from s390x, AIPCC-13600)
- Constraints: `torchao==0.11.0` (must match fms-model-optimizer[fp8-infer]),
  `llguidance>=1.7.0` (AIPCC-18235: Z bug in <=1.7.0),
  `prometheus-fastapi-instrumentator>=8.0.1`,
  `ibm-fms==1.11.1` (AIPCC-27740; pinned in constraints, not requirements),
  `intel-openmp==2024.2.1`, `intel-cmplr-lib-ur==2024.2.1`, `tokenizers==0.22.2`
  (AIPCC-11994: pins for 3.5 EA2 build)

**tpu-ubi9:**
- `vllm[tensorizer]==0.21.0+rhaiv.13.tpu` — 3 minor versions behind CUDA
- `llmcompressor` is commented out (AIPCC-4341, temporarily disabled)
- `timm>=1.0.17`, `setuptools>=80.10.2`
- Uses `torch-2.10.0 *` constraints-rules (one torch minor behind most variants)

**model-opt/cuda13.0-ubi9:**
- `llmcompressor==0.12.0`
- `speculators==0.6.0` (no longer a pre-release)
- `setuptools>=80.10.2`, `pillow>=12.1.1`
- Explicit constraint pins at llmcompressor 0.12.0 release: `loguru==0.7.3`,
  `numpy==2.4.6`, `compressed-tensors==0.17.1`, `transformers>=5.9.0,<=5.10.1`,
  `datasets==5.0.0`, `accelerate==1.13.0`, `auto-round==0.13.0`, etc. (INFERENG-8847)

### Constraints-Rules Delegation

Eight of the ten collection × variant combinations opt in to `torch-2.11.0 *`
via `constraints-rules.txt`: cuda13.0-ubi9 (rhaiis), rubin-ubi9, rocm7.14-ubi9,
cpu-ubi9, gaudi-ubi9, spyre-ubi9, model-opt/cuda13.0-ubi9, and
vllm-omni/cuda13.0-ubi9. Two exceptions:
- `neuron-ubi9`: delegation is disabled (rule commented out); all pins are
  explicit in `constraints.txt` (INFERENG-5249)
- `tpu-ubi9`: opts in to `torch-2.10.0 *` instead (one torch minor behind the
  rest)

Note: `rubin-ubi9` requirements are a placeholder (no packages yet), but the
`constraints-rules.txt` already opts in to `torch-2.11.0 *`.

### Pipeline Flow

**Stages:** checks → bootstrap → build → release → lint → notify

All (collection × variant × arch) combinations include
`pipeline-api/ci-wheelhouse.yml` from `builder@v39.4.0`.

**No publish jobs exist** in this repo. Artifact lifecycle:
1. `rhaiis/pipeline` builds wheels → stored in GitLab CI artifact storage
2. `rhai/pipeline` (separately triggered) publishes to Pulp indexes

`seccomp.json` in this repo provides the Linux seccomp BPF syscall filter
applied to wheel build containers.

### Update Automation

Renovate manages vLLM version updates per variant via per-variant custom regex
managers; local version suffixes differ per accelerator (`.cuda`, `.rocm`,
`.spyre`, `.tpu`, etc.). The pip_requirements manager is globally disabled for
`vllm` across all `collections/rhaiis/*/requirements.txt` via an explicit
packageRule; the custom regex managers are the real vLLM tracking mechanism.
Gaudi vLLM is effectively not updated by Renovate: the custom regex manager for
Gaudi matches versions with a `+rhai` local version tag (e.g.
`0.24.0+rhaiv.N.gaudi`), but the Gaudi requirements file uses plain upstream
`vllm==0.24.0` — no tag, no regex match, no update. There is no dedicated
Gaudi-specific packageRule exclusion; the lack of updates is a format mismatch.
Builder version updates are gated by per-branch `allowedVersions` patterns.

## Impact on Strategies

- **vLLM version fragmentation persists**: Five distinct vLLM versions are
  simultaneously active — `0.24.0+rhaiv.5.cuda` (CUDA rhaiis), `0.24.0+rhaiv.2`
  (ROCm, CPU, vllm-omni), `0.24.0` upstream (Gaudi), `0.24.0+rhaiv.3.spyre`
  (Spyre), `0.21.0+rhaiv.13.tpu` (TPU), `0.16.0+rhaiv.12` (Neuron). Rubin is
  TBD. Cross-variant features must be ported to all applicable fork versions.
  Neuron remains furthest behind (0.16.0 vs 0.24.0 mainstream, 8 minor releases).
- **Gaudi uses a different vLLM fork**: All other RHAIIS vLLM variants use the
  NeuralMagic enterprise fork (`nm-vllm-ent`). Gaudi uses upstream
  `vllm-project/vllm` with a separate `vllm-gaudi` package. NeuralMagic-specific
  patches cannot be applied to Gaudi. Its update cycle is effectively manual —
  Renovate's regex manager for Gaudi requires a `+rhai` local version tag that
  upstream vLLM lacks, so no automated version proposals are generated.
- **Neuron is the most constrained variant**: Torch is at 2.9.1 while other
  variants are at 2.11.0. The constraints-rules delegation is disabled. The full
  neuronx stack carries embedded git commit hashes in version strings. Any RFE
  touching Neuron requires explicit pin management for ~20 packages.
- **Spyre carries IBM-proprietary packages**: The IBM vLLM fork (`.spyre` suffix),
  `sendnn-inference==2.3.1` (IBM inference runtime, arch-conditional with separate
  platform markers but unified version), `torch-sendnn==1.2.5` (pre-built from
  private Pulp index, x86_64 and ppc64le), `torch-nnpa==1.5.0` (pre-built, s390x
  only), and `ibm-fms` (Foundation Model Stack, pinned in constraints). The wheels
  `spyremetrics` and `ibm-aiu-smi` are not yet present in any collection file but
  are anticipated. Note: `aiu-monitor`/`ibm-aiu-monitor` are NOT wheel collection
  packages — they live in the base image (blocked from all collections via
  `global-constraints.txt`). The Spyre RPM runtime stack (`SPYRE_VERSION`) is
  owned by the base image and is not visible here.
- **No Pulp publish path**: Wheels built by this pipeline are only accessible via
  GitLab CI artifact storage, not a customer-facing index. RFEs that require
  customer-accessible inference server wheels must also involve `rhai/pipeline`.
- **Builder version relationship reversed**: This repo is on builder `v39.4.0`,
  now 3 minor versions AHEAD of `rhai/pipeline`'s `v39.1.0`. Both are well behind
  the builder's latest `v42.0.2`. Consumer pins may diverge.
- **cpu-ubi9 `zen` extra is unconditional in this repo**: Unlike `rhai/pipeline`
  (which has a `platform_machine == 'x86_64'` marker because it builds cpu-ubi9
  on all 4 arches), `rhaiis/pipeline` builds cpu-ubi9 on x86_64 only. The `zen`
  extra (`vllm[audio,tensorizer,zen]==0.24.0+rhaiv.2`) has no platform marker —
  it applies unconditionally to the only arch built. RFEs adding ppc64le or s390x
  support for cpu-ubi9 in this repo would need to introduce platform-conditional
  forms.
- **Rubin is a wired-but-empty variant**: CI jobs exist for rubin-ubi9 (x86_64,
  aarch64) but no packages build yet — the requirements file is a placeholder.
  Strategies must not treat Rubin as an active build variant until requirements
  are populated.
- **vllm-omni is a new CUDA-only collection** (AIPCC-12521): Productizes
  `vllm-omni==0.24.0+rhaiv.1` alongside the standard vLLM CUDA build on
  cuda13.0-ubi9 (x86_64, aarch64). No publish path to rhai/pipeline exists yet
  for this collection.

## Context

This overlay was created to capture the state of the RHAIIS wheel pipeline at the
3.5 release boundary. The repo defines the vLLM ecosystem for each supported
hardware variant. The breadth of vLLM version divergence and the complexity of
the Neuron, Spyre, and Gaudi variants are the primary feasibility constraints for
RFEs proposing changes to the inference server. This overlay allows the
feasibility reviewer to know the current vLLM version per variant, the
IBM/AWS/Intel-specific package dependencies, and the boundary between build
specification (this repo) and distribution (`rhai/pipeline`). Updated 2026-07-30
by running the `update-rhaiis-pipeline-overlay` skill.
