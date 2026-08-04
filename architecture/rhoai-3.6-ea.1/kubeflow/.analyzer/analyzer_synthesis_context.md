# Analyzer Synthesis Context: kubeflow

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 3 crds facts extracted [source: components/notebook-controller/api/v1alpha1/notebook_types.go:69, components/notebook-controller/api/v1beta1/notebook_types.go:69, components/notebook-controller/config/crd/patches/trivial_conversion_patch.yaml:2]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 4 http_endpoints facts extracted [source: components/notebook-controller/main.go:125, components/notebook-controller/main.go:130, components/odh-notebook-controller/main.go:335, components/odh-notebook-controller/main.go:339]
- **services (observed)**: 1 services facts extracted [source: components/notebook-controller/config/manager/service.yaml:1]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (observed)**: 5 webhooks facts extracted [source: components/notebook-controller/config/crd/patches/webhook_in_notebooks.yaml:4, components/odh-notebook-controller/config/webhook/manifests.yaml:2, components/odh-notebook-controller/config/webhook/manifests.yaml:28, components/odh-notebook-controller/controllers/notebook_mutating_webhook.go:54, components/odh-notebook-controller/controllers/notebook_validating_webhook.go:31]

## Deterministic Cross-References

- **controller**: CullingReconciler —watches-reference→ api/v1beta1/Notebook; api/v1beta1/Notebook [source: components/notebook-controller/controllers/culling_controller.go:580, components/notebook-controller/controllers/culling_controller.go:92]
- **controller**: NotebookReconciler —watches-reference→ /v1/Event; /v1/Event [source: components/notebook-controller/controllers/notebook_controller.go:100, components/notebook-controller/controllers/notebook_controller.go:808]
- **controller**: NotebookReconciler —watches-reference→ /v1/Pod; /v1/Pod [source: components/notebook-controller/controllers/culling_controller.go:122, components/notebook-controller/controllers/notebook_controller.go:804]
- **controller**: NotebookReconciler —watches-reference→ /v1/Service; /v1/Service [source: components/common/reconcilehelper/util.go:49, components/notebook-controller/controllers/notebook_controller.go:803]
- **controller**: NotebookReconciler —watches-reference→ api/v1beta1/Notebook; api/v1beta1/Notebook [source: components/notebook-controller/controllers/culling_controller.go:92, components/notebook-controller/controllers/notebook_controller.go:801]
- **controller**: NotebookReconciler —watches-reference→ apps/v1/StatefulSet; apps/v1/StatefulSet [source: components/notebook-controller/controllers/notebook_controller.go:159, components/notebook-controller/controllers/notebook_controller.go:802]
- **controller**: OpenshiftNotebookReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: components/odh-notebook-controller/controllers/notebook_controller.go:551, components/odh-notebook-controller/controllers/notebook_controller.go:742]
- **controller**: OpenshiftNotebookReconciler —watches-reference→ /v1/Secret; /v1/Secret [source: components/odh-notebook-controller/controllers/notebook_controller.go:741, components/odh-notebook-controller/controllers/notebook_dspa_secret.go:249]
- **controller**: OpenshiftNotebookReconciler —watches-reference→ /v1/Service; /v1/Service [source: components/common/reconcilehelper/util.go:49, components/odh-notebook-controller/controllers/notebook_controller.go:740]
- **controller**: OpenshiftNotebookReconciler —watches-reference→ /v1/ServiceAccount; /v1/ServiceAccount [source: components/odh-notebook-controller/controllers/notebook_controller.go:166, components/odh-notebook-controller/controllers/notebook_controller.go:739]
- **controller**: OpenshiftNotebookReconciler —watches-reference→ gateway.networking.k8s.io/v1/HTTPRoute; gateway.networking.k8s.io/v1/HTTPRoute [source: components/odh-notebook-controller/controllers/notebook_controller.go:748, components/odh-notebook-controller/controllers/notebook_route.go:166]
- **controller**: OpenshiftNotebookReconciler —watches-reference→ gateway.networking.k8s.io/v1beta1/ReferenceGrant; gateway.networking.k8s.io/v1beta1/ReferenceGrant [source: components/odh-notebook-controller/controllers/notebook_controller.go:778, components/odh-notebook-controller/controllers/notebook_referencegrant.go:89]
- **controller**: OpenshiftNotebookReconciler —watches-reference→ networking.k8s.io/v1/NetworkPolicy; networking.k8s.io/v1/NetworkPolicy [source: components/odh-notebook-controller/controllers/notebook_controller.go:743, components/odh-notebook-controller/controllers/notebook_network.go:73]
- **controller**: OpenshiftNotebookReconciler —watches-reference→ rbac.authorization.k8s.io/v1/RoleBinding; rbac.authorization.k8s.io/v1/RoleBinding [source: components/odh-notebook-controller/controllers/notebook_controller.go:744, components/odh-notebook-controller/controllers/notebook_mlflow.go:157]

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `components/notebook-controller/main.go`:125 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `components/odh-notebook-controller/controllers/notebook_validating_webhook.go`:31 (Kubernetes admission, Operator webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `components/notebook-controller/config/rbac/auth_proxy_role.yaml`:1 (proxy-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `components/notebook-controller/config/rbac/auth_proxy_role_binding.yaml`:1 (proxy-role, proxy-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `components/notebook-controller/config/rbac/role.yaml`:2 (notebook-controller-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `components/notebook-controller/config/rbac/role_binding.yaml`:1 (notebook-controller-role, notebook-controller-role-binding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `components/notebook-controller/config/rbac/user_cluster_roles.yaml`:1 (notebook-controller-kubeflow-notebooks-admin)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `components/odh-notebook-controller/config/rbac/leader_election_role.yaml`:2 (leader-election-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `components/odh-notebook-controller/config/rbac/leader_election_role_binding.yaml`:2 (leader-election-role, leader-election-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `components/odh-notebook-controller/config/rbac/role.yaml`:2 (manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `components/odh-notebook-controller/config/rbac/role_binding.yaml`:2 (manager-role, manager-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `components/odh-notebook-controller/config/rbac/user_cluster_roles.yaml`:2 (notebooks-admin)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `components/notebook-controller/Dockerfile`:64 (components/notebook-controller/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `components/notebook-controller/Dockerfile.ci`:38 (components/notebook-controller/Dockerfile.ci:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `components/notebook-controller/Dockerfile.konflux`:47 (components/notebook-controller/Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `components/notebook-controller/main.go`:58 (notebook-controller)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `components/odh-notebook-controller/Dockerfile`:62 (components/odh-notebook-controller/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `components/odh-notebook-controller/Dockerfile.konflux`:41 (components/odh-notebook-controller/Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `components/odh-notebook-controller/main.go`:141 (odh-notebook-controller)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `components/notebook-controller/go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `components/notebook-controller/main.go`:125 (/healthz, GET, main)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `components/odh-notebook-controller/main.go`:335 (/healthz, GET, main)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `components/notebook-controller/config/rbac/role.yaml`:2 (CRD CRUD, Kubeflow Notebooks)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `components/odh-notebook-controller/config/rbac/role.yaml`:2 (Gateway API, HTTPRoute CRUD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `components/common/reconcilehelper/util.go`:49 (/v1/Service, create, get, update operations by NotebookReconciler, OpenshiftNotebookReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `components/notebook-controller/config/rbac/role.yaml`:2 (CRD CRUD, Kubeflow Notebooks (kubeflow.org))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `components/notebook-controller/controllers/culling_controller.go`:122 (/v1/Pod, delete, get operations by CullingReconciler, NotebookReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `components/notebook-controller/controllers/notebook_controller.go`:100 (/v1/Event, get operations by NotebookReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `components/odh-notebook-controller/config/rbac/role.yaml`:2 (CRD CRUD, Gateway API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `components/odh-notebook-controller/controllers/notebook_controller.go`:551 (/v1/ConfigMap, create, get, update operations by OpenshiftNotebookReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `components/odh-notebook-controller/controllers/notebook_controller.go`:748 (Controller watch, Gateway API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `components/odh-notebook-controller/controllers/notebook_dspa_secret.go`:249 (/v1/Secret, create, get, update operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `components/odh-notebook-controller/controllers/notebook_dspa_secret.go`:26 (Go library, data-science-pipelines-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `components/odh-notebook-controller/controllers/notebook_mutating_webhook.go`:338 (config.openshift.io/v1/Proxy, list operations by NotebookWebhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `components/odh-notebook-controller/controllers/notebook_route.go`:166 (gateway.networking.k8s.io/v1/HTTPRoute, get, list, update operations by OpenshiftNotebookReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `components/odh-notebook-controller/controllers/notebook_route.go`:166 (Gateway API, HTTPRoute CRUD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `components/common/reconcilehelper/util.go`:49 (/v1/Service, create, get, update operations by NotebookReconciler, OpenshiftNotebookReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `components/notebook-controller/controllers/culling_controller.go`:122 (/v1/Pod, delete, get operations by CullingReconciler, NotebookReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `components/notebook-controller/controllers/culling_controller.go`:580 (CullingReconciler, api/v1beta1/Notebook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `components/notebook-controller/controllers/notebook_controller.go`:100 (/v1/Event, get operations by NotebookReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `components/notebook-controller/controllers/notebook_controller.go`:808 (/v1/Event, NotebookReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `components/odh-notebook-controller/controllers/notebook_controller.go`:551 (/v1/ConfigMap, create, get, update operations by OpenshiftNotebookReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `components/odh-notebook-controller/controllers/notebook_controller.go`:742 (/v1/ConfigMap, OpenshiftNotebookReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `components/odh-notebook-controller/controllers/notebook_dspa_secret.go`:249 (/v1/Secret, create, get, update operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `components/odh-notebook-controller/controllers/notebook_mutating_webhook.go`:338 (config.openshift.io/v1/Proxy, list operations by NotebookWebhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `components/odh-notebook-controller/controllers/notebook_network.go`:73 (create, get, update operations by OpenshiftNotebookReconciler, networking.k8s.io/v1/NetworkPolicy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `components/odh-notebook-controller/controllers/notebook_referencegrant.go`:89 (delete, get, update operations by OpenshiftNotebookReconciler, gateway.networking.k8s.io/v1beta1/ReferenceGrant)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `components/odh-notebook-controller/controllers/notebook_route.go`:166 (gateway.networking.k8s.io/v1/HTTPRoute, get, list, update operations by OpenshiftNotebookReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `components/notebook-controller/config/manager/manager.yaml`:8 (notebook-controller-deployment, notebook-controller-service-account)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `components/notebook-controller/config/manager/service.yaml`:1 (notebook-controller-deployment, notebook-controller-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### webhooks

- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `components/notebook-controller/config/crd/patches/webhook_in_notebooks.yaml`:4 (/convert, notebooks.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `components/odh-notebook-controller/config/webhook/manifests.yaml`:2 (/mutate-notebook-v1, notebooks.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `components/odh-notebook-controller/controllers/notebook_mutating_webhook.go`:54 (/mutate-notebook-v1, notebooks.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `components/odh-notebook-controller/controllers/notebook_validating_webhook.go`:31 (/validate-notebook-v1, notebooks-validation.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: components/notebook-controller/main.go:125]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: components/notebook-controller/main.go:130]
- Operator webhook methods=CREATE mechanism=Kubernetes admission enforcement=ValidatingWebhookConfiguration policy=Admission validation [source: components/odh-notebook-controller/controllers/notebook_validating_webhook.go:31]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: components/notebook-controller/main.go:125]
- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: components/odh-notebook-controller/main.go:335]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: components/notebook-controller/main.go:130]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: components/odh-notebook-controller/main.go:339]
### integrations

- Gateway API interaction=HTTPRoute CRUD role=runtime-transport protocol=HTTPS purpose=Manage Gateway API routing resources [source: components/odh-notebook-controller/config/rbac/role.yaml:2]
- Kubeflow Notebooks interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Create and manage notebook workbenches [source: components/notebook-controller/config/rbac/role.yaml:2]
- OpenShift Image Streams interaction=REST role=runtime-transport protocol=HTTPS purpose=Image stream access [source: components/odh-notebook-controller/config/rbac/role.yaml:2]
- OpenShift Routes interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Dashboard route status [source: components/odh-notebook-controller/config/rbac/role.yaml:2]
### internal_dependencies

- Gateway API interaction=CRD CRUD role=unknown purpose=Manage Gateway API routing resources [source: components/odh-notebook-controller/config/rbac/role.yaml:2]
- Gateway API interaction=Controller watch role=runtime-integration purpose=Manage Gateway API routing resources [source: components/odh-notebook-controller/controllers/notebook_controller.go:748]
- Gateway API interaction=HTTPRoute CRUD role=runtime-transport purpose=Reconcile HTTPRoute resources against a configured Gateway [source: components/odh-notebook-controller/controllers/notebook_route.go:166]
- Kubeflow Notebooks (kubeflow.org) interaction=CRD CRUD role=unknown purpose=Create and manage notebook workbenches [source: components/notebook-controller/config/rbac/role.yaml:2]
- data-science-pipelines-operator interaction=Go library role=runtime-library purpose=Use runtime packages from github.com/opendatahub-io/data-science-pipelines-operator [source: components/odh-notebook-controller/controllers/notebook_dspa_secret.go:26]
### services

- notebook-controller-service port=443 target=443 protocol=TCP encryption= auth= [source: components/notebook-controller/config/manager/service.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload notebook-controller-deployment uses service account notebook-controller-service-account and 1 container(s) [source: components/notebook-controller/config/manager/manager.yaml:8]
- **observed**: Service notebook-controller-service targets notebook-controller-deployment with 1 port(s) [source: components/notebook-controller/config/manager/service.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by main [source: components/notebook-controller/main.go:125]
- **observed**: HTTP GET /readyz is owned by main [source: components/notebook-controller/main.go:130]
### security

- **observed**: CREATE Operator webhook uses Kubernetes admission at ValidatingWebhookConfiguration; policy=Admission validation [source: components/odh-notebook-controller/controllers/notebook_validating_webhook.go:31]
- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: components/notebook-controller/main.go:125]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: components/notebook-controller/main.go:130]
- **observed**: RBAC role kubeflow-notebooks-admin grants 0 rule(s) [source: components/notebook-controller/config/rbac/user_cluster_roles.yaml:1]
- **observed**: RBAC role kubeflow-notebooks-edit grants 1 rule(s) [source: components/notebook-controller/config/rbac/user_cluster_roles.yaml:15]
- **observed**: RBAC role kubeflow-notebooks-view grants 1 rule(s) [source: components/notebook-controller/config/rbac/user_cluster_roles.yaml:40]
- **observed**: RBAC role leader-election-role grants 3 rule(s) [source: components/odh-notebook-controller/config/rbac/leader_election_role.yaml:2]
- **observed**: RBAC role manager-role grants 20 rule(s) [source: components/odh-notebook-controller/config/rbac/role.yaml:2]
- **observed**: RBAC role notebook-controller-kubeflow-notebooks-admin grants 0 rule(s) [source: components/notebook-controller/config/rbac/user_cluster_roles.yaml:1]
- **observed**: RBAC role notebook-controller-kubeflow-notebooks-edit grants 1 rule(s) [source: components/notebook-controller/config/rbac/user_cluster_roles.yaml:15]
- **observed**: RBAC role notebook-controller-kubeflow-notebooks-view grants 1 rule(s) [source: components/notebook-controller/config/rbac/user_cluster_roles.yaml:40]
- **observed**: RBAC role notebook-controller-role grants 6 rule(s) [source: components/notebook-controller/config/rbac/role.yaml:2]
- **observed**: RBAC role notebooks-admin grants 0 rule(s) [source: components/odh-notebook-controller/config/rbac/user_cluster_roles.yaml:2]
- **observed**: RBAC role notebooks-edit grants 1 rule(s) [source: components/odh-notebook-controller/config/rbac/user_cluster_roles.yaml:15]
- **observed**: RBAC role notebooks-view grants 1 rule(s) [source: components/odh-notebook-controller/config/rbac/user_cluster_roles.yaml:39]
- **observed**: RBAC role proxy-role grants 2 rule(s) [source: components/notebook-controller/config/rbac/auth_proxy_role.yaml:1]
- **observed**: RBAC role role grants 6 rule(s) [source: components/notebook-controller/config/rbac/role.yaml:2]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: components/odh-notebook-controller/main.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
