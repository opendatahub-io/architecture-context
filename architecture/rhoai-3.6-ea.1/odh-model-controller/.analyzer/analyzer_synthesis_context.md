# Analyzer Synthesis Context: odh-model-controller

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 1 crds facts extracted [source: config/crd/bases/nim.opendatahub.io_accounts.yaml:2]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 7 http_endpoints facts extracted [source: cmd/main.go:162, cmd/main.go:166, server/observability/observability.go:87, server/server.go:19, server/server.go:20, server/server.go:23, server/server.go:27]
- **services (observed)**: 3 services facts extracted [source: config/default/metrics_service.yaml:1, config/server/service.yaml:1, config/webhook/service.yaml:1]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (observed)**: 16 webhooks facts extracted [source: config/webhook/manifests.yaml:106, config/webhook/manifests.yaml:2, internal/webhook/core/v1/pod_webhook.go:35, internal/webhook/nim/v1/account_webhook.go:49, internal/webhook/serving/v1alpha1/inferencegraph_webhook.go:49, internal/webhook/serving/v1alpha1/inferencegraph_webhook.go:77, internal/webhook/serving/v1alpha2/llminferenceservice_webhook.go:46, internal/webhook/serving/v1alpha2/llminferenceservice_webhook.go:47, internal/webhook/serving/v1beta1/inferenceservice_webhook.go:158, internal/webhook/serving/v1beta1/inferenceservice_webhook.go:62]

## Deterministic Cross-References

- **controller**: AccountReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: internal/controller/core/configmap_controller.go:70, internal/controller/nim/account_controller.go:88]
- **controller**: AccountReconciler —watches-reference→ /v1/Secret; /v1/Secret [source: internal/controller/core/configmap_controller.go:224, internal/controller/nim/account_controller.go:89]
- **controller**: AccountReconciler —watches-reference→ api/nim/v1/Account; api/nim/v1/Account [source: internal/controller/nim/account_controller.go:87, internal/controller/nim/account_controller.go:95]
- **controller**: ConfigMapReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: internal/controller/core/configmap_controller.go:157, internal/controller/core/configmap_controller.go:70]
- **controller**: GatewayReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: internal/controller/core/configmap_controller.go:70, internal/controller/serving/llm/gateway_controller.go:1062]
- **controller**: GatewayReconciler —watches-reference→ /v1/Namespace; /v1/Namespace [source: internal/controller/serving/llm/gateway_controller.go:1049, internal/controller/serving/llm/gateway_controller.go:545]
- **controller**: GatewayReconciler —watches-reference→ gateway.networking.k8s.io/v1/Gateway; gateway.networking.k8s.io/v1/Gateway [source: internal/controller/serving/llm/gateway_controller.go:1003, internal/controller/serving/llm/gateway_controller.go:97]
- **controller**: InferenceServiceReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: internal/controller/core/configmap_controller.go:70, internal/controller/serving/inferenceservice_controller.go:211]
- **controller**: InferenceServiceReconciler —watches-reference→ /v1/Namespace; /v1/Namespace [source: internal/controller/serving/inferenceservice_controller.go:207, internal/controller/serving/llm/gateway_controller.go:545]
- **controller**: InferenceServiceReconciler —watches-reference→ /v1/Secret; /v1/Secret [source: internal/controller/core/configmap_controller.go:224, internal/controller/serving/inferenceservice_controller.go:212]
- **controller**: InferenceServiceReconciler —watches-reference→ /v1/Service; /v1/Service [source: internal/controller/resources/service.go:44, internal/controller/serving/inferenceservice_controller.go:210]
- **controller**: InferenceServiceReconciler —watches-reference→ /v1/ServiceAccount; /v1/ServiceAccount [source: internal/controller/resources/serviceaccount.go:46, internal/controller/serving/inferenceservice_controller.go:209]
- **controller**: InferenceServiceReconciler —watches-reference→ networking.k8s.io/v1/NetworkPolicy; networking.k8s.io/v1/NetworkPolicy [source: internal/controller/resources/networkpolicy.go:46, internal/controller/serving/inferenceservice_controller.go:214]
- **controller**: InferenceServiceReconciler —watches-reference→ rbac.authorization.k8s.io/v1/ClusterRoleBinding; rbac.authorization.k8s.io/v1/ClusterRoleBinding [source: internal/controller/resources/clusterrolebinding.go:53, internal/controller/serving/inferenceservice_controller.go:213]
- **controller**: InferenceServiceReconciler —watches-reference→ rbac.authorization.k8s.io/v1/Role; rbac.authorization.k8s.io/v1/Role [source: internal/controller/serving/inferenceservice_controller.go:217, internal/controller/serving/llm/maas_rbac_cleanup.go:82]
- **controller**: InferenceServiceReconciler —watches-reference→ rbac.authorization.k8s.io/v1/RoleBinding; rbac.authorization.k8s.io/v1/RoleBinding [source: internal/controller/serving/inferenceservice_controller.go:218, internal/controller/serving/llm/maas_rbac_cleanup.go:108]
- **controller**: InferenceServiceReconciler —watches-reference→ route.openshift.io/v1/Route; route.openshift.io/v1/Route [source: internal/controller/resources/route.go:47, internal/controller/serving/inferenceservice_controller.go:208]
- **controller**: PodReconciler —watches-reference→ /v1/Pod; /v1/Pod [source: internal/controller/core/pod_controller.go:109, internal/controller/core/pod_controller.go:53]
- **controller**: SecretReconciler —watches-reference→ /v1/Secret; /v1/Secret [source: internal/controller/core/configmap_controller.go:224, internal/controller/core/secret_controller.go:251]
- **controller**: ServingRuntimeReconciler —watches-reference→ /v1/Namespace; /v1/Namespace [source: internal/controller/serving/llm/gateway_controller.go:545, internal/controller/serving/servingruntime_controller.go:437]
- **controller**: ServingRuntimeReconciler —watches-reference→ /v1/Secret; /v1/Secret [source: internal/controller/core/configmap_controller.go:224, internal/controller/serving/servingruntime_controller.go:421]
- **controller**: ServingRuntimeReconciler —watches-reference→ rbac.authorization.k8s.io/v1/RoleBinding; rbac.authorization.k8s.io/v1/RoleBinding [source: internal/controller/serving/llm/maas_rbac_cleanup.go:108, internal/controller/serving/servingruntime_controller.go:420]
- **security**: Unknown /metrics —protected-by→ Unknown; Application (model-serving-api): Dedicated metrics listener on port 8080; authentication not established by source [source: config/server/server.yaml:1, server/observability/observability.go:87]

## Gap Evidence Index

### authentication

- **Question:** How is this runtime security control wired to the serving surface?
  **Expected signal:** flag/default, certificate, middleware, or enforcement point
  **Candidate:** `cmd/main.go`:240 (controller-runtime metrics, controller-runtime metrics authn/authz filter)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/main.go`:162 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `config/server/server.yaml`:1 (:8443/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `config/webhook/manifests.yaml`:106 (Kubernetes admission, Operator webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `internal/controller/utils/utils.go`:124 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/account_editor_role.yaml`:2 (account-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/account_viewer_role.yaml`:2 (account-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/auth_proxy_role.yaml`:1 (proxy-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/rbac/auth_proxy_role_binding.yaml`:1 (proxy-role, proxy-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/kserve_prometheus_clusterrole.yaml`:1 (kserve-prometheus-k8s)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/leader_election_role.yaml`:2 (leader-election-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/metrics_auth_role.yaml`:1 (metrics-auth-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/metrics_reader_role.yaml`:1 (metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/role.yaml`:3 (odh-model-controller-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/rbac/role_binding.yaml`:1 (odh-model-controller-role, odh-model-controller-rolebinding-opendatahub)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/server/clusterrole.yaml`:1 (model-serving-api)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/server/clusterrolebinding.yaml`:1 (model-serving-api)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:33 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:48 (Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/main.go`:86 (cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `server/main.go`:27 (server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/main.go`:135 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `internal/controller/utils/utils.go`:124 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `server/gateway/discovery.go`:154 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `server/observability/observability.go`:68 (OTLP/gRPC trace exporter, OpenTelemetry Collector)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/main.go`:162 (/healthz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `server/observability/observability.go`:87 (/metrics, Unknown, server/observability)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `server/server.go`:23 (/api/v1/gateways, Unknown, server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:3 (CRD Watch, DataScienceCluster CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `server/observability/observability.go`:68 (OpenTelemetry Collector, gRPC client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:3 (CRD Watch, DataScienceCluster CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/core/configmap_controller.go`:70 (/v1/ConfigMap, create, delete, get operations by ConfigMapReconciler, KserveMetricsDashboardReconciler, SecretReconciler, configMapHandler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/core/pod_controller.go`:109 (/v1/Pod, get, list operations by PodReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/nim/account_controller.go`:95 (api/nim/v1/Account, get, list, patch, update operations by AccountCustomValidator, AccountReconciler, NIMCleanupRunner)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/resources/service.go`:44 (/v1/Service, create, delete, get, list operations by KserveRawMetricsServiceReconciler, KserveRawRouteReconciler, serviceHandler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/resources/serviceaccount.go`:46 (/v1/ServiceAccount, create, delete, get operations by KserveKEDAReconciler, ServiceAccountReconciler, serviceAccountHandler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `internal/controller/serving/inferencegraph_controller.go`:74 (Controller watch, KServe InferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `internal/controller/serving/inferenceservice_controller.go`:216 (Controller watch, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/serving/llm/gateway_controller.go`:545 (/v1/Namespace, get operations by GatewayReconciler, KubeDiscoverer, ServingRuntimeReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `internal/controller/serving/llm/gateway_controller.go`:1003 (Controller watch, Gateway API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/webhook/serving/v1alpha2/llminferenceservice_webhook.go`:529 (/v1/Event, create operations by LLMInferenceServiceCustomDefaulter)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `server/gateway/discovery.go`:172 (authorization/v1/SelfSubjectAccessReview, create operations by SelfSubjectAccessChecker)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/controller/core/configmap_controller.go`:70 (/v1/ConfigMap, create, delete, get operations by ConfigMapReconciler, KserveMetricsDashboardReconciler, SecretReconciler, configMapHandler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/core/configmap_controller.go`:157 (/v1/ConfigMap, ConfigMapReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/core/pod_controller.go`:53 (/v1/Pod, PodReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/core/secret_controller.go`:251 (/v1/Secret, SecretReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/nim/account_controller.go`:88 (/v1/ConfigMap, AccountReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/serving/inferencegraph_controller.go`:74 (InferenceGraphReconciler, serving.kserve.io/v1alpha1/InferenceGraph)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/serving/inferenceservice_controller.go`:211 (/v1/ConfigMap, InferenceServiceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/controller/serving/llm/gateway_controller.go`:545 (/v1/Namespace, get operations by GatewayReconciler, KubeDiscoverer, ServingRuntimeReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/serving/llm/gateway_controller.go`:1062 (/v1/ConfigMap, GatewayReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/serving/llm/llm_inferenceservice_controller.go`:164 (LLMInferenceServiceReconciler, api/v1/AuthPolicy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/serving/servingruntime_controller.go`:437 (/v1/Namespace, ServingRuntimeReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/webhook/serving/v1alpha2/llminferenceservice_webhook.go`:529 (/v1/Event, create operations by LLMInferenceServiceCustomDefaulter)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `config/default/manager_webhook_patch.yaml`:1 (odh-model-controller)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `config/default/metrics_service.yaml`:1 (odh-model-controller, odh-model-controller-metrics-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `config/server/server.yaml`:1 (model-serving-api)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `config/server/service.yaml`:1 (model-serving-api)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `config/webhook/service.yaml`:1 (odh-model-controller, odh-model-controller-webhook-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### webhooks

- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/webhook/manifests.yaml`:2 (/mutate--v1-pod, mutating.pod.odh-model-controller.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/core/v1/pod_webhook.go`:35 (/mutate--v1-pod, mutating.pod.odh-model-controller.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/nim/v1/account_webhook.go`:49 (/validate-nim-opendatahub-io-v1-account, validating.nim.account.odh-model-controller.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/serving/v1alpha1/inferencegraph_webhook.go`:49 (/mutate-serving-kserve-io-v1alpha1-inferencegraph, minferencegraph-v1alpha1.odh-model-controller.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/serving/v1alpha2/llminferenceservice_webhook.go`:47 (/mutate-serving-kserve-io-v1alpha1-llminferenceservice, connection-llmisvc-v1alpha1.odh-model-controller.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/serving/v1beta1/inferenceservice_webhook.go`:158 (/mutate-serving-kserve-io-v1beta1-inferenceservice, minferenceservice-v1beta1.odh-model-controller.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- /metrics methods=Unknown mechanism=Unknown enforcement=Application (model-serving-api) policy=Dedicated metrics listener on port 8080; authentication not established by source [source: config/server/server.yaml:1]
- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: cmd/main.go:162]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/main.go:166]
- :8443/healthz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes liveness probe endpoint [source: config/server/server.yaml:1]
- :8443/readyz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes readiness probe endpoint [source: config/server/server.yaml:1]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via model-serving-api ClusterRole; SA model-serving-api [source: internal/controller/utils/utils.go:124]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via odh-model-controller-role ClusterRole; SA odh-model-controller [source: internal/controller/utils/utils.go:124]
- Operator webhook methods=CREATE mechanism=Kubernetes admission enforcement=ValidatingWebhookConfiguration policy=Admission validation [source: config/webhook/manifests.yaml:106]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/main.go:162]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/main.go:166]
- Unknown /api/v1/gateways on port ; transport=HTTP/1.1 encryption= auth= owner=server [source: server/server.go:23]
- Unknown /api/v1/samples/llm-d on port ; transport=HTTP/1.1 encryption= auth= owner=server [source: server/server.go:27]
- Unknown /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=server [source: server/server.go:19]
- Unknown /metrics on port ; transport=HTTP/1.1 encryption= auth= owner=server/observability [source: server/observability/observability.go:87]
- Unknown /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=server [source: server/server.go:20]
### integrations

- DSCInitialization CR interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read platform initialization state [source: config/rbac/role.yaml:3]
- DataScienceCluster CR interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read enabled platform components [source: config/rbac/role.yaml:3]
- Gateway API interaction=HTTPRoute CRUD role=runtime-transport protocol=HTTPS purpose=Manage Gateway API routing resources [source: config/rbac/role.yaml:3]
- HardwareProfile CR interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage hardware profile resources [source: config/rbac/role.yaml:3]
- KServe InferenceService interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read model serving state [source: config/rbac/role.yaml:3]
- NIM Account CR interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage NVIDIA NIM account configuration [source: config/rbac/role.yaml:3]
- OpenShift Routes interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Dashboard route status [source: config/rbac/role.yaml:3]
- OpenTelemetry Collector interaction=gRPC client role=runtime-integration protocol=OTLP/gRPC purpose=Runtime trace export [source: server/observability/observability.go:68]
- ServingRuntime CR interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage serving runtime templates [source: config/rbac/role.yaml:3]
- prometheus-operator interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage Prometheus monitoring resources [source: config/rbac/role.yaml:3]
### internal_dependencies

- DSCInitialization CR interaction=CRD Watch role=runtime-integration purpose=Read platform initialization state [source: config/rbac/role.yaml:3]
- DataScienceCluster CR interaction=CRD Watch role=runtime-integration purpose=Read enabled platform components [source: config/rbac/role.yaml:3]
- Gateway API interaction=CRD CRUD role=unknown purpose=Manage Gateway API routing resources [source: config/rbac/role.yaml:3]
- Gateway API interaction=Controller watch role=runtime-integration purpose=Manage Gateway API routing resources [source: internal/controller/serving/llm/gateway_controller.go:1003]
- HardwareProfile CR interaction=CRD CRUD role=unknown purpose=Manage hardware profile resources [source: config/rbac/role.yaml:3]
- KServe InferenceService interaction=CRD Watch role=runtime-integration purpose=Read model serving state [source: config/rbac/role.yaml:3]
- KServe InferenceService interaction=Controller watch role=runtime-integration purpose=Read model serving state [source: internal/controller/serving/inferencegraph_controller.go:74]
- prometheus-operator interaction=CRD CRUD role=unknown purpose=Manage Prometheus monitoring resources [source: config/rbac/role.yaml:3]
- prometheus-operator interaction=Controller watch (conditional) role=runtime-integration purpose=Manage Prometheus monitoring resources [source: internal/controller/serving/llm/gateway_controller.go:1012]
- prometheus-operator interaction=Controller watch role=runtime-integration purpose=Manage Prometheus monitoring resources [source: internal/controller/serving/inferenceservice_controller.go:216]
### services

- model-serving-api port=443 target=8443 protocol=TCP encryption= auth= [source: config/server/service.yaml:1]
- model-serving-api port=8080 target=8080 protocol=TCP encryption= auth= [source: config/server/service.yaml:1]
- odh-model-controller-metrics-service port=8080 target=8080 protocol=TCP encryption= auth= [source: config/default/metrics_service.yaml:1]
- odh-model-controller-webhook-service port=443 target=9443 protocol=TCP encryption= auth= [source: config/webhook/service.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload model-serving-api uses service account model-serving-api and 1 container(s) [source: config/server/server.yaml:1]
- **observed**: Deployment workload odh-model-controller uses service account odh-model-controller and 1 container(s) [source: config/default/manager_webhook_patch.yaml:1]
- **observed**: Service model-serving-api targets model-serving-api with 2 port(s) [source: config/server/service.yaml:1]
- **observed**: Service odh-model-controller-metrics-service targets odh-model-controller with 1 port(s) [source: config/default/metrics_service.yaml:1]
- **observed**: Service odh-model-controller-webhook-service targets odh-model-controller with 1 port(s) [source: config/webhook/service.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by cmd [source: cmd/main.go:162]
- **observed**: HTTP GET /readyz is owned by cmd [source: cmd/main.go:166]
- **observed**: HTTP Unknown /api/v1/gateways is owned by server [source: server/server.go:23]
- **observed**: HTTP Unknown /api/v1/samples/llm-d is owned by server [source: server/server.go:27]
- **observed**: HTTP Unknown /healthz is owned by server [source: server/server.go:19]
- **observed**: HTTP Unknown /metrics is owned by server/observability [source: server/observability/observability.go:87]
- **observed**: HTTP Unknown /readyz is owned by server [source: server/server.go:20]
### security

- **observed**: CREATE Operator webhook uses Kubernetes admission at ValidatingWebhookConfiguration; policy=Admission validation [source: config/webhook/manifests.yaml:106]
- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: cmd/main.go:162]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/main.go:166]
- **observed**: GET :8443/healthz uses None at N/A; policy=Unauthenticated Kubernetes liveness probe endpoint [source: config/server/server.yaml:1]
- **observed**: GET :8443/readyz uses None at N/A; policy=Unauthenticated Kubernetes readiness probe endpoint [source: config/server/server.yaml:1]
- **observed**: Kuadrant AuthPolicy {registry-name} applies authentication Kubernetes TokenReview [source: internal/controller/resources/template/authpolicy_llm_isvc_userdefined.yaml:1]
- **observed**: RBAC role account-editor-role grants 2 rule(s) [source: config/rbac/account_editor_role.yaml:2]
- **observed**: RBAC role account-viewer-role grants 2 rule(s) [source: config/rbac/account_viewer_role.yaml:2]
- **observed**: RBAC role kserve-prometheus-k8s grants 1 rule(s) [source: config/rbac/kserve_prometheus_clusterrole.yaml:1]
- **observed**: RBAC role leader-election-role grants 3 rule(s) [source: config/rbac/leader_election_role.yaml:2]
- **observed**: RBAC role metrics-auth-role grants 2 rule(s) [source: config/rbac/metrics_auth_role.yaml:1]
- **observed**: RBAC role metrics-reader grants 1 rule(s) [source: config/rbac/metrics_reader_role.yaml:1]
- **observed**: RBAC role model-serving-api grants 2 rule(s) [source: config/server/clusterrole.yaml:1]
- **observed**: RBAC role odh-model-controller-role grants 35 rule(s) [source: config/rbac/role.yaml:3]
- **observed**: RBAC role proxy-role grants 2 rule(s) [source: config/rbac/auth_proxy_role.yaml:1]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via model-serving-api ClusterRole; SA model-serving-api [source: internal/controller/utils/utils.go:124]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via odh-model-controller-role ClusterRole; SA odh-model-controller [source: internal/controller/utils/utils.go:124]
- **observed**: Unknown /metrics uses Unknown at Application (model-serving-api); policy=Dedicated metrics listener on port 8080; authentication not established by source [source: config/server/server.yaml:1]
- **literal**: rbac-ref targets SelfSubjectAccessReviews: Token or subject access review call [source: server/gateway/discovery.go:171]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: cmd/main.go, internal/controller/utils/nim.go, server/common/certreloader.go, server/main.go, server/observability/observability.go, server/server.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
