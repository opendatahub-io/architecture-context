# Analyzer Synthesis Context: odh-observability

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 1 crds facts extracted [source: charts/odh-observability/crds/services.platform.opendatahub.io_monitorings.yaml:2]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 2 http_endpoints facts extracted [source: cmd/main.go:142, cmd/main.go:146]
- **services (observed)**: 10 services facts extracted [source: internal/controller/resources/collector-monitor-service.tmpl.yaml:5, internal/controller/resources/collector-prometheus-service.tmpl.yaml:5, internal/controller/resources/data-science-prometheus-cluster-proxy.tmpl.yaml:167, internal/controller/resources/data-science-prometheus-namespace-proxy.tmpl.yaml:204, internal/controller/resources/data-science-prometheus-service-override.tmpl.yaml:2, internal/controller/resources/korrel8r-deployment.tmpl.yaml:88, internal/controller/resources/prometheus-web-tls-service.tmpl.yaml:23, internal/controller/resources/webhook-service.tmpl.yaml:1, tests/e2e/prerequisites/inference/lgtm.yaml:48, tests/e2e/prerequisites/inference/lgtm.yaml:95]
- **ingress (observed)**: 4 ingress facts extracted [source: internal/controller/resources/data-science-prometheus-cluster-proxy.tmpl.yaml:187, internal/controller/resources/data-science-prometheus-route.tmpl.yaml:1, internal/controller/resources/thanos-querier-route.tmpl.yaml:1, tests/e2e/prerequisites/inference/lgtm.yaml:166]
- **webhooks (observed)**: 3 webhooks facts extracted [source: internal/controller/resources/webhook-configuration.tmpl.yaml:1, internal/webhook/mutating.go:55, internal/webhook/mutating.go:56]

## Deterministic Cross-References

- **controller**: MonitoringReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: internal/controller/monitoring_reconciler.go:537, internal/controller/monitoring_reconciler.go:629]
- **controller**: MonitoringReconciler —watches-reference→ /v1/Namespace; /v1/Namespace [source: internal/controller/helpers.go:116, internal/controller/monitoring_reconciler.go:636]
- **controller**: MonitoringReconciler —watches-reference→ /v1/Secret; /v1/Secret [source: internal/controller/actions.go:760, internal/controller/monitoring_reconciler.go:631]
- **controller**: MonitoringReconciler —watches-reference→ /v1/Service; /v1/Service [source: internal/controller/actions.go:718, internal/controller/monitoring_reconciler.go:632]
- **controller**: MonitoringReconciler —watches-reference→ api/v1alpha1/Monitoring; api/v1alpha1/Monitoring [source: internal/controller/monitoring_reconciler.go:122, internal/controller/monitoring_reconciler.go:620]
- **controller**: MonitoringReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: internal/controller/actions.go:703, internal/controller/monitoring_reconciler.go:627]
- **controller**: MonitoringReconciler —watches-reference→ config.openshift.io/v1/APIServer; config.openshift.io/v1/APIServer [source: internal/controller/monitoring_reconciler.go:641, pkg/tls/profile.go:153]
- **controller**: MonitoringReconciler —watches-reference→ discovery/v1/EndpointSlice; discovery/v1/EndpointSlice [source: internal/controller/actions.go:726, internal/controller/monitoring_reconciler.go:633]
- **controller**: MonitoringReconciler —watches-reference→ route.openshift.io/v1/Route; route.openshift.io/v1/Route [source: internal/controller/helpers.go:267, internal/controller/monitoring_reconciler.go:637]
- **webhook**: podmonitor-injector.opendatahub.io —served-by→ {template-value}-webhook; admission webhook declares an explicit service reference [source: internal/controller/resources/webhook-configuration.tmpl.yaml:1, internal/controller/resources/webhook-service.tmpl.yaml:1]
- **webhook**: servicemonitor-injector.opendatahub.io —served-by→ {template-value}-webhook; admission webhook declares an explicit service reference [source: internal/controller/resources/webhook-configuration.tmpl.yaml:1, internal/controller/resources/webhook-service.tmpl.yaml:1]

## Behavioral Evidence

- **named-watch-predicate (unresolved)** internal/controller.MonitoringReconciler: rbac.authorization.k8s.io/v1/Role; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/monitoring_reconciler.go:622-622]
- **named-watch-predicate (unresolved)** internal/controller.MonitoringReconciler: rbac.authorization.k8s.io/v1/RoleBinding; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/monitoring_reconciler.go:623-623]
- **named-watch-predicate (unresolved)** internal/controller.MonitoringReconciler: rbac.authorization.k8s.io/v1/ClusterRole; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/monitoring_reconciler.go:624-624]
- **named-watch-predicate (unresolved)** internal/controller.MonitoringReconciler: rbac.authorization.k8s.io/v1/ClusterRoleBinding; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/monitoring_reconciler.go:625-625]
- **named-watch-predicate (unresolved)** internal/controller.MonitoringReconciler: networking.k8s.io/v1/NetworkPolicy; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/monitoring_reconciler.go:626-626]
- **named-watch-predicate (unresolved)** internal/controller.MonitoringReconciler: apps/v1/Deployment; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/monitoring_reconciler.go:627-627]
- **named-watch-predicate (unresolved)** internal/controller.MonitoringReconciler: batch/v1/Job; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/monitoring_reconciler.go:628-628]
- **named-watch-predicate (unresolved)** internal/controller.MonitoringReconciler: /v1/ConfigMap; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/monitoring_reconciler.go:629-629]
- **named-watch-predicate (unresolved)** internal/controller.MonitoringReconciler: /v1/ConfigMap; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/monitoring_reconciler.go:630-630]
- **named-watch-predicate (unresolved)** internal/controller.MonitoringReconciler: /v1/Secret; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/monitoring_reconciler.go:631-631]
- **named-watch-predicate (unresolved)** internal/controller.MonitoringReconciler: /v1/Service; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/monitoring_reconciler.go:632-632]
- **named-watch-predicate (unresolved)** internal/controller.MonitoringReconciler: discovery/v1/EndpointSlice; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/monitoring_reconciler.go:633-633]
- **named-watch-predicate (unresolved)** internal/controller.MonitoringReconciler: /v1/ServiceAccount; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/monitoring_reconciler.go:634-634]
- **named-watch-predicate (unresolved)** internal/controller.MonitoringReconciler: /v1/Namespace; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/monitoring_reconciler.go:636-636]
- **named-watch-predicate (unresolved)** internal/controller.MonitoringReconciler: route.openshift.io/v1/Route; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/monitoring_reconciler.go:637-637]
- **named-watch-predicate (unresolved)** internal/controller.MonitoringReconciler: config.openshift.io/v1/APIServer; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/monitoring_reconciler.go:641-641]

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/main.go`:118 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/main.go`:142 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/main.go`:146 (:8081/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `internal/controller/resources/cluster-log-forwarder-rbac.tmpl.yaml`:21 (cluster-logging-write-application-logs, {template-value}-loki-writer)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `internal/controller/resources/cluster-log-forwarder-rbac.tmpl.yaml`:8 (collect-application-logs, {template-value}-collect-app-logs)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `internal/controller/resources/collector-mlflow-rbac.tmpl.yaml`:1 (data-science-collector-mlflow-trace-export)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `internal/controller/resources/collector-mlflow-rbac.tmpl.yaml`:13 (data-science-collector-mlflow-trace-export)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `internal/controller/resources/collector-rbac.tmpl.yaml`:55 (generate-processors-collector-rolebinding, generate-processors-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `internal/controller/resources/collector-rbac.tmpl.yaml`:83 (data-science-collector-targetallocator-secrets)
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
  **Candidate:** `internal/controller/resources/data-science-prometheus-namespace-proxy.tmpl.yaml`:9 (data-science-metrics-view)
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
  **Candidate:** `tests/e2e/prerequisites/inference/lgtm.yaml`:82 (oauth-proxy-lgtm-auth-delegator, system:auth-delegator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:29 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfiles/Dockerfile.konflux`:28 (Dockerfiles/Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/main.go`:62 (cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/main.go`:117 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/main.go`:118 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/main.go`:142 (/healthz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/main.go`:146 (/readyz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

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
  **Candidate:** `internal/controller/actions.go`:703 (apps/v1/Deployment, get operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/actions.go`:718 (/v1/Service, get operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/actions.go`:726 (discovery/v1/EndpointSlice, list operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/actions.go`:760 (/v1/Secret, get operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/helpers.go`:116 (/v1/Namespace, get, list operations by Injector)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/monitoring_reconciler.go`:122 (api/v1alpha1/Monitoring, get, patch operations by MonitoringReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/monitoring_reconciler.go`:537 (/v1/ConfigMap, get operations by MonitoringReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `internal/controller/resources/collector-rbac.tmpl.yaml`:9 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/tls/profile.go`:153 (config.openshift.io/v1/APIServer, get operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/tls/profile.go`:153 (APIServer resource read, OpenShift Cluster Configuration)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/monitoring_reconciler.go`:622-622 (internal/controller.MonitoringReconciler, rbac.authorization.k8s.io/v1/Role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/monitoring_reconciler.go`:623-623 (internal/controller.MonitoringReconciler, rbac.authorization.k8s.io/v1/RoleBinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/monitoring_reconciler.go`:624-624 (internal/controller.MonitoringReconciler, rbac.authorization.k8s.io/v1/ClusterRole)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/monitoring_reconciler.go`:625-625 (internal/controller.MonitoringReconciler, rbac.authorization.k8s.io/v1/ClusterRoleBinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/monitoring_reconciler.go`:626-626 (internal/controller.MonitoringReconciler, networking.k8s.io/v1/NetworkPolicy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/monitoring_reconciler.go`:627-627 (apps/v1/Deployment, internal/controller.MonitoringReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/monitoring_reconciler.go`:628-628 (batch/v1/Job, internal/controller.MonitoringReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/monitoring_reconciler.go`:629-629 (/v1/ConfigMap, internal/controller.MonitoringReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/monitoring_reconciler.go`:630-630 (/v1/ConfigMap, internal/controller.MonitoringReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/monitoring_reconciler.go`:631-631 (/v1/Secret, internal/controller.MonitoringReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/monitoring_reconciler.go`:632-632 (/v1/Service, internal/controller.MonitoringReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/monitoring_reconciler.go`:633-633 (discovery/v1/EndpointSlice, internal/controller.MonitoringReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- 4 additional gap candidates remain in the analyzer JSON.
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
  **Candidate:** `internal/controller/resources/data-science-prometheus-cluster-proxy.tmpl.yaml`:167 (data-science-prometheus-cluster-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `internal/controller/resources/data-science-prometheus-namespace-proxy.tmpl.yaml`:204 (data-science-prometheus-namespace-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `internal/controller/resources/data-science-prometheus-service-override.tmpl.yaml`:2 (data-science-prometheus-namespace-proxy, data-science-prometheus-namespace-proxy-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `internal/controller/resources/korrel8r-deployment.tmpl.yaml`:88 ({template-value})
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `internal/controller/resources/prometheus-web-tls-service.tmpl.yaml`:23 (prometheus-operated)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `internal/controller/resources/webhook-service.tmpl.yaml`:1 ({template-value}-webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `tests/e2e/prerequisites/inference/lgtm.yaml`:1 (lgtm)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `tests/e2e/prerequisites/inference/lgtm.yaml`:113 (oauth-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `tests/e2e/prerequisites/inference/lgtm.yaml`:48 (lgtm)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `tests/e2e/prerequisites/inference/lgtm.yaml`:95 (oauth-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### webhooks

- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/controller/resources/webhook-configuration.tmpl.yaml`:1 (/mutate-prometheus-monitors, podmonitor-injector.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/controller/resources/webhook-configuration.tmpl.yaml`:1 (/mutate-prometheus-monitors, servicemonitor-injector.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
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

- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: cmd/main.go:142]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/main.go:146]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via generate-processors-role ClusterRole; SA {template-value} [source: cmd/main.go:118]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/main.go:142]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/main.go:146]
### integrations

- prometheus-operator interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage Prometheus monitoring resources [source: internal/controller/resources/collector-rbac.tmpl.yaml:9]
### internal_dependencies

- OpenShift Cluster Configuration interaction=APIServer resource read role=runtime-integration purpose=Read cluster-wide API server configuration [source: pkg/tls/profile.go:153]
- odh-platform-utilities interaction=Go Library role=runtime-library purpose=Platform detection, manifest rendering, and deployment helpers [source: go.mod]
- odh-platform-utilities interaction=Go library role=runtime-library purpose=Use runtime packages from github.com/opendatahub-io/odh-platform-utilities [source: api/v1alpha1/monitoring_types.go:20]
- prometheus-operator interaction=CRD CRUD role=unknown purpose=Manage Prometheus monitoring resources [source: internal/controller/resources/collector-rbac.tmpl.yaml:9]
### services

- data-science-collector-monitoring port=8890 target=8890 protocol=TCP encryption= auth= [source: internal/controller/resources/collector-monitor-service.tmpl.yaml:5]
- data-science-collector-prometheus port=8889 target=8889 protocol=TCP encryption= auth= [source: internal/controller/resources/collector-prometheus-service.tmpl.yaml:5]
- data-science-prometheus-cluster-proxy port=8443 target=https protocol=TCP encryption= auth= [source: internal/controller/resources/data-science-prometheus-cluster-proxy.tmpl.yaml:167]
- data-science-prometheus-namespace-proxy port=8443 target=https protocol=TCP encryption= auth= [source: internal/controller/resources/data-science-prometheus-namespace-proxy.tmpl.yaml:204]
- data-science-prometheus-namespace-proxy-service port=9090 target=https protocol=TCP encryption= auth= [source: internal/controller/resources/data-science-prometheus-service-override.tmpl.yaml:2]
- lgtm port=3000 target=3000 protocol=TCP encryption= auth= [source: tests/e2e/prerequisites/inference/lgtm.yaml:48]
- lgtm port=4317 target=4317 protocol=TCP encryption= auth= [source: tests/e2e/prerequisites/inference/lgtm.yaml:48]
- lgtm port=4318 target=4318 protocol=TCP encryption= auth= [source: tests/e2e/prerequisites/inference/lgtm.yaml:48]
- oauth-proxy port=8443 target=8443 protocol=TCP encryption= auth= [source: tests/e2e/prerequisites/inference/lgtm.yaml:95]
- prometheus-operated port=9090 target=web protocol=TCP encryption= auth= [source: internal/controller/resources/prometheus-web-tls-service.tmpl.yaml:23]
- {template-value} port=8443 target=https protocol=TCP encryption= auth= [source: internal/controller/resources/korrel8r-deployment.tmpl.yaml:88]
- {template-value}-webhook port=9443 target=webhook protocol=TCP encryption= auth= [source: internal/controller/resources/webhook-service.tmpl.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Controller-created Deployment workload data-science-prometheus-cluster-proxy uses service account data-science-prometheus-cluster-proxy and 1 container(s) [source: internal/controller/resources/data-science-prometheus-cluster-proxy.tmpl.yaml:58]
- **observed**: Controller-created Deployment workload data-science-prometheus-namespace-proxy uses service account data-science-prometheus-namespace-proxy and 2 container(s) [source: internal/controller/resources/data-science-prometheus-namespace-proxy.tmpl.yaml:89]
- **observed**: Controller-created Deployment workload {template-value} uses service account {template-value} and 1 container(s) [source: internal/controller/resources/korrel8r-deployment.tmpl.yaml:1]
- **observed**: Deployment workload lgtm uses service account  and 1 container(s) [source: tests/e2e/prerequisites/inference/lgtm.yaml:1]
- **observed**: Deployment workload oauth-proxy uses service account oauth-proxy and 1 container(s) [source: tests/e2e/prerequisites/inference/lgtm.yaml:113]
- **observed**: Service data-science-collector-monitoring targets  with 1 port(s) [source: internal/controller/resources/collector-monitor-service.tmpl.yaml:5]
- **observed**: Service data-science-collector-prometheus targets  with 1 port(s) [source: internal/controller/resources/collector-prometheus-service.tmpl.yaml:5]
- **observed**: Service data-science-prometheus-cluster-proxy targets data-science-prometheus-cluster-proxy with 1 port(s) [source: internal/controller/resources/data-science-prometheus-cluster-proxy.tmpl.yaml:167]
- **observed**: Service data-science-prometheus-namespace-proxy targets data-science-prometheus-namespace-proxy with 1 port(s) [source: internal/controller/resources/data-science-prometheus-namespace-proxy.tmpl.yaml:204]
- **observed**: Service data-science-prometheus-namespace-proxy-service targets data-science-prometheus-namespace-proxy with 1 port(s) [source: internal/controller/resources/data-science-prometheus-service-override.tmpl.yaml:2]
- **observed**: Service lgtm targets lgtm with 3 port(s) [source: tests/e2e/prerequisites/inference/lgtm.yaml:48]
- **observed**: Service oauth-proxy targets oauth-proxy with 1 port(s) [source: tests/e2e/prerequisites/inference/lgtm.yaml:95]
- **observed**: Service prometheus-operated targets  with 1 port(s) [source: internal/controller/resources/prometheus-web-tls-service.tmpl.yaml:23]
- **observed**: Service {template-value} targets {template-value} with 1 port(s) [source: internal/controller/resources/korrel8r-deployment.tmpl.yaml:88]
- **observed**: Service {template-value}-webhook targets  with 1 port(s) [source: internal/controller/resources/webhook-service.tmpl.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by cmd [source: cmd/main.go:142]
- **observed**: HTTP GET /readyz is owned by cmd [source: cmd/main.go:146]
- **observed**: Route data-science-prometheus-cluster-proxy serves host  via TLS; backend=data-science-prometheus-cluster-proxy; transport=HTTPS [source: internal/controller/resources/data-science-prometheus-cluster-proxy.tmpl.yaml:187]
- **observed**: Route data-science-prometheus-route serves host  via TLS; backend=data-science-prometheus-namespace-proxy; transport=HTTPS [source: internal/controller/resources/data-science-prometheus-route.tmpl.yaml:1]
- **observed**: Route data-science-thanos-querier-route serves host  via TLS; backend=thanos-querier-data-science-thanos-querier; transport=HTTPS [source: internal/controller/resources/thanos-querier-route.tmpl.yaml:1]
- **observed**: Route lgtm serves host  via TLS; backend=oauth-proxy; transport=HTTPS [source: tests/e2e/prerequisites/inference/lgtm.yaml:166]
### security

- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: cmd/main.go:142]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/main.go:146]
- **observed**: RBAC role data-science-collector-mlflow-trace-export grants 1 rule(s) [source: internal/controller/resources/collector-mlflow-rbac.tmpl.yaml:1]
- **observed**: RBAC role data-science-collector-targetallocator-secrets grants 1 rule(s) [source: internal/controller/resources/collector-rbac.tmpl.yaml:83]
- **observed**: RBAC role data-science-collector-tempo-trace-export grants 1 rule(s) [source: internal/controller/resources/collector-tempo-rbac.tmpl.yaml:1]
- **observed**: RBAC role data-science-metrics-view grants 1 rule(s) [source: internal/controller/resources/data-science-prometheus-namespace-proxy.tmpl.yaml:9]
- **observed**: RBAC role generate-processors-role grants 4 rule(s) [source: internal/controller/resources/collector-rbac.tmpl.yaml:9]
- **observed**: RBAC role {template-value}-processor grants 3 rule(s) [source: internal/controller/resources/usage-logs-opentelemetry-collector-rbac.tmpl.yaml:2]
- **observed**: RBAC role {template-value}-query grants 5 rule(s) [source: internal/controller/resources/korrel8r-rbac.tmpl.yaml:9]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via generate-processors-role ClusterRole; SA {template-value} [source: cmd/main.go:118]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
