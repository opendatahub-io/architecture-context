---
name: update-fondue-overlays
description: Use when the Fondue monorepo (gitlab.com/redhat/rhel-ai/wheels/fondue) has changed and the AIPCC overlays that document it need refreshing - overlays/0017-aipcc-base-images.md (base images, accelerator support), overlays/0019-wheels-builder.md (builder images, pipeline-API, plugins), overlays/0020-rhai-pipeline.md (collections, channel coverage, Pulp publishing) or overlays/0030-aipcc-content-channels.md (content channel catalog, torch channels, index URLs).
argument-hint: "[base-images] [builder] [rhai-pipeline] [channels] | all"
user-invocable: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(bash ${CLAUDE_SKILL_DIR}/scripts/fetch-fondue.sh)
---

# Update Fondue Overlays

Refresh the overlays that document the Fondue monorepo. One Fondue checkout
feeds four overlays. They stay separate files, but they describe one system
and must agree with each other and with the source.

## Targets

| Target | Overlay | Fondue paths | Rules |
|---|---|---|---|
| `base-images` | `overlays/0017-aipcc-base-images.md` | `images/base/`, `.tekton/` | [references/base-images.md](references/base-images.md) |
| `builder` | `overlays/0019-wheels-builder.md` | `builder/`, `images/builder/` | [references/builder.md](references/builder.md) |
| `rhai-pipeline` | `overlays/0020-rhai-pipeline.md` | `rhai-pipeline/` | [references/rhai-pipeline.md](references/rhai-pipeline.md) |
| `channels` | `overlays/0030-aipcc-content-channels.md` | `rhai-pipeline/channels.yml`, `rhai-pipeline/src/rhai_pipeline/` (`channel.py`, `pulp_*.py`), `rhai-pipeline/package-deletions/`, `rhai-pipeline/bin/upload_to_pulp.sh`, `rhai-pipeline/.gitlab/channel-apply-job.yml`, `rhai-pipeline/supported_versions.yml`, `builder/test/channel_linter.py`, `builder/package_plugins/hooks/upload_after_build_wheel.py`, `ci-job-definitions.yml`, `bin/regen-ci.py`, `.generated/`, `.tekton/`, `images/base/context/common/index-url.sh`, `builder/pipeline-api/`, and every tracked file with an OS token (OS Pins) | [references/channels.md](references/channels.md) |

The `channels` target reads paths the other targets own, so a change there
can leave 0030 stale; Step 4 reports that with `channels` as the target to
rerun.

`$ARGUMENTS` selects the targets (space or comma separated). Empty or `all`
selects all four. If any argument is not a target listed above, stop and list
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

Read every source in [Shared Facts](references/shared-facts.md) from
`{FONDUE}` and record the values. Every selected overlay uses these values
as-is, and Step 4 checks the overlays against them.

### Step 3: Update Each Selected Overlay

For each selected target, in table order:

1. Read its reference file and the Fondue files it lists. Grep large files
   (`rpms.lock.yaml`, anything under `.generated/`) for the values you need;
   do not read them whole.
2. Read the current overlay. If the file does not exist, stop and report it:
   do not create it or invent its front matter.
3. Update the overlay following the reference file and the
   [Overlay Rules](#overlay-rules): rewrite the Fact section, and edit Impact on
   Strategies and Context in place.

### Step 4: Check Consistency

Read all four overlays, including ones not selected in this run, and check
each against the values recorded in Step 2, not against each other:

- **Shared Facts:** every statement an overlay makes about a Shared Facts row
  matches the recorded value, including a channel-awareness result or an OS
  pin restated in 0017, 0019 or 0020 and the values in 0030 itself.
- **Ownership:** a table, list or recipe owned by another overlay (bold in the
  [Shared Facts](references/shared-facts.md) "Overlays" column) is restated
  outside its owner. Replace the copy with the values that overlay's own
  mechanics need and a link to the owner.
- **Channel coverage:** a built channel is one with a `promote-plan-<channel>`
  job in `.generated/rhai-promote-jobs.yml`. For every built channel, check
  that:
  - `rhai-pipeline/channels.yml` has a row for it;
  - its variant has an entry in `builder_images.variants`;
  - `builder/collections/<builder_collection>/<variant>/constraints.txt`
    exists, where `<builder_collection>` comes from
    `rhai_pipeline.torch_versions.<X.Y>.builder_collection`, unless every
    collection that builds the channel skips builder torch constraints for that
    variant (`skip_builder_torch_constraints`);
  - a base image covers it: a `base_images.variants` entry (or `versions` item)
    whose key plus accelerator version is the channel's accelerator and SDK, and
    whose `torch_versions` include the channel's torch version, uses the conf
    `images/base/build-args/<key><accel_version>-torch<X.Y><os_version>-<target>.conf`
    for each entry in `base_images.targets`, and that conf's `INDEX_VARIANT` is
    the channel. Split `<accel_version>` and `<os_version>` from the entry's
    `version` at `-el`, as `split_base_image_version` in `bin/regen-ci.py`
    does. The image torch matrix is declared separately from the wheel matrix,
    so report a built channel without an image as "no image"; it is not a gap
    to fill.

  Also report catalog rows that are not built, and base confs whose
  `INDEX_VARIANT` is not a built channel, with the URL they render. Report
  gaps; do not invent coverage.
- **Index routing:** for each built channel, the catalog row `domain`, the
  `PULP_DOMAIN` of its promote job and the host of its base conf's rendered
  URL agree, and 0017, 0020 and 0030 give it the same public or private label.

Run this check once. For each mismatch: if the overlay was rewritten in this
run, fix it from source. If it was not selected, leave it unchanged and report
the mismatch with the target to rerun.

### Step 5: Report

```
Updated overlays (Fondue {FONDUE} at <commit>):
- overlays/<file>
  - [the items listed in that target's reference under Report Details]
  - Release labels added: [labels | none]
  - Release labels whose version no longer has `release_branch` `main`: [labels | none]
  - Human-authored bullets rewritten or removed: [each one; quote removed bullets verbatim | none]

Source drift: [each Fondue README or comment that contradicts code | none]
Consistency check: [OK | each mismatch, and whether it was fixed or needs a rerun]
```

List the overlays updated in this run, in table order.

## Shared Facts

The Shared Facts table is in
[references/shared-facts.md](references/shared-facts.md): one row per fact
that more than one overlay states, with its authoritative source and the
overlays that state it (a bold entry marks the owner).

## Overlay Rules

- **Front matter:** preserve `id`, `title`, `status`, `created`, `affects`,
  `provenance`, `author` and `superseded_by`.
- **Release labels:** only add to `release`. Keep every existing label, make
  sure `next` is present, and add the version whose `release_branch` is `main`
  in `rhai-pipeline/supported_versions.yml` if it is missing. Never remove a
  label.
- **Fact:** replace entirely with content read from current source. Never carry
  a value over from the existing overlay without re-reading its source. Fact
  content comes from `{FONDUE}` `main` only: team docs, live index checks and
  unmerged branches are not Fact sources. Exception: Retired entries follow
  the sourcing order in their reference file (`main`'s git history, or a
  limited carry-over that Step 5 reports).
- **Headings:** inside Fact and Impact on Strategies, subsections use `###` or
  deeper, never `##`. The overlay linter and arch-query split sections on
  `## `, so a `##` heading cuts the section short.
- **Source precedence:** Fondue configuration and code win over Fondue READMEs
  and conf comments. When they disagree, follow the code and report the drift.
- **Time-bound states:** references list checks for states that change often
  (pipelines not yet channel-aware, temporarily disabled jobs, hardcoded
  fallbacks). Run each check, state the result as of the commit, and report it.
  Never copy such a state into rule text, and never cite an unmerged branch as
  a fact.
- **Impact on Strategies and Context are human-authored:** edit them in place.
  Keep existing bullets and rationale, including ones the reference does not
  list, and make sure every bullet the reference requires is present. Never
  regenerate these sections wholesale. When a bullet's subject no longer exists
  in source, rewrite it to the current subject and keep its rationale. Delete a
  bullet only when its rationale no longer applies and its subject is a Fondue
  artifact (variant, collection, file, job, config key) confirmed absent on
  `main`. Never delete a bullet whose subject is outside Fondue (Jira
  decisions, consumers, Konflux or PMC configuration, other overlays). Report
  every rewrite and removal in Step 5.
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
- **Tracked content only:** a Fondue checkout can hold nested git worktrees and
  tool directories (such as `.claude/` and `.Codex/`) on old commits; the fetch
  script's clean check does not see them. Glob and Grep named Fondue
  subdirectories rather than the checkout root, exclude those directories, and
  never cite a file that exists only there.
- `tmp/` is in `.gitignore`; any clone is local only.
- Do not commit changes to the Fondue repository or to GitLab.
