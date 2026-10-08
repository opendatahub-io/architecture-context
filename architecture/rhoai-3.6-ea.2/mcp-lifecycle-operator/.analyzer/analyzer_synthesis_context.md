# Analyzer Synthesis Context: mcp-lifecycle-operator

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 1 crds facts extracted [source: config/crd/bases/mcp.x-k8s.io_mcpservers.yaml:2]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 2 http_endpoints facts extracted [source: cmd/main.go:206, cmd/main.go:210]
- **services (observed)**: 1 services facts extracted [source: config/default/metrics_service.yaml:4]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References

- **controller**: MCPServerReconciler —watches-reference→ /v1/Service; /v1/Service [source: internal/controller/mcpserver_controller.go:680, internal/controller/mcpserver_controller_service.go:49]
- **controller**: MCPServerReconciler —watches-reference→ api/v1alpha1/MCPServer; api/v1alpha1/MCPServer [source: internal/controller/mcpserver_controller.go:201, internal/controller/mcpserver_controller.go:674]
- **controller**: MCPServerReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: internal/controller/mcpserver_controller.go:679, internal/controller/mcpserver_controller_deployment.go:59]
- **controller**: MCPServerReconciler —watches-reference→ networking.k8s.io/v1/NetworkPolicy; networking.k8s.io/v1/NetworkPolicy [source: internal/controller/mcpserver_controller.go:681, internal/controller/mcpserver_controller_networkpolicy.go:50]

## Behavioral Evidence

- **conditional-metrics-enforcement (unresolved)** controller-runtime metrics: controller-runtime metrics serving surface; limitations=The controller-runtime manager Metrics binding does not use one direct lexical options object with a stable SecureServing condition [source: cmd/main.go:166-166]

## Gap Evidence Index

### authentication

- **Question:** How is this runtime security control wired to the serving surface?
  **Expected signal:** flag/default, certificate, middleware, or enforcement point
  **Candidate:** `cmd/main.go`:144 (controller-runtime metrics, controller-runtime metrics authn/authz filter)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/main.go`:144 (:8443/metrics, TokenReview + SubjectAccessReview (controller-runtime authn/authz filter))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/main.go`:164 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Under which configuration branch does the metrics serving surface install authentication and authorization?
  **Expected signal:** a direct SecureServing condition and controller-runtime authn/authz FilterProvider assignment
  **Candidate:** `cmd/main.go`:166-166 (controller-runtime metrics, controller-runtime metrics serving surface)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/main.go`:206 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/main.go`:210 (:8081/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `config/rbac/mcpserver_admin_role.yaml`:11 (RBAC aggregation (aggregate-to-admin/edit/view ClusterRoles), RBAC-aggregated resources (mcp.x-k8s.io))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/mcpserver_admin_role.yaml`:11 (mcp-lifecycle-operator-mcpserver-admin-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/mcpserver_admin_role.yaml`:11 (mcpserver-admin-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/mcpserver_editor_role.yaml`:11 (mcp-lifecycle-operator-mcpserver-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/mcpserver_editor_role.yaml`:11 (mcpserver-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/mcpserver_viewer_role.yaml`:11 (mcp-lifecycle-operator-mcpserver-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/mcpserver_viewer_role.yaml`:11 (mcpserver-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/metrics_auth_role.yaml`:4 (mcp-lifecycle-operator-metrics-auth-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/metrics_auth_role.yaml`:4 (metrics-auth-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/metrics_reader_role.yaml`:4 (mcp-lifecycle-operator-metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/metrics_reader_role.yaml`:4 (metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/role.yaml`:2 (manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/role.yaml`:2 (mcp-lifecycle-operator-manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:48 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:57 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.ci`:27 (Dockerfile.ci:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:35 (Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/main.go`:60 (cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `hack/mkdocs/image/Dockerfile`:18 (hack/mkdocs/image/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `hack/mkdocs/image/Dockerfile`:19 (hack/mkdocs/image/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `test/e2e/Dockerfile`:59 (test/e2e/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `test/e2e/Dockerfile`:60 (test/e2e/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/main.go`:164 (Kubernetes API, controller-runtime manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/main.go`:206 (/healthz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/main.go`:210 (/readyz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/mcpserver_controller.go`:201 (api/v1alpha1/MCPServer, get, list operations by MCPServerReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/mcpserver_controller_conditions.go`:114 (/v1/Pod, list operations by MCPServerReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/mcpserver_controller_confighash.go`:111 (/v1/Secret, get operations by MCPServerReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/mcpserver_controller_confighash.go`:79 (/v1/ConfigMap, get operations by MCPServerReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/mcpserver_controller_deployment.go`:59 (apps/v1/Deployment, get, update operations by MCPServerReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/mcpserver_controller_networkpolicy.go`:50 (get, update operations by MCPServerReconciler, networking.k8s.io/v1/NetworkPolicy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/mcpserver_controller_service.go`:49 (/v1/Service, get, update operations by MCPServerReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/controller/mcpserver_controller.go`:201 (api/v1alpha1/MCPServer, get, list operations by MCPServerReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/mcpserver_controller.go`:674 (MCPServerReconciler, api/v1alpha1/MCPServer)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/mcpserver_controller.go`:679 (MCPServerReconciler, apps/v1/Deployment)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/mcpserver_controller.go`:680 (/v1/Service, MCPServerReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/mcpserver_controller.go`:681 (MCPServerReconciler, networking.k8s.io/v1/NetworkPolicy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/controller/mcpserver_controller_conditions.go`:114 (/v1/Pod, list operations by MCPServerReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/controller/mcpserver_controller_confighash.go`:111 (/v1/Secret, get operations by MCPServerReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/controller/mcpserver_controller_confighash.go`:79 (/v1/ConfigMap, get operations by MCPServerReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/controller/mcpserver_controller_deployment.go`:59 (apps/v1/Deployment, get, update operations by MCPServerReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/controller/mcpserver_controller_networkpolicy.go`:50 (get, update operations by MCPServerReconciler, networking.k8s.io/v1/NetworkPolicy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/controller/mcpserver_controller_service.go`:49 (/v1/Service, get, update operations by MCPServerReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `config/default/manager_metrics_patch.yaml`:1 (mcp-lifecycle-operator-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `config/default/metrics_service.yaml`:4 (mcp-lifecycle-operator-controller-manager, mcp-lifecycle-operator-controller-manager-metrics-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: cmd/main.go:206]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/main.go:210]
- :8443/metrics methods=GET mechanism=TokenReview + SubjectAccessReview (controller-runtime authn/authz filter) enforcement=controller-runtime metrics authn/authz filter policy=RBAC via mcp-lifecycle-operator-metrics-auth-role; exposed by Service mcp-lifecycle-operator-controller-manager-metrics-service; controller-runtime generated self-signed TLS certificate [source: cmd/main.go:144]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via mcp-lifecycle-operator-manager-role ClusterRole; SA mcp-lifecycle-operator-controller-manager [source: cmd/main.go:164]
- RBAC-aggregated resources (mcp.x-k8s.io) methods=Kubernetes API mechanism=RBAC aggregation (aggregate-to-admin/edit/view ClusterRoles) enforcement=kube-apiserver policy=Built-in admin, edit, and view roles inherit permissions from mcpserver-admin-role, mcpserver-editor-role, and mcpserver-viewer-role [source: config/rbac/mcpserver_admin_role.yaml:11]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/main.go:206]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/main.go:210]
### services

- mcp-lifecycle-operator-controller-manager-metrics-service port=8443 target=8443 protocol=TCP encryption= auth= [source: config/default/metrics_service.yaml:4]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload mcp-lifecycle-operator-controller-manager uses service account mcp-lifecycle-operator-controller-manager and 1 container(s) [source: config/default/manager_metrics_patch.yaml:1]
- **observed**: Service mcp-lifecycle-operator-controller-manager-metrics-service targets mcp-lifecycle-operator-controller-manager with 1 port(s) [source: config/default/metrics_service.yaml:4]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by cmd [source: cmd/main.go:206]
- **observed**: HTTP GET /readyz is owned by cmd [source: cmd/main.go:210]
### security

- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: cmd/main.go:206]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/main.go:210]
- **observed**: GET :8443/metrics uses TokenReview + SubjectAccessReview (controller-runtime authn/authz filter) at controller-runtime metrics authn/authz filter; policy=RBAC via mcp-lifecycle-operator-metrics-auth-role; exposed by Service mcp-lifecycle-operator-controller-manager-metrics-service; controller-runtime generated self-signed TLS certificate [source: cmd/main.go:144]
- **observed**: Kubernetes API RBAC-aggregated resources (mcp.x-k8s.io) uses RBAC aggregation (aggregate-to-admin/edit/view ClusterRoles) at kube-apiserver; policy=Built-in admin, edit, and view roles inherit permissions from mcpserver-admin-role, mcpserver-editor-role, and mcpserver-viewer-role [source: config/rbac/mcpserver_admin_role.yaml:11]
- **observed**: RBAC role leader-election-role grants 3 rule(s) [source: config/rbac/leader_election_role.yaml:5]
- **observed**: RBAC role manager-role grants 9 rule(s) [source: config/rbac/role.yaml:2]
- **observed**: RBAC role mcp-lifecycle-operator-leader-election-role grants 3 rule(s) [source: config/rbac/leader_election_role.yaml:5]
- **observed**: RBAC role mcp-lifecycle-operator-manager-role grants 9 rule(s) [source: config/rbac/role.yaml:2]
- **observed**: RBAC role mcp-lifecycle-operator-mcpserver-admin-role grants 2 rule(s) [source: config/rbac/mcpserver_admin_role.yaml:11]
- **observed**: RBAC role mcp-lifecycle-operator-mcpserver-editor-role grants 2 rule(s) [source: config/rbac/mcpserver_editor_role.yaml:11]
- **observed**: RBAC role mcp-lifecycle-operator-mcpserver-viewer-role grants 2 rule(s) [source: config/rbac/mcpserver_viewer_role.yaml:11]
- **observed**: RBAC role mcp-lifecycle-operator-metrics-auth-role grants 2 rule(s) [source: config/rbac/metrics_auth_role.yaml:4]
- **observed**: RBAC role mcp-lifecycle-operator-metrics-reader grants 1 rule(s) [source: config/rbac/metrics_reader_role.yaml:4]
- **observed**: RBAC role mcpserver-admin-role grants 2 rule(s) [source: config/rbac/mcpserver_admin_role.yaml:11]
- **observed**: RBAC role mcpserver-editor-role grants 2 rule(s) [source: config/rbac/mcpserver_editor_role.yaml:11]
- **observed**: RBAC role mcpserver-viewer-role grants 2 rule(s) [source: config/rbac/mcpserver_viewer_role.yaml:11]
- **observed**: RBAC role metrics-auth-role grants 2 rule(s) [source: config/rbac/metrics_auth_role.yaml:4]
- **observed**: RBAC role metrics-reader grants 1 rule(s) [source: config/rbac/metrics_reader_role.yaml:4]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via mcp-lifecycle-operator-manager-role ClusterRole; SA mcp-lifecycle-operator-controller-manager [source: cmd/main.go:164]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: cmd/main.go, cmd/tlsconfig.go, internal/controller/mcpserver_controller.go, internal/controller/mcpserver_controller_tls.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
