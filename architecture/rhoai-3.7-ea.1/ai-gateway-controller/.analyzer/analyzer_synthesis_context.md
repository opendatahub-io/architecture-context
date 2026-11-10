# Analyzer Synthesis Context: ai-gateway-controller

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 3 crds facts extracted [source: config/crd/bases/inference.opendatahub.io_externalmodels.yaml:2, config/crd/bases/inference.opendatahub.io_externalproviders.yaml:2, config/self/crd/bases/aigateway.opendatahub.io_aiguardrails.yaml:2]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 2 http_endpoints facts extracted [source: cmd/manager/main.go:179, cmd/manager/main.go:183]
- **services (observed)**: 1 services facts extracted [source: config/self/manager/metrics_service.yaml:3]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References

- **controller**: Reconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: pkg/consumerportal/reconciler.go:873, pkg/tenant/reconciler.go:267]
- **controller**: Reconciler —watches-reference→ /v1/Namespace; /v1/Namespace [source: pkg/guardrail/reconciler.go:185, pkg/guardrail/reconciler.go:400]
- **controller**: Reconciler —watches-reference→ /v1/Service; /v1/Service [source: pkg/consumerportal/reconciler.go:375, pkg/controller/reconciler.go:145]
- **controller**: Reconciler —watches-reference→ api/aigateway/v1alpha1/AIGuardrail; api/aigateway/v1alpha1/AIGuardrail [source: pkg/guardrail/policy_reader.go:48, pkg/guardrail/reconciler.go:180]
- **controller**: Reconciler —watches-reference→ api/inference/v1alpha1/ExternalModel; api/inference/v1alpha1/ExternalModel [source: pkg/controller/attachment.go:336, pkg/controller/reconciler.go:140]
- **controller**: Reconciler —watches-reference→ api/inference/v1alpha1/ExternalProvider; api/inference/v1alpha1/ExternalProvider [source: pkg/controller/attachment.go:780, pkg/controller/reconciler.go:167]

## Behavioral Evidence

- **conditional-metrics-enforcement (unresolved)** controller-runtime metrics: controller-runtime metrics serving surface; limitations=The controller-runtime manager Metrics binding does not use one direct lexical options object with a stable SecureServing condition [source: cmd/manager/main.go:169-169]
- **named-watch-predicate (unresolved)** pkg/controller.Reconciler: inference.opendatahub.io/v1alpha1/ExternalProvider; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: pkg/controller/reconciler.go:141-141]
- **named-watch-predicate (unresolved)** pkg/controller.Reconciler: /v1/Service; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: pkg/controller/reconciler.go:145-145]
- **named-watch-predicate (unresolved)** pkg/controller.Reconciler: inference.opendatahub.io/v1alpha1/ExternalModel; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: pkg/controller/reconciler.go:158-158]
- **named-watch-predicate (unresolved)** pkg/guardrail.Reconciler: /v1/Namespace; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: pkg/guardrail/reconciler.go:185-186]
- **named-watch-predicate (unresolved)** pkg/tenant.Reconciler: inference.opendatahub.io/v1alpha1/ExternalModel; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: pkg/tenant/reconciler.go:261-262]
- **named-watch-predicate (unresolved)** pkg/tenant.Reconciler: inference.opendatahub.io/v1alpha1/ExternalProvider; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: pkg/tenant/reconciler.go:263-264]
- **named-watch-predicate (unresolved)** pkg/tenant.Reconciler: aigateway.opendatahub.io/v1alpha1/AIGuardrail; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: pkg/tenant/reconciler.go:268-270]

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `api/inference/v1alpha1/common_types.go`:20 (Ai Gateway Controller (CRD-configured), Configurable: apikey;simple;sigv4;oauth2)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/manager/main.go`:166 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Under which configuration branch does the metrics serving surface install authentication and authorization?
  **Expected signal:** a direct SecureServing condition and controller-runtime authn/authz FilterProvider assignment
  **Candidate:** `cmd/manager/main.go`:169-169 (controller-runtime metrics, controller-runtime metrics serving surface)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/manager/main.go`:179 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/manager/main.go`:183 (:8081/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/self/rbac/clusterrole.yaml`:8 (ai-gateway-controller-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/self/rbac/clusterrole_binding.yaml`:1 (ai-gateway-controller-role, ai-gateway-controller-rolebinding)
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
  **Candidate:** `cmd/manager/main.go`:59 (manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `test/kind-env/provider-recorder/Dockerfile`:4 (test/kind-env/provider-recorder/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/manager/main.go`:166 (Kubernetes API, controller-runtime manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pkg/controller/reconciler.go`:121 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/manager/main.go`:179 (/healthz, GET, cmd/manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/manager/main.go`:183 (/readyz, GET, cmd/manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/self/rbac/clusterrole.yaml`:8 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/self/rbac/clusterrole.yaml`:8 (CRD Watch, DSCInitialization CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/self/rbac/clusterrole.yaml`:8 (CRD Watch, OpenShift Routes)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/self/rbac/clusterrole.yaml`:8 (CRD Watch, TrustyAI CRs)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/self/rbac/clusterrole.yaml`:8 (Gateway API, HTTPRoute CRUD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/self/rbac/clusterrole.yaml`:8 (CRD CRUD, Gateway API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/self/rbac/clusterrole.yaml`:8 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/self/rbac/clusterrole.yaml`:8 (CRD Watch, DSCInitialization CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/self/rbac/clusterrole.yaml`:8 (CRD Watch, TrustyAI (trustyai.opendatahub.io))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/consumerportal/credentials.go`:120 (/v1/Secret, delete, get operations by Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/consumerportal/reconciler.go`:375 (/v1/Service, get operations by Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/consumerportal/reconciler.go`:873 (/v1/ConfigMap, delete, get, patch operations by Publisher, Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/controller/attachment.go`:336 (api/inference/v1alpha1/ExternalModel, get, list, patch operations by Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/controller/attachment.go`:780 (api/inference/v1alpha1/ExternalProvider, get, list, patch operations by Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/controller/withdrawal.go`:802 (/v1/Pod, list operations by Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/guardrail/policy_reader.go`:48 (api/aigateway/v1alpha1/AIGuardrail, get, list, patch operations by ClientPolicyReader, Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/guardrail/reconciler.go`:400 (/v1/Namespace, get operations by Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `pkg/consumerportal/reconciler.go`:873 (/v1/ConfigMap, delete, get, patch operations by Publisher, Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controller/reconciler.go`:140 (Reconciler, api/inference/v1alpha1/ExternalModel)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `pkg/controller/reconciler.go`:141-141 (inference.opendatahub.io/v1alpha1/ExternalProvider, pkg/controller.Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `pkg/controller/reconciler.go`:145-145 (/v1/Service, pkg/controller.Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `pkg/controller/reconciler.go`:158-158 (inference.opendatahub.io/v1alpha1/ExternalModel, pkg/controller.Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controller/reconciler.go`:167 (Reconciler, api/inference/v1alpha1/ExternalProvider)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/guardrail/reconciler.go`:180 (Reconciler, api/aigateway/v1alpha1/AIGuardrail)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `pkg/guardrail/reconciler.go`:185-186 (/v1/Namespace, pkg/guardrail.Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `pkg/tenant/reconciler.go`:261-262 (inference.opendatahub.io/v1alpha1/ExternalModel, pkg/tenant.Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `pkg/tenant/reconciler.go`:263-264 (inference.opendatahub.io/v1alpha1/ExternalProvider, pkg/tenant.Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/tenant/reconciler.go`:267 (/v1/ConfigMap, Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `pkg/tenant/reconciler.go`:268-270 (aigateway.opendatahub.io/v1alpha1/AIGuardrail, pkg/tenant.Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `config/self/manager/manager.yaml`:3 (ai-gateway-controller)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `config/self/manager/metrics_service.yaml`:3 (ai-gateway-controller, ai-gateway-controller-metrics)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: cmd/manager/main.go:179]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/manager/main.go:183]
- Ai Gateway Controller (CRD-configured) methods=ALL mechanism=Configurable: apikey;simple;sigv4;oauth2 enforcement=CRD-specified authentication configuration policy=Authentication type selected by CRD enum with credential secret reference [source: api/inference/v1alpha1/common_types.go:20]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via ai-gateway-controller-role ClusterRole; SA ai-gateway-controller [source: cmd/manager/main.go:166]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/manager [source: cmd/manager/main.go:179]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/manager [source: cmd/manager/main.go:183]
### integrations

- DSCInitialization CR interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read platform initialization state [source: config/self/rbac/clusterrole.yaml:8]
- Gateway API interaction=HTTPRoute CRUD role=runtime-transport protocol=HTTPS purpose=Manage Gateway API routing resources [source: config/self/rbac/clusterrole.yaml:8]
- OpenShift Routes interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Dashboard route status [source: config/self/rbac/clusterrole.yaml:8]
- TrustyAI CRs interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read TrustyAI service resources [source: config/self/rbac/clusterrole.yaml:8]
- prometheus-operator interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage Prometheus monitoring resources [source: config/self/rbac/clusterrole.yaml:8]
### internal_dependencies

- DSCInitialization CR interaction=CRD Watch role=runtime-integration purpose=Read platform initialization state [source: config/self/rbac/clusterrole.yaml:8]
- Gateway API interaction=CRD CRUD role=unknown purpose=Manage Gateway API routing resources [source: config/self/rbac/clusterrole.yaml:8]
- TrustyAI (trustyai.opendatahub.io) interaction=CRD Watch role=runtime-integration purpose=Read TrustyAI service resources [source: config/self/rbac/clusterrole.yaml:8]
- prometheus-operator interaction=CRD CRUD role=unknown purpose=Manage Prometheus monitoring resources [source: config/self/rbac/clusterrole.yaml:8]
### services

- ai-gateway-controller-metrics port=8443 target=metrics protocol=TCP encryption= auth= [source: config/self/manager/metrics_service.yaml:3]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload ai-gateway-controller uses service account ai-gateway-controller and 1 container(s) [source: config/self/manager/manager.yaml:3]
- **observed**: Service ai-gateway-controller-metrics targets ai-gateway-controller with 1 port(s) [source: config/self/manager/metrics_service.yaml:3]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by cmd/manager [source: cmd/manager/main.go:179]
- **observed**: HTTP GET /readyz is owned by cmd/manager [source: cmd/manager/main.go:183]
### security

- **observed**: ALL Ai Gateway Controller (CRD-configured) uses Configurable: apikey;simple;sigv4;oauth2 at CRD-specified authentication configuration; policy=Authentication type selected by CRD enum with credential secret reference [source: api/inference/v1alpha1/common_types.go:20]
- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: cmd/manager/main.go:179]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/manager/main.go:183]
- **observed**: RBAC role ai-gateway-controller-role grants 40 rule(s) [source: config/self/rbac/clusterrole.yaml:8]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via ai-gateway-controller-role ClusterRole; SA ai-gateway-controller [source: cmd/manager/main.go:166]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
