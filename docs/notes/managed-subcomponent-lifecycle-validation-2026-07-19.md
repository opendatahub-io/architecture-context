# Managed Sub-component Lifecycle Validation, 2026-07-19

## Decision

Approve `ai-gateway-operator` for analyzer-only component generation. The analyzer
resolves or source-adjudicates all 3/3 accepted structured corrections, and the
production-path matrix routes the component without an agent.

The analyzer now emits `llm-d batch gateway` only after three independent facts
converge: an explicit CRD `Managed`/`Removed` lifecycle schema, a registered
reconciliation action that gates manifest application on the `Managed` state, and
selected full-lifecycle RBAC for a matching target resource.

## Source Correction

The historical agent described metrics on 8443/TCP as protected by Kubernetes
TokenReview and SubjectAccessReview. The selected Service and review RBAC exist,
but `cmd/operator/operator.go:82-86` sets only `BindAddress` in
`metricsserver.Options`. It leaves `SecureServing` false and `FilterProvider` nil,
so controller-runtime serves plaintext metrics without its authn/authz filter.

The historical metrics row is therefore an accepted analyzer absence. Service port
naming and unused review permissions are not runtime authentication evidence.

## Generic Extraction

- CRD extraction requires a nested `managementState` field with both `Managed` and
  `Removed` enum values and a schema description naming the controlled
  sub-component.
- Go extraction requires the `Managed` comparison to gate a manifest append in a
  callback registered through the reconciliation action chain.
- Constant resolution is package-scoped. The corpus replay exposed and fixed an
  initial implementation that could oscillate when unrelated packages reused a
  constant name with different values.
- Platform semantics require selected RBAC containing create, delete, get, list,
  patch, update, and watch for a resource matching the controlled CR field.
- The relationship identity is derived from the target API group and schema
  component, not from the repository or analyzed component name.

## Full Static Replay

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-managed-subcomponent-static-20260719T153953Z`

| Measure | Result |
|---------|-------:|
| Components analyzed | 90 |
| Static-analysis failures | 0 |
| Static-analysis wall time | 11.86s |
| Analyzer-sufficient components | 64 |
| Approved analyzer-only components | 32 |
| Newly approved components | 1 |
| False nominations | 0 |
| Target corrections resolved/adjudicated | 3/3 |
| Analyzer identities retained | 8,454/8,459 (99.94%) |
| Accepted analyzer conflicts | 16 |
| Accepted analyzer row corrections | 5 |
| Unexplained analyzer conflicts | 0 |
| Unexplained missing analyzer rows | 0 |
| Structurally valid documents | 90/90 |
| Synthesis/structure quality | 90/90 |
| Required gates | PASS |

The accepted-production fixture retains 9,093/9,157 structured identities
(99.30%). The one-row reduction from the prior replay is the invalid metrics
Authentication addition described above.

The approved set projects 32 avoided agent invocations, $17.8371 in historical
cost, 3,581.70 summed agent seconds, 140 reads, 68 source files, and 165,181 output
tokens. The estimated ten-worker agent wall-time reduction is 340.84 seconds
(18.06%).

## Production-Path Matrix

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-managed-subcomponent-matrix-20260719T155024Z`

| Measure | Result |
|---------|-------:|
| Components | 1 |
| Analyzer-only routes | 1 |
| Agent invocations | 0 |
| Analyzer identities retained | 98/98 (100.00%) |
| Structural validation | 1/1 |
| Synthesis/structure quality | 1/1 |
| Required gates | PASS |
| Workflow wall time | 3.22s |

## Verification

- `GOCACHE=/tmp/arch-analyzer-go-cache go test ./...`: pass.
- `.venv/bin/ruff check .`: pass.
- `.venv/bin/pytest -q --ignore=tests/test_strace_agent.py`: 124 passed.
- `git diff --check`: pass.
