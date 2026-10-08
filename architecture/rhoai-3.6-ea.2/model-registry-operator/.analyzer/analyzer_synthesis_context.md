# Analyzer Synthesis Context: model-registry-operator

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 4 crds facts extracted [source: api/aihub/v1alpha1/aihub_types.go:79, api/catalog/v1alpha1/catalog_types.go:121, api/v1alpha1/modelregistry_types.go:440, config/crd/bases/modelregistry.opendatahub.io_modelregistries.yaml:2]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 6 http_endpoints facts extracted [source: cmd/aihub.go:186, cmd/aihub.go:189, cmd/catalog.go:181, cmd/catalog.go:185, cmd/modelregistry.go:265, cmd/modelregistry.go:269]
- **services (observed)**: 5 services facts extracted [source: config/rbac/auth_proxy_service.yaml:1, internal/controller/config/templates/catalog/catalog-postgres-service.yaml.tmpl:1, internal/controller/config/templates/catalog/catalog-service.yaml.tmpl:1, internal/controller/config/templates/postgres-service.yaml.tmpl:1, internal/controller/config/templates/service.yaml.tmpl:1]
- **ingress (observed)**: 5 ingress facts extracted [source: internal/controller/config/templates/catalog/catalog-gateway-httproute.yaml.tmpl:1, internal/controller/config/templates/catalog/catalog-kube-rbac-proxy-https-route.yaml.tmpl:1, internal/controller/config/templates/gateway/gateway-httproute.yaml.tmpl:1, internal/controller/config/templates/http-route.yaml.tmpl:1, internal/controller/config/templates/kube-rbac-proxy/kube-rbac-proxy-https-route.yaml.tmpl:1]
- **webhooks (observed)**: 5 webhooks facts extracted [source: config/crd/patches/webhook_in_modelregistries.yaml:3, config/webhook/manifests.yaml:2, config/webhook/manifests.yaml:31, internal/webhook/modelregistry_webhook.go:110, internal/webhook/modelregistry_webhook.go:57]

## Deterministic Cross-References

- **controller**: AIHubReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: internal/controller/aihub_controller.go:735, internal/controller/aihub_controller.go:771]
- **controller**: AIHubReconciler —watches-reference→ api/aihub/v1alpha1/AIHub; api/aihub/v1alpha1/AIHub [source: internal/controller/aihub_controller.go:170, internal/controller/aihub_controller.go:767]
- **controller**: AIHubReconciler —watches-reference→ api/catalog/v1alpha1/Catalog; api/catalog/v1alpha1/Catalog [source: internal/controller/aihub_controller.go:527, internal/controller/aihub_controller.go:778]
- **controller**: AIHubReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: internal/controller/aihub_controller.go:458, internal/controller/aihub_controller.go:768]
- **controller**: AIHubReconciler —watches-reference→ rbac.authorization.k8s.io/v1/ClusterRoleBinding; rbac.authorization.k8s.io/v1/ClusterRoleBinding [source: internal/controller/aihub_controller.go:775, internal/controller/modelregistry_oauth.go:35]
- **controller**: AIHubReconciler —watches-reference→ rbac.authorization.k8s.io/v1/RoleBinding; rbac.authorization.k8s.io/v1/RoleBinding [source: internal/controller/aihub_controller.go:773, internal/controller/catalog_controller.go:1129]
- **controller**: CatalogReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: internal/controller/aihub_controller.go:735, internal/controller/catalog_controller.go:1476]
- **controller**: CatalogReconciler —watches-reference→ /v1/Secret; /v1/Secret [source: internal/controller/catalog_controller.go:1477, internal/controller/catalog_controller.go:948]
- **controller**: CatalogReconciler —watches-reference→ api/catalog/v1alpha1/Catalog; api/catalog/v1alpha1/Catalog [source: internal/controller/aihub_controller.go:527, internal/controller/catalog_controller.go:1472]
- **controller**: CatalogReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: internal/controller/aihub_controller.go:458, internal/controller/catalog_controller.go:1473]
- **controller**: CatalogReconciler —watches-reference→ networking.k8s.io/v1/NetworkPolicy; networking.k8s.io/v1/NetworkPolicy [source: internal/controller/catalog_controller.go:1478, internal/controller/modelregistry_oauth.go:45]
- **controller**: CatalogReconciler —watches-reference→ rbac.authorization.k8s.io/v1/ClusterRoleBinding; rbac.authorization.k8s.io/v1/ClusterRoleBinding [source: internal/controller/catalog_controller.go:1512, internal/controller/modelregistry_oauth.go:35]
- **controller**: CatalogReconciler —watches-reference→ rbac.authorization.k8s.io/v1/RoleBinding; rbac.authorization.k8s.io/v1/RoleBinding [source: internal/controller/catalog_controller.go:1129, internal/controller/catalog_controller.go:1480]
- **controller**: CatalogReconciler —watches-reference→ route.openshift.io/v1/Route; route.openshift.io/v1/Route [source: internal/controller/catalog_controller.go:1483, internal/controller/modelregistry_controller.go:768]
- **controller**: ModelRegistryReconciler —watches-reference→ api/v1beta1/ModelRegistry; api/v1beta1/ModelRegistry [source: api/v1beta1/modelregistry_webhook.go:246, internal/controller/modelregistry_controller.go:282]
- **controller**: ModelRegistryReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: internal/controller/aihub_controller.go:458, internal/controller/modelregistry_controller.go:285]
- **controller**: ModelRegistryReconciler —watches-reference→ networking.k8s.io/v1/NetworkPolicy; networking.k8s.io/v1/NetworkPolicy [source: internal/controller/modelregistry_controller.go:287, internal/controller/modelregistry_oauth.go:45]
- **controller**: ModelRegistryReconciler —watches-reference→ rbac.authorization.k8s.io/v1/ClusterRoleBinding; rbac.authorization.k8s.io/v1/ClusterRoleBinding [source: internal/controller/modelregistry_controller.go:304, internal/controller/modelregistry_oauth.go:35]
- **controller**: ModelRegistryReconciler —watches-reference→ rbac.authorization.k8s.io/v1/RoleBinding; rbac.authorization.k8s.io/v1/RoleBinding [source: internal/controller/catalog_controller.go:1129, internal/controller/modelregistry_controller.go:289]
- **controller**: ModelRegistryReconciler —watches-reference→ route.openshift.io/v1/Route; route.openshift.io/v1/Route [source: internal/controller/modelregistry_controller.go:300, internal/controller/modelregistry_controller.go:768]
- **security**: GET /healthz —protected-by→ None; N/A: Kubernetes health probe; unauthenticated by design [source: cmd/aihub.go:186]
- **security**: GET /readyz —protected-by→ None; N/A: Kubernetes readiness probe; unauthenticated by design [source: cmd/aihub.go:189]

## Behavioral Evidence

- **conditional-metrics-enforcement (unresolved)** controller-runtime metrics: controller-runtime metrics serving surface; limitations=The controller-runtime manager Metrics binding does not use one direct lexical options object with a stable SecureServing condition [source: cmd/aihub.go:142-142]
- **conditional-metrics-enforcement (unresolved)** controller-runtime metrics: controller-runtime metrics serving surface; limitations=The controller-runtime manager Metrics binding does not use one direct lexical options object with a stable SecureServing condition [source: cmd/catalog.go:128-128]
- **conditional-metrics-enforcement (unresolved)** controller-runtime metrics: controller-runtime metrics serving surface; limitations=The controller-runtime manager Metrics binding does not use one direct lexical options object with a stable SecureServing condition [source: cmd/modelregistry.go:181-181]
- **named-watch-predicate (unresolved)** internal/controller.CatalogReconciler: /v1/ConfigMap; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/catalog_controller.go:1506-1510]
- **named-watch-predicate (unresolved)** internal/controller.CatalogReconciler: rbac.authorization.k8s.io/v1/ClusterRoleBinding; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/catalog_controller.go:1512-1516]
- **named-watch-predicate (unresolved)** internal/controller.ModelRegistryReconciler: route.openshift.io/v1/Route; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/modelregistry_controller.go:300-303]
- **named-watch-predicate (unresolved)** internal/controller.ModelRegistryReconciler: rbac.authorization.k8s.io/v1/ClusterRoleBinding; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/modelregistry_controller.go:304-307]

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/aihub.go`:125 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Under which configuration branch does the metrics serving surface install authentication and authorization?
  **Expected signal:** a direct SecureServing condition and controller-runtime authn/authz FilterProvider assignment
  **Candidate:** `cmd/aihub.go`:142-142 (controller-runtime metrics, controller-runtime metrics serving surface)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/aihub.go`:186 (/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/aihub.go`:189 (/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Under which configuration branch does the metrics serving surface install authentication and authorization?
  **Expected signal:** a direct SecureServing condition and controller-runtime authn/authz FilterProvider assignment
  **Candidate:** `cmd/catalog.go`:128-128 (controller-runtime metrics, controller-runtime metrics serving surface)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Under which configuration branch does the metrics serving surface install authentication and authorization?
  **Expected signal:** a direct SecureServing condition and controller-runtime authn/authz FilterProvider assignment
  **Candidate:** `cmd/modelregistry.go`:181-181 (controller-runtime metrics, controller-runtime metrics serving surface)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/modelregistry.go`:265 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/modelregistry.go`:269 (:8081/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `internal/controller/config/templates/catalog/catalog-deployment.yaml.tmpl`:1 (:8080/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `internal/controller/config/templates/catalog/catalog-deployment.yaml.tmpl`:1 (:8888/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `internal/webhook/modelregistry_webhook.go`:110 (Kubernetes admission, Operator webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/leader_election_role.yaml`:2 (leader-election-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/leader_election_role.yaml`:2 (model-registry-operator-leader-election-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/metrics_auth_role.yaml`:1 (metrics-auth-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/metrics_auth_role.yaml`:1 (model-registry-operator-metrics-auth-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/metrics_reader_role.yaml`:1 (metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/metrics_reader_role.yaml`:1 (model-registry-operator-metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/modelregistry_admin_role.yaml`:8 (modelregistry-admin-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/modelregistry_editor_role.yaml`:2 (modelregistry-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/modelregistry_viewer_role.yaml`:2 (modelregistry-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/role.yaml`:2 (manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/role.yaml`:2 (model-registry-operator-manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `internal/controller/config/templates/catalog/catalog-admin-role.yaml.tmpl`:1 (model-catalog-admin)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:43 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:32 (Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime behavior depends on this configuration default, and can deployment values override it?
  **Expected signal:** default value, environment/config key, flag, or override branch
  **Candidate:** `api/v1alpha1/modelregistry_types.go`:157 (Spec.Rest.Port)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime behavior depends on this configuration default, and can deployment values override it?
  **Expected signal:** default value, environment/config key, flag, or override branch
  **Candidate:** `api/v1beta1/modelregistry_types.go`:167 (Spec.Rest.Port)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime behavior depends on this configuration default, and can deployment values override it?
  **Expected signal:** default value, environment/config key, flag, or override branch
  **Candidate:** `api/v1beta1/modelregistry_types.go`:257 (Spec.KubeRBACProxy.Port)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime behavior depends on this configuration default, and can deployment values override it?
  **Expected signal:** default value, environment/config key, flag, or override branch
  **Candidate:** `api/v1beta1/modelregistry_types.go`:291 (Spec.KubeRBACProxy.RoutePort)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `main.go`:24 (model-registry-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/aihub.go`:125 (Kubernetes API, controller-runtime manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/catalog.go`:120 (Kubernetes API, controller-runtime manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/modelregistry.go`:169 (Kubernetes API, controller-runtime manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/modelregistry.go`:215 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `internal/setup/setup.go`:88 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/aihub.go`:186 (/healthz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/aihub.go`:189 (/readyz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/catalog.go`:181 (/healthz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/catalog.go`:185 (/readyz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/modelregistry.go`:265 (/healthz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/modelregistry.go`:269 (/readyz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, ModelRegistry CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (CRD Watch, OpenShift Routes)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (Gateway API, HTTPRoute CRUD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (OpenShift Users/Groups, REST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `internal/controller/config/templates/catalog/catalog-gateway-httproute.yaml.tmpl`:1 (Gateway API (data-science-gateway), HTTPRoute)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `api/aihub/v1alpha1/aihub_types.go`:22 (Go library, odh-platform-utilities)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, Gateway API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, ModelRegistry (modelregistry.opendatahub.io))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `go.mod` (Go Library, odh-platform-utilities)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/aihub_controller.go`:170 (api/aihub/v1alpha1/AIHub, get, update operations by AIHubReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/aihub_controller.go`:735 (/v1/ConfigMap, delete, get, list operations by AIHubReconciler, CatalogReconciler, ModelRegistryReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/catalog_controller.go`:445 (/v1/PersistentVolumeClaim, delete, get operations by CatalogReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/catalog_controller.go`:619 (/v1/Endpoints, get operations by CatalogReconciler, ModelRegistryReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/catalog_controller.go`:661 (/v1/Pod, list operations by CatalogReconciler, ModelRegistryReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/catalog_controller.go`:948 (/v1/Secret, get, list, update operations by CatalogReconciler, ModelRegistryReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `internal/controller/config/templates/catalog/catalog-gateway-httproute.yaml.tmpl`:1 (Gateway API (data-science-gateway), HTTPRoute)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `internal/controller/modelregistry_gateway.go`:84 (Gateway API, HTTPRoute CRUD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/aihub_controller.go`:769 (/v1/Service, AIHubReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/aihub_controller.go`:770 (/v1/ServiceAccount, AIHubReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/aihub_controller.go`:771 (/v1/ConfigMap, AIHubReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/catalog_controller.go`:1474 (/v1/Service, CatalogReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/catalog_controller.go`:1475 (/v1/ServiceAccount, CatalogReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/catalog_controller.go`:1476 (/v1/ConfigMap, CatalogReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/catalog_controller.go`:1477 (/v1/Secret, CatalogReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/catalog_controller.go`:1506-1510 (/v1/ConfigMap, internal/controller.CatalogReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/catalog_controller.go`:1512-1516 (internal/controller.CatalogReconciler, rbac.authorization.k8s.io/v1/ClusterRoleBinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/modelregistry_controller.go`:284 (/v1/ServiceAccount, ModelRegistryReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/modelregistry_controller.go`:300-303 (internal/controller.ModelRegistryReconciler, route.openshift.io/v1/Route)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/modelregistry_controller.go`:304-307 (internal/controller.ModelRegistryReconciler, rbac.authorization.k8s.io/v1/ClusterRoleBinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `config/default/manager_auth_proxy_patch.yaml`:3 (model-registry-operator-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `config/rbac/auth_proxy_service.yaml`:1 (model-registry-operator-controller-manager, model-registry-operator-controller-manager-metrics-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `internal/controller/config/templates/catalog/catalog-deployment.yaml.tmpl`:1 (model-catalog)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `internal/controller/config/templates/catalog/catalog-postgres-deployment.yaml.tmpl`:1 (model-catalog-postgres)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `internal/controller/config/templates/catalog/catalog-postgres-service.yaml.tmpl`:1 (model-catalog-postgres)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `internal/controller/config/templates/catalog/catalog-service.yaml.tmpl`:1 (model-catalog)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `internal/controller/config/templates/deployment.yaml.tmpl`:1 ({registry-name})
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `internal/controller/config/templates/postgres-deployment.yaml.tmpl`:1 ({registry-name}-postgres)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `internal/controller/config/templates/postgres-service.yaml.tmpl`:1 ({registry-name}-postgres)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `internal/controller/config/templates/service.yaml.tmpl`:1 ({registry-name})
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### webhooks

- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/crd/patches/webhook_in_modelregistries.yaml`:3 (/convert, modelregistries.modelregistry.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/webhook/manifests.yaml`:2 (/mutate-modelregistry-opendatahub-io-modelregistry, mmodelregistry.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/webhook/manifests.yaml`:31 (/validate-modelregistry-opendatahub-io-modelregistry, vmodelregistry.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/modelregistry_webhook.go`:110 (/validate-modelregistry-opendatahub-io-modelregistry, vmodelregistry.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/modelregistry_webhook.go`:57 (/mutate-modelregistry-opendatahub-io-modelregistry, mmodelregistry.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- /healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: cmd/aihub.go:186]
- /readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/aihub.go:189]
- :8080/readyz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes readiness probe endpoint [source: internal/controller/config/templates/catalog/catalog-deployment.yaml.tmpl:1]
- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: cmd/modelregistry.go:265]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/modelregistry.go:269]
- :8888/healthz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes liveness probe endpoint [source: internal/controller/config/templates/catalog/catalog-deployment.yaml.tmpl:1]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via model-registry-operator-manager-role ClusterRole; SA model-registry-operator-controller-manager [source: cmd/aihub.go:125]
- Operator webhook methods=CREATE mechanism=Kubernetes admission enforcement=ValidatingWebhookConfiguration policy=Admission validation [source: internal/webhook/modelregistry_webhook.go:110]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/aihub.go:186]
- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/catalog.go:181]
- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/modelregistry.go:265]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/aihub.go:189]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/catalog.go:185]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/modelregistry.go:269]
### integrations

- Gateway API (data-science-gateway) interaction=HTTPRoute role=runtime-transport protocol=HTTPS purpose=External dashboard ingress [source: internal/controller/config/templates/catalog/catalog-gateway-httproute.yaml.tmpl:1]
- Gateway API interaction=HTTPRoute CRUD role=runtime-transport protocol=HTTPS purpose=Manage Gateway API routing resources [source: config/rbac/role.yaml:2]
- ModelRegistry CR interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage model registry instances [source: config/rbac/role.yaml:2]
- OpenShift Routes interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Dashboard route status [source: config/rbac/role.yaml:2]
- OpenShift Users/Groups interaction=REST role=runtime-transport protocol=HTTPS purpose=User and group management [source: config/rbac/role.yaml:2]
### internal_dependencies

- Gateway API (data-science-gateway) interaction=HTTPRoute role=runtime-transport purpose=Platform ingress through Gateway API [source: internal/controller/config/templates/catalog/catalog-gateway-httproute.yaml.tmpl:1]
- Gateway API interaction=CRD CRUD role=unknown purpose=Manage Gateway API routing resources [source: config/rbac/role.yaml:2]
- Gateway API interaction=HTTPRoute CRUD role=runtime-transport purpose=Reconcile HTTPRoute resources against a configured Gateway [source: internal/controller/modelregistry_gateway.go:84]
- ModelRegistry (modelregistry.opendatahub.io) interaction=CRD CRUD role=unknown purpose=Manage model registry instances [source: config/rbac/role.yaml:2]
- odh-platform-utilities interaction=Go Library role=runtime-library purpose=Platform detection, manifest rendering, and deployment helpers [source: go.mod]
- odh-platform-utilities interaction=Go library role=runtime-library purpose=Use runtime packages from github.com/opendatahub-io/odh-platform-utilities [source: api/aihub/v1alpha1/aihub_types.go:22]
### services

- model-catalog port=8080 target=8080 protocol=TCP encryption= auth= [source: internal/controller/config/templates/catalog/catalog-service.yaml.tmpl:1]
- model-catalog port=8443 target=8443 protocol=TCP encryption= auth= [source: internal/controller/config/templates/catalog/catalog-service.yaml.tmpl:1]
- model-catalog-postgres port=5432 target=5432 protocol=TCP encryption= auth= [source: internal/controller/config/templates/catalog/catalog-postgres-service.yaml.tmpl:1]
- model-registry-operator-controller-manager-metrics-service port=8443 target=https protocol=TCP encryption= auth= [source: config/rbac/auth_proxy_service.yaml:1]
- {registry-name} port=8080 target=8080 protocol=TCP encryption= auth= [source: internal/controller/config/templates/service.yaml.tmpl:1]
- {registry-name} port=8443 target=8443 protocol=TCP encryption= auth= [source: internal/controller/config/templates/service.yaml.tmpl:1]
- {registry-name}-postgres port=5432 target=5432 protocol=TCP encryption= auth= [source: internal/controller/config/templates/postgres-service.yaml.tmpl:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Controller-created Deployment workload model-catalog uses service account model-catalog and 2 container(s) [source: internal/controller/config/templates/catalog/catalog-deployment.yaml.tmpl:1]
- **observed**: Controller-created Deployment workload model-catalog-postgres uses service account  and 1 container(s) [source: internal/controller/config/templates/catalog/catalog-postgres-deployment.yaml.tmpl:1]
- **observed**: Controller-created Deployment workload {registry-name} uses service account {registry-name} and 2 container(s) [source: internal/controller/config/templates/deployment.yaml.tmpl:1]
- **observed**: Controller-created Deployment workload {registry-name}-postgres uses service account  and 1 container(s) [source: internal/controller/config/templates/postgres-deployment.yaml.tmpl:1]
- **observed**: Deployment workload model-registry-operator-controller-manager uses service account model-registry-operator-controller-manager and 1 container(s) [source: config/default/manager_auth_proxy_patch.yaml:3]
- **observed**: Service model-catalog targets model-catalog with 2 port(s) [source: internal/controller/config/templates/catalog/catalog-service.yaml.tmpl:1]
- **observed**: Service model-catalog-postgres targets model-catalog-postgres with 1 port(s) [source: internal/controller/config/templates/catalog/catalog-postgres-service.yaml.tmpl:1]
- **observed**: Service model-registry-operator-controller-manager-metrics-service targets model-registry-operator-controller-manager with 1 port(s) [source: config/rbac/auth_proxy_service.yaml:1]
- **observed**: Service {registry-name} targets {registry-name} with 2 port(s) [source: internal/controller/config/templates/service.yaml.tmpl:1]
- **observed**: Service {registry-name}-postgres targets {registry-name}-postgres with 1 port(s) [source: internal/controller/config/templates/postgres-service.yaml.tmpl:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by cmd [source: cmd/aihub.go:186]
- **observed**: HTTP GET /readyz is owned by cmd [source: cmd/aihub.go:189]
- **observed**: HTTPRoute model-catalog serves host  via plaintext; backend=model-catalog; transport=Unknown [source: internal/controller/config/templates/catalog/catalog-gateway-httproute.yaml.tmpl:1]
- **observed**: HTTPRoute model-registry-{registry-name} serves host  via plaintext; backend={registry-name}; transport=Unknown [source: internal/controller/config/templates/gateway/gateway-httproute.yaml.tmpl:1]
- **observed**: Route model-catalog-https serves host model-catalog.{domain} via TLS; backend=model-catalog; transport=HTTPS [source: internal/controller/config/templates/catalog/catalog-kube-rbac-proxy-https-route.yaml.tmpl:1]
- **observed**: Route {registry-name}-http serves host  via plaintext; backend={registry-name}; transport=HTTP [source: internal/controller/config/templates/http-route.yaml.tmpl:1]
- **observed**: Route {registry-name}-https serves host {registry-name}-rest.{domain} via TLS; backend={registry-name}; transport=HTTPS [source: internal/controller/config/templates/kube-rbac-proxy/kube-rbac-proxy-https-route.yaml.tmpl:1]
### security

- **observed**: CREATE Operator webhook uses Kubernetes admission at ValidatingWebhookConfiguration; policy=Admission validation [source: internal/webhook/modelregistry_webhook.go:110]
- **observed**: GET /healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: cmd/aihub.go:186]
- **observed**: GET /readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/aihub.go:189]
- **observed**: GET :8080/readyz uses None at N/A; policy=Unauthenticated Kubernetes readiness probe endpoint [source: internal/controller/config/templates/catalog/catalog-deployment.yaml.tmpl:1]
- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: cmd/modelregistry.go:265]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/modelregistry.go:269]
- **observed**: GET :8888/healthz uses None at N/A; policy=Unauthenticated Kubernetes liveness probe endpoint [source: internal/controller/config/templates/catalog/catalog-deployment.yaml.tmpl:1]
- **observed**: RBAC role leader-election-role grants 3 rule(s) [source: config/rbac/leader_election_role.yaml:2]
- **observed**: RBAC role manager-role grants 19 rule(s) [source: config/rbac/role.yaml:2]
- **observed**: RBAC role metrics-auth-role grants 2 rule(s) [source: config/rbac/metrics_auth_role.yaml:1]
- **observed**: RBAC role metrics-reader grants 1 rule(s) [source: config/rbac/metrics_reader_role.yaml:1]
- **observed**: RBAC role model-catalog grants 2 rule(s) [source: internal/controller/config/templates/catalog/catalog-role.yaml.tmpl:1]
- **observed**: RBAC role model-catalog-admin grants 1 rule(s) [source: internal/controller/config/templates/catalog/catalog-admin-role.yaml.tmpl:1]
- **observed**: RBAC role model-registry-operator-leader-election-role grants 3 rule(s) [source: config/rbac/leader_election_role.yaml:2]
- **observed**: RBAC role model-registry-operator-manager-role grants 19 rule(s) [source: config/rbac/role.yaml:2]
- **observed**: RBAC role model-registry-operator-metrics-auth-role grants 2 rule(s) [source: config/rbac/metrics_auth_role.yaml:1]
- **observed**: RBAC role model-registry-operator-metrics-reader grants 1 rule(s) [source: config/rbac/metrics_reader_role.yaml:1]
- **observed**: RBAC role modelregistry-admin-role grants 2 rule(s) [source: config/rbac/modelregistry_admin_role.yaml:8]
- **observed**: RBAC role modelregistry-editor-role grants 2 rule(s) [source: config/rbac/modelregistry_editor_role.yaml:2]
- **observed**: RBAC role modelregistry-viewer-role grants 2 rule(s) [source: config/rbac/modelregistry_viewer_role.yaml:2]
- **observed**: RBAC role registry-user-{registry-name} grants 2 rule(s) [source: internal/controller/config/templates/role.yaml.tmpl:1]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via model-registry-operator-manager-role ClusterRole; SA model-registry-operator-controller-manager [source: cmd/aihub.go:125]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: internal/setup/setup.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
