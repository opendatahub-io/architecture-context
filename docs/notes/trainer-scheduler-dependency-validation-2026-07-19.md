# Trainer Scheduler Dependency Validation, 2026-07-19

## Decision

Approve `trainer` for analyzer-only component generation. Three explicit controller
watches now populate Internal Platform Dependencies with JobSet, Volcano Scheduler,
and Kubernetes Scheduler Plugins CoScheduling relationships.

The source audit rejected two broad scan results: Gateway API occurrences exist only
in generated OpenAPI/Python models, and `trainer.kubeflow.org` is trainer's own API.
Neither is emitted as an internal dependency.

## Full Static Replay

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-trainer-dependencies-static-20260719T015433Z`

| Measure | Result |
|---------|-------:|
| Components analyzed | 90 |
| Static-analysis failures | 0 |
| Analyzer-sufficient components | 63 |
| Approved analyzer-only components | 18 |
| Newly approved components | 1 |
| False nominations | 0 |
| Analyzer identities retained | 8,239/8,244 (99.94%) |
| Unexplained analyzer conflicts | 0 |
| Unexplained missing analyzer rows | 0 |
| Structural validation | 90/90 |
| Synthesis/structure quality | 90/90 |
| Required gates | PASS |

Only `trainer` gained structured rows in this tranche: three Internal Platform
Dependencies and their corresponding Integration Points.

## Production-Path Matrix

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-trainer-dependencies-matrix-20260719T015551Z`

| Measure | Result |
|---------|-------:|
| Components | 1 |
| Analyzer-only routes | 1 |
| Agent invocations | 0 |
| Analyzer identities retained | 77/77 |
| Structural validation | 1/1 |
| Synthesis/structure quality | 1/1 |
| Required gates | PASS |
| Workflow wall time | 3.24s |

The removed historical agent represents $0.7290, 150.16 summed agent seconds, 8
reads, 4 source files, and 7,177 output tokens. Across all 18 approved components,
the FIFO ten-worker projection is 59.63 seconds of agent wall time avoided.

## Verification

- `GOCACHE=/tmp/arch-analyzer-go-cache go test ./...`: pass.
- `.venv/bin/ruff check .`: pass.
- Full corpus preservation, structural, and synthesis gates: pass.
