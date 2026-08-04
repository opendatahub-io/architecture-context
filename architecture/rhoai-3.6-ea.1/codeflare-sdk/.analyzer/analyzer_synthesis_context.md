# Analyzer Synthesis Context: codeflare-sdk

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 1 http_endpoints facts extracted [source: src/codeflare_sdk/common/kubernetes_cluster/test_kube_api_helpers.py:62]
- **services (observed)**: 2 services facts extracted [source: src/codeflare_sdk/common/kubernetes_cluster/test_kube_api_helpers.py:62, tests/e2e/minio_deployment.yaml:107]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (confirmed-empty)**: 0 webhooks facts extracted

## Deterministic Cross-References


## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `src/codeflare_sdk/common/kubernetes_cluster/test_kube_api_helpers.py`:62 (HTTP API, None (no auth middleware detected))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `images/tests/rbac-test-user-permissions.yaml`:58 (test-user-kueue-admin)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `images/tests/rbac-test-user-permissions.yaml`:12 (self-provisioner, test-user-self-provisioner)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `images/tests/Dockerfile`:134 (images/tests/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/codeflare_sdk/common/kubernetes_cluster/test_kube_api_helpers.py`:62 (PATCH, builtins.print)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `scripts/migration/ray_cluster_migration.py`:82 (Kubernetes API, Python client library)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `src/codeflare_sdk/ray/client/ray_jobs.py`:20 (Python client library, Ray)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `src/codeflare_sdk/common/kubernetes_cluster/test_kube_api_helpers.py`:62 (codeflare-sdk)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `tests/e2e/minio_deployment.yaml`:24 (minio)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `tests/e2e/minio_deployment.yaml`:107 (minio, minio-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- HTTP API methods=All mechanism=None (no auth middleware detected) enforcement=FastAPI/Starlette application policy=No authentication middleware registered [source: src/codeflare_sdk/common/kubernetes_cluster/test_kube_api_helpers.py:62]
### http_endpoints

- PATCH builtins.print on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/codeflare_sdk/common/kubernetes_cluster/test_kube_api_helpers.py:62]
### internal_dependencies

- Kubernetes API interaction=Python client library role=runtime-integration purpose=Kubernetes resource operations via Python SDK [source: scripts/migration/ray_cluster_migration.py:82]
- Ray interaction=Python client library role=runtime-integration purpose=Distributed compute orchestration via Ray SDK [source: src/codeflare_sdk/ray/client/ray_jobs.py:20]
### services

- minio-service port=9000 target=9000 protocol=TCP encryption= auth= [source: tests/e2e/minio_deployment.yaml:107]
- minio-service port=9090 target=9090 protocol=TCP encryption= auth= [source: tests/e2e/minio_deployment.yaml:107]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload minio uses service account  and 1 container(s) [source: tests/e2e/minio_deployment.yaml:24]
- **observed**: Service codeflare-sdk targets  with 0 port(s) [source: src/codeflare_sdk/common/kubernetes_cluster/test_kube_api_helpers.py:62]
- **observed**: Service minio-service targets minio with 2 port(s) [source: tests/e2e/minio_deployment.yaml:107]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **observed**: All HTTP API uses None (no auth middleware detected) at FastAPI/Starlette application; policy=No authentication middleware registered [source: src/codeflare_sdk/common/kubernetes_cluster/test_kube_api_helpers.py:62]
- **observed**: RBAC role kueue-batch-user-role grants 5 rule(s) [source: images/tests/rbac-test-user-permissions.yaml:127]
- **observed**: RBAC role test-user-kueue-admin grants 1 rule(s) [source: images/tests/rbac-test-user-permissions.yaml:58]
- **observed**: RBAC role test-user-ray-admin grants 1 rule(s) [source: images/tests/rbac-test-user-permissions.yaml:93]
- **dependency-signal**: rbac-ref targets kubernetes: Kubernetes client library (RBAC capable) [source: src/codeflare_sdk/vendored/pyproject.toml:22]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
