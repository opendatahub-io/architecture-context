# Analyzer Synthesis Context: llm-d-planner

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 37 http_endpoints facts extracted [source: simulator/simulator_service.py:237, simulator/simulator_service.py:247, simulator/simulator_service.py:253, simulator/simulator_service.py:272, simulator/simulator_service.py:312, simulator/simulator_service.py:356, src/planner/api/routes/capacity_planner.py:165, src/planner/api/routes/capacity_planner.py:91, src/planner/api/routes/configuration.py:137, src/planner/api/routes/configuration.py:224, src/planner/api/routes/configuration.py:302, src/planner/api/routes/configuration.py:329, src/planner/api/routes/configuration.py:367, src/planner/api/routes/configuration.py:405, src/planner/api/routes/configuration.py:64, src/planner/api/routes/configuration.py:72, src/planner/api/routes/configuration.py:81, src/planner/api/routes/database.py:130, src/planner/api/routes/database.py:37, src/planner/api/routes/database.py:43, src/planner/api/routes/database.py:50, src/planner/api/routes/database.py:64, src/planner/api/routes/gpu_recommender.py:42, src/planner/api/routes/intent.py:23, src/planner/api/routes/quality.py:51, src/planner/api/routes/quality.py:65, src/planner/api/routes/quality.py:73, src/planner/api/routes/recommendation.py:167, src/planner/api/routes/recommendation.py:276, src/planner/api/routes/recommendation.py:75, src/planner/api/routes/reference_data.py:23, src/planner/api/routes/reference_data.py:34, src/planner/api/routes/reference_data.py:45, src/planner/api/routes/reference_data.py:59, src/planner/api/routes/specification.py:101, src/planner/api/routes/specification.py:162, src/planner/api/routes/specification.py:35]
- **services (observed)**: 4 services facts extracted [source: deploy/kubernetes/backend.yaml:150, deploy/kubernetes/ollama.yaml:90, deploy/kubernetes/ui.yaml:56, simulator/simulator_service.py:237]
- **ingress (observed)**: 2 ingress facts extracted [source: deploy/kubernetes/route.yaml:1, deploy/kubernetes/route.yaml:19]
- **webhooks (confirmed-empty)**: 0 webhooks facts extracted

## Deterministic Cross-References


## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `deploy/kubernetes/backend.yaml`:1 (:8000/health, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `simulator/simulator_service.py`:237 (HTTP API, None (no auth middleware detected))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `deploy/kubernetes/gpu-reader-rbac.yaml`:9 (planner-gpu-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `deploy/kubernetes/gpu-reader-rbac.yaml`:20 (planner-gpu-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:57 (Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `pyproject.toml`:2 (planner)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `simulator/Dockerfile`:29 (simulator/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `ui/Dockerfile`:31 (ui/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `simulator/simulator_service.py`:237 (/, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/planner/api/routes/capacity_planner.py`:165 (/api/v1/calculate, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/planner/api/routes/configuration.py`:302 (/api/v1/cluster-status, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/planner/api/routes/database.py`:37 (/api/v1/db/admin-required, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/planner/api/routes/gpu_recommender.py`:42 (/api/v1/estimate, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/planner/api/routes/intent.py`:23 (/api/v1/extract, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/planner/api/routes/quality.py`:51 (/api/v1/quality/auto-update, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/planner/api/routes/recommendation.py`:167 (/api/v1/ranked-recommend-from-spec, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/planner/api/routes/reference_data.py`:34 (/api/v1/gpu-types, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/planner/api/routes/specification.py`:162 (/api/v1/expected-rps/{use_case}, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `deploy/kubernetes/gpu-reader-rbac.yaml`:9 (API client, Kubernetes API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `src/planner/llm/openai_client.py`:10 (OpenAI API, Python SDK client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `deploy/kubernetes/gpu-reader-rbac.yaml`:9 (Kubernetes API (nodes), list)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `deploy/kubernetes/service-ca-configmap.yaml`:3 (CA bundle injection, OpenShift Service CA)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `src/planner/cluster/gpu_detector.py`:43 (Kubernetes API, Python client library)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `deploy/kubernetes/backend.yaml`:1 (backend, planner-backend)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `deploy/kubernetes/backend.yaml`:150 (backend)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `deploy/kubernetes/ollama.yaml`:1 (ollama)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `deploy/kubernetes/ollama.yaml`:90 (ollama)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `deploy/kubernetes/ui.yaml`:1 (ui)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `deploy/kubernetes/ui.yaml`:56 (ui)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `simulator/simulator_service.py`:237 (planner)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- :8000/health methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes liveness probe endpoint [source: deploy/kubernetes/backend.yaml:1]
- HTTP API methods=All mechanism=None (no auth middleware detected) enforcement=FastAPI/Starlette application policy=No authentication middleware registered [source: simulator/simulator_service.py:237]
### http_endpoints

- DELETE /api/v1/deployments/{deployment_id} on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: src/planner/api/routes/configuration.py:367]
- GET / on port ; transport= encryption=Configurable auth=Unknown owner= [source: simulator/simulator_service.py:237]
- GET /api/v1/cluster-status on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: src/planner/api/routes/configuration.py:302]
- GET /api/v1/db/admin-required on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: src/planner/api/routes/database.py:37]
- GET /api/v1/db/status on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: src/planner/api/routes/database.py:50]
- GET /api/v1/deployment-mode on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: src/planner/api/routes/configuration.py:64]
- GET /api/v1/deployments on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: src/planner/api/routes/configuration.py:405]
- GET /api/v1/deployments/{deployment_id}/k8s-status on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: src/planner/api/routes/configuration.py:329]
- GET /api/v1/deployments/{deployment_id}/status on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: src/planner/api/routes/configuration.py:137]
- GET /api/v1/expected-rps/{use_case} on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: src/planner/api/routes/specification.py:162]
- GET /api/v1/gpu-types on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: src/planner/api/routes/reference_data.py:34]
- GET /api/v1/models on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: src/planner/api/routes/reference_data.py:23]
- GET /api/v1/priority-weights on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: src/planner/api/routes/reference_data.py:59]
- GET /api/v1/quality/auto-update on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: src/planner/api/routes/quality.py:51]
- GET /api/v1/slo-defaults/{use_case} on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: src/planner/api/routes/specification.py:35]
- GET /api/v1/use-cases on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: src/planner/api/routes/reference_data.py:45]
- GET /api/v1/workload-profile/{use_case} on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: src/planner/api/routes/specification.py:101]
- GET /health on port ; transport= encryption=Configurable auth=Unknown owner= [source: simulator/simulator_service.py:247]
- GET /metrics on port ; transport= encryption=Configurable auth=Unknown owner= [source: simulator/simulator_service.py:356]
- GET /v1/models on port ; transport= encryption=Configurable auth=Unknown owner= [source: simulator/simulator_service.py:253]
- POST /api/v1/calculate on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: src/planner/api/routes/capacity_planner.py:165]
- POST /api/v1/db/reset on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: src/planner/api/routes/database.py:130]
- POST /api/v1/db/upload-benchmarks on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: src/planner/api/routes/database.py:64]
- POST /api/v1/db/verify-admin on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: src/planner/api/routes/database.py:43]
- POST /api/v1/deploy on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: src/planner/api/routes/configuration.py:81]
- POST /api/v1/deploy-to-cluster on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: src/planner/api/routes/configuration.py:224]
- POST /api/v1/estimate on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: src/planner/api/routes/gpu_recommender.py:42]
- POST /api/v1/extract on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: src/planner/api/routes/intent.py:23]
- POST /api/v1/model-info on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: src/planner/api/routes/capacity_planner.py:91]
- POST /api/v1/quality/refresh on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: src/planner/api/routes/quality.py:73]
- POST /api/v1/ranked-recommend-from-spec on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: src/planner/api/routes/recommendation.py:167]
- POST /api/v1/recommend on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: src/planner/api/routes/recommendation.py:75]
- POST /api/v1/test on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: src/planner/api/routes/recommendation.py:276]
- POST /v1/chat/completions on port ; transport= encryption=Configurable auth=Unknown owner= [source: simulator/simulator_service.py:312]
- POST /v1/completions on port ; transport= encryption=Configurable auth=Unknown owner= [source: simulator/simulator_service.py:272]
- PUT /api/v1/deployment-mode on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: src/planner/api/routes/configuration.py:72]
- PUT /api/v1/quality/auto-update on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: src/planner/api/routes/quality.py:65]
### integrations

- Kubernetes API interaction=API client role=runtime-integration protocol=HTTPS purpose=Cluster resource management via RBAC [source: deploy/kubernetes/gpu-reader-rbac.yaml:9]
- OpenAI API interaction=Python SDK client role=runtime-integration protocol=HTTPS purpose=LLM inference via OpenAI SDK [source: src/planner/llm/openai_client.py:10]
### internal_dependencies

- Kubernetes API (nodes) interaction=list role=unknown purpose=nodes resource access via RBAC [source: deploy/kubernetes/gpu-reader-rbac.yaml:9]
- Kubernetes API interaction=Python client library role=runtime-integration purpose=Kubernetes resource operations via Python SDK [source: src/planner/cluster/gpu_detector.py:43]
- OpenShift Service CA interaction=CA bundle injection role=unknown purpose=TLS certificate trust via service-ca operator annotation [source: deploy/kubernetes/service-ca-configmap.yaml:3]
### services

- backend port=8000 target=8000 protocol=TCP encryption= auth= [source: deploy/kubernetes/backend.yaml:150]
- ollama port=11434 target=11434 protocol=TCP encryption= auth= [source: deploy/kubernetes/ollama.yaml:90]
- planner port=8000 target=8000 protocol=TCP encryption= auth= [source: simulator/simulator_service.py:237]
- ui port=8501 target=8501 protocol=TCP encryption= auth= [source: deploy/kubernetes/ui.yaml:56]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload backend uses service account planner-backend and 1 container(s) [source: deploy/kubernetes/backend.yaml:1]
- **observed**: Deployment workload ollama uses service account  and 1 container(s) [source: deploy/kubernetes/ollama.yaml:1]
- **observed**: Deployment workload ui uses service account  and 1 container(s) [source: deploy/kubernetes/ui.yaml:1]
- **observed**: Service backend targets backend with 1 port(s) [source: deploy/kubernetes/backend.yaml:150]
- **observed**: Service ollama targets ollama with 1 port(s) [source: deploy/kubernetes/ollama.yaml:90]
- **observed**: Service planner targets  with 1 port(s) [source: simulator/simulator_service.py:237]
- **observed**: Service ui targets ui with 1 port(s) [source: deploy/kubernetes/ui.yaml:56]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: Route planner serves host  via TLS; backend=ui; transport=HTTPS [source: deploy/kubernetes/route.yaml:1]
- **observed**: Route planner-backend serves host  via TLS; backend=backend; transport=HTTPS [source: deploy/kubernetes/route.yaml:19]
### security

- **observed**: All HTTP API uses None (no auth middleware detected) at FastAPI/Starlette application; policy=No authentication middleware registered [source: simulator/simulator_service.py:237]
- **observed**: GET :8000/health uses None at N/A; policy=Unauthenticated Kubernetes liveness probe endpoint [source: deploy/kubernetes/backend.yaml:1]
- **observed**: RBAC role planner-gpu-reader grants 1 rule(s) [source: deploy/kubernetes/gpu-reader-rbac.yaml:9]
- **dependency-signal**: rbac-ref targets kubernetes: Kubernetes client library (RBAC capable) [source: pyproject.toml:38]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
