# Task: Add LLM-as-Judge Scoring Dimension

## Goal

Extend the consumer-v1 scorer with an optional semantic-equivalence dimension
that runs alongside deterministic exact-match, citation, and gap checks.

## Preconditions and authorization

- Do not start implementation or model calls until the user authorizes the
  expected model, question count, estimated cost, and duration.
- Prepare an offline fixture/protocol first; no paid or full-corpus evaluation
  is part of task setup.

## Scope

- Define a versioned judge-result schema with prompt/model provenance,
  per-question classification, confidence, rationale, and explicit abstention.
- Keep deterministic scores unchanged and make the judge opt-in.
- Add tests for semantic match, mismatch, abstention, malformed output, and
  disagreement with deterministic checks.
- Define a manually classified calibration set and an acceptance calculation
  for the 90% agreement target before running it.

## Non-goals

- Do not replace exact-match scoring or modify existing raw/scored artifacts.
- Do not claim the 90% target without an authorized run and human-labeled
  reference set.

## Result

**Contract/protocol implemented** — schema v0.1.0, validator, and 65 offline tests.

### Deliverables

| File | Purpose |
|------|---------|
| `benchmark/consumer-v1/judge_result_schema.json` | JSON Schema 2020-12 for LLM-as-judge results (v0.1.0) |
| `benchmark/consumer-v1/validate_judge_result.py` | Deterministic validator for judge results (no model calls) |
| `tests/test_llm_judge_contract.py` | 59 tests covering all acceptance criteria |

### Schema version

`0.1.0` — contract/protocol only. The schema defines per-question judgments
with semantic_match, confidence, rationale (required non-empty for both
semantic judgments and abstentions), abstention, deterministic_match
carry-through, disagreement detection, and calibration-set accounting.

### Test coverage

| Category | Tests | Evidence |
|----------|-------|----------|
| Semantic match | 3 | Valid match fixture, high confidence, human label agreement |
| Semantic mismatch | 2 | Valid mismatch fixture, low confidence |
| Abstention | 5 | Null fields, not counted as match/mismatch, rejects non-null semantic_match/confidence, requires rationale |
| Malformed output | 18 | Missing fields, empty strings, out-of-range values, type errors, summary mismatches, missing/empty/null rationale, null rationale on abstention |
| Disagreement | 6 | Both directions, both agreements, wrong flag rejection |
| Provenance | 3 | Model provenance, authorization fields, corpus version |
| Calibration-set accounting | 7 | Full/partial agreement, no labels, count mismatch, exceeded count, wrong rate, non-null with zero |
| Acceptance calculation | 5 | Exactly 90% passes, 89% fails, threshold constant, wrong flag, wrong threshold |
| Schema file validation | 5 | File loads, version matches, authorization required, abstention defined, rationale required non-empty |
| Deterministic preservation | 2 | Read-only deterministic_match, no alteration |
| Integration (mixed) | 2 | Mixed judgments, empty requires authorization |
| Authorization gate | 3 | Required fields, offline fixture, zero cost |

### Authorization fields for future execution

The schema and validator require these fields before any judge run:

| Field | Type | Purpose |
|-------|------|---------|
| `authorized_by` | string | Who authorized this judge run |
| `authorized_question_count` | integer >= 1 | Number of questions authorized |
| `estimated_cost_usd` | number >= 0 | Estimated cost before execution |
| `estimated_duration_seconds` | number >= 0 | Estimated wall-clock duration |
| `calibration_set_path` | string | Path to human-labeled calibration set |

### Blocked future execution gate

Judge execution is blocked until:

1. A human-labeled calibration set exists (minimum coverage TBD).
2. The user authorizes: model/version, question count, estimated cost, and duration.
3. The 90% agreement threshold is met on the calibration set.

No model was called. No paid or full-corpus evaluation was run. No agreement
was claimed. No production dependencies were modified.

## Status

Done — 2026-07-25 (contract/protocol only; execution blocked on authorization).
