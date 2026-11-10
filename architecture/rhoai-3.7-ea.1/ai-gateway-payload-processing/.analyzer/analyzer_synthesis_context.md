# Analyzer Synthesis Context: ai-gateway-payload-processing

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 2 crds facts extracted [source: config/crd/bases/inference.opendatahub.io_externalmodels.yaml:2, config/crd/bases/inference.opendatahub.io_externalproviders.yaml:2]
- **grpc_services (observed)**: 2 grpc_services facts extracted [source: cmd/runner.go:236, cmd/runner.go:303]
- **http_endpoints (not-verified)**: 0 http_endpoints facts extracted; absence is not proven by the available coverage
- **services (not-verified)**: 0 services facts extracted; absence is not proven by the available coverage
- **ingress (not-verified)**: 0 ingress facts extracted; absence is not proven by the available coverage
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References

- **controller**: Reconciler —watches-reference→ /v1/Service; /v1/Service [source: pkg/controller/externalprovider/reconciler.go:273, pkg/controller/externalprovider/reconciler.go:406]
- **controller**: Reconciler —watches-reference→ api/inference/v1alpha1/ExternalModel; api/inference/v1alpha1/ExternalModel [source: pkg/controller/externalmodel/reconciler.go:319, pkg/controller/externalmodel/reconciler.go:91]
- **controller**: Reconciler —watches-reference→ api/inference/v1alpha1/ExternalProvider; api/inference/v1alpha1/ExternalProvider [source: pkg/controller/externalmodel/reconciler.go:157, pkg/controller/externalprovider/reconciler.go:405]
- **controller**: Reconciler —watches-reference→ gateway.networking.k8s.io/v1/HTTPRoute; gateway.networking.k8s.io/v1/HTTPRoute [source: pkg/controller/externalmodel/reconciler.go:246, pkg/controller/externalmodel/reconciler.go:320]

## Behavioral Evidence

- **conditional-metrics-enforcement (unresolved)** controller-runtime metrics: controller-runtime metrics serving surface; limitations=The controller-runtime manager Metrics binding does not use one direct lexical options object with a stable SecureServing condition [source: cmd/runner.go:165-165]
- **named-watch-predicate (unresolved)** cmd.providerController: inference.opendatahub.io/v1alpha1/ExternalModel; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: cmd/controllers.go:46-51]
- **named-watch-predicate (unresolved)** pkg/controller/externalprovider.Reconciler: inference.opendatahub.io/v1alpha1/ExternalModel; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: pkg/controller/externalprovider/reconciler.go:409-414]

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `api/inference/v1alpha1/common_types.go`:20 (Ai Gateway Payload Processing (CRD-configured), Configurable: apikey;simple;sigv4;oauth2)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Under which configuration branch does the metrics serving surface install authentication and authorization?
  **Expected signal:** a direct SecureServing condition and controller-runtime authn/authz FilterProvider assignment
  **Candidate:** `cmd/runner.go`:165-165 (controller-runtime metrics, controller-runtime metrics serving surface)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/runner.go`:236 (Health gRPC, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/runner.go`:303 (External Processor gRPC, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:39 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:37 (Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux.e2e`:52 (Dockerfile.konflux.e2e:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/main.go`:33 (cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### grpc_services

- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `cmd/runner.go`:236 (Health, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `cmd/runner.go`:303 (ExternalProcessor, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `cmd/runner.go`:303 (Envoy proxy, gRPC ExtProc callout)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `cmd/runner.go`:52 (Go library, llm-d-inference-payload-processor)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/controller/externalmodel/reconciler.go`:157 (api/inference/v1alpha1/ExternalProvider, create, get, update operations by Reconciler, externalProviderReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/controller/externalmodel/reconciler.go`:246 (create, delete, get, update operations by Reconciler, gateway.networking.k8s.io/v1/HTTPRoute)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/controller/externalmodel/reconciler.go`:246 (Gateway API, HTTPRoute CRUD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/controller/externalmodel/reconciler.go`:320 (Controller watch, Gateway API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/controller/externalmodel/reconciler.go`:91 (api/inference/v1alpha1/ExternalModel, create, get, list, update operations by Reconciler, externalModelReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/controller/externalprovider/reconciler.go`:273 (/v1/Service, create, delete, get, update operations by Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/controller/externalprovider/reconciler.go`:307 (/v1/Secret, get operations by Reconciler, secretReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `cmd/controllers.go`:44 (api/inference/v1alpha1/ExternalProvider)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `cmd/controllers.go`:46-51 (cmd.providerController, inference.opendatahub.io/v1alpha1/ExternalModel)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `cmd/controllers.go`:71 (api/inference/v1alpha1/ExternalModel)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `cmd/controllers.go`:73 (api/inference/v1alpha1/ExternalProvider)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controller/externalmodel/reconciler.go`:319 (Reconciler, api/inference/v1alpha1/ExternalModel)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controller/externalmodel/reconciler.go`:321 (Reconciler, api/inference/v1alpha1/ExternalProvider)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controller/externalprovider/reconciler.go`:405 (Reconciler, api/inference/v1alpha1/ExternalProvider)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controller/externalprovider/reconciler.go`:406 (/v1/Service, Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `pkg/controller/externalprovider/reconciler.go`:409-414 (inference.opendatahub.io/v1alpha1/ExternalModel, pkg/controller/externalprovider.Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/plugins/model-provider-resolver/plugin.go`:118 (api/inference/v1alpha1/ExternalModel)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/plugins/model-provider-resolver/plugin.go`:120 (api/inference/v1alpha1/ExternalProvider)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/plugins/model-provider-resolver/plugin.go`:90 (api/inference/v1alpha1/ExternalProvider)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- Ai Gateway Payload Processing (CRD-configured) methods=ALL mechanism=Configurable: apikey;simple;sigv4;oauth2 enforcement=CRD-specified authentication configuration policy=Authentication type selected by CRD enum with credential secret reference [source: api/inference/v1alpha1/common_types.go:20]
- External Processor gRPC methods=gRPC mechanism=None enforcement=N/A policy=Transport TLS is configuration-dependent; no application authentication interceptor is configured [source: cmd/runner.go:303]
- Health gRPC methods=gRPC mechanism=None enforcement=N/A policy=Plaintext gRPC service has no application authentication interceptor [source: cmd/runner.go:236]
### internal_dependencies

- Envoy proxy interaction=gRPC ExtProc callout role=runtime-transport purpose=Receive per-request processing callouts through the Envoy External Processing API [source: cmd/runner.go:303]
- Gateway API interaction=Controller watch role=runtime-integration purpose=Manage Gateway API routing resources [source: pkg/controller/externalmodel/reconciler.go:320]
- Gateway API interaction=HTTPRoute CRUD role=runtime-transport purpose=Reconcile HTTPRoute resources against a configured Gateway [source: pkg/controller/externalmodel/reconciler.go:246]
- llm-d-inference-payload-processor interaction=Go library role=runtime-library purpose=Use runtime packages from github.com/llm-d/llm-d-inference-payload-processor [source: cmd/runner.go:52]

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

- **observed**: ALL Ai Gateway Payload Processing (CRD-configured) uses Configurable: apikey;simple;sigv4;oauth2 at CRD-specified authentication configuration; policy=Authentication type selected by CRD enum with credential secret reference [source: api/inference/v1alpha1/common_types.go:20]
- **observed**: gRPC External Processor gRPC uses None at N/A; policy=Transport TLS is configuration-dependent; no application authentication interceptor is configured [source: cmd/runner.go:303]
- **observed**: gRPC Health gRPC uses None at N/A; policy=Plaintext gRPC service has no application authentication interceptor [source: cmd/runner.go:236]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: cmd/runner.go, pkg/plugins/nemo/nemo_guard_base.go]
- **dependency-signal**: tls-config targets google.golang.org/grpc/credentials: TLS configuration import [source: cmd/runner.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
