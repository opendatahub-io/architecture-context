# Session Log

## 2026-07-25 — Pin INDEX.md Experiment Artifact

**Task**: `docs/tasks/current/pin-index-experiment-artifact.md`

Materialized a deterministic INDEX.md benchmark artifact from the current
architecture snapshot (rhoai-3.5, 69 components) and enabled the `index-md`
experiment condition with explicit validated artifact provenance. The artifact
records source revision (`56eb7ab0`), architecture version, query format
version (2), and materializer format version (1) in a machine-readable
provenance header.

Artifact metadata lives in a separate `index_artifact` section in the
experiment manifest, not inside `artifact_identity`, to avoid requiring
callers to supply metadata fields during evaluation. `combined` remains
pending (requires explicit index+query pairing). Manifest version bumped
from 1.1.0 to 1.2.0.

Updated tests across 5 files to reflect `index-md` as available (with
artifact identity and path) and `combined` as the sole pending condition.
Canary report expectations updated (30 planned/10 unavailable).

Validation: 344 focused tests passed. 3 pre-existing failures outside this
task: `test_rhoai_next_kueue_is_a_valid_baseline_fixture`,
`test_static_analysis_uses_shared_distribution_resolver`,
`test_validator_rejects_incomplete_crd_identity`. Manifest validation PASS
(3 available, 1 pending), canary report PASS (no violations), Ruff lint PASS,
`git diff --check` PASS, Go tests PASS, determinism PASS. No evaluation,
agent, or paid call was run. Estimated cost: $0.00.

Status: accepted. Task note: `docs/notes/pin-index-experiment-artifact.md`.

## 2026-07-25 — Materialize the INDEX.md Evaluation Artifact (accepted)

**Task**: `docs/tasks/done/materialize-index-evaluation-artifact.md`

Implemented deterministic INDEX.md materialization from `arch-query index`
JSON output. The materializer renders a provenance-carrying Markdown artifact
with stable ordering, format version, source revision, applicable architecture
version, and component count. Provenance header validation rejects missing
headers, wrong format versions, and component count mismatches.

Extended the planner and evaluator to require a validated index artifact path
for the `index-md` condition: available `index-md` plans reject missing,
nonexistent, or invalid INDEX.md artifacts. The `_EvalGuard` read boundary
allows reads of the configured index path alongside the architecture tree.
Pending conditions (`index-md`, `combined`) skip index validation and remain
unchanged. Baseline and `arch-query` behavior is preserved. `index-md` and
`combined` remain pending because no artifact is staged in the manifest.

Validation: 341 focused tests passed (64 new + 277 existing), manifest
validation PASS, canary report PASS, Ruff lint passed, `git diff --check`
passed. No evaluation, agent, or paid call was run. Estimated cost: $0.00.

Task note: `docs/notes/materialize-index-evaluation-artifact.md`.

## 2026-07-25 — Enable the Implemented arch-query Experiment Condition

**Task**: `docs/tasks/done/enable-arch-query-condition.md`

Reconciled the analyzer-assisted experiment manifest with the reviewed
arch-query evaluator boundary. The `arch-query` condition is now `available`
with Bash as a constrained transport (guard validates: bare `arch-query query`,
approved subcommands, JSON output, base-dir inside tree). `query_binary_version`
requires `git_sha` provenance. `index-md` and `combined` remain pending.
Manifest version bumped to 1.1.0.

Validation: 277 focused tests passed, manifest validation PASS (2 available,
2 pending), canary report PASS (no violations), ruff and `git diff --check`
passed. No evaluation, agent, or paid call was run. Estimated cost: $0.00.

## 2026-07-25 — Enable the Query-Aware Evaluation Boundary

**Task**: `docs/tasks/done/enable-query-aware-evaluation-boundary.md`

Added opt-in, command-restricted arch-query access to the consumer evaluator,
with explicit JSON/base-dir requirements, path and shell-operator enforcement,
query telemetry, and provenance metadata. Baseline behavior and pending
condition no-fallback remain unchanged. Validation: 205 focused tests, Ruff,
diff checks, and direct parser assertions passed; no evaluation was run.
Accepted in scoped commit.

## 2026-07-25 — Integrate Synthesis Insight Artifacts

**Task**: `docs/tasks/done/integrate-synthesis-insight-artifacts.md`

Connected the InsightArtifact contract to synthesis/partial phase handoffs,
validated and archived artifacts, and exposed metadata in run reports without
promoting insights into Markdown. Legacy and analyzer-only routes remain
unchanged. Validation: 156 focused tests, Ruff, and diff checks passed. No
production agents or evaluations were launched. Accepted in scoped commit.

## 2026-07-25 — Define a Condition-Aware Canary Report

**Task**: `docs/tasks/done/define-condition-canary-report.md`

Added the explicit ten-question canary manifest and deterministic readiness
report. The report distinguishes planned/available/unavailable/missing-result
cells, validates provenance and no-fallback behavior, handles nested
consumer-v1 raw-results envelopes, and never computes scores when results are
absent. Validation: 207 focused tests, Ruff, diff checks, default report, and
nested-result artifact checks passed. No agents or evaluations were launched.
Accepted in scoped commit after review.

## 2026-07-25 — Adapt the Evaluation Runner to the Condition Contract

**Task**: `docs/tasks/done/adapt-condition-aware-evaluation-runner.md`

Added the deterministic analyzer-assisted condition planner and integrated it
with consumer-v1 preflight, dry-run, explicit pending-condition output, and
backward-compatible baseline metadata. Planning paths lazy-load the optional
Claude SDK, so no-agent dry-runs work in minimal environments.

Validation: 145 focused tests passed; Ruff and `git diff --check` passed; host
dry-run and pending no-fallback checks passed. No paid or full-corpus
evaluation was run. Accepted in scoped commit after review.

## 2026-07-24 — Add File-Based Claude Prompt Invocation

Added `--prompt-file` support to `scripts/run_claude_container.sh` while
preserving positional and `--prompt` compatibility. Documented the stable
delegated-agent invocation and rejected simultaneous prompt sources. Validation:
shell syntax, both dry-run modes, conflict handling, and `git diff --check`.

## 2026-07-25 — Add Context Access Telemetry for Evaluation

**Task**: `docs/tasks/done/add-context-access-telemetry.md`

Added the versioned context telemetry collector, optional OTel-compatible/no-op
exporter, guard read/navigation/denial instrumentation, schema-compatible
metrics, and component propagation. Validation: 65 focused tests passed and
ruff passed. Accepted commit: `4627ce4b`.

## 2026-07-25 — Enforce Synthesis Routing and Source-Read Permissions

**Task**: `docs/tasks/done/enforce-synthesis-routing-permissions.md`

Aligned routing with `synthesis`, `partial`, and `legacy`; restricted both
agent routes; and preserved phase pre-seeding/merge behavior. Synthesis source
reads and discovery are denied, while partial reads remain bounded. Validation:
42 focused tests passed and ruff passed. Accepted commit: `7abd1c11`.

## 2026-07-24 — Define Bounded Synthesis Insights Contract

**Task**: `docs/tasks/done/define-synthesis-insights-contract.md`

Added the versioned `InsightArtifact` model, JSON Schema, deterministic
validator, bounded count/token metadata, explicit unknown/not-extracted states,
and valid/invalid fixtures. Merge isolation prevents non-authoritative insight
sections from entering analyzer-owned output. Focused tests: 84 passed; ruff
and `git diff --check` passed. Accepted commit: `fd8e784c`.

## 2026-07-24 — Add Initial Machine-Readable Query Contract

**Task**: `docs/tasks/done/add-initial-query-contract.md`

### Summary

Added the one-shot `arch-query query` command family with versioned JSON
responses for `callers-of`, `consumers-of`, `config-sources`, `crds`,
`dependency-status`, and `diff`. Existing structured CRD/diff/dependency data
is returned with snapshot evidence. Source-level queries that the architecture
snapshot cannot prove return `not-extracted` with a specific reason; missing
components return `unknown` rather than an empty success.

### Validation

- `GOCACHE=/tmp/arch-query-go-cache go test ./...` passed
- `GOCACHE=/tmp/arch-query-go-cache go vet ./...` passed
- `GOCACHE=/tmp/arch-query-go-cache go build ./...` passed
- Existing top-level commands and text output were unchanged.

### Boundaries

Query output is evidence, not an authority override. Call graph/config-source
extraction, OTel instrumentation, synthesis, and routing remain later plan
work; unsupported queries are explicitly visible rather than inferred.

---

## 2026-07-24 — Harvest Explicit Correction Proposals from Review Input

**Task**: `docs/tasks/done/harvest-correction-proposals.md`

### Summary

Added the opt-in `arch-analyzer harvest-proposals` command for
`tmp/feedback-data/corpus/extraction/staff-corrections.yaml`. It filters to
`human_review_type: sme_input` records with non-empty content and explicit
components/types, then emits one pending proposal per record/component/type
tuple. Component labels are copied verbatim; no canonical slug or fact is
inferred. Unsupported correction types map to explicit `unknown`.

### Validation

- `GOCACHE=/tmp/arch-analyzer-go-cache go test ./...` passed
- `GOCACHE=/tmp/arch-analyzer-go-cache go vet ./...` passed
- `GOCACHE=/tmp/arch-query-go-cache go test ./...` and `go vet ./...` passed
- Actual fixture: 169 records, 151 qualifying records, 1,577 proposals
- Generated output passed `arch-query proposals validate`
- Repeated generation with identical explicit `--created-date` was byte-identical
- No generated architecture or overlay files were changed.

### Boundaries

The harvester requires explicit `--created-date`; it defaults author to
`unknown` and preserves exact source/Jira/record/YAML-line provenance. All
records remain `pending`; review and application are separate operations.

---

## 2026-07-24 — Report Correction Frequency from Proposal Artifacts

**Task**: `docs/tasks/done/report-correction-frequency.md`

### Summary

Added a versioned, read-only `arch-query proposals report` command. It first
validates proposal artifacts, then deterministically aggregates correction
frequency by component, category, status, and release. Superseded proposals
remain in input identity and `superseded_count` but are excluded from active
aggregations. JSON and text output are supported, with concrete JSON semantics
documented in command help.

### Validation

- `GOCACHE=/tmp/arch-query-go-cache go test ./...` passed
- `GOCACHE=/tmp/arch-query-go-cache go vet ./...` passed
- `git diff --check` passed
- Nil and invalid proposal sets fail deterministically before aggregation
- No generated architecture or overlay files were modified.

### Boundaries

The report consumes proposal artifacts only. Staff/SME harvesting, alias
inference, automatic application, and priority inference remain separate work.

---

## 2026-07-24 — Define Reviewed Overlay Contract and Correction Proposals

**Task**: `docs/tasks/done/define-reviewed-overlay-contract.md`

### Summary

Added versioned correction proposals for human review, with component scope,
correction category, claim/replacement, provenance, author, releases,
creation/verification dates, review status, and supersession metadata.
Validation rejects unsupported statuses/categories, missing required metadata,
invalid dates, reversed dates, and duplicate IDs. Existing overlays can be
converted to pending proposals through a read-only opt-in command.

### Validation

- `GOCACHE=/tmp/arch-query-go-cache go test ./...` passed
- `GOCACHE=/tmp/arch-query-go-cache go vet ./...` passed
- `git diff --check` passed
- Default proposal generation is deterministic; `--generated-at` is explicit
- Existing overlay parser/CLI behavior and generated architecture output are
  unchanged.

### Boundaries

Proposals are never automatically applied. Text harvesting, correction
frequency reporting, and authoritative overlay application remain separate
plan tasks.

---

## 2026-07-24 — Generate Context Index and Version-Diff Contract

**Task**: `docs/tasks/done/generate-context-index.md`

### Summary

Added an opt-in `arch-query index` command and machine-readable JSON diff
contract. The index format v2 deterministically maps components to available
fact sections, common question categories, source artifact paths, and
available provenance metadata. JSON diff output reports added, removed, and
changed categories between snapshots while preserving explicit
`unknown`, `not-extracted`, and `incompatible` outcomes.

### Validation

- `GOCACHE=/tmp/arch-query-go-cache go test ./...` passed
- `GOCACHE=/tmp/arch-query-go-cache go vet ./...` passed
- `git diff --check` passed
- Existing text output remains unchanged; no `architecture/` or overlay files
  were modified.

### Boundaries

No aliases were invented because the existing component-map data contains no
explicit rename relationships. Overlays, correction harvesting, and the full
query suite remain separate plan tasks.

---

## 2026-07-24 — Define Analyzer Context Contract

**Task**: `docs/tasks/current/define-analyzer-context-contract.md`

### Summary

Implemented the versioned context contract envelope from Step 2 of the
analyzer-assisted agent architecture plan. The contract adds provenance,
applicability/freshness, confidence, maturity, scope/deployment topology,
dependency/upstream status, and behavioral evidence metadata to the
component-architecture.json schema. Explicit `unknown`, `not-extracted`,
and `needs-validation` states distinguish missing from confirmed values.

### Changes

| File | Change |
|------|--------|
| `src/arch-analyzer/internal/model/contract.go` | New: ContextContract struct, ValidationState/Maturity/DependencyStatus enums with Valid() methods, all sub-structs |
| `src/arch-analyzer/internal/model/input.go` | Added `ContextContract *ContextContract` field to Input |
| `src/arch-analyzer/internal/model/document.go` | Added `Contract *ContextContract` field to Document |
| `src/arch-analyzer/internal/model/contract_test.go` | New: 7 tests — round-trip, backward compat, explicit unknowns, JSON omission, enum validation |
| `src/arch-analyzer/schema/component-architecture.schema.json` | Added contextContract, validationState, maturity, dependencyStatus, and all sub-schema definitions |
| `src/arch-analyzer/internal/normalize/normalize.go` | Pass through ContextContract from Input to Document |
| `src/arch-analyzer/internal/normalize/normalize_test.go` | Added 2 tests — contract passthrough, nil passthrough |
| `src/arch-analyzer/internal/renderer/contract.go` | New: renderContract function, validationLabel with descriptive text for unknown/not-extracted states |
| `src/arch-analyzer/internal/renderer/contract_test.go` | New: 8 tests — absent contract, provenance, unknown labels, scope, dependencies, maturity, behavioral evidence, backward compatibility |
| `docs/notes/session-log.md` | This entry |
| `PLAN.md` | Task status updated |

### Design decisions

- Contract is an optional `context_contract` field on Input, preserving full backward compatibility
- Absent sub-fields mean "not provided" (nil pointer), distinct from explicit `unknown` or `not-extracted`
- Renderer labels `unknown` as "unknown (value not determined)" and `not-extracted` as "not-extracted (extraction not attempted)" to avoid implying facts
- No values are populated from inference; the contract is a schema/carrier only

### Negative controls verified

- Existing fixtures decode without change (tests confirm nil contract)
- Existing renderer output unchanged when contract is absent (tests confirm no "Context Contract" section)
- No query, overlay, synthesis, or evaluation code added
- No generated architecture files modified

### Validation

- `GOCACHE=/tmp/arch-analyzer-go-cache make -C src/arch-analyzer test` passed
- `python3 -m json.tool src/arch-analyzer/schema/component-architecture.schema.json` passed

---

## 2026-07-24 — Complete Tag Corpus Questions by Required Scope (re-score)

**Task**: `docs/tasks/done/tag-corpus-questions-by-required-scope.md`

### Summary

Produced the deterministic re-score artifact that was missing from the first
pass. Ran `score_results.py` against `raw-results.json` (40 raw entries) with
the current 31-question scoped corpus, writing separate `scored-results-scoped.json`
and `report-scoped.md` artifacts. 9 retired questions skipped as expected.

### Key metrics

| Metric | Tree A | Tree B |
|--------|--------|--------|
| Architecture-only composite (primary) | 0.5357 | 0.5000 |
| Full-repo composite | 0.0000 | 0.0000 |
| Overall composite | 0.4839 | 0.4516 |
| Scope: architecture count | 28 | 28 |
| Scope: full-repo count | 3 | 3 |

### Artifacts

| File | Purpose |
|------|---------|
| `benchmark/consumer-v1/results/v1-ab/scored-results-scoped.json` | Deterministic re-score with per-question scope tags |
| `benchmark/consumer-v1/results/v1-ab/report-scoped.md` | Human-readable scoped report |

### Tests

Added `TestScopedRescore` class (8 tests) to `tests/test_required_scope.py`.
All 24 tests pass. Historical `raw-results.json`, `scored-results.json`, and
`report.md` verified unchanged via checksum.

### Commands and exit codes

| Command | Exit |
|---------|------|
| `python3 score_results.py --results .../raw-results.json --corpus .../corpus.json --output .../scored-results-scoped.json` | 0 |
| `python3 generate_report.py --scored-results .../scored-results-scoped.json --output .../report-scoped.md` | 0 |
| `python3 -m pytest tests/test_required_scope.py -v` | 0 |

---

## 2026-07-24 — Reconcile Analyzer-Assisted Corpus Baseline

**Task**: `docs/tasks/done/reconcile-analyzer-assisted-corpus-baseline.md`

### Summary

Created a canonical corpus manifest that reconciles the plan's cited 94-question
baseline with the actual 29-question consumer-v1 corpus. Established separate
identities for active (29), retired (11), and unrecovered (54) questions. The
94-question figure and 79/94 score are recorded as unverified plan claims — no
artifact exists in the repository.

### Artifacts created

| File | Purpose |
|------|---------|
| `benchmark/analyzer-assisted-v1/corpus_manifest.json` | Canonical manifest with 40 entries, 3 gaps, aggregate counts |
| `benchmark/analyzer-assisted-v1/corpus_schema.json` | JSON Schema for the manifest format |
| `benchmark/analyzer-assisted-v1/validate_corpus.py` | Deterministic validator for the manifest |
| `tests/test_corpus_manifest.py` | 47 focused tests |
| `docs/notes/analyzer-assisted-corpus-baseline.md` | Validation note with gap accounting |

### Artifacts preserved (not modified)

- `benchmark/consumer-v1/corpus.json` (29 questions)
- `benchmark/consumer-v1/schema.json` (40-question minItems contract)
- `benchmark/consumer-v1/validate.py` (10-per-tier requirement)
- `benchmark/consumer-v1/results/v1-ab/` (raw and scored results)

### Validation results

- Manifest validator: PASS (40 entries, 29 active, 11 retired, 3 gaps)
- New tests: 47 passed
- Existing evaluation tests: 52 passed
- Consumer-v1 validator: unchanged, still reports 5 expected errors (29 < 40)
- No paid or full-corpus evaluation was run

### Next steps

1. Re-author 11 retired questions to reach the 40-question v1 schema target
2. Decide whether to author 54 additional questions or downgrade the plan's 94-question claim

## 2026-07-24 — Answerability Status and Source Evidence (v1.1.0)

**Task**: `docs/tasks/current/reconcile-analyzer-assisted-corpus-baseline.md`

### Summary

Addressed the rejection of the first pass: each active question now carries
explicit `answerability_status` and `source_evidence` fields, with values
derived from the consumer-v1 corpus (`source_file`, `source_line`,
`not_documented_expected`). Extended the schema, validator, and tests to
require and validate these fields.

### Changes

| File | Change |
|------|--------|
| `benchmark/analyzer-assisted-v1/corpus_manifest.json` | v1.0.0 → v1.1.0: added `answerability_status` (all 40 questions) and `source_evidence` (29 active); added `by_answerability_status` aggregate |
| `benchmark/analyzer-assisted-v1/corpus_schema.json` | Added `answerability_status` enum, `source_evidence` object, conditional requirement for active questions, `by_answerability_status` in aggregates |
| `benchmark/analyzer-assisted-v1/validate_corpus.py` | Added `validate_answerability()` (11 checks); added `by_answerability_status` aggregate validation |
| `tests/test_corpus_manifest.py` | 47 → 70 tests: added `TestAnswerabilityStatus` (8 tests), `TestSourceEvidenceCrossReference` (1 test), `TestValidatorAnswerability` (10 negative controls), answerability aggregate test, negative control tests |
| `docs/notes/analyzer-assisted-corpus-baseline.md` | Updated to reflect v1.1.0 deliverables |

### Validation results

- Manifest validator: PASS (40 entries, 29 active, 11 retired, 3 gaps)
- Tests: 70 passed
- Consumer-v1 validator: unchanged, still reports 5 expected errors (29 < 40)
- No consumer-v1 files modified
- No paid or full-corpus evaluation run

## 2026-07-24 — Re-author Retired Consumer-v1 Questions (INV-005, INV-009)

**Task**: `docs/tasks/done/reauthor-retired-consumer-v1-questions.md`

### Summary

Restored INV-005 and INV-009 with corrected expected answers and verified source
evidence. Both questions were retired during ground-truth auditing because their
original expected answers were factually wrong (contradicted by on-disk evidence).

### Evidence

| ID | Original Expected Answer (wrong) | Corrected Answer | Source Evidence |
|----|----------------------------------|------------------|----------------|
| INV-005 | "CodeFlare SDK is not listed in PLATFORM.md component inventory" | "Yes, codeflare-sdk is listed in README.md and has a dedicated architecture doc" | `architecture/rhoai.next/README.md:27` |
| INV-009 | "No. Triton is a Tested & Verified runtime only, not out-of-the-box" | "Yes, Triton is a default ServingRuntime in ModelMesh Serving" | `architecture/rhoai.next/modelmesh-serving.md:182` |

### Changes

| File | Change |
|------|--------|
| `benchmark/consumer-v1/corpus.json` | Added INV-005 and INV-009 entries (29 → 31 questions) |
| `benchmark/analyzer-assisted-v1/corpus_manifest.json` | INV-005 and INV-009: retired → active; aggregates updated (31 active, 9 retired) |
| `tests/test_corpus_manifest.py` | Updated 3 count assertions (29→31, 11→9) |
| `docs/notes/analyzer-assisted-corpus-baseline.md` | Updated counts throughout |

### Validation results

- Manifest validator: PASS (40 entries, 31 active, 9 retired, 3 gaps)
- Tests: 70 passed
- Consumer-v1 validator: 4 expected errors (31 < 40, Tier 3: 4/10, Tier 4: 7/10)
- No evaluation run; no existing results modified

## 2026-07-24 — INTG-002 Re-author Audit (Unresolved)

**Task**: `docs/tasks/current/reauthor-retired-intg-002.md`

### Summary

Audited INTG-002 for restoration. The original v1-ab question asked "Which
components does overlay 0011 (KServe LLMInferenceService and llm-d integration
architecture) affect?" with expected answer listing kserve, odh-model-controller,
llm-d-inference-scheduler, llm-d-router, and llm-d-kv-cache.

Result: **Unresolved — cannot restore.**

### Evidence audit

| Check | Result |
|-------|--------|
| Original question source | `overlays/0011-kserve-llm-d-architecture.md` `affects:` field — outside evaluation scope (architecture tree only) |
| Integration facts in architecture tree | Present in kserve.md, odh-model-controller.md, llm-d-inference-scheduler.md, llm-d-router.md, llm-d-kv-cache.md |
| Source file usability | All five component .md files have unresolved merge conflicts (18/17/18/18/18 conflict markers respectively) |
| Reliable source_line evidence | Cannot be established against conflicted files |

### Blocking condition

The architecture docs for all five affected components contain unresolved merge
conflicts from commit `9db926c2` (analyzer ownership expansion). Until these
conflicts are resolved, no reliable `source_file` + `source_line` evidence can
be pinned for a re-authored integration question in this topic area.

### Changes

| File | Change |
|------|--------|
| `benchmark/analyzer-assisted-v1/corpus_manifest.json` | INTG-002 retirement_reason updated with specific unresolved reason |
| `docs/tasks/current/reauthor-retired-intg-002.md` | Status updated to blocked |

### Artifacts preserved (not modified)

- `benchmark/consumer-v1/corpus.json` (31 questions, unchanged)
- All other manifest entries, schema, validator, results
- No evaluation run; no existing results modified

## 2026-07-24 — NAV-006 Re-author Audit (Unresolved)

**Task**: `docs/tasks/done/reauthor-retired-nav-006.md`

### Summary

Audited NAV-006 for restoration. The original v1-ab question asked "How do overlay
lifecycle states work?" with expected answer describing two lifecycle states
(active/superseded), consumer filtering by status/release/affects, and
affects:[platform] scope — all sourced from `overlays/README.md`.

Result: **Unresolved — cannot restore.**

### Evidence audit

| Check | Result |
|-------|--------|
| Original question | Unambiguous — single overlay lifecycle concept in this repo |
| Expected answer accuracy | Every claim is near-exact paraphrase of `overlays/README.md` lines 72-82 |
| Source file existence | `overlays/README.md` exists (86 lines), content verified |
| Evaluation scope | `overlays/README.md` NOT mounted in evaluation container |
| Alternative source in architecture tree | None — overlay lifecycle not documented in any architecture file |
| Policy | Bug resolution placed overlay knowledge out of benchmark scope |

### Key distinction from NAV-003

NAV-003 was unresolvable due to question quality (ambiguity, no citable source_line).
NAV-006 has exact, complete source evidence — blocked solely by evaluation scope.

### Recovery path

Mount `overlays/` in evaluation container, or implement corpus scope tagging
(`docs/tasks/pending/tag-corpus-questions-by-required-scope.md`).

### Changes

| File | Change |
|------|--------|
| `benchmark/analyzer-assisted-v1/corpus_manifest.json` | NAV-006 retirement_reason updated with specific evidence and unresolved reason |

### Artifacts preserved (not modified)

- `benchmark/consumer-v1/corpus.json` (31 questions, unchanged)
- All other manifest entries, schema, validator, results
- No evaluation run; no existing results modified

## 2026-07-24 — NAV-003 Re-author Audit (Unresolved)

**Task**: `docs/tasks/done/reauthor-retired-nav-003.md`

### Summary

Audited NAV-003 for restoration. The original v1-ab question asked "What overlays
modify the base architecture?" with expected answer listing 20 architecture context
overlays (0001-0018) from the `overlays/` directory.

Result: **Unresolved — cannot restore.**

### Evidence audit

| Check | Result |
|-------|--------|
| Original question | Ambiguous: "overlays" conflates architecture context overlays (`overlays/` directory) with Kustomize overlays (`config/overlays/` in component repos) |
| Expected answer accuracy | Factually correct: 20 active overlay files exist, all `status: active` in frontmatter |
| v1-ab agent behavior | "Confused architecture overlays with Kustomize overlays" — answered about Kustomize overlays from component docs |
| Source evidence | No single file at a citable source_line documents overlay count or topics; `overlays/README.md` explains concept only |
| Verifiability | Requires directory listing + frontmatter reads across 20 files |

### Blocking conditions

1. Question ambiguity would cause repeated evaluation failures
2. No citable source_file + source_line for the expected answer

### Recovery path

Re-author the question to disambiguate — e.g., "What is the purpose of the
overlays/ directory?" answerable from `overlays/README.md` lines 1-3.

### Changes

| File | Change |
|------|--------|
| `benchmark/analyzer-assisted-v1/corpus_manifest.json` | NAV-003 retirement_reason updated with specific unresolved reason |

### Artifacts preserved (not modified)

- `benchmark/consumer-v1/corpus.json` (31 questions, unchanged)
- All other manifest entries, schema, validator, results
- No evaluation run; no existing results modified

---

## Session: Tag Corpus Questions by Required Scope — 2026-07-24

### Task

Add `required_scope` field to each corpus question so the evaluation
harness can filter/report by what content the agent needs access to.

### Reconciliation

The task listed 40 questions across 3 scopes, but the actual corpus has
31 questions (9 retired). Reconciled affected-question lists:

- Task counting errors: listed "3 full-repo" but named 4 IDs; subtotals
  27+10+3=40 but 27+10+4=41.
- INV-005 and INV-009 were re-authored with architecture-only sources,
  moving from `architecture+overlays` to `architecture`.
- NAV-001 (`architecture/current-ga`) classified as `architecture` by
  source_file evidence, not `full-repo` as task originally listed.
- All 8 `architecture+overlays` questions were retired (INTG-002/3/4/6/8/10,
  NAV-003/6); NAV-010 also absent.

Final scope counts: 28 architecture, 0 architecture+overlays, 3 full-repo.

### Changes

| File | Change |
|------|--------|
| `benchmark/consumer-v1/schema.json` | Added `required_scope` to required fields and properties (enum: architecture, architecture+overlays, full-repo) |
| `benchmark/consumer-v1/corpus.json` | Added `required_scope` to all 31 questions |
| `benchmark/consumer-v1/validate.py` | Added `validate_scopes()`, scope counts in PASS output, `required_scope` in required fields list |
| `benchmark/consumer-v1/score_results.py` | Added `by_scope` aggregates, `required_scope` in per-question scored output |
| `benchmark/consumer-v1/generate_report.py` | Added Per-Scope Scores section with primary quality metric callout |
| `tests/test_required_scope.py` | 16 focused tests covering schema, corpus, validator, scorer, reporter |
| `docs/tasks/done/tag-corpus-questions-by-required-scope.md` | Updated with reconciliation notes, acceptance criteria checked, status done |
| `PLAN.md` | Updated task status |

### Validation

- `python3 -m pytest tests/test_required_scope.py`: 16/16 passed
- `python3 -m pytest tests/test_corpus_manifest.py`: 70/70 passed (no regressions)
- `python3 benchmark/consumer-v1/validate.py`: 4 pre-existing errors (31 < 40 minimum, tier count gaps) — no new errors
- No evaluation run performed; no existing results modified
