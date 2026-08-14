# Analyzer Synthesis Context: odh-observability

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 1 crds facts extracted [source: charts/odh-observability/crds/services.platform.opendatahub.io_monitorings.yaml:2]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 2 http_endpoints facts extracted [source: cmd/main.go:141, cmd/main.go:145]
- **services (observed)**: 6 services facts extracted [source: internal/controller/resources/collector-prometheus-service.tmpl.yaml:5, internal/controller/resources/data-science-prometheus-cluster-proxy.tmpl.yaml:163, internal/controller/resources/data-science-prometheus-namespace-proxy.tmpl.yaml:178, internal/controller/resources/data-science-prometheus-service-override.tmpl.yaml:2, internal/controller/resources/prometheus-web-tls-service.tmpl.yaml:23, internal/controller/resources/webhook-service.tmpl.yaml:1]
- **ingress (observed)**: 3 ingress facts extracted [source: internal/controller/resources/data-science-prometheus-cluster-proxy.tmpl.yaml:183, internal/controller/resources/data-science-prometheus-route.tmpl.yaml:1, internal/controller/resources/thanos-querier-route.tmpl.yaml:1]
- **webhooks (observed)**: 3 webhooks facts extracted [source: internal/controller/resources/webhook-configuration.tmpl.yaml:1, internal/webhook/mutating.go:54, internal/webhook/mutating.go:55]

## Deterministic Cross-References

- **controller**: MonitoringReconciler —watches-reference→ /v1/Secret; /v1/Secret [source: internal/controller/actions.go:585, internal/controller/monitoring_reconciler.go:401]
- **controller**: MonitoringReconciler —watches-reference→ api/v1alpha1/Monitoring; api/v1alpha1/Monitoring [source: internal/controller/monitoring_reconciler.go:101, internal/controller/monitoring_reconciler.go:391]
- **controller**: MonitoringReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: internal/controller/actions.go:634, internal/controller/monitoring_reconciler.go:398]
- **controller**: MonitoringReconciler —watches-reference→ route.openshift.io/v1/Route; route.openshift.io/v1/Route [source: internal/controller/helpers.go:136, internal/controller/monitoring_reconciler.go:404]
- **webhook**: podmonitor-injector.opendatahub.io —served-by→ {template-value}-webhook; admission webhook declares an explicit service reference [source: internal/controller/resources/webhook-configuration.tmpl.yaml:1, internal/controller/resources/webhook-service.tmpl.yaml:1]
- **webhook**: servicemonitor-injector.opendatahub.io —served-by→ {template-value}-webhook; admission webhook declares an explicit service reference [source: internal/controller/resources/webhook-configuration.tmpl.yaml:1, internal/controller/resources/webhook-service.tmpl.yaml:1]

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/main.go`:141 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `internal/controller/resources/collector-rbac.tmpl.yaml`:1 (generate-processors-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `internal/controller/resources/collector-rbac.tmpl.yaml`:47 (generate-processors-collector-rolebinding, generate-processors-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `internal/controller/resources/data-science-prometheus-cluster-proxy.tmpl.yaml`:11 (cluster-monitoring-view, data-science-prometheus-cluster-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `internal/controller/resources/data-science-prometheus-namespace-proxy.tmpl.yaml`:11 (cluster-monitoring-view, data-science-prometheus-namespace-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `internal/controller/resources/monitoringstack-alertmanager-rbac.tmpl.yaml`:2 (cluster-monitoring-view, data-science-monitoringstack-alertmanager-prometheus-metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `internal/controller/resources/usage-logs-opentelemetry-collector-rbac.tmpl.yaml`:8 ({template-value}-processor)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `internal/controller/resources/usage-logs-opentelemetry-collector-rbac.tmpl.yaml`:30 ({template-value}-processor)
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
  **Candidate:** `cmd/main.go`:61 (cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/main.go`:117 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/main.go`:141 (/healthz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `internal/controller/resources/collector-rbac.tmpl.yaml`:1 (CRD CRUD, prometheus-operator)
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
  **Candidate:** `internal/controller/actions.go`:585 (/v1/Secret, get operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/helpers.go`:136 (get operations, route.openshift.io/v1/Route)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/monitoring_reconciler.go`:101 (api/v1alpha1/Monitoring, get, patch operations by MonitoringReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `internal/controller/resources/collector-rbac.tmpl.yaml`:1 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/webhook/mutating.go`:113 (/v1/Namespace, get operations by Injector)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/controller/actions.go`:585 (/v1/Secret, get operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/controller/helpers.go`:136 (get operations, route.openshift.io/v1/Route)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/controller/monitoring_reconciler.go`:101 (api/v1alpha1/Monitoring, get, patch operations by MonitoringReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/monitoring_reconciler.go`:400 (/v1/ConfigMap, MonitoringReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/webhook/mutating.go`:113 (/v1/Namespace, get operations by Injector)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `internal/controller/resources/collector-prometheus-service.tmpl.yaml`:5 (data-science-collector-prometheus)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `internal/controller/resources/data-science-prometheus-cluster-proxy.tmpl.yaml`:58 (data-science-prometheus-cluster-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `internal/controller/resources/data-science-prometheus-cluster-proxy.tmpl.yaml`:163 (data-science-prometheus-cluster-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `internal/controller/resources/data-science-prometheus-namespace-proxy.tmpl.yaml`:65 (data-science-prometheus-namespace-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `internal/controller/resources/data-science-prometheus-namespace-proxy.tmpl.yaml`:178 (data-science-prometheus-namespace-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `internal/controller/resources/data-science-prometheus-service-override.tmpl.yaml`:2 (data-science-prometheus-namespace-proxy, data-science-prometheus-namespace-proxy-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `internal/controller/resources/prometheus-web-tls-service.tmpl.yaml`:23 (prometheus-operated)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `internal/controller/resources/webhook-service.tmpl.yaml`:1 ({template-value}-webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### webhooks

- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/controller/resources/webhook-configuration.tmpl.yaml`:1 (/mutate-prometheus-monitors, podmonitor-injector.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/mutating.go`:54 (/mutate-prometheus-monitors, podmonitor-injector.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: cmd/main.go:141]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/main.go:145]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/main.go:141]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/main.go:145]
### integrations

- prometheus-operator interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage Prometheus monitoring resources [source: internal/controller/resources/collector-rbac.tmpl.yaml:1]
### internal_dependencies

- odh-platform-utilities interaction=Go Library role=runtime-library purpose=Platform detection, manifest rendering, and deployment helpers [source: go.mod]
- odh-platform-utilities interaction=Go library role=runtime-library purpose=Use runtime packages from github.com/opendatahub-io/odh-platform-utilities [source: api/v1alpha1/monitoring_types.go:20]
- prometheus-operator interaction=CRD CRUD role=unknown purpose=Manage Prometheus monitoring resources [source: internal/controller/resources/collector-rbac.tmpl.yaml:1]
### services

- data-science-collector-prometheus port=8889 target=8889 protocol=TCP encryption= auth= [source: internal/controller/resources/collector-prometheus-service.tmpl.yaml:5]
- data-science-prometheus-cluster-proxy port=8443 target=https protocol=TCP encryption= auth= [source: internal/controller/resources/data-science-prometheus-cluster-proxy.tmpl.yaml:163]
- data-science-prometheus-namespace-proxy port=8443 target=https protocol=TCP encryption= auth= [source: internal/controller/resources/data-science-prometheus-namespace-proxy.tmpl.yaml:178]
- data-science-prometheus-namespace-proxy-service port=9090 target=https protocol=TCP encryption= auth= [source: internal/controller/resources/data-science-prometheus-service-override.tmpl.yaml:2]
- prometheus-operated port=9090 target=web protocol=TCP encryption= auth= [source: internal/controller/resources/prometheus-web-tls-service.tmpl.yaml:23]
- {template-value}-webhook port=9443 target=webhook protocol=TCP encryption= auth= [source: internal/controller/resources/webhook-service.tmpl.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Controller-created Deployment workload data-science-prometheus-cluster-proxy uses service account data-science-prometheus-cluster-proxy and 1 container(s) [source: internal/controller/resources/data-science-prometheus-cluster-proxy.tmpl.yaml:58]
- **observed**: Controller-created Deployment workload data-science-prometheus-namespace-proxy uses service account data-science-prometheus-namespace-proxy and 2 container(s) [source: internal/controller/resources/data-science-prometheus-namespace-proxy.tmpl.yaml:65]
- **observed**: Service data-science-collector-prometheus targets  with 1 port(s) [source: internal/controller/resources/collector-prometheus-service.tmpl.yaml:5]
- **observed**: Service data-science-prometheus-cluster-proxy targets data-science-prometheus-cluster-proxy with 1 port(s) [source: internal/controller/resources/data-science-prometheus-cluster-proxy.tmpl.yaml:163]
- **observed**: Service data-science-prometheus-namespace-proxy targets data-science-prometheus-namespace-proxy with 1 port(s) [source: internal/controller/resources/data-science-prometheus-namespace-proxy.tmpl.yaml:178]
- **observed**: Service data-science-prometheus-namespace-proxy-service targets data-science-prometheus-namespace-proxy with 1 port(s) [source: internal/controller/resources/data-science-prometheus-service-override.tmpl.yaml:2]
- **observed**: Service prometheus-operated targets  with 1 port(s) [source: internal/controller/resources/prometheus-web-tls-service.tmpl.yaml:23]
- **observed**: Service {template-value}-webhook targets  with 1 port(s) [source: internal/controller/resources/webhook-service.tmpl.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by cmd [source: cmd/main.go:141]
- **observed**: HTTP GET /readyz is owned by cmd [source: cmd/main.go:145]
- **observed**: Route data-science-prometheus-cluster-proxy serves host  via TLS; backend=data-science-prometheus-cluster-proxy; transport=HTTPS [source: internal/controller/resources/data-science-prometheus-cluster-proxy.tmpl.yaml:183]
- **observed**: Route data-science-prometheus-route serves host  via TLS; backend=data-science-prometheus-namespace-proxy; transport=HTTPS [source: internal/controller/resources/data-science-prometheus-route.tmpl.yaml:1]
- **observed**: Route data-science-thanos-querier-route serves host  via TLS; backend=thanos-querier-data-science-thanos-querier; transport=HTTPS [source: internal/controller/resources/thanos-querier-route.tmpl.yaml:1]
### security

- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: cmd/main.go:141]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/main.go:145]
- **observed**: RBAC role generate-processors-role grants 4 rule(s) [source: internal/controller/resources/collector-rbac.tmpl.yaml:1]
- **observed**: RBAC role {template-value}-processor grants 2 rule(s) [source: internal/controller/resources/usage-logs-opentelemetry-collector-rbac.tmpl.yaml:8]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
