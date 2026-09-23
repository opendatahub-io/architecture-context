---
id: "0017"
title: AIPCC Base Images
status: active
created: 2026-05-26
affects:
  - platform
release:
  - "3.6"
  - "next"
provenance:
  - https://gitlab.com/redhat/rhel-ai/wheels/fondue/-/tree/main/images/base
author: Doug Hellmann
superseded_by: null
---

## Fact

The AIPCC base images (Fondue `images/base/`) provide RHEL-based application
containers with runtime dependencies for hardware accelerators used in AI
workloads, plus access to Python packages built in Red Hat's secure build
pipelines. Downstream teams extend these images by installing Python wheels and
additional packages to create product containers (e.g., vLLM, InstructLab).

Images follow a layout similar to
[s2i-base-containers](https://github.com/sclorg/s2i-base-container) but are not
`s2i` images. Each image runs as an unprivileged user (UID 1001) and ships `pip`
and `uv` pre-configured with a single package index.

Two families are produced:

- **RHAI base images** (`rhaibi-*`) — the primary images consumed by downstream
  product teams. They use the product-versioned index (`INDEX_VERSION=3.6`).
- **Torch Day 0 base images** (`torch-base-*`) — dedicated bases for a new
  PyTorch release (torch 2.14.0). They use a version-pinned Torch Day 0 index
  (`INDEX_VERSION=torch-2.14.0`) instead of the regular RHAI release index.

### Common Foundation

- **Base OS:** RHEL 9.8 (`APP_BASE_IMAGE=registry.redhat.io/rhel9-8-els/rhel:9.8-1789640440`
  in `build-args/argfile.conf`)
- **Python:** 3.12 (every variant conf sets `PYTHON_VERSION=3.12`)
- **RHEL AI repo version:** 3.6 (`REPO_VERSION`)
- **Package index version:** 3.6 (`INDEX_VERSION`, matching the wheel index
  product version in `rhai-pipeline/product-version.yml`); Torch Day 0 confs use
  `torch-2.14.0`
- **Repositories:** RHEL 9.8 EUS BaseOS, AppStream and CodeReady Builder
  (`redhat-9.8-eus.repo`), RHELAI 3.6 (`images/shared/repos/rhelai-3.6.repo`),
  plus any accelerator vendor repo in the variant's `contentOrigin.repofiles`.
  Vendor repo files (`cuda`, `rubin`, `rocm`, `gaudi`, `spyre`) are installed
  with `enabled = 0` in non-hermetic (GitLab CI) builds and used only through
  the DNF helper; `neuron.repo` is `enabled=1`. Hermetic Konflux builds install
  no vendor repo files (Cachi2 manages repos).
- **Container layout:** `/opt/app-root/` with `pip.conf` and `uv.toml` carrying a
  single `index-url` (no `extra-index-url` fallback), rendered from the variant's
  `INDEX_URL_TEMPLATE`. The label `com.redhat.aiplatform.index_url` exposes it.
- **Distribution scope:** `DISTRIBUTION_SCOPE` sets the image's
  `distribution-scope` label only. It does not decide index routing: CUDA,
  Rubin and Spyre are `private` but use the public index. Classify indexes by
  the rendered host (`packages.redhat.com` public, `private.console.redhat.com`
  private).
- **Index staging:** the default template is
  `${INDEX_BASE_URL}/${INDEX_VERSION}/${INDEX_VARIANT}${INDEX_STAGE}${INDEX_SUFFIX}`.
  `INDEX_STAGE=-test` in `argfile.conf` and every variant conf on `main` (also
  for `base-v*` tags built from main), so every rendered URL on `main` targets
  the **staging** (`-test`) index. Release branches override it: `3.6-EA2` uses
  `INDEX_STAGE=-prod` with `INDEX_VERSION=3.6-EA2`, and since AIPCC-32489
  `argfile.conf` documents an empty stage (unsuffixed production index) for
  release builds.
- **Environment metadata:** `/etc/rhaipcc/env` (variant, versions, rendered
  `INDEX_URL`, repo info) and `com.redhat.aiplatform.*` image labels
- **Helper script:** `/usr/libexec/rhaipcc/dnf` runs dnf with `--repo
  ${REPOS_ENABLED}` (RHEL, RHELAI and vendor repos) in non-hermetic builds, and
  plain `dnf` in hermetic builds.
- **Build matrix:** `ci-job-definitions.yml` `base_images.variants` (target
  `app`). Konflux push pipelines (`.tekton/*-on-push.yaml`) run only on release
  tags (`base-v*` or `base-<variant>-v*`); pull-request pipelines run on MRs to
  `main` that touch the variant's files.
- **CI index tests:** Pulp index tests (`pulp_test_arches`) run for CPU (aarch64, s390x, x86\_64),
  CUDA 12.9/13.0 and Rubin (aarch64, x86\_64), and ROCm (x86\_64). AutoQA runs on
  x86\_64 for CPU, CUDA and ROCm. Both are non-gating (`allow_failure: true`);
  Rubin's run against an index no Fondue pipeline publishes. Gaudi, Spyre,
  Neuron, TPU and Torch Day 0 have neither.

### Dependency Management Model

- **`context/<variant>/rpms.in.yaml`** — the authoritative declaration of
  packages per variant: `contentOrigin.repofiles`, `arches`, and `packages`
  (bare names, versioned names, and `arches: {only: [...]}` scoping).
  Accelerator SDK versions are expressed as versioned package names (e.g.
  `ibm-aiu-toolbox-e2e-1.3.1`, `aws-neuronx-runtime-lib-2.33.10.0_3dcef56f0-1`,
  `habanalabs-graph-1.24.1-482.el9`); these are the single source of truth for
  SDK **RPM** versions (AIPCC-29839), not build args.
- **`context/<variant>/rpms.lock.yaml`** — hermetic lockfile produced by
  `rpm-lockfile-prototype`: per-arch closures with CDN URL, checksum, size, name
  and EVR. Konflux (Cachi2/Hermeto) fetches from the locked URLs during hermetic
  builds; nothing is re-resolved at build time.
- **MintMaker** refreshes lockfiles for routine version drift
  (`refresh-rpm-lockfiles` Renovate preset). Manual regeneration
  (`bin/hermetic-generate-lockfiles.sh`) is needed only when adding or removing
  packages. `bin/lint-lockfiles.py` (AIPCC-29840) checks arch alignment,
  integrity and pin coverage, and requires `rpms.lock.yaml` to change whenever
  `rpms.in.yaml` changes in an MR (excusable per variant with a
  `Lockfile-unchanged:` commit trailer, or for every variant with the
  `no-lockfile-linting` MR label, which Renovate applies to base-image-bump
  MRs).

### Accelerator Summary

| Accelerator             | Version   | Status         | Python | RHEL | aarch64 | ppc64le | s390x | x86\_64 |
|-------------------------|-----------|----------------|--------|------|---------|---------|-------|---------|
| CPU                     | --        | Active         | 3.12   | 9.8  | Yes     | Yes     | Yes   | Yes     |
| Torch Day 0 CPU         | --        | Active         | 3.12   | 9.8  | Yes     | --      | --    | Yes     |
| NVIDIA CUDA             | 12.9.1    | Active         | 3.12   | 9.8  | Yes     | --      | --    | Yes     |
| NVIDIA CUDA             | 13.0.2    | Active         | 3.12   | 9.8  | Yes     | --      | --    | Yes     |
| Torch Day 0 NVIDIA CUDA | 13.0.2    | Active         | 3.12   | 9.8  | Yes     | --      | --    | Yes     |
| NVIDIA Rubin            | 13.4.0    | In development | 3.12   | 9.8  | Yes     | --      | --    | Yes     |
| AMD ROCm                | 7.14      | Active         | 3.12   | 9.8  | --      | --      | --    | Yes     |
| Intel Gaudi             | 1.24.1    | Active         | 3.12   | 9.8  | --      | --      | --    | Yes     |
| IBM Spyre               | 1.3.1     | Active         | 3.12   | 9.8  | --      | Yes     | Yes   | Yes     |
| AWS Neuron              | 2.33.10.0 | In development | 3.12   | 9.8  | --      | --      | --    | Yes     |
| Google TPU              | --        | In development | 3.12   | 9.8  | --      | --      | --    | Yes     |
| NVIDIA CUDA             | 13.2.1    | Retired        | --     | --   | --      | --      | --    | --      |
| AMD ROCm                | 6.4       | Retired        | --     | --   | --      | --      | --    | --      |

### Status Legend

- **Active** -- supported and built in CI
- **In development** -- under active development, not yet GA
- **Disabled** -- configuration exists but builds are skipped
- **Retired** -- removed from the repository

### CPU

- **Status:** Active. **Config:** `build-args/cpu-el9.8-app.conf`.
  **Lockfile input:** `context/cpu/rpms.in.yaml`.
- **Architectures:** aarch64, ppc64le, s390x, x86\_64. **Container:** `rhaibi-cpu`.
- **Python package index:** public RHEL AI index, rendered
  `https://packages.redhat.com/api/pypi/public-rhai/rhoai/3.6/cpu-ubi9-test/simple/`
  (staging on `main`).
- **Distribution scope:** `authoritative-source-only`
- **Notable packages:** no accelerator RPMs; `gcc-toolset-14` and
  `gcc-toolset-14-gcc-c++` are scoped `only: [ppc64le, s390x]` for
  `torch.compile` (AIPCC-29662).

### Torch Day 0 CPU

- **Status:** Active. **Config:** `build-args/torch-cpu-el9.8-app.conf`.
  **Lockfile input:** `context/cpu/rpms.in.yaml`.
- **Architectures:** aarch64, x86\_64. **Container:** `torch-base-cpu`.
- **Python package index:** Torch Day 0 index on the public host, template
  `${INDEX_BASE_URL}/${INDEX_VERSION}-${INDEX_VARIANT}${INDEX_STAGE}${INDEX_SUFFIX}`
  (`-` joins version and variant), rendered
  `https://packages.redhat.com/api/pypi/public-rhai/torch-2.14.0-cpu-ubi9-test/simple/`
  (staging on `main`). The conf carries
  `regen-skip: INDEX_BASE_URL,INDEX_URL_TEMPLATE,INDEX_VERSION,INDEX_STAGE`.
- **Distribution scope:** `authoritative-source-only`
- **Notes:** GitLab CI tag builds are disabled (`enable_tag_build: false`).

### NVIDIA CUDA

Two CUDA versions are active and share `Containerfile.cuda-app`; the conf's
`LOCKFILE_VARIANT` selects the lockfile. Rubin (CUDA 13.4 Developer Preview) is
in development, and a Torch Day 0 variant exists for CUDA 13.0. All CUDA library
pins are versioned package names in `context/cuda-<ver>/rpms.in.yaml`.

| | CUDA 12.9.1 | CUDA 13.0.2 | Torch Day 0 CUDA 13.0.2 |
|---|---|---|---|
| Config | `cuda12.9-el9.8-app.conf` | `cuda13.0-el9.8-app.conf` | `torch-cuda13.0-el9.8-app.conf` |
| Lockfile | `context/cuda-12.9` | `context/cuda-13.0` | `context/cuda-13.0` (shared) |
| Container | `rhaibi-cuda12.9-el9.8` | `rhaibi-cuda13.0-el9.8` | `torch-base-cuda13.0-el9.8` |
| Index (rendered, `main`) | `https://packages.redhat.com/api/pypi/public-rhai/rhoai/3.6/cuda12.9-ubi9-test/simple/` | `https://packages.redhat.com/api/pypi/public-rhai/rhoai/3.6/cuda13.0-ubi9-test/simple/` | `https://packages.redhat.com/api/pypi/public-rhai/torch-2.14.0-cuda13.0-ubi9-test/simple/` |
| Distribution scope | `private` | `private` | `private` |
| Driver (`NVIDIA_REQUIRE_CUDA`) | `cuda>=12.0 driver>=525.60.13` | `cuda>=13.0 driver>=580.95.05` | `cuda>=13.0 driver>=580.95.05` |
| cuDNN | 9.22.0.52-1 | 9.19.0.56-1 | 9.19.0.56-1 |
| cuSPARSELt | 0.8.1.1-1 | 0.9.1.1-1 | 0.9.1.1-1 |
| cuDSS / NVSHMEM / cuTENSOR | 0.7.1.4-1 / 3.5.19-1 / 2.7.0.5-1 | 0.7.1.4-1 / 3.5.19-1 / 2.7.0.5-1 | 0.7.1.4-1 / 3.5.19-1 / 2.7.0.5-1 |
| NCCL | `libnccl-2.30.4-1+cuda12.9` | `libnccl-2.30.4-1+cuda13.2` | `libnccl-2.30.4-1+cuda13.2` |
| UCX | 1.21.0 (lockfile `1.21.0-3.el9ai`) | 1.21.0 plus `ucx-cuda`, `ucx-gdrcopy`, `ucx-ib-mlx5-cuda` | 1.21.0 plus `ucx-cuda`, `ucx-gdrcopy`, `ucx-ib-mlx5-cuda` |
| Other | `libgomp-offload-nvptx` (x86\_64 only) | `openmpi-cuda`; `libgomp-offload-nvptx` (x86\_64 only) | `openmpi-cuda`; `libgomp-offload-nvptx` (x86\_64 only) |

All three are aarch64 and x86\_64; the host is `https://packages.redhat.com/api/pypi`.
The Torch Day 0 CUDA conf carries the same `regen-skip` list as Torch Day 0 CPU,
has GitLab CI tag builds disabled, and defines CUDA library build args
(`CUDNN_VERSION`, `CUDA_UCX_VERSION=1.20.1-1`, ...) that no base-image
Containerfile consumes; installed versions come from the lockfile.

### NVIDIA Rubin

- **Status:** In development (inferred: CUDA 13.4 Developer Preview toolkit, no
  AutoQA, no published `rhoai/3.6` wheel index; `images/base/README.md` lists
  Rubin as supported).
  **Config:** `build-args/rubin-el9.8-app.conf`. **Lockfile input:** `context/rubin/rpms.in.yaml`.
- **Architectures:** aarch64, x86\_64. **Container:** `rhaibi-rubin-el9.8`.
- **Python package index:** public RHEL AI index, rendered
  `https://packages.redhat.com/api/pypi/public-rhai/rhoai/3.6/rubin-ubi9-test/simple/`
  (staging on `main`). No `rhai-pipeline/` collection builds `rubin-ubi9`, so no
  Fondue pipeline publishes to this index (see overlay 0020); the builder
  pipeline builds `rubin-ubi9` wheels only under its `0.0-el9.8` product
  version, and `rhaiis/pipeline` builds `rubin-ubi9` wheels but has no Pulp
  path (overlay 0021).
- **Distribution scope:** `private`
- **Driver requirement:** `NVIDIA_REQUIRE_CUDA=cuda>=13.4 driver>=616`
- **CUDA levels:** build args set `CUDA_VERSION=13.4.0`, while the RPM closure in
  `rpms.in.yaml` is CUDA 13.3 (`cuda-*-13-3`, `libnccl-2.30.7-1+cuda13.3`). Other
  library pins match CUDA 13.0 (cuDNN 9.19.0.56-1, cuSPARSELt 0.9.1.1-1, cuDSS,
  NVSHMEM, cuTENSOR, UCX 1.21.0 with CUDA extras).

### AMD ROCm

- **Status:** Active. **Config:** `build-args/rocm7.14-el9.8-app.conf`
  (`ROCM_VERSION=7.14`, `ROCM_HOME=/opt/rocm/core`, a symlink to the versioned
  `/opt/rocm/core-7.x/` directory). **Lockfile input:** `context/rocm/rpms.in.yaml`.
- **Architectures:** x86\_64. **Container:** `rhaibi-rocm7.14-el9.8`.
- **Python package index:** public RHEL AI index, rendered
  `https://packages.redhat.com/api/pypi/public-rhai/rhoai/3.6/rocm7.14-ubi9-test/simple/`
  (staging on `main`).
- **Distribution scope:** `authoritative-source-only`
- **Declared packages (not version-pinned by name):** `amdrocm-runtime`,
  `amdrocm-amdsmi`, `amdrocm-llvm`, `amdrocm-rccl`, `amdrocm-math-common`,
  `amdrocm-core-sdk`, `amdrocm-blas`, `amdrocm-dnn`, `amdrocm-fft`,
  `amdrocm-solver`, `amdrocm-sparse`, `amdrocm-rand`, `migraphx`, `-devel`
  packages for runtime, rccl, core, blas, dnn, fft, solver, sparse, rand, ccl
  and migraphx (none for amdsmi, llvm, math-common, core-sdk), `libdrm`, and
  `gcc-toolset-14` (`-gcc-c++`, `-gcc-gfortran`, `-libatomic-devel`). The
  lockfile resolves `amdrocm-*` to `7.14.0-3` and `migraphx` to
  `2.16.0.rocm7.14.0a20260520.b6b2096-1.el8`.

### Intel Gaudi

- **Status:** Active. **Config:** `build-args/gaudi-el9.8-app.conf`
  (`GAUDI_VERSION=1.24.1`, `GAUDI_REVISION=482`). **Lockfile input:** `context/gaudi/rpms.in.yaml`.
- **Architectures:** x86\_64. **Container:** `rhaibi-gaudi`.
- **Python package index:** private RHAIIS index, rendered
  `https://private.console.redhat.com/api/pypi/rhai/rhaiis/3.6/gaudi-ubi9-test/simple/`
  (staging on `main`; `regen-skip: INDEX_BASE_URL`), published from
  `rhai-pipeline/collections/rhaiis/` via `variant_overrides` (overlay 0020; not
  the `rhaiis/pipeline` repository). Serves non-redistributable Habanalabs
  wheels; downstream product builds consume it directly (see Impact on
  Strategies for the private-index pattern).
- **Distribution scope:** `private`
- **Pinned RPMs (lockfile EVR `1.24.1-482.el9`):** `habanalabs-rdma-core`
  (installed separately with `--nodeps`), `habanalabs-thunk`,
  `habanalabs-firmware-tools`, `habanalabs-graph`, all `-1.24.1-482.el9`.

### IBM Spyre

- **Status:** Active. **Config:** `build-args/spyre-el9.8-app.conf`.
  **Lockfile input:** `context/spyre/rpms.in.yaml`.
- **Architectures:** ppc64le, s390x, x86\_64. **Container:** `rhaibi-spyre`.
- **Python package index:** public RHEL AI index, rendered
  `https://packages.redhat.com/api/pypi/public-rhai/rhoai/3.6/spyre-ubi9-test/simple/`
  (staging on `main`). Spyre wheels are published there by `rhai-pipeline/`
  (overlay 0020); the conf's `# NOTE: index does not exist` comment is stale. The
  builder's private Spyre PyPI (pre-built torch-sendnn/torch-nnpa wheels) is a
  separate mechanism.
- **Distribution scope:** `private`
- **IBM SDK version:** 1.3.1. The versioned names in `rpms.in.yaml` are the
  single source of truth for the Spyre SDK RPM versions (AIPCC-29839); the
  versioned IBM SDK packages in the table below resolve to 1.3.1 on every
  arch, with per-arch release strings
  (e.g. `1.3.1-1_0.el9` on ppc64le/x86_64, `1.3.1-1_1.el9` on s390x).

  | Package | Arches |
  |---------|--------|
  | `ibm-aiu-toolbox-e2e-1.3.1` | x86\_64, ppc64le, s390x |
  | `ibm-deeptools-1.3.1` | x86\_64, ppc64le, s390x |
  | `ibm-flex-1.3.1` | x86\_64, ppc64le, s390x |
  | `ibm-senlib-core-1.3.1` | x86\_64, ppc64le, s390x |
  | `ibm-senlib-dd2-1.3.1` | x86\_64, ppc64le, s390x |
  | `ibm-libaiupti-1.3.1` | x86\_64, ppc64le only |
  | `ibm-spyre-model-cache-1.3.1` | ppc64le, s390x only |
  | `ibm-z-spyre-runtime-1.3.1` | s390x only |
  | `libzdnn` | s390x only |
  | `gcc-toolset-14`, `gcc-toolset-14-gcc-c++` | ppc64le, s390x only |

  Non-versioned Spyre packages `hwloc` and `python3.12-pybind11` are also
  declared. RPMs come from the IBM Spyre yum repository (`./repo/spyre.repo`).

### AWS Neuron

- **Status:** In development. **Config:** `build-args/neuron-el9.8-app.conf`.
  **Lockfile input:** `context/neuron/rpms.in.yaml`.
- **Architectures:** x86\_64. **Container:** `rhaibi-neuron`.
- **Python package index:** private RHAIIS index, rendered
  `https://private.console.redhat.com/api/pypi/rhai/rhaiis/3.6/neuron-ubi9-test/simple/`
  (staging on `main`; `regen-skip: INDEX_BASE_URL`). Serves non-redistributable
  AWS Neuron SDK wheels; downstream product builds consume it directly (see
  Impact on Strategies for the private-index pattern).
- **Distribution scope:** `private`
- **Neuron SDK packages pinned in `rpms.in.yaml` (AIPCC-29839, lockfile EVRs match):**
  `aws-neuronx-runtime-lib-2.33.10.0_3dcef56f0-1`,
  `aws-neuronx-tools-2.31.15.0_5c7949a6a-1`,
  `aws-neuronx-collectives-2.33.10.0_068180c7a-1`, plus `libatomic`. Versions
  embed git commit hashes, as is standard for Neuron SDK releases. RPMs come
  from an internal Pulp mirror of the AWS Neuron yum repository
  (`./repo/neuron.repo`); `aws-neuronx-collectives` needs `hwloc-devel`, so it is
  installed with `--nodeps`. The mirror is synced manually
  (`images/base/README.md`), so strategies depending on Neuron updates cannot
  assume same-day upstream availability.

### Google TPU

- **Status:** In development. **Config:** `build-args/tpu-el9.8-app.conf`.
  **Lockfile input:** `context/tpu/rpms.in.yaml`.
- **Architectures:** x86\_64. **Container:** `rhaibi-tpu`.
- **Python package index:** private RHAIIS index, rendered
  `https://private.console.redhat.com/api/pypi/rhai/rhaiis/3.6/tpu-ubi9-test/simple/`
  (staging on `main`; `regen-skip: INDEX_BASE_URL`). Serves non-redistributable
  Google TPU / Torch-XLA wheels (see Impact on Strategies for the
  private-index pattern).
- **Distribution scope:** `private`
- **Notes:** no accelerator RPMs and no vendor repo beyond RHEL EUS and RHELAI.

### Retired Accelerators

#### NVIDIA CUDA 13.2.1

Retired by AIPCC-31823 ("Remove CUDA 13.2 builder and base image variants"). No
`cuda13.2` conf, CI entry, or builder variant exists on `main`. It shared the
`context/cuda-13.0` lockfile and required driver `>=595.58.03`.

#### AMD ROCm 6.4

Retired in RHAI 3.5-EA1
([AIPCC-15426](https://issues.redhat.com/browse/AIPCC-15426)); the base image
and Tekton pipelines were removed. ROCm 7.14 is the current supported version.

## Impact on Strategies

- All RHAI components that use accelerator-specific Python libraries MUST use
  these base images; components that have not yet migrated must be updated to
  stay current with the platform.
- Package content is fixed at lockfile commit time. RFEs that add or remove
  accelerator RPMs must account for the full `rpms.in.yaml` → lockfile
  regeneration → CI lint validation cycle (AIPCC-29840). Version drift of
  existing packages is handled automatically by MintMaker; only package list
  changes require manual lockfile regeneration.
- Active vs. in-development status matters: AWS Neuron, Google TPU, and NVIDIA
  Rubin are not GA — strategies must not assume their availability in production
  workloads. Rubin's image points at `rhoai/3.6/rubin-ubi9`, an index no Fondue
  pipeline publishes (the builder pipeline builds `rubin-ubi9` wheels only under
  its `0.0-el9.8` product version, and `rhaiis/pipeline` builds `rubin-ubi9`
  wheels but has no Pulp path, overlay 0021), so Rubin strategies must also plan
  index publication, including a `variant-linter` pattern approval (overlay
  0020).
- Intel Gaudi is Active in the `base_images` build matrix (x86_64) with Konflux
  pipelines. `images/base/README.md` still marks Gaudi disabled (a note citing
  AIPCC-3471, now Closed); that note is stale. Like every base image, its
  Tekton/Konflux push pipeline runs only on release tags.
- AMD ROCm 6.4 is retired; any references in strategies or RFEs must be updated
  to ROCm 7.14, the current supported version.
- Two active CUDA versions (12.9, 13.0) are maintained simultaneously,
  with a third (Rubin / CUDA 13.4 Developer Preview) in development. CUDA 13.2
  was retired (AIPCC-31823). Strategies and RFEs proposing CUDA-dependent features
  should specify the minimum driver version requirement, since each version has a
  different minimum driver (525.60.13 for 12.9, 580.95.05 for 13.0, 616 for
  Rubin/13.4). Note that cuDNN versions differ between CUDA 12.9 (9.22.0.52) and
  CUDA 13.0/Rubin (9.19.0.56); CUDA-version-specific cuDNN changes require
  coordinated lockfile updates.
- IBM Spyre and AWS Neuron SDK RPM version pins are declared as versioned
  package names in `context/<variant>/rpms.in.yaml` (AIPCC-29839) — not in
  build-args conf files. The SDKs' Python wheels are pinned separately in the
  consuming `rhai-pipeline/collections/*/<variant>/` requirements/constraints
  (e.g. `torch-sendnn==1.3.1` for Spyre; `torch-neuronx`, `neuronx-cc` for
  Neuron), so an SDK bump must update both. IBM Spyre uses arch-conditional
  packages; the ppc64le and s390x package sets differ from x86_64 (see table
  above).
- Torch Day 0 base images (`torch-base-*`) serve a new PyTorch release from a
  version-pinned index (`torch-2.14.0-*`) outside the regular RHAI release
  index. Strategies must not treat them as the product-versioned base images or
  assume they follow the product index or its fast/stable channels. Do not
  change the torch version, CUDA version or index variant of an existing Torch
  Day 0 index; ABI-breaking updates need a new versioned index and matching
  image config (`images/base/README.md`).
- Python package indexes differ by variant and must not be treated as uniform.
  The URL baked into each image is the fully rendered `INDEX_URL_TEMPLATE`
  (including version, variant, `INDEX_STAGE` `-test`/prod suffix, and `/simple/`)
  — not the bare `INDEX_BASE_URL`. On `main` all rendered URLs point at the
  `-test` (staging) index; release branches override `INDEX_STAGE` and the
  value differs by branch (e.g. `3.6-EA2` uses `-prod`; since AIPCC-32489
  `argfile.conf` documents an empty, unsuffixed production stage for release
  builds).
  - **CPU, CUDA, ROCm, Rubin, Torch Day 0** — use the public host
    (`packages.redhat.com/api/pypi/public-rhai`), e.g.
    `.../rhoai/3.6/cpu-ubi9-test/simple/` (RHAI variants) or
    `.../public-rhai/torch-2.14.0-cpu-ubi9-test/simple/` (Torch Day 0). This is
    the default for most strategies; those adding Python dependencies for these
    variants must ensure packages are available in the corresponding public
    index.
  - **Gaudi, Neuron, TPU** — use the private RHAIIS index, which **replaces**
    the public index entirely (single `index-url` in pip/uv config; no
    fallback), e.g.
    `https://private.console.redhat.com/api/pypi/rhai/rhaiis/3.6/gaudi-ubi9-test/simple/`.
    It is published from `rhai-pipeline/collections/rhaiis/` via
    `variant_overrides` (overlay 0020; not the `rhaiis/pipeline` repository).
    These variants require a private index because their wheels (Habanalabs,
    AWS Neuron SDK, Torch-XLA) are non-redistributable.
    Downstream product container builds consume the private index directly.
    Strategies targeting these variants must not assume the public RHEL AI
    index is reachable or sufficient — dependency resolution will fail if
    directed to the wrong index.
  - **Spyre** — uses the public RHEL AI index at
    `rhoai/3.6/spyre-ubi9-test/simple/` on `main` (with `INDEX_STAGE=-test`).
    Spyre wheels are published to this index alongside other variants. The
    builder's private Spyre PyPI (for pre-built torch-sendnn/torch-nnpa wheels)
    is a separate, distinct mechanism.

## Context

This overlay was created to capture the accelerator base image landscape as a
reference for evaluating RFEs proposing accelerator updates or additions. The
generated architecture docs for individual components (vLLM, InstructLab, etc.)
do not describe the shared base image layer or the current status of each
accelerator variant. This overlay fills that gap so that strategy pipelines,
architecture reviews, and design validation tooling have an authoritative,
up-to-date view of which accelerators are active, in development, disabled, or
retired, and what the common foundation looks like across all variants.

Maintained with the `update-fondue-overlays` skill; last refreshed 2026-09-23
from Fondue `main` (`330d9f9ee`).
