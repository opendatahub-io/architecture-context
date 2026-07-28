# Task: Fix Source-Read Ledger Mismatch Diagnostics

## Goal

Make source-read justification validation reliable enough for analyzer-gap
mining by normalizing ledger/telemetry paths, repairing safe malformed records,
and categorizing remaining warnings.

## Bug

- `docs/bugs/fixed/source-read-justification-ledger-mismatches.md`

## Scope

- Normalize source-read telemetry paths and ledger paths before comparison.
- Match absolute telemetry paths to checkout-relative ledger paths by suffix
  when the validator does not know the checkout root.
- Repair missing or malformed `sections` fields to an empty array before final
  validation output.
- Repair legacy string `gap_category` values to arrays.
- Preserve warning-only behavior but add structured diagnostics with category
  and owner for remaining mismatches.
- Add focused tests for missing observed paths, extra ledger paths, malformed
  records, repaired records, and path normalization.

## Execution record

- Added lexical path normalization for observed telemetry and ledger records.
- Added suffix matching so `/data/checkouts/<repo>/pkg/server.go` matches
  ledger path `pkg/server.go`.
- Added `repairs` and `diagnostics` fields to validator results.
- Missing or non-array `sections` now repairs to `[]` and rewrites the sidecar.
- Legacy string `gap_category` values now repair to arrays before validation.
- Structurally invalid records no longer count as justified coverage for a
  telemetry read.
- Remaining warnings are categorized, for example:
  - `missing-justification`
  - `unobserved-ledger-path`
  - `oversized-read-missing-scope-reason`
  - `malformed-record`

## Validation

```bash
uv run ruff check lib/source_read_justifications.py tests/test_source_read_justifications.py
uv run pytest -q tests/test_source_read_justifications.py
uv run pytest -q tests/test_architecture_phase.py
uv run pytest -q tests/test_source_read_justifications.py tests/test_architecture_phase.py
```

Results:

- `tests/test_source_read_justifications.py`: `6 passed`
- `tests/test_architecture_phase.py`: `18 passed`
- combined focused suite: `24 passed`

A focused replay over the existing 97 `logs/generate-architecture/*.run.json`
reports and current `.generation/SOURCE_READ_JUSTIFICATIONS.json` sidecars
checked 97 components. Sixteen still had warning conditions, but each remaining
condition had an explicit diagnostic category and owner. The previous malformed
missing-`sections` warnings were repaired rather than emitted as generic
mismatch warnings.

## Status

Completed 2026-07-28.
