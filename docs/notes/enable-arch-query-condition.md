# Enable the Implemented arch-query Experiment Condition

Reconciled the analyzer-assisted experiment manifest with the reviewed
arch-query evaluator boundary so the `arch-query` condition is accurately
available while keeping INDEX.md and combined conditions unavailable.

## Scope

- Marked `arch-query` as `available: true, status: available` in the
  experiment manifest (`experiment.json` v1.1.0).
- Kept `index-md` and `combined` conditions pending/unavailable.
- Documented the restricted Bash/query evaluator boundary: Bash is the
  transport, but only constrained bare `arch-query query` commands with
  approved subcommands, explicit `-o json`, and `--base-dir` inside the
  evaluated tree are accepted. Arbitrary Bash, shell metacharacters,
  source access, and writes are denied.
- Required `query_binary_version: "git_sha"` provenance for reproducible
  artifact identity.

## Manifest availability decision

Only `arch-query` was enabled because it has a reviewed, guarded evaluator
boundary in `run_evaluation.py`. The `index-md` condition lacks an
implementation. The `combined` condition is blocked on `index-md` only
(not on `arch-query`); its `unavailable_reason` and `blocked_by` were
updated to reflect this dependency.

## Bash/query boundary

`tools_permitted: [Read, Glob, Grep, Bash]` and `tools_denied: [Write, Edit]`.
The `evaluator_bash_constraint` field in the manifest documents the guard
rules that `run_evaluation.py` enforces:

- Bare `arch-query query` invocations only (no pipelines, redirects, or
  shell operators).
- Approved subcommands matching `APPROVED_QUERY_SUBCOMMANDS` in the
  evaluator (cross-referenced by test).
- Explicit `-o json` and `--base-dir` inside the evaluated tree required.

## Provenance decision

`query_binary_version` changed from `null` to `"git_sha"`, requiring
artifact identity to include a query binary version. This ensures
reproducible provenance for evaluation results tied to a specific build.

## Validation evidence

| Command | Result |
|---------|--------|
| `uv run pytest -q tests/test_analyzer_assisted_evaluation.py tests/test_analyzer_assisted_planner.py tests/test_canary_report.py tests/test_query_eval_boundary.py tests/test_condition_aware_runner.py` | 277 passed |
| `python3 benchmark/analyzer-assisted-v1/validate.py` | PASS: 2 available (baseline, arch-query), 2 pending (index-md, combined) |
| `python3 benchmark/analyzer-assisted-v1/canary_report.py --validate-only` | PASS: No violations |
| `ruff check` (changed files) | All checks passed |
| `git diff --check` | No whitespace issues |

## No-evaluation evidence

No evaluation, agent, benchmark, or paid API call was run. All validation
is deterministic. Estimated cost: $0.00.
