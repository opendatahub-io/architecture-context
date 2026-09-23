# RHAI Pipeline Overlay (0020)

Rules for refreshing `overlays/0020-rhai-pipeline.md` from `rhai-pipeline/` in
the Fondue monorepo. Paths in this file are relative to
`{PIPELINE}` = `{FONDUE}/rhai-pipeline` unless they start with `{FONDUE}` (the
monorepo root). Some authoritative files live at the monorepo root; those are
called out explicitly.

## Overview

The overlay documents the RHAI wheel package index management system: which
variants are published, what collections exist, and how wheels flow from CI
builds to the customer-facing Pulp index. When the repo changes -- new variant
in `publish_config.yml`, new collection, updated product version, or changes to
the Pulp publishing workflow -- refresh the overlay.

## Key Files

**Version information:**
- `product-version.yml` -> `PRODUCT_VERSION` (the rhai-pipeline wheel-index
  product version, e.g. `3.6`)
- `supported_versions.yml` -> full version history and per-version variant lists
- `{FONDUE}/builder/product-version.yml` -> `PRODUCT_VERSION` (e.g. `0.0-el9.8`)
  is the **OS/platform version** the builder targets (RHEL 9.8). Report this in the
  overlay as the base OS version, not as the builder release.
- **Builder resolution:** report the builder source exactly as "How consumers
  get the builder" in the SKILL.md Shared Facts states it; confirm the string in
  `{FONDUE}/builder-image-version.yml` but never report it as a version tag.
  Cite the tag in `{FONDUE}/releases/builder-release.yaml` only as context for
  what the current Fondue release contains, never as rhai-pipeline's pinned
  builder release.

**Published variant configuration:**
- `publish_config.yml` -> per-variant `VARIANT`, `WHEEL_REPO_VERSION`, and
  `SDIST_REPO_VERSION` entries (these are the variants currently wired for
  production publication)

**Build matrix and Pulp routing:**
- `{FONDUE}/ci-job-definitions.yml` (at the **fondue monorepo root**, not
  inside `rhai-pipeline/`) -> the authoritative source for the CI matrix and
  per-collection / per-variant Pulp routing. Read this file, not any script
  inside `{PIPELINE}/bin/`. Key sections to extract, all under `rhai_pipeline:`:
  - `collections` (collection -> variants), `variants` (variant -> arches),
    `omit_jobs` list
  - **Effective arch set per (collection, variant) is computed, not copied.**
    For every collection/variant pair, start from `rhai_pipeline.variants.<variant>.arches`
    (the base arch set) and subtract every `omit_jobs` entry matching
    `[<collection>, <variant>, <arch>]`. The remainder is the effective arch
    set. Recompute this from the current file for every pair — never carry the
    arch annotation over from the existing overlay. A narrowed set (fewer than
    the base arches) is valid **only** if a current `omit_jobs` entry removes
    those arches; if no matching `omit_jobs` entry exists, the variant builds on
    all of its base arches. When the effective set equals the base set, say so
    (e.g. "cpu (all 4 arches)") rather than restating a stale subset.
  - **An `omit_jobs` entry is only effective if its first element is a
    collection key** (a key under `rhai_pipeline.collections`). `regen-ci.py` skips a job
    only when the tuple `(collection, variant, arch)` matches, and its
    validator never checks the first element — so an entry naming a *package* or
    *product* (e.g. `docling`, `sdg-hub`) instead of a collection matches
    nothing and is **dead**. Before treating any `omit_jobs` entry as a real
    exclusion, confirm its first element appears as a collection key. Flag dead
    entries explicitly; do not present them as effective exclusions. Note that
    per-package arch exclusions are instead enforced by PEP 508 environment
    markers in the collection's `requirements*.txt` (e.g.
    `docling ; platform_machine != 's390x'`), which is a separate mechanism from
    `omit_jobs` — verify the marker before claiming a package is skipped on an
    arch.
  - `overrides._default` -> default `PULP_DOMAIN` (e.g. `public-rhai`)
  - `overrides.<collection>` -> collection-level routing exceptions (e.g.
    `vllm-deps/torch-2.11` -> `PULP_DOMAIN: rhai`)
  - `variant_overrides.<collection>.<variant>` -> per-variant routing overrides
    applied after collection-level overrides. Precedence:
    `_default -> <collection> -> variant_overrides.<collection>.<variant>`.
    **Enumerate every entry** under `variant_overrides` — iterate all
    collections and all variants beneath them; do not assume the set is limited
    to the `rhaiis` collection or to any previously documented list. For each
    entry, record the collection, the variant, and the exact override keys and
    values (e.g. `PULP_DOMAIN`, `PULP_BASE_PATH`, `PRODUCT_NAME`). Capture the
    rationale wherever a comment supplies one (e.g. AIPCC-28553 for the private
    `PULP_DOMAIN: rhai` overrides).

**Collection contents (spot-check):**
- For each collection subdirectory under `collections/`, read the directory
  listing to confirm which variant subdirs exist.
- For the `rhai` collection on `cpu-ubi9`, read
  `collections/rhai/cpu-ubi9/requirements/` directory listing to see the
  team-owned requirement files.
- For every other collection directory under `collections/` -- read the
  `requirements.txt` or directory listing for at least one representative
  variant.

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
  - `torch-sendnn` pinned version -- pre-built IBM wheel, not compiled by builder
  - `torch-nnpa` pinned version -- pre-built IBM wheel, s390x only
  - `ibm-fms` pinned version (also check `constraints.txt`)
  - `spyremetrics` and `ibm-aiu-smi` -- new wheels; capture version and arch
    restrictions if present
  - **Do not** list `aiu-monitor` / `ibm-aiu-monitor` as wheel collection packages.
    As of AIPCC-28729 the `aiu-monitor<0.0.0` / `ibm-aiu-monitor<0.0.0` guard lines
    were removed from `{FONDUE}/builder/collections/global-constraints.txt`; read the current
    file to confirm the actual set of global constraints. Do not state that aiu-monitor
    is blocked via global-constraints.txt — verify before making that claim.

## Overlay Content

Update `release` only if the product version indicates a new RHOAI release.

**Fact section** -- Replace with fresh content derived from the files above.
This section must cover:

- **Header** -- Purpose of `rhai-pipeline/` (index management, not compilation);
  product name, product version, builder version, Pulp domain, public base URL
- **Published Variants table** -- One row per variant in `publish_config.yml`;
  columns: variant, architectures, key release-defining package versions (found
  using the heuristics from Key Files), public index path.
- **Collections and Variant Coverage table** -- One row per collection with
  purpose description and which variants it covers; derived from
  `{FONDUE}/ci-job-definitions.yml` (the authoritative source per Key Files).
  Where a variant's arch coverage is annotated (e.g. `cpu (all 4 arches)` or
  `cpu (aarch64, x86_64)`), use the **effective arch set computed in Key Files**
  (`rhai_pipeline.variants.<variant>.arches` minus matching `omit_jobs` entries) — recompute
  it, never copy the annotation from the existing overlay. Any subset shown must
  be justified by a current `omit_jobs` entry for that exact
  `(collection, variant, arch)`; if none exists, show the full base arch set.
  Note all routing exceptions from the same file:
  - **Collection-level**: `vllm-deps/torch-2.11` -> private domain `rhai`
    (`private.console.redhat.com`); used by the vLLM team for test builds
    during the transition to supplying pre-built wheels.
  - **Variant-level** (`variant_overrides`): list **every** entry present in
    the file, transcribed exactly (see Key Files) — do not treat the set as fixed.
    Known categories include private-domain overrides (`PULP_DOMAIN: rhai`,
    e.g. the `rhaiis` gaudi/neuron/tpu variants carrying vendor wheels that
    cannot be publicly redistributed, AIPCC-28553) and index-path overrides
    (`PULP_BASE_PATH`, e.g. `torch-day0` variants), but the file is the source
    of truth for what actually exists. Precedence:
    `_default -> overrides.<collection> ->
    variant_overrides.<collection>.<variant>`.
- **OMIT_JOBS** -- Explicit exclusions from the matrix with their reasons.
  Only **effective** entries (first element is a collection key, per Key Files)
  justify narrowing a variant's arch coverage in the table above: every reduced
  arch annotation must map to an effective entry, and every effective entry must
  be reflected as a reduced arch set in the corresponding collection row. If a
  previously-omitted `(collection, variant, arch)` combination is no longer
  listed, that variant now builds on the full base arch set — update the table
  accordingly. **List any dead entries separately and label them as such** (an
  entry whose first element is a package/product name, not a collection, so
  `regen-ci.py` never matches it — e.g. `docling`, `sdg-hub`). Do not describe a
  dead entry as a working exclusion; where the intended arch skip is actually
  achieved by a PEP 508 marker in `requirements*.txt`, say so and cite the
  marker.
- **Test jobs** -- Which collections have `enable_test_jobs: true`
- **The `rhai` Collection** -- Team ownership structure; list notable team files
  and their contents
- **Onboarding Pipeline** -- How new packages enter (onboarding -> graduation via
  weekly bot -> `rhai` collection)
- **Pipeline Flow** -- Stage list; trigger types (derive them from the
  `.generated/rhai-*.yml` include rules in the root `.gitlab-ci.yml` and the job
  rules, per "How consumers get the builder" in the SKILL.md Shared Facts);
  key checks-stage gates
  (variant-linter, verify-publish-config, validate-package-deletion-manifests)
- **Pulp Publishing Mechanics** -- Upload to test repositories, dual-repo
  promotion to prod (promote plan/apply jobs), and the legacy
  `publish_config.yml` path; repository naming convention; authentication
  method. Routing has **two independent dimensions**, both driven by
  `overrides`/`variant_overrides` (see Key Files): `PULP_DOMAIN` (which Pulp
  domain (tenant) on the shared API — public `public-rhai` vs private `rhai`)
  and `PULP_BASE_PATH` (the path/repo
  name **within** a domain). The general rule -- all collections for a published
  variant go to the same public index at the default base path -- applies only
  to variants with **no** `PULP_DOMAIN` and **no** `PULP_BASE_PATH` override.
  Enumerate both kinds of exception from `variant_overrides`:
  - `PULP_DOMAIN` overrides (e.g. `vllm-deps` collection-level, and the `rhaiis`
    gaudi/neuron/tpu variants) redirect to the private `rhai` domain.
  - `PULP_BASE_PATH` overrides (e.g. `torch-day0` variants) keep the **public**
    `public-rhai` domain but publish to a **version-pinned base path** within it
    — e.g. `PULP_BASE_PATH: torch-2.14.0-cpu-ubi9` and
    `PULP_BASE_PATH: torch-2.14.0-cuda13.0-ubi9` yield the Pulp repos
    `public-rhai/torch-2.14.0-cpu-ubi9` and `public-rhai/torch-2.14.0-cuda13.0-ubi9`
    (each with a `-test` sibling); take the current values from
    `variant_overrides`. `dual-repo-promote.sh` derives the repo name
    directly from `PULP_BASE_PATH` (flattening any `/` to `-` — a no-op here, since
    these values contain no slash) and ignores `PRODUCT_VERSION` entirely. Copy the
    base path **verbatim** from source; do not synthesize it from the variant name.
    The published repo **drops** the `-torch-day0` collection segment — it is
    **not** `torch-2.14.0-cpu-torch-day0-ubi9`. These variants do **not** land at
    the default `rhoai/<PRODUCT_VERSION>/<variant>-<stage>` path.
    Do not describe them as using the default per-product path.
  State deletion, copy and promotion scope exactly as the job definitions
  establish (e.g. the `PULP_DOMAIN`/`PRODUCT_NAME` the delete and copy jobs
  set); do not infer beyond them.
- **Package Deletion System** -- Manifest-driven, enforced at upload time,
  idempotent
- **Version Branching** -- the `pulp copy` CLI (see `{PIPELINE}/README.md`) for
  EA->GA promotion

**Impact on Strategies section** -- Update to reflect current state. Must include:

- A bullet establishing `rhai-pipeline/` as the authoritative Pulp publish gate
- A bullet on the steps required to add a new collection or variant
- A bullet on `ENABLE_REPEATABLE_BUILD_MODE` implications for release branches
- A bullet on how many CUDA versions are maintained and the cost of adding one
- A bullet on ROCm version state (which is built vs which is published)
- A bullet on Spyre's IBM-proprietary wheel stack: the vLLM IBM fork (`.spyre`
  suffix), sendnn-inference (IBM's inference runtime), torch-sendnn (pre-built
  from private index; record arch markers exactly as in source), torch-nnpa (Z
  only, pre-built from private index), ibm-fms (Foundation Model Stack, built
  from source). Torch version is
  shared with other variants via constraints-rules.txt. aiu-monitor is not a
  wheel collection package; it ships in the base image instead.
- A bullet on the public URL as a stable contract for air-gapped mirroring
- A bullet on the idempotent deletion system and the onboarding graduation cadence

**ROCm Work Breakdown Patterns** -- Include this subsection to guide downstream
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

## Report Details

- Product version: old -> new
- Builder resolution or release tag changes
- Variants added/removed from `publish_config.yml`
- Collections added/removed
- Notable changes to the publishing workflow

## Notes

- The Pulp version HREFs in `publish_config.yml` are long UUIDs -- include only
  the version number portion in the overlay, not the full HREF
