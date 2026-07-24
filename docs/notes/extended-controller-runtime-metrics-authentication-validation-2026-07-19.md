# Extended Controller-Runtime Metrics Authentication Validation, 2026-07-19

## Decision

Keep analyzer-only routing at 25 components. The semantic pass now separates
authentication evidence from Service exposure and certificate provenance. It emits
a controller-runtime metrics Authentication fact only after the source filter,
deployed bind address, secure-serving state, workload ServiceAccount, and a bound
TokenReview/SubjectAccessReview role converge.

A matching Service is optional. OpenShift service-ca, controller-runtime generated
self-signed TLS, externally supplied certificate paths, and unresolved certificate
sources render as distinct policies.

## Target Results

| Component | Result |
|-----------|--------|
| `mcp-lifecycle-operator` | `:8443/metrics` is analyzer-owned with selected Service exposure, review RBAC, and the controller-runtime self-signed default. All 3/3 accepted corrections are resolved. |
| `workload-variant-autoscaler` | Repository-level Viper getters resolve to the deployed metrics flags; `:8443/metrics` is analyzer-owned with self-signed TLS. The metrics correction is resolved; five dependency corrections remain. |
| `workbenches-operator` | The historical metrics addition is rejected because the selected role grants SubjectAccessReview but not TokenReview. Three dependency corrections remain. |
| `llm-d-inference-scheduler` | The historical `/metrics` addition is rejected because the source options omit metrics `SecureServing` and no selected workload/review-RBAC path converges. Five other corrections remain. |
| `llm-d-router` | The same source-backed rejection applies. Eight other corrections remain. |

Exact source-adjudicated additions are now rejected by the evidence-gated merge as
well as by eligibility classification. This prevents a reviewed invalid historical
row from being reapplied by a later agent candidate.

## Full Static Replay

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-controller-metrics-static-20260719T061600Z`

| Measure | Result |
|---------|-------:|
| Components analyzed | 90 |
| Static-analysis failures | 0 |
| Static-analysis wall time | 11.06s |
| Analyzer-sufficient components | 63 |
| Approved analyzer-only components | 25 |
| Newly approved components | 0 |
| False nominations | 0 |
| Analyzer identities retained | 8,353/8,358 (99.94%) |
| Accepted analyzer conflicts | 16 |
| Accepted analyzer row corrections | 5 |
| Unexplained analyzer conflicts | 0 |
| Unexplained missing analyzer rows | 0 |
| Structurally valid documents | 90/90 |
| Synthesis/structure quality | 90/90 |
| Required gates | PASS |

The corrected fixture recall is 9,136/9,157 (99.77%). Three historical
Authentication rows are intentionally absent after source adjudication. No bounded
production-path matrix was run because routing did not change.

## Verification

- `GOCACHE=/tmp/arch-analyzer-go-cache go test ./...`: pass.
- `.venv/bin/ruff check .`: pass.
- `.venv/bin/pytest -q --ignore=tests/test_strace_agent.py`: pass.
- `git diff --check`: pass.
