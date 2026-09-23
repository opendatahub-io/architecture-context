# Regenerate the Fondue overlays with update-fondue-overlays

Follow-up to [RHAI-2466](https://redhat.atlassian.net/browse/RHAI-2466)
([done task](../done/unify-fondue-overlay-skills.md)), which changed the skill
but deliberately did not regenerate overlay content.

Downstream tools still consume these statements, which the skill's Shared
Facts now mark as wrong (checked against Fondue `ee083a373`, 2026-09-23):

- `overlays/0019-wheels-builder.md:23-25`: says `rhai-pipeline` pins a builder
  release tag; it uses the in-tree builder.
- `overlays/0019-wheels-builder.md:50-51,305`: calls `v46.0.0` the latest
  release and says consumers lag it; `v46.0.1` is a patch tagged on `3.6-EA2`.
- `overlays/0019-wheels-builder.md:243`: aligns torch-sendnn with
  `SPYRE_VERSION`, which no longer exists (AIPCC-29839).
- `overlays/0020-rhai-pipeline.md:18-20`: uses the retired names
  `rhai/pipeline` and `redhat/rhel-ai/wheels/builder`.
- `overlays/0020-rhai-pipeline.md:40-44,411`: says the builder resolves at
  tip-of-`main`; MR pipelines use that MR's builder images.
- `overlays/0020-rhai-pipeline.md:405-440` and
  `overlays/0017-aipcc-base-images.md:486-500`: Context holds per-run change
  logs and restated values, which the skill now removes from Context.
- `overlays/0021-rhaiis-pipeline.md:36-38,389`: calls the `v46.0.1` pin
  "marginally ahead of" the builder release.

The separate `update-rhaiis-pipeline-overlay` skill (kept unchanged in
RHAI-2466) will reintroduce two of these on its next run:

- `SKILL.md:177`: "The SPYRE_VERSION runtime (RPM stack) is owned by the base
  image".
- `SKILL.md:180`: "builder version lag between this repo and rhai/pipeline"
  assumes rhai-pipeline has a builder version.

## Acceptance

- Run `/update-fondue-overlays all` against a clean Fondue `main` and review
  the diff of 0017, 0019 and 0020; the Step 4 consistency check reports OK.
- Correct the two rhaiis skill lines, then rerun it for 0021.
- Decide which overlay is authoritative for the vLLM versions of the Fondue
  `rhai-pipeline/collections/rhaiis/` collection vs the `rhaiis/pipeline`
  repository before rhaiis moves into Fondue.
