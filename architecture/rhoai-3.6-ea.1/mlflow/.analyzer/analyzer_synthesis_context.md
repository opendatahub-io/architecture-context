# Analyzer Synthesis Context: mlflow

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 48 http_endpoints facts extracted [source: mlflow/gateway/app.py:301, mlflow/gateway/app.py:305, mlflow/gateway/app.py:315, mlflow/gateway/app.py:419, mlflow/gateway/app.py:438, mlflow/gateway/app.py:457, mlflow/genai/agent_server/server.py:230, mlflow/genai/agent_server/server.py:237, mlflow/genai/agent_server/server.py:245, mlflow/genai/agent_server/server.py:263, mlflow/pyfunc/scoring_server/__init__.py:470, mlflow/server/assistant/api.py:117, mlflow/server/assistant/api.py:153, mlflow/server/assistant/api.py:217, mlflow/server/assistant/api.py:245, mlflow/server/assistant/api.py:266, mlflow/server/assistant/api.py:281, mlflow/server/assistant/api.py:352, mlflow/server/assistant/api.py:413, mlflow/server/gateway_api.py:1425, mlflow/server/gateway_api.py:615, mlflow/server/gateway_api.py:744, mlflow/server/job_api.py:116, mlflow/server/job_api.py:50, mlflow/server/job_api.py:70, mlflow/server/job_api.py:88, mlflow/server/mcp_server_api.py:622, mlflow/server/mcp_server_api.py:649, mlflow/server/mcp_server_api.py:659, mlflow/server/mcp_server_api.py:667, mlflow/server/mcp_server_api.py:678, mlflow/server/mcp_server_api.py:693, mlflow/server/mcp_server_api.py:701, mlflow/server/mcp_server_api.py:735, mlflow/server/mcp_server_api.py:758, mlflow/server/mcp_server_api.py:778, mlflow/server/mcp_server_api.py:790, mlflow/server/mcp_server_api.py:807, mlflow/server/mcp_server_api.py:815, mlflow/server/mcp_server_api.py:844, mlflow/server/mcp_server_api.py:852, mlflow/server/mcp_server_api.py:860, mlflow/server/mcp_server_api.py:870, mlflow/server/mcp_server_api.py:878, mlflow/server/mcp_server_api.py:887, mlflow/server/mcp_server_api.py:895, mlflow/server/mcp_server_api.py:908, mlflow/tracing/distributed/__init__.py:53]
- **services (observed)**: 1 services facts extracted [source: mlflow/gateway/app.py:301]
- **ingress (not-verified)**: 0 ingress facts extracted; absence is not proven by the available coverage
- **webhooks (confirmed-empty)**: 0 webhooks facts extracted

## Deterministic Cross-References


## Gap Evidence Index

### authentication

- **Question:** Does this container app/plugin selection configure authentication or authorization for the serving surface?
  **Expected signal:** app/plugin selector, authentication middleware, or enforcement boundary
  **Candidate:** `Dockerfile.konflux`:80 (Dockerfile.konflux:CMD, kubernetes-auth)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `mlflow/gateway/app.py`:301 (HTTP API, None (no auth middleware detected))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:80 (Dockerfile.konflux:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `libs/skinny/pyproject.toml`:2 (mlflow)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `pyproject.toml`:43 (gunicorn)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `mlflow/deployments/openai/__init__.py`:175 (Literal outbound HTTP endpoint, api.openai.com)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `mlflow/tracing/fluent.py`:1645 (Literal outbound HTTP endpoint, your-service-endpoint)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `mlflow/transformers/__init__.py`:2950 (Literal outbound HTTP endpoint, www.my.images)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `mlflow/gateway/app.py`:301 (/, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `mlflow/genai/agent_server/server.py`:245 (/agent/info, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `mlflow/pyfunc/scoring_server/__init__.py`:470 (/version, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `mlflow/server/assistant/api.py`:266 (/ajax-api/3.0/mlflow/assistant/config, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `mlflow/server/gateway_api.py`:744 (/gateway/mlflow/v1/chat/completions, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `mlflow/server/job_api.py`:70 (/ajax-api/3.0/jobs/, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `mlflow/server/mcp_server_api.py`:622 (/endpoints, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `mlflow/tracing/distributed/__init__.py`:53 (/agent-handler, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `mlflow/deployments/openai/__init__.py`:175 (HTTP client, api.openai.com)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `mlflow/gateway/providers/bedrock.py`:212 (AWS (S3-compatible storage), Python SDK client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `mlflow/store/artifact/gcs_artifact_repo.py`:57 (Google Cloud Storage, Python SDK client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `mlflow/tracing/fluent.py`:1645 (HTTP client, your-service-endpoint)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `mlflow/transformers/__init__.py`:2950 (HTTP client, www.my.images)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `mlflow/projects/kubernetes.py`:9 (Kubernetes API, Python client library)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `mlflow/gateway/app.py`:301 (mlflow-skinny)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- HTTP API methods=All mechanism=None (no auth middleware detected) enforcement=FastAPI/Starlette application policy=No authentication middleware registered [source: mlflow/gateway/app.py:301]
### http_endpoints

- DELETE /{name:path}/aliases/{alias:path} on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/mcp_server_api.py:878]
- DELETE /{name:path}/endpoints/{endpoint_id} on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/mcp_server_api.py:807]
- DELETE /{name:path}/tags/{key:path} on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/mcp_server_api.py:852]
- DELETE /{name:path}/versions/{version:path}/tags/{key:path} on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/mcp_server_api.py:659]
- GET / on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/gateway/app.py:301]
- GET /agent/info on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/genai/agent_server/server.py:245]
- GET /ajax-api/3.0/jobs/{job_id} on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/job_api.py:50]
- GET /ajax-api/3.0/mlflow/assistant/config on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/assistant/api.py:266]
- GET /ajax-api/3.0/mlflow/assistant/providers/{provider}/health on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/assistant/api.py:245]
- GET /ajax-api/3.0/mlflow/assistant/providers/{provider}/models on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/assistant/api.py:413]
- GET /ajax-api/3.0/mlflow/assistant/sessions/{session_id}/stream on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/assistant/api.py:153]
- GET /docs on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/gateway/app.py:315]
- GET /endpoints on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/mcp_server_api.py:622]
- GET /favicon.ico on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/gateway/app.py:305]
- GET /health on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/genai/agent_server/server.py:263]
- GET /version on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/pyfunc/scoring_server/__init__.py:470]
- GET /{name:path}/aliases/{alias:path} on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/mcp_server_api.py:870]
- GET /{name:path}/endpoints on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/mcp_server_api.py:815]
- GET /{name:path}/endpoints/{endpoint_id} on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/mcp_server_api.py:778]
- PATCH /ajax-api/3.0/jobs/cancel/{job_id} on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/job_api.py:88]
- PATCH /ajax-api/3.0/mlflow/assistant/sessions/{session_id} on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/assistant/api.py:217]
- PATCH /{name:path}/endpoints/{endpoint_id} on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/mcp_server_api.py:790]
- POST /agent-handler on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/tracing/distributed/__init__.py:53]
- POST /ajax-api/3.0/jobs/ on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/job_api.py:70]
- POST /ajax-api/3.0/jobs/search on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/job_api.py:116]
- POST /ajax-api/3.0/mlflow/assistant/message on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/assistant/api.py:117]
- POST /ajax-api/3.0/mlflow/assistant/skills/install on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/assistant/api.py:352]
- POST /gateway/mlflow/v1/chat/completions on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/gateway_api.py:744]
- POST /gateway/proxy/{endpoint_name}/{path:path} on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/gateway_api.py:1425]
- POST /gateway/{endpoint_name}/mlflow/invocations on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/gateway_api.py:615]
- POST /invocations on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/genai/agent_server/server.py:230]
- POST /responses on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/genai/agent_server/server.py:237]
- POST /v1/chat/completions on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/gateway/app.py:419]
- POST /v1/completions on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/gateway/app.py:438]
- POST /v1/embeddings on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/gateway/app.py:457]
- POST /{name:path}/aliases on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/mcp_server_api.py:860]
- POST /{name:path}/endpoints on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/mcp_server_api.py:758]
- POST /{name:path}/tags on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/mcp_server_api.py:844]
- POST /{name:path}/versions/{version:path}/tags on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/mcp_server_api.py:649]
- PUT /ajax-api/3.0/mlflow/assistant/config on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/assistant/api.py:281]
### integrations

- AWS (S3-compatible storage) interaction=Python SDK client role=runtime-integration protocol=HTTPS purpose=AWS service operations via boto3 [source: mlflow/gateway/providers/bedrock.py:212]
- Google Cloud Storage interaction=Python SDK client role=runtime-integration protocol=HTTPS purpose=GCS operations via Python SDK [source: mlflow/store/artifact/gcs_artifact_repo.py:57]
- api.openai.com interaction=HTTP client role=runtime-integration protocol=HTTPS purpose=Literal outbound HTTP endpoint [source: mlflow/deployments/openai/__init__.py:175]
- www.my.images interaction=HTTP client role=runtime-integration protocol=HTTPS purpose=Literal outbound HTTP endpoint [source: mlflow/transformers/__init__.py:2950]
- your-service-endpoint interaction=HTTP client role=runtime-integration protocol=HTTPS purpose=Literal outbound HTTP endpoint [source: mlflow/tracing/fluent.py:1645]
### internal_dependencies

- Kubernetes API interaction=Python client library role=runtime-integration purpose=Kubernetes resource operations via Python SDK [source: mlflow/projects/kubernetes.py:9]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Service mlflow-skinny targets  with 0 port(s) [source: mlflow/gateway/app.py:301]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **observed**: All HTTP API uses None (no auth middleware detected) at FastAPI/Starlette application; policy=No authentication middleware registered [source: mlflow/gateway/app.py:301]
- **dependency-signal**: rbac-ref targets kubernetes: Kubernetes client library (RBAC capable) [source: libs/skinny/pyproject.toml:65]
- **dependency-signal**: tls-config targets cryptography: TLS/cryptography library dependency [source: pyproject.toml:37]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
