# Task: Re-author Retired Navigation Question NAV-003

## Goal

Restore only `NAV-003` with a precise navigation question backed by clean
architecture-tree evidence, or leave it retired with a documented reason.

## Scope and controls

- Read `AGENTS.md`, `PLAN.md`, `agent-driver.md`, this task, the original
  v1-ab NAV-003 record, audit notes, and clean `architecture/rhoai.next/`.
- Prefer a narrow question locating the platform dependency graph in
  `architecture/rhoai.next/PLATFORM.md` (the `Component Relationships` /
  `Dependency Graph` section at lines 22-24), if that is sufficiently useful
  and exact for the navigation category.
- Do not restore the overlay-count question, touch NAV-006, modify raw/scored
  results, schemas/validators, generated docs, overlays, or run evaluation.
- Do not commit; update only task-scoped corpus, manifest, count notes, tests,
  bug/task status, and ledger records if restoration is accepted.

## Acceptance criteria

- [x] Restore NAV-003 only if the question has a deterministic answer and every
  claim has exact clean-tree `source_file`/`source_line` evidence; otherwise
  record a precise unresolved reason and recovery path without corpus changes.
- [x] Keep NAV-006 and all remaining gaps explicit.
- [x] Run manifest/corpus validation, focused planner/runner/manifest tests, and
  `git diff --check`.
- [x] Report the exact question, expected answer, source evidence, counts, files,
  validation results, and limitations.
- [x] Move to `done/` after reconciliation complete.

## Result

**Restored** — NAV-003 re-authored as a dependency-graph navigation question.

### Question

| Field | Value |
|-------|-------|
| Question | Where is the platform component dependency graph documented in the RHOAI architecture tree? |
| Expected answer | In architecture/rhoai.next/PLATFORM.md under the 'Component Relationships' section (line 22) and 'Dependency Graph' subsection (line 24). It is a text-format tree rooted at rhods-operator showing inter-component dependencies, followed by a list of leaf components with no internal dependencies. |
| Source file | `architecture/rhoai.next/PLATFORM.md` |
| Source line | 22 |
| Category | navigation |
| Tier | 4 |
| Difficulty | basic |
| Scope | rhoai.next |
| Answerability | answerable |

### Source evidence

- `architecture/rhoai.next/PLATFORM.md` line 22: `## Component Relationships`
- `architecture/rhoai.next/PLATFORM.md` line 24: `### Dependency Graph`
- Lines 26-115: text-format tree rooted at `rhods-operator` with leaf components list

### Counts (before → after)

| Metric | Before | After |
|--------|--------|-------|
| Active questions | 38 | 39 |
| Retired questions | 2 | 1 |
| Tier 4 active | 8 | 9 |
| Tier 4 retired | 2 | 1 |
| Navigation active | 8 | 9 |
| Navigation retired | 2 | 1 |
| Answerable | 36 | 37 |
| Undetermined | 2 | 1 |
| consumer-v1 corpus | 38 | 39 |
| Missing IDs | NAV-003, NAV-006 | NAV-006 |

### Changed files (task-scoped)

| File | Change |
|------|--------|
| `benchmark/consumer-v1/corpus.json` | Added NAV-003 question entry |
| `benchmark/analyzer-assisted-v1/corpus_manifest.json` | NAV-003 status retired→active, aggregates and gaps updated |
| `tests/test_corpus_manifest.py` | Active count 38→39, retired count 2→1, consumer-v1 count 38→39 |
| `tests/test_analyzer_assisted_planner.py` | Active count 38→39, NAV-003 inclusion/exclusion, retired ID NAV-003→NAV-006 |
| `tests/test_condition_aware_runner.py` | Active count 38→39, retired ID test NAV-003→NAV-006 |
| `docs/bugs/open/corpus-v1-below-minimum-question-count.md` | Counts updated, missing IDs: NAV-006 only |
| `docs/notes/analyzer-assisted-corpus-baseline.md` | Counts and restoration list updated |
| `docs/notes/analyzer-assisted-evaluation-contract.md` | Known gap counts updated |

### Validation results

| Check | Result |
|-------|--------|
| `python3 benchmark/analyzer-assisted-v1/validate_corpus.py` | PASS: 40 entries, 39 active, 1 retired |
| `pytest tests/test_corpus_manifest.py tests/test_analyzer_assisted_planner.py tests/test_condition_aware_runner.py` | 170 passed |
| `git diff --check` | Clean |

### Limitations

- NAV-006 remains retired — its source evidence (`overlays/README.md`) is outside
  the evaluation mount scope. Recovery requires evaluation scope expansion.
- Consumer-v1 corpus is at 39/40 questions; schema `minItems: 40` still fails.
- The original overlay-count question was not restored (per task scope).

## Status

Done — 2026-07-25 (restored; reconciliation complete).
