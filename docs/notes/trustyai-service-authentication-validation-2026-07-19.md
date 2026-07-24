# TrustyAI Service Authentication Validation, 2026-07-19

## Decision

Approve `trustyai-service-operator` for analyzer-only component generation. The
analyzer now correlates source-constructed kube-rbac-proxy workloads with their
application peers, Services, ServiceAccounts, TLS Secrets, and review RBAC. It also
correlates conditional controller-runtime webhook construction with the deployed
port, Service, and OpenShift service-ca serving certificate.

The historical controller-metrics proxy row was rejected. The selected manager
Deployment has no kube-rbac-proxy container or HTTPS target, so an orphaned Service
and review RBAC do not establish a deployed runtime path. The webhook row now
describes TLS server identity; the source does not establish client-certificate
authentication.

## Full Static Replay

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-trustyai-auth-static-20260719T042645Z`

| Measure | Result |
|---------|-------:|
| Components analyzed | 90 |
| Static-analysis failures | 0 |
| Static-analysis wall time | 11.42s |
| Analyzer-sufficient components | 63 |
| Approved analyzer-only components | 23 |
| Newly approved components | 1 |
| False nominations | 0 |
| Target corrections resolved | 7/7 |
| Analyzer identities retained | 8,309/8,314 (99.94%) |
| Accepted analyzer conflicts | 16 |
| Accepted analyzer row corrections | 5 |
| Unexplained analyzer conflicts | 0 |
| Unexplained missing analyzer rows | 0 |
| Structurally valid documents | 90/90 |
| Synthesis/structure quality | 90/90 |
| Required gates | PASS |

The generic source changes also discovered a source-constructed SCC binding in
`rhaii-cluster-validation` and a correlated webhook serving-certificate fact in
`rhods-operator`. Four repositories lost the former image-name-only `All UI/API`
authentication inference. `kube-rbac-proxy` retained its existing analyzer-only
route through a bounded production handler-chain fact requiring paired and invoked
authentication and authorization wrappers.

## Production-Path Matrix

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-trustyai-auth-matrix-20260719T045804Z`

| Measure | Result |
|---------|-------:|
| Components | 1 |
| Analyzer-only routes | 1 |
| Agent invocations | 0 |
| Analyzer identities retained | 202/202 |
| Structural validation | 1/1 |
| Synthesis/structure quality | 1/1 |
| Required gates | PASS |
| Component generation | 0.81s |
| Workflow wall time | 3.61s |

The removed historical agent represents $1.2302, 194.33 summed agent seconds, 9
reads, 4 source files, and 9,510 output tokens. Across all 23 approved components,
the projection is $8.1213 and 167.22 seconds of ten-worker agent wall time avoided.

## Verification

- `GOCACHE=/tmp/arch-analyzer-go-cache go test ./...`: pass.
- `.venv/bin/ruff check .`: pass.
- `.venv/bin/pytest -q --ignore=tests/test_strace_agent.py`: 122 passed.
- Full corpus preservation, structural, and synthesis gates: pass.
