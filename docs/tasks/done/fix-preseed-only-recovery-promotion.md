# Fix Preseed-Only Recovery Promotion

## Status

Done — 2026-07-28

## Context

A full `generate-architecture` run showed components reported as recovered even
when the agent only changed generation metadata, or failed after leaving
`.generation/candidate.md` identical to `.generation/preseed.md`. That allowed
analyzer diagnostic content to be promoted in some runs and made no-op agent
failures hard to diagnose.

## Changes

- Recovery now compares `candidate.md` against `preseed.md`, not merely against
  the analyzer baseline.
- Generated metadata lines and duration footers are ignored when comparing
  preseed and candidate content.
- Partial/synthesis merge now rejects candidates with no substantive delta from
  the preseed before evidence-gated merge/promotion.
- Empty agent errors are filled with an explicit no-substantive-change reason
  when applicable.
- Added regression coverage for unchanged and metadata-only candidates.

## Validation

- `uv run ruff check lib/phases/architecture.py tests/test_architecture_phase.py`
- `uv run pytest tests/test_architecture_phase.py -q`
