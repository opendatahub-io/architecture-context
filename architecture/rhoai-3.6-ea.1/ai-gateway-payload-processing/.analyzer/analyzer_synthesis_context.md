# Analyzer Synthesis Context: ai-gateway-payload-processing

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 2 crds facts extracted [source: config/crd/bases/inference.opendatahub.io_externalmodels.yaml:2, config/crd/bases/inference.opendatahub.io_externalproviders.yaml:2]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (not-verified)**: 0 http_endpoints facts extracted; absence is not proven by the available coverage
- **services (not-verified)**: 0 services facts extracted; absence is not proven by the available coverage
- **ingress (not-verified)**: 0 ingress facts extracted; absence is not proven by the available coverage
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References

- **controller**: Reconciler —watches-reference→ /v1/Service; /v1/Service [source: pkg/controller/externalprovider/reconciler.go:185, pkg/controller/externalprovider/reconciler.go:244]
- **controller**: Reconciler —watches-reference→ api/inference/v1alpha1/ExternalModel; api/inference/v1alpha1/ExternalModel [source: pkg/controller/externalmodel/reconciler.go:258, pkg/controller/externalmodel/reconciler.go:91]
- **controller**: Reconciler —watches-reference→ api/inference/v1alpha1/ExternalProvider; api/inference/v1alpha1/ExternalProvider [source: pkg/controller/externalmodel/reconciler.go:133, pkg/controller/externalprovider/reconciler.go:243]
- **controller**: Reconciler —watches-reference→ gateway.networking.k8s.io/v1/HTTPRoute; gateway.networking.k8s.io/v1/HTTPRoute [source: pkg/controller/externalmodel/reconciler.go:210, pkg/controller/externalmodel/reconciler.go:259]

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `api/inference/v1alpha1/common_types.go`:20 (Ai Gateway Payload Processing (CRD-configured), Configurable: apikey;sigv4;oauth2)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:43 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:41 (Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux.e2e`:52 (Dockerfile.konflux.e2e:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/main.go`:34 (cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `cmd/main.go`:29 (Go library, llm-d-inference-payload-processor)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/controller/externalmodel/reconciler.go`:91 (api/inference/v1alpha1/ExternalModel, create, get, list, update operations by Reconciler, externalModelReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/controller/externalmodel/reconciler.go`:259 (Controller watch, Gateway API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/controller/externalprovider/reconciler.go`:145 (/v1/Secret, get operations by Reconciler, secretReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `cmd/controllers.go`:62 (api/inference/v1alpha1/ExternalModel)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `pkg/controller/externalmodel/reconciler.go`:91 (api/inference/v1alpha1/ExternalModel, create, get, list, update operations by Reconciler, externalModelReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controller/externalmodel/reconciler.go`:258 (Reconciler, api/inference/v1alpha1/ExternalModel)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `pkg/controller/externalprovider/reconciler.go`:145 (/v1/Secret, get operations by Reconciler, secretReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controller/externalprovider/reconciler.go`:244 (/v1/Service, Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/plugins/model-provider-resolver/plugin.go`:101 (api/inference/v1alpha1/ExternalModel)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- Ai Gateway Payload Processing (CRD-configured) methods=ALL mechanism=Configurable: apikey;sigv4;oauth2 enforcement=CRD-specified authentication configuration policy=Authentication type selected by CRD enum with credential secret reference [source: api/inference/v1alpha1/common_types.go:20]
### internal_dependencies

- Gateway API interaction=Controller watch role=runtime-integration purpose=Manage Gateway API routing resources [source: pkg/controller/externalmodel/reconciler.go:259]
- Gateway API interaction=HTTPRoute CRUD role=runtime-transport purpose=Reconcile HTTPRoute resources against a configured Gateway [source: pkg/controller/externalmodel/reconciler.go:210]
- llm-d-inference-payload-processor interaction=Go library role=runtime-library purpose=Use runtime packages from github.com/llm-d/llm-d-inference-payload-processor [source: cmd/main.go:29]

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

- **observed**: ALL Ai Gateway Payload Processing (CRD-configured) uses Configurable: apikey;sigv4;oauth2 at CRD-specified authentication configuration; policy=Authentication type selected by CRD enum with credential secret reference [source: api/inference/v1alpha1/common_types.go:20]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
