# MaaS API Authentication Validation, 2026-07-19

## Decision

Approve `models-as-a-service` for analyzer-only component generation. The analyzer
now models resolved or controller-created Kuadrant `AuthPolicy` objects, correlates
Gateway routes with grouped Go HTTP handlers, retains probe headers, and converges
source, workload, and Service evidence for health and metrics surfaces.

The analyzer owns all four accepted Authentication row identities. It deliberately
corrects the historical API explanation: the controller-created Gateway
`AuthPolicy`, not MaaS application JWT middleware, performs API-key, Kubernetes
TokenReview, optional OIDC JWT, and authorization enforcement. Application code
consumes the identity headers produced by that policy.

Unreferenced policy YAML, a JWT dependency, review RBAC without a runtime policy,
an HTTPRoute without policy evidence, a header-bearing probe, and a metrics listener
without matching source or Service evidence do not produce these facts.

## Full Static Replay

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-maas-auth-static-20260719T031000Z`

| Measure | Result |
|---------|-------:|
| Components analyzed | 90 |
| Static-analysis failures | 0 |
| Static-analysis wall time | 11.90s |
| Analyzer-sufficient components | 63 |
| Approved analyzer-only components | 21 |
| Newly approved components | 1 |
| False nominations | 0 |
| Target corrections resolved | 4/4 |
| Analyzer identities retained | 8,297/8,302 (99.94%) |
| Accepted analyzer conflicts | 16 |
| Accepted analyzer row corrections | 5 |
| Unexplained analyzer conflicts | 0 |
| Unexplained missing analyzer rows | 0 |
| Structurally valid documents | 90/90 |
| Synthesis/structure quality | 90/90 |
| Required gates | PASS |

The generic probe and metrics convergence changed 27 analyzer Markdown documents.
The simulated routed corpus used fresh analyzer documents for all approved routes
and replayed the original accepted change records for the 10 changed agent-routed
components. This preserved current analyzer rows without discarding accepted agent
facts.

## Production-Path Matrix

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-maas-auth-matrix-20260719T032600Z`

| Measure | Result |
|---------|-------:|
| Components | 1 |
| Analyzer-only routes | 1 |
| Agent invocations | 0 |
| Analyzer identities retained | 110/110 |
| Structural validation | 1/1 |
| Synthesis/structure quality | 1/1 |
| Required gates | PASS |
| Component generation | 0.77s |
| Workflow wall time | 3.17s |

The removed historical agent represents $0.9999, 240.67 summed agent seconds, 9
reads, 4 source files, and 11,388 output tokens. Across all 21 approved components,
the projection is $5.3993 and 115.15 seconds of ten-worker agent wall time avoided.

## Verification

- `GOCACHE=/tmp/arch-analyzer-go-cache go test ./...`: pass.
- `.venv/bin/ruff check .`: pass.
- `.venv/bin/pytest -q --ignore=tests/test_strace_agent.py`: 121 passed.
- Full corpus preservation, structural, and synthesis gates: pass.
