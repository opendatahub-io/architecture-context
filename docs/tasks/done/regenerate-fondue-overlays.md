# Regenerate the Fondue overlays with update-fondue-overlays

Follow-up to [RHAI-2466](https://redhat.atlassian.net/browse/RHAI-2466)
([skill task](unify-fondue-overlay-skills.md)). Completed 2026-09-23.

Ran `/update-fondue-overlays all` in a subagent against Fondue `main`
`ee083a373` (3.6, `supported_versions.yml` maps 3.6 to `main`). The skill
refreshed 0017, 0019 and 0020, removed the per-run change logs from Context,
and its consistency check reported no mismatches and one real gap: the Rubin
base image points at `rhoai/3.6/rubin-ubi9`, which no Fondue pipeline
publishes.

Review: four independent adversarial reviews ran in parallel, one fact-check
per overlay against Fondue source and one for skill-rule compliance and
cross-overlay consistency. All four returned REQUEST_CHANGES (two blocking
findings: 0017 said SDK version pins are not in wheel requirements; 0019 said
builder changes are validated by rhai-pipeline builds within the MR). Findings
were fixed in the overlays, and where the skill's own wording caused a wrong
claim, in the skill references too. One finding was rejected with evidence:
the claim "vLLM dropped CUDA 12 support upstream" stays removed, because the
builder builds `vllm[...,cgraph-cuda12]` for `cuda12.9-ubi9` (AIPCC-31069).

Validation run: the final skill was then run from scratch in a throwaway
worktree against Fondue `330d9f9ee` (AIPCC-32500 refreshed the RHEL base image
and lockfiles), and an independent review classified every difference from the
reviewed overlays. The fold-back adopted the new base OS pin and source commit,
three source-backed facts, and five corrections, and kept the reviewed text
wherever the fresh run dropped a still-true fact. The main correction: on
`main`, full `rhai-pipeline/` builds run only in the nightly schedule, because
the root `.gitlab-ci.yml` loads `.generated/rhai-*.yml` only for MR and nightly
pipelines; `build_on_all_pushes` has no effect on pushes to `main`. The skill's
Shared Facts had the same error and are corrected.

Known limitations: the fetch script refreshes only `main`, so release-branch
facts (e.g. `3.6-EA2` settings) come from local `origin/*` refs that may be
stale; and `allowed-tools` has no read-only git history access, which the
"Retired Accelerators" rule in `references/base-images.md` needs.

The statements this task listed as wrong in 0019 and 0020 are corrected. The
0021 and rhaiis-skill items moved to
[align-rhaiis-overlay-with-fondue](../pending/align-rhaiis-overlay-with-fondue.md).
