# Session Log

## 2026-07-26 — Add Local Claude OTel and API Capture

Task: `docs/tasks/current/add-local-claude-otel-api-capture.md`

Implemented local Claude Code OTel capture and explicitly opt-in API-body
capture. The launcher preserves existing `.env`/caller-precedence
authentication loading. OTel output passes through a FIFO streaming redaction
filter before `tmp/otel-capture/otel-console.log` or terminal emission; no raw
capture is written by `tee` or a post-run rewrite.

### Validation

- `.venv/bin/pytest -q tests/test_telemetry_redact.py`: **80 passed**
- `.venv/bin/ruff check lib/telemetry_redact.py tests/test_telemetry_redact.py`:
  **PASS**
- `bash -n scripts/run_claude_container.sh`: **PASS**
- `git diff --check`: **PASS**

Token/cost field presence depends on the Claude Code OTel version and was not
measured in this local validation. Raw benchmark/API dumps remain ignored
under `tmp/`; no secrets or raw capture files are intended for Git.

## 2026-07-26 — Full Provisional 40-Question Corpus Evaluation

Task: `docs/tasks/current/run-full-provisional-corpus-evaluation.md`

Executed the full 320-session provisional evaluation: 4 conditions × 40 questions
× 2 trees, model opus, max 8 concurrent sessions per condition.

### Results

- **320/320 sessions completed**, 0 failures
- **Total cost**: $117.13 ($28.88 baseline, $29.99 index-md, $26.98 arch-query,
  $31.28 combined)
- **Wall time**: 2338.66 seconds (39.0 minutes); 2-hour guard not reached

### Scores (tree_a avg / tree_b avg)

- baseline: 0.5375 / 0.475
- index-md: 0.5125 / 0.475
- arch-query: 0.5250 / 0.4458
- combined: 0.5500 / 0.4458

### MLflow

- 320 runs tracked locally, experiment `analyzer-assisted-provisional-full-corpus`,
  `MLFLOW_RUNS_DIR=/workspace/tmp/mlflow-runs/provisional-full-corpus`
- Read-back verified: 320 runs (80 per condition)

### Validators run

All PASS: consumer-v1 validate.py (40 questions, 10/tier), analyzer-assisted-v1
validate.py (manifest v1.3.0, 4 conditions), validate_corpus.py (40 active, 0
retired), canary_report.py (no violations), validate_adjudication.py (35
proposals), validate_calibration.py (24 questions), `git diff --check` (exit 0).

### Controls

- No `tmp/feedback-data` read; no human labels/categories filled
- No code, schemas, corpus, architecture, overlays, or generated docs modified
- No external state created; no commits made
- Used corrected rhoai.next identities from `tmp/provisional-pilot/`
- Local MLflow only (MLFLOW_TRACKING_URI unset)

### Artifacts

All under `tmp/provisional-full-corpus/results/`; SHA-256 hashes in
`full-corpus-summary.json`.

### Changed files

- `docs/tasks/current/run-full-provisional-corpus-evaluation.md` (execution record)
- `docs/notes/session-log.md` (this entry)

---

## 2026-07-26 — Reconcile Pilot Evidence Across Readiness Documentation

Task: `docs/tasks/current/reconcile-pilot-readiness-evidence.md`

Reconciled stale claims across four durable readiness documents with the
accepted 32-session provisional pilot evidence (32/32 sessions, 4/40
questions, $8.1087, 0 failures, 347.65 s, local MLflow read-back).

### Stale claims updated

- **Audit task** (`docs/tasks/done/audit-analyzer-plan-success-criteria.md`):
  user authorization gate updated from "Not obtained" to "Bounded pilot
  authorized and completed; full-corpus authorization not obtained"; S2
  evidence updated with pilot reference; "No canary has run" updated to
  note bounded pilot with limitations.
- **Evaluation contract note** (`docs/notes/analyzer-assisted-evaluation-contract.md`):
  full-corpus evaluation blocker updated from "Blocked" to "Bounded pilot
  completed; full-corpus blocked"; validation results updated with pilot
  evidence.
- **Benchmark README** (`benchmark/analyzer-assisted-v1/README.md`):
  infrastructure status updated with pilot evidence; user authorization
  blocker updated.
- **No-human-data rollout track** (`docs/notes/no-human-data-provisional-rollout-track.md`):
  S2 provisional measurement updated with pilot evidence; authorization
  gate updated with pilot reference.

### Gates preserved as incomplete

Human-label, semantic-calibration, external-OTel, full-corpus,
external-MLflow, and legacy-retirement gates remain explicitly incomplete.
No full rollout success claimed.

Accepted checkpoint: `9a317b6e`.

### Validators run

All PASS: consumer-v1 validate.py (40 questions, 10/tier),
analyzer-assisted-v1 validate.py (manifest v1.3.0, 4 conditions),
validate_corpus.py (40 active, 0 retired), `git diff --check` (exit 0).

### Changed files

- `docs/tasks/done/audit-analyzer-plan-success-criteria.md` (S2, user
  authorization gate, legacy-route statement)
- `docs/notes/analyzer-assisted-evaluation-contract.md` (full-corpus
  blocker, validation results)
- `benchmark/analyzer-assisted-v1/README.md` (infrastructure status,
  user authorization blocker)
- `docs/notes/no-human-data-provisional-rollout-track.md` (S2
  measurement, authorization gate)
- `PLAN.md` (task added to recently completed)
- `docs/notes/session-log.md` (this entry)
- `docs/tasks/done/reconcile-pilot-readiness-evidence.md` (status
  updated to done)

No models run, no human data consumed or produced, no code/schema/corpus/
generated architecture/pilot artifacts/external state modified.

---

## 2026-07-26 — Add Prior-Snapshot Deterministic Regression Report

Task: `docs/tasks/done/add-prior-snapshot-regression-report.md`

Implemented deterministic bulk comparison of architecture snapshot
directories using existing `lib/architecture_baseline.py` semantics.

**Artifacts created**:
- `lib/snapshot_regression.py` — core comparison module
- `scripts/compare_snapshot_regression.py` — CLI entry point
- `tests/test_snapshot_regression.py` — 13 focused tests

**Default report**: `architecture/rhoai.next.bak` → `architecture/rhoai.next`
— 92 baseline, 99 candidate, 90 paired, 2 missing, 9 additional;
row recall 470/11832 (4.0%), structured recall 188/6151 (3.1%),
115 conflicts, 0 missing required sections; thresholds PASS.

**Documentation updated**:
- `docs/notes/no-human-data-provisional-rollout-track.md` (snapshot
  regression report section)
- Task record (handoff evidence)

**Validation**: 13/13 tests pass; ruff clean; threshold-failure check exits 1
when configured below the observed missing-component count; validators pass;
git diff --check clean.
No models run, no human data consumed or produced. Ready for a scoped
checkpoint commit after review. Accepted checkpoint: `39b77717`.

## 2026-07-26 — Align INDEX.md with Canonical Evaluation Tree (corrected)

Task: `docs/tasks/done/align-index-artifact-with-canonical-tree.md`

Regenerated `benchmark/analyzer-assisted-v1/INDEX.md` from the canonical
`architecture/rhoai.next` snapshot so the index header version is `rhoai.next`
and component source paths are `rhoai.next/...`. The prior attempt changed
only source_revision while leaving version=rhoai-3.5 and rhoai-3.5 source
paths (reading from the wrong architecture directory).

### Changes

- INDEX.md regenerated from `architecture/rhoai.next` via
  `arch-query index --version rhoai.next` and `materialize_index.py`
- Header version: `rhoai-3.5` → `rhoai.next`
- Component count: 69 → 99 (rhoai.next has 30 more components)
- Source revision unchanged: `c5c8201c748a8c982677f0948e686178bf5d2bf8`
- Deterministic hash: `c193e7fc100060981367d8f91274fe009dc503174d641049d9870f960f1c6f03`

### Updated files

- `benchmark/analyzer-assisted-v1/INDEX.md` (version, paths, component count)
- `benchmark/analyzer-assisted-v1/experiment.json` (both index_artifact
  architecture_version and component_count)
- `docs/notes/pin-index-experiment-artifact.md` (version, component count)
- `docs/notes/enable-combined-experiment-condition.md` (version, component count)
- `tests/test_materialize_index.py` (question count assertion: 31→40)
- `docs/tasks/done/align-index-artifact-with-canonical-tree.md` (rewritten)
- `PLAN.md` (updated completion annotation)
- `docs/notes/session-log.md` (this corrected entry)

### Validators run

All PASS: materialize_index.py --validate (99 components, format v1),
deterministic regeneration comparison (exact hash match), 135/135 focused
tests, analyzer-assisted-v1 validate.py (manifest v1.3.0, 4 conditions),
consumer-v1 validate.py (40 questions), validate_corpus.py (40 active),
`git diff --check`.

---

## 2026-07-26 — Define No-Human-Data Rollout Track

Task: `docs/tasks/done/define-no-human-data-rollout-track.md`

Defined a durable provisional rollout track for the documented reality that
additional human adjudication and calibration data is unlikely to arrive.

### Key decisions

- Existing 94-question feedback package is directional signal only — it
  informs plan design priorities but cannot serve as reproducible evaluation
  evidence or substitute for human labels.
- Provisional track permits: deterministic regression testing (S1),
  exact-match scoring against 40-question corpus (S2 subset), automated
  root-cause signal generation (S3 directional), contract-field presence
  checks (S4/S5), context telemetry (S6), insight artifact structure (S7).
- Provisional track prohibits: LLM-as-judge semantic scoring (no calibrated
  judge), human-review quality assertions (no scores exist), authoritative
  failure classifications (all `human_category: null`), full rollout gate
  satisfaction, legacy route retirement.
- Human review scores (S8) are not measurable without human labels.
- All `human_label` and `human_category` values remain null. No fields were
  filled or relabeled.
- The provisional track is a subset of the full rollout track, not a
  replacement. When human data becomes available, the full gates apply.

### Validators run

All PASS: consumer-v1 validate.py (40 questions), analyzer-assisted-v1
validate.py (manifest v1.3.0, 4 conditions), validate_corpus.py (40
active), `git diff --check`.

### Changed files

- `docs/notes/no-human-data-provisional-rollout-track.md` (new: durable
  provisional track note)
- `docs/plans/analyzer-assisted-agent-architecture.md` (provisional track
  subsection added under Success criteria)
- `docs/notes/analyzer-assisted-evaluation-contract.md` (provisional
  evaluation track section added; stale `current/` task path corrected)
- `docs/tasks/done/define-no-human-data-rollout-track.md` (moved from
  `current/`; status updated to done)
- `PLAN.md` (task added to recently completed)
- `docs/notes/session-log.md` (this entry)

---

## 2026-07-25 — Reconcile Historical Feedback Provenance

Task: `docs/tasks/done/reconcile-historical-feedback-provenance.md`

Validated the git-ignored `tmp/feedback-data/` package (94 questions, 13
files, 11 categories) against the plan's historical 84% baseline claim.
Created a durable provenance note at
`docs/notes/historical-feedback-provenance.md` documenting what the package
proves and cannot prove.

### Key findings

- The 94-question corpus exists with per-question verdicts, but the 84%
  accuracy claim is internally inconsistent: the baseline file yields 79/94
  while the questions file yields 81/94 correct. Five of 11 categories have
  mismatched correct counts between the two files. Human-reviewed counts
  also differ (40 vs 45). The baseline's correct+corrected+flagged sums to
  92, not 94.
- Reproducibility requires external systems (Observatory, JIRA, pipeline
  data repos) not available in this repository. Extraction scripts are not
  preserved.
- The feedback data provides useful directional signal (category weaknesses,
  semantic gap patterns, correction frequency) that informed plan design but
  cannot serve as a reproducible evaluation baseline.
- The canonical 40-question corpus, its manifest, and the plan's existing
  "Unverified" classification are all unchanged.

### Validators run

All PASS: consumer-v1 validate.py (40 questions), analyzer-assisted-v1
validate.py (manifest v1.3.0, 4 conditions), validate_corpus.py (40
active), `git diff --check`.

### Changed files

- `docs/notes/historical-feedback-provenance.md` (new: durable provenance note)
- `docs/tasks/done/reconcile-historical-feedback-provenance.md` (moved from `current/`)
- `PLAN.md` (task added to recently completed)
- `docs/notes/session-log.md` (this entry)

---

## 2026-07-25 — Audit Analyzer Plan Success Criteria

Task: `docs/tasks/done/audit-analyzer-plan-success-criteria.md`

Audited every plan success criterion (S1–S8) and rollout gate against
repository files, tests, validators, and durable artifacts. Produced a
durable evidence matrix classifying each as verified local, incomplete
(requires evaluation run or human input), or unverified external.

### Key findings

- No actionable repository-side gap remains (Steps 2–4 complete at
  19/19 + 7/7 + 24/28; 4 external gates).
- Five external inputs required for Step 5: human adjudication (35
  proposals), human labeling (24 questions), user authorization, MLflow
  server, external-fetch OTel producer.
- v1-ab reproducible baseline: tree_a avg 0.3625, tree_b avg 0.3375
  (40 questions). The 84%/94-question figure remains unverified external
  historical feedback.
- Legacy route preserved; no canary has run; plan completion not claimed.

### Validators run

All PASS: consumer-v1 validate.py (40 questions), analyzer-assisted-v1
validate.py (manifest v1.3.0, 4 conditions), validate_corpus.py (40
active), validate_adjudication.py (35 proposals), validate_calibration.py
(24 questions), Go tests (arch-analyzer + arch-query), Python tests
(1147 passed, 5 pre-existing failures, 6 skipped), `git diff --check`.

### Changed files

- `docs/tasks/done/audit-analyzer-plan-success-criteria.md` (evidence matrix added)
- `PLAN.md` (task added to recently completed)
- `docs/notes/session-log.md` (this entry)

---

## 2026-07-25 — Reconcile Plan Step 3 and Step 4 Status

Task: `docs/tasks/done/reconcile-plan-step3-step4-status.md`

Reconciled the architecture plan's implementation sequence with the
independently reviewed audit evidence from
`docs/tasks/done/audit-local-plan-implementation-gaps.md`.

### Changes

| File | Change |
|------|--------|
| `docs/plans/analyzer-assisted-agent-architecture.md` | Added Step 3 implementation annotation (7/7 verified); added Step 4 implementation annotation (24/28 verified, 4 externally blocked); updated MLflow gate to include committed local REST validation (ephemeral MLflow 2.22.0, `max_results` bug fix `9b5a87bc`, 95 tests) alongside file-backed validation |
| `PLAN.md` | Added reconciliation task to recently completed |
| `docs/notes/session-log.md` | This entry |
| `docs/tasks/done/reconcile-plan-step3-step4-status.md` | Moved from `current/`; status updated to done |

### Step 3 annotation (7/7)

All seven sub-requirements verified as implemented: correction harvesting,
reviewable overlay proposals, last-verified metadata, correction-frequency
reports, regression assertions (18 tests), overlay preservation across
regeneration, and source-audited empty categories.

### Step 4 annotation (24/28)

Twenty-four sub-requirements verified as implemented. Four externally blocked
items map directly to Step 5 external-input gates:

1. External-fetch OTel producer (external script not in repository)
2. MLflow server registration (requires `MLFLOW_TRACKING_URI`)
3. Human labels/adjudication (templates prepared, all human fields null)
4. User authorization (required for paid/full-corpus evaluation)

### MLflow gate update

The Step 5 gate table now reflects both validated local modes:
- File-backed (`MLFLOW_RUNS_DIR`): preflight, dry-run, live tracking with
  read-back
- REST: ephemeral MLflow 2.22.0 server validation, `max_results` bug fixed
  in commit `4be242c5`, 95 tests pass

External server registration remains pending.

### Validation

- `git diff --check`: PASS
- No code, schema, corpus, generated architecture, or external state modified
- No evaluation or benchmark was run
- Application/evaluation cost: $0.00; launcher-reported delegated-agent cost:
  $1.61828225

---

## 2026-07-25 — Validate Local MLflow REST Registration

Task: `docs/tasks/done/validate-mlflow-rest-registration-local.md`

Validated the REST tracking adapter against an ephemeral local MLflow
2.22.0 server (SQLite backend, port 5555, no-serve-artifacts). Installed
`mlflow==2.22.0` via pip (matching the Dockerfile pin). Server started
in ~4s and responded to experiments/search API.

### REST Preflight

`MLFLOW_TRACKING_URI=http://127.0.0.1:5555 python3 benchmark/analyzer-assisted-v1/track_experiment.py --preflight`:
configured=true, reachable=true, mode=rest, errors=[], tracking_contract_version=1.0.0.
Dry-run preflight correctly skips connectivity check.

### REST Operations Validated

Individual `MLflowRESTClient` operations confirmed against the live
server: `create_run` (run_id=4484799b63f94dc291212990e13a64a7,
run_name=baseline/INV-001), `log_metrics` (4 metrics, exact values),
`set_terminated` (FINISHED). Read-back via `/api/2.0/mlflow/runs/get`
verified experiment_id=1, 8 tags, 4 metrics, status=FINISHED.

### Bug Discovered

`MLflowRESTClient.get_or_create_experiment()` omits `max_results` in the
experiments/search POST body. MLflow 2.22.0 defaults it to 0 and rejects
with HTTP 400 (`INVALID_PARAMETER_VALUE`). The `ping()` method correctly
sends `max_results: 1`, so preflight passes, but the full
`track_result()` REST flow fails at experiment lookup. Fix: add
`"max_results": 10` to the search body. The mock server tests don't
catch this because they don't validate `max_results`.

### Cleanup

Server killed (PID 358), `/tmp/mlflow-rest-validate/` removed (SQLite
DB, logs, artifacts, PID, fixture). Directory verified absent.

### Validators

- `python3 -m pytest tests/test_mlflow_tracking.py -v`: 94 passed
- `python3 benchmark/analyzer-assisted-v1/validate.py`: PASS (v1.3.0, 4 conditions)
- `git diff --check`: PASS

### Cost

Application/evaluation cost: $0.00. Launcher-reported delegated-agent cost:
$4.34654.

### Updated Files

- `docs/tasks/done/validate-mlflow-rest-registration-local.md` (validation evidence)
- `benchmark/analyzer-assisted-v1/README.md` (REST validation and bug note)
- `docs/notes/analyzer-assisted-evaluation-contract.md` (MLflow status update)
- `PLAN.md` (active task)
- `docs/notes/session-log.md`

---

## 2026-07-25 — Audit Local Plan Implementation Gaps (Steps 2–4)

Task: `docs/tasks/done/audit-local-plan-implementation-gaps.md`

Audited every Step 2–4 requirement from the analyzer-assisted agent
architecture plan against actual implementation files. Classified 45
sub-requirements total: 14/19 Step 2 implemented (5 locally blocked —
extraction-level fields), 7/7 Step 3 implemented, 24/28 Step 4 implemented
(4 locally blocked — external gates).

One concrete gap found and closed: Step 3 requirement 3.5 "regression
assertions for known corrections" had no test validating the shipped
`lib/analyzer_correction_adjudications.json`. Created
`tests/test_correction_adjudication_regression.py` with 18 focused tests
across 6 classes covering structure, entry validity, loader integration,
count regression guards (≥68 absences, ≥16 audited, ≥20/≥10 distinct
components), and spot-checks for known correction patterns
(trustyai-service-operator auth, batch-gateway components, caikit-tgis and
distributed-workloads source-audited).

Validation: 18 new tests PASS, 57 related existing tests PASS,
`git diff --check` PASS. 6 pre-existing async test failures
(missing pytest-asyncio in host) unrelated to this task. No model called,
no evaluation ran, no generated output modified. Cost: $0.00.

Changed files: `tests/test_correction_adjudication_regression.py` (new),
`docs/tasks/done/audit-local-plan-implementation-gaps.md` (audit evidence),
`docs/notes/session-log.md`.

---

## 2026-07-25 — Reconcile External-Gate Preparation Artifacts

Task: `docs/tasks/done/reconcile-plan-external-gate-artifacts.md`

Linked the 24-question calibration template (v0.1.0, all `human_label: null`)
and 35-proposal adjudication template (v0.1.0, all `human_category: null`) to
the analyzer-assisted plan, benchmark README, and evaluation contract note.
Added LLM-as-judge calibration gate to Step 5 gate tables. Updated root-cause
classification gate with adjudication template path and validator. Fixed stale
"1 retired" references in plan (now 0 retired) and "36 active" in README
(now 40 active). All external gates remain explicitly incomplete: human
labeling, human adjudication, MLflow registration, OTel producer, and user
authorization.

Changed files: `docs/plans/analyzer-assisted-agent-architecture.md`,
`benchmark/analyzer-assisted-v1/README.md`,
`docs/notes/analyzer-assisted-evaluation-contract.md`, `PLAN.md`,
`docs/notes/session-log.md`. No corpus, results, code, or generated
architecture output was modified. No evaluation or benchmark was run.

---

## 2026-07-25 — Prepare Failure-Classification Adjudication Template

Task: `docs/tasks/done/prepare-failure-adjudication-template.md`

Created a deterministic 35-proposal adjudication template (v0.1.0) from the
v1-ab scored results for human failure-classification review. All 35 proposals
are "unresolved" because the v1-ab evaluation predates context telemetry — no
direct infrastructure, stale-context, missing-context, or unsupported-inference
signals are available. All `human_category` values are null.

Changed files: `benchmark/consumer-v1/adjudication_template.json` (35-proposal
template), `benchmark/consumer-v1/adjudication_schema.json` (JSON Schema
2020-12), `benchmark/consumer-v1/validate_adjudication.py` (deterministic
validator with corpus cross-check), `tests/test_adjudication_template.py`
(44 tests).

Also moved `docs/tasks/done/improve-corpus-v1-scoring-accuracy.md` to
`done/` (Phase 1 complete and verified; Phase 2 deferred to separate task).

Validation: adjudication validator PASS (35 proposals), 44 focused tests PASS,
corpus manifest validator PASS (40 active, 0 retired), consumer-v1 validator
PASS (40 questions), `git diff --check` PASS. No model called, no evaluation
or benchmark ran. Human adjudication remains an external gate.

---

## 2026-07-25 — Integrate Evaluation Context Telemetry (accepted)

**Task**: `docs/tasks/done/integrate-evaluation-context-telemetry.md`

Wired the existing versioned context telemetry collector into the consumer-v1
evaluation guard (`_EvalGuard`) so reads, denials, searches, and queries
populate deterministic `context_metrics` in per-tree telemetry and result
provenance.

Changes: `benchmark/consumer-v1/run_evaluation.py` — added
`ContextTelemetryCollector` to `_EvalGuard.__init__` with condition-aware
route labeling (baseline/index/query/combined). Instrumented `_check_read`
(useful reads vs INDEX.md navigation reads vs denied), `_check_search`
(navigation reads and denied), `_check_query` (query.issued and
query.denied), and `pre_tool_use` (denied tool calls). Added
`context_metrics` to `telemetry()` output and `context_metrics` to per-tree
result dicts. Added `context_provenance()` method for serialized event data.
Added `context_telemetry_version` to result provenance. No permissions,
condition availability, or agent behavior changed.

New test file: `tests/test_eval_guard_telemetry.py` — 34 focused tests
covering baseline/index/query/combined context_metrics, denied operations,
exporter integration, serialization/provenance, backward compatibility, and
search denial tracking.

Validation: 287 related focused tests passed (40 new + 247 existing related
tests). Ruff lint PASS. `git diff --check` PASS. No evaluation, agent, or paid
call was run. Estimated cost: $0.00.

### Refinement: context_provenance wiring (2026-07-25)

Independent review found `context_provenance()` was implemented/tested but
never attached to actual per-tree results or raw-result provenance.

Changes: `run_question_against_tree()` now attaches `context_provenance` to
both success and error return dicts. `run_evaluation()` adds a
`context_provenance` block to condition-level `raw_results["provenance"]`
with `context_telemetry_version` and `events_attached_per_tree: True`.
Added `TestContextProvenanceInResults` class (7 tests) covering baseline,
index, query, combined, denied activity, metrics consistency, and empty guard.
Total: 40 focused tests pass, ruff clean, result schema intact, no evaluation
run.

### Acceptance (2026-07-25)

All 6 acceptance criteria verified checked. 40 focused tests (9 classes).
Ruff/diff clean. No evaluation, no agent, no paid call. Task note:
`docs/notes/integrate-evaluation-context-telemetry.md`. Moved to
`docs/tasks/done/`. Accepted checkpoint commit: `7856d597`. Estimated cost:
$0.00.

## 2026-07-25 — Enable the Combined INDEX.md + arch-query Condition (accepted)

**Task**: `docs/tasks/done/enable-combined-experiment-condition.md`

Enabled the combined experiment condition requiring both a validated pinned
INDEX.md artifact path/identity and explicit arch-query binary provenance.
Missing either artifact is now an explicit planning failure — no silent
fallback to baseline or partial retrieval path.

Changes: experiment.json combined condition flipped to `available: true` with
`index_artifact` section referencing the pinned INDEX.md (rhoai-3.5, 69
components, source revision `56eb7ab0`). Manifest version bumped 1.2.0 → 1.3.0.
Canary manifest experiment ref updated. README updated.

Test updates across 5 files: assertions for combined changed from
pending/unavailable to available; new tests verify combined requires both
`index_revision_source` and `query_binary_version` provenance, plus a validated
index artifact path. Canary report expectations updated (40 planned, 0
unavailable). CLI no-fallback tests restructured to verify that missing
artifacts produce explicit planning errors rather than silent fallback.

Baseline, index-md, and arch-query behavior preserved. Bash remains constrained
to approved bare arch-query JSON/base-dir commands. INDEX.md is read-only. No
evaluation, agent, or paid call was run.

Validation: 353 focused tests passed. Manifest validation PASS (4 available,
0 pending), canary report PASS (40 planned, 0 unavailable, no violations),
artifact provenance PASS, Ruff lint PASS, `git diff --check` PASS, Go tests
PASS. Explicit missing-artifact failures verified for both index and query
provenance. No evaluation executed. Estimated cost: $0.00.

Status: accepted in scoped commit `125f4a5b`. Task note:
`docs/notes/enable-combined-experiment-condition.md`.

## 2026-07-25 — Pin INDEX.md Experiment Artifact

**Task**: `docs/tasks/done/pin-index-experiment-artifact.md`

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

Status: accepted in scoped commit `b526ef4c`. Task note:
`docs/notes/pin-index-experiment-artifact.md`.

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

**Task**: `docs/tasks/done/define-analyzer-context-contract.md`

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

**Task**: `docs/tasks/done/reconcile-analyzer-assisted-corpus-baseline.md`

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

**Task**: `docs/tasks/done/reauthor-retired-intg-002.md`

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
| `docs/tasks/done/reauthor-retired-intg-002.md` | Status updated to blocked |

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

---

## 2026-07-25 — Validate Context Telemetry in Canary Readiness

Task: `docs/tasks/done/validate-context-telemetry-canary-readiness.md`

### Goal

Extend the canary validator so available-condition result records require valid
context telemetry version, per-tree context provenance, and condition-level
attachment evidence before evaluation is considered rollout-ready.

### Changes

| File | Change |
|------|--------|
| `benchmark/analyzer-assisted-v1/canary_report.py` | Added `_check_context_telemetry()` and `missing-context-telemetry` violation type in `_detect_violations()` |
| `tests/test_canary_report.py` | Added 23 focused tests (12 unit + 11 integration) across `TestCheckContextTelemetryUnit` and `TestContextTelemetryViolations` classes |
| `docs/tasks/done/validate-context-telemetry-canary-readiness.md` | Updated with implementation notes and validation evidence |

### Validation

- 85 focused tests: PASS (62 existing + 23 new)
- `canary_report.py --validate-only`: PASS
- Ruff lint: PASS
- `git diff --check`: PASS
- No evaluation or MLflow run was performed. Two delegated container-agent
  runs cost $4.6831315; no benchmark paid API call was made.
Accepted checkpoint commit: `9617d0ef`.

---

## 2026-07-25 — Reconcile Context Provenance with the Evaluation Schema

Task: `docs/tasks/done/reconcile-context-provenance-schema.md`

The evaluation runner emitted context provenance fields that were not declared
by the analyzer-assisted result schema. Added optional, versioned per-tree
`context_provenance` with serialized events and nested metrics, condition-level
telemetry provenance, exact contract-version checks, event-kind validation, and
all-or-none pairing of condition-level telemetry fields. Legacy records without
optional telemetry remain valid.

Validation: 98 focused contract tests passed in the task container, telemetry
regression tests passed, analyzer-assisted manifest validation passed, Ruff and
diff checks passed. Host JSON parsing, Python compilation, validator, and diff
checks passed; host pytest was unavailable because `.venv` has a stale
`/workspace/.venv` interpreter path. No evaluation or MLflow run was performed.
Delegated container cost: $4.6117015.
Accepted checkpoint commit: `7fa0388b`.

---

## 2026-07-25 — Reconcile Evaluation Contract Readiness Documentation

Task: `docs/tasks/done/reconcile-evaluation-contract-readiness-docs.md`

Updated the evaluation README and validation note to distinguish implemented
four-condition infrastructure from experiment-execution blockers. Corrected
the active corpus statement to 31 questions with a 40-question contract
target, documented the v1.3.0 artifacts and telemetry/canary evidence, and
preserved MLflow, root-cause classification, external-fetch OTel, and explicit
user-authorization gates. The separate open bug file was intentionally left
untouched because it is outside this task and has stale counts.

Validation: manifest and canary validation passed, authoritative corpus count
check passed, and `git diff --check` passed. Two delegated container runs cost
$2.00782825. No evaluation, MLflow run, or benchmark paid API call was made.
Accepted checkpoint commit: `ed322435`.

---

## 2026-07-25 — Reconcile Deterministic V1 Scoring Accuracy

Task: `docs/tasks/done/reconcile-v1-scoring-accuracy.md`

The deterministic scorer now strips markdown emphasis/inline-code markers
before case-insensitive matching. Added nine evidence-backed corpus variants,
source-citation regression reporting, and 28 focused tests. The current
31-question corpus and its below-40 validation status remain unchanged.

Validation: container focused tests passed; analyzer-assisted validation passed;
consumer-v1 validation retained four pre-existing count/tier errors; rescoring
produced Tree A 15/31 and Tree B 14/31 exact matches with no shared-ID exact
match regressions; `git diff --check` passed. No paid benchmark was run. The
delegated container reported cost `$5.15027225`. An unrelated note-file hunk
was rejected and reverted before acceptance. No Dockerfile change was needed.

---

## 2026-07-25 — Re-author Retired Integration Question INTG-002 (validated)

Task: `docs/tasks/done/reauthor-retired-intg-002.md`

Restored INTG-002 with a clean-tree source-backed question after source
conflicts were resolved (commit `c5c8201c`). The new question asks what
Kubernetes resources KServe's llmisvc-controller-manager creates for llm-d
integration, sourced from `architecture/rhoai.next/kserve.md` line 108 with
supporting evidence at lines 261, 307, and 375.

Corpus count after change: 32 active, 8 retired (was 31/9). Tier 3: 5 active,
5 retired (was 4/6). Contract target: 40 (8 remaining).

Changed files: `benchmark/consumer-v1/corpus.json` (INTG-002 added),
`benchmark/analyzer-assisted-v1/corpus_manifest.json` (INTG-002 retired→active,
aggregates updated), `benchmark/analyzer-assisted-v1/README.md` (31→32),
`docs/notes/analyzer-assisted-evaluation-contract.md` (31→32, 9→8),
`tests/test_corpus_manifest.py` (count assertions updated),
`tests/test_analyzer_assisted_planner.py` (31→32, INTG-002 active assertions),
`tests/test_condition_aware_runner.py` (31→32).

Validation: corpus manifest validator PASS (32 active, 8 retired), experiment
manifest validator PASS (v1.3.0, 4 available), consumer-v1 validator 4
pre-existing errors (32 < 40), 168 focused tests passed, `git diff --check`
PASS. No evaluation, agent, or paid call was run.

---

## 2026-07-25 — Resolve INTG-002 Source-Document Conflicts

Task: `docs/tasks/done/resolve-intg-002-source-conflicts.md`

Resolved the merge markers in the five architecture documents required for the
INTG-002 source audit. The hand-authored narrative remains separate from a
dedicated `Analyzer Facts (authoritative)` section in each document, preserving
the complete substantive analyzer payload, explicit Unknown values, coverage
limitations, and source provenance. INTG-002 itself remains unresolved and is
ready for a separate source-backed re-authoring task.

Validation: zero markers in all five files; architecture-document lint passed
for 845 files; required-section, analyzer-section, table-structure, and
`git diff --check` checks passed. Optional YAML and pytest checks were
infrastructure/pre-existing failures. Three delegated runs were required after
review refinement; reported costs were `$3.22636975`, `$4.45412275`, and
`$9.59780625` (total `$19.2782985`). No evaluation or Dockerfile change was
made. The first two runs were review-held and were not separately committed.

---

## 2026-07-25 — Configure Analyzer-Assisted Experiment Tracking (validated)

Task: `docs/tasks/done/configure-analyzer-assisted-experiment-tracking.md`

Added the versioned stdlib-only MLflow REST tracking adapter
(`lib/mlflow_tracking.py`) and `track_experiment.py` CLI. It supports explicit
preflight, offline dry-run, deterministic condition/provenance tags, telemetry
and context metrics, and artifact references. Missing or unreachable tracking
configuration fails explicitly; no external MLflow experiment or evaluation
was created.

Validation: 62 tracking tests and 98 existing evaluation tests passed in the
task container; experiment manifest validation passed; `git diff --check`
passed. The host lacked pytest. The adapter remains ready for external
registration once `MLFLOW_TRACKING_URI` is configured; root-cause classification,
external-fetch OTel spans, and user authorization remain separate gates.
The delegated runs cost `$4.23069125` total.

---

## 2026-07-25 — Add Failure-Classification Proposals (validated)

Task: `docs/tasks/done/add-failure-classification-proposals.md`

Added the versioned deterministic proposal generator and schema
(`lib/failure_proposals.py`, `benchmark/analyzer-assisted-v1/proposal_schema.json`).
It emits pending, non-authoritative proposals from direct infrastructure and
context telemetry signals, preserves recorded classifications as annotations,
and leaves score-only causes unresolved. Output timestamps are input-derived or
an explicit epoch sentinel, so repeated generation is reproducible.

Validation: 41 focused tests passed in the task container, manifest validation
passed, proposal schema validation passed, and `git diff --check` passed. No
evaluation or benchmark ran. Human adjudication remains required. The two
delegated runs cost `$4.5559225` total.

---

## 2026-07-25 — Add the OTel-Compatible File Export Boundary (validated)

Task: `docs/tasks/done/add-otel-file-export-boundary.md`

Added the opt-in, bounded, failure-tolerant `JsonlFileExporter` to
`lib/context_telemetry.py`. It emits versioned OTel-compatible JSONL records
with event kind, route, source fields, timestamps, and trace/span correlation;
the default remains no-op. The external `fetch-architecture-context.sh`
producer is not present in this checkout and remains an explicit end-to-end
blocker.

Validation: 86 telemetry tests passed in the task container, lint and manifest
validation passed, and `git diff --check` passed. No evaluation or benchmark
ran. The delegated run cost `$2.056406`.

---

## 2026-07-25 — Reconcile Plan Evaluation Scope

Task: `docs/tasks/done/reconcile-plan-evaluation-scope.md`

Audited every numeric corpus/baseline claim in
`docs/plans/analyzer-assisted-agent-architecture.md` and added explicit source
and verification status for each. Added a Baseline provenance table
distinguishing three categories:

- **Unverified external feedback**: 94-question / 84% (79/94) retrieval
  baseline and per-category scores (CRD/API 50%, deployment 60%, ownership
  62.5%) — no repository artifact exists; preserved in `corpus_manifest.json`
  as `plan_claim_94q` with `verification_status: "unverified"`.
- **Verified repository artifacts**: 32 active / 8 retired / 40 total corpus
  questions (manifest v1.1.0), v1-ab evaluation (40 questions scored),
  consumer-v1 corpus (32 questions), 40-question contract target
  (`schema.json` `minItems`).
- **Stale design-time claim**: 63/90 analyzer component coverage (architecture
  tree now has 27 versions and 100+ unique components).

Updated the implementation sequence (Steps 1 and 5) and success criteria to
reference the canonical corpus and v1-ab baseline rather than the unverified
94-question figure. Added explicit external-input gate table for Step 5
execution (MLflow, root-cause classification, OTel, corpus minimum,
authorization).

Reconciled stale counts in:
- `docs/notes/analyzer-assisted-corpus-baseline.md` (31→32 active, 9→8
  retired, gap accounting updated)
- `docs/bugs/open/corpus-v1-below-minimum-question-count.md` (29→32
  questions, 11→8 gaps, restored question IDs documented)

Files modified: `docs/plans/analyzer-assisted-agent-architecture.md`,
`docs/notes/analyzer-assisted-corpus-baseline.md`,
`docs/bugs/open/corpus-v1-below-minimum-question-count.md`,
`docs/notes/session-log.md`. No corpus, results, code, or generated
architecture output was modified. No evaluation or benchmark was run.

---

## 2026-07-25 — Restore Source-Backed INTG-004

Delegated re-authoring of retired `INTG-004` to the container agent. The
clean-tree `llm-d-inference-scheduler.md` Flow 1 table supports the five-hop
request-routing answer at lines 370–374, so the question was restored with
exact source evidence. The corpus is now 33 active / 7 retired, with seven
remaining questions below the 40-question contract minimum. Manifest
validation passed; the consumer validator continues to report the expected
minimum-count shortfall. No evaluation or benchmark was run.

Accepted and committed as `758c800d`. An unrequested MLflow task emitted by
the delegated agent was removed. Existing unrelated worktree changes were
preserved unstaged.

---

## 2026-07-25 — Validate Local MLflow Tracking

Delegated validation of the local file-backed MLflow backend after
`mlflow==2.22.0` became available in the task image. Preflight and dry-run
verified no unwanted writes; one bounded live run was read back successfully
with experiment identity, `FINISHED` status, 9 tags, 12 metrics, and 4 artifact
references. Write confinement held under `/tmp/mlflow-validate-live`.

The focused tracking suite passed 94 tests and the analyzer manifest validator
passed. Readiness documentation now marks local tracking validated while
keeping external server registration and paid/full-corpus evaluation pending.

---

## 2026-07-25 — Reconcile Plan State After Local MLflow Validation

Updated the architecture plan's stale corpus and gate claims to match the
accepted repository state: 33 active / 7 retired / 40 total, Tier 3 at 6,
Tier 4 at 7, and seven explicit missing IDs. The plan now records local
MLflow tracking as validated while preserving external server registration,
human adjudication, external-fetch OTel, corpus-minimum, and authorization
gates. Historical 94-question/84% claims remain explicitly unverified.

Architecture-doc lint, plan link verification, and `git diff --check` passed;
no evaluation or benchmark was run.

---

## 2026-07-25 — Restore Source-Backed INTG-010

Re-authored retired `INTG-010` against the clean serving-stack paragraph at
`architecture/rhoai.next/PLATFORM.md:353`. The original ModelMesh archive and
deprecation claims were not restored; the new question asks about the three
documented serving paths and ModelMesh's role. Manifest validation and 70
focused corpus tests passed. The corpus is now 34 active / 6 retired, with six
remaining gaps. No evaluation or benchmark was run.

---

## 2026-07-25 — Restore Source-Backed NAV-010

Re-authored retired `NAV-010` as a narrow clean-tree question about the
platform's name for Llama Stack, backed by
`architecture/rhoai.next/PLATFORM.md:101` (`OGX (Llama Stack)`). Overlay-only
rename details were excluded. After two focused count-audit refinements, the
corpus and all count-sensitive notes are consistent at 35 active / 5 retired /
40 total, with five remaining gaps. Manifest/planner tests passed (140 total).
No evaluation or benchmark was run.

---

## 2026-07-25 — Restore Source-Backed INTG-003

Re-authored retired `INTG-003` as a narrow question about the infrastructure
`odh-model-controller` creates while watching KServe CRs, backed by clean
`architecture/rhoai.next/PLATFORM.md:121`. The overlay-precedence question was
not restored. After count-document reconciliation, the corpus is 37 active / 3
retired / 40 total, with remaining gaps INTG-006, NAV-003, and NAV-006. Focused
planner, runner, and manifest tests passed (169 total). No evaluation or
benchmark was run.

---

## 2026-07-25 — Restore Source-Backed INTG-008 Training Flow

Re-authored retired `INTG-008` as a narrow distributed-training workflow
question backed by clean `architecture/rhoai.next/PLATFORM.md:246-249`.
Conflicted `fms-hf-tuning.md`/`training-hub.md` sources and overlays were
excluded. After a count-document refinement, the corpus is consistent at 36
active / 4 retired / 40 total, with remaining gaps INTG-003, INTG-006, NAV-003,
and NAV-006. Manifest validation and focused tests passed. No evaluation or
benchmark was run.

---

## 2026-07-25 — Restore Source-Backed INTG-006

Re-authored retired `INTG-006` as a narrow question about how `rhods-operator`
manages the lifecycle of platform operators and services, backed by clean
`architecture/rhoai.next/PLATFORM.md:119`. The original overlay-only external
operator policy claim was excluded. After count-document reconciliation, the
corpus is consistent at 38 active / 2 retired / 40 total, with remaining gaps
NAV-003 and NAV-006. Manifest validation and focused tests passed. No
evaluation or benchmark was run.

---

## 2026-07-25 — Restore Source-Backed NAV-003 Dependency Graph (reconciliation)

Re-authored retired `NAV-003` as a dependency-graph navigation question backed
by clean `architecture/rhoai.next/PLATFORM.md:22` (Component Relationships) and
`:24` (Dependency Graph). Reconciled all count-sensitive documents to 39 active /
1 retired / 40 total, Tier 4=9, remaining gap NAV-006 only. Updated baseline
note answerability counts (answerable 36→37, undetermined 2→1) and gap-to-plan
table (active 38→39, retired 2→1, missing 56→55). Updated PLAN.md NAV-003 entry.
Moved task from `current/` to `done/`. Manifest validation and focused tests
passed. No evaluation or benchmark was run.

---

## 2026-07-25 — Restore Source-Backed NAV-006 Deployment Topology

Re-authored retired `NAV-006` as a deployment-topology navigation question backed
by clean `architecture/rhoai.next/PLATFORM.md:253` (Deployment Architecture) and
`:255` (Deployment Topology). Also corrected NAV-003 bookkeeping: fixed plan's
"2 retired" → "1 retired" at two locations, bug report error count "2" → "3",
and bug report question count "38" → "39". Reconciled all count-sensitive
documents to 40 active / 0 retired / 40 total, Tier 4=10, no remaining gaps.
Updated plan baseline provenance (40 active, corpus gate resolved), evaluation
contract (gap resolved to 0 errors), baseline note (40 active, answerable 38,
undetermined 0), and PLAN.md. Tests updated: corpus manifest (40 active, 0
retired, 40 consumer-v1), planner (40 questions, NAV-006 active), runner
(40 questions, no retired ID test). Consumer-v1 corpus now passes its own
schema validation. No evaluation or benchmark was run.

---

## 2026-07-25 — Improve Corpus V1 Scoring Accuracy (Phase 1)

Implemented Phase 1 scoring accuracy improvements. Retargeted INV-002 and
INV-007 as `not_documented_expected: true` since their source evidence
(`docs/notes/analyzer-migration-v1-baseline-2026-07-20.md`) is outside the
architecture evaluation scope. Updated corpus, manifest (answerability
answerable 38→36, answerable-as-gap 2→4), baseline note, and tests.
Case-insensitive matching and source-citation regression detection were
already implemented. Offline re-scoring v1-ab raw results with updated corpus:
exact match A=42.5%/B=40.0% (up from 15%), composite A=0.55/B=0.5375.
No regressions on the original 6 passing questions. Added 5 regression tests
for retargeted gap questions (TestRetargetedGapQuestions). Updated bug status
for both scoring bugs. Phase 2 (LLM-as-judge) deferred. Full composite-score
improvement for re-authored questions requires an authorized rerun.
No evaluation or benchmark was run.

---

## 2026-07-25 — Refine LLM-as-Judge Contract (rationale required)

Task: `docs/tasks/done/add-llm-judge-scoring-dimension.md`

Made `rationale` a required non-empty per-judgment field in both the JSON
schema and Python validator, for semantic judgments and abstentions alike.
Updated test helper to produce abstention rationale. Added 6 new tests:
`test_abstention_requires_rationale`, `test_missing_rationale_fails`,
`test_empty_rationale_fails`, `test_null_rationale_fails`,
`test_null_rationale_on_abstention_fails`, and
`test_schema_requires_rationale_non_empty`. Total: 65 tests (up from 59).

Changed files: `benchmark/consumer-v1/judge_result_schema.json` (rationale
added to required, type changed from `["string", "null"]` to `"string"` with
`minLength: 1`), `benchmark/consumer-v1/validate_judge_result.py` (rationale
presence and non-empty check), `tests/test_llm_judge_contract.py` (6 new tests,
helper updated for abstention rationale).

Validation: 65 judge contract tests PASS, 201 scorer/corpus/planner/runner
tests PASS, consumer-v1 validator PASS (40 questions), corpus manifest
validator PASS (40 active, 0 retired), `git diff --check` PASS.
No model called. No evaluation or benchmark ran.

---

## 2026-07-25 — Prepare Semantic-Judge Calibration Set Template

Task: `docs/tasks/done/prepare-judge-calibration-set-template.md`

Created a versioned 24-question stratified calibration template (v0.1.0) for
human semantic-match labeling. Selection algorithm: include all 4
answerable-as-gap questions (INV-002, INV-006, INV-007, FACT-008), then fill
each tier to 6 with the first answerable questions by ID order. All
`human_label` values are null — no labels were inferred or invented.

Changed files: `benchmark/consumer-v1/calibration_template.json` (24-question
template), `benchmark/consumer-v1/calibration_schema.json` (JSON Schema
2020-12), `benchmark/consumer-v1/validate_calibration.py` (deterministic
validator with corpus cross-check), `tests/test_calibration_template.py` (49
tests covering selection validity, corpus membership, null labels, deterministic
ordering, schema compliance, and 14 validator negative cases).

Validation: calibration validator PASS (24 questions, corpus cross-check),
49 calibration tests PASS, consumer-v1 validator PASS (40 questions),
corpus manifest validator PASS (40 active, 0 retired), `git diff --check` PASS.
No model called. No labels inferred. No evaluation or benchmark ran. Human
labeling and user authorization remain external gates.

### Reconcile Behavioral Contract Audit Evidence — 2026-07-25

Task: `docs/tasks/done/reconcile-behavioral-contract-audit.md`

Reconciled the completed Step 2–4 audit after commit `9f931a8b` added the five
missing Phase 1 behavioral-evidence contract fields. Updated items 2.15–2.19
from "Locally blocked" to "Implemented" with exact field, schema, renderer,
and test citations:

- 2.15 Image/build status → `ImageBuildStatus []string` (`contract.go:196`)
- 2.16 Configuration/RBAC → `ConfigurationRBAC []string` (`contract.go:193`)
- 2.17 Architecture/provider matrices → `ArchProviderMatrices []string` (`contract.go:194`)
- 2.18 Observable outcomes → `ObservableOutcomes []string` (`contract.go:195`)
- 2.19 Delivery-independence → `ContractComponentClassification` (`contract.go:85,200-206`)

Step 2 summary updated from 14/19 to 19/19 implemented. All five fields are
optional with explicit validation states; unsupported values remain
unpopulated/not-extracted. External gates (MLflow server, human calibration
labels, human failure adjudication, LLM-judge authorization, external-fetch
OTel producer, and user authorization) remain explicitly incomplete and
unchanged.

Changed files: `docs/tasks/done/audit-local-plan-implementation-gaps.md`,
`PLAN.md`, `docs/notes/session-log.md`,
`docs/tasks/done/reconcile-behavioral-contract-audit.md` (moved from
`current/`). No code, schema, corpus/results, or generated output modified.
No evaluation or benchmark was run. Estimated cost: $0.00.

### Refinement: plan Step 2 annotation (2026-07-25)

The first pass omitted the required change to
`docs/plans/analyzer-assisted-agent-architecture.md`. Added Step 2
implementation annotation recording 19/19 sub-requirements implemented,
with behavioral-evidence fields (image/build status, configuration/RBAC,
architecture/provider matrices, observable outcomes, delivery-independence)
from commit `9f931a8b` listed as optional with unsupported values remaining
unpopulated/not-extracted. Cross-referenced the audit file. Updated the
task's Changes table and PLAN.md entry. All listed external gates (MLflow
server, human calibration labels, human failure adjudication, LLM-judge
authorization, external-fetch OTel producer, and user authorization) remain
explicitly incomplete and unchanged. Task moved from
`current/` to `done/`.

Changed files: `docs/plans/analyzer-assisted-agent-architecture.md`,
`docs/tasks/done/reconcile-behavioral-contract-audit.md` (moved from
`current/`), `PLAN.md`, `docs/notes/session-log.md`. No code, schema,
corpus/results, or generated output modified. No evaluation or benchmark
was run. Estimated cost: $0.00.

---

### Extend Behavioral Evidence Contract Fields — 2026-07-25

Implemented the five missing Phase 1 context-contract fields identified by the
Step 2 audit (items 2.15–2.19). Added four new `[]string` fields to
`ContractBehavioralEvidence` (`configuration_rbac`, `arch_provider_matrices`,
`observable_outcomes`, `image_build_status`) and a new top-level
`ContractComponentClassification` struct on `ContextContract` (`role`,
`delivery_independence`, `validation`). Updated JSON Schema with matching
definitions, renderer with labeled Markdown output, and normalizer pass-through.

Added 10 new focused tests: 4 model round-trip/omit tests, 5 renderer tests
(populated, not-extracted, nil, empty-field omission), 1 normalize pass-through
test. Extended 3 existing tests (round-trip, explicit-unknowns, omits-empty)
with new field assertions.

Changed files: `contract.go` (model), `component-architecture.schema.json`,
`contract.go` (renderer), `contract_test.go` (model), `contract_test.go`
(renderer), `normalize_test.go`.

Validation: 28 focused contract tests PASS, all arch-analyzer `go test ./...`
PASS (13 packages), all arch-query tests PASS (5 packages), `gofmt -d` clean,
and `git diff --check` PASS. No application model, paid benchmark, or
evaluation call was made. No generated output modified. Backward
compatibility preserved. Delegated implementation-agent cost:
$2.62606025.

---

## 2026-07-25 — Fix MLflow REST Experiment Search

Task: `docs/tasks/done/fix-mlflow-rest-experiment-search.md`
Bug: `docs/bugs/open/mlflow-rest-experiment-search-max-results.md`

Fixed `MLflowRESTClient.get_or_create_experiment()` which omitted
`max_results` from the experiments/search POST body, causing MLflow 2.22.0
to reject with HTTP 400 (`INVALID_PARAMETER_VALUE: Invalid value 0`).

### Fix

Added `"max_results": 10` to the search body in `get_or_create_experiment()`
(`lib/mlflow_tracking.py:266`). This matches the pattern already used by
`ping()` which sends `max_results: 1`.

### Regression Test

Added `test_experiment_search_includes_positive_max_results` to
`TestMockMLflowServer` in `tests/test_mlflow_tracking.py`. Asserts the
experiments/search request body contains `max_results` as a positive integer.

### End-to-End REST Validation

Ephemeral MLflow 2.22.0 server (SQLite backend, port 5556,
`--default-artifact-root`, `--no-serve-artifacts`):

- **Preflight**: configured=true, reachable=true, errors=[]
- **track_result()**: success=true, experiment_id=1,
  run_id=675326ce5ae148e0aedc9a37d13d19ca, run_name=baseline/INV-001
- **Tags**: 16 custom tags logged (tracking_contract_version, experiment_id,
  condition_id, question_id, model, runner_version, timestamp,
  question_category, question_difficulty, question_scope, schema_version,
  seed, 3 provenance tags, artifact_ref.0)
- **Metrics**: 12 metrics logged (response.success, 6 telemetry, 2
  tool_calls, 4 context_metrics) — all exact values
- **Termination**: FINISHED
- **Read-back**: 17 tags (16 custom + mlflow.runName), 12 metrics, status
  FINISHED, lifecycle_stage=active — all values exact match
- **Cleanup**: server killed, /tmp/mlflow-rest-e2e-validate/ removed,
  directory verified absent

### Validators

- `python3 -m pytest tests/test_mlflow_tracking.py -v`: **95 passed**
  (94 existing + 1 new regression test)
- `python3 benchmark/analyzer-assisted-v1/validate.py`: **PASS** (v1.3.0,
  4 conditions available)
- `git diff --check`: **PASS**

### Cost

Application/evaluation cost: $0.00. No models run, no paid evaluation,
no external state created. Launcher-reported delegated-agent cost:
$3.213281.

### Changed Files

- `lib/mlflow_tracking.py` (one-line fix: added `max_results: 10`)
- `tests/test_mlflow_tracking.py` (regression test added)
- `docs/tasks/done/fix-mlflow-rest-experiment-search.md` (evidence)
- `docs/bugs/open/mlflow-rest-experiment-search-max-results.md` (status)
- `benchmark/analyzer-assisted-v1/README.md` (REST status, bug note)
- `docs/notes/analyzer-assisted-evaluation-contract.md` (MLflow status)
- `PLAN.md` (active tasks, bug reference)
- `docs/notes/session-log.md` (this entry)

---

## Session: 2026-07-26 — Provisional 32-Session Pilot Execution

### Summary

Executed the authorized 32-session pilot: 4 questions (INV-001, FACT-001, INTG-001, NAV-001) × 4 conditions (baseline, index-md, arch-query, combined) × 2 trees (rhoai.next.bak, rhoai.next), model opus, max 4 concurrent sessions.

### Results

- **32/32 sessions completed**, 0 failures
- **Cost**: $8.11 total ($3.21 baseline, $1.44 index-md, $1.96 arch-query, $1.50 combined)
- **Wall time**: 348 seconds (5.8 minutes)
- **Guards**: Neither cost ($25) nor time (30min) guards reached
- **Scores**: baseline 0.375/0.375, index-md 0.500/0.375, arch-query 0.375/0.375, combined 0.375/0.375 (tree_a/tree_b)
- **MLflow**: 32 runs tracked locally, experiment `analyzer-assisted-provisional-32-session-pilot`, read-back verified
- **Tokens**: 237 input + 863,902 cache_creation + 3,665,047 cache_read + 32,063 output

### Observations

- index-md condition showed marginally higher tree_a score (0.500 vs 0.375) — likely better navigation guidance from INDEX.md
- baseline condition was most expensive ($3.21) despite identical tool access, likely due to more exploratory reads
- All conditions achieved 0.0 exact_match_rate on tree_b but higher source_citation_rate (0.75), suggesting agents found relevant files but scoring is strict on exact-match phrasing
- MLflow 3.14 requires `MLFLOW_ALLOW_FILE_STORE=true` for filesystem-backed tracking

### Artifacts

All under `tmp/provisional-pilot/results/`; hashes in `pilot-summary.json`.

### Changed Files

- `docs/tasks/done/run-authorized-provisional-32-session-pilot.md` (execution record)
- `docs/plans/analyzer-assisted-agent-architecture.md` (bounded pilot evidence
  added; full-corpus and human-data gates remain)

Accepted checkpoint: `7bb0f757`.
- `docs/notes/session-log.md` (this entry)
