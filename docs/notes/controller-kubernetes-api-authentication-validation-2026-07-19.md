# Controller Kubernetes API Authentication Validation, 2026-07-19

## Decision

Approve `mcp-lifecycle-module-operator` for analyzer-only component generation. The
analyzer now models runtime Kubernetes client construction separately from manifests
and emits in-cluster ServiceAccount authentication only when a deployed
ServiceAccount has a matching RBAC binding and referenced role.

The Go extractor recognizes exact controller-runtime manager and client-go dynamic,
discovery, and typed-client constructors. A `client-go` dependency, a workload, or
TokenReview/SubjectAccessReview permissions alone do not produce the fact.

## Full Static Replay

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-controller-k8s-auth-static-20260719T023000Z`

| Measure | Result |
|---------|-------:|
| Components analyzed | 90 |
| Static-analysis failures | 0 |
| Analyzer-sufficient components | 63 |
| Approved analyzer-only components | 19 |
| Newly approved components | 1 |
| False nominations | 0 |
| Target corrections resolved | 3/3 |
| Analyzer identities retained | 8,256/8,261 (99.94%) |
| Accepted analyzer conflicts | 16 |
| Accepted analyzer row corrections | 5 |
| Unexplained analyzer conflicts | 0 |
| Unexplained missing analyzer rows | 0 |
| Structurally valid documents | 90/90 |
| Synthesis/structure quality | 90/90 |
| Required gates | PASS |

The generic runtime-client signal exposed additional controller facts across the
corpus. Production routing remained bounded by `lib/analyzer_only_approvals.json`;
the eligibility audit reported zero false approved nominations.

## Production-Path Matrix

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-controller-k8s-auth-matrix-20260719T022000Z`

| Measure | Result |
|---------|-------:|
| Components | 1 |
| Analyzer-only routes | 1 |
| Agent invocations | 0 |
| Analyzer identities retained | 67/67 |
| Structural validation | 1/1 |
| Synthesis/structure quality | 1/1 |
| Required gates | PASS |
| Component generation | 0.64s |
| Workflow wall time | 2.96s |

The removed historical MCP agent represents $0.8600, 191.53 summed agent seconds,
8 reads, 4 source files, and 8,570 output tokens. Across all 19 approved components,
the projection is $3.5220 and 83.16 seconds of ten-worker agent wall time avoided.

## Verification

- `GOCACHE=/tmp/arch-analyzer-go-cache go test ./...`: pass.
- `.venv/bin/ruff check .`: pass.
- `.venv/bin/pytest -q --ignore=tests/test_strace_agent.py`: 121 passed.
- Full corpus preservation, structural, and synthesis gates: pass.
