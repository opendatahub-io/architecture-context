# Analyzer Synthesis Context: kubeflow-sdk

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 1 crds facts extracted [source: hack/crds/sparkoperator.k8s.io_sparkconnects.yaml:2]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 1 http_endpoints facts extracted [source: kubeflow/trainer/rhai/transformers_test.py:1607]
- **services (observed)**: 1 services facts extracted [source: kubeflow/trainer/rhai/transformers_test.py:1607]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (confirmed-empty)**: 0 webhooks facts extracted

## Deterministic Cross-References


## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `kubeflow/trainer/rhai/transformers_test.py`:1607 (HTTP API, None (no auth middleware detected))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `hack/Dockerfile.spark-e2e-runner`:18 (hack/Dockerfile.spark-e2e-runner:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `kubeflow/trainer/rhai/transformers_test.py`:1607 (PATCH, kubeflow.trainer.rhai.transformers.get_jit_checkpoint_injection_code)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `kubeflow/common/types.py`:16 (Kubernetes API, Python client library)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `kubeflow/trainer/rhai/transformers_test.py`:1607 (kubeflow)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- HTTP API methods=All mechanism=None (no auth middleware detected) enforcement=FastAPI/Starlette application policy=No authentication middleware registered [source: kubeflow/trainer/rhai/transformers_test.py:1607]
### http_endpoints

- PATCH kubeflow.trainer.rhai.transformers.get_jit_checkpoint_injection_code on port ; transport= encryption=Configurable auth=Unknown owner= [source: kubeflow/trainer/rhai/transformers_test.py:1607]
### internal_dependencies

- Kubernetes API interaction=Python client library role=runtime-integration purpose=Kubernetes resource operations via Python SDK [source: kubeflow/common/types.py:16]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Service kubeflow targets  with 0 port(s) [source: kubeflow/trainer/rhai/transformers_test.py:1607]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **observed**: All HTTP API uses None (no auth middleware detected) at FastAPI/Starlette application; policy=No authentication middleware registered [source: kubeflow/trainer/rhai/transformers_test.py:1607]
- **dependency-signal**: auth-middleware targets pyjwt: JWT/OAuth authentication library dependency [source: requirements.txt:1412]
- **dependency-signal**: rbac-ref targets kubernetes: Kubernetes client library (RBAC capable) [source: pyproject.toml:29]
- **dependency-signal**: tls-config targets cryptography: TLS/cryptography library dependency [source: requirements.txt:416]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
