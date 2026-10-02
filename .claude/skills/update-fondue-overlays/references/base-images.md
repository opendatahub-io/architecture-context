# Base Images Overlay (0017)

Rules for refreshing `overlays/0017-aipcc-base-images.md` from `images/base/`
in the Fondue monorepo. Paths in this file are relative to
`{BASE}` = `{FONDUE}/images/base` unless they start with `{FONDUE}`.

## Overview

The overlay documents the accelerator variants (CPU, CUDA, ROCm, Gaudi, Spyre,
Neuron, TPU, Rubin) built from `images/base/`, the per-torch images GitLab CI
builds for each content channel, and the images Konflux builds. It is used to
evaluate RFEs that propose changes to accelerator support. When `images/base/`
or `.tekton/` changes, refresh the overlay. Channel identity, the catalog and
URL derivation belong to overlay 0030; this overlay records per-image confs,
rendered index URLs, labels, tags and the Konflux state, and links to 0030.

**Dependency management model (as of 3.6):** Package dependencies are declared
in `context/<variant>/rpms.in.yaml` and resolved into a hermetic lockfile at
`context/<variant>/rpms.lock.yaml` using `rpm-lockfile-prototype`. Konflux
(via Cachi2) fetches packages directly from the locked CDN URLs during hermetic
builds. Routine version drift is handled automatically by MintMaker
(`refresh-rpm-lockfiles` Renovate preset). Manual lockfile regeneration is only
needed when adding or removing packages from `rpms.in.yaml`.

## Key Files

**Common build configuration:**
- `build-args/argfile.conf` -> `APP_BASE_IMAGE` (base OS pin),
  `INDEX_URL_TEMPLATE`, `INDEX_BASE_URL` (default package index host and
  domain), `INDEX_STAGE`, `INDEX_SUFFIX`, `INDEX_VERSION` (RHOAI product
  version; grep where it is still used, see "Wheel index product version" in
  `shared-facts.md`), `TORCH_VERSION`, `REPO_VERSION` (RHEL AI RPM repo
  version), `PYTHON_VERSION` default

**Image inventory** (which confs are built, and by whom):
- **GitLab CI:** `{FONDUE}/ci-job-definitions.yml` -> `base_images.variants`
  (see "Variant x arch x torch matrix" in `shared-facts.md`). Each
  entry has a `version` or a `versions` list, and each version may list
  `torch_versions`. A version with torch versions builds one image per torch
  version from `build-args/<key><accel_version>-torch<X.Y><os_version>-<target>.conf`;
  a version without them builds one image from `build-args/<key><version>-<target>.conf`.
  Split `<accel_version>` and `<os_version>` from `version` at `-el`, as
  `split_base_image_version` in `{FONDUE}/bin/regen-ci.py` does. Cross-check
  with the `# --- <image>-<target>` headers in
  `{FONDUE}/.generated/base-image-jobs.yml` (grep them) and the `build-args/`
  listing.
- **Konflux:** `{FONDUE}/.tekton/*-on-push.yaml` -> the `build-args-file`
  param (which conf each pipeline builds), `output-image`, the `NAME` build
  arg, and the `on-cel-expression` trigger. See "Konflux base-image pipelines"
  in `shared-facts.md`: `.tekton/` is generated outside Fondue.
- A conf that neither GitLab CI nor Konflux names is unused; report it rather
  than documenting it as an image.

**Per-image Python package index:** read each built conf (falling back to
`argfile.conf` for any value the conf does not set) for `INDEX_BASE_URL`,
`INDEX_VERSION`, `INDEX_VARIANT`, `INDEX_STAGE`, `INDEX_SUFFIX`,
`INDEX_URL_TEMPLATE`, `TORCH_VERSION`, `NAME` and `DISTRIBUTION_SCOPE`.
The `make regen` markers (`build-args/regen-build-args.sh`) differ:
`# regen-skip: <keys>` keeps the conf's own value for those keys, and
`# regen-versioned: INDEX_BASE_URL` rewrites the last path segment of
`INDEX_BASE_URL` to the argfile `INDEX_VERSION`. Neither classifies the
index.

**Record the rendered index URL, not the bare base URL.** The value baked into
`pip.conf`/`uv.toml` is `INDEX_URL_TEMPLATE` with all variables expanded; read
the template from the conf, never assume it. **Stage matters:** read
`INDEX_STAGE` literally from the conf. On `main` it selects the staging (`-test`)
index; release branches override it and the value differs by branch, so never
state a single release value. Always state which stage the rendered URL
targets, and never present the bare `INDEX_BASE_URL` as the index the images
actually use.

Classify each built conf by its rendered URL (record each as the **rendered**
URL):

- **Channel index:** `INDEX_VARIANT` is a channel name (it parses with the
  channel grammar in `{FONDUE}/rhai-pipeline/src/rhai_pipeline/channel.py`)
  and is a built channel (see overlay 0030). Public or private follows the
  rendered host, per "Public vs private index" in `shared-facts.md`.
  A private index **replaces** the public index entirely: pip and uv are
  configured with a single `index-url` (not `extra-index-url`), so there is no
  fallback to the public index. Those variants use a private index because
  their wheels contain non-redistributable vendor content; downstream product
  container builds consume it directly.
- **Legacy product-versioned index:** `INDEX_VARIANT` is accelerator-only and
  the rendered path carries a product name and version. Record which builder
  (Konflux pipeline or a GitLab CI image without torch versions) uses the
  conf.
- **Legacy torch-versioned index (Konflux only):** confs such as
  `build-args/torch-*-el*-app.conf` whose rendered path is
  `<torch version>-<variant>`. Record whether any `.tekton` pipeline still
  builds them; if none does, the family is Retired.

Do not claim any of these indexes has content: a URL that resolves proves only
that a distribution exists (see "Channel index URL" in `shared-facts.md`).
Conf comments that contradict the catalog or the promote jobs (for example a
comment saying an index does not exist) are drift: report them, do not copy
them.

**pip/uv bootstrap index:** `context/common/index-url.sh`
(`select_bootstrap_cpu_variant`) chooses the CPU index used to install pip and
uv. Describe the regex it matches channel names with and the `case` list of
fallbacks. Whether every fallback is built and every catalog `os` token is
accepted is the bootstrap check in `channels.md`: link overlay 0030 for the
result rather than stating it here.

**Image names, tags and labels:**
- GitLab CI registry path: `IMAGE_BASE` in `gitlab-ci/common.yml`.
- Tags: `bin/image-tag.py` and the tag and `latest` handling in
  `gitlab-ci/common.yml`; `enable_tag_build` in `base_images.variants`.
- Labels: the `LABEL` block in `containerfiles/app-header`. The channel label
  is computed by `compute_base_image_channel_label` in
  `{FONDUE}/bin/regen-ci.py`. Whether its OS token is hardcoded is the image
  channel label check in `channels.md`: link overlay 0030 for the result.
- Konflux image names: `output-image` and the `NAME` build arg in
  `.tekton/*-on-push.yaml`.

**CI tests:** `pulp_test_arches` and `autoqa_test_arches` per
`base_images.variants` entry. This image-specific check is defined here, not
in `channels.md`. Report the current values and any comment on them; a
temporarily disabled test is a state to report each run, not a rule.

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
- `build-args/cuda*-*.conf` (one per CUDA version and torch version) -> CUDA
  toolkit version, `TORCH_CUDA_ARCH_LIST`, `NVIDIA_REQUIRE_CUDA`
- `build-args/rocm7.*.conf` -> ROCm version
- `build-args/spyre-*.conf`, `build-args/gaudi-*.conf`, `build-args/tpu-*.conf`,
  `build-args/neuron-*.conf`, `build-args/rubin-*.conf` -> other
  variant-specific build args

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

Take each variant's built architectures and torch versions from
`base_images.variants` in `{FONDUE}/ci-job-definitions.yml`, not from
`rpms.in.yaml`. Then, for each variant in `context/`, read `rpms.in.yaml` to
determine:
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

Release labels follow the SKILL.md Overlay Rules.

**Fact section** -- Replace entirely with fresh content. This section must cover:

- What the base images are and how downstream teams use them
- **Common foundation** -- base OS image pin (from `argfile.conf`), Python
  version, RHEL AI repo version, the index URL template and the role of
  `INDEX_VERSION` and `TORCH_VERSION`, container layout, environment metadata
  (labels, env vars), helper scripts. Include a one-line note that
  `DISTRIBUTION_SCOPE` is an image label only and does not decide index
  routing.
- **Image families and builders** -- which images GitLab CI builds (one per
  variant and torch version, plus variants without torch versions) and which
  confs each Konflux pipeline builds, with the trigger and output image of
  each; registry paths, tag scheme, and the image name tokens (see "OS
  identity tokens" in `shared-facts.md`). Whether any Konflux pipeline builds
  a channel conf is the Konflux check in `channels.md`: the per-pipeline table
  shows the confs, and overlay 0030 states the result.
- **Dependency management model** -- describe the `rpms.in.yaml` / `rpms.lock.yaml`
  pattern: `rpms.in.yaml` declares packages and arch scoping;
  `rpm-lockfile-prototype` resolves the hermetic lockfile; Konflux/Cachi2
  fetches from locked CDN URLs at build time; MintMaker handles routine drift
  automatically; manual regeneration required only when adding/removing packages
- **Accelerator Summary** table with columns:
  `Accelerator | Version | Status | Python | RHEL | aarch64 | ppc64le | s390x | x86_64 | Torch`.
  Keep one row per accelerator (and per accelerator SDK version); list that
  accelerator's image torch versions in the `Torch` column, never one row per
  torch version. Another skill (`repo-to-architecture-summary`,
  `references/aipcc-analysis.md`) matches images against this table by
  accelerator, version, architectures and status.
- **Status Legend** -- Active / In development / Disabled / Retired. Keep
  these four values: `repo-to-architecture-summary` reads them. An image
  family that only Konflux builds keeps one of them and says "Konflux only"
  in the `Torch` column and its subsection.
- One subsection per accelerator variant covering: status, `rpms.in.yaml` path,
  target architectures, driver/SDK version (from build-args conf or lock),
  `DISTRIBUTION_SCOPE`, notable declared packages (version-pinned or
  arch-scoped), and per image (each torch version, and each Konflux conf): the
  conf file, the container image name, the index class (public channel,
  private channel, legacy product-versioned, legacy torch-versioned, or none)
  and the **rendered `INDEX_URL_TEMPLATE`** (full path incl. channel or
  variant, `-test`/prod stage suffix, and `/simple/`), not the bare
  `INDEX_BASE_URL`
- For **Spyre**: list the IBM SDK RPM version pins from `rpms.in.yaml` and note
  that these are the single source of truth per AIPCC-29839; note which packages
  are arch-conditional (`only: [...]`). **Omit `ibm-aiu-monitor`** from this list
  (see Extract Current State per Variant and Notes)
- **Retired Accelerators** subsection for anything removed from the repo.
  Keep an entry only when it is re-verified absent on `main` and cites the
  removing commit or Jira key. Source each entry, in order, from: (1)
  retirement notes in current `{FONDUE}` docs; (2) otherwise the existing
  overlay entry, limited to the accelerator, version, removing commit or Jira
  key and removal statement: drop every value you could not re-read and report
  the carry-over in Step 5. Drop an entry that cites no
  commit or Jira key. An image family GitLab CI no longer builds but a
  `.tekton` pipeline still builds is not Retired: keep its status and say
  "Konflux only".

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
- A bullet that images are per accelerator and torch version, and that the
  image torch matrix is declared separately from the wheel channel matrix, so
  a built channel can have no image; strategies must pick the torch-qualified
  image and link overlay 0030 for channel identity and recipes
- A bullet on the base-image steps for a new accelerator or torch image,
  derived from current source: the `Containerfile.<accel>-app` and the
  `images/base/Makefile` variant and conf lists, `context/<accel>/rpms.in.yaml`
  with any vendor repo file and its lockfile, one conf per image torch
  version, the `base_images.variants` entry, `make regen`, a Konflux pipeline
  through aipcc-product-management-configs, and the bootstrap fallback in
  `context/common/index-url.sh` when needed. Link overlay 0030 for the
  cross-component recipe
- A bullet explicitly distinguishing the index classes: public channel indexes
  (the default for most strategies); private channel indexes, which
  **replace** the public index entirely (single `index-url`, no fallback)
  because those wheels are non-redistributable, and which downstream product
  builds consume directly; and legacy product-versioned indexes that some confs
  and Konflux pipelines still use. Strategies targeting a private-domain
  variant must not assume the public index is available or sufficient for it.

## Report Details

- Accelerators added, removed, or with changed status/versions
- Images added or removed (per accelerator and torch version), and index class
  changes per image
- Konflux pipeline changes (confs built, triggers, output images)
- Changes to the common foundation (base OS, Python, RHEL AI repo)
- Spyre IBM SDK RPM version changes
- Lockfile model changes, if relevant
- CI test arches (the channel label and bootstrap results are reported by
  the `channels` target)
- Retired entries carried over without re-reading their values

## Notes

- The `rpms.in.yaml` + `rpms.lock.yaml` pattern replaced the old per-variant
  conf-file approach as of 3.6. When reading older overlays or conf files,
  treat them as historical -- the lockfiles are authoritative now.
- **`ibm-aiu-monitor` is intentionally excluded** from this overlay. It is
  present in `context/spyre/rpms.in.yaml` (ppc64le only) but must not be
  documented here: doing so surfaces it to downstream strategy/RFE tooling and
  triggers spurious epics (reviewer request, cf. RHAI-685). Do not re-add it on
  future regenerations, regardless of its version pin in the source.
