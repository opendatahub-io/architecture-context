# Adapt the Evaluation Runner to the Condition Contract

Implemented deterministic condition planning and preflight integration for
the analyzer-assisted evaluation contract.

## Delivered

- Added `benchmark/analyzer-assisted-v1/planner.py` with manifest loading,
  stable active-question subsets, condition availability, access boundaries,
  and manifest-declared provenance validation.
- Added explicit condition, manifest, question subset, artifact, and dry-run
  options to `benchmark/consumer-v1/run_evaluation.py`.
- Pending conditions emit `condition_unavailable` output and never fall back
  to baseline. Planning paths do not require the Claude SDK or launch agents.
- Available baseline execution retains consumer-v1 result fields and adds
  condition/provenance metadata compatibly.

## Validation

- 145 focused pytest tests passed across the planner, runner, and evaluation
  contract suites.
- Ruff and `git diff --check` passed.
- Host dry-run passed for a stable active subset without `claude_agent_sdk`.
- Host pending-condition output passed the explicit unavailable/no-fallback
  assertions.
- No paid, full-corpus, or external-agent evaluation was run.
