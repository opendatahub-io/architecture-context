# Task: Extract Python Dynamic Authentication Middleware

## Goal

Resolve the missed Authentication facts in `ogx` and potentially other Python
server components by extracting dynamic middleware registration, factory-dispatched
auth providers, and function-call-level ABAC enforcement.

## Context

The completeness-only candidate audit (2026-07-19) found six source-backed
authentication facts in `ogx` that the analyzer's `authentication/v1` contract
could not extract. The analyzer correctly identified the Python server framework,
credential references, and dynamic auth composition as limitations but produced
`fact_count: 0`.

The current `python-authentication-signal-scan` check detects authentication
patterns (Authorization headers, Bearer tokens, OAuth2 constructs) but cannot
promote them to structured facts because:

- Middleware registration (`app.add_middleware(AuthenticationMiddleware, ...)`) is
  a dynamic Python call, not a declarative configuration.
- Auth provider selection is factory-dispatched at runtime from YAML config.
- ABAC enforcement uses function-call patterns in routing table code.

## Bounded Start

Do not begin this task with broad codebase or checkout exploration, and do not spawn
general-purpose research agents. The implementation and source surfaces have already
been mapped below. Read the listed files first and widen the search only when a
specific test failure or unresolved evidence chain requires it.

- Checkout: `/data/checkouts/red-hat-data-services.next/ogx`
- Revision: `5d65c017b088eab0f40c88fc92e7b4aac9834a27`
- The checkout is intentionally dirty; do not reset it.
- Current authoritative replay:
  `tmp/architecture-corpus-runs/rhoai.next-20260720T103625Z-3372001`
- Current analyzer snapshot:
  `analyzer/rhoai.next/ogx.json` under that replay.
- Current merge report:
  `logs/agents/ogx.merge.json` and `.md` under that replay.
- Current state: zero Authentication facts; `authentication/v1` is partial because
  Python auth composition, credential classification, and unsupported runtime
  surfaces remain unresolved. `ogx` also has an independent Internal Dependencies
  completeness blocker, so this task must not force analyzer-only eligibility.

## Evidence

`ogx` at `5d65c017b088eab0f40c88fc92e7b4aac9834a27`:

| # | Fact | Location | Pattern |
|---|------|----------|---------|
| 1 | Config-conditional ASGI `AuthenticationMiddleware` | `llama_stack/distribution/server/server.py:448-450` and `server/auth.py:81-103` | Registration, Bearer parsing, and provider invocation |
| 2 | `OAuth2TokenAuthProvider` (JWT/JWKS or RFC 7662) | `llama_stack/distribution/server/auth_providers.py:97-261` | JWT verification or token introspection, selected by configuration |
| 3 | `CustomAuthProvider` (external endpoint) | `llama_stack/distribution/server/auth_providers.py:263-345` | Factory-selected HTTP authentication delegation |
| 4 | ABAC on routing-table CRUD | `llama_stack/distribution/routing_tables/common.py:171-218` | Denial/filter control flow around `is_action_allowed()` |
| 5 | ABAC on session persistence | `llama_stack/providers/inline/agents/meta_reference/persistence.py:45-85` | Denial/filter control flow around `is_action_allowed()` |
| 6 | `QuotaMiddleware` authenticated/anonymous policy | `llama_stack/distribution/server/quota.py:21-111` and `server.py:463-486` | Reads authenticated identity but is not itself proof of authentication |

Additionally, nine credential references were classified: eight are outbound API
keys for third-party services (not inbound auth), one is a build-only script.

Treat these six rows as source-audit hypotheses. In particular, adjudicate the quota
row if it is policy/rate-limiting context rather than an independent Authentication
fact. Do not invent route identities when dynamic route registration prevents a
closed route inventory.

## Analyzer Implementation Map

Read these files in order:

1. `src/arch-analyzer/internal/pythonsource/routes.go`
   - `extractPythonSource` is the only current Python source-to-fact pass.
   - `authMarker` emits one generic fact from constructor-like markers.
   - `dedupeAuthentication` currently returns only the first fact and must not
     silently collapse distinct middleware, provider, and authorization facts.
2. `src/arch-analyzer/internal/pythonsource/pythonsource.go`
   - `Result.Authentication` already carries `[]model.AuthenticationFact`.
   - `walkPythonFiles` already excludes tests, docs, examples, generated protobuf,
     oversized files, and dependency trees.
3. `src/arch-analyzer/internal/extractor/extractor.go:132-144`
   - Python Authentication facts are already appended to `model.Input`; no new
     extractor wiring should be needed.
4. `src/arch-analyzer/internal/extractor/categorycoverage.go`
   - `authenticationCoverage` and `scanPythonAuthenticationSignals` currently flag
     every detected Python construction as unaccounted. Reuse the fact classifier so
     extracted signals are accounted without hiding genuinely unresolved signals.
   - Do not make unsupported shell/native runtime surfaces complete as part of this
     Authentication task.
5. `src/arch-analyzer/internal/model/input.go` and
   `src/arch-analyzer/internal/normalize/normalize.go:301-307`
   - `AuthenticationFact` and Markdown normalization already contain the required
     fields. A schema change is not expected unless implementation proves otherwise.
6. `src/arch-analyzer/internal/pythonsource/pythonsource_test.go`, its
   `testdata/repository/widget_api/` fixture, and
   `src/arch-analyzer/internal/extractor/categorycoverage_test.go`
   - Extend these tests rather than constructing a separate test harness.

A focused implementation may add
`src/arch-analyzer/internal/pythonsource/authentication.go` to keep bounded auth
classification separate from route extraction. Do not add `ogx`, Llama Stack,
provider class names, or repository paths as allowlists.

## Execution Order

1. Build the current binary and reproduce the zero-fact `ogx` result:

   ```bash
   make -C src/arch-analyzer build
   bin/arch-analyzer extract /data/checkouts/red-hat-data-services.next/ogx \
     --distribution rhoai.next --output /tmp/ogx-auth-before.json
   jq '{authentication, category_coverage: .category_coverage.authentication}' \
     /tmp/ogx-auth-before.json
   ```

2. Read only the mapped analyzer and `ogx` source files. Record a disposition for
   each of the six hypotheses before implementing broad pattern matching.
3. Implement the smallest reusable classifier that closes the proven registration,
   provider, and enforcement chains.
4. Add focused fixture tests and run the focused packages before the full suites.
5. Extract `ogx` again and inspect exact Authentication rows and coverage. Do not
   broaden completeness merely to approve it.
6. Run the 90-component static replay. Run a paid bounded matrix only if routing
   changes; do not run another paid full corpus for an unchanged route.

## Scope

### Python middleware registration extraction

Detect `app.add_middleware(SomeMiddleware, ...)` patterns in FastAPI/Starlette
applications, then resolve the local middleware class enough to prove Bearer/API-key
parsing and denial or provider invocation. A class name containing `Auth` is a lead,
not sufficient evidence. Preserve configuration conditions in the emitted policy.

### Python auth provider factory extraction

Detect closed local factory branches that construct concrete auth provider
implementations and are called by a registered middleware. Emit only providers with
source-proven token validation or external authentication delegation; unselected or
disconnected class definitions are insufficient.

### Python ABAC/authorization enforcement extraction

Detect function calls to authorization enforcement functions
(`is_action_allowed`, `check_permission`, etc.) only when their result gates an
operation through denial, early return, exception, or filtering. A call name alone
does not prove enforcement. Group repeated calls by stable protected surface and
operation set rather than emitting one row per call site.

### Reuse assessment

Only after the `ogx` fixture and extraction are correct, replay the corpus and inspect
whether the same generic contract applies to:

| Component | Pattern | Potential |
|-----------|---------|-----------|
| `mlflow` | FastAPI with potential auth middleware | Corpus regression/control |
| `llm-d-latency-predictor` | FastAPI server | Corpus regression/control |
| `NeMo-Guardrails` | FastAPI actions server | Corpus regression/control |

## Negative Controls

- Must not infer auth from framework imports without middleware registration.
- Must not infer auth from middleware or provider class names without inspected
  enforcement behavior and a reachable registration/factory chain.
- Must not treat rate limiting as authentication merely because it distinguishes
  authenticated and anonymous identities. Emit it only as an auth-dependent policy
  after a separate upstream authentication chain is proven.
- Must not treat outbound API keys as inbound authentication facts.
- Must not mark config-conditional auth as unconditionally present — document the
  condition.
- Must not accept auth classes or `is_action_allowed` calls found only in tests,
  docs, examples, generated files, or disconnected modules.
- Must not emit one authorization fact per repeated call, or collapse semantically
  distinct middleware/provider/ABAC facts into the current first-row behavior.
- Must not claim complete route-level coverage when routes are dynamically composed.

## Complexity

High. Python dynamic dispatch and factory patterns are fundamentally harder to
extract deterministically than Go's typed middleware chains. The extraction must
be conservative: produce a fact only when the middleware class, registration call,
and auth-related semantics can all be confirmed statically. Dynamic provider
selection (OAuth2 vs Custom) should produce a fact for each concrete provider class
found, noting runtime selectability.

## Required Validation

```bash
cd src/arch-analyzer
GOCACHE=/tmp/arch-analyzer-go-cache go test ./internal/pythonsource ./internal/extractor
GOCACHE=/tmp/arch-analyzer-go-cache go test ./...
GOCACHE=/tmp/arch-analyzer-go-cache go vet ./...
cd ../..
uv run ruff check .
make test-python
```

## Acceptance Criteria

- [ ] Record source-backed dispositions for all six hypotheses; extraction is not
  required for invalid or non-independent rows.
- [ ] Extract registered, configuration-conditional Python authentication
  middleware without class-name-only inference.
- [ ] Extract only factory providers connected to that middleware and backed by
  concrete validation/delegation behavior.
- [ ] Extract ABAC enforcement only from operation-gating control flow and group it
  into stable protected surfaces.
- [ ] Replace first-row-only Python auth deduplication with deterministic semantic
  identities and ordering.
- [ ] Make coverage account for extracted Python auth signals while retaining every
  unrelated limitation, credential ambiguity, and unsupported runtime surface.
- [ ] Add positive and negative tests for registration, conditional configuration,
  disconnected providers, import/name-only signals, non-gating calls, test-only
  code, repeated enforcement, quota distinction, deduplication, and coverage.
- [ ] Run the focused and full Go tests, Go vet, Ruff, and the Python suite above.
- [ ] Run a fresh 90-component static replay with zero false nominations and no
  approved-component regression.
- [ ] Source-audit every newly nominated component before approval. Run a bounded
  production matrix only if routing changes.
- [ ] Write a validation note, reconcile `PLAN.md`, the ownership goal, and residual
  register, then move this task to `docs/tasks/done/`.

## Status

Done. Validation: [Python dynamic authentication middleware validation, 2026-07-20](../../notes/python-dynamic-authentication-middleware-validation-2026-07-20.md).
