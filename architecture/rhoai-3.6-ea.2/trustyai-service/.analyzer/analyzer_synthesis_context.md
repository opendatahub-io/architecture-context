# Analyzer Synthesis Context: trustyai-service

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 11 http_endpoints facts extracted [source: src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:184, src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:210, src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:251, src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:298, src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:366, src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:378, src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:388, src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:401, src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:415, src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:94, src/trustyai_service/main.py:249]
- **services (observed)**: 1 services facts extracted [source: src/trustyai_service/main.py:249]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (confirmed-empty)**: 0 webhooks facts extracted

## Deterministic Cross-References


## Behavioral Evidence

No bounded behavioral evidence was extracted.

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `src/trustyai_service/main.py`:249 (HTTP API, None (no auth middleware detected))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:38 (Dockerfile.konflux:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `pyproject.toml`:17 (hypercorn)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py`:184 (/metrics/drift/ksteststreaming/definition, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py`:210 (/metrics/drift/ksteststreaming/request, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py`:251 (/metrics/drift/ksteststreaming/request, DELETE)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py`:298 (/metrics/drift/ksteststreaming/requests, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py`:366 (/metrics/drift/approxkstest, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py`:378 (/metrics/drift/approxkstest/definition, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py`:388 (/metrics/drift/approxkstest/request, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py`:401 (/metrics/drift/approxkstest/request, DELETE)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py`:415 (/metrics/drift/approxkstest/requests, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py`:94 (/metrics/drift/ksteststreaming, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/trustyai_service/main.py`:249 (/, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `src/trustyai_service/main.py`:249 (trustyai-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- HTTP API methods=All mechanism=None (no auth middleware detected) enforcement=FastAPI/Starlette application policy=No authentication middleware registered [source: src/trustyai_service/main.py:249]
### http_endpoints

- DELETE /metrics/drift/approxkstest/request on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:401]
- DELETE /metrics/drift/ksteststreaming/request on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:251]
- GET / on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/trustyai_service/main.py:249]
- GET /metrics/drift/approxkstest/definition on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:378]
- GET /metrics/drift/approxkstest/requests on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:415]
- GET /metrics/drift/ksteststreaming/definition on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:184]
- GET /metrics/drift/ksteststreaming/requests on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:298]
- POST /metrics/drift/approxkstest on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:366]
- POST /metrics/drift/approxkstest/request on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:388]
- POST /metrics/drift/ksteststreaming on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:94]
- POST /metrics/drift/ksteststreaming/request on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/trustyai_service/endpoints/metrics/drift/kolmogorov_smirnov_streaming.py:210]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Service trustyai-service targets  with 0 port(s) [source: src/trustyai_service/main.py:249]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **observed**: All HTTP API uses None (no auth middleware detected) at FastAPI/Starlette application; policy=No authentication middleware registered [source: src/trustyai_service/main.py:249]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
