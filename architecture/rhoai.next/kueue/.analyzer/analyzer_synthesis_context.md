# Analyzer Synthesis Context: kueue

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 16 crds facts extracted [source: apis/config/v1beta1/configuration_types.go:31, apis/visibility/v1beta1/types.go:28, apis/visibility/v1beta1/types.go:47, apis/visibility/v1beta1/types.go:85, apis/visibility/v1beta1/types.go:98, config/components/crd/bases/kueue.x-k8s.io_admissionchecks.yaml:2, config/components/crd/bases/kueue.x-k8s.io_cohorts.yaml:2, config/components/crd/bases/kueue.x-k8s.io_multikueueclusters.yaml:2, config/components/crd/bases/kueue.x-k8s.io_multikueueconfigs.yaml:2, config/components/crd/bases/kueue.x-k8s.io_provisioningrequestconfigs.yaml:2, config/components/crd/bases/kueue.x-k8s.io_topologies.yaml:2, config/components/crd/bases/kueue.x-k8s.io_workloadpriorityclasses.yaml:2, config/components/crd/patches/cainjection_in_clusterqueues.yaml:2, config/components/crd/patches/cainjection_in_cohorts.yaml:2, config/components/crd/patches/cainjection_in_resourceflavors.yaml:2, config/components/crd/patches/cainjection_in_workloads.yaml:2]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 15 http_endpoints facts extracted [source: cmd/experimental/kueue-viz/backend/handlers/handlers.go:28, cmd/experimental/kueue-viz/backend/handlers/handlers.go:29, cmd/experimental/kueue-viz/backend/handlers/handlers.go:31, cmd/experimental/kueue-viz/backend/handlers/handlers.go:32, cmd/experimental/kueue-viz/backend/handlers/handlers.go:35, cmd/experimental/kueue-viz/backend/handlers/handlers.go:36, cmd/experimental/kueue-viz/backend/handlers/handlers.go:37, cmd/experimental/kueue-viz/backend/handlers/handlers.go:40, cmd/experimental/kueue-viz/backend/handlers/handlers.go:41, cmd/experimental/kueue-viz/backend/handlers/handlers.go:44, cmd/experimental/kueue-viz/backend/handlers/handlers.go:45, cmd/experimental/kueue-viz/backend/handlers/handlers.go:48, cmd/experimental/kueue-viz/backend/handlers/handlers.go:49, cmd/kueue/main.go:381, cmd/kueue/main.go:393]
- **services (observed)**: 2 services facts extracted [source: config/components/webhook/service.yaml:1, config/rhoai/kueue-metrics-service.yaml:1]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (observed)**: 38 webhooks facts extracted [source: config/components/crd/patches/webhook_in_clusterqueues.yaml:3, config/components/crd/patches/webhook_in_localqueues.yaml:3, config/components/crd/patches/webhook_in_resourceflavors.yaml:3, config/components/crd/patches/webhook_in_workloads.yaml:3, config/rhoai/mutating_webhook_patch.yaml:1, config/rhoai/validating_webhook_patch.yaml:1, pkg/controller/jobs/appwrapper/appwrapper_controller.go:81, pkg/controller/jobs/appwrapper/appwrapper_controller.go:82, pkg/controller/jobs/deployment/deployment_webhook.go:62, pkg/controller/jobs/deployment/deployment_webhook.go:98, pkg/controller/jobs/job/job_webhook.go:72, pkg/controller/jobs/job/job_webhook.go:91, pkg/controller/jobs/jobset/jobset_webhook.go:66, pkg/controller/jobs/jobset/jobset_webhook.go:86, pkg/controller/jobs/kubeflow/jobs/paddlejob/paddlejob_controller.go:48, pkg/controller/jobs/kubeflow/jobs/paddlejob/paddlejob_controller.go:49, pkg/controller/jobs/kubeflow/jobs/pytorchjob/pytorchjob_controller.go:48, pkg/controller/jobs/kubeflow/jobs/pytorchjob/pytorchjob_controller.go:49, pkg/controller/jobs/kubeflow/jobs/tfjob/tfjob_controller.go:48, pkg/controller/jobs/kubeflow/jobs/tfjob/tfjob_controller.go:49, pkg/controller/jobs/kubeflow/jobs/xgboostjob/xgboostjob_controller.go:48, pkg/controller/jobs/kubeflow/jobs/xgboostjob/xgboostjob_controller.go:49, pkg/controller/jobs/leaderworkerset/leaderworkerset_webhook.go:102, pkg/controller/jobs/leaderworkerset/leaderworkerset_webhook.go:63, pkg/controller/jobs/mpijob/mpijob_webhook.go:70, pkg/controller/jobs/mpijob/mpijob_webhook.go:90, pkg/controller/jobs/pod/pod_webhook.go:106, pkg/controller/jobs/pod/pod_webhook.go:216, pkg/controller/jobs/raycluster/raycluster_webhook.go:73, pkg/controller/jobs/raycluster/raycluster_webhook.go:90, pkg/controller/jobs/rayjob/rayjob_webhook.go:70, pkg/controller/jobs/rayjob/rayjob_webhook.go:87, pkg/controller/jobs/statefulset/statefulset_webhook.go:105, pkg/controller/jobs/statefulset/statefulset_webhook.go:65, pkg/webhooks/clusterqueue_webhook.go:53, pkg/webhooks/clusterqueue_webhook.go:68, pkg/webhooks/cohort_webhook.go:44, pkg/webhooks/resourceflavor_webhook.go:47, pkg/webhooks/resourceflavor_webhook.go:63, pkg/webhooks/workload_webhook.go:51, pkg/webhooks/workload_webhook.go:71]

## Deterministic Cross-References

- **controller**: ACReconciler —watches-reference→ kueue/v1beta1/AdmissionCheck; kueue/v1beta1/AdmissionCheck [source: pkg/controller/admissionchecks/multikueue/admissioncheck.go:181, pkg/controller/admissionchecks/multikueue/admissioncheck.go:66]
- **controller**: ACReconciler —watches-reference→ kueue/v1beta1/MultiKueueCluster; kueue/v1beta1/MultiKueueCluster [source: pkg/controller/admissionchecks/multikueue/admissioncheck.go:183, pkg/controller/admissionchecks/multikueue/admissioncheck.go:91]
- **controller**: ACReconciler —watches-reference→ kueue/v1beta1/MultiKueueConfig; kueue/v1beta1/MultiKueueConfig [source: pkg/controller/admissionchecks/multikueue/admissioncheck.go:182, pkg/controller/admissionchecks/multikueue/admissioncheck.go:314]
- **controller**: ClusterQueueReconciler —watches-reference→ /v1/Namespace; /v1/Namespace [source: pkg/controller/core/clusterqueue_controller.go:591, pkg/controller/jobframework/defaults.go:67]
- **controller**: Controller —watches-reference→ kueue/v1beta1/AdmissionCheck; kueue/v1beta1/AdmissionCheck [source: pkg/controller/admissionchecks/multikueue/admissioncheck.go:66, pkg/controller/admissionchecks/provisioning/controller.go:849]
- **controller**: Controller —watches-reference→ kueue/v1beta1/Workload; kueue/v1beta1/Workload [source: cmd/importer/pod/import.go:183, pkg/controller/admissionchecks/provisioning/controller.go:830]
- **controller**: LocalQueueReconciler —watches-reference→ kueue/v1beta1/ClusterQueue; kueue/v1beta1/ClusterQueue [source: cmd/importer/util/util.go:143, pkg/controller/core/localqueue_controller.go:338]
- **controller**: PodReconciler —watches-reference→ /v1/Pod; /v1/Pod [source: cmd/importer/pod/import.go:155, pkg/controller/jobs/leaderworkerset/leaderworkerset_pod_reconciler.go:57]
- **controller**: Reconciler —watches-reference→ /v1/Pod; /v1/Pod [source: cmd/importer/pod/import.go:155, pkg/controller/jobs/pod/pod_controller.go:131]
- **controller**: Reconciler —watches-reference→ kueue/v1beta1/Workload; kueue/v1beta1/Workload [source: cmd/importer/pod/import.go:183, pkg/controller/jobs/pod/pod_controller.go:132]
- **controller**: WorkloadReconciler —watches-reference→ /v1/LimitRange; /v1/LimitRange [source: pkg/controller/core/workload_controller.go:797, pkg/workload/resources.go:69]
- **controller**: WorkloadReconciler —watches-reference→ kueue/v1beta1/ClusterQueue; kueue/v1beta1/ClusterQueue [source: cmd/importer/util/util.go:143, pkg/controller/core/workload_controller.go:799]
- **controller**: WorkloadReconciler —watches-reference→ kueue/v1beta1/LocalQueue; kueue/v1beta1/LocalQueue [source: cmd/importer/util/util.go:151, pkg/controller/core/workload_controller.go:800]
- **controller**: WorkloadReconciler —watches-reference→ node/v1/RuntimeClass; node/v1/RuntimeClass [source: pkg/controller/core/workload_controller.go:798, pkg/workload/resources.go:54]
- **controller**: clustersReconciler —watches-reference→ /v1/Secret; /v1/Secret [source: pkg/controller/admissionchecks/multikueue/multikueuecluster.go:442, pkg/controller/admissionchecks/multikueue/multikueuecluster.go:600]
- **controller**: clustersReconciler —watches-reference→ kueue/v1beta1/MultiKueueCluster; kueue/v1beta1/MultiKueueCluster [source: pkg/controller/admissionchecks/multikueue/admissioncheck.go:91, pkg/controller/admissionchecks/multikueue/multikueuecluster.go:599]
- **controller**: genericReconciler —watches-reference→ kueue/v1beta1/Workload; kueue/v1beta1/Workload [source: cmd/importer/pod/import.go:183, pkg/controller/jobframework/reconciler.go:1281]
- **controller**: rfReconciler —watches-reference→ /v1/Node; /v1/Node [source: pkg/cache/tas_flavor.go:104, pkg/controller/tas/resource_flavor.go:83]
- **controller**: topologyReconciler —watches-reference→ kueue/v1beta1/ResourceFlavor; kueue/v1beta1/ResourceFlavor [source: cmd/importer/util/util.go:159, pkg/controller/tas/topology_controller.go:82]
- **controller**: topologyUngater —watches-reference→ /v1/Pod; /v1/Pod [source: cmd/importer/pod/import.go:155, pkg/controller/tas/topology_ungater.go:102]
- **controller**: topologyUngater —watches-reference→ kueue/v1beta1/Workload; kueue/v1beta1/Workload [source: cmd/importer/pod/import.go:183, pkg/controller/tas/topology_ungater.go:101]
- **controller**: wlReconciler —watches-reference→ kueue/v1beta1/Workload; kueue/v1beta1/Workload [source: cmd/importer/pod/import.go:183, pkg/controller/admissionchecks/multikueue/workload.go:502]
- **security**: GET /healthz —protected-by→ None; N/A: Kubernetes health probe; unauthenticated by design [source: cmd/kueue/main.go:381]
- **security**: GET /readyz —protected-by→ None; N/A: Kubernetes readiness probe; unauthenticated by design [source: cmd/kueue/main.go:393]
- **webhook**: mappwrapper.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/mutating_webhook_patch.yaml:1, pkg/controller/jobs/appwrapper/appwrapper_controller.go:81]
- **webhook**: mclusterqueue.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/mutating_webhook_patch.yaml:1, pkg/webhooks/clusterqueue_webhook.go:53]
- **webhook**: mdeployment.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/mutating_webhook_patch.yaml:1, pkg/controller/jobs/deployment/deployment_webhook.go:62]
- **webhook**: mjob.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/mutating_webhook_patch.yaml:1, pkg/controller/jobs/job/job_webhook.go:72]
- **webhook**: mjobset.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/mutating_webhook_patch.yaml:1, pkg/controller/jobs/jobset/jobset_webhook.go:66]
- **webhook**: mleaderworkerset.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/mutating_webhook_patch.yaml:1, pkg/controller/jobs/leaderworkerset/leaderworkerset_webhook.go:63]
- **webhook**: mmpijob.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/mutating_webhook_patch.yaml:1, pkg/controller/jobs/mpijob/mpijob_webhook.go:70]
- **webhook**: mpaddlejob.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/mutating_webhook_patch.yaml:1, pkg/controller/jobs/kubeflow/jobs/paddlejob/paddlejob_controller.go:48]
- **webhook**: mpod.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/mutating_webhook_patch.yaml:1]
- **webhook**: mpytorchjob.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/mutating_webhook_patch.yaml:1, pkg/controller/jobs/kubeflow/jobs/pytorchjob/pytorchjob_controller.go:48]
- **webhook**: mraycluster.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/mutating_webhook_patch.yaml:1, pkg/controller/jobs/raycluster/raycluster_webhook.go:73]
- **webhook**: mrayjob.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/mutating_webhook_patch.yaml:1, pkg/controller/jobs/rayjob/rayjob_webhook.go:70]
- **webhook**: mresourceflavor.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/mutating_webhook_patch.yaml:1, pkg/webhooks/resourceflavor_webhook.go:47]
- **webhook**: mstatefulset.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/mutating_webhook_patch.yaml:1, pkg/controller/jobs/statefulset/statefulset_webhook.go:65]
- **webhook**: mtfjob.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/mutating_webhook_patch.yaml:1, pkg/controller/jobs/kubeflow/jobs/tfjob/tfjob_controller.go:48]
- **webhook**: mworkload.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/mutating_webhook_patch.yaml:1, pkg/webhooks/workload_webhook.go:51]
- **webhook**: mxgboostjob.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/mutating_webhook_patch.yaml:1, pkg/controller/jobs/kubeflow/jobs/xgboostjob/xgboostjob_controller.go:48]
- **webhook**: vappwrapper.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/validating_webhook_patch.yaml:1, pkg/controller/jobs/appwrapper/appwrapper_controller.go:82]
- **webhook**: vclusterqueue.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/validating_webhook_patch.yaml:1, pkg/webhooks/clusterqueue_webhook.go:68]
- **webhook**: vcohort.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/validating_webhook_patch.yaml:1, pkg/webhooks/cohort_webhook.go:44]
- **webhook**: vdeployment.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/validating_webhook_patch.yaml:1, pkg/controller/jobs/deployment/deployment_webhook.go:98]
- **webhook**: vjob.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/validating_webhook_patch.yaml:1, pkg/controller/jobs/job/job_webhook.go:91]
- **webhook**: vjobset.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/validating_webhook_patch.yaml:1, pkg/controller/jobs/jobset/jobset_webhook.go:86]
- **webhook**: vleaderworkerset.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/validating_webhook_patch.yaml:1, pkg/controller/jobs/leaderworkerset/leaderworkerset_webhook.go:102]
- **webhook**: vmpijob.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/validating_webhook_patch.yaml:1, pkg/controller/jobs/mpijob/mpijob_webhook.go:90]
- **webhook**: vpaddlejob.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/validating_webhook_patch.yaml:1, pkg/controller/jobs/kubeflow/jobs/paddlejob/paddlejob_controller.go:49]
- **webhook**: vpod.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/validating_webhook_patch.yaml:1]
- **webhook**: vpytorchjob.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/validating_webhook_patch.yaml:1, pkg/controller/jobs/kubeflow/jobs/pytorchjob/pytorchjob_controller.go:49]
- **webhook**: vraycluster.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/validating_webhook_patch.yaml:1, pkg/controller/jobs/raycluster/raycluster_webhook.go:90]
- **webhook**: vrayjob.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/validating_webhook_patch.yaml:1, pkg/controller/jobs/rayjob/rayjob_webhook.go:87]
- **webhook**: vresourceflavor.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/validating_webhook_patch.yaml:1, pkg/webhooks/resourceflavor_webhook.go:63]
- **webhook**: vstatefulset.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/validating_webhook_patch.yaml:1, pkg/controller/jobs/statefulset/statefulset_webhook.go:105]
- **webhook**: vtfjob.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/validating_webhook_patch.yaml:1, pkg/controller/jobs/kubeflow/jobs/tfjob/tfjob_controller.go:49]
- **webhook**: vworkload.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/validating_webhook_patch.yaml:1, pkg/webhooks/workload_webhook.go:71]
- **webhook**: vxgboostjob.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: config/components/webhook/service.yaml:1, config/rhoai/validating_webhook_patch.yaml:1, pkg/controller/jobs/kubeflow/jobs/xgboostjob/xgboostjob_controller.go:49]

## Behavioral Evidence

No bounded behavioral evidence was extracted.

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/experimental/kueue-viz/backend/kubernetes_client.go`:31 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/kueue/main.go`:381 (/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/kueue/main.go`:393 (/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/kueue/main.go`:422 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `config/rhoai/manager_metrics_patch.yaml`:1 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `config/rhoai/manager_metrics_patch.yaml`:1 (:8081/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `config/rhoai/validating_webhook_patch.yaml`:1 (Kubernetes admission, Operator webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/components/rbac/batch_admin_role.yaml`:2 (kueue-batch-admin-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/components/rbac/batch_user_role.yaml`:2 (kueue-batch-user-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/components/rbac/clusterqueue_editor_role.yaml`:2 (kueue-clusterqueue-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/components/rbac/localqueue_editor_role.yaml`:2 (kueue-localqueue-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/components/rbac/localqueue_viewer_role.yaml`:2 (kueue-localqueue-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/components/rbac/metrics_auth_role.yaml`:1 (kueue-metrics-auth-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/components/rbac/metrics_reader_role.yaml`:1 (kueue-metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/components/rbac/pending_workloads_cq_viewer_role.yaml`:2 (kueue-pending-workloads-cq-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/components/rbac/resourceflavor_editor_role.yaml`:2 (kueue-resourceflavor-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/components/rbac/resourceflavor_viewer_role.yaml`:2 (kueue-resourceflavor-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rhoai/clusterqueue_viewer_role_patch.yaml`:2 (kueue-clusterqueue-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rhoai/manager_role_patch.yaml`:1 (kueue-manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:23 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:39 (Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.rhoai`:44 (Dockerfile.rhoai:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/experimental/kueue-viz/backend/Dockerfile`:29 (cmd/experimental/kueue-viz/backend/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/experimental/kueue-viz/backend/main.go`:32 (kueue-viz)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/experimental/kueue-viz/frontend/Dockerfile`:35 (cmd/experimental/kueue-viz/frontend/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/importer/Dockerfile`:22 (cmd/importer/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/importer/main.go`:106 (importer)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/kueue/main.go`:106 (kueue)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/kueuectl-docs/main.go`:31 (kueuectl-docs)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/kueuectl/main.go`:25 (kueuectl)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/experimental/kueue-viz/backend/kubernetes_client.go`:57 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/experimental/kueue-viz/backend/kubernetes_client.go`:63 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/kueue/main.go`:422 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/kueuectl/app/util/client_getter.go`:73 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/kueuectl/app/util/client_getter.go`:87 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/experimental/kueue-viz/backend/handlers/handlers.go`:32 (/ws/workload/:namespace/:workload_name/events, GET, handlers)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/experimental/kueue-viz/backend/handlers/handlers.go`:35 (/ws/local-queues, GET, handlers)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/experimental/kueue-viz/backend/handlers/handlers.go`:36 (/ws/local-queue/:namespace/:queue_name, GET, handlers)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/experimental/kueue-viz/backend/handlers/handlers.go`:37 (/ws/local-queue/:namespace/:queue_name/workloads, GET, handlers)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/experimental/kueue-viz/backend/handlers/handlers.go`:40 (/ws/cluster-queues, GET, handlers)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/experimental/kueue-viz/backend/handlers/handlers.go`:41 (/ws/cluster-queue/:cluster_queue_name, GET, handlers)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/experimental/kueue-viz/backend/handlers/handlers.go`:44 (/ws/cohorts, GET, handlers)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/experimental/kueue-viz/backend/handlers/handlers.go`:45 (/ws/cohort/:cohort_name, GET, handlers)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/experimental/kueue-viz/backend/handlers/handlers.go`:48 (/ws/resource-flavors, GET, handlers)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/experimental/kueue-viz/backend/handlers/handlers.go`:49 (/ws/resource-flavor/:flavor_name, GET, handlers)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/kueue/main.go`:381 (/healthz, GET, cmd/kueue)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/kueue/main.go`:393 (/readyz, GET, cmd/kueue)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rhoai/manager_role_patch.yaml`:1 (API client, Kubernetes API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rhoai/manager_role_patch.yaml`:1 (CRD CRUD, Kubeflow Notebooks)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `cmd/importer/pod/import.go`:155 (/v1/Pod, create, delete, get, list, patch, update operations by Pod, PodReconciler, Reconciler, TASFlavorCache, multiKueueAdapter, topologyUngater)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rhoai/manager_role_patch.yaml`:1 (CRD CRUD, Kubeflow Notebooks (kubeflow.org))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rhoai/manager_role_patch.yaml`:1 (Kubernetes API (nodes), list)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/cache/tas_flavor.go`:104 (/v1/Node, list operations by TASFlavorCache)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/controller/admissionchecks/multikueue/admissioncheck.go`:66 (get, list, update operations by ACReconciler, AdmissionCheckReconciler, acReconciler, prcHandler, kueue/v1beta1/AdmissionCheck)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/controller/admissionchecks/multikueue/multikueuecluster.go`:442 (/v1/Secret, get operations by clustersReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/controller/admissionchecks/provisioning/controller.go`:305 (/v1/PodTemplate, create, get, update operations by Controller)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/controller/core/cohort_controller.go`:137 (get, update operations by CohortReconciler, kueue/v1alpha1/Cohort)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/controller/jobframework/defaults.go`:67 (/v1/Namespace, get operations by ClusterQueue, JobReconciler, PodWebhook, Scheduler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/controller/jobs/job/job_controller.go`:128 (batch/v1/Job, create, delete, get, list operations by multiKueueAdapter, parentWorkloadHandler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/controller/tas/topology_controller.go`:91 (get, update operations by topologyReconciler, kueue/v1alpha1/Topology)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/workload/resources.go`:69 (/v1/LimitRange, list operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controller/admissionchecks/multikueue/admissioncheck.go`:181 (ACReconciler, kueue/v1beta1/AdmissionCheck)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controller/admissionchecks/multikueue/multikueuecluster.go`:600 (/v1/Secret, clustersReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controller/admissionchecks/provisioning/controller.go`:831 (Controller, autoscaling.x-k8s.io/v1beta1/ProvisioningRequest)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controller/admissionchecks/provisioning/controller.go`:849 (Controller, kueue/v1beta1/AdmissionCheck)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controller/core/clusterqueue_controller.go`:591 (/v1/Namespace, ClusterQueueReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controller/core/workload_controller.go`:797 (/v1/LimitRange, WorkloadReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controller/jobs/leaderworkerset/leaderworkerset_pod_reconciler.go`:57 (/v1/Pod, PodReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controller/jobs/pod/pod_controller.go`:131 (/v1/Pod, Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controller/jobs/statefulset/statefulset_reconciler.go`:145 (Reconciler, apps/v1/StatefulSet)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controller/jobs/statefulset/statefulset_reconciler.go`:147 (/v1/Pod, Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controller/tas/resource_flavor.go`:83 (/v1/Node, rfReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controller/tas/topology_ungater.go`:102 (/v1/Pod, topologyUngater)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `config/components/webhook/service.yaml`:1 (kueue-webhook-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `config/rhoai/kueue-metrics-service.yaml`:1 (kueue-metrics-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `config/rhoai/manager_metrics_patch.yaml`:1 (kueue-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### webhooks

- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/rhoai/mutating_webhook_patch.yaml`:1 (/mutate-apps-v1-deployment, mdeployment.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/rhoai/mutating_webhook_patch.yaml`:1 (/mutate-batch-v1-job, mjob.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/rhoai/mutating_webhook_patch.yaml`:1 (/mutate-jobset-x-k8s-io-v1alpha2-jobset, mjobset.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/rhoai/mutating_webhook_patch.yaml`:1 (/mutate-kubeflow-org-v1-paddlejob, mpaddlejob.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/rhoai/mutating_webhook_patch.yaml`:1 (/mutate-kubeflow-org-v1-pytorchjob, mpytorchjob.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/rhoai/mutating_webhook_patch.yaml`:1 (/mutate-workload-codeflare-dev-v1beta2-appwrapper, mappwrapper.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/controller/jobs/appwrapper/appwrapper_controller.go`:81 (/mutate-workload-codeflare-dev-v1beta2-appwrapper, mappwrapper.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/controller/jobs/deployment/deployment_webhook.go`:62 (/mutate-apps-v1-deployment, mdeployment.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/controller/jobs/job/job_webhook.go`:72 (/mutate-batch-v1-job, mjob.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/controller/jobs/jobset/jobset_webhook.go`:66 (/mutate-jobset-x-k8s-io-v1alpha2-jobset, mjobset.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/controller/jobs/kubeflow/jobs/paddlejob/paddlejob_controller.go`:48 (/mutate-kubeflow-org-v1-paddlejob, mpaddlejob.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/controller/jobs/kubeflow/jobs/pytorchjob/pytorchjob_controller.go`:48 (/mutate-kubeflow-org-v1-pytorchjob, mpytorchjob.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- /healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: cmd/kueue/main.go:381]
- /readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/kueue/main.go:393]
- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes liveness probe endpoint [source: config/rhoai/manager_metrics_patch.yaml:1]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes readiness probe endpoint [source: config/rhoai/manager_metrics_patch.yaml:1]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=In-cluster configuration provides automatic ServiceAccount token authentication [source: cmd/experimental/kueue-viz/backend/kubernetes_client.go:31]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via kueue-manager-role ClusterRole; SA kueue-controller-manager [source: cmd/kueue/main.go:422]
- Operator webhook methods=CREATE mechanism=Kubernetes admission enforcement=ValidatingWebhookConfiguration policy=Admission validation [source: config/rhoai/validating_webhook_patch.yaml:1]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/kueue [source: cmd/kueue/main.go:381]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/kueue [source: cmd/kueue/main.go:393]
- GET /ws/cluster-queue/:cluster_queue_name on port ; transport=HTTP/1.1 encryption= auth= owner=handlers [source: cmd/experimental/kueue-viz/backend/handlers/handlers.go:41]
- GET /ws/cluster-queues on port ; transport=HTTP/1.1 encryption= auth= owner=handlers [source: cmd/experimental/kueue-viz/backend/handlers/handlers.go:40]
- GET /ws/cohort/:cohort_name on port ; transport=HTTP/1.1 encryption= auth= owner=handlers [source: cmd/experimental/kueue-viz/backend/handlers/handlers.go:45]
- GET /ws/cohorts on port ; transport=HTTP/1.1 encryption= auth= owner=handlers [source: cmd/experimental/kueue-viz/backend/handlers/handlers.go:44]
- GET /ws/local-queue/:namespace/:queue_name on port ; transport=HTTP/1.1 encryption= auth= owner=handlers [source: cmd/experimental/kueue-viz/backend/handlers/handlers.go:36]
- GET /ws/local-queue/:namespace/:queue_name/workloads on port ; transport=HTTP/1.1 encryption= auth= owner=handlers [source: cmd/experimental/kueue-viz/backend/handlers/handlers.go:37]
- GET /ws/local-queues on port ; transport=HTTP/1.1 encryption= auth= owner=handlers [source: cmd/experimental/kueue-viz/backend/handlers/handlers.go:35]
- GET /ws/resource-flavor/:flavor_name on port ; transport=HTTP/1.1 encryption= auth= owner=handlers [source: cmd/experimental/kueue-viz/backend/handlers/handlers.go:49]
- GET /ws/resource-flavors on port ; transport=HTTP/1.1 encryption= auth= owner=handlers [source: cmd/experimental/kueue-viz/backend/handlers/handlers.go:48]
- GET /ws/workload/:namespace/:workload_name on port ; transport=HTTP/1.1 encryption= auth= owner=handlers [source: cmd/experimental/kueue-viz/backend/handlers/handlers.go:31]
- GET /ws/workload/:namespace/:workload_name/events on port ; transport=HTTP/1.1 encryption= auth= owner=handlers [source: cmd/experimental/kueue-viz/backend/handlers/handlers.go:32]
- GET /ws/workloads on port ; transport=HTTP/1.1 encryption= auth= owner=handlers [source: cmd/experimental/kueue-viz/backend/handlers/handlers.go:28]
- GET /ws/workloads/dashboard on port ; transport=HTTP/1.1 encryption= auth= owner=handlers [source: cmd/experimental/kueue-viz/backend/handlers/handlers.go:29]
### integrations

- Kubeflow Notebooks interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Create and manage notebook workbenches [source: config/rhoai/manager_role_patch.yaml:1]
- Kubernetes API interaction=API client role=runtime-integration protocol=HTTPS purpose=Cluster resource management via RBAC [source: config/rhoai/manager_role_patch.yaml:1]
### internal_dependencies

- Kubeflow Notebooks (kubeflow.org) interaction=CRD CRUD role=unknown purpose=Create and manage notebook workbenches [source: config/rhoai/manager_role_patch.yaml:1]
- Kubernetes API (nodes) interaction=list role=unknown purpose=nodes resource access via RBAC [source: config/rhoai/manager_role_patch.yaml:1]
### services

- kueue-metrics-service port=8443 target=https-metrics protocol=TCP encryption= auth= [source: config/rhoai/kueue-metrics-service.yaml:1]
- kueue-webhook-service port=443 target=9443 protocol=TCP encryption= auth= [source: config/components/webhook/service.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload kueue-controller-manager uses service account kueue-controller-manager and 1 container(s) [source: config/rhoai/manager_metrics_patch.yaml:1]
- **observed**: Service kueue-metrics-service targets  with 1 port(s) [source: config/rhoai/kueue-metrics-service.yaml:1]
- **observed**: Service kueue-webhook-service targets  with 1 port(s) [source: config/components/webhook/service.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by cmd/kueue [source: cmd/kueue/main.go:381]
- **observed**: HTTP GET /readyz is owned by cmd/kueue [source: cmd/kueue/main.go:393]
- **observed**: HTTP GET /ws/cluster-queue/:cluster_queue_name is owned by handlers [source: cmd/experimental/kueue-viz/backend/handlers/handlers.go:41]
- **observed**: HTTP GET /ws/cluster-queues is owned by handlers [source: cmd/experimental/kueue-viz/backend/handlers/handlers.go:40]
- **observed**: HTTP GET /ws/cohort/:cohort_name is owned by handlers [source: cmd/experimental/kueue-viz/backend/handlers/handlers.go:45]
- **observed**: HTTP GET /ws/cohorts is owned by handlers [source: cmd/experimental/kueue-viz/backend/handlers/handlers.go:44]
- **observed**: HTTP GET /ws/local-queue/:namespace/:queue_name is owned by handlers [source: cmd/experimental/kueue-viz/backend/handlers/handlers.go:36]
- **observed**: HTTP GET /ws/local-queue/:namespace/:queue_name/workloads is owned by handlers [source: cmd/experimental/kueue-viz/backend/handlers/handlers.go:37]
- **observed**: HTTP GET /ws/local-queues is owned by handlers [source: cmd/experimental/kueue-viz/backend/handlers/handlers.go:35]
- **observed**: HTTP GET /ws/resource-flavor/:flavor_name is owned by handlers [source: cmd/experimental/kueue-viz/backend/handlers/handlers.go:49]
- **observed**: HTTP GET /ws/resource-flavors is owned by handlers [source: cmd/experimental/kueue-viz/backend/handlers/handlers.go:48]
- **observed**: HTTP GET /ws/workload/:namespace/:workload_name is owned by handlers [source: cmd/experimental/kueue-viz/backend/handlers/handlers.go:31]
- **observed**: HTTP GET /ws/workload/:namespace/:workload_name/events is owned by handlers [source: cmd/experimental/kueue-viz/backend/handlers/handlers.go:32]
- **observed**: HTTP GET /ws/workloads is owned by handlers [source: cmd/experimental/kueue-viz/backend/handlers/handlers.go:28]
- **observed**: HTTP GET /ws/workloads/dashboard is owned by handlers [source: cmd/experimental/kueue-viz/backend/handlers/handlers.go:29]
### security

- **observed**: CREATE Operator webhook uses Kubernetes admission at ValidatingWebhookConfiguration; policy=Admission validation [source: config/rhoai/validating_webhook_patch.yaml:1]
- **observed**: GET /healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: cmd/kueue/main.go:381]
- **observed**: GET /readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/kueue/main.go:393]
- **observed**: GET :8081/healthz uses None at N/A; policy=Unauthenticated Kubernetes liveness probe endpoint [source: config/rhoai/manager_metrics_patch.yaml:1]
- **observed**: GET :8081/readyz uses None at N/A; policy=Unauthenticated Kubernetes readiness probe endpoint [source: config/rhoai/manager_metrics_patch.yaml:1]
- **observed**: RBAC role kueue-batch-admin-role grants 0 rule(s) [source: config/components/rbac/batch_admin_role.yaml:2]
- **observed**: RBAC role kueue-batch-user-role grants 0 rule(s) [source: config/components/rbac/batch_user_role.yaml:2]
- **observed**: RBAC role kueue-clusterqueue-editor-role grants 2 rule(s) [source: config/components/rbac/clusterqueue_editor_role.yaml:2]
- **observed**: RBAC role kueue-clusterqueue-viewer-role grants 2 rule(s) [source: config/rhoai/clusterqueue_viewer_role_patch.yaml:2]
- **observed**: RBAC role kueue-cohort-editor-role grants 1 rule(s) [source: config/components/rbac/cohort_editor_role.yaml:2]
- **observed**: RBAC role kueue-cohort-viewer-role grants 1 rule(s) [source: config/components/rbac/cohort_viewer_role.yaml:2]
- **observed**: RBAC role kueue-job-editor-role grants 2 rule(s) [source: config/components/rbac/job_editor_role.yaml:2]
- **observed**: RBAC role kueue-job-viewer-role grants 2 rule(s) [source: config/components/rbac/job_viewer_role.yaml:2]
- **observed**: RBAC role kueue-jobset-editor-role grants 2 rule(s) [source: config/components/rbac/jobset_editor_role.yaml:2]
- **observed**: RBAC role kueue-jobset-viewer-role grants 2 rule(s) [source: config/components/rbac/jobset_viewer_role.yaml:2]
- **observed**: RBAC role kueue-localqueue-editor-role grants 2 rule(s) [source: config/components/rbac/localqueue_editor_role.yaml:2]
- **observed**: RBAC role kueue-localqueue-viewer-role grants 2 rule(s) [source: config/components/rbac/localqueue_viewer_role.yaml:2]
- **observed**: RBAC role kueue-manager-role grants 37 rule(s) [source: config/rhoai/manager_role_patch.yaml:1]
- **observed**: RBAC role kueue-metrics-auth-role grants 2 rule(s) [source: config/components/rbac/metrics_auth_role.yaml:1]
- **observed**: RBAC role kueue-metrics-reader grants 1 rule(s) [source: config/components/rbac/metrics_reader_role.yaml:1]
- **observed**: RBAC role kueue-mpijob-editor-role grants 2 rule(s) [source: config/components/rbac/mpijob_editor_role.yaml:2]
- **observed**: RBAC role kueue-pending-workloads-cq-viewer-role grants 1 rule(s) [source: config/components/rbac/pending_workloads_cq_viewer_role.yaml:2]
- **observed**: RBAC role kueue-pending-workloads-lq-viewer-role grants 1 rule(s) [source: config/components/rbac/pending_workloads_lq_viewer_role.yaml:2]
- **observed**: RBAC role kueue-resourceflavor-editor-role grants 1 rule(s) [source: config/components/rbac/resourceflavor_editor_role.yaml:2]
- **observed**: RBAC role kueue-resourceflavor-viewer-role grants 1 rule(s) [source: config/components/rbac/resourceflavor_viewer_role.yaml:2]
- **observed**: RBAC role kueue-topology-editor-role grants 1 rule(s) [source: config/components/rbac/topology_editor_role.yaml:2]
- **observed**: RBAC role kueue-topology-viewer-role grants 1 rule(s) [source: config/components/rbac/topology_viewer_role.yaml:1]
- **observed**: RBAC role kueue-workload-editor-role grants 2 rule(s) [source: config/components/rbac/workload_editor_role.yaml:2]
- **observed**: RBAC role kueue-workload-viewer-role grants 2 rule(s) [source: config/components/rbac/workload_viewer_role.yaml:2]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=In-cluster configuration provides automatic ServiceAccount token authentication [source: cmd/experimental/kueue-viz/backend/kubernetes_client.go:31]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via kueue-manager-role ClusterRole; SA kueue-controller-manager [source: cmd/kueue/main.go:422]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: cmd/kueue/main.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
