# Task: Implement the Provisional Analyzer-Assisted Summary Migration

## Goal

Enable a bounded, reviewable migration of selected component summaries to the
analyzer-assisted synthesis path while preserving deterministic analyzer facts,
reviewed overlays, explicit unknowns, provenance, and the analyzer-baseline
fallback for restricted-route failures.

## Scope

- Inspect the existing routing, synthesis, merge, eligibility, and validation
  paths in `lib/architecture_routing.py`, `lib/phases/architecture.py`,
  `lib/architecture_merge.py`, and the related schemas/tests.
- Add or complete an explicit operator-controlled component allowlist for the
  provisional analyzer-assisted route; default behavior must remain unchanged
  for components outside the allowlist.
- Run the selected route through evidence-gated synthesis/partial handling and
  preserve analyzer-owned facts and reviewed overlays during merge.
- Preserve a visible analyzer-baseline fallback for restricted-route
  merge/validation failure. The legacy route remains the default for
  insufficient/unknown readiness and allowlist-gated components (those routes
  invoke legacy generation, not a baseline restore). Record the route decision,
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
- Restricted-route merge or validation failure produces a visible, tested
  analyzer-baseline fallback with a machine-readable route, reason, original
  route, and action. The fallback route is `analyzer-baseline` (not `legacy`)
  because no legacy generator runs; the analyzer baseline is restored directly.
- Temporary migration output passes the existing architecture/schema/merge
  validators and includes route, provenance, context-telemetry, and local
  MLflow references where applicable.
- Focused tests, a bounded local migration dry-run or fixture run, and
  `git diff --check` pass.
- Update the task and session ledger with the selected components, exact
  commands, artifacts, route outcomes, fallback outcomes, and limitations.

## Implementation record

### Files created

- `lib/synthesis_migration_allowlist.json` — operator-controlled allowlist
  with `schema_version`, `description`, and empty `components` list.

### Files modified

- `lib/architecture_routing.py` — added `SYNTHESIS_MIGRATION_ALLOWLIST_PATH`,
  `load_synthesis_migration_allowlist()`, and allowlist gate in
  `load_architecture_agent_policy()` for both sufficient→synthesis and
  partial→partial routes. When the allowlist is non-empty and the component
  is not listed, routing falls back to legacy with a machine-readable reason.
  Analyzer-only route is unaffected (it has its own separate allowlist).
- `lib/phases/architecture.py` — added merge/validation failure fallback:
  when synthesis/partial merge fails, the analyzer baseline is restored and
  the run report records a machine-readable `fallback` field with
  `route=analyzer-baseline`, reason, original route, and action. This
  distinguishes it from the `legacy` route (which invokes the legacy
  generator). The `_write_agent_run_reports` function now persists the
  `fallback` field. Insight artifact failures retain their existing hard-fail
  behavior.
- `tests/test_architecture_routing.py` — 10 new tests: allowlist loader
  (valid, missing, invalid JSON), empty allowlist preserves synthesis route,
  populated allowlist gates unlisted components to legacy, allows listed
  components, partial readiness gating, partial readiness allow, and
  analyzer-only route unaffected by synthesis allowlist.
- `tests/test_architecture_phase.py` — 4 new tests: merge failure falls
  back to analyzer baseline with `route=analyzer-baseline` (verifies output
  is byte-identical to ANALYZER_ARCHITECTURE.md, run report, fallback field),
  validation failure restores analyzer baseline with correct route label,
  synthesis allowlist gates route in full phase integration test, and
  confirmed existing insight failure tests still pass.

### Validation commands

```
python3 -m ruff check lib/architecture_routing.py lib/phases/architecture.py \
  tests/test_architecture_routing.py tests/test_architecture_phase.py
python3 -m pytest tests/test_architecture_routing.py tests/test_architecture_phase.py \
  tests/test_architecture_merge.py -v
git diff --check
```

### Route outcomes (fixture dry-run)

| Scenario | Readiness | Allowlist | Route | Outcome |
|----------|-----------|-----------|-------|---------|
| Empty allowlist | sufficient | empty | synthesis | current behavior preserved |
| Component on allowlist | sufficient | listed | synthesis | gated pass |
| Component NOT on allowlist | sufficient | populated, not listed | legacy | legacy route with reason |
| Routing disabled | any | any | legacy | unaffected by allowlist |
| Merge failure | sufficient | n/a | analyzer-baseline | analyzer baseline restored (not legacy) |
| Validation failure | sufficient | n/a | analyzer-baseline | analyzer baseline restored (not legacy) |

### Test results (initial)

- 56/56 tests passed in routing + phase test files
- 28/28 tests passed in merge test file
- 1161/1166 passed in full suite; 5 pre-existing failures (unrelated)
- `git diff --check`: clean
- `ruff check`: clean

### Test results (after refinement)

- 57/57 tests passed in routing + phase test files (1 new validation-failure
  fixture test added)
- 28/28 tests passed in merge test file
- 90/90 passed (5 skipped) in MLflow tracking test file
- `git diff --check`: clean
- `ruff check`: clean
- No `architecture/` output modified

### Limitations

- No full-corpus or paid benchmark executed.
- No human labels or semantic-judge claims used.
- Legacy route not retired; remains the default for all components.
- Insight artifact failures retain hard-fail behavior (not converted to fallback).
- The allowlist file is delivered empty; operator must explicitly add components.
- Committed `architecture/` output is unchanged.
- The merge/validation failure fallback restores the analyzer baseline, not a
  legacy-generated summary. This is intentional: the restricted route already
  has an analyzer baseline available, and running the legacy generator would
  require full agent discovery (defeating the purpose of the restricted route).

## Driver review — not accepted (initial)

Focused routing, phase, and merge tests pass, and the allowlist gate is
implemented. The task remains review-held because the merge/validation failure
fallback does not satisfy its stated legacy-fallback contract:

- `_merge_agent_outputs()` records `fallback.route = "legacy"`, but does not
  invoke the legacy route or restore a legacy-generated summary.
- It copies `ANALYZER_ARCHITECTURE.md` back to the candidate and labels the
  action `analyzer-baseline-restored`. That is a safe analyzer-baseline
  fallback, but it is not the legacy fallback claimed by the report.
- The test currently asserts this mismatch instead of proving a legacy output
  or explicitly changing the contract to call the fallback
  `analyzer-baseline`.

## Refinement — contract revised to analyzer-baseline

Chose the "revise contracts" path: the merge/validation failure fallback
restores the analyzer baseline (not a legacy-generated summary), so the
machine-readable route is now `analyzer-baseline` everywhere. The `legacy`
route label is reserved for paths that actually invoke the legacy generator
(insufficient/unknown readiness, allowlist-gated components).

### Changes

- `lib/phases/architecture.py` — `result["fallback"]["route"]` changed from
  `"legacy"` to `"analyzer-baseline"` in `_merge_agent_outputs()`.
- `tests/test_architecture_phase.py` —
  `test_merge_failure_falls_back_to_analyzer_baseline` now asserts
  `route == "analyzer-baseline"`, verifies output is byte-identical to
  `ANALYZER_ARCHITECTURE.md`, and checks `reason` contains
  `"restricted-route merge failed"`. New test
  `test_validation_failure_restores_analyzer_baseline_not_legacy` exercises
  the validation-failure path with the same contract.
- Task document scope, acceptance criteria, and route outcomes table updated
  to use `analyzer-baseline` for the merge/validation failure fallback.
- Session log updated to distinguish analyzer-baseline fallback from legacy
  route.

### Distinction between route labels

| Label | When used | What happens |
|-------|-----------|--------------|
| `legacy` | Insufficient/unknown readiness, allowlist-gated | Legacy generator runs; full agent discovery |
| `analyzer-baseline` | Restricted-route merge or validation failure | ANALYZER_ARCHITECTURE.md restored as output |
| `synthesis` | Sufficient readiness, on allowlist | Evidence-gated merge of agent candidate |
| `partial` | Partial readiness, on allowlist | Bounded discovery + evidence-gated merge |
| `analyzer-only` | Sufficient + approved + all categories explained | Analyzer baseline promoted directly |
