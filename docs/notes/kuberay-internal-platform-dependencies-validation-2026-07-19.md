# KubeRay Internal Platform Dependencies Validation, 2026-07-19

## Decision

Approve `kuberay` for analyzer-only component generation. The analyzer now retains
cert-manager `Certificate` and `Issuer` mutations, Gateway API `HTTPRoute`
mutations, and `controllerutil.CreateOrUpdate` operations as source-backed runtime
facts. Imports, type construction, generated clients, and read-only references do
not create dependency rows.

The historical dependency on `rhoai platform gateway (rhods-operator)` was
corrected. KubeRay constructs an HTTPRoute with a configurable Gateway parent whose
defaults are `openshift-ingress/data-science-gateway`, but its repository does not
prove that the `rhods-operator` process owns that Gateway in every deployment. The
analyzer therefore reports the Gateway API contract without inventing a runtime
component owner.

## Full Static Replay

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-kuberay-dependencies-static-20260719T050621Z`

| Measure | Result |
|---------|-------:|
| Components analyzed | 90 |
| Static-analysis failures | 0 |
| Static-analysis wall time | 11.02s |
| Analyzer-sufficient components | 63 |
| Approved analyzer-only components | 24 |
| Newly approved components | 1 |
| False nominations | 0 |
| Target corrections resolved or adjudicated | 2/2 |
| Analyzer identities retained | 8,334/8,339 (99.94%) |
| Accepted analyzer conflicts | 16 |
| Accepted analyzer row corrections | 5 |
| Unexplained analyzer conflicts | 0 |
| Unexplained missing analyzer rows | 0 |
| Structurally valid documents | 90/90 |
| Synthesis/structure quality | 90/90 |
| Required gates | PASS |

The generic operation extraction also added source-backed mutations to ten other
documents. All eleven changed components were rebased and included in the full
preservation gate; delete-only HTTPRoute evidence is described as reconciliation,
not incorrectly labeled as create/update behavior.

## Production-Path Matrix

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-kuberay-dependencies-matrix-20260719T053638Z`

| Measure | Result |
|---------|-------:|
| Components | 1 |
| Analyzer-only routes | 1 |
| Agent invocations | 0 |
| Analyzer identities retained | 155/155 |
| Structural validation | 1/1 |
| Synthesis/structure quality | 1/1 |
| Required gates | PASS |
| Component generation | 0.84s |
| Workflow wall time | 4.72s |

The removed historical agent represents $1.2209, 318.25 summed agent seconds, 8
reads, 4 source files, and 15,384 output tokens. Across all 24 approved components,
the projection is $9.3422 and 192.18 seconds of ten-worker agent wall time avoided.

## Verification

- `GOCACHE=/tmp/arch-analyzer-go-cache go test ./...`: pass.
- Full corpus preservation, structural, and synthesis gates: pass.
- The full Python and lint suites are recorded after the tranche documentation.
