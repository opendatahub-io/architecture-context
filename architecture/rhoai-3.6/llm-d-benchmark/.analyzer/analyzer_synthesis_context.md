# Analyzer Synthesis Context: llm-d-benchmark

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (not-verified)**: 0 http_endpoints facts extracted; absence is not proven by the available coverage
- **services (observed)**: 1 services facts extracted [source: util/deploy/common/patch-service.yaml:1]
- **ingress (observed)**: 1 ingress facts extracted [source: util/deploy/openshift/patch-route.yaml:1]
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References


## Behavioral Evidence

No bounded behavioral evidence was extracted.

## Gap Evidence Index

### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `util/deploy/rbac/patch-rbac-role.yaml`:1 (${PROJECT_NAME}-exec-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `util/deploy/rbac/patch-rbac-rolebinding.yaml`:1 (${PROJECT_NAME}-exec-role, ${PROJECT_NAME}-exec-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `build/Dockerfile`:156 (build/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `build/Dockerfile.s390x`:432 (build/Dockerfile.s390x:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `llm_d_stack_discovery/Dockerfile`:23 (llm_d_stack_discovery/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `pyproject.toml`:2 (llmdbenchmark)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `llmdbenchmark/results_store/client/gcs.py`:5 (Google Cloud Storage, Python SDK client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `benchmark-report/llmd_benchmark_report/native_to_br0_2.py`:277 (Kubernetes API, Python client library)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `util/deploy/common/patch-service.yaml`:1 (${PROJECT_NAME}-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `util/deploy/common/patch-statefulset.yaml`:1 (${PROJECT_NAME}-0, operator-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### integrations

- Google Cloud Storage interaction=Python SDK client role=runtime-integration protocol=HTTPS purpose=GCS operations via Python SDK [source: llmdbenchmark/results_store/client/gcs.py:5]
### internal_dependencies

- Kubernetes API interaction=Python client library role=runtime-integration purpose=Kubernetes resource operations via Python SDK [source: benchmark-report/llmd_benchmark_report/native_to_br0_2.py:277]
### services

- ${PROJECT_NAME}-service port=8080 target=8080 protocol=TCP encryption= auth= [source: util/deploy/common/patch-service.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Service ${PROJECT_NAME}-service targets  with 1 port(s) [source: util/deploy/common/patch-service.yaml:1]
- **observed**: StatefulSet workload ${PROJECT_NAME}-0 uses service account operator-controller-manager and 1 container(s) [source: util/deploy/common/patch-statefulset.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: Route ${PROJECT_NAME}-route serves host  via TLS; backend=${PROJECT_NAME}-service; transport=HTTPS [source: util/deploy/openshift/patch-route.yaml:1]
### security

- **observed**: RBAC role ${PROJECT_NAME}-exec-role grants 1 rule(s) [source: util/deploy/rbac/patch-rbac-role.yaml:1]
- **dependency-signal**: rbac-ref targets kubernetes: Kubernetes client library (RBAC capable) [source: pyproject.toml:11]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
