# Secure Controller Metrics Authentication Validation, 2026-07-19

## Decision

Approve `mlflow-operator` for analyzer-only component generation. The analyzer now
retains deployed container arguments and models controller-runtime metrics filter
assignment as a runtime security control. It renders an Authentication row only
when source flags, deployed address, secure-serving state, Service targeting,
ServiceAccount-bound review RBAC, and service-ca TLS evidence converge.

Imports, secure serving, review permissions, or TLS alone do not produce the fact.
Dynamic security settings remain unresolved.

## Full Static Replay

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-secure-metrics-static-20260719T024000Z`

| Measure | Result |
|---------|-------:|
| Components analyzed | 90 |
| Static-analysis failures | 0 |
| Analyzer-sufficient components | 63 |
| Approved analyzer-only components | 20 |
| Newly approved components | 1 |
| False nominations | 0 |
| Target corrections resolved | 3/3 |
| Analyzer identities retained | 8,257/8,262 (99.94%) |
| Accepted analyzer conflicts | 16 |
| Accepted analyzer row corrections | 5 |
| Unexplained analyzer conflicts | 0 |
| Unexplained missing analyzer rows | 0 |
| Structurally valid documents | 90/90 |
| Synthesis/structure quality | 90/90 |
| Required gates | PASS |

Only `mlflow-operator` gained a rendered structured row in this tranche. Container
arguments are retained in normalized JSON but do not create Markdown rows by
themselves.

## Production-Path Matrix

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-secure-metrics-matrix-20260719T024500Z`

| Measure | Result |
|---------|-------:|
| Components | 1 |
| Analyzer-only routes | 1 |
| Agent invocations | 0 |
| Analyzer identities retained | 119/119 |
| Structural validation | 1/1 |
| Synthesis/structure quality | 1/1 |
| Required gates | PASS |
| Component generation | 0.64s |
| Workflow wall time | 2.97s |

The removed historical agent represents $0.8774, 176.69 summed agent seconds, 8
reads, 4 source files, and 7,914 output tokens. Across all 20 approved components,
the projection is $4.3993 and 99.19 seconds of ten-worker agent wall time avoided.

## Verification

- `GOCACHE=/tmp/arch-analyzer-go-cache go test ./...`: pass.
- `.venv/bin/ruff check .`: pass.
- `.venv/bin/pytest -q --ignore=tests/test_strace_agent.py`: 121 passed.
- Full corpus preservation, structural, and synthesis gates: pass.
