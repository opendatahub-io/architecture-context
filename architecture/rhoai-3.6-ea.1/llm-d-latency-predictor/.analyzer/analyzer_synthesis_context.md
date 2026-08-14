# Analyzer Synthesis Context: llm-d-latency-predictor

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 24 http_endpoints facts extracted [source: prediction/prediction_server.py:1017, prediction/prediction_server.py:1070, prediction/prediction_server.py:1140, prediction/prediction_server.py:1159, prediction/prediction_server.py:1164, prediction/prediction_server.py:1176, prediction/prediction_server.py:965, prediction/prediction_server.py:997, training/training_server.py:1870, training/training_server.py:1923, training/training_server.py:1970, training/training_server.py:1996, training/training_server.py:2060, training/training_server.py:2109, training/training_server.py:2155, training/training_server.py:2178, training/training_server.py:2199, training/training_server.py:2227, training/training_server.py:2245, training/training_server.py:2276, training/training_server.py:2294, training/training_server.py:2312, training/training_server.py:2333, training/training_server.py:2354]
- **services (observed)**: 3 services facts extracted [source: deploy/base/prediction/service.yaml:2, deploy/base/training/service.yaml:2, prediction/prediction_server.py:1176]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (confirmed-empty)**: 0 webhooks facts extracted

## Deterministic Cross-References


## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `deploy/base/prediction/deployment.yaml`:2 (:8001/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `deploy/base/training/deployment.yaml`:2 (:8000/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `prediction/prediction_server.py`:1176 (HTTP API, None (no auth middleware detected))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux.prediction`:19 (Dockerfile.konflux.prediction:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux.test`:17 (Dockerfile.konflux.test:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux.training`:14 (Dockerfile.konflux.training:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `prediction/Dockerfile`:42 (prediction/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `requirements-konflux.txt`:147 (uvicorn)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `tests/Dockerfile`:44 (tests/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `training/Dockerfile`:40 (training/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `prediction/prediction_server.py`:1176 (/, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `training/training_server.py`:1870 (/add_training_data_bulk, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `deploy/base/prediction/deployment.yaml`:2 (prediction-server-deployment)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `deploy/base/prediction/service.yaml`:2 (prediction-server-deployment, prediction-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `deploy/base/training/deployment.yaml`:2 (training-server-deployment)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `deploy/base/training/service.yaml`:2 (training-server-deployment, training-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `prediction/prediction_server.py`:1176 (llm-d-latency-predictor)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- :8000/healthz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes liveness probe endpoint [source: deploy/base/training/deployment.yaml:2]
- :8000/readyz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes readiness probe endpoint [source: deploy/base/training/deployment.yaml:2]
- :8001/healthz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes liveness probe endpoint [source: deploy/base/prediction/deployment.yaml:2]
- :8001/readyz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes readiness probe endpoint [source: deploy/base/prediction/deployment.yaml:2]
- HTTP API methods=All mechanism=None (no auth middleware detected) enforcement=FastAPI/Starlette application policy=No authentication middleware registered [source: prediction/prediction_server.py:1176]
### http_endpoints

- GET / on port ; transport= encryption=Configurable auth=Unknown owner= [source: prediction/prediction_server.py:1176]
- GET /data/status on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: training/training_server.py:2060]
- GET /debug/prefix_distribution on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: training/training_server.py:2354]
- GET /healthz on port ; transport= encryption=Configurable auth=Unknown owner= [source: prediction/prediction_server.py:1159]
- GET /metrics on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: training/training_server.py:1970]
- GET /model/download/info on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: training/training_server.py:2109]
- GET /model/export on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: training/training_server.py:1923]
- GET /model/tpot/lgb/importances on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: training/training_server.py:2333]
- GET /model/tpot/lgb/txt on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: training/training_server.py:2294]
- GET /model/tpot/xgb/json on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: training/training_server.py:2178]
- GET /model/ttft/lgb/importances on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: training/training_server.py:2312]
- GET /model/ttft/lgb/txt on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: training/training_server.py:2276]
- GET /model/ttft/xgb/json on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: training/training_server.py:2155]
- GET /model/{model_name}/download on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: training/training_server.py:2227]
- GET /model/{model_name}/info on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: training/training_server.py:2199]
- GET /models/list on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: training/training_server.py:2245]
- GET /readyz on port ; transport= encryption=Configurable auth=Unknown owner= [source: prediction/prediction_server.py:1164]
- GET /status on port ; transport= encryption=Configurable auth=Unknown owner= [source: prediction/prediction_server.py:965]
- POST /add_training_data_bulk on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: training/training_server.py:1870]
- POST /flush on port 8000/TCP; transport= encryption=Configurable auth=Unknown owner= [source: training/training_server.py:1996]
- POST /predict on port ; transport= encryption=Configurable auth=Unknown owner= [source: prediction/prediction_server.py:997]
- POST /predict/bulk on port ; transport= encryption=Configurable auth=Unknown owner= [source: prediction/prediction_server.py:1070]
- POST /predict/bulk/strict on port ; transport= encryption=Configurable auth=Unknown owner= [source: prediction/prediction_server.py:1017]
- POST /reload on port ; transport= encryption=Configurable auth=Unknown owner= [source: prediction/prediction_server.py:1140]
### services

- llm-d-latency-predictor port=8000 target=8000 protocol=TCP encryption= auth= [source: prediction/prediction_server.py:1176]
- prediction-service port=80 target=8001 protocol=TCP encryption= auth= [source: deploy/base/prediction/service.yaml:2]
- training-service port=8000 target=8000 protocol=TCP encryption= auth= [source: deploy/base/training/service.yaml:2]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload prediction-server-deployment uses service account  and 1 container(s) [source: deploy/base/prediction/deployment.yaml:2]
- **observed**: Deployment workload training-server-deployment uses service account  and 1 container(s) [source: deploy/base/training/deployment.yaml:2]
- **observed**: Service llm-d-latency-predictor targets  with 1 port(s) [source: prediction/prediction_server.py:1176]
- **observed**: Service prediction-service targets prediction-server-deployment with 1 port(s) [source: deploy/base/prediction/service.yaml:2]
- **observed**: Service training-service targets training-server-deployment with 1 port(s) [source: deploy/base/training/service.yaml:2]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **observed**: All HTTP API uses None (no auth middleware detected) at FastAPI/Starlette application; policy=No authentication middleware registered [source: prediction/prediction_server.py:1176]
- **observed**: GET :8000/healthz uses None at N/A; policy=Unauthenticated Kubernetes liveness probe endpoint [source: deploy/base/training/deployment.yaml:2]
- **observed**: GET :8000/readyz uses None at N/A; policy=Unauthenticated Kubernetes readiness probe endpoint [source: deploy/base/training/deployment.yaml:2]
- **observed**: GET :8001/healthz uses None at N/A; policy=Unauthenticated Kubernetes liveness probe endpoint [source: deploy/base/prediction/deployment.yaml:2]
- **observed**: GET :8001/readyz uses None at N/A; policy=Unauthenticated Kubernetes readiness probe endpoint [source: deploy/base/prediction/deployment.yaml:2]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
