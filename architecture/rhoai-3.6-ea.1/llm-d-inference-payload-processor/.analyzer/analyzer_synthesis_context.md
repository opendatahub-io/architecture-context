# Analyzer Synthesis Context: llm-d-inference-payload-processor

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 1 crds facts extracted [source: apix/config/v1alpha1/payloadprocessorconfig_types.go:36]
- **grpc_services (observed)**: 2 grpc_services facts extracted [source: cmd/runner/runner.go:315, pkg/server/runserver.go:76]
- **http_endpoints (not-verified)**: 0 http_endpoints facts extracted; absence is not proven by the available coverage
- **services (observed)**: 4 services facts extracted [source: deploy/components/ipp/service.yaml:1, deploy/components/model-server/deepseek/deployment.yaml:35, deploy/components/model-server/llama/deployment.yaml:35, deploy/environments/dev/e2e-infra/envoy.yaml:169]
- **ingress (not-verified)**: 0 ingress facts extracted; absence is not proven by the available coverage
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References


## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/runner/runner.go`:315 (Health gRPC, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `pkg/server/runserver.go`:76 (External Processor gRPC, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `deploy/components/ipp/rbac.yaml`:7 (payload-processor-auth-reviewer)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `deploy/components/ipp/rbac.yaml`:16 (payload-processor-auth-reviewer, payload-processor-auth-reviewer-binding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:55 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/main.go`:27 (cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### grpc_services

- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `cmd/runner/runner.go`:315 (Health, cmd/runner)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `pkg/server/runserver.go`:76 (ExternalProcessor, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/framework/plugins/requesthandling/basemodelextractor/configmap_reconciler.go`:63 (/v1/ConfigMap, get operations by ConfigMapReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/server/runserver.go`:76 (Envoy proxy, gRPC ExtProc callout)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/framework/plugins/requesthandling/basemodelextractor/base_model_to_header.go`:66 (/v1/ConfigMap)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `pkg/framework/plugins/requesthandling/basemodelextractor/configmap_reconciler.go`:63 (/v1/ConfigMap, get operations by ConfigMapReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `deploy/components/ipp/deployment.yaml`:1 (payload-processor)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `deploy/components/ipp/service.yaml`:1 (payload-processor)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `deploy/components/model-server/deepseek/deployment.yaml`:1 (vllm-deepseek-r1)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `deploy/components/model-server/deepseek/deployment.yaml`:35 (vllm-deepseek-r1)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `deploy/components/model-server/llama/deployment.yaml`:1 (vllm-llama3-8b-instruct)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `deploy/components/model-server/llama/deployment.yaml`:35 (vllm-llama3-8b-instruct)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `deploy/environments/dev/e2e-infra/envoy.yaml`:127 (envoy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `deploy/environments/dev/e2e-infra/envoy.yaml`:169 (envoy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- External Processor gRPC methods=gRPC mechanism=None enforcement=N/A policy=Transport TLS is configuration-dependent; no application authentication interceptor is configured [source: pkg/server/runserver.go:76]
- Health gRPC methods=gRPC mechanism=None enforcement=N/A policy=Plaintext gRPC service has no application authentication interceptor [source: cmd/runner/runner.go:315]
### internal_dependencies

- Envoy proxy interaction=gRPC ExtProc callout role=runtime-transport purpose=Receive per-request processing callouts through the Envoy External Processing API [source: pkg/server/runserver.go:76]
### services

- envoy port=8081 target=8081 protocol=TCP encryption= auth= [source: deploy/environments/dev/e2e-infra/envoy.yaml:169]
- payload-processor port=9004 target=9004 protocol=TCP encryption= auth= [source: deploy/components/ipp/service.yaml:1]
- payload-processor port=9090 target=9090 protocol=TCP encryption= auth= [source: deploy/components/ipp/service.yaml:1]
- vllm-deepseek-r1 port=8000 target=8000 protocol=TCP encryption= auth= [source: deploy/components/model-server/deepseek/deployment.yaml:35]
- vllm-llama3-8b-instruct port=8000 target=8000 protocol=TCP encryption= auth= [source: deploy/components/model-server/llama/deployment.yaml:35]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload envoy uses service account  and 1 container(s) [source: deploy/environments/dev/e2e-infra/envoy.yaml:127]
- **observed**: Deployment workload payload-processor uses service account payload-processor and 1 container(s) [source: deploy/components/ipp/deployment.yaml:1]
- **observed**: Deployment workload vllm-deepseek-r1 uses service account  and 1 container(s) [source: deploy/components/model-server/deepseek/deployment.yaml:1]
- **observed**: Deployment workload vllm-llama3-8b-instruct uses service account  and 1 container(s) [source: deploy/components/model-server/llama/deployment.yaml:1]
- **observed**: Service envoy targets envoy with 1 port(s) [source: deploy/environments/dev/e2e-infra/envoy.yaml:169]
- **observed**: Service payload-processor targets payload-processor with 2 port(s) [source: deploy/components/ipp/service.yaml:1]
- **observed**: Service vllm-deepseek-r1 targets vllm-deepseek-r1 with 1 port(s) [source: deploy/components/model-server/deepseek/deployment.yaml:35]
- **observed**: Service vllm-llama3-8b-instruct targets vllm-llama3-8b-instruct with 1 port(s) [source: deploy/components/model-server/llama/deployment.yaml:35]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **observed**: RBAC role payload-processor-auth-reviewer grants 1 rule(s) [source: deploy/components/ipp/rbac.yaml:7]
- **observed**: gRPC External Processor gRPC uses None at N/A; policy=Transport TLS is configuration-dependent; no application authentication interceptor is configured [source: pkg/server/runserver.go:76]
- **observed**: gRPC Health gRPC uses None at N/A; policy=Plaintext gRPC service has no application authentication interceptor [source: cmd/runner/runner.go:315]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: internal/tls/tls.go, pkg/common/certs.go, pkg/server/runserver.go]
- **dependency-signal**: tls-config targets google.golang.org/grpc/credentials: TLS configuration import [source: pkg/server/runserver.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
