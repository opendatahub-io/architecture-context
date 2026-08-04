# Analyzer Synthesis Context: kuberay

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 8 crds facts extracted [source: ray-operator/apis/config/v1alpha1/configuration_types.go:18, ray-operator/apis/ray/v1alpha1/raycluster_types.go:186, ray-operator/apis/ray/v1alpha1/rayjob_types.go:109, ray-operator/apis/ray/v1alpha1/rayservice_types.go:107, ray-operator/config/crd/bases/ray.io_rayclusters.yaml:2, ray-operator/config/crd/bases/ray.io_raycronjobs.yaml:2, ray-operator/config/crd/bases/ray.io_rayjobs.yaml:2, ray-operator/config/crd/bases/ray.io_rayservices.yaml:2]
- **grpc_services (observed)**: 5 grpc_services facts extracted [source: apiserver/cmd/main.go:106, apiserver/cmd/main.go:107, apiserver/cmd/main.go:108, apiserver/cmd/main.go:109, apiserver/cmd/main.go:110]
- **http_endpoints (observed)**: 32 http_endpoints facts extracted [source: apiserver/cmd/main.go:192, apiserver/cmd/main.go:194, apiserver/cmd/main.go:195, apiserver/cmd/main.go:196, apiserversdk/proxy.go:46, apiserversdk/proxy.go:64, apiserversdk/proxy.go:65, experimental/cmd/main.go:111, historyserver/pkg/collector/eventserver/eventserver.go:90, historyserver/pkg/historyserver/router.go:102, historyserver/pkg/historyserver/router.go:111, historyserver/pkg/historyserver/router.go:114, historyserver/pkg/historyserver/router.go:117, historyserver/pkg/historyserver/router.go:121, historyserver/pkg/historyserver/router.go:125, historyserver/pkg/historyserver/router.go:130, historyserver/pkg/historyserver/router.go:134, historyserver/pkg/historyserver/router.go:140, historyserver/pkg/historyserver/router.go:163, historyserver/pkg/historyserver/router.go:174, historyserver/pkg/historyserver/router.go:182, historyserver/pkg/historyserver/router.go:191, historyserver/pkg/historyserver/router.go:256, historyserver/pkg/historyserver/router.go:262, historyserver/pkg/historyserver/router.go:277, historyserver/pkg/historyserver/router.go:285, historyserver/pkg/historyserver/router.go:297, historyserver/pkg/historyserver/router.go:55, historyserver/pkg/historyserver/router.go:64, historyserver/pkg/historyserver/router.go:91, ray-operator/main.go:361, ray-operator/main.go:362]
- **services (observed)**: 1 services facts extracted [source: ray-operator/config/manager/service.yaml:1]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (observed)**: 8 webhooks facts extracted [source: ray-operator/config/webhook/manifests.yaml:2, ray-operator/config/webhook/manifests.yaml:28, ray-operator/pkg/webhooks/v1/raycluster_mutating_webhook.go:21, ray-operator/pkg/webhooks/v1/raycluster_validating_webhook.go:34, ray-operator/pkg/webhooks/v1/rayjob_webhook.go:31, ray-operator/pkg/webhooks/v1/rayservice_webhook.go:31]

## Deterministic Cross-References

- **controller**: AuthenticationController —watches-reference→ /v1/Service; /v1/Service [source: ray-operator/controllers/ray/authentication_controller.go:1053, ray-operator/controllers/ray/raycluster_controller.go:592]
- **controller**: AuthenticationController —watches-reference→ /v1/ServiceAccount; /v1/ServiceAccount [source: ray-operator/controllers/ray/authentication_controller.go:1052, ray-operator/controllers/ray/authentication_controller.go:405]
- **controller**: AuthenticationController —watches-reference→ ray/v1/RayCluster; ray/v1/RayCluster [source: ray-operator/controllers/ray/authentication_controller.go:1050, ray-operator/controllers/ray/authentication_controller.go:121]
- **controller**: AuthenticationController —watches-reference→ route.openshift.io/v1/Route; route.openshift.io/v1/Route [source: ray-operator/controllers/ray/authentication_controller.go:1055, ray-operator/controllers/ray/raycluster_controller.go:466]
- **controller**: NetworkPolicyController —watches-reference→ networking.k8s.io/v1/NetworkPolicy; networking.k8s.io/v1/NetworkPolicy [source: ray-operator/controllers/ray/networkpolicy_controller.go:152, ray-operator/controllers/ray/networkpolicy_controller.go:428]
- **controller**: NetworkPolicyController —watches-reference→ ray/v1/RayCluster; ray/v1/RayCluster [source: ray-operator/controllers/ray/authentication_controller.go:121, ray-operator/controllers/ray/networkpolicy_controller.go:427]
- **controller**: RayClusterMTLSController —watches-reference→ ray/v1/RayCluster; ray/v1/RayCluster [source: ray-operator/controllers/ray/authentication_controller.go:121, ray-operator/controllers/ray/raycluster_mtls_controller.go:834]
- **controller**: RayClusterReconciler —watches-reference→ /v1/Pod; /v1/Pod [source: ray-operator/controllers/ray/common/association.go:184, ray-operator/controllers/ray/raycluster_controller.go:2014]
- **controller**: RayClusterReconciler —watches-reference→ /v1/Secret; /v1/Secret [source: ray-operator/controllers/ray/raycluster_controller.go:2016, ray-operator/controllers/ray/raycluster_controller.go:399]
- **controller**: RayClusterReconciler —watches-reference→ /v1/Service; /v1/Service [source: ray-operator/controllers/ray/raycluster_controller.go:2015, ray-operator/controllers/ray/raycluster_controller.go:592]
- **controller**: RayClusterReconciler —watches-reference→ ray/v1/RayCluster; ray/v1/RayCluster [source: ray-operator/controllers/ray/authentication_controller.go:121, ray-operator/controllers/ray/raycluster_controller.go:2009]
- **controller**: RayCronJobReconciler —watches-reference→ ray/v1/RayCronJob; ray/v1/RayCronJob [source: ray-operator/controllers/ray/raycronjob_controller.go:182, ray-operator/controllers/ray/raycronjob_controller.go:64]
- **controller**: RayCronJobReconciler —watches-reference→ ray/v1/RayJob; ray/v1/RayJob [source: ray-operator/controllers/ray/metrics/ray_job_metrics.go:72, ray-operator/controllers/ray/raycronjob_controller.go:183]
- **controller**: RayJobReconciler —watches-reference→ /v1/Service; /v1/Service [source: ray-operator/controllers/ray/raycluster_controller.go:592, ray-operator/controllers/ray/rayjob_controller.go:890]
- **controller**: RayJobReconciler —watches-reference→ batch/v1/Job; batch/v1/Job [source: ray-operator/controllers/ray/raycluster_controller.go:249, ray-operator/controllers/ray/rayjob_controller.go:891]
- **controller**: RayJobReconciler —watches-reference→ ray/v1/RayCluster; ray/v1/RayCluster [source: ray-operator/controllers/ray/authentication_controller.go:121, ray-operator/controllers/ray/rayjob_controller.go:889]
- **controller**: RayJobReconciler —watches-reference→ ray/v1/RayJob; ray/v1/RayJob [source: ray-operator/controllers/ray/metrics/ray_job_metrics.go:72, ray-operator/controllers/ray/rayjob_controller.go:888]
- **controller**: RayServiceReconciler —watches-reference→ /v1/Service; /v1/Service [source: ray-operator/controllers/ray/raycluster_controller.go:592, ray-operator/controllers/ray/rayservice_controller.go:609]
- **controller**: RayServiceReconciler —watches-reference→ ray/v1/RayCluster; ray/v1/RayCluster [source: ray-operator/controllers/ray/authentication_controller.go:121, ray-operator/controllers/ray/rayservice_controller.go:608]
- **controller**: RayServiceReconciler —watches-reference→ ray/v1/RayService; ray/v1/RayService [source: ray-operator/controllers/ray/metrics/ray_service_metrics.go:62, ray-operator/controllers/ray/rayservice_controller.go:603]
- **security**: GET /healthz —protected-by→ None; N/A: Kubernetes health probe; unauthenticated by design [source: ray-operator/main.go:361]
- **security**: GET /readyz —protected-by→ None; N/A: Kubernetes readiness probe; unauthenticated by design [source: ray-operator/main.go:362]
- **security**: Unknown /healthz —protected-by→ None; N/A: Kubernetes health probe; unauthenticated by design [source: apiserver/cmd/main.go:196, ray-operator/main.go:361]

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `ray-operator/config/manager/manager.yaml`:1 (:8082/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `ray-operator/controllers/ray/utils/util.go`:951 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `ray-operator/main.go`:361 (/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `ray-operator/pkg/webhooks/v1/raycluster_validating_webhook.go`:34 (Kubernetes admission, Operator webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `ray-operator/config/rbac/configmap-role.yaml`:2 (kuberay-operator-configmap)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `ray-operator/config/rbac/editor_role.yaml`:1 (kuberay-edit-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `ray-operator/config/rbac/gateway-api-role.yaml`:2 (kuberay-operator-gateway-api)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `ray-operator/config/rbac/leader_election_role.yaml`:2 (kuberay-operator-leader-election)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `ray-operator/config/rbac/ray_raycronjob_editor_role.yaml`:2 (raycronjob-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `ray-operator/config/rbac/ray_raycronjob_viewer_role.yaml`:2 (raycronjob-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `ray-operator/config/rbac/ray_rayjob_editor_role.yaml`:2 (rayjob-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `ray-operator/config/rbac/ray_rayjob_viewer_role.yaml`:2 (rayjob-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `ray-operator/config/rbac/ray_rayservice_editor_role.yaml`:2 (rayservice-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `ray-operator/config/rbac/ray_rayservice_viewer_role.yaml`:2 (rayservice-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `ray-operator/config/rbac/role.yaml`:2 (kuberay-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `ray-operator/config/rbac/viewer_role.yaml`:1 (kuberay-view-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `apiserver/Dockerfile`:36 (apiserver/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `apiserver/Dockerfile.buildx`:8 (apiserver/Dockerfile.buildx:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `apiserver/cmd/main.go`:50 (cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `dashboard/Dockerfile`:75 (dashboard/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `experimental/Dockerfile`:27 (experimental/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `experimental/Dockerfile.buildx`:7 (experimental/Dockerfile.buildx:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `ray-operator/Dockerfile`:33 (ray-operator/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `ray-operator/Dockerfile.buildx`:7 (ray-operator/Dockerfile.buildx:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `ray-operator/Dockerfile.konflux`:38 (ray-operator/Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `ray-operator/Dockerfile.rhoai`:33 (ray-operator/Dockerfile.rhoai:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `ray-operator/Dockerfile.submitter.buildx`:7 (ray-operator/Dockerfile.submitter.buildx:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `ray-operator/images/tests/Dockerfile`:31 (ray-operator/images/tests/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `apiserver/pkg/client/kubernetes.go`:50 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `apiserversdk/proxy.go`:49 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `ray-operator/controllers/ray/utils/util.go`:951 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `ray-operator/go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### grpc_services

- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `apiserver/cmd/main.go`:106 (ClusterService, apiserver/cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `apiserver/cmd/main.go`:192 (/, Unknown, apiserver/cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where are runtime routes registered on this server?
  **Expected signal:** router construction or route registration
  **Candidate:** `apiserver/cmd/main.go`:209 (HTTP, metrics)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `apiserversdk/proxy.go`:65 (/api/v1/namespaces/{namespace}/services/{service}/proxy/, Unknown, apiserversdk)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `experimental/cmd/main.go`:111 (/, Unknown, experimental/cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `historyserver/pkg/collector/eventserver/eventserver.go`:90 (/events, POST, pkg/collector/eventserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `historyserver/pkg/historyserver/router.go`:102 (/, GET, pkg/historyserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `ray-operator/main.go`:361 (/healthz, GET, main)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `ray-operator/config/manager/service.yaml`:1 (Inbound scrape, Prometheus)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `ray-operator/config/rbac/role.yaml`:2 (Certificate CR, cert-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `ray-operator/config/manager/service.yaml`:1 (Prometheus, monitoring)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `ray-operator/config/rbac/role.yaml`:2 (CRD CRUD, cert-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `ray-operator/controllers/ray/authentication_controller.go`:394 (/v1/ConfigMap, create, delete, get, update operations by AuthenticationController)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `ray-operator/controllers/ray/authentication_controller.go`:365 (Gateway API, HTTPRoute CRUD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `ray-operator/controllers/ray/common/association.go`:184 (/v1/Pod, delete, get, list operations by RayClusterMTLSController, RayClusterReconciler, rayClusterScaleExpectationImpl)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `ray-operator/controllers/ray/networkpolicy_controller.go`:152 (create, delete, get, update operations by NetworkPolicyController, networking.k8s.io/v1/NetworkPolicy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `ray-operator/controllers/ray/raycluster_controller.go`:399 (/v1/Secret, create, delete, get, list operations by RayClusterMTLSController, RayClusterReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `ray-operator/controllers/ray/raycluster_mtls_controller.go`:333 (cert-manager.io/v1/Certificate, create, delete, get, update operations by RayClusterMTLSController)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `ray-operator/controllers/ray/raycluster_mtls_controller.go`:333 (Certificate and Issuer CRD CRUD, cert-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `ray-operator/controllers/ray/rayservice_controller.go`:1883 (discovery/v1/EndpointSlice, list operations by RayServiceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `ray-operator/pkg/tls/tls.go`:91 (config.openshift.io/v1/APIServer, get operations by profileWatcher)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `ray-operator/pkg/tls/tls.go`:91 (APIServer resource read, OpenShift Cluster Configuration)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `ray-operator/controllers/ray/authentication_controller.go`:394 (/v1/ConfigMap, create, delete, get, update operations by AuthenticationController)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `ray-operator/controllers/ray/authentication_controller.go`:1052 (/v1/ServiceAccount, AuthenticationController)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `ray-operator/controllers/ray/batchscheduler/volcano/volcano_scheduler.go`:342 (VolcanoBatchSchedulerFactory, scheduling/v1beta1/PodGroup)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `ray-operator/controllers/ray/common/association.go`:184 (/v1/Pod, delete, get, list operations by RayClusterMTLSController, RayClusterReconciler, rayClusterScaleExpectationImpl)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `ray-operator/controllers/ray/networkpolicy_controller.go`:428 (NetworkPolicyController, networking.k8s.io/v1/NetworkPolicy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `ray-operator/controllers/ray/raycluster_controller.go`:399 (/v1/Secret, create, delete, get, list operations by RayClusterMTLSController, RayClusterReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `ray-operator/controllers/ray/raycluster_controller.go`:2014 (/v1/Pod, RayClusterReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `ray-operator/controllers/ray/raycluster_mtls_controller.go`:333 (cert-manager.io/v1/Certificate, create, delete, get, update operations by RayClusterMTLSController)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `ray-operator/controllers/ray/raycluster_mtls_controller.go`:834 (RayClusterMTLSController, ray/v1/RayCluster)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `ray-operator/controllers/ray/raycronjob_controller.go`:182 (RayCronJobReconciler, ray/v1/RayCronJob)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `ray-operator/controllers/ray/rayjob_controller.go`:890 (/v1/Service, RayJobReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `ray-operator/controllers/ray/rayservice_controller.go`:609 (/v1/Service, RayServiceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `ray-operator/config/manager/manager.yaml`:1 (kuberay-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `ray-operator/config/manager/service.yaml`:1 (kuberay-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### webhooks

- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `ray-operator/config/webhook/manifests.yaml`:2 (/mutate-ray-io-v1-raycluster, mraycluster.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `ray-operator/pkg/webhooks/v1/raycluster_mutating_webhook.go`:21 (/mutate-ray-io-v1-raycluster, mraycluster.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `ray-operator/pkg/webhooks/v1/raycluster_validating_webhook.go`:34 (/validate-ray-io-v1-raycluster, vraycluster.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `ray-operator/pkg/webhooks/v1/rayjob_webhook.go`:31 (/validate-ray-io-v1-rayjob, vrayjob.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `ray-operator/pkg/webhooks/v1/rayservice_webhook.go`:31 (/validate-ray-io-v1-rayservice, vrayservice.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- /healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: ray-operator/main.go:361]
- /readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: ray-operator/main.go:362]
- :8082/healthz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes liveness probe endpoint [source: ray-operator/config/manager/manager.yaml:1]
- :8082/readyz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes readiness probe endpoint [source: ray-operator/config/manager/manager.yaml:1]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via kuberay-operator ClusterRole; SA kuberay-operator [source: ray-operator/controllers/ray/utils/util.go:951]
- Operator webhook methods=CREATE mechanism=Kubernetes admission enforcement=ValidatingWebhookConfiguration policy=Admission validation [source: ray-operator/pkg/webhooks/v1/raycluster_validating_webhook.go:34]
### http_endpoints

- GET / on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:64]
- GET / on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:55]
- GET / on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:102]
- GET /actors on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:277]
- GET /actors/{single_actor:*} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:285]
- GET /cluster_status on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:111]
- GET /grafana_health on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:114]
- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: ray-operator/main.go:361]
- GET /jobs/ on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:121]
- GET /jobs/{job_id} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:125]
- GET /prometheus_health on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:117]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: ray-operator/main.go:362]
- GET /v0/cluster_metadata on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:130]
- GET /v0/logs on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:134]
- GET /v0/logs/{media_type} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:140]
- GET /v0/tasks on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:163]
- GET /v0/tasks/summarize on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:174]
- GET /v0/tasks/timeline on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:182]
- GET /{namespace}/{name}/{session} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:297]
- GET /{node_id} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:91]
- GET /{subpath:*} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:191]
- POST /events on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/collector/eventserver [source: historyserver/pkg/collector/eventserver/eventserver.go:90]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=apiserver/cmd [source: apiserver/cmd/main.go:192]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=experimental/cmd [source: experimental/cmd/main.go:111]
- Unknown /api/v1/namespaces/{namespace}/services/{service}/proxy on port ; transport=HTTP/1.1 encryption= auth= owner=apiserversdk [source: apiserversdk/proxy.go:64]
- Unknown /api/v1/namespaces/{namespace}/services/{service}/proxy/ on port ; transport=HTTP/1.1 encryption= auth= owner=apiserversdk [source: apiserversdk/proxy.go:65]
- Unknown /apis/ray.io/v1/ on port ; transport=HTTP/1.1 encryption= auth= owner=apiserversdk [source: apiserversdk/proxy.go:46]
- Unknown /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=apiserver/cmd [source: apiserver/cmd/main.go:196]
- Unknown /livez on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:262]
- Unknown /metrics on port ; transport=HTTP/1.1 encryption= auth= owner=apiserver/cmd [source: apiserver/cmd/main.go:194]
- Unknown /readz on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:256]
- Unknown /swagger/ on port ; transport=HTTP/1.1 encryption= auth= owner=apiserver/cmd [source: apiserver/cmd/main.go:195]
### integrations

- Gateway API interaction=HTTPRoute CRUD role=runtime-transport protocol=HTTPS purpose=Manage Gateway API routing resources [source: ray-operator/config/rbac/role.yaml:2]
- OpenShift Routes interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Dashboard route status [source: ray-operator/config/rbac/role.yaml:2]
- Prometheus interaction=Inbound scrape role=unknown protocol=HTTP purpose=Metrics collection via prometheus.io/scrape annotation at /metrics [source: ray-operator/config/manager/service.yaml:1]
- cert-manager interaction=Certificate CR role=unknown protocol=HTTPS purpose=Manage TLS certificates through cert-manager CRDs [source: ray-operator/config/rbac/role.yaml:2]
### internal_dependencies

- Gateway API interaction=CRD CRUD role=unknown purpose=Manage Gateway API routing resources [source: ray-operator/config/rbac/role.yaml:2]
- Gateway API interaction=HTTPRoute CRUD role=runtime-transport purpose=Reconcile HTTPRoute resources against a configured Gateway [source: ray-operator/controllers/ray/authentication_controller.go:365]
- OpenShift Cluster Configuration interaction=APIServer resource read role=runtime-integration purpose=Read cluster-wide API server configuration [source: ray-operator/pkg/tls/tls.go:91]
- Prometheus interaction=monitoring role=unknown purpose=Metrics scraping via service annotations [source: ray-operator/config/manager/service.yaml:1]
- cert-manager interaction=CRD CRUD role=unknown purpose=Manage TLS certificates through cert-manager CRDs [source: ray-operator/config/rbac/role.yaml:2]
- cert-manager interaction=Certificate and Issuer CRD CRUD role=unknown purpose=Reconcile cert-manager Certificate and Issuer resources [source: ray-operator/controllers/ray/raycluster_mtls_controller.go:333]
### services

- kuberay-operator port=8080 target=8080 protocol=TCP encryption= auth= [source: ray-operator/config/manager/service.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload kuberay-operator uses service account kuberay-operator and 1 container(s) [source: ray-operator/config/manager/manager.yaml:1]
- **observed**: Service kuberay-operator targets kuberay-operator with 1 port(s) [source: ray-operator/config/manager/service.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET / is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:102]
- **observed**: HTTP GET /actors is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:277]
- **observed**: HTTP GET /actors/{single_actor:*} is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:285]
- **observed**: HTTP GET /cluster_status is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:111]
- **observed**: HTTP GET /grafana_health is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:114]
- **observed**: HTTP GET /healthz is owned by main [source: ray-operator/main.go:361]
- **observed**: HTTP GET /jobs/ is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:121]
- **observed**: HTTP GET /jobs/{job_id} is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:125]
- **observed**: HTTP GET /prometheus_health is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:117]
- **observed**: HTTP GET /readyz is owned by main [source: ray-operator/main.go:362]
- **observed**: HTTP GET /v0/cluster_metadata is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:130]
- **observed**: HTTP GET /v0/logs is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:134]
- **observed**: HTTP GET /v0/logs/{media_type} is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:140]
- **observed**: HTTP GET /v0/tasks is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:163]
- **observed**: HTTP GET /v0/tasks/summarize is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:174]
- **observed**: HTTP GET /v0/tasks/timeline is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:182]
- **observed**: HTTP GET /{namespace}/{name}/{session} is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:297]
- **observed**: HTTP GET /{node_id} is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:91]
- **observed**: HTTP GET /{subpath:*} is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:191]
- **observed**: HTTP POST /events is owned by pkg/collector/eventserver [source: historyserver/pkg/collector/eventserver/eventserver.go:90]
- **observed**: HTTP Unknown / is owned by apiserver/cmd [source: apiserver/cmd/main.go:192]
- **observed**: HTTP Unknown / is owned by experimental/cmd [source: experimental/cmd/main.go:111]
- **observed**: HTTP Unknown /api/v1/namespaces/{namespace}/services/{service}/proxy is owned by apiserversdk [source: apiserversdk/proxy.go:64]
- **observed**: HTTP Unknown /api/v1/namespaces/{namespace}/services/{service}/proxy/ is owned by apiserversdk [source: apiserversdk/proxy.go:65]
- **observed**: HTTP Unknown /apis/ray.io/v1/ is owned by apiserversdk [source: apiserversdk/proxy.go:46]
- **observed**: HTTP Unknown /healthz is owned by apiserver/cmd [source: apiserver/cmd/main.go:196]
- **observed**: HTTP Unknown /livez is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:262]
- **observed**: HTTP Unknown /metrics is owned by apiserver/cmd [source: apiserver/cmd/main.go:194]
- **observed**: HTTP Unknown /readz is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:256]
- **observed**: HTTP Unknown /swagger/ is owned by apiserver/cmd [source: apiserver/cmd/main.go:195]
### security

- **observed**: CREATE Operator webhook uses Kubernetes admission at ValidatingWebhookConfiguration; policy=Admission validation [source: ray-operator/pkg/webhooks/v1/raycluster_validating_webhook.go:34]
- **observed**: GET /healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: ray-operator/main.go:361]
- **observed**: GET /readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: ray-operator/main.go:362]
- **observed**: GET :8082/healthz uses None at N/A; policy=Unauthenticated Kubernetes liveness probe endpoint [source: ray-operator/config/manager/manager.yaml:1]
- **observed**: GET :8082/readyz uses None at N/A; policy=Unauthenticated Kubernetes readiness probe endpoint [source: ray-operator/config/manager/manager.yaml:1]
- **observed**: RBAC role kuberay-edit-role grants 2 rule(s) [source: ray-operator/config/rbac/editor_role.yaml:1]
- **observed**: RBAC role kuberay-operator grants 27 rule(s) [source: ray-operator/config/rbac/role.yaml:2]
- **observed**: RBAC role kuberay-operator-configmap grants 1 rule(s) [source: ray-operator/config/rbac/configmap-role.yaml:2]
- **observed**: RBAC role kuberay-operator-gateway-api grants 3 rule(s) [source: ray-operator/config/rbac/gateway-api-role.yaml:2]
- **observed**: RBAC role kuberay-operator-leader-election grants 3 rule(s) [source: ray-operator/config/rbac/leader_election_role.yaml:2]
- **observed**: RBAC role kuberay-view-role grants 2 rule(s) [source: ray-operator/config/rbac/viewer_role.yaml:1]
- **observed**: RBAC role raycronjob-editor-role grants 2 rule(s) [source: ray-operator/config/rbac/ray_raycronjob_editor_role.yaml:2]
- **observed**: RBAC role raycronjob-viewer-role grants 2 rule(s) [source: ray-operator/config/rbac/ray_raycronjob_viewer_role.yaml:2]
- **observed**: RBAC role rayjob-editor-role grants 2 rule(s) [source: ray-operator/config/rbac/ray_rayjob_editor_role.yaml:2]
- **observed**: RBAC role rayjob-viewer-role grants 2 rule(s) [source: ray-operator/config/rbac/ray_rayjob_viewer_role.yaml:2]
- **observed**: RBAC role rayservice-editor-role grants 2 rule(s) [source: ray-operator/config/rbac/ray_rayservice_editor_role.yaml:2]
- **observed**: RBAC role rayservice-viewer-role grants 2 rule(s) [source: ray-operator/config/rbac/ray_rayservice_viewer_role.yaml:2]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via kuberay-operator ClusterRole; SA kuberay-operator [source: ray-operator/controllers/ray/utils/util.go:951]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: ray-operator/pkg/tls/tls.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
