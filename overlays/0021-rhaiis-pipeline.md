---
id: "0021"
title: RHAIIS Pipeline — vLLM Wheel Build Specification
status: active
created: 2026-07-15
affects:
  - platform
release:
  - "3.6"
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

- **Product version:** `3.6-fast2` (`PRODUCT_VERSION` in `product-version.yml`;
  unchanged). This is the trigger-rule product string, **not** a git branch —
  the working tree read for this refresh is on `main`.
- **Builder version pinned:** `v46.0.1` (`BUILDER_IMAGE_VERSION` in
  `builder-image-version.yml` on `main`). Every fondue `include:` in
  `.gitlab-ci.yml` — the `inputs-validator.yml` checks job plus all
  `ci-wheelhouse.yml` (collection × variant × arch) jobs — pulls at
  `ref: v46.0.1`. On `main` the `fondue` packageRule is enabled and a custom
  regex manager tracks `redhat/rhel-ai/wheels/fondue` releases; Renovate bumped
  this pin to `v46.0.1` (INFERENG-10565). A separate `3.6-fast2` *release
  branch* caps the builder at `/^v44\.0\.\d+$/` via a `renovate.json`
  `allowedVersions` rule; that `v44.0.x` pin lives only on that branch, not on
  `main`.
- **Repeatable build mode:** `ENABLE_REPEATABLE_BUILD_MODE` is commented out
  for all variants on `main` (not enabled); it is intended for release
  branches and must be uncommented when cutting a release branch.

### Variant Matrix

| Collection | Variant | Arch | vLLM Version | Torch | Notes |
|---|---|---|---|---|---|
| rhaiis | cuda13.0-ubi9 | x86_64, aarch64 | 0.28.0+rhaiv.3 | 2.13.0 | NeuralMagic fork; `cgraph-cuda13` extra; `cohere-melody==0.11.1` (INFERENG-10518) |
| rhaiis | rubin-ubi9 | x86_64, aarch64 | 0.26.0+rhaiv.5 | 2.11.0 | NeuralMagic fork; `cgraph-cuda13` extra; geospatial and plugins commented out for Vera Rubin tech preview (INFERENG-9846); llm-d packages include `nixl-cu13` and `deep_gemm` not in cuda13.0 |
| rhaiis | rocm7.14-ubi9 | x86_64 | 0.28.0+rhaiv.2 | 2.12.0 | NeuralMagic fork; `amd-aiter==0.1.19` |
| rhaiis | cpu-ubi9 | x86_64, s390x, ppc64le | 0.28.0+rhaiv.2 | 2.13.0 | NeuralMagic fork; no local-version arch suffix (plain `+rhaiv.2`); multi-arch; `zen` extra x86_64-only |
| rhaiis | gaudi-ubi9 | x86_64 | 0.26.0+rhaiv.8 | 2.11.0 | NeuralMagic-tagged fork + `vllm-gaudi==0.26.0`; constraints-rules uses `[!c]*` filter; tensorboard deps re-added (INFERENG-10912) |
| rhaiis | spyre-ubi9 | x86_64, ppc64le, s390x | 0.27.1+rhaiv.1.spyre | 2.11.0 | IBM fork; sendnn/IBM packages; spyremetrics + ibm-aiu-smi present |
| rhaiis | neuron-ubi9 | x86_64 | 0.16.0+rhaiv.13 | 2.9.1 | Furthest behind; neuronx stack pinned with git hashes; constraints-rules delegation disabled |
| rhaiis | tpu-ubi9 | x86_64 | 0.27.1+rhaiv.3 | 2.10.0 | No `.tpu` local-version suffix (plain `+rhaiv.3`); torch-2.10.0 constraints-rules |
| model-opt | cuda13.0-ubi9 | x86_64, aarch64 | N/A | 2.13.0 | llmcompressor 0.13.0 + speculators 0.7.0.1 |
| vllm-omni | cuda13.0-ubi9 | x86_64, aarch64 | 0.26.0+rhaiv.5 (+vllm-omni 0.26.0+rhaiv.7) | 2.11.0 | AIPCC-12521: AIPCC vllm-omni productization |

**vLLM versions are unchanged since the previous refresh (2026-09-22)** — that
refresh already captured the 0.28.0 CUDA/ROCm/CPU bumps and the 0.27.1
Spyre/TPU bumps. CUDA is furthest ahead at `0.28.0+rhaiv.3`; ROCm and CPU are at
`0.28.0+rhaiv.2`; Spyre (`0.27.1+rhaiv.1.spyre`) and TPU (`0.27.1+rhaiv.3`) sit
at 0.27.1; Gaudi (`0.26.0+rhaiv.8`), Rubin (`0.26.0+rhaiv.5`), and vllm-omni
(base rhaiv.5 / omni rhaiv.7) remain at 0.26.0; Neuron is the outlier at
`0.16.0+rhaiv.13`. The material changes this cycle are at the builder/CI layer
(fondue pin bumped to `v46.0.1` on `main`, INFERENG-10565) and a Rubin
constraint that moved into the builder (see below), not the per-variant vLLM
pins.

Torch baselines remain fragmented across five minors: cuda13.0, cpu, and
model-opt on `torch-2.13.0`; rocm7.14 on `torch-2.12.0`; rubin, spyre, gaudi,
and vllm-omni on `torch-2.11.0`; tpu on `torch-2.10.0`; neuron on 2.9.1
(explicit). Cross-variant features must still be ported to each active fork
version/build string.

Note: Rubin is not a placeholder — requirements and constraints are populated,
though geospatial and plugin packages are commented out pending Vera Rubin CUDA
stack availability (INFERENG-9846).

### Package Content by Variant

**cuda13.0-ubi9** (most package-rich):
- `vllm[audio,tensorizer,cgraph-cuda13]==0.28.0+rhaiv.3`
- `cohere-melody==0.11.1` (INFERENG-10518: North Mini's cohere_command4 tool and
  reasoning parsers require this runtime)
- `vllm-bart-plugin==0.6.0` (INFERENG-6019: BART plugin for custom BART model support)
- `vllm-beam-search-plugin==0.1.4` (INFERENG-9921: beam search decoding support)
- FlashInfer: `flashinfer-cubin`, `flashinfer-jit-cache`, `flashinfer-python`
- llm-d / disaggregated inference: `nixl==1.3.1` (AIPCC-28994), `deep_ep==2.0.0+rhaiv.0`,
  `pplx-kernels==0.0.1` (INFERENG-1925)
- `bitsandbytes`, `triton`, `timm>=1.0.17`, `numba` (AIPCC-5334);
  `xformers` (AIPCC-2152: aarch64 missing dependency)
- `opentelemetry-exporter-prometheus` (INFERENG-2949)
- Geospatial: `algorithm-nexus[product]==0.2.3` (INFERENG-8558),
  `torchgeo` (pulled directly)
- CVE/security: `setuptools>=80.10.2` (AIPCC-9947)
- Constraints (`constraints.txt`): `aiohttp>=3.13.3`, `urllib3>=2.6.3`
  (INFERENG-4285 CVE), `boto3==1.43.46` (INFERENG-4923), `numba==0.65.0`
  (INFERENG-6026), `numpy<2.5` (AIPCC-28010), `torchgeo<0.10` (INFERENG-10155),
  `transformers<5.15.0` (INFERENG-9834), `xgrammar<0.2.5` (INFERENG-10473),
  `grpcio-reflection<1.82.0` + `protobuf==6.33.6` (INFERENG-9832),
  `uv-build<0.12.6` (INFERENG-10262), `quack-kernels==0.6.4` (INFERENG-10588),
  `nvidia-cudnn-frontend<1.29.0` (INFERENG-10716),
  `nvidia-cutlass-dsl==4.6.2` (INFERENG-10727)

**rubin-ubi9** (populated; Vera Rubin CUDA variant):
- `vllm[audio,tensorizer,cgraph-cuda13]==0.26.0+rhaiv.5`
- FlashInfer: `flashinfer-cubin`, `flashinfer-jit-cache`, `flashinfer-python`
- `xformers` (AIPCC-2152), `timm>=1.0.17`, `bitsandbytes`, `triton`, `numba`
- llm-d stack: `nixl==1.3.1`, `nixl-cu13==1.3.1` (AIPCC-28994; both present,
  distinct from cuda13.0 which has only `nixl` without `-cu13`),
  `deep_gemm==2.5.0+rhaiv.0`, `deep_ep==2.0.0+rhaiv.0`, `pplx-kernels==0.0.1`
- `opentelemetry-exporter-prometheus` (INFERENG-2949)
- Geospatial and plugin packages (`vllm-bart-plugin`, `vllm-beam-search-plugin`,
  `geobenchv2`, `algorithm-nexus`, `torchgeo`) are commented out for Vera Rubin
  tech preview (INFERENG-9846)
- Constraints (`constraints.txt`): `aiohttp>=3.13.3`, `urllib3>=2.6.3`,
  `boto3==1.43.46`, `numba==0.65.0`, `numpy<2.5`, `torchgeo<0.10`,
  `transformers<5.15.0`, `uv-build<0.12.6`, `quack-kernels==0.6.4`.
  The `nvidia-cudnn-frontend<1.29.0` cap is now **commented out** (INFERENG-10565:
  as of builder `v46.0.1`, the same version is pinned in the builder's
  `torch-2.11.0/rubin-ubi9/constraints.txt` under AIPCC-31744)

**rocm7.14-ubi9:**
- `vllm[audio,tensorizer]==0.28.0+rhaiv.2`
- `amd-aiter==0.1.19` — AMD attention/iteration kernel (required)
- `flash-attn`, `triton`, `torch`, `torchaudio`, `torchvision` — all unpinned
  in requirements.txt; versions resolved by builder from the `torch-2.12.0`
  constraints-rules collection
- `timm>=1.0.17`, `bitsandbytes`, `numba` (AIPCC-5334)
- `opentelemetry-exporter-prometheus` (AIPCC-6630)
- Constraints (`constraints.txt`): `grpcio==1.78.0` / `grpcio-reflection==1.78.0`
  (INFERENG-5970), `yarl<1.24` (INFERENG-7300), `numba==0.65.0` (INFERENG-7932),
  `onnx>=1.21.0` (INFERENG-8010 CVE), `transformers<5.17.0`

**cpu-ubi9** (x86_64, s390x, ppc64le):
- `vllm[audio,tensorizer,zen]==0.28.0+rhaiv.2; platform_machine == 'x86_64'`
  and `vllm[audio,tensorizer]==0.28.0+rhaiv.2; platform_machine != 'x86_64'`
  — no local-version arch suffix (plain `+rhaiv.2`); the `zen` extra (zentorch
  for AMD EPYC CPUs) is x86_64-only via the platform marker
- `timm>=1.0.17`; geospatial stack (`geobenchv2`, `terrakit`, `terratorch`,
  `torchgeo`) all gated `; platform_machine == 'x86_64'`
- `setuptools>=80.10.2`
- Constraints (`constraints.txt`): `boto3==1.43.46` (INFERENG-4923),
  `terrakit<0.2.0; platform_machine == 'x86_64'` (AIPCC-19339),
  `aiohttp>=3.13.3`, `urllib3>=2.6.3` (INFERENG-4285 CVE),
  `llguidance>=1.7.0,<1.8.0` (AIPCC-18235/AIPCC-29676),
  `matplotlib<3.11.0` (TEMP: build job fix),
  `transformers<5.17.0` (INFERENG-9834), `uv-build<0.12.6` (INFERENG-10262)

**gaudi-ubi9:**
- `vllm==0.26.0+rhaiv.8` + `vllm-gaudi==0.26.0` — carries the NeuralMagic-style
  `+rhaiv.N` tag
- `torch`, `torchvision`, `torchaudio`, `torch-tb-profiler` (unpinned)
- `absl-py`, `markdown`, `tensorboard-data-server`, `werkzeug` — explicitly
  listed to restore the tensorboard dependency closure that dropped out of the
  3.6-fast2 rebuild (INFERENG-10912)
- Habana ecosystem: `habana-torch-plugin`, `habana-gpu-migration`, `habana-pyhlml`,
  `habana-torch-dataloader`, `intel-transformer-engine`, `neural-compressor-pt`
- `symengine` (undeclared habana-torch-plugin dependency)
- Constraints (`constraints.txt`): `transformers<5.15.0` (INFERENG-9834),
  `yarl<1.24` (AIPCC-21773), `propcache<0.5` (AIPCC-21773),
  `cryptography>=48.0.1` (GHSA-537c-gmf6-5ccf CVE fix), `cloudpickle<3.1`
- `constraints-rules.txt` uses `torch-2.11.0 [!c]*` — excludes packages whose
  name starts with `c` from builder delegation

**neuron-ubi9** (most constrained):
- `vllm[tensorizer]==0.16.0+rhaiv.13` + `vllm-neuron==0.5.3` (INFERENG-10060:
  no-op trigger for neuron wheel rebuild; INFERENG-9844: vllm-neuron 0.5.3 for
  Neuron SDK 2.31)
- `timm>=1.0.17`, `setuptools>=80.10.2`
- Full neuronx stack pinned with embedded git commit hashes (in
  `constraints.txt`): `torch==2.9.1`, `torchaudio==2.9.1`, `torchcodec==0.9.1`
  (AIPCC-12191), `torch-xla==2.9.0`, `torchvision==0.24.1`, `triton==3.5.1`,
  `torch-neuronx==2.9.0.2.15.32035+de43f57c`,
  `libneuronxla==2.2.17544.0+fb9962bf`, `neuronx-cc==2.26.6360.0+6f180f47`,
  `neuronx-distributed==0.19.28492+435aae2b`,
  `neuronx-distributed-inference==0.10.18399+ed62453e`,
  `nki==0.5.0+28631259367.ga768afa6`
- Torch pinned at 2.9.1 (not the 2.13.0/2.12.0/2.11.0/2.10.0 used by other variants)
- Constraints-rules API is **disabled** (the `torch-2.9.1 [!v]*` rule is
  commented out) — all pins are explicit in `constraints.txt` (INFERENG-5249)
- Additional constraints: `vllm==0.16.0+rhaiv.13` and `vllm-neuron==0.5.3`
  (also pinned in constraints, INFERENG-5249), `transformers<5` (AIPCC-9443),
  `urllib3>=2.6.3` (INFERENG-4285), `yarl<1.24.2`,
  `prometheus-fastapi-instrumentator>=8.0.1` (INFERENG-8555)

**spyre-ubi9** (multi-arch: ppc64le, s390x, x86_64):
- `vllm[tensorizer]==0.27.1+rhaiv.1.spyre`
- `torch`, `torchvision`, `torchaudio` (unpinned)
- `sendnn-inference==2.6.1` — IBM inference runtime, a single unconditional line
  (no arch marker)
- `torch-sendnn==1.3.1` (AIPCC-14853), `depyf` (AIPCC-3886), `torchao`
  (AIPCC-4976), `flash-linear-attention`, `pytest-asyncio`, `hf-xet`
- `torch-nnpa==1.5.0; platform_machine == 's390x'` (AIPCC-18989)
- `triton; platform_machine == 'x86_64'`, `intel-openmp; platform_machine == 'x86_64'`,
  `intel_cmplr_lib_ur; platform_machine == 'x86_64'`
- `llguidance` (AIPCC-27980)
- `ibm-aiu-smi==1.3.0`, `spyremetrics==0.5.0` (INFERENG-9813)
- `timm>=1.0.17`, `opentelemetry-exporter-prometheus; platform_machine != 's390x'`
  (AIPCC-13600)
- `fms-model-optimizer` is not a direct requirement — it appears only in the
  comment justifying the `torchao` pin; there is no unpinned `ibm-fms` alongside
  the pinned one (no dual-build pattern present)
- Constraints (`constraints.txt`): `intel-openmp==2024.2.1`,
  `intel-cmplr-lib-ur==2024.2.1`, `tokenizers==0.22.2` (AIPCC-11994),
  `torchao==0.11.0` (must match fms-model-optimizer[fp8-infer]),
  `llguidance>=1.7.0,<1.8.0` (AIPCC-18235),
  `prometheus-fastapi-instrumentator>=8.0.1`, `ibm-fms==1.13.1` (AIPCC-27740)

**tpu-ubi9:**
- `vllm[tensorizer]==0.27.1+rhaiv.3` (no `.tpu` local-version suffix)
- `llmcompressor` remains commented out (AIPCC-4341)
- `timm>=1.0.17`, `setuptools>=80.10.2`
- Constraints (`constraints.txt`): `urllib3>=2.6.3` (INFERENG-4285),
  `transformers<5.15.0` (INFERENG-9834)
- Uses `torch-2.10.0 *` constraints-rules (two to three torch minors behind the
  torch-2.12.0/2.13.0 variants)

**model-opt/cuda13.0-ubi9:**
- `llmcompressor==0.13.0`
- `speculators==0.7.0.1`
- `setuptools>=80.10.2`, `pillow>=12.1.1`
- Constraints (`constraints.txt`, INFERENG-8847): `loguru==0.7.3`,
  `PyYAML==6.0.3`, `numpy==2.4.6`, `requests==2.34.2`, `tqdm==4.68.2`,
  `transformers>=5.9.0,<=5.14.1`, `compressed-tensors==0.18.0`,
  `datasets==5.0.0`, `auto-round>=0.14.1,<=0.14.2`, `accelerate==1.13.0`,
  `nvidia-ml-py==13.610.43`
- `constraints-rules.txt` uses `torch-2.13.0 *`

**vllm-omni/cuda13.0-ubi9:**
- `vllm-omni==0.26.0+rhaiv.7` (AIPCC-12521)
- `vllm[audio,tensorizer,cgraph-cuda13]==0.26.0+rhaiv.5`
- FlashInfer, `triton`, `xformers`, `bitsandbytes`, `timm>=1.0.17`, `numba`
- `setuptools>=80.10.2`
- Constraints (`constraints.txt`): `grpcio==1.78.0` / `grpcio-reflection==1.78.0`
  (INFERENG-5970), `aiohttp>=3.13.3`, `urllib3>=2.6.3` (INFERENG-4285),
  `boto3==1.43.46` (INFERENG-4923), `numba==0.65.0` (INFERENG-6026),
  `numpy<2.5` (AIPCC-28010), `transformers<5.15.0` (INFERENG-9834),
  `quack-kernels==0.6.4` (INFERENG-10588),
  `nvidia-cudnn-frontend<1.29.0` (INFERENG-10716)
- `constraints-rules.txt` uses `torch-2.11.0 *`

### Constraints-Rules Delegation

Nine of the ten collection × variant combinations opt in to a `torch-N` builder
constraints collection via `constraints-rules.txt`; torch delegation is
**fragmented across five torch minors**:

- `torch-2.13.0 *`: cuda13.0-ubi9 (rhaiis), cpu-ubi9, model-opt/cuda13.0-ubi9 (3)
- `torch-2.12.0 *`: rocm7.14-ubi9 (1)
- `torch-2.11.0 *`: rubin-ubi9, spyre-ubi9, vllm-omni/cuda13.0-ubi9 (3)
- `torch-2.11.0 [!c]*`: gaudi-ubi9 (1) — the `[!c]*` filter excludes packages
  whose name starts with 'c' from builder delegation
- `torch-2.10.0 *`: tpu-ubi9 (1) — two to three torch minors behind the others

Exception: `neuron-ubi9` disables delegation entirely (the `torch-2.9.1 [!v]*`
rule is commented out); all pins are explicit in `constraints.txt` (INFERENG-5249).

(Note: some `constraints-rules.txt` header comments still say "torch-2.11.0
collection" even where the active rule now reads `torch-2.13.0 *` — the rule
line, not the stale comment, is authoritative.)

### Pipeline Flow

**Stages:** checks → bootstrap → build → release → lint → notify (the release
stage is for internal CI release/lint bookkeeping, not Pulp publish).

On `main`, all (collection × variant × arch) combinations include
`pipeline-api/ci-wheelhouse.yml` from `fondue@v46.0.1` (INFERENG-10565); the
`checks` stage additionally includes `pipeline-api/inputs-validator.yml` from the
same `fondue@v46.0.1` ref, an AI code-review job, and a `central-linter` template
at `v0.1.0`.

**No publish jobs exist** in this repo. Artifact lifecycle:
1. `rhaiis/pipeline` builds wheels → stored in GitLab CI artifact storage
2. `rhai/pipeline` (separately triggered) publishes to Pulp indexes

`seccomp.json` in this repo provides the Linux seccomp BPF syscall filter
applied to wheel build containers.

### Update Automation

Renovate (`renovate.json`) tracks vLLM per variant through per-variant **custom
regex managers** (one manager per `collections/.../requirements.txt`), while the
built-in `pip_requirements` manager is globally disabled for the `vllm` and
`vllm-omni` package names across `collections/rhaiis/*/requirements.txt` and
`collections/vllm-omni/*/requirements.txt` (no branch scope — all branches). The
custom regex managers are the real vLLM tracking mechanism; each pulls tags from
the NeuralMagic `nm-vllm-ent` mirror (vllm-omni additionally uses
`nm-vllm-omni-ent`).

**Base enable rule:** a `nm-vllm-ent` packageRule with **no** `matchBaseBranches`
(so it applies to every branch, including `main`) sets `enabled: true` /
`groupName: vllm-updates` / `ignoreUnstable: false`. A parallel all-branch rule
enables `nm-vllm-omni-ent` (`vllm-omni-updates`).

**`enabled: false` disable matrix — release branches only.** Every `nm-vllm-ent`
disable rule is scoped by `matchBaseBranches` to a specific release branch.
`matchBaseBranches` is literal; **none of these rules lists `main`**:

| Branch | Variants disabled (`enabled: false`) |
|---|---|
| 3.3 | cpu-ubi9, cuda12.9-ubi9, neuron-ubi9, tpu-ubi9 |
| 3.4 | gaudi-ubi9, neuron-ubi9, tpu-ubi9 |
| 3.5 | gaudi-ubi9, neuron-ubi9, tpu-ubi9, rubin-ubi9, vllm-omni/cuda13.0-ubi9 |

**On `main`: no `nm-vllm-ent` disable rule applies.** Because no `enabled: false`
rule lists `main`, the base enable rule stands for every variant on `main`.
Renovate can therefore open vLLM bump MRs on `main` for **neuron, tpu, and
gaudi** (as well as cuda13.0, rubin, rocm7.14, cpu, spyre, and vllm-omni),
subject only to each variant's custom-regex version-format match. These variants
are **not** excluded on `main`; their disables exist solely on the release
branches listed above.

- **neuron-ubi9** — disabled on 3.3, 3.4, and 3.5; Renovate-trackable on `main`
  (its custom regex matches `0.16.0+rhaiv.13`).
- **tpu-ubi9** — disabled on 3.3, 3.4, and 3.5; Renovate-trackable on `main`
  (its custom regex allows an optional `.tpu` suffix, so it matches the current
  suffix-less `0.27.1+rhaiv.3`).
- **gaudi-ubi9** — disabled on **3.4 and 3.5** (not 3.3, where gaudi does not
  appear in the disable list); Renovate-trackable on `main`. Gaudi's custom
  regex requires a `+rhai(?:v\.)?\d+(?:\.gaudi)?` local-version tag; the current
  `vllm==0.26.0+rhaiv.8` carries that tag, so the regex matches and Renovate can
  propose updates on `main`. (Had gaudi used an untagged upstream version such as
  `0.21.0`, the regex would silently fail to match — a format-based non-match,
  not a packageRule exclusion. That is not the current situation.)

**Per-branch `allowedVersions` caps** further constrain the *enabled*
`nm-vllm-ent` variants on release branches: 3.3 → `0.13.x` (cuda13.0, rocm6.4)
and `0.11.0` (spyre); 3.4 → `0.18.x` (cuda13.0, rocm7.1, cpu, spyre); 3.5 →
`0.24.0` (cuda13.0, rocm7.14, cpu, spyre). `main` has no `allowedVersions` cap.

**Builder image version:** on `main`, `BUILDER_IMAGE_VERSION` is tracked from
`redhat/rhel-ai/wheels/fondue` releases via a custom regex manager, and the
`fondue` packageRule is enabled for `main` (`builder-image` group); the current
value is `v46.0.1` (INFERENG-10565). Release branches instead pin the builder
through `redhat/rhel-ai/wheels/builder` `allowedVersions` patterns, one entry per
branch from 3.0 through 3.5 plus a `3.6-fast2` entry (3.5 → `/^v39\.4\.\d+$/`;
3.6-fast2 → `/^v44\.0\.\d+$/`). There is no main-branch `allowedVersions`
restriction on the builder package.

## Impact on Strategies

- **vLLM version fragmentation persists**: eight distinct version strings are in
  play across the variants. CUDA is furthest ahead at `0.28.0+rhaiv.3`; ROCm and
  CPU are at `0.28.0+rhaiv.2`; Spyre (`0.27.1+rhaiv.1.spyre`) and TPU
  (`0.27.1+rhaiv.3`) sit at 0.27.1; Gaudi (`0.26.0+rhaiv.8`), Rubin
  (`0.26.0+rhaiv.5`), and vllm-omni (base rhaiv.5 / omni rhaiv.7) remain at
  0.26.0. Neuron is the outlier at `0.16.0+rhaiv.13` — twelve minor releases
  behind the 0.28.0 mainstream, and by far the furthest behind. Torch baselines
  are also fragmented (2.9.1 / 2.10.0 / 2.11.0 / 2.12.0 / 2.13.0). Cross-variant
  features must still be ported to each active fork version/build string.
- **Gaudi uses the NeuralMagic-tagged vLLM plus a separate plugin**: gaudi pins
  `vllm==0.26.0+rhaiv.8` (the NeuralMagic `+rhaiv` tag) together with
  `vllm-gaudi==0.26.0`. Because the version carries the `+rhaiv` tag, Renovate's
  gaudi custom regex matches it and vLLM bumps are **auto-trackable on `main`**.
  On the release branches, gaudi vLLM updates are disabled (`enabled: false`) on
  **both 3.4 and 3.5**, so on those branches gaudi is manually updated. Gaudi
  also uniquely uses `torch-2.11.0 [!c]*` constraints-rules delegation, excluding
  packages starting with 'c'; strategies relying on complete torch delegation for
  Gaudi should verify which packages are excluded. This cycle also re-added
  tensorboard closure packages (absl-py, markdown, tensorboard-data-server,
  werkzeug) after the 3.6-fast2 rebuild dropped them (INFERENG-10912).
- **Neuron is still the most constrained variant**: Torch remains at 2.9.1 while
  other variants have moved to 2.10.0–2.13.0. Constraints-rules delegation is
  disabled (the `torch-2.9.1 [!v]*` rule is commented out), so the full neuronx
  stack carries explicit pins, several with embedded git commit hashes. The
  variant is still a no-op rebuild trigger (INFERENG-10060) with no vLLM version
  movement. Any RFE touching Neuron requires explicit pin management. Note that
  although vLLM updates are disabled on 3.3/3.4/3.5, neuron is *not* disabled on
  `main` — its custom regex still matches `0.16.0+rhaiv.13`.
- **Spyre carries a multi-arch IBM-proprietary wheel stack**: the IBM vLLM fork
  (`.spyre` suffix, `0.27.1+rhaiv.1.spyre`), `sendnn-inference==2.6.1` (IBM
  inference runtime, a single unconditional line — no arch marker),
  `torch-sendnn==1.3.1` (pre-built from private index, no arch marker),
  `torch-nnpa==1.5.0` (pre-built, s390x only), `ibm-fms==1.13.1` (Foundation
  Model Stack, constraints.txt), `spyremetrics==0.5.0`, and `ibm-aiu-smi==1.3.0`.
  `aiu-monitor` is NOT a wheel collection package — it lives in the base image.
  The Spyre RPM runtime stack (`SPYRE_VERSION`) is owned by the base image and is
  not visible here.
- **No Pulp publish path**: Wheels built by this pipeline are only accessible via
  GitLab CI artifact storage, not a customer-facing index. RFEs requiring
  customer-accessible inference server wheels must also involve `rhai/pipeline`.
- **Builder pin is now current on `main`; the lag survives only on the release
  branch**: `main` pins `fondue@v46.0.1` (`BUILDER_IMAGE_VERSION`, INFERENG-10565).
  The earlier two-minor-version lag (v44.0.x) now exists only on the `3.6-fast2`
  *release branch*, whose
  `renovate.json` `allowedVersions` cap (`/^v44\.0\.\d+$/`) prevents Renovate from
  bumping past `v44.0.x` there. Unlike `rhai/pipeline`, which builds against the
  fondue-monorepo builder resolved dynamically at tip-of-`main` (see
  `0020-rhai-pipeline`), this repo pins a fixed fondue release ref.
- **cpu-ubi9 `zen` extra remains platform-conditional**: the `vllm[...,zen,...]`
  line is gated `; platform_machine == 'x86_64'`; the non-x86_64 line omits
  `zen`. RFEs that assume `zen` applies unconditionally are incorrect.
- **Rubin is an active build variant but a reduced tech preview**: `rubin-ubi9`
  has real package definitions (vLLM, FlashInfer, llm-d stack including
  `nixl-cu13` and `deep_gemm` that are absent in `cuda13.0`, xformers, timm,
  bitsandbytes), but geospatial and plugin packages are commented out pending the
  Vera Rubin CUDA stack (INFERENG-9846). vLLM updates on Rubin are disabled on
  3.5 but trackable on `main`. As of builder `v46.0.1` the
  `nvidia-cudnn-frontend<1.29.0` cap was removed from rubin's `constraints.txt`
  (commented out) because the builder now pins the same version in its
  `torch-2.11.0/rubin-ubi9/constraints.txt` under AIPCC-31744 (INFERENG-10565).
- **vllm-omni remains a CUDA-only collection** (AIPCC-12521): productizes
  `vllm-omni==0.26.0+rhaiv.7` alongside the standard vLLM CUDA build on
  cuda13.0-ubi9 (x86_64, aarch64), tracked by its own `nm-vllm-omni-ent` manager.
  Disabled on 3.5, trackable on `main`. No publish path to `rhai/pipeline` exists
  yet.
- **Python, gcc, and TensorFlow versions are not visible in this repo** — those
  are owned by the `builder`/base image. Any RFE citing specific versions for
  these must be validated against the builder or base-image repos (see
  `0019-wheels-builder`), not this overlay.

## Context

This overlay was created to capture the state of the RHAIIS wheel pipeline at the
3.5 release boundary and is maintained through 3.6. The repo defines the vLLM
ecosystem for each supported hardware variant. The breadth of vLLM version
divergence and the complexity of the Neuron, Spyre, and Gaudi variants are the
primary feasibility constraints for RFEs proposing changes to the inference
server. This overlay allows the feasibility reviewer to know the current vLLM
version per variant, the IBM/AWS/Intel-specific package dependencies, and the
boundary between build specification (this repo) and distribution
(`rhai/pipeline`). Updated 2026-09-23 by running the
`update-rhaiis-pipeline-overlay` skill against the `main` branch (product version
`3.6-fast2`).
