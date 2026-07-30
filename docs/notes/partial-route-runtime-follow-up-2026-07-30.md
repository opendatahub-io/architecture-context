# Partial Route Runtime Follow-up - 2026-07-30

## Scope

Compared the prior 97-component baseline preserved under
`logs.bak/generate-architecture/*.run.json` against the follow-up full run
under `logs/generate-architecture/*.run.json`.

The follow-up run contains `runtime_breakdown` and
`source_read_justifications` for all 97 components. The baseline run did not
contain `runtime_breakdown`, so baseline comparison is limited to run-level
duration, success, route, and aggregate denied-call telemetry.

The baseline is the same run mined in
`docs/notes/partial-run-log-demand-report.md`: 96 components failed
insight-artifact validation after producing component documents, so runtime
comparison is directional rather than a clean success-to-success benchmark.

## Result

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

The follow-up materially improved reliability: all components now succeed.
Runtime indicators also improved: average wall time dropped by 47.8%, P90
dropped by 55.9%, and the count of components over 300s dropped from 95 to 49.
Because the baseline was contaminated by validation failures, treat the runtime
delta as directional evidence rather than a clean benchmark.

The high-runtime bug should remain open. The slowest follow-up components still
spend almost all wall time in the agent API. Across the follow-up run,
`runtime_breakdown` reported 29,867.6s of agent API time versus 5.6s of total
merge/orchestrator time.

## Remaining Slow Components

| Component | Follow-up duration | Source read operations | Denied calls | Gap categories |
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

Among the 49 components still over 300s, the most common routed gap categories
were:

| Gap category | Slow-component count |
|---|---:|
| authentication | 49 |
| grpc_services | 48 |
| internal_dependencies | 46 |
| http_endpoints | 45 |
| integration_points | 44 |
| services | 41 |
| ingress | 12 |
| egress | 7 |

## Interpretation

The completed runtime-breakdown work made the run diagnosable and the latest
full run proves a real reliability improvement. Runtime indicators improved as
well, but the baseline failure mode prevents a clean like-for-like runtime
claim. The remaining bottleneck is not merge, validation, or orchestration
overhead. It is the amount of reasoning the agent still performs when partial
routing hands it a broad six-category gap set.

The next fix should target evidence selection and route narrowing:

- Stop routing every generic partial category when the analyzer already has
  enough specific evidence for that category.
- Precompute and render compact endpoint, service, authentication, and internal
  dependency evidence for components that repeatedly receive the six-category
  gap bundle.
- Investigate `models-as-a-service` separately: it used only 8 source reads and
  1 denied call but still took 650s, so its cost appears to be prompt/evidence
  size or synthesis reasoning rather than tool-loop churn.
- Investigate `llm-d-inference-scheduler` separately: it recorded 20 source
  read operations despite an 8-file budget, plus a missing source-read
  justification diagnostic for `pkg/epp/server/controller_config.go`.

## Decision

Do not close `partial-route-component-runtime-remains-high.md` yet. Update it
from a broad "partial runtime is high" bug to a narrower "partial route still
passes overly broad gap categories and leaves agent API time high" bug.
