# Task: Define Bounded Synthesis Insights Contract

## Goal

Implement the first bounded synthesis step from
`docs/plans/analyzer-assisted-agent-architecture.md`: represent agent-derived
architectural insights separately from analyzer facts and make them reviewable
without allowing unsupported claims to become authoritative structured data.

## Scope

- Add a versioned JSON schema/model and validator for an `insights` artifact.
- Each insight must contain a claim, category (`pattern`, `trade-off`, `risk`,
  or `cross-component implication`), cited input references, reasoning,
  applicability, confidence, unresolved alternatives/counterevidence, and a
  suggested validation action.
- Require explicit provenance references to analyzer facts, query results,
  overlays, or source excerpts; reject empty/unsupported references and
  invalid categories/statuses.
- Add deterministic ordering, bounded insight count/token metadata, explicit
  unknown/not-extracted semantics, and a read-only validation command/library.
- Ensure existing architecture merge/renderer paths do not promote insights
  into analyzer tables, dependency status, security findings, or acceptance
  criteria. Add regression tests for preservation and rejection.
- Document concrete valid, unknown, and invalid examples.

## Negative controls

- Do not invoke paid/full-corpus synthesis runs.
- Do not implement routing, OTel, source-read permissions, or new insight
  generation heuristics.
- Do not modify generated architecture documents or resolve merge conflicts.
- Do not silently promote insights into facts or apply recommendations.

## Acceptance criteria

- [x] Versioned schema/model and validation examples cover all required fields,
  categories, provenance, applicability, confidence, unknowns, and bounds.
- [x] Valid insights round-trip deterministically; invalid category,
  provenance, applicability, and unsupported-claim cases fail visibly.
- [x] Existing merge/renderer behavior is unchanged and tests prove insights
  remain non-authoritative and separate.
- [x] Plan note, session log, and PLAN are reconciled.
- [x] Task is moved to `done/` only after review and an accepted commit.

## Status

Done. Accepted after review; focused tests and lint pass.

## Validation

- `.venv/bin/pytest -q tests/test_insights.py tests/test_rebase_architecture_synthesis.py`: 84 passed
- `.venv/bin/ruff check lib/insights.py tests/test_insights.py`: passed
- `git diff --check`: passed
- No paid/full-corpus synthesis run or generated architecture output was changed.

Accepted commit: `fd8e784c`.
