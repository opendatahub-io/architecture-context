# Task: Allow Bounded Source Reads on the Partial Route

## Goal

Allow partial-route agents to read targeted checkout files within the configured
file budget regardless of readiness classification.

## Context

The completed run routed analyzer-backed components through `partial`, but the
guard still rejected reads whenever readiness was `sufficient`, producing
misleading source-read denials.

## Acceptance Criteria

- [x] Partial route permits checkout reads until `file_budget` is exhausted.
- [x] Synthesis route remains source-free except for explicitly permitted
      analyzer-referenced files.
- [x] Prior architecture paths, outside-checkout paths, tests, and secrets
      remain protected.
- [x] Regression tests cover sufficient+partial and sufficient+synthesis.

## Status

Implemented; next full run should measure the reduction in denied reads.
