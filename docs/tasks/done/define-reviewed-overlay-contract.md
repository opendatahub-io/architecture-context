# Task: Define Reviewed Overlay Contract and Correction Proposals

## Goal

Implement the next bounded step in `docs/plans/analyzer-assisted-agent-architecture.md`:
make human-reviewed architecture corrections representable and reviewable
without allowing regeneration or unreviewed agent output to become
authoritative.

## Scope

- Inspect the existing `architecture/overlays/` format and `arch-query`
  overlay parser.
- Define a versioned, machine-readable overlay/proposal model with component
  scope, correction category, claim or replacement text, provenance, author or
  source, applicability, last-verified date, and review status.
- Add validation for required metadata, supported statuses/categories, date
  ordering, and component scope; preserve unknown/not-extracted semantics.
- Add a deterministic proposal artifact or command that can represent
  correction candidates without applying them to generated architecture
  documents.
- Add focused tests and documentation examples.

## Negative controls

- Do not apply proposals automatically or modify generated `architecture/`
  documents.
- Do not implement Staff/SME text harvesting, correction-frequency reports,
  synthesis, or query expansion in this task.
- Do not infer ownership, maturity, applicability, aliases, or facts.
- Do not resolve existing merge conflicts or touch unrelated worktree files.

## Acceptance criteria

- [x] Contract is versioned and documents provenance, applicability,
  last-verified date, review status, correction category, and explicit
  unknown/not-extracted semantics with concrete examples.
- [x] Invalid metadata is rejected deterministically; valid reviewed and
  pending proposals round-trip without losing fields.
- [x] Proposal generation is opt-in, deterministic, and cannot mutate
  generated architecture output; focused tests cover empty, valid, invalid,
  stale, and unreviewed cases.
- [x] Existing overlay parsing and CLI behavior remain compatible.
- [x] Plan note, session log, and PLAN are reconciled.
- [x] Task is moved to `done/` only after review and an accepted commit.

## Status

Done — proposal contract v1 and read-only `arch-query proposals generate` /
`validate` commands are implemented. Generation is deterministic by default;
explicit generated timestamps are opt-in. All focused and existing tests pass.
