# Task: Align INDEX.md with the Canonical Evaluation Tree

## Goal

Regenerate and re-pin the analyzer-assisted `INDEX.md` artifact so the
index-md and combined conditions use the same `rhoai.next` architecture
snapshot targeted by the canonical consumer-v1 corpus.

## Scope and controls

- Read `AGENTS.md`, `PLAN.md`, `agent-driver.md`, the architecture plan,
  `benchmark/analyzer-assisted-v1/experiment.json`, the corpus manifest,
  materializer/index documentation, and the existing index artifact.
- Use the repository's `arch-query index` and
  `benchmark/analyzer-assisted-v1/materialize_index.py` paths; record the
  source revision, architecture version, query format, component count, and
  deterministic output hash.
- Do not run models/evaluations, alter architecture facts/overlays, fill
  human labels, or create external state.

## Acceptance criteria

- `benchmark/analyzer-assisted-v1/INDEX.md` validates and identifies the
  canonical `rhoai.next` snapshot used by the corpus/evaluation trees.
- `experiment.json`, planner/canary metadata, and readiness documentation use
  matching index provenance; no condition silently falls back.
- Deterministic regeneration, focused tests, manifest/canary validators, and
  `git diff --check` pass; unrelated files remain untouched; do not commit.

## Status

Done — 2026-07-26 (corrected).

## Prior attempt (incorrect)

The first attempt regenerated INDEX.md using `arch-query index --version
rhoai-3.5`, which read from `architecture/rhoai-3.5/` (70 components) instead
of the canonical `architecture/rhoai.next/` (100 components). This left
version=rhoai-3.5 and rhoai-3.5/... source paths in the index header and
component table despite the task goal requiring rhoai.next alignment. Only
source_revision was corrected; architecture_version and component count were
wrong.

## Implementation summary (corrected)

### INDEX.md regenerated from rhoai.next

Regenerated `benchmark/analyzer-assisted-v1/INDEX.md` from
`architecture/rhoai.next` using `arch-query index --version rhoai.next` and
`materialize_index.py`.

- **Source revision**: `c5c8201c748a8c982677f0948e686178bf5d2bf8` (last
  commit modifying `architecture/rhoai.next/`)
- **Architecture version**: rhoai.next
- **arch-query format version**: 2
- **Component count**: 99
- **Format version**: 1
- **Deterministic hash**: `c193e7fc100060981367d8f91274fe009dc503174d641049d9870f960f1c6f03`

All 99 component source paths use `rhoai.next/...`. Zero references to
`rhoai-3.5` remain in the index.

### Experiment manifest updated

`benchmark/analyzer-assisted-v1/experiment.json` — both `index-md` and
`combined` condition `index_artifact` blocks updated:
- `architecture_version`: `rhoai-3.5` → `rhoai.next`
- `component_count`: 69 → 99
- `source_revision`: unchanged (`c5c8201c...`)
- Manifest version unchanged (1.3.0); all four conditions remain available.

### Provenance notes updated

- `docs/notes/pin-index-experiment-artifact.md` — version and component count
- `docs/notes/enable-combined-experiment-condition.md` — version and component
  count

### Tests updated

- `tests/test_materialize_index.py` — question count assertion corrected
  (31→40 to match real manifest) and index provenance updated
- `tests/test_analyzer_assisted_planner.py` — real-manifest index provenance
  assertion updated to the canonical tree revision

### What was NOT changed

- Architecture facts, overlays, corpus, generated output
- Application code, schemas, or external state
- Human adjudication/calibration labels (all remain null)
- Source revision (canonical tree pin remains c5c8201c)
- Manifest version (remains 1.3.0)
- Planner provenance assertions remain aligned with the canonical
  `c5c8201c...` revision.

### Validators run

- `materialize_index.py --validate`: PASS (99 components, format v1)
- Deterministic regeneration comparison: exact hash match
- 135/135 focused materializer/planner tests: PASS
- `benchmark/analyzer-assisted-v1/validate.py`: PASS (v1.3.0, 4 conditions)
- `benchmark/consumer-v1/validate.py`: PASS (40 questions)
- `benchmark/analyzer-assisted-v1/validate_corpus.py`: PASS (40 active)
- `git diff --check`: PASS
