# Python Dynamic Authentication Middleware Validation, 2026-07-20

## Decision

Do not approve `ogx` for analyzer-only generation. The fresh analyzer now extracts
5 source-backed authentication facts (up from 0), but `ogx` retains an independent
Internal Dependencies completeness blocker from unsupported shell and Swift surfaces.
The approved set remains at 36 with zero false nominations.

No routing changes; no paid matrix required. The 90-component static replay confirms
zero false nominations and zero approved-component regressions.

## Extraction Contracts

### ASGI Middleware Registration (`authentication.go`)

- `app.add_middleware(ClassName, ...)` calls are detected in Python files.
- The referenced class must be defined locally with a body containing Bearer
  header parsing (`Authorization`, `.startswith("Bearer ")`, `auth_header`),
  denial behavior (error sending, exception raising, 401/403 status), and
  either token validation (`validate_token()`) or a factory call
  (`create_*auth*`, `get_*provider*`, etc.).
- Classes matching `Quota` or `RateLimit` are excluded.
- Configuration conditions (`if config.server.auth:`) within 5 lines before
  registration are preserved in the emitted policy.
- Import statements without registration are not sufficient.

### Connected Provider Factory (`authentication.go`)

- Factory functions matching `(create|get|build|make)_*auth|provider*()` are
  collected when the middleware class body calls them.
- Each `return ClassName(...)` branch in the factory is resolved to a local class.
- The class must have concrete validation: `validate_token()` plus either
  JWT/JWKS constructs or HTTP client delegation.
- Disconnected providers (defined but not returned by any factory called by
  registered middleware) are excluded.

### Operation-Gating ABAC Enforcement (`authentication.go`)

- Calls to `is_action_allowed`, `check_permission`, `has_permission`, or
  `is_authorized` are detected only when their result gates an operation:
  `if not func()`, list-comprehension filtering, or `return func()`.
- Non-gating calls (logging, assignment without branching) are excluded.
- Action names are extracted from the second string argument.
- Repeated calls within the same class are grouped into a single fact with a
  combined action set.

### Semantic Deduplication (`routes.go`)

- Authentication facts are deduplicated by composite key
  `EnforcementPoint + "\x00" + Mechanism` instead of the prior first-row-only
  behavior.
- Results are sorted by Endpoint, EnforcementPoint, Mechanism for determinism.

### Coverage Accounting (`categorycoverage.go`)

- When Python authentication facts exist, the Python language limitation is
  suppressed (the signal scan results are accounted for by the extracted facts).
- A fact-level relationship accounting limitation is added only for unaccounted
  Python signal-scan matches.
- All unrelated limitations (credential ambiguity, unsupported runtimes) are
  preserved.

## Source Audit

At `5d65c017b088eab0f40c88fc92e7b4aac9834a27`, the analyzer extracts 5
authentication facts from ogx:

| # | Endpoint | Methods | Mechanism | Enforcement Point | Source |
|---|----------|---------|-----------|-------------------|--------|
| 1 | Agent persistence operations | create, read | ABAC enforcement (is_action_allowed) | Agent persistence control flow | persistence.py:55 |
| 2 | HTTP API | All | Bearer token | ASGI middleware (AuthenticationMiddleware) | server.py:450 |
| 3 | HTTP API | All | External HTTP authentication delegation | Auth provider (CustomAuthProvider via factory) | auth_providers.py:263 |
| 4 | HTTP API | All | OAuth2 JWT/JWKS or token introspection | Auth provider (OAuth2TokenAuthProvider via factory) | auth_providers.py:97 |
| 5 | Routing table operations | create, delete, read | ABAC enforcement (is_action_allowed) | Routing table control flow | common.py:171 |

Coverage status changed from `fact_count: 0` to `fact_count: 5` with status
remaining `partial` due to 9 unaccounted credential references and unsupported
runtime surfaces.

## Hypothesis Dispositions

| # | Hypothesis | Source | Disposition |
|---|-----------|--------|-------------|
| H1 | AuthenticationMiddleware registered via `app.add_middleware` | server.py:450 | Confirmed — conditional on `config.server.auth`, class in auth.py |
| H2 | Auth provider factory `create_auth_provider` | auth_providers.py:42 | Confirmed — returns OAuth2TokenAuthProvider or CustomAuthProvider |
| H3 | OAuth2TokenAuthProvider (JWT/JWKS) | auth_providers.py:97 | Confirmed — `jwt.decode`, `get_unverified_header`, token introspection |
| H4 | CustomAuthProvider (HTTP delegation) | auth_providers.py:263 | Confirmed — `httpx.AsyncClient` for external auth delegation |
| H5 | ABAC `is_action_allowed` in routing/persistence | common.py:171, persistence.py:55 | Confirmed — `if not` gating with action extraction |
| H6 | QuotaMiddleware | quota.py | Not independent — rate limiting reads auth identity but does not authenticate |

## Negative Controls

- QuotaMiddleware: Not emitted. Matches `pyQuotaRe` exclusion.
- UnusedAuthProvider: Not emitted. Disconnected from factory and middleware.
- Import-only signals: Not emitted. No `add_middleware` registration.
- Non-gating ABAC (logging, assignment): Not emitted. No `if not`/`return`/filter.
- Test/example code: Not scanned (walkPythonFiles skips test directories).

## Reuse Assessment

The task's reuse table listed three potential corpus controls:

| Component | Prior auth facts | Fresh auth facts | Change |
|-----------|:----------------:|:----------------:|--------|
| `mlflow` | 0 | 0 | None — no `add_middleware` registration found |
| `llm-d-latency-predictor` | 4 | 4 | None — existing Go-based auth unchanged |
| `NeMo-Guardrails` | 1 | 1 | None — existing auth unchanged |

No component other than `ogx` gained or lost authentication facts.

## Corpus Replay

90-component static replay at
`tmp/architecture-corpus-runs/rhoai.next-20260720T173035Z-static`:

| Measure | Result |
|---------|-------:|
| Components extracted | 90/90 |
| Extraction failures | 0 |
| Authentication array changes | 1 (ogx: 0→5) |
| Category coverage changes | 5 (ogx auth + 4 preexisting integration_points) |
| Eligible components | 36 |
| True nominations | 36 |
| False nominations | 0 |
| Approved set match | 36/36 (100%) |

The four non-auth coverage changes (feast, kserve, kserve-autogluon-server,
modelmesh-runtime-adapter) are preexisting `integration_points` fact-count
improvements from prior uncommitted extractor work, unrelated to this task's
authentication changes.

## Validation Suites

| Suite | Result |
|-------|--------|
| Focused Go tests (`./internal/pythonsource`, `./internal/extractor`) | PASS |
| Full Go tests (`go test ./...`) | PASS (12 packages) |
| Go vet | PASS |
| Ruff | All checks passed |
| Python tests (`make test-python`) | 123 passed |
