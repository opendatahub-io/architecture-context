# Analyzer Synthesis Context: models-as-a-service

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 8 crds facts extracted [source: maas-controller/api/maas/v1alpha1/aitenant_types.go:49, maas-controller/api/maas/v1alpha1/config_types.go:40, maas-controller/api/maas/v1alpha1/externalmodel_types.go:34, maas-controller/api/maas/v1alpha1/maasauthpolicy_types.go:118, maas-controller/api/maas/v1alpha1/maasmodelref_types.go:32, maas-controller/api/maas/v1alpha1/maassubscription_types.go:153, maas-controller/api/maas/v1alpha1/maastenantconfig_types.go:40, maas-controller/api/maas/v1alpha1/tenant_types.go:42]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 18 http_endpoints facts extracted [source: maas-api/cmd/main.go:149, maas-api/cmd/main.go:231, maas-api/cmd/main.go:278, maas-api/cmd/main.go:282, maas-api/cmd/main.go:283, maas-api/cmd/main.go:291, maas-api/cmd/main.go:293, maas-api/cmd/main.go:294, maas-api/cmd/main.go:295, maas-api/cmd/main.go:298, maas-api/cmd/main.go:302, maas-api/cmd/main.go:308, maas-api/cmd/main.go:309, maas-api/cmd/main.go:310, maas-api/cmd/main.go:311, maas-api/internal/metrics/server.go:19, maas-controller/cmd/manager/main.go:1284, maas-controller/cmd/manager/main.go:1288]
- **services (observed)**: 1 services facts extracted [source: deployment/base/maas-api/core/service.yaml:1]
- **ingress (observed)**: 1 ingress facts extracted [source: deployment/base/maas-api/networking/httproute.yaml:1]
- **webhooks (observed)**: 4 webhooks facts extracted [source: maas-controller/pkg/webhook/aitenant_webhook.go:33, maas-controller/pkg/webhook/maasauthpolicy_webhook.go:33, maas-controller/pkg/webhook/maasmodelref_webhook.go:34, maas-controller/pkg/webhook/maassubscription_webhook.go:33]

## Deterministic Cross-References

- **controller**: AITenantReconciler —watches-reference→ api/maas/v1alpha1/AITenant; api/maas/v1alpha1/AITenant [source: maas-controller/cmd/manager/main.go:549, maas-controller/pkg/controller/maas/aitenant_controller.go:264]
- **controller**: AITenantReconciler —watches-reference→ api/maas/v1alpha1/MaasTenantConfig; api/maas/v1alpha1/MaasTenantConfig [source: maas-controller/pkg/controller/maas/aitenant_controller.go:267, maas-controller/pkg/controller/maas/aitenant_controller.go:753]
- **controller**: LifecycleReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: maas-controller/pkg/controller/maas/aitenant_controller.go:1243, maas-controller/pkg/controller/maas/self_deployment_controller.go:949]
- **controller**: LifecycleReconciler —watches-reference→ api/maas/v1alpha1/AITenant; api/maas/v1alpha1/AITenant [source: maas-controller/cmd/manager/main.go:549, maas-controller/pkg/controller/maas/self_deployment_controller.go:926]
- **controller**: LifecycleReconciler —watches-reference→ api/maas/v1alpha1/Config; api/maas/v1alpha1/Config [source: maas-controller/cmd/manager/main.go:537, maas-controller/pkg/controller/maas/self_deployment_controller.go:906]
- **controller**: LifecycleReconciler —watches-reference→ api/maas/v1alpha1/MaasTenantConfig; api/maas/v1alpha1/MaasTenantConfig [source: maas-controller/pkg/controller/maas/aitenant_controller.go:753, maas-controller/pkg/controller/maas/self_deployment_controller.go:916]
- **controller**: LifecycleReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: maas-controller/cmd/manager/main.go:474, maas-controller/pkg/controller/maas/self_deployment_controller.go:905]
- **controller**: MaaSAuthPolicyReconciler —watches-reference→ /v1/Namespace; /v1/Namespace [source: maas-controller/cmd/manager/main.go:183, maas-controller/pkg/controller/maas/maasauthpolicy_controller.go:2045]
- **controller**: MaaSAuthPolicyReconciler —watches-reference→ api/maas/v1alpha1/AITenant; api/maas/v1alpha1/AITenant [source: maas-controller/cmd/manager/main.go:549, maas-controller/pkg/controller/maas/maasauthpolicy_controller.go:2024]
- **controller**: MaaSAuthPolicyReconciler —watches-reference→ api/maas/v1alpha1/MaaSAuthPolicy; api/maas/v1alpha1/MaaSAuthPolicy [source: maas-controller/pkg/controller/maas/helpers.go:63, maas-controller/pkg/controller/maas/maasauthpolicy_controller.go:2004]
- **controller**: MaaSAuthPolicyReconciler —watches-reference→ api/maas/v1alpha1/MaaSModelRef; api/maas/v1alpha1/MaaSModelRef [source: maas-controller/pkg/controller/maas/maasauthpolicy_controller.go:2014, maas-controller/pkg/controller/maas/maasauthpolicy_controller.go:693]
- **controller**: MaaSAuthPolicyReconciler —watches-reference→ gateway.networking.k8s.io/v1/HTTPRoute; gateway.networking.k8s.io/v1/HTTPRoute [source: maas-controller/pkg/controller/maas/helpers.go:295, maas-controller/pkg/controller/maas/maasauthpolicy_controller.go:2010]
- **controller**: MaaSModelRefReconciler —watches-reference→ api/maas/v1alpha1/MaaSAuthPolicy; api/maas/v1alpha1/MaaSAuthPolicy [source: maas-controller/pkg/controller/maas/helpers.go:63, maas-controller/pkg/controller/maas/maasmodelref_controller.go:539]
- **controller**: MaaSModelRefReconciler —watches-reference→ api/maas/v1alpha1/MaaSModelRef; api/maas/v1alpha1/MaaSModelRef [source: maas-controller/pkg/controller/maas/maasauthpolicy_controller.go:693, maas-controller/pkg/controller/maas/maasmodelref_controller.go:507]
- **controller**: MaaSModelRefReconciler —watches-reference→ api/maas/v1alpha1/MaaSSubscription; api/maas/v1alpha1/MaaSSubscription [source: maas-controller/pkg/controller/maas/helpers.go:45, maas-controller/pkg/controller/maas/maasmodelref_controller.go:535]
- **controller**: MaaSModelRefReconciler —watches-reference→ gateway.networking.k8s.io/v1/HTTPRoute; gateway.networking.k8s.io/v1/HTTPRoute [source: maas-controller/pkg/controller/maas/helpers.go:295, maas-controller/pkg/controller/maas/maasmodelref_controller.go:513]
- **controller**: MaaSSubscriptionReconciler —watches-reference→ /v1/Namespace; /v1/Namespace [source: maas-controller/cmd/manager/main.go:183, maas-controller/pkg/controller/maas/maassubscription_controller.go:1119]
- **controller**: MaaSSubscriptionReconciler —watches-reference→ api/maas/v1alpha1/AITenant; api/maas/v1alpha1/AITenant [source: maas-controller/cmd/manager/main.go:549, maas-controller/pkg/controller/maas/maassubscription_controller.go:1098]
- **controller**: MaaSSubscriptionReconciler —watches-reference→ api/maas/v1alpha1/MaaSModelRef; api/maas/v1alpha1/MaaSModelRef [source: maas-controller/pkg/controller/maas/maasauthpolicy_controller.go:693, maas-controller/pkg/controller/maas/maassubscription_controller.go:1093]
- **controller**: MaaSSubscriptionReconciler —watches-reference→ api/maas/v1alpha1/MaaSSubscription; api/maas/v1alpha1/MaaSSubscription [source: maas-controller/pkg/controller/maas/helpers.go:45, maas-controller/pkg/controller/maas/maassubscription_controller.go:1076]
- **controller**: MaaSSubscriptionReconciler —watches-reference→ gateway.networking.k8s.io/v1/HTTPRoute; gateway.networking.k8s.io/v1/HTTPRoute [source: maas-controller/pkg/controller/maas/helpers.go:295, maas-controller/pkg/controller/maas/maassubscription_controller.go:1089]
- **controller**: Reconciler —watches-reference→ api/maas/v1alpha1/ExternalModel; api/maas/v1alpha1/ExternalModel [source: maas-controller/pkg/controller/maas/providers_external.go:98, maas-controller/pkg/reconciler/externalmodel/reconciler.go:319]
- **controller**: TenantReconciler —watches-reference→ /v1/Secret; /v1/Secret [source: maas-controller/cmd/manager/main.go:357, maas-controller/pkg/controller/maas/tenant_controller.go:247]
- **controller**: TenantReconciler —watches-reference→ api/maas/v1alpha1/AITenant; api/maas/v1alpha1/AITenant [source: maas-controller/cmd/manager/main.go:549, maas-controller/pkg/controller/maas/tenant_controller.go:238]
- **controller**: TenantReconciler —watches-reference→ api/maas/v1alpha1/Config; api/maas/v1alpha1/Config [source: maas-controller/cmd/manager/main.go:537, maas-controller/pkg/controller/maas/tenant_controller.go:228]
- **controller**: TenantReconciler —watches-reference→ api/maas/v1alpha1/MaasTenantConfig; api/maas/v1alpha1/MaasTenantConfig [source: maas-controller/pkg/controller/maas/aitenant_controller.go:753, maas-controller/pkg/controller/maas/tenant_controller.go:227]
- **security**: Unknown /metrics —protected-by→ Unknown; Application (maas-api): Dedicated metrics listener on port 9090; authentication not established by source [source: deployment/base/maas-api/core/deployment.yaml:1, maas-api/internal/metrics/server.go:19]

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `deployment/base/maas-api/core/deployment.yaml`:1 (:8080/health, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `deployment/base/maas-api/rbac/clusterrole.yaml`:1 (Named Secret access (maas-db-config), RBAC with resourceNames restriction)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `deployment/base/maas-api/rbac/supplemental-clusterrole.yaml`:10 (Named Secret access (maas-db-config), RBAC with resourceNames restriction)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `maas-api/internal/auth/tenant_auth_middleware.go`:20 (Kubernetes TokenReview API, Token validation)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `maas-api/internal/config/cluster_config.go`:216 (Kubernetes API, kubeconfig credential chain)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `maas-controller/cmd/manager/main.go`:1284 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `maas-controller/pkg/controller/maas/maasauthpolicy_controller.go`:1069 (/v1/models, /v1/subscriptions, /v1/api-keys/*, /maas-api/*, API key + Kubernetes TokenReview + OIDC JWT (optional))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `maas-controller/pkg/webhook/aitenant_webhook.go`:33 (Kubernetes admission, Operator webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `deployment/base/maas-api/rbac/clusterrole.yaml`:1 (maas-api)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `deployment/base/maas-api/rbac/clusterrolebinding.yaml`:1 (maas-api)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `deployment/base/maas-api/rbac/supplemental-clusterrole.yaml`:10 (maas-api-supplemental)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `deployment/base/maas-api/rbac/supplemental-clusterrolebinding.yaml`:1 (maas-api-supplemental)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `maas-api/Dockerfile`:36 (maas-api/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `maas-api/Dockerfile.konflux`:35 (maas-api/Dockerfile.konflux:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `maas-api/cmd/main.go`:39 (cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `maas-controller/Dockerfile`:38 (maas-controller/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `maas-controller/Dockerfile.konflux`:37 (maas-controller/Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `maas-controller/cmd/manager/main.go`:929 (manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `maas-api/internal/config/cluster_config.go`:100 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `maas-api/internal/tracing/provider.go`:32 (OTLP/gRPC trace exporter, OpenTelemetry Collector)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `maas-controller/cmd/manager/main.go`:1024 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `maas-controller/go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `maas-api/cmd/main.go`:149 (/*path, OPTIONS, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `maas-api/internal/metrics/server.go`:19 (/metrics, Unknown, internal/metrics)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `maas-controller/cmd/manager/main.go`:1284 (/healthz, GET, cmd/manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `deployment/base/maas-api/networking/httproute.yaml`:1 (Gateway API (data-science-gateway), HTTPRoute)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `deployment/base/maas-api/rbac/clusterrole.yaml`:1 (Gateway API, HTTPRoute CRUD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `maas-api/internal/tracing/provider.go`:32 (OpenTelemetry Collector, gRPC client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `deployment/base/maas-api/networking/httproute.yaml`:1 (Gateway API (data-science-gateway), HTTPRoute)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `deployment/base/maas-api/rbac/clusterrole.yaml`:1 (CRD CRUD, Gateway API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `maas-api/internal/auth/tenant_auth_middleware.go`:44 (authentication/v1/TokenReview, create operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `maas-controller/cmd/manager/main.go`:183 (/v1/Namespace, create, get, patch operations by AITenantReconciler, LifecycleReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `maas-controller/pkg/controller/maas/aitenant_controller.go`:1243 (/v1/ConfigMap, create, delete, get, list, update operations by AITenantReconciler, TenantReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `maas-controller/pkg/controller/maas/helpers.go`:63 (api/maas/v1alpha1/MaaSAuthPolicy, get, list, update operations by MaaSAuthPolicyReconciler, TenantReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `maas-controller/pkg/controller/maas/helpers.go`:295 (Gateway API, HTTPRoute CRUD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `maas-controller/pkg/controller/maas/maasauthpolicy_controller.go`:693 (api/maas/v1alpha1/MaaSModelRef, get, list, update operations by MaaSAuthPolicyReconciler, MaaSModelRefReconciler, MaaSSubscriptionReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `maas-controller/pkg/controller/maas/maasauthpolicy_controller.go`:2010 (Controller watch, Gateway API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `maas-controller/pkg/controller/maas/maasmodelref_controller.go`:523 (Controller watch (conditional), KServe InferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `maas-controller/pkg/controller/maas/providers_external.go`:98 (api/maas/v1alpha1/ExternalModel, get operations by Reconciler, externalModelHandler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `maas-controller/pkg/controller/maas/tenant_reconcile.go`:537 (/v1/Service, create, delete, get, update operations by Reconciler, TenantReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `maas-controller/cmd/manager/main.go`:183 (/v1/Namespace, create, get, patch operations by AITenantReconciler, LifecycleReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `maas-controller/pkg/controller/maas/aitenant_controller.go`:1243 (/v1/ConfigMap, create, delete, get, list, update operations by AITenantReconciler, TenantReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `maas-controller/pkg/controller/maas/aitenant_controller.go`:264 (AITenantReconciler, api/maas/v1alpha1/AITenant)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `maas-controller/pkg/controller/maas/helpers.go`:63 (api/maas/v1alpha1/MaaSAuthPolicy, get, list, update operations by MaaSAuthPolicyReconciler, TenantReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `maas-controller/pkg/controller/maas/maasauthpolicy_controller.go`:2045 (/v1/Namespace, MaaSAuthPolicyReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `maas-controller/pkg/controller/maas/maasmodelref_controller.go`:539 (MaaSModelRefReconciler, api/maas/v1alpha1/MaaSAuthPolicy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `maas-controller/pkg/controller/maas/maassubscription_controller.go`:1119 (/v1/Namespace, MaaSSubscriptionReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `maas-controller/pkg/controller/maas/providers_external.go`:98 (api/maas/v1alpha1/ExternalModel, get operations by Reconciler, externalModelHandler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `maas-controller/pkg/controller/maas/self_deployment_controller.go`:949 (/v1/ConfigMap, LifecycleReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `maas-controller/pkg/controller/maas/tenant_controller.go`:247 (/v1/Secret, TenantReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `maas-controller/pkg/controller/maas/tenant_reconcile.go`:537 (/v1/Service, create, delete, get, update operations by Reconciler, TenantReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `maas-controller/pkg/reconciler/externalmodel/reconciler.go`:319 (Reconciler, api/maas/v1alpha1/ExternalModel)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `deployment/base/maas-api/core/deployment.yaml`:1 (maas-api)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `deployment/base/maas-api/core/service.yaml`:1 (maas-api)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### webhooks

- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `maas-controller/pkg/webhook/aitenant_webhook.go`:33 (/validate-maas-opendatahub-io-v1alpha1-aitenant, vaitenant.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `maas-controller/pkg/webhook/maasauthpolicy_webhook.go`:33 (/validate-maas-opendatahub-io-v1alpha1-maasauthpolicy, vmaasauthpolicy.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `maas-controller/pkg/webhook/maasmodelref_webhook.go`:34 (/validate-maas-opendatahub-io-v1alpha1-maasmodelref, vmaasmodelref.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `maas-controller/pkg/webhook/maassubscription_webhook.go`:33 (/validate-maas-opendatahub-io-v1alpha1-maassubscription, vmaassubscription.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- /metrics methods=Unknown mechanism=Unknown enforcement=Application (maas-api) policy=Dedicated metrics listener on port 9090; authentication not established by source [source: deployment/base/maas-api/core/deployment.yaml:1]
- /v1/models, /v1/subscriptions, /v1/api-keys/*, /maas-api/* methods=GET, POST, DELETE, OPTIONS mechanism=API key + Kubernetes TokenReview + OIDC JWT (optional) enforcement=Kuadrant/Authorino Gateway AuthPolicy policy=Gateway policy authenticates requests and applies policy-defined authorization rules; excludes GET /maas-api/health [source: maas-controller/pkg/controller/maas/maasauthpolicy_controller.go:1069]
- :8080/health methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes liveness probe endpoint [source: deployment/base/maas-api/core/deployment.yaml:1]
- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: maas-controller/cmd/manager/main.go:1284]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: maas-controller/cmd/manager/main.go:1288]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via maas-api ClusterRole; SA maas-api [source: maas-api/internal/config/cluster_config.go:100]
- Kubernetes API methods=REST mechanism=kubeconfig credential chain enforcement=kube-apiserver policy=Kubeconfig-based authentication using user-provided credentials [source: maas-api/internal/config/cluster_config.go:216]
- Named Secret access (maas-db-config) methods=Kubernetes API mechanism=RBAC with resourceNames restriction enforcement=kube-apiserver policy=maas-api restricts secret access to maas-db-config only [source: deployment/base/maas-api/rbac/clusterrole.yaml:1]
- Named Secret access (maas-db-config) methods=Kubernetes API mechanism=RBAC with resourceNames restriction enforcement=kube-apiserver policy=maas-api-supplemental restricts secret access to maas-db-config only [source: deployment/base/maas-api/rbac/supplemental-clusterrole.yaml:10]
- Operator webhook methods=CREATE mechanism=Kubernetes admission enforcement=ValidatingWebhookConfiguration policy=Admission validation [source: maas-controller/pkg/webhook/aitenant_webhook.go:33]
- Token validation methods=Kubernetes TokenReview API mechanism=Kubernetes TokenReview API enforcement=Application-level token validation via kube-apiserver policy=Validates bearer tokens against Kubernetes TokenReview API [source: maas-api/internal/auth/tenant_auth_middleware.go:20]
### http_endpoints

- DELETE /:id on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:295]
- DELETE /tenants/:tenant/api-keys on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:310]
- GET /:id on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:294]
- GET /config on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:291]
- GET /health on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:231]
- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/manager [source: maas-controller/cmd/manager/main.go:1284]
- GET /model/:model-id/subscriptions on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:283]
- GET /models on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:278]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/manager [source: maas-controller/cmd/manager/main.go:1288]
- GET /subscriptions on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:282]
- GET /tenants on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:302]
- OPTIONS /*path on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:149]
- POST /api-keys/cleanup on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:309]
- POST /api-keys/search on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:298]
- POST /api-keys/validate on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:308]
- POST /bulk-revoke on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:293]
- POST /subscriptions/select on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:311]
- Unknown /metrics on port ; transport=HTTP/1.1 encryption= auth= owner=internal/metrics [source: maas-api/internal/metrics/server.go:19]
### integrations

- Gateway API (data-science-gateway) interaction=HTTPRoute role=runtime-transport protocol=HTTPS purpose=External dashboard ingress [source: deployment/base/maas-api/networking/httproute.yaml:1]
- Gateway API interaction=HTTPRoute CRUD role=runtime-transport protocol=HTTPS purpose=Manage Gateway API routing resources [source: deployment/base/maas-api/rbac/clusterrole.yaml:1]
- OpenTelemetry Collector interaction=gRPC client role=runtime-integration protocol=OTLP/gRPC purpose=Runtime trace export [source: maas-api/internal/tracing/provider.go:32]
### internal_dependencies

- Gateway API (data-science-gateway) interaction=HTTPRoute role=runtime-transport purpose=Platform ingress through Gateway API [source: deployment/base/maas-api/networking/httproute.yaml:1]
- Gateway API interaction=CRD CRUD role=unknown purpose=Manage Gateway API routing resources [source: deployment/base/maas-api/rbac/clusterrole.yaml:1]
- Gateway API interaction=Controller watch role=runtime-integration purpose=Manage Gateway API routing resources [source: maas-controller/pkg/controller/maas/maasauthpolicy_controller.go:2010]
- Gateway API interaction=HTTPRoute CRUD role=runtime-transport purpose=Reconcile HTTPRoute resources against a configured Gateway [source: maas-controller/pkg/controller/maas/helpers.go:295]
- KServe InferenceService interaction=Controller watch (conditional) role=runtime-integration purpose=Read model serving state [source: maas-controller/pkg/controller/maas/maasmodelref_controller.go:523]
### services

- maas-api port=8080 target=http protocol=TCP encryption= auth= [source: deployment/base/maas-api/core/service.yaml:1]
- maas-api port=9090 target=metrics protocol=TCP encryption= auth= [source: deployment/base/maas-api/core/service.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload maas-api uses service account maas-api and 1 container(s) [source: deployment/base/maas-api/core/deployment.yaml:1]
- **observed**: Service maas-api targets  with 2 port(s) [source: deployment/base/maas-api/core/service.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP DELETE /:id is owned by cmd [source: maas-api/cmd/main.go:295]
- **observed**: HTTP DELETE /tenants/:tenant/api-keys is owned by cmd [source: maas-api/cmd/main.go:310]
- **observed**: HTTP GET /:id is owned by cmd [source: maas-api/cmd/main.go:294]
- **observed**: HTTP GET /config is owned by cmd [source: maas-api/cmd/main.go:291]
- **observed**: HTTP GET /health is owned by cmd [source: maas-api/cmd/main.go:231]
- **observed**: HTTP GET /healthz is owned by cmd/manager [source: maas-controller/cmd/manager/main.go:1284]
- **observed**: HTTP GET /model/:model-id/subscriptions is owned by cmd [source: maas-api/cmd/main.go:283]
- **observed**: HTTP GET /models is owned by cmd [source: maas-api/cmd/main.go:278]
- **observed**: HTTP GET /readyz is owned by cmd/manager [source: maas-controller/cmd/manager/main.go:1288]
- **observed**: HTTP GET /subscriptions is owned by cmd [source: maas-api/cmd/main.go:282]
- **observed**: HTTP GET /tenants is owned by cmd [source: maas-api/cmd/main.go:302]
- **observed**: HTTP OPTIONS /*path is owned by cmd [source: maas-api/cmd/main.go:149]
- **observed**: HTTP POST /api-keys/cleanup is owned by cmd [source: maas-api/cmd/main.go:309]
- **observed**: HTTP POST /api-keys/search is owned by cmd [source: maas-api/cmd/main.go:298]
- **observed**: HTTP POST /api-keys/validate is owned by cmd [source: maas-api/cmd/main.go:308]
- **observed**: HTTP POST /bulk-revoke is owned by cmd [source: maas-api/cmd/main.go:293]
- **observed**: HTTP POST /subscriptions/select is owned by cmd [source: maas-api/cmd/main.go:311]
- **observed**: HTTP Unknown /metrics is owned by internal/metrics [source: maas-api/internal/metrics/server.go:19]
- **observed**: HTTPRoute maas-api-route serves host  via plaintext; backend=maas-api; transport=Unknown [source: deployment/base/maas-api/networking/httproute.yaml:1]
### security

- **observed**: CREATE Operator webhook uses Kubernetes admission at ValidatingWebhookConfiguration; policy=Admission validation [source: maas-controller/pkg/webhook/aitenant_webhook.go:33]
- **observed**: GET :8080/health uses None at N/A; policy=Unauthenticated Kubernetes liveness probe endpoint [source: deployment/base/maas-api/core/deployment.yaml:1]
- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: maas-controller/cmd/manager/main.go:1284]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: maas-controller/cmd/manager/main.go:1288]
- **observed**: GET, POST, DELETE, OPTIONS /v1/models, /v1/subscriptions, /v1/api-keys/*, /maas-api/* uses API key + Kubernetes TokenReview + OIDC JWT (optional) at Kuadrant/Authorino Gateway AuthPolicy; policy=Gateway policy authenticates requests and applies policy-defined authorization rules; excludes GET /maas-api/health [source: maas-controller/pkg/controller/maas/maasauthpolicy_controller.go:1069]
- **observed**: Kuadrant AuthPolicy controller-created Gateway AuthPolicy applies authentication API key, Kubernetes TokenReview, OIDC JWT (optional) [source: maas-controller/pkg/controller/maas/maasauthpolicy_controller.go:1069]
- **observed**: Kubernetes API Named Secret access (maas-db-config) uses RBAC with resourceNames restriction at kube-apiserver; policy=maas-api restricts secret access to maas-db-config only [source: deployment/base/maas-api/rbac/clusterrole.yaml:1]
- **observed**: Kubernetes API Named Secret access (maas-db-config) uses RBAC with resourceNames restriction at kube-apiserver; policy=maas-api-supplemental restricts secret access to maas-db-config only [source: deployment/base/maas-api/rbac/supplemental-clusterrole.yaml:10]
- **observed**: Kubernetes TokenReview API Token validation uses Kubernetes TokenReview API at Application-level token validation via kube-apiserver; policy=Validates bearer tokens against Kubernetes TokenReview API [source: maas-api/internal/auth/tenant_auth_middleware.go:20]
- **observed**: RBAC role maas-api grants 11 rule(s) [source: deployment/base/maas-api/rbac/clusterrole.yaml:1]
- **observed**: RBAC role maas-api-supplemental grants 5 rule(s) [source: deployment/base/maas-api/rbac/supplemental-clusterrole.yaml:10]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via maas-api ClusterRole; SA maas-api [source: maas-api/internal/config/cluster_config.go:100]
- **observed**: REST Kubernetes API uses kubeconfig credential chain at kube-apiserver; policy=Kubeconfig-based authentication using user-provided credentials [source: maas-api/internal/config/cluster_config.go:216]
- **observed**: Unknown /metrics uses Unknown at Application (maas-api); policy=Dedicated metrics listener on port 9090; authentication not established by source [source: deployment/base/maas-api/core/deployment.yaml:1]
- **literal**: rbac-ref targets SubjectAccessReviews: Token or subject access review call [source: maas-api/internal/auth/sar_admin_checker.go:58, maas-api/internal/auth/tenant_auth_middleware.go:90]
- **literal**: rbac-ref targets TokenReviews: Token or subject access review call [source: maas-api/internal/auth/tenant_auth_middleware.go:44]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: maas-api/cmd/main.go, maas-api/cmd/server.go, maas-api/internal/cert/cert.go, maas-api/internal/config/tls.go, maas-api/internal/models/discovery.go, maas-api/internal/tlsprofile/config.go, maas-api/internal/tlsprofile/profile.go, maas-controller/cmd/manager/main.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
