---
id: "0017"
title: AIPCC Base Images
status: active
created: 2026-05-26
affects:
  - platform
release:
  - "3.6"
  - "3.7"
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

Images are built per accelerator and, for most accelerators, per torch
version. Each torch-qualified image points at one content channel index (the
accelerator, SDK, torch major.minor and OS token of the wheels it consumes).
Channel identity, the catalog and URL derivation are described in overlay
[0030](0030-aipcc-content-channels.md); this overlay records the per-image
confs, rendered index URLs, labels, tags and the Konflux state.

### Common Foundation

- **Base OS:** RHEL 9.8 (`APP_BASE_IMAGE=registry.redhat.io/rhel9-8-els/rhel:9.8-1789640440`
  in `build-args/argfile.conf`)
- **Python:** 3.12 (every conf sets `PYTHON_VERSION=3.12`)
- **RHEL AI repo version:** 3.6 (`REPO_VERSION`)
- **Index URL template:** `${INDEX_BASE_URL}/${INDEX_VARIANT}${INDEX_STAGE}${INDEX_SUFFIX}`
  in `argfile.conf` and every conf, with default
  `INDEX_BASE_URL=https://packages.redhat.com/api/pypi/public-rhai`. Channel
  confs set `INDEX_VARIANT` to the channel name; legacy accelerator-only confs
  set `INDEX_BASE_URL` to a product path (`.../rhoai/3.6` or
  `https://private.console.redhat.com/api/pypi/rhai/rhaiis/3.6`), which their
  `regen-versioned: INDEX_BASE_URL` marker keeps in step with `INDEX_VERSION`
  when `make regen` runs (`build-args/regen-build-args.sh`).
- **`INDEX_VERSION`:** 3.6, matching `rhai-pipeline/product-version.yml`. The
  argfile describes it as "image metadata and legacy package indexes": it sets
  the `com.redhat.aiplatform.index_version` label and the product segment of
  legacy confs, and it does not select a channel index path.
- **`TORCH_VERSION`:** empty in `argfile.conf`; each channel conf sets it
  (`regen-skip: TORCH_VERSION`), and GitLab CI also passes it as a build arg.
- **Repositories:** RHEL 9.8 EUS BaseOS, AppStream and CodeReady Builder
  (`redhat-9.8-eus.repo`), RHELAI 3.6 (`images/shared/repos/rhelai-3.6.repo`),
  plus any accelerator vendor repo in the variant's `contentOrigin.repofiles`.
  Vendor repo files (`cuda`, `rubin`, `rocm`, `gaudi`, `spyre`) are installed
  with `enabled = 0` in non-hermetic (GitLab CI) builds and used only through
  the DNF helper; `neuron.repo` is `enabled=1`. Hermetic Konflux builds install
  no vendor repo files (Cachi2 manages repos).
- **Container layout:** `/opt/app-root/` with `pip.conf` and `uv.toml` carrying a
  single `index-url` (no `extra-index-url` fallback), rendered from the conf's
  `INDEX_URL_TEMPLATE`. The label `com.redhat.aiplatform.index_url` exposes it.
- **Distribution scope:** `DISTRIBUTION_SCOPE` sets the image's
  `distribution-scope` label only and does not decide index routing: CUDA,
  Rubin and Spyre are `private` but use a public index. Classify indexes by
  the rendered host (`packages.redhat.com` public, `private.console.redhat.com`
  private).
- **Index staging:** `INDEX_STAGE=-test` in `argfile.conf` and every conf on
  `main`, so every rendered URL on `main` targets a **staging** (`-test`)
  index. The argfile documents an empty stage (unsuffixed production index)
  for release builds; release branches set their own value and are out of
  scope here.
- **pip/uv bootstrap:** `context/common/index-url.sh`
  (`select_bootstrap_cpu_variant`) installs pip and uv from the CPU channel
  with the image's torch version (`cpu-torch<X.Y>-<os>`), falling back to
  `cpu-torch2.11-<os>` for torch 2.9, 2.10 and 2.12; Torch Day 0 images use
  `torch-<version>-cpu-ubi9` and legacy images `cpu-ubi<major>` under
  `rhoai/<INDEX_VERSION>`. The channel regex accepts only `ubi<N>` OS tokens.
  Whether every fallback is a built channel and every catalog `os` token
  matches is recorded in overlay [0030](0030-aipcc-content-channels.md)
  (Channel Awareness).
- **Labels:** `containerfiles/app-header` sets `com.redhat.aiplatform.*`
  labels (`accelerator`, `channel`, `build_timestamp`, `base_image`,
  `repo_version`, `python`, `index_version`, `index_url`),
  `org.opencontainers.image.revision`, `name` and `com.redhat.component`
  (from the conf `NAME`, which carries no torch version, e.g.
  `rhaibi-cuda13.0-el9.8`), `distribution-scope` and `io.openshift.tags`.
  GitLab CI passes the channel label from `compute_base_image_channel_label`
  in `bin/regen-ci.py`; overlay 0030 (Channel Awareness) records whether its
  OS token matches the catalog.
- **Environment metadata:** `/etc/rhaipcc/env` (variant, versions, rendered
  `INDEX_URL`, repo info).
- **Helper script:** `/usr/libexec/rhaipcc/dnf` runs dnf with `--repo
  ${REPOS_ENABLED}` (RHEL, RHELAI and vendor repos) in non-hermetic builds, and
  plain `dnf` in hermetic builds.
- **CI index tests:** Pulp index tests (`pulp_test_arches`, MR pipelines,
  `allow_failure: true`) run for CPU (aarch64, s390x, x86\_64), CUDA 12.9/13.0
  and Rubin (aarch64, x86\_64), and ROCm (x86\_64). `autoqa_test_arches` is
  empty for every variant as of the commit; CPU, CUDA and ROCm carry the
  comment "AIPCC-32066: temporarily disabled during channels development".
  Gaudi, Spyre, Neuron and TPU have neither test.

### Image Families and Builders

- **GitLab CI (channel images):** `ci-job-definitions.yml`
  `base_images.variants` (target `app`). Each entry's `version` is split at
  `-el` into an accelerator version and an OS suffix
  (`split_base_image_version`); each entry with `torch_versions` builds one
  image per torch version from
  `build-args/<key><accel_version>-torch<X.Y><os_version>-app.conf`, whose
  `INDEX_VARIANT` is the channel. 13 images: CPU 2.11/2.13, CUDA 12.9
  2.11/2.13, CUDA 13.0 2.11/2.13/2.14, ROCm 7.14 2.11/2.12, Gaudi 2.11, Spyre
  2.11, Neuron 2.9, TPU 2.10. The image torch matrix is declared separately
  from the wheel matrix: `cpu-torch2.14-ubi9` is a built wheel channel with no
  image.
- **GitLab CI (no torch version):** Rubin has no `torch_versions` and builds
  one image from `build-args/rubin-el9.8-app.conf` (legacy product-versioned
  index).
- **GitLab CI registry path:**
  `registry.gitlab.com/redhat/rhel-ai/wheels/fondue/aipcc-<key><accel_version>[-torch<X.Y>]<os_version>-app`
  (`gitlab-ci/common.yml` `IMAGE_BASE`), per-arch images `...-<arch>` plus a
  multi-arch manifest, e.g. `aipcc-cuda13.0-torch2.13-el9.8-app`. Tags: MR
  pipelines push `ci_<MR IID>`; pushes to `main` that touch `images/base/`,
  `images/shared/` or `.tekton/`, and `base-*` release tags, push an immutable
  `YYYYMMDDTHHMMSS` tag from the pipeline creation time
  (`bin/image-tag.py`) plus a moving `latest`. No entry sets
  `enable_tag_build: false`.
- **Konflux:** `.tekton/*-on-push.yaml` (generated by PMT from
  aipcc-product-management-configs, per `.tekton/README.md`) build the
  accelerator-only and Torch Day 0 confs in the table below (overlay 0030,
  Channel Awareness, records whether any builds a channel conf). Every
  pipeline triggers on `base-v*` tags plus a per-component tag:

  | Pipeline | Conf | Output image (`quay.io/redhat-user-workloads/ai-tenant/...`) | `NAME` build arg | Component tag |
  |---|---|---|---|---|
  | `base-image-cpu` | `cpu-el9.8-app.conf` | `base-images/base-image-cpu` | `rhai/base-image-cpu-rhel9` | `base-cpu-v*` |
  | `base-image-cuda-12-9` | `cuda12.9-el9.8-app.conf` | `base-images/base-image-cuda-12-9` | `rhai/base-image-cuda-12.9-rhel9` | `base-cuda-v*` |
  | `base-image-cuda-13-0` | `cuda13.0-el9.8-app.conf` | `base-images/base-image-cuda-13-0` | `rhai/base-image-cuda-13.0-rhel9` | `base-cuda-v*` |
  | `base-image-rubin` | `rubin-el9.8-app.conf` | `base-images/base-image-rubin` | `rhai/base-image-rubin-rhel9` | `base-rubin-v*` |
  | `base-image-rocm-7-14` | `rocm7.14-el9.8-app.conf` | `base-images/base-image-rocm-7-14` | `rhai/base-image-rocm-7.14-rhel9` | `base-rocm-v*` |
  | `base-image-gaudi` | `gaudi-el9.8-app.conf` | `base-images/base-image-gaudi` | `rhai/base-image-gaudi-rhel9` | `base-gaudi-v*` |
  | `base-image-spyre` | `spyre-el9.8-app.conf` | `base-images/base-image-spyre` | `rhai/base-image-spyre-rhel9` | `base-spyre-v*` |
  | `base-image-neuron` | `neuron-el9.8-app.conf` | `base-images/base-image-neuron` | `rhai/base-image-neuron-rhel9` | `base-neuron-v*` |
  | `base-image-tpu` | `tpu-el9.8-app.conf` | `base-images/base-image-tpu` | `rhai/base-image-tpu-rhel9` | `base-tpu-v*` |
  | `torch-cpu` | `torch-cpu-el9.8-app.conf` | `torch/torch-cpu` | `torch/cpu-ubi9` | `base-torch-cpu-v*` |
  | `torch-cuda-13-0` | `torch-cuda13.0-el9.8-app.conf` | `torch/torch-cuda-13-0` | `torch/cuda-13.0-ubi9` | `base-torch-cuda-v*` |

  The base-image pipelines prefetch Python packages from
  `https://packages.redhat.com/api/pypi/public-rhai/rhoai/3.6/cpu-ubi9-test/simple/`
  (`pip-index-url`, which `bin/regen_tekton.py` rewrites from
  `cpu-el9.8-app.conf`). Pull-request pipelines run on MRs to `main` that touch
  the component's files.
- **Image name tokens** (see overlay 0030 for the OS token rule): confs and
  GitLab CI images use `el9.8`, channel names use `ubi9`, and the `NAME`
  build args of the Konflux `base-image-*` pipelines use `rhel9` (the Torch
  Day 0 pipelines use `ubi9`).
- **Conf usage:** every conf under `build-args/` is named by GitLab CI or a
  Konflux pipeline; none is unused.

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
  `no-lockfile-linting` MR label).

### Accelerator Summary

| Accelerator             | Version   | Status         | Python | RHEL | aarch64 | ppc64le | s390x | x86\_64 | Torch |
|-------------------------|-----------|----------------|--------|------|---------|---------|-------|---------|-------|
| CPU                     | --        | Active         | 3.12   | 9.8  | Yes     | Yes     | Yes   | Yes     | 2.11, 2.13 |
| NVIDIA CUDA             | 12.9.1    | Active         | 3.12   | 9.8  | Yes     | --      | --    | Yes     | 2.11, 2.13 |
| NVIDIA CUDA             | 13.0.2    | Active         | 3.12   | 9.8  | Yes     | --      | --    | Yes     | 2.11, 2.13, 2.14 |
| NVIDIA Rubin            | 13.4.2    | In development | 3.12   | 9.8  | Yes     | --      | --    | Yes     | -- (no channel) |
| AMD ROCm                | 7.14      | Active         | 3.12   | 9.8  | --      | --      | --    | Yes     | 2.11, 2.12 |
| Intel Gaudi             | 1.24.1    | Active         | 3.12   | 9.8  | --      | --      | --    | Yes     | 2.11 |
| IBM Spyre               | 1.3.1     | Active         | 3.12   | 9.8  | --      | Yes     | Yes   | Yes     | 2.11 |
| AWS Neuron              | 2.33.10.0 | In development | 3.12   | 9.8  | --      | --      | --    | Yes     | 2.9 |
| Google TPU              | --        | In development | 3.12   | 9.8  | --      | --      | --    | Yes     | 2.10 |
| Torch Day 0 CPU         | --        | Active         | 3.12   | 9.8  | Yes     | --      | --    | Yes     | 2.14.0 (Konflux only, legacy index) |
| Torch Day 0 NVIDIA CUDA | 13.0.2    | Active         | 3.12   | 9.8  | Yes     | --      | --    | Yes     | 2.14.0 (Konflux only, legacy index) |
| NVIDIA CUDA             | 13.2.1    | Retired        | --     | --   | --      | --      | --    | --      | -- |
| AMD ROCm                | 6.4       | Retired        | --     | --   | --      | --      | --    | --      | -- |

Architectures come from `base_images.variants` (GitLab CI) and, for the Torch
Day 0 rows, from the Konflux `build-platforms`. The `Torch` column lists image
torch versions; each one is a channel `<accel><sdk>-torch<X.Y>-ubi9`.

### Status Legend

- **Active** -- supported and built in CI
- **In development** -- under active development, not yet GA
- **Disabled** -- configuration exists but builds are skipped
- **Retired** -- removed from the repository

### CPU

- **Status:** Active. **Lockfile input:** `context/cpu/rpms.in.yaml`.
  **Containerfile:** `Containerfile.cpu-app`.
- **Architectures:** aarch64, ppc64le, s390x, x86\_64. **Conf `NAME`:** `rhaibi-cpu`.
- **Distribution scope:** `authoritative-source-only`
- **Notable packages:** no accelerator RPMs; `gcc-toolset-14` and
  `gcc-toolset-14-gcc-c++` are scoped `only: [ppc64le, s390x]` for
  `torch.compile` (AIPCC-29662).

| Image | Builder | Conf | Index class | Rendered index URL (`main`) |
|---|---|---|---|---|
| `aipcc-cpu-torch2.11-el9.8-app` | GitLab CI | `cpu-torch2.11-el9.8-app.conf` | public channel | `https://packages.redhat.com/api/pypi/public-rhai/cpu-torch2.11-ubi9-test/simple/` |
| `aipcc-cpu-torch2.13-el9.8-app` | GitLab CI | `cpu-torch2.13-el9.8-app.conf` | public channel | `https://packages.redhat.com/api/pypi/public-rhai/cpu-torch2.13-ubi9-test/simple/` |
| `base-image-cpu` | Konflux | `cpu-el9.8-app.conf` | legacy product-versioned | `https://packages.redhat.com/api/pypi/public-rhai/rhoai/3.6/cpu-ubi9-test/simple/` |

### NVIDIA CUDA

Two CUDA versions are active and share `Containerfile.cuda-app`; the conf's
`LOCKFILE_VARIANT` selects the lockfile. All CUDA library pins are versioned
package names in `context/cuda-<ver>/rpms.in.yaml`.

| | CUDA 12.9.1 | CUDA 13.0.2 |
|---|---|---|
| Lockfile | `context/cuda-12.9` | `context/cuda-13.0` |
| Conf `NAME` | `rhaibi-cuda12.9-el9.8` | `rhaibi-cuda13.0-el9.8` |
| Distribution scope | `private` | `private` |
| Driver (`NVIDIA_REQUIRE_CUDA`) | `cuda>=12.0 driver>=525.60.13` | `cuda>=13.0 driver>=580.95.05` |
| cuDNN | 9.22.0.52-1 | 9.19.0.56-1 |
| cuSPARSELt | 0.8.1.1-1 | 0.9.1.1-1 |
| cuDSS / NVSHMEM / cuTENSOR | 0.7.1.4-1 / 3.5.19-1 / 2.7.0.5-1 | 0.7.1.4-1 / 3.5.19-1 / 2.7.0.5-1 |
| NCCL | `libnccl-2.30.4-1+cuda12.9` | `libnccl-2.30.4-1+cuda13.2` |
| UCX | 1.21.0 (lockfile `1.21.0-3.el9ai`) | 1.21.0 plus `ucx-cuda`, `ucx-gdrcopy`, `ucx-ib-mlx5-cuda` |
| Other | `libgomp-offload-nvptx` (x86\_64 only) | `openmpi-cuda`; `libgomp-offload-nvptx` (x86\_64 only) |

Both are aarch64 and x86\_64.

| Image | Builder | Conf | Index class | Rendered index URL (`main`) |
|---|---|---|---|---|
| `aipcc-cuda12.9-torch2.11-el9.8-app` | GitLab CI | `cuda12.9-torch2.11-el9.8-app.conf` | public channel | `https://packages.redhat.com/api/pypi/public-rhai/cuda12.9-torch2.11-ubi9-test/simple/` |
| `aipcc-cuda12.9-torch2.13-el9.8-app` | GitLab CI | `cuda12.9-torch2.13-el9.8-app.conf` | public channel | `https://packages.redhat.com/api/pypi/public-rhai/cuda12.9-torch2.13-ubi9-test/simple/` |
| `aipcc-cuda13.0-torch2.11-el9.8-app` | GitLab CI | `cuda13.0-torch2.11-el9.8-app.conf` | public channel | `https://packages.redhat.com/api/pypi/public-rhai/cuda13.0-torch2.11-ubi9-test/simple/` |
| `aipcc-cuda13.0-torch2.13-el9.8-app` | GitLab CI | `cuda13.0-torch2.13-el9.8-app.conf` | public channel | `https://packages.redhat.com/api/pypi/public-rhai/cuda13.0-torch2.13-ubi9-test/simple/` |
| `aipcc-cuda13.0-torch2.14-el9.8-app` | GitLab CI | `cuda13.0-torch2.14-el9.8-app.conf` | public channel | `https://packages.redhat.com/api/pypi/public-rhai/cuda13.0-torch2.14-ubi9-test/simple/` |
| `base-image-cuda-12-9` | Konflux | `cuda12.9-el9.8-app.conf` | legacy product-versioned | `https://packages.redhat.com/api/pypi/public-rhai/rhoai/3.6/cuda12.9-ubi9-test/simple/` |
| `base-image-cuda-13-0` | Konflux | `cuda13.0-el9.8-app.conf` | legacy product-versioned | `https://packages.redhat.com/api/pypi/public-rhai/rhoai/3.6/cuda13.0-ubi9-test/simple/` |

### NVIDIA Rubin

- **Status:** In development (inferred: no channel or catalog row, no AutoQA,
  and the builder's `torch-2.11.0/rubin-ubi9` collection describes CUDA 13.4 as
  a Developer Preview; `images/base/README.md` lists Rubin as supported).
  **Lockfile input:** `context/rubin/rpms.in.yaml`. **Containerfile:**
  `Containerfile.rubin-app`.
- **Architectures:** aarch64, x86\_64. **Conf `NAME`:** `rhaibi-rubin-el9.8`.
- **Distribution scope:** `private`
- **Driver requirement:** `NVIDIA_REQUIRE_CUDA=cuda>=13.4 driver>=615`
  (`CUDA_VERSION=13.4.2`).
- **CUDA levels:** the RPM closure is CUDA 13.4 (`cuda-*-13-4`, lockfile
  `cuda-cudart-13-4` 13.4.92-1) with `cuda-compat-13-4-615.71.09-1.el9`,
  cuDNN 9.24.1.1-1, cuDSS 0.8.0.10-1, NVSHMEM 3.8.0-1, cuSPARSELt 0.9.1.1-1,
  cuTENSOR 2.8.1.0-1 and `libnccl-2.32.3-1+cuda13.4` (AIPCC-32532), plus
  `libcublas-devel`, `libcurand-devel` and `libnccl-devel`, and UCX 1.21.0 with
  CUDA extras.
- **Index:** `ci-job-definitions.yml` says no Rubin channel or publishing
  target exists in `rhai-pipeline/channels.yml`, and no `rhai_pipeline`
  variant builds `rubin-ubi9`. Within Fondue only the builder's
  `torch-2.11.0/rubin-ubi9` collection builds Rubin wheels; `rhaiis/pipeline`
  also builds `rubin-ubi9` (overlay 0021).

| Image | Builder | Conf | Index class | Rendered index URL (`main`) |
|---|---|---|---|---|
| `aipcc-rubin-el9.8-app` | GitLab CI | `rubin-el9.8-app.conf` | legacy product-versioned | `https://packages.redhat.com/api/pypi/public-rhai/rhoai/3.6/rubin-ubi9-test/simple/` |
| `base-image-rubin` | Konflux | `rubin-el9.8-app.conf` | legacy product-versioned | same as above |

### AMD ROCm

- **Status:** Active. **Lockfile input:** `context/rocm/rpms.in.yaml`.
  **Containerfile:** `Containerfile.rocm-app`. Confs set `ROCM_VERSION=7.14`
  and `ROCM_HOME=/opt/rocm/core` (a symlink to the versioned
  `/opt/rocm/core-7.x/` directory).
- **Architectures:** x86\_64. **Conf `NAME`:** `rhaibi-rocm7.14-el9.8`.
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

| Image | Builder | Conf | Index class | Rendered index URL (`main`) |
|---|---|---|---|---|
| `aipcc-rocm7.14-torch2.11-el9.8-app` | GitLab CI | `rocm7.14-torch2.11-el9.8-app.conf` | public channel | `https://packages.redhat.com/api/pypi/public-rhai/rocm7.14-torch2.11-ubi9-test/simple/` |
| `aipcc-rocm7.14-torch2.12-el9.8-app` | GitLab CI | `rocm7.14-torch2.12-el9.8-app.conf` | public channel | `https://packages.redhat.com/api/pypi/public-rhai/rocm7.14-torch2.12-ubi9-test/simple/` |
| `base-image-rocm-7-14` | Konflux | `rocm7.14-el9.8-app.conf` | legacy product-versioned | `https://packages.redhat.com/api/pypi/public-rhai/rhoai/3.6/rocm7.14-ubi9-test/simple/` |

### Intel Gaudi

- **Status:** Active. **Lockfile input:** `context/gaudi/rpms.in.yaml`.
  **Containerfile:** `Containerfile.gaudi-app`. Confs set
  `GAUDI_VERSION=1.24.1` and `GAUDI_REVISION=482`.
- **Architectures:** x86\_64. **Conf `NAME`:** `rhaibi-gaudi`.
- **Distribution scope:** `private`
- **Pinned RPMs (lockfile EVR `1.24.1-482.el9`):** `habanalabs-rdma-core`
  (installed separately with `--nodeps`), `habanalabs-thunk`,
  `habanalabs-firmware-tools`, `habanalabs-graph`, all `-1.24.1-482.el9`.
- **Index:** a private channel. It serves non-redistributable Habanalabs
  wheels built by `rhai-pipeline/collections/rhaiis/` (overlay 0020; not the
  `rhaiis/pipeline` repository); downstream product builds consume it directly.

| Image | Builder | Conf | Index class | Rendered index URL (`main`) |
|---|---|---|---|---|
| `aipcc-gaudi-torch2.11-el9.8-app` | GitLab CI | `gaudi-torch2.11-el9.8-app.conf` | private channel | `https://private.console.redhat.com/api/pypi/rhai/gaudi-torch2.11-ubi9-test/simple/` |
| `base-image-gaudi` | Konflux | `gaudi-el9.8-app.conf` | legacy product-versioned (private host) | `https://private.console.redhat.com/api/pypi/rhai/rhaiis/3.6/gaudi-ubi9-test/simple/` |

### IBM Spyre

- **Status:** Active. **Lockfile input:** `context/spyre/rpms.in.yaml`.
  **Containerfile:** `Containerfile.spyre-app`.
- **Architectures:** ppc64le, s390x, x86\_64. **Conf `NAME`:** `rhaibi-spyre`.
- **Distribution scope:** `private`
- **Index:** Spyre wheels are built by `rhai-pipeline/` into the public
  `spyre-torch2.11-ubi9` channel (overlay 0020). The builder's private Spyre
  PyPI (pre-built torch-sendnn/torch-nnpa wheels) is a separate mechanism.
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

  Non-versioned Spyre packages `hwloc`, `python3.12-pybind11` and `libpdfium`
  are also declared. RPMs come from the IBM Spyre yum repository
  (`./repo/spyre.repo`).

| Image | Builder | Conf | Index class | Rendered index URL (`main`) |
|---|---|---|---|---|
| `aipcc-spyre-torch2.11-el9.8-app` | GitLab CI | `spyre-torch2.11-el9.8-app.conf` | public channel | `https://packages.redhat.com/api/pypi/public-rhai/spyre-torch2.11-ubi9-test/simple/` |
| `base-image-spyre` | Konflux | `spyre-el9.8-app.conf` | legacy product-versioned | `https://packages.redhat.com/api/pypi/public-rhai/rhoai/3.6/spyre-ubi9-test/simple/` |

### AWS Neuron

- **Status:** In development. **Lockfile input:** `context/neuron/rpms.in.yaml`.
  **Containerfile:** `Containerfile.neuron-app`.
- **Architectures:** x86\_64. **Conf `NAME`:** `rhaibi-neuron`.
- **Distribution scope:** `private`
- **Index:** a private channel serving non-redistributable AWS Neuron SDK
  wheels; downstream product builds consume it directly.
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

| Image | Builder | Conf | Index class | Rendered index URL (`main`) |
|---|---|---|---|---|
| `aipcc-neuron-torch2.9-el9.8-app` | GitLab CI | `neuron-torch2.9-el9.8-app.conf` | private channel | `https://private.console.redhat.com/api/pypi/rhai/neuron-torch2.9-ubi9-test/simple/` |
| `base-image-neuron` | Konflux | `neuron-el9.8-app.conf` | legacy product-versioned (private host) | `https://private.console.redhat.com/api/pypi/rhai/rhaiis/3.6/neuron-ubi9-test/simple/` |

### Google TPU

- **Status:** In development. **Lockfile input:** `context/tpu/rpms.in.yaml`.
  **Containerfile:** `Containerfile.tpu-app`.
- **Architectures:** x86\_64. **Conf `NAME`:** `rhaibi-tpu`.
- **Distribution scope:** `private`
- **Index:** a private channel serving non-redistributable Google TPU /
  Torch-XLA wheels.
- **Notes:** no accelerator RPMs and no vendor repo beyond RHEL EUS and RHELAI.

| Image | Builder | Conf | Index class | Rendered index URL (`main`) |
|---|---|---|---|---|
| `aipcc-tpu-torch2.10-el9.8-app` | GitLab CI | `tpu-torch2.10-el9.8-app.conf` | private channel | `https://private.console.redhat.com/api/pypi/rhai/tpu-torch2.10-ubi9-test/simple/` |
| `base-image-tpu` | Konflux | `tpu-el9.8-app.conf` | legacy product-versioned (private host) | `https://private.console.redhat.com/api/pypi/rhai/rhaiis/3.6/tpu-ubi9-test/simple/` |

### Torch Day 0 (Konflux only)

Status: Active, built by Konflux only. GitLab CI no longer builds Torch Day 0
images and no `rhai-pipeline/` job on
`main` writes their indexes; the `torch-cpu` and `torch-cuda-13-0` Konflux
pipelines still build them on tags (table above). Both confs carry
`regen-skip: INDEX_BASE_URL,INDEX_VERSION,INDEX_STAGE`, set
`INDEX_VERSION=torch-2.14.0` and an empty `TORCH_VERSION`, and render a legacy
torch-versioned index.

| Image | Conf | Lockfile | Conf `NAME` | Scope | Rendered index URL (`main`) |
|---|---|---|---|---|---|
| `torch/torch-cpu` | `torch-cpu-el9.8-app.conf` | `context/cpu` | `torch-base-cpu` | `authoritative-source-only` | `https://packages.redhat.com/api/pypi/public-rhai/torch-2.14.0-cpu-ubi9-test/simple/` |
| `torch/torch-cuda-13-0` | `torch-cuda13.0-el9.8-app.conf` | `context/cuda-13.0` | `torch-base-cuda13.0-el9.8` | `private` | `https://packages.redhat.com/api/pypi/public-rhai/torch-2.14.0-cuda13.0-ubi9-test/simple/` |

The CUDA conf has the same driver requirement as CUDA 13.0.2 and also defines
CUDA library build args (`CUDNN_VERSION`, `CUDA_UCX_VERSION=1.20.1-1`, ...)
that no base-image Containerfile consumes; installed versions come from the
lockfile.

### Retired Accelerators

#### NVIDIA CUDA 13.2.1

Retired by AIPCC-31823 (commit `5add017de`, "Remove CUDA 13.2 builder and
base image variants"). No `cuda13.2` conf, CI entry, or builder variant exists
on `main`. Before that commit, `cuda13.2-el9.8-app.conf` used the
`context/cuda-13.0` lockfile (`LOCKFILE_VARIANT`) and required driver
`>=595.58.03`.

#### AMD ROCm 6.4

Retired in RHAI 3.5-EA1
([AIPCC-15426](https://issues.redhat.com/browse/AIPCC-15426); commits
`78511b483` and `c5b2fbaba`); the base image and Tekton pipelines were
removed. ROCm 7.14 is the current supported version.

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
  workloads. Rubin has no content channel: its GitLab CI and Konflux images
  render the legacy `rhoai/3.6/rubin-ubi9-test` index, which no `rhai-pipeline/`
  job on `main` writes (within Fondue only the builder's
  `torch-2.11.0/rubin-ubi9` collection builds Rubin wheels, and
  `rhaiis/pipeline` builds `rubin-ubi9` wheels but has no Pulp path, overlay
  0021). Rubin strategies must also plan index publication: a catalog row,
  `rhai_pipeline` variant and `torch_versions` (including a `variant-linter`
  pattern approval, overlay 0020), and image `torch_versions` (overlay 0030).
- Intel Gaudi is Active in the `base_images` build matrix (x86_64) with Konflux
  pipelines. `images/base/README.md` still marks Gaudi disabled (a note citing
  AIPCC-3471, now Closed); that note is stale. Its Konflux push pipeline
  (`base-image-gaudi`, conf `gaudi-el9.8-app.conf`, legacy private
  `rhaiis/3.6` index) runs only on `base-v*`/`base-gaudi-v*` tags. The channel
  image `aipcc-gaudi-torch2.11-el9.8-app` (`gaudi-torch2.11-ubi9`) has no
  Konflux pipeline: GitLab CI builds it on `main` pushes that touch
  `images/base/`, `images/shared/` or `.tekton/`, and on any `base-*` tag.
- AMD ROCm 6.4 is retired; any references in strategies or RFEs must be updated
  to ROCm 7.14, the current supported version.
- Two active CUDA versions (12.9, 13.0) are maintained simultaneously,
  with a third (Rubin / CUDA 13.4) in development. CUDA 13.2
  was retired (AIPCC-31823). Strategies and RFEs proposing CUDA-dependent features
  should specify the minimum driver version requirement, since each version has a
  different minimum driver (525.60.13 for 12.9, 580.95.05 for 13.0, 615 for
  Rubin/13.4). Note that cuDNN versions differ between CUDA 12.9 (9.22.0.52),
  CUDA 13.0 (9.19.0.56) and Rubin (9.24.1.1); CUDA-version-specific cuDNN
  changes require coordinated lockfile updates.
- IBM Spyre and AWS Neuron SDK RPM version pins are declared as versioned
  package names in `context/<variant>/rpms.in.yaml` (AIPCC-29839) — not in
  build-args conf files. The SDKs' Python wheels are pinned separately in the
  consuming `rhai-pipeline/collections/*/<variant>/` requirements/constraints
  (e.g. `torch-sendnn==1.3.1` for Spyre; `torch-neuronx`, `neuronx-cc` for
  Neuron), so an SDK bump must update both. IBM Spyre uses arch-conditional
  packages; the ppc64le and s390x package sets differ from x86_64 (see table
  above).
- Images are per accelerator and torch version, and the image torch matrix
  (`base_images.variants.*.torch_versions`) is declared separately from the
  wheel channel matrix, so a built channel can have no image
  (`cpu-torch2.14-ubi9` today). Strategies must pick the torch-qualified image
  whose channel matches the wheels they install, and use overlay
  [0030](0030-aipcc-content-channels.md) for channel identity and the recipe
  to add a torch version.
- Adding an accelerator needs, on the base-image side: an
  `images/base/Containerfile.<accel>-app` (hand-edited outside the
  `### BEGIN`/`### END` blocks that `make regen` rewrites) and an
  `APP_VARIANTS` entry in `images/base/Makefile` (plus `CONF_NAMES` for an
  accelerator-only conf); `context/<accel>/rpms.in.yaml`, with any vendor repo
  file in `contentOrigin.repofiles`, and its `rpms.lock.yaml`, regenerated
  with `bin/hermetic-generate-lockfiles.sh` on VPN or an entitled host; one
  `build-args/<accel><version>-torch<X.Y>-el9.8-app.conf` per image torch
  version; a `base_images.variants` entry in `ci-job-definitions.yml`
  (`version`, `arches`, `pulp_test_arches`, `autoqa_test_arches`,
  `torch_versions`); then `make regen`. A Konflux pipeline is a change in
  aipcc-product-management-configs, since PMT generates `.tekton/`. A new
  torch image for an existing accelerator needs only its conf and
  `torch_versions` entry, plus a fallback in `context/common/index-url.sh`
  when no built CPU channel has that torch version. Overlay
  [0030](0030-aipcc-content-channels.md) has the cross-component recipe.
- Torch Day 0 base images (`torch-base-*`) serve a torch release from a
  version-pinned legacy index (`torch-2.14.0-*`) and are now built only by
  Konflux; GitLab CI builds per-torch channel images instead (for torch 2.14
  on CUDA 13.0, `aipcc-cuda13.0-torch2.14-el9.8-app`). Strategies must not treat
  them as the product-versioned base images or as the old fast/stable
  base-image channels (overlay 0030 explains the term "channel"). Do not
  change the torch version, CUDA version or index variant of an existing
  index; ABI-breaking updates need a new channel (a new torch version is a new
  channel name) and a matching image config.
- Python package indexes differ by image and must not be treated as uniform.
  The URL baked into each image is the fully rendered `INDEX_URL_TEMPLATE`
  (including the channel or legacy variant, the `INDEX_STAGE` `-test`/prod
  suffix, and `/simple/`) — not the bare `INDEX_BASE_URL`. On `main` all
  rendered URLs point at the `-test` (staging) index; release branches set
  their own `INDEX_STAGE` (the argfile documents an empty, unsuffixed
  production stage for release builds). A URL that resolves does not prove the
  index has content (overlay 0030).
  - **Public channel indexes** (CPU, CUDA, ROCm, Spyre) are the default for
    most strategies: `https://packages.redhat.com/api/pypi/public-rhai/<channel>-test/simple/`,
    e.g. `.../public-rhai/cuda13.0-torch2.13-ubi9-test/simple/`. Strategies
    adding Python dependencies for these images must ensure the packages are
    built into the matching channel. Spyre wheels are published to its public
    channel alongside other variants; the builder's private Spyre PyPI (for
    pre-built torch-sendnn/torch-nnpa wheels) is a separate, distinct
    mechanism.
  - **Private channel indexes** (Gaudi, Neuron, TPU) **replace** the public
    index entirely (single `index-url` in pip/uv config; no fallback), e.g.
    `https://private.console.redhat.com/api/pypi/rhai/gaudi-torch2.11-ubi9-test/simple/`.
    They are built from `rhai-pipeline/collections/rhaiis/` (overlay 0020; not
    the `rhaiis/pipeline` repository) because their wheels (Habanalabs, AWS
    Neuron SDK, Torch-XLA) are non-redistributable. Downstream product
    container builds consume the private index directly. Strategies targeting
    these variants must not assume the public RHEL AI index is reachable or
    sufficient — dependency resolution will fail if directed to the wrong
    index.
  - **Legacy indexes:** every Konflux pipeline and the GitLab CI Rubin image
    still render product-versioned paths (`.../public-rhai/rhoai/3.6/<variant>-test/simple/`,
    or `.../rhai/rhaiis/3.6/<variant>-test/simple/` for the private
    variants), and the Torch Day 0 pipelines render
    `.../public-rhai/torch-2.14.0-<variant>-test/simple/`. No build job on
    `main` uploads to these paths (overlay 0030).

## Context

This overlay was created to capture the accelerator base image landscape as a
reference for evaluating RFEs proposing accelerator updates or additions. The
generated architecture docs for individual components (vLLM, InstructLab, etc.)
do not describe the shared base image layer or the current status of each
accelerator variant. This overlay fills that gap so that strategy pipelines,
architecture reviews, and design validation tooling have an authoritative,
up-to-date view of which accelerators are active, in development, disabled, or
retired, and what the common foundation looks like across all variants.

Maintained with the `update-fondue-overlays` skill; last refreshed 2026-10-01
from Fondue `main` (`18d0c049d`).
