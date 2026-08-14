# Analyzer Synthesis Context: rhods-operator

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 22 crds facts extracted [source: api/cloudmanager/aws/v1alpha1/awskubernetesengine_types.go:55, api/cloudmanager/azure/v1alpha1/azurekubernetesengine_types.go:55, api/cloudmanager/coreweave/v1alpha1/coreweavekubernetesengine_types.go:55, api/components/v1alpha1/datasciencepipelines_types.go:45, api/components/v1alpha1/kueue_types.go:45, api/components/v1alpha1/modelregistry_types.go:64, api/components/v1alpha1/ray_types.go:44, api/components/v1alpha1/sparkoperator_types.go:51, api/components/v1alpha1/trainer_types.go:44, api/components/v1alpha1/trainingoperator_types.go:44, api/components/v1alpha1/trustyai_types.go:44, api/config/v1alpha1/platform_types.go:96, api/datasciencecluster/v1/datasciencecluster_types.go:182, api/datasciencecluster/v2/datasciencecluster_types.go:182, api/dscinitialization/v1/dscinitialization_types.go:92, api/dscinitialization/v2/dscinitialization_types.go:85, api/features/v1/features_types.go:18, api/infrastructure/v1/hardwareprofile_types.go:134, api/infrastructure/v1alpha1/hardwareprofile_types.go:134, api/services/v1alpha1/auth_types.go:57, api/services/v1alpha1/gateway_types.go:198, api/services/v1alpha1/monitoring_types.go:155]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 4 http_endpoints facts extracted [source: cmd/cloudmanager/app/run.go:81, cmd/cloudmanager/app/run.go:85, cmd/main.go:604, cmd/main.go:608]
- **services (observed)**: 8 services facts extracted [source: config/default/metrics_service_patch.yaml:3, config/webhook/service.yaml:1, internal/controller/services/gateway/resources/kube-auth-proxy-svc.tmpl.yaml:1, internal/controller/services/monitoring/resources/collector-prometheus-service.tmpl.yaml:5, internal/controller/services/monitoring/resources/data-science-prometheus-cluster-proxy.tmpl.yaml:168, internal/controller/services/monitoring/resources/data-science-prometheus-namespace-proxy.tmpl.yaml:206, internal/controller/services/monitoring/resources/data-science-prometheus-service-override.tmpl.yaml:2, internal/controller/services/monitoring/resources/prometheus-web-tls-service.tmpl.yaml:23]
- **ingress (observed)**: 6 ingress facts extracted [source: internal/controller/services/gateway/resources/dashboard-redirect-legacy-gateway-route.tmpl.yaml:2, internal/controller/services/gateway/resources/gateway-ocp-route.tmpl.yaml:1, internal/controller/services/gateway/resources/kube-auth-proxy-httproute.tmpl.yaml:1, internal/controller/services/monitoring/resources/data-science-prometheus-cluster-proxy.tmpl.yaml:188, internal/controller/services/monitoring/resources/data-science-prometheus-route.tmpl.yaml:1, internal/controller/services/monitoring/resources/thanos-querier-route.tmpl.yaml:1]
- **webhooks (observed)**: 10 webhooks facts extracted [source: config/crd/patches/webhook_in_datasciencecluster_datascienceclusters.yaml:3, config/crd/patches/webhook_in_dscinitialization_dscinitializations.yaml:3, config/crd/patches/webhook_in_services_auths.yaml:3, config/crd/patches/webhook_in_services_monitorings.yaml:3, internal/webhook/dashboard/validating_acceleratorprofile.go:22, internal/webhook/dashboard/validating_hardwareprofile.go:22, internal/webhook/datasciencecluster/v1/defaulting.go:22, internal/webhook/datasciencecluster/v1/validating.go:28, internal/webhook/datasciencecluster/v2/defaulting.go:22, internal/webhook/datasciencecluster/v2/validating.go:24, internal/webhook/dscinitialization/v1/validating.go:24, internal/webhook/dscinitialization/v2/validating.go:24, internal/webhook/monitoring/mutating.go:31, internal/webhook/monitoring/mutating.go:32]

## Deterministic Cross-References

- **controller**: ServiceHandler —watches-reference→ /v1/Namespace; /v1/Namespace [source: internal/controller/components/kueue/kueue_support.go:98, internal/controller/services/auth/auth_controller.go:63]
- **controller**: ServiceHandler —watches-reference→ /v1/Secret; /v1/Secret [source: internal/controller/services/gateway/gateway_controller.go:60, internal/controller/services/gateway/gateway_controller_actions.go:291]
- **controller**: ServiceHandler —watches-reference→ rbac.authorization.k8s.io/v1/ClusterRole; rbac.authorization.k8s.io/v1/ClusterRole [source: internal/controller/components/kueue/kueue_controller_actions.go:60, internal/controller/services/auth/auth_controller.go:60]
- **controller**: ServiceHandler —watches-reference→ rbac.authorization.k8s.io/v1/RoleBinding; rbac.authorization.k8s.io/v1/RoleBinding [source: internal/controller/services/auth/auth_controller.go:62, pkg/cluster/resources.go:245]
- **controller**: componentHandler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: internal/controller/components/datasciencepipelines/datasciencepipelines_controller.go:47, internal/controller/components/kueue/kueue_config.go:63]
- **controller**: componentHandler —watches-reference→ /v1/Namespace; /v1/Namespace [source: internal/controller/components/kueue/kueue_controller.go:139, internal/controller/components/kueue/kueue_support.go:98]
- **controller**: componentHandler —watches-reference→ /v1/Secret; /v1/Secret [source: internal/controller/components/datasciencepipelines/datasciencepipelines_controller.go:48, internal/controller/services/gateway/gateway_controller_actions.go:291]
- **controller**: componentHandler —watches-reference→ /v1/Service; /v1/Service [source: internal/controller/components/datasciencepipelines/datasciencepipelines_controller.go:54, internal/controller/services/gateway/gateway_support.go:665]
- **controller**: componentHandler —watches-reference→ /v1/ServiceAccount; /v1/ServiceAccount [source: internal/controller/components/datasciencepipelines/datasciencepipelines_controller.go:53, pkg/webhook/utils.go:113]
- **controller**: componentHandler —watches-reference→ api/dscinitialization/v2/DSCInitialization; api/dscinitialization/v2/DSCInitialization [source: internal/controller/components/modelregistry/modelregistry_controller.go:63, internal/controller/dscinitialization/dscinitialization_controller.go:125]
- **controller**: componentHandler —watches-reference→ api/services/v1alpha1/Auth; api/services/v1alpha1/Auth [source: internal/controller/components/kueue/kueue_controller.go:150, internal/controller/components/kueue/kueue_controller_actions.go:80]
- **controller**: componentHandler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: internal/controller/components/datasciencepipelines/datasciencepipelines_controller.go:56, internal/controller/components/trustyai/trustyai_controller_actions.go:113]
- **controller**: componentHandler —watches-reference→ rbac.authorization.k8s.io/v1/ClusterRole; rbac.authorization.k8s.io/v1/ClusterRole [source: internal/controller/components/datasciencepipelines/datasciencepipelines_controller.go:50, internal/controller/components/kueue/kueue_controller_actions.go:60]
- **controller**: componentHandler —watches-reference→ rbac.authorization.k8s.io/v1/RoleBinding; rbac.authorization.k8s.io/v1/RoleBinding [source: internal/controller/components/datasciencepipelines/datasciencepipelines_controller.go:52, pkg/cluster/resources.go:245]
- **controller**: serviceHandler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: internal/controller/components/kueue/kueue_config.go:63, internal/controller/services/monitoring/monitoring_controller.go:97]
- **controller**: serviceHandler —watches-reference→ /v1/Secret; /v1/Secret [source: internal/controller/services/gateway/gateway_controller_actions.go:291, internal/controller/services/monitoring/monitoring_controller.go:98]
- **controller**: serviceHandler —watches-reference→ /v1/Service; /v1/Service [source: internal/controller/services/gateway/gateway_support.go:665, internal/controller/services/monitoring/monitoring_controller.go:99]
- **controller**: serviceHandler —watches-reference→ /v1/ServiceAccount; /v1/ServiceAccount [source: internal/controller/services/monitoring/monitoring_controller.go:100, pkg/webhook/utils.go:113]
- **controller**: serviceHandler —watches-reference→ api/datasciencecluster/v2/DataScienceCluster; api/datasciencecluster/v2/DataScienceCluster [source: internal/controller/services/monitoring/monitoring_controller.go:131, internal/webhook/datasciencecluster/v1/validating.go:145]
- **controller**: serviceHandler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: internal/controller/components/trustyai/trustyai_controller_actions.go:113, internal/controller/services/monitoring/monitoring_controller.go:95]
- **controller**: serviceHandler —watches-reference→ rbac.authorization.k8s.io/v1/ClusterRole; rbac.authorization.k8s.io/v1/ClusterRole [source: internal/controller/components/kueue/kueue_controller_actions.go:60, internal/controller/services/monitoring/monitoring_controller.go:92]
- **controller**: serviceHandler —watches-reference→ rbac.authorization.k8s.io/v1/RoleBinding; rbac.authorization.k8s.io/v1/RoleBinding [source: internal/controller/services/monitoring/monitoring_controller.go:91, pkg/cluster/resources.go:245]
- **security**: GET /healthz —protected-by→ None; N/A: Kubernetes health probe; unauthenticated by design [source: cmd/cloudmanager/app/run.go:81]
- **security**: GET /readyz —protected-by→ None; N/A: Kubernetes readiness probe; unauthenticated by design [source: cmd/cloudmanager/app/run.go:85]

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/cloudmanager/app/run.go`:81 (/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/main.go`:493 (TLS serving certificate (server identity), Webhook (port 9443))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/manifest-tools/pkg/applier/olm.go`:37 (Kubernetes API, kubeconfig credential chain)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `config/default/manager_webhook_patch.yaml`:1 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `internal/webhook/dashboard/validating_acceleratorprofile.go`:22 (Kubernetes admission, Operator webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

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
  **Candidate:** `config/rbac/components_datasciencepipelines_editor_role.yaml`:2 (datasciencepipelines-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/components_datasciencepipelines_viewer_role.yaml`:2 (datasciencepipelines-viewer-role)
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
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfiles/Dockerfile`:95 (Dockerfiles/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfiles/Dockerfile.konflux`:77 (Dockerfiles/Dockerfile.konflux:ENTRYPOINT)
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
  **Candidate:** `cmd/main.go`:293 (cmd)
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
  **Candidate:** `cmd/manifest-tools/pkg/applier/olm.go`:56 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/cloudmanager/app/run.go`:81 (/healthz, GET, cmd/cloudmanager/app)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/main.go`:604 (/healthz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `internal/controller/services/auth/resources/data-science-admingroup-clusterrole.tmpl.yaml`:1 (CRD Watch, DataScienceCluster CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `internal/controller/services/auth/resources/data-science-admingroup-role.tmpl.yaml`:1 (CRD CRUD, HardwareProfile CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `internal/controller/services/gateway/resources/kube-auth-proxy-httproute.tmpl.yaml`:1 (Gateway API (data-science-gateway), HTTPRoute)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `internal/controller/services/monitoring/resources/collector-rbac.tmpl.yaml`:1 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `api/common/types.go`:4 (Go library, odh-platform-utilities)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `cmd/main.go`:29 (Go library, models-as-a-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/components/kueue/kueue_config.go`:63 (/v1/ConfigMap, create, delete, get, list, update operations by DSCInitializationReconciler, GateChecker)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `internal/controller/components/kueue/kueue_controller.go`:68 (Controller watch, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/components/kueue/kueue_support.go`:98 (/v1/Namespace, create, get, list, update operations by DSCInitializationReconciler, Injector)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `internal/controller/services/auth/resources/data-science-admingroup-clusterrole.tmpl.yaml`:1 (CRD Watch, DataScienceCluster CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `internal/controller/services/auth/resources/data-science-admingroup-role.tmpl.yaml`:1 (CRD CRUD, HardwareProfile CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `internal/controller/services/gateway/gateway_controller.go`:69 (Controller watch, Gateway API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `internal/controller/services/gateway/resources/kube-auth-proxy-httproute.tmpl.yaml`:1 (Gateway API (data-science-gateway), HTTPRoute)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `internal/controller/services/monitoring/resources/collector-rbac.tmpl.yaml`:1 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/webhook/hardwareprofile/mutating.go`:523 (/v1/Event, create, list operations by Injector)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/tls/profile.go`:153 (APIServer resource read, OpenShift Cluster Configuration)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/components/datasciencepipelines/datasciencepipelines_controller.go`:47 (/v1/ConfigMap, componentHandler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/components/kueue/kueue_controller.go`:59 (/v1/ConfigMap, componentHandler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/components/modelregistry/modelregistry_controller.go`:49 (/v1/ConfigMap, componentHandler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/components/ray/ray_controller.go`:49 (/v1/ConfigMap, componentHandler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/components/sparkoperator/sparkoperator_controller.go`:46 (/v1/ConfigMap, componentHandler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/components/trainingoperator/trainingoperator_controller.go`:46 (/v1/ConfigMap, componentHandler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/components/trustyai/trustyai_controller.go`:49 (/v1/ConfigMap, componentHandler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/datasciencecluster/datasciencecluster_controller.go`:84 (/v1/ConfigMap)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/modules/modules_controller.go`:113 (/v1/ConfigMap)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/services/auth/auth_controller.go`:63 (/v1/Namespace, ServiceHandler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/services/gateway/gateway_controller.go`:60 (/v1/Secret, ServiceHandler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/services/monitoring/monitoring_controller.go`:97 (/v1/ConfigMap, serviceHandler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
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
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `internal/controller/services/monitoring/resources/collector-prometheus-service.tmpl.yaml`:5 (data-science-collector-prometheus)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `internal/controller/services/monitoring/resources/data-science-prometheus-cluster-proxy.tmpl.yaml`:59 (data-science-prometheus-cluster-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `internal/controller/services/monitoring/resources/data-science-prometheus-cluster-proxy.tmpl.yaml`:168 (data-science-prometheus-cluster-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `internal/controller/services/monitoring/resources/data-science-prometheus-namespace-proxy.tmpl.yaml`:91 (data-science-prometheus-namespace-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `internal/controller/services/monitoring/resources/data-science-prometheus-namespace-proxy.tmpl.yaml`:206 (data-science-prometheus-namespace-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `internal/controller/services/monitoring/resources/data-science-prometheus-service-override.tmpl.yaml`:2 (data-science-prometheus-namespace-proxy, data-science-prometheus-namespace-proxy-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `internal/controller/services/monitoring/resources/prometheus-web-tls-service.tmpl.yaml`:23 (prometheus-operated)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### webhooks

- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/crd/patches/webhook_in_datasciencecluster_datascienceclusters.yaml`:3 (/convert, datascienceclusters.datasciencecluster.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/crd/patches/webhook_in_dscinitialization_dscinitializations.yaml`:3 (/convert, datascienceclusters.datasciencecluster.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/crd/patches/webhook_in_services_auths.yaml`:3 (/convert, datascienceclusters.datasciencecluster.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/crd/patches/webhook_in_services_monitorings.yaml`:3 (/convert, datascienceclusters.datasciencecluster.opendatahub.io)
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
  **Candidate:** `internal/webhook/datasciencecluster/v1/defaulting.go`:22 (/mutate-datasciencecluster-v1, datasciencecluster-v1-defaulter.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/datasciencecluster/v1/validating.go`:28 (/validate-datasciencecluster-v1, datasciencecluster-v1-validator.opendatahub.io)
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
- Kubernetes API methods=REST mechanism=kubeconfig credential chain enforcement=kube-apiserver policy=Kubeconfig-based authentication using user-provided credentials [source: cmd/manifest-tools/pkg/applier/olm.go:37]
- Operator webhook methods=CREATE mechanism=Kubernetes admission enforcement=ValidatingWebhookConfiguration policy=Admission validation [source: internal/webhook/dashboard/validating_acceleratorprofile.go:22]
- Webhook (port 9443) methods=HTTPS mechanism=TLS serving certificate (server identity) enforcement=controller-runtime webhook server policy=API server validates the OpenShift service-ca serving certificate opendatahub-operator-controller-webhook-cert [source: cmd/main.go:493]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/main.go:604]
- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/cloudmanager/app [source: cmd/cloudmanager/app/run.go:81]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/main.go:608]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/cloudmanager/app [source: cmd/cloudmanager/app/run.go:85]
### integrations

- DataScienceCluster CR interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read enabled platform components [source: internal/controller/services/auth/resources/data-science-admingroup-clusterrole.tmpl.yaml:1]
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
- prometheus-operator interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage Prometheus monitoring resources [source: internal/controller/services/monitoring/resources/collector-rbac.tmpl.yaml:1]
### internal_dependencies

- DataScienceCluster CR interaction=CRD Watch role=runtime-integration purpose=Read enabled platform components [source: internal/controller/services/auth/resources/data-science-admingroup-clusterrole.tmpl.yaml:1]
- Gateway API (data-science-gateway) interaction=HTTPRoute role=runtime-transport purpose=Platform ingress through Gateway API [source: internal/controller/services/gateway/resources/kube-auth-proxy-httproute.tmpl.yaml:1]
- Gateway API interaction=Controller watch role=runtime-integration purpose=Manage Gateway API routing resources [source: internal/controller/services/gateway/gateway_controller.go:69]
- HardwareProfile CR interaction=CRD CRUD role=unknown purpose=Manage hardware profile resources [source: internal/controller/services/auth/resources/data-science-admingroup-role.tmpl.yaml:1]
- KServe InferenceService interaction=CRD Watch role=runtime-integration purpose=Read model serving state [source: internal/controller/services/auth/resources/data-science-admingroup-role.tmpl.yaml:1]
- ModelRegistry (modelregistry.opendatahub.io) interaction=CRD CRUD role=unknown purpose=Manage model registry instances [source: internal/controller/services/auth/resources/data-science-admingroup-clusterrole.tmpl.yaml:1]
- OpenShift Cluster Configuration interaction=APIServer resource read role=runtime-integration purpose=Read cluster-wide API server configuration [source: pkg/tls/profile.go:153]
- models-as-a-service interaction=Go library role=runtime-library purpose=Use runtime packages from github.com/opendatahub-io/models-as-a-service/maas-controller [source: cmd/main.go:29]
- odh-platform-utilities interaction=Go library role=runtime-library purpose=Use runtime packages from github.com/opendatahub-io/odh-platform-utilities/framework [source: api/common/types.go:4]
- prometheus-operator interaction=CRD CRUD role=unknown purpose=Manage Prometheus monitoring resources [source: internal/controller/services/monitoring/resources/collector-rbac.tmpl.yaml:1]
- prometheus-operator interaction=Controller watch role=runtime-integration purpose=Manage Prometheus monitoring resources [source: internal/controller/components/kueue/kueue_controller.go:68]
### services

- data-science-collector-prometheus port=8889 target=8889 protocol=TCP encryption= auth= [source: internal/controller/services/monitoring/resources/collector-prometheus-service.tmpl.yaml:5]
- data-science-prometheus-cluster-proxy port=8443 target=https protocol=TCP encryption= auth= [source: internal/controller/services/monitoring/resources/data-science-prometheus-cluster-proxy.tmpl.yaml:168]
- data-science-prometheus-namespace-proxy port=8443 target=https protocol=TCP encryption= auth= [source: internal/controller/services/monitoring/resources/data-science-prometheus-namespace-proxy.tmpl.yaml:206]
- data-science-prometheus-namespace-proxy-service port=9090 target=https protocol=TCP encryption= auth= [source: internal/controller/services/monitoring/resources/data-science-prometheus-service-override.tmpl.yaml:2]
- opendatahub-operator-controller-manager-metrics-service port=8443 target=8443 protocol=TCP encryption= auth= [source: config/default/metrics_service_patch.yaml:3]
- opendatahub-operator-webhook-service port=443 target=9443 protocol=TCP encryption= auth= [source: config/webhook/service.yaml:1]
- prometheus-operated port=9090 target=web protocol=TCP encryption= auth= [source: internal/controller/services/monitoring/resources/prometheus-web-tls-service.tmpl.yaml:23]
- {template-value} port={template-value} target={template-value} protocol=TCP encryption= auth= [source: internal/controller/services/gateway/resources/kube-auth-proxy-svc.tmpl.yaml:1]
- {template-value} port={template-value} target={template-value} protocol=TCP encryption= auth= [source: internal/controller/services/gateway/resources/kube-auth-proxy-svc.tmpl.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Controller-created Deployment workload data-science-prometheus-cluster-proxy uses service account data-science-prometheus-cluster-proxy and 1 container(s) [source: internal/controller/services/monitoring/resources/data-science-prometheus-cluster-proxy.tmpl.yaml:59]
- **observed**: Controller-created Deployment workload data-science-prometheus-namespace-proxy uses service account data-science-prometheus-namespace-proxy and 2 container(s) [source: internal/controller/services/monitoring/resources/data-science-prometheus-namespace-proxy.tmpl.yaml:91]
- **observed**: Controller-created Deployment workload {template-value} uses service account {template-value} and 1 container(s) [source: internal/controller/services/gateway/resources/kube-auth-proxy-oidc-deployment.tmpl.yaml:1]
- **observed**: Deployment workload opendatahub-operator-controller-manager uses service account opendatahub-operator-controller-manager and 1 container(s) [source: config/default/manager_webhook_patch.yaml:1]
- **observed**: Service data-science-collector-prometheus targets  with 1 port(s) [source: internal/controller/services/monitoring/resources/collector-prometheus-service.tmpl.yaml:5]
- **observed**: Service data-science-prometheus-cluster-proxy targets data-science-prometheus-cluster-proxy with 1 port(s) [source: internal/controller/services/monitoring/resources/data-science-prometheus-cluster-proxy.tmpl.yaml:168]
- **observed**: Service data-science-prometheus-namespace-proxy targets data-science-prometheus-namespace-proxy with 1 port(s) [source: internal/controller/services/monitoring/resources/data-science-prometheus-namespace-proxy.tmpl.yaml:206]
- **observed**: Service data-science-prometheus-namespace-proxy-service targets data-science-prometheus-namespace-proxy with 1 port(s) [source: internal/controller/services/monitoring/resources/data-science-prometheus-service-override.tmpl.yaml:2]
- **observed**: Service opendatahub-operator-controller-manager-metrics-service targets opendatahub-operator-controller-manager with 1 port(s) [source: config/default/metrics_service_patch.yaml:3]
- **observed**: Service opendatahub-operator-webhook-service targets opendatahub-operator-controller-manager with 1 port(s) [source: config/webhook/service.yaml:1]
- **observed**: Service prometheus-operated targets  with 1 port(s) [source: internal/controller/services/monitoring/resources/prometheus-web-tls-service.tmpl.yaml:23]
- **observed**: Service {template-value} targets {template-value} with 2 port(s) [source: internal/controller/services/gateway/resources/kube-auth-proxy-svc.tmpl.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by cmd [source: cmd/main.go:604]
- **observed**: HTTP GET /healthz is owned by cmd/cloudmanager/app [source: cmd/cloudmanager/app/run.go:81]
- **observed**: HTTP GET /readyz is owned by cmd [source: cmd/main.go:608]
- **observed**: HTTP GET /readyz is owned by cmd/cloudmanager/app [source: cmd/cloudmanager/app/run.go:85]
- **observed**: HTTPRoute {template-value} serves host  via plaintext; backend={template-value}; transport=Unknown [source: internal/controller/services/gateway/resources/kube-auth-proxy-httproute.tmpl.yaml:1]
- **observed**: Route data-science-prometheus-cluster-proxy serves host  via TLS; backend=data-science-prometheus-cluster-proxy; transport=HTTPS [source: internal/controller/services/monitoring/resources/data-science-prometheus-cluster-proxy.tmpl.yaml:188]
- **observed**: Route data-science-prometheus-route serves host  via TLS; backend=data-science-prometheus-namespace-proxy; transport=HTTPS [source: internal/controller/services/monitoring/resources/data-science-prometheus-route.tmpl.yaml:1]
- **observed**: Route data-science-thanos-querier-route serves host  via TLS; backend=thanos-querier-data-science-thanos-querier; transport=HTTPS [source: internal/controller/services/monitoring/resources/thanos-querier-route.tmpl.yaml:1]
- **observed**: Route {gateway-name} serves host {template-value} via TLS; backend={template-value}; transport=HTTPS [source: internal/controller/services/gateway/resources/gateway-ocp-route.tmpl.yaml:1]
- **observed**: Route {template-value} serves host {template-value} via TLS; backend={template-value}; transport=HTTPS [source: internal/controller/services/gateway/resources/dashboard-redirect-legacy-gateway-route.tmpl.yaml:2]
### security

- **observed**: CREATE Operator webhook uses Kubernetes admission at ValidatingWebhookConfiguration; policy=Admission validation [source: internal/webhook/dashboard/validating_acceleratorprofile.go:22]
- **observed**: GET /healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: cmd/cloudmanager/app/run.go:81]
- **observed**: GET /readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/cloudmanager/app/run.go:85]
- **observed**: GET :8081/healthz uses None at N/A; policy=Unauthenticated Kubernetes liveness probe endpoint [source: config/default/manager_webhook_patch.yaml:1]
- **observed**: GET :8081/readyz uses None at N/A; policy=Unauthenticated Kubernetes readiness probe endpoint [source: config/default/manager_webhook_patch.yaml:1]
- **observed**: HTTPS Webhook (port 9443) uses TLS serving certificate (server identity) at controller-runtime webhook server; policy=API server validates the OpenShift service-ca serving certificate opendatahub-operator-controller-webhook-cert [source: cmd/main.go:493]
- **observed**: RBAC role auth-editor-role grants 2 rule(s) [source: config/rbac/services_auth_editor_role.yaml:2]
- **observed**: RBAC role auth-viewer-role grants 2 rule(s) [source: config/rbac/services_auth_viewer_role.yaml:2]
- **observed**: RBAC role dashboard-editor-role grants 2 rule(s) [source: config/rbac/components_dashboard_editor_role.yaml:2]
- **observed**: RBAC role dashboard-viewer-role grants 2 rule(s) [source: config/rbac/components_dashboard_viewer_role.yaml:2]
- **observed**: RBAC role datasciencepipelines-editor-role grants 2 rule(s) [source: config/rbac/components_datasciencepipelines_editor_role.yaml:2]
- **observed**: RBAC role datasciencepipelines-viewer-role grants 2 rule(s) [source: config/rbac/components_datasciencepipelines_viewer_role.yaml:2]
- **observed**: RBAC role kserve-editor-role grants 2 rule(s) [source: config/rbac/components_kserve_editor_role.yaml:2]
- **observed**: RBAC role kserve-viewer-role grants 2 rule(s) [source: config/rbac/components_kserve_viewer_role.yaml:2]
- **observed**: RBAC role kueue-editor-role grants 2 rule(s) [source: config/rbac/components_kueue_editor_role.yaml:2]
- **observed**: RBAC role kueue-viewer-role grants 2 rule(s) [source: config/rbac/components_kueue_viewer_role.yaml:2]
- **observed**: RBAC role metrics-reader grants 1 rule(s) [source: config/rbac/auth_proxy_client_clusterrole.yaml:1]
- **observed**: RBAC role modelregistry-editor-role grants 2 rule(s) [source: config/rbac/components_modelregistry_editor_role.yaml:2]
- **observed**: RBAC role modelregistry-viewer-role grants 2 rule(s) [source: config/rbac/components_modelregistry_viewer_role.yaml:2]
- **observed**: RBAC role monitoring-editor-role grants 2 rule(s) [source: config/rbac/services_monitoring_editor_role.yaml:2]
- **observed**: RBAC role monitoring-viewer-role grants 2 rule(s) [source: config/rbac/services_monitoring_viewer_role.yaml:2]
- **observed**: RBAC role opendatahub-operator-metrics-reader grants 1 rule(s) [source: config/rbac/auth_proxy_client_clusterrole.yaml:1]
- **observed**: RBAC role ray-editor-role grants 2 rule(s) [source: config/rbac/components_ray_editor_role.yaml:2]
- **observed**: RBAC role ray-viewer-role grants 2 rule(s) [source: config/rbac/components_ray_viewer_role.yaml:2]
- **observed**: RBAC role trainingoperator-editor-role grants 2 rule(s) [source: config/rbac/components_trainingoperator_editor_role.yaml:2]
- **observed**: RBAC role trainingoperator-viewer-role grants 2 rule(s) [source: config/rbac/components_trainingoperator_viewer_role.yaml:2]
- **observed**: RBAC role trustyai-editor-role grants 2 rule(s) [source: config/rbac/components_trustyai_editor_role.yaml:2]
- **observed**: RBAC role trustyai-viewer-role grants 2 rule(s) [source: config/rbac/components_trustyai_viewer_role.yaml:2]
- **observed**: RBAC role workbenches-editor-role grants 2 rule(s) [source: config/rbac/components_workbenches_editor_role.yaml:2]
- **observed**: RBAC role workbenches-viewer-role grants 2 rule(s) [source: config/rbac/components_workbenches_viewer_role.yaml:2]
- **observed**: REST Kubernetes API uses kubeconfig credential chain at kube-apiserver; policy=Kubeconfig-based authentication using user-provided credentials [source: cmd/manifest-tools/pkg/applier/olm.go:37]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: cmd/main.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
