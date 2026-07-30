# Task: Replace Hard Partial Route File Budget

## Goal

Reduce the remaining partial-route slow tail by replacing the hard
partial-route source-file cap with a bounded read policy. The policy should
continue to block expensive or unsafe behavior while avoiding retry loops when
an agent follows a relevant bounded source trail.

## Context

The `20260730T110242Z` full rerun improved overall generation runtime, but
`docs/bugs/open/partial-route-component-runtime-remains-high.md` remains open.
The current slow tail includes:

| Component | Duration | Gap count | Targeted reads | Denied calls |
|---|---:|---:|---:|---:|
| `notebooks-downstream` | 548s | 4 | 6 | 5 |
| `odh-gitops` | 388s | 6 | 9 | 6 |
| `pipelines-components` | 353s | 5 | 7 | 5 |
| `modelmesh` | 367s | 5 | 7 | 4 |

## Plan

1. Mine current `logs/generate-architecture/*.run.json` and agent logs for the
   slow/high-denial components.
2. Classify denied calls by cause: skill/tool instruction mismatch, route
   planner over-selection, missing analyzer evidence, or expected sandbox
   protection.
3. Replace hard source-file and targeted-discovery budget denials with
   telemetry while preserving hard denials for broad discovery, Bash/Task,
   prior architecture reads, writes outside the output contract, and unbounded
   large source reads.
4. Validate with focused tests and a targeted pipeline replay command or
   script update.
5. Update the runtime bug and session log with before/after evidence.

## Acceptance Criteria

- The current slow/high-denial components have a documented denial taxonomy.
- Avoidable hard budget denials are replaced by soft-budget telemetry.
- Focused tests cover the implemented behavior.
- A targeted replay path exists for the affected components.

## Status

Done 2026-07-30.

Denial mining showed the slow tail was dominated by
`budget-exhausted`, `broad-discovery`, and `oversized-source-read` retries.
The hard source-file budget was judged counterproductive until analyzer
coverage is much more complete. The implementation should keep bounded source
reads and targeted discovery, but allow relevant over-guidance reads while
recording budget pressure.

Implemented by replacing hard source-file and targeted-discovery budget
denials with soft telemetry (`source_read_budget_exceeded`,
`source_read_budget_exceeded_files`, and `discovery_budget_exceeded`).
Preserved hard denials for Bash/Task, broad full-checkout Glob patterns, prior
architecture reads, invalid writes, and unbounded large source reads. Also
closed the default-output guard gap where `Write` could replace a preseeded
`GENERATED_ARCHITECTURE.md` when explicit output paths were not supplied.

Validation:

- `uv run pytest tests/test_agent_runner.py tests/test_architecture_routing.py -q`
  — 101 passed
- `uv run python -m py_compile lib/agent_runner.py lib/phases/architecture.py lib/architecture_routing.py`
- `bash -n custom-test.sh`

Replay result:

The user-run targeted replay at
`logs/pipeline/partial-route-soft-budget-replay-20260730T122935Z/generate-architecture/`
completed all four components successfully.

| Component | Duration | Denials | Source reads | Soft source-budget hits | Soft discovery-budget hits |
|---|---:|---:|---:|---:|---:|
| `notebooks-downstream` | 548s -> 284s | 5 -> 1 | 6 -> 11 | 5 | 0 |
| `odh-gitops` | 388s -> 299s | 6 -> 1 | 9 -> 21 | 12 | 12 |
| `modelmesh` | 367s -> 346s | 4 -> 0 | 7 -> 14 | 4 | 12 |
| `pipelines-components` | 353s -> 338s | 5 -> 0 | 7 -> 11 | 1 | 13 |

The replay removed all `budget-exhausted` denials and improved wall time for
all four components, especially `notebooks-downstream` and `odh-gitops`.
Remaining hard denials were expected guardrail cases: one oversized unbounded
read and one root-wide Glob. Three components reported missing source-read
justifications for extra files read beyond the old hard cap; that is the next
follow-up, not a reason to restore hard file-budget denials.
