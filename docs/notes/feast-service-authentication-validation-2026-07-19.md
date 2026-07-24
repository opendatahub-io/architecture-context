# Feast Service Authentication Validation, 2026-07-19

## Decision

Approve `feast` for analyzer-only component generation. The analyzer now proves
bounded `net/http` handler chains, correlates handler method checks, inventories
statically constructed gRPC server options and service registrations, and recognizes
typed CRD authorization choices.

The Go HTTP and gRPC rows claim no application authentication only when the complete
static chain is bounded. Unknown or conditional middleware, unresolved methods,
undeployed muxes, dynamic gRPC option slices, unknown interceptors, health-only
servers, and multiply assigned server variables remain unresolved. The CRD row says
Kubernetes RBAC or OIDC is configurable and does not claim either is currently
selected.

## Full Static Replay

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-feast-auth-static-20260719T034500Z`

| Measure | Result |
|---------|-------:|
| Components analyzed | 90 |
| Static-analysis failures | 0 |
| Static-analysis wall time | 10.50s |
| Analyzer-sufficient components | 63 |
| Approved analyzer-only components | 22 |
| Newly approved components | 1 |
| False nominations | 0 |
| Target corrections resolved | 4/4 |
| Analyzer identities retained | 8,303/8,308 (99.94%) |
| Accepted analyzer conflicts | 16 |
| Accepted analyzer row corrections | 5 |
| Unexplained analyzer conflicts | 0 |
| Unexplained missing analyzer rows | 0 |
| Structurally valid documents | 90/90 |
| Synthesis/structure quality | 90/90 |
| Required gates | PASS |

The new rules changed three analyzer Markdown documents. `agents-operator` and
`feast` are approved analyzer-only routes. `modelmesh-runtime-adapter` remained
agent-routed and was rebased with its original accepted change record. A first-pass
fact for `gateway-api-inference-extension` was rejected after the audit found
conditional TLS and plaintext assignments to the same server variable.

## Production-Path Matrix

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-feast-auth-matrix-20260719T035000Z`

| Measure | Result |
|---------|-------:|
| Components | 1 |
| Analyzer-only routes | 1 |
| Agent invocations | 0 |
| Analyzer identities retained | 448/448 |
| Structural validation | 1/1 |
| Synthesis/structure quality | 1/1 |
| Required gates | PASS |
| Component generation | 0.72s |
| Workflow wall time | 5.58s |

The removed historical agent represents $1.4918, 214.69 summed agent seconds, 10
reads, 4 source files, and 9,725 output tokens. Across all 22 approved components,
the projection is $6.8911 and 147.63 seconds of ten-worker agent wall time avoided.

## Verification

- `GOCACHE=/tmp/arch-analyzer-go-cache go test ./...`: pass.
- `.venv/bin/ruff check .`: pass.
- `.venv/bin/pytest -q --ignore=tests/test_strace_agent.py`: 121 passed.
- Full corpus preservation, structural, and synthesis gates: pass.
