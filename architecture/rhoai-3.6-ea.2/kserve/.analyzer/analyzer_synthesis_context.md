# Analyzer Synthesis Context: kserve

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 19 crds facts extracted [source: kserve-module/pkg/apis/v1alpha1/types.go:43, pkg/apis/serving/v1alpha1/inference_graph.go:35, pkg/apis/serving/v1alpha1/kernel_cache_capture_types.go:30, pkg/apis/serving/v1alpha1/kernel_cache_node_group_types.go:32, pkg/apis/serving/v1alpha1/kernel_cache_node_types.go:34, pkg/apis/serving/v1alpha1/kernel_cache_types.go:34, pkg/apis/serving/v1alpha1/llm_inference_service_types.go:61, pkg/apis/serving/v1alpha1/llm_inference_service_types.go:77, pkg/apis/serving/v1alpha1/local_model_cache_types.go:70, pkg/apis/serving/v1alpha1/local_model_namespace_cache_types.go:73, pkg/apis/serving/v1alpha1/local_model_node_group_types.go:40, pkg/apis/serving/v1alpha1/local_model_node_types.go:62, pkg/apis/serving/v1alpha1/servingruntime_types.go:245, pkg/apis/serving/v1alpha1/servingruntime_types.go:271, pkg/apis/serving/v1alpha1/storage_container_types.go:61, pkg/apis/serving/v1alpha1/trained_model.go:33, pkg/apis/serving/v1alpha2/llm_inference_service_types.go:47, pkg/apis/serving/v1alpha2/llm_inference_service_types.go:64, pkg/apis/serving/v1beta1/inference_service.go:176]
- **grpc_services (observed)**: 8 grpc_services facts extracted [source: python/kserve/kserve/protocol/grpc/grpc_predict_v2.proto:23, python/kserve/kserve/protocol/grpc/grpc_predict_v2.proto:26, python/kserve/kserve/protocol/grpc/grpc_predict_v2.proto:29, python/kserve/kserve/protocol/grpc/grpc_predict_v2.proto:34, python/kserve/kserve/protocol/grpc/grpc_predict_v2.proto:39, python/kserve/kserve/protocol/grpc/grpc_predict_v2.proto:44, python/kserve/kserve/protocol/grpc/grpc_predict_v2.proto:47, python/kserve/kserve/protocol/grpc/grpc_predict_v2.proto:50]
- **http_endpoints (observed)**: 18 http_endpoints facts extracted [source: cmd/llmisvc/main.go:353, cmd/llmisvc/main.go:357, cmd/localmodel/main.go:208, cmd/localmodel/main.go:212, cmd/manager/main.go:305, cmd/manager/main.go:311, cmd/router/main.go:675, docs/samples/graph/bgtest/bgtest/main.go:26, docs/samples/graph/bgtest/bgtest/main.go:27, docs/samples/graph/bgtest/bgtest/main.go:28, docs/samples/graph/bgtest/bgtest/main.go:29, kserve-module/cmd/kserve-module/main.go:91, kserve-module/cmd/kserve-module/main.go:95, python/huggingfaceserver/test_health_check.py:114, python/huggingfaceserver/test_health_check.py:26, python/huggingfaceserver/test_health_check.py:27, python/huggingfaceserver/test_health_check.py:36, qpext/cmd/qpext/main.go:323]
- **services (observed)**: 4 services facts extracted [source: config/manager/service.yaml:1, config/rbac/auth_proxy_service.yaml:1, config/webhook/service.yaml:1, python/huggingfaceserver/test_health_check.py:27]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (observed)**: 30 webhooks facts extracted [source: charts/kserve-llmisvc-crd/templates/serving.kserve.io_llminferenceserviceconfigs.yaml:2, charts/kserve-llmisvc-crd/templates/serving.kserve.io_llminferenceservices.yaml:2, config/default/clusterservingruntime_validatingwebhook_cainjection_patch.yaml:1, config/default/inferencegraph_validatingwebhook_cainjection_patch.yaml:1, config/default/isvc_mutatingwebhook_cainjection_patch.yaml:1, config/default/isvc_validatingwebhook_cainjection_patch.yaml:1, config/default/servingruntime_validationwebhook_cainjection_patch.yaml:1, config/default/trainedmodel_validatingwebhook_cainjection_patch.yaml:1, config/webhook/llmisvc/manifests.yaml:1, config/webhook/llmisvc/manifests.yaml:48, config/webhook/llmisvc/manifests.yaml:95, config/webhook/localmodel/manifests.yaml:2, config/webhook/manifests.yaml:108, config/webhook/manifests.yaml:134, config/webhook/manifests.yaml:160, config/webhook/manifests.yaml:2, config/webhook/manifests.yaml:56, config/webhook/manifests.yaml:82, pkg/apis/serving/v1alpha1/inference_graph_validation.go:68, pkg/apis/serving/v1alpha1/llm_inference_service_config_validation.go:33, pkg/apis/serving/v1alpha1/llm_inference_service_validation.go:35, pkg/apis/serving/v1alpha1/trainedmodel_webhook.go:60, pkg/apis/serving/v1alpha2/llm_inference_service_config_validation.go:34, pkg/apis/serving/v1alpha2/llm_inference_service_validation.go:54, pkg/apis/serving/v1beta1/inference_service_defaults.go:55, pkg/apis/serving/v1beta1/inference_service_validation.go:67, pkg/webhook/admission/llminferenceservice/defaulter.go:41, pkg/webhook/admission/llminferenceservice/defaulter.go:67, pkg/webhook/admission/localmodelcache/localmodelcache_validator.go:49, pkg/webhook/admission/localmodelnamespacecache/local_model_namespace_cache_validation.go:51, pkg/webhook/admission/pod/mutator.go:36, pkg/webhook/admission/servingruntime/servingruntime_webhook.go:57, pkg/webhook/admission/servingruntime/servingruntime_webhook.go:64]

## Deterministic Cross-References

- **controller**: InferenceGraphReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: pkg/controller/v1alpha1/inferencegraph/controller.go:455, pkg/controller/v1alpha2/llmisvc/scheduler.go:437]
- **controller**: InferenceGraphReconciler —watches-reference→ route.openshift.io/v1/Route; route.openshift.io/v1/Route [source: pkg/controller/v1alpha1/inferencegraph/controller.go:458, pkg/controller/v1alpha1/inferencegraph/openshift_route_reconciler.go:56]
- **controller**: InferenceServiceReconciler —watches-reference→ /v1/Pod; /v1/Pod [source: pkg/controller/v1alpha2/llmisvc/workload_tls_self_signed.go:336, pkg/controller/v1beta1/inferenceservice/controller.go:733]
- **controller**: InferenceServiceReconciler —watches-reference→ /v1/Service; /v1/Service [source: pkg/controller/v1alpha2/llmisvc/controller_setup_odh.go:266, pkg/controller/v1beta1/inferenceservice/controller.go:679]
- **controller**: InferenceServiceReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: pkg/controller/v1alpha2/llmisvc/scheduler.go:437, pkg/controller/v1beta1/inferenceservice/controller.go:678]
- **controller**: InferenceServiceReconciler —watches-reference→ gateway.networking.k8s.io/v1/HTTPRoute; gateway.networking.k8s.io/v1/HTTPRoute [source: pkg/controller/v1alpha2/llmisvc/controller_setup_odh.go:167, pkg/controller/v1beta1/inferenceservice/controller.go:723]
- **controller**: InferenceServiceReconciler —watches-reference→ networking.k8s.io/v1/Ingress; networking.k8s.io/v1/Ingress [source: pkg/controller/v1beta1/inferenceservice/controller.go:729, pkg/controller/v1beta1/inferenceservice/reconcilers/ingress/kube_ingress_reconciler.go:78]
- **controller**: KserveModuleReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: kserve-module/pkg/kservemodule/setup.go:116, pkg/controller/v1alpha2/llmisvc/config_loader.go:199]
- **controller**: KserveModuleReconciler —watches-reference→ /v1/Node; /v1/Node [source: kserve-module/pkg/kservemodule/setup.go:145, pkg/controller/v1alpha1/localmodel/reconcilers/utils.go:153]
- **controller**: KserveModuleReconciler —watches-reference→ /v1/PersistentVolume; /v1/PersistentVolume [source: kserve-module/pkg/kservemodule/setup.go:120, pkg/controller/v1alpha1/localmodel/reconcilers/utils.go:394]
- **controller**: KserveModuleReconciler —watches-reference→ /v1/PersistentVolumeClaim; /v1/PersistentVolumeClaim [source: kserve-module/pkg/kservemodule/setup.go:121, pkg/controller/v1alpha1/localmodel/reconcilers/sharedpvc.go:98]
- **controller**: KserveModuleReconciler —watches-reference→ /v1/Secret; /v1/Secret [source: kserve-module/pkg/kservemodule/setup.go:117, pkg/controller/v1alpha2/llmisvc/workload_tls_cert_odh.go:111]
- **controller**: KserveModuleReconciler —watches-reference→ /v1/Service; /v1/Service [source: kserve-module/pkg/kservemodule/setup.go:118, pkg/controller/v1alpha2/llmisvc/controller_setup_odh.go:266]
- **controller**: KserveModuleReconciler —watches-reference→ /v1/ServiceAccount; /v1/ServiceAccount [source: kserve-module/pkg/kservemodule/setup.go:119, pkg/controller/v1alpha2/llmisvc/scheduler.go:692]
- **controller**: KserveModuleReconciler —watches-reference→ admissionregistration/v1/MutatingWebhookConfiguration; admissionregistration/v1/MutatingWebhookConfiguration [source: kserve-module/pkg/kservemodule/setup.go:129, kserve-module/pkg/kservemodule/upgrade.go:217]
- **controller**: KserveModuleReconciler —watches-reference→ admissionregistration/v1/ValidatingWebhookConfiguration; admissionregistration/v1/ValidatingWebhookConfiguration [source: kserve-module/pkg/kservemodule/llmisvcconfig_cleanup.go:322, kserve-module/pkg/kservemodule/setup.go:130]
- **controller**: KserveModuleReconciler —watches-reference→ apps/v1/DaemonSet; apps/v1/DaemonSet [source: kserve-module/pkg/kservemodule/modelcache.go:469, kserve-module/pkg/kservemodule/setup.go:123]
- **controller**: KserveModuleReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: kserve-module/pkg/kservemodule/setup.go:122, pkg/controller/v1alpha2/llmisvc/scheduler.go:437]
- **controller**: KserveModuleReconciler —watches-reference→ rbac.authorization.k8s.io/v1/RoleBinding; rbac.authorization.k8s.io/v1/RoleBinding [source: kserve-module/pkg/kservemodule/setup.go:126, pkg/controller/v1beta1/inferenceservice/workload_permissions_odh.go:169]
- **controller**: LLMISVCReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: pkg/controller/v1alpha2/llmisvc/config_loader.go:199, pkg/controller/v1alpha2/llmisvc/controller.go:434]
- **controller**: LLMISVCReconciler —watches-reference→ /v1/Pod; /v1/Pod [source: pkg/controller/v1alpha2/llmisvc/controller.go:436, pkg/controller/v1alpha2/llmisvc/workload_tls_self_signed.go:336]
- **controller**: LLMISVCReconciler —watches-reference→ /v1/Secret; /v1/Secret [source: pkg/controller/v1alpha2/llmisvc/controller.go:431, pkg/controller/v1alpha2/llmisvc/workload_tls_cert_odh.go:111]
- **controller**: LLMISVCReconciler —watches-reference→ /v1/Service; /v1/Service [source: pkg/controller/v1alpha2/llmisvc/controller.go:432, pkg/controller/v1alpha2/llmisvc/controller_setup_odh.go:266]
- **controller**: LLMISVCReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: pkg/controller/v1alpha2/llmisvc/controller.go:430, pkg/controller/v1alpha2/llmisvc/scheduler.go:437]
- **controller**: LLMISVCReconciler —watches-reference→ autoscaling/v2/HorizontalPodAutoscaler; autoscaling/v2/HorizontalPodAutoscaler [source: pkg/controller/v1alpha2/llmisvc/controller.go:433, pkg/controller/v1alpha2/llmisvc/scaling.go:278]
- **controller**: LLMISVCReconciler —watches-reference→ gateway.networking.k8s.io/v1/Gateway; gateway.networking.k8s.io/v1/Gateway [source: pkg/controller/v1alpha2/llmisvc/controller.go:455, pkg/controller/v1alpha2/llmisvc/router.go:631]
- **controller**: LLMISVCReconciler —watches-reference→ gateway.networking.k8s.io/v1/HTTPRoute; gateway.networking.k8s.io/v1/HTTPRoute [source: pkg/controller/v1alpha2/llmisvc/controller.go:451, pkg/controller/v1alpha2/llmisvc/controller_setup_odh.go:167]
- **controller**: LLMISVCReconciler —watches-reference→ networking.k8s.io/v1/Ingress; networking.k8s.io/v1/Ingress [source: pkg/controller/v1alpha2/llmisvc/controller.go:429, pkg/controller/v1beta1/inferenceservice/reconcilers/ingress/kube_ingress_reconciler.go:78]
- **controller**: LLMISVCReconciler —watches-reference→ route.openshift.io/v1/Route; route.openshift.io/v1/Route [source: pkg/controller/v1alpha1/inferencegraph/openshift_route_reconciler.go:56, pkg/controller/v1alpha2/llmisvc/controller_setup_odh.go:59]
- **controller**: LocalModelNamespaceCacheReconciler —watches-reference→ /v1/Node; /v1/Node [source: pkg/controller/v1alpha1/localmodel/reconcilers/localmodelnamespacecache_reconciler.go:464, pkg/controller/v1alpha1/localmodel/reconcilers/utils.go:153]
- **controller**: LocalModelNamespaceCacheReconciler —watches-reference→ /v1/PersistentVolumeClaim; /v1/PersistentVolumeClaim [source: pkg/controller/v1alpha1/localmodel/reconcilers/localmodelnamespacecache_reconciler.go:432, pkg/controller/v1alpha1/localmodel/reconcilers/sharedpvc.go:98]
- **controller**: LocalModelNamespaceCacheReconciler —watches-reference→ batch/v1/Job; batch/v1/Job [source: pkg/controller/v1alpha1/localmodel/reconcilers/localmodelnamespacecache_reconciler.go:434, pkg/controller/v1alpha1/localmodel/reconcilers/sharedpvc.go:172]
- **controller**: LocalModelNodeReconciler —watches-reference→ batch/v1/Job; batch/v1/Job [source: pkg/controller/v1alpha1/localmodel/reconcilers/sharedpvc.go:172, pkg/controller/v1alpha1/localmodelnode/controller.go:602]
- **controller**: LocalModelReconciler —watches-reference→ /v1/Node; /v1/Node [source: pkg/controller/v1alpha1/localmodel/reconcilers/localmodelcache_reconciler.go:371, pkg/controller/v1alpha1/localmodel/reconcilers/utils.go:153]
- **controller**: LocalModelReconciler —watches-reference→ /v1/PersistentVolume; /v1/PersistentVolume [source: pkg/controller/v1alpha1/localmodel/reconcilers/localmodelcache_reconciler.go:341, pkg/controller/v1alpha1/localmodel/reconcilers/utils.go:394]
- **controller**: LocalModelReconciler —watches-reference→ /v1/PersistentVolumeClaim; /v1/PersistentVolumeClaim [source: pkg/controller/v1alpha1/localmodel/reconcilers/localmodelcache_reconciler.go:342, pkg/controller/v1alpha1/localmodel/reconcilers/sharedpvc.go:98]
- **controller**: ProfileWatcher —watches-reference→ config.openshift.io/v1/APIServer; config.openshift.io/v1/APIServer [source: pkg/tls/distro/resolve.go:116, pkg/tls/distro/watcher.go:63]
- **security**: GET /healthz —protected-by→ None; N/A: Kubernetes health probe; unauthenticated by design [source: cmd/llmisvc/main.go:353, cmd/localmodel/main.go:208]
- **security**: GET /readyz —protected-by→ None; N/A: Kubernetes readiness probe; unauthenticated by design [source: cmd/llmisvc/main.go:357, cmd/localmodel/main.go:212]

## Behavioral Evidence

- **named-watch-predicate (unresolved)** pkg/controller/v1alpha1/localmodel/reconcilers.LocalModelNamespaceCacheReconciler: serving.kserve.io/v1beta1/InferenceService; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: pkg/controller/v1alpha1/localmodel/reconcilers/localmodelnamespacecache_reconciler.go:456-456]
- **named-watch-predicate (unresolved)** pkg/controller/v1alpha1/localmodel/reconcilers.LocalModelNamespaceCacheReconciler: serving.kserve.io/v1alpha2/LLMInferenceService; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: pkg/controller/v1alpha1/localmodel/reconcilers/localmodelnamespacecache_reconciler.go:458-458]
- **named-watch-predicate (unresolved)** pkg/controller/v1alpha1/localmodel/reconcilers.LocalModelNamespaceCacheReconciler: serving.kserve.io/v1alpha1/LocalModelNamespaceCache; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: pkg/controller/v1alpha1/localmodel/reconcilers/localmodelnamespacecache_reconciler.go:463-463]
- **named-watch-predicate (unresolved)** pkg/controller/v1alpha1/localmodel/reconcilers.LocalModelNamespaceCacheReconciler: /v1/Node; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: pkg/controller/v1alpha1/localmodel/reconcilers/localmodelnamespacecache_reconciler.go:464-464]
- **named-watch-predicate (unresolved)** pkg/controller/v1alpha1/localmodel/reconcilers.LocalModelNamespaceCacheReconciler: serving.kserve.io/v1alpha1/LocalModelNode; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: pkg/controller/v1alpha1/localmodel/reconcilers/localmodelnamespacecache_reconciler.go:465-465]
- **named-watch-predicate (unresolved)** pkg/controller/v1alpha1/localmodel/reconcilers.LocalModelReconciler: serving.kserve.io/v1beta1/InferenceService; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: pkg/controller/v1alpha1/localmodel/reconcilers/localmodelcache_reconciler.go:364-364]
- **named-watch-predicate (unresolved)** pkg/controller/v1alpha1/localmodel/reconcilers.LocalModelReconciler: serving.kserve.io/v1alpha2/LLMInferenceService; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: pkg/controller/v1alpha1/localmodel/reconcilers/localmodelcache_reconciler.go:366-366]
- **named-watch-predicate (unresolved)** pkg/controller/v1alpha1/localmodel/reconcilers.LocalModelReconciler: /v1/Node; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: pkg/controller/v1alpha1/localmodel/reconcilers/localmodelcache_reconciler.go:371-371]
- **named-watch-predicate (unresolved)** pkg/controller/v1alpha1/localmodel/reconcilers.LocalModelReconciler: serving.kserve.io/v1alpha1/LocalModelNode; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: pkg/controller/v1alpha1/localmodel/reconcilers/localmodelcache_reconciler.go:373-373]
- **named-watch-predicate (unresolved)** pkg/controller/v1alpha2/llmisvc.LLMISVCReconciler: /v1/ConfigMap; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: pkg/controller/v1alpha2/llmisvc/controller.go:434-434]
- **named-watch-predicate (unresolved)** pkg/controller/v1alpha2/llmisvc.LLMISVCReconciler: /v1/ConfigMap; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: pkg/controller/v1alpha2/llmisvc/controller.go:435-435]
- **named-watch-predicate (unresolved)** pkg/controller/v1alpha2/llmisvc.LLMISVCReconciler: /v1/Pod; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: pkg/controller/v1alpha2/llmisvc/controller.go:436-438]
- **named-watch-predicate (unresolved)** pkg/controller/v1alpha2/llmisvc.LLMISVCReconciler: serving.kserve.io/v1alpha2/LLMInferenceService; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: pkg/controller/v1alpha2/llmisvc/controller.go:440-444]
- **named-watch-predicate (unresolved)** pkg/controller/v1alpha2/llmisvc.LLMISVCReconciler: serving.kserve.io/v1alpha1/ClusterServingRuntime; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: pkg/controller/v1alpha2/llmisvc/controller.go:495-497]
- **named-watch-predicate (unresolved)** pkg/controller/v1alpha2/llmisvc.LLMISVCReconciler: serving.kserve.io/v1alpha1/ServingRuntime; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: pkg/controller/v1alpha2/llmisvc/controller.go:500-502]
- **named-watch-predicate (unresolved)** pkg/controller/v1alpha2/llmisvc.LLMISVCReconciler: route.openshift.io/v1/Route; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: pkg/controller/v1alpha2/llmisvc/controller_setup_odh.go:59-62]
- 5 additional behavioral records remain in the analyzer JSON.

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/llmisvc/main.go`:264 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/llmisvc/main.go`:353 (/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/llmisvc/main.go`:357 (/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/router/main.go`:525 (Kubernetes TokenReview API, Token validation)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/router/main.go`:614 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `config/default/isvc_validatingwebhook_cainjection_patch.yaml`:1 (Kubernetes admission, Operator webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `kserve-module/cmd/kserve-module/main.go`:91 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `kserve-module/cmd/kserve-module/main.go`:95 (:8081/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `kserve-module/config/rbac/role.yaml`:2 (Named Secret access (kserve-webhook-server-secret, workload-variant-autoscaler-controller-manager-token, workload-variant-autoscaler-epp-metrics-token, workload-variant-autoscaler-metrics-reader-token), RBAC with resourceNames restriction)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `python/huggingfaceserver/test_health_check.py`:27 (HTTP API, None (no auth middleware detected))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/auth_proxy_role.yaml`:1 (kserve-proxy-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/rbac/auth_proxy_role_binding.yaml`:1 (kserve-proxy-role, kserve-proxy-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/leader_election_role.yaml`:2 (kserve-leader-election-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/rbac/llmisvc/clusterrolebinding.yaml`:1 (kserve-llmisvc-manager-role, llmisvc-manager-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/llmisvc/leader_election_role.yaml`:2 (llmisvc-leader-election-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/llmisvc/role.yaml`:2 (kserve-llmisvc-manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/localmodel/role.yaml`:2 (kserve-localmodel-manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/localmodelnode/role.yaml`:2 (kserve-localmodelnode-agent-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/role.yaml`:2 (kserve-manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/rbac/role_binding.yaml`:1 (kserve-manager-role, kserve-manager-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `kserve-module/config/rbac/leader_election_role.yaml`:1 (kserve-module-leader-election-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `kserve-module/config/rbac/role.yaml`:2 (kserve-module-manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:55 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfiles/Dockerfile.konflux.kserve-module-controller`:33 (Dockerfiles/Dockerfile.konflux.kserve-module-controller:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `docs/apis/Dockerfile`:14 (docs/apis/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `docs/apis/Dockerfile`:15 (docs/apis/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `docs/kfp/Dockerfile`:13 (docs/kfp/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `docs/kfp/Dockerfile`:14 (docs/kfp/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `docs/samples/explanation/aif/germancredit/server/Dockerfile`:19 (docs/samples/explanation/aif/germancredit/server/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `docs/samples/graph/bgtest/Dockerfile`:8 (docs/samples/graph/bgtest/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `docs/samples/v1beta1/custom/paddleserving/Dockerfile`:9 (docs/samples/v1beta1/custom/paddleserving/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `docs/samples/v1beta1/custom/torchserve/torchserve-image/Dockerfile`:92 (docs/samples/v1beta1/custom/torchserve/torchserve-image/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `docs/samples/v1beta1/custom/torchserve/torchserve-image/Dockerfile`:93 (docs/samples/v1beta1/custom/torchserve/torchserve-image/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `docs/samples/v1beta1/torchserve/model-archiver/model-archiver-image/Dockerfile`:37 (docs/samples/v1beta1/torchserve/model-archiver/model-archiver-image/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/llmisvc/main.go`:164 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/llmisvc/main.go`:380 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/llmisvc/main.go`:407 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/localmodel/main.go`:113 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/localmodelnode/main.go`:107 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/manager/main.go`:128 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/router/main.go`:623 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pkg/agent/storage/utils.go`:142 (Azure Blob Storage, Azure Blob Storage client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pkg/agent/storage/utils.go`:163 (Azure Blob Storage, Azure Blob Storage client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pkg/agent/storage/utils.go`:196 (GCS storage client, Google Cloud Storage)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pkg/agent/storage/utils.go`:198 (GCS storage client, Google Cloud Storage)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pkg/utils/utils.go`:246 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### grpc_services

- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `python/kserve/kserve/protocol/grpc/grpc_predict_v2.proto`:23 (inference.GRPCInferenceService/ServerLive)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `python/kserve/kserve/protocol/grpc/grpc_predict_v2.proto`:26 (inference.GRPCInferenceService/ServerReady)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `python/kserve/kserve/protocol/grpc/grpc_predict_v2.proto`:29 (inference.GRPCInferenceService/ModelReady)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `python/kserve/kserve/protocol/grpc/grpc_predict_v2.proto`:34 (inference.GRPCInferenceService/ServerMetadata)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `python/kserve/kserve/protocol/grpc/grpc_predict_v2.proto`:39 (inference.GRPCInferenceService/ModelMetadata)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `python/kserve/kserve/protocol/grpc/grpc_predict_v2.proto`:44 (inference.GRPCInferenceService/ModelInfer)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `python/kserve/kserve/protocol/grpc/grpc_predict_v2.proto`:47 (inference.GRPCInferenceService/RepositoryModelLoad)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `python/kserve/kserve/protocol/grpc/grpc_predict_v2.proto`:50 (inference.GRPCInferenceService/RepositoryModelUnload)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/llmisvc/main.go`:353 (/healthz, GET, cmd/llmisvc)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/llmisvc/main.go`:357 (/readyz, GET, cmd/llmisvc)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/localmodel/main.go`:208 (/healthz, GET, cmd/localmodel)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/localmodel/main.go`:212 (/readyz, GET, cmd/localmodel)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/manager/main.go`:305 (/healthz, GET, cmd/manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/manager/main.go`:311 (/readyz, GET, cmd/manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/router/main.go`:675 (/, Unknown, cmd/router)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `docs/samples/graph/bgtest/bgtest/main.go`:28 (/single, POST, main)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `docs/samples/graph/bgtest/bgtest/main.go`:29 (/ensemble, POST, main)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `kserve-module/cmd/kserve-module/main.go`:91 (/healthz, GET, cmd/kserve-module)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `kserve-module/cmd/kserve-module/main.go`:95 (/readyz, GET, cmd/kserve-module)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `qpext/cmd/qpext/main.go`:323 (/metrics, Unknown, cmd/qpext)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/auth_proxy_service.yaml`:1 (Inbound scrape, Prometheus)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/llmisvc/role.yaml`:2 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/localmodel/role.yaml`:2 (API client, Kubernetes API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, ServingRuntime CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (CRD Watch, KServe InferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (Gateway API, HTTPRoute CRUD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `kserve-module/config/rbac/role.yaml`:2 (CRD CRUD, HardwareProfile CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `kserve-module/config/rbac/role.yaml`:2 (CRD CRUD, NIM Account CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `kserve-module/config/rbac/role.yaml`:2 (Certificate CR, cert-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `pkg/agent/storage/utils.go`:142 (Azure Blob Storage, File storage client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `pkg/agent/storage/utils.go`:196 (File storage client, Google Cloud Storage)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `pkg/agent/storage/utils.go`:245 (File storage client, S3-compatible storage)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/auth_proxy_service.yaml`:1 (Prometheus, monitoring)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/llmisvc/role.yaml`:2 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/localmodel/role.yaml`:2 (CRUD, Kubernetes API (persistent volumes))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/localmodel/role.yaml`:2 (Kubernetes API (nodes), list)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, Gateway API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRD Watch, KServe InferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `kserve-module/config/rbac/role.yaml`:2 (CRD CRUD, HardwareProfile CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `kserve-module/config/rbac/role.yaml`:2 (CRD CRUD, cert-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/controller/v1alpha2/llmisvc/controller.go`:455 (Controller watch (conditional), Gateway API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/controller/v1alpha2/llmisvc/controller.go`:478 (Controller watch (conditional), prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/controller/v1alpha2/llmisvc/controller_setup_odh.go`:167 (Gateway API, HTTPRoute CRUD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/tls/distro/resolve.go`:116 (APIServer resource read, OpenShift Cluster Configuration)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `kserve-module/pkg/kservemodule/setup.go`:136-142 (/v1/ConfigMap, pkg/kservemodule.KserveModuleReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `kserve-module/pkg/kservemodule/setup.go`:145-150 (/v1/Node, pkg/kservemodule.KserveModuleReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `pkg/controller/v1alpha1/localmodel/reconcilers/localmodelcache_reconciler.go`:364-364 (pkg/controller/v1alpha1/localmodel/reconcilers.LocalModelReconciler, serving.kserve.io/v1beta1/InferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `pkg/controller/v1alpha1/localmodel/reconcilers/localmodelcache_reconciler.go`:366-366 (pkg/controller/v1alpha1/localmodel/reconcilers.LocalModelReconciler, serving.kserve.io/v1alpha2/LLMInferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `pkg/controller/v1alpha1/localmodel/reconcilers/localmodelcache_reconciler.go`:371-371 (/v1/Node, pkg/controller/v1alpha1/localmodel/reconcilers.LocalModelReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `pkg/controller/v1alpha1/localmodel/reconcilers/localmodelcache_reconciler.go`:373-373 (pkg/controller/v1alpha1/localmodel/reconcilers.LocalModelReconciler, serving.kserve.io/v1alpha1/LocalModelNode)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `pkg/controller/v1alpha1/localmodel/reconcilers/localmodelnamespacecache_reconciler.go`:456-456 (pkg/controller/v1alpha1/localmodel/reconcilers.LocalModelNamespaceCacheReconciler, serving.kserve.io/v1beta1/InferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `pkg/controller/v1alpha1/localmodel/reconcilers/localmodelnamespacecache_reconciler.go`:458-458 (pkg/controller/v1alpha1/localmodel/reconcilers.LocalModelNamespaceCacheReconciler, serving.kserve.io/v1alpha2/LLMInferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `pkg/controller/v1alpha1/localmodel/reconcilers/localmodelnamespacecache_reconciler.go`:463-463 (pkg/controller/v1alpha1/localmodel/reconcilers.LocalModelNamespaceCacheReconciler, serving.kserve.io/v1alpha1/LocalModelNamespaceCache)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `pkg/controller/v1alpha1/localmodel/reconcilers/localmodelnamespacecache_reconciler.go`:464-464 (/v1/Node, pkg/controller/v1alpha1/localmodel/reconcilers.LocalModelNamespaceCacheReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `pkg/controller/v1alpha1/localmodel/reconcilers/localmodelnamespacecache_reconciler.go`:465-465 (pkg/controller/v1alpha1/localmodel/reconcilers.LocalModelNamespaceCacheReconciler, serving.kserve.io/v1alpha1/LocalModelNode)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `pkg/controller/v1alpha2/llmisvc/controller.go`:434-434 (/v1/ConfigMap, pkg/controller/v1alpha2/llmisvc.LLMISVCReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- 9 additional gap candidates remain in the analyzer JSON.
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `config/default/manager_resources_patch.yaml`:1 (kserve-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `config/manager/service.yaml`:1 (kserve-controller-manager, kserve-controller-manager-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `config/rbac/auth_proxy_service.yaml`:1 (kserve-controller-manager, kserve-controller-manager-metrics-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `config/webhook/service.yaml`:1 (kserve-controller-manager, kserve-webhook-server-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `python/huggingfaceserver/test_health_check.py`:27 (aifserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### webhooks

- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/default/clusterservingruntime_validatingwebhook_cainjection_patch.yaml`:1 (/validate-serving-kserve-io-v1alpha1-clusterservingruntime, clusterservingruntime.kserve-webhook-server.validator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/default/inferencegraph_validatingwebhook_cainjection_patch.yaml`:1 (/validate-serving-kserve-io-v1alpha1-inferencegraph, inferencegraph.kserve-webhook-server.validator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/default/isvc_mutatingwebhook_cainjection_patch.yaml`:1 (/mutate-pods, inferenceservice.kserve-webhook-server.pod-mutator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/default/isvc_mutatingwebhook_cainjection_patch.yaml`:1 (/mutate-serving-kserve-io-v1beta1-inferenceservice, inferenceservice.kserve-webhook-server.defaulter)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/default/isvc_validatingwebhook_cainjection_patch.yaml`:1 (/validate-serving-kserve-io-v1beta1-inferenceservice, inferenceservice.kserve-webhook-server.validator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/default/trainedmodel_validatingwebhook_cainjection_patch.yaml`:1 (/validate-serving-kserve-io-v1alpha1-trainedmodel, trainedmodel.kserve-webhook-server.validator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/apis/serving/v1alpha1/inference_graph_validation.go`:68 (/validate-serving-kserve-io-v1alpha1-inferencegraph, inferencegraph.kserve-webhook-server.validator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/apis/serving/v1alpha1/trainedmodel_webhook.go`:60 (/validate-serving-kserve-io-v1alpha1-trainedmodel, trainedmodel.kserve-webhook-server.validator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/apis/serving/v1beta1/inference_service_defaults.go`:55 (/mutate-serving-kserve-io-v1beta1-inferenceservice, inferenceservice.kserve-webhook-server.defaulter)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/apis/serving/v1beta1/inference_service_validation.go`:67 (/validate-serving-kserve-io-v1beta1-inferenceservice, inferenceservice.kserve-webhook-server.validator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/webhook/admission/pod/mutator.go`:36 (/mutate-pods, inferenceservice.kserve-webhook-server.pod-mutator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/webhook/admission/servingruntime/servingruntime_webhook.go`:57 (/validate-serving-kserve-io-v1alpha1-clusterservingruntime, clusterservingruntime.kserve-webhook-server.validator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- /healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: cmd/llmisvc/main.go:353]
- /readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/llmisvc/main.go:357]
- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: kserve-module/cmd/kserve-module/main.go:91]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: kserve-module/cmd/kserve-module/main.go:95]
- HTTP API methods=All mechanism=None (no auth middleware detected) enforcement=FastAPI/Starlette application policy=No authentication middleware registered [source: python/huggingfaceserver/test_health_check.py:27]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=In-cluster configuration provides automatic ServiceAccount token authentication [source: cmd/router/main.go:614]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via kserve-manager-role ClusterRole; SA kserve-controller-manager [source: cmd/llmisvc/main.go:264]
- Named Secret access (kserve-webhook-server-secret, workload-variant-autoscaler-controller-manager-token, workload-variant-autoscaler-epp-metrics-token, workload-variant-autoscaler-metrics-reader-token) methods=Kubernetes API mechanism=RBAC with resourceNames restriction enforcement=kube-apiserver policy=kserve-module-manager-role restricts secret access to kserve-webhook-server-secret, workload-variant-autoscaler-controller-manager-token, workload-variant-autoscaler-epp-metrics-token, workloa... [source: kserve-module/config/rbac/role.yaml:2]
- Operator webhook methods=CREATE mechanism=Kubernetes admission enforcement=ValidatingWebhookConfiguration policy=Admission validation [source: config/default/isvc_validatingwebhook_cainjection_patch.yaml:1]
- Token validation methods=Kubernetes TokenReview API mechanism=Kubernetes TokenReview API enforcement=Application-level token validation via kube-apiserver policy=Validates bearer tokens against Kubernetes TokenReview API [source: cmd/router/main.go:525]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/kserve-module [source: kserve-module/cmd/kserve-module/main.go:91]
- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/llmisvc [source: cmd/llmisvc/main.go:353]
- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/localmodel [source: cmd/localmodel/main.go:208]
- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/manager [source: cmd/manager/main.go:305]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/kserve-module [source: kserve-module/cmd/kserve-module/main.go:95]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/llmisvc [source: cmd/llmisvc/main.go:357]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/localmodel [source: cmd/localmodel/main.go:212]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/manager [source: cmd/manager/main.go:311]
- PATCH health_check.ray.init on port ; transport= encryption=Configurable auth=Unknown owner= [source: python/huggingfaceserver/test_health_check.py:27]
- PATCH health_check.ray.is_initialized on port ; transport= encryption=Configurable auth=Unknown owner= [source: python/huggingfaceserver/test_health_check.py:26]
- PATCH health_check.ray.nodes on port ; transport= encryption=Configurable auth=Unknown owner= [source: python/huggingfaceserver/test_health_check.py:36]
- PATCH health_check.requests.get on port ; transport= encryption=Configurable auth=Unknown owner= [source: python/huggingfaceserver/test_health_check.py:114]
- POST /ensemble on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: docs/samples/graph/bgtest/bgtest/main.go:29]
- POST /single on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: docs/samples/graph/bgtest/bgtest/main.go:28]
- POST /splitter on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: docs/samples/graph/bgtest/bgtest/main.go:26]
- POST /switch on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: docs/samples/graph/bgtest/bgtest/main.go:27]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/router [source: cmd/router/main.go:675]
- Unknown /metrics on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/qpext [source: qpext/cmd/qpext/main.go:323]
### integrations

- Azure Blob Storage interaction=File storage client role=runtime-integration protocol=HTTP/HTTPS purpose=Runtime object storage [source: pkg/agent/storage/utils.go:142]
- Gateway API interaction=HTTPRoute CRUD role=runtime-transport protocol=HTTPS purpose=Manage Gateway API routing resources [source: config/rbac/role.yaml:2]
- Google Cloud Storage interaction=File storage client role=runtime-integration protocol=HTTP/HTTPS purpose=Runtime object storage [source: pkg/agent/storage/utils.go:196]
- HardwareProfile CR interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage hardware profile resources [source: kserve-module/config/rbac/role.yaml:2]
- KServe InferenceService interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read model serving state [source: config/rbac/role.yaml:2]
- Kubernetes API interaction=API client role=runtime-integration protocol=HTTPS purpose=Cluster resource management via RBAC [source: config/rbac/localmodel/role.yaml:2]
- NIM Account CR interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage NVIDIA NIM account configuration [source: kserve-module/config/rbac/role.yaml:2]
- OLM (operators.coreos.com) interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Operator subscription status [source: kserve-module/config/rbac/role.yaml:2]
- OpenShift Routes interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Dashboard route status [source: config/rbac/role.yaml:2]
- Prometheus interaction=Inbound scrape role=unknown protocol=HTTP purpose=Metrics collection via prometheus.io/scrape annotation [source: config/rbac/auth_proxy_service.yaml:1]
- S3-compatible storage interaction=File storage client role=runtime-integration protocol=HTTP/HTTPS purpose=Runtime object storage [source: pkg/agent/storage/utils.go:245]
- ServingRuntime CR interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage serving runtime templates [source: config/rbac/role.yaml:2]
- cert-manager interaction=Certificate CR role=unknown protocol=HTTPS purpose=Manage TLS certificates through cert-manager CRDs [source: kserve-module/config/rbac/role.yaml:2]
- kube-rbac-proxy interaction=Sidecar (localhost) role=unknown protocol=HTTPS to HTTP purpose=Authentication enforcement [source: config/default/manager_resources_patch.yaml:1]
- prometheus-operator interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage Prometheus monitoring resources [source: config/rbac/llmisvc/role.yaml:2]
### internal_dependencies

- Gateway API interaction=CRD CRUD role=unknown purpose=Manage Gateway API routing resources [source: config/rbac/role.yaml:2]
- Gateway API interaction=Controller watch (conditional) role=runtime-integration purpose=Manage Gateway API routing resources [source: pkg/controller/v1alpha2/llmisvc/controller.go:455]
- Gateway API interaction=HTTPRoute CRUD role=runtime-transport purpose=Reconcile HTTPRoute resources against a configured Gateway [source: pkg/controller/v1alpha2/llmisvc/controller_setup_odh.go:167]
- HardwareProfile CR interaction=CRD CRUD role=unknown purpose=Manage hardware profile resources [source: kserve-module/config/rbac/role.yaml:2]
- KServe InferenceService interaction=CRD Watch role=runtime-integration purpose=Read model serving state [source: config/rbac/role.yaml:2]
- Kubernetes API (nodes) interaction=list role=unknown purpose=nodes resource access via RBAC [source: config/rbac/localmodel/role.yaml:2]
- Kubernetes API (persistent volumes) interaction=CRUD role=unknown purpose=persistentvolumes resource access via RBAC [source: config/rbac/localmodel/role.yaml:2]
- OpenShift Cluster Configuration interaction=APIServer resource read role=runtime-integration purpose=Read cluster-wide API server configuration [source: pkg/tls/distro/resolve.go:116]
- Prometheus interaction=monitoring role=unknown purpose=Metrics scraping via service annotations [source: config/rbac/auth_proxy_service.yaml:1]
- cert-manager interaction=CRD CRUD role=unknown purpose=Manage TLS certificates through cert-manager CRDs [source: kserve-module/config/rbac/role.yaml:2]
- gateway-api-inference-extension interaction=Go library role=runtime-library purpose=Use runtime packages from sigs.k8s.io/gateway-api-inference-extension [source: pkg/apis/gie/v1alpha2pool/inferencepool_conversion.go:29]
- kube-rbac-proxy (odh-kube-auth-proxy) interaction=Sidecar Container role=unknown purpose=TLS termination and authentication enforcement [source: config/default/manager_resources_patch.yaml:1]
- odh-platform-utilities interaction=Go Library role=runtime-library purpose=Platform detection, manifest rendering, and deployment helpers [source: kserve-module/go.mod]
- odh-platform-utilities interaction=Go library role=runtime-library purpose=Use runtime packages from github.com/opendatahub-io/odh-platform-utilities [source: kserve-module/pkg/apis/v1alpha1/types.go:9]
- prometheus-operator interaction=CRD CRUD role=unknown purpose=Manage Prometheus monitoring resources [source: config/rbac/llmisvc/role.yaml:2]
- prometheus-operator interaction=Controller watch (conditional) role=runtime-integration purpose=Manage Prometheus monitoring resources [source: pkg/controller/v1alpha2/llmisvc/controller.go:478]
### services

- kserve-controller-manager-metrics-service port=8443 target=https protocol=TCP encryption= auth= [source: config/rbac/auth_proxy_service.yaml:1]
- kserve-controller-manager-service port=8443 target=https protocol=TCP encryption= auth= [source: config/manager/service.yaml:1]
- kserve-webhook-server-service port=443 target=webhook-server protocol=TCP encryption= auth= [source: config/webhook/service.yaml:1]
### serving_runtime_definitions

- ClusterServingRuntime csr-kserve-mlserver formats=lightgbm:3, lightgbm:4, onnx:1, sklearn:0, sklearn:1, xgboost:1, xgboost:2 images=kserve-container=$(mlserver-image) builtInAdapter= [source: kserve-module/prefetched-manifests-rhoai/modelcontroller/runtimes/csr-kserve-mlserver.yaml:1]
- ClusterServingRuntime csr-kserve-mlserver-cuda formats=onnx:1 images=kserve-container=$(mlserver-cuda-image) builtInAdapter= [source: kserve-module/prefetched-manifests-rhoai/modelcontroller/runtimes/csr-kserve-mlserver-cuda.yaml:1]
- ClusterServingRuntime csr-kserve-ovms formats=onnx:1, openvino_ir:opset13 (autoSelect), paddle:2 (autoSelect), pytorch:2 (autoSelect), tensorflow:1 (autoSelect), tensorflow:2 (autoSelect) images=kserve-container=$(ovms-image) builtInAdapter= [source: kserve-module/prefetched-manifests-rhoai/modelcontroller/runtimes/csr-kserve-ovms.yaml:1]
- ClusterServingRuntime csr-kserve-vllm-cpu formats=vLLM (autoSelect) images=kserve-container=$(vllm-cpu-image) builtInAdapter= [source: kserve-module/prefetched-manifests-rhoai/modelcontroller/runtimes/vllm/csr-kserve-vllm-cpu.yaml:1]
- ClusterServingRuntime csr-kserve-vllm-cpu-x86 formats=vLLM (autoSelect) images=kserve-container=$(vllm-cpu-x86-image) builtInAdapter= [source: kserve-module/prefetched-manifests-rhoai/modelcontroller/runtimes/vllm/csr-kserve-vllm-cpu-x86.yaml:1]
- ClusterServingRuntime csr-kserve-vllm-cuda formats=vLLM (autoSelect) images=kserve-container=$(vllm-cuda-image) builtInAdapter= [source: kserve-module/prefetched-manifests-rhoai/modelcontroller/runtimes/vllm/csr-kserve-vllm-cuda.yaml:1]
- ClusterServingRuntime csr-kserve-vllm-gaudi formats=vLLM images=kserve-container=$(vllm-gaudi-image) builtInAdapter= [source: kserve-module/prefetched-manifests-rhoai/modelcontroller/runtimes/vllm/csr-kserve-vllm-gaudi.yaml:1]
- ClusterServingRuntime csr-kserve-vllm-rocm formats=vLLM (autoSelect) images=kserve-container=$(vllm-rocm-image) builtInAdapter= [source: kserve-module/prefetched-manifests-rhoai/modelcontroller/runtimes/vllm/csr-kserve-vllm-rocm.yaml:1]
- ClusterServingRuntime csr-kserve-vllm-spyre-ppc64le formats=vLLM (autoSelect) images=kserve-container=$(vllm-spyre-image) builtInAdapter= [source: kserve-module/prefetched-manifests-rhoai/modelcontroller/runtimes/vllm/csr-kserve-vllm-spyre-ppc64le.yaml:1]
- ClusterServingRuntime csr-kserve-vllm-spyre-s390x formats=vLLM (autoSelect) images=kserve-container=$(vllm-spyre-image) builtInAdapter= [source: kserve-module/prefetched-manifests-rhoai/modelcontroller/runtimes/vllm/csr-kserve-vllm-spyre-s390x.yaml:1]
- ClusterServingRuntime csr-kserve-vllm-spyre-x86 formats=vLLM (autoSelect) images=kserve-container=$(vllm-spyre-image) builtInAdapter= [source: kserve-module/prefetched-manifests-rhoai/modelcontroller/runtimes/vllm/csr-kserve-vllm-spyre-x86.yaml:1]
- ClusterServingRuntime kserve-autogluonserver formats=autogluon:1 (autoSelect) images=kserve-container=kserve-autogluonserver:replace builtInAdapter= [source: config/runtimes/kserve-autogluonserver.yaml:1]
- ClusterServingRuntime kserve-huggingfaceserver formats=huggingface:1 (autoSelect) images=kserve-container=huggingfaceserver:replace builtInAdapter= [source: config/runtimes/kserve-huggingfaceserver.yaml:1]
- ClusterServingRuntime kserve-huggingfaceserver-multinode formats=huggingface:1 (autoSelect) images=kserve-container=huggingfaceserver-gpu:replace builtInAdapter= [source: config/runtimes/kserve-huggingfaceserver-multinode.yaml:1]
- ClusterServingRuntime kserve-lgbserver formats=lightgbm:4 (autoSelect) images=kserve-container=kserve-lgbserver:replace builtInAdapter= [source: config/runtimes/kserve-lgbserver.yaml:1]
- ClusterServingRuntime kserve-llm-sglang formats=sglang:1 images=main=lmsysorg/sglang:v0.5.14 builtInAdapter= [source: config/runtimes/kserve-llm-sglang.yaml:1]
- ClusterServingRuntime kserve-mlserver formats=lightgbm:3 (autoSelect), lightgbm:4 (autoSelect), mlflow:1 (autoSelect), mlflow:2 (autoSelect), sklearn:0 (autoSelect), sklearn:1 (autoSelect), xgboost:1 (autoSelect), xgboost:2 (autoSelect) images=kserve-container=mlserver:replace builtInAdapter= [source: config/runtimes/kserve-mlserver.yaml:1]
- ClusterServingRuntime kserve-paddleserver formats=paddle:2 (autoSelect) images=kserve-container=kserve-paddleserver:replace builtInAdapter= [source: config/runtimes/kserve-paddleserver.yaml:1]
- ClusterServingRuntime kserve-pmmlserver formats=pmml:3 (autoSelect), pmml:4 (autoSelect) images=kserve-container=kserve-pmmlserver:replace builtInAdapter= [source: config/runtimes/kserve-pmmlserver.yaml:1]
- ClusterServingRuntime kserve-predictiveserver formats=lightgbm:4, sklearn:1, xgboost:2 images=kserve-container=kserve-predictiveserver:replace builtInAdapter= [source: config/runtimes/kserve-predictiveserver.yaml:1]
- ClusterServingRuntime kserve-sklearnserver formats=sklearn:1 (autoSelect) images=kserve-container=kserve-sklearnserver:replace builtInAdapter= [source: config/runtimes/kserve-sklearnserver.yaml:1]
- ClusterServingRuntime kserve-tensorflow-serving formats=tensorflow:1 (autoSelect), tensorflow:2 (autoSelect) images=kserve-container=tensorflow-serving:replace builtInAdapter= [source: config/runtimes/kserve-tensorflow-serving.yaml:1]
- ClusterServingRuntime kserve-torchserve formats=pytorch:1 (autoSelect) images=kserve-container=kserve-torchserve:replace builtInAdapter= [source: config/runtimes/kserve-torchserve.yaml:1]
- ClusterServingRuntime kserve-tritonserver formats=onnx:1 (autoSelect), pytorch:1, tensorflow:1 (autoSelect), tensorflow:2 (autoSelect), tensorrt:8 (autoSelect), triton:2 (autoSelect) images=kserve-container=kserve-tritonserver:replace builtInAdapter= [source: config/runtimes/kserve-tritonserver.yaml:1]
- ClusterServingRuntime kserve-vllmserver formats=vLLM:1 (autoSelect) images=kserve-container=vllmserver:replace builtInAdapter= [source: config/runtimes/kserve-vllmserver.yaml:1]
- ClusterServingRuntime kserve-xgbserver formats=xgboost:2 (autoSelect) images=kserve-container=kserve-xgbserver:replace builtInAdapter= [source: config/runtimes/kserve-xgbserver.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload kserve-controller-manager uses service account kserve-controller-manager and 2 container(s) [source: config/default/manager_resources_patch.yaml:1]
- **observed**: Service aifserver targets  with 0 port(s) [source: python/huggingfaceserver/test_health_check.py:27]
- **observed**: Service kserve-controller-manager-metrics-service targets kserve-controller-manager with 1 port(s) [source: config/rbac/auth_proxy_service.yaml:1]
- **observed**: Service kserve-controller-manager-service targets kserve-controller-manager with 1 port(s) [source: config/manager/service.yaml:1]
- **observed**: Service kserve-webhook-server-service targets kserve-controller-manager with 1 port(s) [source: config/webhook/service.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by cmd/kserve-module [source: kserve-module/cmd/kserve-module/main.go:91]
- **observed**: HTTP GET /healthz is owned by cmd/llmisvc [source: cmd/llmisvc/main.go:353]
- **observed**: HTTP GET /healthz is owned by cmd/localmodel [source: cmd/localmodel/main.go:208]
- **observed**: HTTP GET /healthz is owned by cmd/manager [source: cmd/manager/main.go:305]
- **observed**: HTTP GET /readyz is owned by cmd/kserve-module [source: kserve-module/cmd/kserve-module/main.go:95]
- **observed**: HTTP GET /readyz is owned by cmd/llmisvc [source: cmd/llmisvc/main.go:357]
- **observed**: HTTP GET /readyz is owned by cmd/localmodel [source: cmd/localmodel/main.go:212]
- **observed**: HTTP GET /readyz is owned by cmd/manager [source: cmd/manager/main.go:311]
- **observed**: HTTP POST /ensemble is owned by main [source: docs/samples/graph/bgtest/bgtest/main.go:29]
- **observed**: HTTP POST /single is owned by main [source: docs/samples/graph/bgtest/bgtest/main.go:28]
- **observed**: HTTP POST /splitter is owned by main [source: docs/samples/graph/bgtest/bgtest/main.go:26]
- **observed**: HTTP POST /switch is owned by main [source: docs/samples/graph/bgtest/bgtest/main.go:27]
- **observed**: HTTP Unknown / is owned by cmd/router [source: cmd/router/main.go:675]
- **observed**: HTTP Unknown /metrics is owned by cmd/qpext [source: qpext/cmd/qpext/main.go:323]
### security

- **observed**: All HTTP API uses None (no auth middleware detected) at FastAPI/Starlette application; policy=No authentication middleware registered [source: python/huggingfaceserver/test_health_check.py:27]
- **observed**: CREATE Operator webhook uses Kubernetes admission at ValidatingWebhookConfiguration; policy=Admission validation [source: config/default/isvc_validatingwebhook_cainjection_patch.yaml:1]
- **observed**: GET /healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: cmd/llmisvc/main.go:353]
- **observed**: GET /readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/llmisvc/main.go:357]
- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: kserve-module/cmd/kserve-module/main.go:91]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: kserve-module/cmd/kserve-module/main.go:95]
- **observed**: Kubernetes API Named Secret access (kserve-webhook-server-secret, workload-variant-autoscaler-controller-manager-token, workload-variant-autoscaler-epp-metrics-token, workload-variant-autoscaler-metrics-reader-token) uses RBAC with resourceNames restriction at kube-apiserver; policy=kserve-module-manager-role restricts secret access to kserve-webhook-server-secret, workload-variant-autoscaler-controller-manager-token, workload-variant-autoscaler-epp-metrics-token, workload-variant-autoscaler-metrics-reader-token only [source: kserve-module/config/rbac/role.yaml:2]
- **observed**: Kubernetes TokenReview API Token validation uses Kubernetes TokenReview API at Application-level token validation via kube-apiserver; policy=Validates bearer tokens against Kubernetes TokenReview API [source: cmd/router/main.go:525]
- **observed**: RBAC role kserve-leader-election-role grants 4 rule(s) [source: config/rbac/leader_election_role.yaml:2]
- **observed**: RBAC role kserve-llmisvc-manager-role grants 28 rule(s) [source: config/rbac/llmisvc/role.yaml:2]
- **observed**: RBAC role kserve-localmodel-manager-role grants 10 rule(s) [source: config/rbac/localmodel/role.yaml:2]
- **observed**: RBAC role kserve-localmodelnode-agent-role grants 9 rule(s) [source: config/rbac/localmodelnode/role.yaml:2]
- **observed**: RBAC role kserve-manager-role grants 23 rule(s) [source: config/rbac/role.yaml:2]
- **observed**: RBAC role kserve-module-leader-election-role grants 2 rule(s) [source: kserve-module/config/rbac/leader_election_role.yaml:1]
- **observed**: RBAC role kserve-module-manager-role grants 34 rule(s) [source: kserve-module/config/rbac/role.yaml:2]
- **observed**: RBAC role kserve-proxy-role grants 2 rule(s) [source: config/rbac/auth_proxy_role.yaml:1]
- **observed**: RBAC role llmisvc-leader-election-role grants 1 rule(s) [source: config/rbac/llmisvc/leader_election_role.yaml:2]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=In-cluster configuration provides automatic ServiceAccount token authentication [source: cmd/router/main.go:614]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via kserve-manager-role ClusterRole; SA kserve-controller-manager [source: cmd/llmisvc/main.go:264]
- **dependency-signal**: auth-middleware targets pyjwt: JWT/OAuth authentication library dependency [source: python/kserve/pyproject.toml:41]
- **literal**: rbac-ref targets SubjectAccessReviews: Token or subject access review call [source: cmd/router/main.go:583]
- **literal**: rbac-ref targets TokenReviews: Token or subject access review call [source: cmd/router/main.go:529]
- **dependency-signal**: rbac-ref targets kubernetes: Kubernetes client library (RBAC capable) [source: python/kserve/pyproject.toml:16]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: cmd/llmisvc/main.go, cmd/llmisvc/main_start_default.go, cmd/llmisvc/main_start_odh.go, cmd/localmodel/main_start_default.go, cmd/localmodel/main_start_odh.go, cmd/localmodelnode/main_start_default.go, cmd/localmodelnode/main_start_odh.go, cmd/manager/main_start_default.go, cmd/manager/main_start_odh.go, kernelcache/mcv/pkg/registryauth/registryauth.go, pkg/logger/worker.go, pkg/tls/distro/resolve.go, pkg/tls/distro/result.go, pkg/tls/resolve.go, pkg/tls/tls.go]
- **dependency-signal**: tls-config targets cryptography: TLS/cryptography library dependency [source: python/kserve/pyproject.toml:39]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
