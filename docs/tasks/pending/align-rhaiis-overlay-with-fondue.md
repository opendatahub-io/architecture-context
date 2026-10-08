# Align the rhaiis overlay and skill with the Fondue facts

Follow-up to [RHAI-2466](https://redhat.atlassian.net/browse/RHAI-2466) and
[regenerate-fondue-overlays](../done/regenerate-fondue-overlays.md). The
`update-rhaiis-pipeline-overlay` skill and overlay 0021 were out of scope there
and now contradict overlays 0017, 0019 and 0020 (checked 2026-09-23, rechecked
2026-10-01 against Fondue `18d0c049d`):

- `overlays/0021-rhaiis-pipeline.md` uses the retired name `rhai/pipeline`
  (lines 25, 277, 384, 390, 408, 425), cites `SPYRE_VERSION` (380), and says
  rhai-pipeline resolves the builder at "tip-of-main" (390-392). Its Impact
  bullet title still calls the `v46.0.1` pin "current on `main`" (385); that
  pin is a patch tagged on `3.6-EA2`. The clauses comparing it with the
  builder release in 0019 were dropped under
  [RHAI-4469](https://redhat.atlassian.net/browse/RHAI-4469)
  ([refresh-fondue-overlays-for-channels](../done/refresh-fondue-overlays-for-channels.md)).
- `.claude/skills/update-rhaiis-pipeline-overlay/SKILL.md:177` ("The
  SPYRE_VERSION runtime ...") and `:180` ("builder version lag between this
  repo and rhai/pipeline") will reintroduce two of those on the next run.

## Acceptance

- Correct the two skill lines, rerun `update-rhaiis-pipeline-overlay`, and
  confirm 0021 no longer contradicts the Shared Facts in
  `.claude/skills/update-fondue-overlays/references/shared-facts.md`.
- Decide which overlay is authoritative for RHAIIS vLLM versions: the Fondue
  `rhai-pipeline/collections/rhaiis/` collection (now one
  `torch/requirements-torch-<X.Y>.txt` pin per torch version) and the
  `rhaiis/pipeline` repository pin vLLM independently (e.g. spyre
  `0.27.1+rhaiv.1.spyre` in 0021 vs `+rhaiv.4.spyre` in Fondue; the earlier
  cuda13.0 example now matches at `+rhaiv.3`).

## Fondue-side issues found during review (not overlay work)

Raise with the Fondue owners:

- Resolved: the AutoQA/qualify URL that `.generated/rhai-promote-jobs.yml`
  built for private `rhai`-domain indexes on `packages.redhat.com`.
  `2eadc6043` (AIPCC-32633) moved private promote `INDEX_URL`s to
  `private.console.redhat.com/api/pypi/`, and `regen-ci.py` now picks the host
  from the channel's domain. Three private channels remain on `main`
  (`gaudi-torch2.11-el9.8`, `neuron-torch2.9-el9.8`, `tpu-torch2.10-el9.8`;
  named `-ubi9` before AIPCC-32814; checked at Fondue `d57f272`).
- `images/base/README.md` still marks Gaudi disabled (AIPCC-3471) and lists
  stale versions; `rhai-pipeline/README.md` shows ROCm on torch 2.13.0.
