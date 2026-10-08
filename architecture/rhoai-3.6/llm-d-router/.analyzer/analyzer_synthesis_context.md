# Analyzer Synthesis Context: llm-d-router

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 5 crds facts extracted [source: apix/config/v1/endpointpickerconfig_types.go:34, apix/config/v1alpha1/endpointpickerconfig_types.go:34, apix/v1/inferenceobjective_types.go:35, config/crd/bases/llm-d.ai_inferencemodelrewrites.yaml:1, config/crd/bases/llm-d.ai_inferenceobjectives.yaml:1]
- **grpc_services (observed)**: 2 grpc_services facts extracted [source: pkg/epp/server/runserver.go:278, pkg/epp/server/runserver.go:282]
- **http_endpoints (observed)**: 6 http_endpoints facts extracted [source: cmd/coordinator/main.go:254, cmd/epp/runner/runner.go:1352, pkg/coordinator/steps/asyncbroker/routes.go:50, pkg/coordinator/steps/asyncbroker/routes.go:51, pkg/sidecar/proxy/dns_metrics.go:144, pkg/sidecar/proxy/proxy.go:571]
- **services (not-verified)**: 0 services facts extracted; absence is not proven by the available coverage
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References

- **controller**: PodReconciler —watches-reference→ /v1/Pod; /v1/Pod [source: pkg/epp/controller/pod_reconciler.go:55, pkg/epp/controller/pod_reconciler.go:91]

## Behavioral Evidence

- **named-watch-predicate (unresolved)** pkg/epp/controller.InferenceObjectiveReconciler: inference.networking.k8s.io/v1/InferencePool; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: pkg/epp/controller/inferenceobjective_reconciler.go:182-191]
- **named-watch-predicate (unresolved)** pkg/epp/controller.InferenceObjectiveReconciler: apix/v1alpha2/InferenceObjective; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: pkg/epp/controller/inferenceobjective_reconciler.go:193-215]

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `pkg/epp/server/runserver.go`:278 (External Processor gRPC, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `pkg/epp/server/runserver.go`:282 (Health gRPC, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `pkg/sidecar/proxy/allowlist.go`:86 (Kubernetes API, kubeconfig credential chain)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.builder`:95 (Dockerfile.builder:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.coordinator`:47 (Dockerfile.coordinator:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.epp`:59 (Dockerfile.epp:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux.coordinator`:40 (Dockerfile.konflux.coordinator:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux.epp`:53 (Dockerfile.konflux.epp:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux.sidecar`:40 (Dockerfile.konflux.sidecar:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.sidecar`:50 (Dockerfile.sidecar:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/coordinator/main.go`:64 (coordinator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/epp/main.go`:35 (epp)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/pd-sidecar/main.go`:30 (pd-sidecar)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `pkg/epp/framework/plugins/requestcontrol/dataproducer/predictedlatency/latencypredictorclient/tests/Dockerfile`:23 (pkg/epp/framework/plugins/requestcontrol/dataproducer/predictedlatency/latencypredictorclient/tests/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `pkg/generator/main.go`:36 (generator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pkg/common/observability/tracing/telemetry.go`:314 (OTLP/gRPC trace exporter, OpenTelemetry Collector)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pkg/epp/server/controller_config.go`:73 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pkg/sidecar/proxy/allowlist.go`:113 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### grpc_services

- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `pkg/epp/server/runserver.go`:278 (ExternalProcessor, pkg/epp/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `pkg/epp/server/runserver.go`:282 (Health, pkg/epp/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/coordinator/main.go`:254 (/metrics, Unknown, cmd/coordinator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where are runtime routes registered on this server?
  **Expected signal:** router construction or route registration
  **Candidate:** `cmd/coordinator/main.go`:295 (HTTP, metrics)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/epp/runner/runner.go`:1352 (/metrics, Unknown, cmd/epp/runner)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `pkg/coordinator/steps/asyncbroker/routes.go`:50 (/v1/requests/{id}, GET, pkg/coordinator/steps/asyncbroker)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `pkg/coordinator/steps/asyncbroker/routes.go`:51 (/v1/requests/{id}, DELETE, pkg/coordinator/steps/asyncbroker)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `pkg/sidecar/proxy/dns_metrics.go`:144 (/metrics, Unknown, pkg/sidecar/proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `pkg/sidecar/proxy/proxy.go`:571 (/, Unknown, pkg/sidecar/proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `pkg/common/observability/tracing/telemetry.go`:314 (OpenTelemetry Collector, gRPC client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `apix/v1/conversion.go`:23 (Go library, gateway-api-inference-extension)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/coordinator/steps/asyncbroker/broker.go`:29 (Go library, llm-d-async)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/epp/controller/inferencepool_reconciler.go`:80 (Controller watch (conditional), gateway-api-inference-extension)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/epp/controller/pod_reconciler.go`:55 (/v1/Pod, get, list operations by PodReconciler, datastore)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/epp/server/runserver.go`:278 (Envoy proxy, gRPC ExtProc callout)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/epp/controller/inferencemodelrewrite_reconciler.go`:82 (InferenceModelRewriteReconciler, apix/v1alpha2/InferenceModelRewrite)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/epp/controller/inferenceobjective_reconciler.go`:171 (InferenceObjectiveReconciler, apix/v1/InferenceObjective)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `pkg/epp/controller/inferenceobjective_reconciler.go`:182-191 (inference.networking.k8s.io/v1/InferencePool, pkg/epp/controller.InferenceObjectiveReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `pkg/epp/controller/inferenceobjective_reconciler.go`:193-215 (apix/v1alpha2/InferenceObjective, pkg/epp/controller.InferenceObjectiveReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/epp/controller/inferenceobjective_reconciler.go`:218 (InferenceObjectiveReconciler, apix/v1alpha2/InferenceObjective)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/epp/controller/inferencepool_reconciler.go`:80 (InferencePoolReconciler, inference.networking.k8s.io/v1/InferencePool)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `pkg/epp/controller/pod_reconciler.go`:55 (/v1/Pod, get, list operations by PodReconciler, datastore)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/epp/controller/pod_reconciler.go`:91 (/v1/Pod, PodReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- External Processor gRPC methods=gRPC mechanism=None enforcement=N/A policy=Transport TLS is configuration-dependent; no application authentication interceptor is configured [source: pkg/epp/server/runserver.go:278]
- Health gRPC methods=gRPC mechanism=None enforcement=N/A policy=Transport TLS is configuration-dependent; no application authentication interceptor is configured [source: pkg/epp/server/runserver.go:282]
- Kubernetes API methods=REST mechanism=kubeconfig credential chain enforcement=kube-apiserver policy=Kubeconfig-based authentication using user-provided credentials [source: pkg/sidecar/proxy/allowlist.go:86]
### http_endpoints

- DELETE /v1/requests/{id} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/coordinator/steps/asyncbroker [source: pkg/coordinator/steps/asyncbroker/routes.go:51]
- GET /v1/requests/{id} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/coordinator/steps/asyncbroker [source: pkg/coordinator/steps/asyncbroker/routes.go:50]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/sidecar/proxy [source: pkg/sidecar/proxy/proxy.go:571]
- Unknown /metrics on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/coordinator [source: cmd/coordinator/main.go:254]
- Unknown /metrics on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/epp/runner [source: cmd/epp/runner/runner.go:1352]
- Unknown /metrics on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/sidecar/proxy [source: pkg/sidecar/proxy/dns_metrics.go:144]
### integrations

- OpenTelemetry Collector interaction=gRPC client role=runtime-integration protocol=OTLP/gRPC purpose=Runtime trace export [source: pkg/common/observability/tracing/telemetry.go:314]
### internal_dependencies

- Envoy proxy interaction=gRPC ExtProc callout role=runtime-transport purpose=Receive per-request processing callouts through the Envoy External Processing API [source: pkg/epp/server/runserver.go:278]
- gateway-api-inference-extension interaction=Controller watch (conditional) role=runtime-integration purpose=Watch InferencePool resources for pool-based autoscaling configuration [source: pkg/epp/controller/inferencepool_reconciler.go:80]
- gateway-api-inference-extension interaction=Go library role=runtime-library purpose=Use runtime packages from sigs.k8s.io/gateway-api-inference-extension [source: apix/v1/conversion.go:23]
- llm-d-async interaction=Go library role=runtime-library purpose=Use runtime packages from github.com/llm-d/llm-d-async/api [source: pkg/coordinator/steps/asyncbroker/broker.go:29]

## Cross-Cutting Evidence

### deployment_topology

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:deployment_topology]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP DELETE /v1/requests/{id} is owned by pkg/coordinator/steps/asyncbroker [source: pkg/coordinator/steps/asyncbroker/routes.go:51]
- **observed**: HTTP GET /v1/requests/{id} is owned by pkg/coordinator/steps/asyncbroker [source: pkg/coordinator/steps/asyncbroker/routes.go:50]
- **observed**: HTTP Unknown / is owned by pkg/sidecar/proxy [source: pkg/sidecar/proxy/proxy.go:571]
- **observed**: HTTP Unknown /metrics is owned by cmd/coordinator [source: cmd/coordinator/main.go:254]
- **observed**: HTTP Unknown /metrics is owned by cmd/epp/runner [source: cmd/epp/runner/runner.go:1352]
- **observed**: HTTP Unknown /metrics is owned by pkg/sidecar/proxy [source: pkg/sidecar/proxy/dns_metrics.go:144]
### security

- **observed**: REST Kubernetes API uses kubeconfig credential chain at kube-apiserver; policy=Kubeconfig-based authentication using user-provided credentials [source: pkg/sidecar/proxy/allowlist.go:86]
- **observed**: gRPC External Processor gRPC uses None at N/A; policy=Transport TLS is configuration-dependent; no application authentication interceptor is configured [source: pkg/epp/server/runserver.go:278]
- **observed**: gRPC Health gRPC uses None at N/A; policy=Transport TLS is configuration-dependent; no application authentication interceptor is configured [source: pkg/epp/server/runserver.go:282]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: cmd/coordinator/main.go, internal/tls/tls.go, pkg/common/certs.go, pkg/coordinator/server/tls.go, pkg/epp/framework/plugins/datalayer/source/http/datasource.go, pkg/epp/framework/plugins/requestcontrol/dataproducer/tokenizer/vllm_http.go, pkg/epp/server/options.go, pkg/epp/server/runserver.go, pkg/sidecar/proxy/dns_metrics.go, pkg/sidecar/proxy/options.go, pkg/sidecar/proxy/proxy.go, pkg/sidecar/proxy/proxy_helpers.go]
- **dependency-signal**: tls-config targets google.golang.org/grpc/credentials: TLS configuration import [source: pkg/epp/server/runserver.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
