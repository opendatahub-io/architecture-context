# Bug: Generation Agents Attempt Denied Tools During Partial Runs

## Summary

The latest 97-component `rhoai.next` generation run succeeded, but every
component recorded at least one denied tool call. Across the run there were 250
denied calls.

The most common denial was `TodoWrite`, which is not needed for the component
generation workflow. Other denials included `Glob`, `Grep`, `Bash`, and `Read`
when agents tried to step outside the allowed route boundaries.

## Evidence

The run reports under `logs/generate-architecture/*.run.json` recorded:

- 97 components with denied tool calls.
- 250 total denied calls.
- Highest examples:
  - `vllm-rocm`: 8 denials
  - `vllm-spyre`: 8 denials
  - `odh-deployer`: 6 denials
  - `openvino_model_server`: 6 denials
  - `vllm`: 6 denials
  - `kube-auth-proxy`: 5 denials
  - `must-gather`: 5 denials
  - `odh-gitops`: 5 denials

## Expected

Partial-route prompts and allowed-tool configuration should make the available
workflow clear enough that agents do not repeatedly attempt denied tools.
Planning should be done in prose or omitted; component agents do not need
`TodoWrite`.

## Actual

Denied calls are normal in the current run profile. They add turns, increase
runtime, and make logs noisier.

## Impact

Medium. Denials do not currently fail generation, but they waste model turns
and obscure meaningful permission-boundary violations.

## Acceptance Criteria

- Component-generation prompts explicitly tell agents not to use `TodoWrite`.
- The generation launch path removes or blocks unnecessary planning tools when
  possible.
- Denied tool summaries distinguish expected guardrail denials from avoidable
  workflow noise.
- A focused replay shows `TodoWrite` denials eliminated and total denials
  materially reduced.

## Status

Fixed on 2026-07-28 by
`docs/tasks/done/fix-partial-route-denied-tool-noise.md`.

Component-generation route guidance now explicitly forbids `TodoWrite`.
Restricted `run_agent` SDK options exclude `TodoWrite`, `Task`, and `Bash`.
If a model still attempts `TodoWrite`, the guard returns a targeted denial
reason and telemetry records it as `workflow-noise` with
`avoidable_workflow_denials`.

Validation passed:

```bash
uv run ruff check lib/agent_runner.py tests/test_agent_runner.py
uv run pytest -q tests/test_agent_runner.py
uv run pytest -q tests/test_architecture_phase.py
uv run pytest -q tests/test_agent_runner.py tests/test_source_read_justifications.py tests/test_architecture_phase.py
```

The historical full-run logs are unchanged and still contain the old
97-component `TodoWrite` denial baseline. The fix is enforced for future
partial-route generation runs; attempted `TodoWrite` calls are now explicitly
categorized as avoidable workflow noise.
