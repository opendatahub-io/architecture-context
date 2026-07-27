# Task: Enable Partial Routing in the `all` Command

## Goal

Make `uv run main.py all ...` use the same analyzer-assisted bounded partial
routing as the standalone `generate-architecture` command and the scripted
full-run launcher.

## Context

`run_all_phases()` constructs `generate_arch_args` without
`evidence_gated_merge`. `run_generate_architecture_phase()` therefore treats
the missing attribute as `False`, silently selecting legacy routing for every
component. The `all` command must default evidence-gated routing on.

## Scope

- Add `--evidence-gated-merge/--no-evidence-gated-merge` to the `all` parser,
  defaulting to enabled.
- Propagate the parsed value into `generate_arch_args`.
- Preserve explicit `--no-evidence-gated-merge` legacy behavior.
- Add focused CLI/orchestration regression tests proving the default and
  explicit opt-out behavior.
- Update relevant CLI documentation/help text and this task/PLAN state.

## Exclusions

- Do not change routing policy semantics, analyzer extraction, generated
  architecture outputs, MLflow/OTel/API capture, or model selection.
- Do not read, stage, or modify prior architecture documents.
- Do not modify unrelated user changes or commit generated outputs.
- Implementation agent must not commit.

## Acceptance Criteria

- [x] `main.py all --help` documents evidence-gated routing enabled by default.
- [x] `run_all_phases()` passes the flag into the Phase 3 argument namespace.
- [x] Default `all` execution uses `readiness_routing=True`.
- [x] Explicit `--no-evidence-gated-merge` preserves legacy routing.
- [x] Focused regression tests pass and no generated outputs are changed.

## Validation

```bash
PYTHONPATH=. ./.venv/bin/pytest -q tests/test_cli.py tests/test_architecture_routing.py
git diff --check
```

## Status

Complete — `--evidence-gated-merge/--no-evidence-gated-merge` added to the `all`
parser (default: enabled), propagated through `run_all_phases()` into
`generate_arch_args`, and covered by 4 focused regression tests (2 in
test_cli.py, 2 in test_architecture_routing.py). 101 tests pass.

## Driver Review

Accepted after independent validation:

```text
PYTHONPATH=. ./.venv/bin/pytest -q tests/test_cli.py tests/test_architecture_routing.py tests/test_context_telemetry.py
101 passed in 0.52s
git diff --check
clean for task-scoped files
```

Generated architecture and unrelated working-tree changes were excluded from
the checkpoint.
