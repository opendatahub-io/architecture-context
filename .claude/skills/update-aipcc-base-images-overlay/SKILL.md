---
name: update-aipcc-base-images-overlay
description: Use when the AIPCC base image repository has changed and the overlay file overlays/0017-aipcc-base-images.md needs to be refreshed with current accelerator support information, versions, or architecture details.
user-invocable: true
allowed-tools: Read, Write, Bash(bash ${CLAUDE_SKILL_DIR}/scripts/fetch-base-images-repo.sh), Bash(./tmp/app/bin/generate-platform-docs.py), Glob, Grep
---

# Update AIPCC Base Images Overlay

Refresh `overlays/0017-aipcc-base-images.md` with current information from the
AIPCC base images repository.

## Overview

The overlay documents the accelerator variants (CPU, CUDA, ROCm, Gaudi, Spyre,
Neuron, TPU) built from the base-images/app repository. It is used to evaluate
RFEs that propose changes to accelerator support. When the repository changes,
run this skill to update the overlay.

## Instructions

### Step 1: Locate or Clone the Repository

Run the fetch script from the root of the architecture-context repository:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/fetch-base-images-repo.sh
```

The script checks for a local fondue checkout at `../fondue/images/base`. If
found, it prints that path and exits. Otherwise it clones or updates `./tmp/fondue`
from `https://gitlab.com/redhat/rhel-ai/wheels/fondue.git` and prints
`./tmp/fondue/images/base`.

Use the printed path as `{REPO}` in all subsequent steps.

### Step 1b: Read Spyre-Specific Build Args

In addition to the generated tables, read the following files directly from
`{REPO}` to capture Spyre runtime state:

- `build-args/spyre-app.conf` → per-arch Spyre runtime version:
  `SPYRE_VERSION_x86_64`, `SPYRE_VERSION_ppc64le`, `SPYRE_VERSION_s390x`.
  These pin the version of every IBM proprietary RPM installed by
  `context/spyre/app/dnf-install-spyre.sh` (ibm-aiu-toolbox-e2e, ibm-deeptools,
  ibm-flex, ibm-senlib-core, ibm-senlib-dd2, ibm-spyre-model-cache,
  ibm-libaiupti, ibm-z-spyre-runtime). All three arches must match or be
  documented separately if they diverge.
- `context/spyre/app/requirements/requirements.txt` → the version of
  `ibm-aiu-monitor` installed into the dedicated `/opt/aiu-monitor` venv (x86_64
  and ppc64le only). This package is installed from a private PyPI index — it is
  not in the public wheel collections. Include its version in the Spyre variant
  subsection of the overlay.

### Step 2: Generate Tables from the Repository

The generator script expects `.gitlab-ci.yml` in `{REPO}`, but in the fondue
monorepo the variant definitions live in `{REPO}/gitlab-ci/common.yml`. Create
a temporary symlink before running the script, and remove it afterward:

```bash
ln -s gitlab-ci/common.yml {REPO}/.gitlab-ci.yml
{REPO}/bin/generate-platform-docs.py
rm {REPO}/.gitlab-ci.yml
```

Capture the full output — it contains the accelerator summary table and
per-variant details that form the factual base of the overlay.

If the script produces output files rather than printing to stdout, read those
files to get the generated content.

### Step 3: Read the Current Overlay

Read the current content of `overlays/0017-aipcc-base-images.md` to understand
the existing structure, especially the "Impact on Strategies" and "Context"
sections, which contain human-authored guidance that must be preserved and
updated — not replaced wholesale.

### Step 4: Update the Overlay

Rewrite `overlays/0017-aipcc-base-images.md` using the following approach:

**Preserve the YAML front matter** (`id`, `title`, `status`, `created`,
`affects`, `release`, `provenance`, `author`, `superseded_by`). Update
`release` only if the repository clearly targets a new RHEL AI release.

**Fact section** — Replace entirely with fresh content derived from the
generator output and the repository. This section must describe:

- What the base images are and how downstream teams use them
- The common foundation (base OS, Python version, RHEL AI repo version,
  package index version, repositories, container layout, environment metadata,
  helper script)
- An **Accelerator Summary** table with columns:
  `Accelerator | Version | Status | Python | RHEL | aarch64 | ppc64le | s390x | x86_64`
- A **Status Legend** explaining Active / In development / Disabled / Retired
- One subsection per accelerator variant (CPU, NVIDIA CUDA variants, AMD ROCm,
  Intel Gaudi, IBM Spyre, AWS Neuron, Google TPU) covering: status, config
  file, architectures, container image, driver requirements (if applicable),
  and key dependencies
- A **Retired Accelerators** subsection for anything removed from the repo

For the **Spyre** variant subsection specifically, include:
- The per-arch `SPYRE_VERSION` values from `build-args/spyre-app.conf`
- The `ibm-aiu-monitor` version and arch restriction (x86_64 and ppc64le only),
  noting it is installed in a dedicated venv at `/opt/aiu-monitor` from a
  private index, not from the public wheel collections

**Impact on Strategies section** — Update to reflect the current state of each
accelerator variant. The section must include at least:

- A bullet noting that all RHAI components using accelerator-specific Python
  libraries must use these base images
- Bullets for each non-Active variant (in-development, disabled, retired)
  explaining what strategies must or must not assume
- A bullet about the number of concurrent CUDA versions and the driver-version
  dependency each introduces
- A bullet about any per-architecture versioning schemes (e.g., IBM Spyre)
- A bullet about the authoritative Python package index

**Context section** — Keep largely as-is but update the date and any version
references so it remains accurate. The context explains _why_ the overlay
exists; that rationale does not change with routine updates.

### Step 5: Write the Updated File

Write the updated content to `overlays/0017-aipcc-base-images.md` using the
Write tool.

### Step 6: Report

Output a brief summary:

```
Updated overlays/0017-aipcc-base-images.md

Changes:
- [list any accelerators added, removed, or with changed status/versions]
- [note any changes to common foundation]

Repository cloned/updated: {REPO} (./tmp/fondue is not tracked by git)
```

## Notes

- **Trust assumption:** This skill executes `generate-platform-docs.py` from
  `{REPO}/bin/`. The fetch script validates the git remote origin of both the
  local `../fondue` checkout and any `./tmp/fondue` clone against the allowlisted
  URL. Both the HTTPS form (`https://gitlab.com/redhat/rhel-ai/wheels/fondue.git`)
  and the SSH form (`git@gitlab.com:redhat/rhel-ai/wheels/fondue.git`) are
  accepted as they resolve to the same repository. Do not run this skill against a
  fork or unofficial mirror, and do not bypass the fetch script by supplying a
  path directly.
- `tmp/` is in `.gitignore`; the cloned repository is local only
- The script is idempotent: run it again any time the upstream repository changes
- Do not change the overlay `id` (0017) or `author` fields
- Preserve Jira ticket references (e.g., AIPCC-3471) in the Fact section when
  they are still accurate; remove them if the underlying issue is resolved
