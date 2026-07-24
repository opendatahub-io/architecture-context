# Task: Classify Remaining Analyzer-Sufficient Components

## Goal

Produce an exhaustive, source-backed, ranked work queue for every deterministic
analyzer-sufficient component that remains unapproved after the completed `odh-cli`
tranche.

## Context

The authoritative post-`odh-cli` replay contains 64 analyzer-sufficient components:
34 approved, 29 false candidates, and one structurally eligible component retained
for prose. Of the 29 false candidates, 26 carry 168 unresolved structured mutations;
three are blocked only by category completeness. The previous 8/40 plus 21 split was
based on a stale pre-snapshot classification and must not be used.

This task is analysis and planning. It does not itself approve components or change
extractor behavior.

## Authoritative Inputs

- Accepted baseline:
  `tmp/architecture-corpus-runs/rhoai-next-20260718T215431Z`
- Post-`odh-cli` static replay:
  `tmp/architecture-corpus-runs/rhoai-next-cli-kubernetes-static-20260719T180727Z`
- Eligibility report:
  `tmp/architecture-corpus-runs/rhoai-next-cli-kubernetes-static-20260719T180727Z/reports/analyzer-only-eligibility.json`
- Fresh analyzer JSON:
  `tmp/architecture-corpus-runs/rhoai-next-cli-kubernetes-static-20260719T180727Z/analyzer/rhoai.next/`
- Fresh merge reports:
  `tmp/architecture-corpus-runs/rhoai-next-cli-kubernetes-static-20260719T180727Z/logs/agents/`
- Residual register: `docs/notes/analyzer-residual-agent-gaps.md`

Do not substitute the older
`rhoai-next-go-http-auth-static-20260719T173651Z` eligibility report; its correction
counts were calculated before the fresh analyzer snapshot was supplied.

## Required Inventory

| Component | Resolved/total | Unresolved | Blocking categories | Historical time | Cost |
|-----------|---------------:|-----------:|---------------------|----------------:|-----:|
| `MLServer` | 0/6 | 6 | Authentication, Integration Points, Internal Dependencies | 329.14s | $1.3602 |
| `NeMo-Guardrails` | 0/4 | 4 | Integration Points, Internal Dependencies | 156.57s | $0.9981 |
| `ai-gateway-payload-processing` | 0/5 | 5 | Architecture Components, Authentication | 187.41s | $0.9432 |
| `argo-workflows` | 0/5 | 5 | Authentication, Internal Dependencies | 233.73s | $1.1690 |
| `caikit-tgis-serving` | 0/6 | 6 | Authentication, Integration Points, Internal Dependencies | 220.43s | $0.8617 |
| `caikit` | 0/7 | 7 | Authentication, Integration Points, Internal Dependencies | 205.23s | $1.0568 |
| `codeflare-sdk` | 0/7 | 7 | Authentication, Integration Points, Internal Dependencies | 234.05s | $0.8588 |
| `distributed-workloads` | 0/3 | 3 | Authentication, Internal Dependencies | 219.31s | $1.0615 |
| `eval-hub` | 0/8 | 8 | Architecture Components, Authentication, Internal Dependencies | 203.29s | $0.9234 |
| `guardrails-regex-detector` | 0/0 | 0 | Integration Points | 149.98s | $0.6013 |
| `kube-auth-proxy` | 0/2 | 2 | Authentication, Internal Dependencies | 198.96s | $0.8646 |
| `kubeflow-sdk` | 0/14 | 14 | Authentication, Integration Points, Internal Dependencies | 208.10s | $1.0700 |
| `llm-d-async` | 0/4 | 4 | Authentication, Internal Dependencies | 351.29s | $1.0814 |
| `llm-d-batch-gateway-operator` | 2/4 | 2 | Internal Dependencies | 242.35s | $1.0450 |
| `llm-d-kv-cache` | 0/4 | 4 | Authentication, Internal Dependencies | 227.65s | $1.0122 |
| `llm-d-latency-predictor` | 0/3 | 3 | Integration Points, Internal Dependencies | 194.77s | $1.8426 |
| `llm-d-planner` | 0/12 | 12 | Integration Points, Internal Dependencies | 242.18s | $1.0245 |
| `llm-d-routing-sidecar` | 0/2 | 2 | Authentication, Internal Dependencies | 193.50s | $0.7429 |
| `lm-evaluation-harness` | 0/4 | 4 | Authentication, Internal Dependencies | 222.34s | $1.0793 |
| `mlflow` | 0/4 | 4 | Authentication, Internal Dependencies | 211.08s | $0.9679 |
| `model-registry` | 2/2 | 0 | Internal Dependencies | 202.91s | $1.0476 |
| `modelmesh-runtime-adapter` | 0/10 | 10 | Integration Points, Internal Dependencies | 226.87s | $1.0727 |
| `notebooks-downstream` | 0/17 | 17 | Authentication, Integration Points, Internal Dependencies | 199.24s | $1.2945 |
| `notebooks` | 0/19 | 19 | Authentication, Integration Points, Internal Dependencies | 298.00s | $1.8169 |
| `ogx` | 0/0 | 0 | Authentication, Internal Dependencies | 168.16s | $0.7168 |
| `rhaii-cluster-validation` | 0/5 | 5 | Architecture Components, Authentication, Internal Dependencies | 180.99s | $1.2173 |
| `rhoai-mcp` | 0/2 | 2 | Authentication | 236.97s | $0.8408 |
| `trustyai-explainability` | 0/9 | 9 | Authentication, Integration Points, Internal Dependencies | 239.79s | $0.8513 |
| `vllm-cpu` | 0/4 | 4 | Authentication, Integration Points, Internal Dependencies | 196.66s | $1.1226 |

The completeness-only cases are `guardrails-regex-detector`, `model-registry`, and
`ogx`. `model-registry` has already resolved 2/2 accepted corrections but its
Internal Dependencies category is not complete. Every other row requires correction
audit as well as category-completeness analysis.

## Required Output

Create `docs/notes/analyzer-remaining-candidate-prioritization-<date>.md`. For every
one of the 29 components, record:

| Field | Requirement |
|-------|-------------|
| Replay state | Candidate, approval, readiness, and blocking high-value categories |
| Correction state | Accepted, resolved, unresolved, and source-adjudicated counts |
| Evidence | Exact merge-report and analyzer JSON paths, plus source locations where audited |
| Repository shape | Languages, frameworks, shipped entrypoints, manifests, and relevant runtime surfaces |
| Likely contract | Generic extraction or completeness contract that could close the gap |
| Negative controls | Concrete false-positive cases the contract must reject |
| Value | Historical duration, cost, reads, source files, output tokens, and reuse across components |
| Risk | Dynamic dispatch, generated code, examples, docs, test-only evidence, or unsupported language |
| Disposition | Extractor tranche, completeness audit, source adjudication, or justified agent residual |

Cluster components by reusable correction pattern before ranking them. Rank using
expected avoided worker time/cost, corpus reuse, implementation complexity, and
false-positive risk. High correction count alone is not sufficient.

## Acceptance Criteria

- [ ] Use the post-`odh-cli` replay and record its exact path.
- [ ] Account for all 29 false candidates exactly once.
- [ ] Reconcile the 26 correction-bearing components and all 168 unresolved
  structured mutations.
- [ ] Reconcile the three completeness-only components.
- [ ] Audit historical evidence that relies only on `go.mod`, generated proto,
  examples, docs, or tests before treating it as extractor ground truth.
- [ ] Group candidates into reusable extractor/completeness patterns.
- [ ] Produce a ranked queue with explicit value, reuse, complexity, and safety
  reasoning.
- [ ] Name the next three bounded tranches and link existing focused task files.
- [ ] Update the residual register and `PLAN.md` if classification changes their
  evidence or ordering.
- [ ] Do not add approvals, weaken completeness, or introduce component-name
  exceptions as part of classification.

## Handoff Procedure

1. Read the active goal, this task, and the residual register.
2. Query the authoritative eligibility JSON; do not infer state from Markdown table
   emptiness or older reports.
3. Inspect each component's fresh analyzer JSON and merge report.
4. Source-audit ambiguous corrections before assigning a reusable tranche.
5. Write the prioritization note and reconcile the register.
6. Leave analyzer implementation to focused task files.

Focused tasks already available:

- [Extract Eval Hub runtime boundaries](../pending/extract-eval-hub-runtime-boundaries.md)
- [Extract ModelMesh runtime relationships](../pending/extract-modelmesh-runtime-relationships.md)

## Output

[Analyzer remaining candidate prioritization, 2026-07-19](../../notes/analyzer-remaining-candidate-prioritization-2026-07-19.md)

## Status

Done.
