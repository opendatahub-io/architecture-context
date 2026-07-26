# Task: Run the First Allowlisted Analyzer-Assisted Migration

## Goal

Run and validate the first real provisional analyzer-assisted summary migration
for a small representative component set, then checkpoint the accepted
migration evidence without retiring the legacy route.

## Fixed boundaries

- Select a small, representative set of 3–5 components from the available
  architecture corpus; record the exact components and selection rationale.
- Populate or override the operator allowlist only for this bounded run; do not
  silently broaden it.
- Use the existing synthesis/partial routing, evidence-gated merge, analyzer
  baseline, and legacy fallback behavior.
- Write generated summaries, merge reports, route reports, telemetry, and logs
  only under an ignored temporary run directory such as
  `tmp/analyzer-assisted-migration/<run-id>/`.
- Use local context telemetry and local file-backed MLflow where tracking is
  exercised; do not create external tracking or collector state.

## Acceptance criteria

- The task records the selected components, source/analyzer revisions, model,
  allowlist contents, exact commands, run duration, and local artifact paths.
- Every selected component has a route decision, generated output status,
  provenance, merge/validation result, telemetry, and explicit fallback result
  if applicable.
- Analyzer-owned facts, reviewed overlays, explicit unknowns, and evidence
  boundaries are preserved; agent insights remain non-authoritative.
- Temporary outputs pass the architecture, merge, schema, and relevant route
  validators. Compare each migrated summary with its analyzer baseline and
  record any accepted evidence-backed changes.
- Exercise at least one controlled fallback scenario and verify its
  machine-readable outcome (`legacy` or `analyzer-baseline` as appropriate).
- Produce a committed human-readable Markdown migration report covering
  methodology, component matrix, route outcomes, summary/merge findings,
  telemetry, limitations, and recommendation to expand or hold the allowlist.
- Run focused tests and `git diff --check`; do not modify committed
  `architecture/` output, run a full-corpus/paid benchmark, fill human labels,
  retire legacy code, or commit raw results/dumps.

## Review boundary

This task is evidence for provisional expansion only. It does not establish
semantic quality, human approval, production rollout, or legacy retirement.
