# Analyzer Synthesis Context: model-registry

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (not-verified)**: 0 grpc_services facts extracted; absence is not proven by the available coverage
- **http_endpoints (observed)**: 8 http_endpoints facts extracted [source: catalog/internal/plugin/server.go:169, catalog/internal/plugin/server.go:170, catalog/internal/plugins/mcp/plugin.go:135, catalog/internal/plugins/serving_runtime/plugin.go:121, clients/ui/bff/internal/api/app.go:379, clients/ui/bff/internal/api/app.go:403, cmd/controller/main.go:160, cmd/controller/main.go:164]
- **services (observed)**: 1 services facts extracted [source: manifests/kustomize/options/controller/default/metrics_service.yaml:1]
- **ingress (observed)**: 3 ingress facts extracted [source: manifests/kustomize/options/catalog/options/istio/virtual-service.yaml:1, manifests/kustomize/options/istio/virtual-service.yaml:1, manifests/kustomize/options/ui/overlays/istio/virtual-service.yaml:1]
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References


## Behavioral Evidence

- **conditional-metrics-enforcement (unresolved)** controller-runtime metrics: controller-runtime metrics serving surface; limitations=The controller-runtime manager Metrics binding does not use one direct lexical options object with a stable SecureServing condition [source: cmd/controller/main.go:116-116]

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `clients/ui/bff/cmd/main.go`:56 (/api/v1/*, Bearer Token (Authorization header) or internal ServiceAccount token)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this runtime security control wired to the serving surface?
  **Expected signal:** flag/default, certificate, middleware, or enforcement point
  **Candidate:** `cmd/controller/main.go`:104 (controller-runtime metrics, controller-runtime metrics authn/authz filter)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/controller/main.go`:104 (:8443/metrics, TokenReview + SubjectAccessReview (controller-runtime authn/authz filter))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/controller/main.go`:114 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Under which configuration branch does the metrics serving surface install authentication and authorization?
  **Expected signal:** a direct SecureServing condition and controller-runtime authn/authz FilterProvider assignment
  **Candidate:** `cmd/controller/main.go`:116-116 (controller-runtime metrics, controller-runtime metrics serving surface)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/controller/main.go`:160 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/controller/main.go`:164 (:8081/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `manifests/kustomize/options/istio/istio-authorization-policy.yaml`:1 (/api/model_registry/*, Istio source namespace + Istio source principal + Kubernetes JWT (Authorization header))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `manifests/kustomize/options/ui/overlays/istio/authorization-policy-ui.yaml`:1 (/model-registry/*, Istio source principal)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/kustomize/options/controller/rbac/leader_election_role.yaml`:2 (controller-leader-election-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `manifests/kustomize/options/controller/rbac/leader_election_role_binding.yaml`:1 (controller-leader-election-role, controller-leader-election-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/kustomize/options/controller/rbac/metrics_auth_role.yaml`:1 (controller-metrics-auth-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `manifests/kustomize/options/controller/rbac/metrics_auth_role_binding.yaml`:1 (controller-metrics-auth-role, controller-metrics-auth-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/kustomize/options/controller/rbac/metrics_reader_role.yaml`:1 (controller-metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/kustomize/options/controller/rbac/role.yaml`:2 (controller-model-registry-manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `manifests/kustomize/options/controller/rbac/role_binding.yaml`:1 (controller-model-registry-manager-role, controller-model-registry-manager-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:45 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:42 (Dockerfile.konflux:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.odh`:38 (Dockerfile.odh:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.testops`:56 (Dockerfile.testops:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.testops`:57 (Dockerfile.testops:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `clients/ui/Dockerfile`:64 (clients/ui/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `clients/ui/Dockerfile.standalone`:68 (clients/ui/Dockerfile.standalone:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/controller/Dockerfile.controller`:38 (cmd/controller/Dockerfile.controller:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/csi/Dockerfile.csi`:32 (cmd/csi/Dockerfile.csi:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `jobs/async-upload/Dockerfile`:52 (jobs/async-upload/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `jobs/async-upload/Dockerfile`:68 (jobs/async-upload/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `jobs/async-upload/Dockerfile.konflux`:61 (jobs/async-upload/Dockerfile.konflux:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `clients/ui/bff/go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `clients/ui/bff/internal/integrations/kubernetes/internal_k8s_client.go`:33 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `clients/ui/bff/internal/integrations/kubernetes/token_k8s_client.go`:77 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/controller/main.go`:114 (Kubernetes API, controller-runtime manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `catalog/internal/plugin/server.go`:169 (/healthz, GET, catalog/internal/plugin)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `catalog/internal/plugin/server.go`:170 (/readyz, GET, catalog/internal/plugin)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `catalog/internal/plugins/mcp/plugin.go`:135 (/api/mcp_catalog/v1alpha1/mcp_servers/{server_id}/logo, GET, catalog/internal/plugins/mcp)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `catalog/internal/plugins/serving_runtime/plugin.go`:121 (/api/serving_runtime_catalog/v1/serving_runtimes/{id}/logo, GET, catalog/internal/plugins/serving_runtime)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `clients/ui/bff/internal/api/app.go`:379 (/, Unknown, internal/api)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `clients/ui/bff/internal/api/app.go`:403 (/, Unknown, internal/api)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/controller/main.go`:160 (/healthz, GET, main)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/controller/main.go`:164 (/readyz, GET, main)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `manifests/kustomize/options/controller/rbac/role.yaml`:2 (CRD Watch, KServe InferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `clients/ui/bff/internal/integrations/kubernetes/internal_k8s_client.go`:65 (authorization/v1/SubjectAccessReview, create operations by InternalKubernetesClient)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `clients/ui/bff/internal/integrations/kubernetes/shared_k8s_client.go`:250 (/v1/Secret, create operations by SharedClientLogic)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `clients/ui/bff/internal/integrations/kubernetes/shared_k8s_client.go`:346 (/v1/ConfigMap, create, update operations by SharedClientLogic)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `clients/ui/bff/internal/integrations/kubernetes/shared_k8s_client.go`:492 (batch/v1/Job, create operations by SharedClientLogic)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `clients/ui/bff/internal/integrations/kubernetes/token_k8s_client.go`:165 (authorization/v1/SelfSubjectRulesReview, create operations by TokenKubernetesClient)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `clients/ui/bff/internal/integrations/kubernetes/token_k8s_client.go`:263 (authentication/v1/SelfSubjectReview, create operations by TokenKubernetesClient)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `clients/ui/bff/internal/integrations/kubernetes/token_k8s_client.go`:42 (authorization/v1/SelfSubjectAccessReview, create operations by TokenKubernetesClient)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `cmd/controller/internal/controllers/inferenceservice_controller.go`:44 (Controller watch (conditional), KServe InferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `manifests/kustomize/options/controller/rbac/role.yaml`:2 (CRD Watch, KServe InferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/inferenceservice-controller/controller.go`:251 (Controller watch, KServe InferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/inferenceservice-controller/controller.go`:310 (/v1/Service, get, list operations by InferenceServiceController)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `clients/ui/bff/internal/integrations/kubernetes/internal_k8s_client.go`:65 (authorization/v1/SubjectAccessReview, create operations by InternalKubernetesClient)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `clients/ui/bff/internal/integrations/kubernetes/shared_k8s_client.go`:250 (/v1/Secret, create operations by SharedClientLogic)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `clients/ui/bff/internal/integrations/kubernetes/shared_k8s_client.go`:346 (/v1/ConfigMap, create, update operations by SharedClientLogic)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `clients/ui/bff/internal/integrations/kubernetes/shared_k8s_client.go`:492 (batch/v1/Job, create operations by SharedClientLogic)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `clients/ui/bff/internal/integrations/kubernetes/token_k8s_client.go`:165 (authorization/v1/SelfSubjectRulesReview, create operations by TokenKubernetesClient)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `clients/ui/bff/internal/integrations/kubernetes/token_k8s_client.go`:263 (authentication/v1/SelfSubjectReview, create operations by TokenKubernetesClient)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `clients/ui/bff/internal/integrations/kubernetes/token_k8s_client.go`:42 (authorization/v1/SelfSubjectAccessReview, create operations by TokenKubernetesClient)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `cmd/controller/internal/controllers/inferenceservice_controller.go`:44 (InferenceServiceReconciler, serving.kserve.io/v1beta1/InferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/inferenceservice-controller/controller.go`:251 (InferenceServiceController, serving.kserve.io/v1beta1/InferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `pkg/inferenceservice-controller/controller.go`:310 (/v1/Service, get, list operations by InferenceServiceController)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `manifests/kustomize/options/controller/default/manager_metrics_patch.yaml`:1 (controller-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `manifests/kustomize/options/controller/default/metrics_service.yaml`:1 (controller-controller-manager, controller-controller-manager-metrics-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- /api/model_registry/* methods=GET mechanism=Istio source namespace + Istio source principal + Kubernetes JWT (Authorization header) enforcement=Istio sidecar proxy AuthorizationPolicy policy=Istio AuthorizationPolicy for component=model-registry-server; action=ALLOW; allows namespaces: kubeflow; allows principals: cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account; blocks request.headers[kubeflow-userid]; requires request.headers[authorization] [source: manifests/kustomize/options/istio/istio-authorization-policy.yaml:1]
- /api/v1/* methods=ALL mechanism=Bearer Token (Authorization header) or internal ServiceAccount token enforcement=Go BFF authentication configuration policy=auth-method flag accepts internal or user_token; token header and Bearer prefix are configurable [source: clients/ui/bff/cmd/main.go:56]
- /model-registry/* methods=GET mechanism=Istio source principal enforcement=Istio sidecar proxy AuthorizationPolicy policy=Istio AuthorizationPolicy for app=model-registry-ui; action=ALLOW; allows principals: cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account [source: manifests/kustomize/options/ui/overlays/istio/authorization-policy-ui.yaml:1]
- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: cmd/controller/main.go:160]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/controller/main.go:164]
- :8443/metrics methods=GET mechanism=TokenReview + SubjectAccessReview (controller-runtime authn/authz filter) enforcement=controller-runtime metrics authn/authz filter policy=RBAC via controller-metrics-auth-role; exposed by Service controller-controller-manager-metrics-service; controller-runtime generated self-signed TLS certificate [source: cmd/controller/main.go:104]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via controller-model-registry-manager-role ClusterRole; SA controller-controller-manager [source: cmd/controller/main.go:114]
### http_endpoints

- GET /api/mcp_catalog/v1alpha1/mcp_servers/{server_id}/logo on port ; transport=HTTP/1.1 encryption= auth= owner=catalog/internal/plugins/mcp [source: catalog/internal/plugins/mcp/plugin.go:135]
- GET /api/serving_runtime_catalog/v1/serving_runtimes/{id}/logo on port ; transport=HTTP/1.1 encryption= auth= owner=catalog/internal/plugins/serving_runtime [source: catalog/internal/plugins/serving_runtime/plugin.go:121]
- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=catalog/internal/plugin [source: catalog/internal/plugin/server.go:169]
- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: cmd/controller/main.go:160]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=catalog/internal/plugin [source: catalog/internal/plugin/server.go:170]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: cmd/controller/main.go:164]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=internal/api [source: clients/ui/bff/internal/api/app.go:379]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=internal/api [source: clients/ui/bff/internal/api/app.go:403]
### integrations

- KServe InferenceService interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read model serving state [source: manifests/kustomize/options/controller/rbac/role.yaml:2]
### internal_dependencies

- KServe InferenceService interaction=CRD Watch role=runtime-integration purpose=Read model serving state [source: manifests/kustomize/options/controller/rbac/role.yaml:2]
- KServe InferenceService interaction=Controller watch (conditional) role=runtime-integration purpose=Read model serving state [source: cmd/controller/internal/controllers/inferenceservice_controller.go:44]
- KServe InferenceService interaction=Controller watch role=runtime-integration purpose=Read model serving state [source: pkg/inferenceservice-controller/controller.go:251]
### services

- controller-controller-manager-metrics-service port=8443 target=8443 protocol=TCP encryption= auth= [source: manifests/kustomize/options/controller/default/metrics_service.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload controller-controller-manager uses service account controller-controller-manager and 1 container(s) [source: manifests/kustomize/options/controller/default/manager_metrics_patch.yaml:1]
- **observed**: Service controller-controller-manager-metrics-service targets controller-controller-manager with 1 port(s) [source: manifests/kustomize/options/controller/default/metrics_service.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /api/mcp_catalog/v1alpha1/mcp_servers/{server_id}/logo is owned by catalog/internal/plugins/mcp [source: catalog/internal/plugins/mcp/plugin.go:135]
- **observed**: HTTP GET /api/serving_runtime_catalog/v1/serving_runtimes/{id}/logo is owned by catalog/internal/plugins/serving_runtime [source: catalog/internal/plugins/serving_runtime/plugin.go:121]
- **observed**: HTTP GET /healthz is owned by catalog/internal/plugin [source: catalog/internal/plugin/server.go:169]
- **observed**: HTTP GET /healthz is owned by main [source: cmd/controller/main.go:160]
- **observed**: HTTP GET /readyz is owned by catalog/internal/plugin [source: catalog/internal/plugin/server.go:170]
- **observed**: HTTP GET /readyz is owned by main [source: cmd/controller/main.go:164]
- **observed**: HTTP Unknown / is owned by internal/api [source: clients/ui/bff/internal/api/app.go:379]
- **observed**: VirtualService model-catalog serves host * via plaintext; backend=model-catalog.kubeflow.svc.cluster.local; transport=HTTP [source: manifests/kustomize/options/catalog/options/istio/virtual-service.yaml:1]
- **observed**: VirtualService model-registry serves host * via plaintext; backend=model-registry-service.kubeflow.svc.cluster.local; transport=HTTP [source: manifests/kustomize/options/istio/virtual-service.yaml:1]
- **observed**: VirtualService model-registry-ui serves host * via plaintext; backend=model-registry-ui-service.kubeflow.svc.cluster.local; transport=HTTP [source: manifests/kustomize/options/ui/overlays/istio/virtual-service.yaml:1]
### security

- **observed**: ALL /api/v1/* uses Bearer Token (Authorization header) or internal ServiceAccount token at Go BFF authentication configuration; policy=auth-method flag accepts internal or user_token; token header and Bearer prefix are configurable [source: clients/ui/bff/cmd/main.go:56]
- **observed**: GET /api/model_registry/* uses Istio source namespace + Istio source principal + Kubernetes JWT (Authorization header) at Istio sidecar proxy AuthorizationPolicy; policy=Istio AuthorizationPolicy for component=model-registry-server; action=ALLOW; allows namespaces: kubeflow; allows principals: cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account; blocks request.headers[kubeflow-userid]; requires request.headers[authorization] [source: manifests/kustomize/options/istio/istio-authorization-policy.yaml:1]
- **observed**: GET /model-registry/* uses Istio source principal at Istio sidecar proxy AuthorizationPolicy; policy=Istio AuthorizationPolicy for app=model-registry-ui; action=ALLOW; allows principals: cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account [source: manifests/kustomize/options/ui/overlays/istio/authorization-policy-ui.yaml:1]
- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: cmd/controller/main.go:160]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/controller/main.go:164]
- **observed**: GET :8443/metrics uses TokenReview + SubjectAccessReview (controller-runtime authn/authz filter) at controller-runtime metrics authn/authz filter; policy=RBAC via controller-metrics-auth-role; exposed by Service controller-controller-manager-metrics-service; controller-runtime generated self-signed TLS certificate [source: cmd/controller/main.go:104]
- **observed**: Istio AuthorizationPolicy model-registry-service applies authentication Istio source namespace, Istio source principal, Kubernetes JWT (Authorization header) [source: manifests/kustomize/options/istio/istio-authorization-policy.yaml:1]
- **observed**: Istio AuthorizationPolicy model-registry-ui applies authentication Istio source principal [source: manifests/kustomize/options/ui/overlays/istio/authorization-policy-ui.yaml:1]
- **observed**: RBAC role controller-leader-election-role grants 3 rule(s) [source: manifests/kustomize/options/controller/rbac/leader_election_role.yaml:2]
- **observed**: RBAC role controller-metrics-auth-role grants 2 rule(s) [source: manifests/kustomize/options/controller/rbac/metrics_auth_role.yaml:1]
- **observed**: RBAC role controller-metrics-reader grants 1 rule(s) [source: manifests/kustomize/options/controller/rbac/metrics_reader_role.yaml:1]
- **observed**: RBAC role controller-model-registry-manager-role grants 3 rule(s) [source: manifests/kustomize/options/controller/rbac/role.yaml:2]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via controller-model-registry-manager-role ClusterRole; SA controller-controller-manager [source: cmd/controller/main.go:114]
- **dependency-signal**: auth-middleware targets pyjwt: JWT/OAuth authentication library dependency [source: jobs/async-upload/requirements-aipcc.txt:222]
- **literal**: rbac-ref targets SelfSubjectAccessReviews: Token or subject access review call [source: clients/ui/bff/internal/integrations/kubernetes/token_k8s_client.go:109, clients/ui/bff/internal/integrations/kubernetes/token_k8s_client.go:139, clients/ui/bff/internal/integrations/kubernetes/token_k8s_client.go:220, clients/ui/bff/internal/integrations/kubernetes/token_k8s_client.go:42]
- **literal**: rbac-ref targets SubjectAccessReviews: Token or subject access review call [source: clients/ui/bff/internal/integrations/kubernetes/internal_k8s_client.go:129, clients/ui/bff/internal/integrations/kubernetes/internal_k8s_client.go:230, clients/ui/bff/internal/integrations/kubernetes/internal_k8s_client.go:65, clients/ui/bff/internal/integrations/kubernetes/internal_k8s_client.go:97, clients/ui/bff/internal/integrations/kubernetes/namespace_registry_access.go:46]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: clients/ui/bff/cmd/main.go, clients/ui/bff/internal/integrations/httpclient/http.go, cmd/controller/main.go, internal/platform/tls/config.go, pkg/inferenceservice-controller/controller.go]
- **dependency-signal**: tls-config targets cryptography: TLS/cryptography library dependency [source: jobs/async-upload/requirements-aipcc.txt:75]
- **dependency-signal**: tls-config targets pyopenssl: TLS/cryptography library dependency [source: jobs/async-upload/requirements-aipcc.txt:225]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
