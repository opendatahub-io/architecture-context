# Analyzer Synthesis Context: llm-d-async

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (not-verified)**: 0 grpc_services facts extracted; absence is not proven by the available coverage
- **http_endpoints (observed)**: 2 http_endpoints facts extracted [source: internal/health/health.go:40, internal/health/health.go:41]
- **services (not-verified)**: 0 services facts extracted; absence is not proven by the available coverage
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References

- **security**: Unknown /healthz —protected-by→ Kubernetes kubelet health probe (unauthenticated by design); Pod-local network (kubelet only): Kubernetes liveness/readiness probes accessed by kubelet via pod-local network without authentication [source: internal/health/health.go:40, platform-delegated:Kubernetes kubelet health probe]
- **security**: Unknown /readyz —protected-by→ Kubernetes kubelet health probe (unauthenticated by design); Pod-local network (kubelet only): Kubernetes liveness/readiness probes accessed by kubelet via pod-local network without authentication [source: internal/health/health.go:41, platform-delegated:Kubernetes kubelet health probe]

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `platform-delegated:Kubernetes kubelet health probe` (/healthz, Kubernetes kubelet health probe (unauthenticated by design))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:38 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:37 (Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/main.go`:14 (cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `internal/health/health.go`:40 (/healthz, Unknown, internal/health)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/async/inference/flowcontrol/binary_metric_dispatch_gate.go`:27 (Go library, gateway-api-inference-extension)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `docs/guides/e2e-deploy/modelserver/patch-vllm.yaml`:1 (vllm-qwen3-0-6b-decode, vllm-qwen3-0-6b-sa)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- /healthz methods=HTTP mechanism=Kubernetes kubelet health probe (unauthenticated by design) enforcement=Pod-local network (kubelet only) policy=Kubernetes liveness/readiness probes accessed by kubelet via pod-local network without authentication [source: platform-delegated:Kubernetes kubelet health probe]
- /readyz methods=HTTP mechanism=Kubernetes kubelet health probe (unauthenticated by design) enforcement=Pod-local network (kubelet only) policy=Kubernetes liveness/readiness probes accessed by kubelet via pod-local network without authentication [source: platform-delegated:Kubernetes kubelet health probe]
### http_endpoints

- Unknown /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=internal/health [source: internal/health/health.go:40]
- Unknown /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=internal/health [source: internal/health/health.go:41]
### internal_dependencies

- gateway-api-inference-extension interaction=Go library role=runtime-library purpose=Use runtime packages from sigs.k8s.io/gateway-api-inference-extension [source: pkg/async/inference/flowcontrol/binary_metric_dispatch_gate.go:27]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload vllm-qwen3-0-6b-decode uses service account vllm-qwen3-0-6b-sa and 1 container(s) [source: docs/guides/e2e-deploy/modelserver/patch-vllm.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP Unknown /healthz is owned by internal/health [source: internal/health/health.go:40]
- **observed**: HTTP Unknown /readyz is owned by internal/health [source: internal/health/health.go:41]
### security

- **observed**: HTTP /healthz uses Kubernetes kubelet health probe (unauthenticated by design) at Pod-local network (kubelet only); policy=Kubernetes liveness/readiness probes accessed by kubelet via pod-local network without authentication [source: platform-delegated:Kubernetes kubelet health probe]
- **observed**: HTTP /readyz uses Kubernetes kubelet health probe (unauthenticated by design) at Pod-local network (kubelet only); policy=Kubernetes liveness/readiness probes accessed by kubelet via pod-local network without authentication [source: platform-delegated:Kubernetes kubelet health probe]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: pkg/server/runner.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
