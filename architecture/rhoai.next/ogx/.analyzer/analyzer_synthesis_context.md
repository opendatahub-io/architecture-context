# Analyzer Synthesis Context: ogx

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (not-verified)**: 0 http_endpoints facts extracted; absence is not proven by the available coverage
- **services (not-verified)**: 0 services facts extracted; absence is not proven by the available coverage
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References


## Behavioral Evidence

No bounded behavioral evidence was extracted.

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `llama_stack/distribution/routing_tables/common.py`:171 (ABAC enforcement (is_action_allowed), Routing table operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `llama_stack/distribution/server/auth_providers.py`:263 (External HTTP authentication delegation, HTTP API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `llama_stack/distribution/server/auth_providers.py`:97 (HTTP API, OAuth2 JWT/JWKS or token introspection)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `llama_stack/distribution/server/server.py`:450 (Bearer token, HTTP API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `llama_stack/providers/inline/agents/meta_reference/persistence.py`:55 (ABAC enforcement (is_action_allowed), Agent persistence operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `pyproject.toml`:133 (install-wheel-from-presigned)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `pyproject.toml`:6 (llama)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `llama_stack/providers/remote/tool_runtime/tavily_search/tavily_search.py`:74 (Literal outbound HTTP endpoint, api.tavily.com)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `llama_stack/distribution/routers/inference.py`:12 (OpenAI API, Python SDK client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `llama_stack/providers/remote/tool_runtime/tavily_search/tavily_search.py`:74 (HTTP client, api.tavily.com)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- Agent persistence operations methods=create, read mechanism=ABAC enforcement (is_action_allowed) enforcement=Agent persistence control flow policy=Operation-gating: denies or filters based on policy and authenticated user attributes [source: llama_stack/providers/inline/agents/meta_reference/persistence.py:55]
- HTTP API methods=All mechanism=Bearer token enforcement=ASGI middleware (AuthenticationMiddleware) policy=Configuration-conditional (config.server.auth) [source: llama_stack/distribution/server/server.py:450]
- HTTP API methods=All mechanism=External HTTP authentication delegation enforcement=Auth provider (CustomAuthProvider via factory) policy=Runtime-selectable provider [source: llama_stack/distribution/server/auth_providers.py:263]
- HTTP API methods=All mechanism=OAuth2 JWT/JWKS or token introspection enforcement=Auth provider (OAuth2TokenAuthProvider via factory) policy=Runtime-selectable provider [source: llama_stack/distribution/server/auth_providers.py:97]
- Routing table operations methods=create, delete, read mechanism=ABAC enforcement (is_action_allowed) enforcement=Routing table control flow policy=Operation-gating: denies or filters based on policy and authenticated user attributes [source: llama_stack/distribution/routing_tables/common.py:171]
### integrations

- OpenAI API interaction=Python SDK client role=runtime-integration protocol=HTTPS purpose=LLM inference via OpenAI SDK [source: llama_stack/distribution/routers/inference.py:12]
- api.tavily.com interaction=HTTP client role=runtime-integration protocol=HTTPS purpose=Literal outbound HTTP endpoint [source: llama_stack/providers/remote/tool_runtime/tavily_search/tavily_search.py:74]

## Cross-Cutting Evidence

### deployment_topology

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:deployment_topology]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **observed**: All HTTP API uses Bearer token at ASGI middleware (AuthenticationMiddleware); policy=Configuration-conditional (config.server.auth) [source: llama_stack/distribution/server/server.py:450]
- **observed**: All HTTP API uses External HTTP authentication delegation at Auth provider (CustomAuthProvider via factory); policy=Runtime-selectable provider [source: llama_stack/distribution/server/auth_providers.py:263]
- **observed**: All HTTP API uses OAuth2 JWT/JWKS or token introspection at Auth provider (OAuth2TokenAuthProvider via factory); policy=Runtime-selectable provider [source: llama_stack/distribution/server/auth_providers.py:97]
- **dependency-signal**: auth-middleware targets python-jose: JWT/OAuth authentication library dependency [source: requirements.txt:134]
- **observed**: create, delete, read Routing table operations uses ABAC enforcement (is_action_allowed) at Routing table control flow; policy=Operation-gating: denies or filters based on policy and authenticated user attributes [source: llama_stack/distribution/routing_tables/common.py:171]
- **observed**: create, read Agent persistence operations uses ABAC enforcement (is_action_allowed) at Agent persistence control flow; policy=Operation-gating: denies or filters based on policy and authenticated user attributes [source: llama_stack/providers/inline/agents/meta_reference/persistence.py:55]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
