# Task: Extract Runtime Data-service Clients

## Goal

Extract source-backed PostgreSQL, Redis/Valkey, S3-compatible storage, and
OpenTelemetry Collector integrations from runtime-reachable Go constructors,
starting with `batch-gateway`.

## Context

The newly analyzer-sufficient `batch-gateway` still has eleven accepted structured
additions. Four integration rows use standard Go client constructors and are a
smaller reusable tranche than its command topology, custom inference client, and
inbound endpoint semantics.

Constructor presence alone is insufficient because repositories commonly contain
unused adapters, examples, and support packages. The extractor needs a
repository-wide call graph rooted at executable `main` functions and must follow
local and imported project calls to the standard client construction site.

## Acceptance Criteria

- [x] Build a package-qualified runtime call graph rooted at non-test Go `main`
  functions and follow local, method, and imported project calls.
- [x] Emit PostgreSQL only for a runtime-reachable pgx pool constructor.
- [x] Emit Redis/Valkey only for a runtime-reachable go-redis client constructor.
- [x] Emit S3-compatible storage only for a runtime-reachable AWS SDK S3 client
  constructor.
- [x] Emit OpenTelemetry Collector only for a runtime-reachable OTLP/gRPC trace
  exporter constructor.
- [x] Reject disconnected constructors, test-only source, and same-named functions
  from unrelated packages.
- [x] Render the four clients as generic Integration Points with stable protocol and
  transport semantics.
- [x] Measure the accepted `batch-gateway` correction reduction without approving
  the component while other residual categories remain.
- [x] A fresh 90-component replay has zero false approved nominations and passes
  preservation, structural, and synthesis gates.

## Files Likely Involved

- `src/arch-analyzer/internal/gosource/`
- `src/arch-analyzer/internal/model/input.go`
- `src/arch-analyzer/internal/platformfacts/platformfacts.go`
- `docs/notes/analyzer-residual-agent-gaps.md`

## Status

Done

## Baseline Evidence

- Replay:
  `tmp/architecture-corpus-runs/rhoai-next-managed-subcomponent-static-20260719T153953Z`
- Checkout: `fac0c8d8c69369662d46edf1bfecacf3bd15b5d2`
- PostgreSQL: `internal/database/postgresql/db_postgresql.go:116`
- Redis/Valkey: `internal/util/redis/redis_client.go:144`
- S3: `internal/files_store/s3/client.go:116`
- OTLP/gRPC: `internal/util/otel/otel.go:94`

## Progress

- Source audit separated four standard runtime-client relationships from the seven
  remaining custom topology, inference, and inbound endpoint gaps.
- The package- and receiver-qualified call graph follows local functions, imported
  project functions, and unambiguous local methods from executable `main` roots.
  Disconnected packages, tests, same-named functions in other packages, and
  same-named methods on unrelated receiver types are regression-tested absences.
- The accepted `batch-gateway` commit emits all four intended source-backed clients
  at the audited constructor lines. Runtime-configured ports and encryption remain
  explicit; the S3 endpoint is not assumed to be HTTPS because source allows an
  arbitrary configured endpoint.
- Accepted `batch-gateway` corrections improved from 0/11 to 4/11. The remaining
  seven corrections are three command components, two Authentication surfaces,
  and the inference-gateway Integration Point plus Internal Dependency.
- The final 90-component replay extracted 90/90 repositories in 11.92 seconds,
  retained 8,471/8,476 analyzer identities, reported zero false approved
  nominations, and passed structural and synthesis checks for 90/90 documents.
  Routing did not change, so no paid matrix was run.
