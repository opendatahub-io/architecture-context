# Analyzer Synthesis Context: ogx-k8s-operator

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 3 crds facts extracted [source: config/crd/bases/llamastack.io_llamastackdistributions.yaml:2, config/crd/bases/ogx.io_ogxservers.yaml:2, ogx-module/config/crd/bases/components.platform.opendatahub.io_ogxs.yaml:2]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 4 http_endpoints facts extracted [source: main.go:142, main.go:145, ogx-module/cmd/ogx-module/main.go:106, ogx-module/cmd/ogx-module/main.go:110]
- **services (observed)**: 2 services facts extracted [source: config/rbac/auth_proxy_service.yaml:1, config/webhook/service.yaml:1]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (observed)**: 2 webhooks facts extracted [source: api/v1beta1/ogxserver_webhook.go:55, config/webhook/manifests.yaml:2]

## Deterministic Cross-References

- **controller**: OGXServerReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: controllers/configmap_reconciler.go:145, controllers/ogxserver_controller.go:853]
- **controller**: OGXServerReconciler —watches-reference→ /v1/PersistentVolumeClaim; /v1/PersistentVolumeClaim [source: controllers/legacy_adoption.go:168, controllers/ogxserver_controller.go:867]
- **controller**: OGXServerReconciler —watches-reference→ /v1/Secret; /v1/Secret [source: controllers/migration_job.go:325, controllers/ogxserver_controller.go:860]
- **controller**: OGXServerReconciler —watches-reference→ /v1/Service; /v1/Service [source: controllers/legacy_adoption.go:278, controllers/ogxserver_controller.go:852]
- **controller**: OGXServerReconciler —watches-reference→ api/v1beta1/OGXServer; api/v1beta1/OGXServer [source: controllers/ogxserver_controller.go:230, controllers/ogxserver_controller.go:846]
- **controller**: OGXServerReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: controllers/configmap_reconciler.go:294, controllers/ogxserver_controller.go:849]
- **controller**: OGXServerReconciler —watches-reference→ autoscaling/v2/HorizontalPodAutoscaler; autoscaling/v2/HorizontalPodAutoscaler [source: controllers/ogxserver_controller.go:431, controllers/ogxserver_controller.go:851]
- **controller**: OGXServerReconciler —watches-reference→ batch/v1/Job; batch/v1/Job [source: controllers/migration_job.go:463, controllers/ogxserver_controller.go:854]
- **controller**: OGXServerReconciler —watches-reference→ networking.k8s.io/v1/Ingress; networking.k8s.io/v1/Ingress [source: controllers/legacy_adoption.go:311, controllers/ogxserver_controller.go:866]
- **controller**: OGXServerReconciler —watches-reference→ networking.k8s.io/v1/NetworkPolicy; networking.k8s.io/v1/NetworkPolicy [source: controllers/ogxserver_controller.go:375, controllers/ogxserver_controller.go:865]
- **controller**: OGXServerReconciler —watches-reference→ policy/v1/PodDisruptionBudget; policy/v1/PodDisruptionBudget [source: controllers/ogxserver_controller.go:404, controllers/ogxserver_controller.go:850]
- **controller**: Reconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: controllers/configmap_reconciler.go:145, ogx-module/internal/controller/ogx/reconciler.go:142]
- **controller**: Reconciler —watches-reference→ /v1/Service; /v1/Service [source: controllers/legacy_adoption.go:278, ogx-module/internal/controller/ogx/reconciler.go:143]
- **controller**: Reconciler —watches-reference→ admissionregistration/v1/ValidatingWebhookConfiguration; admissionregistration/v1/ValidatingWebhookConfiguration [source: ogx-module/internal/controller/ogx/reconciler.go:150, ogx-module/internal/controller/ogx/reconciler.go:404]
- **controller**: Reconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: controllers/configmap_reconciler.go:294, ogx-module/internal/controller/ogx/reconciler.go:141]
- **controller**: Reconciler —watches-reference→ policy/v1/PodDisruptionBudget; policy/v1/PodDisruptionBudget [source: controllers/ogxserver_controller.go:404, ogx-module/internal/controller/ogx/reconciler.go:145]
- **controller**: Reconciler —watches-reference→ rbac.authorization.k8s.io/v1/ClusterRole; rbac.authorization.k8s.io/v1/ClusterRole [source: ogx-module/internal/controller/ogx/reconciler.go:148, pkg/deploy/kustomizer.go:856]
- **controller**: Reconciler —watches-reference→ rbac.authorization.k8s.io/v1/ClusterRoleBinding; rbac.authorization.k8s.io/v1/ClusterRoleBinding [source: ogx-module/internal/controller/ogx/reconciler.go:149, pkg/cluster/cluster.go:62]
- **security**: GET /healthz —protected-by→ None; N/A: Kubernetes health probe; unauthenticated by design [source: main.go:142, ogx-module/cmd/ogx-module/main.go:106]
- **security**: GET /readyz —protected-by→ None; N/A: Kubernetes readiness probe; unauthenticated by design [source: main.go:145, ogx-module/cmd/ogx-module/main.go:110]
- **webhook**: vogxserver.kb.io —served-by→ ogx-k8s-operator-webhook-service; admission webhook declares an explicit service reference [source: api/v1beta1/ogxserver_webhook.go:55, config/webhook/manifests.yaml:2, config/webhook/service.yaml:1]

## Behavioral Evidence

- **conditional-metrics-enforcement (unresolved)** controller-runtime metrics: controller-runtime metrics serving surface; limitations=The controller-runtime manager Metrics binding does not use one direct lexical options object with a stable SecureServing condition [source: main.go:298-298]
- **conditional-metrics-enforcement (unresolved)** controller-runtime metrics: controller-runtime metrics serving surface; limitations=The controller-runtime manager Metrics binding does not use one direct lexical options object with a stable SecureServing condition [source: ogx-module/cmd/ogx-module/main.go:82-82]
- **named-watch-predicate (unresolved)** controllers.OGXServerReconciler: /v1/ConfigMap; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: controllers/ogxserver_controller.go:855-859]
- **named-watch-predicate (unresolved)** controllers.OGXServerReconciler: /v1/Secret; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: controllers/ogxserver_controller.go:860-864]
- **named-watch-predicate (unresolved)** internal/controller/ogx.Reconciler: /v1/ConfigMap; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: ogx-module/internal/controller/ogx/reconciler.go:152-160]

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `config/webhook/manifests.yaml`:2 (Kubernetes admission, Operator webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `main.go`:142 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `main.go`:145 (:8081/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Under which configuration branch does the metrics serving surface install authentication and authorization?
  **Expected signal:** a direct SecureServing condition and controller-runtime authn/authz FilterProvider assignment
  **Candidate:** `main.go`:298-298 (controller-runtime metrics, controller-runtime metrics serving surface)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `ogx-module/cmd/ogx-module/main.go`:106 (/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `ogx-module/cmd/ogx-module/main.go`:110 (/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `ogx-module/cmd/ogx-module/main.go`:66 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Under which configuration branch does the metrics serving surface install authentication and authorization?
  **Expected signal:** a direct SecureServing condition and controller-runtime authn/authz FilterProvider assignment
  **Candidate:** `ogx-module/cmd/ogx-module/main.go`:82-82 (controller-runtime metrics, controller-runtime metrics serving surface)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/auth_proxy_client_clusterrole.yaml`:1 (ogx-k8s-operator-metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/auth_proxy_role.yaml`:1 (ogx-k8s-operator-proxy-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/auth_proxy_role.yaml`:1 (proxy-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/ogxserver_editor_role.yaml`:2 (ogx-k8s-operator-ogxserver-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/ogxserver_editor_role.yaml`:2 (ogxserver-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/ogxserver_viewer_role.yaml`:2 (ogx-k8s-operator-ogxserver-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/ogxserver_viewer_role.yaml`:2 (ogxserver-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/role.yaml`:2 (manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/role.yaml`:2 (ogx-k8s-operator-manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `ogx-module/config/rbac/cluster_role.yaml`:1 (manager-cluster-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `ogx-module/config/rbac/components_ogx_admin_role.yaml`:4 (components-ogx-admin-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `ogx-module/config/rbac/metrics_reader_role.yaml`:1 (metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:67 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:39 (Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/configgen/main.go`:59 (configgen)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `main.go`:215 (ogx-k8s-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `ogx-module/Dockerfile`:52 (ogx-module/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `ogx-module/Dockerfile.konflux`:32 (ogx-module/Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `ogx-module/cmd/ogx-module/main.go`:30 (ogx-module)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `ogx-module/cmd/ogx-module/main.go`:60 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `ogx-module/cmd/ogx-module/main.go`:66 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `main.go`:142 (/healthz, GET, main)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `main.go`:145 (/readyz, GET, main)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `ogx-module/cmd/ogx-module/main.go`:106 (/healthz, GET, cmd/ogx-module)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `ogx-module/cmd/ogx-module/main.go`:110 (/readyz, GET, cmd/ogx-module)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (CRD Watch, OGX Server CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `cmd/configgen/main.go`:225 (/v1/Namespace, create operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRD Watch, OGX Server (ogx.io))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `controllers/configmap_reconciler.go`:145 (/v1/ConfigMap, create, delete, get, list, patch, update operations by OGXServerReconciler, Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `controllers/legacy_adoption.go`:168 (/v1/PersistentVolumeClaim, get, list, update operations by OGXServerReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `controllers/legacy_adoption.go`:278 (/v1/Service, get, list operations by OGXServerReconciler, Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `controllers/legacy_adoption.go`:361 (/v1/Pod, list operations by OGXServerReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `controllers/migration_job.go`:325 (/v1/Secret, get operations by OGXServerReconciler, Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `controllers/ogxserver_controller.go`:230 (api/v1beta1/OGXServer, get, list, update operations by OGXServerReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `ogx-module/go.mod` (Go Library, odh-platform-utilities)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `ogx-module/internal/controller/ogx/reconciler.go`:15 (Go library, odh-platform-utilities)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `ogx-module/internal/controller/ogx/reconciler.go`:404 (admissionregistration/v1/ValidatingWebhookConfiguration, get operations by Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/ogxserver_controller.go`:846 (OGXServerReconciler, api/v1beta1/OGXServer)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/ogxserver_controller.go`:852 (/v1/Service, OGXServerReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/ogxserver_controller.go`:853 (/v1/ConfigMap, OGXServerReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `controllers/ogxserver_controller.go`:855-859 (/v1/ConfigMap, controllers.OGXServerReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `controllers/ogxserver_controller.go`:860-864 (/v1/Secret, controllers.OGXServerReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/ogxserver_controller.go`:867 (/v1/PersistentVolumeClaim, OGXServerReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `ogx-module/internal/controller/ogx/reconciler.go`:142 (/v1/ConfigMap, Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `ogx-module/internal/controller/ogx/reconciler.go`:143 (/v1/Service, Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `ogx-module/internal/controller/ogx/reconciler.go`:144 (/v1/ServiceAccount, Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `ogx-module/internal/controller/ogx/reconciler.go`:150 (Reconciler, admissionregistration/v1/ValidatingWebhookConfiguration)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `ogx-module/internal/controller/ogx/reconciler.go`:151 (Reconciler, apiextensions/v1/CustomResourceDefinition)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `ogx-module/internal/controller/ogx/reconciler.go`:152-160 (/v1/ConfigMap, internal/controller/ogx.Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `config/default/manager_webhook_patch.yaml`:1 (ogx-k8s-operator-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `config/rbac/auth_proxy_service.yaml`:1 (ogx-k8s-operator-controller-manager, ogx-k8s-operator-controller-manager-metrics-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `config/webhook/service.yaml`:1 (ogx-k8s-operator-controller-manager, ogx-k8s-operator-webhook-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### webhooks

- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `api/v1beta1/ogxserver_webhook.go`:55 (/validate-ogx-io-v1beta1-ogxserver, vogxserver.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/webhook/manifests.yaml`:2 (/validate-ogx-io-v1beta1-ogxserver, vogxserver.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- /healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: ogx-module/cmd/ogx-module/main.go:106]
- /readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: ogx-module/cmd/ogx-module/main.go:110]
- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: main.go:142]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: main.go:145]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via ogx-k8s-operator-manager-role ClusterRole; SA ogx-k8s-operator-controller-manager [source: ogx-module/cmd/ogx-module/main.go:66]
- Operator webhook methods=CREATE mechanism=Kubernetes admission enforcement=ValidatingWebhookConfiguration policy=Admission validation [source: config/webhook/manifests.yaml:2]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/ogx-module [source: ogx-module/cmd/ogx-module/main.go:106]
- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: main.go:142]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/ogx-module [source: ogx-module/cmd/ogx-module/main.go:110]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: main.go:145]
### integrations

- OGX Server CR interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read OGX server state [source: config/rbac/role.yaml:2]
- prometheus-operator interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage Prometheus monitoring resources [source: config/rbac/role.yaml:2]
### internal_dependencies

- OGX Server (ogx.io) interaction=CRD Watch role=runtime-integration purpose=Read OGX server state [source: config/rbac/role.yaml:2]
- odh-platform-utilities interaction=Go Library role=runtime-library purpose=Platform detection, manifest rendering, and deployment helpers [source: ogx-module/go.mod]
- odh-platform-utilities interaction=Go library role=runtime-library purpose=Use runtime packages from github.com/opendatahub-io/odh-platform-utilities [source: ogx-module/internal/controller/ogx/reconciler.go:15]
- prometheus-operator interaction=CRD CRUD role=unknown purpose=Manage Prometheus monitoring resources [source: config/rbac/role.yaml:2]
### services

- ogx-k8s-operator-controller-manager-metrics-service port=8443 target=https protocol=TCP encryption= auth= [source: config/rbac/auth_proxy_service.yaml:1]
- ogx-k8s-operator-webhook-service port=443 target=9443 protocol=TCP encryption= auth= [source: config/webhook/service.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload ogx-k8s-operator-controller-manager uses service account ogx-k8s-operator-controller-manager and 1 container(s) [source: config/default/manager_webhook_patch.yaml:1]
- **observed**: Service ogx-k8s-operator-controller-manager-metrics-service targets ogx-k8s-operator-controller-manager with 1 port(s) [source: config/rbac/auth_proxy_service.yaml:1]
- **observed**: Service ogx-k8s-operator-webhook-service targets ogx-k8s-operator-controller-manager with 1 port(s) [source: config/webhook/service.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by cmd/ogx-module [source: ogx-module/cmd/ogx-module/main.go:106]
- **observed**: HTTP GET /healthz is owned by main [source: main.go:142]
- **observed**: HTTP GET /readyz is owned by cmd/ogx-module [source: ogx-module/cmd/ogx-module/main.go:110]
- **observed**: HTTP GET /readyz is owned by main [source: main.go:145]
### security

- **observed**: CREATE Operator webhook uses Kubernetes admission at ValidatingWebhookConfiguration; policy=Admission validation [source: config/webhook/manifests.yaml:2]
- **observed**: GET /healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: ogx-module/cmd/ogx-module/main.go:106]
- **observed**: GET /readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: ogx-module/cmd/ogx-module/main.go:110]
- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: main.go:142]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: main.go:145]
- **observed**: RBAC role components-ogx-admin-role grants 2 rule(s) [source: ogx-module/config/rbac/components_ogx_admin_role.yaml:4]
- **observed**: RBAC role components-ogx-editor-role grants 2 rule(s) [source: ogx-module/config/rbac/components_ogx_editor_role.yaml:4]
- **observed**: RBAC role components-ogx-viewer-role grants 2 rule(s) [source: ogx-module/config/rbac/components_ogx_viewer_role.yaml:4]
- **observed**: RBAC role leader-election-role grants 3 rule(s) [source: ogx-module/config/rbac/leader_election_role.yaml:1]
- **observed**: RBAC role manager-cluster-role grants 25 rule(s) [source: ogx-module/config/rbac/cluster_role.yaml:1]
- **observed**: RBAC role manager-role grants 22 rule(s) [source: config/rbac/role.yaml:2]
- **observed**: RBAC role manager-role grants 8 rule(s) [source: ogx-module/config/rbac/role.yaml:1]
- **observed**: RBAC role metrics-auth-role grants 2 rule(s) [source: ogx-module/config/rbac/metrics_auth_role.yaml:1]
- **observed**: RBAC role metrics-reader grants 1 rule(s) [source: ogx-module/config/rbac/metrics_reader_role.yaml:1]
- **observed**: RBAC role ogx-k8s-operator-leader-election-role grants 3 rule(s) [source: config/rbac/leader_election_role.yaml:2]
- **observed**: RBAC role ogx-k8s-operator-manager-role grants 22 rule(s) [source: config/rbac/role.yaml:2]
- **observed**: RBAC role ogx-k8s-operator-metrics-reader grants 1 rule(s) [source: config/rbac/auth_proxy_client_clusterrole.yaml:1]
- **observed**: RBAC role ogx-k8s-operator-ogxserver-editor-role grants 2 rule(s) [source: config/rbac/ogxserver_editor_role.yaml:2]
- **observed**: RBAC role ogx-k8s-operator-ogxserver-viewer-role grants 2 rule(s) [source: config/rbac/ogxserver_viewer_role.yaml:2]
- **observed**: RBAC role ogx-k8s-operator-proxy-role grants 2 rule(s) [source: config/rbac/auth_proxy_role.yaml:1]
- **observed**: RBAC role ogxserver-editor-role grants 2 rule(s) [source: config/rbac/ogxserver_editor_role.yaml:2]
- **observed**: RBAC role ogxserver-viewer-role grants 2 rule(s) [source: config/rbac/ogxserver_viewer_role.yaml:2]
- **observed**: RBAC role proxy-role grants 2 rule(s) [source: config/rbac/auth_proxy_role.yaml:1]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via ogx-k8s-operator-manager-role ClusterRole; SA ogx-k8s-operator-controller-manager [source: ogx-module/cmd/ogx-module/main.go:66]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: main.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
