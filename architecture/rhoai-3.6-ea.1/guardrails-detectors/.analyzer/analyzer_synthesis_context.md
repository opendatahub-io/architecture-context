# Analyzer Synthesis Context: guardrails-detectors

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (not-verified)**: 0 grpc_services facts extracted; absence is not proven by the available coverage
- **http_endpoints (observed)**: 5 http_endpoints facts extracted [source: detectors/built_in/app.py:35, detectors/built_in/app.py:42, detectors/built_in/app.py:68, detectors/llm_judge/app.py:57, detectors/llm_judge/app.py:78]
- **services (observed)**: 2 services facts extracted [source: detectors/huggingface/deploy/model_container.yaml:1, detectors/llm_judge/app.py:78]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References


## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `detectors/llm_judge/app.py`:78 (HTTP API, None (no auth middleware detected))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `detectors/huggingface/deploy/model_container.yaml`:117 (user-one-view, view)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `detectors/Dockerfile.builtIn`:25 (detectors/Dockerfile.builtIn:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `detectors/Dockerfile.hf`:23 (detectors/Dockerfile.hf:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `detectors/Dockerfile.judge`:19 (detectors/Dockerfile.judge:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `detectors/Dockerfile.konflux.builtIn`:30 (detectors/Dockerfile.konflux.builtIn:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `detectors/Dockerfile.konflux.hf`:29 (detectors/Dockerfile.konflux.hf:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `detectors/requirements.builtIn.txt`:157 (uvicorn)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `detectors/built_in/app.py`:42 (/api/v1/text/contents, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `detectors/llm_judge/app.py`:78 (/api/v1/metrics, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `detectors/huggingface/deploy/model_container.yaml`:27 (guardrails-container-deployment-guardian)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `detectors/huggingface/deploy/model_container.yaml`:1 (guardrails-container-deployment-guardian, minio-guardrails-guardian)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `detectors/llm_judge/app.py`:78 (guardrails-detectors)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- HTTP API methods=All mechanism=None (no auth middleware detected) enforcement=FastAPI/Starlette application policy=No authentication middleware registered [source: detectors/llm_judge/app.py:78]
### http_endpoints

- GET /api/v1/metrics on port ; transport= encryption=Configurable auth=Unknown owner= [source: detectors/llm_judge/app.py:78]
- GET /metrics on port ; transport= encryption=Configurable auth=Unknown owner= [source: detectors/built_in/app.py:35]
- GET /registry on port ; transport= encryption=Configurable auth=Unknown owner= [source: detectors/built_in/app.py:68]
- POST /api/v1/text/contents on port ; transport= encryption=Configurable auth=Unknown owner= [source: detectors/built_in/app.py:42]
- POST /api/v1/text/generation on port ; transport= encryption=Configurable auth=Unknown owner= [source: detectors/llm_judge/app.py:57]
### services

- minio-guardrails-guardian port=9000 target=9000 protocol=TCP encryption= auth= [source: detectors/huggingface/deploy/model_container.yaml:1]
### serving_runtime_definitions

- ServingRuntime guardrails-detector-runtime-guardian formats=guardrails-detector-huggingface (autoSelect) images=kserve-container=quay.io/rh-ee-mmisiura/guardrails-detector-huggingface:3d51741 builtInAdapter= [source: detectors/huggingface/deploy/servingruntime.yaml:1]
- ServingRuntime guardrails-detector-runtime-judge formats=guardrails-detector-llm-judge (autoSelect) images=kserve-container=quay.io/trustyai/guardrails-detector-llm-judge:latest builtInAdapter= [source: detectors/llm_judge/deploy/servingruntime.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload guardrails-container-deployment-guardian uses service account  and 1 container(s) [source: detectors/huggingface/deploy/model_container.yaml:27]
- **observed**: Service guardrails-detectors targets  with 0 port(s) [source: detectors/llm_judge/app.py:78]
- **observed**: Service minio-guardrails-guardian targets guardrails-container-deployment-guardian with 1 port(s) [source: detectors/huggingface/deploy/model_container.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **observed**: All HTTP API uses None (no auth middleware detected) at FastAPI/Starlette application; policy=No authentication middleware registered [source: detectors/llm_judge/app.py:78]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
