# Analyzer Synthesis Context: mlflow-operator

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 3 crds facts extracted [source: config/crd/bases/components.platform.opendatahub.io_mlflowoperators.yaml:2, config/crd/bases/mlflow.opendatahub.io_mlflows.yaml:2, config/crd/mlflow.kubeflow.org_mlflowconfigs.yaml:2]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 2 http_endpoints facts extracted [source: cmd/main.go:570, cmd/main.go:574]
- **services (observed)**: 1 services facts extracted [source: config/overlays/openshift/metrics_service_patch.yaml:1]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References

- **controller**: MLflowOperatorReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: internal/controller/mlflow_controller.go:273, internal/controller/mlflowoperator_controller.go:157]
- **controller**: MLflowOperatorReconciler —watches-reference→ api/mlflowoperator/v1alpha1/MLflowOperator; api/mlflowoperator/v1alpha1/MLflowOperator [source: internal/controller/mlflowoperator_controller.go:148, internal/controller/mlflowoperator_controller.go:84]
- **controller**: MLflowOperatorReconciler —watches-reference→ api/v1/MLflow; api/v1/MLflow [source: internal/controller/migration.go:529, internal/controller/mlflowoperator_controller.go:149]
- **controller**: MLflowReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: internal/controller/mlflow_controller.go:273, internal/controller/mlflow_controller.go:602]
- **controller**: MLflowReconciler —watches-reference→ /v1/Secret; /v1/Secret [source: internal/controller/artifacts_server_validation.go:71, internal/controller/mlflow_controller.go:609]
- **controller**: MLflowReconciler —watches-reference→ api/mlflowoperator/v1alpha1/MLflowOperator; api/mlflowoperator/v1alpha1/MLflowOperator [source: internal/controller/mlflow_controller.go:614, internal/controller/mlflowoperator_controller.go:84]
- **controller**: MLflowReconciler —watches-reference→ api/v1/MLflow; api/v1/MLflow [source: internal/controller/migration.go:529, internal/controller/mlflow_controller.go:586]
- **controller**: MLflowReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: internal/controller/migration.go:248, internal/controller/mlflow_controller.go:587]
- **controller**: MLflowReconciler —watches-reference→ batch/v1/Job; batch/v1/Job [source: internal/controller/migration.go:740, internal/controller/mlflow_controller.go:588]
- **controller**: NamespaceRBACReconciler —watches-reference→ /v1/Namespace; /v1/Namespace [source: internal/controller/namespace_rbac_controller.go:139, internal/controller/namespace_rbac_controller.go:92]
- **controller**: NamespaceRBACReconciler —watches-reference→ api/v1/MLflow; api/v1/MLflow [source: internal/controller/migration.go:529, internal/controller/namespace_rbac_controller.go:101]

## Behavioral Evidence

- **conditional-metrics-enforcement (unresolved)** controller-runtime metrics: controller-runtime metrics serving surface; limitations=The controller-runtime manager Metrics binding does not use one direct lexical options object with a stable SecureServing condition [source: cmd/main.go:430-430]
- **named-watch-predicate (unresolved)** internal/controller.MLflowOperatorReconciler: /v1/ConfigMap; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/mlflowoperator_controller.go:157-163]
- **named-watch-predicate (unresolved)** internal/controller.MLflowReconciler: /v1/ConfigMap; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/mlflow_controller.go:602-608]

## Gap Evidence Index

### authentication

- **Question:** How is this runtime security control wired to the serving surface?
  **Expected signal:** flag/default, certificate, middleware, or enforcement point
  **Candidate:** `cmd/main.go`:295 (controller-runtime metrics, controller-runtime metrics authn/authz filter)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/main.go`:295 (:8443/metrics, TokenReview + SubjectAccessReview (controller-runtime authn/authz filter))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/main.go`:323 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Under which configuration branch does the metrics serving surface install authentication and authorization?
  **Expected signal:** a direct SecureServing condition and controller-runtime authn/authz FilterProvider assignment
  **Candidate:** `cmd/main.go`:430-430 (controller-runtime metrics, controller-runtime metrics serving surface)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/main.go`:570 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/main.go`:574 (:8081/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `config/rbac/role.yaml`:2 (Named Secret access (mlflow-artifact-connection), RBAC with resourceNames restriction)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/overlays/openshift/tls_clusterrole.yaml`:1 (mlflow-operator-openshift-tls-profile-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/metrics_auth_role.yaml`:1 (metrics-auth-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/metrics_auth_role.yaml`:1 (mlflow-operator-metrics-auth-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/metrics_reader_role.yaml`:1 (metrics-reader)
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
  **Candidate:** `config/rbac/mlflow_aggregate_roles.yaml`:4 (mlflow-view)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/mlflow_aggregate_roles.yaml`:56 (mlflow-edit)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/mlflow_aggregate_roles.yaml`:56 (mlflow-operator-mlflow-edit)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/mlflow_integration_role.yaml`:8 (mlflow-integration)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/mlflow_integration_role.yaml`:8 (mlflow-operator-mlflow-integration)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/role.yaml`:2 (mlflow-operator-manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:46 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:42 (Dockerfile.konflux:ENTRYPOINT)
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
  **Candidate:** `cmd/main.go`:323 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/main.go`:570 (/healthz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/main.go`:574 (/readyz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (CRD Watch, MLflow CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (CRD Watch, OpenShift Console)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (Gateway API, HTTPRoute CRUD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, Gateway API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRD Watch, MLflow (mlflow.opendatahub.io))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/artifacts_server_validation.go`:71 (/v1/Secret, get operations by MLflowReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/migration.go`:248 (apps/v1/Deployment, get, patch operations by MLflowReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/migration.go`:442 (/v1/Pod, list operations by MLflowReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/migration.go`:529 (api/v1/MLflow, get, list, patch, update operations by MLflowOperatorReconciler, MLflowReconciler, NamespaceRBACReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/mlflow_controller.go`:273 (/v1/ConfigMap, get operations by MLflowOperatorReconciler, MLflowReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `internal/controller/mlflow_controller.go`:655 (Controller watch (conditional), Gateway API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `internal/controller/mlflow_controller.go`:663 (Controller watch (conditional), prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/mlflowoperator_controller.go`:84 (api/mlflowoperator/v1alpha1/MLflowOperator, get, update operations by MLflowOperatorReconciler, MLflowReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/namespace_rbac_controller.go`:139 (/v1/Namespace, get, list operations by NamespaceRBACReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/mlflow_controller.go`:586 (MLflowReconciler, api/v1/MLflow)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/mlflow_controller.go`:590 (/v1/Service, MLflowReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/mlflow_controller.go`:591 (/v1/ServiceAccount, MLflowReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/mlflow_controller.go`:592 (/v1/PersistentVolumeClaim, MLflowReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/mlflow_controller.go`:602-608 (/v1/ConfigMap, internal/controller.MLflowReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/mlflow_controller.go`:609 (/v1/Secret, MLflowReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/mlflow_controller.go`:614 (MLflowReconciler, api/mlflowoperator/v1alpha1/MLflowOperator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/mlflowoperator_controller.go`:148 (MLflowOperatorReconciler, api/mlflowoperator/v1alpha1/MLflowOperator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/mlflowoperator_controller.go`:149 (MLflowOperatorReconciler, api/v1/MLflow)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/mlflowoperator_controller.go`:157-163 (/v1/ConfigMap, internal/controller.MLflowOperatorReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/namespace_rbac_controller.go`:101 (NamespaceRBACReconciler, api/v1/MLflow)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/namespace_rbac_controller.go`:92 (/v1/Namespace, NamespaceRBACReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `config/overlays/openshift/metrics_service_patch.yaml`:1 (mlflow-operator-controller-manager, mlflow-operator-controller-manager-metrics-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `config/overlays/rhoai/manager_patch.yaml`:1 (mlflow-operator-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: cmd/main.go:570]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/main.go:574]
- :8443/metrics methods=GET mechanism=TokenReview + SubjectAccessReview (controller-runtime authn/authz filter) enforcement=controller-runtime metrics authn/authz filter policy=RBAC via mlflow-operator-metrics-auth-role; exposed by Service mlflow-operator-controller-manager-metrics-service; TLS certificate provisioned by OpenShift service-ca [source: cmd/main.go:295]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via mlflow-operator-manager-role ClusterRole; SA mlflow-operator-controller-manager [source: cmd/main.go:323]
- Named Secret access (mlflow-artifact-connection) methods=Kubernetes API mechanism=RBAC with resourceNames restriction enforcement=kube-apiserver policy=manager-role restricts secret access to mlflow-artifact-connection only [source: config/rbac/role.yaml:2]
- Named Secret access (mlflow-artifact-connection) methods=Kubernetes API mechanism=RBAC with resourceNames restriction enforcement=kube-apiserver policy=mlflow-operator-manager-role restricts secret access to mlflow-artifact-connection only [source: config/rbac/role.yaml:2]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/main.go:570]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/main.go:574]
### integrations

- Gateway API interaction=HTTPRoute CRUD role=runtime-transport protocol=HTTPS purpose=Manage Gateway API routing resources [source: config/rbac/role.yaml:2]
- MLflow CR interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read MLflow instances [source: config/rbac/role.yaml:2]
- OpenShift Console interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Console link resources [source: config/rbac/role.yaml:2]
- prometheus-operator interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage Prometheus monitoring resources [source: config/rbac/role.yaml:2]
### internal_dependencies

- Gateway API interaction=CRD CRUD role=unknown purpose=Manage Gateway API routing resources [source: config/rbac/role.yaml:2]
- Gateway API interaction=Controller watch (conditional) role=runtime-integration purpose=Manage Gateway API routing resources [source: internal/controller/mlflow_controller.go:655]
- MLflow (mlflow.opendatahub.io) interaction=CRD Watch role=runtime-integration purpose=Read MLflow instances [source: config/rbac/role.yaml:2]
- prometheus-operator interaction=CRD CRUD role=unknown purpose=Manage Prometheus monitoring resources [source: config/rbac/role.yaml:2]
- prometheus-operator interaction=Controller watch (conditional) role=runtime-integration purpose=Manage Prometheus monitoring resources [source: internal/controller/mlflow_controller.go:663]
### services

- mlflow-operator-controller-manager-metrics-service port=8443 target=8443 protocol=TCP encryption= auth= [source: config/overlays/openshift/metrics_service_patch.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload mlflow-operator-controller-manager uses service account mlflow-operator-controller-manager and 1 container(s) [source: config/overlays/rhoai/manager_patch.yaml:1]
- **observed**: Service mlflow-operator-controller-manager-metrics-service targets mlflow-operator-controller-manager with 1 port(s) [source: config/overlays/openshift/metrics_service_patch.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by cmd [source: cmd/main.go:570]
- **observed**: HTTP GET /readyz is owned by cmd [source: cmd/main.go:574]
### security

- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: cmd/main.go:570]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/main.go:574]
- **observed**: GET :8443/metrics uses TokenReview + SubjectAccessReview (controller-runtime authn/authz filter) at controller-runtime metrics authn/authz filter; policy=RBAC via mlflow-operator-metrics-auth-role; exposed by Service mlflow-operator-controller-manager-metrics-service; TLS certificate provisioned by OpenShift service-ca [source: cmd/main.go:295]
- **observed**: Kubernetes API Named Secret access (mlflow-artifact-connection) uses RBAC with resourceNames restriction at kube-apiserver; policy=manager-role restricts secret access to mlflow-artifact-connection only [source: config/rbac/role.yaml:2]
- **observed**: Kubernetes API Named Secret access (mlflow-artifact-connection) uses RBAC with resourceNames restriction at kube-apiserver; policy=mlflow-operator-manager-role restricts secret access to mlflow-artifact-connection only [source: config/rbac/role.yaml:2]
- **observed**: RBAC role leader-election-role grants 3 rule(s) [source: config/rbac/leader_election_role.yaml:2]
- **observed**: RBAC role manager-role grants 19 rule(s) [source: config/rbac/role.yaml:2]
- **observed**: RBAC role manager-role grants 6 rule(s) [source: config/rbac/namespace_role.yaml:11]
- **observed**: RBAC role metrics-auth-role grants 2 rule(s) [source: config/rbac/metrics_auth_role.yaml:1]
- **observed**: RBAC role metrics-reader grants 1 rule(s) [source: config/rbac/metrics_reader_role.yaml:1]
- **observed**: RBAC role mlflow-edit grants 6 rule(s) [source: config/rbac/mlflow_aggregate_roles.yaml:56]
- **observed**: RBAC role mlflow-integration grants 4 rule(s) [source: config/rbac/mlflow_integration_role.yaml:8]
- **observed**: RBAC role mlflow-operator-leader-election-role grants 3 rule(s) [source: config/rbac/leader_election_role.yaml:2]
- **observed**: RBAC role mlflow-operator-manager-role grants 19 rule(s) [source: config/rbac/role.yaml:2]
- **observed**: RBAC role mlflow-operator-manager-role grants 6 rule(s) [source: config/rbac/namespace_role.yaml:11]
- **observed**: RBAC role mlflow-operator-metrics-auth-role grants 2 rule(s) [source: config/rbac/metrics_auth_role.yaml:1]
- **observed**: RBAC role mlflow-operator-metrics-reader grants 1 rule(s) [source: config/rbac/metrics_reader_role.yaml:1]
- **observed**: RBAC role mlflow-operator-mlflow-edit grants 6 rule(s) [source: config/rbac/mlflow_aggregate_roles.yaml:56]
- **observed**: RBAC role mlflow-operator-mlflow-integration grants 4 rule(s) [source: config/rbac/mlflow_integration_role.yaml:8]
- **observed**: RBAC role mlflow-operator-mlflow-view grants 4 rule(s) [source: config/rbac/mlflow_aggregate_roles.yaml:4]
- **observed**: RBAC role mlflow-operator-openshift-tls-profile-reader grants 1 rule(s) [source: config/overlays/openshift/tls_clusterrole.yaml:1]
- **observed**: RBAC role mlflow-view grants 4 rule(s) [source: config/rbac/mlflow_aggregate_roles.yaml:4]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via mlflow-operator-manager-role ClusterRole; SA mlflow-operator-controller-manager [source: cmd/main.go:323]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: cmd/main.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
