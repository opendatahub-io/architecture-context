# Analyzer Synthesis Context: agents-operator

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 3 crds facts extracted [source: kagenti-operator/config/crd/bases/agent.kagenti.dev_agentcards.yaml:2, kagenti-operator/config/crd/bases/agent.kagenti.dev_agentruntimes.yaml:2, kagenti-operator/config/crd/bases/agent.kagenti.dev_authorizationpolicies.yaml:2]
- **grpc_services (observed)**: 1 grpc_services facts extracted [source: authbridge/cmd/authbridge-envoy/main.go:316]
- **http_endpoints (observed)**: 35 http_endpoints facts extracted [source: authbridge/authlib/observe/statserver.go:59, authbridge/authlib/observe/statserver.go:60, authbridge/authlib/observe/statserver.go:62, authbridge/authlib/observe/statserver.go:65, authbridge/cmd/authbridge-envoy/main.go:266, authbridge/cmd/authbridge-envoy/main.go:269, authbridge/cmd/authbridge-lite/main.go:298, authbridge/cmd/authbridge-lite/main.go:301, authbridge/cmd/authbridge-proxy/main.go:420, authbridge/cmd/authbridge-proxy/main.go:423, authbridge/demos/echo/agent/main.go:383, authbridge/demos/echo/agent/main.go:384, authbridge/demos/echo/upstream/main.go:33, authbridge/demos/finance-sparc/finance-agent/main.go:464, authbridge/demos/finance-sparc/finance-agent/main.go:465, authbridge/demos/finance-sparc/finance-mcp/main.go:213, authbridge/demos/ibac/agent/main.go:799, authbridge/demos/ibac/agent/main.go:800, authbridge/demos/ibac/email-server/main.go:161, authbridge/demos/ibac/evil-server/main.go:17, kagenti-operator/cmd/main.go:889, kagenti-operator/cmd/main.go:893, kagenti-operator/cmd/main.go:897, kagenti-operator/cmd/test-tls-agent/main.go:52, kagenti-operator/cmd/test-tls-agent/main.go:56, kagenti-operator/internal/bundleservice/handler/handler.go:32, kagenti-operator/internal/bundleservice/handler/handler.go:33, kagenti-operator/internal/bundleservice/handler/handler.go:34, token-broker/cmd/main.go:302, token-broker/cmd/main.go:305, token-broker/internal/api/handlers.go:54, token-broker/internal/api/handlers.go:55, token-broker/internal/api/handlers.go:56, token-broker/internal/api/handlers.go:57, token-broker/internal/api/handlers.go:58]
- **services (observed)**: 2 services facts extracted [source: kagenti-operator/config/default/metrics_service.yaml:1, kagenti-operator/config/webhook/service.yaml:1]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (observed)**: 6 webhooks facts extracted [source: kagenti-operator/config/default/webhook_namespace_selector_patch.yaml:1, kagenti-operator/config/webhook/manifests.yaml:2, kagenti-operator/config/webhook/manifests.yaml:28, kagenti-operator/internal/webhook/v1alpha1/agentcard_webhook.go:37, kagenti-operator/internal/webhook/v1alpha1/agentruntime_webhook.go:37, kagenti-operator/internal/webhook/v1alpha1/authbridge_webhook.go:199]

## Deterministic Cross-References

- **controller**: AgentCardNetworkPolicyReconciler —watches-reference→ api/v1alpha1/AgentCard; api/v1alpha1/AgentCard [source: kagenti-operator/internal/controller/agentcard_controller.go:166, kagenti-operator/internal/controller/agentcard_networkpolicy_controller.go:372]
- **controller**: AgentCardNetworkPolicyReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: kagenti-operator/internal/bootstrap/otel.go:112, kagenti-operator/internal/controller/agentcard_networkpolicy_controller.go:374]
- **controller**: AgentCardNetworkPolicyReconciler —watches-reference→ apps/v1/StatefulSet; apps/v1/StatefulSet [source: kagenti-operator/internal/bootstrap/keycloak.go:194, kagenti-operator/internal/controller/agentcard_networkpolicy_controller.go:379]
- **controller**: AgentCardNetworkPolicyReconciler —watches-reference→ networking.k8s.io/v1/NetworkPolicy; networking.k8s.io/v1/NetworkPolicy [source: kagenti-operator/internal/controller/agentcard_networkpolicy_controller.go:183, kagenti-operator/internal/controller/agentcard_networkpolicy_controller.go:373]
- **controller**: AgentCardReconciler —watches-reference→ api/v1alpha1/AgentCard; api/v1alpha1/AgentCard [source: kagenti-operator/internal/controller/agentcard_controller.go:1653, kagenti-operator/internal/controller/agentcard_controller.go:166]
- **controller**: AgentCardReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: kagenti-operator/internal/bootstrap/otel.go:112, kagenti-operator/internal/controller/agentcard_controller.go:1654]
- **controller**: AgentCardReconciler —watches-reference→ apps/v1/StatefulSet; apps/v1/StatefulSet [source: kagenti-operator/internal/bootstrap/keycloak.go:194, kagenti-operator/internal/controller/agentcard_controller.go:1659]
- **controller**: AgentCardSyncReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: kagenti-operator/internal/bootstrap/otel.go:112, kagenti-operator/internal/controller/agentcardsync_controller.go:410]
- **controller**: AgentCardSyncReconciler —watches-reference→ apps/v1/StatefulSet; apps/v1/StatefulSet [source: kagenti-operator/internal/bootstrap/keycloak.go:194, kagenti-operator/internal/controller/agentcardsync_controller.go:418]
- **controller**: AgentRuntimeReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: kagenti-operator/cmd/agentcard-signer/main.go:150, kagenti-operator/internal/controller/agentruntime_controller.go:1391]
- **controller**: AgentRuntimeReconciler —watches-reference→ api/v1alpha1/AgentRuntime; api/v1alpha1/AgentRuntime [source: kagenti-operator/internal/controller/agentruntime_controller.go:1382, kagenti-operator/internal/controller/agentruntime_controller.go:154]
- **controller**: AgentRuntimeReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: kagenti-operator/internal/bootstrap/otel.go:112, kagenti-operator/internal/controller/agentruntime_controller.go:1383]
- **controller**: AgentRuntimeReconciler —watches-reference→ apps/v1/StatefulSet; apps/v1/StatefulSet [source: kagenti-operator/internal/bootstrap/keycloak.go:194, kagenti-operator/internal/controller/agentruntime_controller.go:1387]
- **controller**: AuthbridgeConfigReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: kagenti-operator/cmd/agentcard-signer/main.go:150, kagenti-operator/internal/controller/authbridgeconfig_controller.go:201]
- **controller**: AuthbridgeConfigReconciler —watches-reference→ /v1/Namespace; /v1/Namespace [source: kagenti-operator/internal/bootstrap/keycloak.go:77, kagenti-operator/internal/controller/authbridgeconfig_controller.go:186]
- **controller**: ClientRegistrationReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: kagenti-operator/internal/bootstrap/otel.go:112, kagenti-operator/internal/controller/clientregistration_controller.go:602]
- **controller**: ClientRegistrationReconciler —watches-reference→ apps/v1/StatefulSet; apps/v1/StatefulSet [source: kagenti-operator/internal/bootstrap/keycloak.go:194, kagenti-operator/internal/controller/clientregistration_controller.go:603]
- **controller**: MLflowOperandReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: kagenti-operator/internal/bootstrap/otel.go:112, kagenti-operator/internal/controller/mlflow_operand_controller.go:430]
- **controller**: MLflowReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: kagenti-operator/internal/bootstrap/otel.go:112, kagenti-operator/internal/controller/mlflow_controller.go:353]
- **controller**: MLflowReconciler —watches-reference→ rbac.authorization.k8s.io/v1/Role; rbac.authorization.k8s.io/v1/Role [source: kagenti-operator/internal/controller/mlflow_controller.go:281, kagenti-operator/internal/controller/mlflow_controller.go:354]
- **controller**: MLflowReconciler —watches-reference→ rbac.authorization.k8s.io/v1/RoleBinding; rbac.authorization.k8s.io/v1/RoleBinding [source: kagenti-operator/internal/controller/agentruntime_controller.go:1207, kagenti-operator/internal/controller/mlflow_controller.go:355]
- **controller**: SharedTrustReconciler —watches-reference→ /v1/Secret; /v1/Secret [source: kagenti-operator/internal/bootstrap/keycloak.go:128, kagenti-operator/internal/controller/sharedtrust_controller.go:390]
- **controller**: SharedTrustReconciler —watches-reference→ cert-manager.io/v1/Certificate; cert-manager.io/v1/Certificate [source: kagenti-operator/internal/controller/sharedtrust_controller.go:141, kagenti-operator/internal/controller/sharedtrust_controller.go:389]
- **controller**: TLSBridgeCAReconciler —watches-reference→ api/v1alpha1/AgentRuntime; api/v1alpha1/AgentRuntime [source: kagenti-operator/internal/controller/agentruntime_controller.go:154, kagenti-operator/internal/controller/tlsbridge_ca_controller.go:99]
- **controller**: TLSBridgeCAReconciler —watches-reference→ cert-manager.io/v1/Certificate; cert-manager.io/v1/Certificate [source: kagenti-operator/internal/controller/sharedtrust_controller.go:141, kagenti-operator/internal/controller/tlsbridge_ca_controller.go:100]
- **webhook**: inject.kagenti.io —served-by→ kagenti-operator-webhook-service; admission webhook declares an explicit service reference [source: kagenti-operator/config/default/webhook_namespace_selector_patch.yaml:1, kagenti-operator/config/webhook/service.yaml:1, kagenti-operator/internal/webhook/v1alpha1/authbridge_webhook.go:199]
- **webhook**: vagentcard.kb.io —served-by→ kagenti-operator-webhook-service; admission webhook declares an explicit service reference [source: kagenti-operator/config/webhook/manifests.yaml:28, kagenti-operator/config/webhook/service.yaml:1, kagenti-operator/internal/webhook/v1alpha1/agentcard_webhook.go:37]
- **webhook**: vagentruntime.kb.io —served-by→ kagenti-operator-webhook-service; admission webhook declares an explicit service reference [source: kagenti-operator/config/webhook/manifests.yaml:28, kagenti-operator/config/webhook/service.yaml:1, kagenti-operator/internal/webhook/v1alpha1/agentruntime_webhook.go:37]

## Behavioral Evidence

- **conditional-metrics-enforcement (unresolved)** controller-runtime metrics: controller-runtime metrics serving surface; limitations=The controller-runtime manager Metrics binding does not use one direct lexical options object with a stable SecureServing condition [source: kagenti-operator/cmd/main.go:393-393]
- **named-watch-predicate (unresolved)** internal/controller.AgentCardNetworkPolicyReconciler: apps/v1/Deployment; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: kagenti-operator/internal/controller/agentcard_networkpolicy_controller.go:374-378]
- **named-watch-predicate (unresolved)** internal/controller.AgentCardNetworkPolicyReconciler: apps/v1/StatefulSet; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: kagenti-operator/internal/controller/agentcard_networkpolicy_controller.go:379-383]
- **named-watch-predicate (unresolved)** internal/controller.AgentCardReconciler: apps/v1/Deployment; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: kagenti-operator/internal/controller/agentcard_controller.go:1654-1658]
- **named-watch-predicate (unresolved)** internal/controller.AgentCardReconciler: apps/v1/StatefulSet; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: kagenti-operator/internal/controller/agentcard_controller.go:1659-1663]
- **named-watch-predicate (unresolved)** internal/controller.ClientRegistrationReconciler: apps/v1/StatefulSet; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: kagenti-operator/internal/controller/clientregistration_controller.go:603-607]
- **named-watch-predicate (unresolved)** internal/controller.MLflowOperandReconciler: apps/v1/Deployment; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: kagenti-operator/internal/controller/mlflow_operand_controller.go:430-433]

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `authbridge/cmd/authbridge-envoy/main.go`:315 (None, gRPC services (Go))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `authbridge/cmd/authbridge-envoy/main.go`:316 (External Processor gRPC, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `kagenti-operator/cmd/agentcard-signer/main.go`:120 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this runtime security control wired to the serving surface?
  **Expected signal:** flag/default, certificate, middleware, or enforcement point
  **Candidate:** `kagenti-operator/cmd/main.go`:359 (controller-runtime metrics, controller-runtime metrics authn/authz filter)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `kagenti-operator/cmd/main.go`:359 (:8443/metrics, TokenReview + SubjectAccessReview (controller-runtime authn/authz filter))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `kagenti-operator/cmd/main.go`:391 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Under which configuration branch does the metrics serving surface install authentication and authorization?
  **Expected signal:** a direct SecureServing condition and controller-runtime authn/authz FilterProvider assignment
  **Candidate:** `kagenti-operator/cmd/main.go`:393-393 (controller-runtime metrics, controller-runtime metrics serving surface)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `kagenti-operator/cmd/main.go`:889 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `kagenti-operator/cmd/main.go`:893 (:8081/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `kagenti-operator/cmd/main.go`:897 (:8081/webhook, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `kagenti-operator/config/webhook/manifests.yaml`:28 (Kubernetes admission, Operator webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `kagenti-operator/config/rbac/leader_election_role.yaml`:2 (kagenti-operator-leader-election-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `kagenti-operator/config/rbac/leader_election_role.yaml`:2 (leader-election-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `kagenti-operator/config/rbac/metrics_auth_role.yaml`:1 (kagenti-operator-metrics-auth-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `kagenti-operator/config/rbac/metrics_auth_role.yaml`:1 (metrics-auth-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `kagenti-operator/config/rbac/metrics_auth_role_binding.yaml`:1 (kagenti-operator-metrics-auth-role, kagenti-operator-metrics-auth-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `kagenti-operator/config/rbac/metrics_auth_role_binding.yaml`:1 (metrics-auth-role, metrics-auth-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `kagenti-operator/config/rbac/metrics_reader_role.yaml`:1 (kagenti-operator-metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `kagenti-operator/config/rbac/metrics_reader_role.yaml`:1 (metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `kagenti-operator/config/rbac/mlflow_binding.yaml`:1 (kagenti-operator-mlflow-integration-binding, mlflow-operator-mlflow-integration)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `kagenti-operator/config/rbac/role.yaml`:2 (kagenti-operator-manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `kagenti-operator/config/rbac/role.yaml`:2 (manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `kagenti-operator/config/rbac/role_binding.yaml`:1 (kagenti-operator-manager-role, kagenti-operator-manager-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `authbridge/cmd/authbridge-envoy/Dockerfile`:44 (authbridge/cmd/authbridge-envoy/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `authbridge/cmd/authbridge-lite/Dockerfile`:44 (authbridge/cmd/authbridge-lite/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `authbridge/cmd/authbridge-proxy/Dockerfile`:45 (authbridge/cmd/authbridge-proxy/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `authbridge/cmd/authbridge-proxy/Dockerfile.konflux`:45 (authbridge/cmd/authbridge-proxy/Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `authbridge/demos/echo/agent/Dockerfile`:17 (authbridge/demos/echo/agent/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `authbridge/demos/echo/upstream/Dockerfile`:10 (authbridge/demos/echo/upstream/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `authbridge/demos/finance-sparc/finance-agent/Dockerfile`:12 (authbridge/demos/finance-sparc/finance-agent/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `authbridge/demos/finance-sparc/finance-mcp/Dockerfile`:11 (authbridge/demos/finance-sparc/finance-mcp/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `authbridge/demos/ibac/agent/Dockerfile`:17 (authbridge/demos/ibac/agent/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `authbridge/demos/ibac/email-server/Dockerfile`:10 (authbridge/demos/ibac/email-server/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `authbridge/demos/ibac/evil-server/Dockerfile`:10 (authbridge/demos/ibac/evil-server/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `authbridge/proxy-init/Dockerfile.init`:16 (authbridge/proxy-init/Dockerfile.init:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `kagenti-operator/cmd/agentcard-signer/main.go`:132 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `kagenti-operator/cmd/bundle-service/main.go`:68 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `kagenti-operator/cmd/main.go`:391 (Kubernetes API, controller-runtime manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `kagenti-operator/go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `kagenti-operator/internal/bootstrap/otel.go`:172 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `kagenti-operator/internal/bootstrap/otel.go`:492 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `kagenti-operator/internal/controller/agentruntime_controller.go`:1363 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `kagenti-operator/internal/controller/kuadrant_controller.go`:179 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `kagenti-operator/internal/controller/network_check.go`:41 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `kagenti-operator/internal/controller/sharedtrust_controller.go`:395 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `kagenti-operator/internal/controller/spire_operand_controller.go`:312 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `kagenti-operator/internal/controller/tektonconfig_controller.go`:97 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### grpc_services

- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `authbridge/cmd/authbridge-envoy/main.go`:316 (ExternalProcessor, main)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `authbridge/authlib/observe/statserver.go`:59 (/config, Unknown, observe)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `authbridge/authlib/observe/statserver.go`:65 (/, Unknown, observe)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `authbridge/demos/echo/agent/main.go`:383 (/, Unknown, agent)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `authbridge/demos/echo/agent/main.go`:384 (/.well-known/agent-card.json, Unknown, agent)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `authbridge/demos/echo/upstream/main.go`:33 (/echo, Unknown, upstream)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `authbridge/demos/finance-sparc/finance-agent/main.go`:464 (/, Unknown, finance-agent)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `authbridge/demos/finance-sparc/finance-agent/main.go`:465 (/.well-known/agent-card.json, Unknown, finance-agent)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `authbridge/demos/ibac/agent/main.go`:799 (/, Unknown, agent)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `authbridge/demos/ibac/agent/main.go`:800 (/.well-known/agent-card.json, Unknown, agent)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `authbridge/demos/ibac/evil-server/main.go`:17 (/, Unknown, evil-server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `kagenti-operator/cmd/test-tls-agent/main.go`:52 (/.well-known/agent-card.json, Unknown, cmd/test-tls-agent)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `kagenti-operator/internal/bundleservice/handler/handler.go`:32 (/bundles, Unknown, internal/bundleservice/handler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `kagenti-operator/config/rbac/role.yaml`:2 (CRD Watch, DataScienceCluster CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `kagenti-operator/config/rbac/role.yaml`:2 (CRD Watch, MLflow CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `kagenti-operator/config/rbac/role.yaml`:2 (CRD Watch, OpenShift Routes)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `kagenti-operator/config/rbac/role.yaml`:2 (Certificate CR, cert-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `authbridge/cmd/authbridge-envoy/main.go`:316 (Envoy proxy, gRPC ExtProc callout)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `kagenti-operator/cmd/agentcard-signer/main.go`:150 (/v1/ConfigMap, create, delete, get, list, update operations by AgentRuntimeReconciler, AuthbridgeConfigReconciler, ConfigMapFetcher, KeycloakBootstrapRunnable, OtelBootstrapRunnable, SharedTrustReconciler, UIConfigBootstrapRunnable, X5CProvider)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `kagenti-operator/config/rbac/role.yaml`:2 (CRD CRUD, cert-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `kagenti-operator/config/rbac/role.yaml`:2 (CRD Watch, DataScienceCluster CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `kagenti-operator/config/rbac/role.yaml`:2 (CRD Watch, MLflow (mlflow.opendatahub.io))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `kagenti-operator/internal/bootstrap/keycloak.go`:128 (/v1/Secret, create, delete, get, update operations by ClientRegistrationReconciler, KeycloakBootstrapRunnable, SharedTrustReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `kagenti-operator/internal/bootstrap/keycloak.go`:211 (/v1/Service, create, get, list operations by AgentCardReconciler, AgentRuntimeReconciler, KeycloakBootstrapRunnable, MLflowOperandReconciler, OtelBootstrapRunnable)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `kagenti-operator/internal/bootstrap/keycloak.go`:77 (/v1/Namespace, create, get, patch operations by AgentRuntimeReconciler, AuthbridgeConfigReconciler, KeycloakBootstrapRunnable, KuadrantReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `kagenti-operator/internal/controller/agentcard_networkpolicy_controller.go`:349 (/v1/Endpoints, get operations by AgentCardNetworkPolicyReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `kagenti-operator/internal/controller/agentruntime_controller.go`:537 (/v1/Pod, list operations by AgentRuntimeReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `kagenti-operator/internal/controller/sharedtrust_controller.go`:141 (Certificate and Issuer CRD CRUD, cert-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `kagenti-operator/internal/controller/tlsbridge_ca_controller.go`:100 (Controller watch (conditional), cert-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `kagenti-operator/internal/controller/agentcard_controller.go`:1653 (AgentCardReconciler, api/v1alpha1/AgentCard)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `kagenti-operator/internal/controller/agentcard_controller.go`:1654-1658 (apps/v1/Deployment, internal/controller.AgentCardReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `kagenti-operator/internal/controller/agentcard_controller.go`:1659-1663 (apps/v1/StatefulSet, internal/controller.AgentCardReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `kagenti-operator/internal/controller/agentcard_networkpolicy_controller.go`:372 (AgentCardNetworkPolicyReconciler, api/v1alpha1/AgentCard)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `kagenti-operator/internal/controller/agentcard_networkpolicy_controller.go`:374-378 (apps/v1/Deployment, internal/controller.AgentCardNetworkPolicyReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `kagenti-operator/internal/controller/agentcard_networkpolicy_controller.go`:379-383 (apps/v1/StatefulSet, internal/controller.AgentCardNetworkPolicyReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `kagenti-operator/internal/controller/agentruntime_controller.go`:1391 (/v1/ConfigMap, AgentRuntimeReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `kagenti-operator/internal/controller/authbridgeconfig_controller.go`:186 (/v1/Namespace, AuthbridgeConfigReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `kagenti-operator/internal/controller/authbridgeconfig_controller.go`:201 (/v1/ConfigMap, AuthbridgeConfigReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `kagenti-operator/internal/controller/clientregistration_controller.go`:603-607 (apps/v1/StatefulSet, internal/controller.ClientRegistrationReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `kagenti-operator/internal/controller/mlflow_operand_controller.go`:430-433 (apps/v1/Deployment, internal/controller.MLflowOperandReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `kagenti-operator/internal/controller/sharedtrust_controller.go`:390 (/v1/Secret, SharedTrustReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `kagenti-operator/config/default/manager_webhook_patch.yaml`:1 (kagenti-operator-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `kagenti-operator/config/default/metrics_service.yaml`:1 (kagenti-operator-controller-manager, kagenti-operator-controller-manager-metrics-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `kagenti-operator/config/webhook/service.yaml`:1 (kagenti-operator-controller-manager, kagenti-operator-webhook-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### webhooks

- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `kagenti-operator/config/default/webhook_namespace_selector_patch.yaml`:1 (/mutate-workloads-authbridge, inject.kagenti.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `kagenti-operator/config/webhook/manifests.yaml`:2 (/mutate-workloads-authbridge, inject.kagenti.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `kagenti-operator/config/webhook/manifests.yaml`:28 (/validate-agent-kagenti-dev-v1alpha1-agentcard, vagentcard.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `kagenti-operator/config/webhook/manifests.yaml`:28 (/validate-agent-kagenti-dev-v1alpha1-agentruntime, vagentruntime.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `kagenti-operator/internal/webhook/v1alpha1/agentcard_webhook.go`:37 (/validate-agent-kagenti-dev-v1alpha1-agentcard, vagentcard.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `kagenti-operator/internal/webhook/v1alpha1/agentruntime_webhook.go`:37 (/validate-agent-kagenti-dev-v1alpha1-agentruntime, vagentruntime.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `kagenti-operator/internal/webhook/v1alpha1/authbridge_webhook.go`:199 (/mutate-workloads-authbridge, inject.kagenti.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: kagenti-operator/cmd/main.go:889]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: kagenti-operator/cmd/main.go:893]
- :8081/webhook methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: kagenti-operator/cmd/main.go:897]
- :8443/metrics methods=GET mechanism=TokenReview + SubjectAccessReview (controller-runtime authn/authz filter) enforcement=controller-runtime metrics authn/authz filter policy=RBAC via kagenti-operator-metrics-auth-role; exposed by Service kagenti-operator-controller-manager-metrics-service; TLS certificate source unresolved [source: kagenti-operator/cmd/main.go:359]
- External Processor gRPC methods=gRPC mechanism=None enforcement=N/A policy=Plaintext gRPC service has no application authentication interceptor [source: authbridge/cmd/authbridge-envoy/main.go:316]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=In-cluster configuration provides automatic ServiceAccount token authentication [source: kagenti-operator/cmd/agentcard-signer/main.go:120]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via kagenti-operator-manager-role ClusterRole; SA kagenti-operator-controller-manager [source: kagenti-operator/cmd/main.go:391]
- Operator webhook methods=CREATE mechanism=Kubernetes admission enforcement=ValidatingWebhookConfiguration policy=Admission validation [source: kagenti-operator/config/webhook/manifests.yaml:28]
- gRPC services (Go) methods=ALL mechanism=None enforcement=N/A policy=Bounded grpc.NewServer option set contains only observability interceptors; no authentication interceptor configured [source: authbridge/cmd/authbridge-envoy/main.go:315]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: token-broker/cmd/main.go:302]
- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: kagenti-operator/cmd/main.go:889]
- GET /oauth/callback on port ; transport=HTTP/1.1 encryption= auth= owner=internal/api [source: token-broker/internal/api/handlers.go:58]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: kagenti-operator/cmd/main.go:893]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: token-broker/cmd/main.go:305]
- GET /webhook on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: kagenti-operator/cmd/main.go:897]
- POST /sessions on port ; transport=HTTP/1.1 encryption= auth= owner=internal/api [source: token-broker/internal/api/handlers.go:54]
- POST /sessions/broker-events on port ; transport=HTTP/1.1 encryption= auth= owner=internal/api [source: token-broker/internal/api/handlers.go:56]
- POST /sessions/end on port ; transport=HTTP/1.1 encryption= auth= owner=internal/api [source: token-broker/internal/api/handlers.go:57]
- POST /sessions/token on port ; transport=HTTP/1.1 encryption= auth= owner=internal/api [source: token-broker/internal/api/handlers.go:55]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=agent [source: authbridge/demos/echo/agent/main.go:383]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=agent [source: authbridge/demos/ibac/agent/main.go:799]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=evil-server [source: authbridge/demos/ibac/evil-server/main.go:17]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=finance-agent [source: authbridge/demos/finance-sparc/finance-agent/main.go:464]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=observe [source: authbridge/authlib/observe/statserver.go:65]
- Unknown /.well-known/agent-card.json on port ; transport=HTTP/1.1 encryption= auth= owner=agent [source: authbridge/demos/ibac/agent/main.go:800]
- Unknown /.well-known/agent-card.json on port ; transport=HTTP/1.1 encryption= auth= owner=agent [source: authbridge/demos/echo/agent/main.go:384]
- Unknown /.well-known/agent-card.json on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/test-tls-agent [source: kagenti-operator/cmd/test-tls-agent/main.go:52]
- Unknown /.well-known/agent-card.json on port ; transport=HTTP/1.1 encryption= auth= owner=finance-agent [source: authbridge/demos/finance-sparc/finance-agent/main.go:465]
- Unknown /bundles on port ; transport=HTTP/1.1 encryption= auth= owner=internal/bundleservice/handler [source: kagenti-operator/internal/bundleservice/handler/handler.go:32]
- Unknown /config on port ; transport=HTTP/1.1 encryption= auth= owner=observe [source: authbridge/authlib/observe/statserver.go:59]
- Unknown /echo on port ; transport=HTTP/1.1 encryption= auth= owner=upstream [source: authbridge/demos/echo/upstream/main.go:33]
- Unknown /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/test-tls-agent [source: kagenti-operator/cmd/test-tls-agent/main.go:56]
- Unknown /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=internal/bundleservice/handler [source: kagenti-operator/internal/bundleservice/handler/handler.go:33]
- Unknown /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: authbridge/cmd/authbridge-envoy/main.go:266]
- Unknown /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: authbridge/cmd/authbridge-lite/main.go:298]
- Unknown /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: authbridge/cmd/authbridge-proxy/main.go:420]
- Unknown /mcp on port ; transport=HTTP/1.1 encryption= auth= owner=email-server [source: authbridge/demos/ibac/email-server/main.go:161]
- Unknown /mcp on port ; transport=HTTP/1.1 encryption= auth= owner=finance-mcp [source: authbridge/demos/finance-sparc/finance-mcp/main.go:213]
- Unknown /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=internal/bundleservice/handler [source: kagenti-operator/internal/bundleservice/handler/handler.go:34]
- Unknown /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: authbridge/cmd/authbridge-envoy/main.go:269]
- Unknown /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: authbridge/cmd/authbridge-lite/main.go:301]
- Unknown /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: authbridge/cmd/authbridge-proxy/main.go:423]
- Unknown /reload/status on port ; transport=HTTP/1.1 encryption= auth= owner=observe [source: authbridge/authlib/observe/statserver.go:62]
- Unknown /stats on port ; transport=HTTP/1.1 encryption= auth= owner=observe [source: authbridge/authlib/observe/statserver.go:60]
### integrations

- DataScienceCluster CR interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read enabled platform components [source: kagenti-operator/config/rbac/role.yaml:2]
- MLflow CR interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read MLflow instances [source: kagenti-operator/config/rbac/role.yaml:2]
- OpenShift Routes interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Dashboard route status [source: kagenti-operator/config/rbac/role.yaml:2]
- cert-manager interaction=Certificate CR role=unknown protocol=HTTPS purpose=Manage TLS certificates through cert-manager CRDs [source: kagenti-operator/config/rbac/role.yaml:2]
### internal_dependencies

- DataScienceCluster CR interaction=CRD Watch role=runtime-integration purpose=Read enabled platform components [source: kagenti-operator/config/rbac/role.yaml:2]
- Envoy proxy interaction=gRPC ExtProc callout role=runtime-transport purpose=Receive per-request processing callouts through the Envoy External Processing API [source: authbridge/cmd/authbridge-envoy/main.go:316]
- MLflow (mlflow.opendatahub.io) interaction=CRD Watch role=runtime-integration purpose=Read MLflow instances [source: kagenti-operator/config/rbac/role.yaml:2]
- cert-manager interaction=CRD CRUD role=unknown purpose=Manage TLS certificates through cert-manager CRDs [source: kagenti-operator/config/rbac/role.yaml:2]
- cert-manager interaction=Certificate and Issuer CRD CRUD role=unknown purpose=Reconcile cert-manager Certificate and Issuer resources [source: kagenti-operator/internal/controller/sharedtrust_controller.go:141]
- cert-manager interaction=Controller watch (conditional) role=runtime-integration purpose=Manage TLS certificates through cert-manager CRDs [source: kagenti-operator/internal/controller/tlsbridge_ca_controller.go:100]
### services

- kagenti-operator-controller-manager-metrics-service port=8443 target=8443 protocol=TCP encryption= auth= [source: kagenti-operator/config/default/metrics_service.yaml:1]
- kagenti-operator-webhook-service port=443 target=9443 protocol=TCP encryption= auth= [source: kagenti-operator/config/webhook/service.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload kagenti-operator-controller-manager uses service account kagenti-operator-controller-manager and 1 container(s) [source: kagenti-operator/config/default/manager_webhook_patch.yaml:1]
- **observed**: Service kagenti-operator-controller-manager-metrics-service targets kagenti-operator-controller-manager with 1 port(s) [source: kagenti-operator/config/default/metrics_service.yaml:1]
- **observed**: Service kagenti-operator-webhook-service targets kagenti-operator-controller-manager with 1 port(s) [source: kagenti-operator/config/webhook/service.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by cmd [source: kagenti-operator/cmd/main.go:889]
- **observed**: HTTP GET /oauth/callback is owned by internal/api [source: token-broker/internal/api/handlers.go:58]
- **observed**: HTTP GET /readyz is owned by cmd [source: kagenti-operator/cmd/main.go:893]
- **observed**: HTTP GET /webhook is owned by cmd [source: kagenti-operator/cmd/main.go:897]
- **observed**: HTTP POST /sessions is owned by internal/api [source: token-broker/internal/api/handlers.go:54]
- **observed**: HTTP POST /sessions/broker-events is owned by internal/api [source: token-broker/internal/api/handlers.go:56]
- **observed**: HTTP POST /sessions/end is owned by internal/api [source: token-broker/internal/api/handlers.go:57]
- **observed**: HTTP POST /sessions/token is owned by internal/api [source: token-broker/internal/api/handlers.go:55]
- **observed**: HTTP Unknown / is owned by agent [source: authbridge/demos/ibac/agent/main.go:799]
- **observed**: HTTP Unknown / is owned by evil-server [source: authbridge/demos/ibac/evil-server/main.go:17]
- **observed**: HTTP Unknown / is owned by finance-agent [source: authbridge/demos/finance-sparc/finance-agent/main.go:464]
- **observed**: HTTP Unknown / is owned by observe [source: authbridge/authlib/observe/statserver.go:65]
- **observed**: HTTP Unknown /.well-known/agent-card.json is owned by agent [source: authbridge/demos/echo/agent/main.go:384]
- **observed**: HTTP Unknown /.well-known/agent-card.json is owned by cmd/test-tls-agent [source: kagenti-operator/cmd/test-tls-agent/main.go:52]
- **observed**: HTTP Unknown /.well-known/agent-card.json is owned by finance-agent [source: authbridge/demos/finance-sparc/finance-agent/main.go:465]
- **observed**: HTTP Unknown /bundles is owned by internal/bundleservice/handler [source: kagenti-operator/internal/bundleservice/handler/handler.go:32]
- **observed**: HTTP Unknown /config is owned by observe [source: authbridge/authlib/observe/statserver.go:59]
- **observed**: HTTP Unknown /echo is owned by upstream [source: authbridge/demos/echo/upstream/main.go:33]
- **observed**: HTTP Unknown /healthz is owned by cmd/test-tls-agent [source: kagenti-operator/cmd/test-tls-agent/main.go:56]
- **observed**: HTTP Unknown /healthz is owned by internal/bundleservice/handler [source: kagenti-operator/internal/bundleservice/handler/handler.go:33]
- **observed**: HTTP Unknown /healthz is owned by main [source: authbridge/cmd/authbridge-proxy/main.go:420]
- **observed**: HTTP Unknown /mcp is owned by email-server [source: authbridge/demos/ibac/email-server/main.go:161]
- **observed**: HTTP Unknown /mcp is owned by finance-mcp [source: authbridge/demos/finance-sparc/finance-mcp/main.go:213]
- **observed**: HTTP Unknown /readyz is owned by internal/bundleservice/handler [source: kagenti-operator/internal/bundleservice/handler/handler.go:34]
- **observed**: HTTP Unknown /readyz is owned by main [source: authbridge/cmd/authbridge-envoy/main.go:269]
- **observed**: HTTP Unknown /reload/status is owned by observe [source: authbridge/authlib/observe/statserver.go:62]
- **observed**: HTTP Unknown /stats is owned by observe [source: authbridge/authlib/observe/statserver.go:60]
### security

- **observed**: ALL gRPC services (Go) uses None at N/A; policy=Bounded grpc.NewServer option set contains only observability interceptors; no authentication interceptor configured [source: authbridge/cmd/authbridge-envoy/main.go:315]
- **observed**: CREATE Operator webhook uses Kubernetes admission at ValidatingWebhookConfiguration; policy=Admission validation [source: kagenti-operator/config/webhook/manifests.yaml:28]
- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: kagenti-operator/cmd/main.go:889]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: kagenti-operator/cmd/main.go:893]
- **observed**: GET :8081/webhook uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: kagenti-operator/cmd/main.go:897]
- **observed**: GET :8443/metrics uses TokenReview + SubjectAccessReview (controller-runtime authn/authz filter) at controller-runtime metrics authn/authz filter; policy=RBAC via kagenti-operator-metrics-auth-role; exposed by Service kagenti-operator-controller-manager-metrics-service; TLS certificate source unresolved [source: kagenti-operator/cmd/main.go:359]
- **observed**: RBAC role kagenti-operator-leader-election-role grants 3 rule(s) [source: kagenti-operator/config/rbac/leader_election_role.yaml:2]
- **observed**: RBAC role kagenti-operator-manager-role grants 33 rule(s) [source: kagenti-operator/config/rbac/role.yaml:2]
- **observed**: RBAC role kagenti-operator-metrics-auth-role grants 2 rule(s) [source: kagenti-operator/config/rbac/metrics_auth_role.yaml:1]
- **observed**: RBAC role kagenti-operator-metrics-reader grants 1 rule(s) [source: kagenti-operator/config/rbac/metrics_reader_role.yaml:1]
- **observed**: RBAC role leader-election-role grants 3 rule(s) [source: kagenti-operator/config/rbac/leader_election_role.yaml:2]
- **observed**: RBAC role manager-role grants 33 rule(s) [source: kagenti-operator/config/rbac/role.yaml:2]
- **observed**: RBAC role metrics-auth-role grants 2 rule(s) [source: kagenti-operator/config/rbac/metrics_auth_role.yaml:1]
- **observed**: RBAC role metrics-reader grants 1 rule(s) [source: kagenti-operator/config/rbac/metrics_reader_role.yaml:1]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=In-cluster configuration provides automatic ServiceAccount token authentication [source: kagenti-operator/cmd/agentcard-signer/main.go:120]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via kagenti-operator-manager-role ClusterRole; SA kagenti-operator-controller-manager [source: kagenti-operator/cmd/main.go:391]
- **observed**: gRPC External Processor gRPC uses None at N/A; policy=Plaintext gRPC service has no application authentication interceptor [source: authbridge/cmd/authbridge-envoy/main.go:316]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: authbridge/authlib/listener/forwardproxy/server.go, authbridge/authlib/listener/forwardproxy/sniff.go, authbridge/authlib/listener/internal/tlssniff/listener.go, authbridge/authlib/listener/reverseproxy/server.go, authbridge/authlib/pipeline/context.go, authbridge/authlib/pipeline/session.go, authbridge/authlib/spiffe/source.go, authbridge/authlib/spiffe/workload_x509.go, authbridge/authlib/tls/client.go, authbridge/authlib/tls/server.go, authbridge/authlib/tlsbridge/minter.go, authbridge/authlib/tlsbridge/serve.go, authbridge/authlib/tlsbridge/terminator.go, authbridge/authlib/tlsbridge/upstream.go, kagenti-operator/cmd/main.go, kagenti-operator/cmd/test-tls-agent/main.go, kagenti-operator/internal/agentcard/fetcher.go, kagenti-operator/internal/bootstrap/otel.go, kagenti-operator/internal/keycloak/admin.go, kagenti-operator/internal/mlflow/client.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
