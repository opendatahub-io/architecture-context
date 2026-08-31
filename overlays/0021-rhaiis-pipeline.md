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

- **Product version:** `3.6-fast1` (was `3.5`)
- **Builder version pinned:** `v43.3.0` (was `v39.4.0`). As of the last refresh
  of the sibling [`0020-rhai-pipeline`](0020-rhai-pipeline.md) overlay
  (2026-07-30), `rhai/pipeline` was pinned to `v39.1.0` — if still current,
  this repo is now ~4 minor versions ahead of it. The sibling
  [`0019-wheels-builder`](0019-wheels-builder.md) overlay (also last refreshed
  2026-07-30) documented the builder's latest release as `v42.0.2`; this
  repo's `v43.3.0` is already past that, so the wheels-builder overlay is due
  for its own refresh and this comparison should be treated as stale.
- **Repeatable build mode:** `ENABLE_REPEATABLE_BUILD_MODE` is commented out
  for all variants on the main branch (not enabled); it is intended for release
  branches and must be uncommented when cutting a release branch.

### Variant Matrix

| Collection | Variant | Arch | vLLM Version | Torch | Notes |
|---|---|---|---|---|---|
| rhaiis | cuda13.0-ubi9 | x86_64, aarch64 | 0.26.0+rhaiv.1 | 2.11.0 | NeuralMagic fork; `cgraph-cuda13` extra; `.cuda` local-version suffix has been dropped (plain `+rhaiv.N` again) |
| rhaiis | rubin-ubi9 | x86_64, aarch64 | TBD (placeholder) | TBD | Still awaiting Rubin CUDA stack — requirements/constraints unchanged since last refresh |
| rhaiis | rocm7.14-ubi9 | x86_64 | 0.26.0+rhaiv.1 | 2.11.0 | NeuralMagic fork |
| rhaiis | cpu-ubi9 | x86_64, s390x, ppc64le | 0.26.0+rhaiv.3.cpu | 2.11.0 | NeuralMagic fork; new `.cpu` local-version suffix; now multi-arch (was x86_64-only) |
| rhaiis | gaudi-ubi9 | x86_64 | 0.26.0+rhaiv.4 | 2.11.0 | **Now carries a NeuralMagic-style `+rhai` tag** (previously plain upstream `0.24.0`, no tag) |
| rhaiis | spyre-ubi9 | x86_64, ppc64le, s390x | 0.25.1+rhaiv.1.spyre | 2.11.0 | IBM fork; sendnn packages; two new IBM wheels landed (spyremetrics, ibm-aiu-smi) |
| rhaiis | neuron-ubi9 | x86_64 | 0.16.0+rhaiv.12 | 2.9.1 | Still furthest behind; neuronx stack pinned with git hashes, all bumped |
| rhaiis | tpu-ubi9 | x86_64 | 0.26.0+rhaiv.2.tpu | 2.10.0 | Caught up to CUDA/ROCm/CPU minor (was 3 minors behind at 0.21.0) |
| model-opt | cuda13.0-ubi9 | x86_64, aarch64 | N/A | 2.11.0 | llmcompressor 0.12.0.1 + speculators 0.6.0.1 |
| vllm-omni | cuda13.0-ubi9 | x86_64, aarch64 | 0.26.0+rhaiv.1 (+vllm-omni 0.26.0+rhaiv.2) | 2.11.0 | AIPCC-12521: AIPCC vllm-omni productization |

CUDA 13.0, ROCm, and vllm-omni's vLLM component all advanced to `0.26.0` (from
`0.24.0`); the `.cuda` suffix used at the last refresh is no longer present on
the CUDA build string. TPU jumped from `0.21.0+rhaiv.13.tpu` (3 minors behind)
to `0.26.0+rhaiv.2.tpu` — now level with CUDA/ROCm/CPU. Spyre advanced to
`0.25.1+rhaiv.1.spyre` (one minor behind the 0.26.0 line). Gaudi advanced to
`0.26.0+rhaiv.4` **and gained a `+rhai` local-version tag it did not have
before** (see Update Automation). Neuron remains unchanged and furthest behind
(0.16.0 vs 0.26.0 mainstream, 10 minor releases).

Note: `cpu-ubi9` in this repo now builds on **x86_64, s390x, and ppc64le**
(previously x86_64 only) — it has caught up to `rhai/pipeline`'s 4-arch cpu
matrix (no aarch64 job is defined here). This also resolves the `zen` extra
question below.

### Package Content by Variant

**cuda13.0-ubi9** (most package-rich):
- `vllm[audio,tensorizer,cgraph-cuda13]==0.26.0+rhaiv.1`
- `vllm-bart-plugin==0.6.0` (INFERENG-6019: BART plugin for custom BART model support)
- `vllm-beamsearch-plugin==0.1.0` (INFERENG-9921: new — beam search decoding support)
- FlashInfer: `flashinfer-cubin`, `flashinfer-jit-cache`, `flashinfer-python`
- llm-d / disaggregated inference: `nixl`, `nixl-cu13`, `deep_ep==2.0.0+rhaiv.0`,
  `pplx-kernels==0.0.1` (INFERENG-1925)
- `bitsandbytes`, `triton`, `timm>=1.0.17`, `numba` (AIPCC-5334);
  `xformers` (AIPCC-2152: aarch64 missing dependency)
- `opentelemetry-exporter-prometheus` (INFERENG-2949)
- Geospatial: `geobenchv2`, `algorithm-nexus[product]==0.2.2` (INFERENG-8558:
  replaces direct `terrakit`/`terratorch` deps), `torchgeo` (AIPCC-8393)
- CVE/security: `setuptools>=80.10.2` (AIPCC-9947), `aiohttp>=3.13.3`,
  `urllib3>=2.6.3` (INFERENG-4285)
- Constraints: `boto3==1.43.46` (INFERENG-4923: botocore/aiobotocore compat),
  `numba==0.65.0` (INFERENG-6026: match vllm midstream requirement, prevent
  llvmlite conflict), `numpy<2.5` (AIPCC-28010: ABI compat). The `terrakit`
  version cap seen at the last refresh is gone now that `terrakit` is pulled
  transitively via `algorithm-nexus`.

**vllm-omni/cuda13.0-ubi9:**
- `vllm-omni==0.26.0+rhaiv.2` (AIPCC-12521: AIPCC vllm-omni productization)
- `vllm[audio,tensorizer,cgraph-cuda13]==0.26.0+rhaiv.1` (same extras/version as rhaiis CUDA)
- FlashInfer, `triton`, `xformers`, `bitsandbytes`, `timm>=1.0.17`, `numba`
- Constraints: same CVE/compat pins as rhaiis cuda13.0-ubi9 (`grpcio==1.78.0`,
  `boto3==1.43.46`, `numba==0.65.0`, `numpy<2.5`, `aiohttp`/`urllib3` CVE pins)

**rocm7.14-ubi9:**
- `vllm[audio,tensorizer]==0.26.0+rhaiv.1`
- `amd-aiter==0.1.16.post3` — AMD attention/iteration kernel (required; was 0.1.13.post1)
- `flash-attn`, `triton`, `torch`, `torchaudio`, `torchvision` — **all unpinned**
  in requirements.txt; actual versions are resolved by the builder from
  whatever the `torch-2.11.0` constraints-rules collection (owned by
  `builder`, not visible in this repo) and PyPI/index metadata provide. There
  is no explicit torch, triton, or flash-attn version pin anywhere in this
  variant's requirements.txt, constraints.txt, or constraints-rules.txt.
- `timm>=1.0.17`, `bitsandbytes`, `numba` (AIPCC-5334)
- `opentelemetry-exporter-prometheus` (AIPCC-6630: pre-release-only on PyPI, must pin)
- Constraints: `grpcio==1.78.0` / `grpcio-reflection==1.78.0` (INFERENG-5970
  prevents version conflict), `yarl<1.24` (INFERENG-7300 avoids setuptools>=82
  requirement), `onnx>=1.21.0` (INFERENG-8010, CVE fix), `numba==0.65.0` (INFERENG-7932)
- No `python`, `gcc`, or `tensorflow` reference exists anywhere in this
  variant's files, or anywhere in this repo — those are owned by the builder
  image / base image, not by `rhaiis/pipeline`.

**cpu-ubi9** (now x86_64, s390x, ppc64le):
- `vllm[audio,tensorizer,zen]==0.26.0+rhaiv.3.cpu; platform_machine == 'x86_64'`
  and `vllm[audio,tensorizer]==0.26.0+rhaiv.3.cpu; platform_machine != 'x86_64'`
  — the `zen` extra (zentorch for AMD EPYC CPUs) **is now platform-conditional**,
  gated on `platform_machine == 'x86_64'`, because this repo builds cpu-ubi9 on
  3 architectures as of this refresh (see Impact on Strategies)
- `timm>=1.0.17`; geospatial stack (`geobenchv2`, `terrakit`, `terratorch`,
  `torchgeo`) is now also gated `; platform_machine == 'x86_64'` (previously
  unconditional, since the variant was x86_64-only)
- `setuptools>=80.10.2`
- Constraints: `boto3==1.43.46` (INFERENG-4923), `terrakit<0.2.0; platform_machine == 'x86_64'`
  (AIPCC-19339: tacoreader conflict, now also arch-gated), `aiohttp>=3.13.3`,
  `urllib3>=2.6.3` (INFERENG-4285 CVE), `llguidance>=1.7.0,<1.8.0` (AIPCC-18235 /
  AIPCC-29676: new — caps below vllm 0.26.0's llguidance requirement),
  `matplotlib<3.11.0` (TEMP: build job fix)

**gaudi-ubi9** (structurally shifted since last refresh):
- `vllm==0.26.0+rhaiv.4` + `vllm-gaudi==0.26.0` — **this vLLM version now
  carries a `+rhaiv.4` local-version tag**. At the last refresh this variant
  used plain upstream `vllm==0.24.0` with no tag; that is no longer the case
  (see Update Automation for why this matters)
- Habana ecosystem: `habana-torch-plugin`, `habana-gpu-migration`, `habana-pyhlml`,
  `habana-torch-dataloader`, `intel-transformer-engine`, `neural-compressor-pt`,
  `torch-tb-profiler`
- `symengine` (undeclared habana-torch-plugin dependency)
- Constraints: `yarl<1.24`, `propcache<0.5` (AIPCC-21773: required until
  Cython>=3.2.0 is available) — unchanged

**rubin-ubi9** (still placeholder):
- Requirements and constraints files are unchanged since last refresh: only a
  placeholder comment, "Packages will be populated in a follow-up MR once the
  Rubin CUDA stack is available."
- Jobs are defined in `.gitlab-ci.yml` for x86_64 and aarch64, but no packages
  will build until the requirements are populated.

**neuron-ubi9** (most constrained; all pins bumped):
- `vllm[tensorizer]==0.16.0+rhaiv.12` + `vllm-neuron==0.5.3` (was 0.5.1;
  INFERENG-9844: bumped for Neuron SDK 2.31)
- `timm>=1.0.17`, `setuptools>=80.10.2`
- Full neuronx stack pinned with embedded git commit hashes, all advanced:
  `torch==2.9.1` (unchanged), `torch-neuronx==2.9.0.2.15.32035+de43f57c`,
  `libneuronxla==2.2.17544.0+fb9962bf`, `neuronx-cc==2.26.6360.0+6f180f47`,
  `neuronx-distributed==0.19.28492+435aae2b`,
  `neuronx-distributed-inference==0.10.18399+ed62453e`,
  `nki==0.5.0+28631259367.ga768afa6`, `torch-xla==2.9.0` (unchanged),
  `torchaudio==2.9.1`, `torchcodec==0.9.1` (AIPCC-12191), `torchvision==0.24.1`,
  `triton==3.5.1` (unchanged)
- Torch pinned at 2.9.1 (not 2.11.0 used by most other variants)
- Constraints-rules API is **disabled** (rule commented out) — all pins are
  explicit in `constraints.txt` (INFERENG-5249)
- Additional constraints: `transformers<5` (AIPCC-9443: vllm transitive dep),
  `prometheus-fastapi-instrumentator>=8.0.1` (INFERENG-8555),
  `yarl<1.24.2`, `urllib3>=2.6.3` (INFERENG-4285)

**spyre-ubi9** (multi-arch: ppc64le, s390x, x86_64):
- `vllm[tensorizer]==0.25.1+rhaiv.1.spyre` (was `0.24.0+rhaiv.3.spyre`)
- `sendnn-inference==2.5.2` (was 2.3.1) for both platform-marker groups
  (ppc64le; s390x/x86_64) — unified version, separate platform markers
  (AIPCC-18691)
- `torch-sendnn==1.3.0` (was 1.2.5), `depyf`, `torchao`, `flash-linear-attention`,
  `pytest-asyncio`, `hf-xet`
- `torch-nnpa==1.5.0; platform_machine == 's390x'` (AIPCC-18989, unchanged)
- `triton; platform_machine == 'x86_64'`, `intel-openmp`, `intel_cmplr_lib_ur` (x86_64 only)
- `llguidance` (AIPCC-27980: explicit to ensure install)
- **New wheels landed this refresh** (INFERENG-9813, confirmed by nzeak on
  Slack 2026-08-14): `ibm-aiu-smi==1.3.0`, `spyremetrics==0.5.0` — previously
  anticipated but absent
- `timm>=1.0.17`, `opentelemetry-exporter-prometheus; platform_machine != 's390x'`
  (excluded from s390x, AIPCC-13600)
- Constraints: `torchao==0.11.0` (unchanged; must match fms-model-optimizer[fp8-infer]),
  `llguidance>=1.7.0,<1.8.0`,
  `prometheus-fastapi-instrumentator>=8.0.1`,
  `ibm-fms==1.13.0` (was 1.11.1, AIPCC-27740),
  `intel-openmp==2024.2.1`, `intel-cmplr-lib-ur==2024.2.1`, `tokenizers==0.22.2`
  (AIPCC-11994: pins for the 3.5 EA2 build; comment text not yet updated for 3.6)

**tpu-ubi9:**
- `vllm[tensorizer]==0.26.0+rhaiv.2.tpu` — was `0.21.0+rhaiv.13.tpu`; now level
  with CUDA/ROCm/CPU's 0.26.0 minor instead of 3 minors behind
- `llmcompressor` remains commented out (AIPCC-4341, temporarily disabled)
- `timm>=1.0.17`, `setuptools>=80.10.2`
- Still uses `torch-2.10.0 *` constraints-rules (one torch minor behind most variants)

**model-opt/cuda13.0-ubi9:**
- `llmcompressor==0.12.0.1` (was 0.12.0)
- `speculators==0.6.0.1` (was 0.6.0)
- `setuptools>=80.10.2`, `pillow>=12.1.1` (new lower-bound pin, moved from global-constraints)
- Explicit constraint pins: `loguru==0.7.3`, `PyYAML==6.0.3`, `numpy==2.4.6`,
  `requests==2.34.2`, `tqdm==4.68.2`, `transformers>=5.9.0,<=5.10.1`,
  `compressed-tensors==0.17.1`, `datasets==5.0.0`, `auto-round==0.13.0`,
  `accelerate==1.13.0`, `nvidia-ml-py==13.610.43` (INFERENG-8847)

### Constraints-Rules Delegation

Eight of the ten collection × variant combinations opt in to `torch-2.11.0 *`
via `constraints-rules.txt`: cuda13.0-ubi9 (rhaiis), rubin-ubi9, rocm7.14-ubi9,
cpu-ubi9, gaudi-ubi9, spyre-ubi9, model-opt/cuda13.0-ubi9, and
vllm-omni/cuda13.0-ubi9. Two exceptions, unchanged since last refresh:
- `neuron-ubi9`: delegation is disabled (rule commented out); all pins are
  explicit in `constraints.txt` (INFERENG-5249)
- `tpu-ubi9`: opts in to `torch-2.10.0 *` instead (one torch minor behind the
  rest)

Note: `rubin-ubi9` requirements are still a placeholder (no packages yet), but
the `constraints-rules.txt` already opts in to `torch-2.11.0 *`.

### Pipeline Flow

**Stages:** checks → bootstrap → build → release → lint → notify (unchanged;
release stage is for internal CI release/lint bookkeeping, not Pulp publish)

All (collection × variant × arch) combinations include
`pipeline-api/ci-wheelhouse.yml` from `builder@v43.3.0`.

**No publish jobs exist** in this repo. Artifact lifecycle:
1. `rhaiis/pipeline` builds wheels → stored in GitLab CI artifact storage
2. `rhai/pipeline` (separately triggered) publishes to Pulp indexes

`seccomp.json` in this repo provides the Linux seccomp BPF syscall filter
applied to wheel build containers.

### Update Automation

Renovate manages vLLM version updates per variant via per-variant custom regex
managers; local version suffixes differ per accelerator (`.cuda` dropped this
refresh, `.cpu`, `.rocm`, `.spyre`, `.tpu`, `.gaudi` all still supported as
optional suffixes in the regexes). The pip_requirements manager is globally
disabled for `vllm`/`vllm-omni` across all
`collections/{rhaiis,vllm-omni}/*/requirements.txt` via an explicit
packageRule; the custom regex managers are the real vLLM tracking mechanism.

**Gaudi's status has changed.** At the last refresh, Gaudi used plain upstream
`vllm==0.24.0` with no `+rhai` tag, so the custom regex manager (which requires
`+rhai(?:v\.)?\d+`) never matched — an update exclusion via format mismatch,
not an explicit `enabled: false` rule. As of this refresh, `gaudi-ubi9`'s
requirements.txt reads `vllm==0.26.0+rhaiv.4` — **this now matches the regex.**
On the `main` base branch there is no branch-scoped packageRule disabling
`nm-vllm-ent` updates for gaudi-ubi9 (the explicit disables for
`gaudi-ubi9/requirements.txt` only apply to `matchBaseBranches: ["3.4"]` and
`["3.5"]`, i.e. old release branches). So on `main`, Gaudi vLLM updates now
appear to be Renovate-trackable in principle — this reverses the previous
"effectively manual update cycle" conclusion for Gaudi and should be
re-verified against actual Renovate MR history before being relied upon.

Builder version updates are gated by per-branch `allowedVersions` patterns
(`renovate.json` packageRules for `redhat/rhel-ai/wheels/builder`, one entry
per release branch from 3.0 through 3.5).

## Impact on Strategies

- **vLLM version fragmentation persists, but has partly narrowed**: CUDA,
  ROCm, CPU, TPU, and vllm-omni are now all on the `0.26.0` minor
  (`0.26.0+rhaiv.1`, `0.26.0+rhaiv.1`, `0.26.0+rhaiv.3.cpu`,
  `0.26.0+rhaiv.2.tpu`, `0.26.0+rhaiv.1`/`vllm-omni 0.26.0+rhaiv.2`
  respectively) — TPU in particular caught up from 3 minors behind. Gaudi
  (`0.26.0+rhaiv.4`) and Spyre (`0.25.1+rhaiv.1.spyre`) are close but not
  identical strings. Neuron remains the outlier at `0.16.0+rhaiv.12` (10 minor
  releases behind). Rubin is still TBD. Cross-variant features must still be
  ported to each active fork version/build string.
- **Gaudi's fork relationship has shifted**: Gaudi's vLLM now carries a
  `+rhaiv.4` local-version tag, the same tagging convention the NeuralMagic
  fork uses elsewhere, whereas previously it used untagged upstream
  `vllm-project/vllm`. This also means Renovate's Gaudi-specific regex manager
  can now match and, absent a `main`-branch disable rule, may begin proposing
  automated vLLM updates for Gaudi where none were possible before. Strategies
  that assumed Gaudi vLLM updates are manual-only should re-verify this
  against current Renovate MR activity before relying on it.
- **Neuron is still the most constrained variant**: Torch remains at 2.9.1
  while most other variants are at 2.11.0. The constraints-rules delegation
  remains disabled. The full neuronx stack carries embedded git commit hashes
  in version strings, and all of them were bumped this cycle (SDK 2.31). Any
  RFE touching Neuron requires explicit pin management for ~20 packages.
- **Spyre carries IBM-proprietary packages, and two more have now landed**:
  the IBM vLLM fork (`.spyre` suffix), `sendnn-inference==2.5.2` (IBM inference
  runtime, arch-conditional with separate platform markers but unified
  version), `torch-sendnn==1.3.0` (pre-built from private index, x86_64 and
  ppc64le), `torch-nnpa==1.5.0` (pre-built, s390x only), and `ibm-fms==1.13.0`
  (Foundation Model Stack, pinned in constraints). `spyremetrics==0.5.0` and
  `ibm-aiu-smi==1.3.0` — anticipated at the last refresh — are now present in
  requirements.txt (INFERENG-9813). `aiu-monitor` is still NOT a wheel
  collection package — it lives in the base image. The Spyre RPM runtime stack
  (`SPYRE_VERSION`) is owned by the base image and remains not visible here.
- **No Pulp publish path**: Wheels built by this pipeline are only accessible
  via GitLab CI artifact storage, not a customer-facing index. RFEs that
  require customer-accessible inference server wheels must also involve
  `rhai/pipeline`.
- **Builder version lag/lead is now uncertain and needs re-checking**: This
  repo jumped from `v39.4.0` to `v43.3.0`. Based on the last refresh of the
  sibling `rhai-pipeline` (`v39.1.0`) and `wheels-builder` (`v42.0.2`)
  overlays — both dated 2026-07-30 and not re-verified in this pass — this
  repo would now be ahead of both. Since a consumer shouldn't normally be
  ahead of the builder's own "latest," this strongly suggests those two
  sibling overlays are stale and due for their own refresh; don't treat this
  comparison as authoritative until they are.
- **cpu-ubi9 is no longer x86_64-only, and the `zen` extra is no longer
  unconditional**: This repo now builds cpu-ubi9 on x86_64, s390x, and
  ppc64le (previously x86_64 only), matching `rhai/pipeline`'s multi-arch cpu
  matrix (still missing aarch64 here). The `zen` extra
  (zentorch for AMD EPYC CPUs) is now explicitly gated
  `; platform_machine == 'x86_64'` in `vllm[audio,tensorizer,zen]==0.26.0+rhaiv.3.cpu`,
  with a parallel non-`zen` line for other architectures. RFEs that assumed
  cpu-ubi9 was single-arch or that `zen` applied unconditionally should be
  corrected.
- **Rubin is still a wired-but-empty variant**: CI jobs exist for rubin-ubi9
  (x86_64, aarch64) but no packages build yet — the requirements file is
  unchanged since the last refresh. Strategies must not treat Rubin as an
  active build variant until requirements are populated.
- **vllm-omni remains a CUDA-only collection** (AIPCC-12521): productizes
  `vllm-omni==0.26.0+rhaiv.2` alongside the standard vLLM CUDA build on
  cuda13.0-ubi9 (x86_64, aarch64). No publish path to rhai/pipeline exists yet
  for this collection.
- **Python, gcc, and TensorFlow versions are not visible in this repo at
  all** — there is no `python`, `gcc`, or `tensorflow` reference anywhere in
  `rhaiis/pipeline`. Those are owned by the `builder`/base image, not this
  build spec. Any RFE citing specific Python/gcc/TensorFlow versions for a
  variant must be validated against the builder or base-image repos (see
  `0019-wheels-builder`), not this overlay. Separately, sibling overlay
  [`0019-rhel-9.8-rebase-platform-wide-3.6-ea1`](0019-rhel-9.8-rebase-platform-wide-3.6-ea1.md)
  records gcc14 as the platform-wide compiler toolchain for 3.6 EA1 across all
  accelerator variants including ROCm 7.14 — that fact lives there, not in
  this repo's files.

## Context

This overlay was created to capture the state of the RHAIIS wheel pipeline at the
3.5 release boundary. The repo defines the vLLM ecosystem for each supported
hardware variant. The breadth of vLLM version divergence and the complexity of
the Neuron, Spyre, and Gaudi variants are the primary feasibility constraints for
RFEs proposing changes to the inference server. This overlay allows the
feasibility reviewer to know the current vLLM version per variant, the
IBM/AWS/Intel-specific package dependencies, and the boundary between build
specification (this repo) and distribution (`rhai/pipeline`). Updated
2026-08-25 by running the `update-rhaiis-pipeline-overlay` skill against the
`3.6-fast1` product version.
