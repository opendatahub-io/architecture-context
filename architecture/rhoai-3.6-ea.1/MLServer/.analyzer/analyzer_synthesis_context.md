# Analyzer Synthesis Context: MLServer

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (observed)**: 16 grpc_services facts extracted [source: mlserver/grpc/server.py:81, mlserver/grpc/server.py:84, proto/dataplane.proto:14, proto/dataplane.proto:17, proto/dataplane.proto:20, proto/dataplane.proto:23, proto/dataplane.proto:26, proto/dataplane.proto:29, proto/dataplane.proto:32, proto/dataplane.proto:35, proto/dataplane.proto:38, proto/dataplane.proto:42, proto/dataplane.proto:46, proto/model_repository.proto:12, proto/model_repository.proto:16, proto/model_repository.proto:8]
- **http_endpoints (not-verified)**: 0 http_endpoints facts extracted; absence is not proven by the available coverage
- **services (not-verified)**: 0 services facts extracted; absence is not proven by the available coverage
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References


## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `platform-delegated:kube-rbac-proxy sidecar` (inference.GRPCInferenceService/ModelInfer, kube-rbac-proxy sidecar (platform-delegated))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:124 (Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.cuda`:139 (Dockerfile.cuda:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:66 (Dockerfile.konflux:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux.cuda`:69 (Dockerfile.konflux.cuda:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `pyproject.toml`:55 (uvicorn)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### grpc_services

- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `mlserver/grpc/server.py`:81 (GRPCInferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `proto/dataplane.proto`:32 (inference.GRPCInferenceService/ModelInfer)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `proto/model_repository.proto`:8 (inference.model_repository.ModelRepositoryService/RepositoryIndex)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `mlserver/grpc/interceptors.py`:6 (Python library, gRPC framework)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- GRPCInferenceService methods=gRPC mechanism=kube-rbac-proxy sidecar (platform-delegated) enforcement=KServe pod kube-rbac-proxy container policy=OpenShift OAuth/ServiceAccount token validation [source: platform-delegated:kube-rbac-proxy sidecar]
- ModelRepositoryService methods=gRPC mechanism=kube-rbac-proxy sidecar (platform-delegated) enforcement=KServe pod kube-rbac-proxy container policy=OpenShift OAuth/ServiceAccount token validation [source: platform-delegated:kube-rbac-proxy sidecar]
- inference.GRPCInferenceService/ModelInfer methods=gRPC mechanism=kube-rbac-proxy sidecar (platform-delegated) enforcement=KServe pod kube-rbac-proxy container policy=OpenShift OAuth/ServiceAccount token validation [source: platform-delegated:kube-rbac-proxy sidecar]
- inference.GRPCInferenceService/ModelMetadata methods=gRPC mechanism=kube-rbac-proxy sidecar (platform-delegated) enforcement=KServe pod kube-rbac-proxy container policy=OpenShift OAuth/ServiceAccount token validation [source: platform-delegated:kube-rbac-proxy sidecar]
- inference.GRPCInferenceService/ModelReady methods=gRPC mechanism=kube-rbac-proxy sidecar (platform-delegated) enforcement=KServe pod kube-rbac-proxy container policy=OpenShift OAuth/ServiceAccount token validation [source: platform-delegated:kube-rbac-proxy sidecar]
- inference.GRPCInferenceService/ModelStreamInfer methods=gRPC mechanism=kube-rbac-proxy sidecar (platform-delegated) enforcement=KServe pod kube-rbac-proxy container policy=OpenShift OAuth/ServiceAccount token validation [source: platform-delegated:kube-rbac-proxy sidecar]
- inference.GRPCInferenceService/RepositoryIndex methods=gRPC mechanism=kube-rbac-proxy sidecar (platform-delegated) enforcement=KServe pod kube-rbac-proxy container policy=OpenShift OAuth/ServiceAccount token validation [source: platform-delegated:kube-rbac-proxy sidecar]
- inference.GRPCInferenceService/RepositoryModelLoad methods=gRPC mechanism=kube-rbac-proxy sidecar (platform-delegated) enforcement=KServe pod kube-rbac-proxy container policy=OpenShift OAuth/ServiceAccount token validation [source: platform-delegated:kube-rbac-proxy sidecar]
- inference.GRPCInferenceService/RepositoryModelUnload methods=gRPC mechanism=kube-rbac-proxy sidecar (platform-delegated) enforcement=KServe pod kube-rbac-proxy container policy=OpenShift OAuth/ServiceAccount token validation [source: platform-delegated:kube-rbac-proxy sidecar]
- inference.GRPCInferenceService/RuntimeSecurity methods=gRPC mechanism=kube-rbac-proxy sidecar (platform-delegated) enforcement=KServe pod kube-rbac-proxy container policy=OpenShift OAuth/ServiceAccount token validation [source: platform-delegated:kube-rbac-proxy sidecar]
- inference.GRPCInferenceService/ServerLive methods=gRPC mechanism=kube-rbac-proxy sidecar (platform-delegated) enforcement=KServe pod kube-rbac-proxy container policy=OpenShift OAuth/ServiceAccount token validation [source: platform-delegated:kube-rbac-proxy sidecar]
- inference.GRPCInferenceService/ServerMetadata methods=gRPC mechanism=kube-rbac-proxy sidecar (platform-delegated) enforcement=KServe pod kube-rbac-proxy container policy=OpenShift OAuth/ServiceAccount token validation [source: platform-delegated:kube-rbac-proxy sidecar]
- inference.GRPCInferenceService/ServerReady methods=gRPC mechanism=kube-rbac-proxy sidecar (platform-delegated) enforcement=KServe pod kube-rbac-proxy container policy=OpenShift OAuth/ServiceAccount token validation [source: platform-delegated:kube-rbac-proxy sidecar]
- inference.model_repository.ModelRepositoryService/RepositoryIndex methods=gRPC mechanism=kube-rbac-proxy sidecar (platform-delegated) enforcement=KServe pod kube-rbac-proxy container policy=OpenShift OAuth/ServiceAccount token validation [source: platform-delegated:kube-rbac-proxy sidecar]
- inference.model_repository.ModelRepositoryService/RepositoryModelLoad methods=gRPC mechanism=kube-rbac-proxy sidecar (platform-delegated) enforcement=KServe pod kube-rbac-proxy container policy=OpenShift OAuth/ServiceAccount token validation [source: platform-delegated:kube-rbac-proxy sidecar]
- inference.model_repository.ModelRepositoryService/RepositoryModelUnload methods=gRPC mechanism=kube-rbac-proxy sidecar (platform-delegated) enforcement=KServe pod kube-rbac-proxy container policy=OpenShift OAuth/ServiceAccount token validation [source: platform-delegated:kube-rbac-proxy sidecar]
### internal_dependencies

- gRPC framework interaction=Python library role=runtime-library purpose=gRPC transport for service communication [source: mlserver/grpc/interceptors.py:6]

## Cross-Cutting Evidence

### deployment_topology

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:deployment_topology]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **observed**: gRPC GRPCInferenceService uses kube-rbac-proxy sidecar (platform-delegated) at KServe pod kube-rbac-proxy container; policy=OpenShift OAuth/ServiceAccount token validation [source: platform-delegated:kube-rbac-proxy sidecar]
- **observed**: gRPC ModelRepositoryService uses kube-rbac-proxy sidecar (platform-delegated) at KServe pod kube-rbac-proxy container; policy=OpenShift OAuth/ServiceAccount token validation [source: platform-delegated:kube-rbac-proxy sidecar]
- **observed**: gRPC inference.GRPCInferenceService/ModelInfer uses kube-rbac-proxy sidecar (platform-delegated) at KServe pod kube-rbac-proxy container; policy=OpenShift OAuth/ServiceAccount token validation [source: platform-delegated:kube-rbac-proxy sidecar]
- **observed**: gRPC inference.GRPCInferenceService/ModelMetadata uses kube-rbac-proxy sidecar (platform-delegated) at KServe pod kube-rbac-proxy container; policy=OpenShift OAuth/ServiceAccount token validation [source: platform-delegated:kube-rbac-proxy sidecar]
- **observed**: gRPC inference.GRPCInferenceService/ModelReady uses kube-rbac-proxy sidecar (platform-delegated) at KServe pod kube-rbac-proxy container; policy=OpenShift OAuth/ServiceAccount token validation [source: platform-delegated:kube-rbac-proxy sidecar]
- **observed**: gRPC inference.GRPCInferenceService/ModelStreamInfer uses kube-rbac-proxy sidecar (platform-delegated) at KServe pod kube-rbac-proxy container; policy=OpenShift OAuth/ServiceAccount token validation [source: platform-delegated:kube-rbac-proxy sidecar]
- **observed**: gRPC inference.GRPCInferenceService/RepositoryIndex uses kube-rbac-proxy sidecar (platform-delegated) at KServe pod kube-rbac-proxy container; policy=OpenShift OAuth/ServiceAccount token validation [source: platform-delegated:kube-rbac-proxy sidecar]
- **observed**: gRPC inference.GRPCInferenceService/RepositoryModelLoad uses kube-rbac-proxy sidecar (platform-delegated) at KServe pod kube-rbac-proxy container; policy=OpenShift OAuth/ServiceAccount token validation [source: platform-delegated:kube-rbac-proxy sidecar]
- **observed**: gRPC inference.GRPCInferenceService/RepositoryModelUnload uses kube-rbac-proxy sidecar (platform-delegated) at KServe pod kube-rbac-proxy container; policy=OpenShift OAuth/ServiceAccount token validation [source: platform-delegated:kube-rbac-proxy sidecar]
- **observed**: gRPC inference.GRPCInferenceService/RuntimeSecurity uses kube-rbac-proxy sidecar (platform-delegated) at KServe pod kube-rbac-proxy container; policy=OpenShift OAuth/ServiceAccount token validation [source: platform-delegated:kube-rbac-proxy sidecar]
- **observed**: gRPC inference.GRPCInferenceService/ServerLive uses kube-rbac-proxy sidecar (platform-delegated) at KServe pod kube-rbac-proxy container; policy=OpenShift OAuth/ServiceAccount token validation [source: platform-delegated:kube-rbac-proxy sidecar]
- **observed**: gRPC inference.GRPCInferenceService/ServerMetadata uses kube-rbac-proxy sidecar (platform-delegated) at KServe pod kube-rbac-proxy container; policy=OpenShift OAuth/ServiceAccount token validation [source: platform-delegated:kube-rbac-proxy sidecar]
- **observed**: gRPC inference.GRPCInferenceService/ServerReady uses kube-rbac-proxy sidecar (platform-delegated) at KServe pod kube-rbac-proxy container; policy=OpenShift OAuth/ServiceAccount token validation [source: platform-delegated:kube-rbac-proxy sidecar]
- **observed**: gRPC inference.model_repository.ModelRepositoryService/RepositoryIndex uses kube-rbac-proxy sidecar (platform-delegated) at KServe pod kube-rbac-proxy container; policy=OpenShift OAuth/ServiceAccount token validation [source: platform-delegated:kube-rbac-proxy sidecar]
- **observed**: gRPC inference.model_repository.ModelRepositoryService/RepositoryModelLoad uses kube-rbac-proxy sidecar (platform-delegated) at KServe pod kube-rbac-proxy container; policy=OpenShift OAuth/ServiceAccount token validation [source: platform-delegated:kube-rbac-proxy sidecar]
- **observed**: gRPC inference.model_repository.ModelRepositoryService/RepositoryModelUnload uses kube-rbac-proxy sidecar (platform-delegated) at KServe pod kube-rbac-proxy container; policy=OpenShift OAuth/ServiceAccount token validation [source: platform-delegated:kube-rbac-proxy sidecar]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
