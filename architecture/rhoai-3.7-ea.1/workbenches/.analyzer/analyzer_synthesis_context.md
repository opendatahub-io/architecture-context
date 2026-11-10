# Analyzer Synthesis Context: workbenches

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 2 crds facts extracted [source: workspaces/controller/api/v1beta1/workspace_types.go:388, workspaces/controller/api/v1beta1/workspacekind_types.go:954]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 3 http_endpoints facts extracted [source: workspaces/backend/api/app.go:152, workspaces/controller/cmd/main.go:312, workspaces/controller/cmd/main.go:316]
- **services (not-verified)**: 0 services facts extracted; absence is not proven by the available coverage
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (observed)**: 3 webhooks facts extracted [source: workspaces/controller/internal/webhook/workspace_webhook.go:44, workspaces/controller/internal/webhook/workspacekind_webhook.go:65, workspaces/controller/manifests/kustomize/base/crd/workspacekinds_webhook_patch.yaml:3, workspaces/controller/manifests/kustomize/base/crd/workspaces_webhook_patch.yaml:3]

## Deterministic Cross-References

- **controller**: WorkspaceKindReconciler —watches-reference→ api/v1beta1/Workspace; api/v1beta1/Workspace [source: workspaces/controller/internal/controller/workspace_controller.go:186, workspaces/controller/internal/controller/workspacekind_controller.go:286]
- **controller**: WorkspaceKindReconciler —watches-reference→ api/v1beta1/WorkspaceKind; api/v1beta1/WorkspaceKind [source: workspaces/controller/internal/controller/workspace_controller.go:266, workspaces/controller/internal/controller/workspacekind_controller.go:285]
- **controller**: WorkspaceReconciler —watches-reference→ /v1/Pod; /v1/Pod [source: workspaces/backend/internal/repositories/metrics/repo.go:74, workspaces/controller/internal/controller/workspace_controller.go:1049]
- **controller**: WorkspaceReconciler —watches-reference→ /v1/Service; /v1/Service [source: workspaces/controller/internal/controller/workspace_controller.go:1032, workspaces/controller/internal/controller/workspace_controller.go:516]
- **controller**: WorkspaceReconciler —watches-reference→ /v1/ServiceAccount; /v1/ServiceAccount [source: workspaces/controller/internal/controller/workspace_controller.go:1033, workspaces/controller/internal/controller/workspace_controller.go:357]
- **controller**: WorkspaceReconciler —watches-reference→ api/v1beta1/Workspace; api/v1beta1/Workspace [source: workspaces/controller/internal/controller/workspace_controller.go:1030, workspaces/controller/internal/controller/workspace_controller.go:186]
- **controller**: WorkspaceReconciler —watches-reference→ api/v1beta1/WorkspaceKind; api/v1beta1/WorkspaceKind [source: workspaces/controller/internal/controller/workspace_controller.go:1044, workspaces/controller/internal/controller/workspace_controller.go:266]
- **controller**: WorkspaceReconciler —watches-reference→ apps/v1/StatefulSet; apps/v1/StatefulSet [source: workspaces/controller/internal/controller/workspace_controller.go:1031, workspaces/controller/internal/controller/workspace_controller.go:449]
- **controller**: WorkspaceReconciler —watches-reference→ rbac.authorization.k8s.io/v1/RoleBinding; rbac.authorization.k8s.io/v1/RoleBinding [source: workspaces/controller/internal/controller/workspace_controller.go:1034, workspaces/controller/internal/controller/workspace_controller.go:1393]

## Behavioral Evidence

- **conditional-metrics-enforcement (unresolved)** controller-runtime metrics: controller-runtime metrics serving surface; limitations=The controller-runtime manager Metrics binding does not use one direct lexical options object with a stable SecureServing condition [source: workspaces/backend/internal/helper/k8s.go:76-78]
- **conditional-metrics-enforcement (unresolved)** controller-runtime metrics: controller-runtime metrics serving surface; limitations=The controller-runtime manager Metrics binding does not use one direct lexical options object with a stable SecureServing condition [source: workspaces/controller/cmd/main.go:204-210]
- **named-watch-predicate (unresolved)** internal/controller.WorkspaceKindReconciler: kubeflow.org/v1beta1/Workspace; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: workspaces/controller/internal/controller/workspacekind_controller.go:286-290]
- **named-watch-predicate (unresolved)** internal/controller.WorkspaceReconciler: kubeflow.org/v1beta1/WorkspaceKind; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: workspaces/controller/internal/controller/workspace_controller.go:1044-1048]
- **named-watch-predicate (unresolved)** internal/controller.WorkspaceReconciler: /v1/Pod; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: workspaces/controller/internal/controller/workspace_controller.go:1049-1053]

## Gap Evidence Index

### authentication

- **Question:** Under which configuration branch does the metrics serving surface install authentication and authorization?
  **Expected signal:** a direct SecureServing condition and controller-runtime authn/authz FilterProvider assignment
  **Candidate:** `workspaces/backend/internal/helper/k8s.go`:76-78 (controller-runtime metrics, controller-runtime metrics serving surface)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Under which configuration branch does the metrics serving surface install authentication and authorization?
  **Expected signal:** a direct SecureServing condition and controller-runtime authn/authz FilterProvider assignment
  **Candidate:** `workspaces/controller/cmd/main.go`:204-210 (controller-runtime metrics, controller-runtime metrics serving surface)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `workspaces/controller/cmd/main.go`:312 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `workspaces/controller/cmd/main.go`:316 (:8081/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `workspaces/controller/internal/webhook/workspace_webhook.go`:44 (Kubernetes admission, Operator webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `developing/manifests/dev-resources-dashboard/cluster-rbac/admin.yaml`:1 (dev-admin-workspaces, kubeflow-workspaces-admin)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `developing/manifests/dev-resources-dashboard/cluster-rbac/admin.yaml`:15 (dev-admin-supplement)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `developing/manifests/dev-resources-dashboard/cluster-rbac/admin.yaml`:46 (dev-admin-supplement)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `developing/manifests/dev-resources-dashboard/example-profile-1/user.yaml`:1 (dev-user-workspaces, kubeflow-workspaces-edit)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `developing/manifests/dev-resources-dashboard/example-profile-1/user.yaml`:15 (dev-user-resources)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `developing/manifests/dev-resources-dashboard/example-profile-1/user.yaml`:40 (dev-user-resources)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `workspaces/backend/Dockerfile`:40 (workspaces/backend/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `workspaces/backend/cmd/main.go`:57 (cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `workspaces/controller/Dockerfile`:34 (workspaces/controller/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `workspaces/controller/Dockerfile.konflux`:37 (workspaces/controller/Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `workspaces/frontend/Dockerfile`:60 (workspaces/frontend/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `workspaces/frontend/Dockerfile.dev`:37 (workspaces/frontend/Dockerfile.dev:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `workspaces/backend/cmd/main.go`:202 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `workspaces/backend/go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `workspaces/backend/internal/integrations/kubernetes/testenv/testenv.go`:79 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `workspaces/controller/cmd/main.go`:185 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `workspaces/backend/api/app.go`:152 (/, Unknown, api)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `workspaces/controller/cmd/main.go`:312 (/healthz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `workspaces/controller/cmd/main.go`:316 (/readyz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `workspaces/backend/api/workspace_podtemplate_logs_handler.go`:122 (api/constants/ContainerQueryParam, get operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `workspaces/backend/api/workspacekinds_handler.go`:109 (api/constants/NamespaceFilterQueryParam, get operations by App)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `workspaces/backend/internal/helper/validation.go`:180 (/v1/Secret, delete, get, update operations by SecretRepository)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `workspaces/backend/internal/helper/validation.go`:211 (/v1/PersistentVolumeClaim, create, delete, get, list operations by PVCRepository)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `workspaces/backend/internal/repositories/metrics/repo.go`:74 (/v1/Pod, list operations by MetricsRepository, PVCRepository)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `workspaces/backend/internal/repositories/namespaces/repo.go`:43 (/v1/Namespace, get, list operations by NamespaceRepository, WorkspaceKindRepository, WorkspaceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `workspaces/backend/internal/repositories/pvcs/repo.go`:94 (/v1/PersistentVolume, get operations by PVCRepository)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `workspaces/backend/internal/repositories/workspacekinds/repo.go`:297 (/v1/ConfigMap, get, update operations by WorkspaceKindReconciler, WorkspaceKindRepository, WorkspaceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `workspaces/controller/internal/controller/workspace_controller.go`:222 (Gateway API, HTTPRoute CRUD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `workspaces/controller/internal/controller/workspace_controller.go`:2410 (/v1/Event, list operations by WorkspaceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `workspaces/controller/internal/controller/workspace_controller.go`:357 (/v1/ServiceAccount, get, list operations by WorkspaceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `workspaces/controller/internal/controller/workspace_controller.go`:516 (/v1/Service, get, list operations by WorkspaceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `workspaces/backend/internal/repositories/workspacekinds/repo.go`:297 (/v1/ConfigMap, get, update operations by WorkspaceKindReconciler, WorkspaceKindRepository, WorkspaceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `workspaces/controller/internal/controller/workspace_controller.go`:1030 (WorkspaceReconciler, api/v1beta1/Workspace)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `workspaces/controller/internal/controller/workspace_controller.go`:1031 (WorkspaceReconciler, apps/v1/StatefulSet)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `workspaces/controller/internal/controller/workspace_controller.go`:1032 (/v1/Service, WorkspaceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `workspaces/controller/internal/controller/workspace_controller.go`:1033 (/v1/ServiceAccount, WorkspaceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `workspaces/controller/internal/controller/workspace_controller.go`:1034 (WorkspaceReconciler, rbac.authorization.k8s.io/v1/RoleBinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `workspaces/controller/internal/controller/workspace_controller.go`:1037 (WorkspaceReconciler, networking/v1/VirtualService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `workspaces/controller/internal/controller/workspace_controller.go`:1044-1048 (internal/controller.WorkspaceReconciler, kubeflow.org/v1beta1/WorkspaceKind)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `workspaces/controller/internal/controller/workspace_controller.go`:1049-1053 (/v1/Pod, internal/controller.WorkspaceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `workspaces/controller/internal/controller/workspace_controller.go`:2410 (/v1/Event, list operations by WorkspaceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `workspaces/controller/internal/controller/workspacekind_controller.go`:285 (WorkspaceKindReconciler, api/v1beta1/WorkspaceKind)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `workspaces/controller/internal/controller/workspacekind_controller.go`:286-290 (internal/controller.WorkspaceKindReconciler, kubeflow.org/v1beta1/Workspace)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### webhooks

- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `workspaces/controller/internal/webhook/workspace_webhook.go`:44 (/validate-kubeflow-org-v1beta1-workspace, vworkspace.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `workspaces/controller/internal/webhook/workspacekind_webhook.go`:65 (/validate-kubeflow-org-v1beta1-workspacekind, vworkspacekind.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `workspaces/controller/manifests/kustomize/base/crd/workspacekinds_webhook_patch.yaml`:3 (/convert, workspacekinds.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `workspaces/controller/manifests/kustomize/base/crd/workspaces_webhook_patch.yaml`:3 (/convert, workspacekinds.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: workspaces/controller/cmd/main.go:312]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: workspaces/controller/cmd/main.go:316]
- Operator webhook methods=CREATE mechanism=Kubernetes admission enforcement=ValidatingWebhookConfiguration policy=Admission validation [source: workspaces/controller/internal/webhook/workspace_webhook.go:44]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: workspaces/controller/cmd/main.go:312]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: workspaces/controller/cmd/main.go:316]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=api [source: workspaces/backend/api/app.go:152]
### internal_dependencies

- Gateway API interaction=HTTPRoute CRUD role=runtime-transport purpose=Reconcile HTTPRoute resources against a configured Gateway [source: workspaces/controller/internal/controller/workspace_controller.go:222]

## Cross-Cutting Evidence

### deployment_topology

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:deployment_topology]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by cmd [source: workspaces/controller/cmd/main.go:312]
- **observed**: HTTP GET /readyz is owned by cmd [source: workspaces/controller/cmd/main.go:316]
- **observed**: HTTP Unknown / is owned by api [source: workspaces/backend/api/app.go:152]
### security

- **observed**: CREATE Operator webhook uses Kubernetes admission at ValidatingWebhookConfiguration; policy=Admission validation [source: workspaces/controller/internal/webhook/workspace_webhook.go:44]
- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: workspaces/controller/cmd/main.go:312]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: workspaces/controller/cmd/main.go:316]
- **observed**: RBAC role dev-admin-supplement grants 3 rule(s) [source: developing/manifests/dev-resources-dashboard/cluster-rbac/admin.yaml:15]
- **observed**: RBAC role dev-user-resources grants 2 rule(s) [source: developing/manifests/dev-resources-dashboard/example-profile-1/user.yaml:15]
- **literal**: rbac-ref targets TokenReviews: Token or subject access review call [source: workspaces/backend/cmd/main.go:213]
- **dependency-signal**: rbac-ref targets k8s.io/apiserver/pkg/authorization/authorizer: RBAC/authorization API import [source: workspaces/backend/api/app.go, workspaces/backend/api/auth.go, workspaces/backend/internal/auth/authorization.go]
- **dependency-signal**: rbac-ref targets k8s.io/client-go/kubernetes/typed/authorization/v1: RBAC/authorization API import [source: workspaces/backend/internal/auth/authorization.go]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: workspaces/backend/internal/server/server.go, workspaces/controller/cmd/main.go, workspaces/controller/pkg/tls/proxy.go, workspaces/controller/pkg/tls/tls.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
