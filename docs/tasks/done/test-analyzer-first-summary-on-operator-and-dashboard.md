# Task: Test Analyzer-First Summary on rhods-operator and odh-dashboard

## Goal

Run a bounded, temporary validation of the analyzer-first
`repo-to-architecture-summary` skill against `rhods-operator` and
`odh-dashboard` from the RHOAI 3.5 checkouts.

## Scope

- Use `/data/checkouts/red-hat-data-services.rhoai-3.5/{rhods-operator,odh-dashboard}`
  as read-only source inputs.
- Use `arch-analyzer` outputs first: generate or stage
  `component-architecture.json` and `ANALYZER_ARCHITECTURE.md` in run-scoped
  temporary copies as needed; do not mutate `/data/checkouts`.
- Invoke the skill with analyzer-first route arguments and record readiness,
  route, source reads, discovery calls, denials, output provenance, duration,
  and cost for each component.
- Preserve analyzer-owned rows and explicit unknown/not-extracted values;
  validate architecture output and any insight/change artifacts.

## Exclusions

- Do not modify committed `architecture/` output or production code.
- Do not add raw logs, API dumps, OTel payloads, secrets, or run artifacts to
  Git; keep all generated material under ignored `tmp/`.
- Do not claim full rollout, semantic quality, or retire the legacy route.

## Acceptance criteria

- Both components have a complete route/read/validation record, including an
  explicit reason when analyzer readiness requires partial or legacy fallback.
- The report compares analyzer-first source volume with the prior broad route
  without claiming causal quality improvement.
- Focused validators pass and the task remains review-held until independent
  driver inspection.

## Execution record — 2026-07-26

- Run directory: `tmp/analyzer-first-rhods-dashboard/`
- Both components: sufficient → synthesis; 0 source reads and 0 grep/search
  patterns.
- Durations: `rhods-operator` 252s; `odh-dashboard` 237s.
- Architecture validation: both PASS; dashboard has one informational warning
  for analyzer-produced `Admission Webhooks`.
- Report: `docs/notes/analyzer-first-rhods-dashboard-test-report.md`.
- Total reported container cost: `$11.7130`; no MLflow tracking was needed.
- Review finding: the old checkout JSON is incompatible with the current
  analyzer binary, and `--distribution rhoai.next` does not match these
  checkout manifests. Fresh default-distribution extraction was used and this
  limitation is not a rollout claim.

## Driver review

Accepted as a bounded provisional validation with the extraction limitations
recorded. No generated output or raw artifact is committed. The legacy and
partial routes remain available for analyzer-missing surfaces.
