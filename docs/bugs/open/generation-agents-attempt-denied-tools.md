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
