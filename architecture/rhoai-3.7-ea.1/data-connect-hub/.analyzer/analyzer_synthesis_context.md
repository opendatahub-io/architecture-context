# Analyzer Synthesis Context: data-connect-hub

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 3 crds facts extracted [source: dc-controller/config/crd/bases/dataconnecthub.opendatahub.io_dataconnectservices.yaml:2, dc-controller/config/crd/bases/dataconnecthub.opendatahub.io_initdataconnections.yaml:2, dc-controller/config/crd/bases/dataconnecthub.opendatahub.io_initdataconnectiontypes.yaml:2]
- **grpc_services (not-verified)**: 0 grpc_services facts extracted; absence is not proven by the available coverage
- **http_endpoints (observed)**: 21 http_endpoints facts extracted [source: dc-controller/cmd/main.go:270, dc-controller/cmd/main.go:274, services/flight/src/flight/metrics.rs:123, services/rest/src/main.rs:50, services/rest/src/main.rs:55, services/rest/src/main.rs:56, services/rest/src/main.rs:57, services/rest/src/main.rs:58, services/rest/src/main.rs:59, services/rest/src/main.rs:60, services/rest/src/main.rs:61, services/rest/src/main.rs:62, services/rest/src/main.rs:63, services/rest/src/main.rs:64, services/rest/src/main.rs:65, services/rest/src/main.rs:69, services/rest/src/main.rs:70, services/rest/src/main.rs:71, services/rest/src/main.rs:72, services/rest/src/main.rs:73, services/rest/src/main.rs:74]
- **services (observed)**: 3 services facts extracted [source: dc-controller/config/default/metrics_service.yaml:1]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References

- **controller**: ConfigMapWatcherReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: dc-controller/internal/controller/configmap_watcher_controller.go:261, dc-controller/internal/controller/configmap_watcher_controller.go:64]
- **controller**: DataConnectServiceReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: dc-controller/internal/controller/configmap_watcher_controller.go:64, dc-controller/internal/controller/dataconnectservice_controller.go:1092]
- **controller**: DataConnectServiceReconciler —watches-reference→ api/dataconnecthub/v1alpha1/DataConnectService; api/dataconnecthub/v1alpha1/DataConnectService [source: dc-controller/internal/controller/dataconnectservice_controller.go:1089, dc-controller/internal/controller/dataconnectservice_controller.go:225]
- **controller**: DataConnectServiceReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: dc-controller/internal/controller/dataconnectservice_controller.go:1020, dc-controller/internal/controller/dataconnectservice_controller.go:1090]
- **controller**: InitDataConnectionReconciler —watches-reference→ api/dataconnecthub/v1alpha1/InitDataConnection; api/dataconnecthub/v1alpha1/InitDataConnection [source: dc-controller/internal/controller/initdataconnection_controller.go:44, dc-controller/internal/controller/initdataconnection_controller.go:66]
- **controller**: InitDataConnectionTypeReconciler —watches-reference→ api/dataconnecthub/v1alpha1/InitDataConnectionType; api/dataconnecthub/v1alpha1/InitDataConnectionType [source: dc-controller/internal/controller/dataconnectservice_controller.go:608, dc-controller/internal/controller/initdataconnectiontype_controller.go:150]
- **controller**: SecretWatcherReconciler —watches-reference→ /v1/Secret; /v1/Secret [source: dc-controller/internal/controller/dataconnectservice_controller.go:719, dc-controller/internal/controller/secret_watcher_controller.go:167]

## Behavioral Evidence

- **conditional-metrics-enforcement (unresolved)** controller-runtime metrics: controller-runtime metrics serving surface; limitations=The controller-runtime manager Metrics binding does not use one direct lexical options object with a stable SecureServing condition [source: dc-controller/cmd/main.go:170-170]
- **named-watch-predicate (unresolved)** internal/controller.DataConnectServiceReconciler: /v1/ConfigMap; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: dc-controller/internal/controller/dataconnectservice_controller.go:1095-1099]

## Gap Evidence Index

### authentication

- **Question:** How is this runtime security control wired to the serving surface?
  **Expected signal:** flag/default, certificate, middleware, or enforcement point
  **Candidate:** `dc-controller/cmd/main.go`:151 (controller-runtime metrics, controller-runtime metrics authn/authz filter)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `dc-controller/cmd/main.go`:151 (:8443/metrics, TokenReview + SubjectAccessReview (controller-runtime authn/authz filter))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Under which configuration branch does the metrics serving surface install authentication and authorization?
  **Expected signal:** a direct SecureServing condition and controller-runtime authn/authz FilterProvider assignment
  **Candidate:** `dc-controller/cmd/main.go`:170-170 (controller-runtime metrics, controller-runtime metrics serving surface)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `dc-controller/cmd/main.go`:270 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `dc-controller/cmd/main.go`:274 (:8081/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `services/rest/src/main.rs`:59 (/api/v1/*, /api/v2/*, Header passthrough)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `services/rest/src/main.rs`:59 (/health, /info, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `dc-controller/config/rbac/dataconnecthub_admin_role.yaml`:8 (dataconnecthub-admin-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `dc-controller/config/rbac/dataconnecthub_admin_role.yaml`:8 (dc-controller-dataconnecthub-admin-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `dc-controller/config/rbac/dataconnecthub_editor_role.yaml`:8 (dataconnecthub-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `dc-controller/config/rbac/dataconnecthub_editor_role.yaml`:8 (dc-controller-dataconnecthub-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `dc-controller/config/rbac/dataconnecthub_viewer_role.yaml`:8 (dataconnecthub-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `dc-controller/config/rbac/dataconnecthub_viewer_role.yaml`:8 (dc-controller-dataconnecthub-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `dc-controller/config/rbac/metrics_auth_role.yaml`:1 (dc-controller-metrics-auth-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `dc-controller/config/rbac/metrics_auth_role.yaml`:1 (metrics-auth-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `dc-controller/config/rbac/metrics_reader_role.yaml`:1 (dc-controller-metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `dc-controller/config/rbac/metrics_reader_role.yaml`:1 (metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `dc-controller/config/rbac/role.yaml`:2 (dc-controller-manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `dc-controller/config/rbac/role.yaml`:2 (manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `dc-controller/cmd/main.go`:76 (cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `dc-controller/go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `dc-controller/cmd/main.go`:270 (/healthz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `dc-controller/cmd/main.go`:274 (/readyz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `services/rest/src/main.rs`:55 (/connection-types, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `services/rest/src/main.rs`:56 (/connection-types, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `services/rest/src/main.rs`:57 (/connection-types/{id}, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `services/rest/src/main.rs`:58 (/connection-types/{id}, PATCH)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `services/rest/src/main.rs`:59 (/connection-types/{id}, DELETE)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `services/rest/src/main.rs`:62 (/connections/{id}, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `services/rest/src/main.rs`:64 (/connections/{id}, DELETE)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `services/rest/src/main.rs`:65 (/connections/{id}/exports/secrets/{secret_name}, PUT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `services/rest/src/main.rs`:69 (/connections/{id}/readiness, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `services/rest/src/main.rs`:70 (/connections/{id}/binary, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `dc-controller/config/rbac/role.yaml`:2 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `dc-controller/config/rbac/role.yaml`:2 (CRD Watch, OpenShift Routes)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `dc-controller/config/rbac/role.yaml`:2 (Gateway API, HTTPRoute CRUD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `dc-controller/cmd/main.go`:42 (Go library, odh-platform-utilities)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `dc-controller/config/rbac/role.yaml`:2 (CRD CRUD, Gateway API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `dc-controller/config/rbac/role.yaml`:2 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `dc-controller/internal/controller/configmap_watcher_controller.go`:64 (/v1/ConfigMap, get, list, patch operations by ConfigMapWatcherReconciler, DataConnectServiceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `dc-controller/internal/controller/dataconnectservice_controller.go`:1020 (apps/v1/Deployment, list operations by DataConnectServiceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `dc-controller/internal/controller/dataconnectservice_controller.go`:225 (api/dataconnecthub/v1alpha1/DataConnectService, get, list, update operations by DataConnectServiceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `dc-controller/internal/controller/dataconnectservice_controller.go`:608 (api/dataconnecthub/v1alpha1/InitDataConnectionType, create, get, list, update operations by DataConnectServiceReconciler, InitDataConnectionTypeReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `dc-controller/internal/controller/dataconnectservice_controller.go`:719 (/v1/Secret, get, list, patch operations by DataConnectServiceReconciler, SecretWatcherReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `dc-controller/internal/controller/dataconnectservice_controller.go`:879 (/v1/Ingress, get operations by DataConnectServiceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `dc-controller/internal/controller/initdataconnection_controller.go`:44 (api/dataconnecthub/v1alpha1/InitDataConnection, get operations by InitDataConnectionReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `dc-controller/internal/tls/authorization.go`:29 (config.openshift.io/v1/APIServer, get operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `dc-controller/internal/tls/authorization.go`:29 (APIServer resource read, OpenShift Cluster Configuration)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `dc-controller/internal/controller/configmap_watcher_controller.go`:261 (/v1/ConfigMap, ConfigMapWatcherReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `dc-controller/internal/controller/configmap_watcher_controller.go`:64 (/v1/ConfigMap, get, list, patch operations by ConfigMapWatcherReconciler, DataConnectServiceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `dc-controller/internal/controller/dataconnectservice_controller.go`:1089 (DataConnectServiceReconciler, api/dataconnecthub/v1alpha1/DataConnectService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `dc-controller/internal/controller/dataconnectservice_controller.go`:1090 (DataConnectServiceReconciler, apps/v1/Deployment)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `dc-controller/internal/controller/dataconnectservice_controller.go`:1091 (/v1/Service, DataConnectServiceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `dc-controller/internal/controller/dataconnectservice_controller.go`:1092 (/v1/ConfigMap, DataConnectServiceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `dc-controller/internal/controller/dataconnectservice_controller.go`:1093 (/v1/ServiceAccount, DataConnectServiceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `dc-controller/internal/controller/dataconnectservice_controller.go`:1094 (DataConnectServiceReconciler, networking.k8s.io/v1/NetworkPolicy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `dc-controller/internal/controller/dataconnectservice_controller.go`:1095-1099 (/v1/ConfigMap, internal/controller.DataConnectServiceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `dc-controller/internal/controller/initdataconnection_controller.go`:66 (InitDataConnectionReconciler, api/dataconnecthub/v1alpha1/InitDataConnection)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `dc-controller/internal/controller/initdataconnectiontype_controller.go`:150 (InitDataConnectionTypeReconciler, api/dataconnecthub/v1alpha1/InitDataConnectionType)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `dc-controller/internal/controller/secret_watcher_controller.go`:167 (/v1/Secret, SecretWatcherReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `dc-controller/config/default/manager_metrics_patch.yaml`:1 (dc-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `dc-controller/config/default/metrics_service.yaml`:1 (dc-controller-manager, dc-controller-metrics-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- /api/v1/*, /api/v2/* methods=POST mechanism=Header passthrough enforcement=Application-level filtering policy=Configured headers are forwarded to downstream services [source: services/rest/src/main.rs:59]
- /health, /info methods=GET mechanism=None enforcement=None policy=Unauthenticated health server [source: services/rest/src/main.rs:59]
- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: dc-controller/cmd/main.go:270]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: dc-controller/cmd/main.go:274]
- :8443/metrics methods=GET mechanism=TokenReview + SubjectAccessReview (controller-runtime authn/authz filter) enforcement=controller-runtime metrics authn/authz filter policy=RBAC via dc-controller-manager-role; exposed by Service dc-controller-metrics-service; controller-runtime generated self-signed TLS certificate [source: dc-controller/cmd/main.go:151]
### http_endpoints

- DELETE /connection-types/{id} on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: services/rest/src/main.rs:59]
- DELETE /connections/{id} on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: services/rest/src/main.rs:64]
- DELETE /flights/{id} on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: services/rest/src/main.rs:73]
- GET /connection-types on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: services/rest/src/main.rs:55]
- GET /connection-types/{id} on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: services/rest/src/main.rs:57]
- GET /connections on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: services/rest/src/main.rs:60]
- GET /connections/{id} on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: services/rest/src/main.rs:62]
- GET /connections/{id}/binary on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: services/rest/src/main.rs:70]
- GET /health on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: services/rest/src/main.rs:50]
- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: dc-controller/cmd/main.go:270]
- GET /metrics on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: services/flight/src/flight/metrics.rs:123]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: dc-controller/cmd/main.go:274]
- PATCH /connection-types/{id} on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: services/rest/src/main.rs:58]
- PATCH /connections/{id} on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: services/rest/src/main.rs:63]
- PATCH /flights/{id} on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: services/rest/src/main.rs:74]
- POST /connection-types on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: services/rest/src/main.rs:56]
- POST /connections on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: services/rest/src/main.rs:61]
- POST /connections/{id}/readiness on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: services/rest/src/main.rs:69]
- POST /flights on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: services/rest/src/main.rs:72]
- POST /test/credentials on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: services/rest/src/main.rs:71]
- PUT /connections/{id}/exports/secrets/{secret_name} on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: services/rest/src/main.rs:65]
### integrations

- Gateway API interaction=HTTPRoute CRUD role=runtime-transport protocol=HTTPS purpose=Manage Gateway API routing resources [source: dc-controller/config/rbac/role.yaml:2]
- OpenShift Routes interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Dashboard route status [source: dc-controller/config/rbac/role.yaml:2]
- prometheus-operator interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage Prometheus monitoring resources [source: dc-controller/config/rbac/role.yaml:2]
### internal_dependencies

- Gateway API interaction=CRD CRUD role=unknown purpose=Manage Gateway API routing resources [source: dc-controller/config/rbac/role.yaml:2]
- OpenShift Cluster Configuration interaction=APIServer resource read role=runtime-integration purpose=Read cluster-wide API server configuration [source: dc-controller/internal/tls/authorization.go:29]
- odh-platform-utilities interaction=Go library role=runtime-library purpose=Use runtime packages from github.com/opendatahub-io/odh-platform-utilities/framework [source: dc-controller/cmd/main.go:42]
- prometheus-operator interaction=CRD CRUD role=unknown purpose=Manage Prometheus monitoring resources [source: dc-controller/config/rbac/role.yaml:2]
### services

- dc-controller-metrics-service port=8443 target=8443 protocol=TCP encryption= auth= [source: dc-controller/config/default/metrics_service.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload dc-controller-manager uses service account dc-controller-manager and 1 container(s) [source: dc-controller/config/default/manager_metrics_patch.yaml:1]
- **observed**: Service dc-controller-metrics-service targets dc-controller-manager with 1 port(s) [source: dc-controller/config/default/metrics_service.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by cmd [source: dc-controller/cmd/main.go:270]
- **observed**: HTTP GET /readyz is owned by cmd [source: dc-controller/cmd/main.go:274]
### security

- **observed**: GET /health, /info uses None at None; policy=Unauthenticated health server [source: services/rest/src/main.rs:59]
- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: dc-controller/cmd/main.go:270]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: dc-controller/cmd/main.go:274]
- **observed**: GET :8443/metrics uses TokenReview + SubjectAccessReview (controller-runtime authn/authz filter) at controller-runtime metrics authn/authz filter; policy=RBAC via dc-controller-manager-role; exposed by Service dc-controller-metrics-service; controller-runtime generated self-signed TLS certificate [source: dc-controller/cmd/main.go:151]
- **observed**: POST /api/v1/*, /api/v2/* uses Header passthrough at Application-level filtering; policy=Configured headers are forwarded to downstream services [source: services/rest/src/main.rs:59]
- **observed**: RBAC role dataconnecthub-admin-role grants 2 rule(s) [source: dc-controller/config/rbac/dataconnecthub_admin_role.yaml:8]
- **observed**: RBAC role dataconnecthub-editor-role grants 2 rule(s) [source: dc-controller/config/rbac/dataconnecthub_editor_role.yaml:8]
- **observed**: RBAC role dataconnecthub-viewer-role grants 2 rule(s) [source: dc-controller/config/rbac/dataconnecthub_viewer_role.yaml:8]
- **observed**: RBAC role dc-controller-dataconnecthub-admin-role grants 2 rule(s) [source: dc-controller/config/rbac/dataconnecthub_admin_role.yaml:8]
- **observed**: RBAC role dc-controller-dataconnecthub-editor-role grants 2 rule(s) [source: dc-controller/config/rbac/dataconnecthub_editor_role.yaml:8]
- **observed**: RBAC role dc-controller-dataconnecthub-viewer-role grants 2 rule(s) [source: dc-controller/config/rbac/dataconnecthub_viewer_role.yaml:8]
- **observed**: RBAC role dc-controller-leader-election-role grants 3 rule(s) [source: dc-controller/config/rbac/leader_election_role.yaml:2]
- **observed**: RBAC role dc-controller-manager-role grants 16 rule(s) [source: dc-controller/config/rbac/role.yaml:2]
- **observed**: RBAC role dc-controller-metrics-auth-role grants 2 rule(s) [source: dc-controller/config/rbac/metrics_auth_role.yaml:1]
- **observed**: RBAC role dc-controller-metrics-reader grants 1 rule(s) [source: dc-controller/config/rbac/metrics_reader_role.yaml:1]
- **observed**: RBAC role leader-election-role grants 3 rule(s) [source: dc-controller/config/rbac/leader_election_role.yaml:2]
- **observed**: RBAC role manager-role grants 16 rule(s) [source: dc-controller/config/rbac/role.yaml:2]
- **observed**: RBAC role metrics-auth-role grants 2 rule(s) [source: dc-controller/config/rbac/metrics_auth_role.yaml:1]
- **observed**: RBAC role metrics-reader grants 1 rule(s) [source: dc-controller/config/rbac/metrics_reader_role.yaml:1]
- **dependency-signal**: crypto-library targets rustls: Rust TLS dependency is present; the cryptographic provider and FIPS mode require configuration or lockfile verification [source: Cargo.toml:46]
- **dependency-signal**: crypto-library targets tokio-rustls: Rust TLS dependency is present; the cryptographic provider and FIPS mode require configuration or lockfile verification [source: Cargo.toml:46]
- **dependency-signal**: crypto-provider targets aws-lc-rs: Cargo.lock selects this cryptographic provider; FIPS validation depends on build and runtime configuration [source: Cargo.lock:696]
- **dependency-signal**: crypto-provider targets ring: Cargo.lock selects ring as a cryptographic provider; ring is not a FIPS-validated provider [source: Cargo.lock:4394]
- **not-extracted**: fips-posture targets FIPS validation: FIPS validation and runtime provider selection are not fully determined by static dependency/build signals [source: Cargo.toml:46]
- **literal**: rbac-ref targets resolveTokenReviewAudiences: Token or subject access review call [source: dc-controller/internal/controller/dataconnectservice_controller.go:495]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: dc-controller/internal/controller/resources.go, dc-controller/internal/controller/restclient.go, dc-controller/internal/tls/profile.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
