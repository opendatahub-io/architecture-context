# Task: Enforce Synthesis Routing and Source-Read Permissions

## Goal

Align the architecture-agent policy with the analyzer-assisted plan's three
routes and make source-read permissions explicit and testable.

## Scope

- Update `lib/architecture_routing.py` and the directly affected architecture
  phase/agent-runner integration so routes are explicitly `synthesis`,
  `partial`, or `legacy`.
- `synthesis` must expose baseline/index/overlay/query context only and no
  source discovery or source-file reads.
- `partial` must expose only category-specific, bounded source reads and record
  the nominated gap categories and file budget.
- Preserve the legacy fallback for insufficient/unknown readiness and existing
  analyzer-only eligibility behavior where it remains compatible.
- Add focused regression tests for route selection, tool permissions, source
  budgets, and prompt arguments; preserve existing safety gates.

## Negative controls

- Do not implement OTel, paid/full-corpus benchmarks, synthesis generation,
  merge behavior, or generated architecture output.
- Do not weaken analyzer-owned fact or overlay protections.
- Do not resolve existing generated-document merge conflicts.

## Acceptance criteria

- [x] Route values and prompt arguments match the plan's `synthesis`, `partial`,
  and `legacy` contract.
- [x] Synthesis policies cannot request source reads; partial policies have
  explicit category and file limits; legacy retains boundedness as currently
  defined by its existing route.
- [x] Existing routing tests pass or any changed expectation is documented with
  evidence; new tests cover positive and negative permission cases.
- [x] Task note, session log, PLAN, and an accepted scoped commit are recorded.

## Status

Done. Accepted after review; focused tests and lint pass.

## Validation

- `.venv/bin/pytest -q tests/test_architecture_routing.py tests/test_architecture_phase.py tests/test_agent_runner.py`: 42 passed
- `.venv/bin/ruff check lib/architecture_routing.py lib/agent_runner.py lib/phases/architecture.py tests/test_architecture_routing.py tests/test_architecture_phase.py tests/test_agent_runner.py`: passed
- `git diff --check`: passed
- Synthesis policies have no source-file budget or discovery tools and deny source reads.
- Partial policies use bounded file budgets and `Glob`/`Grep` only.
- Legacy and analyzer-only routes remain unchanged.

Accepted commit: `7abd1c11`.
