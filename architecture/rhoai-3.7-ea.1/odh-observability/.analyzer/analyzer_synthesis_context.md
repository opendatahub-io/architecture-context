# Analyzer Synthesis Context: odh-observability

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 1 crds facts extracted [source: charts/odh-observability/crds/services.platform.opendatahub.io_monitorings.yaml:2]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 2 http_endpoints facts extracted [source: cmd/main.go:203, cmd/main.go:207]
- **services (observed)**: 10 services facts extracted [source: internal/controller/resources/collector-monitor-service.tmpl.yaml:5, internal/controller/resources/collector-prometheus-service.tmpl.yaml:5, internal/controller/resources/data-science-prometheus-cluster-proxy.tmpl.yaml:170, internal/controller/resources/data-science-prometheus-namespace-proxy.tmpl.yaml:249, internal/controller/resources/data-science-prometheus-service-override.tmpl.yaml:2, internal/controller/resources/data-science-thanos-querier-proxy.tmpl.yaml:199, internal/controller/resources/korrel8r-deployment.tmpl.yaml:88, internal/controller/resources/prometheus-web-tls-service.tmpl.yaml:23, tests/e2e/prerequisites/inference/lgtm.yaml:106, tests/e2e/prerequisites/inference/lgtm.yaml:55]
- **ingress (observed)**: 4 ingress facts extracted [source: internal/controller/resources/data-science-prometheus-cluster-proxy.tmpl.yaml:190, internal/controller/resources/data-science-prometheus-route.tmpl.yaml:1, internal/controller/resources/thanos-querier-route.tmpl.yaml:1, tests/e2e/prerequisites/inference/lgtm.yaml:177]
- **webhooks (observed)**: 1 webhooks facts extracted [source: internal/webhook/mutating.go:55, internal/webhook/mutating.go:56]

## Deterministic Cross-References

- **controller**: MonitoringReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: internal/controller/monitoring_reconciler.go:1086, internal/controller/monitoring_reconciler.go:1281]
- **controller**: MonitoringReconciler —watches-reference→ /v1/Namespace; /v1/Namespace [source: internal/controller/helpers.go:119, internal/controller/monitoring_reconciler.go:1298]
- **controller**: MonitoringReconciler —watches-reference→ /v1/Secret; /v1/Secret [source: internal/controller/actions.go:614, internal/controller/monitoring_reconciler.go:1283]
- **controller**: MonitoringReconciler —watches-reference→ /v1/Service; /v1/Service [source: internal/controller/actions.go:1451, internal/controller/monitoring_reconciler.go:1294]
- **controller**: MonitoringReconciler —watches-reference→ api/v1alpha1/Monitoring; api/v1alpha1/Monitoring [source: internal/controller/monitoring_reconciler.go:1272, internal/controller/monitoring_reconciler.go:200]
- **controller**: MonitoringReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: internal/controller/actions.go:1436, internal/controller/monitoring_reconciler.go:1279]
- **controller**: MonitoringReconciler —watches-reference→ discovery/v1/EndpointSlice; discovery/v1/EndpointSlice [source: internal/controller/actions.go:1459, internal/controller/monitoring_reconciler.go:1295]
- **controller**: MonitoringReconciler —watches-reference→ networking.k8s.io/v1/NetworkPolicy; networking.k8s.io/v1/NetworkPolicy [source: internal/controller/monitoring_reconciler.go:1278, internal/controller/monitoring_reconciler.go:523]
- **controller**: MonitoringReconciler —watches-reference→ rbac.authorization.k8s.io/v1/ClusterRole; rbac.authorization.k8s.io/v1/ClusterRole [source: internal/controller/monitoring_reconciler.go:1276, internal/controller/monitoring_reconciler.go:855]
- **controller**: MonitoringReconciler —watches-reference→ rbac.authorization.k8s.io/v1/ClusterRoleBinding; rbac.authorization.k8s.io/v1/ClusterRoleBinding [source: internal/controller/monitoring_reconciler.go:1277, internal/controller/monitoring_reconciler.go:873]
- **controller**: MonitoringReconciler —watches-reference→ rbac.authorization.k8s.io/v1/Role; rbac.authorization.k8s.io/v1/Role [source: internal/controller/monitoring_reconciler.go:1274, internal/controller/monitoring_reconciler.go:936]
- **controller**: MonitoringReconciler —watches-reference→ rbac.authorization.k8s.io/v1/RoleBinding; rbac.authorization.k8s.io/v1/RoleBinding [source: internal/controller/monitoring_reconciler.go:1275, internal/controller/monitoring_reconciler.go:957]
- **controller**: MonitoringReconciler —watches-reference→ route.openshift.io/v1/Route; route.openshift.io/v1/Route [source: internal/controller/helpers.go:304, internal/controller/monitoring_reconciler.go:1299]

## Behavioral Evidence

- **named-watch-predicate (unresolved)** internal/controller.MonitoringReconciler: rbac.authorization.k8s.io/v1/Role; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/monitoring_reconciler.go:1274-1274]
- **named-watch-predicate (unresolved)** internal/controller.MonitoringReconciler: rbac.authorization.k8s.io/v1/RoleBinding; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/monitoring_reconciler.go:1275-1275]
- **named-watch-predicate (unresolved)** internal/controller.MonitoringReconciler: rbac.authorization.k8s.io/v1/ClusterRole; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/monitoring_reconciler.go:1276-1276]
- **named-watch-predicate (unresolved)** internal/controller.MonitoringReconciler: rbac.authorization.k8s.io/v1/ClusterRoleBinding; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/monitoring_reconciler.go:1277-1277]
- **named-watch-predicate (unresolved)** internal/controller.MonitoringReconciler: networking.k8s.io/v1/NetworkPolicy; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/monitoring_reconciler.go:1278-1278]
- **named-watch-predicate (unresolved)** internal/controller.MonitoringReconciler: apps/v1/Deployment; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/monitoring_reconciler.go:1279-1279]
- **named-watch-predicate (unresolved)** internal/controller.MonitoringReconciler: batch/v1/Job; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/monitoring_reconciler.go:1280-1280]
- **named-watch-predicate (unresolved)** internal/controller.MonitoringReconciler: /v1/ConfigMap; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/monitoring_reconciler.go:1281-1281]
- **named-watch-predicate (unresolved)** internal/controller.MonitoringReconciler: /v1/ConfigMap; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/monitoring_reconciler.go:1282-1282]
- **named-watch-predicate (unresolved)** internal/controller.MonitoringReconciler: /v1/Secret; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/monitoring_reconciler.go:1283-1283]
- **named-watch-predicate (unresolved)** internal/controller.MonitoringReconciler: /v1/Secret; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/monitoring_reconciler.go:1284-1284]
- **named-watch-predicate (unresolved)** internal/controller.MonitoringReconciler: /v1/Secret; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/monitoring_reconciler.go:1291-1293]
- **named-watch-predicate (unresolved)** internal/controller.MonitoringReconciler: /v1/Service; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/monitoring_reconciler.go:1294-1294]
- **named-watch-predicate (unresolved)** internal/controller.MonitoringReconciler: discovery/v1/EndpointSlice; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/monitoring_reconciler.go:1295-1295]
- **named-watch-predicate (unresolved)** internal/controller.MonitoringReconciler: /v1/ServiceAccount; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/monitoring_reconciler.go:1296-1296]
- **named-watch-predicate (unresolved)** internal/controller.MonitoringReconciler: /v1/Namespace; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/monitoring_reconciler.go:1298-1298]
- 2 additional behavioral records remain in the analyzer JSON.

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/main.go`:167 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/main.go`:203 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/main.go`:207 (:8081/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `internal/controller/resources/cluster-log-forwarder-rbac.tmpl.yaml`:10 (collect-application-logs, {template-value}-collect-app-logs)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `internal/controller/resources/cluster-log-forwarder-rbac.tmpl.yaml`:25 (cluster-logging-write-application-logs, {template-value}-loki-writer)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `internal/controller/resources/collector-mlflow-rbac.tmpl.yaml`:1 (data-science-collector-mlflow-trace-export)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `internal/controller/resources/collector-mlflow-rbac.tmpl.yaml`:13 (data-science-collector-mlflow-trace-export)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `internal/controller/resources/collector-rbac.tmpl.yaml`:166 (data-science-collector-targetallocator-secrets)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `internal/controller/resources/collector-rbac.tmpl.yaml`:55 (generate-processors-collector-rolebinding, generate-processors-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `internal/controller/resources/collector-rbac.tmpl.yaml`:85 (generate-processors-targetallocator-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `internal/controller/resources/collector-rbac.tmpl.yaml`:9 (generate-processors-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `internal/controller/resources/collector-tempo-rbac.tmpl.yaml`:1 (data-science-collector-tempo-trace-export)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `internal/controller/resources/korrel8r-rbac.tmpl.yaml`:9 ({template-value}-query)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `internal/controller/resources/usage-logs-opentelemetry-collector-rbac.tmpl.yaml`:2 ({template-value}-processor)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `tests/e2e/prerequisites/inference/lgtm.yaml`:93 (oauth-proxy-lgtm-auth-delegator, system:auth-delegator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:28 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfiles/Dockerfile.konflux`:27 (Dockerfiles/Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/main.go`:84 (cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/main.go`:166 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/main.go`:167 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/main.go`:203 (/healthz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/main.go`:207 (/readyz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `internal/controller/resources/collector-rbac.tmpl.yaml`:85 (API client, Kubernetes API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `internal/controller/resources/collector-rbac.tmpl.yaml`:9 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `api/v1alpha1/monitoring_types.go`:20 (Go library, odh-platform-utilities)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `go.mod` (Go Library, odh-platform-utilities)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/actions.go`:1436 (apps/v1/Deployment, get operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/actions.go`:1451 (/v1/Service, get operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/actions.go`:1459 (discovery/v1/EndpointSlice, list operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/actions.go`:614 (/v1/Secret, delete, get operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/helpers.go`:119 (/v1/Namespace, get, list operations by AdmissionProbe, Injector)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/monitoring_reconciler.go`:1086 (/v1/ConfigMap, get operations by MonitoringReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/monitoring_reconciler.go`:200 (api/v1alpha1/Monitoring, get, patch operations by MonitoringReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/monitoring_reconciler.go`:523 (delete, get operations by MonitoringReconciler, networking.k8s.io/v1/NetworkPolicy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `internal/controller/resources/collector-rbac.tmpl.yaml`:85 (Kubernetes API (nodes), list)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `internal/controller/resources/collector-rbac.tmpl.yaml`:9 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/monitoring_reconciler.go`:1274-1274 (internal/controller.MonitoringReconciler, rbac.authorization.k8s.io/v1/Role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/monitoring_reconciler.go`:1275-1275 (internal/controller.MonitoringReconciler, rbac.authorization.k8s.io/v1/RoleBinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/monitoring_reconciler.go`:1276-1276 (internal/controller.MonitoringReconciler, rbac.authorization.k8s.io/v1/ClusterRole)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/monitoring_reconciler.go`:1277-1277 (internal/controller.MonitoringReconciler, rbac.authorization.k8s.io/v1/ClusterRoleBinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/monitoring_reconciler.go`:1278-1278 (internal/controller.MonitoringReconciler, networking.k8s.io/v1/NetworkPolicy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/monitoring_reconciler.go`:1279-1279 (apps/v1/Deployment, internal/controller.MonitoringReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/monitoring_reconciler.go`:1280-1280 (batch/v1/Job, internal/controller.MonitoringReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/monitoring_reconciler.go`:1281-1281 (/v1/ConfigMap, internal/controller.MonitoringReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/monitoring_reconciler.go`:1282-1282 (/v1/ConfigMap, internal/controller.MonitoringReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/monitoring_reconciler.go`:1283-1283 (/v1/Secret, internal/controller.MonitoringReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/monitoring_reconciler.go`:1284-1284 (/v1/Secret, internal/controller.MonitoringReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/monitoring_reconciler.go`:1291-1293 (/v1/Secret, internal/controller.MonitoringReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- 6 additional gap candidates remain in the analyzer JSON.
### services

- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `internal/controller/resources/collector-monitor-service.tmpl.yaml`:5 (data-science-collector-monitoring)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `internal/controller/resources/collector-prometheus-service.tmpl.yaml`:5 (data-science-collector-prometheus)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `internal/controller/resources/data-science-prometheus-cluster-proxy.tmpl.yaml`:170 (data-science-prometheus-cluster-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `internal/controller/resources/data-science-prometheus-namespace-proxy.tmpl.yaml`:249 (data-science-prometheus-namespace-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `internal/controller/resources/data-science-prometheus-service-override.tmpl.yaml`:2 (data-science-prometheus-namespace-proxy, data-science-prometheus-namespace-proxy-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `internal/controller/resources/data-science-thanos-querier-proxy.tmpl.yaml`:199 (data-science-thanos-querier-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `internal/controller/resources/korrel8r-deployment.tmpl.yaml`:88 ({template-value})
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `internal/controller/resources/prometheus-web-tls-service.tmpl.yaml`:23 (prometheus-operated)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `tests/e2e/prerequisites/inference/lgtm.yaml`:1 (lgtm)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `tests/e2e/prerequisites/inference/lgtm.yaml`:106 (oauth-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `tests/e2e/prerequisites/inference/lgtm.yaml`:124 (oauth-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `tests/e2e/prerequisites/inference/lgtm.yaml`:55 (lgtm)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### webhooks

- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/mutating.go`:55 (/mutate-prometheus-monitors, podmonitor-injector.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/mutating.go`:56 (/mutate-prometheus-monitors, podmonitor-injector.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: cmd/main.go:203]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/main.go:207]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via generate-processors-role ClusterRole; SA {template-value} [source: cmd/main.go:167]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/main.go:203]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/main.go:207]
### integrations

- Kubernetes API interaction=API client role=runtime-integration protocol=HTTPS purpose=Cluster resource management via RBAC [source: internal/controller/resources/collector-rbac.tmpl.yaml:85]
- prometheus-operator interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage Prometheus monitoring resources [source: internal/controller/resources/collector-rbac.tmpl.yaml:9]
### internal_dependencies

- Kubernetes API (nodes) interaction=list role=unknown purpose=nodes resource access via RBAC [source: internal/controller/resources/collector-rbac.tmpl.yaml:85]
- odh-platform-utilities interaction=Go Library role=runtime-library purpose=Platform detection, manifest rendering, and deployment helpers [source: go.mod]
- odh-platform-utilities interaction=Go library role=runtime-library purpose=Use runtime packages from github.com/opendatahub-io/odh-platform-utilities [source: api/v1alpha1/monitoring_types.go:20]
- prometheus-operator interaction=CRD CRUD role=unknown purpose=Manage Prometheus monitoring resources [source: internal/controller/resources/collector-rbac.tmpl.yaml:9]
### services

- data-science-collector-monitoring port=8890 target=8890 protocol=TCP encryption= auth= [source: internal/controller/resources/collector-monitor-service.tmpl.yaml:5]
- data-science-collector-prometheus port=8889 target=8889 protocol=TCP encryption= auth= [source: internal/controller/resources/collector-prometheus-service.tmpl.yaml:5]
- data-science-prometheus-cluster-proxy port=8443 target=https protocol=TCP encryption= auth= [source: internal/controller/resources/data-science-prometheus-cluster-proxy.tmpl.yaml:170]
- data-science-prometheus-namespace-proxy port=8443 target=https protocol=TCP encryption= auth= [source: internal/controller/resources/data-science-prometheus-namespace-proxy.tmpl.yaml:249]
- data-science-prometheus-namespace-proxy-service port=9090 target=https protocol=TCP encryption= auth= [source: internal/controller/resources/data-science-prometheus-service-override.tmpl.yaml:2]
- data-science-thanos-querier-proxy port=8443 target=https protocol=TCP encryption= auth= [source: internal/controller/resources/data-science-thanos-querier-proxy.tmpl.yaml:199]
- lgtm port=3000 target=3000 protocol=TCP encryption= auth= [source: tests/e2e/prerequisites/inference/lgtm.yaml:55]
- lgtm port=3200 target=3200 protocol=TCP encryption= auth= [source: tests/e2e/prerequisites/inference/lgtm.yaml:55]
- lgtm port=4317 target=4317 protocol=TCP encryption= auth= [source: tests/e2e/prerequisites/inference/lgtm.yaml:55]
- lgtm port=4318 target=4318 protocol=TCP encryption= auth= [source: tests/e2e/prerequisites/inference/lgtm.yaml:55]
- oauth-proxy port=8443 target=8443 protocol=TCP encryption= auth= [source: tests/e2e/prerequisites/inference/lgtm.yaml:106]
- prometheus-operated port=9090 target=web protocol=TCP encryption= auth= [source: internal/controller/resources/prometheus-web-tls-service.tmpl.yaml:23]
- {template-value} port=8443 target=https protocol=TCP encryption= auth= [source: internal/controller/resources/korrel8r-deployment.tmpl.yaml:88]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Controller-created Deployment workload data-science-prometheus-cluster-proxy uses service account data-science-prometheus-cluster-proxy and 1 container(s) [source: internal/controller/resources/data-science-prometheus-cluster-proxy.tmpl.yaml:58]
- **observed**: Controller-created Deployment workload data-science-prometheus-namespace-proxy uses service account data-science-prometheus-namespace-proxy and 3 container(s) [source: internal/controller/resources/data-science-prometheus-namespace-proxy.tmpl.yaml:94]
- **observed**: Controller-created Deployment workload data-science-thanos-querier-proxy uses service account data-science-thanos-querier-proxy and 3 container(s) [source: internal/controller/resources/data-science-thanos-querier-proxy.tmpl.yaml:68]
- **observed**: Controller-created Deployment workload {template-value} uses service account {template-value} and 1 container(s) [source: internal/controller/resources/korrel8r-deployment.tmpl.yaml:1]
- **observed**: Deployment workload lgtm uses service account  and 1 container(s) [source: tests/e2e/prerequisites/inference/lgtm.yaml:1]
- **observed**: Deployment workload oauth-proxy uses service account oauth-proxy and 1 container(s) [source: tests/e2e/prerequisites/inference/lgtm.yaml:124]
- **observed**: Service data-science-collector-monitoring targets  with 1 port(s) [source: internal/controller/resources/collector-monitor-service.tmpl.yaml:5]
- **observed**: Service data-science-collector-prometheus targets  with 1 port(s) [source: internal/controller/resources/collector-prometheus-service.tmpl.yaml:5]
- **observed**: Service data-science-prometheus-cluster-proxy targets data-science-prometheus-cluster-proxy with 1 port(s) [source: internal/controller/resources/data-science-prometheus-cluster-proxy.tmpl.yaml:170]
- **observed**: Service data-science-prometheus-namespace-proxy targets data-science-prometheus-namespace-proxy with 1 port(s) [source: internal/controller/resources/data-science-prometheus-namespace-proxy.tmpl.yaml:249]
- **observed**: Service data-science-prometheus-namespace-proxy-service targets data-science-prometheus-namespace-proxy with 1 port(s) [source: internal/controller/resources/data-science-prometheus-service-override.tmpl.yaml:2]
- **observed**: Service data-science-thanos-querier-proxy targets data-science-thanos-querier-proxy with 1 port(s) [source: internal/controller/resources/data-science-thanos-querier-proxy.tmpl.yaml:199]
- **observed**: Service lgtm targets lgtm with 4 port(s) [source: tests/e2e/prerequisites/inference/lgtm.yaml:55]
- **observed**: Service oauth-proxy targets oauth-proxy with 1 port(s) [source: tests/e2e/prerequisites/inference/lgtm.yaml:106]
- **observed**: Service prometheus-operated targets  with 1 port(s) [source: internal/controller/resources/prometheus-web-tls-service.tmpl.yaml:23]
- **observed**: Service {template-value} targets {template-value} with 1 port(s) [source: internal/controller/resources/korrel8r-deployment.tmpl.yaml:88]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by cmd [source: cmd/main.go:203]
- **observed**: HTTP GET /readyz is owned by cmd [source: cmd/main.go:207]
- **observed**: Route data-science-prometheus-cluster-proxy serves host  via TLS; backend=data-science-prometheus-cluster-proxy; transport=HTTPS [source: internal/controller/resources/data-science-prometheus-cluster-proxy.tmpl.yaml:190]
- **observed**: Route data-science-prometheus-route serves host  via TLS; backend=data-science-prometheus-namespace-proxy; transport=HTTPS [source: internal/controller/resources/data-science-prometheus-route.tmpl.yaml:1]
- **observed**: Route data-science-thanos-querier-route serves host  via TLS; backend=data-science-thanos-querier-proxy; transport=HTTPS [source: internal/controller/resources/thanos-querier-route.tmpl.yaml:1]
- **observed**: Route lgtm serves host  via TLS; backend=oauth-proxy; transport=HTTPS [source: tests/e2e/prerequisites/inference/lgtm.yaml:177]
### security

- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: cmd/main.go:203]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/main.go:207]
- **observed**: RBAC role data-science-collector-mlflow-trace-export grants 1 rule(s) [source: internal/controller/resources/collector-mlflow-rbac.tmpl.yaml:1]
- **observed**: RBAC role data-science-collector-targetallocator-secrets grants 1 rule(s) [source: internal/controller/resources/collector-rbac.tmpl.yaml:166]
- **observed**: RBAC role data-science-collector-tempo-trace-export grants 1 rule(s) [source: internal/controller/resources/collector-tempo-rbac.tmpl.yaml:1]
- **observed**: RBAC role generate-processors-role grants 4 rule(s) [source: internal/controller/resources/collector-rbac.tmpl.yaml:9]
- **observed**: RBAC role generate-processors-targetallocator-role grants 7 rule(s) [source: internal/controller/resources/collector-rbac.tmpl.yaml:85]
- **observed**: RBAC role {template-value}-processor grants 3 rule(s) [source: internal/controller/resources/usage-logs-opentelemetry-collector-rbac.tmpl.yaml:2]
- **observed**: RBAC role {template-value}-query grants 5 rule(s) [source: internal/controller/resources/korrel8r-rbac.tmpl.yaml:9]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via generate-processors-role ClusterRole; SA {template-value} [source: cmd/main.go:167]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: cmd/tls.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
