# Bug: Partial Route Component Runtime Remains High

## Summary

A follow-up 97-component `rhoai.next` generation run materially improved
partial-route reliability and directional runtime indicators, but partial-route
component runtime remains high for a large minority of components. The
remaining bottleneck is agent API time caused by broad gap-category routing,
not merge or validation overhead.

## Evidence

The original high-runtime baseline is preserved under
`logs.bak/generate-architecture/*.run.json`. The follow-up run is under
`logs/generate-architecture/*.run.json` and includes `runtime_breakdown` plus
`source_read_justifications` for all 97 components.

The baseline is contaminated by 96 insight-artifact validation failures, as
documented in `docs/notes/partial-run-log-demand-report.md`, so runtime deltas
are directional rather than a clean success-to-success benchmark.

| Metric | Baseline | Follow-up |
|---|---:|---:|
| Components | 97 | 97 |
| Partial-route components | 96 | 97 |
| Legacy-route components | 1 | 0 |
| Successful components | 1 | 97 |
| Failed components | 96 | 0 |
| Average wall time | 591.8s | 308.9s |
| Median wall time | 579.1s | 301.5s |
| P90 wall time | 820.1s | 361.5s |
| Max wall time | 1218.7s | 650.9s |
| Components over 300s | 95 | 49 |
| Denied tool calls from run JSON telemetry | 354 | 167 |

Slowest follow-up components:

| Component | Duration | Source read operations | Denied calls | Gap categories |
|---|---:|---:|---:|---|
| `models-as-a-service` | 650s | 8 | 1 | authentication, integration_points, internal_dependencies, http_endpoints, grpc_services, services |
| `kubeflow-sdk` | 478s | 8 | 3 | authentication, internal_dependencies, grpc_services, ingress, egress, rbac_cluster_roles |
| `notebooks-downstream` | 443s | 7 | 1 | authentication, integration_points, internal_dependencies, http_endpoints, grpc_services, services |
| `argo-workflows` | 425s | 8 | 1 | authentication, integration_points, internal_dependencies, http_endpoints, grpc_services, services |
| `llm-d-inference-scheduler` | 418s | 20 | 3 | authentication, integration_points, internal_dependencies, http_endpoints, grpc_services, services |
| `ai-gateway-payload-processing` | 409s | 8 | 2 | authentication, integration_points, internal_dependencies, http_endpoints, grpc_services, services |
| `must-gather` | 391s | 8 | 3 | authentication, integration_points, internal_dependencies, http_endpoints, grpc_services, services |
| `odh-deployer` | 372s | 11 | 6 | authentication, integration_points, internal_dependencies, http_endpoints, grpc_services, services |
| `eval-hub` | 365s | 12 | 1 | authentication, integration_points, internal_dependencies, http_endpoints, grpc_services, services |
| `rhds-llama-stack-distribution` | 361s | 6 | 3 | authentication, integration_points, internal_dependencies, http_endpoints, grpc_services, services |

Among the 49 follow-up components still over 300s, routed gap categories remain
very broad: authentication appeared in 49, grpc_services in 48,
internal_dependencies in 46, http_endpoints in 45, integration_points in 44,
and services in 41.

The follow-up `runtime_breakdown` reports 29,867.6s of total agent API time
versus 5.6s of total merge/orchestrator time, so remaining runtime is dominated
by agent work rather than local validation or merge code.

## Expected

Analyzer-assisted partial synthesis should keep per-component runtime bounded
by providing enough compact evidence that agents receive narrow, concrete gap
categories and perform fewer exploratory reads, edits, and denied tool
attempts.

## Actual

Partial-route execution is much healthier than the baseline, but 49 of 97
components still exceed 300s. Most slow components receive the same broad
authentication, integration, dependency, endpoint, gRPC, and service gap
bundle, which leaves the agent to reconcile too much evidence during partial
synthesis.

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

Follow-up measured on 2026-07-30 by
`docs/tasks/done/measure-partial-route-runtime-follow-up.md` and recorded in
`docs/notes/partial-route-runtime-follow-up-2026-07-30.md`.

The bug remains open. Runtime indicators improved, but the next fix should
narrow partial-route gap selection and precompute compact evidence for the
repeated authentication, endpoint, gRPC, service, integration, and internal
dependency gap bundle. Track `models-as-a-service` and
`llm-d-inference-scheduler` as specific outliers.

2026-07-30 update: `docs/tasks/done/narrow-partial-route-gap-selection.md`
implemented route-planner narrowing. Category-specific partial coverage now
suppresses populated structural categories with only generic dynamic-resolution
limitations, while concrete unaccounted/unsupported limitations and partial
safety-critical category coverage remain routed. Empty baseline tables no
longer nominate every low-priority category by themselves.

Local policy simulation over the current 97 `architecture/rhoai.next` analyzer
artifacts reduced the routed six-gap distribution from the measured follow-up's
97/97 six-category runs to 23/97 six-category policies under the new planner.
Representative slow components now route as:

| Component | Routed gaps after narrowing |
|---|---|
| `models-as-a-service` | authentication, integration_points, internal_dependencies, grpc_services |
| `llm-d-inference-scheduler` | authentication, integration_points, services |
| `odh-deployer` | authentication, integration_points, internal_dependencies, http_endpoints, grpc_services, services |
| `eval-hub` | authentication, integration_points, internal_dependencies, grpc_services, services |

The bug remains open pending a generation rerun or representative replay that
proves wall-time improvement.
