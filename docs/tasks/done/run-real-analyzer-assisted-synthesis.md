# Task: Run Real Analyzer-Assisted Synthesis on Operator and Dashboard

## Goal

Exercise the refactored skill end-to-end on real `rhods-operator` and
`odh-dashboard` checkouts using fresh analyzer artifacts and clean temporary
outputs.

## Scope

- Use read-only source checkouts and fresh `component-architecture.json` plus
  `ANALYZER_ARCHITECTURE.md` artifacts.
- Run the actual repo-to-architecture-summary skill through analyzer-first
  synthesis/analyzer-only routes; use a synthetic or available real partial
  component to exercise targeted narrative reads if needed.
- Verify generated narrative sections, analyzer fact preservation, source
  references, merge/validation results, route/read telemetry, and no prior
  `architecture/` input.
- Produce a tracked human-readable report; keep generated documents, logs,
  OTel/API dumps, and MLflow files under ignored `tmp/` paths.

## Acceptance criteria

- Real generated outputs are valid and preserve analyzer-owned facts.
- Synthesis consumes analyzer artifacts first and does not read prior outputs.
- Targeted route evidence shows only declared bounded source reads; sufficient
  routes remain source-free.
- Local file-backed MLflow and redacted OTel/API capture work without external
  services or human labels.
- Report includes methodology, outputs, route/read evidence, costs, limits,
  and conclusions. Implementation agent does not commit.

## Execution record — 2026-07-27

- Validation run: `/tmp/claude-task-runs/agent-driver.jsonl`, reported cost
  `$8.4473`; raw outputs remain under ignored `tmp/real-synth-20260727-000232/`.
- Real outputs: `rhods-operator` 548 lines and `odh-dashboard` 616 lines;
  both passed architecture validation, with one informational analyzer-section
  warning on dashboard.
- Analyzer-owned rows were preserved with zero fact loss: 267 rows for
  rhods-operator and 364 rows for odh-dashboard.
- Real synthesis/analyzer-only routes performed zero source reads; a clearly
  marked synthetic partial route performed 4 reads within an 8-file budget and
  discovered a missing endpoint.
- 81 focused tests passed; 14 existing allowlist/fixture failures were
  documented as pre-existing. Go tests and architecture validators passed.
- Redacted OTel/API captures were written under ignored `tmp/`.
- The run configured local MLflow but the SDK was unavailable, so it recorded
  a manual file-backed record. The actual MLflow FileStore path remains
  independently validated by the completed 320-session provisional evaluation
  and its local read-back report; this run does not claim SDK-level tracking.
- Report: `docs/notes/real-analyzer-assisted-synthesis-report.md`.

## Driver review

Accepted. The end-to-end skill behavior and generated outputs satisfy the
task; the documented MLflow SDK limitation is execution-environment-specific,
not an external-service requirement or implementation blocker.
