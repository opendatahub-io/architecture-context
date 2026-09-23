# Align the rhaiis overlay and skill with the Fondue facts

Follow-up to [RHAI-2466](https://redhat.atlassian.net/browse/RHAI-2466) and
[regenerate-fondue-overlays](../done/regenerate-fondue-overlays.md). The
`update-rhaiis-pipeline-overlay` skill and overlay 0021 were out of scope there
and now contradict overlays 0017, 0019 and 0020 (checked 2026-09-23):

- `overlays/0021-rhaiis-pipeline.md` uses the retired name `rhai/pipeline`
  (lines 25, 279, 386, 393, 411, 428), cites `SPYRE_VERSION` (382), calls the
  `v46.0.1` pin "marginally ahead of" the builder release (38, 389; it is a
  patch tagged on `3.6-EA2`), and says rhai-pipeline resolves the builder at
  "tip-of-main" (393-395).
- `.claude/skills/update-rhaiis-pipeline-overlay/SKILL.md:177` ("The
  SPYRE_VERSION runtime ...") and `:180` ("builder version lag between this
  repo and rhai/pipeline") will reintroduce two of those on the next run.

## Acceptance

- Correct the two skill lines, rerun `update-rhaiis-pipeline-overlay`, and
  confirm 0021 no longer contradicts the Shared Facts in
  `.claude/skills/update-fondue-overlays/SKILL.md`.
- Decide which overlay is authoritative for RHAIIS vLLM versions: the Fondue
  `rhai-pipeline/collections/rhaiis/` collection and the `rhaiis/pipeline`
  repository pin vLLM independently (e.g. cuda13.0 `0.28.0+rhaiv.1` vs
  `+rhaiv.3`).

## Fondue-side issues found during review (not overlay work)

Raise with the Fondue owners:

- `.generated/rhai-promote-jobs.yml` builds the AutoQA/qualify URL for the five
  private `rhai`-domain indexes on `packages.redhat.com`; private consumers use
  `private.console.redhat.com`. `regen-ci.py` only switches hosts on
  `PULP_BASE_URL`, which AIPCC-31824 removed.
- `images/base/README.md` still marks Gaudi disabled (AIPCC-3471) and lists
  stale versions; `rhai-pipeline/README.md` shows ROCm on torch 2.13.0.
