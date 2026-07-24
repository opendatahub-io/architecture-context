# Analyzer-Assisted Evaluation Contract — Validation Note

**Date**: 2026-07-24
**Task**: `docs/tasks/done/define-analyzer-assisted-evaluation-contract.md`
**Status**: Complete

## What was defined

The evaluation contract for the four-condition analyzer-assisted experiment,
as specified in `docs/plans/analyzer-assisted-agent-architecture.md` Step 1.

### Deliverables

1. **Experiment manifest** (`benchmark/analyzer-assisted-v1/experiment.json`):
   defines four conditions (baseline, index-md, arch-query, combined) with
   stable IDs, access boundaries, artifact identity requirements, and
   explicit unavailable-condition handling for the three pending conditions.

2. **Result schema** (`benchmark/analyzer-assisted-v1/result_schema.json`):
   extends the v1 result format with condition identity, artifact provenance,
   question metadata (category, difficulty, scope), telemetry, context fetch
   metrics, and failure classification vocabulary.

3. **Validation module** (`benchmark/analyzer-assisted-v1/validate.py`):
   deterministic validation for manifest and result records. Rejects unknown
   condition IDs, missing provenance, invalid failure classifications,
   negative telemetry, and unavailable conditions claiming success.

4. **Focused tests** (`tests/test_analyzer_assisted_evaluation.py`):
   52 tests covering manifest validation, result validation, all four
   conditions, unavailable condition fixtures, classified failure fixtures,
   v1 compatibility, and constant consistency.

### Design decisions

- The new evaluation infrastructure lives in `benchmark/analyzer-assisted-v1/`
  alongside the existing `benchmark/consumer-v1/` harness, preserving the v1
  harness untouched.
- Unavailable conditions are explicitly represented with `available: false`,
  `status: "pending"`, and `unavailable_reason` — they cannot silently fall
  back to baseline.
- Six failure classifications are defined: `stale-context`, `missing-context`,
  `retrieval-failure`, `unsupported-inference`, `scoring-defect`, and
  `infrastructure-failure`.
- Context metrics (useful reads, navigation reads, queries issued) default to
  null until OTel instrumentation is wired.
- The result schema requires provenance (architecture SHA, corpus version,
  manifest version) for every result.

## What was NOT done (handoff boundary)

The following are explicitly deferred to follow-on tasks:

| Concern | When | Dependency |
|---------|------|------------|
| Adapt `run_evaluation.py` to execute multiple conditions | After at least one non-baseline condition is available | INDEX.md or arch-query implementation |
| Generate INDEX.md | Phase 2 of the architecture plan | Context index design and correction feedback loop |
| Implement arch-query queries | Phase 3 of the architecture plan | Query interface design |
| Wire OTel spans for context reads/queries | After query interface exists | OTel SDK integration |
| Run a full-corpus paid evaluation | After conditions are available and runner is adapted | All of the above |
| Populate context metrics from OTel spans | After OTel instrumentation | OTel span exporter |

## Validation results

- Experiment manifest: all four conditions, six failure classifications,
  no validation errors.
- Existing v1 corpus, schema, raw results, and scored results: untouched
  and still parseable.
- No paid or full-corpus evaluation was run.
- No artifacts, metrics, or scores were fabricated.

### Known gap: corpus below minimum question count

The v1 corpus currently contains 29 questions (Tier 1: 8, Tier 2: 10,
Tier 3: 4, Tier 4: 7). The v1 schema requires `minItems: 40` and
`validate.py` requires exactly 10 per tier. Running
`python3 benchmark/consumer-v1/validate.py` reports 5 errors.

This is a pre-existing condition — the 11 missing questions were removed
during ground-truth auditing after the v1-ab evaluation run. The schema
and validator intentionally preserve the 40-question / 10-per-tier
contract; the corpus will pass validation once the missing questions are
authored against verified evidence.

See: `docs/bugs/open/corpus-v1-below-minimum-question-count.md`
