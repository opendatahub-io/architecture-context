# Wheels Builder Overlay (0019)

Rules for refreshing `overlays/0019-wheels-builder.md` from the Fondue
monorepo. Paths in this file are relative to `{FONDUE}`.

## Overview

The overlay documents the builder's role as both a build factory (container
images per variant) and a CI pipeline API provider (`pipeline-api/`). Its two
consumers get the builder differently; describe each as "How consumers get the
builder" in the SKILL.md Shared Facts states it. Builder content is split
across `builder/` (plugins, overrides, pipeline-api),
`images/builder/` (Containerfiles, build-args, `gitlab-ci/images.yml`) and
`releases/builder-release.yaml` (release tag).

## Key Files

**Release version:**
- `releases/builder-release.yaml` → the release declared on `main` (e.g.,
  `v46.0.0`); see "Builder release tag" in the SKILL.md Shared Facts

**Container image configuration** (in `{FONDUE}/images/builder/`):
- `images/builder/build-args/common.conf` → base OS image pin, Python version,
  LLVM commit hashes, Triton commit hashes (one hash per Triton release line)
- `images/builder/containerfiles/header-ubi9` → GCC toolset version and root
  path (look for the `ENV PATH=/opt/rh/gcc-toolset-NN/...` line)

**Variant matrix:**
- `ci-job-definitions.yml` → `builder_images.variants`: which `VARIANT` x `ARCH`
  builder images are built (the authoritative list of what builder produces; see
  "Variant × arch matrix" in the SKILL.md Shared Facts).
  `images/builder/gitlab-ci/images.yml` is only the job template. Not all built
  images may be actively consumed by downstream pipelines. Add a caveat in the
  overlay directing readers to cross-reference with `rhai-pipeline/` and
  `rhaiis/pipeline` for currently active variants.
- `images/builder/build-args/cuda*-*.conf` (one per CUDA version) → CUDA
  versions and `TORCH_CUDA_ARCH_LIST`
- `images/builder/build-args/rocm7.*.conf` → ROCm versions
- `images/builder/build-args/spyre*.conf`,
  `images/builder/build-args/gaudi*.conf`,
  `images/builder/build-args/tpu*.conf`,
  `images/builder/build-args/neuron*.conf` → other variant specifics

**Pipeline-API contract** (in `{FONDUE}/builder/`):
- `builder/pipeline-api/ci-wheelhouse.yml` → the `inputs:` block at the top of
  the file defines all accepted inputs and their types/defaults. Read at minimum
  the first 120 lines to capture the full inputs block and the job stage names.
  For the `VARIANT` input specifically: read the enum values directly from the
  file and report the exact count and list of options as they appear — do not
  use a hardcoded count or list. Note explicitly that `cpu-hb` and
  `cpu-torch-day0-ubi9` do NOT appear in this enum; they are handled outside
  the standard VARIANT enum (cpu-hb uses a separate non-UBI9 base image;
  cpu-torch-day0-ubi9 is a torch-day0 variant processed by a different path).

**Plugin system** (in `{FONDUE}/builder/`):
- `builder/pyproject.toml` → count the entries under
  `[project.entry-points."fromager.project_overrides"]` to get the plugin count

**Internal collections** (in `{FONDUE}/builder/`):
- `builder/collections/` directory listing — what collection subdirectories
  exist (e.g., `torch-2.11.0/`, `torch-2.12.0/`, `non-accelerated/`). Note:
  internal test collections are primarily in the separate `wheels-test`
  repository. The collections in the builder directory are build-verification
  sets used by the builder's own CI pipeline.

**Global configuration** (in `{FONDUE}/builder/`):
- `builder/overrides/settings.yaml` → global SBOM metadata and changelog
  entries per base variant

**Spyre-specific builder configuration** (read for every update):

The Spyre variant relies on IBM-proprietary pre-built wheels served from a
private Pulp index. Read the following overrides settings files to capture their
current state:

- `builder/overrides/settings/torch_sendnn.yaml` → `pre_built: true`,
  `wheel_server_url` pointing to the private Spyre PyPI index
  (`https://private.console.redhat.com/api/pulp-content/rhai/spyre-pypi/simple/`).
  This defines the *sourcing mechanism* only — the builder fetches a pre-built
  IBM wheel from the private index rather than compiling from source. The pinned
  version is declared in the consuming `rhai-pipeline/` collection's
  `requirements.txt` (e.g. `collections/rhaiis/spyre-ubi9/`), not here. The
  changelog in this YAML is historical only.
  The version should match the IBM Spyre SDK RPM version pinned in
  `images/base/context/spyre/rpms.in.yaml` (AIPCC-29839; there is no
  `SPYRE_VERSION` build arg).
- `builder/overrides/settings/torch_nnpa.yaml` → same `pre_built: true` pattern,
  s390x (Z) only. Same distinction applies: sourcing mechanism only; version is
  pinned in the pipeline requirements. torch-nnpa has its own version line; do
  not claim it matches the SDK RPM version.
- `builder/overrides/settings/sendnn_inference.yaml` → compiled from source;
  has a build requirement override. Note whether it still replaces `vllm-spyre`.
- `builder/overrides/settings/ibm_fms.yaml` → sourced from the GitLab mirror
  (`foundation-model-stack/foundation-model-stack`). Note the mirror URL.
- `builder/collections/global-constraints.txt` → grep for `aiu-monitor` before
  making any claim about it (see "aiu-monitor" in the SKILL.md Shared Facts).

Include the private index URL and the pre-built status of torch-sendnn and
torch-nnpa in the overlay's Package Plugin System section. Explicitly note that
the builder settings define the sourcing mechanism, not the pinned version —
version authority lives in the consumer pipeline requirements.txt files, and
torch-sendnn's version must align with the Spyre SDK RPM version in the base
image.

## Overlay Content

Update `release` only if the builder clearly targets a new RHEL AI release.

**Fact section** — Replace with fresh content derived from the files above.
This section must cover:

- **Purpose** — Brief description of the two roles (API Provider, Build Factory)
- **Release State** — Release declared in `releases/builder-release.yaml`;
  how versioning works, and how each consumer gets the builder (per the SKILL.md
  Shared Facts)
- **Builder Images** — Common foundation table (base OS, Python, GCC toolset,
  registry path); Variant × Architecture table listing all current variants and
  their supported architectures and hardware
- **Pipeline-API Contract** — Inputs table from `ci-wheelhouse.yml`; the job
  definitions per instantiation (four jobs in three stages plus the
  `ENABLE_TEST_JOBS`-gated `test-...-bootstrap-and-onboard` job, five in all;
  count them from the file); trigger guard; runner tags
- **Build Toolchain** — fromager settings (`FROMAGER_NETWORK_ISOLATION`,
  `FROMAGER_MIN_RELEASE_AGE`), nginx local server, PinP, `SECURITY_CONSTRAINTS_URL`
- **Package Plugin System** — Plugin count; key hook points; notable plugins
  (global upload hook, vllm.py, torch.py, simple setuptools-cap plugins)
- **Internal Collections** — Table of collections the builder owns and tests
- **Global Configuration** — `overrides/settings.yaml` changelog significance

**Impact on Strategies section** — Update to reflect current state. Must include:

- A bullet on what a single `BUILDER_IMAGE_VERSION` pin controls for a pinned
  consumer and the risk of updating it, and how `rhai-pipeline/` differs (per
  the SKILL.md Shared Facts)
- A bullet on what adding a new accelerator variant requires (Containerfile,
  build-args, collections, consumer pipeline changes, API enum update)
- A bullet on the global changelog as a high-stakes operation (rebuild time,
  coordination required)
- A bullet on `ENABLE_REPEATABLE_BUILD_MODE` implications for release branches
- A bullet on `SECURITY_CONSTRAINTS_URL` as a zero-day response path
- A bullet on the wheel index location and the clean-replace upload pattern

**ROCm Work Breakdown Patterns** — Include this subsection to guide downstream
strategy generation. When a strategy involves ROCm-related changes, the
builder-side work reliably decomposes into these epics:
- Sync Pulp mirrors to new ROCm GA RPMs (amdgpu driver repo, ROCm SDK repo,
  MIGraphX frameworks repo) — only when the ROCm SDK version itself changes
- Rebuild builder stack against new ROCm RPMs (update Containerfile parts,
  build-args conf)
- Update torch for the new ROCm version
- Update vllm for the new ROCm version
- Per-package ROCm-specific updates (tensorflow-rocm, amd-quark, amd-aiter,
  flash-attn, and any new AMD ecosystem packages)
- AE/QE test plan for the ROCm variant

Strategies referencing ROCm upgrades should structure their Technical Approach
around these epics rather than describing the work as prose.

## Report Details

- Builder version: old → new
- Variants added or removed
- Base image changes
- Notable API input changes
