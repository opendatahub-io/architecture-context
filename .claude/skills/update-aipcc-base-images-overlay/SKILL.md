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

### Step 1: Clone or Update the Repository

Run the fetch script from the root of the architecture-context repository:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/fetch-base-images-repo.sh
```

This clones `https://gitlab.com/redhat/rhel-ai/core/base-images/app.git` to
`./tmp/app`, or pulls the latest changes if the clone already exists.

### Step 2: Generate Tables from the Repository

Run the repository's own documentation generator as an executable:

```bash
./tmp/app/bin/generate-platform-docs.py
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

Repository cloned/updated: tmp/app (not tracked by git)
```

## Notes

- **Trust assumption:** This skill executes `generate-platform-docs.py` from
  `https://gitlab.com/redhat/rhel-ai/core/base-images/app.git` without
  integrity verification. The upstream repository is assumed to be trusted and
  not compromised. Do not run this skill against a fork or unofficial mirror.
- `tmp/` is in `.gitignore`; the cloned repository is local only
- The script is idempotent: run it again any time the upstream repository changes
- Do not change the overlay `id` (0017) or `author` fields
- Preserve Jira ticket references (e.g., AIPCC-3471) in the Fact section when
  they are still accurate; remove them if the underlying issue is resolved
