# Bug: Concurrent Agent Output Aborts Captured Platform Run

## Summary

The first full `rhoai.next` corpus attempt aborted component generation after the
first ten workers because concurrent agents streamed complete SDK messages through
the shared Rich progress console while the harness captured stdout with `tee`.

## Reproduction

1. Run `scripts/run_rhoai_next_architecture.sh` with ten workers.
2. Allow agents to return large `Read` tool results.
3. Observe multi-megabyte SDK messages written to the shared progress console.
4. The nonblocking captured stdout eventually raises
   `[Errno 11] write could not complete without blocking`.

## Expected

Full SDK messages are retained in per-agent logs, while shared console output stays
bounded and cannot terminate agent execution.

## Actual

The run at `rhoai-next-20260718T033804Z` completed static analysis and captured all
90 analyzer inputs, then aborted component generation after approximately 61 seconds.
Only the first ten agents had started and no collection or comparison report ran.

## Root Cause

`run_agent` sent every SDK response to both the per-agent file and
`AgentProgress.log`. Source-file tool results can be hundreds of kilobytes each.
Rich attempted to write that volume through the harness pipe and propagated
`EAGAIN`, including from error-reporting paths.

## Fix

- Concurrent runs now write complete SDK payloads only to per-agent log files.
- The shared progress console receives bounded lifecycle messages.
- Progress logging treats nonblocking `EAGAIN` as a best-effort display failure,
  without affecting agent results.
- Regression tests verify large SDK payloads do not reach the shared console and a
  nonblocking progress write does not escape.

## Status

Fixed on 2026-07-17.

## Related Work

- [RHOAI next corpus measurement harness](../../tasks/done/rhoai-next-corpus-measurement-harness.md)
