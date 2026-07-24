# Runtime Inference Gateway Client Validation, 2026-07-19

## Decision

Accept project-owned runtime HTTP client extraction and keep `batch-gateway`
agent-routed. The analyzer now resolves or source-adjudicates nine of its eleven
accepted structured corrections. Only two inbound Authentication rows remain.
Routing did not change, so this tranche required no paid production-path matrix.

## Generic Extraction

- The package- and receiver-qualified Go call graph exposes reverse runtime
  reachability from a concrete transport factory to its executable ancestors.
- A project-owned HTTP client requires a runtime-reachable Resty constructor, a
  non-literal `SetBaseURL` binding, and a concrete returned client type whose method
  executes an outbound HTTP request.
- One ancestor must independently contain the `inference`, `gateway`, and `client`
  semantics in its package path, function or receiver name, typed signature, or
  function documentation. Identifiers in unrelated sibling calls do not contribute
  semantic evidence.
- GitHub module ownership supplies the platform namespace. Only an `llm-d`-owned
  semantic inference-gateway chain maps to the internal `llm-d inference gateway`
  relationship.
- Disconnected factories, test-only code, fixed demo endpoints, wrappers without an
  outbound method, generic HTTP clients, ambiguous declarations, dynamic interface
  dispatch, and semantic sibling calls are rejected.

The 90-component corpus emitted this project-owned client only for `batch-gateway`.

## Target Result

At commit `fac0c8d8c69369662d46edf1bfecacf3bd15b5d2`, the runtime chain is:

1. `cmd/batch-processor/main.go:283-299` resolves global or per-model gateways.
2. `internal/util/clientset/clientset.go:267-282` constructs the selected resolver.
3. `pkg/clients/inference/inference_client_resolver.go:82-118` creates concrete
   inference clients.
4. `pkg/clients/http/http_client.go:134` constructs Resty with the runtime base URL.
5. `pkg/clients/http/http_client.go:238-260` executes outbound HTTP POST requests.

The analyzer emits:

| Category | Component | Interaction | Source |
|----------|-----------|-------------|--------|
| Internal Platform Dependencies | `llm-d inference gateway` | HTTP client | `pkg/clients/http/http_client.go:134` |
| Integration Points | `llm-d inference gateway` | HTTP client | `pkg/clients/http/http_client.go:134` |

Both rows preserve runtime-configured ports and encryption. Accepted correction
resolution improved from 7/11 to 9/11.

## Normalization Correction

An Internal Dependency is also projected into Integration Points for compatibility.
When an explicit Integration Point has the same `(component, interaction)` identity,
the normalizer now suppresses the lower-detail projection. Fourteen corpus documents
were affected; each retained its richer explicit row rather than rendering two rows
with the same canonical identity.

## Full Static Replay

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-inference-gateway-client-static-20260719T165652Z`

| Measure | Result |
|---------|-------:|
| Components analyzed | 90 |
| Static-analysis failures | 0 |
| Static-analysis wall time | 12.04s |
| Analyzer-sufficient components | 64 |
| Approved analyzer-only components | 32 |
| False nominations | 0 |
| Target corrections resolved or adjudicated | 9/11 |
| Analyzer identities retained | 8,494/8,499 (99.94%) |
| Accepted analyzer conflicts | 16 |
| Accepted analyzer row corrections | 5 |
| Unexplained analyzer conflicts | 0 |
| Unexplained missing analyzer rows | 0 |
| Structurally valid documents | 90/90 |
| Synthesis/structure quality | 90/90 |
| Required gates | PASS |

The accepted-production fixture retains 9,090/9,157 structured identities
(99.27%), unchanged from the runtime-command replay.

## Verification

- `GOCACHE=/tmp/arch-analyzer-go-cache go test ./...`: pass.
- `GOCACHE=/tmp/arch-analyzer-go-cache go vet ./...`: pass.
- `.venv/bin/ruff check lib scripts tests src/arch-analyzer`: pass.
- Deterministic Python suite excluding the credentialed strace test: 125 passed.
- Corpus preservation, structural, and synthesis gates: pass.

