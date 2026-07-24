# Completeness-Only Candidate Audit, 2026-07-19

## Decision

Approve zero components for analyzer-only routing. All three completeness-only
candidates have blocking categories that cannot be resolved without new contracts
or extractor work. None of the three components is promoted to analyzer-only.

| Component | Category | Outcome | Action |
|-----------|----------|---------|--------|
| `guardrails-regex-detector` | Integration Points | New contract required | Integration Points has no discovery contract; source audit proves emptiness but the routing system cannot recognize it |
| `model-registry` | Internal Dependencies | Missed source-backed fact | KServe controller dependency exists with construction and call evidence |
| `ogx` | Authentication | Partial — unsupported dynamic behavior | 6 source-backed auth facts exist; dynamic Python middleware is beyond current extraction |
| `ogx` | Internal Dependencies | Partial — unsupported languages | Source audit confirms emptiness but shell/C-family surfaces prevent formal completeness |

## Authoritative Replay

`tmp/architecture-corpus-runs/rhoai-next-cli-kubernetes-static-20260719T180727Z`

---

## guardrails-regex-detector

### Revision

`5c6116749e66a3496f7a5ac7427219f294df7ec3`

### Shipped Entrypoints

One binary: `regex-detector`, built from `src/main.rs` (Cargo.toml `[[bin]]`).
Dockerfile ships it as `/app/bin/regex-detector`. Pure inbound HTTP server using
Axum on `HOST`:`HTTP_PORT` (default `0.0.0.0:8080`) with two routes:

- `GET /health` — returns `"healthy"`
- `POST /api/v1/text/contents` — accepts JSON with text and regex patterns, returns
  match results

### Runtime Surfaces Searched

| Surface | Files |
|---------|-------|
| Rust source (entire codebase) | `src/main.rs` (46 lines), `src/detectors.rs` (167 lines) — the only 2 `.rs` files |
| Cargo.toml | 18 lines, 8 direct dependencies |
| Cargo.lock | Checked for network client crate names |
| Dockerfile | 45 lines, confirmed shipped binary path |
| Kubernetes manifests | None exist in the repository |
| Helm/Kustomize | None exist |
| YAML/JSON config | Only `component-architecture.json` (generated artifact) |

### Negative Controls

- No HTTP client crates: `reqwest`, `hyper` (as client), `tonic`, `surf`, `ureq`,
  `isahc`, `attohttpc`, `curl` — zero matches in `src/`. `hyper` in Cargo.lock is
  a transitive Axum dependency (inbound server only).
- No HTTP client construction: `Client::new`, `ClientBuilder`, `HttpClient`,
  `http::Request` — zero matches.
- No outbound URL literals: `http://`, `https://`, `localhost`, `127.0.0.1` — zero
  matches in `src/`.
- No database connections: `sqlx`, `diesel`, `postgres`, `mysql`, `sqlite`,
  `mongodb`, `redis`, `Connection`, `Pool` — zero matches.
- No message queues: `kafka`, `rabbitmq`, `amqp`, `nats`, `pulsar`, `mqtt` — zero
  matches.
- No gRPC: `grpc`, `proto`, `prost`, `tonic` — zero matches.
- Only two env vars read: `HTTP_PORT` and `HOST` (bind address only).
- Only network call: `tokio::net::TcpListener::bind` — inbound listener, not
  outbound.
- No `.send()`, `.fetch()`, `.request()`, `.execute()` methods in source.

### Current Limitations

- Macro expansion not performed (Axum routing macros, `#[tokio::main]`). However,
  the codebase is 213 total lines of Rust, fully manually inspected.
- Deployment configuration is external. The README states integration with FMS
  Guardrails Orchestrator, but that is inbound — the orchestrator calls this
  service's POST endpoint. This service makes zero outbound calls.

### Discovered Facts

Zero Integration Points. This is a pure request-response regex processor with no
outbound network connections. All regex matching is in-process. No files read at
runtime (patterns provided in request payload or compiled constants).

### Analyzer Coverage State

```json
{
  "authentication": {"status": "partial", "fact_count": 2},
  "internal_dependencies": {"status": "complete", "fact_count": 0}
}
```

Internal Dependencies is already `complete` with fact_count 0. Authentication is
`partial` with 2 facts and 4 unaccounted inbound surfaces. Neither of these is
the blocking category.

**Integration Points** has no entry in `category_coverage` because no discovery
contract exists for this category. The routing system requires Integration Points
to be populated (at least one row) or complete-empty under a recognized contract.
Neither condition can be satisfied.

### Decision

**4 — A new generic completeness contract is required.**

The source audit proves Integration Points is legitimately empty: a standalone
regex processor with zero outbound connections, zero external API calls, and zero
runtime file I/O. But the analyzer has no `integration-points` discovery contract,
so the routing system cannot distinguish "empty because complete" from "empty
because not evaluated."

A focused task is required to design an Integration Points discovery contract
analogous to `authentication/v1` and `internal-platform-dependencies/v1`.

---

## model-registry

### Revision

`62733189ea906eeb88e955052c9b5da10405115a`

### Shipped Entrypoints

| Binary | Source | Language |
|--------|--------|----------|
| `model-registry` | `main.go` | Go |
| `bff` | `clients/ui/bff/cmd/main.go` | Go + TypeScript (static frontend) |
| `manager` | `cmd/controller/main.go` | Go |
| `mr-storage-initializer` | `cmd/csi/main.go` | Go |
| `async-upload` | `jobs/async-upload/job/entrypoint.py` | Python |

### Runtime Surfaces Searched

- All Go `main.go` entrypoints (4 shipped binaries)
- `pkg/inferenceservice-controller/controller.go` (runtime controller logic)
- `clients/ui/bff/internal/integrations/` (BFF HTTP client layer)
- `clients/ui/bff/internal/repositories/` (BFF repository with label references)
- `jobs/async-upload/job/entrypoint.py` and `mr_client.py` (Python job)
- All `manifests/kustomize/` directories (24 kustomization.yaml files)
- All Dockerfiles (7 total)
- 1,209 runtime source/config files scanned against 23 platform aliases

### Nine Active Platform Aliases

The analyzer flagged 9 references as "runtime source/config reference." Each is
classified below:

| # | File | Alias | Classification |
|---|------|-------|----------------|
| 1 | `clients/ui/bff/internal/api/model_registry_settings_handler.go` | `gatewayconfig` | False positive — Go struct type name within model-registry's own BFF data models |
| 2 | `clients/ui/bff/internal/integrations/kubernetes/k8mocks/base_testenv.go` | `kubeflow.org` | Test fixture — in `k8mocks/` directory |
| 3 | `clients/ui/bff/internal/integrations/kubernetes/shared_k8s_client.go` | `kubeflow.org` | Self-referential — model-registry reads its own `modelregistry.kubeflow.org/job-type` labels |
| 4 | `clients/ui/bff/internal/models/model_registry_kind.go` | `gatewayconfig` | False positive — Go struct definition in own type system |
| 5 | `clients/ui/bff/internal/repositories/model_transfer_jobs.go` | `kubeflow.org` | Self-referential — reads own `modelregistry.kubeflow.org/*` labels/annotations (17 label reads) |
| 6 | `clients/ui/frontend/src/__mocks__/mockModelRegistryKind.ts` | `modelregistry.opendatahub.io` | Test mock — in `__mocks__/` directory |
| 7 | `cmd/controller/main.go` | `kubeflow.org` | Naming convention — LeaderElectionID string `"a7d60e25.kubeflow.org"` |
| 8 | `cmd/csi/samples/modelregistry.clusterstoragecontainer.yaml` | `serving.kserve.io` | Sample — in `samples/` directory |
| 9 | `jobs/async-upload/samples/sample_job_s3_to_oci.yaml` | `kubeflow.org` | Sample — in `samples/` directory |

All 9 are accounted for. None represents a missed Internal Dependency.

### Kustomize Limitations

Three unresolved Kustomize features:

| Feature | Occurrences | Content | Dependencies hidden |
|---------|-------------|---------|---------------------|
| configMapGenerator | 8 files | Controller label/annotation names (`modelregistry.kubeflow.org/*`, all self-referential), catalog sources, DB connection config | None |
| secretGenerator | 5 files | Database credentials (`model-catalog-postgres`, `model-catalog-hf-api-key`) | None |
| Inline patches | Multiple | Deployment patches (metrics, Istio port exclusions) | None |

### Unsupported Runtime Languages

**Python** (`jobs/async-upload/`): Shipped as container image. Constructs
`ModelRegistry` client to model-registry's own REST API (self-referential). Uses
HuggingFace Hub, ORAS, and S3 for model download/upload. None are internal
platform dependencies.

**TypeScript** (`clients/ui/frontend/`): Static frontend served by BFF. Contains
`opendatahub.io/recommended-accelerators` annotation type definition for displaying
metadata. Passive Kubernetes annotation reading, not a service dependency.

Neither unsupported language surface hides internal platform dependencies.

### Discovered Facts

**One genuine Internal Dependency: KServe.**

The `manager` binary (controller, `cmd/controller/main.go`) watches, reads, and
writes KServe InferenceService CRDs:

| Evidence | Location | Detail |
|----------|----------|--------|
| Scheme registration | `cmd/controller/main.go:111` | `kservev1beta1.AddToScheme(scheme)` |
| Conditional gate | `cmd/controller/main.go:138` | `INFERENCE_SERVICE_CONTROLLER == "managed"` env var |
| Watch construction | `cmd/controller/internal/controllers/inferenceservice_controller.go:44` | `For(&kservev1beta1.InferenceService{})` |
| Watch construction | `pkg/inferenceservice-controller/controller.go:251` | `For(&kservev1beta1.InferenceService{})` |
| Runtime Get | `pkg/inferenceservice-controller/controller.go:96` | `r.client.Get(ctx, req.NamespacedName, isvc)` |
| Runtime Update | `pkg/inferenceservice-controller/controller.go:155,181,241` | `r.client.Update(ctx, isvc)` |
| RBAC manifest | `manifests/kustomize/options/controller/rbac/role.yaml:16,26` | ClusterRole grants `serving.kserve.io/inferenceservices` get/list/watch/update/patch |

This is not inferred from `go.mod` alone. It is backed by scheme registration,
controller-runtime Watch construction, and concrete Get/Update operations on KServe
CRDs at runtime.

The dependency is conditional (gated by `INFERENCE_SERVICE_CONTROLLER == "managed"`
env var) but when enabled, it is a hard runtime dependency.

### Analyzer Alias Classification Gap

The alias scanner classified `cmd/controller/internal/controllers/inferenceservice_controller.go`
as "commented configuration" for `serving.kserve.io`. The raw API group string
appears in a Go import comment, but the runtime code uses imported Go types
(`kservev1beta1.InferenceService{}`) rather than the raw string. The CRD watch
extractor did not extract this dependency, likely because:

- The controller setup is in an imported package (`internal/controllers/`), not
  directly in `main.go`
- The conditional env-var gate may prevent recognition

The merge process also rejected the agent-proposed KServe row on formal grounds
("candidate-only row has no exact evidence record"), not on substantive analysis.

### Analyzer Coverage State

```json
{
  "internal_dependencies": {
    "status": "partial",
    "fact_count": 0,
    "limitations": [
      "9 active platform alias references require relationship accounting",
      "kustomize resolution is partial: configMapGenerator not resolved",
      "kustomize resolution is partial: inline patches skipped",
      "kustomize resolution is partial: secretGenerator not resolved",
      "unsupported runtime source languages require platform dependency analysis"
    ]
  }
}
```

### Decision

**2 — Missed source-backed fact requiring generic extraction.**

KServe is a genuine Internal Dependency with construction and call evidence. The
empty table is not legitimately empty. The nine active aliases are all accounted
for (false positives, self-referential labels, test/mock/sample data). The
Kustomize limitations do not hide dependencies. The unsupported language surfaces
(Python, TypeScript) do not contain platform dependencies.

Resolution requires:

1. The CRD watch extractor must follow controller-runtime registrations into
   imported packages, not just `main.go`.
2. The alias scanner should classify test/mock directories, sample directories,
   self-referential labels, and Go struct type names more precisely.

A focused pending task is created for this extraction.

---

## ogx

### Revision

`5d65c017b088eab0f40c88fc92e7b4aac9834a27`

### Shipped Entrypoints

| Entry point | Module | Role |
|-------------|--------|------|
| `llama_stack.cli.llama:main` | CLI | Command-line interface |
| `llama_stack.distribution.server.server` | FastAPI | Primary runtime server |
| `llama_stack.distribution.ui.app` | Streamlit | Optional UI (requires `[ui]` extra) |

### Runtime Surfaces Searched

- All `.py` files under `llama_stack/` (shipped Python package)
- All `.sh` files (12 total)
- All `.h` and `.swift` files (5 total, under `llama_stack/providers/inline/ios/`)
- `pyproject.toml`, `requirements.txt`
- YAML template/run configs under `llama_stack/templates/`
- Kubernetes examples under `docs/source/distributions/k8s/`
- 735 runtime source/config files scanned against 23 platform aliases

---

### Authentication

#### Auth Middleware and Decorators Found

Six source-backed authentication facts exist in shipped code with confirmed
registration:

| # | Fact | Location | Evidence |
|---|------|----------|----------|
| 1 | ASGI `AuthenticationMiddleware` on FastAPI app | `server.py:448-450` | `app.add_middleware(AuthenticationMiddleware, auth_config=config.server.auth)` — config-conditional |
| 2 | `OAuth2TokenAuthProvider` — JWT/JWKS validation, RFC 7662 introspection | `auth_providers.py:133-261` | `python-jose` JWT validation, configurable audience/issuer/claims mapping |
| 3 | `CustomAuthProvider` — external auth endpoint delegation | `auth_providers.py:267-335` | Delegates to HTTP endpoint with API key and request context |
| 4 | ABAC `is_action_allowed()` enforcement on routing table CRUD | `routing_tables/common.py:171,178,195,218` | Read, delete, create, and list operations check user attributes against resource policies |
| 5 | ABAC enforcement on agent session persistence | `persistence.py:45,55,85` | Session create and read operations check access policies |
| 6 | `QuotaMiddleware` with authenticated/anonymous rate limits | `quota.py:21-111`, `server.py:473-479` | Reads `authenticated_client_id` from ASGI scope set by AuthenticationMiddleware |

#### Nine Credential References

| # | Name | Location | Classification |
|---|------|----------|----------------|
| 1 | `FIREWORKS_API_KEY` | `llama_stack/distribution/ui/modules/api.py:17` | Outbound — provider data for third-party inference |
| 2 | `TOGETHER_API_KEY` | `api.py:18` | Outbound — same pattern |
| 3 | `SAMBANOVA_API_KEY` | `api.py:19` | Outbound |
| 4 | `OPENAI_API_KEY` | `api.py:20` | Outbound |
| 5 | `TAVILY_SEARCH_API_KEY` | `api.py:21` | Outbound |
| 6 | `NVIDIA_API_KEY` | `providers/remote/datasetio/nvidia/config.py:18` | Outbound — NVIDIA API provider config |
| 7 | `CEREBRAS_API_KEY` | `providers/remote/inference/cerebras/config.py:24` | Outbound |
| 8 | `WATSONX_API_KEY` | `providers/remote/inference/watsonx/config.py:28` | Outbound |
| 9 | `GITHUB_TOKEN` | `scripts/gen-changelog.py:73` | Not runtime — developer utility script |

All eight runtime credentials are outbound API keys for third-party services, not
inbound authentication mechanisms. Credential #9 is build-only.

#### Dynamic Authentication Behavior

Confirmed:

- Config-gated: `if config.server.auth:` at `server.py:448`
- Factory-dispatched: `create_auth_provider(config.server.auth)` at `auth.py:83`
- Provider-polymorphic: OAuth2 (JWKS or introspection) or Custom endpoint, selected
  at runtime from YAML config
- Claims-mapped: JWT attribute extraction uses configurable mapping

This cannot be resolved by static analysis alone. The auth providers, their
configuration, and whether auth is active are all determined by the runtime YAML
config.

#### Analyzer Coverage State (Authentication)

```json
{
  "authentication": {
    "status": "partial",
    "fact_count": 0,
    "completed_checks": [
      "normalized-authentication-facts",
      "no-inbound-runtime-surfaces",
      "credential-reference-inventory",
      "python-authentication-signal-scan"
    ],
    "limitations": [
      "9 credential references are not fully accounted for by authentication facts",
      "unsupported runtime source languages require authentication analysis",
      "Python server framework is present and dynamic authentication composition is unresolved",
      "Python authentication constructions require fact-level relationship accounting"
    ]
  }
}
```

The analyzer correctly identified the Python server framework, credential
references, and dynamic auth composition as limitations. It ran the
`python-authentication-signal-scan` check and found authentication patterns but
could not extract them as structured facts because:

- Middleware registration (`app.add_middleware(...)`) is a dynamic Python call
- Auth provider selection is factory-dispatched at runtime
- ABAC enforcement uses decorator/function-call patterns in routing table code

#### Authentication Decision

**3 — Partial because unsupported or dynamic behavior prevents an absence claim.**

The table is not empty because the category was completely evaluated and found
nothing. Six real authentication facts exist. The analyzer correctly identified
the gap but cannot extract the facts because dynamic Python middleware composition,
factory-dispatched auth providers, and function-call-level ABAC enforcement are
beyond current static extraction capabilities.

---

### Internal Dependencies

#### Platform Service Clients

None found. No construction of clients to RHOAI/ODH components (Model Registry,
KServe, Caikit, TrustyAI, ModelMesh, Data Science Pipelines, etc.).

The `ModelRegistryHelper` class in `llama_stack/providers/utils/inference/model_registry.py`
is an internal utility for managing the provider's own model list, not a client to
the RHOAI Model Registry component.

#### Platform Aliases Found

Zero matches. Scanned 735 runtime source/config files against 23 platform aliases
(odh, rhoai, opendatahub, rhods, kserve, caikit, trustyai, modelmesh,
data-science-pipelines, etc.).

Kubernetes examples in `docs/source/distributions/k8s/` deploy generic vLLM,
PostgreSQL, and Chroma services. None are RHOAI/ODH components.

#### Unsupported Surfaces

**Shell scripts (12 total)**:

| Script | Classification | Platform deps |
|--------|----------------|---------------|
| `install.sh` | Container deployment (Docker/Podman) | None |
| `llama_stack/cli/scripts/install-wheel-from-presigned.sh` | Wheel download utility | None |
| `llama_stack/distribution/build_conda_env.sh` | Build tooling | None |
| `llama_stack/distribution/build_container.sh` | Build tooling | None |
| `llama_stack/distribution/build_venv.sh` | Build tooling | None |
| `llama_stack/distribution/common.sh` | Build utilities | None |
| `llama_stack/distribution/start_stack.sh` | Runtime launcher — delegates to Python server | None beyond Python analysis |
| `scripts/check-workflows-use-hashes.sh` | CI tooling | None |
| `scripts/unit-tests.sh` | CI/test tooling | None |
| `docs/contbuild.sh` | Documentation | None |
| `docs/openapi_generator/run_openapi_generator.sh` | Documentation | None |
| `docs/source/distributions/k8s/apply.sh` | Documentation/example | None |

**C-family / Swift (5 files)**:

All under `llama_stack/providers/inline/ios/inference/LocalInferenceImpl/`. iOS
local inference provider, not part of the RHOAI/Linux server deployment. No auth
mechanisms, no platform dependencies, no credential references.

Shell and C-family/Swift concerns are **resolved** for Internal Dependencies. None
contain platform dependencies.

#### Analyzer Coverage State (Internal Dependencies)

```json
{
  "internal_dependencies": {
    "status": "partial",
    "fact_count": 0,
    "completed_checks": [
      "normalized-platform-dependency-facts",
      "runtime-source-config-platform-alias-scan",
      "dependency-impacting-manifest-resolution"
    ],
    "limitations": [
      "unsupported runtime source languages require platform dependency analysis"
    ]
  }
}
```

The `supported-language-surface-inventory` check did not complete because shell
and C-family/Swift files exist. The alias scan successfully covered all 735 files
(including unsupported languages) and found zero platform references, providing
strong negative evidence. But the formal completeness claim requires the
supported-language check to pass.

#### Internal Dependencies Decision

**3 — Partial because unsupported behavior prevents an absence claim.**

The source audit confirms the table is legitimately empty: zero platform references
across all runtime surfaces including every shell script and C-family/Swift file.
However, the analyzer correctly reports `partial` because it cannot formally
evaluate shell and Swift source for structured platform dependencies. The alias
scan provides strong circumstantial evidence (zero matches across 735 files) but
is not equivalent to the formal `supported-language-surface-inventory` completeness
check.

Resolution would require the analyzer to classify build/CI shell scripts and iOS
provider code as non-server-runtime, or to add shell/Swift platform dependency
extraction support.

---

## Focused Tasks Created

| Task | Component | Category | Reason |
|------|-----------|----------|--------|
| [Design Integration Points discovery contract](../tasks/pending/design-integration-points-discovery-contract.md) | guardrails-regex-detector (and others) | Integration Points | No contract exists; 14+ components are blocked by empty Integration Points |
| [Extract model-registry KServe controller dependency](../tasks/pending/extract-model-registry-kserve-controller-dependency.md) | model-registry | Internal Dependencies | KServe dependency has construction + call evidence but is not extracted |
| [Extract Python dynamic authentication middleware](../tasks/pending/extract-python-dynamic-authentication-middleware.md) | ogx (and other Python servers) | Authentication | Dynamic middleware registration, factory providers, and ABAC enforcement require Python-specific extraction |

The ogx Internal Dependencies limitation (unsupported shell/Swift classification)
is documented here but not given a separate task. It is part of the broader
analyzer supported-language-surface-inventory gap that affects multiple components.
The alias scan's zero-match result across 735 files provides strong evidence that
no platform dependencies are hidden.

## Reconciliation

### Routing Impact

Zero routing expansion. All three components remain false deterministic candidates.
No components are promoted to analyzer-only.

| Component | Before | After | Change |
|-----------|--------|-------|--------|
| `guardrails-regex-detector` | False candidate, 0 corrections, eligible=false | False candidate, eligible=false | No change; new contract required |
| `model-registry` | False candidate, 2/2 resolved, eligible=false | False candidate, eligible=false | No change; missed KServe dependency |
| `ogx` | False candidate, 0 corrections, eligible=false | False candidate, eligible=false | No change; dynamic Python auth + unsupported languages |

### Analyzer Changes

None. This audit produced no analyzer code changes. All gaps require focused
extractor work or new contract design documented in the pending tasks above.

### Validation

No validation is required because no analyzer behavior changed. The existing
replay at `rhoai-next-cli-kubernetes-static-20260719T180727Z` remains the
authoritative classification with 34 approved analyzer-only components, 29 false
candidates, and zero false nominations.
