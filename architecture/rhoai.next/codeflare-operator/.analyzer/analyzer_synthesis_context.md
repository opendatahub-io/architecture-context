# Analyzer Synthesis Context: codeflare-operator

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 1 crds facts extracted [source: config/crd/crd-appwrapper.yml:1]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (not-verified)**: 0 http_endpoints facts extracted; absence is not proven by the available coverage
- **services (observed)**: 2 services facts extracted [source: config/default/metrics_service.yaml:1, config/webhook/service.yaml:1]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (observed)**: 8 webhooks facts extracted [source: config/webhook/manifests.yaml:2, config/webhook/manifests.yaml:48, pkg/controllers/appwrapper_webhook.go:20, pkg/controllers/appwrapper_webhook.go:21, pkg/controllers/raycluster_webhook.go:59, pkg/controllers/raycluster_webhook.go:60]

## Deterministic Cross-References

- **controller**: RayClusterReconciler —watches-reference→ rbac.authorization.k8s.io/v1/ClusterRoleBinding; rbac.authorization.k8s.io/v1/ClusterRoleBinding [source: pkg/controllers/raycluster_controller.go:146, pkg/controllers/raycluster_controller.go:685]
- **webhook**: mappwrapper.kb.io —served-by→ codeflare-operator-webhook-service; admission webhook declares an explicit service reference [source: config/webhook/manifests.yaml:2, config/webhook/service.yaml:1, pkg/controllers/appwrapper_webhook.go:20]
- **webhook**: mraycluster.ray.openshift.ai —served-by→ codeflare-operator-webhook-service; admission webhook declares an explicit service reference [source: config/webhook/manifests.yaml:2, config/webhook/service.yaml:1, pkg/controllers/raycluster_webhook.go:59]
- **webhook**: vappwrapper.kb.io —served-by→ codeflare-operator-webhook-service; admission webhook declares an explicit service reference [source: config/webhook/manifests.yaml:48, config/webhook/service.yaml:1, pkg/controllers/appwrapper_webhook.go:21]
- **webhook**: vraycluster.ray.openshift.ai —served-by→ codeflare-operator-webhook-service; admission webhook declares an explicit service reference [source: config/webhook/manifests.yaml:48, config/webhook/service.yaml:1, pkg/controllers/raycluster_webhook.go:60]

## Behavioral Evidence

- **conditional-metrics-enforcement (unresolved)** controller-runtime metrics: controller-runtime metrics serving surface; limitations=The controller-runtime manager Metrics binding does not use one direct lexical options object with a stable SecureServing condition [source: main.go:202-204]

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `config/webhook/manifests.yaml`:48 (Kubernetes admission, Operator webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `main.go`:158 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Under which configuration branch does the metrics serving surface install authentication and authorization?
  **Expected signal:** a direct SecureServing condition and controller-runtime authn/authz FilterProvider assignment
  **Candidate:** `main.go`:202-204 (controller-runtime metrics, controller-runtime metrics serving surface)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/appwrapper_editor_role.yaml`:2 (appwrapper-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/appwrapper_editor_role.yaml`:2 (codeflare-operator-appwrapper-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/appwrapper_viewer_role.yaml`:2 (codeflare-operator-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/appwrapper_viewer_role.yaml`:2 (viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/leader_election_role.yaml`:2 (codeflare-operator-leader-election-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/leader_election_role.yaml`:2 (leader-election-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/rbac/leader_election_role_binding.yaml`:1 (codeflare-operator-leader-election-role, codeflare-operator-leader-election-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/rbac/leader_election_role_binding.yaml`:1 (leader-election-role, leader-election-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/role.yaml`:2 (codeflare-operator-manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/role.yaml`:2 (manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/rbac/role_binding.yaml`:1 (codeflare-operator-manager-role, codeflare-operator-manager-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/rbac/role_binding.yaml`:1 (manager-role, manager-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:26 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:34 (Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `main.go`:102 (codeflare-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `main.go`:158 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pkg/controllers/raycluster_controller.go`:669 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (API client, Kubernetes API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, Kubeflow Notebooks)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (CRD Watch, DSCInitialization CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (CRD Watch, OpenShift Routes)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, Kubeflow Notebooks (kubeflow.org))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRD Watch, DSCInitialization CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (Kubernetes API (nodes), list)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `main.go`:30 (Go library, opendatahub-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `main.go`:375 (/v1/ConfigMap, create operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/controllers/raycluster_controller.go`:146 (delete operations by RayClusterReconciler, rbac.authorization.k8s.io/v1/ClusterRoleBinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `main.go`:375 (/v1/ConfigMap, create operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `pkg/controllers/raycluster_controller.go`:146 (delete operations by RayClusterReconciler, rbac.authorization.k8s.io/v1/ClusterRoleBinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controllers/raycluster_controller.go`:680 (RayClusterReconciler, ray/v1/RayCluster)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controllers/raycluster_controller.go`:681 (/v1/ServiceAccount, RayClusterReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controllers/raycluster_controller.go`:682 (/v1/Service, RayClusterReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controllers/raycluster_controller.go`:683 (RayClusterReconciler, networking.k8s.io/v1/Ingress)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controllers/raycluster_controller.go`:684 (RayClusterReconciler, networking.k8s.io/v1/NetworkPolicy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controllers/raycluster_controller.go`:685 (RayClusterReconciler, rbac.authorization.k8s.io/v1/ClusterRoleBinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controllers/raycluster_controller.go`:704 (RayClusterReconciler, route.openshift.io/v1/Route)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `config/default/manager_webhook_patch.yaml`:1 (codeflare-operator-controller-manager, codeflare-operator-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `config/default/metrics_service.yaml`:1 (codeflare-operator-manager, codeflare-operator-manager-metrics)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `config/webhook/service.yaml`:1 (codeflare-operator-manager, codeflare-operator-webhook-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### webhooks

- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/webhook/manifests.yaml`:2 (/mutate-ray-io-v1-raycluster, mraycluster.ray.openshift.ai)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/webhook/manifests.yaml`:2 (/mutate-workload-codeflare-dev-v1beta2-appwrapper, mappwrapper.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/webhook/manifests.yaml`:48 (/validate-ray-io-v1-raycluster, vraycluster.ray.openshift.ai)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/webhook/manifests.yaml`:48 (/validate-workload-codeflare-dev-v1beta2-appwrapper, vappwrapper.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/controllers/appwrapper_webhook.go`:20 (/mutate-workload-codeflare-dev-v1beta2-appwrapper, mappwrapper.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/controllers/appwrapper_webhook.go`:21 (/validate-workload-codeflare-dev-v1beta2-appwrapper, vappwrapper.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/controllers/raycluster_webhook.go`:59 (/mutate-ray-io-v1-raycluster, mraycluster.ray.openshift.ai)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/controllers/raycluster_webhook.go`:60 (/validate-ray-io-v1-raycluster, vraycluster.ray.openshift.ai)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via codeflare-operator-manager-role ClusterRole; SA codeflare-operator-controller-manager [source: main.go:158]
- Operator webhook methods=CREATE mechanism=Kubernetes admission enforcement=ValidatingWebhookConfiguration policy=Admission validation [source: config/webhook/manifests.yaml:48]
### integrations

- DSCInitialization CR interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read platform initialization state [source: config/rbac/role.yaml:2]
- Kubeflow Notebooks interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Create and manage notebook workbenches [source: config/rbac/role.yaml:2]
- Kubernetes API interaction=API client role=runtime-integration protocol=HTTPS purpose=Cluster resource management via RBAC [source: config/rbac/role.yaml:2]
- OpenShift Routes interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Dashboard route status [source: config/rbac/role.yaml:2]
### internal_dependencies

- DSCInitialization CR interaction=CRD Watch role=runtime-integration purpose=Read platform initialization state [source: config/rbac/role.yaml:2]
- Kubeflow Notebooks (kubeflow.org) interaction=CRD CRUD role=unknown purpose=Create and manage notebook workbenches [source: config/rbac/role.yaml:2]
- Kubernetes API (nodes) interaction=list role=unknown purpose=nodes resource access via RBAC [source: config/rbac/role.yaml:2]
- opendatahub-operator interaction=Go library role=runtime-library purpose=Use runtime packages from github.com/opendatahub-io/opendatahub-operator/v2 [source: main.go:30]
### services

- codeflare-operator-manager-metrics port=8080 target=metrics protocol=TCP encryption= auth= [source: config/default/metrics_service.yaml:1]
- codeflare-operator-webhook-service port=443 target=9443 protocol=TCP encryption= auth= [source: config/webhook/service.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload codeflare-operator-manager uses service account codeflare-operator-controller-manager and 1 container(s) [source: config/default/manager_webhook_patch.yaml:1]
- **observed**: Service codeflare-operator-manager-metrics targets codeflare-operator-manager with 1 port(s) [source: config/default/metrics_service.yaml:1]
- **observed**: Service codeflare-operator-webhook-service targets codeflare-operator-manager with 1 port(s) [source: config/webhook/service.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **observed**: CREATE Operator webhook uses Kubernetes admission at ValidatingWebhookConfiguration; policy=Admission validation [source: config/webhook/manifests.yaml:48]
- **observed**: RBAC role appwrapper-editor-role grants 2 rule(s) [source: config/rbac/appwrapper_editor_role.yaml:2]
- **observed**: RBAC role codeflare-operator-appwrapper-editor-role grants 2 rule(s) [source: config/rbac/appwrapper_editor_role.yaml:2]
- **observed**: RBAC role codeflare-operator-leader-election-role grants 3 rule(s) [source: config/rbac/leader_election_role.yaml:2]
- **observed**: RBAC role codeflare-operator-manager-role grants 31 rule(s) [source: config/rbac/role.yaml:2]
- **observed**: RBAC role codeflare-operator-viewer-role grants 2 rule(s) [source: config/rbac/appwrapper_viewer_role.yaml:2]
- **observed**: RBAC role leader-election-role grants 3 rule(s) [source: config/rbac/leader_election_role.yaml:2]
- **observed**: RBAC role manager-role grants 31 rule(s) [source: config/rbac/role.yaml:2]
- **observed**: RBAC role viewer-role grants 2 rule(s) [source: config/rbac/appwrapper_viewer_role.yaml:2]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via codeflare-operator-manager-role ClusterRole; SA codeflare-operator-controller-manager [source: main.go:158]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
