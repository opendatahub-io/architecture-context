# Analyzer Synthesis Context: ai4rag

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 2 http_endpoints facts extracted [source: ai4rag/assets_generator/starter_kit_templates/agentic_rag/main.py:126, ai4rag/assets_generator/starter_kit_templates/agentic_rag/main.py:193]
- **services (observed)**: 1 services facts extracted [source: ai4rag/assets_generator/starter_kit_templates/agentic_rag/main.py:193]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (confirmed-empty)**: 0 webhooks facts extracted

## Deterministic Cross-References


## Behavioral Evidence

No bounded behavioral evidence was extracted.

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `ai4rag/assets_generator/starter_kit_templates/agentic_rag/main.py`:193 (HTTP API, None (no auth middleware detected))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `ai4rag/assets_generator/starter_kit_templates/agentic_rag/main.py`:126 (/v1/responses, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `ai4rag/assets_generator/starter_kit_templates/agentic_rag/main.py`:193 (/health, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `ai4rag/assets_generator/starter_kit_templates/agentic_rag/main.py`:16 (OpenAI API, Python SDK client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `ai4rag/utils/clients/s3.py`:8 (AWS (S3-compatible storage), Python SDK client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `ai4rag/assets_generator/starter_kit_templates/agentic_rag/main.py`:193 (ai4rag)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- HTTP API methods=All mechanism=None (no auth middleware detected) enforcement=FastAPI/Starlette application policy=No authentication middleware registered [source: ai4rag/assets_generator/starter_kit_templates/agentic_rag/main.py:193]
### http_endpoints

- GET /health on port ; transport= encryption=Configurable auth=Unknown owner= [source: ai4rag/assets_generator/starter_kit_templates/agentic_rag/main.py:193]
- POST /v1/responses on port ; transport= encryption=Configurable auth=Unknown owner= [source: ai4rag/assets_generator/starter_kit_templates/agentic_rag/main.py:126]
### integrations

- AWS (S3-compatible storage) interaction=Python SDK client role=runtime-integration protocol=HTTPS purpose=AWS service operations via boto3 [source: ai4rag/utils/clients/s3.py:8]
- OpenAI API interaction=Python SDK client role=runtime-integration protocol=HTTPS purpose=LLM inference via OpenAI SDK [source: ai4rag/assets_generator/starter_kit_templates/agentic_rag/main.py:16]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Service ai4rag targets  with 0 port(s) [source: ai4rag/assets_generator/starter_kit_templates/agentic_rag/main.py:193]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **observed**: All HTTP API uses None (no auth middleware detected) at FastAPI/Starlette application; policy=No authentication middleware registered [source: ai4rag/assets_generator/starter_kit_templates/agentic_rag/main.py:193]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
