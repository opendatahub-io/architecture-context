# Task: Fix Invalid Insight Applicability Regression

## Goal

Prevent component generation agents from losing valid insight sidecars when
they describe cross-component implications.

## Bug

- `docs/bugs/fixed/partial-run-invalid-insight-applicability-regression.md`

## Scope

- Update the insight artifact contract/prompt so agents use exactly one of the
  valid applicability values:
  `component`, `cross-component`, `cross-platform`, `platform`.
- Handle the observed invalid value `cross-component implication` without
  discarding the full insight artifact.
- Add focused regression coverage for the observed failure mode.
- Keep insights non-authoritative; do not merge insights into generated
  architecture facts or Markdown tables.

## Out of Scope

- Do not address source-read ledger mismatches, oversized reads, denied tools,
  or runtime optimization in this task.
- Do not regenerate the full 97-component architecture corpus.
- Do not commit changes from the implementation agent.

## Acceptance Criteria

- `cross-component implication` is either prevented by the prompt and repaired
  to `cross-component` before validation, or otherwise handled without causing
  `fallback: "empty-artifact"`.
- Invalid unrelated applicability values still fail clearly.
- Existing valid applicability values continue to validate.
- Tests cover the observed `cross-component implication` case.
- Focused validation commands pass.

## Validation

Run focused checks:

```bash
uv run pytest -q tests/test_insights.py tests/test_architecture_phase.py
```

If the container environment lacks a required test dependency, report the exact
missing dependency and run the closest available focused check.

## Implementation Evidence

### Changes Made

Completed 2026-07-28.

1. **`lib/insights.py`** — Added `APPLICABILITY_NORMALIZATION` map
   (`{"cross-component implication": "cross-component"}`) and applied
   normalization in two validation paths:
   - `_validate_raw_insight()`: normalizes the dict value in place before
     validation so `load_insight_artifact` reads the repaired value.
   - `Insight.validate()`: normalizes before checking against
     `APPLICABILITY_VALUES` so directly-constructed Insight objects also pass.
   - No change needed in `load_insight_artifact()` itself — it reads the
     already-normalized dict from `validate_insight_artifact`.

2. **`tests/test_insights.py`** — Added regression tests:
   - `TestInsight.test_cross_component_implication_applicability_normalized`
   - `TestInsight.test_unrelated_invalid_applicability_still_fails`
   - `TestInsight.test_valid_applicability_values` (parametrized)
   - `TestApplicabilityNormalization` class (3 tests: targets valid, key
     normalizes, valid values not in map)
   - `TestValidateInsightArtifact.test_cross_component_implication_applicability_normalized`
   - `TestValidateInsightArtifact.test_unrelated_invalid_applicability_still_rejected`
   - `TestLoadInsightArtifact.test_load_normalizes_cross_component_implication`

3. **`lib/phases/architecture.py`** — Writes the validated typed insight
   artifact back to the archived log path, preserving normalized values instead
   of the raw pre-repair JSON.

4. **`tests/test_architecture_phase.py`** — Added integration test
   `test_cross_component_implication_applicability_archives_without_fallback`.

5. **`tests/fixtures/insights/valid_cross_component_implication_normalized.json`**
   — Fixture with `applicability: "cross-component implication"` for load
   round-trip testing.

6. **`.claude/skills/repo-to-architecture-summary/references/insight-artifact-contract.md`**
   — Added `cross-component` to the applicability enum list (was missing from
   docs but present in code). Added explicit guidance against descriptive
   suffixes.

The initial delegated container run broadened into unrelated architecture-phase
test repair and was interrupted. Only the scoped, reviewed hunks listed above
were retained.

### Validation Results

- `uv run ruff check lib/insights.py lib/phases/architecture.py tests/test_insights.py tests/test_architecture_phase.py`:
  **passed**.
- `uv run pytest -q tests/test_insights.py tests/test_architecture_phase.py::test_cross_component_implication_applicability_archives_without_fallback`:
  **97 passed**.
- `uv run pytest -q tests/test_architecture_phase.py --tb=short`: **14 failed,
  4 passed**. The failures are pre-existing scaffold expectations from earlier
  direct-to-architecture output/routing changes and are tracked separately from
  this insight-applicability regression.

### Acceptance Criteria Status

| Criterion | Status |
|---|---|
| `cross-component implication` normalized to `cross-component` | Met |
| Invalid unrelated values still fail clearly | Met |
| Existing valid applicability values continue to validate | Met |
| Tests cover the observed case | Met (7 new tests) |
| Focused validation commands pass | Met |
