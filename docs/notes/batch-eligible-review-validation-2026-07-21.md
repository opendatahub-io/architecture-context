# Batch Eligible Component Review Validation

Date: 2026-07-21

## Summary

The kube-auth-proxy shell script classification fix caused 11 additional
components to pass the eligibility check. On investigation, **9 of 11 were
false positives** caused by running the eligibility check against
`GENERATED_ARCHITECTURE.md` (agent-written) instead of
`ANALYZER_ARCHITECTURE.md` (Go binary output).

Outcome: 1 approved (kubeflow-sdk), 1 technically eligible but not approved
(rhods-operator — permanent residual), 9 false positives documented.

## Baseline Discrepancy

The ad-hoc eligibility check used `architecture/rhoai.next/<component>.md`
files, which are collected from `GENERATED_ARCHITECTURE.md` in the checkout
directories. For non-analyzer-only components, these contain agent-written
content from prior full corpus runs. The production routing code
(`load_architecture_agent_policy` at `lib/architecture_routing.py:258`)
correctly reads `ANALYZER_ARCHITECTURE.md` — the Go binary's output.

For the 51 previously approved components, both baselines agree: the agent
enriched existing analyzer-populated tables but did not create categories
from nothing. For the 9 false-positive newcomers, the agent filled empty
categories that the analyzer does not populate.

**Future ad-hoc eligibility checks must use `ANALYZER_ARCHITECTURE.md` from
the checkout directories, not the collected `architecture/rhoai.next/` files.**

## Per-Component Analysis

### Approved: kubeflow-sdk (52nd component)

ANALYZER_ARCHITECTURE.md table rows: auth=1, integration=1, internal_deps=1.

All high-value categories populated by the analyzer:
- `authentication`: 1 row — Kubernetes API Server kubeconfig auth
- `integration_points`: 1 row — Kubernetes API (complete-empty contract also
  available but unnecessary since the analyzer produces a row)
- `internal_dependencies`: 1 row — training-operator (from platform alias scan)
- `architecture_components`: 1 row

The `integration_points` category also passes the complete-empty contract
(status=complete, fact_count=0, no limitations), providing a fallback.

Previously blocked because import analysis returned nothing (uses setup.py,
not pyproject.toml). The shell script fix removed unsupported-language
limitations that were creating coverage gaps in categories that the
analyzer already populated.

### Not approved: rhods-operator (permanent residual — deliberate prose)

ANALYZER_ARCHITECTURE.md table rows: auth=5, integration=132, internal_deps=4.

Technically eligible — the analyzer populates all four high-value categories.
However, rhods-operator is classified as a **permanent agent residual** for
"deliberate prose" reasons: the agent produces hierarchical lifecycle
narrative with cross-component orchestration context that the analyzer
cannot replicate. The analyzer's 132 integration point rows are mechanical
controller-watch-target expansions, while the agent synthesizes meaningful
lifecycle relationships.

**Decision**: Not approved. The permanent residual classification addresses
generation quality, not eligibility criteria. Eligibility gates on whether
the analyzer populates the table structure; generation quality requires
the agent's contextual synthesis.

### Not approved: notebooks (permanent residual — non-runtime evidence model)

ANALYZER_ARCHITECTURE.md table rows: auth=1, integration=0, internal_deps=0.

Not eligible against analyzer baseline (integration_points and
internal_dependencies are empty). The single auth fact is a false positive
from a CI test script (make_test.py:174 misidentified as a web app).

The permanent residual classification ("non-runtime evidence model, 19
mutations from requirements.txt bundled-library inventory") remains valid.
The agent's 23 markdown rows were synthesized from requirements.txt files
and CI scripts, not from analyzer structured data.

### False positives (9 components)

These components appeared eligible because the eligibility check read
agent-generated GENERATED_ARCHITECTURE.md (with agent-written table rows)
instead of ANALYZER_ARCHITECTURE.md (Go binary output with empty tables
in one or more high-value categories).

| Component | Empty HV in analyzer MD | Prior blocker | Status |
|-----------|------------------------|---------------|--------|
| MLServer | authentication (0 rows) | 16 inbound gRPC, no auth facts | Unchanged — auth gap remains |
| caikit | authentication (0 rows) | 16 inbound gRPC, no auth facts | Unchanged — auth gap remains |
| caikit-tgis-backend | authentication (0 rows) | 4 inbound gRPC, no auth facts | Never scoped; auth gap |
| llama-stack-provider-trustyai-garak | authentication (0 rows) | 3 credential refs, no auth facts | Never scoped; auth gap |
| pipelines-components | authentication (0 rows) | 8 credential refs, no auth facts | Never scoped; auth gap |
| rhoai-mcp | authentication (0 rows) | 3 inbound MCP, no auth facts | MCP handler gap remains |
| llm-d-kv-cache | authentication (0), internal_deps (0) | 6 inbound, unresolved interceptors | Two gaps remain |
| llm-d-routing-sidecar | internal_dependencies (0 rows) | Unresolved kustomize template vars | internal_deps gap remains |

All 9 remain ineligible when checked against the correct baseline. Their
prior blockers are unchanged by the shell script classification fix.

## Verification

### Eligibility check

All 52 approved components verified against ANALYZER_ARCHITECTURE.md from
checkout directories:
```
Checked 52/52 approved components against ANALYZER_ARCHITECTURE.md
Zero regressions. All checked components remain eligible.
```

### Approval counts

| State | Count |
|-------|------:|
| Analyzer-sufficient | 68 |
| Approved analyzer-only | 52 |
| Permanent agent residual | 4 |
| Ineligible (bounded correction gaps) | 12 |
