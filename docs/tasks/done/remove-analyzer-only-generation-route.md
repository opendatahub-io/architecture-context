# Task: Remove Analyzer-Only Generation Route

## Goal

Ensure every generated architecture summary combines analyzer evidence with
agent synthesis or bounded agent enrichment.

## Result

- Sufficient analyzer readiness always routes to `synthesis`.
- Partial readiness routes to bounded `partial` synthesis.
- Missing or insufficient analyzer evidence routes to `legacy`.
- `analyzer_only_approvals.json` remains available for historical audit tools,
  but no longer selects a generation route.
- The architecture phase always prepares an agent job and no longer copies an
  analyzer baseline as a final analyzer-only document.

## Validation

- Python compilation passed for `lib/architecture_routing.py` and
  `lib/phases/architecture.py`.
- Focused routing assertions were updated to require synthesis for sufficient
  baselines, including contract-complete and source-audited cases.
- `git diff --check` passed.
- Existing pytest infrastructure is unavailable in the host/container
  environment, so the focused pytest suite could not run.

No generated architecture output, raw telemetry, API/OTel dump, secret, or
unrelated worktree change was modified.
