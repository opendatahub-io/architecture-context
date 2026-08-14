# Analyzer Synthesis Context: odh-dashboard

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 3 crds facts extracted [source: dashboard-operator/config/crd/bases/components.platform.opendatahub.io_dashboards.yaml:2, packages/notebooks/upstream/workspaces/controller/api/v1beta1/workspace_types.go:301, packages/notebooks/upstream/workspaces/controller/api/v1beta1/workspacekind_types.go:650]
- **grpc_services (not-verified)**: 0 grpc_services facts extracted; absence is not proven by the available coverage
- **http_endpoints (observed)**: 48 http_endpoints facts extracted [source: backend/src/app.ts:4, backend/src/routes/module-federation.ts:1, backend/src/routes/root.ts:1, backend/src/routes/wss/k8s/index.ts:73, dashboard-operator/cmd/manager/main.go:130, dashboard-operator/cmd/manager/main.go:134, distributions/core-bff/bff/internal/api/routes.go:1, distributions/core-bff/bff/internal/api/routes.go:94, manifests/rhoai/base/federation-configmap.yaml:120, manifests/rhoai/base/federation-configmap.yaml:141, manifests/rhoai/base/federation-configmap.yaml:15, manifests/rhoai/base/federation-configmap.yaml:162, manifests/rhoai/base/federation-configmap.yaml:36, manifests/rhoai/base/federation-configmap.yaml:57, manifests/rhoai/base/federation-configmap.yaml:78, manifests/rhoai/base/federation-configmap.yaml:99, packages/agent-ops/bff/internal/api/app.go:271, packages/agent-ops/bff/internal/api/app.go:305, packages/agent-ops/bff/internal/api/app.go:34, packages/agent-ops/bff/internal/api/app.go:35, packages/automl/bff/internal/api/app.go:33, packages/automl/bff/internal/api/app.go:375, packages/automl/bff/internal/api/app.go:401, packages/autorag/bff/internal/api/app.go:33, packages/autorag/bff/internal/api/app.go:350, packages/autorag/bff/internal/api/app.go:376, packages/data-registry/bff/internal/api/app.go:197, packages/data-registry/bff/internal/api/app.go:222, packages/eval-hub/bff/internal/api/app.go:292, packages/eval-hub/bff/internal/api/app.go:329, packages/eval-hub/bff/internal/api/app.go:34, packages/gen-ai/bff/internal/api/app.go:549, packages/gen-ai/bff/internal/api/app.go:595, packages/gen-ai/bff/internal/constants/api_constants.go:15, packages/maas/bff/internal/api/app.go:309, packages/maas/bff/internal/api/app.go:337, packages/maas/bff/internal/constants/api_routes.go:4, packages/mlflow/bff/internal/api/app.go:284, packages/mlflow/bff/internal/api/app.go:31, packages/mlflow/bff/internal/api/app.go:312, packages/mlflow/bff/internal/api/app.go:32, packages/model-registry/upstream/bff/internal/api/app.go:31, packages/model-registry/upstream/bff/internal/api/app.go:480, packages/model-registry/upstream/bff/internal/api/app.go:504, packages/notebooks/upstream/workspaces/controller/cmd/main.go:217, packages/notebooks/upstream/workspaces/controller/cmd/main.go:221]
- **services (observed)**: 2 services facts extracted [source: dashboard-operator/config/webhook/manifests.yaml:29, dashboard-operator/config/webhook/manifests.yaml:64]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (observed)**: 5 webhooks facts extracted [source: dashboard-operator/config/webhook/manifests.yaml:1, packages/notebooks/upstream/workspaces/controller/internal/webhook/workspace_webhook.go:44, packages/notebooks/upstream/workspaces/controller/internal/webhook/workspacekind_webhook.go:52, packages/notebooks/upstream/workspaces/controller/manifests/kustomize/base/crd/workspacekinds_webhook_patch.yaml:3, packages/notebooks/upstream/workspaces/controller/manifests/kustomize/base/crd/workspaces_webhook_patch.yaml:3]

## Deterministic Cross-References

- **controller**: WorkspaceKindReconciler —watches-reference→ api/v1beta1/Workspace; api/v1beta1/Workspace [source: packages/notebooks/upstream/workspaces/controller/internal/controller/workspace_controller.go:121, packages/notebooks/upstream/workspaces/controller/internal/controller/workspacekind_controller.go:286]
- **controller**: WorkspaceKindReconciler —watches-reference→ api/v1beta1/WorkspaceKind; api/v1beta1/WorkspaceKind [source: packages/notebooks/upstream/workspaces/controller/internal/controller/workspace_controller.go:146, packages/notebooks/upstream/workspaces/controller/internal/controller/workspacekind_controller.go:285]
- **controller**: WorkspaceReconciler —watches-reference→ /v1/Pod; /v1/Pod [source: dashboard-operator/internal/controller/dashboard_reconciler.go:345, packages/notebooks/upstream/workspaces/controller/internal/controller/workspace_controller.go:494]
- **controller**: WorkspaceReconciler —watches-reference→ /v1/Service; /v1/Service [source: dashboard-operator/internal/controller/actions.go:72, packages/notebooks/upstream/workspaces/controller/internal/controller/workspace_controller.go:481]
- **controller**: WorkspaceReconciler —watches-reference→ api/v1beta1/Workspace; api/v1beta1/Workspace [source: packages/notebooks/upstream/workspaces/controller/internal/controller/workspace_controller.go:121, packages/notebooks/upstream/workspaces/controller/internal/controller/workspace_controller.go:479]
- **controller**: WorkspaceReconciler —watches-reference→ api/v1beta1/WorkspaceKind; api/v1beta1/WorkspaceKind [source: packages/notebooks/upstream/workspaces/controller/internal/controller/workspace_controller.go:146, packages/notebooks/upstream/workspaces/controller/internal/controller/workspace_controller.go:489]
- **controller**: WorkspaceReconciler —watches-reference→ apps/v1/StatefulSet; apps/v1/StatefulSet [source: packages/notebooks/upstream/workspaces/controller/internal/controller/workspace_controller.go:243, packages/notebooks/upstream/workspaces/controller/internal/controller/workspace_controller.go:480]
- **network**: HTTP ALL /_mf/:name/* —served-by→ odh-dashboard-operator-metrics-service; endpoint and service share an explicit owner or port [source: backend/src/routes/module-federation.ts:1, dashboard-operator/config/webhook/manifests.yaml:64]
- **network**: HTTP ALL /api/* —served-by→ odh-dashboard-operator-metrics-service; endpoint and service share an explicit owner or port [source: backend/src/app.ts:4, dashboard-operator/config/webhook/manifests.yaml:64]
- **network**: HTTP GET / —served-by→ odh-dashboard-operator-metrics-service; endpoint and service share an explicit owner or port [source: backend/src/routes/root.ts:1, dashboard-operator/config/webhook/manifests.yaml:64]
- **network**: HTTP WS /wss/k8s/* —served-by→ odh-dashboard-operator-metrics-service; endpoint and service share an explicit owner or port [source: backend/src/routes/wss/k8s/index.ts:73, dashboard-operator/config/webhook/manifests.yaml:64]
- **security**: ALL /api/* —protected-by→ Bearer Token (Authorization header) or internal ServiceAccount token; Go BFF authentication configuration: auth-method flag accepts internal or user_token; token header and Bearer prefix are configurable [source: backend/src/app.ts:4, packages/agent-ops/bff/cmd/main.go:42]
- **security**: ALL /gen-ai/api/v1/* —protected-by→ Bearer Token (x-forwarded-access-token); Go BFF middleware (RequireAccessToService): RBAC and namespace access [source: packages/gen-ai/bff/internal/api/middleware.go:169, packages/gen-ai/bff/internal/constants/api_constants.go:15]
- **security**: ALL /maas/api/v1/* —protected-by→ Bearer Token (x-forwarded-access-token or internal); Go BFF middleware: Internal service account or user token [source: packages/maas/bff/internal/config/environment.go:21, packages/maas/bff/internal/constants/api_routes.go:4]
- **webhook**: validate.dashboards.components.platform.opendatahub.io —served-by→ odh-dashboard-operator-webhook-service; admission webhook declares an explicit service reference [source: dashboard-operator/config/webhook/manifests.yaml:1, dashboard-operator/config/webhook/manifests.yaml:29]

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `backend/src/utils/constants.ts`:18 (/api/* (backend), Bearer Token (x-forwarded-access-token))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `backend/src/utils/proxy.ts`:39 (/api/k8s/*, Bearer Token to K8s Impersonation)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `dashboard-operator/cmd/manager/main.go`:130 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `packages/agent-ops/bff/cmd/main.go`:42 (/api/*, Bearer Token (Authorization header) or internal ServiceAccount token)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `packages/agent-ops/bff/internal/api/middleware.go`:1 (/agent-ops/api/v1/agents/*, Bearer Token + SubjectAccessReview)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `packages/data-registry/bff/cmd/main.go`:42 (/api/*, Bearer Token (Authorization header) or internal ServiceAccount token)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `packages/eval-hub/bff/cmd/main.go`:44 (/api/*, Bearer Token (Authorization header) or internal ServiceAccount token)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `packages/gen-ai/bff/internal/api/middleware.go`:169 (/gen-ai/api/v1/*, Bearer Token (x-forwarded-access-token))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `packages/gen-ai/bff/internal/integrations/kubernetes/otel_config_manager.go`:65 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `packages/maas/bff/cmd/main.go`:41 (/api/*, Bearer Token (Authorization header) or internal ServiceAccount token)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `packages/maas/bff/internal/config/environment.go`:21 (/maas/api/v1/*, Bearer Token (x-forwarded-access-token or internal))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `packages/model-registry/upstream/bff/cmd/main.go`:59 (/api/v1/*, Bearer Token (Authorization header) or internal ServiceAccount token)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `dashboard-operator/config/rbac/role.yaml`:1 (odh-dashboard-operator-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `dashboard-operator/config/rbac/role_binding.yaml`:1 (odh-dashboard-operator-role, odh-dashboard-operator-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:66 (Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:52 (Dockerfile.konflux:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux.agent-ops`:103 (Dockerfile.konflux.agent-ops:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux.automl`:108 (Dockerfile.konflux.automl:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux.autorag`:108 (Dockerfile.konflux.autorag:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux.core-bff`:94 (Dockerfile.konflux.core-bff:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux.dashboard-operator`:37 (Dockerfile.konflux.dashboard-operator:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux.eval-hub`:102 (Dockerfile.konflux.eval-hub:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux.genai`:108 (Dockerfile.konflux.genai:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux.maas`:102 (Dockerfile.konflux.maas:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux.mlflow`:96 (Dockerfile.konflux.mlflow:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux.modelregistry`:99 (Dockerfile.konflux.modelregistry:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `distributions/core-bff/bff/internal/api/app.go`:153 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `distributions/core-bff/bff/internal/api/cluster_info.go`:166 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `distributions/core-bff/bff/internal/integrations/kubernetes/shared_k8s_client.go`:37 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `packages/agent-ops/bff/internal/integrations/kubernetes/internal_k8s_client.go`:64 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `packages/agent-ops/bff/internal/integrations/kubernetes/token_k8s_client.go`:106 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `packages/autox-core/services/kubernetes/client_internal.go`:63 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `packages/autox-core/services/kubernetes/client_token.go`:51 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `packages/eval-hub/bff/internal/api/inferenceservices_handler.go`:94 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `packages/eval-hub/bff/internal/integrations/kubernetes/internal_k8s_client.go`:263 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `packages/eval-hub/bff/internal/integrations/kubernetes/token_k8s_client.go`:186 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `packages/gen-ai/bff/internal/integrations/kubernetes/otel_config_manager.go`:78 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `packages/gen-ai/bff/internal/integrations/mlflow/mlflow_cr.go`:53 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `dashboard-operator/cmd/manager/main.go`:130 (/healthz, GET, cmd/manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `distributions/core-bff/bff/internal/api/routes.go`:94 (/, Unknown, internal/api)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `packages/agent-ops/bff/internal/api/app.go`:271 (/, Unknown, internal/api)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `packages/automl/bff/internal/api/app.go`:375 (/, Unknown, internal/api)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `packages/autorag/bff/internal/api/app.go`:376 (/, Unknown, internal/api)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `packages/data-registry/bff/internal/api/app.go`:222 (/, Unknown, internal/api)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `packages/eval-hub/bff/internal/api/app.go`:329 (/, Unknown, internal/api)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `packages/gen-ai/bff/internal/api/app.go`:549 (/, Unknown, internal/api)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `packages/maas/bff/internal/api/app.go`:309 (/, Unknown, internal/api)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `packages/mlflow/bff/internal/api/app.go`:284 (/, Unknown, internal/api)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `packages/model-registry/upstream/bff/internal/api/app.go`:504 (/, Unknown, internal/api)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `packages/notebooks/upstream/workspaces/controller/cmd/main.go`:217 (/healthz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `dashboard-operator/charts/dashboard/values.yaml`:18 (CRD Watch (Dashboard CR), rhods-operator / opendatahub-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `dashboard-operator/config/rbac/role.yaml`:1 (CRD Watch, DataScienceCluster CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `dashboard-operator/config/webhook/manifests.yaml`:51 (Certificate CR, cert-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `packages/gen-ai/bff/internal/constants/mcp.go`:11 (MCP Servers, SSE/Streamable HTTP)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `dashboard-operator/api/v1alpha1/dashboard_types.go`:4 (Go library, odh-platform-utilities)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `dashboard-operator/charts/dashboard/values.yaml`:18 (CRD Watch, rhods-operator / opendatahub-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `dashboard-operator/config/rbac/role.yaml`:1 (CRD Watch, DataScienceCluster CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `dashboard-operator/go.mod` (Go Library, odh-platform-utilities)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `dashboard-operator/internal/controller/config.go`:40 (/v1/ConfigMap, create, delete, get, list, update operations by App, ClusterSettingsRepository, ConnectionTypeRepository, DashboardReconciler, ModelRegistrySettingsRepository, SharedClientLogic, TokenKubernetesClient, TokenKubernetesClientMock, WorkspaceKindReconciler, WorkspaceKindRepository)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `packages/eval-hub/bff/internal/api/inferenceservices_handler.go`:101 (CRD Watch, KServe InferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `packages/eval-hub/bff/internal/integrations/kubernetes/internal_k8s_client.go`:269 (CRD Watch, TrustyAI (trustyai.opendatahub.io))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `packages/gen-ai/bff/internal/integrations/kubernetes/k8smocks/base_testenv.go`:536 (/v1/Namespace, create, get, list operations by NamespaceRepository, TokenKubernetesClient, TokenKubernetesClientMock)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `packages/gen-ai/bff/internal/integrations/mlflow/client.go`:6 (Go library, mlflow-go)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `packages/gen-ai/bff/internal/integrations/mlflow/mlflow_cr.go`:61 (CRD Watch, MLflow (mlflow.opendatahub.io))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `packages/model-registry/upstream/bff/internal/redhat/repositories/model_registry_settings_repository.go`:110 (CRD CRUD, ModelRegistry (modelregistry.opendatahub.io))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `packages/notebooks/upstream/workspaces/controller/internal/controller/workspace_controller.go`:1218 (/v1/Event, list operations by WorkspaceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `dashboard-operator/internal/controller/actions.go`:72 (/v1/Service, get, list operations by DashboardReconciler, TokenKubernetesClient, WorkspaceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `dashboard-operator/internal/controller/config.go`:40 (/v1/ConfigMap, create, delete, get, list, update operations by App, ClusterSettingsRepository, ConnectionTypeRepository, DashboardReconciler, ModelRegistrySettingsRepository, SharedClientLogic, TokenKubernetesClient, TokenKubernetesClientMock, WorkspaceKindReconciler, WorkspaceKindRepository)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `dashboard-operator/internal/controller/dashboard_reconciler.go`:345 (/v1/Pod, list operations by DashboardReconciler, PVCRepository)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `dashboard-operator/internal/controller/dashboard_reconciler.go`:994 (/v1/ConfigMap)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `distributions/core-bff/bff/internal/repositories/nim.go`:189 (/v1/Secret, create, delete, get, update operations by ModelRegistrySettingsRepository, NIMRepository, SharedClientLogic, TokenKubernetesClient, TokenKubernetesClientMock)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `packages/agent-ops/bff/internal/integrations/agents/kubernetes/sandbox.go`:19 (agents.x-k8s.io/v1beta1/sandboxes, get, list operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `packages/gen-ai/bff/internal/integrations/kubernetes/k8smocks/base_testenv.go`:536 (/v1/Namespace, create, get, list operations by NamespaceRepository, TokenKubernetesClient, TokenKubernetesClientMock)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `packages/notebooks/upstream/workspaces/backend/internal/helper/validation.go`:208 (/v1/PersistentVolumeClaim, create, delete, get, list operations by PVCRepository)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `packages/notebooks/upstream/workspaces/backend/internal/repositories/pvcs/repo.go`:94 (/v1/PersistentVolume, get operations by PVCRepository)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `packages/notebooks/upstream/workspaces/controller/internal/controller/workspace_controller.go`:1218 (/v1/Event, list operations by WorkspaceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `packages/notebooks/upstream/workspaces/controller/internal/controller/workspace_controller.go`:494 (/v1/Pod, WorkspaceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `packages/notebooks/upstream/workspaces/controller/internal/controller/workspacekind_controller.go`:285 (WorkspaceKindReconciler, api/v1beta1/WorkspaceKind)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `dashboard-operator/config/manager/manager.yaml`:1 (odh-dashboard-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `dashboard-operator/config/webhook/manifests.yaml`:29 (odh-dashboard-operator, odh-dashboard-operator-webhook-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### webhooks

- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `dashboard-operator/config/webhook/manifests.yaml`:1 (/validate-dashboard, validate.dashboards.components.platform.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `packages/notebooks/upstream/workspaces/controller/internal/webhook/workspace_webhook.go`:44 (/validate-kubeflow-org-v1beta1-workspace, vworkspace.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `packages/notebooks/upstream/workspaces/controller/internal/webhook/workspacekind_webhook.go`:52 (/validate-kubeflow-org-v1beta1-workspacekind, vworkspacekind.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `packages/notebooks/upstream/workspaces/controller/manifests/kustomize/base/crd/workspacekinds_webhook_patch.yaml`:3 (/convert, workspacekinds.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `packages/notebooks/upstream/workspaces/controller/manifests/kustomize/base/crd/workspaces_webhook_patch.yaml`:3 (/convert, workspacekinds.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- /agent-ops/api/v1/agents/* methods=GET mechanism=Bearer Token + SubjectAccessReview enforcement=Go BFF middleware (RequireAccessToAgent) policy=Per-agent RBAC via SSAR [source: packages/agent-ops/bff/internal/api/middleware.go:1]
- /api/* (backend) methods=ALL mechanism=Bearer Token (x-forwarded-access-token) enforcement=Node.js backend middleware policy=Route-specific user or admin authorization [source: backend/src/utils/constants.ts:18]
- /api/* methods=ALL mechanism=Bearer Token (Authorization header) or internal ServiceAccount token enforcement=Go BFF authentication configuration policy=auth-method flag accepts internal or user_token; token header and Bearer prefix are configurable [source: packages/eval-hub/bff/cmd/main.go:44]
- /api/* methods=ALL mechanism=Bearer Token (Authorization header) or internal ServiceAccount token enforcement=Go BFF authentication configuration policy=auth-method flag accepts internal or user_token; token header and Bearer prefix are configurable [source: packages/agent-ops/bff/cmd/main.go:42]
- /api/* methods=ALL mechanism=Bearer Token (Authorization header) or internal ServiceAccount token enforcement=Go BFF authentication configuration policy=auth-method flag accepts internal or user_token; token header and Bearer prefix are configurable [source: packages/data-registry/bff/cmd/main.go:42]
- /api/* methods=ALL mechanism=Bearer Token (Authorization header) or internal ServiceAccount token enforcement=Go BFF authentication configuration policy=auth-method flag accepts internal or user_token; token header and Bearer prefix are configurable [source: packages/maas/bff/cmd/main.go:41]
- /api/k8s/* methods=ALL mechanism=Bearer Token to K8s Impersonation enforcement=Node.js proxy to K8s API policy=User Kubernetes RBAC [source: backend/src/utils/proxy.ts:39]
- /api/v1/* methods=ALL mechanism=Bearer Token (Authorization header) or internal ServiceAccount token enforcement=Go BFF authentication configuration policy=auth-method flag accepts internal or user_token; token header and Bearer prefix are configurable [source: packages/model-registry/upstream/bff/cmd/main.go:59]
- /gen-ai/api/v1/* methods=ALL mechanism=Bearer Token (x-forwarded-access-token) enforcement=Go BFF middleware (RequireAccessToService) policy=RBAC and namespace access [source: packages/gen-ai/bff/internal/api/middleware.go:169]
- /maas/api/v1/* methods=ALL mechanism=Bearer Token (x-forwarded-access-token or internal) enforcement=Go BFF middleware policy=Internal service account or user token [source: packages/maas/bff/internal/config/environment.go:21]
- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: dashboard-operator/cmd/manager/main.go:130]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: dashboard-operator/cmd/manager/main.go:134]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=In-cluster configuration provides automatic ServiceAccount token authentication [source: packages/gen-ai/bff/internal/integrations/kubernetes/otel_config_manager.go:65]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via odh-dashboard-operator-role ClusterRole; SA odh-dashboard-operator [source: dashboard-operator/cmd/manager/main.go:101]
- Operator webhook methods=CREATE mechanism=Kubernetes admission enforcement=ValidatingWebhookConfiguration policy=Admission validation [source: dashboard-operator/config/webhook/manifests.yaml:1]
### http_endpoints

- ALL /_bff/mlflow/api/* on port 8343; transport= encryption=TLS auth=user_token owner= [source: manifests/rhoai/base/federation-configmap.yaml:78]
- ALL /_bff/mlflow/api/v1/* on port 8343; transport= encryption=TLS auth=user_token owner= [source: packages/mlflow/bff/internal/api/app.go:32]
- ALL /_mf/:name/* on port 8443; transport= encryption=TLS (kube-rbac-proxy) auth=user_token owner= [source: backend/src/routes/module-federation.ts:1]
- ALL /agent-ops/api/* on port 8843; transport= encryption=TLS auth=user_token owner= [source: manifests/rhoai/base/federation-configmap.yaml:162]
- ALL /agent-ops/api/v1/* on port 8843; transport= encryption=TLS auth=user_token owner= [source: packages/agent-ops/bff/internal/api/app.go:35]
- ALL /api/* on port 8443; transport= encryption=TLS (kube-rbac-proxy) auth=OpenShift project list + user_token owner= [source: backend/src/app.ts:4]
- ALL /automl/api/* on port 8643; transport= encryption=TLS auth=user_token owner= [source: manifests/rhoai/base/federation-configmap.yaml:120]
- ALL /automl/api/v1/* on port 8643; transport= encryption=TLS auth=user_token owner= [source: packages/automl/bff/internal/api/app.go:33]
- ALL /autorag/api/* on port 8743; transport= encryption=TLS auth=user_token owner= [source: manifests/rhoai/base/federation-configmap.yaml:141]
- ALL /autorag/api/v1/* on port 8743; transport= encryption=TLS auth=user_token owner= [source: packages/autorag/bff/internal/api/app.go:33]
- ALL /eval-hub/api/* on port 8543; transport= encryption=TLS auth=user_token owner= [source: manifests/rhoai/base/federation-configmap.yaml:99]
- ALL /eval-hub/api/v1/* on port 8543; transport= encryption=TLS auth=user_token owner= [source: packages/eval-hub/bff/internal/api/app.go:34]
- ALL /gen-ai/api/* on port 8143; transport= encryption=TLS auth=user_token owner= [source: manifests/rhoai/base/federation-configmap.yaml:36]
- ALL /gen-ai/api/v1/* on port 8143; transport= encryption=TLS auth=user_token owner= [source: packages/gen-ai/bff/internal/constants/api_constants.go:15]
- ALL /maas/api/* on port 8243; transport= encryption=TLS auth=user_token owner= [source: manifests/rhoai/base/federation-configmap.yaml:57]
- GET / on port 8443; transport= encryption=TLS (kube-rbac-proxy) auth=OpenShift project list owner= [source: backend/src/routes/root.ts:1]
- GET /healthcheck on port 8080; transport= encryption=None auth=None owner= [source: distributions/core-bff/bff/internal/api/routes.go:1]
- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: packages/notebooks/upstream/workspaces/controller/cmd/main.go:217]
- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/manager [source: dashboard-operator/cmd/manager/main.go:130]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: packages/notebooks/upstream/workspaces/controller/cmd/main.go:221]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/manager [source: dashboard-operator/cmd/manager/main.go:134]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=internal/api [source: packages/autorag/bff/internal/api/app.go:350]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=internal/api [source: packages/model-registry/upstream/bff/internal/api/app.go:504]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=internal/api [source: packages/mlflow/bff/internal/api/app.go:284]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=internal/api [source: packages/maas/bff/internal/api/app.go:337]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=internal/api [source: packages/maas/bff/internal/api/app.go:309]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=internal/api [source: packages/gen-ai/bff/internal/api/app.go:595]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=internal/api [source: packages/gen-ai/bff/internal/api/app.go:549]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=internal/api [source: packages/mlflow/bff/internal/api/app.go:312]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=internal/api [source: packages/model-registry/upstream/bff/internal/api/app.go:480]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=internal/api [source: packages/data-registry/bff/internal/api/app.go:222]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=internal/api [source: packages/data-registry/bff/internal/api/app.go:197]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=internal/api [source: packages/eval-hub/bff/internal/api/app.go:292]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=internal/api [source: packages/eval-hub/bff/internal/api/app.go:329]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=internal/api [source: packages/automl/bff/internal/api/app.go:401]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=internal/api [source: packages/automl/bff/internal/api/app.go:375]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=internal/api [source: packages/agent-ops/bff/internal/api/app.go:305]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=internal/api [source: packages/agent-ops/bff/internal/api/app.go:271]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=internal/api [source: distributions/core-bff/bff/internal/api/routes.go:94]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=internal/api [source: packages/autorag/bff/internal/api/app.go:376]
### integrations

- AcceleratorProfile CR interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage hardware accelerator profiles [source: dashboard-operator/config/rbac/role.yaml:1]
- DSCInitialization CR interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read platform initialization state [source: dashboard-operator/config/rbac/role.yaml:1]
- DataScienceCluster CR interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read enabled platform components [source: dashboard-operator/config/rbac/role.yaml:1]
- Feast FeatureStore CR interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read feature store instances [source: dashboard-operator/config/rbac/role.yaml:1]
- Gateway API interaction=HTTPRoute CRUD role=runtime-transport protocol=HTTPS purpose=Manage Gateway API routing resources [source: dashboard-operator/config/rbac/role.yaml:1]
- HardwareProfile CR interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage hardware profile resources [source: dashboard-operator/config/rbac/role.yaml:1]
- KServe InferenceService interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read model serving state [source: dashboard-operator/config/rbac/role.yaml:1]
- Kubeflow Notebooks interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Create and manage notebook workbenches [source: dashboard-operator/config/rbac/role.yaml:1]
- Kubernetes API interaction=API client role=runtime-integration protocol=HTTPS purpose=Cluster resource management via RBAC [source: dashboard-operator/config/rbac/role.yaml:1]
- MCP Servers interaction=SSE/Streamable HTTP role=runtime-transport protocol=SSE/streamable HTTP purpose=Tool discovery and invocation [source: packages/gen-ai/bff/internal/constants/mcp.go:11]
- MLflow CR interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read MLflow instances [source: dashboard-operator/config/rbac/role.yaml:1]
- ModelRegistry CR interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage model registry instances [source: dashboard-operator/config/rbac/role.yaml:1]
- NIM Account CR interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage NVIDIA NIM account configuration [source: dashboard-operator/config/rbac/role.yaml:1]
- OLM (operators.coreos.com) interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Operator subscription status [source: dashboard-operator/config/rbac/role.yaml:1]
- OpenShift Console interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Console link resources [source: dashboard-operator/config/rbac/role.yaml:1]
- OpenShift Image Streams interaction=REST role=runtime-transport protocol=HTTPS purpose=Image stream access [source: dashboard-operator/config/rbac/role.yaml:1]
- OpenShift Routes interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Dashboard route status [source: dashboard-operator/config/rbac/role.yaml:1]
- OpenShift Users/Groups interaction=REST role=runtime-transport protocol=HTTPS purpose=User and group management [source: dashboard-operator/config/rbac/role.yaml:1]
- ServingRuntime CR interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage serving runtime templates [source: dashboard-operator/config/rbac/role.yaml:1]
- TrustyAI CRs interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read TrustyAI service resources [source: dashboard-operator/config/rbac/role.yaml:1]
- cert-manager interaction=Certificate CR role=unknown protocol=HTTPS purpose=Webhook and metrics TLS certificates [source: dashboard-operator/config/webhook/manifests.yaml:51]
- prometheus-operator interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage Prometheus monitoring resources [source: dashboard-operator/config/rbac/role.yaml:1]
- rhods-operator / opendatahub-operator interaction=CRD Watch (Dashboard CR) role=runtime-integration protocol=HTTPS purpose=Operator creates Dashboard CR; dashboard-operator reconciles it [source: dashboard-operator/charts/dashboard/values.yaml:18]
### internal_dependencies

- DSCInitialization CR interaction=CRD Watch role=runtime-integration purpose=Read platform initialization state [source: dashboard-operator/config/rbac/role.yaml:1]
- DataScienceCluster CR interaction=CRD Watch role=runtime-integration purpose=Read enabled platform components [source: dashboard-operator/config/rbac/role.yaml:1]
- Feast (feast.dev) interaction=CRD Watch role=runtime-integration purpose=Read feature store instances [source: dashboard-operator/config/rbac/role.yaml:1]
- Gateway API interaction=CRD CRUD role=unknown purpose=Manage Gateway API routing resources [source: dashboard-operator/config/rbac/role.yaml:1]
- HardwareProfile CR interaction=CRD CRUD role=unknown purpose=Manage hardware profile resources [source: dashboard-operator/config/rbac/role.yaml:1]
- KServe InferenceService interaction=CRD Watch role=runtime-integration purpose=Read model serving state [source: dashboard-operator/config/rbac/role.yaml:1]
- KServe InferenceService interaction=CRD Watch role=runtime-integration purpose=Read model serving state [source: packages/eval-hub/bff/internal/api/inferenceservices_handler.go:101]
- Kubeflow Notebooks (kubeflow.org) interaction=CRD CRUD role=unknown purpose=Create and manage notebook workbenches [source: dashboard-operator/config/rbac/role.yaml:1]
- Kubernetes API (nodes) interaction=list role=unknown purpose=nodes resource access via RBAC [source: dashboard-operator/config/rbac/role.yaml:1]
- MLflow (mlflow.opendatahub.io) interaction=CRD Watch role=runtime-integration purpose=Read MLflow instances [source: dashboard-operator/config/rbac/role.yaml:1]
- MLflow (mlflow.opendatahub.io) interaction=CRD Watch role=runtime-integration purpose=Read MLflow instances [source: packages/gen-ai/bff/internal/integrations/mlflow/mlflow_cr.go:61]
- ModelRegistry (modelregistry.opendatahub.io) interaction=CRD CRUD role=unknown purpose=Manage model registry instances [source: dashboard-operator/config/rbac/role.yaml:1]
- ModelRegistry (modelregistry.opendatahub.io) interaction=CRD CRUD role=unknown purpose=Manage model registry instances [source: packages/model-registry/upstream/bff/internal/redhat/repositories/model_registry_settings_repository.go:110]
- TrustyAI (trustyai.opendatahub.io) interaction=CRD Watch role=runtime-integration purpose=Read TrustyAI service resources [source: dashboard-operator/config/rbac/role.yaml:1]
- TrustyAI (trustyai.opendatahub.io) interaction=CRD Watch role=runtime-integration purpose=Read TrustyAI service resources [source: packages/eval-hub/bff/internal/integrations/kubernetes/internal_k8s_client.go:269]
- mlflow-go interaction=Go library role=runtime-library purpose=Use runtime packages from github.com/opendatahub-io/mlflow-go [source: packages/gen-ai/bff/internal/integrations/mlflow/client.go:6]
- odh-platform-utilities interaction=Go Library role=runtime-library purpose=Platform detection, manifest rendering, and deployment helpers [source: dashboard-operator/go.mod]
- odh-platform-utilities interaction=Go library role=runtime-library purpose=Use runtime packages from github.com/opendatahub-io/odh-platform-utilities [source: dashboard-operator/api/v1alpha1/dashboard_types.go:4]
- prometheus-operator interaction=CRD CRUD role=unknown purpose=Manage Prometheus monitoring resources [source: dashboard-operator/config/rbac/role.yaml:1]
- rhods-operator / opendatahub-operator interaction=CRD Watch role=runtime-integration purpose=Creates and owns the Dashboard custom resource [source: dashboard-operator/charts/dashboard/values.yaml:18]
### services

- odh-dashboard-operator-metrics-service port=8443 target=8443 protocol=TCP encryption= auth= [source: dashboard-operator/config/webhook/manifests.yaml:64]
- odh-dashboard-operator-webhook-service port=443 target=9443 protocol=TCP encryption= auth= [source: dashboard-operator/config/webhook/manifests.yaml:29]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload odh-dashboard-operator uses service account odh-dashboard-operator and 1 container(s) [source: dashboard-operator/config/manager/manager.yaml:1]
- **observed**: Service odh-dashboard-operator-metrics-service targets odh-dashboard-operator with 1 port(s) [source: dashboard-operator/config/webhook/manifests.yaml:64]
- **observed**: Service odh-dashboard-operator-webhook-service targets odh-dashboard-operator with 1 port(s) [source: dashboard-operator/config/webhook/manifests.yaml:29]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by cmd [source: packages/notebooks/upstream/workspaces/controller/cmd/main.go:217]
- **observed**: HTTP GET /healthz is owned by cmd/manager [source: dashboard-operator/cmd/manager/main.go:130]
- **observed**: HTTP GET /readyz is owned by cmd [source: packages/notebooks/upstream/workspaces/controller/cmd/main.go:221]
- **observed**: HTTP GET /readyz is owned by cmd/manager [source: dashboard-operator/cmd/manager/main.go:134]
- **observed**: HTTP Unknown / is owned by internal/api [source: packages/data-registry/bff/internal/api/app.go:222]
### security

- **observed**: ALL /api/* (backend) uses Bearer Token (x-forwarded-access-token) at Node.js backend middleware; policy=Route-specific user or admin authorization [source: backend/src/utils/constants.ts:18]
- **observed**: ALL /api/* uses Bearer Token (Authorization header) or internal ServiceAccount token at Go BFF authentication configuration; policy=auth-method flag accepts internal or user_token; token header and Bearer prefix are configurable [source: packages/agent-ops/bff/cmd/main.go:42]
- **observed**: ALL /api/k8s/* uses Bearer Token to K8s Impersonation at Node.js proxy to K8s API; policy=User Kubernetes RBAC [source: backend/src/utils/proxy.ts:39]
- **observed**: ALL /api/v1/* uses Bearer Token (Authorization header) or internal ServiceAccount token at Go BFF authentication configuration; policy=auth-method flag accepts internal or user_token; token header and Bearer prefix are configurable [source: packages/model-registry/upstream/bff/cmd/main.go:59]
- **observed**: ALL /gen-ai/api/v1/* uses Bearer Token (x-forwarded-access-token) at Go BFF middleware (RequireAccessToService); policy=RBAC and namespace access [source: packages/gen-ai/bff/internal/api/middleware.go:169]
- **observed**: ALL /maas/api/v1/* uses Bearer Token (x-forwarded-access-token or internal) at Go BFF middleware; policy=Internal service account or user token [source: packages/maas/bff/internal/config/environment.go:21]
- **observed**: CREATE Operator webhook uses Kubernetes admission at ValidatingWebhookConfiguration; policy=Admission validation [source: dashboard-operator/config/webhook/manifests.yaml:1]
- **observed**: GET /agent-ops/api/v1/agents/* uses Bearer Token + SubjectAccessReview at Go BFF middleware (RequireAccessToAgent); policy=Per-agent RBAC via SSAR [source: packages/agent-ops/bff/internal/api/middleware.go:1]
- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: dashboard-operator/cmd/manager/main.go:130]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: dashboard-operator/cmd/manager/main.go:134]
- **observed**: RBAC role dashboard-operator-role grants 59 rule(s) [source: dashboard-operator/config/rbac/role.yaml:1]
- **observed**: RBAC role odh-dashboard-operator-role grants 59 rule(s) [source: dashboard-operator/config/rbac/role.yaml:1]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=In-cluster configuration provides automatic ServiceAccount token authentication [source: packages/gen-ai/bff/internal/integrations/kubernetes/otel_config_manager.go:65]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via odh-dashboard-operator-role ClusterRole; SA odh-dashboard-operator [source: dashboard-operator/cmd/manager/main.go:101]
- **literal**: rbac-ref targets SelfSubjectAccessReviews: Token or subject access review call [source: distributions/core-bff/bff/internal/integrations/kubernetes/token_k8s_client.go:134, distributions/core-bff/bff/internal/integrations/kubernetes/token_k8s_client.go:165, distributions/core-bff/bff/internal/integrations/kubernetes/token_k8s_client.go:260, distributions/core-bff/bff/internal/integrations/kubernetes/token_k8s_client.go:283, distributions/core-bff/bff/internal/integrations/kubernetes/token_k8s_client.go:44, packages/agent-ops/bff/internal/integrations/kubernetes/agent_rbac.go:72, packages/agent-ops/bff/internal/integrations/kubernetes/token_k8s_client.go:129, packages/agent-ops/bff/internal/integrations/kubernetes/token_k8s_client.go:160, packages/agent-ops/bff/internal/integrations/kubernetes/token_k8s_client.go:43, packages/autox-core/services/kubernetes/client_base.go:125, packages/autox-core/services/kubernetes/client_base.go:149, packages/data-registry/bff/internal/integrations/kubernetes/token_k8s_client.go:117, packages/data-registry/bff/internal/integrations/kubernetes/token_k8s_client.go:148, packages/data-registry/bff/internal/integrations/kubernetes/token_k8s_client.go:42, packages/eval-hub/bff/internal/integrations/kubernetes/token_k8s_client.go:121, packages/eval-hub/bff/internal/integrations/kubernetes/token_k8s_client.go:152, packages/eval-hub/bff/internal/integrations/kubernetes/token_k8s_client.go:284, packages/eval-hub/bff/internal/integrations/kubernetes/token_k8s_client.go:46, packages/gen-ai/bff/internal/integrations/kubernetes/token_k8s_client.go:186, packages/gen-ai/bff/internal/integrations/kubernetes/token_k8s_client.go:399, packages/gen-ai/bff/internal/integrations/kubernetes/token_k8s_client.go:443, packages/gen-ai/bff/internal/integrations/kubernetes/token_k8s_client.go:487, packages/maas/bff/internal/integrations/kubernetes/token_k8s_client.go:117, packages/maas/bff/internal/integrations/kubernetes/token_k8s_client.go:148, packages/maas/bff/internal/integrations/kubernetes/token_k8s_client.go:235, packages/maas/bff/internal/integrations/kubernetes/token_k8s_client.go:45, packages/mlflow/bff/internal/integrations/kubernetes/token_k8s_client.go:177, packages/mlflow/bff/internal/integrations/kubernetes/token_k8s_client.go:43, packages/model-registry/upstream/bff/internal/integrations/kubernetes/token_k8s_client.go:109, packages/model-registry/upstream/bff/internal/integrations/kubernetes/token_k8s_client.go:139, packages/model-registry/upstream/bff/internal/integrations/kubernetes/token_k8s_client.go:220, packages/model-registry/upstream/bff/internal/integrations/kubernetes/token_k8s_client.go:252, packages/model-registry/upstream/bff/internal/integrations/kubernetes/token_k8s_client.go:42]
- **literal**: rbac-ref targets SubjectAccessReviews: Token or subject access review call [source: packages/agent-ops/bff/internal/integrations/kubernetes/agent_rbac.go:40, packages/agent-ops/bff/internal/integrations/kubernetes/internal_k8s_client.go:142, packages/agent-ops/bff/internal/integrations/kubernetes/internal_k8s_client.go:257, packages/data-registry/bff/internal/integrations/kubernetes/internal_k8s_client.go:119, packages/eval-hub/bff/internal/integrations/kubernetes/internal_k8s_client.go:121, packages/eval-hub/bff/internal/integrations/kubernetes/internal_k8s_client.go:241, packages/maas/bff/internal/integrations/kubernetes/internal_k8s_client.go:128, packages/model-registry/upstream/bff/internal/integrations/kubernetes/internal_k8s_client.go:129, packages/model-registry/upstream/bff/internal/integrations/kubernetes/internal_k8s_client.go:169, packages/model-registry/upstream/bff/internal/integrations/kubernetes/internal_k8s_client.go:261, packages/model-registry/upstream/bff/internal/integrations/kubernetes/internal_k8s_client.go:65, packages/model-registry/upstream/bff/internal/integrations/kubernetes/internal_k8s_client.go:97, packages/model-registry/upstream/bff/internal/integrations/kubernetes/namespace_registry_access.go:46]
- **dependency-signal**: rbac-ref targets k8s.io/apiserver/pkg/authorization/authorizer: RBAC/authorization API import [source: packages/notebooks/upstream/workspaces/backend/api/app.go, packages/notebooks/upstream/workspaces/backend/api/auth.go, packages/notebooks/upstream/workspaces/backend/internal/auth/authorization.go]
- **dependency-signal**: rbac-ref targets k8s.io/client-go/kubernetes/typed/authorization/v1: RBAC/authorization API import [source: packages/notebooks/upstream/workspaces/backend/internal/auth/authorization.go]
- **literal**: rbac-ref targets selfSubjectAccessReviewGroup: Token or subject access review call [source: packages/agent-ops/bff/internal/integrations/kubernetes/agent_enrichment_rbac.go:44]
- **literal**: rbac-ref targets subjectAccessReviewGroup: Token or subject access review call [source: packages/agent-ops/bff/internal/integrations/kubernetes/agent_enrichment_rbac.go:28]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: dashboard-operator/cmd/manager/main.go, distributions/core-bff/bff/cmd/main.go, distributions/core-bff/bff/internal/api/app_proxy.go, distributions/core-bff/bff/internal/api/app_tls.go, distributions/core-bff/bff/internal/api/connection_test_probes.go, distributions/core-bff/bff/internal/integrations/bffclient/client.go, distributions/core-bff/bff/internal/integrations/httpclient/http.go, distributions/core-bff/bff/internal/proxy/factory.go, distributions/core-bff/bff/internal/proxy/k8s_proxy.go, distributions/core-bff/bff/internal/proxy/ws_proxy.go, distributions/core-bff/bff/internal/repositories/prometheus.go, packages/agent-ops/bff/cmd/main.go, packages/agent-ops/bff/internal/integrations/bffclient/client.go, packages/agent-ops/bff/internal/integrations/httpclient/http.go, packages/automl/bff/cmd/main.go, packages/automl/bff/internal/integrations/modelregistry/client.go, packages/autorag/bff/cmd/main.go, packages/autorag/bff/internal/integrations/ogx/ogx_client.go, packages/autox-core/services/pipelines/client.go, packages/autox-core/services/s3/client.go, packages/data-registry/bff/cmd/main.go, packages/data-registry/bff/internal/integrations/bffclient/client.go, packages/data-registry/bff/internal/integrations/httpclient/http.go, packages/data-registry/bff/internal/proxy/tls.go, packages/data-registry/bff/internal/proxy/websocket.go, packages/eval-hub/bff/cmd/main.go, packages/eval-hub/bff/internal/integrations/bffclient/client.go, packages/eval-hub/bff/internal/integrations/connectionprobe/client.go, packages/eval-hub/bff/internal/integrations/evalhub/evalhub_client.go, packages/eval-hub/bff/internal/integrations/httpclient/http.go, packages/gen-ai/bff/cmd/main.go, packages/gen-ai/bff/internal/api/app.go, packages/gen-ai/bff/internal/integrations/bffclient/client.go, packages/gen-ai/bff/internal/integrations/externalmodels/client.go, packages/gen-ai/bff/internal/integrations/http.go, packages/gen-ai/bff/internal/integrations/kubernetes/otel_config_manager.go, packages/gen-ai/bff/internal/integrations/llamastack/llamastack_client.go, packages/gen-ai/bff/internal/integrations/mcp/transport_factory.go, packages/gen-ai/bff/internal/integrations/mlflow/factory.go, packages/gen-ai/bff/internal/integrations/nemo/nemo_client.go, packages/maas/bff/cmd/main.go, packages/maas/bff/internal/helpers/maas_discovery.go, packages/maas/bff/internal/integrations/httpclient/http.go, packages/maas/bff/internal/integrations/maas/maas_client.go, packages/mlflow/bff/cmd/main.go, packages/mlflow/bff/internal/integrations/mlflow/factory.go, packages/model-registry/upstream/bff/cmd/main.go, packages/model-registry/upstream/bff/internal/integrations/httpclient/http.go, packages/notebooks/upstream/workspaces/controller/cmd/main.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
