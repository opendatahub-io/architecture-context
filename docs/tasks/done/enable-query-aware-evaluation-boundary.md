# Task: Enable the Query-Aware Evaluation Boundary

## Goal

Add an opt-in, command-restricted `arch-query` execution path to the
consumer-v1 evaluator so query-enabled conditions can use structured evidence
without granting unrestricted shell or source access.

## Scope

- Extend `benchmark/consumer-v1/run_evaluation.py` so a query-enabled condition
  explicitly permits `arch-query query` through the evaluator guard, while
  baseline behavior remains Read/Glob/Grep-only.
- Allow only direct, parsed query invocations from the approved binary, with
  the query subcommands in the experiment contract, JSON output, and an
  architecture-tree base directory constrained to the evaluated tree; deny
  shell operators, arbitrary commands, writes, and path escapes.
- Add query permission/denial telemetry and condition-aware prompt guidance;
  preserve result/provenance compatibility and no-fallback preflight.
- Add focused tests for opt-in permission, command parsing, base-dir/path
  enforcement, telemetry, denied shell behavior, and unchanged baseline.

## Negative controls

- Do not mark pending experiment conditions available or run any evaluation.
- Do not launch paid/full-corpus/external agents, modify generated output,
  manifests, query implementation, or architecture facts.
- Do not permit arbitrary Bash, source reads outside the evaluated tree, or
  fabricated query evidence.

## Acceptance criteria

- [x] Query access is unavailable unless the selected condition explicitly
  enables it.
- [x] Valid query commands are constrained to the approved binary, subcommands,
  JSON output, and evaluated-tree base directory.
- [x] Denials and successful queries are visible in context telemetry and
  result provenance without changing baseline compatibility.
- [x] Focused tests, lint, task note, session log, PLAN, and accepted scoped
  commit are recorded.

## Status

Implementation complete; accepted after focused review and validation.
