# Analyzer Synthesis Context: workbenches-operator

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 1 crds facts extracted [source: config/crd/bases/components.platform.opendatahub.io_workbenches.yaml:2]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 2 http_endpoints facts extracted [source: cmd/main.go:213, cmd/main.go:218]
- **services (observed)**: 1 services facts extracted [source: config/default/webhook_openshift_patch.yaml:1]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (observed)**: 5 webhooks facts extracted [source: config/default/webhookconfig_openshift_patch.yaml:1, config/webhook/manifests.yaml:2, internal/webhook/hardwareprofile/mutating.go:67, internal/webhook/notebook/mutating.go:55, opt/manifests/workbenches/kf-notebook-controller/crd/patches/webhook_in_notebooks.yaml:4]

## Deterministic Cross-References

- **controller**: WorkbenchesReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: internal/controller/workbenches_controller.go:148, internal/platformconfig/config.go:80]
- **controller**: WorkbenchesReconciler —watches-reference→ /v1/Secret; /v1/Secret [source: internal/controller/workbenches_controller.go:149, internal/webhook/notebook/mutating.go:322]
- **controller**: WorkbenchesReconciler —watches-reference→ /v1/Service; /v1/Service [source: internal/controller/workbenches_controller.go:150, internal/webhook/tls/ensure.go:150]
- **controller**: WorkbenchesReconciler —watches-reference→ admissionregistration/v1/MutatingWebhookConfiguration; admissionregistration/v1/MutatingWebhookConfiguration [source: internal/controller/workbenches_controller.go:156, internal/webhook/tls/ensure.go:133]
- **controller**: WorkbenchesReconciler —watches-reference→ api/v1alpha1/Workbenches; api/v1alpha1/Workbenches [source: internal/controller/workbenches_controller.go:115, internal/controller/workbenches_controller.go:146]
- **controller**: WorkbenchesReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: internal/controller/workbenches_controller.go:159, internal/controller/workbenches_controller.go:809]
- **webhook**: connection-notebook.opendatahub.io —served-by→ workbenches-operator-webhook-service; admission webhook declares an explicit service reference [source: config/default/webhook_openshift_patch.yaml:1, config/default/webhookconfig_openshift_patch.yaml:1, internal/webhook/notebook/mutating.go:55]
- **webhook**: hardwareprofile-notebook-injector.opendatahub.io —served-by→ workbenches-operator-webhook-service; admission webhook declares an explicit service reference [source: config/default/webhook_openshift_patch.yaml:1, config/default/webhookconfig_openshift_patch.yaml:1, internal/webhook/hardwareprofile/mutating.go:67]

## Gap Evidence Index

### authentication

- **Question:** How is this runtime security control wired to the serving surface?
  **Expected signal:** flag/default, certificate, middleware, or enforcement point
  **Candidate:** `cmd/main.go`:145 (controller-runtime metrics, controller-runtime metrics authn/authz filter)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/main.go`:213 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `internal/webhook/tls/ensure.go`:68 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/leader_election_role.yaml`:1 (workbenches-operator-leader-election-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/rbac/leader_election_role_binding.yaml`:1 (workbenches-operator-leader-election-role, workbenches-operator-leader-election-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/rbac_escalate_role.yaml`:7 (workbenches-operator-manager-rbac-escalate-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/rbac/rbac_escalate_role_binding.yaml`:1 (workbenches-operator-manager-rbac-escalate-role, workbenches-operator-manager-rbac-escalate-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/role.yaml`:2 (workbenches-operator-manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/rbac/role_binding.yaml`:1 (workbenches-operator-manager-role, workbenches-operator-manager-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/webhook_tls_role.yaml`:1 (workbenches-operator-webhook-tls-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/rbac/webhook_tls_role_binding.yaml`:1 (workbenches-operator-webhook-tls-role, workbenches-operator-webhook-tls-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:27 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:27 (Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/main.go`:67 (cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `internal/webhook/tls/ensure.go`:68 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `internal/webhook/tls/ensurer.go`:51 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/main.go`:213 (/healthz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (Certificate CR, cert-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/crd/bases/components.platform.opendatahub.io_workbenches.yaml`:79 (DSC MLflowOperator, Indirect (via orchestrator))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/crd/bases/components.platform.opendatahub.io_workbenches.yaml:56; config/crd/bases/components.platform.opendatahub.io_workbenches.yaml:79; config/crd/bases/components.platform.opendatahub.io_workbenches.yaml`:84 (CR field projection, Platform orchestrator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, cert-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/imagestreams.go`:52 (image.openshift.io/v1/ImageStream, list operations by WorkbenchesReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/workbenches_controller.go`:708 (/v1/Namespace, create, get, update operations by WorkbenchesReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/platformconfig/config.go`:80 (/v1/ConfigMap, get operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/webhook/hardwareprofile/mutating.go`:356 (/v1/Event, create operations by Injector)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/webhook/notebook/mutating.go`:322 (/v1/Secret, get operations by NotebookWebhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/webhook/tls/ensure.go`:150 (/v1/Service, get, patch operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/controller/imagestreams.go`:52 (image.openshift.io/v1/ImageStream, list operations by WorkbenchesReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/controller/workbenches_controller.go`:708 (/v1/Namespace, create, get, update operations by WorkbenchesReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/workbenches_controller.go`:148 (/v1/ConfigMap, WorkbenchesReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/platformconfig/config.go`:80 (/v1/ConfigMap, get operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/webhook/hardwareprofile/mutating.go`:356 (/v1/Event, create operations by Injector)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/webhook/notebook/mutating.go`:322 (/v1/Secret, get operations by NotebookWebhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/webhook/tls/ensure.go`:150 (/v1/Service, get, patch operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `config/base/manager_webhook_patch.yaml`:1 (workbenches-operator-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `config/default/webhook_openshift_patch.yaml`:1 (workbenches-operator-controller-manager, workbenches-operator-webhook-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### webhooks

- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/default/webhookconfig_openshift_patch.yaml`:1 (/workbenches-hardware-profile, hardwareprofile-notebook-injector.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/webhook/manifests.yaml`:2 (/workbenches-hardware-profile, hardwareprofile-notebook-injector.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/hardwareprofile/mutating.go`:67 (/workbenches-hardware-profile, hardwareprofile-notebook-injector.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/notebook/mutating.go`:55 (/workbenches-connection-notebook, connection-notebook.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `opt/manifests/workbenches/kf-notebook-controller/crd/patches/webhook_in_notebooks.yaml`:4 (/convert, notebooks.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: cmd/main.go:213]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/main.go:218]
- :8443/metrics methods=GET mechanism=TokenReview + SubjectAccessReview (controller-runtime authn/authz filter) enforcement=controller-runtime FilterProvider (WithAuthenticationAndAuthorization) policy=RBAC via metrics review role; metrics-bind-address patch exposes port 8443; metrics-secure defaults true [source: cmd/main.go:145]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via workbenches-operator-manager-role ClusterRole; SA workbenches-operator-controller-manager [source: internal/webhook/tls/ensure.go:68]
- Webhook (port 9443) methods=HTTPS mechanism=TLS serving certificate (server identity) enforcement=controller-runtime webhook server policy=API server validates the OpenShift service-ca serving certificate workbenches-operator-controller-webhook-cert; server is enabled conditionally by controller configuration [source: cmd/main.go:159]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/main.go:213]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/main.go:218]
### integrations

- HardwareProfile CR interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage hardware profile resources [source: config/rbac/role.yaml:2]
- Kubeflow Notebooks interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Create and manage notebook workbenches [source: config/rbac/role.yaml:2]
- OpenShift Image Streams interaction=REST role=runtime-transport protocol=HTTPS purpose=Image stream access [source: config/rbac/role.yaml:2]
- cert-manager interaction=Certificate CR role=unknown protocol=HTTPS purpose=Manage TLS certificates through cert-manager CRDs [source: config/rbac/role.yaml:2]
### internal_dependencies

- DSC MLflowOperator interaction=Indirect (via orchestrator) role=unknown purpose=Source of mlflowEnabled state projected into Workbenches CR spec [source: config/crd/bases/components.platform.opendatahub.io_workbenches.yaml:79]
- GatewayConfig interaction=Indirect (via orchestrator) role=unknown purpose=Source of gatewayDomain projected into Workbenches CR spec [source: config/crd/bases/components.platform.opendatahub.io_workbenches.yaml:56]
- HardwareProfile CR interaction=CRD CRUD role=unknown purpose=Manage hardware profile resources [source: config/rbac/role.yaml:2]
- Kubeflow Notebooks (kubeflow.org) interaction=CRD CRUD role=unknown purpose=Create and manage notebook workbenches [source: config/rbac/role.yaml:2]
- Platform orchestrator interaction=CR field projection role=unknown purpose=Projects gatewayDomain, mlflowEnabled, platform into Workbenches CR spec [source: config/crd/bases/components.platform.opendatahub.io_workbenches.yaml:56; config/crd/bases/components.platform.opendatahub.io_workbenches.yaml:79; config/crd/bases/components.platform.opendatahub.io_workbenches.yaml:84]
- cert-manager interaction=CRD CRUD role=unknown purpose=Manage TLS certificates through cert-manager CRDs [source: config/rbac/role.yaml:2]
### services

- workbenches-operator-webhook-service port=443 target=9443 protocol=TCP encryption= auth= [source: config/default/webhook_openshift_patch.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload workbenches-operator-controller-manager uses service account workbenches-operator-controller-manager and 1 container(s) [source: config/base/manager_webhook_patch.yaml:1]
- **observed**: Service workbenches-operator-webhook-service targets workbenches-operator-controller-manager with 1 port(s) [source: config/default/webhook_openshift_patch.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by cmd [source: cmd/main.go:213]
- **observed**: HTTP GET /readyz is owned by cmd [source: cmd/main.go:218]
### security

- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: cmd/main.go:213]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/main.go:218]
- **observed**: GET :8443/metrics uses TokenReview + SubjectAccessReview (controller-runtime authn/authz filter) at controller-runtime FilterProvider (WithAuthenticationAndAuthorization); policy=RBAC via metrics review role; metrics-bind-address patch exposes port 8443; metrics-secure defaults true [source: cmd/main.go:145]
- **observed**: HTTPS Webhook (port 9443) uses TLS serving certificate (server identity) at controller-runtime webhook server; policy=API server validates the OpenShift service-ca serving certificate workbenches-operator-controller-webhook-cert; server is enabled conditionally by controller configuration [source: cmd/main.go:159]
- **observed**: RBAC role leader-election-role grants 3 rule(s) [source: config/rbac/leader_election_role.yaml:1]
- **observed**: RBAC role manager-rbac-escalate-role grants 1 rule(s) [source: config/rbac/rbac_escalate_role.yaml:7]
- **observed**: RBAC role manager-role grants 16 rule(s) [source: config/rbac/role.yaml:2]
- **observed**: RBAC role webhook-tls-role grants 1 rule(s) [source: config/rbac/webhook_tls_role.yaml:1]
- **observed**: RBAC role workbenches-operator-leader-election-role grants 3 rule(s) [source: config/rbac/leader_election_role.yaml:1]
- **observed**: RBAC role workbenches-operator-manager-rbac-escalate-role grants 1 rule(s) [source: config/rbac/rbac_escalate_role.yaml:7]
- **observed**: RBAC role workbenches-operator-manager-role grants 16 rule(s) [source: config/rbac/role.yaml:2]
- **observed**: RBAC role workbenches-operator-webhook-tls-role grants 1 rule(s) [source: config/rbac/webhook_tls_role.yaml:1]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via workbenches-operator-manager-role ClusterRole; SA workbenches-operator-controller-manager [source: internal/webhook/tls/ensure.go:68]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: internal/tlsconfig/tlsconfig.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
