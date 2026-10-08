# Analyzer Synthesis Context: mcp-lifecycle-module-operator

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 2 crds facts extracted [source: config/crd/bases/components.platform.opendatahub.io_mcplifecycleoperators.yaml:2, internal/controller/resources/mcp-lifecycle-operator.yaml:1]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 2 http_endpoints facts extracted [source: cmd/main.go:157, cmd/main.go:161]
- **services (observed)**: 1 services facts extracted [source: internal/controller/resources/mcp-lifecycle-operator.yaml:2067]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References

- **controller**: MCPLifecycleOperatorReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: internal/controller/mcplifecycleoperator_reconciler.go:427, internal/controller/mcplifecycleoperator_reconciler.go:488]
- **controller**: MCPLifecycleOperatorReconciler —watches-reference→ api/v1alpha1/MCPLifecycleOperator; api/v1alpha1/MCPLifecycleOperator [source: internal/controller/mcplifecycleoperator_reconciler.go:112, internal/controller/mcplifecycleoperator_reconciler.go:487]
- **controller**: MCPLifecycleOperatorReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: internal/controller/mcplifecycleoperator_reconciler.go:299, internal/controller/mcplifecycleoperator_reconciler.go:489]

## Behavioral Evidence

- **conditional-metrics-enforcement (unresolved)** controller-runtime metrics: controller-runtime metrics serving surface; limitations=The controller-runtime manager Metrics binding does not use one direct lexical options object with a stable SecureServing condition [source: cmd/main.go:93-93]
- **named-watch-predicate (unresolved)** internal/controller.MCPLifecycleOperatorReconciler: /v1/ConfigMap; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/mcplifecycleoperator_reconciler.go:488-488]
- **named-watch-predicate (unresolved)** internal/controller.MCPLifecycleOperatorReconciler: apps/v1/Deployment; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/mcplifecycleoperator_reconciler.go:489-489]
- **named-watch-predicate (unresolved)** internal/controller.MCPLifecycleOperatorReconciler: /v1/ServiceAccount; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/mcplifecycleoperator_reconciler.go:490-490]
- **named-watch-predicate (unresolved)** internal/controller.MCPLifecycleOperatorReconciler: /v1/Service; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/mcplifecycleoperator_reconciler.go:491-491]
- **named-watch-predicate (unresolved)** internal/controller.MCPLifecycleOperatorReconciler: rbac.authorization.k8s.io/v1/ClusterRole; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/mcplifecycleoperator_reconciler.go:492-492]
- **named-watch-predicate (unresolved)** internal/controller.MCPLifecycleOperatorReconciler: rbac.authorization.k8s.io/v1/ClusterRoleBinding; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/mcplifecycleoperator_reconciler.go:493-493]
- **named-watch-predicate (unresolved)** internal/controller.MCPLifecycleOperatorReconciler: rbac.authorization.k8s.io/v1/Role; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/mcplifecycleoperator_reconciler.go:494-494]
- **named-watch-predicate (unresolved)** internal/controller.MCPLifecycleOperatorReconciler: rbac.authorization.k8s.io/v1/RoleBinding; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/mcplifecycleoperator_reconciler.go:495-495]
- **named-watch-predicate (unresolved)** internal/controller.MCPLifecycleOperatorReconciler: apiextensions/v1/CustomResourceDefinition; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/mcplifecycleoperator_reconciler.go:496-496]

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/main.go`:157 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/main.go`:161 (:8081/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/main.go`:91 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Under which configuration branch does the metrics serving surface install authentication and authorization?
  **Expected signal:** a direct SecureServing condition and controller-runtime authn/authz FilterProvider assignment
  **Candidate:** `cmd/main.go`:93-93 (controller-runtime metrics, controller-runtime metrics serving surface)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `internal/controller/resources/mcp-lifecycle-operator.yaml`:1912 (RBAC aggregation (aggregate-to-admin/edit/view ClusterRoles), RBAC-aggregated resources (mcp.x-k8s.io))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/role.yaml`:2 (manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/role.yaml`:2 (mcp-lifecycle-module-operator-manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/rbac/role_binding.yaml`:1 (mcp-lifecycle-module-operator-manager-role, mcp-lifecycle-module-operator-manager-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/rbac/role_binding.yaml`:1 (mcp-lifecycle-module-operator-manager-role, mcp-lifecycle-module-operator-mcp-lifecycle-module-operator-manager-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `internal/controller/resources/mcp-lifecycle-operator.yaml`:1787 (mcp-lifecycle-operator-leader-election-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `internal/controller/resources/mcp-lifecycle-operator.yaml`:1828 (mcp-lifecycle-operator-manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `internal/controller/resources/mcp-lifecycle-operator.yaml`:1912 (mcp-lifecycle-operator-mcpserver-admin-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `internal/controller/resources/mcp-lifecycle-operator.yaml`:1941 (mcp-lifecycle-operator-mcpserver-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `internal/controller/resources/mcp-lifecycle-operator.yaml`:1969 (mcp-lifecycle-operator-mcpserver-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `internal/controller/resources/mcp-lifecycle-operator.yaml`:1993 (mcp-lifecycle-operator-metrics-auth-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `internal/controller/resources/mcp-lifecycle-operator.yaml`:2011 (mcp-lifecycle-operator-metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `internal/controller/resources/mcp-lifecycle-operator.yaml`:2038 (mcp-lifecycle-operator-manager-role, mcp-lifecycle-operator-manager-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:57 (Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/main.go`:64 (cmd)
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
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/main.go`:91 (Kubernetes API, controller-runtime manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/main.go`:157 (/healthz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/main.go`:161 (/readyz, GET, cmd)
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
  **Candidate:** `internal/controller/mcplifecycleoperator_reconciler.go`:112 (api/v1alpha1/MCPLifecycleOperator, get, patch operations by MCPLifecycleOperatorReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/mcplifecycleoperator_reconciler.go`:299 (apps/v1/Deployment, get operations by MCPLifecycleOperatorReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/mcplifecycleoperator_reconciler.go`:427 (/v1/ConfigMap, get operations by MCPLifecycleOperatorReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/controller/mcplifecycleoperator_reconciler.go`:427 (/v1/ConfigMap, get operations by MCPLifecycleOperatorReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/mcplifecycleoperator_reconciler.go`:487 (MCPLifecycleOperatorReconciler, api/v1alpha1/MCPLifecycleOperator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/mcplifecycleoperator_reconciler.go`:488-488 (/v1/ConfigMap, internal/controller.MCPLifecycleOperatorReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/mcplifecycleoperator_reconciler.go`:489-489 (apps/v1/Deployment, internal/controller.MCPLifecycleOperatorReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/mcplifecycleoperator_reconciler.go`:490-490 (/v1/ServiceAccount, internal/controller.MCPLifecycleOperatorReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/mcplifecycleoperator_reconciler.go`:491-491 (/v1/Service, internal/controller.MCPLifecycleOperatorReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/mcplifecycleoperator_reconciler.go`:492-492 (internal/controller.MCPLifecycleOperatorReconciler, rbac.authorization.k8s.io/v1/ClusterRole)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/mcplifecycleoperator_reconciler.go`:493-493 (internal/controller.MCPLifecycleOperatorReconciler, rbac.authorization.k8s.io/v1/ClusterRoleBinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/mcplifecycleoperator_reconciler.go`:494-494 (internal/controller.MCPLifecycleOperatorReconciler, rbac.authorization.k8s.io/v1/Role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/mcplifecycleoperator_reconciler.go`:495-495 (internal/controller.MCPLifecycleOperatorReconciler, rbac.authorization.k8s.io/v1/RoleBinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/mcplifecycleoperator_reconciler.go`:496-496 (apiextensions/v1/CustomResourceDefinition, internal/controller.MCPLifecycleOperatorReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/mcplifecycleoperator_reconciler.go`:499 (MCPLifecycleOperatorReconciler, config.openshift.io/v1/APIServer)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `config/manager/manager.yaml`:1 (mcp-lifecycle-module-operator-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `internal/controller/resources/mcp-lifecycle-operator.yaml`:2067 (mcp-lifecycle-operator-controller-manager, mcp-lifecycle-operator-controller-manager-metrics-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `internal/controller/resources/mcp-lifecycle-operator.yaml`:2086 (mcp-lifecycle-operator-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: cmd/main.go:157]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/main.go:161]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via mcp-lifecycle-module-operator-manager-role ClusterRole; SA mcp-lifecycle-module-operator-controller-manager [source: cmd/main.go:91]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via mcp-lifecycle-operator-manager-role ClusterRole; SA mcp-lifecycle-operator-controller-manager [source: cmd/main.go:91]
- RBAC-aggregated resources (mcp.x-k8s.io) methods=Kubernetes API mechanism=RBAC aggregation (aggregate-to-admin/edit/view ClusterRoles) enforcement=kube-apiserver policy=Built-in admin, edit, and view roles inherit permissions from mcp-lifecycle-operator-mcpserver-admin-role, mcp-lifecycle-operator-mcpserver-editor-role, and mcp-lifecycle-operator-mcpserver-viewer-role [source: internal/controller/resources/mcp-lifecycle-operator.yaml:1912]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/main.go:157]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/main.go:161]
### integrations

- prometheus-operator interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage Prometheus monitoring resources [source: config/rbac/role.yaml:2]
### internal_dependencies

- odh-platform-utilities interaction=Go Library role=runtime-library purpose=Platform detection, manifest rendering, and deployment helpers [source: go.mod]
- odh-platform-utilities interaction=Go library role=runtime-library purpose=Use runtime packages from github.com/opendatahub-io/odh-platform-utilities [source: api/v1alpha1/mcplifecycleoperator_lifecycle.go:20]
- prometheus-operator interaction=CRD CRUD role=unknown purpose=Manage Prometheus monitoring resources [source: config/rbac/role.yaml:2]
### services

- mcp-lifecycle-operator-controller-manager-metrics-service port=8443 target=8443 protocol=TCP encryption= auth= [source: internal/controller/resources/mcp-lifecycle-operator.yaml:2067]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Controller-created Deployment workload mcp-lifecycle-operator-controller-manager uses service account mcp-lifecycle-operator-controller-manager and 1 container(s) [source: internal/controller/resources/mcp-lifecycle-operator.yaml:2086]
- **observed**: Deployment workload mcp-lifecycle-module-operator-controller-manager uses service account mcp-lifecycle-module-operator-controller-manager and 1 container(s) [source: config/manager/manager.yaml:1]
- **observed**: Service mcp-lifecycle-operator-controller-manager-metrics-service targets mcp-lifecycle-operator-controller-manager with 1 port(s) [source: internal/controller/resources/mcp-lifecycle-operator.yaml:2067]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by cmd [source: cmd/main.go:157]
- **observed**: HTTP GET /readyz is owned by cmd [source: cmd/main.go:161]
### security

- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: cmd/main.go:157]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/main.go:161]
- **observed**: Kubernetes API RBAC-aggregated resources (mcp.x-k8s.io) uses RBAC aggregation (aggregate-to-admin/edit/view ClusterRoles) at kube-apiserver; policy=Built-in admin, edit, and view roles inherit permissions from mcp-lifecycle-operator-mcpserver-admin-role, mcp-lifecycle-operator-mcpserver-editor-role, and mcp-lifecycle-operator-mcpserver-viewer-role [source: internal/controller/resources/mcp-lifecycle-operator.yaml:1912]
- **observed**: RBAC role manager-role grants 20 rule(s) [source: config/rbac/role.yaml:2]
- **observed**: RBAC role mcp-lifecycle-module-operator-manager-role grants 20 rule(s) [source: config/rbac/role.yaml:2]
- **observed**: RBAC role mcp-lifecycle-operator-leader-election-role grants 3 rule(s) [source: internal/controller/resources/mcp-lifecycle-operator.yaml:1787]
- **observed**: RBAC role mcp-lifecycle-operator-manager-role grants 9 rule(s) [source: internal/controller/resources/mcp-lifecycle-operator.yaml:1828]
- **observed**: RBAC role mcp-lifecycle-operator-mcpserver-admin-role grants 2 rule(s) [source: internal/controller/resources/mcp-lifecycle-operator.yaml:1912]
- **observed**: RBAC role mcp-lifecycle-operator-mcpserver-editor-role grants 2 rule(s) [source: internal/controller/resources/mcp-lifecycle-operator.yaml:1941]
- **observed**: RBAC role mcp-lifecycle-operator-mcpserver-viewer-role grants 2 rule(s) [source: internal/controller/resources/mcp-lifecycle-operator.yaml:1969]
- **observed**: RBAC role mcp-lifecycle-operator-metrics-auth-role grants 2 rule(s) [source: internal/controller/resources/mcp-lifecycle-operator.yaml:1993]
- **observed**: RBAC role mcp-lifecycle-operator-metrics-reader grants 1 rule(s) [source: internal/controller/resources/mcp-lifecycle-operator.yaml:2011]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via mcp-lifecycle-module-operator-manager-role ClusterRole; SA mcp-lifecycle-module-operator-controller-manager [source: cmd/main.go:91]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via mcp-lifecycle-operator-manager-role ClusterRole; SA mcp-lifecycle-operator-controller-manager [source: cmd/main.go:91]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
