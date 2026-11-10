# Analyzer Synthesis Context: kuberay

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 8 crds facts extracted [source: ray-operator/apis/config/v1alpha1/configuration_types.go:18, ray-operator/apis/ray/v1alpha1/raycluster_types.go:192, ray-operator/apis/ray/v1alpha1/rayjob_types.go:115, ray-operator/apis/ray/v1alpha1/rayservice_types.go:113, ray-operator/config/crd/bases/ray.io_rayclusters.yaml:2, ray-operator/config/crd/bases/ray.io_raycronjobs.yaml:2, ray-operator/config/crd/bases/ray.io_rayjobs.yaml:2, ray-operator/config/crd/bases/ray.io_rayservices.yaml:2]
- **grpc_services (observed)**: 5 grpc_services facts extracted [source: apiserver/cmd/main.go:105, apiserver/cmd/main.go:106, apiserver/cmd/main.go:107, apiserver/cmd/main.go:108, apiserver/cmd/main.go:109]
- **http_endpoints (observed)**: 33 http_endpoints facts extracted [source: apiserver/cmd/main.go:191, apiserver/cmd/main.go:193, apiserver/cmd/main.go:194, apiserver/cmd/main.go:195, apiserversdk/proxy.go:46, apiserversdk/proxy.go:64, apiserversdk/proxy.go:65, historyserver/pkg/collector/eventcollector/eventcollector.go:241, historyserver/pkg/historyserver/router.go:101, historyserver/pkg/historyserver/router.go:112, historyserver/pkg/historyserver/router.go:121, historyserver/pkg/historyserver/router.go:124, historyserver/pkg/historyserver/router.go:127, historyserver/pkg/historyserver/router.go:131, historyserver/pkg/historyserver/router.go:135, historyserver/pkg/historyserver/router.go:140, historyserver/pkg/historyserver/router.go:144, historyserver/pkg/historyserver/router.go:150, historyserver/pkg/historyserver/router.go:173, historyserver/pkg/historyserver/router.go:184, historyserver/pkg/historyserver/router.go:192, historyserver/pkg/historyserver/router.go:201, historyserver/pkg/historyserver/router.go:265, historyserver/pkg/historyserver/router.go:271, historyserver/pkg/historyserver/router.go:289, historyserver/pkg/historyserver/router.go:298, historyserver/pkg/historyserver/router.go:306, historyserver/pkg/historyserver/router.go:379, historyserver/pkg/historyserver/router.go:391, historyserver/pkg/historyserver/router.go:65, historyserver/pkg/historyserver/router.go:74, ray-operator/main.go:431, ray-operator/main.go:432]
- **services (observed)**: 1 services facts extracted [source: ray-operator/config/manager/service.yaml:1]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (observed)**: 8 webhooks facts extracted [source: ray-operator/config/webhook/manifests.yaml:2, ray-operator/config/webhook/manifests.yaml:28, ray-operator/pkg/webhooks/v1/raycluster_mutating_webhook.go:21, ray-operator/pkg/webhooks/v1/raycluster_validating_webhook.go:35, ray-operator/pkg/webhooks/v1/rayjob_webhook.go:28, ray-operator/pkg/webhooks/v1/rayservice_webhook.go:28]

## Deterministic Cross-References

- **controller**: AuthenticationController —watches-reference→ /v1/Service; /v1/Service [source: ray-operator/controllers/ray/authentication_controller.go:1056, ray-operator/controllers/ray/raycluster_controller.go:613]
- **controller**: AuthenticationController —watches-reference→ /v1/ServiceAccount; /v1/ServiceAccount [source: ray-operator/controllers/ray/authentication_controller.go:1055, ray-operator/controllers/ray/authentication_controller.go:404]
- **controller**: AuthenticationController —watches-reference→ ray/v1/RayCluster; ray/v1/RayCluster [source: ray-operator/controllers/ray/authentication_controller.go:1053, ray-operator/controllers/ray/authentication_controller.go:120]
- **controller**: AuthenticationController —watches-reference→ route.openshift.io/v1/Route; route.openshift.io/v1/Route [source: ray-operator/controllers/ray/authentication_controller.go:1058, ray-operator/controllers/ray/raycluster_controller.go:512]
- **controller**: LegacySecurityController —watches-reference→ ray/v1/RayCluster; ray/v1/RayCluster [source: ray-operator/controllers/ray/authentication_controller.go:120, ray-operator/controllers/ray/legacy_security_controller.go:64]
- **controller**: NetworkPolicyController —watches-reference→ networking.k8s.io/v1/NetworkPolicy; networking.k8s.io/v1/NetworkPolicy [source: ray-operator/controllers/ray/networkpolicy_controller.go:189, ray-operator/controllers/ray/networkpolicy_controller.go:601]
- **controller**: NetworkPolicyController —watches-reference→ ray/v1/RayCluster; ray/v1/RayCluster [source: ray-operator/controllers/ray/authentication_controller.go:120, ray-operator/controllers/ray/networkpolicy_controller.go:600]
- **controller**: Provider —watches-reference→ scheduling.k8s.io/v1alpha2/PodGroup; scheduling.k8s.io/v1alpha2/PodGroup [source: ray-operator/controllers/ray/batchscheduler/kubernetes-was/v1alpha2/kubernetes_was_v1alpha2.go:108, ray-operator/controllers/ray/batchscheduler/kubernetes-was/v1alpha2/kubernetes_was_v1alpha2.go:176]
- **controller**: Provider —watches-reference→ scheduling.k8s.io/v1alpha2/Workload; scheduling.k8s.io/v1alpha2/Workload [source: ray-operator/controllers/ray/batchscheduler/kubernetes-was/v1alpha2/kubernetes_was_v1alpha2.go:107, ray-operator/controllers/ray/batchscheduler/kubernetes-was/v1alpha2/kubernetes_was_v1alpha2.go:131]
- **controller**: RayClusterMTLSController —watches-reference→ ray/v1/RayCluster; ray/v1/RayCluster [source: ray-operator/controllers/ray/authentication_controller.go:120, ray-operator/controllers/ray/raycluster_mtls_controller.go:505]
- **controller**: RayClusterReconciler —watches-reference→ /v1/PersistentVolumeClaim; /v1/PersistentVolumeClaim [source: ray-operator/controllers/ray/raycluster_controller.go:2032, ray-operator/controllers/ray/raycluster_controller.go:717]
- **controller**: RayClusterReconciler —watches-reference→ /v1/Pod; /v1/Pod [source: ray-operator/controllers/ray/common/association.go:184, ray-operator/controllers/ray/raycluster_controller.go:2029]
- **controller**: RayClusterReconciler —watches-reference→ /v1/Secret; /v1/Secret [source: historyserver/pkg/historyserver/clientmanager.go:124, ray-operator/controllers/ray/raycluster_controller.go:2031]
- **controller**: RayClusterReconciler —watches-reference→ /v1/Service; /v1/Service [source: ray-operator/controllers/ray/raycluster_controller.go:2030, ray-operator/controllers/ray/raycluster_controller.go:613]
- **controller**: RayClusterReconciler —watches-reference→ ray/v1/RayCluster; ray/v1/RayCluster [source: ray-operator/controllers/ray/authentication_controller.go:120, ray-operator/controllers/ray/raycluster_controller.go:2024]
- **controller**: RayCronJobReconciler —watches-reference→ ray/v1/RayCronJob; ray/v1/RayCronJob [source: ray-operator/controllers/ray/raycronjob_controller.go:196, ray-operator/controllers/ray/raycronjob_controller.go:63]
- **controller**: RayJobReconciler —watches-reference→ /v1/Service; /v1/Service [source: ray-operator/controllers/ray/raycluster_controller.go:613, ray-operator/controllers/ray/rayjob_controller.go:917]
- **controller**: RayJobReconciler —watches-reference→ batch/v1/Job; batch/v1/Job [source: ray-operator/controllers/ray/raycluster_controller.go:290, ray-operator/controllers/ray/rayjob_controller.go:918]
- **controller**: RayJobReconciler —watches-reference→ ray/v1/RayCluster; ray/v1/RayCluster [source: ray-operator/controllers/ray/authentication_controller.go:120, ray-operator/controllers/ray/rayjob_controller.go:916]
- **controller**: RayJobReconciler —watches-reference→ ray/v1/RayJob; ray/v1/RayJob [source: ray-operator/controllers/ray/metrics/ray_job_metrics.go:72, ray-operator/controllers/ray/rayjob_controller.go:915]
- **controller**: RayServiceReconciler —watches-reference→ /v1/Service; /v1/Service [source: ray-operator/controllers/ray/raycluster_controller.go:613, ray-operator/controllers/ray/rayservice_controller.go:840]
- **controller**: RayServiceReconciler —watches-reference→ ray/v1/RayCluster; ray/v1/RayCluster [source: ray-operator/controllers/ray/authentication_controller.go:120, ray-operator/controllers/ray/rayservice_controller.go:839]
- **controller**: RayServiceReconciler —watches-reference→ ray/v1/RayService; ray/v1/RayService [source: ray-operator/controllers/ray/metrics/ray_service_metrics.go:62, ray-operator/controllers/ray/rayservice_controller.go:834]
- **security**: GET /healthz —protected-by→ None; N/A: Kubernetes health probe; unauthenticated by design [source: ray-operator/main.go:431]
- **security**: GET /readyz —protected-by→ None; N/A: Kubernetes readiness probe; unauthenticated by design [source: ray-operator/main.go:432]
- **security**: Unknown /healthz —protected-by→ None; N/A: Kubernetes health probe; unauthenticated by design [source: apiserver/cmd/main.go:195, ray-operator/main.go:431]

## Behavioral Evidence

No bounded behavioral evidence was extracted.

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `podpool/cmd/main.go`:82 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `ray-operator/config/manager/manager.yaml`:1 (:8082/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `ray-operator/config/manager/manager.yaml`:1 (:8082/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `ray-operator/controllers/ray/batchscheduler/kubernetes-was/v1alpha2/kubernetes_was_v1alpha2.go`:391 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `ray-operator/main.go`:431 (/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `ray-operator/main.go`:432 (/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `ray-operator/pkg/webhooks/v1/raycluster_validating_webhook.go`:35 (Kubernetes admission, Operator webhook)
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
  **Candidate:** `dashboard/Dockerfile`:75 (dashboard/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `historyserver/Dockerfile.collector`:38 (historyserver/Dockerfile.collector:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `historyserver/Dockerfile.collector.buildx`:9 (historyserver/Dockerfile.collector.buildx:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `historyserver/Dockerfile.historyserver`:35 (historyserver/Dockerfile.historyserver:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `historyserver/Dockerfile.historyserver.buildx`:7 (historyserver/Dockerfile.historyserver.buildx:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `ray-operator/Dockerfile`:34 (ray-operator/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `ray-operator/Dockerfile`:41 (ray-operator/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `ray-operator/Dockerfile.buildx`:7 (ray-operator/Dockerfile.buildx:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `ray-operator/Dockerfile.konflux`:40 (ray-operator/Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `ray-operator/Dockerfile.rhoai`:35 (ray-operator/Dockerfile.rhoai:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `apiserver/pkg/client/kubernetes.go`:52 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `apiserversdk/proxy.go`:49 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `podpool/cmd/main.go`:101 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `ray-operator/controllers/ray/batchscheduler/kubernetes-was/v1alpha2/kubernetes_was_v1alpha2.go`:391 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `ray-operator/controllers/ray/utils/openshift.go`:44 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `ray-operator/controllers/ray/utils/util.go`:995 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `ray-operator/go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### grpc_services

- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `apiserver/cmd/main.go`:105 (ClusterService, apiserver/cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `apiserver/cmd/main.go`:106 (ComputeTemplateService, apiserver/cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `apiserver/cmd/main.go`:107 (RayJobService, apiserver/cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `apiserver/cmd/main.go`:108 (RayJobSubmissionService, apiserver/cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `apiserver/cmd/main.go`:109 (RayServeService, apiserver/cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `apiserver/cmd/main.go`:191 (/, Unknown, apiserver/cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `apiserversdk/proxy.go`:46 (/apis/ray.io/v1/, Unknown, apiserversdk)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `apiserversdk/proxy.go`:64 (/api/v1/namespaces/{namespace}/services/{service}/proxy, Unknown, apiserversdk)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `apiserversdk/proxy.go`:65 (/api/v1/namespaces/{namespace}/services/{service}/proxy/, Unknown, apiserversdk)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `historyserver/pkg/collector/eventcollector/eventcollector.go`:241 (/events, POST, pkg/collector/eventcollector)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `historyserver/pkg/historyserver/router.go`:112 (/, GET, pkg/historyserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `historyserver/pkg/historyserver/router.go`:121 (/cluster_status, GET, pkg/historyserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `historyserver/pkg/historyserver/router.go`:124 (/grafana_health, GET, pkg/historyserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `historyserver/pkg/historyserver/router.go`:298 (/actors, GET, pkg/historyserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `historyserver/pkg/historyserver/router.go`:306 (/actors/{single_actor:*}, GET, pkg/historyserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `historyserver/pkg/historyserver/router.go`:65 (/, GET, pkg/historyserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `historyserver/pkg/historyserver/router.go`:74 (/, GET, pkg/historyserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `ray-operator/config/manager/service.yaml`:1 (Inbound scrape, Prometheus)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `ray-operator/config/rbac/role.yaml`:2 (CRD Watch, OpenShift Routes)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `ray-operator/config/rbac/role.yaml`:2 (Certificate CR, cert-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `ray-operator/config/rbac/role.yaml`:2 (Gateway API, HTTPRoute CRUD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `historyserver/pkg/historyserver/clientmanager.go`:124 (/v1/Secret, create, get, update operations by ClientManager, RayClusterMTLSController, RayClusterReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `ray-operator/config/manager/service.yaml`:1 (Prometheus, monitoring)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `ray-operator/config/rbac/role.yaml`:2 (CRD CRUD, Gateway API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `ray-operator/config/rbac/role.yaml`:2 (CRD CRUD, cert-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `ray-operator/controllers/ray/authentication_controller.go`:364 (Gateway API, HTTPRoute CRUD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `ray-operator/controllers/ray/authentication_controller.go`:393 (/v1/ConfigMap, create, delete, get, update operations by AuthenticationController)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `ray-operator/controllers/ray/authentication_controller.go`:404 (/v1/ServiceAccount, create, delete, get, update operations by AuthenticationController, RayClusterReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `ray-operator/controllers/ray/common/association.go`:184 (/v1/Pod, delete, get, list operations by NetworkPolicyController, RayClusterMTLSController, RayClusterReconciler, rayClusterScaleExpectationImpl)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `ray-operator/controllers/ray/raycluster_controller.go`:613 (/v1/Service, create, get, list, update operations by RayClusterReconciler, RayJobReconciler, RayServiceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `ray-operator/controllers/ray/raycluster_controller.go`:717 (/v1/PersistentVolumeClaim, get, update operations by RayClusterReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `ray-operator/controllers/ray/raycluster_mtls_controller.go`:259 (Certificate and Issuer CRD CRUD, cert-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `ray-operator/pkg/tls/tls.go`:223 (APIServer resource read, OpenShift Cluster Configuration)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `ray-operator/controllers/ray/authentication_controller.go`:1053 (AuthenticationController, ray/v1/RayCluster)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `ray-operator/controllers/ray/authentication_controller.go`:1055 (/v1/ServiceAccount, AuthenticationController)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `ray-operator/controllers/ray/authentication_controller.go`:1056 (/v1/Service, AuthenticationController)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `ray-operator/controllers/ray/legacy_security_controller.go`:64 (LegacySecurityController, ray/v1/RayCluster)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `ray-operator/controllers/ray/networkpolicy_controller.go`:601 (NetworkPolicyController, networking.k8s.io/v1/NetworkPolicy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `ray-operator/controllers/ray/raycluster_controller.go`:2029 (/v1/Pod, RayClusterReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `ray-operator/controllers/ray/raycluster_controller.go`:2030 (/v1/Service, RayClusterReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `ray-operator/controllers/ray/raycluster_controller.go`:2031 (/v1/Secret, RayClusterReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `ray-operator/controllers/ray/raycluster_controller.go`:2032 (/v1/PersistentVolumeClaim, RayClusterReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `ray-operator/controllers/ray/rayjob_controller.go`:917 (/v1/Service, RayJobReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `ray-operator/controllers/ray/rayjob_controller.go`:918 (RayJobReconciler, batch/v1/Job)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `ray-operator/controllers/ray/rayservice_controller.go`:840 (/v1/Service, RayServiceReconciler)
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
  **Candidate:** `ray-operator/config/webhook/manifests.yaml`:28 (/validate-ray-io-v1-raycluster, vraycluster.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `ray-operator/config/webhook/manifests.yaml`:28 (/validate-ray-io-v1-rayjob, vrayjob.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `ray-operator/config/webhook/manifests.yaml`:28 (/validate-ray-io-v1-rayservice, vrayservice.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `ray-operator/pkg/webhooks/v1/raycluster_mutating_webhook.go`:21 (/mutate-ray-io-v1-raycluster, mraycluster.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `ray-operator/pkg/webhooks/v1/raycluster_validating_webhook.go`:35 (/validate-ray-io-v1-raycluster, vraycluster.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `ray-operator/pkg/webhooks/v1/rayjob_webhook.go`:28 (/validate-ray-io-v1-rayjob, vrayjob.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `ray-operator/pkg/webhooks/v1/rayservice_webhook.go`:28 (/validate-ray-io-v1-rayservice, vrayservice.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- /healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: ray-operator/main.go:431]
- /readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: ray-operator/main.go:432]
- :8082/healthz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes liveness probe endpoint [source: ray-operator/config/manager/manager.yaml:1]
- :8082/readyz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes readiness probe endpoint [source: ray-operator/config/manager/manager.yaml:1]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=In-cluster configuration provides automatic ServiceAccount token authentication [source: podpool/cmd/main.go:82]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via kuberay-operator ClusterRole; SA kuberay-operator [source: ray-operator/controllers/ray/batchscheduler/kubernetes-was/v1alpha2/kubernetes_was_v1alpha2.go:391]
- Operator webhook methods=CREATE mechanism=Kubernetes admission enforcement=ValidatingWebhookConfiguration policy=Admission validation [source: ray-operator/pkg/webhooks/v1/raycluster_validating_webhook.go:35]
### http_endpoints

- GET / on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:112]
- GET / on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:74]
- GET / on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:65]
- GET /actors on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:298]
- GET /actors/{single_actor:*} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:306]
- GET /cluster_status on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:121]
- GET /grafana_health on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:124]
- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: ray-operator/main.go:431]
- GET /jobs/ on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:131]
- GET /jobs/{job_id} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:135]
- GET /prometheus_health on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:127]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: ray-operator/main.go:432]
- GET /v0/cluster_metadata on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:140]
- GET /v0/logs on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:144]
- GET /v0/logs/{media_type} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:150]
- GET /v0/tasks on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:173]
- GET /v0/tasks/summarize on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:184]
- GET /v0/tasks/timeline on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:192]
- GET /{namespace}/{kind}/{name} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:379]
- GET /{namespace}/{kind}/{name}/{session} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:391]
- GET /{node_id} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:101]
- GET /{subpath:*} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:201]
- POST /events on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/collector/eventcollector [source: historyserver/pkg/collector/eventcollector/eventcollector.go:241]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=apiserver/cmd [source: apiserver/cmd/main.go:191]
- Unknown /api/v1/namespaces/{namespace}/services/{service}/proxy on port ; transport=HTTP/1.1 encryption= auth= owner=apiserversdk [source: apiserversdk/proxy.go:64]
- Unknown /api/v1/namespaces/{namespace}/services/{service}/proxy/ on port ; transport=HTTP/1.1 encryption= auth= owner=apiserversdk [source: apiserversdk/proxy.go:65]
- Unknown /apis/ray.io/v1/ on port ; transport=HTTP/1.1 encryption= auth= owner=apiserversdk [source: apiserversdk/proxy.go:46]
- Unknown /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=apiserver/cmd [source: apiserver/cmd/main.go:195]
- Unknown /livez on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:271]
- Unknown /metrics on port ; transport=HTTP/1.1 encryption= auth= owner=apiserver/cmd [source: apiserver/cmd/main.go:193]
- Unknown /readz on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:265]
- Unknown /select_cluster on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/historyserver [source: historyserver/pkg/historyserver/router.go:289]
- Unknown /swagger/ on port ; transport=HTTP/1.1 encryption= auth= owner=apiserver/cmd [source: apiserver/cmd/main.go:194]
### integrations

- Gateway API interaction=HTTPRoute CRUD role=runtime-transport protocol=HTTPS purpose=Manage Gateway API routing resources [source: ray-operator/config/rbac/role.yaml:2]
- OpenShift Routes interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Dashboard route status [source: ray-operator/config/rbac/role.yaml:2]
- Prometheus interaction=Inbound scrape role=unknown protocol=HTTP purpose=Metrics collection via prometheus.io/scrape annotation at /metrics [source: ray-operator/config/manager/service.yaml:1]
- cert-manager interaction=Certificate CR role=unknown protocol=HTTPS purpose=Manage TLS certificates through cert-manager CRDs [source: ray-operator/config/rbac/role.yaml:2]
### internal_dependencies

- Gateway API interaction=CRD CRUD role=unknown purpose=Manage Gateway API routing resources [source: ray-operator/config/rbac/role.yaml:2]
- Gateway API interaction=HTTPRoute CRUD role=runtime-transport purpose=Reconcile HTTPRoute resources against a configured Gateway [source: ray-operator/controllers/ray/authentication_controller.go:364]
- OpenShift Cluster Configuration interaction=APIServer resource read role=runtime-integration purpose=Read cluster-wide API server configuration [source: ray-operator/pkg/tls/tls.go:223]
- Prometheus interaction=monitoring role=unknown purpose=Metrics scraping via service annotations [source: ray-operator/config/manager/service.yaml:1]
- cert-manager interaction=CRD CRUD role=unknown purpose=Manage TLS certificates through cert-manager CRDs [source: ray-operator/config/rbac/role.yaml:2]
- cert-manager interaction=Certificate and Issuer CRD CRUD role=unknown purpose=Reconcile cert-manager Certificate and Issuer resources [source: ray-operator/controllers/ray/raycluster_mtls_controller.go:259]
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

- **observed**: HTTP GET / is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:65]
- **observed**: HTTP GET /actors is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:298]
- **observed**: HTTP GET /actors/{single_actor:*} is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:306]
- **observed**: HTTP GET /cluster_status is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:121]
- **observed**: HTTP GET /grafana_health is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:124]
- **observed**: HTTP GET /healthz is owned by main [source: ray-operator/main.go:431]
- **observed**: HTTP GET /jobs/ is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:131]
- **observed**: HTTP GET /jobs/{job_id} is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:135]
- **observed**: HTTP GET /prometheus_health is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:127]
- **observed**: HTTP GET /readyz is owned by main [source: ray-operator/main.go:432]
- **observed**: HTTP GET /v0/cluster_metadata is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:140]
- **observed**: HTTP GET /v0/logs is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:144]
- **observed**: HTTP GET /v0/logs/{media_type} is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:150]
- **observed**: HTTP GET /v0/tasks is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:173]
- **observed**: HTTP GET /v0/tasks/summarize is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:184]
- **observed**: HTTP GET /v0/tasks/timeline is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:192]
- **observed**: HTTP GET /{namespace}/{kind}/{name} is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:379]
- **observed**: HTTP GET /{namespace}/{kind}/{name}/{session} is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:391]
- **observed**: HTTP GET /{node_id} is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:101]
- **observed**: HTTP GET /{subpath:*} is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:201]
- **observed**: HTTP POST /events is owned by pkg/collector/eventcollector [source: historyserver/pkg/collector/eventcollector/eventcollector.go:241]
- **observed**: HTTP Unknown / is owned by apiserver/cmd [source: apiserver/cmd/main.go:191]
- **observed**: HTTP Unknown /api/v1/namespaces/{namespace}/services/{service}/proxy is owned by apiserversdk [source: apiserversdk/proxy.go:64]
- **observed**: HTTP Unknown /api/v1/namespaces/{namespace}/services/{service}/proxy/ is owned by apiserversdk [source: apiserversdk/proxy.go:65]
- **observed**: HTTP Unknown /apis/ray.io/v1/ is owned by apiserversdk [source: apiserversdk/proxy.go:46]
- **observed**: HTTP Unknown /healthz is owned by apiserver/cmd [source: apiserver/cmd/main.go:195]
- **observed**: HTTP Unknown /livez is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:271]
- **observed**: HTTP Unknown /metrics is owned by apiserver/cmd [source: apiserver/cmd/main.go:193]
- **observed**: HTTP Unknown /readz is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:265]
- **observed**: HTTP Unknown /select_cluster is owned by pkg/historyserver [source: historyserver/pkg/historyserver/router.go:289]
- **observed**: HTTP Unknown /swagger/ is owned by apiserver/cmd [source: apiserver/cmd/main.go:194]
### security

- **observed**: CREATE Operator webhook uses Kubernetes admission at ValidatingWebhookConfiguration; policy=Admission validation [source: ray-operator/pkg/webhooks/v1/raycluster_validating_webhook.go:35]
- **observed**: GET /healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: ray-operator/main.go:431]
- **observed**: GET /readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: ray-operator/main.go:432]
- **observed**: GET :8082/healthz uses None at N/A; policy=Unauthenticated Kubernetes liveness probe endpoint [source: ray-operator/config/manager/manager.yaml:1]
- **observed**: GET :8082/readyz uses None at N/A; policy=Unauthenticated Kubernetes readiness probe endpoint [source: ray-operator/config/manager/manager.yaml:1]
- **observed**: RBAC role kuberay-edit-role grants 2 rule(s) [source: ray-operator/config/rbac/editor_role.yaml:1]
- **observed**: RBAC role kuberay-operator grants 29 rule(s) [source: ray-operator/config/rbac/role.yaml:2]
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
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=In-cluster configuration provides automatic ServiceAccount token authentication [source: podpool/cmd/main.go:82]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via kuberay-operator ClusterRole; SA kuberay-operator [source: ray-operator/controllers/ray/batchscheduler/kubernetes-was/v1alpha2/kubernetes_was_v1alpha2.go:391]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: ray-operator/pkg/tls/tls.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
