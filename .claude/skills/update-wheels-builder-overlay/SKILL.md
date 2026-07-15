---
name: update-wheels-builder-overlay
description: Use when the AIPCC wheels builder repository has changed and the overlay file overlays/0019-wheels-builder.md needs to be refreshed with current builder version, variant matrix, pipeline-API contract, or plugin system details.
user-invocable: true
allowed-tools: Read, Write, Bash(bash ${CLAUDE_SKILL_DIR}/scripts/fetch-repo.sh), Glob, Grep
---

# Update Wheels Builder Overlay

Refresh `overlays/0019-wheels-builder.md` with current information from the
wheels builder repository.

## Overview

The overlay documents the builder's role as both a build factory (container
images per variant) and a CI pipeline API provider (`pipeline-api/`). Consumer
repos (`rhai-pipeline`, `rhaiis/pipeline`) pin to a builder release tag. In the
fondue monorepo, builder content is split across two subdirectories:
`builder/` (plugins, overrides, pipeline-api, `release.yaml`) and
`images/builder/` (Containerfiles, build-args, `gitlab-ci/images.yml`). When
the builder changes in a meaningful way — new variant, updated API inputs,
changed base image, plugin count, or release version — run this skill to update
the overlay.

## Instructions

### Step 1: Locate or Clone the Repository

Run the fetch script from the root of the architecture-context repository:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/fetch-repo.sh
```

The script checks for a local fondue checkout at `../fondue`. If the
`builder/` and `images/builder/` subdirectories are present, it prints that
path and exits. Otherwise it clones or updates `./tmp/fondue` from
`https://gitlab.com/redhat/rhel-ai/wheels/fondue.git` and prints that path.

Use the printed path as `{FONDUE}` in all subsequent steps. Builder content
lives under two subdirectories: `{FONDUE}/builder/` and
`{FONDUE}/images/builder/`.

### Step 2: Read the Key Files

**Version and base image** (in `{FONDUE}/builder/`):
- `builder/release.yaml` → current version tag (e.g., `v36.6.0`)

**Container image configuration** (in `{FONDUE}/images/builder/`):
- `images/builder/build-args/common.conf` → base OS image pin, Python version,
  LLVM commit hashes, Triton commit hashes (one hash per Triton release line)
- `images/builder/containerfiles/header-ubi9` → GCC toolset version and root
  path (look for the `ENV PATH=/opt/rh/gcc-toolset-NN/...` line)

**Variant matrix** (in `{FONDUE}/images/builder/`):
- `images/builder/gitlab-ci/images.yml` — which `VARIANT` x `ARCH` image build
  jobs are defined (the authoritative list of what builder produces). Note: not
  all defined images may be actively consumed by downstream pipelines. Add a
  caveat in the overlay directing readers to cross-reference with `rhai-pipeline`
  and `rhaiis/pipeline` for currently active variants.
- `images/builder/build-args/cuda12.9-*.conf`,
  `images/builder/build-args/cuda13.0-*.conf`,
  `images/builder/build-args/cuda13.2-*.conf` → CUDA versions and
  `TORCH_CUDA_ARCH_LIST`
- `images/builder/build-args/rocm7.*.conf` → ROCm versions
- `images/builder/build-args/spyre*.conf`,
  `images/builder/build-args/gaudi*.conf`,
  `images/builder/build-args/tpu*.conf`,
  `images/builder/build-args/neuron*.conf` → other variant specifics

**Pipeline-API contract** (in `{FONDUE}/builder/`):
- `builder/pipeline-api/ci-wheelhouse.yml` → the `inputs:` block at the top of
  the file defines all accepted inputs and their types/defaults. Read at minimum
  the first 120 lines to capture the full inputs block and the job stage names.

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
  version is declared in the consumer pipeline requirements.txt files (rhai and
  rhaiis pipelines), not here. The changelog in this YAML is historical only.
  The version should match `SPYRE_VERSION` in the base image build args.
- `builder/overrides/settings/torch_nnpa.yaml` → same `pre_built: true` pattern,
  s390x (Z) only. Same distinction applies: sourcing mechanism only; version is
  pinned in the pipeline requirements.
- `builder/overrides/settings/sendnn_inference.yaml` → compiled from source;
  has a build requirement override. Note whether it still replaces `vllm-spyre`.
- `builder/overrides/settings/ibm_fms.yaml` → sourced from the GitLab mirror
  (`foundation-model-stack/foundation-model-stack`). Note the mirror URL.
- `builder/collections/global-constraints.txt` → verify that `aiu-monitor<0.0.0`
  and `ibm-aiu-monitor<0.0.0` are still present (AIPCC-15183). These entries
  prevent aiu-monitor from being pulled into any wheel collection; it is
  installed in the base image instead.

Include the private index URL and the pre-built status of torch-sendnn and
torch-nnpa in the overlay's Package Plugin System section. Explicitly note that
the builder settings define the sourcing mechanism, not the pinned version —
version authority lives in the consumer pipeline requirements.txt files and must
align with `SPYRE_VERSION` in the base image.

### Step 3: Read the Current Overlay

Read `overlays/0019-wheels-builder.md` to understand the existing structure.
Identify the human-authored sections (Impact on Strategies, Context) that must
be preserved and updated, not replaced wholesale.

### Step 4: Update the Overlay

Rewrite `overlays/0019-wheels-builder.md` using the following approach:

**Preserve the YAML front matter** (`id`, `title`, `status`, `created`,
`affects`, `provenance`, `author`, `superseded_by`). Update `release` only if
the builder clearly targets a new RHEL AI release.

**Fact section** — Replace with fresh content derived from the files above.
This section must cover:

- **Purpose** — Brief description of the two roles (API Provider, Build Factory)
- **Release State** — Current version tag from `release.yaml`; how versioning
  works
- **Builder Images** — Common foundation table (base OS, Python, GCC toolset,
  registry path); Variant × Architecture table listing all current variants and
  their supported architectures and hardware
- **Pipeline-API Contract** — Inputs table from `ci-wheelhouse.yml`; the four
  jobs defined per instantiation; trigger guard; runner tags
- **Build Toolchain** — fromager settings (`FROMAGER_NETWORK_ISOLATION`,
  `FROMAGER_MIN_RELEASE_AGE`), nginx local server, PinP, `SECURITY_CONSTRAINTS_URL`
- **Package Plugin System** — Plugin count; key hook points; notable plugins
  (global upload hook, vllm.py, torch.py, simple setuptools-cap plugins)
- **Internal Collections** — Table of collections the builder owns and tests
- **Global Configuration** — `overrides/settings.yaml` changelog significance

**Impact on Strategies section** — Update to reflect current state. Must include:

- A bullet on what a single `BUILDER_IMAGE_VERSION` pin controls and the risk
  of updating it
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

**Context section** — Keep the rationale unchanged. Update the date and version
references to remain accurate.

### Step 5: Write the Updated File

Write the updated content to `overlays/0019-wheels-builder.md` using the Write
tool.

### Step 6: Report

Output a brief summary:

```
Updated overlays/0019-wheels-builder.md

Changes:
- [builder version: old → new]
- [any variants added or removed]
- [any base image changes]
- [any notable API input changes]

Repository used: {FONDUE} (./tmp/fondue is not tracked by git)
```

## Notes

- **Trust assumption:** The fetch script validates the git remote origin against
  the allowlisted fondue repository. Both the HTTPS form
  (`https://gitlab.com/redhat/rhel-ai/wheels/fondue.git`) and the SSH form
  (`git@gitlab.com:redhat/rhel-ai/wheels/fondue.git`) are accepted, as they
  resolve to the same repository. Do not bypass the fetch script by supplying a
  path directly.
- `tmp/` is in `.gitignore`; the cloned repository is local only
- The script is idempotent: run it again any time the upstream fondue repo changes
- Do not change the overlay `id` (0019) or `author` fields
- Preserve AIPCC/INFERENG ticket references when they are still accurate; remove
  them if the underlying issue is resolved
- Do not commit any changes to the builder repository or to GitLab
