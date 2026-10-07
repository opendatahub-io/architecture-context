# Analyzer Synthesis Context: llm-d-autoscaling

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 2 http_endpoints facts extracted [source: legacy/cmd/main.go:664, legacy/cmd/main.go:668]
- **services (observed)**: 1 services facts extracted [source: legacy/config/base/manager/service.yaml:1]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References

- **controller**: ConfigMapReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: legacy/internal/controller/configmap_bootstrap.go:124, legacy/internal/controller/configmap_reconciler.go:109]
- **controller**: HPAReconciler —watches-reference→ autoscaling/v2/HorizontalPodAutoscaler; autoscaling/v2/HorizontalPodAutoscaler [source: legacy/internal/collector/locator/locator.go:281, legacy/internal/controller/hpa_reconciler.go:67]

## Behavioral Evidence

No bounded behavioral evidence was extracted.

## Gap Evidence Index

### authentication

- **Question:** How is this runtime security control wired to the serving surface?
  **Expected signal:** flag/default, certificate, middleware, or enforcement point
  **Candidate:** `legacy/cmd/main.go`:272 (controller-runtime metrics, controller-runtime metrics authn/authz filter)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `legacy/cmd/main.go`:272 (:8443/metrics, TokenReview + SubjectAccessReview (controller-runtime authn/authz filter))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `legacy/cmd/main.go`:664 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `legacy/cmd/main.go`:668 (:8081/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `legacy/internal/actuator/direct_actuator.go`:108 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `legacy/config/base/rbac/epp-metrics-reader-clusterrole.yaml`:1 (epp-metrics-reader-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `legacy/config/base/rbac/epp-metrics-reader-clusterrolebinding.yaml`:1 (epp-metrics-reader-role, epp-metrics-reader-role-binding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `legacy/config/base/rbac/leader-election-role.yaml`:1 (leader-election-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `legacy/config/base/rbac/leader-election-rolebinding.yaml`:1 (leader-election-role, leader-election-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `legacy/config/base/rbac/manager-clusterrole.yaml`:2 (manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `legacy/config/base/rbac/manager-clusterrolebinding.yaml`:1 (manager-role, manager-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `legacy/config/base/rbac/metrics-auth-clusterrole.yaml`:1 (metrics-auth-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `legacy/config/base/rbac/metrics-auth-clusterrolebinding.yaml`:1 (metrics-auth-role, metrics-auth-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `legacy/config/base/rbac/metrics-reader-clusterrole.yaml`:1 (metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `legacy/config/base/rbac/metrics-reader-clusterrolebinding.yaml`:4 (metrics-reader, metrics-reader-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `legacy/Dockerfile`:37 (legacy/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `legacy/cmd/main.go`:99 (cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `legacy/cmd/main.go`:446 (Prometheus, Prometheus HTTP API client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `legacy/go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `legacy/internal/actuator/direct_actuator.go`:108 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `legacy/internal/engines/scalefromzero/engine.go`:88 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `legacy/internal/utils/crd/crd.go`:31 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `legacy/cmd/main.go`:664 (/healthz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `legacy/cmd/main.go`:668 (/readyz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `legacy/config/base/rbac/manager-clusterrole.yaml`:2 (API client, Kubernetes API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `legacy/config/base/rbac/manager-clusterrole.yaml`:2 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `legacy/cmd/main.go`:446 (Metrics source, Prometheus)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `legacy/cmd/main.go`:76 (Go library, gateway-api-inference-extension)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `legacy/config/base/rbac/manager-clusterrole.yaml`:2 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `legacy/config/base/rbac/manager-clusterrole.yaml`:2 (Kubernetes API (nodes), list)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `legacy/internal/collector/locator/locator.go`:140 (/v1/Pod, get, list operations by K8sWithGpuOperator, PodScrapingSource, podLocator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `legacy/internal/collector/source/pod/pod_scraping_source.go`:180 (/v1/Service, get operations by PodScrapingSource)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `legacy/internal/controller/configmap_bootstrap.go`:124 (/v1/ConfigMap, get operations by ConfigMapReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `legacy/internal/controller/configmap_bootstrap.go`:56 (/v1/Namespace, get, list operations by ConfigMapReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `legacy/internal/controller/inferencepool_reconciler.go`:113 (Controller watch, gateway-api-inference-extension)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `legacy/internal/controller/scaledobject_reconciler.go`:68 (Controller watch (conditional), KEDA)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `legacy/internal/coordinator/plugins/gpurebalance/plugin.go`:238 (/v1/ResourceQuota, list operations by Plugin)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `legacy/internal/discovery/k8s_with_gpu_operator.go`:83 (/v1/Node, list operations by K8sWithGpuOperator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `legacy/internal/actuator/direct_actuator.go`:102 (autoscaling/v1/Scale, update operations by DirectActuator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `legacy/internal/collector/locator/locator.go`:140 (/v1/Pod, get, list operations by K8sWithGpuOperator, PodScrapingSource, podLocator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `legacy/internal/collector/source/pod/pod_scraping_source.go`:180 (/v1/Service, get operations by PodScrapingSource)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `legacy/internal/controller/configmap_bootstrap.go`:124 (/v1/ConfigMap, get operations by ConfigMapReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `legacy/internal/controller/configmap_bootstrap.go`:56 (/v1/Namespace, get, list operations by ConfigMapReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `legacy/internal/controller/configmap_reconciler.go`:109 (/v1/ConfigMap, ConfigMapReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `legacy/internal/controller/hpa_reconciler.go`:67 (HPAReconciler, autoscaling/v2/HorizontalPodAutoscaler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `legacy/internal/controller/inferencepool_reconciler.go`:109 (InferencePoolReconciler, inference.networking.x-k8s.io/v1alpha2/InferencePool)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `legacy/internal/controller/inferencepool_reconciler.go`:113 (InferencePoolReconciler, inference.networking.k8s.io/v1/InferencePool)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `legacy/internal/controller/scaledobject_reconciler.go`:68 (ScaledObjectReconciler, keda.sh/v1alpha1/ScaledObject)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `legacy/internal/coordinator/plugins/gpurebalance/plugin.go`:238 (/v1/ResourceQuota, list operations by Plugin)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `legacy/internal/discovery/k8s_with_gpu_operator.go`:83 (/v1/Node, list operations by K8sWithGpuOperator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `legacy/config/base/manager/deployment.yaml`:1 (controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `legacy/config/base/manager/service.yaml`:1 (controller-manager, controller-manager-metrics-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: legacy/cmd/main.go:664]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: legacy/cmd/main.go:668]
- :8443/metrics methods=GET mechanism=TokenReview + SubjectAccessReview (controller-runtime authn/authz filter) enforcement=controller-runtime metrics authn/authz filter policy=RBAC via metrics-auth-role; exposed by Service controller-manager-metrics-service; controller-runtime generated self-signed TLS certificate [source: legacy/cmd/main.go:272]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via manager-role ClusterRole; SA controller-manager [source: legacy/internal/actuator/direct_actuator.go:108]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: legacy/cmd/main.go:664]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: legacy/cmd/main.go:668]
### integrations

- Kubernetes API interaction=API client role=runtime-integration protocol=HTTPS purpose=Cluster resource management via RBAC [source: legacy/config/base/rbac/manager-clusterrole.yaml:2]
- prometheus-operator interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage Prometheus monitoring resources [source: legacy/config/base/rbac/manager-clusterrole.yaml:2]
### internal_dependencies

- KEDA interaction=Controller watch (conditional) role=runtime-integration purpose=Optional ScaledObject discovery for autoscaling targets [source: legacy/internal/controller/scaledobject_reconciler.go:68]
- Kubernetes API (nodes) interaction=list role=unknown purpose=nodes resource access via RBAC [source: legacy/config/base/rbac/manager-clusterrole.yaml:2]
- Prometheus interaction=Metrics source role=unknown purpose=Required Prometheus API client used for runtime metrics queries [source: legacy/cmd/main.go:446]
- gateway-api-inference-extension interaction=Controller watch role=runtime-integration purpose=Watch InferencePool resources for pool-based autoscaling configuration [source: legacy/internal/controller/inferencepool_reconciler.go:113]
- gateway-api-inference-extension interaction=Go library role=runtime-library purpose=Use runtime packages from sigs.k8s.io/gateway-api-inference-extension [source: legacy/cmd/main.go:76]
- prometheus-operator interaction=CRD CRUD role=unknown purpose=Manage Prometheus monitoring resources [source: legacy/config/base/rbac/manager-clusterrole.yaml:2]
### services

- controller-manager-metrics-service port=8443 target=8443 protocol=TCP encryption= auth= [source: legacy/config/base/manager/service.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload controller-manager uses service account controller-manager and 1 container(s) [source: legacy/config/base/manager/deployment.yaml:1]
- **observed**: Service controller-manager-metrics-service targets controller-manager with 1 port(s) [source: legacy/config/base/manager/service.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by cmd [source: legacy/cmd/main.go:664]
- **observed**: HTTP GET /readyz is owned by cmd [source: legacy/cmd/main.go:668]
### security

- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: legacy/cmd/main.go:664]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: legacy/cmd/main.go:668]
- **observed**: GET :8443/metrics uses TokenReview + SubjectAccessReview (controller-runtime authn/authz filter) at controller-runtime metrics authn/authz filter; policy=RBAC via metrics-auth-role; exposed by Service controller-manager-metrics-service; controller-runtime generated self-signed TLS certificate [source: legacy/cmd/main.go:272]
- **observed**: RBAC role epp-metrics-reader-role grants 1 rule(s) [source: legacy/config/base/rbac/epp-metrics-reader-clusterrole.yaml:1]
- **observed**: RBAC role leader-election-role grants 2 rule(s) [source: legacy/config/base/rbac/leader-election-role.yaml:1]
- **observed**: RBAC role manager-role grants 12 rule(s) [source: legacy/config/base/rbac/manager-clusterrole.yaml:2]
- **observed**: RBAC role metrics-auth-role grants 2 rule(s) [source: legacy/config/base/rbac/metrics-auth-clusterrole.yaml:1]
- **observed**: RBAC role metrics-reader grants 1 rule(s) [source: legacy/config/base/rbac/metrics-reader-clusterrole.yaml:1]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via manager-role ClusterRole; SA controller-manager [source: legacy/internal/actuator/direct_actuator.go:108]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: legacy/cmd/main.go, legacy/internal/prometheus/tls.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
