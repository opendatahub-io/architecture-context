# Task: Report Correction Frequency from Proposal Artifacts

## Goal

Implement the next bounded feedback-loop step from
`docs/plans/analyzer-assisted-agent-architecture.md`: prioritize manual review
and regeneration using deterministic correction-frequency reports derived from
reviewable proposal artifacts.

## Scope

- Add a versioned machine-readable report model and an opt-in `arch-query`
  command that reads a validated proposal set.
- Aggregate proposal counts by component, correction category, review status,
  and release applicability; include stable ordering and a concise text view.
- Exclude superseded proposals from active counts while retaining explicit
  rejected/reviewed/pending distinctions.
- Add focused tests for empty, duplicate-invalid, mixed-status, superseded,
  and deterministic inputs, plus documentation examples.

## Negative controls

- Do not harvest Staff/SME text or infer corrections from architecture files.
- Do not apply proposals, modify generated architecture output, or change
  existing overlay parsing.
- Do not invent component aliases, ownership, maturity, or priorities.
- Do not run paid/full-corpus evaluations or resolve merge conflicts.

## Acceptance criteria

- [x] Report format is versioned and documents provenance/input identity,
  explicit unknown/not-extracted values, and concrete examples.
- [x] Invalid proposal sets fail deterministically before aggregation.
- [x] Counts and ordering are deterministic and covered by focused tests; the
  command is opt-in and read-only.
- [x] Existing CLI behavior remains compatible and no generated output changes.
- [x] Plan note, session log, and PLAN are reconciled.
- [x] Task is moved to `done/` only after review and an accepted commit.

## Status

Done — `arch-query proposals report` emits a versioned deterministic report
from validated proposal artifacts, excluding superseded proposals from active
aggregations while preserving their input identity and count.
