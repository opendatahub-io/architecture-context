# Go HTTP Authentication Boundaries Validation, 2026-07-19

## Decision

Approve `batch-gateway` for analyzer-only component generation. A project-owned Go
pass now resolves both remaining Authentication additions from closed `net/http`
mux boundaries. No other corpus component matched the contract.

## Extraction Contract

- A concrete `http.NewServeMux` must be returned through a server struct field,
  attached to `http.Server.Handler`, served by `Serve`, `ServeTLS`, or
  `ListenAndServe`, and constructed by a caller that invokes that lifecycle method.
- Registration helpers are recognized from their implementation: `GetRoutes`
  enumeration, method-and-pattern registration, and complete variadic middleware
  application must all be visible.
- Handler constructors must resolve to concrete local types whose `GetRoutes`
  methods return a complete static route inventory. Handler bodies may not contain
  authentication or authorization enforcement.
- Every middleware expression must resolve to one unique project-local declaration,
  pass the request to its handler parameter, and contain no credential enforcement.
  Imported, ambiguous, dynamically mutated, or conditional unknown middleware keeps
  the mux unresolved.
- Direct standard-library pprof registrations can participate in the closed mux;
  unknown imported direct handlers cannot.

Focused negative controls reject credential enforcement, dynamic route returns,
disconnected constructors, imported middleware, and conditionally mutated
middleware slices.

## Target Result

At `fac0c8d8c69369662d46edf1bfecacf3bd15b5d2`, the analyzer emits:

| Endpoint | Methods | Mechanism | Source |
|----------|---------|-----------|--------|
| `API server routes` | `POST, GET, DELETE` | None | `internal/apiserver/server/server.go:98` |
| `Observability endpoints (/health, /ready, /metrics)` | `GET, HEAD` | None | `internal/apiserver/server/server.go:108` |

The accepted agent recorded only `GET` for observability. Source explicitly
registers `HEAD` for health and readiness at
`internal/apiserver/health/health_handler.go:41-53` and
`internal/apiserver/readiness/readiness_handler.go:45-57`. The stale row is therefore
rejected through `lib/analyzer_correction_adjudications.json` and the analyzer keeps
the complete method set.

## Eligibility Correction

The eligibility harness previously filtered components using historical agent-run
readiness before reading fresh analyzer output. That hid components such as
`batch-gateway` that moved from `partial` to `sufficient`. Classification now uses
fresh analyzer JSON for readiness and retains historical run data only for telemetry.
A regression test covers that transition.

## Full Static Replay

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-go-http-auth-static-20260719T173651Z`

| Measure | Result |
|---------|-------:|
| Components analyzed | 90 |
| Static-analysis failures | 0 |
| Static-analysis wall time | 12.36s |
| Fresh analyzer-sufficient components | 64 |
| Approved analyzer-only components | 33 |
| False nominations | 0 |
| Target accepted corrections | 11/11 resolved or adjudicated |
| Accepted-corpus structured identities | 9,089/9,157 (99.26%) |
| Analyzer identities retained | 8,496/8,501 (99.94%) |
| Accepted analyzer conflicts | 16 |
| Accepted analyzer row corrections | 5 |
| Unexplained conflicts or missing rows | 0 |
| Structural validation | 90/90 |
| Synthesis/structure quality | 90/90 |
| Required gates | PASS |

## Production-Path Matrix

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-go-http-auth-matrix-20260719T174250Z`

The one-component matrix routed `batch-gateway` analyzer-only, invoked zero agents,
retained 39/39 analyzer identities, passed structural and synthesis validation, and
completed in 2.50 seconds.

## Verification

- `go test ./...`: pass.
- `go vet ./...`: pass.
- `.venv/bin/ruff check lib scripts tests src/arch-analyzer`: pass.
- Deterministic Python suite excluding the credentialed strace test: 126 passed.
