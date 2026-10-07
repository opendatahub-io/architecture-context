# RHAI Pipeline Overlay (0020)

Rules for refreshing `overlays/0020-rhai-pipeline.md` from `rhai-pipeline/` in
the Fondue monorepo. Paths in this file are relative to
`{PIPELINE}` = `{FONDUE}/rhai-pipeline` unless they start with `{FONDUE}` (the
monorepo root). Some authoritative files live at the monorepo root; those are
called out explicitly.

## Overview

The overlay documents the RHAI wheel package index management system: which
collections build into which channels, what collections exist, and how wheels
flow from CI builds to the customer-facing Pulp indexes (channel uploads,
promotion, and the legacy product-versioned publish). Channel identity, the
catalog and URL derivation belong to overlay 0030; this overlay records
per-collection channel coverage, release-defining pins and the publishing
mechanics, and links to 0030. When the repo changes -- a new catalog row or
`torch_versions` entry, a new collection, an updated product version, or
changes to the Pulp publishing workflow -- refresh the overlay.

## Key Files

**Version information:**
- `product-version.yml` -> `PRODUCT_VERSION` (the rhai-pipeline wheel-index
  product version, e.g. `3.6`). It does not select channel index paths; report
  where it is still used, per "Wheel index product version" in `shared-facts.md`.
- `supported_versions.yml` -> full version history, the release branch of
  each version, and per-version variant lists
- `{FONDUE}/builder/product-version.yml` -> `PRODUCT_VERSION` (e.g. `0.0-el9.8`)
  is the **OS/platform version** the builder targets (RHEL 9.8). Report this in the
  overlay as the base OS version, not as the builder release.
- **Builder resolution:** report the builder source exactly as "How consumers
  get the builder" in `shared-facts.md` states it; confirm the string in
  `{FONDUE}/builder-image-version.yml` but never report it as a version tag.
  Cite the tag in `{FONDUE}/releases/builder-release.yaml` only as context for
  what the current Fondue release contains, never as rhai-pipeline's pinned
  builder release.

**Built channels and the legacy publish:**
- `{FONDUE}/.generated/rhai-promote-jobs.yml` -> one `promote-plan-<slug>` /
  `promote-apply-<slug>` pair per built index (grep the job names, the header
  count, and each job's `PULP_DOMAIN`, `PULP_BASE_PATH` and `INDEX_URL`).
  These are generated from the CI matrix, not from the catalog.
- `{FONDUE}/.generated/rhai-*.yml` -> grep `CHANNEL:` to see which collection
  builds which channel on which arch, and grep for build jobs without a
  channel.
- `channels.yml` -> the catalog. Read it for coverage checks only; overlay 0030
  owns its content.
- `publish_config.yml` -> per-variant `VARIANT`, `WHEEL_REPO_VERSION`, and
  `SDIST_REPO_VERSION` entries for the legacy product-versioned publish job.
  Do not present it as the list of published channels.

**Build matrix and Pulp routing:**
- `{FONDUE}/ci-job-definitions.yml` (at the **fondue monorepo root**, not
  inside `rhai-pipeline/`) -> the authoritative source for the CI matrix and
  per-collection / per-variant Pulp routing. Read this file, not any script
  inside `{PIPELINE}/bin/`. Key sections to extract, all under `rhai_pipeline:`:
  - `collections` (collection -> variants), `variants` (variant -> arches and
    `torch_versions`), `omit_jobs` list, `defaults`
  - **Torch versions per (collection, variant)**: `collections.<c>.torch_versions.<variant>`
    when present, else `variants.<variant>.torch_versions`. Each torch version
    is one channel (see overlay 0030). Also record
    `collections.<c>.torch_version_settings.<X.Y>` (per-torch job settings),
    `skip_builder_torch_constraints` (a variant list, or `true` for every
    variant) and `enable_post_merge_jobs`.
  - **Effective arch set per (collection, variant, torch) is computed, not
    copied.** Start from `rhai_pipeline.variants.<variant>.arches` (the base
    arch set) and subtract every `omit_jobs` entry matching
    `[<collection>, <variant>, <arch>]` or
    `[<collection>, <variant>, <torch>, <arch>]` (check the tuple forms
    `bin/regen-ci.py` accepts). The remainder is the effective arch set.
    Recompute this from the current file for every combination; never carry
    the arch annotation over from the existing overlay. A narrowed set (fewer
    than the base arches) is valid **only** if a current `omit_jobs` entry
    removes those arches; if no matching entry exists, the combination builds
    on all of its base arches. When the effective set equals the base set, say
    so (e.g. "cpu (all 4 arches)") rather than restating a stale subset.
  - **An `omit_jobs` entry is only effective if its first element is a
    collection key** (a key under `rhai_pipeline.collections`). `regen-ci.py` skips a job
    only when the tuple matches, and its validator never checks the first
    element, so an entry naming a *package* or *product* (e.g. `docling`,
    `sdg-hub`) instead of a collection matches nothing and is **dead**. Before
    treating any `omit_jobs` entry as a real exclusion, confirm its first
    element appears as a collection key. Flag dead entries explicitly; do not
    present them as effective exclusions. Per-package arch exclusions are
    instead enforced by PEP 508 environment markers in the collection's
    `requirements*.txt` (e.g. `docling ; platform_machine != 's390x'`), which
    is a separate mechanism from `omit_jobs`; verify the marker before
    claiming a package is skipped on an arch.
  - `overrides._default` -> default `PULP_DOMAIN`, `PULP_CACHE` and other job
    variables
  - `overrides.<collection>` -> collection-level overrides (read every entry;
    do not assume any of them changes the domain)
  - `variant_overrides.<collection>.<variant>` -> per-variant overrides
    applied after collection-level overrides. Precedence:
    `_default -> <collection> -> variant_overrides.<collection>.<variant>`.
    **Enumerate every entry** under `variant_overrides` — iterate all
    collections and all variants beneath them; do not assume the set is limited
    to the `rhaiis` collection or to any previously documented list. For each
    entry, record the collection, the variant, and the exact override keys and
    values (e.g. `PULP_DOMAIN`, `PULP_CACHE`, `CHANNEL`, `PRODUCT_NAME`,
    `WHEEL_SERVER_PROJECT_PATH`). Capture the rationale wherever a comment
    supplies one (e.g. AIPCC-28553 for the private `PULP_DOMAIN: rhai`
    overrides).

**Publishing code** (read the code, not the README, for behavior):
- `bin/upload_to_pulp.sh` and `src/rhai_pipeline/pulp_upload.py` -> upload
  mode precedence and the channel upload target (see "Legacy
  product-versioned indexes" in `shared-facts.md`)
- `.gitlab/channel-apply-job.yml` and `src/rhai_pipeline/pulp_channel.py` ->
  when and how the catalog is applied to Pulp
- `bin/dual-repo-promote.sh` -> promotion
- `.gitlab/publish-pulp-repositories.yml`, `.gitlab/copy-wheels-jobs.yml`,
  `.gitlab/delete-packages-job.yml`, `src/rhai_pipeline/pulp_copy.py`,
  `src/rhai_pipeline/pulp_delete.py`, `package-deletions/` -> legacy publish,
  version copy and package deletion
- `src/rhai_pipeline/pulp_config.py` -> the Pulp authentication method
- `.gitlab/*-job.yml` with `stage: checks` -> the checks-stage gates

**Collection contents (spot-check):**
- For each collection subdirectory under `collections/`, read the directory
  listing to confirm which variant subdirs exist, and list each variant's
  `torch/` overlays (`requirements-torch-<X.Y>.txt`,
  `constraints-torch-<X.Y>.txt`).
- For the `rhai` collection on `cpu-ubi9`, read
  `collections/rhai/cpu-ubi9/requirements/` directory listing to see the
  team-owned requirement files.
- For every other collection directory under `collections/` -- read the
  `requirements.txt` or directory listing for at least one representative
  variant.

**Key top-level package versions per channel:**

A collection whose `ci-job-definitions.yml` entry or comment declares it a
temporary rebuild of legacy pins, and that adds no channel, does not feed the
release-defining heuristics; name it as a contributing collection and report
any of its versions that are newer than a release-defining pin on the same
channel. To identify release-defining packages, use these heuristics rather
than a hardcoded list:

- **Torch pin**: follow "Torch pin and builder torch collections" in
  `shared-facts.md`. For each built channel, read the `torch==` line in
  `{FONDUE}/builder/collections/<builder_collection>/<variant>/constraints.txt`.
  Only for a (collection, variant) in `skip_builder_torch_constraints`, read the
  `torch-X.Y.Z *` line of the `constraints-rules.txt` that
  `{FONDUE}/builder/pipeline-api/prepare_constraints.sh` selects (variant
  level, else collection level); it names the builder collection whose
  constraints, including its `torch==` line, apply. If that rules file has no
  active rule, read `torch==` from the collection variant's `constraints.txt`
  and `torch/constraints-torch-<X.Y>.txt`; if neither pins torch, report no
  torch pin. Never report a rules file of a variant that is not skipped as its
  torch pin.
- **vLLM and other torch-linked packages**: for each torch version the
  collection builds, read the variant's `requirements.txt` and
  `constraints.txt` together with the matching
  `torch/requirements-torch-<X.Y>.txt` and `constraints-torch-<X.Y>.txt`, as
  `{FONDUE}/builder/pipeline-api/prepare_constraints.sh` assembles them (the
  overlays are appended to the base files, which are never just a fallback).
  For example, the neuron `torch-neuronx` and `torch-xla` pins live only in
  `collections/rhaiis/neuron-ubi9/constraints.txt`. Packages with local version tags (e.g. `+rhaiv.N`,
  `+rhai19`, `+rhaiv.N.spyre`) are maintained as internal forks and are
  release-defining. Note the fork origin: `+rhai` tags indicate the NeuralMagic
  enterprise fork, plain upstream versions indicate `vllm-project/vllm`, and a
  `.spyre` suffix indicates the IBM fork. Report any other suffix after the
  local tag exactly as written, with what source says about it.
- Packages that have different versions across variants or torch versions
  (visible by comparing the files above) are also release-defining because they
  drive per-channel scope decisions.
- Include these packages and their versions in the Channel Coverage table so
  RFE creators can identify major upgrades at a glance.

  **For `spyre-ubi9` specifically**, read
  `collections/rhaiis/spyre-ubi9/requirements.txt` and its `torch/` overlays,
  and capture:
  - `vllm` exact version string (note the local version tag and fork origin)
  - `sendnn-inference` pinned version; check whether it differs by arch
  - `torch-sendnn` pinned version -- pre-built IBM wheel, not compiled by builder
  - `torch-nnpa` pinned version -- pre-built IBM wheel, s390x only
  - `ibm-fms` pinned version (also check `constraints.txt`)
  - `spyremetrics` and `ibm-aiu-smi` -- capture version and arch restrictions
    exactly as in source
  - **Do not** list `aiu-monitor` / `ibm-aiu-monitor` as wheel collection packages.
    As of AIPCC-28729 the `aiu-monitor<0.0.0` / `ibm-aiu-monitor<0.0.0` guard lines
    were removed from `{FONDUE}/builder/collections/global-constraints.txt`; read the current
    file to confirm the actual set of global constraints. Do not state that aiu-monitor
    is blocked via global-constraints.txt — verify before making that claim.

## Overlay Content

Release labels follow the SKILL.md Overlay Rules.

**Fact section** -- Replace with fresh content derived from the files above.
This section must cover:

- **Header** -- Purpose of `rhai-pipeline/` (index management, not compilation);
  what `PRODUCT_NAME` and `PRODUCT_VERSION` still drive (only the consumers
  "Wheel index product version" in `shared-facts.md` lists; a path that
  hardcodes the version, such as a `variant_overrides` cache path, is not
  one), builder version
  context, default Pulp domain, and a link to overlay 0030 for channel identity
  and index URLs (do not restate the URL derivation)
- **Channel Coverage table** -- One row per built channel (promote job);
  columns: channel, collections that build it with their effective arch sets,
  torch pin and other release-defining package versions (found using the
  heuristics from Key Files). Do not add domain, maturity or `adopted_by`
  columns: overlay 0030 owns them.
- **Collections and Variant Coverage table** -- One row per collection with
  purpose description and which variants and torch versions it covers; derived
  from `{FONDUE}/ci-job-definitions.yml` (the authoritative source per Key
  Files). Do not restate the per-variant default torch lists
  (`rhai_pipeline.variants.<v>.torch_versions`): overlay 0030 owns them, so
  give the base arch sets and per-collection coverage and link 0030. Where an
  arch set is annotated (e.g. `cpu (all 4 arches)` or
  `cpu (aarch64, x86_64)`), use the **effective arch set computed in Key Files**
  (recompute it, never copy the annotation from the existing overlay). Any
  subset shown must be justified by a current, effective `omit_jobs` entry; if
  none exists, show the full base arch set. Also record per-collection
  `torch_versions` overrides, `torch_version_settings`,
  `skip_builder_torch_constraints` and `enable_test_jobs`. Note every
  override from the same file:
  - **Collection-level** (`overrides.<collection>`): list every entry and its
    keys.
  - **Variant-level** (`variant_overrides`): list **every** entry present in
    the file, transcribed exactly (see Key Files) — do not treat the set as fixed.
    Known categories include private-domain overrides (`PULP_DOMAIN: rhai`,
    e.g. the `rhaiis` variants carrying vendor wheels that cannot be publicly
    redistributed, AIPCC-28553), an explicit `CHANNEL`, and cache settings
    (`PULP_CACHE`, `WHEEL_SERVER_PROJECT_PATH`), but the file is the source of
    truth for what actually exists. Precedence:
    `_default -> overrides.<collection> ->
    variant_overrides.<collection>.<variant>`.
- **OMIT_JOBS** -- Explicit exclusions from the matrix with their reasons.
  Only **effective** entries (first element is a collection key, per Key Files)
  justify narrowing an arch set in the tables above: every reduced arch
  annotation must map to an effective entry, and every effective entry must be
  reflected as a reduced arch set in the corresponding row. If a
  previously-omitted combination is no longer listed, it now builds on the full
  base arch set; update the tables accordingly. **List any dead entries
  separately and label them as such** (an entry whose first element is a
  package/product name, not a collection, so `regen-ci.py` never matches it,
  e.g. `docling`, `sdg-hub`). Do not describe a dead entry as a working
  exclusion; where the intended arch skip is actually achieved by a PEP 508
  marker in `requirements*.txt`, say so and cite the marker.
- **Test jobs** -- Which collections have `enable_test_jobs: true`
- **The `rhai` Collection** -- Team ownership structure; list notable team files
  and their contents
- **Onboarding Pipeline** -- How new packages enter (onboarding -> graduation via
  weekly bot -> `rhai` collection)
- **Pipeline Flow** -- Stage list from the root `.gitlab-ci.yml`; trigger types
  (derive them from the `.generated/rhai-*.yml` include rules in the root
  `.gitlab-ci.yml` and the job rules, per "How consumers get the builder" in
  `shared-facts.md`, including which file changes start a push build);
  the `channel-apply` triggers; key checks-stage gates (read the job files
  with `stage: checks`) and the channel linter (`{FONDUE}/builder/test/channel_linter.py`)
- **Pulp Publishing Mechanics** -- Read each step from the publishing code in
  Key Files, not from the README:
  - Upload modes and their precedence; a channel upload targets the channel's
    `-test` repositories in the catalog row's domain and fails if the channel
    is not catalogued.
  - `channel-apply`: what it creates for each catalog row and when it runs.
  - Promotion: the promote plan/apply jobs per built channel and how they pick
    the source and target repositories.
  - Pulp cache: which jobs use the channel `-test` index as their build cache
    (`PULP_CACHE`) and which keep a GitLab wheel server cache.
  - The legacy product-versioned path: the `publish_config.yml` publish job
    and its repository naming convention.
  - Routing: `PULP_DOMAIN` after override precedence for jobs and promote; the
    catalog `domain` for channel uploads. Step 4 of SKILL.md checks they agree.
  - Authentication method, from `src/rhai_pipeline/pulp_config.py`.
  State deletion, copy and promotion scope exactly as the job definitions
  establish (e.g. the `PULP_DOMAIN`/`PRODUCT_NAME` the delete and copy jobs
  set); do not infer beyond them.
- **Package Deletion System** -- Manifest-driven and idempotent. Read which
  upload paths apply the manifests: `pulp upload`
  (`src/rhai_pipeline/pulp_upload.py`) and the build hook's Pulp cache upload
  (`{FONDUE}/builder/package_plugins/hooks/upload_after_build_wheel.py`), and
  state exactly which ones filter; say "enforced at upload time" only if
  every upload path filters. Describe how `pulp delete` resolves
  repositories. Whether deletion covers channel indexes is the deletion check
  in `channels.md`: link overlay 0030 for the result.
- **Version Branching** -- the `pulp copy` CLI (see `src/rhai_pipeline/pulp_copy.py`
  and its job) for EA->GA promotion of product-versioned indexes

**Impact on Strategies section** -- Update to reflect current state. Must include:

- A bullet establishing `rhai-pipeline/` as the authoritative Pulp publish gate
- A bullet on the `rhai-pipeline/` steps to add a new collection, variant or
  torch version (`ci-job-definitions.yml` entries, collection and `torch/`
  overlay files, `make regen`, merging the changes together), linking overlay
  0030 for the cross-component recipe (catalog row, builder torch collection,
  base image)
- A bullet on `ENABLE_REPEATABLE_BUILD_MODE` implications for release branches
- A bullet on how many CUDA versions are maintained and the cost of adding one
  or adding a torch version (count build-wheels jobs in `.generated/rhai-*.yml`;
  each torch version multiplies jobs per collection and arch)
- A bullet on ROCm state (which ROCm channels are built, and their torch pins)
- A bullet on Spyre's IBM-proprietary wheel stack: the vLLM IBM fork (`.spyre`
  suffix, pinned in the torch overlay), sendnn-inference (IBM's inference
  runtime), torch-sendnn (pre-built from private index; record arch markers
  exactly as in source), torch-nnpa (Z only, pre-built from private index),
  ibm-fms (Foundation Model Stack, built from source). The torch pin comes from
  the builder torch collection, per "Torch pin and builder torch collections"
  in `shared-facts.md`. aiu-monitor is not a wheel collection package;
  it ships in the base image instead.
- A bullet on index paths as a stable contract for air-gapped mirroring:
  changing an index path means coordinating all downstream consumers; name
  the channel paths and the legacy product-versioned paths that exist, and
  link overlay 0030 for the URL derivation
- A bullet on the idempotent deletion system (including any upload path that
  skips the manifests) and the onboarding graduation cadence

**ROCm Work Breakdown Patterns** -- Include this subsection to guide downstream
strategy generation. When a strategy involves a ROCm variant update in the
pipeline (e.g., new ROCm version or ROCm package changes), the pipeline-side
work decomposes into these epics:
- Update ROCm channel pins (the torch pin comes from the builder torch
  collection, which must exist first; the vLLM pin from the `torch/` overlay;
  ROCm-specific package versions in `constraints.txt` and the `torch/`
  constraints overlay)
- Add or update ROCm-specific packages in collections (amd-quark, amd-aiter,
  tensorflow-rocm, flash-attn, and any new AMD ecosystem packages)
- Validate build and publish for each ROCm channel (CI pipeline green, wheels
  uploaded to the channel `-test` index, promoted to production)

Strategies referencing ROCm pipeline updates should structure their Technical
Approach around these epics rather than describing the work as prose.

## Report Details

- Product version: old -> new
- Builder resolution or release tag changes
- Built channels added or removed (promote jobs), and channel coverage changes
  per collection
- Collections added/removed
- Variants added/removed from the legacy `publish_config.yml`
- Notable changes to the publishing workflow

## Notes

- The Pulp version HREFs in `publish_config.yml` are long UUIDs -- include only
  the version number portion in the overlay, not the full HREF
- `{PIPELINE}/README.md` is a lower-precedence source than the code. Take
  publishing behavior (authentication, where and when jobs may run) from the
  code and job files, and report README drift per the SKILL.md source
  precedence rule.
