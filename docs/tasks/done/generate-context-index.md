# Task: Generate Context Index and Version-Diff Contract

## Goal

Implement the next bounded step in `docs/plans/analyzer-assisted-agent-architecture.md`:
provide a deterministic, generated index for architecture context and a
machine-readable version-diff contract without changing generated component
facts or resolving unrelated source conflicts.

## Scope

- Inspect the existing architecture/component-map formats and current
  `arch-query` version/loader facilities before choosing the narrowest
  integration point.
- Add a deterministic index artifact or generator that maps components and
  common question categories to their available architecture sections and
  source artifacts.
- Include stable component aliases where existing data provides an explicit
  rename relationship; do not infer aliases from fuzzy names.
- Define and test a bounded machine-readable diff result for two compatible
  architecture snapshots, including added/removed/changed facts and explicit
  unknown/not-extracted outcomes when comparison inputs are absent or
  incompatible.
- Preserve existing CLI behavior and generated architecture output unless the
  new command/artifact is explicitly requested.

## Negative controls

- Do not implement overlays, correction harvesting, synthesis, or the full
  query command suite.
- Do not invent aliases, ownership, applicability, or fact values.
- Do not modify generated `architecture/` documents or resolve existing merge
  conflicts.
- Do not run paid/full-corpus evaluations.

## Acceptance criteria

- [x] The index and diff formats are versioned and documented with concrete
  examples, provenance/applicability fields where available, and explicit
  unknown/not-extracted semantics.
- [x] Generation/order is deterministic and has focused tests for normal,
  empty, missing, and incompatible inputs.
- [x] Existing tests and CLI commands remain compatible; new behavior is
  opt-in and has a focused invocation test.
- [x] No generated architecture files, overlays, or unrelated worktree files
  are changed.
- [x] A plan note, session-log entry, and PLAN update reconcile the result.
- [x] Task is moved to `done/` only after review and an accepted commit.

## Status

Done — `arch-query index` emits a deterministic versioned context index with
question-category mappings and source artifacts; JSON diff output is versioned
and reports explicit unknown/not-extracted/incompatible outcomes. Focused
tests and vet pass.
