---
name: update-rhaiis-pipeline-overlay
description: Use when the rhaiis/pipeline repository has changed and the overlay file overlays/0021-rhaiis-pipeline.md needs to be refreshed with current vLLM versions, variant matrix, or package content details.
user-invocable: true
allowed-tools: Read, Edit, Write, Bash(bash ${CLAUDE_SKILL_DIR}/scripts/fetch-repo.sh), Glob, Grep
---

# Update RHAIIS Pipeline Overlay

Refresh `overlays/0021-rhaiis-pipeline.md` with current information from the
`rhaiis/pipeline` repository.

## Overview

The overlay documents the RHAIIS wheel build specification: which hardware
variants are supported, which vLLM version (and fork) is used per variant, and
what packages each variant builds. When vLLM versions change, new variants are
added, or package content shifts — run this skill to update the overlay.

## Instructions

### Step 1: Locate or Clone the Repository

Run the fetch script from the root of the architecture-context repository:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/fetch-repo.sh
```

The script checks for a local checkout at `../rhaiis/pipeline`. If found, it
prints that path and exits. Otherwise it clones or updates `./tmp/rhaiis-pipeline`
from `https://gitlab.com/redhat/rhel-ai/rhaiis/pipeline.git` and prints that
path.

Use the printed path as `{REPO}` in all subsequent steps.

### Step 2: Read the Key Files

Read the following files to extract current state. All paths are relative to
`{REPO}`:

**Version information:**
- `product-version.yml` → `PRODUCT_VERSION` variable
- `builder-image-version.yml` → `BUILDER_IMAGE_VERSION` variable

**Variant matrix:**
- `.gitlab-ci.yml` → the `include:` blocks list every (COLLECTION × VARIANT ×
  ARCH) combination. Read the full file to extract the complete matrix. Note
  whether `ENABLE_REPEATABLE_BUILD_MODE` is set per variant.

**Per-variant package content:**

For each variant listed in `.gitlab-ci.yml`, read:
- `collections/rhaiis/{VARIANT}/requirements.txt` — direct packages including
  vLLM version, extras, and key functional packages
- `collections/rhaiis/{VARIANT}/constraints.txt` — hard-pinned versions and
  security fixes
- `collections/rhaiis/{VARIANT}/constraints-rules.txt` — builder constraints API
  delegation rules (which torch version is pulled)

For model-opt:
- `collections/model-opt/cuda13.0-ubi9/requirements.txt`
- `collections/model-opt/cuda13.0-ubi9/constraints.txt`

**Spyre variant — additional detail for the general per-variant step above:**

When processing `spyre-ubi9`, the general read of requirements.txt and
constraints.txt already covers it. Additionally extract:

- `vllm` exact version string — note the local version tag and fork origin
- `sendnn-inference` — IBM's inference runtime; check whether versions differ by
  arch (ppc64le may be specified separately from s390x/x86_64)
- `torch-sendnn` — pre-built IBM wheel (not compiled by builder); note the
  pinned version
- `torch-nnpa` — pre-built IBM wheel, s390x only; note version and confirm the
  `platform_machine == 's390x'` guard is present
- `ibm-fms` — note if both a pinned version and an unpinned `ibm-fms` appear
  (dual-build pattern for latest + stable)
- `fms-model-optimizer` — check if present directly or only referenced in
  comments (torchao constraint is driven by `fms-model-optimizer[fp8]`)
- `spyremetrics` — new wheel; if present, capture version and arch restrictions
- `ibm-aiu-smi` — new wheel; if present, capture version and arch restrictions

From `constraints.txt`, confirm:
- `ibm-fms` pin
- `torchao` pin (driven by `fms-model-optimizer[fp8]` or `[fp8-infer]`)
- Any per-arch guards on security constraints

**Update automation:**
- `renovate.json` → which variants are covered by the custom regex managers
  and per-branch `allowedVersions` rules. For Gaudi specifically: Renovate
  has a custom regex manager for gaudi that only matches versions with a `+rhai`
  local version tag (e.g. `+rhaiv.N.gaudi`). If gaudi uses upstream vLLM without
  that tag (e.g. `vllm==0.21.0`), the regex will not match and Renovate will not
  propose updates — this is effective exclusion through format mismatch, not
  through an explicit `"enabled": false` packageRule. Check whether the current
  gaudi `requirements.txt` has or lacks a `+rhai` tag, and describe the update
  situation accurately.

### Step 3: Read the Current Overlay

Read `overlays/0021-rhaiis-pipeline.md` to understand the existing structure.
Identify the human-authored sections (Impact on Strategies, Context) that must
be preserved and updated, not replaced wholesale.

### Step 4: Update the Overlay

Rewrite `overlays/0021-rhaiis-pipeline.md` using the following approach:

**Preserve the YAML front matter** (`id`, `title`, `status`, `created`,
`affects`, `provenance`, `author`, `superseded_by`). Update `release` only if
the product version indicates a new RHOAI release.

**Fact section** — Replace with fresh content derived from the files above.
This section must cover:

- **Header** — Purpose of the repo (build spec, not publish); product version,
  builder version, repeatable build mode status
- **Variant Matrix table** — One row per (collection × variant) combination;
  columns: collection, variant, architectures, vLLM version, torch baseline,
  notable notes. Include whether the vLLM version is from the NeuralMagic fork
  (has `+rhai` local version tag) or upstream.
- **Package Content by Variant** — For each variant, list: vLLM package + extras,
  key functional packages (FlashInfer, AMD-specific kernels, IBM-specific, etc.),
  notable security constraints with JIRA references. Group variants logically
  (CUDA, ROCm, CPU, Gaudi, Neuron, Spyre, TPU).
- **Constraints-Rules Delegation** — Count how many variants use `torch-2.11.0 *`
  via constraints-rules.txt. Note exceptions: neuron-ubi9 disables delegation
  entirely; tpu-ubi9 uses `torch-2.10.0 *` (a different torch version, not
  torch-2.11.0). Any additional variants that use a non-2.11.0 collection or
  disable delegation must be called out explicitly.
- **Pipeline Flow** — Stage list; the fact that no publish jobs exist; artifact
  lifecycle explanation
- **Update Automation** — Renovate management status per variant; which variants
  are excluded from auto-updates

**Impact on Strategies section** — Update to reflect current state. Must include:

- A bullet on vLLM version fragmentation across variants (list how many distinct
  versions exist and which variant is furthest behind)
- A bullet on the Gaudi variant using a different vLLM fork with manual update cycle
- A bullet on the Neuron variant's complexity (old torch version, pinned neuronx
  stack with git hashes, disabled constraints-rules)
- A bullet on Spyre's multi-arch IBM-proprietary wheel stack: the IBM vLLM fork
  (`.spyre` suffix), sendnn-inference (arch-conditional), torch-sendnn (x86/P,
  pre-built from private index), torch-nnpa (Z only, pre-built), ibm-fms
  (Foundation Model Stack), and new wheels spyremetrics / ibm-aiu-smi once they
  land. Note that aiu-monitor is not a wheel collection package — it lives in
  the base image. The SPYRE_VERSION runtime (RPM stack) is owned by the base
  image and is not visible here.
- A bullet establishing that no Pulp publish path exists (build artifacts only)
- A bullet on the builder version lag between this repo and rhai/pipeline
- A bullet on the cpu-ubi9 `zen` extra — read `collections/rhaiis/cpu-ubi9/requirements.txt`
  and report the exact platform marker (or absence of one) on the `vllm[...,zen,...]`
  line; do not assume it is unconditional

**Context section** — Keep the rationale unchanged. Update the date and version
references to remain accurate.

### Step 5: Write the Updated File

Write the updated content to `overlays/0021-rhaiis-pipeline.md` using the Write
tool.

### Step 6: Report

Output a brief summary:

```
Updated overlays/0021-rhaiis-pipeline.md

Changes:
- [product version: old → new]
- [builder version: old → new]
- [per-variant vLLM version changes, e.g., "cuda13.0: 0.21.0+rhaiv.10 → 0.22.0+rhaiv.1"]
- [any variants added or removed]
- [any notable package additions/removals]

Repository used: {REPO} (./tmp/rhaiis-pipeline is not tracked by git)
```

## Notes

- **Trust assumption:** The fetch script validates the git remote origin for
  both the local `../rhaiis/pipeline` checkout and any `./tmp/rhaiis-pipeline`
  clone against the allowlisted repository. Both the HTTPS form
  (`https://gitlab.com/redhat/rhel-ai/rhaiis/pipeline.git`) and the SSH form
  (`git@gitlab.com:redhat/rhel-ai/rhaiis/pipeline.git`) are accepted. Do not
  run this skill against a fork or unofficial mirror.
- `tmp/` is in `.gitignore`; the cloned repository is local only
- The script is idempotent: run it again any time the upstream repo changes
- Do not change the overlay `id` (0021) or `author` fields
- Preserve AIPCC and INFERENG ticket references when they are still accurate
- Pay close attention to whether the Gaudi vLLM version has a `+rhai` local
  version tag or not — the absence of the tag indicates upstream vllm-project/vllm,
  not the NeuralMagic fork. If the tag is absent, Renovate's custom regex manager
  for Gaudi will not match the version and will not propose updates; do NOT
  describe this as "explicitly excluded" — there is no dedicated exclusion
  packageRule for Gaudi
- Do not commit any changes to the rhaiis/pipeline repository or to GitLab
