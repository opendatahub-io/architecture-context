# Task: Fix Partial Route Oversized Source Reads

## Goal

Prevent future partial-route agents from reading whole large source files while
making oversized-read telemetry visible enough for analyzer optimization.

## Bug

- `docs/bugs/fixed/partial-route-oversized-source-reads.md`

## Scope

- Add structured oversized-read details to source-read justification validation.
- Group oversized reads by gap category in run-report validation output.
- Treat oversized ledger records without `scope_reason` as unjustified.
- Strengthen the repo-to-architecture-summary skill contract so agents prefer
  exact symbols, functions, handlers, and manifest snippets over whole files.
- Enforce partial-route read bounds in the agent guard: source files larger than
  400 lines require an explicit `offset`/`limit`, and `limit` must be at most
  400.

## Execution record

- `lib.source_read_justifications` now emits:
  - `oversized_reads`
  - `oversized_read_category_counts`
  - `oversized-read-missing-scope-reason` diagnostics
- Oversized records missing `scope_reason` no longer count toward justified
  telemetry coverage.
- `lib.agent_runner._AgentExecutionGuard` now denies unbounded partial-route
  source reads of files larger than 400 lines and denies partial-route source
  reads with `limit > 400`.
- Bounded reads of the same large file remain allowed, so the guard does not
  block source inspection outright.
- `.claude/skills/repo-to-architecture-summary/SKILL.md` now directs agents to
  use exact symbols/functions/manifest snippets and says missing `scope_reason`
  makes a broad read unjustified.

## Validation

```bash
uv run ruff check lib/agent_runner.py lib/source_read_justifications.py tests/test_agent_runner.py tests/test_source_read_justifications.py
uv run pytest -q tests/test_agent_runner.py tests/test_source_read_justifications.py
uv run pytest -q tests/test_architecture_phase.py
uv run pytest -q tests/test_agent_runner.py tests/test_source_read_justifications.py tests/test_architecture_phase.py
```

Results:

- agent/source-read focused suite: `26 passed`
- architecture-phase suite: `18 passed`
- combined focused suite: `44 passed`

A read-only replay over existing historical `rhoai.next` run reports still
shows the old baseline of 64 oversized reads across 49 components, with 2
missing `scope_reason`. Those historical artifacts are not rewritten or
committed. Future partial-route runs should not produce new unbounded
single-read oversized source events because the guard now requires bounded
`offset`/`limit` reads.

## Status

Completed 2026-07-28.
