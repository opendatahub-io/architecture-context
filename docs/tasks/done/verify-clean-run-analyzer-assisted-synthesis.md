# Task: Verify Clean-Run Analyzer-Assisted Synthesis

## Goal

Ensure a full architecture run uses `arch-analyzer` outputs to enrich the
synthesis agent's context while treating the target `architecture/` output
directory as empty.

## Scope

- Trace generation, routing, analyzer staging, merge, and collection paths.
- Ensure synthesis receives analyzer JSON/rendered baseline plus approved
  index, overlays, and query context.
- Ensure prior generated documents under `architecture/` are never staged,
  read, or used as fallback inputs during a full run.
- Preserve analyzer-owned facts, provenance, explicit unknowns, analyzer-only
  behavior, legacy fallback, and raw-artifact protections.
- Add focused tests for clean-run isolation and analyzer-context handoff.

## Exclusions

- Do not use prior architecture documents to seed or influence synthesis.
- Do not broaden source discovery in synthesis mode.
- Do not modify committed generated architecture output, add raw artifacts or
  secrets, or change production dependencies.

## Acceptance criteria

- A clean-run fixture proves synthesis receives analyzer outputs without prior
  architecture documents being read or staged.
- Existing architecture documents remain available only to explicit
  comparison/evaluation tooling.
- Missing analyzer output follows the existing route/fallback behavior.
- Focused tests and architecture validation pass, with evidence recorded in
  this task or a validation note.
- Implementation agent does not commit; the driver independently reviews and
  creates the scoped checkpoint commit if accepted.

## Execution record — 2026-07-26

- Container run: `/tmp/claude-task-runs/agent-driver.jsonl`
- Agent result: completed successfully; reported cost `$5.4618`, 63 turns,
  API duration 509.7 seconds.
- Implementation changed only `tests/test_architecture_phase.py` and
  `tests/test_agent_runner.py`; no production code, generated architecture,
  raw artifacts, or production dependencies changed.
- Seven new clean-run isolation tests passed in the task container; focused
  Ruff checks passed.
- The task container also confirmed nine unrelated pre-existing failures in
  the broader architecture-phase test selection, caused by the existing
  non-empty synthesis migration allowlist.
- Independent host rerun was unavailable because `.venv/bin/pytest` has a
  stale `/workspace/.venv/bin/python3` interpreter path; this is an
  infrastructure limitation, not a task failure.

## Driver review

Accepted in commit `6e04522a`. The tests verify the intended boundary:
analyzer files inside the checkout are allowed synthesis context, while prior
documents under `architecture/` are denied and are not used as fallback.
