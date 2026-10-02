# Content Channels Overlay (0030)

Rules for refreshing `overlays/0030-aipcc-content-channels.md` from the Fondue
monorepo. Paths in this file are relative to `{FONDUE}`.

## Overview

A content channel is the ABI identity of a wheel index: accelerator and SDK,
torch major.minor and OS token, with maturity as a label. Channels cut across
`rhai-pipeline/` (catalog, uploads, promotion), `builder/` (torch collections)
and `images/base/` (per-torch images). This overlay is the single owner of the
channel facts marked bold for 0030 in `shared-facts.md`: identity and
the OS token rule, the catalog, URL derivation, the torch to builder
collection map, the relationship with legacy product-versioned indexes, the
channel-awareness results, the OS pin list and the cross-component recipes.
Overlays 0017, 0019 and 0020 keep their
component mechanics and link here. When the catalog, a `torch_versions`
entry, the channel code or the URL code changes, refresh the overlay.

## Key Files

**Catalog and identity:**
- `rhai-pipeline/channels.yml` -> every catalog row: `channel`, `accelerator`,
  `accelerator_version`, `torch_version`, `os`, `domain`, `maturity`,
  `adopted_by`, `namespace`, `labels`. Read the comments for rationale only.
- `rhai-pipeline/src/rhai_pipeline/channel.py` -> the module docstring (what a
  channel is), the name and OS token patterns, `DEFAULT_DOMAIN` (the domain of
  a row without `domain`), the `Channel` model defaults, `Channel._names`
  (repository names and base paths), `Channel.indexes` (distributions per
  row) and `Channel.distribution_labels` (Pulp labels).

**Built channels and the torch matrix:**
- `ci-job-definitions.yml` -> `rhai_pipeline.torch_versions` (torch version to
  `builder_collection`, plus any other keys and what reads them),
  `rhai_pipeline.variants.<v>.torch_versions`,
  `rhai_pipeline.collections.<c>.torch_versions.<v>`,
  `skip_builder_torch_constraints`, and `base_images.variants.*.torch_versions`
  (the separate image matrix).
- `bin/regen-ci.py` -> `compute_channel` (channel from variant and torch),
  `collect_promote_indexes` (built channels), `simple_index_url` (host by
  domain), `split_base_image_version` and `compute_base_image_channel_label`
  (image side).
- `.generated/rhai-promote-jobs.yml` -> the built channels (grep
  `promote-plan-` and each job's `PULP_DOMAIN` and `INDEX_URL`).
- `.generated/rhai-*.yml` -> grep `CHANNEL:` for which collections build each
  channel.
- `builder/pipeline-api/prepare_constraints.sh` -> where the torch pin comes
  from in channel mode, and the `skip_builder_torch_constraints` exception.
- `builder/test/channel_linter.py` -> the docstring lists what Fondue itself
  validates about channels.

**URLs and Pulp:**
- `builder/pipeline-api/pulp_content_url.sh` -> `pulp_content_index_url`
  (host by domain) and how build jobs pick the cache index.
- `rhai-pipeline/src/rhai_pipeline/pulp_channel.py` and
  `rhai-pipeline/.gitlab/channel-apply-job.yml` -> what `pulp channel apply`
  creates and when it runs.
- `rhai-pipeline/src/rhai_pipeline/pulp_upload.py` and
  `rhai-pipeline/bin/upload_to_pulp.sh` -> where channel uploads go and the
  upload mode precedence.

**Releases:**
- `rhai-pipeline/supported_versions.yml` -> the version whose `release_branch`
  is `main` (the SKILL.md release label rule).

**Channel-awareness checks.** These states change often. This list is their
only definition; the other references describe the mechanics and link here.
Run each check, record the result for the "Channel-awareness states" row in
`shared-facts.md`, state it as of the commit in the Fact, and report it;
never copy a result into this file:
- **Konflux:** whether any `.tekton/*-on-push.yaml` `build-args-file` names a
  `-torch` conf, and which index each Konflux conf renders (see "Konflux
  base-image pipelines" in `shared-facts.md`).
- **Image channel label:** whether `compute_base_image_channel_label` takes the
  OS token from the catalog or hardcodes it.
- **Deletion:** whether `rhai-pipeline/src/rhai_pipeline/pulp_delete.py` and
  `rhai-pipeline/package-deletions/` handle channel indexes, and which upload
  paths read the manifests: `pulp upload`
  (`rhai-pipeline/src/rhai_pipeline/pulp_upload.py`) and the build hook's
  Pulp cache upload
  (`builder/package_plugins/hooks/upload_after_build_wheel.py`).
- **Images:** built channels without a base image, and `base_images.variants`
  entries without `torch_versions` (their conf, and the index it renders).
- **Bootstrap:** the fallback `case` list and the channel regex in
  `images/base/context/common/index-url.sh`, against the built channels and
  the catalog `os` tokens.
- **Catalog vs built:** built channels without a catalog row (their uploads
  fail), or "none". Catalog rows that are not built already show in the
  Catalog table; do not list them again.
- **Legacy writers on `main`:** build jobs in `.generated/rhai-*.yml` that
  upload without `CHANNEL`. Builder collection jobs
  (`.generated/builder-*.yml`) set `CHANNEL: ''` and cache under
  `builder-cache/` (overlay 0019): they are not legacy writers, so scope the
  result to `rhai-pipeline/` jobs.

**Lower-precedence sources:** `rhai-pipeline/README.md`, `images/base/README.md`
and conf comments. Read them only to report drift against the code.

## Overlay Content

Release labels follow the SKILL.md Overlay Rules.

**Fact section** -- Replace entirely with fresh content derived from the files
above. Use `###` subsections. This section must cover:

- **What a channel is** -- the identity format, that torch is major.minor,
  that maturity, `adopted_by` and `labels` are labels and not part of the
  name or URL, that `namespace`, when set, prefixes the base path, repository
  name and catalog key (`Channel._names`, `catalog_key`), and the OS token
  pattern (one token; quote the pattern from `channel.py`)
- **OS identity tokens** -- the channel token, the conf and GitLab CI image
  token, and the Konflux image name, each with its source (see "OS identity
  tokens" in `shared-facts.md`)
- **Catalog** -- one table row per catalog row: channel, accelerator and SDK,
  torch, OS, domain, maturity, `adopted_by`, built (has a promote job) and
  image (has a base conf). This table owns built status; other overlays
  state it only where their own mechanics need it. State whether any row
  sets `namespace` and what a row without `domain` gets.
- **Torch matrix** -- the torch version to builder collection map and the
  variants that build each torch version by default
  (`rhai_pipeline.variants.<v>.torch_versions`; 0030 owns these lists); which
  collections narrow them (summarize, and link overlay 0020 for
  per-collection coverage); the torch pin rule and its
  `skip_builder_torch_constraints` exception; the per-torch overlay rule. Do
  not add a built-channels column
- **Index URLs** -- the base path and host derivation, with one rendered
  public and one rendered private example built from catalog rows; the four
  distributions per catalog row; that uploads reach only a built channel's
  `-test` index and production indexes get content only from promote jobs;
  that `pulp channel apply` never deletes a distribution, so a resolving URL
  proves only that a distribution exists, not content
- **Lifecycle** -- the order of operations from catalog row to production
  index (catalog row, `channel-apply`, matrix entry, builds and uploads,
  promote), naming the file or job for each step and linking overlay 0020 for
  the mechanics. Only `build-wheels` jobs upload; MR
  `test-*-bootstrap-and-onboard` jobs only bootstrap
- **Legacy product-versioned indexes** -- whether any `rhai-pipeline/` build
  job on `main` still writes one (builder collection jobs cache under
  `builder-cache/` instead, overlay 0019),
  what still reads or writes them (legacy publish, copy and delete jobs; base
  confs and Konflux pipelines that render a product path), and that Fondue
  release branches build their own product-versioned indexes but are out of
  scope here because this overlay is generated from `main`
- **Channel awareness** -- the result of every channel-awareness check in Key
  Files, as of the commit
- **Validation** -- what `channel_linter.py` and the CI checks validate, and
  which Step 4 consistency checks of SKILL.md have no Fondue-side check
- **OS Pins** -- a table (files, what they pin, scope) built each run:
  - Scope: tracked files only (`git -C {FONDUE} grep` and `git ls-files`) at
    the overlay's commit, across the whole tree. Search contents for the
    current OS tokens (`ubi9`, `el9`, `el9.8`, `rhel9`, `rhel-9`, `rhel9-8`,
    and `9.8` as a whole version) and `git ls-files` paths for the same tokens
    (variant directories, conf and fragment names). The root `.gitlab-ci.yml`
    (`BUILDER_PRODUCT_VERSION`), `renovate.json`, `images/llvm-triton/` and
    `llvm_triton_images` in `ci-job-definitions.yml` are in scope. Derive the
    tokens from the OS identity tokens and catalog `labels`, not from this
    list, when the OS changes.
  - A pin is a token in a value, key, code literal or file or directory name.
    Skip comments, docstrings, tests (`*/test/`, `*/tests/`), docs (`*.md`),
    `.agents/`, `.claude/`, symlinks and files nothing includes. List the
    files that `make regen` rewrites (`.generated/`, `.gitlab-triggers.yaml`,
    `.gitlab-test-jobs.yaml`, `images/builder/Containerfile.*`) in one line
    as generated, and `.tekton/` as generated by PMT.
  - Group by directory and give counts from the command for families (for
    example the `variants:` keys in N `builder/overrides/settings/*.yaml`
    files); name every other file with what it pins. Re-derive every count.
  - Give each row a scope: per variant, per image or per channel (a second OS
    adds a parallel entry), per OS (copied for the new OS), or single value
    (shared by every variant today, so two OS streams need a per-variant
    override or a restructure).
  - Cross-check with Fondue's RHEL bump guidance (`AGENTS.md` "Builder RHEL
    minor bump" and `.agents/images/builder.md`): state that every file it
    names is in the table, or report the ones that are not, and state its
    ordering constraints.

**Impact on Strategies section** -- Update to reflect current state. Must include:

- A bullet on what adding a torch version to an existing accelerator requires,
  as file-level steps derived from current source (catalog row with an
  explicit `domain`, `rhai_pipeline.torch_versions` mapping, builder torch
  collection directory per variant, variant or collection `torch_versions`,
  per-torch overlays, base image `torch_versions` and conf, `make regen`)
- A bullet on what adding an accelerator requires across components, linking
  the component-local steps in overlays 0017, 0019 and 0020
- A bullet on a new OS stream: a new OS is a new channel OS token and a new
  variant per accelerator. Keep it to rationale and link the OS Pins Fact
  subsection rather than listing files: which pins multiply per variant, which
  single-value pins must become per OS, Fondue's ordering constraints, and
  that `.tekton/` changes go through the PMC configuration, not `.tekton`
  edits.
- A bullet on maturity and `adopted_by`: labels on the distributions, not part
  of the name or URL
- A bullet on public vs private channels: the catalog `domain` decides, an
  omitted domain is private, and a private channel's images get no public
  fallback
- A bullet disambiguating "channel": content channels here are not the KServe
  and vLLM "fast channel" templates (overlays 0011, 0014) or the base-image
  fast and stable channels that `images/base/README.md` describes
- A bullet that a resolving index URL proves only that a distribution exists
  (catalog rows removed later keep theirs), not content, and that production
  channel indexes stay empty until a promote run
- A bullet on how consumers move from legacy product-versioned references to
  channel references; keep the human-authored cut-over details and links

## Report Details

- Catalog rows added or removed; maturity, `adopted_by`, `domain` or
  `namespace` changes
- Built channels added or removed; catalog rows that are not built
- Torch to builder collection map changes
- Channel-awareness check results, as of the commit
- OS pins added or removed, and any file Fondue's RHEL bump guidance names
  that the table lacks
- Drift between Fondue READMEs or conf comments and the code

## Notes

- Fact content comes from Fondue `main` only. Team docs, live index checks and
  unmerged branches may appear only in human-authored Impact on Strategies or
  Context bullets, and the skill never adds them.
- Never put index probe results (status codes, link counts) in this file or in
  a Fact.
- The overlay must not repeat 0020's per-collection coverage tables or 0017's
  per-image tables; link them.
