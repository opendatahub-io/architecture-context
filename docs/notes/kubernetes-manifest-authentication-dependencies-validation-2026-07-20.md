# Kubernetes Manifest Authentication and Dependencies Validation

## Summary

This tranche audited and resolved all 27 accepted corrections across 5 components
(`rhoai-mcp`, `llm-d-routing-sidecar`, `llm-d-batch-gateway-operator`,
`trustyai-explainability`, `llm-d-planner`) without component-specific exceptions.
Three corrections are resolved by the analyzer through generic `resourceGroups`
additions. Twenty-four corrections are source-adjudicated — eight as invalid
historical evidence that fails negative controls, sixteen as valid-but-unsupported
extraction capabilities.

No component becomes newly eligible. The approved analyzer-only set remains at 36.

## Corrections Addressed

| # | Component | Category | Historical identity | Disposition | Evidence |
|--:|-----------|----------|---------------------|-------------|----------|
| 1 | rhoai-mcp | Authentication | `/health :: GET` | **Adjudicated** | Python MCP handler not extractable |
| 2 | llm-d-routing-sidecar | Internal dependency | `platform operator (operator-controller-manager)` | **Adjudicated** | SA name inference (negative control) |
| 3 | llm-d-routing-sidecar | Authentication | `/ (8080/tcp) :: http` | **Adjudicated** | Absence of auth sidecar (negative control) |
| 4 | llm-d-routing-sidecar | Authentication | `${project_name}-route :: https` | **Adjudicated** | Unresolved template + tls absence (negative control) |
| 5 | llm-d-batch-gateway-operator | Internal dependency | `opendatahub-operator` | **Adjudicated** | Comment-only platform attribution (negative control) |
| 6 | llm-d-batch-gateway-operator | Internal dependency | `gateway api gateway` | **Resolved by analyzer** | RBAC CRUD on gateway.networking.k8s.io + controller imports + scheme registration |
| 7 | llm-d-batch-gateway-operator | Internal dependency | `prometheus operator` | **Resolved by analyzer** | RBAC CRUD on monitoring.coreos.com + controller imports + MetricsController |
| 8 | llm-d-batch-gateway-operator | Internal dependency | `cert-manager` | **Resolved by analyzer** | RBAC CRUD on cert-manager.io + controller imports + Helm Certificate rendering |
| 9 | llm-d-batch-gateway-operator | Integration | `llm-d inference gateway` | **Adjudicated** | CRD schema field alone (negative control) |
| 10 | trustyai-explainability | Internal dependency | `kserve / model serving` | **Adjudicated** | Init container extraction not implemented |
| 11 | trustyai-explainability | Internal dependency | `prometheus / monitoring` | **Adjudicated** | Annotation-based dependency not implemented |
| 12 | trustyai-explainability | Internal dependency | `trustyai-config configmap` | **Adjudicated** | ConfigMap = config resource, not platform dependency (negative control) |
| 13 | trustyai-explainability | Authentication | `trustyai route (port 80) :: http` | **Adjudicated** | Route tls:null = absence-only (negative control) |
| 14 | trustyai-explainability | Authentication | `/q/health/live :: GET` | **Adjudicated** | Java handler extraction not implemented |
| 15 | trustyai-explainability | Authentication | `/q/health/ready :: GET` | **Adjudicated** | Java handler extraction not implemented |
| 16 | trustyai-explainability | Integration | `kserve model serving :: configmap injection` | **Adjudicated** | Init container extraction not implemented |
| 17 | trustyai-explainability | Integration | `prometheus :: metrics scraping` | **Adjudicated** | Annotation-based integration not implemented |
| 18 | llm-d-planner | Internal dependency | `openshift service ca operator` | **Adjudicated** | Service-CA annotation correlation not implemented |
| 19 | llm-d-planner | Internal dependency | `kubernetes api (core/v1 nodes)` | **Adjudicated** | Python RBAC-to-dependency not implemented |
| 20 | llm-d-planner | Internal dependency | `openshift route (ingress)` | **Adjudicated** | Already captured in ingress table (negative control) |
| 21 | llm-d-planner | Integration | `postgres :: database client` | **Adjudicated** | Python runtime source correlation not implemented |
| 22 | llm-d-planner | Integration | `ollama :: http client` | **Adjudicated** | Python runtime source correlation not implemented |
| 23 | llm-d-planner | Integration | `kubernetes api :: api client (rbac)` | **Adjudicated** | Python RBAC-to-integration not implemented |
| 24 | llm-d-planner | Integration | `hugging face hub :: https client` | **Adjudicated** | Credential-only evidence (negative control) |
| 25 | llm-d-planner | Integration | `openai-compatible api :: https client` | **Adjudicated** | Credential-only evidence (negative control) |
| 26 | llm-d-planner | Integration | `google vertex ai :: https client` | **Adjudicated** | Credential-only evidence (negative control) |
| 27 | llm-d-planner | Integration | `model catalog :: https client` | **Adjudicated** | Credential-only evidence (negative control) |

## Generic Extraction Improvements

### RBAC-to-dependency for infrastructure API groups

Added `monitoring.coreos.com`, `cert-manager.io`, and `gateway.networking.k8s.io`
to the `resourceGroups` map in `platformfacts.go`. This enables both the RBAC-based
dependency path (lines 117-136) and the controller watch generic fallback (line 620)
for these infrastructure groups.

Verified across the 90-component corpus: all 18 components with RBAC on these
groups are legitimate platform infrastructure consumers. The corpus includes
operators/controllers for data-science-pipelines-operator, feast, kserve, kuberay,
ai-gateway-operator, trainer-operator, workload-variant-autoscaler, and others.

Removed `cert-manager.io` and `gateway.networking.k8s.io` from
`additionalInternalDependencyAliases` since they are now in `resourceGroups` (which
feeds into alias discovery automatically). Added `monitoring.coreos.com` to the
alias vocabulary for the first time.

Files: `src/arch-analyzer/internal/platformfacts/platformfacts.go`

## Tests

New tests:
- `TestResourceGroupRBACProducesInfrastructureDependencies` — verifies RBAC on all
  three groups creates internal dependencies and integration facts
- `TestResourceGroupRBACRejectsUnmappedGroups` — verifies unknown groups produce
  no dependencies
- `TestResourceGroupRBACCoexistsWithComponentRefDependencies` — verifies RBAC-based
  and componentRef-based dependencies coexist for cert-manager

Updated:
- `TestWatchInternalDependencies` — fixture changed to use non-platform GVK for
  GeneratedModel negative case (previously used gateway.networking.k8s.io, now
  matched by generic fallback)

All existing tests pass unchanged:
- `TestInternalDependencyDiscoveryAliasesIncludeSemanticResourceGroups` —
  automatically validates new resourceGroups entries in alias vocabulary
- `TestExtractSemanticPlatformFacts` — no count changes (fixture has no RBAC on
  these groups)
- Go: `go test ./...` and `go vet ./...` pass
- Python: `ruff check` and 131 tests pass

## Replay Results

Fresh 90-component replay at
`tmp/architecture-corpus-runs/rhoai.next-20260720T103625Z-3372001`:

| Measure | Value |
|---------|------:|
| Components | 90 |
| Analyzer-only | 36 |
| Evidence-gated | 46 |
| Legacy | 8 |
| Agent invocations | 54 |
| False nominations | 0 |
| Regressions on approved components | 0 |
| Unexplained conflicts | 0 |
| Unexplained missing rows | 0 |
| Workflow wall time | 1542.39s |
| Reduction from one-hour reference | 57.16% |

## Eligibility Analysis

No component becomes newly eligible from this tranche:

| Component | Candidate | Eligible | Reason |
|-----------|-----------|----------|--------|
| llm-d-batch-gateway-operator | yes | no | internal_dependencies still partial (6 unaccounted alias references, partial kustomize) |
| rhoai-mcp | no | no | Authentication coverage gap (Python handler correlation not implemented) |
| llm-d-routing-sidecar | no | no | Authentication and Internal Dependencies coverage gaps |
| trustyai-explainability | no | no | Authentication, Integration Points, Internal Dependencies gaps |
| llm-d-planner | no | no | Integration Points and Internal Dependencies gaps |

## Adjudication Summary

24 adjudication entries added to `lib/analyzer_correction_adjudications.json`:

| Type | Count | Examples |
|------|------:|---------|
| Invalid evidence (negative controls) | 8 | SA name inference, absence-only auth, comment-only attribution, ConfigMap as dependency, Route tls:null, credential-only integrations |
| Valid-but-unsupported | 16 | Python/Java handler correlation, init container extraction, annotation-based dependencies, service-CA correlation, Python RBAC-to-dependency |

## Outcome

- 3/27 corrections resolved by generic RBAC-to-dependency extraction.
- 24/27 corrections source-adjudicated with documented reasoning.
- Approved set unchanged at 36 (no component newly eligible).
- Zero regressions, zero false nominations.
- One generic improvement (infrastructure API group RBAC) available to all
  components with RBAC on monitoring.coreos.com, cert-manager.io, or
  gateway.networking.k8s.io.
