# Task: Add Targeted Pipeline Subcommand

## Goal

Add a CLI path for targeted multi-phase, multi-component runs so runtime
experiments can replay representative components without running the full
platform pipeline.

## Context

The next validation step for
`docs/bugs/open/partial-route-component-runtime-remains-high.md` is a
representative replay for `models-as-a-service`,
`llm-d-inference-scheduler`, `eval-hub`, and `odh-deployer`. Existing phase
commands accept only one `--component`, and `all` always constructs full-scope
phase arguments.

## Plan

1. Add a `pipeline` subcommand with repeated `--phase`, `--component`, and
   `--repo` filters.
2. Implement orchestration by looping existing phase functions with
   single-component namespaces.
3. Use a pipeline-specific log directory for generation runs.
4. Add a root `custom-test.sh` for the current four-component runtime replay.
5. Add focused CLI/orchestration tests.

## Acceptance Criteria

- `uv run main.py pipeline --phase ... --component ...` parses and dispatches.
- `--repo` filters resolve to component keys from `component-map.json`.
- Targeted component phases execute in phase order without changing existing
  single-phase command behavior.
- `custom-test.sh` runs the current representative replay command.
- Focused tests pass.

## Status

Completed on 2026-07-30.

Implemented:

- Added `uv run main.py pipeline` with repeated `--phase`, `--component`, and
  `--repo` selectors.
- Resolved `--repo` selectors through `component-map.json` using component key,
  repo name, `org/repo`, or repo URL tail.
- Dispatched component-scoped phases by looping existing single-component phase
  functions in the requested phase order.
- Added timestamped default generation logs under
  `logs/pipeline/<timestamp>/generate-architecture`.
- Added root `custom-test.sh` for the current four-component replay:
  `models-as-a-service`, `llm-d-inference-scheduler`, `eval-hub`, and
  `odh-deployer`.

Validation:

```bash
uv run pytest tests/test_cli.py tests/test_pipeline_orchestration.py -q
uv run python -m py_compile lib/cli.py lib/phases/orchestration.py
bash -n custom-test.sh
```

Result: all passed.
