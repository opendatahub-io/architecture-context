---
id: "0030"
title: "AIPCC Content Channels: Torch, Accelerator and OS Wheel Index Streams"
status: active
created: 2026-10-01
affects:
  - platform
release:
  - "3.6"
  - "3.7"
  - "next"
provenance:
  - https://gitlab.com/redhat/rhel-ai/wheels/fondue/-/blob/main/rhai-pipeline/channels.yml
  - https://gitlab.com/redhat/rhel-ai/wheels/fondue/-/blob/main/rhai-pipeline/src/rhai_pipeline/channel.py
  - https://gitlab.com/redhat/rhel-ai/wheels/fondue/-/blob/main/ci-job-definitions.yml
  - https://gitlab.com/redhat/rhel-ai/core/team-docs/-/blob/main/docs/adrs/0225-content-channels-decoupled-from-release-cycles.md
  - https://gitlab.com/redhat/rhel-ai/core/team-docs/-/blob/main/docs/ecosystems/guide-content-channels.md
author: Emilien Macchi
superseded_by: null
---

## Fact

A content channel is the ABI identity of an AIPCC wheel index: the
accelerator and its SDK version, the torch major.minor version and an OS
token. Fondue (`redhat/rhel-ai/wheels/fondue`) builds, uploads and promotes
wheels per channel. Channels cut across `rhai-pipeline/` (catalog, uploads,
promotion; overlay [0020](0020-rhai-pipeline.md)), `builder/` (the torch
collections that pin torch; overlay [0019](0019-wheels-builder.md)) and
`images/base/` (per-torch base images; overlay
[0017](0017-aipcc-base-images.md)).

### What a Channel Is

- **Name:** `{accel}{sdk}-torch{major.minor}-{os}`, e.g. `cpu-torch2.11-el9.8`
  or `cuda13.0-torch2.13-el9.8` (`rhai-pipeline/src/rhai_pipeline/channel.py`,
  ADR0225). The name pattern is
  `^(?P<accelerator>[a-z]+)(?P<accelerator_version>\d+\.\d+)?-torch(?P<torch_version>\d+\.\d+)-(?P<os>[a-z]+[0-9]+(?:\.[0-9]+)?)$`.
- **Torch** is major.minor only (`2.11`, never `2.11.0`).
- **OS token** must match `^[a-z]+[0-9]+(?:\.[0-9]+)?$` (`_OS_RE`): a name
  and major version with an optional minor, so `ubi9`, `el10` and `el9.8` are
  valid. Every catalog row uses `el9.8`.
- **Maturity** (`rolling` by default, or `stable`), `adopted_by` and the
  free-form `labels` are distribution labels, not part of the name or URL.
  `namespace` is not part of the channel name, but when set it prefixes the
  base path, the Pulp repository name and the catalog key
  (`{namespace}/{channel}`, `Channel._names` and `catalog_key`), and it is
  also emitted as a distribution label (see Index URLs).
- **Variant:** a row's `variant` is the builder variant (today
  `{accel}{sdk}-ubi9`, e.g. `cuda12.9-ubi9`), independent of the channel OS
  token. `Channel` derives it as `{accel}{sdk}-{os}` only when the OS has no
  minor, so a row with `os: el9.8` must set it, and it must match the
  channel's accelerator and SDK. `compute_channel` in `bin/regen-ci.py`
  resolves a `rhai_pipeline` (variant, torch) pair to exactly one catalog row
  by `variant` and `torch_version` (`get_channel_for_variant`); it no longer
  builds the name from the variant.

### OS Identity Tokens

The same OS appears under three tokens, each from its own source:

| Token | Where | Source |
|---|---|---|
| `el9.8` | channel names and catalog `os`; base-image conf files and GitLab CI image names (`aipcc-cuda13.0-torch2.13-el9.8-app`) | `rhai-pipeline/channels.yml`; `base_images.variants.*.version` split by `split_base_image_version` in `bin/regen-ci.py` |
| `ubi9` | `rhai_pipeline` and builder variant names, catalog `variant` | variant keys in `ci-job-definitions.yml`; `rhai-pipeline/channels.yml` (`compute_channel` matches on `variant`) |
| `rhel9` | `NAME` build args of the Konflux `base-image-*` pipelines (`rhai/base-image-cuda-13.0-rhel9`, `rhai/base-image-cuda13.0-torch2.14-rhel9`); the Torch Day 0 pipelines use `ubi9` (`torch/cpu-ubi9`) | `.tekton/*-on-push.yaml` |

The RHEL minor appears in the catalog `os` and channel names (`el9.8`), in
catalog `labels.rhel_version` (`9.8`), in
`builder/product-version.yml` and the root `.gitlab-ci.yml`
`BUILDER_PRODUCT_VERSION` (both `0.0-el9.8`) and in the base OS image pins.
OS Pins below lists every file that pins today's OS.

### Catalog

`rhai-pipeline/channels.yml` is the allow-list: a strict model
(`extra="forbid"`) whose identity fields must be quoted strings that match the
name. It has 22 rows. Every row sets `os: "el9.8"`, an explicit builder
`variant`, the labels `architectures`, `python_version: "3.12"` and
`rhel_version: "9.8"`, and an explicit `domain`.
No row sets `namespace`. A row without `domain` gets `DEFAULT_DOMAIN = "rhai"`
(private): the catalog fails closed. **Built** means the channel has a
`promote-plan-<channel>` job in `.generated/rhai-promote-jobs.yml`; **Image**
means a GitLab CI base image conf renders it.

| Channel | Accel / SDK | Torch | OS | Builder variant | Domain | Maturity | `adopted_by` | Built | Image |
|---|---|---|---|---|---|---|---|---|---|
| `cpu-torch2.11-el9.8` | cpu | 2.11 | el9.8 | `cpu-ubi9` | public-rhai | stable | RHOAI-3.5 GA | yes | yes |
| `cuda12.9-torch2.11-el9.8` | cuda 12.9 | 2.11 | el9.8 | `cuda12.9-ubi9` | public-rhai | stable | RHOAI-3.5 GA | yes | yes |
| `cuda13.0-torch2.11-el9.8` | cuda 13.0 | 2.11 | el9.8 | `cuda13.0-ubi9` | public-rhai | stable | RHOAI-3.5 GA | yes | yes |
| `rocm7.14-torch2.11-el9.8` | rocm 7.14 | 2.11 | el9.8 | `rocm7.14-ubi9` | public-rhai | stable | RHOAI-3.5 GA | yes | yes |
| `spyre-torch2.11-el9.8` | spyre | 2.11 | el9.8 | `spyre-ubi9` | public-rhai | stable | RHOAI-3.5 GA | yes | yes |
| `gaudi-torch2.11-el9.8` | gaudi | 2.11 | el9.8 | `gaudi-ubi9` | rhai | rolling | -- | yes | yes |
| `neuron-torch2.9-el9.8` | neuron | 2.9 | el9.8 | `neuron-ubi9` | rhai | rolling | -- | yes | yes |
| `tpu-torch2.10-el9.8` | tpu | 2.10 | el9.8 | `tpu-ubi9` | rhai | rolling | -- | yes | yes |
| `rocm7.14-torch2.12-el9.8` | rocm 7.14 | 2.12 | el9.8 | `rocm7.14-ubi9` | public-rhai | stable | -- | yes | yes |
| `cpu-torch2.13-el9.8` | cpu | 2.13 | el9.8 | `cpu-ubi9` | public-rhai | stable | -- | yes | yes |
| `cuda12.9-torch2.13-el9.8` | cuda 12.9 | 2.13 | el9.8 | `cuda12.9-ubi9` | public-rhai | stable | RHOAI-3.6EA2 | yes | yes |
| `cuda13.0-torch2.13-el9.8` | cuda 13.0 | 2.13 | el9.8 | `cuda13.0-ubi9` | public-rhai | stable | RHOAI-3.6EA2 | yes | yes |
| `rocm7.14-torch2.13-el9.8` | rocm 7.14 | 2.13 | el9.8 | `rocm7.14-ubi9` | public-rhai | stable | -- | no | no |
| `spyre-torch2.13-el9.8` | spyre | 2.13 | el9.8 | `spyre-ubi9` | public-rhai | stable | -- | no | no |
| `cpu-torch2.14-el9.8` | cpu | 2.14 | el9.8 | `cpu-ubi9` | public-rhai | rolling | -- | yes | no |
| `cuda12.9-torch2.14-el9.8` | cuda 12.9 | 2.14 | el9.8 | `cuda12.9-ubi9` | public-rhai | rolling | -- | no | no |
| `cuda13.0-torch2.14-el9.8` | cuda 13.0 | 2.14 | el9.8 | `cuda13.0-ubi9` | public-rhai | rolling | -- | yes | yes |
| `rocm7.14-torch2.14-el9.8` | rocm 7.14 | 2.14 | el9.8 | `rocm7.14-ubi9` | public-rhai | rolling | -- | no | no |
| `cpu-torch2.15-el9.8` | cpu | 2.15 | el9.8 | `cpu-ubi9` | public-rhai | rolling | -- | no | no |
| `cuda12.9-torch2.15-el9.8` | cuda 12.9 | 2.15 | el9.8 | `cuda12.9-ubi9` | public-rhai | rolling | -- | no | no |
| `cuda13.0-torch2.15-el9.8` | cuda 13.0 | 2.15 | el9.8 | `cuda13.0-ubi9` | public-rhai | rolling | -- | no | no |
| `rocm7.14-torch2.15-el9.8` | rocm 7.14 | 2.15 | el9.8 | `rocm7.14-ubi9` | public-rhai | rolling | -- | no | no |

14 rows are built and 8 are catalog-only. Every built channel has a catalog
row. Rubin has no row (`ci-job-definitions.yml` notes that no Rubin channel or
publishing target exists yet).

### Torch Matrix

`ci-job-definitions.yml` `rhai_pipeline.torch_versions` maps each torch
version to the builder collection that pins it; every entry also sets
`default_maturity: rolling`, which only `builder/test/channel_linter.py`
reads.

| Torch | Builder collection | Variants with this torch by default |
|---|---|---|
| 2.9 | `torch-2.9.1` | neuron |
| 2.10 | `torch-2.10.0` | tpu |
| 2.11 | `torch-2.11.0` | cpu, cuda12.9, cuda13.0, gaudi, rocm7.14, spyre |
| 2.12 | `torch-2.12.0` | rocm7.14 |
| 2.13 | `torch-2.13.0` | cpu, cuda12.9, cuda13.0 |
| 2.14 | `torch-2.14.0` | cpu, cuda13.0 |
| 2.15 | none | none (catalog rows only) |

The Catalog table above records which channels are built.

Per-collection overrides narrow the defaults: `ogx` cpu, `rhaiis` cpu and
cuda13.0, and `vllm-deps` cuda12.9 and cuda13.0 build 2.11 and 2.13 only, and
`backfill` adds no channel (overlay 0020).
Overlay 0020 has the per-collection coverage. The builder `torch-2.11.0`
collection also has a `rubin-ubi9` directory that no channel uses.

- **Torch pin:** channel jobs get `BUILDER_TORCH_COLLECTION` from the map, and
  `builder/pipeline-api/prepare_constraints.sh` reads
  `builder/collections/<BUILDER_TORCH_COLLECTION>/<variant>/constraints.txt`
  (its `torch==` line is the channel's torch pin) instead of the
  `constraints-rules.txt` files; the job fails if that file is missing
  (AIPCC-32417).
- **Exception:** for a (collection, variant) in
  `skip_builder_torch_constraints` (`rhaiis`: `neuron-ubi9`, `tpu-ubi9`;
  `torch-deps`: every variant), `BUILDER_TORCH_COLLECTION` is empty and the
  `constraints-rules.txt` files still apply (`rhaiis/tpu-ubi9`:
  `torch-2.10.0 *`; `rhaiis/neuron-ubi9` and `torch-deps` have no active rule,
  and neuron pins `torch==2.9.1` in its torch constraints overlay). Rules files
  on variants that are not skipped (for example `rhai/cpu-ubi9`:
  `torch-2.13.0 *`) are bypassed and are not the torch pin.
- **Per-torch overlays:** torch-linked packages (vLLM, torchvision,
  torchaudio, FlashInfer and similar) live in
  `rhai-pipeline/collections/<collection>/<variant>/torch/requirements-torch-<X.Y>.txt`
  and `constraints-torch-<X.Y>.txt` (48 files), appended after the
  collection's own files for the matching `TORCH_VERSION` (AIPCC-31695). A
  channel whose collection has no overlay gets none of those packages from it.

### Index URLs

- **Base path** (`Channel._names`): `<channel>` for production wheels,
  `<channel>-test` for test wheels, `<channel>-sdists` and
  `<channel>-sdists-test` for sdists, prefixed with `<namespace>/` when a row
  sets `namespace` (none does). The Pulp repository name is the base path with
  `/` replaced by `-`.
- **Host** by domain (`simple_index_url` in `bin/regen-ci.py`,
  `pulp_content_index_url` in `builder/pipeline-api/pulp_content_url.sh`):
  `public-rhai` -> `https://packages.redhat.com/api/pypi/public-rhai/<base path>/simple/`;
  any other domain -> `https://private.console.redhat.com/api/pypi/<domain>/<base path>/simple/`.
- **Examples:** public `https://packages.redhat.com/api/pypi/public-rhai/cuda13.0-torch2.13-el9.8/simple/`
  (test: `.../cuda13.0-torch2.13-el9.8-test/simple/`); private
  `https://private.console.redhat.com/api/pypi/rhai/gaudi-torch2.11-el9.8/simple/`.
- **Distributions:** `pulp channel apply --all` creates four repositories with
  floating distributions per catalog row (`Channel.indexes`), so every catalog
  row's URLs exist whether or not the channel is built. `pulp channel apply`
  only creates or updates (`rhai-pipeline/src/rhai_pipeline/pulp_channel.py`)
  and nothing deletes distributions, so a row removed from `channels.yml`
  keeps its distributions.
- **Content:** uploads go only to a built channel's `-test` repositories, and
  production repositories get content only from `promote-apply-<channel>`
  jobs. A URL that resolves proves only that a distribution exists, not that
  the index has content.

### Lifecycle

1. **Catalog row** in `rhai-pipeline/channels.yml`, with an explicit `domain`.
2. **`channel-apply`:** merging the row to the default branch runs
   `apply-channel-catalog` (`rhai-pipeline/.gitlab/channel-apply-job.yml`),
   which creates the four repositories and distributions in the row's domain.
3. **Matrix entry:** a `rhai_pipeline.torch_versions` entry and builder
   collection `builder/collections/torch-X.Y.Z/<variant>/`, the version in a
   variant's or collection's `torch_versions`, per-torch overlays, then
   `make regen`, which generates the build jobs and the promote jobs and fails
   when a (variant, torch) pair has no catalog row.
4. **Builds and uploads:** `build-wheels` jobs in path-scoped protected-push
   pipelines and nightly pipelines upload to `<channel>-test`; an uncatalogued
   `CHANNEL` override fails at upload. MR `test-*-bootstrap-and-onboard` jobs
   only bootstrap, reading `<channel>-test` as a cache, and upload nothing.
5. **Promote:** a web pipeline with `SCHEDULE_TYPE=wheel-promote` runs
   `promote-plan-<channel>` (content diff, AutoQA, qualification) and the
   manual `promote-apply-<channel>` into the production `<channel>` index.
6. **Image (optional):** a `base_images.variants.*.torch_versions` entry and a
   `images/base/build-args/<key><accel_version>-torch<X.Y><os_version>-app.conf`.

Overlay 0020 describes the upload, promotion and cache mechanics.

### Legacy Product-Versioned Indexes

Every `rhai-pipeline/` collection build job on `main`
(`.generated/rhai-*.yml`) sets `CHANNEL`, so no build on `main` uploads to a
product-versioned index (`rhoai/<PRODUCT_VERSION>/<variant>` or
`rhaiis/<PRODUCT_VERSION>/<variant>`). Builder collection jobs
(`.generated/builder-*.yml`) set `CHANNEL: ''` and are not legacy writers
(overlay [0019](0019-wheels-builder.md) says where they cache).
What still reads or writes the product-versioned indexes on `main`:

- the legacy publish (`publish_config.yml` pins five variants and
  `publish-pulp-repositories` publishes `rhoai/3.6/<variant>`), and
  `update-publish-config-from-test`, which reads the `rhoai-3.6-<variant>-test`
  repositories;
- `pulp copy` and `pulp delete`, which resolve product-versioned repositories
  only;
- the nine accelerator-only base confs (`<key><version>-el9.8-app.conf`),
  built by the nine accelerator-only Konflux base-image pipelines and, for
  Rubin, by GitLab CI and the disabled Rubin channel pipeline (its
  `build-args` pass the non-legacy `INDEX_VARIANT=rubin-torch2.11-el9.8`;
  overlay 0017); those nine pipelines also prefetch from
  `rhoai/3.6/cpu-ubi9-test`;
- the two Torch Day 0 confs and Konflux pipelines, which render the legacy
  torch-versioned indexes `torch-2.14.0-cpu-ubi9` and
  `torch-2.14.0-cuda13.0-ubi9`.

Fondue release branches build and upload to their own product-versioned
indexes; this overlay is generated from `main` and does not cover them.

### Channel Awareness

Results of the channel-awareness checks as of the commit in Context:

- **Konflux:** 14 of the 25 `.tekton/*-on-push.yaml` pipelines pass a
  `CHANNEL` build arg; 13 of them build a catalogued channel's `-torch<X.Y>`
  conf. Four of the 14 have triggers disabled with `&& false`.
  The Rubin pipeline's `CHANNEL` and `INDEX_VARIANT`
  (`rubin-torch2.11-el9.8`) have no catalog row and are not a built channel;
  every other `CHANNEL` is a built channel. The other 11 pipelines render
  legacy indexes: nine product-versioned (accelerator-only confs) and two
  torch-versioned (Torch Day 0). Overlay [0017](0017-aipcc-base-images.md)
  has the per-pipeline tables, including which pipelines are disabled.
  `.tekton/` is generated by PMT from aipcc-product-management-configs.
- **Image channel label:** `compute_base_image_channel_label` builds the
  builder variant with a literal `-ubi9` and, for an image with torch
  versions, resolves it through the catalog (`compute_channel`), so every
  torch image gets its `el9.8` channel label. Rubin, which has no torch
  versions, gets the literal `rubin-ubi9`.
- **Deletion:** `rhai-pipeline/src/rhai_pipeline/pulp_delete.py` resolves
  product-versioned repositories only, and no manifest in
  `rhai-pipeline/package-deletions/` is named after a channel. `pulp upload`
  would skip packages listed in a `<channel>.yaml` manifest, but the build
  hook's Pulp cache upload
  (`builder/package_plugins/hooks/upload_after_build_wheel.py`) does not read
  manifests and uploads to the same `-test` repositories first (overlay
  [0020](0020-rhai-pipeline.md)).
- **Images:** the Catalog table's Image column shows which built channels
  have no base image. Rubin is the only `base_images.variants` entry without
  `torch_versions`; its `rubin-el9.8-app.conf` renders
  `https://packages.redhat.com/api/pypi/public-rhai/rhoai/3.6/rubin-ubi9-test/simple/`.
- **Bootstrap:** `images/base/context/common/index-url.sh` matches channels
  with `^[^-]+-(torch[^-]+-(ubi[[:digit:]]+|el[[:digit:]]+\.[[:digit:]]+))$`
  (`ubi<N>` or `el<N>.<M>` OS tokens) and maps torch 2.9, 2.10 and 2.12 to
  `cpu-torch2.11-<os>`; it runs only in non-hermetic builds. Every built
  accelerator channel resolves to a built CPU channel, and every catalog `os`
  token matches.
- **Catalog vs built:** no built channel lacks a catalog row. A matrix
  (variant, torch) pair without a row fails `make regen`; the three explicit
  `CHANNEL` overrides in `variant_overrides.rhaiis` replace the resolved
  channel after that lookup and are not checked themselves, so an
  uncatalogued override value would fail only at upload.
- **Legacy writers on `main`:** no `rhai-pipeline/` build job
  (`.generated/rhai-*.yml`) uploads without `CHANNEL`.

### Validation

- `builder/test/channel_linter.py` (run by the `linter` CI job through
  `make linter-core`) checks that each `torch_versions` entry names an
  existing builder collection whose name matches the torch version, that
  variant torch lists use defined versions and have arches, that each variant
  x torch combination has a builder collection directory, that torch pins in
  those constraints match the directory, that `default_maturity` is valid,
  that overlay files are named correctly and target a built torch version, and
  that each channel's constraints merge without conflicting `==` pins.
- `rhai-pipeline-unit-tests` loads the catalog with the strict model on MRs
  that touch it and asserts a fixed subset of channels, the three private
  channels in the `rhai` domain, 22 rows, and `os: el9.8` with a `-ubi9`
  builder variant on every row.
- At run time, `pulp upload` rejects uncatalogued channels and
  `prepare_constraints.sh` rejects a missing builder constraints file.
- `make regen`, which the `linter` job runs, resolves every matrix
  (variant, torch) pair to one catalog row, so a matrix channel without a row
  fails the MR; an explicit `CHANNEL` override replaces the resolved channel
  and is not checked itself, so an uncatalogued override value fails only at
  upload. Catalog rows that are not built pass silently, and nothing
  checks that the catalog `domain`, the promote `PULP_DOMAIN` and the base
  conf host agree, that a base conf's `INDEX_VARIANT` is a built channel, or
  that a Konflux `CHANNEL` build arg has a catalog row.

### OS Pins

Tracked files on `main` that pin today's OS in a value, key, code literal or
file name (tokens `ubi9`, `el9`, `el9.8`, `rhel9`, `rhel-9`, `rhel9-8`,
`9.8`). **Scope** says what a second OS stream next to this one needs: *per
variant*, *per image* or *per channel* pins get a parallel entry; *per OS*
pins get a copy for the new OS; a *single value* is shared by every variant
today, so el9 and el10 side by side need a per-variant override or a
restructure.

| Files | What they pin | Scope |
|---|---|---|
| `ci-job-definitions.yml` | variant keys (`<accel>-ubi9`) under `rhai_pipeline` (variants, collections, `variant_overrides`, `skip_builder_torch_constraints`), `builder_pipeline` and `builder_images`; the three private `CHANNEL` overrides (`<channel>-el9.8`); `base_images.variants.*.version` (`-el9.8`); the private `rhaiis-3.6/<accel>-ubi9-x86_64` cache paths | per variant; per channel (`CHANNEL` overrides) |
| `ci-job-definitions.yml` `llvm_triton_images` | `commits[].rhel_versions`: `["9.8"]` on 9 of the 13 entries and `["9.8", "10.2"]` on the 4 Triton 3.7.0, 3.7.1, 3.8.0 and 3.8.0+rhaiv.1 entries (RHAI-5549); each version builds on `ubi<major>/ubi:<version>` and publishes `llvm-{triton,flydsl}-<shortcommit>-ubi<version>` | per RHEL version (list) |
| root `.gitlab-ci.yml` | `BUILDER_PRODUCT_VERSION: "0.0-el9.8"`, which `builder-image-version.yml` turns into the `ci-<VERSION>-` builder image tags; the hand-written `api-test-cpu-ubi9-*` jobs; the `release-notes` `needs` list of `build-image-<variant>-ubi9-<arch>` jobs | single value (`BUILDER_PRODUCT_VERSION`); per variant (jobs) |
| `builder/product-version.yml` | `PRODUCT_VERSION: "0.0-el9.8"`: builder-collection release tags, the builder collections' cache path (overlay 0019) and their push trigger | single value |
| root `Makefile` | the `VARIANTS` list and the `images/builder/Containerfile.%-ubi9` rule (`header-ubi9`, `<v>-ubi9`, `llvm-triton-<v>-ubi9`, `footer-ubi9`) | per variant (list); per OS (rule) |
| `bin/regen-ci.py`, `bin/regen_tekton.py` | `compute_base_image_channel_label` builds its `-ubi9` builder variant; `CPU_ARGS_PATH` reads the legacy Konflux prefetch URL from `cpu-el9.8-app.conf` | single value |
| `renovate.json` | the regex managers and `allowedVersions` (`9.8-*`) for `registry.access.redhat.com/ubi9/ubi` and `registry.redhat.io/rhel9-8-els/rhel` | single value per image |
| `rhai-pipeline/channels.yml` | the channel name and `os` (`el9.8`), `variant` (`<accel><sdk>-ubi9`) and `labels.rhel_version: "9.8"` on every row | per channel |
| collection directories: 34 `rhai-pipeline/collections/<collection>/<variant>-ubi9/`, 19 `builder/collections/<collection>/<variant>-ubi9/` | the variant in the directory name | per variant |
| `rhai-pipeline/src/rhai_pipeline/compare_variants.py` | hardcoded `*-ubi9` variant sets | per variant |
| `rhai-pipeline/supported_versions.yml`, `rhai-pipeline/publish_config.yml` | `<variant>-ubi9` lists of the legacy product-versioned publish | per variant (legacy) |
| `builder/overrides/settings.yaml` and 54 `builder/overrides/settings/*.yaml` | per-variant changelog keys (`cpu-ubi9`, `cuda-ubi9`, ...) and `variants:` keys (for example `spyre-ubi9` in `torch_sendnn.yaml`) | per variant |
| `builder/package_plugins/pyarrow.py` | `ctx.variant == "cuda-ubi9"` gates `ARROW_CUDA` (other plugins match the `cuda` prefix) | per variant |
| `builder/bin/bootstrap.sh`, `builder/bin/build_from_graph.sh` | `cuda-ubi9` / `rocm-ubi9` versioned Containerfile handling; the builder cache prefix (`-0.0-el9.8` in `bootstrap.sh`, still `-0.0-el9.6` in `build_from_graph.sh`) | per variant; single value |
| `builder/pipeline-api/ci-wheelhouse.yml`, `images/builder/gitlab-ci/images.yml` | the `VARIANT` enums (`-ubi9` options) and the `cuda*` / `rocm*` mapping to `Containerfile.cuda-ubi9` / `Containerfile.rocm-ubi9` | per variant |
| `builder/pipeline-api/inputs-validator.yml` | runs on `builder-cpu-ubi9-aarch64` | single value (changes only if the ubi9 builders retire) |
| `images/builder/build-args/common.conf` | `BASE_IMAGE=registry.access.redhat.com/ubi9/ubi:9.8-...` (`cpu-hb.conf` overrides it per variant) | single value |
| 9 `images/builder/build-args/<variant>-ubi9.conf` | the variant in the file name | per variant |
| 18 `images/builder/containerfiles/*-ubi9` fragments (plus `entrypoint-spyre-ubi9.sh`) | `header-ubi9` and `footer-ubi9` for every `-ubi9` image; `<v>-ubi9` and `llvm-triton-<v>-ubi9` per variant; the 8 `llvm-triton-*` fragments COPY `llvm-triton-*-ubi9.8:latest`; `cuda-ubi9` sets `FROMAGER_VARIANT=cuda-ubi9` | per OS (header, footer); per variant |
| `images/builder/container-install/dnf-install-ubi9.sh` | the `buildroot-for-rhel-9-<arch>-rpms` repository | per OS |
| `images/builder/container-install/dnf-install-gaudi.sh` | the `.el9` release suffix of the Habana RPMs it downloads | per OS |
| `images/llvm-triton/gitlab-ci/llvm-triton.yml`, `llvm-flydsl.yml` | `RHEL_VERSION` `options: ["9.8", "10.2"]`; the job image `registry.access.redhat.com/ubi$[[ inputs.RHEL_MAJOR ]]/ubi:${RHEL_VERSION}` and image names `llvm-*-<shortcommit>-ubi${RHEL_VERSION}` (`RHEL_MAJOR` set by `bin/regen-ci.py`) | per RHEL version (list) |
| 7 of the 8 `images/shared/repos/*.repo` files | RHEL 9 repository ids and paths (`rhel-9-for-...`, `rhelai-3.6-for-rhel-9`, `cuda-rhel9`, ROCm `rhel-9.6`) | per OS |
| `images/base/build-args/argfile.conf` | `APP_BASE_IMAGE=registry.redhat.io/rhel9-8-els/rhel:9.8-...`; `make regen` copies it into every conf unless the conf has `# regen-skip: APP_BASE_IMAGE` (none does) | single value |
| 24 `images/base/build-args/*-el9.8-app.conf` | `-el9.8` in the file name, the copied `APP_BASE_IMAGE`, the `INDEX_VARIANT` values (channel confs `-el9.8`, legacy and Torch Day 0 confs `-ubi9`), and some `NAME` values (`rhaibi-cuda13.0-el9.8`) | per image |
| `images/base/Makefile` | `CONF_NAMES`, the `*-torch*-el9.8-app.conf` wildcard and the `container-*-el9.8-app` targets | per image |
| `images/base/containerfiles/app-header` | `io.openshift.tags="rhel9 ..."`, which `make regen` copies into every `Containerfile.*-app` | single value |
| `images/base/redhat-9.8-eus.repo`, `images/base/context/common/repo-config.sh` | the RHEL 9.8 EUS repositories; the `9.8_3.6` RHEL / RHEL AI pair and `rhel-9.6` ROCm repository ids | per OS |
| `images/base/context/common/index-url.sh` | the bootstrap channel regex accepts `ubi<N>` and `el<N>.<M>` OS tokens, the Torch Day 0 regex only `ubi<N>`, and the legacy fallback is `cpu-ubi<major>` (found by the bootstrap check in Channel Awareness; the regexes contain no literal token) | per OS family |
| 9 `images/base/context/<variant>/rpms.in.yaml` with their `rpms.lock.yaml`, and the `neuron` and `rocm` `repo/*.repo` files | the `redhat-9.8-eus.repo` reference, `el9` EVRs and RHEL 9 vendor repository paths | per variant (lockfiles regenerate) |
| `images/base/bin/hermetic-generate-lockfiles.sh` | `BASE_IMAGE` (the `APP_BASE_IMAGE` value), `CDN_REPOS` and `releasever` `9.8` | single value |
| `images/base/bin/list-releases`, `pulp-rocm-create.sh`, `pulp-cuda-update.sh` | `-el9.8` Quay names; `RHEL_VERSION=9.8`; `cuda-rhel-9-*` mirror names | single value (helper scripts) |
| 50 `.tekton/*.yaml` pipelines | `*-el9.8-app.conf` `build-args-file` values, `NAME` build args (`rhel9`; Torch Day 0 `ubi9`), the `cpe` label (`::el9`), the channel pipelines' `CHANNEL`, `INDEX_VARIANT` and `pip-index-url` (`-el9.8`), and the legacy `pip-index-url` (`cpu-ubi9`) | per pipeline; generated by PMT from aipcc-product-management-configs |

`make regen` rewrites `.generated/`, `.gitlab-triggers.yaml`,
`.gitlab-test-jobs.yaml`, `images/builder/Containerfile.*` and the marker
blocks of `images/base/Containerfile.*-app` from the sources above, so they
follow them. Not pins: comments, docstrings, tests, docs,
`images/base/examples/`, `rhai-pipeline/package-deletions/` (historical
manifest names) and `images/base/gitlab-ci/all-variants.yml` (no pipeline
includes it; only a test reads it).

Fondue's own RHEL minor bump rule (`AGENTS.md` "Builder RHEL minor bump",
`.agents/images/builder.md`) names `rhel_versions`, the LLVM `options`, the
`-ubi9.X` LLVM image tags, both product version files, `renovate.json` and
the two cache prefixes; every one is in the table. The rule does not name
`rhai-pipeline/channels.yml`, whose channel names and `os` now carry the RHEL
minor (`el9.8`); `AGENTS.md` also says never to change the RHEL version on a
live, populated Pulp index. The bump rule also orders the work:
LLVM images for the new RHEL version are built and published from `main` in
an earlier MR, before the builder images that COPY them.

## Impact on Strategies

- **A new OS stream (for example RHEL 10, as framed by RHAIRFE-3420) is a new
  channel OS token, not a rebuild of today's channels.** The channel `{os}`
  carries the RHEL minor (`el9.8`; `channel.py` accepts `el<N>.<M>`, and the
  `rhai-pipeline/channels.yml` header gives the identity as
  `{accel}{sdk}-torch{major.minor}-el9.8`), while builder variants carry only
  the major (`-ubi9`, the catalog `variant`). A RHEL minor bump therefore
  renames the catalog rows in place (new `el<N>.<M>` channel names, same
  builder variants), because `compute_channel` resolves each (variant, torch)
  pair to exactly one row (`get_channel_for_variant` in `bin/regen-ci.py`);
  running two RHEL minors side by side, or a new major (RHEL 10), needs a new
  variant per accelerator.
  No catalog row uses a RHEL 10 token yet, so the RHEL 10 token is still to
  be chosen. OS Pins (Fact) lists every Fondue file that pins today's OS.
  Running el9 and el10 side by side multiplies the per-variant pins: new
  catalog rows (`make regen` fails without them), builder
  `torch-X.Y.Z/<variant>/constraints.txt` files (channel jobs fail without
  them), and collection directories with their `torch/` overlays (without
  them a channel ships no vLLM). The single-value pins must become per OS:
  `common.conf` `BASE_IMAGE` and `argfile.conf` `APP_BASE_IMAGE` need a
  per-variant override (`cpu-hb.conf` is the builder precedent; base confs
  would need `# regen-skip: APP_BASE_IMAGE`), and `builder/product-version.yml`
  and `BUILDER_PRODUCT_VERSION` would otherwise label el10 builder images,
  release tags and caches `el9.8`. Fondue's bump rule builds and publishes the
  LLVM images for a new RHEL version in an earlier MR, so the LLVM work comes
  first (four Triton LLVM images are configured to build for RHEL 10.2,
  RHAI-5549).
  `.tekton/` is generated by PMT, so new Konflux pipelines on `main` are a
  change in aipcc-product-management-configs, outside Fondue, and Konflux
  release builds use the `.tekton/` the productization team keeps on
  `release/trailing` (overlay 0017).

  Overlay 0014's note that RHEL 10 needs no rebuild is about worker hosts
  running RHEL 9 containers, not about a RHEL 10 userspace stream.
- **Adding a torch version to an existing accelerator** lands in one change: a
  `rhai-pipeline/channels.yml` row with an explicit `domain` and `variant`; a
  `rhai_pipeline.torch_versions` entry mapping the version to a builder
  collection; `builder/collections/torch-X.Y.Z/<variant>/constraints.txt`; the
  variant's `torch_versions` (or a per-collection override); per-torch
  overlays `rhai-pipeline/collections/<collection>/<variant>/torch/*-torch-X.Y.txt`
  for torch-linked packages; optionally a base image (`torch_versions` under
  `base_images.variants` plus its conf); then `make regen`. Merging the row
  applies it to Pulp, builds upload to the `-test` index, and production needs
  a `wheel-promote` run. Push builds are path-scoped and do not watch the
  catalog or the builder torch collections, so those changes reach the
  channels at the next nightly build.
- **Adding an accelerator** combines the steps above with the component-local
  steps in overlays [0017](0017-aipcc-base-images.md) (Containerfile, context
  and lockfile, confs, `base_images.variants`, Konflux via PMC), [0019](0019-wheels-builder.md) (builder image and
  `VARIANT` enums) and [0020](0020-rhai-pipeline.md) (collections and
  routing).
- **Maturity is a label, not an address.** `maturity` (`rolling` or `stable`)
  and `adopted_by` are Pulp distribution labels and never part of the channel
  name or URL, so marking a channel stable or recording an adopting release
  changes no consumer URL. ADR 0225 makes a channel stable when a product
  release adopts it (validates at its GA and ships on it).
- **Public or private is decided by the catalog `domain`.** A row without
  `domain` is private, so the catalog fails closed. Private channels carry
  non-redistributable vendor wheels, and their base images get a single
  private `index-url` with no public fallback.
- **"Channel" means three different things in this repo.** Content channels
  (this overlay) are wheel index streams keyed by accelerator, torch and OS.
  They are not the KServe and vLLM "fast channel" serving templates (overlays
  [0011](0011-kserve-llm-d-architecture.md) and
  [0014](0014-model-runtimes-team-architecture.md)), and not the earlier
  base-image fast and stable channels (AIPCC-13781, first shipped as
  `3.5-stable`) that ADR 0225 evolves into this model and that
  `images/base/README.md` still describes.
- **A URL that resolves is not an index with content.** `pulp channel apply`
  creates all four distributions for every catalog row and nothing deletes
  them, so catalog-only channels, rows later removed from the catalog and every
  production channel resolve. A live check on 2026-10-01, before AIPCC-32814
  renamed the channels to `-el9.8` (names below as probed),
  found 1560 packages in `public-rhai/cpu-torch2.11-ubi9-test` and 1554 in
  `public-rhai/cuda13.0-torch2.13-ubi9-test`, but none in their production
  indexes (no `wheel-promote` run yet) and none in the catalog-only
  `public-rhai/rocm7.14-torch2.13-ubi9-test`. The legacy
  `public-rhai/rhoai/3.6/cpu-ubi9` index still served 1544 packages. Point
  consumers at a production channel URL only after a promote run. The
  pre-rename `<channel>-ubi9` indexes are no longer catalogued: their
  distributions still resolve and keep their content, but nothing on `main`
  uploads or promotes to them and Fondue has no step that copies channel
  content to the `-el9.8` names, so consumers pinned to a `-ubi9` URL stop
  receiving updates. Build jobs with `PULP_CACHE=true` now read the
  `-el9.8-test` index as their cache.
- **Team docs and Fondue disagree on the URL shape.** Team-docs consumer guides
  (for example
  [guide-content-channels.md](https://gitlab.com/redhat/rhel-ai/core/team-docs/-/blob/main/docs/ecosystems/guide-content-channels.md))
  show `https://packages.redhat.com/api/pypi/public-rhai/rhoai/<channel>/simple/`,
  which returned 404 on 2026-10-01. Fondue catalog rows set no `namespace`, so
  the base path is the bare channel name; the team-docs shape is what
  `namespace: rhoai` would produce. Use the Fondue shape until one side
  changes.
- **Moving consumers from legacy to channel references.** ADR 0225 targets
  channels for RHOAI 3.6 GA, which builds from Fondue `main`. At Fondue
  `18d0c049d` (2026-10-01), consumers were still on legacy references: no
  release tag contained the channel code yet and no production channel index
  had content. Team docs
  keep legacy product-versioned index and image references available through
  RHOAI 3.6 GA and use channel references starting with RHOAI 3.7 EA. Fondue release
  branches (for example `3.6-EA2`) still build their own product-versioned
  indexes; this overlay covers `main` only. Production base images are planned
  as `registry.redhat.io/rhai/base-image-<accel><sdk>-torch<X.Y>-rhel9`, which
  matches the `NAME` build arg of the Konflux channel pipelines
  (`.tekton/base-image-*-torch*-on-push.yaml`, overlay 0017); `rhel9` is a
  third OS token next to `el9.8` (channels, confs and GitLab CI images) and
  `ubi9` (builder variants).

## Context

Fondue moved its wheel indexes from product-versioned paths
(`rhoai/<version>/<variant>`) to content channels on `main` on 2026-10-01
(ADR 0225, RFD AIPCC-27889). Channels cut across `rhai-pipeline/`, `builder/`
and `images/base/`, and overlays 0017, 0019 and 0020 are each rewritten
independently, so three partial descriptions would drift. This overlay is the
single owner of channel identity, the catalog, URL derivation, the torch to
builder collection map, the legacy index relationship and the cross-component
recipes; the other Fondue overlays keep their component mechanics and link
here. It also gives RFE authors one entry point for questions such as where a
new torch version or OS stream lands.

The release labels include `3.6` because ADR 0225 targets channels for RHOAI
3.6 GA (built from `main`), `3.7` because team docs make channel references
the default from RHOAI 3.7 EA, and `next` because channels are decoupled from
product releases.

Maintained with the `update-fondue-overlays` skill (`channels` target), which
regenerates the Fact section from Fondue `main`; last refreshed 2026-10-07
from Fondue `main` (`d57f272`).
