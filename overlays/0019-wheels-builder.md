---
id: "0019"
title: AIPCC Wheels Builder
status: active
created: 2026-07-15
affects:
  - platform
release:
  - "3.6"
  - "3.7"
  - "next"
provenance:
  - https://gitlab.com/redhat/rhel-ai/wheels/fondue/-/tree/main/builder
  - https://gitlab.com/redhat/rhel-ai/wheels/fondue/-/tree/main/images/builder
author: Lance Barto
superseded_by: null
---

## Fact

The AIPCC wheels builder is the build platform for all Python wheels in the
RHAI/RHAIIS ecosystem. It lives in the Fondue monorepo
(`redhat/rhel-ai/wheels/fondue`) as `builder/` (plugins, overrides,
pipeline-api), `images/builder/` (Containerfiles, build args, image job
template) and `releases/builder-release.yaml` (release tag). It has two tightly
coupled roles:

**API Provider**: `builder/pipeline-api/` is a GitLab CI include library
(`ci-wheelhouse.yml`) that gives consumers fully defined build pipelines
without repeating build logic. Its two consumers get the builder differently:
`rhai-pipeline/` uses the in-tree builder (see Release State), while the
separate `rhaiis/pipeline` repository pins a Fondue release ref (see
[0021](0021-rhaiis-pipeline.md)).

**Build Factory**: Owns the per-variant builder container images, the package
plugin system (184 plugins), and all build overrides and patches. Internal test
collections are maintained in the separate `wheels-test` repository; the
collections in `builder/collections/` are build-verification sets for the
builder's own CI, and the `torch-X.Y.Z/` ones are also the torch pin source
for content channel builds (see Internal Collections).

### Release State

- **Release declared on `main`:** `v47.1.0` (`releases/builder-release.yaml`,
  field `version:`). A protected-branch push that changes this file creates the
  tag (`builder/pipeline-api/release-automation.yml`; the push pipeline runs
  with `RELEASE_ONLY_PIPELINE=true`), and the tag pipeline builds the builder
  images tagged with it. `main` sometimes declares a patch release and release
  branches tag others, so the declared tag is not a consumer's pin.
- **Base OS version:** `builder/product-version.yml` `PRODUCT_VERSION: "0.0-el9.8"`
  is the OS the builder targets (RHEL 9.8; `0.0` = 9.4, `0.0-el9.6` = 9.6). It
  drives builder-collection release tags (`builder-0.0-el9.8.<IID>+...`) and
  the builder collection cache path (`<collection>-0.0-el9.8/<variant>-<arch>`,
  see Internal Collections; `builder_pipeline` in
  `ci-job-definitions.yml`). The `ci-<VERSION>-` image tags come from
  `BUILDER_PRODUCT_VERSION` instead (next bullet), which must name the same
  OS. It is not a builder release.
- **Image tags:** root `.gitlab-ci.yml` sets `BUILDER_PRODUCT_VERSION: "0.0-el9.8"`;
  `builder-image-version.yml`, included last, sets
  `BUILDER_IMAGE_VERSION: ci-${BUILDER_PRODUCT_VERSION}-${CI_MERGE_REQUEST_IID}`.
  MR pipelines tag images `ci-0.0-el9.8-<MR IID>`, post-merge pipelines
  `ci-0.0-el9.8-`, tag pipelines the git tag (`v*`). The separate variable lets
  `rhai-pipeline/` set its own `PRODUCT_VERSION` without affecting image tags.
- **How consumers get the builder:** `rhai-pipeline/` jobs run the in-tree images
  selected by `BUILDER_IMAGE_VERSION`, so MR pipelines use that MR's builder
  images and non-MR pipelines use the branch's `ci-0.0-el9.8-` images. Builder
  images rebuild on protected pushes that touch builder-relevant paths and on
  the nightly schedule. This is not a release tag. `rhaiis/pipeline` pins a
  Fondue release ref (overlay 0021).
- **RHEL AI repo version:** `3.6` (`images/builder/build-args/rhelai.conf`, which
  also sets `GOLANG_MIN_VERSION=1.26.3`, `RUST_MIN_VERSION=1.97`).

### Builder Images

One image is built per variant x architecture: 10 variants, 18 images
(`ci-job-definitions.yml` `builder_images.variants`).

**Common foundation (all variants except `cpu-hb`):**

| Item | Value |
|---|---|
| Base OS | RHEL 9.8, `registry.access.redhat.com/ubi9/ubi:9.8-1790067847` (`build-args/common.conf` `BASE_IMAGE`) |
| Python | 3.12 (`common.conf` `PYTHON_VERSION`) |
| GCC toolset | 14, default via `ENV PATH=/opt/rh/gcc-toolset-14/root/usr/bin:...` in `containerfiles/header-ubi9` (AIPCC-10154) |
| Registry | `registry.gitlab.com/redhat/rhel-ai/wheels/fondue/builder-{VARIANT}-{ARCH}:{TAG}` |

**`cpu-hb` exception:** a Hummingbird FIPS variant on the non-UBI9 base
`registry.access.redhat.com/hi/python:3.12-fips-builder` (`build-args/cpu-hb.conf`
overrides `BASE_IMAGE`; `header-hb` pins `PYTHON_VERSION=3.12`), x86_64 only.

Containerfiles are assembled by `make regen` (root `Makefile`) from
`containerfiles/header-ubi9` + `{variant}-ubi9` + `llvm-triton-{variant}-ubi9` +
`footer-ubi9`; `cpu-hb` uses `header-hb` + `cpu-hb` + `footer-hb` with no
LLVM/Triton layer. The image job maps every `cuda*` variant to
`Containerfile.cuda-ubi9` and every `rocm*` variant to
`Containerfile.rocm-ubi9` (`images/builder/gitlab-ci/images.yml`); `rubin-ubi9`
has its own Containerfile. The LLVM images are built in Fondue from
`llvm_triton_images` in `ci-job-definitions.yml` (AIPCC-30320). LLVM commits in
`common.conf`:

| Triton version | LLVM commit |
|---|---|
| 3.5.0 | `7d5de303` |
| 3.6.0 | `f6ded0be` |
| 3.7.0 | `ac5dc54d` |
| 3.7.1 | `1f126a6d` |
| 3.8.0 | `5f07f818` |
| 3.8.0+rhaiv.1 | `46111560` |

cpu, cuda, rubin and rocm layers use all six; gaudi and spyre use 3.6.0 only;
neuron 3.5.0; tpu 3.5.0 and 3.6.0.

**Variant × Architecture Matrix** (`ci-job-definitions.yml`
`builder_images.variants`; `images/builder/gitlab-ci/images.yml` is only the job
template):

| Variant | Architectures | Hardware |
|---|---|---|
| `cpu-ubi9` | aarch64, ppc64le, s390x, x86_64 | Generic CPU |
| `cpu-hb` | x86_64 | Hummingbird FIPS CPU (non-UBI9 base) |
| `cuda12.9-ubi9` | aarch64, x86_64 | NVIDIA CUDA 12.9.1 |
| `cuda13.0-ubi9` | aarch64, x86_64 | NVIDIA CUDA 13.0.2 (drops compute capability < 7.5) |
| `rubin-ubi9` | aarch64, x86_64 | NVIDIA Rubin, CUDA 13.4.2 (conf comment: R616 driver) |
| `gaudi-ubi9` | x86_64 | Intel Gaudi 1.24.1 (rev 482) |
| `neuron-ubi9` | x86_64 | AWS Trainium/Inferentia (Neuron SDK via RPMs, Python 3.12) |
| `rocm7.14-ubi9` | x86_64 | AMD ROCm 7.14.0 (gfx90a, gfx942, gfx950) |
| `spyre-ubi9` | ppc64le, s390x, x86_64 | IBM Spyre |
| `tpu-ubi9` | x86_64 | Google Cloud TPU (Torch/XLA) |

Not every image is consumed downstream: cross-reference the `rhai-pipeline/`
matrix (overlay 0020) and `rhaiis/pipeline` (overlay 0021) for active variants.
No `rhai-pipeline/` collection uses `rubin-ubi9` or `cpu-hb`. Within Fondue
only builder collections use them (`torch-2.11.0` for `rubin-ubi9`,
`torchless` for `cpu-hb`); `rhaiis/pipeline` also builds `rubin-ubi9`
(overlay 0021). The Rubin builder conf comment names an R616 driver, while the
Rubin base image conf requires `driver>=615` (overlay 0017).

CUDA arch lists (`build-args/cuda*-ubi9.conf`, `rubin-ubi9.conf`):

- CUDA 12.9.1: `TORCH_CUDA_ARCH_LIST=7.5 8.0 8.6 8.7 8.9 9.0a 10.0 10.0a 12.0+PTX`
- CUDA 13.0.2: `TORCH_CUDA_ARCH_LIST=7.5 8.0 8.6 8.7 8.9 9.0a 10.0 10.0a 12.0 12.1+PTX`
- Rubin (CUDA 13.4.2): `TORCH_CUDA_ARCH_LIST=10.7a+PTX` (Rubin R100 / sm_107a
  only); the conf also pins cuDNN 9.24.1.1, cuDSS 0.8.0.10, NVSHMEM 3.8.0-1,
  NCCL 2.32.3-1 and the Arm Compute Library `v52.8.0` (AIPCC-21237)

Both CUDA builder confs pin `LIBNCCL_VERSION=2.30.4-1`, commented as matching
the base image (AIPCC-19609); the base images now lock NCCL 2.30.7 and CUDA
13.0.3 (overlay 0017), while the CUDA 13.0 builder stays on CUDA 13.0.2.

**ROCm 7.14** (`build-args/rocm7.14-ubi9.conf`): `ROCM_VERSION=7.14.0`,
`ROCM_GPUS=gfx90a;gfx942;gfx950` (MI200 CDNA2, MI300 CDNA3, MI350/MI355 CDNA4),
`ROCM_HOME=/opt/rocm/core` (kpack multi-arch, installs under
`/opt/rocm/core-7.14/`), `HIPFLAGS=--offload-compress`,
`FLASH_ATTENTION_GPU_ARCHS=gfx90a;gfx942;gfx950`, and a CUDA 12.9.1 toolchain for
the AOTriton build. LLVM pins: AOTriton 0.9b0 `86b69c31`, 0.10b0 `3c709802`,
0.11b0 `57088512`, 0.12b0 `7f77ca0d`, FlyDSL `7f77ca0d`; the ROCm LLVM layer
consumes 0.11b0, 0.12b0 and FlyDSL.

### Pipeline-API Contract

Each instantiation of `builder/pipeline-api/ci-wheelhouse.yml` covers one
(COLLECTION x VARIANT x ARCH), plus a torch version in channel mode. The
`VARIANT` input enum has **9 options**: `cpu-ubi9`, `cuda12.9-ubi9`,
`cuda13.0-ubi9`, `rubin-ubi9`, `gaudi-ubi9`, `neuron-ubi9`, `rocm7.14-ubi9`,
`spyre-ubi9`, `tpu-ubi9`. The `VARIANT` options in
`images/builder/gitlab-ci/images.yml` and `builder_images.variants` both list
10 variants: they add `cpu-hb` (non-UBI9 base). In Fondue, `bin/regen-ci.py`
expands the template inline from `ci-job-definitions.yml` into `.generated/`
without checking the enum, so `cpu-hb` never passes through the `VARIANT`
input.

All accepted inputs (26):

| Input | Type | Default | Description |
|---|---|---|---|
| `JOB_PREFIX` | string | `""` | Prefix added to all generated job names |
| `COLLECTION` | string | (required) | Collection name (e.g., `rhai`, `rhaiis`) |
| `COLLECTION_SLUG` | string | (required) | `COLLECTION` with `/` -> `-` (e.g., `example/torch-2.13` -> `example-torch-2.13`); used for tarball names and index paths |
| `VARIANT` | enum | (required) | Accelerator variant; one of the 9 options |
| `ENABLE_REPEATABLE_BUILD_MODE` | boolean | `false` | Lock dependency graph from prior bootstrap |
| `ENABLE_MULTI_VERSION_BOOTSTRAP` | boolean | `false` | Bootstrap multiple package versions |
| `MAX_RELEASE_AGE` | string | `""` | Max release age in days (required with multi-version bootstrap) |
| `BOOTSTRAP_MODE` | enum | `sdist-only` | `sdist-only`, `full`, `full-parallel` |
| `BUILD_MODE` | enum | `serial` | `parallel` (graph file) or `serial` (build order) |
| `ARCH` | enum | `x86_64` | aarch64, ppc64le, s390x, x86_64 |
| `BUILD_ON_ALL_PUSHES` | boolean | `false` | Trigger even without collection file changes |
| `ENABLE_NIGHTLY_BUILDS` | boolean | `false` | Enable nightly scheduled builds |
| `ENABLE_TEST_JOBS` | boolean | `false` | Run MR-level test bootstrap jobs |
| `ENABLE_JOB` | boolean | `true` | Master switch for all jobs in this instantiation |
| `RETRY` | number | `0` | Job retry count (0, 1, or 2) |
| `ALLOW_FAILURE` | boolean | `false` | Allow job failure without blocking the pipeline |
| `COLLECTIONS_DIR` | string | `builder/collections` | Collections dir, relative to repo root |
| `BUILDER_DIR` | string | `builder` | Dir containing `pipeline-api/` and scripts |
| `PRODUCT_VERSION` | string | `${PRODUCT_VERSION}` | Product version for wheel index paths and release naming |
| `RELEASE_TAG_PREFIX` | string | `""` | Release tag prefix (e.g. `builder-`, `rhai-`) |
| `PRODUCT_VERSION_FILE` | string | `product-version.yml` | Product version YAML used in `changes:` rules |
| `CHANNEL` | string | `""` | Channel name (e.g. `cpu-torch2.11-el9.8`), resolved by `regen-ci.py` from the catalog row for the variant and torch version; selects the channel wheel-server path and upload target |
| `TORCH_VERSION` | string | `""` | Torch major.minor of the channel; selects the collection's `torch/*-torch-<X.Y>.txt` overlays |
| `BUILDER_TORCH_COLLECTION` | string | `""` | Builder collection directory (e.g. `torch-2.11.0`) whose `<variant>/constraints.txt` replaces the rules files; empty outside channel mode or when skipped |
| `WHEEL_SERVER_PROJECT_PATH` | string | `${WHEEL_SERVER_PROJECT_PREFIX}/${COLLECTION}-${PRODUCT_VERSION}/${VARIANT}-${ARCH}` | Pre-computed GitLab wheel project: `{prefix}/{slug}-{channel}/{arch}` in channel mode, `{prefix}/{slug}-{version}/{variant}-{arch}` otherwise |
| `PULP_CACHE` | string | `"false"` | `true` uses the Pulp `-test` index as the wheel cache and uploads to Pulp instead of GitLab. The description says "Builder collections only", but builder collections set it to `"false"` and most `rhai-pipeline/` jobs set it to `true` (overlay 0020) |

`EPHEMERAL_COLLECTION` is not a spec input: when set as a CI variable, the
`before_script` synthesizes a collection from `REQUIREMENTS_TXT`,
`CONSTRAINTS_TXT` and `CONSTRAINTS_RULES_TXT`.

**Jobs per instantiation** (four jobs, three stages, plus an optional test job):

1. `{COLLECTION}-{VARIANT}-{ARCH}-bootstrap-and-onboard` (stage `bootstrap`) —
   fromager dependency resolution; uploads patched sdists to the sdist server
2. `{COLLECTION}-{VARIANT}-{ARCH}-build-wheels` (stage `build`) — compiles wheels
   inside the builder container; when `rhai-pipeline/bin/upload_to_pulp.sh`
   exists next to the collections directory, it then uploads to Pulp
3. `{COLLECTION}-{VARIANT}-{ARCH}-release-tarball` (stage `release`) — packages
   artifacts into the GitLab Generic Package Registry
4. `{COLLECTION}-{VARIANT}-{ARCH}-publish-wheels` (stage `release`) — creates a
   GitLab Release (skipped when `PUBLISH_WHEEL_RELEASES` is `false`)

With `ENABLE_TEST_JOBS`, `test-...-bootstrap-and-onboard` runs a `full-parallel`
bootstrap on MRs that touch the collection files (including the matching
`torch/*-torch-<X.Y>.txt` overlay), `builder-image-version.yml` or the product
version file.

**Channel-mode names:** for a channel, `regen-ci.py` replaces
`{COLLECTION}-{VARIANT}-{ARCH}` with `{COLLECTION}-{CHANNEL}-{ARCH}` in job
names and references, so the generated jobs are
`rhai-cpu-torch2.11-el9.8-x86_64-build-wheels` and similar, and release
versions are `{RELEASE_TAG_PREFIX}{PRODUCT_VERSION}.{CI_PIPELINE_IID}+{COLLECTION_SLUG}-{CHANNEL}-{ARCH}`
(e.g. `rhai-3.6.<IID>+rhai-cpu-torch2.11-el9.8-x86_64`). Builder collections
have no channel and keep variant names
(`builder-0.0-el9.8.<IID>+torch-2.11.0-cpu-ubi9-aarch64`).

**Trigger guard:** API jobs never run unless `$CI_PROJECT_ROOT_NAMESPACE == "redhat"`.
Image build jobs use the tighter `$CI_PROJECT_NAMESPACE == "redhat/rhel-ai/wheels"`.
Build and bootstrap jobs run on protected pushes only when the collection
files listed in their `changes:` rule change (or `BUILD_ON_ALL_PUSHES`), on
nightly schedules when `ENABLE_NIGHTLY_BUILDS`, and on web/API pipelines;
they never run for `wheel-publish`, `wheel-copy`, `wheel-promote` or
`channel-apply` pipelines.

**Runner tags:** bootstrap and build jobs use `aipcc-large-{ARCH}`;
release-tarball and publish-wheels use `aipcc`; image builds use
`aipcc-small-{ARCH}`. Bootstrap, build-wheels and test jobs all run
Podman-in-Podman inside
`registry.gitlab.com/redhat/rhel-ai/wheels/fondue/podman-stable:v5.8.2`
(all three extend the base job with that image).

### Build Toolchain

- **fromager**: core build orchestration. `FROMAGER_NETWORK_ISOLATION=1` is set in
  every builder Containerfile and in root `.gitlab-ci.yml` (no outbound
  internet during builds; sources are pre-fetched to the sdist server).
  `FROMAGER_MIN_RELEASE_AGE=3` (root `.gitlab-ci.yml`) blocks packages released
  fewer than 3 days ago; package settings bypass it with `min_release_age: 0`.
- **nginx local PyPI server**: `pipeline-api/nginx_server.sh` serves built wheels
  on `localhost:8080` so later packages in the graph can consume them.
- **Podman-in-Podman (PinP)**: bootstrap, build-wheels and test jobs run the
  builder image via `podman run` inside `podman-stable`, avoiding privileged
  Docker-in-Docker; the job clears
  `/var/lib/containers/storage/*` first.
- **`SECURITY_CONSTRAINTS_URL`**: external constraints file (project
  `redhat/rhel-ai/core/security-constraints`, AIPCC-17173) applied by
  `bootstrap_and_onboard.sh` and `build_wheels.sh`, so vulnerable versions can be
  blocked without a builder release.
- **Constraints assembly** (`pipeline-api/prepare_constraints.sh`): global
  constraints, then either the builder torch collection's
  `<variant>/constraints.txt` (channel mode, `BUILDER_TORCH_COLLECTION` set;
  the job fails if the file is missing, AIPCC-32417) or the
  `constraints-rules.txt` extraction, then the collection's `constraints.txt`
  and its `torch/constraints-torch-<X.Y>.txt` overlay. Requirements append the
  `torch/requirements-torch-<X.Y>.txt` overlay (AIPCC-31695).

### Package Plugin System

184 plugins are registered under
`[project.entry-points."fromager.project_overrides"]` in `builder/pyproject.toml`.
The most used override hooks are `prepare_source`, `get_resolver_provider`,
`build_wheel`, `update_extra_environ`, `get_build_system_dependencies` and
`download_source`. Global hooks (`fromager.hooks`) are `post_build`,
`post_bootstrap` and `prebuilt_wheel`.

**Notable plugins:**

- **`package_plugins/hooks/upload_after_build_wheel.py`** (registered for all
  three global hooks): validates artifact filenames. It uploads only in
  `build-wheels` jobs, the only jobs that set `RUN_CLEAN_AND_UPLOAD`. There,
  with `PULP_CACHE=true` it uploads each sdist and wheel to the Pulp cache
  repository (the `CHANNEL`'s `-test` repository in the catalog domain, else
  `<PULP_BASE_PATH>-test`, else the product-versioned `-test` repository; no
  job on `main` reaches the fallbacks) and skips files already there.
  Otherwise `post_build`
  deletes the same version from the GitLab PyPI project and then uploads the
  new sdist + wheel (clean-replace), while `prebuilt_wheel` uploads without
  deleting. It also emits Datadog telemetry events.
- **`vllm.py`** (most complex): uses midstream GitLab mirrors (NeuralMagic
  `nm-vllm-ent`) and injects CUTLASS, QuTLASS, Triton, oneDNN and Arm Compute
  Library sources; separate resolver matching per variant.
- **`torch.py`**: for CUDA variants, resolves pre-built torch wheels from
  per-CUDA GitLab projects (`_CUDA_PREBUILT_PROJECT_IDS`: 12.9, 13.0); standard
  resolution otherwise.
- **Simple setuptools-cap plugins**: 21 plugins only add a `setuptools<81` or
  `<82` build requirement (`utils.get_setuptools_constraint`) when `setup.py`
  uses removed APIs; four more (`llvmlite`, `pandas`, `pyarrow`, `torchvision`)
  apply the same cap alongside other overrides. This replaces the global
  setuptools ceiling (AIPCC-15912).

**Spyre-specific pre-built packages** (private Spyre PyPI index
`https://private.console.redhat.com/api/pulp-content/rhai/spyre-pypi/simple/`):

The builder settings define the *sourcing mechanism* only, not the pinned
version. Version pins live in the consuming collection's `requirements.txt`
or its `torch/requirements-torch-<X.Y>.txt` overlay (listed in overlay 0020);
torch-sendnn must match the Spyre SDK RPM version in
`images/base/context/spyre/rpms.in.yaml` (AIPCC-29839); torch-nnpa has its own
version line.

- **`torch_sendnn`** (`pre_built: true` for `spyre-ubi9`): IBM-distributed wheel
  mirrored by AIPCC. The settings changelog (historical only) ends at `1.1.1`
  (2026-02-19). Global constraint `torch-sendnn>=1.2.0` blocks non-redistributable
  older versions (AIPCC-14853).
- **`torch_nnpa`** (`pre_built: true` for `spyre-ubi9`): IBM-distributed s390x
  (Z) wheel from the same index; changelog `1.5.0` (2026-07-14).
- **`sendnn_inference`**: compiled from source; replaces `vllm-spyre`
  (AIPCC-14693); adds `setuptools` via `update_build_requires`.
- **`ibm_fms`**: built from source (pre-built variant removed) from the GitLab
  mirror
  `gitlab.com/redhat/rhel-ai/core/mirrors/github/foundation-model-stack/foundation-model-stack`.

### Internal Collections

Build-verification sets in `builder/collections/` (`builder_pipeline` in
`ci-job-definitions.yml`). The `torch-X.Y.Z/` collections are also the torch
pin source for content channel builds: `prepare_constraints.sh` reads
`builder/collections/<BUILDER_TORCH_COLLECTION>/<variant>/constraints.txt`.
Which torch version maps to which collection is owned by overlay
[0030](0030-aipcc-content-channels.md); every `torch-X.Y.Z/` directory below
is mapped by a `rhai_pipeline.torch_versions` entry.

| Collection | Variants | Purpose |
|---|---|---|
| `api-test/cpu-ubi9` | cpu-ubi9 | Pipeline API plumbing test (Pulp domain `rhai-stage`, `full-parallel` bootstrap) |
| `non-accelerated/cpu-ubi9` | cpu-ubi9 | CPU-only packages |
| `accelerated/` | (placeholder) | README only; no variant subdirs, not in the matrix |
| `torch-2.9.1/` | neuron-ubi9 | Torch 2.9.1 for AWS Neuron |
| `torch-2.10.0/` | tpu-ubi9 | Torch 2.10.0 for Google Cloud TPU |
| `torch-2.11.0/` | cpu-ubi9, cuda12.9-ubi9, cuda13.0-ubi9, gaudi-ubi9, rocm7.14-ubi9, rubin-ubi9, spyre-ubi9 | torch 2.11.0 + vLLM, ONNX Runtime, FlashInfer, etc. |
| `torch-2.12.0/` | rocm7.14-ubi9 | Torch 2.12.0 for ROCm 7.14 |
| `torch-2.13.0/` | cpu-ubi9, cuda12.9-ubi9, cuda13.0-ubi9 | Torch 2.13.0; cpu-ubi9 carries the broad CPU package set, CUDA variants a smaller torch + vLLM stack |
| `torch-2.14.0/` | cpu-ubi9, cuda13.0-ubi9 | Torch 2.14.0 with a minimal package set |
| `torchless/` | cpu-hb, cpu-ubi9 (aarch64, x86_64 via `omit_jobs`), rocm7.14-ubi9 | Non-torch packages |

Builder collections default to `pulp_cache: "false"` (AIPCC-32847) in
`public-rhai` (`api-test`: `rhai-stage`), so every builder collection job
caches in a GitLab PyPI project at
`redhat/rhel-ai/core/wheels/<collection>-<product_version>/<variant>-<arch>`
(e.g. `redhat/rhel-ai/core/wheels/torch-2.11.0-0.0-el9.8/cpu-ubi9-x86_64`;
`WHEEL_SERVER_PROJECT_PREFIX` in the root `.gitlab-ci.yml`). The Pulp
`pulp_cache_base_path` is inactive (`builder-cache/...` applies only when
`PULP_CACHE` is `true`), so no generated builder job uses it. The
`PULP_CACHE: "false"` overrides on `torch-2.11.0/gaudi-ubi9`,
`torch-2.10.0/tpu-ubi9` and `torch-2.9.1/neuron-ubi9` now match the default.

`collections/global-constraints.txt` carries cross-collection version
constraints, most with an AIPCC/RHAI/INFERENG ticket reference.
`collections/global-requirements.txt` adds `pip` and `setuptools` to every
build. `global-constraints.txt` has no `aiu-monitor<0.0.0` /
`ibm-aiu-monitor<0.0.0` guards (removed in AIPCC-28729): aiu-monitor is not a
wheel collection package and ships as an RPM in the Spyre base image
(`images/base/context/spyre/`).

### Global Configuration

`overrides/settings.yaml` carries:

- Global SBOM metadata (`supplier: "Organization: Red Hat"`, namespace, creators,
  `repository_url: "https://packages.redhat.com"`)
- A **changelog** with exactly one entry per base variant (cpu-ubi9, cpu-hb,
  cuda-ubi9, gaudi-ubi9, neuron-ubi9, rocm-ubi9, rubin-ubi9, spyre-ubi9,
  tpu-ubi9) so all wheels start with build tag `1`. The file warns against
  adding *global* changelog entries: one invalidates all cached wheels for a
  variant and forces a full rebuild. Per-package changelog entries are the
  intended mechanism. Every variant's entry is dated 2026-08-10 except
  neuron-ubi9 (2026-09-04).

`overrides/settings/` holds 294 per-package fromager settings files and
`overrides/patches/` 94 per-package-version patch entries (87 directories, 7
symlinks to shared sets) applied at build time.

## Impact on Strategies

- For a consumer that pins the builder (`rhaiis/pipeline`, which pins a Fondue
  release ref; overlay 0021), one `BUILDER_IMAGE_VERSION` value pins the
  compiler toolchain, build scripts, plugin set, and container images
  simultaneously. Updating it is a one-value change but may change the behavior
  of any package plugin. `rhai-pipeline/` has no such pin: its jobs always run
  the in-tree images (`ci-${BUILDER_PRODUCT_VERSION}-${CI_MERGE_REQUEST_IID}`).
  On `main`, the root `.gitlab-ci.yml` loads `.generated/rhai-*.yml` for MR,
  nightly and protected-push pipelines (`RHAI_INCLUDE_RULES` and
  `RHAI_POST_MERGE_RULE` in `bin/regen-ci.py`), but a push builds only the
  collection x channel jobs whose own files changed (collection requirements
  and constraints, rules files, matching `torch/` overlays,
  `builder-image-version.yml`, `rhai-pipeline/product-version.yml`);
  `build_on_all_pushes` is `false`. A merged builder change (plugins,
  overrides, builder torch collections) therefore reaches every collection at
  the next nightly build. Release branches (`3.6-EA1`, `3.6-EA2`) load them on
  push too, so there every protected push runs full builds. In the MR itself
  only the `test-*-bootstrap-and-onboard` jobs of collections with
  `enable_test_jobs` (`onboarding`, `ogx`) run, and only when the MR touches
  their collection files, `builder-image-version.yml` or
  `rhai-pipeline/product-version.yml`.
- Adding a new accelerator variant requires, on the builder side: new
  Containerfile parts (`containerfiles/<variant>` and `llvm-triton-<variant>`;
  `cpu-hb` with `header-hb`/`footer-hb` is the existing non-UBI9 precedent), a
  root `Makefile` `VARIANTS` entry, the `Containerfile`
  mapping in `images/builder/gitlab-ci/images.yml` (today `cuda*` and `rocm*`
  map to the shared `-ubi9` Containerfiles), a new build-args conf, an
  `overrides/settings.yaml` changelog entry, a `builder_images.variants` entry,
  the `release-notes` `needs` list in the root `.gitlab-ci.yml`, both
  `VARIANT` enums (`images/builder/gitlab-ci/images.yml`, 10 options, and
  `builder/pipeline-api/ci-wheelhouse.yml`, 9 options), and a
  `builder/collections/torch-X.Y.Z/<variant>/constraints.txt` for every torch
  version its channels build (channel jobs fail without it). A new OS stream
  touches files across components; overlay
  [0030](0030-aipcc-content-channels.md) (OS Pins) lists them. External
  consumers cannot reference a variant the
  `ci-wheelhouse.yml` enum does not list; `rubin-ubi9` was added to it this
  way, while `cpu-hb` is handled outside it (expanded by `bin/regen-ci.py`
  from `ci-job-definitions.yml`). Strategies proposing new hardware must
  evaluate whether the enum path or the code-generator path applies.
  `rhai-pipeline/` variants must also match its `variant-linter` patterns
  (overlay 0020), and overlay [0030](0030-aipcc-content-channels.md) has the
  cross-component recipe.
- The global changelog in `overrides/settings.yaml` is a high-stakes operation.
  Adding a global entry invalidates every cached wheel for a variant. Any RFE
  proposing a RHEL, CUDA, or ROCm major version bump must account for a full
  rebuild and stakeholder coordination window; the file itself directs authors to
  per-package changelog entries instead.
- `ENABLE_REPEATABLE_BUILD_MODE` locks dependency versions from the prior
  bootstrap. On `main`, `bin/regen-ci.py` sets it only for a collection with
  `enable_repeatable_build_mode: true`, and no collection sets it, so it is
  `false` for every generated job. Release branches enable it when cut:
  `3.6-EA1` (AIPCC-31131) and `3.6-EA2` (AIPCC-32040) set
  `rhai_pipeline.defaults.enable_repeatable_build_mode: true` and carry a
  `regen-ci.py` that reads it. Bootstrap then reuses the latest matching
  release tarball's `graph.json`, so adding or updating a package on a release
  branch needs an exact version pin; fromager will not re-resolve the
  dependency graph from scratch.
- `SECURITY_CONSTRAINTS_URL` provides a zero-day response path for CVEs without
  a builder release cycle. RFEs proposing security-sensitive package changes
  should evaluate whether this mechanism is faster than a full builder update.
- The build-time wheel cache depends on `PULP_CACHE`. When it is `true` (the
  `_default` for `rhai-pipeline/`), jobs read the channel's Pulp `-test`
  index as their cache and upload there. When it is `false` (the default for
  builder collections since AIPCC-32847, and the private `rhaiis` Gaudi,
  Neuron and TPU variants), jobs use a GitLab PyPI project at
  `WHEEL_SERVER_PROJECT_PATH` (prefix `redhat/rhel-ai/rhai/indexes` for
  `rhai-pipeline/`, e.g. `rhaiis-3.6/gaudi-ubi9-x86_64`;
  `redhat/rhel-ai/core/wheels` for builder collections). The
  `upload_after_build_wheel.py` clean-replace pattern applies only to the
  GitLab path, so any proposal to change the cache location must account for
  it and for downstream caches that depend on stable project paths. The
  customer-facing index is Pulp, published by `rhai-pipeline/`. The
  `PULP_CACHE` input description in `ci-wheelhouse.yml` still says "Builder
  collections only", but only `rhai-pipeline/` jobs set it to `true`:
  strategies that reference Pulp publishing for builder collections must
  account for builder wheels staying in GitLab projects, and strategies for
  `rhai-pipeline/` must account for channel `-test` indexes receiving cache
  uploads.

### ROCm Work Breakdown Patterns

When a strategy involves ROCm-related changes, the builder-side work reliably
decomposes into these epics:

- **Sync Pulp mirrors to new ROCm GA RPMs** (amdgpu driver repo, ROCm SDK repo,
  MIGraphX frameworks repo) — only required when the ROCm SDK version itself
  changes, not for package-level updates.
- **Rebuild builder stack against new ROCm RPMs** — update Containerfile parts,
  build-args conf (`ROCM_VERSION`, `ROCM_GPUS`, AOTriton commit hashes, FlyDSL
  commit). Adding a new CDNA generation (as gfx950 was added for MI350/355)
  also requires updating `FLASH_ATTENTION_GPU_ARCHS` and `ROCM_GPUS`.
- **Update torch for the new ROCm version**: update the builder
  `torch-X.Y.Z/<rocm variant>/` collection each ROCm channel reads its torch
  pin from (a new ROCm torch version needs a new collection directory first).
- **Update vLLM for the new ROCm version** — vllm.py plugin changes, AOTriton
  version alignment.
- **Per-package ROCm-specific updates** — tensorflow-rocm, amd-quark, amd-aiter,
  flash-attn, and any new AMD ecosystem packages in consumer pipeline collections.
- **AE/QE test plan for the ROCm variant** — build green, wheels published,
  customer-facing index validated.

Strategies referencing ROCm upgrades should structure their Technical Approach
around these epics rather than describing the work as prose.

## Context

This overlay was created to capture the state of the wheels builder at the
3.6-EA1 release boundary and is maintained through the 3.6 cycle. The builder is
an internal platform dependency of both `rhai-pipeline/` and `rhaiis/pipeline`;
its version and capabilities constrain what both can do. RFEs that propose changes
to the build environment, new accelerator support, or changes to the wheel
publishing contract need to evaluate feasibility against the builder's current
architecture. This overlay is updated by running the `update-fondue-overlays`
skill. Last updated 2026-10-07 (Fondue `main` at `d57f272`).
