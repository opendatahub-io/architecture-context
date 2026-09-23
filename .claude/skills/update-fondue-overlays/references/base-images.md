# Base Images Overlay (0017)

Rules for refreshing `overlays/0017-aipcc-base-images.md` from `images/base/`
in the Fondue monorepo. Paths in this file are relative to
`{BASE}` = `{FONDUE}/images/base` unless they start with `{FONDUE}`.

## Overview

The overlay documents the accelerator variants (CPU, CUDA, ROCm, Gaudi, Spyre,
Neuron, TPU, Rubin) built from `images/base/`. It is used to evaluate RFEs that
propose changes to accelerator support. When `images/base/` changes, refresh
the overlay.

**Dependency management model (as of 3.6):** Package dependencies are declared
in `context/<variant>/rpms.in.yaml` and resolved into a hermetic lockfile at
`context/<variant>/rpms.lock.yaml` using `rpm-lockfile-prototype`. Konflux
(via Cachi2) fetches packages directly from the locked CDN URLs during hermetic
builds. Routine version drift is handled automatically by MintMaker
(`refresh-rpm-lockfiles` Renovate preset). Manual lockfile regeneration is only
needed when adding or removing packages from `rpms.in.yaml`.

## Key Files

**Common build configuration:**
- `build-args/argfile.conf` -> `APP_BASE_IMAGE` (base OS pin), `INDEX_VERSION`
  (RHOAI product version), `REPO_VERSION` (RHEL AI RPM repo version),
  `PYTHON_VERSION` default, `INDEX_BASE_URL` (default public package index URL),
  `INDEX_STAGE`

**Per-variant Python package index** -- read each `build-args/<variant>-*.conf`
(falling back to `argfile.conf` for any value the variant conf does not set) for
`INDEX_BASE_URL`, `INDEX_VERSION`, `INDEX_VARIANT`, `INDEX_STAGE`,
`INDEX_SUFFIX`, `INDEX_URL_TEMPLATE`, `DISTRIBUTION_SCOPE`, and whether
`regen-skip: INDEX_BASE_URL` is present (indicating a deliberate override).

**Record the rendered index URL, not the bare base URL.** The value baked into
`pip.conf`/`uv.toml` is `INDEX_URL_TEMPLATE` with all variables expanded. For the
default template
`${INDEX_BASE_URL}/${INDEX_VERSION}/${INDEX_VARIANT}${INDEX_STAGE}${INDEX_SUFFIX}`
this renders to e.g.
`https://packages.redhat.com/api/pypi/public-rhai/rhoai/3.6/cpu-ubi9-test/simple/`.
**Stage matters:** `INDEX_STAGE` is `-test` on `main` (images point at the
**staging** index). Release branches override it and the value differs by
branch (e.g. an EA branch may use `-prod` while later release builds use an
empty, unsuffixed stage) -- never state a single release value.
Read `INDEX_STAGE` literally from the conf rather than assuming a value.
Always state which stage the rendered URL targets, and never present the bare
`INDEX_BASE_URL` as the index the images actually use.

There are three index patterns (record each as its **rendered** URL):

- **Public RHEL AI index** (base `https://packages.redhat.com/api/pypi/public-rhai/rhoai`;
  renders to `.../rhoai/${INDEX_VERSION}/${INDEX_VARIANT}${INDEX_STAGE}/simple/`,
  e.g. `.../rhoai/3.6/cpu-ubi9-test/simple/` on `main`): CPU, CUDA, ROCm, Rubin.
  These images embed a single `index-url` in `pip.conf` and `uv.toml` pointing
  to this rendered URL.
- **Private RHAIIS index** (`https://private.console.redhat.com/api/pypi/rhai/rhaiis`):
  Gaudi, Neuron, TPU. Marked `regen-skip: INDEX_BASE_URL` and
  `DISTRIBUTION_SCOPE=private` (not a classifier: some public-index variants are
  also `private`; see Shared Facts). The private index **replaces** the public index
  entirely -- pip and uv are configured with a single `index-url` (not
  `extra-index-url`), so there is no fallback to the public index. These variants
  use a private index because their wheels contain non-redistributable content
  (Habanalabs, AWS Neuron SDK, Google TPU/Torch-XLA). Downstream product
  container builds consume this index directly.
- **Torch Day 0 variants**: use the public host (`packages.redhat.com/api/pypi/public-rhai`)
  with a different template
  (`${INDEX_BASE_URL}/${INDEX_VERSION}-${INDEX_VARIANT}${INDEX_STAGE}${INDEX_SUFFIX}`,
  note the `-` joining version and variant), rendering to e.g.
  `.../public-rhai/torch-2.14.0-cpu-ubi9-test/simple/`. The same `-test`/prod
  stage rule applies; these confs carry `regen-skip` for the index vars, so read
  their literal values rather than assuming the default.
- **Spyre**: wheels are published to the public RHAI index like the other variants
  (`rhoai/3.6/spyre-ubi9/simple/`, via `rhai-pipeline/`; see overlay 0020 which
  lists spyre-ubi9 in `publish_config.yml`). Any `# NOTE: index does not exist`
  comment in the conf file is stale and should not be treated as authoritative.

**Per-variant configuration** (one directory per variant under `context/`):
- `context/<variant>/rpms.in.yaml` -- **primary source of truth for package
  content.** Contains:
  - `contentOrigin.repofiles`: which `.repo` files feed the resolver (RHEL EUS,
    RHELAI, and any accelerator-specific repo)
  - `arches`: architectures the lockfile resolves for (may be a superset of
    what CI builds)
  - `packages`: flat list of package names (bare names) plus arch-scoped entries
    using `arches: {only: [...]}`. For Spyre, IBM SDK RPMs are expressed as
    versioned package names (e.g. `ibm-aiu-toolbox-e2e-1.3.0`) -- these are the
    authoritative version pins (AIPCC-29839).
- `context/<variant>/rpms.lock.yaml` -- hermetic lockfile produced by
  `rpm-lockfile-prototype`. Contains per-arch closures with full CDN URL,
  sha256/sha512 checksum, size, name, and EVR for every resolved package.
  Grep it (do not read it whole) to confirm resolved EVRs for key packages
  (e.g. CUDA driver RPMs, ROCm SDK version, Spyre IBM RPMs). Do not use this file to enumerate the *declared*
  package list -- use `rpms.in.yaml` for that.

**Build args per variant** (read for hardware-specific details):
- `build-args/cuda*-*.conf` (one per CUDA version) -> CUDA toolkit version,
  `TORCH_CUDA_ARCH_LIST`
- `build-args/rocm7.*.conf` -> ROCm version
- `build-args/spyre-*.conf`, `build-args/gaudi-*.conf`, `build-args/tpu-*.conf`,
  `build-args/neuron-*.conf` -> other variant-specific build args

**Variant inventory** (authoritative list of variants currently built):
- `{FONDUE}/ci-job-definitions.yml` -> `base_images.variants` (see "Variant ×
  arch matrix" in the SKILL.md Shared Facts)
- Cross-check with the `build-args/` listing (one conf file per variant, e.g.
  `cuda13.0-el9.8-app.conf`; `argfile.conf` is the common base) and the
  `context/` listing (per-variant lockfiles)

**Documentation generator** (do not run): `bin/generate-platform-docs.py`
resolves `.gitlab-ci.yml` relative to `images/base/`, so it always fails in the
monorepo layout. Derive everything from the source files above, which are the
authoritative source in any case.

**Lockfile tooling** (for context -- do not execute):
- `bin/hermetic-generate-lockfiles.sh` -> how lockfiles are regenerated manually
  (only needed when adding/removing packages); reads `rpm-lockfile-prototype`
- `bin/lint-lockfiles.py` -> static linter run in CI (arch alignment, integrity,
  coupling: if `rpms.in.yaml` changed, `rpms.lock.yaml` must also change)
- `bin/merge-arch-locks.py` -> merges per-arch lockfile outputs

## Extract Current State per Variant

Take each variant's built architectures from `base_images.variants` in
`{FONDUE}/ci-job-definitions.yml`, not from `rpms.in.yaml`. Then, for each
variant in `context/`, read `rpms.in.yaml` to determine:
- Repo sources (`contentOrigin.repofiles`)
- Notable declared packages (especially any version-pinned names, arch-scoped
  packages, and packages with JIRA-referenced comments)

For Spyre specifically, record all `ibm-*` versioned package names from
`rpms.in.yaml` -- these are the IBM SDK version pins replacing the old conf-file
approach (AIPCC-29839).

**Exclude `ibm-aiu-monitor` from the overlay.** Do not list `ibm-aiu-monitor`
(nor `aiu-monitor`) in the Spyre IBM RPM table or anywhere else in this overlay,
even though it appears in `context/spyre/rpms.in.yaml`. Documenting it here
surfaces it to strategy/RFE tooling and causes spurious epics to be created
(reviewer request, cf. RHAI-685). Skip this package when transcribing the Spyre
package set.

For CUDA variants, read `build-args/cuda*.conf` for the CUDA toolkit version
and `TORCH_CUDA_ARCH_LIST`.

## Overlay Content

Update `release` only if the repository clearly targets a new RHEL AI release.

**Fact section** -- Replace entirely with fresh content. This section must cover:

- What the base images are and how downstream teams use them
- **Common foundation** -- base OS image pin (from `argfile.conf`), Python
  version, RHEL AI repo version, package index version and URL, container
  layout, environment metadata (labels, env vars), helper scripts. Include a
  one-line note that `DISTRIBUTION_SCOPE` is an image label only and does not
  decide index routing.
- **Dependency management model** -- describe the `rpms.in.yaml` / `rpms.lock.yaml`
  pattern: `rpms.in.yaml` declares packages and arch scoping;
  `rpm-lockfile-prototype` resolves the hermetic lockfile; Konflux/Cachi2
  fetches from locked CDN URLs at build time; MintMaker handles routine drift
  automatically; manual regeneration required only when adding/removing packages
- **Accelerator Summary** table with columns:
  `Accelerator | Version | Status | Python | RHEL | aarch64 | ppc64le | s390x | x86_64`
- **Status Legend** -- Active / In development / Disabled / Retired
- One subsection per accelerator variant covering: status, `rpms.in.yaml` path,
  target architectures, container image name, driver/SDK version (from build-args
  conf or lock), Python package index (public RHEL AI, private RHAIIS, Torch Day 0,
  or none) shown as the **rendered `INDEX_URL_TEMPLATE`** (full path incl.
  version, variant, `-test`/prod stage suffix, and `/simple/`) — not the bare
  `INDEX_BASE_URL`, `DISTRIBUTION_SCOPE`, and notable declared packages
  (version-pinned or arch-scoped)
- For **Spyre**: list the IBM SDK RPM version pins from `rpms.in.yaml` and note
  that these are the single source of truth per AIPCC-29839; note which packages
  are arch-conditional (`only: [...]`). **Omit `ibm-aiu-monitor`** from this list
  (see Extract Current State per Variant and Notes)
- **Retired Accelerators** subsection for anything removed from the repo

**Impact on Strategies section** -- Update to reflect current state. Must include:

- A bullet that all RHAI components using accelerator-specific Python libraries
  must use these base images
- A bullet on the lockfile-based hermetic build model: package content is fixed
  at lockfile commit time; RFEs adding packages must account for the
  `rpms.in.yaml` -> lockfile regeneration -> CI validation cycle
- Bullets for each non-Active variant (in-development, disabled, retired)
  explaining what strategies must or must not assume
- A bullet about the number of concurrent CUDA versions and the driver-version
  dependency each introduces
- A bullet about Spyre's arch-conditional IBM RPM stack and that SDK RPM pins
  live in `rpms.in.yaml`, while the SDKs' Python wheels are pinned separately
  in the consuming `rhai-pipeline/` collections, so an SDK bump must update
  both
- A bullet explicitly distinguishing the two Python package index patterns:
  (a) public RHEL AI index for CPU/CUDA/ROCm/Rubin -- the default for most
  strategies; (b) private RHAIIS index for Gaudi/Neuron/TPU -- **replaces** the
  public index entirely (single `index-url`, no fallback) because those wheels
  are non-redistributable; downstream product builds consume the private index
  directly. Strategies targeting Gaudi, Neuron, or TPU must not assume the
  public RHEL AI index is available or sufficient for those variants.

## Report Details

- Accelerators added, removed, or with changed status/versions
- Changes to the common foundation (base OS, Python, RHEL AI repo)
- Spyre IBM SDK RPM version changes
- Lockfile model changes, if relevant

## Notes

- The `rpms.in.yaml` + `rpms.lock.yaml` pattern replaced the old per-variant
  conf-file approach as of 3.6. When reading older overlays or conf files,
  treat them as historical -- the lockfiles are authoritative now.
- **`ibm-aiu-monitor` is intentionally excluded** from this overlay. It is
  present in `context/spyre/rpms.in.yaml` (ppc64le only) but must not be
  documented here: doing so surfaces it to downstream strategy/RFE tooling and
  triggers spurious epics (reviewer request, cf. RHAI-685). Do not re-add it on
  future regenerations, regardless of its version pin in the source.
