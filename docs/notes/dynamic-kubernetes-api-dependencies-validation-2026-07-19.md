# Dynamic Kubernetes API Dependencies Validation, 2026-07-19

## Decision

Approve `spark-operator` for analyzer-only component generation. The Go extractor
now binds a concrete `schema.GroupVersionKind` to an
`unstructured.Unstructured` variable and requires that same variable to reach a
Kubernetes client operation after the binding. Spark's webhook therefore retains
its read of `config.openshift.io/v1/APIServer` as an OpenShift Cluster
Configuration dependency.

The selected RHOAI manifests do not enable Spark's optional Volcano scheduler or
cert-manager integration, so compiled support and documentation references were
not promoted to runtime dependencies. GVK construction without a client call,
different variables, unresolved GVK fields, operations before the binding, and
fixture directories are negative controls.

## Full Static Replay

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-dynamic-gvk-static-20260719T054834Z`

| Measure | Result |
|---------|-------:|
| Components analyzed | 90 |
| Static-analysis failures | 0 |
| Static-analysis wall time | 10.91s |
| Analyzer-sufficient components | 63 |
| Approved analyzer-only components | 25 |
| Newly approved components | 1 |
| False nominations | 0 |
| Target corrections resolved | 0/0 |
| Analyzer identities retained | 8,348/8,353 (99.94%) |
| Accepted analyzer conflicts | 16 |
| Accepted analyzer row corrections | 5 |
| Unexplained analyzer conflicts | 0 |
| Unexplained missing analyzer rows | 0 |
| Structurally valid documents | 90/90 |
| Synthesis/structure quality | 90/90 |
| Required gates | PASS |

Nine analyzer documents changed. The replay added only object-connected dynamic
client operations and removed fixture-derived Namespace, Secret, ServiceAccount,
and HTTPRoute operations that had been incorrectly treated as production facts.

## Production-Path Matrix

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-dynamic-gvk-matrix-20260719T055354Z`

| Measure | Result |
|---------|-------:|
| Components | 1 |
| Analyzer-only routes | 1 |
| Agent invocations | 0 |
| Analyzer identities retained | 112/112 |
| Structural validation | 1/1 |
| Synthesis/structure quality | 1/1 |
| Required gates | PASS |
| Component generation | 0.63s |
| Workflow wall time | 3.30s |

The removed historical agent represents $1.0982, 194.94 summed agent seconds, 8
reads, 4 source files, and 8,714 output tokens. Across all 25 approved components,
the projection is $10.4404 and 233.49 seconds of ten-worker agent wall time avoided.

## Verification

- `GOCACHE=/tmp/arch-analyzer-go-cache go test ./...`: pass.
- `.venv/bin/ruff check .`: pass.
- `.venv/bin/pytest -q --ignore=tests/test_strace_agent.py`: 122 passed.
- `git diff --check`: pass.
- Full corpus preservation, structural, and synthesis gates: pass.
