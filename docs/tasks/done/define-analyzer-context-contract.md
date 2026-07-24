# Task: Define Analyzer Context Contract

## Goal

Implement the first schema/model contract from Step 2 of
`docs/plans/analyzer-assisted-agent-architecture.md` so analyzer output can
carry provenance, applicability, freshness, confidence, maturity, scope,
deployment topology, dependency/upstream status, behavioral evidence, and
explicit unknowns without guessing.

## Scope

- Add a versioned JSON Schema/model representation for the contract envelope
  around `component-architecture.json`.
- Support explicit `unknown`, `not-extracted`, and `needs-validation` states;
  distinguish missing from confirmed values.
- Preserve all existing analyzer fields and existing JSON fixtures as
  backwards-compatible input unless a focused migration is justified.
- Add renderer support only for displaying populated contract metadata and
  unknown states deterministically; do not invent values or claims.

## Negative controls

- Do not populate provenance, freshness, maturity, ownership, performance,
  dependency, or behavioral fields from inference or absence.
- Do not alter generated architecture output broadly or resolve unrelated
  merge-conflicted documents.
- Do not implement query, overlays, synthesis, or run paid/full-corpus
  evaluations in this task.

## Acceptance criteria

- [x] Versioned schema documents the contract fields, enums, applicability, and
  explicit unknown states with concrete `examples`.
- [x] Go model/input decoding preserves absent fields and explicit unknowns;
  existing fixtures still decode and render unchanged where metadata is absent.
- [x] Renderer emits contract metadata only when present and labels unknown or
  not-extracted values without implying facts.
- [x] Focused Go/schema tests cover valid confirmed values, explicit unknowns,
  invalid enums, stale applicability (including invalid date ordering), and
  backward compatibility.
- [x] Plan note, session log, and PLAN are reconciled; no unrelated generated
  artifacts are changed.
- [x] Task is moved to `done/` only after review and an accepted commit.

## Status

Done — schema includes concrete examples for confirmed and
explicit-unknown/not-extracted contracts, applicability documents the date
ordering constraint, and Go model exposes `Validate()` (rejects inverted date
ordering) and `Stale()` (deterministic staleness check) with full table-driven
test coverage. All Go tests pass.
