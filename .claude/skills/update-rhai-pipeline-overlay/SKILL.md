---
name: update-rhai-pipeline-overlay
description: Use when the rhai/pipeline repository has changed and the overlay file overlays/0020-rhai-pipeline.md needs to be refreshed with current product version, published variants, collection matrix, or Pulp publishing details.
user-invocable: true
allowed-tools: Read, Write, Bash(bash ${CLAUDE_SKILL_DIR}/scripts/fetch-repo.sh), Glob, Grep
---

# Update RHAI Pipeline Overlay

Refresh `overlays/0020-rhai-pipeline.md` with current information from the
`rhai/pipeline` repository.

## Overview

The overlay documents the RHAI wheel package index management system: which
variants are published, what collections exist, and how wheels flow from CI
builds to the customer-facing Pulp index. When the repo changes — new variant
in `publish_config.yml`, new collection, updated product version, or changes to
the Pulp publishing workflow — run this skill to update the overlay.

## Instructions

### Step 1: Locate or Clone the Repository

Run the fetch script from the root of the architecture-context repository:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/fetch-repo.sh
```

The script checks for a local fondue checkout at `../fondue/rhai-pipeline`. If
found, it prints that path and exits. Otherwise it clones or updates
`./tmp/fondue` from `https://gitlab.com/redhat/rhel-ai/wheels/fondue.git` and
prints `./tmp/fondue/rhai-pipeline`.

Use the printed path as `{REPO}` in all subsequent steps.

### Step 2: Read the Key Files

Read the following files to extract current state. All paths are relative to
`{REPO}`:

**Version information:**
- `product-version.yml` → `PRODUCT_VERSION` variable
- `builder-image-version.yml` → `BUILDER_IMAGE_VERSION` variable
- `supported_versions.yml` → full version history and per-version variant lists

**Published variant configuration:**
- `publish_config.yml` → per-variant `VARIANT`, `WHEEL_REPO_VERSION`, and
  `SDIST_REPO_VERSION` entries (these are the variants currently wired for
  production publication)

**Build matrix:**
- `bin/regen-gitlab-jobs.py` → the `COLLECTIONS` dict (collection name →
  list of variant name strings), the `VARIANTS` dict (variant name → list of
  arches), and the `OMIT_JOBS` set (explicitly excluded `(collection, variant,
  arch)` tuples). This is the authoritative source for the CI matrix. Note:
  `OMIT_JOBS` is checked against collection names only; entries with non-collection
  strings (e.g. package names) are dead code.

**Collection contents (spot-check):**
- For each collection subdirectory under `collections/`, read the directory
  listing to confirm which variant subdirs exist.
- For the `rhai` collection on `cpu-ubi9`, read
  `collections/rhai/cpu-ubi9/requirements/` directory listing to see the
  team-owned requirement files.
- For `onboarding`, `rhai-innovation`, `rhaiis`, `model-opt`, `ogx`,
  `aiu-monitor-deps` -- read the `requirements.txt` or directory listing for at
  least one representative variant.

**Key top-level package versions per variant:**

To identify release-defining packages, use these heuristics rather than a
hardcoded list:

- Read `collections/{collection}/{variant}/constraints-rules.txt` for each
  published variant in the `rhai` collection. Lines of the form `torch-X.Y.Z *`
  pin the torch version. Packages that appear in constraints-rules are
  release-defining because they anchor the dependency graph for their variant.
- Read `collections/rhaiis/{VARIANT}/requirements.txt` for each published
  variant. Packages with local version tags (e.g. `+rhaiv.N`, `+rhai19`,
  `+rhaiv.1.spyre`) are maintained as internal forks and are release-defining.
  Note the fork origin: `+rhai` tags indicate the NeuralMagic enterprise fork,
  plain upstream versions indicate `vllm-project/vllm`, and `.spyre` suffixes
  indicate IBM forks.
- Packages that have different versions across variants (visible by comparing
  requirements.txt files) are also release-defining because they drive
  per-variant scope decisions.
- Include these packages and their versions in the Published Variants table so
  RFE creators can identify major upgrades at a glance.

  **For `spyre-ubi9` specifically**, when reading
  `collections/rhaiis/spyre-ubi9/requirements.txt`, capture:
  - `vllm` exact version string (note the local version tag and fork origin)
  - `sendnn-inference` pinned version; check whether it differs by arch
  - `torch-sendnn` pinned version — pre-built IBM wheel, not compiled by builder
  - `torch-nnpa` pinned version — pre-built IBM wheel, s390x only
  - `ibm-fms` pinned version (also check `constraints.txt`)
  - `spyremetrics` and `ibm-aiu-smi` — new wheels; capture version and arch
    restrictions if present
  - **Do not** list `aiu-monitor` / `ibm-aiu-monitor` as wheel collection
    packages — both are blocked via `global-constraints.txt`
    (`aiu-monitor<0.0.0`, `ibm-aiu-monitor<0.0.0`) and live in the base image

### Step 3: Read the Current Overlay

Read `overlays/0020-rhai-pipeline.md` to understand the existing structure.
Identify the human-authored sections (Impact on Strategies, Context) that must
be preserved and updated, not replaced wholesale.

### Step 4: Update the Overlay

Rewrite `overlays/0020-rhai-pipeline.md` using the following approach:

**Preserve the YAML front matter** (`id`, `title`, `status`, `created`,
`affects`, `provenance`, `author`, `superseded_by`). Update `release` only if
the product version indicates a new RHOAI release.

**Fact section** — Replace with fresh content derived from the files above.
This section must cover:

- **Header** — Purpose of the repo (index management, not compilation);
  product name, product version, builder version, Pulp domain, public base URL
- **Published Variants table** -- One row per variant in `publish_config.yml`;
  columns: variant, architectures, key release-defining package versions (found
  using the heuristics from Step 2), public index path.
- **Collections and Variant Coverage table** — One row per collection with
  purpose description and which variants it covers; derived from `regen-gitlab-jobs.py`
- **OMIT_JOBS** — Explicit exclusions from the matrix with their reasons
- **Test jobs** — Which collections have `ENABLE_TEST_JOBS: true`
- **The `rhai` Collection** — Team ownership structure; list notable team files
  and their contents
- **Onboarding Pipeline** — How new packages enter (onboarding → graduation via
  weekly bot → `rhai` collection)
- **Pipeline Flow** — Stage list; trigger types; key checks-stage gates
  (variant-linter, verify-publish-config, validate-package-deletion-manifests)
- **Pulp Publishing Mechanics** — Two-stage workflow (upload then publish);
  repository naming convention; authentication method; `-test` distribution
  auto-increment
- **Package Deletion System** — Manifest-driven, enforced at upload time,
  idempotent
- **Version Branching** — `copy_wheels.py` for EA→GA promotion

**Impact on Strategies section** — Update to reflect current state. Must include:

- A bullet establishing this repo as the authoritative Pulp publish gate
- A bullet on the steps required to add a new collection or variant
- A bullet on `ENABLE_REPEATABLE_BUILD_MODE` implications for release branches
- A bullet on how many CUDA versions are maintained and the cost of adding one
- A bullet on ROCm version state (which is built vs which is published)
- A bullet on Spyre's IBM-proprietary wheel stack: the vLLM IBM fork (`.spyre`
  suffix), sendnn-inference (IBM's inference runtime), torch-sendnn (x86/P,
  pre-built from private index), torch-nnpa (Z only, pre-built from private
  index), ibm-fms (Foundation Model Stack, built from source). Torch version is
  shared with other variants via constraints-rules.txt. aiu-monitor is blocked
  from all wheel collections and lives in the base image instead.
- A bullet on the public URL as a stable contract for air-gapped mirroring
- A bullet on the idempotent deletion system and the onboarding graduation cadence

**ROCm Work Breakdown Patterns** — Include this subsection to guide downstream
strategy generation. When a strategy involves a ROCm variant update in the
pipeline (e.g., new ROCm version or ROCm package changes), the pipeline-side
work decomposes into these epics:
- Update ROCm variant constraints (torch pin, vllm pin, ROCm-specific package
  versions in constraints.txt and constraints-rules.txt)
- Add or update ROCm-specific packages in collections (amd-quark, amd-aiter,
  tensorflow-rocm, flash-attn, and any new AMD ecosystem packages)
- Validate build and publish for the ROCm variant (CI pipeline green, wheels
  uploaded to Pulp, customer-facing index updated)

Strategies referencing ROCm pipeline updates should structure their Technical
Approach around these epics rather than describing the work as prose.

**Context section** — Keep the rationale unchanged. Update the date and version
references to remain accurate.

### Step 5: Write the Updated File

Write the updated content to `overlays/0020-rhai-pipeline.md` using the Write
tool.

### Step 6: Report

Output a brief summary:

```
Updated overlays/0020-rhai-pipeline.md

Changes:
- [product version: old → new]
- [builder version: old → new]
- [any variants added/removed from publish_config.yml]
- [any collections added/removed]
- [any notable changes to the publishing workflow]

Repository used: {REPO} (./tmp/fondue/rhai-pipeline is not tracked by git)
```

## Notes

- **Trust assumption:** The fetch script validates the git remote origin against
  the allowlisted fondue repository. Both the HTTPS form
  (`https://gitlab.com/redhat/rhel-ai/wheels/fondue.git`) and the SSH form
  (`git@gitlab.com:redhat/rhel-ai/wheels/fondue.git`) are accepted, as they
  resolve to the same repository. Do not bypass the fetch script by supplying a
  path directly.
- `tmp/` is in `.gitignore`; the cloned repository is local only
- The script is idempotent: run it again any time the upstream repo changes
- Do not change the overlay `id` (0020) or `author` fields
- Preserve AIPCC ticket references when they are still accurate
- The Pulp version HREFs in `publish_config.yml` are long UUIDs — include only
  the version number portion in the overlay, not the full HREF
- Do not commit any changes to the rhai/pipeline repository or to GitLab
