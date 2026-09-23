---
id: "0020"
title: RHAI Pipeline — Wheel Package Index
status: active
created: 2026-07-15
affects:
  - platform
release:
  - "3.6"
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
global constraints, security constraints, and variant-specific build
requirements. Collection constraint files must not conflict with the builder's
constraints. `rhai-pipeline/` declares which packages to build per collection ×
variant × architecture and publishes approved wheels to the customer-facing Pulp
index. The authoritative CI matrix (collections, variants, arches, Pulp routing)
is `ci-job-definitions.yml` at the **monorepo root**.

The `rhaiis` collection below (`rhai-pipeline/collections/rhaiis/`) is not the
separate `rhaiis/pipeline` repository, which lives outside Fondue (overlay
[0021](0021-rhaiis-pipeline.md)). Both `rhai-pipeline/collections/rhaiis/` and
the `rhaiis/pipeline` repository build vLLM for overlapping variants with
independent pins; check overlay 0021 before citing a RHAIIS vLLM version.

- **Product name:** `rhoai` (default `PRODUCT_NAME`; overrides use `rhaiis` and `vllm-deps`)
- **Product version:** `3.6` (`rhai-pipeline/product-version.yml`; the base
  images' `INDEX_VERSION` is also `3.6`)
- **Base OS version:** RHEL **9.8** (`builder/product-version.yml`
  `PRODUCT_VERSION: "0.0-el9.8"`, the OS the builder targets, not a builder release)
- **Builder:** the in-tree builder, not a release tag. `builder-image-version.yml`
  (included last by the root `.gitlab-ci.yml`) sets `BUILDER_IMAGE_VERSION` to
  `ci-${BUILDER_PRODUCT_VERSION}-${CI_MERGE_REQUEST_IID}`, so MR pipelines use
  that MR's builder images and non-MR pipelines use the branch's
  `ci-0.0-el9.8-` images (on `main`, the nightly pipeline rebuilds them before
  its builds). For context,
  `releases/builder-release.yaml` declares Fondue builder release `v46.0.0` on
  `main`; `rhai-pipeline/` does not pin it. `rhaiis/pipeline` pins a Fondue
  release ref (overlay 0021).
- **Pulp domain (default):** `public-rhai`
- **Public index base URL:** `https://packages.redhat.com/api/pypi/public-rhai/rhoai/`

### Published Variants (3.6)

One row per variant in `publish_config.yml` (`supported_versions.yml` lists the
same five for `3.6` on `main`).

| Variant | Architectures | Torch | vLLM (`rhaiis` collection) | Public Index Path |
|---|---|---|---|---|
| `cpu-ubi9` | aarch64, ppc64le, s390x, x86_64 | 2.13.0 | 0.28.0+rhaiv.1 (NeuralMagic; x86_64 adds `zen`) | `rhoai/3.6/cpu-ubi9/simple/` |
| `cuda13.0-ubi9` | aarch64, x86_64 | 2.13.0 | 0.28.0+rhaiv.1 (NeuralMagic) | `rhoai/3.6/cuda13.0-ubi9/simple/` |
| `cuda12.9-ubi9` | aarch64, x86_64 | 2.13.0 | none (not in `rhaiis`) | `rhoai/3.6/cuda12.9-ubi9/simple/` |
| `rocm7.14-ubi9` | x86_64 | 2.12.0 | 0.28.0+rhaiv.1 (NeuralMagic) | `rhoai/3.6/rocm7.14-ubi9/simple/` |
| `spyre-ubi9` | ppc64le, s390x, x86_64 | 2.11.0 | 0.27.1+rhaiv.1.spyre (IBM fork) | `rhoai/3.6/spyre-ubi9/simple/` |

Torch is pinned per variant by `collections/rhai/<variant>/constraints-rules.txt`
(`torch-X.Y.Z *` pulls that builder collection's constraints). vLLM `+rhaiv`
tags indicate the NeuralMagic enterprise fork; `.spyre` indicates the IBM fork
(`vllm[tensorizer]==0.27.1+rhaiv.1.spyre`, RHAI-688). Other variant-specific
pins: cuda13.0 `flashinfer-*==0.6.16.post3`, `nixl==1.3.2`,
`deep-ep==2.0.1+rhaiv.1`; rocm7.14 `amd-aiter==0.1.19`. ROCm 7.1 is retired;
only ROCm 7.14 remains.

Privately published `rhaiis` variants (not in `publish_config.yml`; routed to
the **private** `rhai` Pulp domain and promoted by the dual-repo promote jobs):
`gaudi-ubi9` (vLLM 0.26.0 + vllm-gaudi 0.26.0,
torch-2.11.0 rules), `neuron-ubi9` (vLLM 0.16.0+rhaiv.12 + vllm-neuron 0.5.3,
`torch==2.9.1` in `constraints.txt`), and `tpu-ubi9` (vLLM 0.27.1 upstream,
torch-2.10.0 rules). The `torch-day0` collection builds torch 2.14.0 for
`cpu-torch-day0-ubi9` and `cuda13.0-ubi9` into version-pinned public base paths.

### Collections and Variant Coverage

`make regen` (monorepo-root `bin/regen-ci.py`) generates
`.generated/rhai-<collection>.yml` from `ci-job-definitions.yml`, the
authoritative source for collection names, variant lists, base arch sets,
`omit_jobs`, Pulp routing and optional keys (`enable_test_jobs`,
`enable_multi_version_bootstrap`, `max_release_age`).

**Arch coverage is computed:** effective arches = `rhai_pipeline.variants.<variant>.arches`
minus every `omit_jobs` entry `[<collection>, <variant>, <arch>]` whose first
element is a collection key. Base arch sets: cpu-ubi9 and cpu-torch-day0-ubi9 =
aarch64, ppc64le, s390x, x86_64; cuda12.9-ubi9 and cuda13.0-ubi9 = aarch64,
x86_64; spyre-ubi9 = ppc64le, s390x, x86_64; gaudi, neuron, rocm7.14, tpu = x86_64.

| Collection | Purpose | Variants (effective arches) |
|---|---|---|
| `onboarding` | Intake staging area; test builds before graduation (`enable_test_jobs`) | cpu (all 4 arches), cuda12.9, cuda13.0, rocm7.14, spyre |
| `rhai` | Primary production packages, organized by owning team | cpu (all 4 arches), cuda12.9, cuda13.0, rocm7.14, spyre |
| `rhai-innovation` | RHAI Innovation composite: `docling`, `its-hub`, `sdg-hub`, `training-hub` (README also lists universal-training) | cpu (all 4 arches), cuda12.9, cuda13.0, rocm7.14 |
| `rhaiis` | Red Hat AI Inference Server (vLLM). `gaudi-ubi9`, `neuron-ubi9`, `tpu-ubi9` route to the **private** `rhai` domain via `variant_overrides` (AIPCC-28553); other variants use `public-rhai`. | cpu (all 4 arches), cuda13.0, gaudi-ubi9, neuron-ubi9, rocm7.14, spyre, tpu-ubi9 |
| `model-opt` | Model Optimization (CUDA 13 only) | cuda13.0 (aarch64, x86_64) |
| `torch-deps` | PyTorch team exact-pin dependencies matching upstream PyTorch CI | cpu (all 4 arches), cuda12.9, cuda13.0, rocm7.14 |
| `torch-day0` | Rapid PyTorch version availability; `enable_multi_version_bootstrap`, `max_release_age` 60 days; torch 2.14.0 (AIPCC-30387). Both variants carry a `PULP_BASE_PATH` override (public domain). A `collections/torch-day0/cpu-ubi9/` directory exists but is not in the matrix. | cpu-torch-day0-ubi9 (all 4 arches), cuda13.0-ubi9 (aarch64, x86_64) |
| `ogx` | OGX / Llama Stack inference framework; `enable_test_jobs`, `enable_multi_version_bootstrap`, `max_release_age` 30 days | cpu (aarch64, ppc64le, x86_64) — s390x removed by an effective `omit_jobs` entry |
| `vllm-deps/torch-2.11` | vLLM build dependencies, torch 2.11; **private** domain `rhai` (`PRODUCT_NAME: vllm-deps`, `PRODUCT_VERSION: torch2.11`), a private index for vLLM team test builds during the transition to pre-built wheels (AIPCC-19939 / AIPCC-12506, ADR0211); `enable_multi_version_bootstrap`, `max_release_age` 10 days | cuda12.9-ubi9, cuda13.0-ubi9 |

Routing precedence: `overrides._default → overrides.<collection> →
variant_overrides.<collection>.<variant>` (details under Pulp Publishing
Mechanics). Test jobs (`enable_test_jobs: true`) run for `onboarding` and `ogx`.

**`OMIT_JOBS`:** an entry is only effective if its **first element is a
collection key**; `regen-ci.py` skips a job only when `(collection, variant,
arch)` matches, so an entry naming a *package* matches nothing and is **dead**.

| `omit_jobs` entry | Status | Notes |
|---|---|---|
| `[ogx, cpu-ubi9, s390x]` | **Effective** | Narrows `ogx`/cpu to (aarch64, ppc64le, x86_64); no s390x index for this collection. |
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

`collections/rhai/cpu-ubi9/requirements/` holds 39 files: `rhai.txt` (shared
base: `pyyaml`, `uv`), `onboarded.txt` (empty; spyre has none; graduation now
appends to team files), and 37 per-team `team-*.txt` files. Notable team files:

- `team-notebooks-images.txt` (about 200 packages), `team-notebooks-extensions.txt` — data science / workbench stack
- `team-mlserver.txt`, `team-kserve.txt`, `team-model-serving.txt`, `team-model-runtimes.txt` — serving
- `team-vllm-runtime.txt`, `team-infereng-midstream.txt`, `team-speculators.txt`, `team-llm-d.txt`, `team-llmd.txt`, `team-serving-orchestration.txt` — inference / llm-d
- `team-fine-tuning.txt`, `team-pytorch.txt`, `team-training-kubeflow.txt`, `team-kubeflow-devx.txt` — training
- `team-sdg.txt`, `team-autorag.txt`, `team-rag-vector-db.txt`, `team-data-processing.txt`, `team-data-connect-hub.txt` — AI / data (`docling-slim` in `team-autorag.txt` guards s390x; `docling-jobkit` has no marker)
- `team-llama-stack-core.txt`, `team-ogx-core.txt` — Llama Stack and OGX
- `team-guardrails-detectors.txt`, `team-ai-safety.txt`, `team-model-eval.txt`, `team-lm-evaluation-harness.txt` — safety and evaluation
- `team-aipcc-ecosystems.txt`, `team-wheel-package-index.txt`,
  `team-accelerator-enablement.txt`, `team-ai-core-platform.txt`,
  `team-ai-hub.txt`, `team-ai-navigator.txt`, `team-development-platform.txt`,
  `team-devops.txt`, `team-perfscale.txt`, `team-service-mesh.txt` — platform
  teams

Other variants carry subsets: cuda12.9/cuda13.0 38 files (no
`team-rag-vector-db`), rocm7.14 37 (also no `team-mlserver`), spyre 31 (no
`onboarded.txt`, `team-ai-core-platform`, `team-devops`, `team-fine-tuning`,
`team-llmd`, `team-mlserver`, `team-rag-vector-db`, `team-speculators`).

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

**Stages used by `rhai-pipeline/` jobs** (monorepo order): checks → lint →
bootstrap → build → release → branching → publish → promote →
package-deletion → notify.

**Trigger types:**

- Push / MR: standard CI; interruptible jobs auto-cancel on new commits (not for
  schedules or dual-repo promote). On `main`, the `.generated/rhai-*.yml`
  includes load only for MR pipelines and nightly schedules
  (`RHAI_INCLUDE_RULES` in `bin/regen-ci.py`): MR pipelines run only the
  `test-*-bootstrap-and-onboard` jobs, push pipelines run no collection jobs,
  and `build_on_all_pushes: true` has no effect there. Release branches
  (`3.6-EA1`, `3.6-EA2`) include them on every pipeline except non-nightly
  schedules, so every protected push runs full builds.
- Scheduled pipelines build wheels where
  `rhai_pipeline.defaults.enable_nightly_builds` is true (true on `main`, false
  on release branches), so on `main` full builds and `-test` Pulp uploads run
  nightly. Nightly (`SCHEDULE_TYPE=nightly`) and failed post-merge pipelines
  trigger AI failure analysis (stage `notify`)
- Weekly `move-onboarded` and `cve-scan` schedules
- Web pipelines: `wheel-copy` (version branching), `wheel-publish` (refresh
  `publish_config.yml`), `wheel-promote` (dual-repo promotion)

**Key checks-stage gates:**

- `variant-linter` — validates `ci-job-definitions.yml` variants on MRs
- `verify-publish-config` (`bin/verify_publish_config.py`): on
  `publish_config.yml` MRs, compares old and new repo versions through the Pulp
  API and saves `publish-delta/index-delta.md`. It is `allow_failure: true` and
  never blocks the MR (AIPCC-30074). `trigger-autoqa-verification` runs on the
  same MRs and only warns if the trigger fails.
- `validate-package-deletion-manifests` — validates deletion YAML on MRs to
  `main`; `delete-packages-from-pulp` (stage `package-deletion`) executes on
  merge

### Pulp Publishing Mechanics

**Dual-repo architecture (ADR 0199).** Each `{product}-{version}-{variant}` maps
to four Pulp repositories:

```
{product}-{version}-{variant}-test           wheels test
{product}-{version}-{variant}                wheels prod (unsuffixed)
{product}-{version}-{variant}-sdists-test    sdists test
{product}-{version}-{variant}-sdists         sdists prod
```

Base paths follow `{product}/{version}/{variant}[-suffix]`, so the prod index is
`rhoai/{version}/{variant}/simple/` and test is
`rhoai/{version}/{variant}-test/simple/` (naming in
`src/rhai_pipeline/pulp_ops.py`). Since AIPCC-32489, production repos are
**unsuffixed**; the obsolete `-prod` target suffix is rejected by
`pulp promote`. Both distributions are floating (always serve latest).

1. **Upload** (`uv run pulp upload`, dual-repo by default), called from each
   `build-wheels` job via `bin/upload_to_pulp.sh`: skips packages listed in
   deletion manifests and uploads over mTLS to the `-test` repos, labelling
   packages with CI metadata (commit SHA, pipeline IID, job ID, product name
   and version).
2. **Promote** (web pipeline, `SCHEDULE_TYPE=wheel-promote`): generated
   plan/apply jobs for 12 indexes (`.generated/rhai-promote-jobs.yml`) run
   `bin/dual-repo-promote.sh`. `plan` runs content-diff → AutoQA →
   qualify-wheels; `apply` (manual) runs `pulp promote` into the unsuffixed prod
   repo. Promotion is additive; matching sdists follow their wheels.
3. **Legacy publish:** `publish_config.yml` pins `WHEEL_REPO_VERSION` /
   `SDIST_REPO_VERSION` for the five published variants.
   `update-publish-config-from-test` (`SCHEDULE_TYPE=wheel-publish`) refreshes
   them through an MR, and `publish-pulp-repositories` publishes on a protected
   branch push that changes the file. This publishing targets the same
   `rhoai/<version>/<variant>` distribution as the dual-repo promote path.
   `docs/dual-repo-architecture.md` says the dual-repo model replaces this
   pinning model, but the publish job is still wired on `main`.

**Routing has two independent dimensions**, both set by `overrides` /
`variant_overrides`. Variants without either override publish to `public-rhai`
at the default per-product path. Every collection that builds such a variant
(e.g. `rhai`, `onboarding`, `rhaiis`, `rhai-innovation`, `torch-deps`, `ogx`,
`model-opt`) uploads into that one `rhoai/<version>/<variant>` index;
`publish_config.yml` and the promote jobs work per variant, not per
collection.

1. **`PULP_DOMAIN`** — which Pulp domain (tenant) on the shared mTLS API;
   `public-rhai` content is served at `packages.redhat.com`, `rhai` at
   `private.console.redhat.com`. `overrides._default` sets
   `public-rhai` (plus `PUBLISH_WHEEL_RELEASES: "true"`, `GITLAB_PRIVATE_TOKEN`).
   Exceptions route to the private `rhai` domain (`private.console.redhat.com`):
   - Collection-level: `vllm-deps/torch-2.11` (`PRODUCT_NAME: vllm-deps`,
     `PRODUCT_VERSION: torch2.11`).
   - Variant-level `variant_overrides.rhaiis`: `gaudi-ubi9`, `neuron-ubi9`,
     `tpu-ubi9` (`PRODUCT_NAME: rhaiis`, `PULP_DOMAIN: rhai`; `PRODUCT_VERSION`
     intentionally omitted so it comes from `product-version.yml`; vendor wheels
     that cannot be publicly redistributed, AIPCC-28553).
2. **`PULP_BASE_PATH`** — the repo name **within** a domain.
   `variant_overrides.torch-day0`:
   - `cpu-torch-day0-ubi9` → `PULP_BASE_PATH: torch-2.14.0-cpu-ubi9`
   - `cuda13.0-ubi9` → `PULP_BASE_PATH: torch-2.14.0-cuda13.0-ubi9`

   These stay on the **public** `public-rhai` domain and publish to the repos
   `public-rhai/torch-2.14.0-cpu-ubi9` and `public-rhai/torch-2.14.0-cuda13.0-ubi9`,
   each with a `-test` sibling. `dual-repo-promote.sh` and
   `pulp_ops.repo_name_from_base_path` derive the repo name from the base path
   (`/` → `-`, a no-op here) and ignore `PRODUCT_VERSION`. The repo name
   **drops** the `-torch-day0` collection segment (it is not
   `torch-2.14.0-cpu-torch-day0-ubi9`), and these variants do **not** use the
   default `rhoai/<PRODUCT_VERSION>/<variant>` path.

CI deletion (`delete-packages-from-pulp`, `validate-package-deletion-manifests`)
and version branching (`copy-wheels-to-new-version`) run with `PULP_DOMAIN:
public-rhai` and product `rhoai`, so they never touch the private
`rhai`-domain repos (`rhaiis-*`, `vllm-deps-torch2.11-*`) or the
`torch-2.14.0-*` base-path repos. Promotion covers all 12 indexes.

**Authentication:** all Pulp operations use mTLS (`PULP_CERT_BASE64` /
`PULP_KEY_BASE64`).

**Supporting tools:** `pulp autoqa`, `pulp catalog`, `pulp content-diff`.

### Package Deletion System

YAML manifests in `package-deletions/{release}.yaml` (schema
`package-deletions/manifest-schema.json`; current manifests cover 0.0-el9.6,
3.4-EA2, 3.4, 3.5-EA1, 3.5) declare packages to remove. Deletion is enforced at
upload time (matching packages are skipped, so re-runs cannot reintroduce them).
MR validation runs a dry run; on merge the job deletes from Pulp. `pulp delete`
processes every manifest in one run and probes Pulp per `(version, variant)`: if
a `-test` repo exists it is a dual-repo release (removes from `-test` and the
unsuffixed prod repo, plus `-sdists-test` / `-sdists` when `delete_sdist: true`),
otherwise the legacy unsuffixed names. Pre-AIPCC-32489 `-prod` / `-sdists-prod`
repos are still recognized. The system is idempotent.

### Version Branching

`uv run pulp copy` (`src/rhai_pipeline/pulp_copy.py`, dual-repo by default)
copies existing repositories to a new product version (e.g.
`--source-version 3.6-EA2 --dest-version 3.6`), creating all four repos per
variant seeded from the source's prod content. The variant set is the
intersection from `supported_versions.yml` unless `--variants` overrides it. CI
runs it as `copy-wheels-to-new-version` (web, `SCHEDULE_TYPE=wheel-copy`,
manual). This promotion path needs no rebuild.

## Impact on Strategies

- This is the authoritative publish gate for all RHAI Python packages. No package
  reaches the customer-facing Pulp index without going through this pipeline.
- Adding a new collection or variant requires: (1) adding an entry to the
  `collections:` section in `ci-job-definitions.yml` at the monorepo root (for
  a new variant, also add `rhai_pipeline.variants.<variant>.arches`, add it to
  the `VARIANT` `options` in `builder/pipeline-api/ci-wheelhouse.yml`, and make
  sure a builder collection (`builder/collections/torch-X.Y.Z/<variant>/`)
  exists for its `constraints-rules.txt`),
  (2) creating `rhai-pipeline/collections/{name}/{variant}/` directory structure
  with `requirements.txt`/`constraints.txt`, (3) running `make regen` to generate
  `.generated/rhai-{name}.yml`, (4) merging all three changesets together. The
  `variant-linter` CI job blocks any unrecognized accelerator type (e.g.
  `rubin-ubi9` would need a new approved pattern). To exclude an arch, add an
  `omit_jobs` entry whose first element is the **collection** key (a package
  name there is a no-op) — or, for a single package, use a PEP 508 marker in
  `requirements.txt`.
- On `main`, `bin/regen-ci.py` hard-codes `ENABLE_REPEATABLE_BUILD_MODE: false`
  for every job. Release branches enable it when cut: `3.6-EA1` (AIPCC-31131)
  and `3.6-EA2` (AIPCC-32040, which also disables nightly builds) set
  `rhai_pipeline.defaults.enable_repeatable_build_mode: true` and carry a
  `regen-ci.py` that reads it. Bootstrap then reuses the latest release tag's
  `graph.json` (`--previous-bootstrap-file`), so adding or updating a package
  on a release branch needs an exact version pin in `requirements.txt`. 3.6 GA
  builds from `main` (`supported_versions.yml`), so it currently runs without
  repeatable mode.
- Two CUDA versions (12.9 and 13.0) are maintained simultaneously. Each variant
  costs one job set per (collection, arch) it joins: `cuda12.9-ubi9` runs 10 of
  the 70 `rhai-pipeline/` build-wheels jobs (5 collections × 2 arches) and
  `cuda13.0-ubi9` runs 16 (8 × 2); each also needs a builder collection and
  builder/base images. A third CUDA version adds two build-wheels jobs
  (aarch64, x86_64) per collection that takes it (10 with cuda12.9's
  collection set, 16 with cuda13.0's). `cuda12.9-ubi9` gets no `vllm` pin
  from `rhai-pipeline/` because it is not in the `rhaiis` collection; `rhai`/
  cuda12.9 does request vLLM ecosystem packages (`vllm-omni`, `vllm-judge`,
  `vllm-beam-search-plugin==0.1.4`), and the builder's torch-2.13.0 cuda12.9
  collection builds `vllm` (AIPCC-31069).
- ROCm 7.1 has been fully retired. Only ROCm 7.14 is built and published. ROCm
  7.14 pins torch 2.12.0 (one minor below the CUDA variants' 2.13.0 — the
  builder has no `torch-2.13.0` rocm7.14-ubi9 collection, so moving ROCm to
  2.13 needs one first). RFEs referencing ROCm should specify 7.14 and note the
  different torch pin.
- Spyre carries IBM-proprietary packages
  (`rhai-pipeline/collections/rhaiis/spyre-ubi9/requirements.txt`):
  `vllm[tensorizer]==0.27.1+rhaiv.1.spyre` (IBM fork, `.spyre` suffix
  distinguishes it from the NeuralMagic fork; RHAI-688),
  `sendnn-inference==2.6.1` (IBM inference runtime),
  `torch-sendnn==1.3.1` (pre-built IBM wheel from the private Spyre index; no
  arch marker; tracks the Spyre SDK RPM version 1.3.1 in the base image),
  `torch-nnpa==1.5.0` (pre-built IBM wheel from the same private index, s390x
  only, its own version line), `ibm-fms==1.13.1` (Foundation Model Stack, built
  from source; both pinned and unpinned `ibm-fms` listed per AIPCC-27741),
  `spyremetrics==0.5.0` (ppc64le only, AIPCC-28704), and `ibm-aiu-smi==1.3.0`
  (ppc64le only, AIPCC-28706). Spyre's torch 2.11.0 pin comes from
  `constraints-rules.txt` (`torch-2.11.0 *`, the builder's torch-2.11.0
  constraints), which it shares with `rhaiis`/gaudi-ubi9; the other published
  variants pin 2.13.0 (cpu, cuda) or 2.12.0 (rocm). aiu-monitor is not a wheel
  collection package; it ships as an RPM in the Spyre base image, and
  `builder/collections/global-constraints.txt` carries no aiu-monitor guard.
- The public index URL structure (`rhoai/{version}/{variant}/simple/`, unsuffixed
  production as of AIPCC-32489; `-test` for test) is treated as a stable contract
  for air-gapped mirroring (`wget`-based). Breaking this structure requires
  coordinating all downstream consumers. Note that `torch-day0` variants deviate
  from this structure (version-pinned base path).
- Package deletion is idempotent and enforced at upload time. RFEs proposing
  package removal must go through the deletion manifest process; simply removing
  a package from `requirements.txt` does not remove it from Pulp.
- New packages usually enter through the `onboarding` collection, whose test
  jobs give CI feedback. Graduation to `rhai` is automated but weekly, not on
  demand, and only moves entries that carry both a Jira ticket and a `team-*`
  reference.

### ROCm Work Breakdown Patterns

When a strategy involves a ROCm variant update in the pipeline (e.g., new ROCm
version or ROCm package changes), the pipeline-side work decomposes into these
epics:

- **Update ROCm variant constraints** — torch pin, vllm pin, and ROCm-specific
  package versions in `constraints.txt` and `constraints-rules.txt` for the
  `rocm{version}-ubi9` variant.
- **Add or update ROCm-specific packages in collections** — `amd-quark`,
  `amd-aiter`, `tensorflow-rocm`, `flash-attn`, and any new AMD ecosystem packages
  in `collections/rhaiis/rocm{version}-ubi9/requirements.txt`.
- **Validate build and publish for the ROCm variant** — CI pipeline green, wheels
  uploaded to Pulp, promoted to the production repo, and the customer-facing index
  updated.

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

Maintained with the `update-fondue-overlays` skill; last refreshed 2026-09-23
from Fondue `main` (`330d9f9ee`).
