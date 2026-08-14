# Analyzer Synthesis Context: eval-hub

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 4 http_endpoints facts extracted [source: internal/eval_hub/server/metrics_server.go:28, internal/eval_hub/server/server.go:475, internal/evalhub_mcp/server/server.go:223, internal/evalhub_mcp/server/server.go:228]
- **services (not-verified)**: 0 services facts extracted; absence is not proven by the available coverage
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References


## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `internal/eval_hub/runtimes/k8s/k8s_helper.go`:41 (Kubernetes API, kubeconfig credential chain)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `internal/eval_hub/server/server.go`:444 (/api/v1/evaluations/collections (Go HTTP), Conditional (configuration-dependent))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:100 (Dockerfile.konflux:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/eval_hub/main.go`:59 (eval_hub)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/eval_runtime_init/main.go`:52 (eval_runtime_init)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/eval_runtime_sidecar/main.go`:42 (eval_runtime_sidecar)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/evalhub_mcp/main.go`:22 (evalhub_mcp)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/validate_configs/main.go`:14 (validate_configs)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/eval_runtime_init/main.go`:114 (AWS SDK S3 client, S3-compatible storage)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `internal/eval_hub/runtimes/k8s/k8s_helper.go`:68 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `internal/otel/otel_sdk.go`:174 (OTLP/gRPC trace exporter, OpenTelemetry Collector)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `internal/eval_hub/server/metrics_server.go`:28 (/metrics, Unknown, internal/eval_hub/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where are runtime routes registered on this server?
  **Expected signal:** router construction or route registration
  **Candidate:** `internal/eval_hub/server/metrics_server.go`:23 (HTTP, metrics)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `internal/eval_hub/server/server.go`:475 (/metrics, Unknown, internal/eval_hub/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `internal/evalhub_mcp/server/server.go`:228 (/, Unknown, internal/evalhub_mcp/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `cmd/eval_runtime_init/main.go`:114 (File storage client, S3-compatible storage)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `internal/otel/otel_sdk.go`:174 (OpenTelemetry Collector, gRPC client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/eval_hub/runtimes/k8s/k8s_helper.go`:153 (/v1/ConfigMap, create operations by KubernetesHelper)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `internal/eval_hub/runtimes/k8s/k8s_helper.go`:112 (CRD CRUD, HardwareProfile CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/eval_hub/runtimes/k8s/k8s_helper.go`:153 (/v1/ConfigMap, create operations by KubernetesHelper)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- /api/v1/evaluations/collections (Go HTTP) methods=ALL mechanism=Conditional (configuration-dependent) enforcement=Identity header check gated by runtime configuration policy=Requires X-User and X-Tenant headers when configuration enables identity enforcement; bypassed in local/development mode [source: internal/eval_hub/server/server.go:444]
- /api/v1/evaluations/jobs (Go HTTP) methods=ALL mechanism=Conditional (configuration-dependent) enforcement=Identity header check gated by runtime configuration policy=Requires X-User and X-Tenant headers when configuration enables identity enforcement; bypassed in local/development mode [source: internal/eval_hub/server/server.go:444]
- /api/v1/evaluations/providers (Go HTTP) methods=ALL mechanism=Conditional (configuration-dependent) enforcement=Identity header check gated by runtime configuration policy=Requires X-User and X-Tenant headers when configuration enables identity enforcement; bypassed in local/development mode [source: internal/eval_hub/server/server.go:444]
- /api/v1/health (Go HTTP) methods=GET mechanism=None enforcement=N/A policy=Route handler does not invoke the conditional identity gate [source: internal/eval_hub/server/server.go:444]
- /docs (Go HTTP) methods=GET mechanism=None enforcement=N/A policy=Route handler does not invoke the conditional identity gate [source: internal/eval_hub/server/server.go:444]
- /openapi.yaml (Go HTTP) methods=GET mechanism=None enforcement=N/A policy=Route handler does not invoke the conditional identity gate [source: internal/eval_hub/server/server.go:444]
- Kubernetes API methods=REST mechanism=kubeconfig credential chain enforcement=kube-apiserver policy=Kubeconfig-based authentication using user-provided credentials [source: internal/eval_hub/runtimes/k8s/k8s_helper.go:41]
### http_endpoints

- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=internal/evalhub_mcp/server [source: internal/evalhub_mcp/server/server.go:228]
- Unknown /health on port ; transport=HTTP/1.1 encryption= auth= owner=internal/evalhub_mcp/server [source: internal/evalhub_mcp/server/server.go:223]
- Unknown /metrics on port ; transport=HTTP/1.1 encryption= auth= owner=internal/eval_hub/server [source: internal/eval_hub/server/metrics_server.go:28]
- Unknown /metrics on port ; transport=HTTP/1.1 encryption= auth= owner=internal/eval_hub/server [source: internal/eval_hub/server/server.go:475]
### integrations

- OpenTelemetry Collector interaction=gRPC client role=runtime-integration protocol=OTLP/gRPC purpose=Runtime trace export [source: internal/otel/otel_sdk.go:174]
- S3-compatible storage interaction=File storage client role=runtime-integration protocol=HTTP/HTTPS purpose=Runtime object storage [source: cmd/eval_runtime_init/main.go:114]
### internal_dependencies

- HardwareProfile CR interaction=CRD CRUD role=unknown purpose=Manage hardware profile resources [source: internal/eval_hub/runtimes/k8s/k8s_helper.go:112]

## Cross-Cutting Evidence

### deployment_topology

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:deployment_topology]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP Unknown / is owned by internal/evalhub_mcp/server [source: internal/evalhub_mcp/server/server.go:228]
- **observed**: HTTP Unknown /health is owned by internal/evalhub_mcp/server [source: internal/evalhub_mcp/server/server.go:223]
- **observed**: HTTP Unknown /metrics is owned by internal/eval_hub/server [source: internal/eval_hub/server/metrics_server.go:28]
### security

- **observed**: ALL /api/v1/evaluations/collections (Go HTTP) uses Conditional (configuration-dependent) at Identity header check gated by runtime configuration; policy=Requires X-User and X-Tenant headers when configuration enables identity enforcement; bypassed in local/development mode [source: internal/eval_hub/server/server.go:444]
- **observed**: ALL /api/v1/evaluations/jobs (Go HTTP) uses Conditional (configuration-dependent) at Identity header check gated by runtime configuration; policy=Requires X-User and X-Tenant headers when configuration enables identity enforcement; bypassed in local/development mode [source: internal/eval_hub/server/server.go:444]
- **observed**: ALL /api/v1/evaluations/providers (Go HTTP) uses Conditional (configuration-dependent) at Identity header check gated by runtime configuration; policy=Requires X-User and X-Tenant headers when configuration enables identity enforcement; bypassed in local/development mode [source: internal/eval_hub/server/server.go:444]
- **observed**: GET /api/v1/health (Go HTTP) uses None at N/A; policy=Route handler does not invoke the conditional identity gate [source: internal/eval_hub/server/server.go:444]
- **observed**: GET /docs (Go HTTP) uses None at N/A; policy=Route handler does not invoke the conditional identity gate [source: internal/eval_hub/server/server.go:444]
- **observed**: GET /openapi.yaml (Go HTTP) uses None at N/A; policy=Route handler does not invoke the conditional identity gate [source: internal/eval_hub/server/server.go:444]
- **observed**: REST Kubernetes API uses kubeconfig credential chain at kube-apiserver; policy=Kubeconfig-based authentication using user-provided credentials [source: internal/eval_hub/runtimes/k8s/k8s_helper.go:41]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: internal/eval_hub/config/mlflow_config.go, internal/eval_hub/config/otel.go, internal/eval_hub/config/sidecar_config.go, internal/eval_hub/evalcards/oci_factory.go, internal/eval_hub/mlflow/mlflow.go, internal/eval_hub/server/server.go, internal/eval_runtime_sidecar/proxy/http_client.go, internal/eval_runtime_sidecar/server/server.go, pkg/evalhubclient/client.go]
- **dependency-signal**: tls-config targets google.golang.org/grpc/credentials: TLS configuration import [source: internal/otel/otel_sdk.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
