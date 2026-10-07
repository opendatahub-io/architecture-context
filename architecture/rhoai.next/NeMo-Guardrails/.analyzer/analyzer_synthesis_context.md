# Analyzer Synthesis Context: NeMo-Guardrails

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 19 http_endpoints facts extracted [source: benchmark/mock_llm_server/api.py:108, benchmark/mock_llm_server/api.py:120, benchmark/mock_llm_server/api.py:270, benchmark/mock_llm_server/api.py:336, benchmark/mock_llm_server/api.py:404, nemoguardrails/actions_server/actions_server.py:54, nemoguardrails/actions_server/actions_server.py:76, nemoguardrails/library/factchecking/align_score/server.py:79, nemoguardrails/library/factchecking/align_score/server.py:85, nemoguardrails/library/jailbreak_detection/server.py:104, nemoguardrails/library/jailbreak_detection/server.py:80, nemoguardrails/library/jailbreak_detection/server.py:85, nemoguardrails/library/jailbreak_detection/server.py:90, nemoguardrails/server/api.py:278, nemoguardrails/server/api.py:303, nemoguardrails/server/api.py:308, nemoguardrails/server/api.py:772, nemoguardrails/server/api.py:842, nemoguardrails/server/checks.py:522]
- **services (observed)**: 1 services facts extracted [source: benchmark/mock_llm_server/api.py:108]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References


## Behavioral Evidence

No bounded behavioral evidence was extracted.

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `nemoguardrails/library/prompt_security/actions.py`:47 (Bearer token or API key, HTTP API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:59 (Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:61 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:62 (Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:92 (Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.server`:80 (Dockerfile.server:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `nemoguardrails/library/factchecking/align_score/Dockerfile`:55 (nemoguardrails/library/factchecking/align_score/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `nemoguardrails/library/factchecking/align_score/Dockerfile`:56 (nemoguardrails/library/factchecking/align_score/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `nemoguardrails/library/jailbreak_detection/Dockerfile`:33 (nemoguardrails/library/jailbreak_detection/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `nemoguardrails/library/jailbreak_detection/Dockerfile`:34 (nemoguardrails/library/jailbreak_detection/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `pyproject.toml`:2 (nemoguardrails)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `pyproject.toml`:50 (uvicorn)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `nemoguardrails/embeddings/providers/azureopenai.py`:53 (Azure OpenAI, Outbound SDK client construction)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `benchmark/mock_llm_server/api.py`:108 (/, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `benchmark/mock_llm_server/api.py`:404 (/health, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `nemoguardrails/actions_server/actions_server.py`:54 (/v1/actions/run, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `nemoguardrails/actions_server/actions_server.py`:76 (/v1/actions/list, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `nemoguardrails/library/factchecking/align_score/server.py`:79 (/alignscore_base, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `nemoguardrails/library/factchecking/align_score/server.py`:85 (/alignscore_large, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `nemoguardrails/library/jailbreak_detection/server.py`:104 (/model, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `nemoguardrails/library/jailbreak_detection/server.py`:80 (/jailbreak_lp_heuristic, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `nemoguardrails/library/jailbreak_detection/server.py`:85 (/jailbreak_ps_heuristic, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `nemoguardrails/library/jailbreak_detection/server.py`:90 (/heuristics, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `nemoguardrails/server/api.py`:308 (/healthz, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `nemoguardrails/server/api.py`:842 (/v1/challenges, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `nemoguardrails/embeddings/providers/azureopenai.py`:49 (OpenAI API, Python SDK client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `nemoguardrails/embeddings/providers/azureopenai.py`:53 (Azure OpenAI, SDK client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `benchmark/mock_llm_server/api.py`:108 (nemoguardrails)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- HTTP API methods=All mechanism=Bearer token or API key enforcement=Python API dependency or middleware policy=Source-defined authentication [source: nemoguardrails/library/prompt_security/actions.py:47]
### http_endpoints

- GET / on port ; transport= encryption=Configurable auth=Unknown owner= [source: benchmark/mock_llm_server/api.py:108]
- GET /health on port ; transport= encryption=Configurable auth=Unknown owner= [source: benchmark/mock_llm_server/api.py:404]
- GET /healthz on port ; transport= encryption=Configurable auth=Unknown owner= [source: nemoguardrails/server/api.py:308]
- GET /v1/actions/list on port ; transport= encryption=Configurable auth=Unknown owner= [source: nemoguardrails/actions_server/actions_server.py:76]
- GET /v1/challenges on port ; transport= encryption=Configurable auth=Unknown owner= [source: nemoguardrails/server/api.py:842]
- GET /v1/health on port ; transport= encryption=Configurable auth=Unknown owner= [source: nemoguardrails/server/api.py:303]
- GET /v1/models on port ; transport= encryption=Configurable auth=Unknown owner= [source: benchmark/mock_llm_server/api.py:120]
- GET /v1/rails/configs on port ; transport= encryption=Configurable auth=Unknown owner= [source: nemoguardrails/server/api.py:278]
- POST /alignscore_base on port ; transport= encryption=Configurable auth=Unknown owner= [source: nemoguardrails/library/factchecking/align_score/server.py:79]
- POST /alignscore_large on port ; transport= encryption=Configurable auth=Unknown owner= [source: nemoguardrails/library/factchecking/align_score/server.py:85]
- POST /heuristics on port ; transport= encryption=Configurable auth=Unknown owner= [source: nemoguardrails/library/jailbreak_detection/server.py:90]
- POST /jailbreak_lp_heuristic on port ; transport= encryption=Configurable auth=Unknown owner= [source: nemoguardrails/library/jailbreak_detection/server.py:80]
- POST /jailbreak_ps_heuristic on port ; transport= encryption=Configurable auth=Unknown owner= [source: nemoguardrails/library/jailbreak_detection/server.py:85]
- POST /model on port ; transport= encryption=Configurable auth=Unknown owner= [source: nemoguardrails/library/jailbreak_detection/server.py:104]
- POST /v1/actions/run on port ; transport= encryption=Configurable auth=Unknown owner= [source: nemoguardrails/actions_server/actions_server.py:54]
- POST /v1/chat/completions on port ; transport= encryption=Configurable auth=Unknown owner= [source: benchmark/mock_llm_server/api.py:270]
- POST /v1/checks on port ; transport= encryption=Configurable auth=Unknown owner= [source: nemoguardrails/server/api.py:772]
- POST /v1/completions on port ; transport= encryption=Configurable auth=Unknown owner= [source: benchmark/mock_llm_server/api.py:336]
- POST /v1/guardrail/checks on port ; transport= encryption=Configurable auth=Unknown owner= [source: nemoguardrails/server/checks.py:522]
### integrations

- Azure OpenAI interaction=SDK client role=runtime-integration protocol=HTTPS purpose=Outbound SDK client construction [source: nemoguardrails/embeddings/providers/azureopenai.py:53]
- OpenAI API interaction=Python SDK client role=runtime-integration protocol=HTTPS purpose=LLM inference via OpenAI SDK [source: nemoguardrails/embeddings/providers/azureopenai.py:49]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Service nemoguardrails targets  with 0 port(s) [source: benchmark/mock_llm_server/api.py:108]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **observed**: All HTTP API uses Bearer token or API key at Python API dependency or middleware; policy=Source-defined authentication [source: nemoguardrails/library/prompt_security/actions.py:47]
- **dependency-signal**: tls-config targets cryptography: TLS/cryptography library dependency [source: requirements.txt:112]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
