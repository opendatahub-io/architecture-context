# Analyzer Synthesis Context: rhods-operator

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 24 crds facts extracted [source: api/cloudmanager/aws/v1alpha1/awskubernetesengine_types.go:55, api/cloudmanager/azure/v1alpha1/azurekubernetesengine_types.go:55, api/cloudmanager/coreweave/v1alpha1/coreweavekubernetesengine_types.go:55, api/components/v1alpha1/kueue_types.go:45, api/config/v1alpha1/platform_types.go:127, api/config/v1alpha2/platform_types.go:126, api/datasciencecluster/v2/datasciencecluster_types.go:224, api/datasciencecluster/v3/datasciencecluster_types.go:175, api/dscinitialization/v1/dscinitialization_types.go:92, api/dscinitialization/v2/dscinitialization_types.go:85, api/infrastructure/v1/hardwareprofile_types.go:151, api/infrastructure/v1alpha1/hardwareprofile_types.go:150, api/services/v1alpha1/auth_types.go:57, api/services/v1alpha1/gateway_types.go:449, prefetched-manifests/datasciencepipelines/argo/crds/crd.applications.yaml:1, prefetched-manifests/datasciencepipelines/argo/crds/crd.clusterworkflowtemplates.yaml:1, prefetched-manifests/datasciencepipelines/argo/crds/crd.cronworkflows.yaml:1, prefetched-manifests/datasciencepipelines/argo/crds/crd.viewers.yaml:1, prefetched-manifests/datasciencepipelines/argo/crds/crd.workflowartifactgctasks.yaml:2, prefetched-manifests/datasciencepipelines/argo/crds/crd.workfloweventbinding.yaml:2, prefetched-manifests/datasciencepipelines/argo/crds/crd.workflows.yaml:1, prefetched-manifests/datasciencepipelines/argo/crds/crd.workflowtaskresult.yaml:2, prefetched-manifests/datasciencepipelines/argo/crds/crd.workflowtaskset.yaml:1, prefetched-manifests/datasciencepipelines/argo/crds/crd.workflowtemplate.yaml:1]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 4 http_endpoints facts extracted [source: cmd/cloudmanager/app/run.go:81, cmd/cloudmanager/app/run.go:85, cmd/main.go:552, cmd/main.go:556]
- **services (observed)**: 3 services facts extracted [source: config/default/metrics_service_patch.yaml:3, config/webhook/service.yaml:1, internal/controller/services/gateway/resources/kube-auth-proxy-svc.tmpl.yaml:1]
- **ingress (observed)**: 2 ingress facts extracted [source: internal/controller/services/gateway/resources/dashboard-redirect-legacy-gateway-route.tmpl.yaml:2, internal/controller/services/gateway/resources/kube-auth-proxy-httproute.tmpl.yaml:1]
- **webhooks (observed)**: 11 webhooks facts extracted [source: config/crd/patches/webhook_in_config_platforms.yaml:2, config/crd/patches/webhook_in_datasciencecluster_datascienceclusters.yaml:3, config/crd/patches/webhook_in_dscinitialization_dscinitializations.yaml:3, config/crd/patches/webhook_in_services_auths.yaml:3, internal/webhook/dashboard/validating_acceleratorprofile.go:22, internal/webhook/dashboard/validating_hardwareprofile.go:22, internal/webhook/datasciencecluster/v2/defaulting.go:22, internal/webhook/datasciencecluster/v2/validating.go:24, internal/webhook/datasciencecluster/v3/defaulting.go:24, internal/webhook/datasciencecluster/v3/validating.go:23, internal/webhook/dscinitialization/v1/validating.go:24, internal/webhook/dscinitialization/v2/validating.go:24, internal/webhook/gateway/validating.go:24, internal/webhook/monitoring/mutating.go:31, internal/webhook/monitoring/mutating.go:32]

## Deterministic Cross-References

- **controller**: ServiceHandler —watches-reference→ /v1/Namespace; /v1/Namespace [source: internal/controller/components/kueue/kueue_support.go:98, internal/controller/services/auth/auth_controller.go:63]
- **controller**: ServiceHandler —watches-reference→ /v1/Secret; /v1/Secret [source: internal/controller/services/gateway/gateway_certmanager.go:119, internal/controller/services/gateway/gateway_controller.go:167]
- **controller**: ServiceHandler —watches-reference→ /v1/Service; /v1/Service [source: internal/controller/services/gateway/gateway_controller.go:132, internal/controller/services/gateway/gateway_support.go:956]
- **controller**: ServiceHandler —watches-reference→ operator.openshift.io/v1/IngressController; operator.openshift.io/v1/IngressController [source: internal/controller/services/gateway/gateway_controller.go:137, pkg/cluster/cert.go:216]
- **controller**: ServiceHandler —watches-reference→ rbac.authorization.k8s.io/v1/ClusterRole; rbac.authorization.k8s.io/v1/ClusterRole [source: internal/controller/components/kueue/kueue_controller_actions.go:61, internal/controller/services/auth/auth_controller.go:60]
- **controller**: ServiceHandler —watches-reference→ rbac.authorization.k8s.io/v1/RoleBinding; rbac.authorization.k8s.io/v1/RoleBinding [source: internal/controller/services/auth/auth_controller.go:62, pkg/cluster/resources.go:245]
- **controller**: componentHandler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: internal/controller/components/kueue/kueue_config.go:66, internal/controller/components/kueue/kueue_controller.go:63]
- **controller**: componentHandler —watches-reference→ /v1/Namespace; /v1/Namespace [source: internal/controller/components/kueue/kueue_controller.go:150, internal/controller/components/kueue/kueue_support.go:98]
- **controller**: componentHandler —watches-reference→ /v1/Secret; /v1/Secret [source: internal/controller/components/kueue/kueue_controller.go:64, internal/controller/services/gateway/gateway_certmanager.go:119]
- **controller**: componentHandler —watches-reference→ /v1/Service; /v1/Service [source: internal/controller/components/kueue/kueue_controller.go:70, internal/controller/services/gateway/gateway_support.go:956]
- **controller**: componentHandler —watches-reference→ /v1/ServiceAccount; /v1/ServiceAccount [source: internal/controller/components/kueue/kueue_controller.go:69, pkg/webhook/utils.go:113]
- **controller**: componentHandler —watches-reference→ api/services/v1alpha1/Auth; api/services/v1alpha1/Auth [source: internal/controller/components/kueue/kueue_controller.go:161, internal/controller/components/kueue/kueue_controller_actions.go:81]
- **controller**: componentHandler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: internal/controller/components/kueue/kueue_controller.go:76, internal/controller/services/gateway/gateway_controller_actions.go:681]
- **controller**: componentHandler —watches-reference→ rbac.authorization.k8s.io/v1/ClusterRole; rbac.authorization.k8s.io/v1/ClusterRole [source: internal/controller/components/kueue/kueue_controller.go:66, internal/controller/components/kueue/kueue_controller_actions.go:61]
- **controller**: componentHandler —watches-reference→ rbac.authorization.k8s.io/v1/RoleBinding; rbac.authorization.k8s.io/v1/RoleBinding [source: internal/controller/components/kueue/kueue_controller.go:68, pkg/cluster/resources.go:245]
- **security**: GET /healthz —protected-by→ None; N/A: Kubernetes health probe; unauthenticated by design [source: cmd/cloudmanager/app/run.go:81]
- **security**: GET /readyz —protected-by→ None; N/A: Kubernetes readiness probe; unauthenticated by design [source: cmd/cloudmanager/app/run.go:85]

## Behavioral Evidence

- **conditional-metrics-enforcement (observed)** controller-runtime metrics: controller-runtime metrics serving surface; condition=oconfig.MetricsSecure is true; enforcement=filters.WithAuthenticationAndAuthorization [source: cmd/main.go:425-440]
- **named-watch-predicate (observed)** internal/controller/services/auth.ServiceHandler: /v1/Namespace; literal names=models-as-a-service; event target=services.platform.opendatahub.io/v1alpha1/Auth/auth [source: internal/controller/services/auth/auth_controller.go:63-69]
- **named-watch-predicate (observed)** internal/controller/services/auth.ServiceHandler: /v1/Namespace; literal names=kuadrant-system; event target=services.platform.opendatahub.io/v1alpha1/Auth/auth [source: internal/controller/services/auth/auth_controller.go:70-76]
- **named-watch-predicate (unresolved)** internal/controller/cloudmanager/aws.NewReconciler: apiextensions/v1/CustomResourceDefinition; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/cloudmanager/aws/awskubernetesengine_controller.go:28-32]
- **named-watch-predicate (unresolved)** internal/controller/cloudmanager/azure.NewReconciler: apiextensions/v1/CustomResourceDefinition; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/cloudmanager/azure/azurekubernetesengine_controller.go:28-32]
- **named-watch-predicate (unresolved)** internal/controller/cloudmanager/coreweave.NewReconciler: apiextensions/v1/CustomResourceDefinition; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/cloudmanager/coreweave/coreweavekubernetesengine_controller.go:28-32]
- **named-watch-predicate (unresolved)** internal/controller/components/kueue.componentHandler: apiextensions/v1/CustomResourceDefinition; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/components/kueue/kueue_controller.go:135-143]
- **named-watch-predicate (unresolved)** internal/controller/components/kueue.componentHandler: rbac.authorization.k8s.io/v1/ClusterRole; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/components/kueue/kueue_controller.go:144-149]
- **named-watch-predicate (unresolved)** internal/controller/components/kueue.componentHandler: /v1/Namespace; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/components/kueue/kueue_controller.go:150-160]
- **named-watch-predicate (unresolved)** internal/controller/components/kueue.componentHandler: /v1/ConfigMap; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/components/kueue/kueue_controller.go:77-84]
- **named-watch-predicate (unresolved)** internal/controller/datasciencecluster.NewDataScienceClusterReconciler: services.platform.opendatahub.io/v1alpha1/GatewayConfig; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/datasciencecluster/datasciencecluster_controller.go:72-77]
- **named-watch-predicate (unresolved)** internal/controller/datasciencecluster.NewDataScienceClusterReconciler: /v1/ConfigMap; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/datasciencecluster/datasciencecluster_controller.go:78-85]
- **named-watch-predicate (unresolved)** internal/controller/modules.NewModuleReconciler: /v1/ConfigMap; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/modules/modules_controller.go:108-116]
- **named-watch-predicate (unresolved)** internal/controller/modules.addModuleCRDWatches: apiextensions/v1/CustomResourceDefinition; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/modules/modules_controller.go:174-178]
- **named-watch-predicate (unresolved)** internal/controller/services/gateway.ServiceHandler: /v1/Service; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/services/gateway/gateway_controller.go:132-136]
- **named-watch-predicate (unresolved)** internal/controller/services/gateway.ServiceHandler: operator.openshift.io/v1/IngressController; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/services/gateway/gateway_controller.go:137-147]
- 6 additional behavioral records remain in the analyzer JSON.

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/cloudmanager/app/run.go`:81 (/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/cloudmanager/app/run.go`:85 (/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/main.go`:441 (TLS serving certificate (server identity), Webhook (port 9443))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/manifest-tools/pkg/applier/olm.go`:39 (Kubernetes API, kubeconfig credential chain)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `config/default/manager_webhook_patch.yaml`:1 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `config/default/manager_webhook_patch.yaml`:1 (:8081/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `internal/webhook/dashboard/validating_acceleratorprofile.go`:22 (Kubernetes admission, Operator webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `prefetched-manifests/datasciencepipelines/argo/clusterrole.argo-aggregate-to-admin.yaml`:2 (Argo Workflow CRDs (argoproj.io), RBAC aggregation (aggregate-to-admin/edit/view ClusterRoles))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `prefetched-manifests/datasciencepipelines/argo/clusterrole.argo-cluster-role.yaml`:1 (Argo Workflow agent secrets, RBAC with resourceNames restriction)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/auth_proxy_client_clusterrole.yaml`:1 (metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/auth_proxy_client_clusterrole.yaml`:1 (opendatahub-operator-metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/components_dashboard_editor_role.yaml`:2 (dashboard-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/components_dashboard_viewer_role.yaml`:2 (dashboard-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/components_kserve_editor_role.yaml`:2 (kserve-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/components_kserve_viewer_role.yaml`:2 (kserve-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/components_kueue_editor_role.yaml`:2 (kueue-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/components_kueue_viewer_role.yaml`:2 (kueue-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/components_modelregistry_editor_role.yaml`:2 (modelregistry-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/components_modelregistry_viewer_role.yaml`:2 (modelregistry-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/components_ray_editor_role.yaml`:2 (ray-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/components_ray_viewer_role.yaml`:2 (ray-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfiles/Dockerfile`:95 (Dockerfiles/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfiles/Dockerfile.konflux`:79 (Dockerfiles/Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/cloudmanager/main.go`:10 (cloudmanager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/component-codegen/main.go`:23 (component-codegen)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/health-check/main.go`:33 (health-check)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/main.go`:239 (cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/manifest-tools/main.go`:9 (manifest-tools)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/mcp-server/main.go`:16 (mcp-server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/test-retry/main.go`:10 (test-retry)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `cmd/manifest-tools/go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/manifest-tools/pkg/applier/olm.go`:58 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/manifest-tools/pkg/applier/olm.go`:63 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/cloudmanager/app/run.go`:81 (/healthz, GET, cmd/cloudmanager/app)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/cloudmanager/app/run.go`:85 (/readyz, GET, cmd/cloudmanager/app)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/main.go`:552 (/healthz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/main.go`:556 (/readyz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `internal/controller/services/auth/resources/data-science-admingroup-clusterrole.tmpl.yaml`:1 (CRD CRUD, ModelRegistry CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `internal/controller/services/auth/resources/data-science-admingroup-clusterrole.tmpl.yaml`:1 (CRD Watch, DataScienceCluster CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `internal/controller/services/auth/resources/data-science-admingroup-clusterrole.tmpl.yaml`:1 (CRD Watch, Feast FeatureStore CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `internal/controller/services/auth/resources/data-science-admingroup-clusterrole.tmpl.yaml`:1 (OpenShift Users/Groups, REST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `internal/controller/services/auth/resources/data-science-admingroup-role.tmpl.yaml`:1 (CRD CRUD, HardwareProfile CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `internal/controller/services/auth/resources/data-science-admingroup-role.tmpl.yaml`:1 (CRD CRUD, NIM Account CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `internal/controller/services/auth/resources/data-science-admingroup-role.tmpl.yaml`:1 (CRD CRUD, ServingRuntime CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `internal/controller/services/auth/resources/data-science-admingroup-role.tmpl.yaml`:1 (CRD Watch, KServe InferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `internal/controller/services/auth/resources/data-science-admingroup-role.tmpl.yaml`:1 (CRD Watch, OpenShift Console)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `internal/controller/services/auth/resources/data-science-admingroup-role.tmpl.yaml`:1 (CRD Watch, OpenShift Routes)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `internal/controller/services/auth/resources/data-science-admingroup-role.tmpl.yaml`:1 (OpenShift Image Streams, REST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `internal/controller/services/gateway/resources/kube-auth-proxy-httproute.tmpl.yaml`:1 (Gateway API (data-science-gateway), HTTPRoute)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `cmd/main.go`:29 (Go library, models-as-a-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `go.mod` (Go Library, odh-platform-utilities)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `internal/controller/components/kueue/kueue_config.go`:10 (Go library, odh-platform-utilities)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `internal/controller/components/kueue/kueue_controller.go`:72 (Controller watch, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `internal/controller/services/auth/resources/data-science-admingroup-clusterrole.tmpl.yaml`:1 (CRD CRUD, ModelRegistry (modelregistry.opendatahub.io))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `internal/controller/services/auth/resources/data-science-admingroup-clusterrole.tmpl.yaml`:1 (CRD Watch, DataScienceCluster CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `internal/controller/services/auth/resources/data-science-admingroup-clusterrole.tmpl.yaml`:1 (CRD Watch, Feast (feast.dev))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `internal/controller/services/auth/resources/data-science-admingroup-role.tmpl.yaml`:1 (CRD CRUD, HardwareProfile CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `internal/controller/services/auth/resources/data-science-admingroup-role.tmpl.yaml`:1 (CRD Watch, KServe InferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `internal/controller/services/gateway/gateway_controller.go`:179 (Controller watch, Gateway API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `internal/controller/services/gateway/resources/kube-auth-proxy-httproute.tmpl.yaml`:1 (Gateway API (data-science-gateway), HTTPRoute)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/tls/profile.go`:305 (APIServer resource read, OpenShift Cluster Configuration)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/cloudmanager/aws/awskubernetesengine_controller.go`:28-32 (apiextensions/v1/CustomResourceDefinition, internal/controller/cloudmanager/aws.NewReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/cloudmanager/azure/azurekubernetesengine_controller.go`:28-32 (apiextensions/v1/CustomResourceDefinition, internal/controller/cloudmanager/azure.NewReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/cloudmanager/coreweave/coreweavekubernetesengine_controller.go`:28-32 (apiextensions/v1/CustomResourceDefinition, internal/controller/cloudmanager/coreweave.NewReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/components/kueue/kueue_controller.go`:135-143 (apiextensions/v1/CustomResourceDefinition, internal/controller/components/kueue.componentHandler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/components/kueue/kueue_controller.go`:144-149 (internal/controller/components/kueue.componentHandler, rbac.authorization.k8s.io/v1/ClusterRole)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/components/kueue/kueue_controller.go`:150-160 (/v1/Namespace, internal/controller/components/kueue.componentHandler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/components/kueue/kueue_controller.go`:77-84 (/v1/ConfigMap, internal/controller/components/kueue.componentHandler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/datasciencecluster/datasciencecluster_controller.go`:72-77 (internal/controller/datasciencecluster.NewDataScienceClusterReconciler, services.platform.opendatahub.io/v1alpha1/GatewayConfig)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/datasciencecluster/datasciencecluster_controller.go`:78-85 (/v1/ConfigMap, internal/controller/datasciencecluster.NewDataScienceClusterReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/modules/modules_controller.go`:108-116 (/v1/ConfigMap, internal/controller/modules.NewModuleReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/modules/modules_controller.go`:174-178 (apiextensions/v1/CustomResourceDefinition, internal/controller/modules.addModuleCRDWatches)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/services/gateway/gateway_controller.go`:132-136 (/v1/Service, internal/controller/services/gateway.ServiceHandler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- 7 additional gap candidates remain in the analyzer JSON.
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `config/default/manager_webhook_patch.yaml`:1 (opendatahub-operator-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `config/default/metrics_service_patch.yaml`:3 (opendatahub-operator-controller-manager, opendatahub-operator-controller-manager-metrics-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `config/webhook/service.yaml`:1 (opendatahub-operator-controller-manager, opendatahub-operator-webhook-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `internal/controller/services/gateway/resources/kube-auth-proxy-oidc-deployment.tmpl.yaml`:1 ({template-value})
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `internal/controller/services/gateway/resources/kube-auth-proxy-svc.tmpl.yaml`:1 ({template-value})
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### webhooks

- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/crd/patches/webhook_in_config_platforms.yaml`:2 (/convert, platforms.config.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/crd/patches/webhook_in_datasciencecluster_datascienceclusters.yaml`:3 (/convert, platforms.config.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/crd/patches/webhook_in_dscinitialization_dscinitializations.yaml`:3 (/convert, platforms.config.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/crd/patches/webhook_in_services_auths.yaml`:3 (/convert, platforms.config.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/dashboard/validating_acceleratorprofile.go`:22 (/validate-dashboard-acceleratorprofile, dashboard-acceleratorprofile-validator.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/dashboard/validating_hardwareprofile.go`:22 (/validate-dashboard-hardwareprofile, dashboard-hardwareprofile-validator.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/datasciencecluster/v2/defaulting.go`:22 (/mutate-datasciencecluster-v2, datasciencecluster-v2-defaulter.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/datasciencecluster/v2/validating.go`:24 (/validate-datasciencecluster-v2, datasciencecluster-v2-validator.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/datasciencecluster/v3/defaulting.go`:24 (/mutate-datasciencecluster-v3, datasciencecluster-v3-defaulter.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/datasciencecluster/v3/validating.go`:23 (/validate-datasciencecluster-v3, datasciencecluster-v3-validator.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/dscinitialization/v1/validating.go`:24 (/validate-dscinitialization-v1, dscinitialization-v1-validator.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/dscinitialization/v2/validating.go`:24 (/validate-dscinitialization-v2, dscinitialization-v2-validator.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- /healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: cmd/cloudmanager/app/run.go:81]
- /readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/cloudmanager/app/run.go:85]
- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes liveness probe endpoint [source: config/default/manager_webhook_patch.yaml:1]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes readiness probe endpoint [source: config/default/manager_webhook_patch.yaml:1]
- Argo Workflow CRDs (argoproj.io) methods=Kubernetes API mechanism=RBAC aggregation (aggregate-to-admin/edit/view ClusterRoles) enforcement=kube-apiserver policy=admin: full CRUD on all Argo resources; edit: full CRUD excl. WorkflowTaskSets; view: read-only [source: prefetched-manifests/datasciencepipelines/argo/clusterrole.argo-aggregate-to-admin.yaml:2]
- Argo Workflow agent secrets methods=Kubernetes API mechanism=RBAC with resourceNames restriction enforcement=kube-apiserver policy=argo-cluster-role restricts secret access to argo-workflows-agent-ca-certificates only [source: prefetched-manifests/datasciencepipelines/argo/clusterrole.argo-cluster-role.yaml:1]
- Kubernetes API methods=REST mechanism=kubeconfig credential chain enforcement=kube-apiserver policy=Kubeconfig-based authentication using user-provided credentials [source: cmd/manifest-tools/pkg/applier/olm.go:39]
- Operator webhook methods=CREATE mechanism=Kubernetes admission enforcement=ValidatingWebhookConfiguration policy=Admission validation [source: internal/webhook/dashboard/validating_acceleratorprofile.go:22]
- Webhook (port 9443) methods=HTTPS mechanism=TLS serving certificate (server identity) enforcement=controller-runtime webhook server policy=API server validates the OpenShift service-ca serving certificate opendatahub-operator-controller-webhook-cert [source: cmd/main.go:441]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/main.go:552]
- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/cloudmanager/app [source: cmd/cloudmanager/app/run.go:81]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/main.go:556]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/cloudmanager/app [source: cmd/cloudmanager/app/run.go:85]
### integrations

- DataScienceCluster CR interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read enabled platform components [source: internal/controller/services/auth/resources/data-science-admingroup-clusterrole.tmpl.yaml:1]
- Feast FeatureStore CR interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read feature store instances [source: internal/controller/services/auth/resources/data-science-admingroup-clusterrole.tmpl.yaml:1]
- Gateway API (data-science-gateway) interaction=HTTPRoute role=runtime-transport protocol=HTTPS purpose=External dashboard ingress [source: internal/controller/services/gateway/resources/kube-auth-proxy-httproute.tmpl.yaml:1]
- HardwareProfile CR interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage hardware profile resources [source: internal/controller/services/auth/resources/data-science-admingroup-role.tmpl.yaml:1]
- KServe InferenceService interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read model serving state [source: internal/controller/services/auth/resources/data-science-admingroup-role.tmpl.yaml:1]
- ModelRegistry CR interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage model registry instances [source: internal/controller/services/auth/resources/data-science-admingroup-clusterrole.tmpl.yaml:1]
- NIM Account CR interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage NVIDIA NIM account configuration [source: internal/controller/services/auth/resources/data-science-admingroup-role.tmpl.yaml:1]
- OpenShift Console interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Console link resources [source: internal/controller/services/auth/resources/data-science-admingroup-role.tmpl.yaml:1]
- OpenShift Image Streams interaction=REST role=runtime-transport protocol=HTTPS purpose=Image stream access [source: internal/controller/services/auth/resources/data-science-admingroup-role.tmpl.yaml:1]
- OpenShift Routes interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Dashboard route status [source: internal/controller/services/auth/resources/data-science-admingroup-role.tmpl.yaml:1]
- OpenShift Users/Groups interaction=REST role=runtime-transport protocol=HTTPS purpose=User and group management [source: internal/controller/services/auth/resources/data-science-admingroup-clusterrole.tmpl.yaml:1]
- ServingRuntime CR interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage serving runtime templates [source: internal/controller/services/auth/resources/data-science-admingroup-role.tmpl.yaml:1]
### internal_dependencies

- DataScienceCluster CR interaction=CRD Watch role=runtime-integration purpose=Read enabled platform components [source: internal/controller/services/auth/resources/data-science-admingroup-clusterrole.tmpl.yaml:1]
- Feast (feast.dev) interaction=CRD Watch role=runtime-integration purpose=Read feature store instances [source: internal/controller/services/auth/resources/data-science-admingroup-clusterrole.tmpl.yaml:1]
- Gateway API (data-science-gateway) interaction=HTTPRoute role=runtime-transport purpose=Platform ingress through Gateway API [source: internal/controller/services/gateway/resources/kube-auth-proxy-httproute.tmpl.yaml:1]
- Gateway API interaction=Controller watch role=runtime-integration purpose=Manage Gateway API routing resources [source: internal/controller/services/gateway/gateway_controller.go:179]
- HardwareProfile CR interaction=CRD CRUD role=unknown purpose=Manage hardware profile resources [source: internal/controller/services/auth/resources/data-science-admingroup-role.tmpl.yaml:1]
- KServe InferenceService interaction=CRD Watch role=runtime-integration purpose=Read model serving state [source: internal/controller/services/auth/resources/data-science-admingroup-role.tmpl.yaml:1]
- ModelRegistry (modelregistry.opendatahub.io) interaction=CRD CRUD role=unknown purpose=Manage model registry instances [source: internal/controller/services/auth/resources/data-science-admingroup-clusterrole.tmpl.yaml:1]
- OpenShift Cluster Configuration interaction=APIServer resource read role=runtime-integration purpose=Read cluster-wide API server configuration [source: pkg/tls/profile.go:305]
- models-as-a-service interaction=Go library role=runtime-library purpose=Use runtime packages from github.com/opendatahub-io/models-as-a-service/maas-controller [source: cmd/main.go:29]
- odh-platform-utilities interaction=Go Library role=runtime-library purpose=Platform detection, manifest rendering, and deployment helpers [source: go.mod]
- odh-platform-utilities interaction=Go library role=runtime-library purpose=Use runtime packages from github.com/opendatahub-io/odh-platform-utilities [source: internal/controller/components/kueue/kueue_config.go:10]
- prometheus-operator interaction=Controller watch role=runtime-integration purpose=Manage Prometheus monitoring resources [source: internal/controller/components/kueue/kueue_controller.go:72]
### services

- opendatahub-operator-controller-manager-metrics-service port=8443 target=8443 protocol=TCP encryption= auth= [source: config/default/metrics_service_patch.yaml:3]
- opendatahub-operator-webhook-service port=443 target=9443 protocol=TCP encryption= auth= [source: config/webhook/service.yaml:1]
- {template-value} port={template-value} target={template-value} protocol=TCP encryption= auth= [source: internal/controller/services/gateway/resources/kube-auth-proxy-svc.tmpl.yaml:1]
- {template-value} port={template-value} target={template-value} protocol=TCP encryption= auth= [source: internal/controller/services/gateway/resources/kube-auth-proxy-svc.tmpl.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Controller-created Deployment workload {template-value} uses service account {template-value} and 1 container(s) [source: internal/controller/services/gateway/resources/kube-auth-proxy-oidc-deployment.tmpl.yaml:1]
- **observed**: Deployment workload opendatahub-operator-controller-manager uses service account opendatahub-operator-controller-manager and 1 container(s) [source: config/default/manager_webhook_patch.yaml:1]
- **observed**: Service opendatahub-operator-controller-manager-metrics-service targets opendatahub-operator-controller-manager with 1 port(s) [source: config/default/metrics_service_patch.yaml:3]
- **observed**: Service opendatahub-operator-webhook-service targets opendatahub-operator-controller-manager with 1 port(s) [source: config/webhook/service.yaml:1]
- **observed**: Service {template-value} targets {template-value} with 2 port(s) [source: internal/controller/services/gateway/resources/kube-auth-proxy-svc.tmpl.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by cmd [source: cmd/main.go:552]
- **observed**: HTTP GET /healthz is owned by cmd/cloudmanager/app [source: cmd/cloudmanager/app/run.go:81]
- **observed**: HTTP GET /readyz is owned by cmd [source: cmd/main.go:556]
- **observed**: HTTP GET /readyz is owned by cmd/cloudmanager/app [source: cmd/cloudmanager/app/run.go:85]
- **observed**: HTTPRoute {template-value} serves host  via plaintext; backend={template-value}; transport=Unknown [source: internal/controller/services/gateway/resources/kube-auth-proxy-httproute.tmpl.yaml:1]
- **observed**: Route {template-value} serves host {template-value} via TLS; backend={template-value}; transport=HTTPS [source: internal/controller/services/gateway/resources/dashboard-redirect-legacy-gateway-route.tmpl.yaml:2]
### security

- **observed**: CREATE Operator webhook uses Kubernetes admission at ValidatingWebhookConfiguration; policy=Admission validation [source: internal/webhook/dashboard/validating_acceleratorprofile.go:22]
- **observed**: GET /healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: cmd/cloudmanager/app/run.go:81]
- **observed**: GET /readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/cloudmanager/app/run.go:85]
- **observed**: GET :8081/healthz uses None at N/A; policy=Unauthenticated Kubernetes liveness probe endpoint [source: config/default/manager_webhook_patch.yaml:1]
- **observed**: GET :8081/readyz uses None at N/A; policy=Unauthenticated Kubernetes readiness probe endpoint [source: config/default/manager_webhook_patch.yaml:1]
- **observed**: HTTPS Webhook (port 9443) uses TLS serving certificate (server identity) at controller-runtime webhook server; policy=API server validates the OpenShift service-ca serving certificate opendatahub-operator-controller-webhook-cert [source: cmd/main.go:441]
- **observed**: Kubernetes API Argo Workflow CRDs (argoproj.io) uses RBAC aggregation (aggregate-to-admin/edit/view ClusterRoles) at kube-apiserver; policy=admin: full CRUD on all Argo resources; edit: full CRUD excl. WorkflowTaskSets; view: read-only [source: prefetched-manifests/datasciencepipelines/argo/clusterrole.argo-aggregate-to-admin.yaml:2]
- **observed**: Kubernetes API Argo Workflow agent secrets uses RBAC with resourceNames restriction at kube-apiserver; policy=argo-cluster-role restricts secret access to argo-workflows-agent-ca-certificates only [source: prefetched-manifests/datasciencepipelines/argo/clusterrole.argo-cluster-role.yaml:1]
- **observed**: RBAC role argo-aggregate-to-admin grants 1 rule(s) [source: prefetched-manifests/datasciencepipelines/argo/clusterrole.argo-aggregate-to-admin.yaml:2]
- **observed**: RBAC role argo-aggregate-to-edit grants 1 rule(s) [source: prefetched-manifests/datasciencepipelines/argo/clusterrole.argo-aggregate-to-edit.yaml:2]
- **observed**: RBAC role auth-editor-role grants 2 rule(s) [source: config/rbac/services_auth_editor_role.yaml:2]
- **observed**: RBAC role auth-viewer-role grants 2 rule(s) [source: config/rbac/services_auth_viewer_role.yaml:2]
- **observed**: RBAC role dashboard-editor-role grants 2 rule(s) [source: config/rbac/components_dashboard_editor_role.yaml:2]
- **observed**: RBAC role dashboard-viewer-role grants 2 rule(s) [source: config/rbac/components_dashboard_viewer_role.yaml:2]
- **observed**: RBAC role data-science-admingroupcluster-role grants 9 rule(s) [source: internal/controller/services/auth/resources/data-science-admingroup-clusterrole.tmpl.yaml:1]
- **observed**: RBAC role data-science-allowedgroupcluster-role grants 2 rule(s) [source: internal/controller/services/auth/resources/data-science-allowedgroup-clusterrole.tmpl.yaml:1]
- **observed**: RBAC role kserve-editor-role grants 2 rule(s) [source: config/rbac/components_kserve_editor_role.yaml:2]
- **observed**: RBAC role kserve-viewer-role grants 2 rule(s) [source: config/rbac/components_kserve_viewer_role.yaml:2]
- **observed**: RBAC role kueue-editor-role grants 2 rule(s) [source: config/rbac/components_kueue_editor_role.yaml:2]
- **observed**: RBAC role kueue-viewer-role grants 2 rule(s) [source: config/rbac/components_kueue_viewer_role.yaml:2]
- **observed**: RBAC role metrics-reader grants 1 rule(s) [source: config/rbac/auth_proxy_client_clusterrole.yaml:1]
- **observed**: RBAC role modelregistry-editor-role grants 2 rule(s) [source: config/rbac/components_modelregistry_editor_role.yaml:2]
- **observed**: RBAC role modelregistry-viewer-role grants 2 rule(s) [source: config/rbac/components_modelregistry_viewer_role.yaml:2]
- **observed**: RBAC role opendatahub-operator-metrics-reader grants 1 rule(s) [source: config/rbac/auth_proxy_client_clusterrole.yaml:1]
- **observed**: RBAC role ray-editor-role grants 2 rule(s) [source: config/rbac/components_ray_editor_role.yaml:2]
- **observed**: RBAC role ray-viewer-role grants 2 rule(s) [source: config/rbac/components_ray_viewer_role.yaml:2]
- **observed**: RBAC role trustyai-editor-role grants 2 rule(s) [source: config/rbac/components_trustyai_editor_role.yaml:2]
- **observed**: RBAC role trustyai-viewer-role grants 2 rule(s) [source: config/rbac/components_trustyai_viewer_role.yaml:2]
- **observed**: RBAC role workbenches-editor-role grants 2 rule(s) [source: config/rbac/components_workbenches_editor_role.yaml:2]
- **observed**: RBAC role workbenches-viewer-role grants 2 rule(s) [source: config/rbac/components_workbenches_viewer_role.yaml:2]
- **observed**: REST Kubernetes API uses kubeconfig credential chain at kube-apiserver; policy=Kubeconfig-based authentication using user-provided credentials [source: cmd/manifest-tools/pkg/applier/olm.go:39]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: cmd/main.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
