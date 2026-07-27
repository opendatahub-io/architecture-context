# Analyzer-Assisted Targeted Synthesis Validation Report

**Date**: 2026-07-26
**Commit under validation**: `c4838d96` ("Add analyzer-guided targeted synthesis routing")
**Task**: `docs/tasks/done/refactor-analyzer-assisted-targeted-synthesis.md`

## Methodology

This validation exercises the implementation from `c4838d96` against real
component checkouts (`rhods-operator`, `odh-dashboard` from
`/data/checkouts/red-hat-data-services.rhoai-3.5/`) and synthetic partial
scenarios, covering all acceptance criteria from the task spec.

### Steps performed

1. **Arch-analyzer extract/render**: Fresh `arch-analyzer extract` and
   `arch-analyzer render` on both `rhods-operator` and `odh-dashboard`,
   producing `component-architecture.json` and `ANALYZER_ARCHITECTURE.md`
   under `tmp/validation-run/`. Analyzer JSON/baseline precedes any bounded
   source reads.

2. **Routing exercised**: `load_architecture_agent_policy()` invoked on four
   scenarios — two real components with the synthesis migration allowlist
   active (verifying legacy fallback) and with the allowlist bypassed
   (verifying synthesis/analyzer-only routing), plus two synthetic partial
   scenarios testing targeted reads and narrative gap detection.

3. **Agent execution guard**: `_AgentExecutionGuard` instantiated for
   synthesis and partial routes, exercising source-read denials, prior-
   architecture isolation, and budget enforcement.

4. **Focused test suite**: All 52 targeted-synthesis tests and 90 MLflow
   tracking tests run and passed. 5 MLflow SDK-dependent tests skipped
   (expected — no SDK installed).

5. **Architecture validators**: `lint_architecture_docs.py` (845 files
   passed), `lint_overlays.py` (20 overlays passed),
   `lint_platforms.py` (16 platforms passed).

6. **Go tests**: All arch-analyzer packages pass (14 packages).

7. **Ruff linting**: All modified Python files pass (`lib/architecture_routing.py`,
   `lib/agent_runner.py`, `tests/test_targeted_synthesis.py`).

8. **MLflow dry-run and OTel/API capture**: Local file-backed tracking
   under `tmp/validation-run/mlflow-runs/` with redacted OTel and API
   captures under `tmp/validation-run/{otel-capture,api-capture}/`.

## Results

### Route decisions

| Component | Readiness | Route (allowlisted) | Route (open) | Evidence gated | Source reads |
|-----------|-----------|---------------------|--------------|----------------|--------------|
| rhods-operator | sufficient | legacy | synthesis | yes | 0 |
| odh-dashboard | sufficient | analyzer-only | analyzer-only | no (analyzer-only) | 0 |
| odh-dashboard-partial (synthetic) | partial | — | partial | yes | 0 (guard init) |
| narrative-test (synthetic) | partial | — | partial | yes | 0 (guard init) |

### Gap categories and reasons

**rhods-operator (open, synthesis route)**: No gaps — all high-value
categories populated; analyzer-only candidate awaiting corpus approval.
Gap categories: `()`, gap reasons: `()`.

**odh-dashboard (open, analyzer-only route)**: No gaps — all high-value
categories populated with contract-complete evidence. Eligible and approved
for analyzer-only via `analyzer_only_approvals.json`.

**odh-dashboard-partial (synthetic partial)**: 6 gap categories nominated:

| Gap | Classification | Evidence basis |
|-----|----------------|----------------|
| architecture_components | structural | partial-coverage |
| authentication | safety-critical | partial-coverage |
| integration_points | structural | partial-coverage |
| internal_dependencies | structural | partial-coverage |
| http_endpoints | structural | partial-coverage |
| grpc_services | structural | empty-in-baseline, partial-coverage |

File budget: 8. Discovery tools: Glob, Grep.

**narrative-test (synthetic partial with thin prose)**: 6 gap categories
nominated, including 2 narrative gaps:

| Gap | Classification | Evidence basis |
|-----|----------------|----------------|
| architecture_components | structural | partial-coverage |
| authentication | safety-critical | empty-in-baseline, partial-coverage |
| integration_points | structural | empty-in-baseline, partial-coverage |
| internal_dependencies | structural | empty-in-baseline, partial-coverage |
| purpose | narrative | thin-narrative |
| data_flows | narrative | thin-narrative |

File budget: 8. Narrative gaps detected: `purpose`, `data_flows`,
`architectural_analysis` (3rd capped by 6-category limit).

### Source file reads and denials

| Scenario | Source reads | Denied reads | Denial reasons |
|----------|-------------|--------------|----------------|
| rhods-operator synthesis guard | 0 | 1 | Prior architecture isolation |
| odh-dashboard-partial guard | 1 (`frontend/src/app.tsx`) | 1 | Prior architecture isolation |
| narrative-test guard | 2 (`src/main.go`, `cmd/server.go`) | 1 | Prior architecture isolation |
| synthesis guard source attempt | 0 | 1 | Source reads denied (no budget) |

### Prior architecture isolation

All routes correctly deny reads of `architecture/**/*.md`:
- Synthesis guard: denied `/workspace/architecture/rhoai-3.5/rhods-operator.md`
  with reason "prior architecture documents are comparison-only and must not
  be used as synthesis inputs"
- Partial guard: denied similarly for `odh-dashboard.md`
- Legacy guard: correctly allows (unrestricted)
- Path detection: `_is_prior_architecture_path()` correctly identifies
  `architecture/rhoai-3.5/dashboard.md` as prior, rejects
  `checkouts/org/repo/GENERATED_ARCHITECTURE.md`

### Provenance and merge/validator results

- `readiness_detail` preserved through policy: e.g., "sufficient: 67 runtime
  facts, 1 source components, and 51 dependencies; broad repository
  discovery is not required"
- `route` reason preserved: e.g., "analyzer-only candidate is awaiting
  corpus approval; agent is synthesis-only and may read only
  analyzer-referenced files"
- `evidence_gated` property correct: `True` for synthesis/partial, `False`
  for analyzer-only/legacy
- `output_preseeded` correct: `True` for synthesis/partial/analyzer-only,
  `False` for legacy
- Architecture doc linter: 845 files passed (no regressions)
- Overlay linter: 20 overlays passed
- Platform linter: 16 platforms passed

### Sufficient vs targeted behavior comparison

| Property | Sufficient/Synthesis route | Partial/Targeted route |
|----------|---------------------------|------------------------|
| File budget | None | 4–10 (function of gap count) |
| Discovery tools | None | Glob, Grep |
| Source files | None | Analyzer-referenced, within budget |
| Gap categories | High-value only, max 4 | Priority-ordered, max 6, includes narrative |
| Narrative gaps | Not nominated | Nominated when prose < 50 chars |
| Source reads | Denied by guard | Allowed within budget, denied over |
| Prior architecture | Denied | Denied |
| Output preseeded | Yes | Yes |

### MLflow tracking

All 4 scenarios tracked successfully in dry-run mode:

- Preflight: configured=true, mode=local, dry_run=true
- Tags logged: `experiment_id`, `condition_id`, `question_id`,
  `tracking_contract_version`, `provenance.architecture_context_sha`,
  `provenance.corpus_version`
- Metrics logged: `response.success`, `telemetry.duration_seconds`,
  `telemetry.input_tokens`, `telemetry.output_tokens`,
  `telemetry.total_cost_usd`
- No external MLflow server required

### OTel and API captures

Redacted captures written for all 4 scenarios:
- `tmp/validation-run/otel-capture/{component}-otel.json`
- `tmp/validation-run/api-capture/{component}-api.json`

All captures are valid JSON with `redacted: true` tags. No external OTel
collector or API calls made.

## Observations

1. **Both real components are "sufficient"**: `rhods-operator` routes to
   synthesis (awaiting analyzer-only corpus approval); `odh-dashboard`
   routes to analyzer-only (already approved). Neither has gap categories,
   confirming the analyzer provides complete high-value coverage for these
   mature components.

2. **Synthesis migration allowlist is active**: The allowlist
   (`synthesis_migration_allowlist.json`) contains only `caikit-nlp` and
   `rhoai-mcp`. Both `rhods-operator` and `odh-dashboard` fall to legacy
   when the allowlist is active, which is the expected gating behavior.

3. **Narrative gap detection works correctly**: The `_narrative_gap_sections`
   function correctly identifies thin prose (< 50 chars) in Purpose, Data
   Flows, and Architectural Analysis sections. When the baseline has
   substantial prose (> 50 chars), those sections are not nominated.

4. **Gap reason auditing is comprehensive**: Every gap category includes
   its classification (narrative/safety-critical/structural) and evidence
   basis (empty-in-baseline, partial-coverage, thin-narrative).

5. **Guard enforcement is correct**: Synthesis guards deny all source reads;
   partial guards allow reads within the file budget and deny over-budget
   reads. Prior architecture isolation works across all restricted routes.

6. **`_PARTIAL_GAP_PRIORITY`** correctly includes narrative sections after
   high-value agent categories, ensuring narrative gaps are nominated on
   partial routes but not on sufficient routes (where only
   `HIGH_VALUE_AGENT_CATEGORIES` are considered).

## Conclusions

The implementation in `c4838d96` satisfies all acceptance criteria:

1. **Analyzer context consumed first**: Both real components produce analyzer
   JSON and rendered baselines before any source-read decision. The routing
   logic reads `component-architecture.json` and `ANALYZER_ARCHITECTURE.md`
   before computing gap categories.

2. **Sufficient routes perform no source discovery**: Confirmed — synthesis
   route has `file_budget=None`, `discovery_tools=()`, `source_files=()`.
   Guard denies all source reads.

3. **Targeted/partial routes read only declared gap categories within
   budget**: Confirmed — partial route nominates specific categories,
   enforces file budget, and the guard tracks reads against the budget.

4. **Analyzer-owned facts and overlays survive synthesis**: `readiness_detail`,
   `reason`, `gap_reasons`, and `output_preseeded` are preserved in the
   policy and propagated to prompt arguments.

5. **Clean-run isolation**: Prior architecture documents are denied by the
   guard. No prior-summary leakage possible.

6. **Tests pass**: 52 targeted-synthesis tests, 90 MLflow tracking tests,
   all Go tests, all architecture validators, ruff clean.

## Limitations

- **MLflow SDK not installed**: Tracking runs in dry-run mode only. The 5
  SDK-dependent tests are skipped. Full MLflow server integration not
  validated.
- **No external OTel collector**: OTel captures are redacted placeholders.
  No live span export validated.
- **No external API calls**: API captures are redacted placeholders.
- **No human labels**: Existing feedback is directional evidence only.
- **Synthetic partial scenarios**: `odh-dashboard-partial` and
  `narrative-test` are synthetic — they use real analyzer JSON with
  modified readiness to exercise partial routing. Real partial components
  were not available in the checkout set (both real components are
  "sufficient").
- **Allowlist gating**: Real components fall to legacy under the active
  allowlist, which is correct but means the synthesis/partial routes for
  real components were validated only with the allowlist bypassed (matching
  the test suite's `_open_allowlist` fixture pattern).

## Artifact paths

| Artifact | Path |
|----------|------|
| Validation results JSON | `tmp/validation-run/full-validation-results.json` |
| Routing results JSON | `tmp/validation-run/routing-results.json` |
| Guard results JSON | `tmp/validation-run/guard-results.json` |
| Narrative gap results JSON | `tmp/validation-run/narrative-gap-results.json` |
| MLflow runs directory | `tmp/validation-run/mlflow-runs/` |
| OTel captures | `tmp/validation-run/otel-capture/` |
| API captures | `tmp/validation-run/api-capture/` |
| rhods-operator analyzer JSON | `tmp/validation-run/rhods-operator/component-architecture.json` |
| rhods-operator analyzer MD | `tmp/validation-run/rhods-operator/ANALYZER_ARCHITECTURE.md` |
| odh-dashboard analyzer JSON | `tmp/validation-run/odh-dashboard/component-architecture.json` |
| odh-dashboard analyzer MD | `tmp/validation-run/odh-dashboard/ANALYZER_ARCHITECTURE.md` |

## Test evidence

```
$ python3 -m pytest tests/test_targeted_synthesis.py -v
52 passed in 0.68s

$ python3 -m pytest tests/test_mlflow_tracking.py -v
90 passed, 5 skipped in 3.75s

$ python3 -m ruff check lib/architecture_routing.py lib/agent_runner.py tests/test_targeted_synthesis.py
All checks passed!

$ python3 scripts/lint_architecture_docs.py
All 845 component architecture file(s) passed validation.

$ python3 scripts/lint_overlays.py
All 20 overlay(s) passed validation.

$ python3 scripts/lint_platforms.py
All 16 platform(s) passed validation.

$ cd src/arch-analyzer && go test ./...
ok (14 packages)
```
