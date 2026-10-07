# Analyzer Synthesis Context: modelmesh-serving

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 4 crds facts extracted [source: config/crd/bases/serving.kserve.io_clusterservingruntimes.yaml:3, config/crd/bases/serving.kserve.io_inferenceservices.yaml:2, config/crd/bases/serving.kserve.io_predictors.yaml:2, config/crd/bases/serving.kserve.io_servingruntimes.yaml:2]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 3 http_endpoints facts extracted [source: main.go:339, main.go:521, main.go:527]
- **services (observed)**: 1 services facts extracted [source: config/webhook/service.yaml:14]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (observed)**: 3 webhooks facts extracted [source: apis/serving/v1alpha1/servingruntime_webhook.go:32, config/crd/patches/webhook_in_predictors.yaml:17, config/crd/patches/webhook_in_servingruntimes.yaml:17, config/default/webhookcainjection_patch.yaml:16, config/webhook/manifests.yaml:14]

## Deterministic Cross-References

- **controller**: PredictorReconciler —watches-reference→ serving/v1alpha1/Predictor; serving/v1alpha1/Predictor [source: controllers/predictor_controller.go:594, pkg/predictor_source/predictor_registry.go:35]
- **controller**: ServiceReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: controllers/modelmesh/cluster_config.go:68, controllers/service_controller.go:454]
- **controller**: ServiceReconciler —watches-reference→ /v1/Namespace; /v1/Namespace [source: controllers/service_controller.go:120, controllers/service_controller.go:476]
- **controller**: ServiceReconciler —watches-reference→ /v1/Service; /v1/Service [source: controllers/service_controller.go:133, controllers/service_controller.go:433]
- **controller**: ServiceReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: controllers/service_controller.go:161, controllers/service_controller.go:449]
- **controller**: ServingRuntimeReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: controllers/modelmesh/cluster_config.go:68, controllers/servingruntime_controller.go:610]
- **controller**: ServingRuntimeReconciler —watches-reference→ /v1/Namespace; /v1/Namespace [source: controllers/service_controller.go:120, controllers/servingruntime_controller.go:626]
- **controller**: ServingRuntimeReconciler —watches-reference→ /v1/Secret; /v1/Secret [source: controllers/modelmesh/tls.go:48, controllers/servingruntime_controller.go:650]
- **controller**: ServingRuntimeReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: controllers/service_controller.go:161, controllers/servingruntime_controller.go:608]
- **controller**: ServingRuntimeReconciler —watches-reference→ serving/v1alpha1/Predictor; serving/v1alpha1/Predictor [source: controllers/servingruntime_controller.go:619, pkg/predictor_source/predictor_registry.go:35]
- **webhook**: servingruntime.modelmesh-webhook-server.default —served-by→ modelmesh-webhook-server-service; admission webhook declares an explicit service reference [source: apis/serving/v1alpha1/servingruntime_webhook.go:32, config/default/webhookcainjection_patch.yaml:16, config/webhook/service.yaml:14]

## Behavioral Evidence

No bounded behavioral evidence was extracted.

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `config/default/webhookcainjection_patch.yaml`:16 (Kubernetes admission, Operator webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `main.go`:268 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `main.go`:521 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `main.go`:527 (:8081/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/cluster-scope/role.yaml`:15 (modelmesh-controller-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/common/auth_proxy_client_clusterrole.yaml`:14 (metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/common/auth_proxy_role.yaml`:14 (proxy-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/common/inferenceservice_editor_role.yaml`:15 (inferenceservice-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/common/inferenceservice_viewer_role.yaml`:15 (inferenceservice-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/common/leader_election_role.yaml`:15 (modelmesh-controller-leader-election-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/common/predictor_editor_role.yaml`:15 (predictor-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/common/predictor_viewer_role.yaml`:15 (predictor-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/common/restricted_scc_role.yaml`:14 (modelmesh-controller-restricted-scc-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/common/servingruntime_editor_role.yaml`:15 (servingruntime-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/common/servingruntime_viewer_role.yaml`:15 (servingruntime-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/namespace-scope/role.yaml`:15 (modelmesh-controller-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:74 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.develop`:135 (Dockerfile.develop:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.develop.ci`:129 (Dockerfile.develop.ci:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:59 (Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `docs/examples/python-custom-runtime/custom-model/Dockerfile`:35 (docs/examples/python-custom-runtime/custom-model/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `main.go`:110 (modelmesh-serving)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `tests/Dockerfile`:63 (tests/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `fvt/fvtclient.go`:182 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `main.go`:268 (Kubernetes API, controller-runtime manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `main.go`:339 (/debug/, Unknown, main)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `main.go`:521 (/healthz, GET, main)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `main.go`:527 (/readyz, GET, main)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/cluster-scope/role.yaml`:15 (CRD CRUD, ServingRuntime CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/cluster-scope/role.yaml`:15 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/cluster-scope/role.yaml`:15 (CRD Watch, KServe InferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/cluster-scope/role.yaml`:15 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/cluster-scope/role.yaml`:15 (CRD Watch, KServe InferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `controllers/hpa/hpa_reconciler.go`:148 (autoscaling/v2/HorizontalPodAutoscaler, get operations by HPAReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `controllers/modelmesh/cluster_config.go`:68 (/v1/ConfigMap, create, delete, get, update operations by ClusterConfig, ConfigProvider, Deployment)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `controllers/modelmesh/tls.go`:48 (/v1/Secret, create, delete, get, update operations by Deployment, EtcdSecret, ModelMeshEventStream, ServiceReconciler, ServingRuntimeReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `controllers/service_controller.go`:120 (/v1/Namespace, get, list operations by ServiceReconciler, ServingRuntimeReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `controllers/service_controller.go`:133 (/v1/Service, create, delete, list, update operations by ServiceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `controllers/service_controller.go`:161 (apps/v1/Deployment, get operations by ServiceReconciler, ServingRuntimeReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `controllers/service_controller.go`:465 (Controller watch (conditional), prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `controllers/servingruntime_controller.go`:416 (/v1/PersistentVolumeClaim, get operations by ServingRuntimeReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/mmesh/grpc_resolver.go`:160 (/v1/Endpoints, get operations by KubeResolver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/predictor_source/predictor_registry.go`:35 (get, list, update operations by PredictorCRRegistry, serving/v1alpha1/Predictor)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/service_controller.go`:433 (/v1/Service, ServiceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/service_controller.go`:449 (ServiceReconciler, apps/v1/Deployment)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/service_controller.go`:454 (/v1/ConfigMap, ServiceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/service_controller.go`:465 (ServiceReconciler, monitoring.coreos.com/v1/ServiceMonitor)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/service_controller.go`:476 (/v1/Namespace, ServiceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/service_controller.go`:477 (/v1/ConfigMap, ServiceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/service_controller.go`:499 (ServiceReconciler, monitoring.coreos.com/v1/ServiceMonitor)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/servingruntime_controller.go`:608 (ServingRuntimeReconciler, apps/v1/Deployment)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/servingruntime_controller.go`:610 (/v1/ConfigMap, ServingRuntimeReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/servingruntime_controller.go`:626 (/v1/Namespace, ServingRuntimeReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/servingruntime_controller.go`:650 (/v1/Secret, ServingRuntimeReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/mmesh/grpc_resolver.go`:72 (/v1/Endpoints)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `config/default/manager_webhook_patch.yaml`:14 (modelmesh-controller)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `config/webhook/service.yaml`:14 (modelmesh-controller, modelmesh-webhook-server-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### webhooks

- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `apis/serving/v1alpha1/servingruntime_webhook.go`:32 (/validate-serving-modelmesh-io-v1alpha1-servingruntime, servingruntime.modelmesh-webhook-server.default)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/crd/patches/webhook_in_predictors.yaml`:17 (/convert, predictors.serving.kserve.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/crd/patches/webhook_in_servingruntimes.yaml`:17 (/convert, predictors.serving.kserve.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/default/webhookcainjection_patch.yaml`:16 (/validate-serving-modelmesh-io-v1alpha1-servingruntime, servingruntime.modelmesh-webhook-server.default)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/webhook/manifests.yaml`:14 (/validate-serving-modelmesh-io-v1alpha1-servingruntime, servingruntime.modelmesh-webhook-server.default)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: main.go:521]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: main.go:527]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via modelmesh-controller-role ClusterRole; SA modelmesh-controller [source: main.go:268]
- Operator webhook methods=CREATE mechanism=Kubernetes admission enforcement=ValidatingWebhookConfiguration policy=Admission validation [source: config/default/webhookcainjection_patch.yaml:16]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: main.go:521]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: main.go:527]
- Unknown /debug/ on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: main.go:339]
### integrations

- KServe InferenceService interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read model serving state [source: config/rbac/cluster-scope/role.yaml:15]
- ServingRuntime CR interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage serving runtime templates [source: config/rbac/cluster-scope/role.yaml:15]
- prometheus-operator interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage Prometheus monitoring resources [source: config/rbac/cluster-scope/role.yaml:15]
### internal_dependencies

- KServe InferenceService interaction=CRD Watch role=runtime-integration purpose=Read model serving state [source: config/rbac/cluster-scope/role.yaml:15]
- prometheus-operator interaction=CRD CRUD role=unknown purpose=Manage Prometheus monitoring resources [source: config/rbac/cluster-scope/role.yaml:15]
- prometheus-operator interaction=Controller watch (conditional) role=runtime-integration purpose=Manage Prometheus monitoring resources [source: controllers/service_controller.go:465]
### services

- modelmesh-webhook-server-service port=9443 target=webhook protocol=TCP encryption= auth= [source: config/webhook/service.yaml:14]
### serving_runtime_definitions

- ClusterServingRuntime mlserver-1.x formats=lightgbm:3 (autoSelect), sklearn:0 (autoSelect), xgboost:1 (autoSelect) images=mlserver=mlserver-1:replace builtInAdapter=mlserver [source: config/runtimes/mlserver-1.x.yaml:14]
- ClusterServingRuntime ovms-1.x formats=onnx:1, openvino_ir:opset1 (autoSelect) images=ovms=ovms-1:replace builtInAdapter=ovms [source: config/runtimes/ovms-1.x.yaml:14]
- ClusterServingRuntime torchserve-0.x formats=pytorch-mar:0 (autoSelect) images=torchserve=torchserve-0:replace builtInAdapter=torchserve [source: config/runtimes/torchserve-0.x.yaml:14]
- ClusterServingRuntime triton-2.x formats=keras:2 (autoSelect), lightgbm:3, onnx:1 (autoSelect), pytorch:1 (autoSelect), sklearn:0, tensorflow:1 (autoSelect), tensorflow:2 (autoSelect), tensorrt:7 (autoSelect), xgboost:1 images=triton=tritonserver-2:replace builtInAdapter=triton [source: config/runtimes/triton-2.x.yaml:14]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload modelmesh-controller uses service account modelmesh-controller and 1 container(s) [source: config/default/manager_webhook_patch.yaml:14]
- **observed**: Service modelmesh-webhook-server-service targets modelmesh-controller with 1 port(s) [source: config/webhook/service.yaml:14]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by main [source: main.go:521]
- **observed**: HTTP GET /readyz is owned by main [source: main.go:527]
- **observed**: HTTP Unknown /debug/ is owned by main [source: main.go:339]
### security

- **observed**: CREATE Operator webhook uses Kubernetes admission at ValidatingWebhookConfiguration; policy=Admission validation [source: config/default/webhookcainjection_patch.yaml:16]
- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: main.go:521]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: main.go:527]
- **observed**: RBAC role inferenceservice-editor-role grants 2 rule(s) [source: config/rbac/common/inferenceservice_editor_role.yaml:15]
- **observed**: RBAC role inferenceservice-viewer-role grants 2 rule(s) [source: config/rbac/common/inferenceservice_viewer_role.yaml:15]
- **observed**: RBAC role metrics-reader grants 1 rule(s) [source: config/rbac/common/auth_proxy_client_clusterrole.yaml:14]
- **observed**: RBAC role modelmesh-controller-leader-election-role grants 3 rule(s) [source: config/rbac/common/leader_election_role.yaml:15]
- **observed**: RBAC role modelmesh-controller-restricted-scc-role grants 1 rule(s) [source: config/rbac/common/restricted_scc_role.yaml:14]
- **observed**: RBAC role modelmesh-controller-role grants 15 rule(s) [source: config/rbac/namespace-scope/role.yaml:15]
- **observed**: RBAC role modelmesh-controller-role grants 18 rule(s) [source: config/rbac/cluster-scope/role.yaml:15]
- **observed**: RBAC role predictor-editor-role grants 2 rule(s) [source: config/rbac/common/predictor_editor_role.yaml:15]
- **observed**: RBAC role predictor-viewer-role grants 2 rule(s) [source: config/rbac/common/predictor_viewer_role.yaml:15]
- **observed**: RBAC role proxy-role grants 2 rule(s) [source: config/rbac/common/auth_proxy_role.yaml:14]
- **observed**: RBAC role servingruntime-editor-role grants 2 rule(s) [source: config/rbac/common/servingruntime_editor_role.yaml:15]
- **observed**: RBAC role servingruntime-viewer-role grants 2 rule(s) [source: config/rbac/common/servingruntime_viewer_role.yaml:15]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via modelmesh-controller-role ClusterRole; SA modelmesh-controller [source: main.go:268]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: controllers/service_controller.go, fvt/fvtclient.go, pkg/mmesh/etcdrangewatcher.go, pkg/mmesh/modelmesh_service.go]
- **dependency-signal**: tls-config targets google.golang.org/grpc/credentials: TLS configuration import [source: fvt/fvtclient.go, pkg/mmesh/modelmesh_service.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
