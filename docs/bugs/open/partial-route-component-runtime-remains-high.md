# Bug: Partial Route Component Runtime Remains High

## Summary

The latest 97-component `rhoai.next` generation run used the partial route for
all components, but several component agents still took 7 to 9 minutes each.
This indicates that analyzer-assisted generation has not yet delivered the
expected per-component runtime reduction.

## Evidence

Slowest component durations from `logs/generate-architecture/*.run.json`:

| Component | Duration |
|---|---:|
| `distributed-workloads` | 533s |
| `llm-d-inference-scheduler` | 484s |
| `codeflare-operator` | 472s |
| `llama-stack-provider-trustyai-garak` | 471s |
| `kube-auth-proxy` | 467s |
| `mlflow` | 460s |
| `eval-hub` | 458s |
| `mcp-lifecycle-module-operator` | 458s |
| `trainer` | 451s |
| `training-operator` | 447s |

The same run also recorded 64 oversized reads across 49 components and 250
denied tool calls, both of which likely contribute to runtime.

## Expected

Analyzer-assisted partial synthesis should reduce per-component runtime by
providing enough compact evidence that agents perform fewer exploratory reads,
fewer edits, and fewer denied tool attempts.

## Actual

Partial-route execution still spends several minutes per component on many
repositories, especially large or multi-language components.

## Impact

High. Long per-component runtime limits iteration speed and makes full
97-component experiments expensive even when the generated outputs are valid.

## Acceptance Criteria

- Runtime reports separate agent time into analyzer-context reading, targeted
  source reads, editing, sidecar writing, denied calls, and validation.
- The slowest components are mined for common missing evidence categories.
- Analyzer output is expanded where repeated source-read demand can be
  deterministically precomputed.
- A follow-up full run compares wall-clock and per-agent runtime against this
  run and identifies whether runtime materially improved.

## Status

Partially remediated on 2026-07-28 by
`docs/tasks/done/add-component-runtime-breakdown-reports.md`.

Each component `*.run.json` now includes a `runtime_breakdown` object with:

- agent activity counts for analyzer-context reads, targeted source reads,
  targeted discovery, architecture output edits, sidecar writes, and denied
  calls;
- denied-call categories;
- orchestrator timings for preseed, merge, merged-document validation,
  insight archive/validation, and source-read-justification validation.

This makes the next full run diagnosable, but the bug remains open until that
run proves whether runtime materially improved and identifies remaining
slow-component evidence gaps.
