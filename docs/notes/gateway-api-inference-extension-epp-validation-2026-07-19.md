# Gateway API Inference Extension EPP Validation, 2026-07-19

## Decision

Approve `gateway-api-inference-extension` for analyzer-only component generation.
The analyzer resolves the repository's 1/1 accepted structured correction and now
accounts for its reachable ExternalProcessor and health gRPC surfaces.

The Endpoint Picker component is not inferred from the repository name. It requires
an `EndpointPickerConfig` API and a reachable registered ExternalProcessor service.
The resulting component also retains the typed `InferencePool` reference contract:
`Spec.EndpointPickerRef` defaults to a `Service`, supports `FailOpen` and
`FailClose`, and defaults to `FailClose`.

## Generic Extraction

- A registered Go gRPC service requires `grpc.NewServer`, a protobuf
  `Register*Server` call, and a runtime anchor: a reachable `main` call, a returned
  manager `Runnable`, manager registration, or a server `Serve`/`Start` call.
- Imports, generated declarations, and disconnected constructed servers are negative
  controls.
- TLS is asserted only when `grpc.Creds` resolves to a server credential built from
  `credentials.NewTLS` with certificate-bearing `tls.Config`, or from
  `credentials.NewServerTLSFromFile`. Unknown credentials and interceptors remain
  explicit Authentication limitations.
- Repository-wide service normalization merges plaintext and TLS constructions into
  `Optional TLS` without hiding unresolved options.
- Kubebuilder CRD structures generically expose typed reference defaults and failure
  modes as `api_reference_contracts`; the EPP semantic adapter consumes that fact
  only after independent API and runtime evidence converge.
- Conformance, test, example, and sample paths are excluded from deployed inbound
  surface accounting. Production manifests selected by runtime overlays remain
  eligible.
- Exact gRPC Authentication facts satisfy their corresponding inbound-surface
  accounting instead of producing a contradictory unaccounted-surface warning.

The generic registered-service pass also found source-backed facts in shared llm-d,
Caikit, and ModelMesh repositories. Those agent-routed documents were rebased so all
fresh analyzer facts remain preserved; no additional component was approved by this
tranche.

## Full Static Replay

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-gie-epp-static-20260719T143319Z`

| Measure | Result |
|---------|-------:|
| Components analyzed | 90 |
| Static-analysis failures | 0 |
| Observed static-analysis wall time | 11.90s |
| Analyzer-sufficient components | 63 |
| Approved analyzer-only components | 29 |
| Newly approved components | 1 |
| False nominations | 0 |
| Target corrections resolved | 1/1 |
| Analyzer identities retained | 8,405/8,410 (99.94%) |
| Accepted analyzer conflicts | 16 |
| Accepted analyzer row corrections | 5 |
| Unexplained analyzer conflicts | 0 |
| Unexplained missing analyzer rows | 0 |
| Structurally valid documents | 90/90 |
| Synthesis/structure quality | 90/90 |
| Required gates | PASS |

The accepted-production fixture retains 9,094/9,157 structured identities (99.31%).
The approved set projects 29 avoided agent invocations, $14.2899 in historical cost,
2,906.41 summed agent seconds, 116 reads, 56 source files, and 134,826 output tokens.

## Production-Path Matrix

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-gie-epp-matrix-20260719T144004Z`

| Measure | Result |
|---------|-------:|
| Components | 1 |
| Analyzer-only routes | 1 |
| Agent invocations | 0 |
| Analyzer identities retained | 91/91 |
| Historical structured recall | 83/87 (95.40%) |
| Structural validation | 1/1 |
| Synthesis/structure quality | 1/1 |
| Required gates | PASS |
| Workflow wall time | 3.45s |

## Verification

- `GOCACHE=/tmp/arch-analyzer-go-cache go test ./...`: pass.
- `UV_CACHE_DIR=/tmp/uv-cache uv run ruff check .`: pass.
- `.venv/bin/pytest -q --ignore=tests/test_strace_agent.py`: 123 passed.
