# Milestone: Analyzer Ownership Migration V1

## Goal

Expand `src/arch-analyzer` ownership until every analyzer-sufficient component is
either safely analyzer-only or has a documented, source-backed reason requiring an
agent, then validate the final routing policy in production and reduce the
component-summary skill to those residual responsibilities.

## Result

The migration is accepted against the final production run at
`tmp/architecture-corpus-runs/rhoai.next-20260720T193556Z-104162`.

| Measure | Baseline | V1 final |
|---------|:--------:|---------:|
| Components | 90 | 90 |
| Analyzer-sufficient | 63 | 64 |
| Approved analyzer-only | 15 | 37 |
| Agent invocations | 75 | 53 |
| Workflow wall time | 1903.90s | 1546.70s |
| Wall-time reduction (from 1h reference) | 47.11% | 57.04% |
| Total cost | — | $69.61 |
| Output tokens | — | 650,020 |
| Analyzer identities retained | — | 8614/8618 (99.95%) |
| Unexplained conflicts | 0 | 0 |
| False nominations | 0 | 0 |
| Structurally valid documents | 90/90 | 90/90 |
| Synthesis/structure quality | 90/90 | 90/90 |

## Routing Policy

| Route | Components | Description |
|-------|:----------:|-------------|
| analyzer-only | 37 | Deterministic structured output, no agent invocation |
| evidence-gated (sufficient) | 27 | Agent synthesizes prose; structured facts analyzer-owned |
| evidence-gated (partial) | 18 | Agent fills gap categories under bounded budget |
| legacy (insufficient) | 8 | Full agent discovery with legacy fallback |

## Approved Analyzer-Only Components (37)

agents-operator, ai-gateway-operator, batch-gateway, codeflare-operator,
data-science-pipelines, data-science-pipelines-operator, feast,
fms-guardrails-orchestrator, gateway-api-inference-extension,
guardrails-regex-detector, kserve, kserve-autogluon-server, kube-rbac-proxy,
kubeflow, kuberay, kueue, llm-d-batch-gateway-operator, llm-d-inference-scheduler,
llm-d-router, mcp-lifecycle-module-operator, mcp-lifecycle-operator, mlflow-operator,
model-registry, model-registry-operator, modelmesh-serving, models-as-a-service,
odh-cli, odh-dashboard, odh-model-controller, ogx-k8s-operator, spark-operator,
trainer, trainer-operator, training-operator, trustyai-service-operator,
workbenches-operator, workload-variant-autoscaler.

## Residual Summary

| Disposition | Components | Unresolved mutations |
|-------------|:----------:|---------------------:|
| Deliberate prose residual | 1 | 0 |
| Adjudicated invalid evidence | 3 | 0 (25 adjudicated) |
| Empty categories — pending extraction | 1 | 0 |
| Empty categories — unsupported language | 1 | 0 |
| Pending Python runtime extraction | 3 | 13 |
| Go runtime source residual | 6 | 15 |
| Manifest/deployment residual | 4 | 18 |
| Python dependency declaration residual | 4 | 24 |
| Go gRPC residual | 1 | 8 |
| Notebook image inventory residual | 2 | 20 |
| **Total non-approved** | **26** | **99** |

One remaining reusable extraction tranche (Python runtime source surfaces) has a
focused pending task. All other residuals have named unsupported behavior with
source evidence.

## Known Limitations

- Conservative false negatives are accepted. Unsupported behavior is not
  reclassified as complete to increase the analyzer-only count.
- 99 unresolved mutations remain across 21 components. These represent genuinely
  unsupported extraction surfaces (Python import analysis, Go gRPC proto
  correlation, notebook image inventories, manifest-only deployment evidence).
- The skill still invokes agents for 53 components; further reduction requires
  implementing the Python runtime source extraction tranche or accepting the
  remaining residuals as permanent.

## Evidence

- Final production run: `tmp/architecture-corpus-runs/rhoai.next-20260720T193556Z-104162`
- Static replay authority: `tmp/architecture-corpus-runs/rhoai.next-20260720T173035Z-static/reports/eligibility-v1.json`
- Residual register: [Analyzer residual agent gaps](../notes/architecture-context-static-migration.md)
- Prioritization report: [Analyzer remaining candidate prioritization](../notes/architecture-context-static-migration.md)
- Approval registry: `lib/analyzer_only_approvals.json` (37 entries)
- Adjudication registry: `lib/analyzer_correction_adjudications.json` (70 entries)
- Pending extraction and residual coverage: [Architecture context static migration plan](../plans/architecture-context-static-migration.md)
- Ownership goal: [Architecture context static migration plan](../plans/architecture-context-static-migration.md)

## Status

Done on 2026-07-20.
