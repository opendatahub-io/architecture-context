# Operator Authentication Extraction Validation, 2026-07-19

## Decision

Approve `data-science-pipelines-operator` and `trainer-operator` for analyzer-only
component generation. The analyzer now reproduces all six accepted Authentication
corrections from source-backed facts, and the rollout approval registry prevents
partially covered components from bypassing their agents.

## Implementation

- The Go AST pass extracts controller-runtime health/readiness Authentication facts
  and resolves their configured probe address.
- Metrics are classified as unauthenticated only when
  `metricsserver.Options.SecureServing` is explicitly and statically `false`.
- Manifest collection retains ClusterRole labels and RBAC `resourceNames`.
- Platform semantics emit Argo RBAC aggregation and named-secret restriction facts.
- Historical correction adjudication distinguishes resolved from unresolved row
  identities, including precise probe rows that supersede a coarser combined row.
- `lib/analyzer_only_approvals.json` is the production rollout boundary for
  corpus-validated analyzer-only components.

## Full Static Replay

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-operator-auth-static-20260719T012904Z`

| Measure | Result |
|---------|-------:|
| Components analyzed | 90 |
| Static-analysis failures | 0 |
| Analyzer-sufficient components | 63 |
| Approved analyzer-only components | 17 |
| Newly approved components | 2 |
| False nominations | 0 |
| Target corrections resolved | 6/6 |
| Analyzer identities retained | 8,233/8,238 (99.94%) |
| Unexplained analyzer conflicts | 0 |
| Unexplained missing analyzer rows | 0 |
| Structurally valid documents | 90/90 |
| Synthesis/structure quality | 90/90 |
| Required gates | PASS |

The five additional semantic candidates remained unapproved because accepted
corrections are still unresolved: `feast`, `mcp-lifecycle-module-operator`,
`mlflow-operator`, `models-as-a-service`, and `trustyai-service-operator`.

## Production-Path Matrix

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-operator-auth-matrix-20260719T014328Z`

| Measure | Result |
|---------|-------:|
| Components | 2 |
| Analyzer-only routes | 2 |
| Agent invocations | 0 |
| Analyzer identities retained | 309/309 |
| Structural validation | 2/2 |
| Synthesis/structure quality | 2/2 |
| Required gates | PASS |
| Component generation | 0.69s |
| Workflow wall time | 3.12s |

Against the accepted production fixture, the two removed agents represent $1.9330,
381.44 summed agent seconds, 16 reads, 8 source files, and 17,618 output tokens. A
FIFO ten-worker schedule projects 38.97 seconds of agent wall time avoided.

## Verification

- `GOCACHE=/tmp/arch-analyzer-go-cache go test ./...`: pass.
- `.venv/bin/ruff check .`: pass.
- `.venv/bin/pytest -q --ignore=tests/test_strace_agent.py`: 121 passed.
- `tests/test_strace_agent.py` hangs in the current sandbox and was interrupted; it
  does not exercise the analyzer or routing changes in this tranche.
