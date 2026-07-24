# Runtime Command Components Validation, 2026-07-19

## Decision

Accept the shipped Go command extractor and keep `batch-gateway` agent-routed.
The analyzer now resolves or source-adjudicates seven of its eleven accepted
structured corrections. The remaining four are two inference-gateway relationships
and two Authentication rows. Routing did not change, so this tranche required no
paid production-path matrix.

## Generic Extraction

- A command requires a concrete non-test, non-generated Go `main` function, a
  Dockerfile `go build` selecting its package, an explicit `-o` artifact, and a
  final `ENTRYPOINT` or `CMD` that runs that artifact.
- Both shell and JSON runtime commands are supported, as are continued Dockerfile
  instructions, `-o value`, `-o=value`, local package targets, and local Go-file
  targets.
- Component identity comes from the shipped build artifact. Adjacent package docs
  provide purpose; bounded lifecycle vocabulary classifies HTTP services and
  background workers without inferring request flows.
- Example, demo, tool, test, and testdata paths are excluded. Incomplete build or
  runtime correlations and packages without `main()` are rejected.
- Standard and Konflux Dockerfiles are deduplicated with stable preference for the
  standard shipping source.
- Separate command rows are emitted only when the repository ships at least two
  commands, avoiding a redundant generic `manager` row for one-binary repositories.

The corpus emitted shipped command components in nine repositories:
`agents-operator`, `argo-workflows`, `batch-gateway`,
`data-science-pipelines`, `feast`, `model-registry`,
`models-as-a-service`, `odh-dashboard`, and `trustyai-service-operator`.

## Target Result

At commit `fac0c8d8c69369662d46edf1bfecacf3bd15b5d2`, `batch-gateway`
emits:

| Component | Type | Source |
|-----------|------|--------|
| `batch-gateway-apiserver` | Go HTTP Service | `docker/Dockerfile.apiserver:23` |
| `batch-gateway-gc` | Go Background Worker | `docker/Dockerfile.gc:14` |
| `batch-gateway-processor` | Go Background Worker | `docker/Dockerfile.processor:23` |

The accepted agent used the shortened identities `batch-apiserver`, `batch-gc`,
and `batch-processor`. The shipping artifacts and historical Markdown fixture use
the exact analyzer identities. Those three accepted additions are therefore
source-adjudicated and rejected during evidence-gated merge rather than retained as
duplicate aliases.

Accepted correction resolution improved from 4/11 to 7/11. The four remaining
corrections are the `llm-d inference gateway` Integration Point and Internal
Dependency plus API-route and observability-endpoint Authentication rows.

## Full Static Replay

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-runtime-commands-static-20260719T162833Z`

| Measure | Result |
|---------|-------:|
| Components analyzed | 90 |
| Static-analysis failures | 0 |
| Static-analysis wall time | 12.26s |
| Analyzer-sufficient components | 64 |
| Approved analyzer-only components | 32 |
| False nominations | 0 |
| Target corrections resolved or adjudicated | 7/11 |
| Analyzer identities retained | 8,492/8,497 (99.94%) |
| Accepted analyzer conflicts | 16 |
| Accepted analyzer row corrections | 5 |
| Unexplained analyzer conflicts | 0 |
| Unexplained missing analyzer rows | 0 |
| Structurally valid documents | 90/90 |
| Synthesis/structure quality | 90/90 |
| Required gates | PASS |

The accepted-production fixture retains 9,090/9,157 structured identities
(99.27%). This is three rows below the previous replay because the comparator treats
the three more precise `batch-gateway-*` build identities as different from the
accepted agent's shortened names. The source-backed correction is intentional and
is not hidden with a component-specific alias.

## Verification

- `GOCACHE=/tmp/arch-analyzer-go-cache go test ./...`: pass.
- `.venv/bin/ruff check lib scripts tests src/arch-analyzer`: pass.
- Deterministic Python suite excluding the credentialed strace test: 125 passed.
- Corpus preservation, structural, and synthesis gates: pass.
