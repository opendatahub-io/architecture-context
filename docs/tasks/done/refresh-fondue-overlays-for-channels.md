# Refresh the Fondue overlays for content channels

Tracked in [RHAI-4469](https://redhat.atlassian.net/browse/RHAI-4469).
Completed 2026-10-01.

Fondue moved `rhai-pipeline/` from product-versioned indexes
(`rhoai/<PRODUCT_VERSION>/<variant>`) to content channels
(`<accel><sdk>-torch<X.Y>-<os>`), with per-torch base images and builder torch
collections. Overlays 0017, 0019 and 0020 and the `update-fondue-overlays`
skill still presented torch-day0, the `publish_config.yml` publish, mTLS and
`rhoai/3.6` as the current path. Channels span all three overlays, so none of
them could own the topic.

Decisions:

- **Overlay shape:** new `overlays/0030-aipcc-content-channels.md` and a fourth
  skill target, `channels` (`references/channels.md`). 0030's front matter,
  Impact and Context are hand-authored; the skill writes its Fact.
- **Ownership:** one owner per topic, marked in bold in the "Overlays" column
  of the Shared Facts table, which moved to `references/shared-facts.md` to
  keep `SKILL.md` within skillsaw's context budget. 0030 owns channel identity,
  the catalog (the owner of built status), URL derivation,
  the torch to builder-collection map and per-variant default torch lists,
  the channel-awareness results, the OS pin list and the cross-component
  recipes. 0020 keeps upload, promote, cache, deletion and the
  legacy publish; 0019 keeps the pipeline-API inputs and builder collection
  directories; 0017 keeps confs, rendered URLs, labels, Konflux and the
  per-accelerator Accelerator Summary that `repo-to-architecture-summary`
  consumes. Step 4 flags owned content restated elsewhere.
- **Release labels:** rechecked on every run against
  `rhai-pipeline/supported_versions.yml`. `next` always stays, the version
  whose `release_branch` is `main` is added, and a label is removed once its
  release builds from another branch (the Fact covers `main` only); the report
  flags whether a release-pinned overlay should be split off. The rule lives
  once in `SKILL.md`. `3.7` was added by hand to 0017, 0019, 0020
  and 0030 because team docs name RHOAI 3.7 EA as the switch to channel
  references; the rule would not add it while `main` is the 3.6 line.
- **Checks, not rules:** time-bound states (Konflux channel awareness, the
  `-ubi9` label hardcode, AutoQA, channel deletion, built channels without
  images) are reported on each run, never written into rules. Fondue code
  beats READMEs and comments; facts come from tracked content on `main` only.
- **Human-authored bullets:** rewrite to the current subject and keep the
  rationale; delete only when the subject is a Fondue artifact confirmed absent.
- **OS pins are Fact:** the files a new OS stream touches moved out of 0030's
  Impact bullet into a generated `### OS Pins` Fact subsection: tracked files
  across the whole tree, a fixed token set, a scope per row (per variant, per
  OS or single value) and a cross-check against Fondue's own RHEL bump
  guidance. The Impact bullet keeps only the rationale.
- **Status vocabulary:** 0017 keeps the four statuses `repo-to-architecture-summary`
  reads. Images that only Konflux builds stay Active and say "Konflux only".
  Retired entries stay only when they cite the removing commit or Jira key;
  their values come from current Fondue docs or are dropped. The skill runs
  no `git` command beyond the fetch script, which keeps its tool grant to that
  one validated script.

Scope: the skill (`SKILL.md`, all references, plus the new `channels.md` and
`shared-facts.md`); 0017, 0019 and 0020 regenerated with
`/update-fondue-overlays all` against Fondue `18d0c049d`; 0030 created. The
run rewrote human-authored Impact bullets in place and removed none; owner
review: 0017 (Doug Hellmann), 0019 and 0020 (Lance Barto). In 0021 only the
clauses comparing its builder pin with 0019 were dropped; the rest stays with
[align-rhaiis-overlay-with-fondue](../pending/align-rhaiis-overlay-with-fondue.md).
Untouched: 0014, 0025, team-docs, `PLAN.md` and the generated `architecture/`
(0030 appears in `INDEX.md` at the next index phase).

Validation: `make lint-overlays` (35 pass), `make lint-architecture-docs`
(912 pass), `uv run pytest tests/test_fetch_fondue.py -q` (17 passed) and
`skillsaw lint` on the skill (0 errors, 0 warnings, A+).

Review: independent code and architecture reviews, plus a from-scratch rerun
of the skill from the `origin/main` overlays in a throwaway worktree, whose
Fact output converged with the reviewed overlays and whose Step 4 passed. All
24 confirmed findings were merged into one fix list and fixed, each
re-verified against Fondue `18d0c049d`. PR review then found that the rules
called `git` outside the skill's tool grant and that the release label rule
could never drop a stale label; both were fixed.

Raise with owners:

- Team-docs write channel URLs as `public-rhai/rhoai/<channel>` in eight files
  (`docs/rfds/AIPCC-27889.md` and, under `docs/ecosystems/`,
  `architecture-base-images.md`, `guide-content-channels.md`,
  `guide-package-index-rss-feeds.md`, `how-tos/base-images-adoption.md`,
  `how-tos/hermetic-pip-prefetch.md`,
  `policy-release-content-delivery-streams.md` and `reference-consumer-faq.md`).
  No catalog row sets `namespace`, so Fondue serves `public-rhai/<channel>`;
  the `rhoai/` form returned 404 on 2026-10-01.
- Rubin: `rubin-el9.8-app.conf` renders `public-rhai/rhoai/3.6/rubin-ubi9-test`,
  which no `main` job writes and which returned 404 on 2026-10-01. It says
  driver R615; the builder `rubin-ubi9.conf` says R616.
- `rhai-pipeline/README.md:194` says `channel-apply` can run from another
  branch (the job requires the default branch), and its mTLS
  `PULP_CERT_BASE64`/`PULP_KEY_BASE64` sections contradict the TBR basic auth
  in `pulp_config.py`.
- `builder/pipeline-api/ci-wheelhouse.yml` describes `PULP_CACHE` as "Builder
  collections only"; most `rhai-pipeline/` jobs set it to `true`.
- `spyre-el9.8-app.conf:11` and `spyre-torch2.11-el9.8-app.conf:11` say
  "index does not exist"; `spyre-torch2.11-ubi9` is built.
- Deletion manifests have a bypass: during `build-wheels`, the build hook's
  Pulp cache upload (`upload_to_pulp_cache` in
  `builder/package_plugins/hooks/upload_after_build_wheel.py`) adds wheels
  and sdists to the channel `-test` repository without reading
  `rhai-pipeline/package-deletions/`. Only `pulp upload` filters
  (`_apply_blocking` in `pulp_upload.py`), and neither `pulp promote` nor
  `pulp delete` removes a listed package from a channel repository, so a
  blocked package can reach production through `wheel-promote`.
- `builder/bin/build_from_graph.sh` still uses the `-0.0-el9.6` builder
  cache prefix; Fondue's own RHEL minor bump rule (`AGENTS.md`) says to
  update it with `builder/bin/bootstrap.sh` (`-0.0-el9.8`).

Follow-up (out of scope): `repo-to-architecture-summary`
(`references/aipcc-analysis.md`) detects AIPCC base images by
`quay.io/aipcc/base-images/*`, but GitLab CI now publishes
`aipcc-<accel><sdk>-torch<X.Y>-<os>-app` to the Fondue registry and Konflux
builds `quay.io/redhat-user-workloads/ai-tenant/base-images/base-image-<accel>`.
