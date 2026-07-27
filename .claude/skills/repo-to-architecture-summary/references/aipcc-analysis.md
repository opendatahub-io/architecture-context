# AIPCC Ecosystems Detection — Legacy Route Only

Synthesis and partial routes skip this step entirely.

For every Konflux Dockerfile that installs Python packages (via `pip` or `uv`),
check for indicators that the project uses the output of the AIPCC Ecosystems
team:

- References `quay.io/aipcc/base-images/*` in FROM lines
- Uses build args (`BASE_IMAGE`, `AIPCC_IMAGE`, `FROM_IMAGE`, etc.) that may resolve to AIPCC images
- Has filename suffixes indicating accelerator variants (`.cpu`, `.cuda*`, `.rocm*`, `.gaudi`, `.spyre`, `.neuron`, `.tpu`)
- References AIPCC tooling paths (the string `rhaipcc`, per overlay 0017: `/usr/libexec/rhaipcc/dnf`, `/etc/rhaipcc/env`)

**Always include the `## AIPCC Ecosystems Use` section when any Konflux
Dockerfile installs Python packages.** The section documents both actual AIPCC
usage AND the absence of AIPCC usage. Components that install Python packages
but do NOT use AIPCC base images represent a gap that architects need to track.
Skip this section only when no Konflux Dockerfile installs Python packages.

## When AIPCC indicators are found

1. Read `overlays/0017-aipcc-base-images.md` from the architecture-context repo
   (the repo containing this skill) to get the authoritative catalog of
   accelerator variants, their current versions, architectures, and status.
   Do NOT rely on cached or remembered values — always read the overlay file
   to get current data.
2. For each matching Dockerfile:
   a. Extract the exact base image reference (including SHA256 digest if present).
   b. Match the image name or Dockerfile suffix against the variant catalog from
      overlay 0017 to determine: Accelerator type, Version, Architectures, Status.
   c. If the image name matches an AIPCC pattern not listed in overlay 0017,
      document it as-is with Status "Unknown" and note it may be a new or
      unlisted variant.
   d. If the image is a non-AIPCC Python base, document base image; set
      Accelerator and Status to "N/A".
3. Check whether the Dockerfile adds pip/uv configuration beyond what the AIPCC
   base provides, and list any additional packages installed on top.
4. Check whether the Dockerfile calls `/usr/libexec/rhaipcc/dnf` or sources
   `/etc/rhaipcc/env`.
5. Write all findings into the `## AIPCC Ecosystems Use` section.

## When NO AIPCC indicators are found but Python packages are installed

1. Still include the `## AIPCC Ecosystems Use` section.
2. For each Dockerfile that installs Python packages but uses a non-AIPCC base
   image, document the base image used and note that it does not use the AIPCC
   Ecosystems.
3. State that the component must be migrated to use AIPCC base images to comply
   with Red Hat's product security requirements for secure builds regardless of
   whether it uses accelerator-specific libraries.
