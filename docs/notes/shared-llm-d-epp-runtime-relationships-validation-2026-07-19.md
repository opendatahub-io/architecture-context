# Shared llm-d EPP Runtime Relationships Validation, 2026-07-19

## Decision

Approve `llm-d-inference-scheduler` and `llm-d-router` independently for
analyzer-only component generation. The analyzer resolves all 6/6 and 9/9 accepted
structured corrections respectively, and the production-path matrix routes both
without an agent.

The shared implementation now deterministically exposes the Endpoint Picker,
dedicated health and metrics servers, InferencePool provider relationship, Envoy
ExtProc relationship, model-serving metrics scrape, and `llm-d-kv-cache` runtime
module use. Historical EPP, InferencePool, vLLM, and ExtProc labels normalize to
these canonical facts instead of creating duplicate rows.

## Generic Extraction

- Model-server endpoint discovery, `MetricsHost` URL construction, registered
  metrics data-source construction, and an executed HTTP GET must all converge
  before emitting the model-serving metrics relationship.
- A standalone gRPC health component requires server construction, Health service
  registration, runtime reachability, and `Serve`, `Start`, or a concrete manager
  `GRPCServer` runnable. The dedicated plaintext listener is source-correlated to
  its registration before deduplication with the conditional Health service hosted
  on the optional-TLS ExtProc server.
- A standalone metrics component requires a runtime-reachable Prometheus handler,
  `http.Server`, and `ListenAndServe` lifecycle.
- Project-owned Go modules require a direct dependency and non-test runtime import.
  Their component identity is the repository segment after the project namespace;
  nested version and API suffixes cannot become components such as `v2` or `api`,
  and repository-owned nested modules are excluded as self-dependencies.
- Exact `InferencePool` GVKs remain in controller-watch facts while
  `gateway-api-inference-extension` remains the stable provider identity used by
  other consumers such as Workload Variant Autoscaler.
- The source-visible metrics authentication filter remains an accepted absence:
  without secure serving and deployed TokenReview/SubjectAccessReview permissions,
  it does not prove an operational authenticated metrics endpoint.

## Full Static Replay

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-llm-d-epp-static-20260719T151327Z`

| Measure | Result |
|---------|-------:|
| Components analyzed | 90 |
| Static-analysis failures | 0 |
| Static-analysis wall time | 12.10s |
| Analyzer-sufficient components | 64 |
| Approved analyzer-only components | 31 |
| Newly approved components | 2 |
| False nominations | 0 |
| Target corrections resolved | 15/15 |
| Analyzer identities retained | 8,452/8,457 (99.94%) |
| Accepted analyzer conflicts | 16 |
| Accepted analyzer row corrections | 5 |
| Unexplained analyzer conflicts | 0 |
| Unexplained missing analyzer rows | 0 |
| Structurally valid documents | 90/90 |
| Synthesis/structure quality | 90/90 |
| Required gates | PASS |

The accepted-production fixture retains 9,094/9,157 structured identities (99.31%).
The approved set projects 31 avoided agent invocations, $16.7838 in historical
cost, 3,347.03 summed agent seconds, 132 reads, 64 source files, and 154,365 output
tokens.

The runtime-server extractor also moved `batch-gateway` from partial to sufficient.
It remains unapproved pending an independent correction and residual audit.

## Production-Path Matrix

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-llm-d-epp-matrix-20260719T152123Z`

| Measure | Result |
|---------|-------:|
| Components | 2 |
| Analyzer-only routes | 2 |
| Agent invocations | 0 |
| Analyzer identities retained | 154/154 (100.00%) |
| Historical structured recall | 135/139 (97.12%) |
| Structural validation | 2/2 |
| Synthesis/structure quality | 2/2 |
| Required gates | PASS |
| Workflow wall time | 4.03s |

## Verification

- `GOCACHE=/tmp/arch-analyzer-go-cache go test ./...`: pass.
- `.venv/bin/ruff check .`: pass.
- `.venv/bin/pytest -q --ignore=tests/test_strace_agent.py`: 124 passed.
