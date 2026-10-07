# Analyzer Synthesis Context: ilab-on-ocp

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (not-verified)**: 0 http_endpoints facts extracted; absence is not proven by the available coverage
- **services (observed)**: 1 services facts extracted [source: manifests/nfs_storage/nfs-server-deployment.yaml:96]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References


## Behavioral Evidence

No bounded behavioral evidence was extracted.

## Gap Evidence Index

### authorization

- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `manifests/mixtral_serve/mixtral_serve/rbac.yaml`:23 (mixtral-view, mixtral-view-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/mixtral_serve/mixtral_serve/rbac.yaml`:7 (mixtral-view-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `manifests/nfs_storage/nfs-server-deployment.yaml`:20 (nfs-server-sa-anyuid, system:openshift:scc:anyuid)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `manifests/nfs_storage/nfs-server-deployment.yaml`:34 (nfs-server-sa-privileged, system:openshift:scc:privileged)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `manifests/prometheus_serve/prometheus_serve/rbac.yaml`:23 (prometheus-view, prometheus-view-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/prometheus_serve/prometheus_serve/rbac.yaml`:7 (prometheus-view-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `manifests/mixtral_serve/mixtral_serve/rbac.yaml`:7 (CRD Watch, KServe InferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `manifests/mixtral_serve/mixtral_serve/rbac.yaml`:7 (CRD Watch, KServe InferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pipeline.py`:7 (Kubeflow Pipelines SDK, Python client library)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `utils/components.py`:319 (Kubernetes API, Python client library)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `manifests/nfs_storage/nfs-server-deployment.yaml`:48 (nfs-server, nfs-server-sa)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `manifests/nfs_storage/nfs-server-deployment.yaml`:96 (nfs-server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### integrations

- KServe InferenceService interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read model serving state [source: manifests/mixtral_serve/mixtral_serve/rbac.yaml:7]
### internal_dependencies

- KServe InferenceService interaction=CRD Watch role=runtime-integration purpose=Read model serving state [source: manifests/mixtral_serve/mixtral_serve/rbac.yaml:7]
- Kubeflow Pipelines SDK interaction=Python client library role=runtime-integration purpose=Pipeline definition and execution [source: pipeline.py:7]
- Kubernetes API interaction=Python client library role=runtime-integration purpose=Kubernetes resource operations via Python SDK [source: utils/components.py:319]
### services

- nfs-server port=111 target=111 protocol=UDP encryption= auth= [source: manifests/nfs_storage/nfs-server-deployment.yaml:96]
- nfs-server port=2049 target=2049 protocol=TCP encryption= auth= [source: manifests/nfs_storage/nfs-server-deployment.yaml:96]
### serving_runtime_definitions

- ServingRuntime mixtral formats=vLLM (autoSelect) images=kserve-container=quay.io/modh/vllm@sha256:4f1f6b5738b311332b2bc786ea71259872e570081807592d97b4bd4cb65c4be1 builtInAdapter= [source: manifests/mixtral_serve/mixtral_serve/runtime.yaml:1]
- ServingRuntime prometheus formats=vLLM (autoSelect) images=kserve-container=quay.io/modh/vllm@sha256:3c56d4c2a5a9565e8b07ba17a6624290c4fb39ac9097b99b946326c09a8b40c8 builtInAdapter= [source: manifests/prometheus_serve/prometheus_serve/runtime.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload nfs-server uses service account nfs-server-sa and 1 container(s) [source: manifests/nfs_storage/nfs-server-deployment.yaml:48]
- **observed**: Service nfs-server targets nfs-server with 2 port(s) [source: manifests/nfs_storage/nfs-server-deployment.yaml:96]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **observed**: RBAC role mixtral-view-role grants 1 rule(s) [source: manifests/mixtral_serve/mixtral_serve/rbac.yaml:7]
- **observed**: RBAC role prometheus-view-role grants 1 rule(s) [source: manifests/prometheus_serve/prometheus_serve/rbac.yaml:7]
- **dependency-signal**: rbac-ref targets kubernetes: Kubernetes client library (RBAC capable) [source: pyproject.toml:12]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
