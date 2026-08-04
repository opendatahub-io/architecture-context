# Analyzer Synthesis Context: mlflow-operator

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 3 crds facts extracted [source: config/crd/bases/components.platform.opendatahub.io_mlflowoperators.yaml:2, config/crd/bases/mlflow.opendatahub.io_mlflows.yaml:2, config/crd/mlflow.kubeflow.org_mlflowconfigs.yaml:2]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 2 http_endpoints facts extracted [source: cmd/main.go:542, cmd/main.go:546]
- **services (observed)**: 1 services facts extracted [source: config/base/metrics_service.yaml:1]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References

- **controller**: MLflowOperatorReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: internal/controller/mlflow_controller.go:195, internal/controller/mlflowoperator_controller.go:143]
- **controller**: MLflowOperatorReconciler —watches-reference→ api/mlflowoperator/v1alpha1/MLflowOperator; api/mlflowoperator/v1alpha1/MLflowOperator [source: internal/controller/mlflowoperator_controller.go:134, internal/controller/mlflowoperator_controller.go:76]
- **controller**: MLflowOperatorReconciler —watches-reference→ api/v1/MLflow; api/v1/MLflow [source: internal/controller/migration.go:482, internal/controller/mlflowoperator_controller.go:135]
- **controller**: MLflowReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: internal/controller/mlflow_controller.go:195, internal/controller/mlflow_controller.go:490]
- **controller**: MLflowReconciler —watches-reference→ api/mlflowoperator/v1alpha1/MLflowOperator; api/mlflowoperator/v1alpha1/MLflowOperator [source: internal/controller/mlflow_controller.go:498, internal/controller/mlflowoperator_controller.go:76]
- **controller**: MLflowReconciler —watches-reference→ api/v1/MLflow; api/v1/MLflow [source: internal/controller/migration.go:482, internal/controller/mlflow_controller.go:473]
- **controller**: MLflowReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: internal/controller/migration.go:845, internal/controller/mlflow_controller.go:474]
- **controller**: MLflowReconciler —watches-reference→ batch/v1/Job; batch/v1/Job [source: internal/controller/migration.go:661, internal/controller/mlflow_controller.go:475]
- **controller**: NamespaceRBACReconciler —watches-reference→ /v1/Namespace; /v1/Namespace [source: internal/controller/namespace_rbac_controller.go:139, internal/controller/namespace_rbac_controller.go:92]
- **controller**: NamespaceRBACReconciler —watches-reference→ api/v1/MLflow; api/v1/MLflow [source: internal/controller/migration.go:482, internal/controller/namespace_rbac_controller.go:101]

## Gap Evidence Index

### authentication

- **Question:** How is this runtime security control wired to the serving surface?
  **Expected signal:** flag/default, certificate, middleware, or enforcement point
  **Candidate:** `cmd/main.go`:272 (controller-runtime metrics, controller-runtime metrics authn/authz filter)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/main.go`:542 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `config/rbac/role.yaml`:2 (Named Secret access (mlflow-artifact-connection), RBAC with resourceNames restriction)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/leader_election_role.yaml`:2 (mlflow-operator-leader-election-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/rbac/leader_election_role_binding.yaml`:1 (mlflow-operator-leader-election-role, mlflow-operator-leader-election-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/metrics_auth_role.yaml`:1 (mlflow-operator-metrics-auth-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/rbac/metrics_auth_role_binding.yaml`:1 (mlflow-operator-metrics-auth-role, mlflow-operator-metrics-auth-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/metrics_reader_role.yaml`:1 (mlflow-operator-metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/mlflow_aggregate_roles.yaml`:4 (mlflow-operator-mlflow-view)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/mlflow_integration_role.yaml`:8 (mlflow-operator-mlflow-integration)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/namespace_role.yaml`:11 (mlflow-operator-manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/rbac/namespace_role_binding.yaml`:1 (mlflow-operator-manager-role, mlflow-operator-manager-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/role.yaml`:2 (mlflow-operator-manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/rbac/role_binding.yaml`:1 (mlflow-operator-manager-role, mlflow-operator-manager-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:44 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:40 (Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/main.go`:171 (cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `mlflow-tests/images/Dockerfile.konflux`:75 (mlflow-tests/images/Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/main.go`:300 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/main.go`:542 (/healthz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/namespace_role.yaml`:11 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (Gateway API, HTTPRoute CRUD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/namespace_role.yaml`:11 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, Gateway API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/migration.go`:395 (/v1/Pod, list operations by MLflowReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/mlflow_controller.go`:195 (/v1/ConfigMap, get operations by MLflowOperatorReconciler, MLflowReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `internal/controller/mlflow_controller.go`:539 (Controller watch (conditional), Gateway API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/mlflowoperator_controller.go`:76 (api/mlflowoperator/v1alpha1/MLflowOperator, get, update operations by MLflowOperatorReconciler, MLflowReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/namespace_rbac_controller.go`:139 (/v1/Namespace, get, list operations by NamespaceRBACReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/controller/migration.go`:395 (/v1/Pod, list operations by MLflowReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/controller/mlflow_controller.go`:195 (/v1/ConfigMap, get operations by MLflowOperatorReconciler, MLflowReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/mlflow_controller.go`:490 (/v1/ConfigMap, MLflowReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/controller/mlflowoperator_controller.go`:76 (api/mlflowoperator/v1alpha1/MLflowOperator, get, update operations by MLflowOperatorReconciler, MLflowReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/mlflowoperator_controller.go`:143 (/v1/ConfigMap, MLflowOperatorReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/controller/namespace_rbac_controller.go`:139 (/v1/Namespace, get, list operations by NamespaceRBACReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/namespace_rbac_controller.go`:92 (/v1/Namespace, NamespaceRBACReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `config/base/metrics_service.yaml`:1 (mlflow-operator-controller-manager, mlflow-operator-controller-manager-metrics-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `config/manager/manager.yaml`:2 (mlflow-operator-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: cmd/main.go:542]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/main.go:546]
- :8443/metrics methods=GET mechanism=TokenReview + SubjectAccessReview (controller-runtime authn/authz filter) enforcement=controller-runtime metrics authn/authz filter policy=RBAC via mlflow-operator-metrics-auth-role; exposed by Service mlflow-operator-controller-manager-metrics-service; controller-runtime generated self-signed TLS certificate [source: cmd/main.go:272]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via mlflow-operator-manager-role ClusterRole; SA mlflow-operator-controller-manager [source: cmd/main.go:300]
- Named Secret access (mlflow-artifact-connection) methods=Kubernetes API mechanism=RBAC with resourceNames restriction enforcement=kube-apiserver policy=manager-role restricts secret access to mlflow-artifact-connection only [source: config/rbac/role.yaml:2]
- Named Secret access (mlflow-artifact-connection) methods=Kubernetes API mechanism=RBAC with resourceNames restriction enforcement=kube-apiserver policy=mlflow-operator-manager-role restricts secret access to mlflow-artifact-connection only [source: config/rbac/role.yaml:2]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/main.go:542]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/main.go:546]
### integrations

- Gateway API interaction=HTTPRoute CRUD role=runtime-transport protocol=HTTPS purpose=Manage Gateway API routing resources [source: config/rbac/role.yaml:2]
- MLflow CR interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read MLflow instances [source: config/rbac/role.yaml:2]
- OpenShift Console interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Console link resources [source: config/rbac/role.yaml:2]
- prometheus-operator interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage Prometheus monitoring resources [source: config/rbac/namespace_role.yaml:11]
### internal_dependencies

- Gateway API interaction=CRD CRUD role=unknown purpose=Manage Gateway API routing resources [source: config/rbac/role.yaml:2]
- Gateway API interaction=Controller watch (conditional) role=runtime-integration purpose=Manage Gateway API routing resources [source: internal/controller/mlflow_controller.go:539]
- MLflow (mlflow.opendatahub.io) interaction=CRD Watch role=runtime-integration purpose=Read MLflow instances [source: config/rbac/role.yaml:2]
- prometheus-operator interaction=CRD CRUD role=unknown purpose=Manage Prometheus monitoring resources [source: config/rbac/namespace_role.yaml:11]
- prometheus-operator interaction=Controller watch (conditional) role=runtime-integration purpose=Manage Prometheus monitoring resources [source: internal/controller/mlflow_controller.go:547]
### services

- mlflow-operator-controller-manager-metrics-service port=8443 target=8443 protocol=TCP encryption= auth= [source: config/base/metrics_service.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload mlflow-operator-controller-manager uses service account mlflow-operator-controller-manager and 1 container(s) [source: config/manager/manager.yaml:2]
- **observed**: Service mlflow-operator-controller-manager-metrics-service targets mlflow-operator-controller-manager with 1 port(s) [source: config/base/metrics_service.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by cmd [source: cmd/main.go:542]
- **observed**: HTTP GET /readyz is owned by cmd [source: cmd/main.go:546]
### security

- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: cmd/main.go:542]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/main.go:546]
- **observed**: GET :8443/metrics uses TokenReview + SubjectAccessReview (controller-runtime authn/authz filter) at controller-runtime metrics authn/authz filter; policy=RBAC via mlflow-operator-metrics-auth-role; exposed by Service mlflow-operator-controller-manager-metrics-service; controller-runtime generated self-signed TLS certificate [source: cmd/main.go:272]
- **observed**: Kubernetes API Named Secret access (mlflow-artifact-connection) uses RBAC with resourceNames restriction at kube-apiserver; policy=manager-role restricts secret access to mlflow-artifact-connection only [source: config/rbac/role.yaml:2]
- **observed**: Kubernetes API Named Secret access (mlflow-artifact-connection) uses RBAC with resourceNames restriction at kube-apiserver; policy=mlflow-operator-manager-role restricts secret access to mlflow-artifact-connection only [source: config/rbac/role.yaml:2]
- **observed**: RBAC role leader-election-role grants 3 rule(s) [source: config/rbac/leader_election_role.yaml:2]
- **observed**: RBAC role manager-role grants 18 rule(s) [source: config/rbac/role.yaml:2]
- **observed**: RBAC role manager-role grants 6 rule(s) [source: config/rbac/namespace_role.yaml:11]
- **observed**: RBAC role metrics-auth-role grants 2 rule(s) [source: config/rbac/metrics_auth_role.yaml:1]
- **observed**: RBAC role metrics-reader grants 1 rule(s) [source: config/rbac/metrics_reader_role.yaml:1]
- **observed**: RBAC role mlflow-edit grants 6 rule(s) [source: config/rbac/mlflow_aggregate_roles.yaml:56]
- **observed**: RBAC role mlflow-integration grants 4 rule(s) [source: config/rbac/mlflow_integration_role.yaml:8]
- **observed**: RBAC role mlflow-operator-leader-election-role grants 3 rule(s) [source: config/rbac/leader_election_role.yaml:2]
- **observed**: RBAC role mlflow-operator-manager-role grants 18 rule(s) [source: config/rbac/role.yaml:2]
- **observed**: RBAC role mlflow-operator-manager-role grants 6 rule(s) [source: config/rbac/namespace_role.yaml:11]
- **observed**: RBAC role mlflow-operator-metrics-auth-role grants 2 rule(s) [source: config/rbac/metrics_auth_role.yaml:1]
- **observed**: RBAC role mlflow-operator-metrics-reader grants 1 rule(s) [source: config/rbac/metrics_reader_role.yaml:1]
- **observed**: RBAC role mlflow-operator-mlflow-edit grants 6 rule(s) [source: config/rbac/mlflow_aggregate_roles.yaml:56]
- **observed**: RBAC role mlflow-operator-mlflow-integration grants 4 rule(s) [source: config/rbac/mlflow_integration_role.yaml:8]
- **observed**: RBAC role mlflow-operator-mlflow-view grants 4 rule(s) [source: config/rbac/mlflow_aggregate_roles.yaml:4]
- **observed**: RBAC role mlflow-view grants 4 rule(s) [source: config/rbac/mlflow_aggregate_roles.yaml:4]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via mlflow-operator-manager-role ClusterRole; SA mlflow-operator-controller-manager [source: cmd/main.go:300]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: cmd/main.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
