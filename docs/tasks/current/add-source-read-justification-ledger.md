# Task: Add the Source-Read Justification Ledger

## Goal

Require partial-route agents to explain why each source file was read and what
the read contributed, without blocking legitimate bounded investigation.

## Contract

Write a sidecar JSON artifact containing `path`, `line_range`,
`gap_category`, `question`, `expected_signal`, `outcome`, and affected output
`sections`. It must contain metadata only, never source excerpts or secrets.

## Acceptance Criteria

- [ ] Skill instructions require one record per source file read.
- [ ] Orchestrator passes a dedicated sidecar output path and validates its
      schema.
- [ ] Telemetry and ledger paths are compared; missing records are reported.
- [ ] Initial behavior is warning-only and does not deny source reads.
- [ ] Replay reaches at least 95% justified reads on representative fixtures.

## Status

Current
