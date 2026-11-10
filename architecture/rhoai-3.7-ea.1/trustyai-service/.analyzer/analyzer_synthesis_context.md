# Analyzer Synthesis Context: trustyai-service

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 11 http_endpoints facts extracted [source: src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:185, src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:211, src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:252, src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:299, src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:367, src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:379, src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:389, src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:402, src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:416, src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:95, src/trustyai_service/main.py:252]
- **services (observed)**: 1 services facts extracted [source: src/trustyai_service/main.py:252]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (confirmed-empty)**: 0 webhooks facts extracted

## Deterministic Cross-References


## Behavioral Evidence

No bounded behavioral evidence was extracted.

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `src/trustyai_service/main.py`:252 (HTTP API, None (no auth middleware detected))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:51 (Dockerfile.konflux:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `pyproject.toml`:16 (hypercorn)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `pyproject.toml`:85 (trustyai-migrate)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py`:185 (/metrics/drift/ksteststreaming/definition, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py`:211 (/metrics/drift/ksteststreaming/request, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py`:252 (/metrics/drift/ksteststreaming/request, DELETE)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py`:299 (/metrics/drift/ksteststreaming/requests, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py`:367 (/metrics/drift/approxkstest, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py`:379 (/metrics/drift/approxkstest/definition, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py`:389 (/metrics/drift/approxkstest/request, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py`:402 (/metrics/drift/approxkstest/request, DELETE)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py`:416 (/metrics/drift/approxkstest/requests, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py`:95 (/metrics/drift/ksteststreaming, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/trustyai_service/main.py`:252 (/, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `src/trustyai_service/main.py`:252 (trustyai-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- HTTP API methods=All mechanism=None (no auth middleware detected) enforcement=FastAPI/Starlette application policy=No authentication middleware registered [source: src/trustyai_service/main.py:252]
### http_endpoints

- DELETE /metrics/drift/approxkstest/request on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:402]
- DELETE /metrics/drift/ksteststreaming/request on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:252]
- GET / on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/trustyai_service/main.py:252]
- GET /metrics/drift/approxkstest/definition on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:379]
- GET /metrics/drift/approxkstest/requests on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:416]
- GET /metrics/drift/ksteststreaming/definition on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:185]
- GET /metrics/drift/ksteststreaming/requests on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:299]
- POST /metrics/drift/approxkstest on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:367]
- POST /metrics/drift/approxkstest/request on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:389]
- POST /metrics/drift/ksteststreaming on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:95]
- POST /metrics/drift/ksteststreaming/request on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:211]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Service trustyai-service targets  with 0 port(s) [source: src/trustyai_service/main.py:252]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **observed**: All HTTP API uses None (no auth middleware detected) at FastAPI/Starlette application; policy=No authentication middleware registered [source: src/trustyai_service/main.py:252]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
