# Analyzer Synthesis Context: ai-gateway-operator

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 1 crds facts extracted [source: config/crd/bases/components.platform.opendatahub.io_aigateways.yaml:2]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (not-verified)**: 0 http_endpoints facts extracted; absence is not proven by the available coverage
- **services (observed)**: 1 services facts extracted [source: config/default/metrics_service.yaml:1]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References


## Behavioral Evidence

- **named-watch-predicate (unresolved)** internal/controller/aigateway.NewReconciler: /v1/ConfigMap; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/aigateway/aigateway_controller.go:166-176]

## Gap Evidence Index

### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/components_aigateway_admin_role.yaml`:8 (ai-gateway-components-aigateway-admin-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/components_aigateway_admin_role.yaml`:8 (components-aigateway-admin-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/components_aigateway_editor_role.yaml`:8 (ai-gateway-components-aigateway-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/components_aigateway_editor_role.yaml`:8 (components-aigateway-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/components_aigateway_viewer_role.yaml`:8 (ai-gateway-components-aigateway-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/components_aigateway_viewer_role.yaml`:8 (components-aigateway-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/metrics_auth_role.yaml`:1 (ai-gateway-metrics-auth-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/metrics_auth_role.yaml`:1 (metrics-auth-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/metrics_reader_role.yaml`:1 (ai-gateway-metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/metrics_reader_role.yaml`:1 (metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/role.yaml`:2 (ai-gateway-manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/role.yaml`:2 (manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:53 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:45 (Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/main.go`:30 (cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (CRD Watch, DSCInitialization CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (CRD Watch, KServe InferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (Certificate CR, cert-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (Gateway API, HTTPRoute CRUD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `api/components/v1alpha1/aigateway_types.go`:20 (Go library, opendatahub-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, Gateway API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, cert-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRD Watch, DSCInitialization CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRD Watch, KServe InferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `internal/controller/aigateway/aigateway.go`:179 (CRD-managed sub-component, llm-d batch gateway)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/aigateway/aigateway.go`:298 (apps/v1/Deployment, delete, get operations by Module)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/aigateway/aigateway.go`:593 (/v1/ConfigMap, get operations by Module)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/aigateway/aigateway_infra_rbac.go`:107 (create, delete, get, update operations, rbac.authorization.k8s.io/v1/Role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/aigateway/aigateway_infra_rbac.go`:114 (create, delete, get, update operations, rbac.authorization.k8s.io/v1/RoleBinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/aigateway/aigateway_infra_rbac.go`:129 (/v1/Namespace, create, get, update operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/controller/aigateway/aigateway.go`:593 (/v1/ConfigMap, get operations by Module)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/aigateway/aigateway_controller.go`:154 (/v1/ConfigMap)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/aigateway/aigateway_controller.go`:155 (rbac.authorization.k8s.io/v1/ClusterRoleBinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/aigateway/aigateway_controller.go`:156 (rbac.authorization.k8s.io/v1/ClusterRole)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/aigateway/aigateway_controller.go`:157 (rbac.authorization.k8s.io/v1/RoleBinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/aigateway/aigateway_controller.go`:158 (rbac.authorization.k8s.io/v1/Role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/aigateway/aigateway_controller.go`:159 (/v1/ServiceAccount)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/aigateway/aigateway_controller.go`:160 (/v1/Service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/aigateway/aigateway_controller.go`:161 (apiextensions/v1/CustomResourceDefinition)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/aigateway/aigateway_controller.go`:162 (admissionregistration/v1/ValidatingWebhookConfiguration)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/aigateway/aigateway_controller.go`:163 (apps/v1/Deployment)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/aigateway/aigateway_controller.go`:166-176 (/v1/ConfigMap, internal/controller/aigateway.NewReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `config/default/cert_metrics_manager_patch.yaml`:1 (ai-gateway-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `config/default/metrics_service.yaml`:1 (ai-gateway-metrics-service, ai-gateway-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### integrations

- DSCInitialization CR interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read platform initialization state [source: config/rbac/role.yaml:2]
- Gateway API interaction=HTTPRoute CRUD role=runtime-transport protocol=HTTPS purpose=Manage Gateway API routing resources [source: config/rbac/role.yaml:2]
- KServe InferenceService interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read model serving state [source: config/rbac/role.yaml:2]
- cert-manager interaction=Certificate CR role=unknown protocol=HTTPS purpose=Manage TLS certificates through cert-manager CRDs [source: config/rbac/role.yaml:2]
- prometheus-operator interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage Prometheus monitoring resources [source: config/rbac/role.yaml:2]
### internal_dependencies

- DSCInitialization CR interaction=CRD Watch role=runtime-integration purpose=Read platform initialization state [source: config/rbac/role.yaml:2]
- Gateway API interaction=CRD CRUD role=unknown purpose=Manage Gateway API routing resources [source: config/rbac/role.yaml:2]
- KServe InferenceService interaction=CRD Watch role=runtime-integration purpose=Read model serving state [source: config/rbac/role.yaml:2]
- cert-manager interaction=CRD CRUD role=unknown purpose=Manage TLS certificates through cert-manager CRDs [source: config/rbac/role.yaml:2]
- llm-d batch gateway interaction=CRD-managed sub-component role=unknown purpose=spec.batchGateway.managementState selects the Managed state to reconcile manifests with full lifecycle RBAC for batch.llm-d.ai/llmbatchgateways (schema: config/crd/bases/components.platform.opendatahub.io_aigateways.yaml:56; RBAC: config/rbac/role.yaml:2) [source: internal/controller/aigateway/aigateway.go:179]
- opendatahub-operator interaction=Go library role=runtime-library purpose=Use runtime packages from github.com/opendatahub-io/opendatahub-operator/v2 [source: api/components/v1alpha1/aigateway_types.go:20]
- prometheus-operator interaction=CRD CRUD role=unknown purpose=Manage Prometheus monitoring resources [source: config/rbac/role.yaml:2]
### services

- ai-gateway-metrics-service port=8443 target=8443 protocol=TCP encryption= auth= [source: config/default/metrics_service.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload ai-gateway-operator uses service account ai-gateway-operator and 1 container(s) [source: config/default/cert_metrics_manager_patch.yaml:1]
- **observed**: Service ai-gateway-metrics-service targets ai-gateway-operator with 1 port(s) [source: config/default/metrics_service.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **observed**: RBAC role ai-gateway-components-aigateway-admin-role grants 2 rule(s) [source: config/rbac/components_aigateway_admin_role.yaml:8]
- **observed**: RBAC role ai-gateway-components-aigateway-editor-role grants 2 rule(s) [source: config/rbac/components_aigateway_editor_role.yaml:8]
- **observed**: RBAC role ai-gateway-components-aigateway-viewer-role grants 2 rule(s) [source: config/rbac/components_aigateway_viewer_role.yaml:8]
- **observed**: RBAC role ai-gateway-leader-election-role grants 3 rule(s) [source: config/rbac/leader_election_role.yaml:2]
- **observed**: RBAC role ai-gateway-manager-role grants 59 rule(s) [source: config/rbac/role.yaml:2]
- **observed**: RBAC role ai-gateway-metrics-auth-role grants 2 rule(s) [source: config/rbac/metrics_auth_role.yaml:1]
- **observed**: RBAC role ai-gateway-metrics-reader grants 1 rule(s) [source: config/rbac/metrics_reader_role.yaml:1]
- **observed**: RBAC role components-aigateway-admin-role grants 2 rule(s) [source: config/rbac/components_aigateway_admin_role.yaml:8]
- **observed**: RBAC role components-aigateway-editor-role grants 2 rule(s) [source: config/rbac/components_aigateway_editor_role.yaml:8]
- **observed**: RBAC role components-aigateway-viewer-role grants 2 rule(s) [source: config/rbac/components_aigateway_viewer_role.yaml:8]
- **observed**: RBAC role leader-election-role grants 3 rule(s) [source: config/rbac/leader_election_role.yaml:2]
- **observed**: RBAC role manager-role grants 59 rule(s) [source: config/rbac/role.yaml:2]
- **observed**: RBAC role metrics-auth-role grants 2 rule(s) [source: config/rbac/metrics_auth_role.yaml:1]
- **observed**: RBAC role metrics-reader grants 1 rule(s) [source: config/rbac/metrics_reader_role.yaml:1]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: cmd/operator/metrics.go, internal/tls/profile.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
