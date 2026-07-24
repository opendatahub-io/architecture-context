# Task: Eliminate Redundant Sufficient-Route Agent Passes

## Goal

Reduce component-generation wall time and cost by allowing an explicitly safe subset
of analyzer-sufficient repositories to produce complete agent-facing Markdown
without an Opus repository-reading pass.

## Context

The accepted 90-component run `rhoai-next-20260718T200215Z` completed in 33.11
minutes for $101.1090. Static analysis took only 13.74 seconds; the 90 component
agents consumed almost all remaining time and cost.

Of the 63 analyzer-sufficient components, 18 agents produced no accepted structured
architecture mutation. Those 18 passes cost $15.5726 in aggregate and spent a
summed 2,568.64 agent-seconds primarily generating prose and source inventory. This
is a measured optimization opportunity, not proof that those same components can be
skipped based only on historical output.

The next route must be selected from current analyzer coverage and document shape,
not a hard-coded component list or knowledge of a previous agent result. Markdown
remains the contract for downstream agents and humans, so a static-only route must
still produce useful Purpose, Data Flows, and Architectural Analysis sections.

## Acceptance Criteria

- [x] Classify the 63 sufficient components in the accepted full run by accepted
      structured mutations, synthesis work, source reads, duration, tokens, and cost.
- [x] Define a conservative analyzer-only eligibility policy using current coverage
      signals and populated structured categories rather than component names or
      prior agent outcomes.
- [x] Demonstrate zero false analyzer-only nominations against components that made
      source-backed structured corrections in the accepted full run; low initial
      recall is acceptable.
- [x] Add deterministic Markdown synthesis for eligible components, derived only
      from typed analyzer facts and their evidence, with no fabricated claims.
- [x] Keep all required headings and tables and populate Purpose, Data Flows, and
      Architectural Analysis with useful agent-facing Markdown rather than pending
      placeholders.
- [x] Preserve the existing evidence-gated sufficient/partial routes and the legacy
      insufficient fallback for every component that is not analyzer-only eligible.
- [x] Add routing, rendering, structural, preservation, and quality regression tests
      for the new route.
- [x] Run a bounded same-revision matrix containing at least two eligible candidates,
      one sufficient component with source-backed structured corrections, and one
      partial or insufficient control.
- [x] Compare matrix output to the accepted Opus documents by structured facts and a
      documented synthesis review; do not use exact prose equality as the gate.
- [x] Record wall time, agent count, tool calls, source reads, tokens, and cost, and
      project platform-scale savings before deciding on another 90-component run.

## Initial Evidence

The 18 sufficient components with zero accepted structured mutations in the accepted
run are:

`agents-operator`, `codeflare-operator`, `data-science-pipelines`,
`data-science-pipelines-operator`, `fms-guardrails-orchestrator`, `kserve`,
`kserve-autogluon-server`, `kube-rbac-proxy`, `kubeflow`, `kueue`,
`lm-evaluation-harness`, `model-registry-operator`, `modelmesh-serving`,
`odh-dashboard`, `odh-model-controller`, `ogx-k8s-operator`, `trainer`, and
`training-operator`.

These are an evaluation set, not an allowlist. The eligibility policy must explain
why a repository can bypass source-reading synthesis from its fresh analyzer output.

## Candidate Matrix

| Component | Role |
|-----------|------|
| `odh-dashboard` | High-fidelity eligible candidate and established control |
| `kueue` | Large operator eligible candidate |
| `eval-hub` | Sufficient component with source-backed structured corrections |
| `batch-gateway` | Partial-route control that must retain bounded discovery |

The final matrix may substitute components when the eligibility policy provides a
better boundary case, but it must retain all four roles.

## Non-Goals

- Do not remove Markdown or replace it with JSON as the downstream contract.
- Do not weaken analyzer preservation, evidence requirements, or quality gates.
- Do not broaden repository discovery.
- Do not hard-code routing by component name.
- Do not change `PLATFORM.md` synthesis or diagrams.
- Do not launch a full paid corpus before the bounded matrix is reviewed.

## Related

- [Full-corpus routing validation](../../notes/rhoai-next-routing-coverage-full-corpus-2026-07-18.md)
- [Completed routing coverage task](../done/improve-readiness-routed-synthesis-coverage.md)
- [Component analyzer migration plan](../../plans/component-analyzer-migration.md)
- [Analyzer-only routing matrix](../../notes/analyzer-only-routing-matrix-2026-07-18.md)

## Status

Completed on 2026-07-18.

## Results

The reference classifier nominated 15 of 63 sufficient components with zero false
nominations and 83.33% recall of the observed zero-mutation set. Their accepted-run
passes represented $13.0212, 2,034.82 summed agent-seconds, 119 reads, 60 source
files, and 87,810 output tokens. The 10-worker schedule projection reduces the agent
phase by 214.94 seconds (10.93%).

The same-commit Opus matrix routed `kueue` and `odh-dashboard` analyzer-only while
retaining evidence-gated agents for `eval-hub` and `batch-gateway`. It preserved
652/652 analyzer identities and 577/577 accepted Opus structured rows for the
analyzer-only pair, passed structural and synthesis-quality gates for all four
documents, and reduced matrix agent invocations by 50% and cost by 40.37%. The
permanent matrix note records provenance, synthesis review, execution metrics, and
the decision to permit a separately reviewed full production validation.

The subsequent [full-corpus production validation](../../notes/analyzer-only-full-corpus-production-validation-2026-07-18.md)
selected all 15 nominated components, retained 2,460/2,460 accepted structured rows
for them with no conflicts, and passed all 90 structural, synthesis, and preservation
gates. Compared with the reference run, it removed 15 agent invocations, $12.0144,
129 reads, and 75 source-file reads. The direct workflow was 82.80 seconds faster;
a route-isolated 10-worker counterfactual estimates 199.43 seconds (9.56%) avoided.
