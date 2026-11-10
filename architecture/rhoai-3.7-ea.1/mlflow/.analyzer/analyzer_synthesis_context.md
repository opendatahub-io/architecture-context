# Analyzer Synthesis Context: mlflow

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 89 http_endpoints facts extracted [source: mlflow/gateway/app.py:301, mlflow/gateway/app.py:305, mlflow/gateway/app.py:315, mlflow/gateway/app.py:419, mlflow/gateway/app.py:438, mlflow/gateway/app.py:457, mlflow/genai/agent_server/server.py:230, mlflow/genai/agent_server/server.py:237, mlflow/genai/agent_server/server.py:245, mlflow/genai/agent_server/server.py:263, mlflow/pyfunc/scoring_server/__init__.py:477, mlflow/server/artifact_router.py:146, mlflow/server/artifact_router.py:150, mlflow/server/artifact_router.py:65, mlflow/server/artifact_router.py:69, mlflow/server/assistant/api.py:1002, mlflow/server/assistant/api.py:1073, mlflow/server/assistant/api.py:516, mlflow/server/assistant/api.py:583, mlflow/server/assistant/api.py:676, mlflow/server/assistant/api.py:724, mlflow/server/assistant/api.py:756, mlflow/server/assistant/api.py:787, mlflow/server/assistant/api.py:809, mlflow/server/assistant/api.py:837, mlflow/server/assistant/api.py:871, mlflow/server/gateway_api.py:1050, mlflow/server/gateway_api.py:1779, mlflow/server/gateway_api.py:785, mlflow/server/gateway_api.py:931, mlflow/server/job_api.py:105, mlflow/server/job_api.py:126, mlflow/server/job_api.py:154, mlflow/server/job_api.py:85, mlflow/server/mcp_server_api.py:614, mlflow/server/mcp_server_api.py:641, mlflow/server/mcp_server_api.py:651, mlflow/server/mcp_server_api.py:659, mlflow/server/mcp_server_api.py:670, mlflow/server/mcp_server_api.py:685, mlflow/server/mcp_server_api.py:693, mlflow/server/mcp_server_api.py:727, mlflow/server/mcp_server_api.py:750, mlflow/server/mcp_server_api.py:770, mlflow/server/mcp_server_api.py:782, mlflow/server/mcp_server_api.py:799, mlflow/server/mcp_server_api.py:807, mlflow/server/mcp_server_api.py:836, mlflow/server/mcp_server_api.py:844, mlflow/server/mcp_server_api.py:852, mlflow/server/mcp_server_api.py:862, mlflow/server/mcp_server_api.py:870, mlflow/server/mcp_server_api.py:879, mlflow/server/mcp_server_api.py:887, mlflow/server/mcp_server_api.py:900, mlflow/server/server_info_api.py:25, mlflow/server/server_info_api.py:26, mlflow/server/skill_registry_api.py:1001, mlflow/server/skill_registry_api.py:1013, mlflow/server/skill_registry_api.py:1030, mlflow/server/skill_registry_api.py:1073, mlflow/server/skill_registry_api.py:1078, mlflow/server/skill_registry_api.py:1089, mlflow/server/skill_registry_api.py:1094, mlflow/server/skill_registry_api.py:1109, mlflow/server/skill_registry_api.py:1118, mlflow/server/skill_registry_api.py:1132, mlflow/server/skill_registry_api.py:1137, mlflow/server/skill_registry_api.py:1146, mlflow/server/skill_registry_api.py:1151, mlflow/server/skill_registry_api.py:1166, mlflow/server/skill_registry_api.py:1171, mlflow/server/skill_registry_api.py:1176, mlflow/server/skill_registry_api.py:1191, mlflow/server/skill_registry_api.py:833, mlflow/server/skill_registry_api.py:838, mlflow/server/skill_registry_api.py:859, mlflow/server/skill_registry_api.py:876, mlflow/server/skill_registry_api.py:890, mlflow/server/skill_registry_api.py:899, mlflow/server/skill_registry_api.py:915, mlflow/server/skill_registry_api.py:930, mlflow/server/skill_registry_api.py:935, mlflow/server/skill_registry_api.py:940, mlflow/server/skill_registry_api.py:954, mlflow/server/skill_registry_api.py:963, mlflow/server/skill_registry_api.py:972, mlflow/server/skill_registry_api.py:996, mlflow/tracing/distributed/__init__.py:53]
- **services (observed)**: 1 services facts extracted [source: mlflow/server/skill_registry_api.py:1137]
- **ingress (not-verified)**: 0 ingress facts extracted; absence is not proven by the available coverage
- **webhooks (confirmed-empty)**: 0 webhooks facts extracted

## Deterministic Cross-References


## Behavioral Evidence

No bounded behavioral evidence was extracted.

## Gap Evidence Index

### authentication

- **Question:** Does this container app/plugin selection configure authentication or authorization for the serving surface?
  **Expected signal:** app/plugin selector, authentication middleware, or enforcement boundary
  **Candidate:** `Dockerfile.konflux`:98 (Dockerfile.konflux:CMD, kubernetes-auth)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `mlflow/server/skill_registry_api.py`:1137 (HTTP API, None (no auth middleware detected))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:98 (Dockerfile.konflux:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `libs/skinny/pyproject.toml`:2 (mlflow)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `libs/skinny/pyproject.toml`:53 (uvicorn)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `pyproject.toml`:48 (gunicorn)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `mlflow/deployments/openai/__init__.py`:175 (Literal outbound HTTP endpoint, api.openai.com)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `mlflow/tracing/fluent.py`:1760 (Literal outbound HTTP endpoint, your-service-endpoint)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `mlflow/transformers/__init__.py`:2974 (Literal outbound HTTP endpoint, www.my.images)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `mlflow/server/skill_registry_api.py`:1013 (/@{organization}/{name}/versions, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `mlflow/server/skill_registry_api.py`:1078 (/@{organization}/{name}/versions/{version}, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `mlflow/server/skill_registry_api.py`:1094 (/@{organization}/{name}/aliases/{alias}, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `mlflow/server/skill_registry_api.py`:1118 (/@{organization}/{name}/aliases, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `mlflow/server/skill_registry_api.py`:1137 (/@{organization}/{name}/aliases/{alias}, DELETE)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `mlflow/server/skill_registry_api.py`:1151 (/@{organization}/{name}/versions/{version}, DELETE)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `mlflow/server/skill_registry_api.py`:1191 (/@{organization}/{name}/versions/{version}, PATCH)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `mlflow/server/skill_registry_api.py`:838 (/@{organization}/{name}/versions, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `mlflow/server/skill_registry_api.py`:876 (/@{organization}/{name}/tags, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `mlflow/server/skill_registry_api.py`:890 (/@{organization}/{name}/tags/{key:path}, DELETE)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `mlflow/server/skill_registry_api.py`:899 (/@{organization}/{name}/versions/{version}/tags, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `mlflow/server/skill_registry_api.py`:915 (/@{organization}/{name}/versions/{version}/tags/{key:path}, DELETE)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `mlflow/deployments/openai/__init__.py`:175 (HTTP client, api.openai.com)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `mlflow/gateway/providers/bedrock.py`:295 (AWS (S3-compatible storage), Python SDK client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `mlflow/store/artifact/gcs_artifact_repo.py`:58 (Google Cloud Storage, Python SDK client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `mlflow/tracing/fluent.py`:1760 (HTTP client, your-service-endpoint)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `mlflow/transformers/__init__.py`:2974 (HTTP client, www.my.images)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `mlflow/projects/kubernetes.py`:9 (Kubernetes API, Python client library)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `mlflow/server/skill_registry_api.py`:1137 (mlflow-skinny)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- HTTP API methods=All mechanism=None (no auth middleware detected) enforcement=FastAPI/Starlette application policy=No authentication middleware registered [source: mlflow/server/skill_registry_api.py:1137]
### http_endpoints

- DELETE /@{organization}/{name} on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/skill_registry_api.py:1171]
- DELETE /@{organization}/{name}/aliases/{alias} on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/skill_registry_api.py:1137]
- DELETE /@{organization}/{name}/tags/{key:path} on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/skill_registry_api.py:890]
- DELETE /@{organization}/{name}/versions/{version} on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/skill_registry_api.py:1151]
- DELETE /@{organization}/{name}/versions/{version}/tags/{key:path} on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/skill_registry_api.py:915]
- GET / on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/gateway/app.py:301]
- GET /@{organization}/{name} on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/skill_registry_api.py:833]
- GET /@{organization}/{name}/aliases/{alias} on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/skill_registry_api.py:1094]
- GET /@{organization}/{name}/versions on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/skill_registry_api.py:838]
- GET /@{organization}/{name}/versions/{version} on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/skill_registry_api.py:1078]
- GET /agent/info on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/genai/agent_server/server.py:245]
- GET /ajax-api/2.0/mlflow-artifacts/artifacts/{artifact_path:path} on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/artifact_router.py:69]
- GET /ajax-api/3.0/jobs/{job_id} on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/job_api.py:85]
- GET /ajax-api/3.0/mlflow/assistant/config on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/assistant/api.py:837]
- GET /ajax-api/3.0/mlflow/assistant/providers on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/assistant/api.py:809]
- GET /ajax-api/3.0/mlflow/assistant/providers/{provider}/health on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/assistant/api.py:787]
- GET /ajax-api/3.0/mlflow/assistant/providers/{provider}/models on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/assistant/api.py:1073]
- GET /ajax-api/3.0/mlflow/assistant/sessions/{session_id}/stream on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/assistant/api.py:583]
- GET /ajax-api/3.0/mlflow/server-info on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/server_info_api.py:26]
- GET /api/2.0/mlflow-artifacts/artifacts/{artifact_path:path} on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/artifact_router.py:65]
- GET /api/3.0/mlflow/server-info on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/server_info_api.py:25]
- PATCH /@{organization}/{name} on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/skill_registry_api.py:972]
- PATCH /@{organization}/{name}/versions/{version} on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/skill_registry_api.py:1191]
- PATCH /ajax-api/3.0/jobs/cancel/{job_id} on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/job_api.py:126]
- PATCH /ajax-api/3.0/mlflow/assistant/sessions/{session_id} on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/assistant/api.py:676]
- POST /@{organization}/{name}/aliases on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/skill_registry_api.py:1118]
- POST /@{organization}/{name}/tags on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/skill_registry_api.py:876]
- POST /@{organization}/{name}/versions on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/skill_registry_api.py:1013]
- POST /@{organization}/{name}/versions/{version}/tags on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/skill_registry_api.py:899]
- POST /agent-handler on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/tracing/distributed/__init__.py:53]
- POST /ajax-api/3.0/jobs/ on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/job_api.py:105]
- POST /ajax-api/3.0/jobs/search on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/job_api.py:154]
- POST /ajax-api/3.0/mlflow/assistant/message on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/assistant/api.py:516]
- POST /ajax-api/3.0/mlflow/assistant/sessions/{session_id}/permission on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/assistant/api.py:724]
- POST /ajax-api/3.0/mlflow/assistant/sessions/{session_id}/tool-result on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/assistant/api.py:756]
- POST /ajax-api/3.0/mlflow/assistant/skills/install on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/assistant/api.py:1002]
- POST /bulk-register on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/skill_registry_api.py:1030]
- PUT /ajax-api/2.0/mlflow-artifacts/artifacts/{artifact_path:path} on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/artifact_router.py:150]
- PUT /ajax-api/3.0/mlflow/assistant/config on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/assistant/api.py:871]
- PUT /api/2.0/mlflow-artifacts/artifacts/{artifact_path:path} on port ; transport= encryption=Configurable auth=Unknown owner= [source: mlflow/server/artifact_router.py:146]
### integrations

- AWS (S3-compatible storage) interaction=Python SDK client role=runtime-integration protocol=HTTPS purpose=AWS service operations via boto3 [source: mlflow/gateway/providers/bedrock.py:295]
- Google Cloud Storage interaction=Python SDK client role=runtime-integration protocol=HTTPS purpose=GCS operations via Python SDK [source: mlflow/store/artifact/gcs_artifact_repo.py:58]
- api.openai.com interaction=HTTP client role=runtime-integration protocol=HTTPS purpose=Literal outbound HTTP endpoint [source: mlflow/deployments/openai/__init__.py:175]
- www.my.images interaction=HTTP client role=runtime-integration protocol=HTTPS purpose=Literal outbound HTTP endpoint [source: mlflow/transformers/__init__.py:2974]
- your-service-endpoint interaction=HTTP client role=runtime-integration protocol=HTTPS purpose=Literal outbound HTTP endpoint [source: mlflow/tracing/fluent.py:1760]
### internal_dependencies

- Kubernetes API interaction=Python client library role=runtime-integration purpose=Kubernetes resource operations via Python SDK [source: mlflow/projects/kubernetes.py:9]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Service mlflow-skinny targets  with 0 port(s) [source: mlflow/server/skill_registry_api.py:1137]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **observed**: All HTTP API uses None (no auth middleware detected) at FastAPI/Starlette application; policy=No authentication middleware registered [source: mlflow/server/skill_registry_api.py:1137]
- **dependency-signal**: rbac-ref targets kubernetes: Kubernetes client library (RBAC capable) [source: libs/skinny/pyproject.toml:71]
- **dependency-signal**: tls-config targets cryptography: TLS/cryptography library dependency [source: pyproject.toml:42]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
