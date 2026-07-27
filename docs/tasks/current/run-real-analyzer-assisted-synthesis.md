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
