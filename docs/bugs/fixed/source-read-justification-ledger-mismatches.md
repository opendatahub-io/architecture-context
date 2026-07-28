# Bug: Source-Read Justification Ledger Has Telemetry Mismatches

## Summary

The latest 97-component `rhoai.next` generation run completed, but the
source-read justification ledger reported 23 warnings. The warnings show that
the ledger and observed telemetry still disagree in several cases.

## Evidence

The run reports under `logs/generate-architecture/*.run.json` recorded:

- 10 components with observed source files lacking matching justifications.
- 7 components with ledger paths not observed by telemetry.
- `ai4rag` emitted malformed justification records missing `sections`.
- `kube-rbac-proxy` and `model-metadata-collection` emitted oversized ranges
  without `scope_reason`.

Representative component warnings:

| Component | Warning |
|---|---|
| `caikit` | observed source file lacks justification |
| `data-science-pipelines` | observed source file lacks justification |
| `kube-auth-proxy` | observed source file lacks justification; ledger path not observed |
| `llm-d-batch-gateway-operator` | observed source file lacks justification; ledger path not observed |
| `ogx-distribution` | two observed source files lack justification |
| `text-generation-inference` | two observed source files lack justification |
| `workbenches` | observed source file lacks justification; ledger path not observed |

## Expected

Every source file read by an agent should have a structured justification
record, and every justification record should correspond to an observed
telemetry read. Required fields such as `sections` should be present and
well-typed.

## Actual

Some source reads are not justified, some justified paths were not observed,
and at least one component emitted malformed ledger records.

## Impact

Medium. The current warning-only contract keeps generation moving, but the
ledger cannot yet be treated as clean measurement evidence for source-read
reduction or analyzer gap mining.

## Acceptance Criteria

- The source-read ledger schema rejects or repairs missing `sections` before
  writing final sidecars.
- Path normalization handles telemetry paths and ledger paths consistently.
- Focused tests cover missing observed paths, extra ledger paths, and malformed
  records.
- A full or focused replay has zero ledger/telemetry mismatch warnings, or each
  remaining mismatch has an explicit diagnostic category and owner.

## Status

Fixed on 2026-07-28 by
`docs/tasks/done/fix-source-read-ledger-mismatch-diagnostics.md`.

The validator now repairs missing/non-array `sections`, repairs legacy string
`gap_category`, normalizes paths before comparison, and emits structured
diagnostics with category and owner for remaining warnings.

Focused validation passed:

```bash
uv run ruff check lib/source_read_justifications.py tests/test_source_read_justifications.py
uv run pytest -q tests/test_source_read_justifications.py
uv run pytest -q tests/test_architecture_phase.py
uv run pytest -q tests/test_source_read_justifications.py tests/test_architecture_phase.py
```

Focused replay over 97 existing run reports still found real agent-side warning
conditions in 16 components, but each remaining condition is categorized
(`missing-justification`, `unobserved-ledger-path`, or
`oversized-read-missing-scope-reason`) and owner-attributed.
