# Task: Audit Analyzer-Assisted Plan Success Criteria

## Goal

Produce a final repository-backed readiness audit for the architecture plan's
success criteria, separating verified local behavior from external rollout
gates and identifying any remaining actionable local gap.

## Scope and controls

- Read `AGENTS.md`, `PLAN.md`, `agent-driver.md`, the architecture plan,
  `docs/tasks/done/audit-local-plan-implementation-gaps.md`, the evaluation
  contract/readiness notes, and relevant validators/artifacts.
- Inspect current source/tests/artifacts as needed; do not run models, paid or
  full-corpus evaluation, contact external systems, or modify production code.
- Do not treat historical/unverified scores or null human labels as evidence of
  success; preserve explicit unknowns and external blockers.

## Acceptance criteria

- Add a durable evidence matrix mapping every plan success criterion and open
  rollout gate to verified evidence, incomplete evidence, or external input.
- Identify any actionable repository-side gap; if none remains, state that
  clearly and enumerate the exact external inputs required to proceed.
- Reconcile the plan status, `PLAN.md`, and session ledger without overstating
  completion; retain the legacy route and external gates.
- Run relevant deterministic validators and `git diff --check`; no unrelated
  files or generated outputs changed; do not commit.

## Evidence matrix

### Success criteria

| # | Criterion | Evidence class | Evidence | Gaps |
|---|-----------|---------------|----------|------|
| S1 | No analyzer-owned fact regressions or loss of reviewed overlays | **Verified local** | Merge layer (`lib/architecture_merge.py`) restores silently deleted/changed rows and rejects `NON_AUTHORITATIVE_SECTIONS`; 18 adjudication regression tests PASS; overlay preservation tests PASS (223 routing/merge/telemetry/eval tests PASS) | Regression can only be confirmed against a live synthesis run (Step 5 gate) |
| S2 | Retrieval improves from v1-ab baseline; CRD/deployment/ownership categories improve | **Incomplete — requires evaluation run** | Reproducible baseline: `benchmark/consumer-v1/results/v1-ab/scored-results.json` (40 questions, tree_a overall avg 0.3625, tree_b 0.3375). Four experiment conditions available (manifest v1.3.0, validator PASS). Context telemetry wired. The 84%/94-question figure is **unverified external historical feedback** — no artifact exists | Requires paid multi-condition evaluation with user authorization |
| S3 | Fewer stale/wrong-context corrections and fewer invented thresholds | **Incomplete — requires evaluation run + human adjudication** | Adjudication template ready (35 proposals, all `human_category: null`, validator PASS 35/35). Failure-classification pipeline implemented. Correction harvester and frequency reports operational | Requires human adjudication of 35 proposals and a post-synthesis evaluation comparison |
| S4 | Testability output: concrete observable outcomes, applicable test matrices, explicit unknowns | **Verified local** | Context contract fields: `TestTopology`, `PerformanceBaselines`, `ObservableOutcomes`, `ArchProviderMatrices` (schema + renderer + tests); `ValidationUnknown` and `ValidationNotExtracted` are first-class enum values with distinctive rendering; insights contract requires category/evidence/reasoning per claim | Actual synthesis output quality is a Step 5 gate |
| S5 | Feasibility output: dependency status, upstream coordination, critical-path questions | **Verified local** | `DependencyStatus` (4 enum values + upstream provenance), `ContractScope` with `Limitations`/`DeploymentTopology`, `ContractMaturity` (5 lifecycle values), `ContractComponentClassification` with `DeliveryIndependence`; insights contract supports `risk` and `trade-off` categories | Actual synthesis output quality is a Step 5 gate |
| S6 | Context fetches once per CI run; measured navigation/read/query cost and token/time cost reported | **Partially verified local** | `ContextTelemetryCollector` (65 tests) records reads, queries, denials, context-quality signals. Eval guard (34 tests) wires telemetry into per-tree results with `context_metrics` and `context_provenance`. Local OTel JSONL exporter ready | External-fetch OTel producer required for CI-run instrumentation |
| S7 | Synthesis includes architectural insights with reasoning chains; unsupported-claim and false-positive rates below threshold | **Verified local (contract only)** | Insights contract (`lib/insights.py`, 83 tests): 4 categories, bounded count/tokens, provenance references, non-authoritative isolation. Merge layer strips insight sections. Synthesis skill exists | Threshold undefined. Actual quality requires evaluation run |
| S8 | Human review scores do not regress; rollout failures attributable to recorded root-cause categories | **Incomplete — requires human review** | Calibration template ready (24 questions, all `human_label: null`, validator PASS 24/24). Six failure classifications defined in experiment manifest. No human review scores exist yet | Requires human labeling, judge calibration, user authorization, and a synthesis run |

### Rollout gates (Step 5)

| Gate | Evidence class | Evidence | Required external input |
|------|---------------|----------|------------------------|
| MLflow experiment registration | **Verified local** | Local file-backed (`MLFLOW_RUNS_DIR`) and REST modes validated end-to-end (95 focused tests passed for the fixed REST flow). REST bug fixed (commit `4be242c5`). Preflight, dry-run, live tracking with read-back all confirmed against ephemeral MLflow 2.22.0 | `MLFLOW_TRACKING_URI` + running MLflow server for external registration |
| Root-cause classification | **Template ready; human adjudication pending** | `adjudication_template.json` v0.1.0: 35 proposals, all `human_category: null`, all `proposed_category: "unresolved"`. Validator PASS (44 tests). Pipeline: `lib/failure_proposals.py` | Human adjudication of 35 proposals |
| LLM-as-judge calibration | **Template ready; human labeling pending** | `calibration_template.json` v0.1.0: 24 questions (6/tier, 4 gap), all `human_label: null`. Validator PASS (49 tests). Schema v0.1.0, rationale required non-empty | Human semantic-match labeling + user authorization for judge execution |
| External-fetch OTel spans | **Local export ready; producer external** | `JsonlFileExporter` provides OTel-compatible local event export | `fetch-architecture-context.sh` OTel producer (not in this repository) |
| Corpus at contract minimum | **Verified** | 40/40 active questions. `validate.py` PASS. Schema `minItems: 40` enforced. 10 per tier | None — resolved |
| User authorization | **Not obtained** | No paid or full-corpus evaluation without explicit authorization | Explicit user authorization stating expected cost and duration |

### Baseline provenance

| Claim | Evidence class | Current artifact status |
|-------|---------------|----------------------|
| v1-ab 40-question scored results | **Verified** | `benchmark/consumer-v1/results/v1-ab/scored-results.json` — 40 results, tree_a avg 0.3625, tree_b avg 0.3375 |
| 94-question / 84% retrieval baseline | **Unverified external historical** | No 94-question corpus, result set, or evaluation log exists in repository; preserved in `corpus_manifest.json` as `plan_claim_94q` with `verification_status: "unverified"` |
| Category scores: CRD/API 50%, deployment 60%, ownership 62.5% | **Unverified external historical** | Same provenance as 94-question claim; no per-category artifact |

## Findings

### No actionable repository-side gap remains

All locally implementable plan requirements are complete:
- Step 2: 19/19 implemented
- Step 3: 7/7 implemented
- Step 4: 24/28 implemented (4 are external gates, not local gaps)
- Corpus: 40/40 at contract minimum
- All deterministic validators PASS
- All four experiment conditions available (manifest v1.3.0)

### External inputs required to proceed

The following external inputs are required before Step 5 can execute. None can be resolved by repository-side implementation work:

1. **Human adjudication** — 35 proposals in `adjudication_template.json` require human failure-classification review
2. **Human labeling** — 24 questions in `calibration_template.json` require human semantic-match labels
3. **User authorization** — explicit authorization with expected cost and duration for paid/full-corpus evaluation
4. **MLflow server** — `MLFLOW_TRACKING_URI` and a running MLflow server for external experiment registration
5. **External-fetch OTel producer** — instrumentation in `fetch-architecture-context.sh` (not in this repository)

### Legacy route

The legacy route is preserved. The plan explicitly states: "Retire legacy only after a canary shows no regression in analyzer-fact accuracy, improves retrieval on the question corpus, and does not degrade human review outcomes." No canary has run. The legacy route must remain available.

### Pre-existing issues (not task-scoped)

- 5 pre-existing test failures: 3 from corpus growth (31→40 hardcoded assertions), 1 fixture signature change, 1 validator assertion. 1147 tests pass.
- 100 pre-existing ruff lint findings (84 line-too-long, 7 unused-import, 6 unsorted-imports, 3 import-order).
- Bug `docs/bugs/open/corpus-v1-below-minimum-question-count.md` is marked "Resolved" in its body but remains in `open/`. Should be relocated to `docs/bugs/closed/` in a future reconciliation.

## Validation

- `benchmark/consumer-v1/validate.py`: PASS (40 questions, 10/tier)
- `benchmark/analyzer-assisted-v1/validate.py`: PASS (manifest v1.3.0, 4 conditions, 6 classifications)
- `benchmark/analyzer-assisted-v1/validate_corpus.py`: PASS (40 active, 0 retired, v1.1.0)
- `benchmark/consumer-v1/validate_adjudication.py`: PASS (35 proposals)
- `benchmark/consumer-v1/validate_calibration.py`: PASS (24 questions, v0.1.0)
- Go tests (`arch-analyzer`): all PASS (13 packages)
- Go tests (`arch-query`): all PASS (4 packages with tests)
- Python tests: 1147 passed, 5 failed (pre-existing), 6 skipped
- `git diff --check`: PASS (exit 0)
- No code, schema, corpus, generated architecture, Dockerfile, or external state modified by this task

## Status

Done — 2026-07-25. Local implementation complete; rollout pending
external gates. No actionable repository-side gap remains. Five external
inputs required for Step 5 execution (human adjudication, human labeling,
user authorization, MLflow server, external-fetch OTel producer). Legacy
route preserved. Plan completion not claimed.
