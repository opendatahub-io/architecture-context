# Task: Implement the Provisional Analyzer-Assisted Summary Migration

## Goal

Enable a bounded, reviewable migration of selected component summaries to the
analyzer-assisted synthesis path while preserving deterministic analyzer facts,
reviewed overlays, explicit unknowns, provenance, and the legacy fallback.

## Scope

- Inspect the existing routing, synthesis, merge, eligibility, and validation
  paths in `lib/architecture_routing.py`, `lib/phases/architecture.py`,
  `lib/architecture_merge.py`, and the related schemas/tests.
- Add or complete an explicit operator-controlled component allowlist for the
  provisional analyzer-assisted route; default behavior must remain unchanged
  for components outside the allowlist.
- Run the selected route through evidence-gated synthesis/partial handling and
  preserve analyzer-owned facts and reviewed overlays during merge.
- Preserve a visible legacy fallback for route failure, insufficient evidence,
  missing analyzer artifacts, or validation failure. Record the route decision,
  fallback reason, provenance, and local telemetry for every selected component.
- Exercise a small bounded local migration against temporary output only; do
  not overwrite committed `architecture/` output or retire the legacy route.

## Explicit exclusions

- No full-corpus or paid benchmark.
- No human labels, semantic-judge claims, or promotion of agent insights to
  authoritative facts.
- No deletion/retirement of legacy code or route.
- No changes to committed generated architecture output.
- Do not commit; the driver will review and checkpoint accepted work.

## Acceptance criteria

- The allowlist and route selection are explicit, deterministic, documented,
  and tested; non-allowlisted components retain their prior route.
- Analyzer-owned fields and reviewed overlays are unchanged by synthesis; any
  accepted structured changes carry evidence and provenance.
- Route failure, missing evidence, or validation failure produces a visible,
  tested legacy fallback with a machine-readable reason.
- Temporary migration output passes the existing architecture/schema/merge
  validators and includes route, provenance, context-telemetry, and local
  MLflow references where applicable.
- Focused tests, a bounded local migration dry-run or fixture run, and
  `git diff --check` pass.
- Update the task and session ledger with the selected components, exact
  commands, artifacts, route outcomes, fallback outcomes, and limitations.
