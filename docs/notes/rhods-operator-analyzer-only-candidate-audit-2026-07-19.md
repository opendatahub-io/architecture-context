# rhods-operator Analyzer-Only Candidate Audit, 2026-07-19

## Decision

Keep `rhods-operator` agent-routed. Dynamic GVK extraction made it a semantic
candidate because the analyzer now emits one OpenShift cluster-configuration
dependency, but that predicate is not sufficient evidence for this repository.
No rollout approval was added and no paid matrix was run.

The accepted Internal Platform Dependencies table is empty and has no accepted
structured corrections. Component CRDs, watches, and client operations are already
retained as 129 structured integration points; they are self-owned orchestration
surfaces rather than external platform dependencies.

## Residual Agent Responsibility

The accepted agent synthesis adds source-backed relationships that are not presently
expressed by deterministic prose adaptation:

- `internal/controller/datasciencecluster/datasciencecluster_controller.go:70-94`
  establishes the ordered DataScienceCluster reconciliation actions;
- `datasciencecluster_controller_actions.go:70-111` iterates enabled component
  handlers, constructs each component CR, and adds it to the reconciliation output;
- `api/components/v1alpha1/dashboard_types.go:41-47` documents GatewayConfig data
  propagated into the Dashboard CR; and
- `internal/controller/components/modelcontroller/modelcontroller.go:35-70`
  derives ModelController state from KServe and ModelRegistry state.

Together these facts support the hierarchical lifecycle, fan-out provisioning,
cross-component state, and GatewayConfig propagation described in Purpose, Data
Flows, and Architectural Analysis. The analyzer retains the underlying rows but does
not yet synthesize those relationships into equivalent Markdown. Replacing such
agent-written prose is outside the current ownership-expansion scope.

## Validation Boundary

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-dynamic-gvk-static-20260719T054834Z`

| Measure | Result |
|---------|-------:|
| Components analyzed | 90 |
| Approved analyzer-only components | 25 |
| False nominations | 0 |
| Analyzer identities retained | 8,348/8,353 (99.94%) |
| Unexplained analyzer conflicts | 0 |
| Unexplained missing analyzer rows | 0 |
| Structurally valid documents | 90/90 |
| Synthesis/structure quality | 90/90 |
| Required gates | PASS |

The candidate remains blocked by explicit approval. This is a documented residual,
not an analyzer-completeness claim.
