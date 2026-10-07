# Analyzer Synthesis Context: kf-poc-rhods-operator

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 3 crds facts extracted [source: config/crd/bases/datasciencecluster.opendatahub.io_datascienceclusters.yaml:2, config/crd/bases/dscinitialization.opendatahub.io_dscinitializations.yaml:2, config/crd/bases/features.opendatahub.io_featuretrackers.yaml:2]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 2 http_endpoints facts extracted [source: main.go:315, main.go:319]
- **services (observed)**: 4 services facts extracted [source: components/kserve/resources/servicemesh/routing/kserve-local-gateway-svc.tmpl.yaml:1, components/kserve/resources/servicemesh/routing/local-gateway-svc.tmpl.yaml:1, config/rbac/auth_proxy_service.yaml:1, config/webhook/service.yaml:2]
- **ingress (observed)**: 3 ingress facts extracted [source: components/kserve/resources/servicemesh/routing/istio-ingress-gateway.tmpl.yaml:1, components/kserve/resources/servicemesh/routing/istio-kserve-local-gateway.tmpl.yaml:2, components/kserve/resources/servicemesh/routing/istio-local-gateway.yaml:1]
- **webhooks (observed)**: 5 webhooks facts extracted [source: config/crd/patches/webhook_in_datasciencecluster_datascienceclusters.yaml:3, config/crd/patches/webhook_in_dscinitialization.opendatahub.io_dscinitializations.yaml:3, config/crd/patches/webhook_in_dscinitialization_dscinitializations.yaml:3, config/webhook/manifests.yaml:2, config/webhook/manifests.yaml:28, controllers/webhook/webhook.go:128, controllers/webhook/webhook.go:40]

## Deterministic Cross-References

- **controller**: CertConfigmapGeneratorReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: components/kserve/kserve_config_handler.go:58, controllers/certconfigmapgenerator/certconfigmapgenerator_controller.go:39]
- **controller**: CertConfigmapGeneratorReconciler —watches-reference→ /v1/Namespace; /v1/Namespace [source: controllers/certconfigmapgenerator/certconfigmapgenerator_controller.go:40, controllers/certconfigmapgenerator/certconfigmapgenerator_controller.go:51]
- **controller**: DSCInitializationReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: components/kserve/kserve_config_handler.go:58, controllers/dscinitialization/dscinitialization_controller.go:279]
- **controller**: DSCInitializationReconciler —watches-reference→ /v1/Namespace; /v1/Namespace [source: controllers/certconfigmapgenerator/certconfigmapgenerator_controller.go:51, controllers/dscinitialization/dscinitialization_controller.go:273]
- **controller**: DSCInitializationReconciler —watches-reference→ /v1/Secret; /v1/Secret [source: components/dashboard/dashboard.go:223, controllers/dscinitialization/dscinitialization_controller.go:276]
- **controller**: DSCInitializationReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: controllers/dscinitialization/dscinitialization_controller.go:297, controllers/dscinitialization/monitoring.go:318]
- **controller**: DSCInitializationReconciler —watches-reference→ datasciencecluster/v1/DataScienceCluster; datasciencecluster/v1/DataScienceCluster [source: controllers/datasciencecluster/datasciencecluster_controller.go:96, controllers/dscinitialization/dscinitialization_controller.go:309]
- **controller**: DSCInitializationReconciler —watches-reference→ dscinitialization/v1/DSCInitialization; dscinitialization/v1/DSCInitialization [source: controllers/certconfigmapgenerator/certconfigmapgenerator_controller.go:57, controllers/dscinitialization/dscinitialization_controller.go:269]
- **controller**: DSCInitializationReconciler —watches-reference→ networking.k8s.io/v1/NetworkPolicy; networking.k8s.io/v1/NetworkPolicy [source: controllers/dscinitialization/dscinitialization_controller.go:282, controllers/dscinitialization/utils.go:290]
- **controller**: DSCInitializationReconciler —watches-reference→ rbac.authorization.k8s.io/v1/ClusterRole; rbac.authorization.k8s.io/v1/ClusterRole [source: controllers/dscinitialization/dscinitialization_controller.go:291, pkg/cluster/roles.go:26]
- **controller**: DSCInitializationReconciler —watches-reference→ rbac.authorization.k8s.io/v1/ClusterRoleBinding; rbac.authorization.k8s.io/v1/ClusterRoleBinding [source: controllers/dscinitialization/dscinitialization_controller.go:294, pkg/cluster/roles.go:66]
- **controller**: DSCInitializationReconciler —watches-reference→ rbac.authorization.k8s.io/v1/RoleBinding; rbac.authorization.k8s.io/v1/RoleBinding [source: controllers/dscinitialization/dscinitialization_controller.go:288, controllers/dscinitialization/utils.go:170]
- **controller**: DSCInitializationReconciler —watches-reference→ route.openshift.io/v1/Route; route.openshift.io/v1/Route [source: controllers/dscinitialization/dscinitialization_controller.go:306, controllers/dscinitialization/monitoring.go:264]
- **controller**: DataScienceClusterReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: components/kserve/kserve_config_handler.go:58, controllers/datasciencecluster/datasciencecluster_controller.go:466]
- **controller**: DataScienceClusterReconciler —watches-reference→ /v1/Namespace; /v1/Namespace [source: controllers/certconfigmapgenerator/certconfigmapgenerator_controller.go:51, controllers/datasciencecluster/datasciencecluster_controller.go:464]
- **controller**: DataScienceClusterReconciler —watches-reference→ /v1/Secret; /v1/Secret [source: components/dashboard/dashboard.go:223, controllers/datasciencecluster/datasciencecluster_controller.go:465]
- **controller**: DataScienceClusterReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: controllers/datasciencecluster/datasciencecluster_controller.go:486, controllers/dscinitialization/monitoring.go:318]
- **controller**: DataScienceClusterReconciler —watches-reference→ datasciencecluster/v1/DataScienceCluster; datasciencecluster/v1/DataScienceCluster [source: controllers/datasciencecluster/datasciencecluster_controller.go:463, controllers/datasciencecluster/datasciencecluster_controller.go:96]
- **controller**: DataScienceClusterReconciler —watches-reference→ dscinitialization/v1/DSCInitialization; dscinitialization/v1/DSCInitialization [source: controllers/certconfigmapgenerator/certconfigmapgenerator_controller.go:57, controllers/datasciencecluster/datasciencecluster_controller.go:507]
- **controller**: DataScienceClusterReconciler —watches-reference→ networking.k8s.io/v1/NetworkPolicy; networking.k8s.io/v1/NetworkPolicy [source: controllers/datasciencecluster/datasciencecluster_controller.go:470, controllers/dscinitialization/utils.go:290]
- **controller**: DataScienceClusterReconciler —watches-reference→ rbac.authorization.k8s.io/v1/ClusterRole; rbac.authorization.k8s.io/v1/ClusterRole [source: controllers/datasciencecluster/datasciencecluster_controller.go:480, pkg/cluster/roles.go:26]
- **controller**: DataScienceClusterReconciler —watches-reference→ rbac.authorization.k8s.io/v1/ClusterRoleBinding; rbac.authorization.k8s.io/v1/ClusterRoleBinding [source: controllers/datasciencecluster/datasciencecluster_controller.go:483, pkg/cluster/roles.go:66]
- **controller**: DataScienceClusterReconciler —watches-reference→ rbac.authorization.k8s.io/v1/RoleBinding; rbac.authorization.k8s.io/v1/RoleBinding [source: controllers/datasciencecluster/datasciencecluster_controller.go:477, controllers/dscinitialization/utils.go:170]
- **controller**: SecretGeneratorReconciler —watches-reference→ /v1/Secret; /v1/Secret [source: components/dashboard/dashboard.go:223, controllers/secretgenerator/secretgenerator_controller.go:87]
- **webhook**: mutate.operator.opendatahub.io —served-by→ redhat-ods-operator-webhook-service; admission webhook declares an explicit service reference [source: config/webhook/manifests.yaml:2, config/webhook/service.yaml:2, controllers/webhook/webhook.go:128]
- **webhook**: operator.opendatahub.io —served-by→ redhat-ods-operator-webhook-service; admission webhook declares an explicit service reference [source: config/webhook/manifests.yaml:28, config/webhook/service.yaml:2, controllers/webhook/webhook.go:40]

## Behavioral Evidence

- **conditional-metrics-enforcement (unresolved)** controller-runtime metrics: controller-runtime metrics serving surface; limitations=The controller-runtime manager Metrics binding does not use one direct lexical options object with a stable SecureServing condition [source: main.go:185-185]
- **named-watch-predicate (unresolved)** controllers/certconfigmapgenerator.CertConfigmapGeneratorReconciler: /v1/ConfigMap; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: controllers/certconfigmapgenerator/certconfigmapgenerator_controller.go:39-39]
- **named-watch-predicate (unresolved)** controllers/certconfigmapgenerator.CertConfigmapGeneratorReconciler: /v1/Namespace; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: controllers/certconfigmapgenerator/certconfigmapgenerator_controller.go:40-40]
- **named-watch-predicate (unresolved)** controllers/datasciencecluster.DataScienceClusterReconciler: /v1/ConfigMap; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: controllers/datasciencecluster/datasciencecluster_controller.go:513-519]
- **named-watch-predicate (unresolved)** controllers/datasciencecluster.DataScienceClusterReconciler: apiextensions/v1/CustomResourceDefinition; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: controllers/datasciencecluster/datasciencecluster_controller.go:520-526]
- **named-watch-predicate (unresolved)** controllers/datasciencecluster.DataScienceClusterReconciler: /v1/Secret; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: controllers/datasciencecluster/datasciencecluster_controller.go:527-532]
- **named-watch-predicate (unresolved)** controllers/dscinitialization.DSCInitializationReconciler: datasciencecluster.opendatahub.io/v1/DataScienceCluster; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: controllers/dscinitialization/dscinitialization_controller.go:309-315]
- **named-watch-predicate (unresolved)** controllers/dscinitialization.DSCInitializationReconciler: /v1/Secret; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: controllers/dscinitialization/dscinitialization_controller.go:316-320]
- **named-watch-predicate (unresolved)** controllers/dscinitialization.DSCInitializationReconciler: /v1/ConfigMap; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: controllers/dscinitialization/dscinitialization_controller.go:321-325]
- **named-watch-predicate (unresolved)** controllers/secretgenerator.SecretGeneratorReconciler: /v1/Secret; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: controllers/secretgenerator/secretgenerator_controller.go:88-95]

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `config/webhook/manifests.yaml`:28 (Kubernetes admission, Operator webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `main.go`:183 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Under which configuration branch does the metrics serving surface install authentication and authorization?
  **Expected signal:** a direct SecureServing condition and controller-runtime authn/authz FilterProvider assignment
  **Candidate:** `main.go`:185-185 (controller-runtime metrics, controller-runtime metrics serving surface)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `main.go`:186 (TLS serving certificate (server identity), Webhook (port 9443))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `main.go`:315 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `main.go`:319 (:8081/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/auth_proxy_client_clusterrole.yaml`:1 (metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/auth_proxy_client_clusterrole.yaml`:1 (redhat-ods-operator-metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/datasciencecluster_datasciencecluster_editor_role.yaml`:2 (datasciencecluster-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/datasciencecluster_datasciencecluster_viewer_role.yaml`:2 (datasciencecluster-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/dscinitialization_dscinitialization_editor_role.yaml`:2 (dscinitialization-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/dscinitialization_dscinitialization_viewer_role.yaml`:2 (dscinitialization-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/role.yaml`:2 (controller-manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/role.yaml`:2 (redhat-ods-operator-controller-manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/rbac/role_binding.yaml`:1 (controller-manager-role, controller-manager-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/rbac/role_binding.yaml`:1 (redhat-ods-operator-controller-manager-role, redhat-ods-operator-controller-manager-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfiles/Dockerfile`:61 (Dockerfiles/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime behavior depends on this configuration default, and can deployment values override it?
  **Expected signal:** default value, environment/config key, flag, or override branch
  **Candidate:** `apis/infrastructure/v1/serverless_types.go`:16 (Serving.Name)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime behavior depends on this configuration default, and can deployment values override it?
  **Expected signal:** default value, environment/config key, flag, or override branch
  **Candidate:** `apis/infrastructure/v1/servicemesh_types.go`:19 (ControlPlane.Name)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime behavior depends on this configuration default, and can deployment values override it?
  **Expected signal:** default value, environment/config key, flag, or override branch
  **Candidate:** `apis/infrastructure/v1/servicemesh_types.go`:22 (ControlPlane.Namespace)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `main.go`:104 (v2)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `main.go`:183 (Kubernetes API, controller-runtime manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `main.go`:315 (/healthz, GET, main)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `main.go`:319 (/readyz, GET, main)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (API client, Kubernetes API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (AcceleratorProfile CR, CRD CRUD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, ModelRegistry CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, ServingRuntime CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (CRD Watch, DSCInitialization CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (CRD Watch, DataScienceCluster CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (CRD Watch, KServe InferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (CRD Watch, OLM (operators.coreos.com))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (CRD Watch, OpenShift Console)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (Certificate CR, cert-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (OpenShift Image Streams, REST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `components/dashboard/dashboard.go`:223 (/v1/Secret, create, delete, get, update operations by DSCInitializationReconciler, Dashboard, ModelRegistry, SecretGeneratorReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `components/kserve/kserve_config_handler.go`:108 (/v1/Pod, list operations by Kserve)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `components/kserve/kserve_config_handler.go`:58 (/v1/ConfigMap, create, delete, get, list, update operations by DSCInitializationReconciler, Kserve)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, ModelRegistry (modelregistry.opendatahub.io))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, cert-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRD Watch, DSCInitialization CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRD Watch, DataScienceCluster CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRD Watch, KServe InferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (Kubernetes API (persistent volumes), list)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `controllers/certconfigmapgenerator/certconfigmapgenerator_controller.go`:51 (/v1/Namespace, create, delete, get, list, patch, update operations by CertConfigmapGeneratorReconciler, DSCInitializationReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `controllers/dscinitialization/monitoring.go`:318 (apps/v1/Deployment, delete, get, list operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `controllers/certconfigmapgenerator/certconfigmapgenerator_controller.go`:39-39 (/v1/ConfigMap, controllers/certconfigmapgenerator.CertConfigmapGeneratorReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `controllers/certconfigmapgenerator/certconfigmapgenerator_controller.go`:40-40 (/v1/Namespace, controllers/certconfigmapgenerator.CertConfigmapGeneratorReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/datasciencecluster/datasciencecluster_controller.go`:464 (/v1/Namespace, DataScienceClusterReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/datasciencecluster/datasciencecluster_controller.go`:466 (/v1/ConfigMap, DataScienceClusterReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `controllers/datasciencecluster/datasciencecluster_controller.go`:513-519 (/v1/ConfigMap, controllers/datasciencecluster.DataScienceClusterReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `controllers/datasciencecluster/datasciencecluster_controller.go`:520-526 (apiextensions/v1/CustomResourceDefinition, controllers/datasciencecluster.DataScienceClusterReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `controllers/datasciencecluster/datasciencecluster_controller.go`:527-532 (/v1/Secret, controllers/datasciencecluster.DataScienceClusterReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/dscinitialization/dscinitialization_controller.go`:279 (/v1/ConfigMap, DSCInitializationReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `controllers/dscinitialization/dscinitialization_controller.go`:309-315 (controllers/dscinitialization.DSCInitializationReconciler, datasciencecluster.opendatahub.io/v1/DataScienceCluster)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `controllers/dscinitialization/dscinitialization_controller.go`:316-320 (/v1/Secret, controllers/dscinitialization.DSCInitializationReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `controllers/dscinitialization/dscinitialization_controller.go`:321-325 (/v1/ConfigMap, controllers/dscinitialization.DSCInitializationReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `controllers/secretgenerator/secretgenerator_controller.go`:88-95 (/v1/Secret, controllers/secretgenerator.SecretGeneratorReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `components/kserve/resources/servicemesh/routing/kserve-local-gateway-svc.tmpl.yaml`:1 (kserve-local-gateway)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `components/kserve/resources/servicemesh/routing/local-gateway-svc.tmpl.yaml`:1 (knative-local-gateway)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `config/default/manager_webhook_patch.yaml`:1 (redhat-ods-operator-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `config/rbac/auth_proxy_service.yaml`:1 (redhat-ods-operator-controller-manager, redhat-ods-operator-controller-manager-metrics-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `config/webhook/service.yaml`:2 (redhat-ods-operator-controller-manager, redhat-ods-operator-webhook-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `controllers/dscinitialization/resources/authorino/deployment.injection.patch.tmpl.yaml`:1 ({template-value})
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### webhooks

- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/crd/patches/webhook_in_datasciencecluster_datascienceclusters.yaml`:3 (/convert, datascienceclusters.datasciencecluster.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/crd/patches/webhook_in_dscinitialization.opendatahub.io_dscinitializations.yaml`:3 (/convert, datascienceclusters.datasciencecluster.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/crd/patches/webhook_in_dscinitialization_dscinitializations.yaml`:3 (/convert, datascienceclusters.datasciencecluster.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/webhook/manifests.yaml`:2 (/mutate-opendatahub-io-v1, mutate.operator.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/webhook/manifests.yaml`:28 (/validate-opendatahub-io-v1, operator.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `controllers/webhook/webhook.go`:128 (/mutate-opendatahub-io-v1, mutate.operator.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `controllers/webhook/webhook.go`:40 (/validate-opendatahub-io-v1, operator.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: main.go:315]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: main.go:319]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via redhat-ods-operator-controller-manager-role ClusterRole; SA redhat-ods-operator-controller-manager [source: main.go:183]
- Operator webhook methods=CREATE mechanism=Kubernetes admission enforcement=ValidatingWebhookConfiguration policy=Admission validation [source: config/webhook/manifests.yaml:28]
- Webhook (port 9443) methods=HTTPS mechanism=TLS serving certificate (server identity) enforcement=controller-runtime webhook server policy=API server validates the OpenShift service-ca serving certificate redhat-ods-operator-controller-webhook-cert [source: main.go:186]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: main.go:315]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: main.go:319]
### integrations

- AcceleratorProfile CR interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage hardware accelerator profiles [source: config/rbac/role.yaml:2]
- DSCInitialization CR interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read platform initialization state [source: config/rbac/role.yaml:2]
- DataScienceCluster CR interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read enabled platform components [source: config/rbac/role.yaml:2]
- KServe InferenceService interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read model serving state [source: config/rbac/role.yaml:2]
- Kubernetes API interaction=API client role=runtime-integration protocol=HTTPS purpose=Cluster resource management via RBAC [source: config/rbac/role.yaml:2]
- ModelRegistry CR interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage model registry instances [source: config/rbac/role.yaml:2]
- OLM (operators.coreos.com) interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Operator subscription status [source: config/rbac/role.yaml:2]
- OpenShift Console interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Console link resources [source: config/rbac/role.yaml:2]
- OpenShift Image Streams interaction=REST role=runtime-transport protocol=HTTPS purpose=Image stream access [source: config/rbac/role.yaml:2]
- OpenShift Routes interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Dashboard route status [source: config/rbac/role.yaml:2]
- OpenShift Users/Groups interaction=REST role=runtime-transport protocol=HTTPS purpose=User and group management [source: config/rbac/role.yaml:2]
- ServingRuntime CR interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage serving runtime templates [source: config/rbac/role.yaml:2]
- cert-manager interaction=Certificate CR role=unknown protocol=HTTPS purpose=Manage TLS certificates through cert-manager CRDs [source: config/rbac/role.yaml:2]
- prometheus-operator interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage Prometheus monitoring resources [source: config/rbac/role.yaml:2]
### internal_dependencies

- DSCInitialization CR interaction=CRD Watch role=runtime-integration purpose=Read platform initialization state [source: config/rbac/role.yaml:2]
- DataScienceCluster CR interaction=CRD Watch role=runtime-integration purpose=Read enabled platform components [source: config/rbac/role.yaml:2]
- KServe InferenceService interaction=CRD Watch role=runtime-integration purpose=Read model serving state [source: config/rbac/role.yaml:2]
- Kubernetes API (persistent volumes) interaction=list role=unknown purpose=persistentvolumes resource access via RBAC [source: config/rbac/role.yaml:2]
- ModelRegistry (modelregistry.opendatahub.io) interaction=CRD CRUD role=unknown purpose=Manage model registry instances [source: config/rbac/role.yaml:2]
- cert-manager interaction=CRD CRUD role=unknown purpose=Manage TLS certificates through cert-manager CRDs [source: config/rbac/role.yaml:2]
- prometheus-operator interaction=CRD CRUD role=unknown purpose=Manage Prometheus monitoring resources [source: config/rbac/role.yaml:2]
### services

- knative-local-gateway port=80 target=8081 protocol=TCP encryption= auth= [source: components/kserve/resources/servicemesh/routing/local-gateway-svc.tmpl.yaml:1]
- kserve-local-gateway port=443 target=8445 protocol=TCP encryption= auth= [source: components/kserve/resources/servicemesh/routing/kserve-local-gateway-svc.tmpl.yaml:1]
- redhat-ods-operator-controller-manager-metrics-service port=8443 target=8080 protocol=TCP encryption= auth= [source: config/rbac/auth_proxy_service.yaml:1]
- redhat-ods-operator-webhook-service port=443 target=9443 protocol=TCP encryption= auth= [source: config/webhook/service.yaml:2]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Controller-created Deployment workload {template-value} uses service account  and 0 container(s) [source: controllers/dscinitialization/resources/authorino/deployment.injection.patch.tmpl.yaml:1]
- **observed**: Deployment workload redhat-ods-operator-controller-manager uses service account redhat-ods-operator-controller-manager and 1 container(s) [source: config/default/manager_webhook_patch.yaml:1]
- **observed**: Service knative-local-gateway targets  with 1 port(s) [source: components/kserve/resources/servicemesh/routing/local-gateway-svc.tmpl.yaml:1]
- **observed**: Service kserve-local-gateway targets  with 1 port(s) [source: components/kserve/resources/servicemesh/routing/kserve-local-gateway-svc.tmpl.yaml:1]
- **observed**: Service redhat-ods-operator-controller-manager-metrics-service targets redhat-ods-operator-controller-manager with 1 port(s) [source: config/rbac/auth_proxy_service.yaml:1]
- **observed**: Service redhat-ods-operator-webhook-service targets redhat-ods-operator-controller-manager with 1 port(s) [source: config/webhook/service.yaml:2]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: Gateway knative-ingress-gateway serves host  via plaintext; backend=; transport=Unknown [source: components/kserve/resources/servicemesh/routing/istio-ingress-gateway.tmpl.yaml:1]
- **observed**: Gateway knative-local-gateway serves host  via plaintext; backend=; transport=Unknown [source: components/kserve/resources/servicemesh/routing/istio-local-gateway.yaml:1]
- **observed**: Gateway kserve-local-gateway serves host  via plaintext; backend=; transport=Unknown [source: components/kserve/resources/servicemesh/routing/istio-kserve-local-gateway.tmpl.yaml:2]
- **observed**: HTTP GET /healthz is owned by main [source: main.go:315]
- **observed**: HTTP GET /readyz is owned by main [source: main.go:319]
### security

- **observed**: CREATE Operator webhook uses Kubernetes admission at ValidatingWebhookConfiguration; policy=Admission validation [source: config/webhook/manifests.yaml:28]
- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: main.go:315]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: main.go:319]
- **observed**: HTTPS Webhook (port 9443) uses TLS serving certificate (server identity) at controller-runtime webhook server; policy=API server validates the OpenShift service-ca serving certificate redhat-ods-operator-controller-webhook-cert [source: main.go:186]
- **observed**: RBAC role controller-manager-role grants 89 rule(s) [source: config/rbac/role.yaml:2]
- **observed**: RBAC role datasciencecluster-editor-role grants 2 rule(s) [source: config/rbac/datasciencecluster_datasciencecluster_editor_role.yaml:2]
- **observed**: RBAC role datasciencecluster-viewer-role grants 2 rule(s) [source: config/rbac/datasciencecluster_datasciencecluster_viewer_role.yaml:2]
- **observed**: RBAC role dscinitialization-editor-role grants 2 rule(s) [source: config/rbac/dscinitialization_dscinitialization_editor_role.yaml:2]
- **observed**: RBAC role dscinitialization-viewer-role grants 2 rule(s) [source: config/rbac/dscinitialization_dscinitialization_viewer_role.yaml:2]
- **observed**: RBAC role metrics-reader grants 1 rule(s) [source: config/rbac/auth_proxy_client_clusterrole.yaml:1]
- **observed**: RBAC role redhat-ods-operator-controller-manager-role grants 89 rule(s) [source: config/rbac/role.yaml:2]
- **observed**: RBAC role redhat-ods-operator-metrics-reader grants 1 rule(s) [source: config/rbac/auth_proxy_client_clusterrole.yaml:1]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via redhat-ods-operator-controller-manager-role ClusterRole; SA redhat-ods-operator-controller-manager [source: main.go:183]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
