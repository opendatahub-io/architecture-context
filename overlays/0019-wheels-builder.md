---
id: "0019"
title: AIPCC Wheels Builder
status: active
created: 2026-07-15
affects:
  - platform
release:
  - "3.6"
provenance:
  - https://gitlab.com/redhat/rhel-ai/wheels/fondue/-/tree/main/builder
  - https://gitlab.com/redhat/rhel-ai/wheels/fondue/-/tree/main/images/builder
author: Lance Barto
superseded_by: null
---

## Fact

The AIPCC wheels builder (`redhat/rhel-ai/wheels/fondue`) is the central build
platform for all Python wheels in the RHAI/RHAIIS ecosystem. It has two tightly
coupled roles:

**API Provider**: The `builder/pipeline-api/` directory is a GitLab CI include
library. Consumer repos (`rhai-pipeline`, `rhaiis/pipeline`) pin to a builder
release tag and include these YAML files to get fully-defined build pipelines
without repeating build logic.

**Build Factory**: Owns the per-variant builder container images, the package
plugin system (181 plugins), and all build overrides and patches. Internal test
collections are maintained in the separate `wheels-test` repository; the
collections in `builder/collections/` are build-verification sets for the
builder's own CI.

### Release State (PRODUCT_VERSION 0.0-el9.8)

The builder uses a product version scheme defined in `builder/product-version.yml`
(`PRODUCT_VERSION: "0.0-el9.8"`). The format encodes the RHEL/UBI base image
generation: `0.0` for RHEL 9.4, `0.0-el9.6` for RHEL 9.6, `0.0-el9.8` for RHEL 9.8.

Image tagging uses a separate variable, `BUILDER_PRODUCT_VERSION: "0.0-el9.8"`,
defined in `.gitlab-ci.yml` and consumed by `builder-image-version.yml`. This
decoupling lets consumer repos set their own `PRODUCT_VERSION` for wheel index
paths without affecting image tags.

- **MR pipeline image tag**: `ci-${BUILDER_PRODUCT_VERSION}-${CI_MERGE_REQUEST_IID}`
  (e.g., `ci-0.0-el9.8-123`)
- **Post-merge pipeline image tag**: `ci-${BUILDER_PRODUCT_VERSION}-` (MR IID is empty)
- **Release pipeline image tag**: the git tag directly (e.g., `v46.0.0`)

Release tags are cut from `releases/builder-release.yaml` (field: `version:`). The
latest release tag is `v46.0.0`. The RHEL AI repo version is pinned at `3.6` in
`images/builder/build-args/rhelai.conf`.

### Builder Images

One container image is built per variant × architecture combination.

**Common foundation across UBI9 variants** (all variants except `cpu-hb`):

- **Base OS:** RHEL 9.8 (`registry.access.redhat.com/ubi9/ubi:9.8-1785906690`)
- **Python:** 3.12
- **GCC toolset:** 14 (`/opt/rh/gcc-toolset-14/root`, set as default via `ENV PATH`
  in `containerfiles/header-ubi9`, AIPCC-10154)
- **Registry:** `registry.gitlab.com/redhat/rhel-ai/wheels/fondue/builder-{VARIANT}-{ARCH}:{TAG}`

**`cpu-hb` exception:** `cpu-hb` is a Hummingbird FIPS variant built on a non-UBI9
base image (`registry.access.redhat.com/hi/python:3.12-fips-builder`, Python 3.12
baked in). It uses the same registry path structure (`wheels/fondue/builder-cpu-hb-x86_64`)
and the same `builder/pipeline-api/ci-wheelhouse.yml` template as other builder
variants, but targets x86_64 only. It is the first variant to build on a non-UBI9
base (the later `--build-arg-file cpu-hb.conf` overrides the UBI9 `BASE_IMAGE`).

Containerfiles are assembled from parts via `make regen`:
`containerfiles/header-ubi9` + `containerfiles/{variant}-ubi9` +
`containerfiles/llvm-triton-{variant}-ubi9` + `containerfiles/footer-ubi9`.
LLVM and Triton commit hashes are pinned in `build-args/common.conf`:

| Triton version | LLVM commit |
|---|---|
| 3.5.0 | `7d5de303` |
| 3.6.0 | `f6ded0be` |
| 3.7.0 | `ac5dc54d` |
| 3.7.1 | `1f126a6d` |
| 3.8.0 | `5f07f818` |
| 3.8.0+rhaiv.1 | `46111560` |

**Variant × Architecture Matrix:**

The image build matrix is authoritatively defined by the `VARIANT` × `ARCH`
options in `images/builder/gitlab-ci/images.yml` (10 `VARIANT` options:
`cpu-ubi9`, `cpu-hb`, `cuda12.9-ubi9`, `cuda13.0-ubi9`, `rubin-ubi9`,
`gaudi-ubi9`, `neuron-ubi9`, `rocm7.14-ubi9`, `spyre-ubi9`, `tpu-ubi9`). The
`cpu-torch-day0-ubi9` variant has its own Containerfile and build-args but is
instantiated only through the internal code generator in `ci-job-definitions.yml`,
not via the `images.yml` build matrix. Not all defined images are necessarily
consumed by downstream pipelines; cross-reference the `rhai-pipeline` and
`rhaiis/pipeline` variant matrices for currently active variants.

| Variant | Architectures | Hardware |
|---|---|---|
| `cpu-ubi9` | aarch64, ppc64le, s390x, x86_64 | Generic CPU |
| `cpu-hb` | x86_64 | Hummingbird FIPS CPU (non-UBI9 base: `registry.access.redhat.com/hi/python:3.12-fips-builder`) |
| `cpu-torch-day0-ubi9` | aarch64, ppc64le, s390x, x86_64 | CPU day-0 Torch builds (code-generator only) |
| `cuda12.9-ubi9` | aarch64, x86_64 | NVIDIA CUDA 12.9.1 (sm 7.5–12.0+PTX) |
| `cuda13.0-ubi9` | aarch64, x86_64 | NVIDIA CUDA 13.0.2 (sm 7.5–12.1+PTX; drops pre-7.5) |
| `rubin-ubi9` | aarch64, x86_64 | NVIDIA Rubin CUDA 13.4.0 DP / R616 driver (sm 10.7a+PTX only) |
| `gaudi-ubi9` | x86_64 | Intel Gaudi 1.24.1 (rev 482) |
| `neuron-ubi9` | x86_64 | AWS Trainium/Inferentia (Neuron SDK via RPMs, Python 3.12) |
| `rocm7.14-ubi9` | x86_64 | AMD ROCm 7.14.0 (gfx90a, gfx942, gfx950) |
| `spyre-ubi9` | ppc64le, s390x, x86_64 | IBM Spyre |
| `tpu-ubi9` | x86_64 | Google Cloud TPU (Torch/XLA) |

CUDA arch lists (`build-args/cuda*.conf`, `rubin-ubi9.conf`):
- CUDA 12.9.1: `TORCH_CUDA_ARCH_LIST=7.5 8.0 8.6 8.7 8.9 9.0a 10.0 10.0a 12.0+PTX`
- CUDA 13.0.2: `TORCH_CUDA_ARCH_LIST=7.5 8.0 8.6 8.7 8.9 9.0a 10.0 10.0a 12.0 12.1+PTX`
  (drops compute capability < 7.5: Maxwell/Pascal/Volta)
- Rubin (CUDA 13.4.0 DP): `TORCH_CUDA_ARCH_LIST=10.7a+PTX` (Rubin R100 / sm_107a only)

**ROCm 7.14 GPU targets** (`build-args/rocm7.14-ubi9.conf`): gfx90a (MI200 CDNA2),
gfx942 (MI300 CDNA3), gfx950 (MI350/MI355 CDNA4). `ROCM_VERSION=7.14.0`,
`ROCM_HOME=/opt/rocm/core` (kpack multi-arch, ROCm installs under
`/opt/rocm/core-7.14/`). HIPFLAGS include `--offload-compress`;
`FLASH_ATTENTION_GPU_ARCHS=gfx90a;gfx942;gfx950`.

AOTriton LLVM commit pins in `build-args/rocm7.14-ubi9.conf`:
- AOTriton 0.9b0: `86b69c31`
- AOTriton 0.10b0: `3c709802`
- AOTriton 0.11b0: `57088512`
- AOTriton 0.12b0: `7f77ca0d`
- FlyDSL: `7f77ca0d`

### Pipeline-API Contract

Consumer repos include `builder/pipeline-api/ci-wheelhouse.yml` once per
(COLLECTION × VARIANT × ARCH) combination. The `VARIANT` input enum in this API
contract has **9 options** (`cpu-ubi9`, `cuda12.9-ubi9`, `cuda13.0-ubi9`,
`rubin-ubi9`, `gaudi-ubi9`, `neuron-ubi9`, `rocm7.14-ubi9`, `spyre-ubi9`,
`tpu-ubi9`). `cpu-hb` and `cpu-torch-day0-ubi9` are **not** in this enum:
`cpu-hb` uses a separate non-UBI9 base image and `cpu-torch-day0-ubi9` is a
torch-day0 variant; both are driven through the internal code generator
(`ci-job-definitions.yml`) using the same `ci-wheelhouse.yml` template rather
than through the public `VARIANT` input.

All accepted inputs:

| Input | Type | Default | Description |
|---|---|---|---|
| `JOB_PREFIX` | string | `""` | Prefix added to all generated job names |
| `COLLECTION` | string | (required) | Collection name (e.g., `rhai`, `rhaiis`) |
| `COLLECTION_SLUG` | string | (required) | Filesystem/URL-safe form of COLLECTION with `/` → `-` (e.g., `vllm-deps/torch-2.11` → `vllm-deps-torch-2.11`). Used for release tarball names and index paths |
| `VARIANT` | enum | (required) | Accelerator variant; one of the 9 defined options |
| `ENABLE_REPEATABLE_BUILD_MODE` | boolean | `false` | Lock dependency graph from prior bootstrap |
| `ENABLE_MULTI_VERSION_BOOTSTRAP` | boolean | `false` | Allow bootstrapping multiple package versions simultaneously |
| `MAX_RELEASE_AGE` | string | `""` | Max release age in days (required with multi-version bootstrap) |
| `BOOTSTRAP_MODE` | enum | `sdist-only` | Bootstrap strategy: `sdist-only`, `full`, `full-parallel` |
| `BUILD_MODE` | enum | `serial` | Build execution: `parallel` (graph file) or `serial` (build order) |
| `ARCH` | enum | `x86_64` | CPU architecture: aarch64, ppc64le, s390x, x86_64 |
| `BUILD_ON_ALL_PUSHES` | boolean | `false` | Trigger even without collection file changes |
| `ENABLE_NIGHTLY_BUILDS` | boolean | `false` | Enable nightly scheduled builds |
| `ENABLE_TEST_JOBS` | boolean | `false` | Run MR-level test bootstrap jobs |
| `ENABLE_JOB` | boolean | `true` | Master switch to disable all jobs in this instantiation |
| `RETRY` | number | `0` | Job retry count (0, 1, or 2) |
| `ALLOW_FAILURE` | boolean | `false` | Allow job failure without blocking the pipeline |
| `COLLECTIONS_DIR` | string | `builder/collections` | Path to collections dir, relative to repo root |
| `BUILDER_DIR` | string | `builder` | Path to builder dir containing pipeline-api/ and scripts |
| `PRODUCT_VERSION` | string | `$PRODUCT_VERSION` | Product version for wheel index paths and release naming |
| `WHEEL_SERVER_PROJECT_PREFIX` | string | `$WHEEL_SERVER_PROJECT_PREFIX` | GitLab group prefix for wheel index projects |
| `RELEASE_TAG_PREFIX` | string | `""` | Prefix for release version tags (e.g. `builder-`, `rhai-`). Namespaces wheelserver tags in the monorepo |
| `PRODUCT_VERSION_FILE` | string | `product-version.yml` | Path to product version YAML, relative to repo root. Used in changes: trigger rules |
| `PULP_CACHE` | string | `""` | Set to `true` to use the Pulp wheel cache and upload to Pulp instead of GitLab (builder collections only) |

`EPHEMERAL_COLLECTION` is a non-spec environment variable (not in `spec.inputs:`)
that the `before_script` reads to synthesize a collection directory from env vars
(`REQUIREMENTS_TXT`, `CONSTRAINTS_TXT`, `CONSTRAINTS_RULES_TXT`). Consumer repos
that need it set it as a CI variable, not as an `inputs:` value.

**Jobs defined per instantiation** (four jobs, three stages):

1. `{COLLECTION}-{VARIANT}-{ARCH}-bootstrap-and-onboard` (stage `bootstrap`) —
   fromager dependency resolution; uploads patched sdists to the sdist server
2. `{COLLECTION}-{VARIANT}-{ARCH}-build-wheels` (stage `build`) — compile wheels
   in topological order inside the builder container
3. `{COLLECTION}-{VARIANT}-{ARCH}-release-tarball` (stage `release`) — package
   build artifacts into GitLab Generic Package Registry
4. `{COLLECTION}-{VARIANT}-{ARCH}-publish-wheels` (stage `release`) — create
   GitLab Release (gated on `PUBLISH_WHEEL_RELEASES`)

**Trigger guard:** All API jobs check `$CI_PROJECT_ROOT_NAMESPACE == "redhat"` —
they never fire outside the Red Hat namespace. (The image build jobs in
`images.yml` use the tighter `$CI_PROJECT_NAMESPACE == "redhat/rhel-ai/wheels"`.)

**Runner tags:** Bootstrap and build jobs use `aipcc-large-{ARCH}` (large runners,
one per architecture). Release/publish jobs use `aipcc`/`aipcc-small-x86_64`. Jobs
run Podman-in-Podman inside `registry.gitlab.com/redhat/rhel-ai/wheels/fondue/podman-stable:v5.8.2`.

### Build Toolchain

- **fromager**: Core build orchestration. `FROMAGER_NETWORK_ISOLATION=1` set in
  every builder Containerfile (no outbound internet during builds; all sources
  pre-fetched to sdist server). `FROMAGER_MIN_RELEASE_AGE=3` (CI variable in
  `.gitlab-ci.yml`) blocks packages released fewer than 3 days ago (supply-chain
  cooldown; per-package bypass via `min_release_age: 0` in package settings).
- **nginx local PyPI server**: Started on `localhost:8080` during build jobs
  (`pipeline-api/nginx_server.sh`); serves already-built wheels so later packages
  in the dependency graph can consume them immediately.
- **Podman-in-Podman (PinP)**: Build jobs run inside `podman-stable` and execute
  the builder image via `podman run`. Avoids Docker-in-Docker privileged mode.
  Storage reset pattern (`rm -rf /var/lib/containers/storage/*`) handles
  pre-existing runner storage conflicts.
- **`SECURITY_CONSTRAINTS_URL`**: External constraints file applied at bootstrap
  and build time (`build_wheels.sh`, `bootstrap.sh`). Allows blocking vulnerable
  package versions without a builder release cycle.

### Package Plugin System

181 Python package plugins registered as `fromager.project_overrides` entry
points in `builder/pyproject.toml`. Hook points: `get_resolver_provider`,
`extra_environ`, `extra_cmake_args`, `pre_build`, `post_build`, `post_bootstrap`,
`prebuilt_wheel`.

**Notable plugins:**

- **`package_plugins/hooks/upload_after_build_wheel.py`** (global post_build,
  registered under `[project.entry-points."fromager.hooks"]`): Validates
  artifact filenames; deletes the prior version from the GitLab PyPI index then
  uploads the new sdist + wheel. This clean-replace pattern ensures the index
  never contains stale builds.
- **`vllm.py`** (most complex): Uses midstream GitLab mirrors; injects CUTLASS,
  Triton, OneDNN, ARM Compute Library as submodules. Separate resolver path per
  variant.
- **`torch.py`**: For CUDA variants, fetches pre-built wheels from
  variant-specific GitLab projects (`_CUDA_PREBUILT_PROJECT_IDS`). Standard
  resolution for non-CUDA.
- **Simple plugins** (the bulk of the 181): Most exist solely to cap the
  `setuptools` version (AIPCC-15912). They register but delegate all behavior
  to defaults.

**Spyre-specific pre-built packages** (sourced from a private Pulp index):

The builder settings below define the *sourcing mechanism* only. The pinned
version is declared in the consumer pipeline requirements.txt files (rhai and
rhaiis pipelines), not here. Version authority lives in the consumer pipelines
and must align with `SPYRE_VERSION` in the base image build args.

- **`torch_sendnn`** (`pre_built: true`): IBM-distributed wheel mirrored by
  AIPCC at `https://private.console.redhat.com/api/pulp-content/rhai/spyre-pypi/simple/`.
  Latest changelog entry: `1.1.1` (2026-02-19). Not compiled from source.
- **`torch_nnpa`** (`pre_built: true`): IBM-distributed s390x wheel (Z only),
  also mirrored from the same private Spyre PyPI index. Latest changelog entry:
  `1.5.0` (2026-07-14). Not compiled from source.
- **`sendnn_inference`**: Compiled from source; replaces `vllm-spyre`
  (AIPCC-14693). Requires a `setuptools` build override.
- **`ibm_fms`**: Built from source (pre-built variant removed) from the GitLab
  mirror at
  `gitlab.com/redhat/rhel-ai/core/mirrors/github/foundation-model-stack/foundation-model-stack`.

### Internal Collections

The builder repo contains collection definitions used by its own CI pipeline.
Internal test collections are primarily maintained in the `wheels-test`
repository; the collections below are the builder's own build-verification sets:

| Collection | Variants | Purpose |
|---|---|---|
| `api-test/cpu-ubi9` | cpu-ubi9 | Pipeline API plumbing test |
| `non-accelerated/cpu-ubi9` | cpu-ubi9 | CPU-only packages |
| `accelerated/` | (placeholder) | Directory created, README only; no variant subdirs yet |
| `torch-2.9.1/neuron-ubi9` | neuron-ubi9 | Torch 2.9.1 for AWS Neuron |
| `torch-2.10.0/tpu-ubi9` | tpu-ubi9 | Torch 2.10.0 for Google Cloud TPU |
| `torch-2.11.0/{7 variants}` | cpu-ubi9, cuda12.9-ubi9, cuda13.0-ubi9, gaudi-ubi9, rocm7.14-ubi9, rubin-ubi9, spyre-ubi9 | torch 2.11.0 + vLLM, ONNX Runtime, FlashInfer, etc. |
| `torch-2.12.0/rocm7.14-ubi9` | rocm7.14-ubi9 | Torch 2.12.0 for ROCm 7.14 |
| `torch-2.13.0/{3 variants}` | cpu-ubi9, cuda12.9-ubi9, cuda13.0-ubi9 | Torch 2.13.0 (primary CPU/CUDA collection after the torch 2.11→2.13 CPU migration, AIPCC-31285) |
| `torch-2.14.0/{2 variants}` | cpu-torch-day0-ubi9, cuda13.0-ubi9 | Torch 2.14.0 day-0 builds |
| `torchless/{3 variants}` | cpu-hb, cpu-ubi9, rocm7.14-ubi9 | Non-torch packages for cpu-hb, cpu, and ROCm |

`collections/global-constraints.txt` carries cross-collection version
constraints with AIPCC/RHAI ticket references for every entry.
`collections/global-requirements.txt` adds `pip` and `setuptools` to every
build. (Note: the former `aiu-monitor<0.0.0` / `ibm-aiu-monitor<0.0.0`
exclusions no longer live in this file — aiu-monitor is now handled entirely in
the base image RPM manifests under `images/base/context/spyre/`.)

### Global Configuration

`overrides/settings.yaml` carries:
- Global SBOM metadata (`supplier: "Organization: Red Hat"`, namespace, creators,
  `repository_url`)
- A **changelog** with exactly one entry per base variant (cpu-ubi9, cpu-hb,
  cuda-ubi9, gaudi-ubi9, neuron-ubi9, rocm-ubi9, rubin-ubi9, spyre-ubi9,
  tpu-ubi9) so all wheels start with build tag `1`. The file explicitly warns
  against adding *global* changelog entries: a new global entry invalidates all
  cached wheels for a variant, forcing a full rebuild from scratch. Per-package
  changelog entries in the individual settings files are the intended mechanism.
  Most variants last rebuilt 2026-08-10; neuron-ubi9 rebuilt 2026-09-04.

`overrides/settings/` (288 files): per-package YAML fromager settings.
`overrides/patches/` (91 directories): per-package-version patch sets applied
during `pre_build` hooks.

## Impact on Strategies

- A single `BUILDER_IMAGE_VERSION` value in a consumer repo pins the compiler
  toolchain, build scripts, plugin set, and container images simultaneously.
  Updating the builder is a one-value change but may change the behavior of any
  package plugin. Consumer repos may be pinned to a version that lags the
  builder's latest tag (`v46.0.0` as of this refresh).
- Adding a new accelerator variant requires: new Containerfile parts, new
  build-args conf, new collection entries, and new job instantiations in all
  consumer pipelines. The `VARIANT` input's `options:` enum list in
  `ci-wheelhouse.yml` (currently 9 options) must be updated in the builder API
  first — consumers cannot reference a variant the builder API does not
  recognize. `rubin-ubi9` was added to the enum this way. `cpu-hb` and
  `cpu-torch-day0-ubi9` are handled outside the public enum (instantiated by the
  internal code generator in `ci-job-definitions.yml`); strategies proposing new
  hardware must evaluate whether the enum path or the code-generator path applies.
- The global changelog in `overrides/settings.yaml` is a high-stakes operation.
  Adding a global entry invalidates every cached wheel for a variant. Any RFE
  proposing a RHEL, CUDA, or ROCm major version bump must account for a full
  rebuild and stakeholder coordination window; the file itself directs authors to
  per-package changelog entries instead.
- `ENABLE_REPEATABLE_BUILD_MODE` locks dependency versions from the prior
  bootstrap. On a release branch, adding or updating a package requires explicit
  pinning — fromager will not re-resolve the dependency graph from scratch.
- `SECURITY_CONSTRAINTS_URL` provides a zero-day response path for CVEs without
  a builder release cycle. RFEs proposing security-sensitive package changes
  should evaluate whether this mechanism is faster than a full builder update.
- The wheel index is GitLab PyPI registry (one project per collection/variant/arch
  in `redhat/rhel-ai/wheels/indexes/`). Any proposal to change the index location
  or layout must account for the `upload_after_build_wheel.py` clean-replace
  pattern and the downstream caches that depend on stable project paths.
- The `PULP_CACHE` input enables an alternate Pulp-backed wheel cache and upload
  path; strategies that reference Pulp publishing for builder collections must
  account for this flag being set.

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
- **Update torch for the new ROCm version** — update the `torch-{version}/rocm*`
  collection entry in the builder's internal collections.
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
an internal platform dependency of both `rhai-pipeline` and `rhaiis/pipeline`;
its version and capabilities constrain what both can do. RFEs that propose changes
to the build environment, new accelerator support, or changes to the wheel
publishing contract need to evaluate feasibility against the builder's current
architecture. This overlay is updated by running the `update-fondue-overlays`
skill. Last updated 2026-09-23.
