# Task: Re-author Retired Navigation Question NAV-006

## Goal

Restore only `NAV-006` with a precise navigation question backed by clean
architecture-tree evidence, or leave it retired with a documented reason.

## Scope and controls

- Read `AGENTS.md`, `PLAN.md`, `agent-driver.md`, this task, the original
  v1-ab NAV-006 record, audit notes, and clean `architecture/rhoai.next/`.
- Prefer a narrow question locating the three-namespace deployment model in
  `architecture/rhoai.next/PLATFORM.md` (the `Deployment Architecture` /
  `Deployment Topology` section at lines 253-257), if exact and useful.
- Do not restore the overlay-lifecycle claim; do not modify other IDs, raw or
  scored results, schemas/validators, generated docs, or overlays; do not run
  evaluation/benchmark or commit.

## Acceptance criteria

- [x] Restore NAV-006 only if the question has a deterministic answer and every
  claim has exact clean-tree `source_file`/`source_line` evidence; otherwise
  record a precise unresolved reason and recovery path without corpus changes.
- [x] Keep all remaining gaps explicit and reconcile count-sensitive notes if
  restored.
- [x] Run manifest/corpus validation, focused planner/runner/manifest tests, and
  `git diff --check`.
- [x] Report the exact question, expected answer, source evidence, counts, files,
  validation results, and limitations.

## Result

**Restored** — NAV-006 re-authored as a deployment-topology navigation question.

### Question

| Field | Value |
|-------|-------|
| Question | Where is the platform deployment topology documented in the RHOAI architecture tree? |
| Expected answer | In architecture/rhoai.next/PLATFORM.md under the 'Deployment Architecture' section (line 253) and 'Deployment Topology' subsection (line 255). It describes a three-namespace deployment model with user workspace isolation: operator namespace (redhat-ods-operator), applications namespace (redhat-ods-applications), user namespaces, and monitoring namespace (redhat-ods-monitoring). |
| Source file | `architecture/rhoai.next/PLATFORM.md` |
| Source line | 253 |
| Category | navigation |
| Tier | 4 |
| Difficulty | basic |
| Scope | rhoai.next |
| Answerability | answerable |

### Source evidence

- `architecture/rhoai.next/PLATFORM.md` line 253: `## Deployment Architecture`
- `architecture/rhoai.next/PLATFORM.md` line 255: `### Deployment Topology`
- Line 257: "The platform follows a three-namespace deployment model with user workspace isolation:"
- Lines 259-265: Four namespace descriptions (operator, applications, user, monitoring)

### Counts (before → after)

| Metric | Before | After |
|--------|--------|-------|
| Active questions | 39 | 40 |
| Retired questions | 1 | 0 |
| Tier 4 active | 9 | 10 |
| Tier 4 retired | 1 | 0 |
| Navigation active | 9 | 10 |
| Navigation retired | 1 | 0 |
| Answerable | 37 | 38 |
| Undetermined | 1 | 0 |
| consumer-v1 corpus | 39 | 40 |
| Missing IDs | NAV-006 | (none) |

### Changed files (task-scoped)

| File | Change |
|------|--------|
| `benchmark/consumer-v1/corpus.json` | Added NAV-006 question entry |
| `benchmark/analyzer-assisted-v1/corpus_manifest.json` | NAV-006 status retired→active, aggregates and gaps updated |
| `tests/test_corpus_manifest.py` | Active count 39→40, retired count 1→0, consumer-v1 count 39→40 |
| `tests/test_analyzer_assisted_planner.py` | Active count 39→40, NAV-006 inclusion, retired ID test removed |
| `tests/test_condition_aware_runner.py` | Active count 39→40, retired ID test updated |
| `docs/bugs/open/corpus-v1-below-minimum-question-count.md` | Marked resolved, counts updated |
| `docs/notes/analyzer-assisted-corpus-baseline.md` | Counts and restoration list updated |
| `docs/notes/analyzer-assisted-evaluation-contract.md` | Known gap section updated to resolved |
| `docs/plans/analyzer-assisted-agent-architecture.md` | Baseline provenance, Step 1/5 counts, corpus gate resolved, "2 retired"→"1 retired" |
| `docs/notes/session-log.md` | Session entry added |
| `PLAN.md` | Active task added, recently completed updated |

### Limitations

- The original overlay-lifecycle question was not restored (per task scope).
- The v1-ab scores for NAV-006 reflect the original (pre-correction) expected answer.

## Status

Done — 2026-07-25 (restored; deployment topology navigation).
