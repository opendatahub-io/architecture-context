# Analyzer Synthesis Context: mcp-lifecycle-module-operator

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 2 crds facts extracted [source: config/crd/bases/components.platform.opendatahub.io_mcplifecycleoperators.yaml:2, internal/controller/resources/mcp-lifecycle-operator.yaml:1]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 2 http_endpoints facts extracted [source: cmd/main.go:155, cmd/main.go:159]
- **services (observed)**: 1 services facts extracted [source: internal/controller/resources/mcp-lifecycle-operator.yaml:2032]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References

- **controller**: MCPLifecycleOperatorReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: internal/controller/mcplifecycleoperator_reconciler.go:426, internal/controller/mcplifecycleoperator_reconciler.go:487]
- **controller**: MCPLifecycleOperatorReconciler —watches-reference→ api/v1alpha1/MCPLifecycleOperator; api/v1alpha1/MCPLifecycleOperator [source: internal/controller/mcplifecycleoperator_reconciler.go:112, internal/controller/mcplifecycleoperator_reconciler.go:486]
- **controller**: MCPLifecycleOperatorReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: internal/controller/mcplifecycleoperator_reconciler.go:298, internal/controller/mcplifecycleoperator_reconciler.go:488]

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/main.go`:155 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `internal/controller/resources/mcp-lifecycle-operator.yaml`:1877 (RBAC aggregation (aggregate-to-admin/edit/view ClusterRoles), RBAC-aggregated resources (mcp.x-k8s.io))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/role.yaml`:2 (mcp-lifecycle-module-operator-manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/rbac/role_binding.yaml`:1 (mcp-lifecycle-module-operator-manager-role, mcp-lifecycle-module-operator-mcp-lifecycle-module-operator-manager-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `internal/controller/resources/mcp-lifecycle-operator.yaml`:1793 (mcp-lifecycle-operator-manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `internal/controller/resources/mcp-lifecycle-operator.yaml`:2003 (mcp-lifecycle-operator-manager-role, mcp-lifecycle-operator-manager-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:57 (Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/main.go`:63 (cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/main.go`:116 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/main.go`:155 (/healthz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `api/v1alpha1/mcplifecycleoperator_lifecycle.go`:20 (Go library, odh-platform-utilities)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `go.mod` (Go Library, odh-platform-utilities)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/mcplifecycleoperator_reconciler.go`:426 (/v1/ConfigMap, get operations by MCPLifecycleOperatorReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/controller/mcplifecycleoperator_reconciler.go`:426 (/v1/ConfigMap, get operations by MCPLifecycleOperatorReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/mcplifecycleoperator_reconciler.go`:487 (/v1/ConfigMap, MCPLifecycleOperatorReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `config/manager/manager.yaml`:1 (mcp-lifecycle-module-operator-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `internal/controller/resources/mcp-lifecycle-operator.yaml`:2051 (mcp-lifecycle-operator-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `internal/controller/resources/mcp-lifecycle-operator.yaml`:2032 (mcp-lifecycle-operator-controller-manager, mcp-lifecycle-operator-controller-manager-metrics-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: cmd/main.go:155]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/main.go:159]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via mcp-lifecycle-module-operator-manager-role ClusterRole; SA mcp-lifecycle-module-operator-controller-manager [source: cmd/main.go:90]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via mcp-lifecycle-operator-manager-role ClusterRole; SA mcp-lifecycle-operator-controller-manager [source: cmd/main.go:90]
- RBAC-aggregated resources (mcp.x-k8s.io) methods=Kubernetes API mechanism=RBAC aggregation (aggregate-to-admin/edit/view ClusterRoles) enforcement=kube-apiserver policy=Built-in admin, edit, and view roles inherit permissions from mcp-lifecycle-operator-mcpserver-admin-role, mcp-lifecycle-operator-mcpserver-editor-role, and mcp-lifecycle-operator-mcpserver-viewer-role [source: internal/controller/resources/mcp-lifecycle-operator.yaml:1877]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/main.go:155]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/main.go:159]
### integrations

- prometheus-operator interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage Prometheus monitoring resources [source: config/rbac/role.yaml:2]
### internal_dependencies

- odh-platform-utilities interaction=Go Library role=runtime-library purpose=Platform detection, manifest rendering, and deployment helpers [source: go.mod]
- odh-platform-utilities interaction=Go library role=runtime-library purpose=Use runtime packages from github.com/opendatahub-io/odh-platform-utilities [source: api/v1alpha1/mcplifecycleoperator_lifecycle.go:20]
- prometheus-operator interaction=CRD CRUD role=unknown purpose=Manage Prometheus monitoring resources [source: config/rbac/role.yaml:2]
### services

- mcp-lifecycle-operator-controller-manager-metrics-service port=8443 target=8443 protocol=TCP encryption= auth= [source: internal/controller/resources/mcp-lifecycle-operator.yaml:2032]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Controller-created Deployment workload mcp-lifecycle-operator-controller-manager uses service account mcp-lifecycle-operator-controller-manager and 1 container(s) [source: internal/controller/resources/mcp-lifecycle-operator.yaml:2051]
- **observed**: Deployment workload mcp-lifecycle-module-operator-controller-manager uses service account mcp-lifecycle-module-operator-controller-manager and 1 container(s) [source: config/manager/manager.yaml:1]
- **observed**: Service mcp-lifecycle-operator-controller-manager-metrics-service targets mcp-lifecycle-operator-controller-manager with 1 port(s) [source: internal/controller/resources/mcp-lifecycle-operator.yaml:2032]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by cmd [source: cmd/main.go:155]
- **observed**: HTTP GET /readyz is owned by cmd [source: cmd/main.go:159]
### security

- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: cmd/main.go:155]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/main.go:159]
- **observed**: Kubernetes API RBAC-aggregated resources (mcp.x-k8s.io) uses RBAC aggregation (aggregate-to-admin/edit/view ClusterRoles) at kube-apiserver; policy=Built-in admin, edit, and view roles inherit permissions from mcp-lifecycle-operator-mcpserver-admin-role, mcp-lifecycle-operator-mcpserver-editor-role, and mcp-lifecycle-operator-mcpserver-viewer-role [source: internal/controller/resources/mcp-lifecycle-operator.yaml:1877]
- **observed**: RBAC role manager-role grants 20 rule(s) [source: config/rbac/role.yaml:2]
- **observed**: RBAC role mcp-lifecycle-module-operator-manager-role grants 20 rule(s) [source: config/rbac/role.yaml:2]
- **observed**: RBAC role mcp-lifecycle-operator-leader-election-role grants 3 rule(s) [source: internal/controller/resources/mcp-lifecycle-operator.yaml:1752]
- **observed**: RBAC role mcp-lifecycle-operator-manager-role grants 9 rule(s) [source: internal/controller/resources/mcp-lifecycle-operator.yaml:1793]
- **observed**: RBAC role mcp-lifecycle-operator-mcpserver-admin-role grants 2 rule(s) [source: internal/controller/resources/mcp-lifecycle-operator.yaml:1877]
- **observed**: RBAC role mcp-lifecycle-operator-mcpserver-editor-role grants 2 rule(s) [source: internal/controller/resources/mcp-lifecycle-operator.yaml:1906]
- **observed**: RBAC role mcp-lifecycle-operator-mcpserver-viewer-role grants 2 rule(s) [source: internal/controller/resources/mcp-lifecycle-operator.yaml:1934]
- **observed**: RBAC role mcp-lifecycle-operator-metrics-auth-role grants 2 rule(s) [source: internal/controller/resources/mcp-lifecycle-operator.yaml:1958]
- **observed**: RBAC role mcp-lifecycle-operator-metrics-reader grants 1 rule(s) [source: internal/controller/resources/mcp-lifecycle-operator.yaml:1976]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via mcp-lifecycle-module-operator-manager-role ClusterRole; SA mcp-lifecycle-module-operator-controller-manager [source: cmd/main.go:90]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via mcp-lifecycle-operator-manager-role ClusterRole; SA mcp-lifecycle-operator-controller-manager [source: cmd/main.go:90]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
