---
id: "0020"
title: RHAI Pipeline — Wheel Package Index
status: active
created: 2026-07-15
affects:
  - platform
release:
  - "3.6"
  - "3.7"
  - "next"
provenance:
  - https://gitlab.com/redhat/rhel-ai/wheels/fondue/-/tree/main/rhai-pipeline
author: Lance Barto
superseded_by: null
---

## Fact

`rhai-pipeline/` in the Fondue monorepo (`redhat/rhel-ai/wheels/fondue`) is the
**package index management system** for all Red Hat AI (RHAI) products. It does
not compile wheels: compilation is delegated to the in-tree builder (`builder/`,
`images/builder/`; overlay [0019](0019-wheels-builder.md)), which provides
global constraints, security constraints, the per-torch builder collections
that pin torch, and variant-specific build requirements. Collection constraint
files must not conflict with the builder's constraints. `rhai-pipeline/`
declares which packages to build per collection x variant x torch version x
architecture, uploads them to content channel indexes in Pulp, and promotes
approved wheels to the customer-facing production indexes. The authoritative
CI matrix (collections, variants, torch versions, arches, Pulp routing) is
`ci-job-definitions.yml` at the **monorepo root**. Channel identity, the
catalog and index URLs are described in overlay
[0030](0030-aipcc-content-channels.md).

The `rhaiis` collection below (`rhai-pipeline/collections/rhaiis/`) is not the
separate `rhaiis/pipeline` repository, which lives outside Fondue (overlay
[0021](0021-rhaiis-pipeline.md)). Both `rhai-pipeline/collections/rhaiis/` and
the `rhaiis/pipeline` repository build vLLM for overlapping variants with
independent pins; check overlay 0021 before citing a RHAIIS vLLM version.

- **Product name:** `rhoai` (default `PRODUCT_NAME`; the private `rhaiis`
  variants set `rhaiis`). In channel mode the catalog row, not the product
  name, selects the upload repository.
- **Product version:** `3.6` (`rhai-pipeline/product-version.yml`; the base
  images' `INDEX_VERSION` is also `3.6`). It no longer selects a channel index
  path. It still drives the release tags (`rhai-3.6.<IID>+...`,
  `RELEASE_VERSION_PREFIX`), the `product_name`/`product_version` labels on
  uploaded packages, the legacy `publish_config.yml` publish
  (`publish-pulp-repositories`), `update-publish-config-from-test` (its default
  version and target branch), the legacy
  `rhoai/<PRODUCT_VERSION>/<variant>-test` URL that
  `trigger-autoqa-verification` tests, and the push `changes:` trigger on the
  product version file. The private `rhaiis` Gaudi, Neuron and TPU GitLab
  caches (`rhaiis-3.6/<variant>-x86_64`) are hardcoded in
  `variant_overrides` (RHAI-2725) and do not follow it; `pulp copy` takes
  `SOURCE_VERSION`/`DEST_VERSION` and `pulp delete` takes its versions from
  the manifest names. `supported_versions.yml` is maintained by hand: `3.6`
  maps to `release_branch: main`, and a version bump needs a matching entry
  there (no CI job checks it).
- **Base OS version:** RHEL **9.8** (`builder/product-version.yml`
  `PRODUCT_VERSION: "0.0-el9.8"`, the OS the builder targets, not a builder release)
- **Builder:** the in-tree builder, not a release tag. `builder-image-version.yml`
  (included last by the root `.gitlab-ci.yml`) sets `BUILDER_IMAGE_VERSION` to
  `ci-${BUILDER_PRODUCT_VERSION}-${CI_MERGE_REQUEST_IID}`, so MR pipelines use
  that MR's builder images and non-MR pipelines use the branch's
  `ci-0.0-el9.8-` images. For context, `releases/builder-release.yaml` declares
  Fondue builder release `v47.1.0` on `main`; `rhai-pipeline/` does not pin it.
  `rhaiis/pipeline` pins a Fondue release ref (overlay 0021).
- **Pulp domain (default):** `public-rhai` (`overrides._default`); channel
  uploads use the catalog row's `domain`.

### Channel Coverage

One row per built channel: a `promote-plan-<channel>` job in
`.generated/rhai-promote-jobs.yml` (14 indexes), generated from the CI matrix.
Arch sets are effective (base arches minus effective `omit_jobs`). The torch
pin is the `torch==` line of the builder torch collection the channel's jobs
read (`builder/collections/torch-X.Y.Z/<variant>/constraints.txt`), except
where noted. vLLM and other torch-linked pins come from the collection's
`torch/requirements-torch-<X.Y>.txt` and `constraints-torch-<X.Y>.txt`
overlays. Catalogued channels that are not built are listed in overlay 0030.

| Channel | Collections (effective arches) | Torch | vLLM (`rhaiis`) and other release-defining pins |
|---|---|---|---|
| `cpu-torch2.11-el9.8` | `rhai`, `onboarding`, `rhai-innovation`, `rhaiis`, `torch-deps` (all 4 arches); `ogx` (aarch64, ppc64le, x86_64) | 2.11.0 | `vllm 0.26.0+rhaiv.1` (NeuralMagic; x86_64 adds the `zen` extra) |
| `cpu-torch2.13-el9.8` | same as `cpu-torch2.11-el9.8`, plus `backfill` (all 4 arches) | 2.13.0 | `vllm 0.28.0+rhaiv.3` (x86_64 adds `zen`) |
| `cpu-torch2.14-el9.8` | `rhai`, `onboarding`, `rhai-innovation`, `torch-deps` (all 4 arches) | 2.14.0 | none (`rhaiis` and `ogx` stop at 2.13) |
| `cuda12.9-torch2.11-el9.8` | `rhai`, `onboarding`, `rhai-innovation`, `torch-deps`, `vllm-deps` (aarch64, x86_64) | 2.11.0 | none (not in `rhaiis`); `vllm-deps` `flashinfer-python==0.6.14`; builder `deep-ep==2.0.1+rhaiv.2` |
| `cuda12.9-torch2.13-el9.8` | same as `cuda12.9-torch2.11-el9.8`, plus `backfill` | 2.13.0 | none (not in `rhaiis`); `vllm-deps` `transformers>=5.10.4`, `tilelang==0.1.12`; builder `deep-ep==2.0.1+rhaiv.2` |
| `cuda13.0-torch2.11-el9.8` | `model-opt`, `rhai`, `onboarding`, `rhai-innovation`, `rhaiis`, `torch-deps`, `vllm-deps` (aarch64, x86_64) | 2.11.0 | `vllm 0.26.0+rhaiv.5`; `nixl==1.3.1`; builder `flashinfer-python==0.6.14`, `deep-ep==2.0.1+rhaiv.2` |
| `cuda13.0-torch2.13-el9.8` | same as `cuda13.0-torch2.11-el9.8`, plus `backfill` | 2.13.0 | `vllm 0.28.0+rhaiv.3`; `flashinfer-*==0.6.16.post3`; `nixl==1.3.2`; builder `deep-ep==2.0.1+rhaiv.2` |
| `cuda13.0-torch2.14-el9.8` | `model-opt`, `rhai`, `onboarding`, `rhai-innovation`, `torch-deps` (aarch64, x86_64) | 2.14.0 | none (`rhaiis` excluded until a vLLM release adopts torch 2.14, RHAI-3616) |
| `gaudi-torch2.11-el9.8` | `rhaiis` (x86_64) | 2.11.0 | `vllm 0.26.0+rhaiv.8`, `vllm-gaudi 0.26.0` |
| `neuron-torch2.9-el9.8` | `rhaiis` (x86_64) | 2.9.1 (from `rhaiis/neuron-ubi9/torch/constraints-torch-2.9.txt`; builder torch constraints skipped and the rules file has no active rule) | `vllm 0.16.0+rhaiv.13`, `vllm-neuron 0.5.3`, `torch-neuronx 2.9.0.2.15.32035+de43f57c` |
| `rocm7.14-torch2.11-el9.8` | `rhai`, `onboarding`, `rhai-innovation`, `rhaiis`, `torch-deps` (x86_64) | 2.11.0 | `vllm 0.26.0+rhaiv.5`; builder `amd-aiter==0.1.16.post3` |
| `rocm7.14-torch2.12-el9.8` | same as `rocm7.14-torch2.11-el9.8`, plus `backfill` | 2.12.0 | `vllm 0.28.0+rhaiv.3`; builder `amd-aiter==0.1.19` |
| `spyre-torch2.11-el9.8` | `rhai`, `onboarding`, `rhaiis`, `backfill` (ppc64le, s390x, x86_64) | 2.11.0 | `vllm[tensorizer] 0.27.1+rhaiv.4.spyre` (IBM fork, RHAI-688); IBM stack below |
| `tpu-torch2.10-el9.8` | `rhaiis` (x86_64) | 2.10.0 (builder constraints skipped; `rhaiis/tpu-ubi9/constraints-rules.txt` `torch-2.10.0 *` selects the builder `torch-2.10.0` constraints) | `vllm[tensorizer] 0.27.1+rhaiv.4.tpu` (AIPCC-31840; the builder `torch-2.10.0` collection pins `vllm==0.27.1`) |

`torch-deps` sets `skip_builder_torch_constraints: true` and its collection
rules file has no active rule, so its jobs get no builder constraints and no
torch pin. vLLM `+rhaiv` tags indicate the NeuralMagic enterprise fork; `.spyre`
indicates the IBM fork; `.tpu` is reported as written (source cites
AIPCC-31840 only). Other per-channel pins: `vllm-bart-plugin==0.6.0` on CUDA
13.0 `rhaiis`; `vllm-beam-search-plugin==0.1.4` on `rhaiis` CUDA 13.0 torch
2.13. ROCm 7.1 is retired; only ROCm 7.14 remains. `backfill` adds no
channels and defines no release pins: it rebuilds historical `rhoai/3.6`
pins, several versions of a package per channel (for example `torch-sendnn`
`1.2.3+0`, `1.2.5+0` and `1.3.0+0` in its Spyre torch 2.11 overlay), into
channels other collections already build. Its versions can be newer than a
release-defining pin on the same channel (for example `nixl` 1.4.0 next to the
`rhaiis` `nixl==1.3.2` on `cuda13.0-torch2.13-el9.8`), so consumers of the
`-test` index must pin.

**Spyre IBM stack** (`collections/rhaiis/spyre-ubi9/requirements.txt` and its
torch 2.11 overlay): `sendnn-inference==2.6.1`, `torch-sendnn==1.3.1` (no arch
marker), `torch-nnpa==1.5.0` (s390x only), `ibm-fms==1.13.1` plus unpinned
`ibm-fms` (AIPCC-27741), `spyremetrics==0.5.0` and `ibm-aiu-smi==1.3.0` (no
arch marker; AIPCC-28704, AIPCC-28706, INFERENG-9813), and
`torchao==0.11.0` in the torch constraints overlay.

### Collections and Variant Coverage

`make regen` (monorepo-root `bin/regen-ci.py`) generates
`.generated/rhai-<collection>.yml` from `ci-job-definitions.yml`, the
authoritative source for collection names, variant lists, torch versions, base
arch sets, `omit_jobs`, Pulp routing and optional keys.

**Torch versions are a matrix dimension at three levels:**
`rhai_pipeline.torch_versions` (torch version -> builder collection; overlay
0030 owns the map), `rhai_pipeline.variants.<variant>.torch_versions` (the
default list per variant), and `collections.<c>.torch_versions.<variant>`
(a per-collection override). Each (collection, variant, torch) combination is
one channel, and `regen-ci.py` names its jobs
`<collection>-<channel>-<arch>-*`. `collections.<c>.torch_version_settings.<X.Y>`
sets `enable_multi_version_bootstrap`, `max_release_age` or `PULP_CACHE` for one
torch version, and `skip_builder_torch_constraints` (a variant list, or `true`)
drops the builder torch collection constraints for those variants.

**Arch coverage is computed:** effective arches = `rhai_pipeline.variants.<variant>.arches`
minus every `omit_jobs` entry `[<collection>, <variant>, <arch>]` or
`[<collection>, <variant>, <torch>, <arch>]` whose first element is a
collection key. Base arch sets: cpu-ubi9 = aarch64, ppc64le, s390x, x86_64;
cuda12.9-ubi9 and cuda13.0-ubi9 = aarch64, x86_64; spyre-ubi9 = ppc64le,
s390x, x86_64; gaudi, neuron, rocm7.14, tpu = x86_64. The per-variant
default torch versions are in overlay [0030](0030-aipcc-content-channels.md)
(Torch Matrix); the table below shows what each collection builds.

| Collection | Purpose | Variants: torch (effective arches) | Settings |
|---|---|---|---|
| `onboarding` | Intake staging area; test builds before graduation | cpu: 2.11, 2.13, 2.14 (all 4 arches); cuda12.9: 2.11, 2.13; cuda13.0: 2.11, 2.13, 2.14; rocm7.14: 2.11, 2.12; spyre: 2.11 | `enable_test_jobs`; torch 2.13: multi-version bootstrap, 10 days, `PULP_CACHE: "true"` |
| `rhai` | Primary production packages, organized by owning team | same as `onboarding` | torch 2.13: multi-version bootstrap, 10 days, `PULP_CACHE: "true"` |
| `rhai-innovation` | RHAI Innovation composite: `docling`, `its-hub`, `sdg-hub`, `training-hub` (README also lists universal-training) | cpu: 2.11, 2.13, 2.14 (all 4 arches); cuda12.9: 2.11, 2.13; cuda13.0: 2.11, 2.13, 2.14; rocm7.14: 2.11, 2.12 | torch 2.13: multi-version bootstrap, 10 days, `PULP_CACHE: "true"` |
| `rhaiis` | Red Hat AI Inference Server (vLLM) | cpu: 2.11, 2.13 (all 4 arches); cuda13.0: 2.11, 2.13 (RHAI-3616); gaudi: 2.11; neuron: 2.9; rocm7.14: 2.11, 2.12; spyre: 2.11; tpu: 2.10 | `skip_builder_torch_constraints: [neuron-ubi9, tpu-ubi9]`; torch 2.13: multi-version bootstrap, 10 days; private variants via `variant_overrides` |
| `model-opt` | Model Optimization (CUDA 13 only) | cuda13.0: 2.11, 2.13, 2.14 (aarch64, x86_64) | torch 2.13: multi-version bootstrap, 10 days, `PULP_CACHE: "true"` |
| `torch-deps` | PyTorch team exact-pin dependencies matching upstream PyTorch CI | cpu: 2.11, 2.13, 2.14 (all 4 arches); cuda12.9: 2.11, 2.13; cuda13.0: 2.11, 2.13, 2.14; rocm7.14: 2.11, 2.12 | `skip_builder_torch_constraints: true`; torch 2.13: multi-version bootstrap, 10 days, `PULP_CACHE: "true"` |
| `ogx` | OGX / Llama Stack inference framework | cpu: 2.11, 2.13 (aarch64, ppc64le, x86_64; s390x removed by an effective `omit_jobs` entry) | `enable_test_jobs`; torch 2.13: multi-version bootstrap, 10 days |
| `vllm-deps` | vLLM build dependencies on the public CUDA torch channels (AIPCC-12506; per-torch sets in `torch/` overlays, AIPCC-31695) | cuda12.9: 2.11, 2.13; cuda13.0: 2.11, 2.13 (aarch64, x86_64) | `enable_multi_version_bootstrap`, `max_release_age` 10 days (AIPCC-17844) |
| `backfill` | Temporary rebuild of `rhoai/3.6` pins missing from the mapped channel `-test` indexes, to be deleted once that diff is empty (AIPCC-32962); see Channel Coverage | cpu: 2.13 (all 4 arches); cuda12.9: 2.13; cuda13.0: 2.13 (aarch64, x86_64); rocm7.14: 2.12; spyre: 2.11 | `enable_test_jobs: false` (the scheduled pipeline builds it after merge) |

`enable_post_merge_jobs` is `true` by default (and set on `ogx`), so every
collection's jobs load in protected-push pipelines. Test jobs
(`enable_test_jobs: true`) run for `onboarding` and `ogx`.

**Overrides** (precedence `overrides._default -> overrides.<collection> ->
variant_overrides.<collection>.<variant>`, then per-torch `PULP_CACHE`):

- `overrides._default`: `PULP_DOMAIN: public-rhai`, `PULP_CACHE: "true"`,
  `PUBLISH_WHEEL_RELEASES: "true"`, `GITLAB_PRIVATE_TOKEN`.
- `overrides.ogx`: `PULP_CACHE: "true"`.
- `overrides.vllm-deps`: `PULP_DOMAIN: public-rhai`, `PULP_CACHE: "true"`
  (AIPCC-12506).
- `variant_overrides.rhaiis` `cpu-ubi9`, `cuda13.0-ubi9`, `rocm7.14-ubi9`,
  `spyre-ubi9`: `PULP_CACHE: "true"` (RHAI-3382).
- `variant_overrides.rhaiis` `gaudi-ubi9`, `neuron-ubi9`, `tpu-ubi9`:
  `PRODUCT_NAME: rhaiis`, `PULP_DOMAIN: rhai`, `PULP_CACHE: "false"`, an
  explicit `CHANNEL` (`gaudi-torch2.11-el9.8`, `neuron-torch2.9-el9.8`,
  `tpu-torch2.10-el9.8`; AIPCC-32667, AIPCC-32633) and
  `WHEEL_SERVER_PROJECT_PATH: redhat/rhel-ai/rhai/indexes/rhaiis-3.6/<variant>-x86_64`
  (RHAI-2725). Vendor wheels that cannot be publicly redistributed
  (AIPCC-28553).

**`OMIT_JOBS`:** an entry is only effective if its **first element is a
collection key**; `regen-ci.py` skips a job only when `(collection, variant,
arch)` or `(collection, variant, torch, arch)` matches, so an entry naming a
*package* matches nothing and is **dead**.

| `omit_jobs` entry | Status | Notes |
|---|---|---|
| `[ogx, cpu-ubi9, s390x]` | **Effective** | Narrows `ogx`/cpu to (aarch64, ppc64le, x86_64) for both torch versions; no s390x index for this collection. |
| `[docling, cpu-ubi9, s390x]` | **Dead** | `docling` is a package. The real s390x skip is the PEP 508 marker `docling ; platform_machine != 's390x'` in `collections/rhai-innovation/cpu-ubi9/requirements.txt` (AIPCC-8297). |
| `[sdg-hub, cpu-ubi9, s390x]` | **Dead** | `sdg-hub` is a package. The real skip is `sdg-hub[examples] ; platform_machine != 's390x'` in the same file (AIPCC-10512). |

`rhai-innovation`/cpu therefore builds on all 4 arches, with per-package s390x
exclusion by PEP 508 markers. `docling-slim` carries
`platform_machine != "s390x"` in `rhai`/cpu and `rhai`/spyre
(`team-autorag.txt`, AIPCC-28691/AIPCC-30770), and `docling-serve` is limited
to aarch64/x86_64. `docling-jobkit` (`team-data-processing.txt`) has no
marker.

**Variant linter** (`rhai-pipeline/bin/variant-linter.py`) runs on MRs that
change `ci-job-definitions.yml` and blocks any `rhai_pipeline` variant not
matching `ALLOWED_VARIANT_PATTERNS` (case-insensitive substring): `["cuda",
"rocm", "cpu", "spyre", "tpu", "neuron", "gaudi"]`. New accelerator types need
approval before a pattern is added; `rubin-ubi9` matches none.

### The `rhai` Collection

`collections/rhai/cpu-ubi9/requirements/` holds 38 files: `rhai.txt` (shared
base: `pyyaml`, `uv`), `onboarded.txt` (empty; spyre has none; graduation now
appends to team files), and 36 per-team `team-*.txt` files. Notable team files:

- `team-notebooks-images.txt` (about 200 packages), `team-notebooks-extensions.txt` — data science / workbench stack
- `team-mlserver.txt`, `team-kserve.txt`, `team-model-serving.txt`, `team-model-runtimes.txt` — serving
- `team-vllm-runtime.txt`, `team-infereng-midstream.txt`, `team-llm-d.txt`, `team-llmd.txt`, `team-serving-orchestration.txt` — inference / llm-d
- `team-fine-tuning.txt`, `team-pytorch.txt`, `team-training-kubeflow.txt`, `team-kubeflow-devx.txt` — training
- `team-sdg.txt`, `team-autorag.txt`, `team-rag-vector-db.txt`, `team-data-processing.txt`, `team-data-connect-hub.txt` — AI / data (`docling-slim` in `team-autorag.txt` guards s390x; `docling-jobkit` has no marker)
- `team-llama-stack-core.txt`, `team-ogx-core.txt` — Llama Stack and OGX
- `team-guardrails-detectors.txt`, `team-ai-safety.txt`, `team-model-eval.txt`, `team-lm-evaluation-harness.txt` — safety and evaluation
- `team-aipcc-ecosystems.txt`, `team-wheel-package-index.txt`,
  `team-accelerator-enablement.txt`, `team-ai-core-platform.txt`,
  `team-ai-hub.txt`, `team-ai-navigator.txt`, `team-development-platform.txt`,
  `team-devops.txt`, `team-perfscale.txt`, `team-service-mesh.txt` — platform
  teams

Other variants differ: cuda12.9 38 files (adds `team-speculators`, no
`team-rag-vector-db`), cuda13.0 37 (no `team-rag-vector-db`), rocm7.14 37
(adds `team-speculators`; no `team-mlserver` or `team-rag-vector-db`), spyre
31 (no `onboarded.txt`, `team-ai-core-platform`, `team-devops`,
`team-fine-tuning`, `team-llmd`, `team-mlserver`, `team-rag-vector-db`).
Torch-linked packages live in the `torch/requirements-torch-<X.Y>.txt`
overlays of every variant except spyre, which has no `torch/` directory:
`detectron2` and `torchcodec` on all four (the only ones on rocm7.14), and
among others `torchvision` on cpu and CUDA, `speculators` on cpu and
cuda13.0, `kvcached` on CUDA, and `deep-ep` and `nixl` on cuda12.9.

### Onboarding Pipeline

New dependency requests land in `collections/onboarding/{variant}/requirements/`
first (shared `0000-core-packages.txt` plus per-package files; the collection
root carries `core-packages.txt`). Test jobs give teams CI feedback before
production. The weekly `move-onboarded-packages` job (`SCHEDULE_TYPE=move-onboarded`)
runs `bin/move-onboarded-packages.sh`: entries whose inline comment carries both
a Jira ticket (RHAI-* or AIPCC-*) and a `team-*` reference are appended to
`collections/rhai/<variant>/requirements/<team>.txt`, fully migrated files are
deleted, and a bot MR is opened on `auto/move-onboarded-packages`.

### Pipeline Flow

**Stages used by `rhai-pipeline/` jobs** (monorepo order): checks ->
channel-apply -> lint -> bootstrap -> build -> release -> branching -> publish ->
promote -> package-deletion -> notify.

**Trigger types:**

- **MR:** the `.generated/rhai-*.yml` includes load (`RHAI_INCLUDE_RULES` in
  `bin/regen-ci.py`), but only the `test-*-bootstrap-and-onboard` jobs of
  collections with `enable_test_jobs` run, when the MR touches their files.
- **Protected push:** the includes also load for every collection with
  `enable_post_merge_jobs` (`RHAI_POST_MERGE_RULE`). A job runs only when its
  own files change: the collection variant's `requirements.txt`,
  `requirements/*.txt`, `constraints.txt` and `torch/*-torch-<X.Y>.txt`, the
  `constraints-rules.txt` files, `builder-image-version.yml` or
  `rhai-pipeline/product-version.yml` (`builder/pipeline-api/ci-wheelhouse.yml`).
  `build_on_all_pushes` is `false`, so changes to `channels.yml` or to builder
  torch collections rebuild nothing until the nightly.
- **Nightly schedule** (`SCHEDULE_TYPE=nightly`): full builds and `-test`
  uploads for every collection (`enable_nightly_builds: true`); the same
  pipeline rebuilds the builder images. Nightly and failed post-merge
  pipelines on the default branch trigger AI failure analysis (stage `notify`).
- **Weekly schedules:** `move-onboarded` and `cve-scan`.
- **Web pipelines:** `wheel-copy` (version branching), `wheel-publish`
  (refresh `publish_config.yml`), `wheel-promote` (channel promotion) and
  `channel-apply` (manual, default branch only). Build jobs never run in these
  pipelines.
- **`channel-apply`** also runs automatically on a default-branch push that
  changes `rhai-pipeline/channels.yml`.

**Key checks-stage gates:**

- `variant-linter` — validates `ci-job-definitions.yml` variants on MRs
- `verify-publish-config` (`bin/verify_publish_config.py`): on
  `publish_config.yml` MRs, compares old and new repo versions through the Pulp
  API and saves `publish-delta/index-delta.md`. It is `allow_failure: true` and
  never blocks the MR (AIPCC-30074). `trigger-autoqa-verification` runs on the
  same MRs, except MRs targeting `feat/channels*` branches (AIPCC-32066).
- `validate-package-deletion-manifests` — validates deletion YAML on MRs to
  `main`; `delete-packages-from-pulp` (stage `package-deletion`) executes on
  merge
- In the `lint` stage, the `linter` job checks that `make regen` leaves no
  diff and runs `builder/test/channel_linter.py` (torch version map, builder
  collection directories, torch pins, overlay names and per-channel
  constraint merges), and `rhai-pipeline-unit-tests` loads the catalog on MRs
  that touch `channels.yml` or `rhai-pipeline/` code.

### Pulp Publishing Mechanics

1. **Upload** (`uv run pulp upload`, dual-repo by default), called from each
   `build-wheels` job via `bin/upload_to_pulp.sh`. Mode precedence is
   `CHANNEL`, then `PULP_BASE_PATH`, then `PRODUCT_VERSION`. Every
   `rhai-pipeline/` build job on `main` sets `CHANNEL`, so uploads go to the
   channel's `-test` and `-sdists-test` repositories in the catalog row's
   `domain` (which overrides `PULP_DOMAIN`); the upload fails if the channel
   is not catalogued or its variant differs from the job's. `pulp upload`
   skips packages listed in a deletion manifest named after the channel (the
   build hook's cache upload in step 4 does not) and labels packages with CI
   metadata (commit SHA, pipeline IID, job ID, product name and version).
2. **Channel apply:** `apply-channel-catalog` runs `pulp channel apply --all`,
   which creates or updates, for every catalog row, four repositories with
   floating distributions (wheels and sdists, test and production) in the
   row's domain, with the channel's distribution labels.
3. **Promote** (web pipeline, `SCHEDULE_TYPE=wheel-promote`): generated
   `promote-plan-<channel>` / `promote-apply-<channel>` jobs for the 14 built
   channels (11 in `public-rhai`, 3 in `rhai`) run `bin/dual-repo-promote.sh`
   with `PULP_BASE_PATH=<channel>`. `plan` runs content-diff -> AutoQA ->
   qualify-wheels on `<channel>-test`; `apply` (manual, `allow_failure`) runs
   `pulp promote` into the unsuffixed `<channel>` repository. Promotion is
   additive; matching sdists follow their wheels. Production channel indexes
   get content only from these jobs.
4. **Pulp cache:** with `PULP_CACHE: "true"` (the default), bootstrap, build and
   release-tarball jobs use the channel's `-test` index as their wheel cache,
   and the build hook
   (`builder/package_plugins/hooks/upload_after_build_wheel.py`) uploads each
   new wheel and sdist there during `build-wheels`, before `pulp upload` runs
   and without checking deletion manifests. The private `rhaiis` Gaudi, Neuron
   and TPU jobs set `PULP_CACHE: "false"` and keep their GitLab caches
   (`rhaiis-3.6/<variant>-x86_64`).
5. **Legacy publish:** `publish_config.yml` pins `WHEEL_REPO_VERSION` /
   `SDIST_REPO_VERSION` for five variants (cpu-ubi9 460/222, cuda13.0-ubi9
   279/153, cuda12.9-ubi9 224/114, rocm7.14-ubi9 151/134, spyre-ubi9 245/104).
   `publish-pulp-repositories` publishes them to the
   `rhoai/<PRODUCT_VERSION>/<variant>` and `-sdists` distributions on a
   protected-branch push that changes the file, and
   `update-publish-config-from-test` (`SCHEDULE_TYPE=wheel-publish`) refreshes
   the pins from the `rhoai-<version>-<variant>-test` repositories through an
   MR. No build job on `main` uploads to those repositories.

**Routing:** `PULP_DOMAIN` after override precedence sets each job's and each
promote job's domain; channel uploads use the catalog `domain`. As of the
commit they agree for all 14 built channels. `public-rhai` content is served
at `packages.redhat.com`, `rhai` at `private.console.redhat.com` (overlay
0030). CI deletion (`delete-packages-from-pulp`, `PULP_DOMAIN: public-rhai`)
and version branching (`copy-wheels-to-new-version`, `PULP_DOMAIN:
public-rhai`, `PRODUCT_NAME: rhoai`) resolve product-versioned repositories
only, so they never touch channel repositories or the private `rhai` domain.

**Authentication:** TBR HTTP Basic auth with `PULP_USERNAME` /
`PULP_PASSWORD` (`src/rhai_pipeline/pulp_config.py`).

**Supporting tools:** `pulp autoqa`, `pulp catalog`, `pulp channel`,
`pulp content-diff`, `pulp qualify-wheels`.

### Package Deletion System

YAML manifests in `package-deletions/{release}.yaml` (schema
`package-deletions/manifest-schema.json`; current manifests cover 0.0-el9.6,
3.4-EA2, 3.4, 3.5-EA1, 3.5) declare packages to remove. `pulp upload` skips
matching packages, but the build hook's Pulp cache upload
(`builder/package_plugins/hooks/upload_after_build_wheel.py`) does not read
the manifests, so with `PULP_CACHE` on a rebuild can put a listed package back
into a `-test` repository, and neither `pulp promote` nor `pulp delete`
removes it from a channel repository. MR validation runs a dry run; on merge
the job deletes from Pulp. `pulp delete` processes every manifest in one run
and probes Pulp per `(version, variant)`: if
a `-test` repo exists it is a dual-repo release (removes from `-test` and the
unsuffixed prod repo, plus `-sdists-test` / `-sdists` when `delete_sdist: true`),
otherwise the legacy unsuffixed names. Pre-AIPCC-32489 `-prod` / `-sdists-prod`
repos are still recognized. The system is idempotent. Whether deletion covers
channel indexes is recorded in overlay [0030](0030-aipcc-content-channels.md)
(Channel Awareness).

### Version Branching

`uv run pulp copy` (`src/rhai_pipeline/pulp_copy.py`, dual-repo by default)
copies existing product-versioned repositories to a new product version (e.g.
`--source-version 3.6-EA2 --dest-version 3.6`), creating all four repos per
variant seeded from the source's prod content. The variant set is the
intersection from `supported_versions.yml` unless `--variants` overrides it. CI
runs it as `copy-wheels-to-new-version` (web, `SCHEDULE_TYPE=wheel-copy`,
manual). This promotion path needs no rebuild and does not copy channels.

## Impact on Strategies

- This is the authoritative publish gate for all RHAI Python packages. No package
  reaches the customer-facing Pulp index without going through this pipeline.
- Adding a new collection, variant or torch version on the `rhai-pipeline/`
  side requires: (1) `ci-job-definitions.yml` entries at the monorepo root (the
  `collections:` entry; for a new variant also
  `rhai_pipeline.variants.<variant>.arches` and `torch_versions`; for a new
  torch version a `rhai_pipeline.torch_versions` entry, or a per-collection
  `torch_versions` override), (2) the
  `rhai-pipeline/collections/{name}/{variant}/` directory with
  `requirements.txt`/`constraints.txt` and `torch/*-torch-<X.Y>.txt` overlays
  for torch-linked packages, (3) running `make regen` to generate
  `.generated/rhai-{name}.yml` and the promote jobs, (4) merging the changes
  together. Each new channel also needs a catalog row (`make regen` fails
  without one for a matrix channel; an explicit `CHANNEL` override value is
  not checked, so an uncatalogued one fails only at upload, overlay 0030) and
  a builder torch collection directory (jobs fail without it); overlay
  [0030](0030-aipcc-content-channels.md) has the cross-component recipe. The
  `variant-linter` CI job blocks any unrecognized accelerator type (e.g.
  `rubin-ubi9` would need a new approved pattern). To exclude an arch, add an
  `omit_jobs` entry whose first element is the **collection** key (a package
  name there is a no-op) — or, for a single package, use a PEP 508 marker in
  `requirements.txt`.
- On `main`, `bin/regen-ci.py` sets `ENABLE_REPEATABLE_BUILD_MODE` only for a
  collection with `enable_repeatable_build_mode: true`, and none sets it, so it
  is `false` for every job. Release branches enable it when cut: `3.6-EA1`
  (AIPCC-31131) and `3.6-EA2` (AIPCC-32040, which also disables nightly builds)
  set `rhai_pipeline.defaults.enable_repeatable_build_mode: true` and carry a
  `regen-ci.py` that reads it. Bootstrap then reuses the latest release tag's
  `graph.json` (`--previous-bootstrap-file`), so adding or updating a package
  on a release branch needs an exact version pin in `requirements.txt`. 3.6 GA
  builds from `main` (`supported_versions.yml`), so it currently runs without
  repeatable mode.
- Two CUDA versions (12.9 and 13.0) are maintained simultaneously, and each
  torch version multiplies the jobs. Each channel costs one job set per
  (collection, arch) it joins: `cuda12.9-ubi9` runs 22 of the 154
  `rhai-pipeline/` build-wheels jobs (5 collections x 2 torch versions x 2
  arches, plus `backfill` on torch 2.13) and `cuda13.0-ubi9` runs 40 (8
  collections, 1 to 3 torch versions, 2 arches). A third CUDA version adds
  two build-wheels jobs (aarch64, x86_64)
  per collection and torch version that takes it; each also needs builder
  torch collection directories and builder/base images. `cuda12.9-ubi9` gets
  no `vllm` pin from `rhai-pipeline/` because it is not in the `rhaiis`
  collection; `rhai`/cuda12.9 does request vLLM ecosystem packages
  (`vllm-omni`, `vllm-judge`, `vllm-beam-search-plugin==0.1.4`), and the
  builder's `torch-2.11.0` and `torch-2.13.0` cuda12.9 collections build
  `vllm` (the latter per AIPCC-31069).
- ROCm 7.1 has been fully retired. Only ROCm 7.14 is built and published, in
  two channels: `rocm7.14-torch2.11-el9.8` (torch 2.11.0) and
  `rocm7.14-torch2.12-el9.8` (torch 2.12.0). `rocm7.14-torch2.13-el9.8` and later
  ROCm rows are catalogued but not built: the builder has no
  `torch-2.13.0/rocm7.14-ubi9` collection, so moving ROCm to 2.13 needs one
  first. RFEs referencing ROCm should specify 7.14 and the torch channel.
- Spyre carries IBM-proprietary packages
  (`rhai-pipeline/collections/rhaiis/spyre-ubi9/requirements.txt` and its
  `torch/requirements-torch-2.11.txt` overlay):
  `vllm[tensorizer]==0.27.1+rhaiv.4.spyre` (IBM fork, `.spyre` suffix
  distinguishes it from the NeuralMagic fork; RHAI-688; in the torch overlay),
  `sendnn-inference==2.6.1` (IBM inference runtime),
  `torch-sendnn==1.3.1` (pre-built IBM wheel from the private Spyre index; no
  arch marker; tracks the Spyre SDK RPM version 1.3.1 in the base image),
  `torch-nnpa==1.5.0` (pre-built IBM wheel from the same private index, s390x
  only, its own version line), `ibm-fms==1.13.1` (Foundation Model Stack, built
  from source; both pinned and unpinned `ibm-fms` listed per AIPCC-27741),
  `spyremetrics==0.5.0` (AIPCC-28704) and `ibm-aiu-smi==1.3.0` (AIPCC-28706),
  both on every Spyre arch since INFERENG-9813. Spyre's torch 2.11.0 pin comes
  from the builder `torch-2.11.0/spyre-ubi9` collection, which the
  `spyre-torch2.11-el9.8` channel reads in channel mode (its
  `constraints-rules.txt` is bypassed). aiu-monitor is not a wheel collection
  package; it ships as an RPM in the Spyre base image, and
  `builder/collections/global-constraints.txt` carries no aiu-monitor guard.
- The index URL structure is treated as a stable contract for air-gapped
  mirroring (`wget`-based). Breaking it requires coordinating all downstream
  consumers. `main` now publishes per channel (`<channel>-test` for test, the
  unsuffixed `<channel>` for production, e.g. `cuda13.0-torch2.13-el9.8`, in the
  domain the catalog sets), while the legacy publish still targets
  `rhoai/{version}/{variant}` (unsuffixed production as of AIPCC-32489;
  `-test` for test). Overlay [0030](0030-aipcc-content-channels.md) has the URL
  derivation and the legacy-to-channel relationship.
- Package deletion is idempotent, but only `pulp upload` enforces the
  manifests: the build hook's Pulp cache upload skips them, so with
  `PULP_CACHE` on a rebuild can put a deleted package back into a `-test`
  index, and a `wheel-promote` run could then carry it to production. RFEs
  proposing package removal must go through the deletion manifest process and
  account for that gap; simply removing a package from `requirements.txt` does
  not remove it from Pulp. As of the commit the manifests and `pulp delete`
  cover product-versioned indexes only, so removing a package from a channel
  index has no merged path.
- New packages usually enter through the `onboarding` collection, whose test
  jobs give CI feedback. Graduation to `rhai` is automated but weekly, not on
  demand, and only moves entries that carry both a Jira ticket and a `team-*`
  reference.

### ROCm Work Breakdown Patterns

When a strategy involves a ROCm variant update in the pipeline (e.g., new ROCm
version or ROCm package changes), the pipeline-side work decomposes into these
epics:

- **Update ROCm channel pins**: the torch pin comes from the builder
  `torch-X.Y.Z/rocm{version}-ubi9` collection, which must exist first; the vLLM
  pin from `collections/rhaiis/rocm{version}-ubi9/torch/requirements-torch-<X.Y>.txt`;
  ROCm-specific package versions in `constraints.txt` and the `torch/`
  constraints overlay.
- **Add or update ROCm-specific packages in collections** — `amd-quark`,
  `amd-aiter`, `tensorflow-rocm`, `flash-attn`, and any new AMD ecosystem packages
  in `collections/rhaiis/rocm{version}-ubi9/requirements.txt` and its `torch/`
  overlays.
- **Validate build and publish for each ROCm channel**: CI pipeline green,
  wheels uploaded to the channel `-test` index, promoted to the production
  channel index, and the customer-facing index updated.

Strategies referencing ROCm pipeline updates should structure their Technical
Approach around these epics rather than describing the work as prose.

## Context

This overlay was created to capture the state of the RHAI wheel pipeline at the
3.6-EA1 release boundary and updated to reflect the current 3.6 (GA) state. The
pipeline is mostly declarative (collections, variant matrix, Pulp routing) plus
the `pulp` CLI tooling that drives publishing. Its architecture (collection
structure, variant matrix, Pulp publishing contract) shapes what RHAI customers
receive and constrains what RFEs can realistically propose. This overlay allows
the feasibility reviewer to evaluate whether a proposed change is compatible with
the existing index structure, build infrastructure, and publishing workflow.

Maintained with the `update-fondue-overlays` skill; last refreshed 2026-10-07
from Fondue `main` (`d57f272`).
