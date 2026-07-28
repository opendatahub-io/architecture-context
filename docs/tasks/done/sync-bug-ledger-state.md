# Task: Sync Bug Ledger State

## Goal

Make the bug directories and `PLAN.md` Open Bugs section reflect the current
state of known bugs.

## Scope

- Move internally fixed bugs out of `docs/bugs/open/`.
- Keep genuinely open or partially remediated bugs in `docs/bugs/open/`.
- Update stale references to moved bug files.
- Record the reconciliation in the session log.

## Execution record

- Moved `partial-run-insight-artifact-validation.md` to `docs/bugs/fixed/`.
- Moved `report-generator-misses-source-citation-regressions.md` to
  `docs/bugs/fixed/`.
- Left these bugs open:
  - `corpus-v1-exact-match-variants-too-strict.md`
  - `corpus-v1-meta-questions-outside-architecture-tree.md`
  - `partial-route-component-runtime-remains-high.md`
- Updated `PLAN.md` so its Open Bugs section matches `docs/bugs/open/`.
- Updated references that pointed at the moved report-generator bug path.

## Validation

```bash
find docs/bugs/open -maxdepth 1 -type f -name '*.md' -printf '%f\n' | sort
rg -n "docs/bugs/open/(partial-run-insight-artifact-validation|report-generator-misses-source-citation-regressions)\\.md" PLAN.md docs
```

Expected result: the open directory contains the three open bugs listed above,
and no stale references point to the moved fixed bug paths.

## Status

Completed 2026-07-28.
