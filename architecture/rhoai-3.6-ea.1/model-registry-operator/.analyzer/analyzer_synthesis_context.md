# Analyzer Synthesis Context: model-registry-operator

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 4 crds facts extracted [source: api/v1alpha1/modelregistry_types.go:440, config/crd/bases/aihub.opendatahub.io_catalogs.yaml:2, config/crd/bases/components.platform.opendatahub.io_aihubs.yaml:2, config/crd/bases/modelregistry.opendatahub.io_modelregistries.yaml:2]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 2 http_endpoints facts extracted [source: cmd/modelregistry.go:287, cmd/modelregistry.go:291]
- **services (observed)**: 5 services facts extracted [source: config/rbac/auth_proxy_service.yaml:1, internal/controller/config/templates/catalog/catalog-postgres-service.yaml.tmpl:1, internal/controller/config/templates/catalog/catalog-service.yaml.tmpl:1, internal/controller/config/templates/postgres-service.yaml.tmpl:1, internal/controller/config/templates/service.yaml.tmpl:1]
- **ingress (observed)**: 5 ingress facts extracted [source: internal/controller/config/templates/catalog/catalog-gateway-httproute.yaml.tmpl:1, internal/controller/config/templates/catalog/catalog-kube-rbac-proxy-https-route.yaml.tmpl:1, internal/controller/config/templates/gateway/gateway-httproute.yaml.tmpl:1, internal/controller/config/templates/http-route.yaml.tmpl:1, internal/controller/config/templates/kube-rbac-proxy/kube-rbac-proxy-https-route.yaml.tmpl:1]
- **webhooks (observed)**: 5 webhooks facts extracted [source: config/crd/patches/webhook_in_modelregistries.yaml:3, config/webhook/manifests.yaml:2, config/webhook/manifests.yaml:31, internal/webhook/modelregistry_webhook.go:110, internal/webhook/modelregistry_webhook.go:57]

## Deterministic Cross-References

- **controller**: ModelCatalogReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: internal/controller/modelcatalog_controller.go:1354, internal/controller/modelcatalog_controller.go:183]
- **controller**: ModelCatalogReconciler —watches-reference→ /v1/Secret; /v1/Secret [source: internal/controller/modelcatalog_controller.go:1355, internal/controller/modelcatalog_controller.go:861]
- **controller**: ModelCatalogReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: internal/controller/modelcatalog_controller.go:1353, internal/controller/modelcatalog_controller.go:552]
- **controller**: ModelCatalogReconciler —watches-reference→ networking.k8s.io/v1/NetworkPolicy; networking.k8s.io/v1/NetworkPolicy [source: internal/controller/modelcatalog_controller.go:1361, internal/controller/modelregistry_oauth.go:45]
- **controller**: ModelCatalogReconciler —watches-reference→ rbac.authorization.k8s.io/v1/ClusterRoleBinding; rbac.authorization.k8s.io/v1/ClusterRoleBinding [source: internal/controller/modelcatalog_controller.go:1358, internal/controller/modelregistry_oauth.go:35]
- **controller**: ModelCatalogReconciler —watches-reference→ rbac.authorization.k8s.io/v1/RoleBinding; rbac.authorization.k8s.io/v1/RoleBinding [source: internal/controller/modelcatalog_controller.go:1360, internal/controller/modelcatalog_controller.go:996]
- **controller**: ModelRegistryReconciler —watches-reference→ api/v1beta1/ModelRegistry; api/v1beta1/ModelRegistry [source: api/v1beta1/modelregistry_webhook.go:246, internal/controller/modelregistry_controller.go:282]
- **controller**: ModelRegistryReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: internal/controller/modelcatalog_controller.go:552, internal/controller/modelregistry_controller.go:285]
- **controller**: ModelRegistryReconciler —watches-reference→ networking.k8s.io/v1/NetworkPolicy; networking.k8s.io/v1/NetworkPolicy [source: internal/controller/modelregistry_controller.go:287, internal/controller/modelregistry_oauth.go:45]
- **controller**: ModelRegistryReconciler —watches-reference→ rbac.authorization.k8s.io/v1/ClusterRoleBinding; rbac.authorization.k8s.io/v1/ClusterRoleBinding [source: internal/controller/modelregistry_controller.go:304, internal/controller/modelregistry_oauth.go:35]
- **controller**: ModelRegistryReconciler —watches-reference→ rbac.authorization.k8s.io/v1/RoleBinding; rbac.authorization.k8s.io/v1/RoleBinding [source: internal/controller/modelcatalog_controller.go:996, internal/controller/modelregistry_controller.go:289]
- **controller**: ModelRegistryReconciler —watches-reference→ route.openshift.io/v1/Route; route.openshift.io/v1/Route [source: internal/controller/modelregistry_controller.go:300, internal/controller/modelregistry_controller.go:768]

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/modelregistry.go`:287 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `internal/controller/config/templates/catalog/catalog-deployment.yaml.tmpl`:1 (:8080/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `internal/webhook/modelregistry_webhook.go`:110 (Kubernetes admission, Operator webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/leader_election_role.yaml`:2 (model-registry-operator-leader-election-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/metrics_auth_role.yaml`:1 (model-registry-operator-metrics-auth-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/rbac/metrics_auth_role_binding.yaml`:1 (model-registry-operator-metrics-auth-role, model-registry-operator-metrics-auth-rolebinding)
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
  **Candidate:** `config/rbac/role.yaml`:2 (model-registry-operator-manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/rbac/role_binding.yaml`:1 (model-registry-operator-manager-role, model-registry-operator-manager-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `internal/controller/config/templates/catalog/catalog-admin-role.yaml.tmpl`:1 (model-catalog-admin)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `internal/controller/config/templates/catalog/catalog-role.yaml.tmpl`:1 (model-catalog)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `internal/controller/config/templates/role.yaml.tmpl`:1 (registry-user-{registry-name})
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:39 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:30 (Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime behavior depends on this configuration default, and can deployment values override it?
  **Expected signal:** default value, environment/config key, flag, or override branch
  **Candidate:** `api/v1alpha1/modelregistry_types.go`:157 (Spec.Rest.Port)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime behavior depends on this configuration default, and can deployment values override it?
  **Expected signal:** default value, environment/config key, flag, or override branch
  **Candidate:** `api/v1beta1/modelregistry_types.go`:257 (Spec.KubeRBACProxy.Port)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `main.go`:24 (model-registry-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

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
  **Candidate:** `internal/setup/setup.go`:86 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/modelregistry.go`:287 (/healthz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (Gateway API, HTTPRoute CRUD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `internal/controller/config/templates/catalog/catalog-gateway-httproute.yaml.tmpl`:1 (Gateway API (data-science-gateway), HTTPRoute)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `api/v1alpha1/modelregistry_webhook.go`:236 (api/v1alpha1/ModelRegistry, list operations by ModelRegistry)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `api/v1beta1/modelregistry_webhook.go`:246 (api/v1beta1/ModelRegistry, get, list, update operations by ModelRegistry, ModelRegistryReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, Gateway API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/config/defaults.go`:199 (config.openshift.io/v1/Ingress, get operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `internal/controller/config/templates/catalog/catalog-gateway-httproute.yaml.tmpl`:1 (Gateway API (data-science-gateway), HTTPRoute)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/modelcatalog_controller.go`:183 (/v1/ConfigMap, delete, get, list, update operations by ModelCatalogReconciler, ModelRegistryReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `internal/controller/modelcatalog_controller.go`:518 (Gateway API, HTTPRoute CRUD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/modelregistry_controller.go`:768 (delete, list operations by ModelRegistryReconciler, route.openshift.io/v1/Route)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/modelregistry_controller_status.go`:267 (/v1/Endpoints, get operations by ModelRegistryReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/modelregistry_oauth.go`:45 (delete operations by ModelRegistryReconciler, networking.k8s.io/v1/NetworkPolicy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/migration/svm_strategy.go`:122 (get operations by SVMStrategy, migration.k8s.io/v1alpha1/StorageVersionMigration)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `api/v1alpha1/modelregistry_webhook.go`:236 (api/v1alpha1/ModelRegistry, list operations by ModelRegistry)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `api/v1beta1/modelregistry_webhook.go`:246 (api/v1beta1/ModelRegistry, get, list, update operations by ModelRegistry, ModelRegistryReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/controller/config/defaults.go`:199 (config.openshift.io/v1/Ingress, get operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/controller/modelcatalog_controller.go`:183 (/v1/ConfigMap, delete, get, list, update operations by ModelCatalogReconciler, ModelRegistryReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/modelcatalog_controller.go`:1354 (/v1/ConfigMap, ModelCatalogReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/controller/modelregistry_controller.go`:768 (delete, list operations by ModelRegistryReconciler, route.openshift.io/v1/Route)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/modelregistry_controller.go`:284 (/v1/ServiceAccount, ModelRegistryReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/controller/modelregistry_controller_status.go`:267 (/v1/Endpoints, get operations by ModelRegistryReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/controller/modelregistry_oauth.go`:45 (delete operations by ModelRegistryReconciler, networking.k8s.io/v1/NetworkPolicy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/migration/svm_strategy.go`:122 (get operations by SVMStrategy, migration.k8s.io/v1alpha1/StorageVersionMigration)
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
  **Candidate:** `internal/webhook/modelregistry_webhook.go`:57 (/mutate-modelregistry-opendatahub-io-modelregistry, mmodelregistry.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- :8080/readyz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes readiness probe endpoint [source: internal/controller/config/templates/catalog/catalog-deployment.yaml.tmpl:1]
- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: cmd/modelregistry.go:287]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/modelregistry.go:291]
- :8888/healthz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes liveness probe endpoint [source: internal/controller/config/templates/catalog/catalog-deployment.yaml.tmpl:1]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via model-registry-operator-manager-role ClusterRole; SA model-registry-operator-controller-manager [source: cmd/modelregistry.go:169]
- Operator webhook methods=CREATE mechanism=Kubernetes admission enforcement=ValidatingWebhookConfiguration policy=Admission validation [source: internal/webhook/modelregistry_webhook.go:110]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/modelregistry.go:287]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/modelregistry.go:291]
### integrations

- Gateway API (data-science-gateway) interaction=HTTPRoute role=runtime-transport protocol=HTTPS purpose=External dashboard ingress [source: internal/controller/config/templates/catalog/catalog-gateway-httproute.yaml.tmpl:1]
- Gateway API interaction=HTTPRoute CRUD role=runtime-transport protocol=HTTPS purpose=Manage Gateway API routing resources [source: config/rbac/role.yaml:2]
- ModelRegistry CR interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage model registry instances [source: config/rbac/role.yaml:2]
- OpenShift Routes interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Dashboard route status [source: config/rbac/role.yaml:2]
- OpenShift Users/Groups interaction=REST role=runtime-transport protocol=HTTPS purpose=User and group management [source: config/rbac/role.yaml:2]
### internal_dependencies

- Gateway API (data-science-gateway) interaction=HTTPRoute role=runtime-transport purpose=Platform ingress through Gateway API [source: internal/controller/config/templates/catalog/catalog-gateway-httproute.yaml.tmpl:1]
- Gateway API interaction=CRD CRUD role=unknown purpose=Manage Gateway API routing resources [source: config/rbac/role.yaml:2]
- Gateway API interaction=HTTPRoute CRUD role=runtime-transport purpose=Reconcile HTTPRoute resources against a configured Gateway [source: internal/controller/modelcatalog_controller.go:518]
- ModelRegistry (modelregistry.opendatahub.io) interaction=CRD CRUD role=unknown purpose=Manage model registry instances [source: config/rbac/role.yaml:2]
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

- **observed**: HTTP GET /healthz is owned by cmd [source: cmd/modelregistry.go:287]
- **observed**: HTTP GET /readyz is owned by cmd [source: cmd/modelregistry.go:291]
- **observed**: HTTPRoute model-catalog serves host  via plaintext; backend=model-catalog; transport=Unknown [source: internal/controller/config/templates/catalog/catalog-gateway-httproute.yaml.tmpl:1]
- **observed**: HTTPRoute model-registry-{registry-name} serves host  via plaintext; backend={registry-name}; transport=Unknown [source: internal/controller/config/templates/gateway/gateway-httproute.yaml.tmpl:1]
- **observed**: Route model-catalog-https serves host model-catalog.{domain} via TLS; backend=model-catalog; transport=HTTPS [source: internal/controller/config/templates/catalog/catalog-kube-rbac-proxy-https-route.yaml.tmpl:1]
- **observed**: Route {registry-name}-http serves host  via plaintext; backend={registry-name}; transport=HTTP [source: internal/controller/config/templates/http-route.yaml.tmpl:1]
- **observed**: Route {registry-name}-https serves host {registry-name}-rest.{domain} via TLS; backend={registry-name}; transport=HTTPS [source: internal/controller/config/templates/kube-rbac-proxy/kube-rbac-proxy-https-route.yaml.tmpl:1]
### security

- **observed**: CREATE Operator webhook uses Kubernetes admission at ValidatingWebhookConfiguration; policy=Admission validation [source: internal/webhook/modelregistry_webhook.go:110]
- **observed**: GET :8080/readyz uses None at N/A; policy=Unauthenticated Kubernetes readiness probe endpoint [source: internal/controller/config/templates/catalog/catalog-deployment.yaml.tmpl:1]
- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: cmd/modelregistry.go:287]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/modelregistry.go:291]
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
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via model-registry-operator-manager-role ClusterRole; SA model-registry-operator-controller-manager [source: cmd/modelregistry.go:169]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: internal/setup/setup.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
