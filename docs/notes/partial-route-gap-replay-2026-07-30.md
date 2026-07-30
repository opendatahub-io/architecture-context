# Partial Route Gap Replay - 2026-07-30

## Scope

Compared the targeted replay under
`logs/pipeline/partial-route-gap-replay-20260730T025831Z/generate-architecture/`
against the previous full-run baseline under `logs/generate-architecture/`.

Components:

- `models-as-a-service`
- `llm-d-inference-scheduler`
- `eval-hub`
- `odh-deployer`

## Result

All four targeted component runs succeeded.

| Component | Gap count | Duration | Targeted source reads | Denied calls | Diagnostics |
|---|---:|---:|---:|---:|---:|
| `models-as-a-service` | 6 -> 4 | 650s -> 260s (-61%) | 8 -> 6 | 1 -> 0 | 0 -> 0 |
| `llm-d-inference-scheduler` | 6 -> 3 | 418s -> 257s (-39%) | 20 -> 4 | 3 -> 0 | 1 -> 0 |
| `eval-hub` | 6 -> 5 | 365s -> 287s (-22%) | 12 -> 7 | 1 -> 0 | 0 -> 0 |
| `odh-deployer` | 6 -> 6 | 372s -> 279s (-25%) | 11 -> 11 | 6 -> 5 | 0 -> 1 |

## Interpretation

The replay supports the route-planner change. The three components with
narrowed gap lists all reduced wall time, agent API time, targeted source
reads, and denied calls. `llm-d-inference-scheduler` is the clearest win: the
policy dropped from six gaps to three, targeted reads dropped from 20 to 4, and
the prior missing-justification diagnostic disappeared.

`odh-deployer` also improved despite retaining the same six gaps and source-read
count. That means some runtime improvement is likely due to run-to-run variance,
static-analysis refresh, or generated-output state, not solely the gap-selection
change. It remains a useful control case because it still records 5 denied
calls and one missing source-read justification for `Dockerfile`.

## Decision

Keep `docs/bugs/open/partial-route-component-runtime-remains-high.md` open
pending a larger generation rerun or full 97-component runtime comparison. The
targeted replay is strong enough to justify running the broader validation.
