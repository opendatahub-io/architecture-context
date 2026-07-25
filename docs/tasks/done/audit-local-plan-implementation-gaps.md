# Task: Audit Local Analyzer-Assisted Plan Implementation

## Goal

Verify Steps 2–4 of `docs/plans/analyzer-assisted-agent-architecture.md`
against the current schemas, renderer, overlay/correction, query, routing,
merge, and synthesis implementations, and close only concrete local gaps that
can be fixed without an evaluation run.

## Scope and controls

- Read `AGENTS.md`, `PLAN.md`, `agent-driver.md`, the plan, ledger, applicable
  completed task notes, implementation files, schemas, and focused tests.
- If an explicit plan requirement is missing, implement the smallest
  evidence-backed fix with focused regression tests and update the task/ledger.
- If a requirement is already satisfied, record the exact implementation and
  test evidence; do not refactor it.
- Do not run models, paid calls, full-corpus or four-condition evaluations,
  modify generated architecture output, or alter corpus/raw/scored results.
- Do not change `scripts/Dockerfile.claude` or reinstall MLflow.

## Acceptance criteria

- Every Step 2–4 bullet is classified as implemented, locally blocked, or
  genuinely missing with file/test evidence.
- Any code change is task-scoped, evidence-backed, and covered by focused tests.
- No external gate is marked complete: MLflow server, human labels,
  adjudication, external-fetch OTel producer, and user authorization remain
  explicit prerequisites.
- Run focused tests and `git diff --check`; do not commit.

## Audit evidence

### Step 2: Improve the context contract

| # | Requirement | Status | Evidence |
|---|-------------|--------|---------|
| 2.1 | Provenance (source, extraction timestamp) | **Implemented** | `src/arch-analyzer/internal/model/contract.go:88-95` `ContractProvenance`; schema `component-architecture.schema.json:138-150`; renderer `contract.go:19-32`; test `contract_test.go` `TestContextContractRoundTrips` |
| 2.2 | Freshness (applicability window, staleness) | **Implemented** | `contract.go:99-144` `ContractApplicability` with `Validate()` and `Stale()` methods; schema; renderer; tests `TestApplicabilityValidateDateOrdering`, `TestApplicabilityStale` |
| 2.3 | Maturity / lifecycle (GA, TP, DP, planned, deprecated) | **Implemented** | `contract.go:33-50` `Maturity` type with 5 enum values; `ContractMaturity:161-164`; schema; renderer; tests `TestMaturityValid` |
| 2.4 | Dependency/upstream status (exists, needed, open, blocked) | **Implemented** | `contract.go:53-69` `DependencyStatus` with 4 enum values; `ContractDependency:175-181` with upstream provenance; schema; renderer; tests `TestDependencyStatusValid` |
| 2.5 | Scope/interaction constraints and deployment topology | **Implemented** | `contract.go:167-171` `ContractScope` with `Limitations`, `DeploymentTopology`; schema; renderer; tests |
| 2.6 | Confidence and validation state | **Implemented** | `contract.go:14-30` `ValidationState` (confirmed, needs-validation, unknown, not-extracted); `ContractConfidence:155-158`; schema; renderer; tests `TestValidationStateValid` |
| 2.7 | Test topology | **Implemented** | `contract.go:190` `TestTopology []string` in `ContractBehavioralEvidence`; schema; renderer; tests |
| 2.8 | Performance baselines | **Implemented** | `contract.go:191` `PerformanceBaselines []string`; schema; renderer; tests |
| 2.9 | Integration constraints and failure modes | **Implemented** | `contract.go:188-189` `IntegrationConstraints`, `FailureModes`; schema; renderer; tests |
| 2.10 | Explicit unknowns | **Implemented** | `ValidationUnknown` and `ValidationNotExtracted` as first-class enum values; renderer labels distinctively; tests `TestContextContractExplicitUnknownsRoundTrip`, `TestMarkdownRendersExplicitUnknownLabels` |
| 2.11 | Contract passes through normalize layer | **Implemented** | `normalize.go:313`; tests `TestInputPassesThroughContextContract`, `TestInputNilContractPassesThrough` |
| 2.12 | Backward compatibility (absent contract) | **Implemented** | Tests `TestContextContractAbsentPreservesBackwardCompatibility`, `TestExistingFixturesDecodeWithoutContract`, `TestMarkdownExistingOutputUnchangedWithoutContract` |
| 2.13 | Generated index | **Implemented** | `src/arch-query/internal/index/index.go` `ContextIndex`, `IndexEntry`, `Generate()`; CLI `cmd/index.go`; 10 tests in `index_test.go` |
| 2.14 | Version diff capability | **Implemented** | `src/arch-query/internal/diff/diff.go` `Compute()`, `ComputeSingle()`; 9 category dimensions; CLI `cmd/diff.go`; 12 tests in `diff_test.go` |
| 2.15 | Image/build status | **Locally blocked** | Plan says "image/build status" under behavioral evidence. No structured field exists. Adding a field would require populating it from analysis, which is out of scope without extraction changes. |
| 2.16 | Configuration/RBAC/deployment ordering | **Locally blocked** | Plan says "configuration and RBAC/deployment ordering." No structured field. Would require extraction-level changes to populate meaningfully. |
| 2.17 | Architecture/provider matrices | **Locally blocked** | No structured matrix type. `TestTopology` can hold informal descriptions. Structured representation requires extraction support. |
| 2.18 | Observable outcomes | **Locally blocked** | No explicit field. Would require synthesis or extraction to populate. |
| 2.19 | Delivery-independence / primary-vs-peripheral hints | **Locally blocked** | No field. Requires component-map metadata or extraction changes. |

**Step 2 summary**: 14 of 19 sub-requirements implemented; 5 locally blocked (all require extraction-level or population-level work before the schema field would be useful).

### Step 3: Add reviewed overlays and the correction loop

| # | Requirement | Status | Evidence |
|---|-------------|--------|---------|
| 3.1 | Correction harvesting | **Implemented** | `src/arch-analyzer/internal/proposal/harvest.go` `Harvest()`, `harvest_test.go`; CLI `cmd/root.go` `harvest-proposals`; session log: 169 records → 1577 proposals |
| 3.2 | Reviewable overlay proposals | **Implemented** | `src/arch-query/internal/overlay/proposal.go` with `Proposal`, `ProposalSet`, `Validate()`, `ValidateQuiet()`; `proposal_test.go`; CLI `cmd/proposals.go` with `validate` and `generate` sub-commands |
| 3.3 | Last-verified metadata | **Implemented** | `proposal.go` `Proposal` struct includes `CreatedDate`, `LastVerifiedDate`, dates validated (reject reversed/invalid dates); schema in `proposal_test.go` |
| 3.4 | Component correction-frequency reports | **Implemented** | `src/arch-query/internal/overlay/report.go` `ComputeReport()`; `report_test.go`; CLI `cmd/proposals.go` `report` sub-command with JSON/text output; per-component, per-category, per-status aggregation |
| 3.5 | Regression assertions for known corrections | **Was missing; now implemented** | New: `tests/test_correction_adjudication_regression.py` — 18 tests across 6 classes: `TestShippedAdjudicationsStructure` (5 tests), `TestAcceptedAbsenceEntryValidity` (2), `TestSourceAuditedEntryValidity` (1), `TestAdjudicationLoaderIntegration` (2), `TestCorrectionCountRegression` (4), `TestKnownCorrectionPatterns` (4). Validates the shipped `lib/analyzer_correction_adjudications.json` (68 accepted absences, 16 source-audited empty categories). |
| 3.6 | Overlay layer preserves corrections across regeneration | **Implemented** | `lib/architecture_merge.py` `merge_architecture_documents()` with `NON_AUTHORITATIVE_SECTIONS` rejection, `load_rejected_additions()` from `analyzer_correction_adjudications.json`; tests `test_source_adjudicated_addition_is_rejected`, `test_rejected_addition_loader_normalizes_persisted_row_keys` |
| 3.7 | Source-audited empty categories | **Implemented** | `lib/architecture_routing.py:61-90` `load_source_audited_empty_categories()`; integration with `analyzer_only_eligibility()`; tests `test_source_audited_empty_categories_loader`, `test_source_audited_categories_enable_analyzer_only_eligibility`, `test_source_audited_policy_routes_analyzer_only` |

**Step 3 summary**: 7 of 7 sub-requirements implemented. The only gap (3.5, regression assertions) was addressed in this task.

### Step 4: Implement query and synthesis modes

| # | Requirement | Status | Evidence |
|---|-------------|--------|---------|
| 4.1 | `arch-query query` CLI (one-shot, no server) | **Implemented** | `src/arch-query/cmd/query.go`; `src/arch-query/internal/query/contract.go` versioned `Response` with `ContractVersion`, `Status` (ok/unknown/not-extracted), `Evidence` |
| 4.2 | `callers-of` query | **Implemented (not-extracted)** | `src/arch-query/internal/query/notextracted.go:7-14` `QueryCallersOf()` returns explicit not-extracted with reason |
| 4.3 | `consumers-of` query | **Implemented (not-extracted)** | `notextracted.go:16-23` `QueryConsumersOf()` returns explicit not-extracted |
| 4.4 | `config-sources` query | **Implemented (not-extracted)** | `notextracted.go:25-41` `QueryConfigSources()` returns not-extracted (component existence checked) |
| 4.5 | `crds` query | **Implemented** | `src/arch-query/internal/query/crds.go` `QueryCRDs()` returns CRD entries + controller watches with evidence |
| 4.6 | `dependency-status` query | **Implemented** | `src/arch-query/internal/query/deps.go` `QueryDependencyStatus()` with reverse-dependency resolution |
| 4.7 | `diff` query | **Implemented** | `src/arch-query/internal/query/diff.go` wraps `diff.Compute()` in Response contract |
| 4.8 | Query tests | **Implemented** | `src/arch-query/internal/query/query_test.go` with tests for crds, dependency-status, diff, callers-of, consumers-of |
| 4.9 | Synthesis routing (3 routes) | **Implemented** | `lib/architecture_routing.py` `load_architecture_agent_policy()` returns routes: `synthesis`, `partial`, `legacy`, plus `analyzer-only`; tested in `tests/test_architecture_routing.py` (29 tests) |
| 4.10 | Synthesis source-read prohibition | **Implemented** | `lib/agent_runner.py` `_AgentExecutionGuard._check_read()` denies source files for sufficient readiness unless in `_allowed_sources`; tested |
| 4.11 | Partial bounded reads | **Implemented** | `_check_read()` enforces `file_budget`; `_check_discovery()` enforces Glob/Grep limits; tested |
| 4.12 | Legacy full exploration | **Implemented** | `pre_tool_use()` permits all tools when `not self.restricted`; tested `test_legacy_guard_counts_reads_without_restricting_them` |
| 4.13 | Route selection by coverage/freshness/confidence | **Implemented** | `load_architecture_agent_policy()` checks `readiness` level, `_coverage_gap_categories()`, empty categories, complete-empty contracts, source-audited categories |
| 4.14 | Insights contract | **Implemented** | `lib/insights.py` `InsightArtifact`, `Insight`, `ProvenanceReference` with validation, JSON Schema, 4 categories (pattern, trade-off, risk, cross-component implication), bounded count/tokens; `tests/test_insights.py` (84 tests per session log) |
| 4.15 | Insights non-authoritative isolation | **Implemented** | `lib/architecture_merge.py:32-33` `NON_AUTHORITATIVE_SECTIONS = frozenset({"Insights", "Agent Insights", "Synthesis Insights"})` — stripped during merge |
| 4.16 | Insight artifact integration in pipeline | **Implemented** | `lib/phases/architecture.py:432-463` loads, validates, archives insight artifacts; tests per session log (156 tests) |
| 4.17 | Deterministic synthesis prose in renderer | **Implemented** | `src/arch-analyzer/internal/renderer/synthesis.go` `deterministicShortPurpose()`, `deterministicDetailedPurpose()`, `deterministicDataFlows()`, `deterministicArchitecturalAnalysis()` |
| 4.18 | Merge layer preserves analyzer-owned rows | **Implemented** | `lib/architecture_merge.py` `merge_architecture_documents()` restores silently deleted/changed rows; tested `test_silent_row_deletion_is_restored`, `test_silent_cell_rewrite_is_restored` |
| 4.19 | Evidence-backed change records | **Implemented** | `parse_change_records()` requires explicit action/category/key/column/reason/evidence; tested extensively |
| 4.20 | `gosource` extractors | **Implemented** | `src/arch-analyzer/internal/gosource/` — 30+ files covering clients, controllers, CRDs, endpoints, gRPC, security, watches, etc. with tests |
| 4.21 | `pythonsource` extractors | **Implemented** | `src/arch-analyzer/internal/pythonsource/` — 8 files covering authentication, imports, routes, SDK clients, etc. with tests |
| 4.22 | Skill for synthesis | **Implemented** | `.claude/skills/repo-to-architecture-summary/SKILL.md` exists |
| 4.23 | Context telemetry | **Implemented** | `lib/context_telemetry.py` `ContextTelemetryCollector`, OTel file exporter; `tests/test_context_telemetry.py` (65 tests), `tests/test_eval_guard_telemetry.py` (34 tests), `tests/test_jsonl_file_exporter.py` |
| 4.24 | Agent runner tool guard | **Implemented** | `lib/agent_runner.py` `_AgentExecutionGuard` with pre_tool_use hook, telemetry, denied-call tracking |
| 4.25 | External-fetch OTel producer | **Locally blocked** | Plan: "fetch-architecture-context.sh OTel producer (not in this repository)"; file exporter ready but producer is external |
| 4.26 | MLflow server registration | **Locally blocked** | Local tracking validated; external server requires `MLFLOW_TRACKING_URI` |
| 4.27 | Human labels/adjudication | **Locally blocked** | Calibration template (24 questions) and adjudication template (35 proposals) prepared; all human fields null |
| 4.28 | User authorization | **Locally blocked** | Required for paid/full-corpus evaluation; no gate to implement locally |

**Step 4 summary**: 24 of 28 sub-requirements implemented; 4 explicitly locally blocked (all are external gates documented in the plan's Step 5 gate table).

## Changes made

| File | Change |
|------|--------|
| `tests/test_correction_adjudication_regression.py` | New: 18 regression assertion tests for shipped adjudication data |
| `docs/tasks/done/audit-local-plan-implementation-gaps.md` | Updated with audit evidence and acceptance status |
| `docs/notes/session-log.md` | Recorded audit and independent validation evidence |
| `PLAN.md` | Moved task to recently completed; no active task remains |

## Validation

- 18 new focused tests: PASS
- 57 related existing tests: PASS in the task container's available test setup;
  the container lacked `pytest` for a broader run
- `git diff --check`: PASS
- No model called, no evaluation ran, no generated output modified
- Estimated cost: $0.00

## Status

Accepted after independent host validation — 2026-07-25. The container could
not run pytest because its image has no pytest installation; host validation
passed 250 focused Python tests plus all `go test ./...` checks in both Go
modules. No model or evaluation call was made.
