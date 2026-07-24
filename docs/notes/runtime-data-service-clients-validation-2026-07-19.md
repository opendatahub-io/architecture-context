# Runtime Data-service Clients Validation, 2026-07-19

## Decision

Keep `batch-gateway` agent-routed. The analyzer now resolves four of its eleven
accepted structured corrections, but seven exact source-backed gaps remain. Routing
did not change, so this tranche required no paid production-path matrix.

## Generic Extraction

- A repository-wide Go call graph starts at non-test executable `main` functions
  and follows local functions, imported project functions, and statically bounded
  local methods.
- Function identities include the Go package. Method identities also include the
  receiver type, preventing a reachable method from selecting an unrelated method
  with the same name in the same package.
- Only runtime-reachable standard constructors emit facts: pgx
  `NewWithConfig`, go-redis `NewClient`, AWS SDK S3 `NewFromConfig`, and OTLP/gRPC
  trace exporter `New`.
- Disconnected packages, test-only code, same-named functions in other packages,
  and same-named methods on unrelated receivers are negative controls.
- Transport fields preserve source uncertainty. PostgreSQL, Redis, S3, and OTLP
  endpoints remain runtime-configured; the analyzer does not manufacture default
  ports or assume TLS for a configurable S3 endpoint.

The full corpus found 18 constructor sites producing 17 deduplicated Integration
Point rows across ten components. Every emitted row remains source-backed and
runtime-reachable.

## Target Result

At commit `fac0c8d8c69369662d46edf1bfecacf3bd15b5d2`, `batch-gateway`
emits:

| Component | Source |
|-----------|--------|
| PostgreSQL | `internal/database/postgresql/db_postgresql.go:116` |
| Redis/Valkey | `internal/util/redis/redis_client.go:144` |
| S3-compatible storage | `internal/files_store/s3/client.go:116` |
| OpenTelemetry Collector | `internal/util/otel/otel.go:94` |

Accepted correction resolution improved from 0/11 to 4/11. The remaining seven
corrections are the three executable components, two inbound Authentication
surfaces, and the inference-gateway Integration Point and Internal Dependency.

## Full Static Replay

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-runtime-data-clients-static-20260719T160816Z`

| Measure | Result |
|---------|-------:|
| Components analyzed | 90 |
| Static-analysis failures | 0 |
| Static-analysis wall time | 11.92s |
| Analyzer-sufficient components | 64 |
| Approved analyzer-only components | 32 |
| False nominations | 0 |
| Target corrections resolved | 4/11 |
| Analyzer identities retained | 8,471/8,476 (99.94%) |
| Accepted analyzer conflicts | 16 |
| Accepted analyzer row corrections | 5 |
| Unexplained analyzer conflicts | 0 |
| Unexplained missing analyzer rows | 0 |
| Structurally valid documents | 90/90 |
| Synthesis/structure quality | 90/90 |
| Required gates | PASS |

The accepted-production fixture retains 9,093/9,157 structured identities
(99.30%). A replay also exposed nondeterministic ordering for Integration Point rows
sharing the same component and interaction type. The normalizer now sorts through
all rendered columns, with a regression test for tied identities.

## Verification

- `GOCACHE=/tmp/arch-analyzer-go-cache go test ./...`: pass.
- `.venv/bin/ruff check .`: pass.
- Deterministic Python suite: 124 passed.
- Credentialed `tests/test_strace_agent.py`: external Claude CLI startup timed out
  under restricted network; unrelated to analyzer behavior.
- Corpus preservation, structural, and synthesis gates: pass.
