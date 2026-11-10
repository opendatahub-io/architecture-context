# Analyzer Synthesis Context: models-as-a-service

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 8 crds facts extracted [source: maas-controller/api/maas/v1alpha1/aitenant_types.go:53, maas-controller/api/maas/v1alpha1/config_types.go:60, maas-controller/api/maas/v1alpha1/externalmodel_types.go:34, maas-controller/api/maas/v1alpha1/maasauthpolicy_types.go:119, maas-controller/api/maas/v1alpha1/maasmodelref_types.go:32, maas-controller/api/maas/v1alpha1/maassubscription_types.go:318, maas-controller/api/maas/v1alpha1/maastenantconfig_types.go:40, maas-controller/api/maas/v1alpha1/tenant_types.go:43]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 27 http_endpoints facts extracted [source: maas-api/cmd/main.go:171, maas-api/cmd/main.go:265, maas-api/cmd/main.go:268, maas-api/cmd/main.go:335, maas-api/cmd/main.go:349, maas-api/cmd/main.go:353, maas-api/cmd/main.go:354, maas-api/cmd/main.go:366, maas-api/cmd/main.go:368, maas-api/cmd/main.go:369, maas-api/cmd/main.go:370, maas-api/cmd/main.go:373, maas-api/cmd/main.go:377, maas-api/cmd/main.go:386, maas-api/cmd/main.go:388, maas-api/cmd/main.go:389, maas-api/cmd/main.go:390, maas-api/cmd/main.go:391, maas-api/internal/lokiproxy/handler.go:97, maas-api/internal/lokiproxy/handler.go:98, maas-api/internal/lokiproxy/handler.go:99, maas-api/internal/metrics/server.go:87, maas-controller/cmd/manager/main.go:1461, maas-controller/cmd/manager/main.go:1465, maas-discovery/internal/handler/handler.go:83, maas-discovery/internal/handler/handler.go:84, maas-discovery/internal/handler/handler.go:85]
- **services (observed)**: 2 services facts extracted [source: deployment/base/maas-api/core/metrics_service.yaml:4, deployment/base/maas-api/core/service.yaml:1]
- **ingress (observed)**: 1 ingress facts extracted [source: deployment/base/maas-api/networking/httproute.yaml:1]
- **webhooks (observed)**: 5 webhooks facts extracted [source: maas-controller/pkg/webhook/aitenant_webhook.go:32, maas-controller/pkg/webhook/externalmodel_webhook.go:35, maas-controller/pkg/webhook/maasauthpolicy_webhook.go:32, maas-controller/pkg/webhook/maasmodelref_webhook.go:33, maas-controller/pkg/webhook/maassubscription_webhook.go:39]

## Deterministic Cross-References

- **controller**: AITenantReconciler —watches-reference→ api/maas/v1alpha1/AITenant; api/maas/v1alpha1/AITenant [source: maas-controller/cmd/manager/main.go:655, maas-controller/pkg/controller/maas/aitenant_controller.go:319]
- **controller**: AITenantReconciler —watches-reference→ api/maas/v1alpha1/MaasTenantConfig; api/maas/v1alpha1/MaasTenantConfig [source: maas-controller/pkg/controller/maas/aitenant_controller.go:1271, maas-controller/pkg/controller/maas/aitenant_controller.go:325]
- **controller**: AITenantReconciler —watches-reference→ gateway.networking.k8s.io/v1/Gateway; gateway.networking.k8s.io/v1/Gateway [source: maas-controller/pkg/controller/maas/aitenant_controller.go:329, maas-controller/pkg/controller/maas/providers_external.go:400]
- **controller**: LifecycleReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: maas-controller/pkg/controller/maas/aitenant_controller.go:1828, maas-controller/pkg/controller/maas/self_deployment_controller.go:1226]
- **controller**: LifecycleReconciler —watches-reference→ api/maas/v1alpha1/AITenant; api/maas/v1alpha1/AITenant [source: maas-controller/cmd/manager/main.go:655, maas-controller/pkg/controller/maas/self_deployment_controller.go:1202]
- **controller**: LifecycleReconciler —watches-reference→ api/maas/v1alpha1/Config; api/maas/v1alpha1/Config [source: maas-controller/cmd/manager/main.go:643, maas-controller/pkg/controller/maas/self_deployment_controller.go:1182]
- **controller**: LifecycleReconciler —watches-reference→ api/maas/v1alpha1/MaasTenantConfig; api/maas/v1alpha1/MaasTenantConfig [source: maas-controller/pkg/controller/maas/aitenant_controller.go:1271, maas-controller/pkg/controller/maas/self_deployment_controller.go:1192]
- **controller**: LifecycleReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: maas-controller/cmd/manager/main.go:580, maas-controller/pkg/controller/maas/self_deployment_controller.go:1181]
- **controller**: MaaSAuthPolicyReconciler —watches-reference→ /v1/Namespace; /v1/Namespace [source: maas-controller/cmd/manager/main.go:193, maas-controller/pkg/controller/maas/maasauthpolicy_controller.go:2474]
- **controller**: MaaSAuthPolicyReconciler —watches-reference→ api/maas/v1alpha1/AITenant; api/maas/v1alpha1/AITenant [source: maas-controller/cmd/manager/main.go:655, maas-controller/pkg/controller/maas/maasauthpolicy_controller.go:2420]
- **controller**: MaaSAuthPolicyReconciler —watches-reference→ api/maas/v1alpha1/MaaSAuthPolicy; api/maas/v1alpha1/MaaSAuthPolicy [source: maas-controller/pkg/controller/maas/guardrail_watch.go:60, maas-controller/pkg/controller/maas/maasauthpolicy_controller.go:2400]
- **controller**: MaaSAuthPolicyReconciler —watches-reference→ api/maas/v1alpha1/MaaSModelRef; api/maas/v1alpha1/MaaSModelRef [source: maas-controller/pkg/controller/maas/guardrail_headers.go:122, maas-controller/pkg/controller/maas/maasauthpolicy_controller.go:2410]
- **controller**: MaaSAuthPolicyReconciler —watches-reference→ api/maas/v1alpha1/MaaSSubscription; api/maas/v1alpha1/MaaSSubscription [source: maas-controller/pkg/controller/maas/guardrail_headers.go:112, maas-controller/pkg/controller/maas/maasauthpolicy_controller.go:2433]
- **controller**: MaaSAuthPolicyReconciler —watches-reference→ api/maas/v1alpha1/MaasTenantConfig; api/maas/v1alpha1/MaasTenantConfig [source: maas-controller/pkg/controller/maas/aitenant_controller.go:1271, maas-controller/pkg/controller/maas/maasauthpolicy_controller.go:2426]
- **controller**: MaaSAuthPolicyReconciler —watches-reference→ gateway.networking.k8s.io/v1/HTTPRoute; gateway.networking.k8s.io/v1/HTTPRoute [source: maas-controller/pkg/controller/maas/helpers.go:360, maas-controller/pkg/controller/maas/maasauthpolicy_controller.go:2406]
- **controller**: MaaSModelRefReconciler —watches-reference→ api/maas/v1alpha1/AITenant; api/maas/v1alpha1/AITenant [source: maas-controller/cmd/manager/main.go:655, maas-controller/pkg/controller/maas/maasmodelref_controller.go:791]
- **controller**: MaaSModelRefReconciler —watches-reference→ api/maas/v1alpha1/MaaSAuthPolicy; api/maas/v1alpha1/MaaSAuthPolicy [source: maas-controller/pkg/controller/maas/guardrail_watch.go:60, maas-controller/pkg/controller/maas/maasmodelref_controller.go:785]
- **controller**: MaaSModelRefReconciler —watches-reference→ api/maas/v1alpha1/MaaSModelRef; api/maas/v1alpha1/MaaSModelRef [source: maas-controller/pkg/controller/maas/guardrail_headers.go:122, maas-controller/pkg/controller/maas/maasmodelref_controller.go:717]
- **controller**: MaaSModelRefReconciler —watches-reference→ api/maas/v1alpha1/MaaSSubscription; api/maas/v1alpha1/MaaSSubscription [source: maas-controller/pkg/controller/maas/guardrail_headers.go:112, maas-controller/pkg/controller/maas/maasmodelref_controller.go:781]
- **controller**: MaaSModelRefReconciler —watches-reference→ gateway.networking.k8s.io/v1/HTTPRoute; gateway.networking.k8s.io/v1/HTTPRoute [source: maas-controller/pkg/controller/maas/helpers.go:360, maas-controller/pkg/controller/maas/maasmodelref_controller.go:723]
- **controller**: MaaSSubscriptionReconciler —watches-reference→ /v1/Namespace; /v1/Namespace [source: maas-controller/cmd/manager/main.go:193, maas-controller/pkg/controller/maas/maassubscription_controller.go:1548]
- **controller**: MaaSSubscriptionReconciler —watches-reference→ api/maas/v1alpha1/AITenant; api/maas/v1alpha1/AITenant [source: maas-controller/cmd/manager/main.go:655, maas-controller/pkg/controller/maas/maassubscription_controller.go:1491]
- **controller**: MaaSSubscriptionReconciler —watches-reference→ api/maas/v1alpha1/MaaSModelRef; api/maas/v1alpha1/MaaSModelRef [source: maas-controller/pkg/controller/maas/guardrail_headers.go:122, maas-controller/pkg/controller/maas/maassubscription_controller.go:1486]
- **controller**: MaaSSubscriptionReconciler —watches-reference→ api/maas/v1alpha1/MaaSSubscription; api/maas/v1alpha1/MaaSSubscription [source: maas-controller/pkg/controller/maas/guardrail_headers.go:112, maas-controller/pkg/controller/maas/maassubscription_controller.go:1469]
- **controller**: MaaSSubscriptionReconciler —watches-reference→ api/maas/v1alpha1/MaasTenantConfig; api/maas/v1alpha1/MaasTenantConfig [source: maas-controller/pkg/controller/maas/aitenant_controller.go:1271, maas-controller/pkg/controller/maas/maassubscription_controller.go:1496]
- **controller**: MaaSSubscriptionReconciler —watches-reference→ api/maas/v1alpha1/Tenant; api/maas/v1alpha1/Tenant [source: maas-controller/cmd/manager/main.go:704, maas-controller/pkg/controller/maas/maassubscription_controller.go:1499]
- **controller**: MaaSSubscriptionReconciler —watches-reference→ gateway.networking.k8s.io/v1/HTTPRoute; gateway.networking.k8s.io/v1/HTTPRoute [source: maas-controller/pkg/controller/maas/helpers.go:360, maas-controller/pkg/controller/maas/maassubscription_controller.go:1482]
- **controller**: Reconciler —watches-reference→ api/maas/v1alpha1/ExternalModel; api/maas/v1alpha1/ExternalModel [source: maas-controller/pkg/controller/maas/providers_external.go:112, maas-controller/pkg/reconciler/externalmodel/reconciler.go:529]
- **controller**: TenantReconciler —watches-reference→ /v1/Secret; /v1/Secret [source: maas-controller/cmd/manager/main.go:447, maas-controller/pkg/controller/maas/tenant_controller.go:356]
- **controller**: TenantReconciler —watches-reference→ api/maas/v1alpha1/AITenant; api/maas/v1alpha1/AITenant [source: maas-controller/cmd/manager/main.go:655, maas-controller/pkg/controller/maas/tenant_controller.go:339]
- **controller**: TenantReconciler —watches-reference→ api/maas/v1alpha1/Config; api/maas/v1alpha1/Config [source: maas-controller/cmd/manager/main.go:643, maas-controller/pkg/controller/maas/tenant_controller.go:334]
- **controller**: TenantReconciler —watches-reference→ api/maas/v1alpha1/MaasTenantConfig; api/maas/v1alpha1/MaasTenantConfig [source: maas-controller/pkg/controller/maas/aitenant_controller.go:1271, maas-controller/pkg/controller/maas/tenant_controller.go:326]
- **controller**: TenantReconciler —watches-reference→ gateway.networking.k8s.io/v1/Gateway; gateway.networking.k8s.io/v1/Gateway [source: maas-controller/pkg/controller/maas/providers_external.go:400, maas-controller/pkg/controller/maas/tenant_controller.go:343]

## Behavioral Evidence

- **conditional-metrics-enforcement (unresolved)** controller-runtime metrics: controller-runtime metrics serving surface; limitations=The controller-runtime manager Metrics binding does not use one direct lexical options object with a stable SecureServing condition [source: maas-controller/cmd/manager/main.go:1278-1278]
- **named-watch-predicate (unresolved)** pkg/controller/maas.AITenantReconciler: gateway.networking.k8s.io/v1/Gateway; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: maas-controller/pkg/controller/maas/aitenant_controller.go:329-333]
- **named-watch-predicate (unresolved)** pkg/controller/maas.LifecycleReconciler: maas.opendatahub.io/v1alpha1/Config; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: maas-controller/pkg/controller/maas/self_deployment_controller.go:1182-1191]
- **named-watch-predicate (unresolved)** pkg/controller/maas.LifecycleReconciler: maas.opendatahub.io/v1alpha1/MaasTenantConfig; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: maas-controller/pkg/controller/maas/self_deployment_controller.go:1192-1201]
- **named-watch-predicate (unresolved)** pkg/controller/maas.LifecycleReconciler: maas.opendatahub.io/v1alpha1/AITenant; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: maas-controller/pkg/controller/maas/self_deployment_controller.go:1202-1211]
- **named-watch-predicate (unresolved)** pkg/controller/maas.LifecycleReconciler: /v1/ConfigMap; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: maas-controller/pkg/controller/maas/self_deployment_controller.go:1226-1238]
- **named-watch-predicate (unresolved)** pkg/controller/maas.LifecycleReconciler: rbac.authorization.k8s.io/v1/ClusterRoleBinding; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: maas-controller/pkg/controller/maas/self_deployment_controller.go:1239-1250]
- **named-watch-predicate (unresolved)** pkg/controller/maas.LifecycleReconciler: networking.k8s.io/v1/NetworkPolicy; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: maas-controller/pkg/controller/maas/self_deployment_controller.go:1251-1263]
- **named-watch-predicate (unresolved)** pkg/controller/maas.LifecycleReconciler: apps/v1/Deployment; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: maas-controller/pkg/controller/maas/self_deployment_controller.go:1265-1280]
- **named-watch-predicate (unresolved)** pkg/controller/maas.MaaSAuthPolicyReconciler: maas.opendatahub.io/v1alpha1/MaasTenantConfig; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: maas-controller/pkg/controller/maas/maasauthpolicy_controller.go:2426-2432]
- **named-watch-predicate (unresolved)** pkg/controller/maas.MaaSAuthPolicyReconciler: maas.opendatahub.io/v1alpha1/MaaSSubscription; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: maas-controller/pkg/controller/maas/maasauthpolicy_controller.go:2433-2439]
- **named-watch-predicate (unresolved)** pkg/controller/maas.MaaSAuthPolicyReconciler: /v1/Namespace; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: maas-controller/pkg/controller/maas/maasauthpolicy_controller.go:2474-2476]
- **named-watch-predicate (unresolved)** pkg/controller/maas.MaaSModelRefReconciler: gateway.networking.k8s.io/v1/HTTPRoute; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: maas-controller/pkg/controller/maas/maasmodelref_controller.go:723-725]
- **named-watch-predicate (unresolved)** pkg/controller/maas.MaaSModelRefReconciler: serving.kserve.io/v1alpha2/LLMInferenceService; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: maas-controller/pkg/controller/maas/maasmodelref_controller.go:760-763]
- **named-watch-predicate (unresolved)** pkg/controller/maas.MaaSSubscriptionReconciler: maas.opendatahub.io/v1alpha1/MaaSSubscription; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: maas-controller/pkg/controller/maas/maassubscription_controller.go:1475-1479]
- **named-watch-predicate (unresolved)** pkg/controller/maas.MaaSSubscriptionReconciler: gateway.networking.k8s.io/v1/HTTPRoute; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: maas-controller/pkg/controller/maas/maassubscription_controller.go:1482-1484]
- 9 additional behavioral records remain in the analyzer JSON.

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
  **Candidate:** `maas-api/internal/auth/cleanup_auth_middleware.go`:23 (Kubernetes TokenReview API, Token validation)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `maas-api/internal/config/cluster_config.go`:289 (Kubernetes API, kubeconfig credential chain)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `maas-api/internal/tlsprofile/fetch.go`:127 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Under which configuration branch does the metrics serving surface install authentication and authorization?
  **Expected signal:** a direct SecureServing condition and controller-runtime authn/authz FilterProvider assignment
  **Candidate:** `maas-controller/cmd/manager/main.go`:1278-1278 (controller-runtime metrics, controller-runtime metrics serving surface)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `maas-controller/cmd/manager/main.go`:1461 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `maas-controller/cmd/manager/main.go`:1465 (:8081/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `maas-controller/pkg/controller/maas/maasauthpolicy_controller.go`:1244 (/v1/models, /v1/subscriptions, /v1/api-keys/*, /maas-api/v1/*, /maas-api/health, /v1/me, API key + Kubernetes TokenReview + OIDC JWT (optional))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `maas-controller/pkg/webhook/aitenant_webhook.go`:32 (Kubernetes admission, Operator webhook)
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
  **Candidate:** `maas-api/Dockerfile.konflux`:33 (maas-api/Dockerfile.konflux:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `maas-api/cmd/main.go`:40 (cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `maas-controller/Dockerfile`:39 (maas-controller/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `maas-controller/Dockerfile.konflux`:36 (maas-controller/Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `maas-controller/cmd/manager/main.go`:1108 (manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `maas-discovery/Dockerfile`:35 (maas-discovery/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `maas-discovery/Dockerfile.konflux`:32 (maas-discovery/Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `maas-discovery/cmd/discovery/main.go`:39 (discovery)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `maas-api/go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `maas-api/internal/config/cluster_config.go`:117 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `maas-api/internal/config/cluster_config.go`:122 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `maas-api/internal/tlsprofile/fetch.go`:127 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `maas-api/internal/tracing/provider.go`:37 (OTLP/gRPC trace exporter, OpenTelemetry Collector)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `maas-controller/cmd/manager/main.go`:1213 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `maas-discovery/cmd/discovery/main.go`:102 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `maas-discovery/internal/cache/informer.go`:123 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `maas-discovery/internal/cache/informer.go`:832 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `maas-api/cmd/main.go`:171 (/*path, OPTIONS, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `maas-api/cmd/main.go`:265 (/health, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `maas-api/cmd/main.go`:268 (/health/database, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `maas-api/cmd/main.go`:366 (/config, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `maas-api/cmd/main.go`:368 (/bulk-revoke, POST, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `maas-api/cmd/main.go`:369 (/:id, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `maas-api/cmd/main.go`:370 (/:id, DELETE, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `maas-api/cmd/main.go`:373 (/api-keys/search, POST, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `maas-api/cmd/main.go`:386 (/api-keys/validate, POST, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `maas-api/cmd/main.go`:388 (/api-keys/cleanup, POST, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `maas-controller/cmd/manager/main.go`:1461 (/healthz, GET, cmd/manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `maas-discovery/internal/handler/handler.go`:84 (/healthz, GET, internal/handler)
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
  **Candidate:** `maas-api/internal/tracing/provider.go`:37 (OpenTelemetry Collector, gRPC client)
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
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `maas-api/internal/subscription/guardrail.go`:8 (Go library, ai-gateway-controller)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `maas-controller/cmd/manager/main.go`:193 (/v1/Namespace, create, get, patch operations by AITenantReconciler, LifecycleReconciler, MaaSAuthPolicyReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `maas-controller/cmd/manager/main.go`:34 (Go library, llm-d-router)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `maas-controller/cmd/manager/main.go`:447 (/v1/Secret, create, get operations by LifecycleReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `maas-controller/pkg/controller/maas/aitenant_controller.go`:1828 (/v1/ConfigMap, create, delete, get, list, update operations by AITenantReconciler, TenantReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `maas-controller/pkg/controller/maas/aitenant_controller.go`:329 (Controller watch, Gateway API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `maas-controller/pkg/controller/maas/helpers.go`:360 (Gateway API, HTTPRoute CRUD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `maas-controller/pkg/controller/maas/maasmodelref_controller.go`:760 (Controller watch (conditional), KServe InferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `maas-controller/pkg/controller/maas/tenant_reconcile.go`:682 (/v1/Service, create, delete, get, update operations by Reconciler, TenantReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `maas-controller/pkg/platform/tenantreconcile/pipeline.go`:878 (/v1/Pod, list operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `maas-controller/pkg/controller/maas/aitenant_controller.go`:329-333 (gateway.networking.k8s.io/v1/Gateway, pkg/controller/maas.AITenantReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `maas-controller/pkg/controller/maas/maasauthpolicy_controller.go`:2426-2432 (maas.opendatahub.io/v1alpha1/MaasTenantConfig, pkg/controller/maas.MaaSAuthPolicyReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `maas-controller/pkg/controller/maas/maasauthpolicy_controller.go`:2433-2439 (maas.opendatahub.io/v1alpha1/MaaSSubscription, pkg/controller/maas.MaaSAuthPolicyReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `maas-controller/pkg/controller/maas/maasauthpolicy_controller.go`:2474-2476 (/v1/Namespace, pkg/controller/maas.MaaSAuthPolicyReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `maas-controller/pkg/controller/maas/maasmodelref_controller.go`:723-725 (gateway.networking.k8s.io/v1/HTTPRoute, pkg/controller/maas.MaaSModelRefReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `maas-controller/pkg/controller/maas/maasmodelref_controller.go`:760-763 (pkg/controller/maas.MaaSModelRefReconciler, serving.kserve.io/v1alpha2/LLMInferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `maas-controller/pkg/controller/maas/maassubscription_controller.go`:1475-1479 (maas.opendatahub.io/v1alpha1/MaaSSubscription, pkg/controller/maas.MaaSSubscriptionReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `maas-controller/pkg/controller/maas/maassubscription_controller.go`:1482-1484 (gateway.networking.k8s.io/v1/HTTPRoute, pkg/controller/maas.MaaSSubscriptionReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `maas-controller/pkg/controller/maas/maassubscription_controller.go`:1496-1498 (maas.opendatahub.io/v1alpha1/MaasTenantConfig, pkg/controller/maas.MaaSSubscriptionReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `maas-controller/pkg/controller/maas/maassubscription_controller.go`:1499-1501 (maas.opendatahub.io/v1alpha1/Tenant, pkg/controller/maas.MaaSSubscriptionReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `maas-controller/pkg/controller/maas/maassubscription_controller.go`:1508-1511 (pkg/controller/maas.MaaSSubscriptionReconciler, serving.kserve.io/v1alpha2/LLMInferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `maas-controller/pkg/controller/maas/maassubscription_controller.go`:1520-1523 (apix/v1alpha2/InferenceObjective, pkg/controller/maas.MaaSSubscriptionReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- 12 additional gap candidates remain in the analyzer JSON.
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `deployment/base/maas-api/core/deployment.yaml`:1 (maas-api)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `deployment/base/maas-api/core/metrics_service.yaml`:4 (maas-api-metrics)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `deployment/base/maas-api/core/service.yaml`:1 (maas-api)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### webhooks

- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `maas-controller/pkg/webhook/aitenant_webhook.go`:32 (/validate-maas-opendatahub-io-v1alpha1-aitenant, vaitenant.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `maas-controller/pkg/webhook/externalmodel_webhook.go`:35 (/validate-maas-opendatahub-io-v1alpha1-externalmodel, vexternalmodel.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `maas-controller/pkg/webhook/maasauthpolicy_webhook.go`:32 (/validate-maas-opendatahub-io-v1alpha1-maasauthpolicy, vmaasauthpolicy.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `maas-controller/pkg/webhook/maasmodelref_webhook.go`:33 (/validate-maas-opendatahub-io-v1alpha1-maasmodelref, vmaasmodelref.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `maas-controller/pkg/webhook/maassubscription_webhook.go`:39 (/validate-maas-opendatahub-io-v1alpha1-maassubscription, vmaassubscription.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- /v1/models, /v1/subscriptions, /v1/api-keys/*, /maas-api/v1/*, /maas-api/health, /v1/me methods=GET, POST, DELETE, OPTIONS mechanism=API key + Kubernetes TokenReview + OIDC JWT (optional) enforcement=Kuadrant/Authorino Gateway AuthPolicy policy=Gateway policy authenticates requests and applies policy-defined authorization rules; excludes GET /maas-api/health [source: maas-controller/pkg/controller/maas/maasauthpolicy_controller.go:1244]
- :8080/health methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes liveness probe endpoint [source: deployment/base/maas-api/core/deployment.yaml:1]
- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: maas-controller/cmd/manager/main.go:1461]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: maas-controller/cmd/manager/main.go:1465]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via maas-api ClusterRole; SA maas-api [source: maas-api/internal/tlsprofile/fetch.go:127]
- Kubernetes API methods=REST mechanism=kubeconfig credential chain enforcement=kube-apiserver policy=Kubeconfig-based authentication using user-provided credentials [source: maas-api/internal/config/cluster_config.go:289]
- Named Secret access (maas-db-config) methods=Kubernetes API mechanism=RBAC with resourceNames restriction enforcement=kube-apiserver policy=maas-api restricts secret access to maas-db-config only [source: deployment/base/maas-api/rbac/clusterrole.yaml:1]
- Named Secret access (maas-db-config) methods=Kubernetes API mechanism=RBAC with resourceNames restriction enforcement=kube-apiserver policy=maas-api-supplemental restricts secret access to maas-db-config only [source: deployment/base/maas-api/rbac/supplemental-clusterrole.yaml:10]
- Operator webhook methods=CREATE mechanism=Kubernetes admission enforcement=ValidatingWebhookConfiguration policy=Admission validation [source: maas-controller/pkg/webhook/aitenant_webhook.go:32]
- Token validation methods=Kubernetes TokenReview API mechanism=Kubernetes TokenReview API enforcement=Application-level token validation via kube-apiserver policy=Validates bearer tokens against Kubernetes TokenReview API [source: maas-api/internal/auth/cleanup_auth_middleware.go:23]
### http_endpoints

- DELETE /:id on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:370]
- DELETE /tenants/:tenant/api-keys on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:389]
- DELETE /tenants/:tenant/subscriptions/:subscription/api-keys on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:390]
- GET /:id on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:369]
- GET /config on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:366]
- GET /health on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:265]
- GET /health/database on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:268]
- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/manager [source: maas-controller/cmd/manager/main.go:1461]
- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=internal/handler [source: maas-discovery/internal/handler/handler.go:84]
- GET /logs/loki/api/v1/label/:name/values on port ; transport=HTTP/1.1 encryption= auth= owner=internal/lokiproxy [source: maas-api/internal/lokiproxy/handler.go:99]
- GET /logs/loki/api/v1/labels on port ; transport=HTTP/1.1 encryption= auth= owner=internal/lokiproxy [source: maas-api/internal/lokiproxy/handler.go:98]
- GET /logs/loki/api/v1/query_range on port ; transport=HTTP/1.1 encryption= auth= owner=internal/lokiproxy [source: maas-api/internal/lokiproxy/handler.go:97]
- GET /me on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:349]
- GET /model/:model-id/subscriptions on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:354]
- GET /models on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:335]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/manager [source: maas-controller/cmd/manager/main.go:1465]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=internal/handler [source: maas-discovery/internal/handler/handler.go:85]
- GET /subscriptions on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:353]
- GET /tenants on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:377]
- GET /v1/tenants on port ; transport=HTTP/1.1 encryption= auth= owner=internal/handler [source: maas-discovery/internal/handler/handler.go:83]
- OPTIONS /*path on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:171]
- POST /api-keys/cleanup on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:388]
- POST /api-keys/search on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:373]
- POST /api-keys/validate on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:386]
- POST /bulk-revoke on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:368]
- POST /subscriptions/select on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: maas-api/cmd/main.go:391]
- Unknown /metrics on port ; transport=HTTP/1.1 encryption= auth= owner=internal/metrics [source: maas-api/internal/metrics/server.go:87]
### integrations

- Gateway API (data-science-gateway) interaction=HTTPRoute role=runtime-transport protocol=HTTPS purpose=External dashboard ingress [source: deployment/base/maas-api/networking/httproute.yaml:1]
- Gateway API interaction=HTTPRoute CRUD role=runtime-transport protocol=HTTPS purpose=Manage Gateway API routing resources [source: deployment/base/maas-api/rbac/clusterrole.yaml:1]
- OpenTelemetry Collector interaction=gRPC client role=runtime-integration protocol=OTLP/gRPC purpose=Runtime trace export [source: maas-api/internal/tracing/provider.go:37]
### internal_dependencies

- Gateway API (data-science-gateway) interaction=HTTPRoute role=runtime-transport purpose=Platform ingress through Gateway API [source: deployment/base/maas-api/networking/httproute.yaml:1]
- Gateway API interaction=CRD CRUD role=unknown purpose=Manage Gateway API routing resources [source: deployment/base/maas-api/rbac/clusterrole.yaml:1]
- Gateway API interaction=Controller watch role=runtime-integration purpose=Manage Gateway API routing resources [source: maas-controller/pkg/controller/maas/aitenant_controller.go:329]
- Gateway API interaction=HTTPRoute CRUD role=runtime-transport purpose=Reconcile HTTPRoute resources against a configured Gateway [source: maas-controller/pkg/controller/maas/helpers.go:360]
- KServe InferenceService interaction=Controller watch (conditional) role=runtime-integration purpose=Read model serving state [source: maas-controller/pkg/controller/maas/maasmodelref_controller.go:760]
- ai-gateway-controller interaction=Go library role=runtime-library purpose=Use runtime packages from github.com/opendatahub-io/ai-gateway-controller [source: maas-api/internal/subscription/guardrail.go:8]
- llm-d-router interaction=Go library role=runtime-library purpose=Use runtime packages from github.com/llm-d/llm-d-router [source: maas-controller/cmd/manager/main.go:34]
### services

- maas-api port=8080 target=http protocol=TCP encryption= auth= [source: deployment/base/maas-api/core/service.yaml:1]
- maas-api-metrics port=9090 target=https-metrics protocol=TCP encryption= auth= [source: deployment/base/maas-api/core/metrics_service.yaml:4]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload maas-api uses service account maas-api and 1 container(s) [source: deployment/base/maas-api/core/deployment.yaml:1]
- **observed**: Service maas-api targets  with 1 port(s) [source: deployment/base/maas-api/core/service.yaml:1]
- **observed**: Service maas-api-metrics targets  with 1 port(s) [source: deployment/base/maas-api/core/metrics_service.yaml:4]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP DELETE /:id is owned by cmd [source: maas-api/cmd/main.go:370]
- **observed**: HTTP DELETE /tenants/:tenant/api-keys is owned by cmd [source: maas-api/cmd/main.go:389]
- **observed**: HTTP DELETE /tenants/:tenant/subscriptions/:subscription/api-keys is owned by cmd [source: maas-api/cmd/main.go:390]
- **observed**: HTTP GET /:id is owned by cmd [source: maas-api/cmd/main.go:369]
- **observed**: HTTP GET /config is owned by cmd [source: maas-api/cmd/main.go:366]
- **observed**: HTTP GET /health is owned by cmd [source: maas-api/cmd/main.go:265]
- **observed**: HTTP GET /health/database is owned by cmd [source: maas-api/cmd/main.go:268]
- **observed**: HTTP GET /healthz is owned by cmd/manager [source: maas-controller/cmd/manager/main.go:1461]
- **observed**: HTTP GET /healthz is owned by internal/handler [source: maas-discovery/internal/handler/handler.go:84]
- **observed**: HTTP GET /logs/loki/api/v1/label/:name/values is owned by internal/lokiproxy [source: maas-api/internal/lokiproxy/handler.go:99]
- **observed**: HTTP GET /logs/loki/api/v1/labels is owned by internal/lokiproxy [source: maas-api/internal/lokiproxy/handler.go:98]
- **observed**: HTTP GET /logs/loki/api/v1/query_range is owned by internal/lokiproxy [source: maas-api/internal/lokiproxy/handler.go:97]
- **observed**: HTTP GET /me is owned by cmd [source: maas-api/cmd/main.go:349]
- **observed**: HTTP GET /model/:model-id/subscriptions is owned by cmd [source: maas-api/cmd/main.go:354]
- **observed**: HTTP GET /models is owned by cmd [source: maas-api/cmd/main.go:335]
- **observed**: HTTP GET /readyz is owned by cmd/manager [source: maas-controller/cmd/manager/main.go:1465]
- **observed**: HTTP GET /readyz is owned by internal/handler [source: maas-discovery/internal/handler/handler.go:85]
- **observed**: HTTP GET /subscriptions is owned by cmd [source: maas-api/cmd/main.go:353]
- **observed**: HTTP GET /tenants is owned by cmd [source: maas-api/cmd/main.go:377]
- **observed**: HTTP GET /v1/tenants is owned by internal/handler [source: maas-discovery/internal/handler/handler.go:83]
- **observed**: HTTP OPTIONS /*path is owned by cmd [source: maas-api/cmd/main.go:171]
- **observed**: HTTP POST /api-keys/cleanup is owned by cmd [source: maas-api/cmd/main.go:388]
- **observed**: HTTP POST /api-keys/search is owned by cmd [source: maas-api/cmd/main.go:373]
- **observed**: HTTP POST /api-keys/validate is owned by cmd [source: maas-api/cmd/main.go:386]
- **observed**: HTTP POST /bulk-revoke is owned by cmd [source: maas-api/cmd/main.go:368]
- **observed**: HTTP POST /subscriptions/select is owned by cmd [source: maas-api/cmd/main.go:391]
- **observed**: HTTP Unknown /metrics is owned by internal/metrics [source: maas-api/internal/metrics/server.go:87]
- **observed**: HTTPRoute maas-api-route serves host  via plaintext; backend=maas-api; transport=Unknown [source: deployment/base/maas-api/networking/httproute.yaml:1]
### security

- **observed**: CREATE Operator webhook uses Kubernetes admission at ValidatingWebhookConfiguration; policy=Admission validation [source: maas-controller/pkg/webhook/aitenant_webhook.go:32]
- **observed**: GET :8080/health uses None at N/A; policy=Unauthenticated Kubernetes liveness probe endpoint [source: deployment/base/maas-api/core/deployment.yaml:1]
- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: maas-controller/cmd/manager/main.go:1461]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: maas-controller/cmd/manager/main.go:1465]
- **observed**: GET, POST, DELETE, OPTIONS /v1/models, /v1/subscriptions, /v1/api-keys/*, /maas-api/v1/*, /maas-api/health, /v1/me uses API key + Kubernetes TokenReview + OIDC JWT (optional) at Kuadrant/Authorino Gateway AuthPolicy; policy=Gateway policy authenticates requests and applies policy-defined authorization rules; excludes GET /maas-api/health [source: maas-controller/pkg/controller/maas/maasauthpolicy_controller.go:1244]
- **observed**: Kuadrant AuthPolicy controller-created Gateway AuthPolicy applies authentication API key, Kubernetes TokenReview, OIDC JWT (optional) [source: maas-controller/pkg/controller/maas/maasauthpolicy_controller.go:1244]
- **observed**: Kubernetes API Named Secret access (maas-db-config) uses RBAC with resourceNames restriction at kube-apiserver; policy=maas-api restricts secret access to maas-db-config only [source: deployment/base/maas-api/rbac/clusterrole.yaml:1]
- **observed**: Kubernetes API Named Secret access (maas-db-config) uses RBAC with resourceNames restriction at kube-apiserver; policy=maas-api-supplemental restricts secret access to maas-db-config only [source: deployment/base/maas-api/rbac/supplemental-clusterrole.yaml:10]
- **observed**: Kubernetes TokenReview API Token validation uses Kubernetes TokenReview API at Application-level token validation via kube-apiserver; policy=Validates bearer tokens against Kubernetes TokenReview API [source: maas-api/internal/auth/cleanup_auth_middleware.go:23]
- **observed**: RBAC role maas-api grants 8 rule(s) [source: deployment/base/maas-api/rbac/clusterrole.yaml:1]
- **observed**: RBAC role maas-api-supplemental grants 6 rule(s) [source: deployment/base/maas-api/rbac/supplemental-clusterrole.yaml:10]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via maas-api ClusterRole; SA maas-api [source: maas-api/internal/tlsprofile/fetch.go:127]
- **observed**: REST Kubernetes API uses kubeconfig credential chain at kube-apiserver; policy=Kubeconfig-based authentication using user-provided credentials [source: maas-api/internal/config/cluster_config.go:289]
- **literal**: rbac-ref targets SubjectAccessReviews: Token or subject access review call [source: maas-api/internal/auth/sar_admin_checker.go:58, maas-api/internal/auth/tenant_auth_middleware.go:90, maas-discovery/internal/auth/token_review.go:126, maas-discovery/internal/auth/token_review.go:90]
- **literal**: rbac-ref targets TokenReviewMiddleware: Token or subject access review call [source: maas-discovery/cmd/discovery/main.go:106]
- **literal**: rbac-ref targets TokenReviews: Token or subject access review call [source: maas-api/internal/auth/cleanup_auth_middleware.go:40, maas-api/internal/auth/tenant_auth_middleware.go:44, maas-discovery/internal/auth/token_review.go:54]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: maas-api/cmd/server.go, maas-api/internal/cert/cert.go, maas-api/internal/config/tls.go, maas-api/internal/metrics/server.go, maas-api/internal/models/discovery.go, maas-api/internal/tlsprofile/config.go, maas-api/internal/tlsprofile/profile.go, maas-controller/cmd/manager/main.go, maas-discovery/cmd/discovery/main.go, maas-discovery/internal/cert/cert.go, maas-discovery/internal/tlsprofile/config.go, maas-discovery/internal/tlsprofile/profile.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
