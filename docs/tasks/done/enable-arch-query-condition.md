# Task: Enable the Implemented `arch-query` Experiment Condition

## Goal

Reconcile the analyzer-assisted experiment contract with the reviewed query
implementation so the `arch-query` condition is accurately available, while
keeping INDEX.md and combined conditions unavailable.

## Scope

- Update `benchmark/analyzer-assisted-v1/experiment.json` to mark only
  `arch-query` available, describe its actual restricted evaluator boundary,
  and provide reproducible query-binary provenance requirements.
- Update the analyzer-assisted README and focused tests that assert all
  non-baseline conditions are pending; preserve the no-silent-fallback rules.
- Ensure the manifest’s permitted/denied tools agree with
  `benchmark/consumer-v1/run_evaluation.py`: Bash is the transport, but only
  the constrained bare `arch-query query` commands are accepted.
- Record validation evidence in a task note and session log; do not run an
  evaluation or mark INDEX.md/combined available.

## Negative controls

- Do not modify query implementation, generated architecture output, corpus
  facts, scoring, or production dependencies.
- Do not launch agents, paid/full-corpus benchmarks, or external evaluations.
- Do not claim query subcommands are extracted beyond their current
  `unknown`/`not-extracted` contract behavior.

## Acceptance criteria

- [x] Manifest accurately marks only `arch-query` available and requires
  architecture and query-binary provenance.
- [x] Manifest access boundaries match the guarded evaluator behavior and
  explicitly forbid arbitrary Bash/source access and writes.
- [x] README, planner/evaluation tests, and manifest validation agree on the
  new availability split and no-fallback behavior.
- [x] Focused tests, deterministic validators, task note, session log, and
  scoped commit are recorded.

## Status

Accepted — 2026-07-25.

## Task Note

### Reconciliation summary (2026-07-25)

The manifest `arch-query` condition is now `available: true, status: available`
with `tools_permitted: [Read, Glob, Grep, Bash]` and `tools_denied: [Write, Edit]`.
This matches the `run_evaluation.py` evaluator guard which permits Bash only as a
transport for constrained `arch-query query` invocations (no shell metacharacters,
approved subcommands only, explicit `-o json`, `--base-dir` inside evaluated tree).

The `evaluator_bash_constraint` field documents the guard rules directly in the
manifest. The `approved_query_subcommands` list matches `APPROVED_QUERY_SUBCOMMANDS`
in `run_evaluation.py` — this is verified by a cross-reference test.

`query_binary_version` is now `"git_sha"` (non-null), requiring artifact identity
to include a query binary version for reproducible provenance. The `combined`
condition stays pending (blocked on INDEX.md only, not arch-query). Its
`unavailable_reason` and `blocked_by` were updated to reflect this.

Manifest version bumped from `1.0.0` to `1.1.0` (minor: condition availability
change, no schema breaking changes).

### Validation evidence

| Command | Result |
|---------|--------|
| `python3 -m pytest tests/test_analyzer_assisted_evaluation.py tests/test_analyzer_assisted_planner.py tests/test_canary_report.py -v` | 188 passed |
| `python3 benchmark/analyzer-assisted-v1/validate.py` | PASS: 2 available (baseline, arch-query), 2 pending (index-md, combined) |
| `python3 benchmark/analyzer-assisted-v1/canary_report.py --validate-only` | PASS: No violations |
| `ruff check` (changed files) | All checks passed |
| `git diff --check` | No whitespace issues |
| `python3 benchmark/analyzer-assisted-v1/planner.py --condition arch-query --artifact-json ...` | available=true, 31 questions, Bash in tools_permitted |

### Files changed (this task only)

| File | Change |
|------|--------|
| `benchmark/analyzer-assisted-v1/experiment.json` | arch-query: available=true, Bash transport, provenance, evaluator constraint |
| `benchmark/analyzer-assisted-v1/README.md` | Updated availability table and documentation |
| `tests/test_analyzer_assisted_evaluation.py` | +8 tests: boundary, provenance, subcommand cross-ref |
| `tests/test_analyzer_assisted_planner.py` | +3 tests: real manifest arch-query planning, pending split |
| `tests/test_canary_report.py` | Updated canary planned/unavailable counts |

### Estimated cost

$0.00 — no agents, evaluations, or paid API calls. All validation is deterministic.
