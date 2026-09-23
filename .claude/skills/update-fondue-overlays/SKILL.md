---
name: update-fondue-overlays
description: Use when the Fondue monorepo (gitlab.com/redhat/rhel-ai/wheels/fondue) has changed and the AIPCC overlays that document it need refreshing - overlays/0017-aipcc-base-images.md (base images, accelerator support), overlays/0019-wheels-builder.md (builder images, pipeline-API, plugins) or overlays/0020-rhai-pipeline.md (published variants, collections, Pulp publishing).
argument-hint: "[base-images] [builder] [rhai-pipeline] | all"
user-invocable: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(bash ${CLAUDE_SKILL_DIR}/scripts/fetch-fondue.sh)
---

# Update Fondue Overlays

Refresh the overlays that document the Fondue monorepo. One Fondue checkout
feeds three overlays. They stay separate files, but they describe one system
and must agree with each other and with the source.

## Targets

| Target | Overlay | Fondue paths | Rules |
|---|---|---|---|
| `base-images` | `overlays/0017-aipcc-base-images.md` | `images/base/` | [references/base-images.md](references/base-images.md) |
| `builder` | `overlays/0019-wheels-builder.md` | `builder/`, `images/builder/` | [references/builder.md](references/builder.md) |
| `rhai-pipeline` | `overlays/0020-rhai-pipeline.md` | `rhai-pipeline/` | [references/rhai-pipeline.md](references/rhai-pipeline.md) |

`$ARGUMENTS` selects the targets (space or comma separated). Empty or `all`
selects all three. If any argument is not a target listed above, stop and list
the valid targets. For `rhaiis` or `0021`, point to the
`update-rhaiis-pipeline-overlay` skill: `rhaiis/pipeline` is still a separate
repository and overlay 0021 is out of scope here.

## Workflow

### Step 1: Locate Fondue

Run the fetch script from the root of the architecture-context repository:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/fetch-fondue.sh
```

It prints the absolute path of the Fondue monorepo root. Use it as `{FONDUE}`
in every step and reference file. The script uses `$FONDUE_PATH` if exported,
else `../fondue`, else the `./tmp/fondue` cache (cloned if absent). Every
checkout it returns, including the cache and a fresh clone, is the top level of
a clean `main` at the freshly fetched `origin/main`, with the Fondue repository
as origin. It never modifies your own checkouts; only the cache is
fast-forwarded, and only when it is a clean `main` that is merely behind. It
logs the checkout and commit on stderr; record both for the report.

If the script exits non-zero, stop and show its error to the user. Do not
locate, clone, or choose a Fondue directory yourself. Users who keep Fondue
elsewhere export `FONDUE_PATH` before starting the session.

### Step 2: Read the Shared Facts

Read every source in [Shared Facts](#shared-facts) from `{FONDUE}` and record
the values. Every selected overlay uses these values as-is, and Step 4 checks
the overlays against them.

### Step 3: Update Each Selected Overlay

For each selected target, in table order:

1. Read its reference file and the Fondue files it lists. Grep large files
   (`rpms.lock.yaml`, anything under `.generated/`) for the values you need;
   do not read them whole.
2. Read the current overlay.
3. Update the overlay following the reference file and the
   [Overlay Rules](#overlay-rules): rewrite the Fact section, and edit Impact on
   Strategies and Context in place.

### Step 4: Check Consistency

Read all three overlays, including ones not selected in this run, and check
each against the values recorded in Step 2, not against each other:

- **Shared Facts:** every statement an overlay makes about a Shared Facts row
  matches the recorded value.
- **Variant coverage:** every variant in `rhai-pipeline/publish_config.yml` has
  an entry in `builder_images.variants`, and every base image in
  `base_images.variants` maps to a published index. A base image entry
  `<key>` with `version` `<v>` uses the conf
  `images/base/build-args/<key><v>-<target>.conf` for each entry in
  `base_images.targets` (e.g. `torch-cpu` + `-el9.8` + `app` ->
  `torch-cpu-el9.8-app.conf`); its `INDEX_VARIANT` and
  `INDEX_VERSION` name the index. An `INDEX_VERSION` equal to the wheel index
  product version means a product-versioned index
  (`<PRODUCT_NAME>/<PRODUCT_VERSION>/<INDEX_VARIANT>`, `PRODUCT_NAME` `rhoai`
  unless an override sets it); any other value (e.g. `torch-2.14.0`) means the
  `PULP_BASE_PATH` override `<INDEX_VERSION>-<INDEX_VARIANT>` in
  `rhai_pipeline.variant_overrides`. Report gaps; do not invent coverage.
- **Index routing:** for each base image, the public/private label in 0017 and
  the Pulp domain in 0020 for its mapped index both match the source
  `PULP_DOMAIN` after `_default` -> `overrides` -> `variant_overrides`
  precedence.

Run this check once. For each mismatch: if the overlay was rewritten in this
run, fix it from source. If it was not selected, leave it unchanged and report
the mismatch with the target to rerun.

### Step 5: Report

```
Updated overlays (Fondue {FONDUE} at <commit>):
- overlays/<file>
  - [the items listed in that target's reference under Report Details]

Consistency check: [OK | each mismatch, and whether it was fixed or needs a rerun]
```

List the overlays updated in this run, in table order.

## Shared Facts

Paths are relative to `{FONDUE}`. Read every value from source on each run.

| Fact | Authoritative source | Overlays |
|---|---|---|
| Variant × arch matrix | `ci-job-definitions.yml` (Fondue's declared single source of truth for the CI matrix): `base_images.variants`, `builder_images.variants`, `rhai_pipeline.variants` / `collections` / `omit_jobs`. Published variants: `rhai-pipeline/publish_config.yml`. Job templates such as `images/builder/gitlab-ci/images.yml` and directory listings are not the matrix. | 0017, 0019, 0020 |
| Builder release tag | `releases/builder-release.yaml` -> `version`: the release declared on `main` (there is no `builder/release.yaml`). Patch releases such as `v46.0.1` are tagged on release branches and never appear here, so never describe a consumer's pinned tag as ahead of or behind the builder. | 0019, 0020 (context only) |
| Base OS (RHEL) version | `builder/product-version.yml` -> `PRODUCT_VERSION` (e.g. `0.0-el9.8`; the OS the builder targets, not a builder release), `images/builder/build-args/common.conf` -> `BASE_IMAGE`, `images/base/build-args/argfile.conf` -> `APP_BASE_IMAGE`. All three name the same RHEL minor; if not, report each value. | 0017, 0019, 0020 |
| Wheel index product version | `rhai-pipeline/product-version.yml` -> `PRODUCT_VERSION`; `images/base/build-args/argfile.conf` -> `INDEX_VERSION` should match. If they differ, report both; do not pick one. | 0017, 0020 |
| How consumers get the builder | `rhai-pipeline/` uses the in-tree builder: `builder-image-version.yml` (included last by `.gitlab-ci.yml`) sets `BUILDER_IMAGE_VERSION` to `ci-${BUILDER_PRODUCT_VERSION}-${CI_MERGE_REQUEST_IID}`, so MR pipelines use that MR's builder images and post-merge pipelines use `main`'s. It is not a release tag. `rhaiis/pipeline` is outside Fondue: say it pins a Fondue release ref and link overlay 0021; do not restate its pin. | 0019, 0020 |
| Public vs private index | Pulp routing: `ci-job-definitions.yml` `rhai_pipeline.overrides` and `variant_overrides` (0020). Image-side index: rendered `INDEX_URL_TEMPLATE` from `images/base/build-args/*.conf` (0017). Classify by the rendered `INDEX_BASE_URL` host (`packages.redhat.com` public, `private.console.redhat.com` private), not by `DISTRIBUTION_SCOPE`. Private-domain variants carry non-redistributable vendor wheels (AIPCC-28553); torch-day0 variants stay public with a `PULP_BASE_PATH` override. | 0017, 0020 |
| Spyre IBM stack | SDK RPM pins: versioned package names in `images/base/context/spyre/rpms.in.yaml` (AIPCC-29839; there is no `SPYRE_VERSION` build arg). Wheel sourcing: `builder/overrides/settings/torch_sendnn.yaml` and `torch_nnpa.yaml` (pre-built, private index). Wheel version pins: the consuming collection's `requirements.txt`. torch-sendnn tracks the SDK RPM version; torch-nnpa has its own version line. | 0017, 0019, 0020 |
| aiu-monitor | Not a wheel collection package; it ships as an RPM in the Spyre base image. The `aiu-monitor<0.0.0` / `ibm-aiu-monitor<0.0.0` guards were removed from `builder/collections/global-constraints.txt` (AIPCC-28729); grep that file before claiming any guard exists. Overlay 0017 must not mention `aiu-monitor` or `ibm-aiu-monitor` at all (see its reference), so skip this row when checking 0017. | 0019, 0020 |

## Overlay Rules

- **Front matter:** preserve `id`, `title`, `status`, `created`, `affects`,
  `provenance`, `author` and `superseded_by`. Change `release` only under the
  condition the reference file gives.
- **Fact:** replace entirely with content read from current source. Never carry
  a value over from the existing overlay without re-reading its source.
- **Impact on Strategies and Context are human-authored:** edit them in place.
  Keep existing bullets and rationale, including ones the reference does not
  list, and make sure every bullet the reference requires is present. Never
  regenerate these sections wholesale.
- **Context:** update the date and version references. When it names the skill
  used, name `update-fondue-overlays`. Context holds rationale only: lists of
  what changed in a run belong in the Step 5 report, and per-run change logs or
  restated Fact values already in Context are not rationale, so delete them.
- **Component names:** refer to components by Fondue path (`images/base/`,
  `builder/`, `images/builder/`, `rhai-pipeline/`); `rhai/pipeline`,
  `wheels/builder` and the standalone base-images repository are retired
  names. The `rhai-pipeline/collections/rhaiis/` collection is not the
  `rhaiis/pipeline` repository (overlay 0021); say which one you mean.
- **Jira references:** keep them while the statement they support is still
  true; remove them when it no longer is.

## Notes

- **Trust assumption:** the fetch script validates the git remote origin of the
  local checkout and of any `./tmp/fondue` clone against the allowlisted Fondue
  repository (HTTPS and SSH forms are both accepted). Only read Fondue content
  from the path it prints. Do not execute scripts from the checkout.
- `tmp/` is in `.gitignore`; any clone is local only.
- Do not commit changes to the Fondue repository or to GitLab.
