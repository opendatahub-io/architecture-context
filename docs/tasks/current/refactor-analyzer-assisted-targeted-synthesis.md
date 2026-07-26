# Task: Refactor Analyzer-Assisted Targeted Synthesis

## Goal

Refactor the repo-to-architecture-summary workflow so analyzer outputs enrich
every synthesis decision first, followed by narrowly targeted source scanning
only for analyzer-declared narrative or safety-critical gaps.

## Scope

- Trace `.claude/skills/repo-to-architecture-summary/SKILL.md`,
  `lib/architecture_routing.py`, `lib/phases/architecture.py`, and the agent
  execution guard.
- Preserve clean-run isolation: prior generated documents under
  `architecture/` are comparison-only and never synthesis inputs or fallback.
- Make the analyzer JSON/rendered baseline, approved overlays, indexes, and
  query results the first-class synthesis context.
- Define deterministic routing from analyzer coverage to analyzer-only,
  analyzer-assisted targeted/partial, or legacy fallback. Targeted reads must
  be category-specific, budgeted, source-referenced, and denied outside the
  declared scope.
- Improve the human-readable narrative sections (purpose, data flows,
  architectural analysis, failure modes, testability, and feasibility) without
  weakening analyzer-owned facts, provenance, explicit unknowns, or overlays.
- Add focused fixtures/tests and a bounded rhods-operator/dashboard validation
  using clean temporary outputs. Capture local MLflow, OTel, and redacted API
  artifacts only under ignored `tmp/` paths.

## Exclusions

- Do not read or stage prior `architecture/<platform>-x.y/*.md` documents for
  synthesis.
- Do not perform broad repository rediscovery when analyzer evidence is
  sufficient; do not silently turn targeted routes into legacy scans.
- Do not require an external MLflow server, external OTel collector, or new
  human labels. Existing feedback may provide directional evaluation only.
- Do not commit raw results, API dumps, OTel payloads, secrets, generated
  architecture output, or unrelated user changes.

## Acceptance criteria

- Analyzer context is consumed before any allowed source read, with an
  auditable reason for every targeted read.
- Sufficient routes perform no source discovery; targeted/partial routes read
  only declared gap categories within their budget; legacy remains available
  for unresolved high-value gaps.
- Analyzer-owned facts and reviewed overlays survive synthesis and merge.
- Clean-run isolation and provenance tests pass, including no prior-summary
  leakage.
- Bounded component validation produces a human-readable summary of route,
  source reads, telemetry, local MLflow experiment/path, API/OTel capture
  paths, limitations, and conclusions.
- Implementation agent does not commit; the driver independently reviews and
  checkpoints accepted work.

## Execution record — 2026-07-26

- Initial implementation run: `/tmp/claude-task-runs/agent-driver.jsonl`,
  reported cost `$8.8398`; added gap classification, prior-summary denial,
  telemetry fields, and 40 focused tests.
- Driver review found the initial patch did not nominate narrative gaps for
  targeted reads; it incorrectly documented narrative gaps as analyzer-only
  on every route.
- Refinement run: same stable log path, reported cost `$4.8705`; added
  thin-narrative detection, partial-route narrative gap nomination, explicit
  targeted-read instructions, and 12 additional tests.
- Container validation: 52 targeted-synthesis tests and 90 MLflow tracking
  tests passed; 5 MLflow SDK-dependent tests were skipped. Existing routing
  failures remain attributable to the populated migration allowlist.
- Ruff checks passed. No commits were made by the implementation agent.

## Driver review

The code/test portion is accepted for checkpointing. The task remains
review-held for the required real rhods-operator/odh-dashboard bounded run
and human-readable validation report; those are tracked as the next bounded
validation step and are not being represented as completed here.
