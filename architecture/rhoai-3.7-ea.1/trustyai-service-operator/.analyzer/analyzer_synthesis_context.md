# Analyzer Synthesis Context: trustyai-service-operator

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 7 crds facts extracted [source: api/evalhub/v1/evalhub_types.go:28, api/evalhub/v1alpha1/evalhub_types.go:15, api/lmes/v1alpha1/lmevaljob_types.go:750, api/nemo_guardrails/v1alpha1/nemoguardrails_types.go:189, api/tas/v1/trustyaiservice_types.go:12, api/tas/v1alpha1/trustyaiservice_types.go:27, trustyai-operator-module/config/crd/bases/components.platform.opendatahub.io_trustyais.yaml:2]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 4 http_endpoints facts extracted [source: cmd/main.go:220, cmd/main.go:224, trustyai-operator-module/cmd/trustyai-operator-module/main.go:85, trustyai-operator-module/cmd/trustyai-operator-module/main.go:89]
- **services (observed)**: 1 services facts extracted [source: controllers/tas/templates/service/service-tls.tmpl.yaml:1]
- **ingress (observed)**: 2 ingress facts extracted [source: controllers/tas/templates/service/route.tmpl.yaml:1, controllers/tas/templates/service/virtual-service.tmpl.yaml:1]
- **webhooks (observed)**: 1 webhooks facts extracted [source: config/components/evalhub/patches/webhook_in_evalhubs.yaml:2, config/components/tas/patches/webhook_in_trustyaiservices.yaml:2]

## Deterministic Cross-References

- **controller**: EvalHubReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: controllers/dsc/config.go:49, controllers/evalhub/evalhub_controller.go:399]
- **controller**: EvalHubReconciler —watches-reference→ /v1/Namespace; /v1/Namespace [source: controllers/evalhub/evalhub_controller.go:183, controllers/evalhub/evalhub_controller.go:400]
- **controller**: EvalHubReconciler —watches-reference→ /v1/Service; /v1/Service [source: controllers/evalhub/evalhub_controller.go:398, controllers/evalhub/mcp_service.go:42]
- **controller**: EvalHubReconciler —watches-reference→ api/evalhub/v1/EvalHub; api/evalhub/v1/EvalHub [source: controllers/evalhub/evalhub_controller.go:395, controllers/evalhub/evalhub_controller.go:86]
- **controller**: EvalHubReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: controllers/evalhub/deployment.go:37, controllers/evalhub/evalhub_controller.go:396]
- **controller**: EvalHubReconciler —watches-reference→ networking.k8s.io/v1/NetworkPolicy; networking.k8s.io/v1/NetworkPolicy [source: controllers/evalhub/evalhub_controller.go:397, controllers/lmes/network_policy.go:230]
- **controller**: LMEvalJobReconciler —watches-reference→ /v1/Pod; /v1/Pod [source: controllers/evalhub/evaluation_job_failure_reconciler.go:543, controllers/lmes/lmevaljob_controller.go:358]
- **controller**: LMEvalJobReconciler —watches-reference→ api/lmes/v1alpha1/LMEvalJob; api/lmes/v1alpha1/LMEvalJob [source: controllers/lmes/lmevaljob_controller.go:188, controllers/lmes/lmevaljob_controller.go:351]
- **controller**: LMEvalJobReconciler —watches-reference→ networking.k8s.io/v1/NetworkPolicy; networking.k8s.io/v1/NetworkPolicy [source: controllers/lmes/lmevaljob_controller.go:357, controllers/lmes/network_policy.go:230]
- **controller**: NemoGuardrailsReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: controllers/dsc/config.go:49, controllers/nemo_guardrails/nemoguardrail_controller.go:275]
- **controller**: NemoGuardrailsReconciler —watches-reference→ api/nemo_guardrails/v1alpha1/NemoGuardrails; api/nemo_guardrails/v1alpha1/NemoGuardrails [source: controllers/nemo_guardrails/ca.go:152, controllers/nemo_guardrails/nemoguardrail_controller.go:271]
- **controller**: ProfileWatcher —watches-reference→ config.openshift.io/v1/APIServer; config.openshift.io/v1/APIServer [source: pkg/tls/watcher.go:119, pkg/tls/watcher.go:64]
- **controller**: TrustyAIModuleReconciler —watches-reference→ /v1/Service; /v1/Service [source: controllers/evalhub/mcp_service.go:42, trustyai-operator-module/pkg/trustyaimodule/reconciler.go:507]
- **controller**: TrustyAIModuleReconciler —watches-reference→ /v1/ServiceAccount; /v1/ServiceAccount [source: controllers/evalhub/evalhub_controller.go:603, trustyai-operator-module/pkg/trustyaimodule/reconciler.go:506]
- **controller**: TrustyAIModuleReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: controllers/evalhub/deployment.go:37, trustyai-operator-module/pkg/trustyaimodule/reconciler.go:508]
- **controller**: TrustyAIModuleReconciler —watches-reference→ rbac.authorization.k8s.io/v1/RoleBinding; rbac.authorization.k8s.io/v1/RoleBinding [source: controllers/evalhub/evalhub_controller.go:579, trustyai-operator-module/pkg/trustyaimodule/reconciler.go:509]
- **controller**: TrustyAIServiceReconciler —watches-reference→ /v1/Pod; /v1/Pod [source: controllers/evalhub/evaluation_job_failure_reconciler.go:543, controllers/tas/trustyaiservice_controller.go:350]
- **controller**: TrustyAIServiceReconciler —watches-reference→ api/tas/v1/TrustyAIService; api/tas/v1/TrustyAIService [source: controllers/tas/statuses.go:34, controllers/tas/trustyaiservice_controller.go:343]
- **controller**: TrustyAIServiceReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: controllers/evalhub/deployment.go:37, controllers/tas/trustyaiservice_controller.go:344]
- **controller**: TrustyAIServiceReconciler —watches-reference→ networking.k8s.io/v1/NetworkPolicy; networking.k8s.io/v1/NetworkPolicy [source: controllers/lmes/network_policy.go:230, controllers/tas/trustyaiservice_controller.go:345]

## Behavioral Evidence

- **conditional-metrics-enforcement (unresolved)** controller-runtime metrics: controller-runtime metrics serving surface; limitations=The controller-runtime manager Metrics binding does not use one direct lexical options object with a stable SecureServing condition [source: trustyai-operator-module/cmd/trustyai-operator-module/main.go:62-62]
- **named-watch-predicate (unresolved)** controllers/evalhub.EvalHubReconciler: /v1/Namespace; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: controllers/evalhub/evalhub_controller.go:400-400]
- **named-watch-predicate (unresolved)** controllers/evalhub.EvalHubReconciler: /v1/ConfigMap; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: controllers/evalhub/evalhub_controller.go:401-401]
- **named-watch-predicate (unresolved)** controllers/evalhub.registerEvalHubEvaluationJobFailureController: /v1/Pod; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: controllers/evalhub/evaluation_job_failure_reconciler.go:211-215]
- **named-watch-predicate (unresolved)** controllers/evalhub.registerEvalHubEvaluationJobFailureController: /v1/Namespace; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: controllers/evalhub/evaluation_job_failure_reconciler.go:216-220]
- **named-watch-predicate (unresolved)** controllers/lmes.LMEvalJobReconciler: /v1/Pod; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: controllers/lmes/lmevaljob_controller.go:358-363]
- **named-watch-predicate (unresolved)** controllers/nemo_guardrails.NemoGuardrailsReconciler: /v1/ConfigMap; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: controllers/nemo_guardrails/nemoguardrail_controller.go:275-305]
- **named-watch-predicate (unresolved)** controllers/tas.TrustyAIServiceReconciler: /v1/Pod; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: controllers/tas/trustyaiservice_controller.go:350-355]

## Gap Evidence Index

### authentication

- **Question:** How is this runtime security control wired to the serving surface?
  **Expected signal:** flag/default, certificate, middleware, or enforcement point
  **Candidate:** `cmd/main.go`:152 (controller-runtime metrics, controller-runtime metrics authn/authz filter)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/main.go`:220 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/main.go`:224 (:8081/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `controllers/tas/templates/service/deployment.tmpl.yaml`:1 (:9443/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `trustyai-operator-module/cmd/trustyai-operator-module/main.go`:60 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Under which configuration branch does the metrics serving surface install authentication and authorization?
  **Expected signal:** a direct SecureServing condition and controller-runtime authn/authz FilterProvider assignment
  **Candidate:** `trustyai-operator-module/cmd/trustyai-operator-module/main.go`:62-62 (controller-runtime metrics, controller-runtime metrics serving surface)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `controllers/evalhub/service_accounts.go`:523 (trustyai-service-operator-evalhub-auth-reviewer-role, {name}-{namespace}-auth-reviewer-crb)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `controllers/tas/service_accounts.go`:69 (trustyai-service-operator-proxy-role, {name}-{namespace}-proxy-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `trustyai-operator-module/config/rbac/role.yaml`:2 (manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `trustyai-operator-module/config/rbac/role.yaml`:2 (trustyai-operator-module-manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `trustyai-operator-module/config/rbac/role_binding.yaml`:1 (manager-role, manager-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `trustyai-operator-module/config/rbac/role_binding.yaml`:1 (trustyai-operator-module-manager-role, trustyai-operator-module-manager-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:36 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.driver`:30 (Dockerfile.driver:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:41 (Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux.driver`:30 (Dockerfile.konflux.driver:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.lmes-job`:32 (Dockerfile.lmes-job:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/lmes_driver/main.go`:78 (lmes_driver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/main.go`:93 (cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `tests/Dockerfile`:59 (tests/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `trustyai-operator-module/Dockerfile`:45 (trustyai-operator-module/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `trustyai-operator-module/Dockerfile.konflux`:46 (trustyai-operator-module/Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `trustyai-operator-module/cmd/trustyai-operator-module/main.go`:32 (trustyai-operator-module)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `controllers/evalhub/kueue_workloads_discovery.go`:22 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `controllers/lmes/lmevaljob_controller.go`:129 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pkg/tls/tls.go`:133 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pkg/tls/watcher.go`:109 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pkg/tracing/tracing.go`:374 (OTLP/gRPC trace exporter, OpenTelemetry Collector)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `trustyai-operator-module/cmd/trustyai-operator-module/main.go`:60 (Kubernetes API, controller-runtime manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `trustyai-operator-module/go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/main.go`:220 (/healthz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/main.go`:224 (/readyz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `trustyai-operator-module/cmd/trustyai-operator-module/main.go`:85 (/healthz, GET, cmd/trustyai-operator-module)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `trustyai-operator-module/cmd/trustyai-operator-module/main.go`:89 (/readyz, GET, cmd/trustyai-operator-module)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `pkg/tracing/tracing.go`:374 (OpenTelemetry Collector, gRPC client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `trustyai-operator-module/config/rbac/role.yaml`:2 (API client, Kubernetes API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `trustyai-operator-module/config/rbac/role.yaml`:2 (CRD CRUD, HardwareProfile CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `trustyai-operator-module/config/rbac/role.yaml`:2 (CRD CRUD, ServingRuntime CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `trustyai-operator-module/config/rbac/role.yaml`:2 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `trustyai-operator-module/config/rbac/role.yaml`:2 (CRD Watch, KServe InferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `trustyai-operator-module/config/rbac/role.yaml`:2 (CRD Watch, OpenShift Routes)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `trustyai-operator-module/config/rbac/role.yaml`:2 (CRD Watch, TrustyAI CRs)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `trustyai-operator-module/config/rbac/role.yaml`:2 (Gateway API, HTTPRoute CRUD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `controllers/dsc/config.go`:49 (/v1/ConfigMap, create, delete, get, list, update operations by DSCConfigReader, EvalHubReconciler, LMEvalJobReconciler, NemoGuardrailsReconciler, TrustyAIModuleReconciler, TrustyAIServiceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `controllers/evalhub/evalhub_controller.go`:404 (Controller watch (conditional), prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `controllers/tas/trustyaiservice_controller.go`:356 (Controller watch, KServe InferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/tls/watcher.go`:64 (APIServer resource read, OpenShift Cluster Configuration)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `trustyai-operator-module/config/rbac/role.yaml`:2 (CRD CRUD, Gateway API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `trustyai-operator-module/config/rbac/role.yaml`:2 (CRD CRUD, HardwareProfile CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `trustyai-operator-module/config/rbac/role.yaml`:2 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `trustyai-operator-module/config/rbac/role.yaml`:2 (CRD Watch, KServe InferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `trustyai-operator-module/config/rbac/role.yaml`:2 (CRD Watch, TrustyAI (trustyai.opendatahub.io))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `trustyai-operator-module/config/rbac/role.yaml`:2 (Kubernetes API (persistent volumes), list)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `trustyai-operator-module/go.mod` (Go Library, odh-platform-utilities)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `trustyai-operator-module/pkg/apis/v1alpha1/trustyai_types.go`:4 (Go library, odh-platform-utilities)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/evalhub/evalhub_controller.go`:395 (EvalHubReconciler, api/evalhub/v1/EvalHub)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/evalhub/evalhub_controller.go`:398 (/v1/Service, EvalHubReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/evalhub/evalhub_controller.go`:399 (/v1/ConfigMap, EvalHubReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `controllers/evalhub/evalhub_controller.go`:400-400 (/v1/Namespace, controllers/evalhub.EvalHubReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `controllers/evalhub/evalhub_controller.go`:401-401 (/v1/ConfigMap, controllers/evalhub.EvalHubReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `controllers/evalhub/evaluation_job_failure_reconciler.go`:211-215 (/v1/Pod, controllers/evalhub.registerEvalHubEvaluationJobFailureController)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `controllers/evalhub/evaluation_job_failure_reconciler.go`:216-220 (/v1/Namespace, controllers/evalhub.registerEvalHubEvaluationJobFailureController)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `controllers/lmes/lmevaljob_controller.go`:358-363 (/v1/Pod, controllers/lmes.LMEvalJobReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `controllers/nemo_guardrails/nemoguardrail_controller.go`:275-305 (/v1/ConfigMap, controllers/nemo_guardrails.NemoGuardrailsReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `controllers/tas/trustyaiservice_controller.go`:350-355 (/v1/Pod, controllers/tas.TrustyAIServiceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `trustyai-operator-module/pkg/trustyaimodule/reconciler.go`:506 (/v1/ServiceAccount, TrustyAIModuleReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `trustyai-operator-module/pkg/trustyaimodule/reconciler.go`:507 (/v1/Service, TrustyAIModuleReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `controllers/tas/templates/service/deployment.tmpl.yaml`:1 ({template-value}, {template-value}-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `controllers/tas/templates/service/service-tls.tmpl.yaml`:1 ({registry-name}, {template-value})
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `trustyai-operator-module/config/manager/manager.yaml`:1 (trustyai-operator-module-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### webhooks

- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/components/evalhub/patches/webhook_in_evalhubs.yaml`:2 (/convert, evalhubs.trustyai.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/components/tas/patches/webhook_in_trustyaiservices.yaml`:2 (/convert, evalhubs.trustyai.opendatahub.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: cmd/main.go:220]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/main.go:224]
- :9443/healthz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes liveness probe endpoint [source: controllers/tas/templates/service/deployment.tmpl.yaml:1]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via trustyai-operator-module-manager-role ClusterRole; SA trustyai-operator-module-controller-manager [source: trustyai-operator-module/cmd/trustyai-operator-module/main.go:60]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/main.go:220]
- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/trustyai-operator-module [source: trustyai-operator-module/cmd/trustyai-operator-module/main.go:85]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/main.go:224]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/trustyai-operator-module [source: trustyai-operator-module/cmd/trustyai-operator-module/main.go:89]
### integrations

- Gateway API interaction=HTTPRoute CRUD role=runtime-transport protocol=HTTPS purpose=Manage Gateway API routing resources [source: trustyai-operator-module/config/rbac/role.yaml:2]
- HardwareProfile CR interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage hardware profile resources [source: trustyai-operator-module/config/rbac/role.yaml:2]
- KServe InferenceService interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read model serving state [source: trustyai-operator-module/config/rbac/role.yaml:2]
- Kubernetes API interaction=API client role=runtime-integration protocol=HTTPS purpose=Cluster resource management via RBAC [source: trustyai-operator-module/config/rbac/role.yaml:2]
- OpenShift Routes interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Dashboard route status [source: trustyai-operator-module/config/rbac/role.yaml:2]
- OpenTelemetry Collector interaction=gRPC client role=runtime-integration protocol=OTLP/gRPC purpose=Runtime trace export [source: pkg/tracing/tracing.go:374]
- ServingRuntime CR interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage serving runtime templates [source: trustyai-operator-module/config/rbac/role.yaml:2]
- TrustyAI CRs interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read TrustyAI service resources [source: trustyai-operator-module/config/rbac/role.yaml:2]
- prometheus-operator interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage Prometheus monitoring resources [source: trustyai-operator-module/config/rbac/role.yaml:2]
### internal_dependencies

- Gateway API interaction=CRD CRUD role=unknown purpose=Manage Gateway API routing resources [source: trustyai-operator-module/config/rbac/role.yaml:2]
- HardwareProfile CR interaction=CRD CRUD role=unknown purpose=Manage hardware profile resources [source: trustyai-operator-module/config/rbac/role.yaml:2]
- KServe InferenceService interaction=CRD Watch role=runtime-integration purpose=Read model serving state [source: trustyai-operator-module/config/rbac/role.yaml:2]
- KServe InferenceService interaction=Controller watch role=runtime-integration purpose=Read model serving state [source: controllers/tas/trustyaiservice_controller.go:356]
- Kubernetes API (persistent volumes) interaction=list role=unknown purpose=persistentvolumes resource access via RBAC [source: trustyai-operator-module/config/rbac/role.yaml:2]
- OpenShift Cluster Configuration interaction=APIServer resource read role=runtime-integration purpose=Read cluster-wide API server configuration [source: pkg/tls/watcher.go:64]
- TrustyAI (trustyai.opendatahub.io) interaction=CRD Watch role=runtime-integration purpose=Read TrustyAI service resources [source: trustyai-operator-module/config/rbac/role.yaml:2]
- odh-platform-utilities interaction=Go Library role=runtime-library purpose=Platform detection, manifest rendering, and deployment helpers [source: trustyai-operator-module/go.mod]
- odh-platform-utilities interaction=Go library role=runtime-library purpose=Use runtime packages from github.com/opendatahub-io/odh-platform-utilities [source: trustyai-operator-module/pkg/apis/v1alpha1/trustyai_types.go:4]
- prometheus-operator interaction=CRD CRUD role=unknown purpose=Manage Prometheus monitoring resources [source: trustyai-operator-module/config/rbac/role.yaml:2]
- prometheus-operator interaction=Controller watch (conditional) role=runtime-integration purpose=Manage Prometheus monitoring resources [source: controllers/evalhub/evalhub_controller.go:404]
### services

- {registry-name} port=443 target=8443 protocol=TCP encryption= auth= [source: controllers/tas/templates/service/service-tls.tmpl.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Controller-created Deployment workload {template-value} uses service account {template-value}-proxy and 3 container(s) [source: controllers/tas/templates/service/deployment.tmpl.yaml:1]
- **observed**: Deployment workload trustyai-operator-module-controller-manager uses service account trustyai-operator-module-controller-manager and 1 container(s) [source: trustyai-operator-module/config/manager/manager.yaml:1]
- **observed**: Service {registry-name} targets {template-value} with 1 port(s) [source: controllers/tas/templates/service/service-tls.tmpl.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by cmd [source: cmd/main.go:220]
- **observed**: HTTP GET /healthz is owned by cmd/trustyai-operator-module [source: trustyai-operator-module/cmd/trustyai-operator-module/main.go:85]
- **observed**: HTTP GET /readyz is owned by cmd [source: cmd/main.go:224]
- **observed**: HTTP GET /readyz is owned by cmd/trustyai-operator-module [source: trustyai-operator-module/cmd/trustyai-operator-module/main.go:89]
- **observed**: Route {registry-name} serves host  via TLS; backend={template-value}; transport=HTTPS [source: controllers/tas/templates/service/route.tmpl.yaml:1]
- **observed**: VirtualService {template-value} serves host {registry-name}.registry namespace.svc.cluster.local via plaintext; backend={registry-name}.registry namespace.svc.cluster.local; transport=HTTP [source: controllers/tas/templates/service/virtual-service.tmpl.yaml:1]
### security

- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: cmd/main.go:220]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/main.go:224]
- **observed**: GET :9443/healthz uses None at N/A; policy=Unauthenticated Kubernetes liveness probe endpoint [source: controllers/tas/templates/service/deployment.tmpl.yaml:1]
- **observed**: RBAC role manager-role grants 42 rule(s) [source: trustyai-operator-module/config/rbac/role.yaml:2]
- **observed**: RBAC role trustyai-operator-module-manager-role grants 42 rule(s) [source: trustyai-operator-module/config/rbac/role.yaml:2]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via trustyai-operator-module-manager-role ClusterRole; SA trustyai-operator-module-controller-manager [source: trustyai-operator-module/cmd/trustyai-operator-module/main.go:60]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: cmd/main.go, controllers/evalhub/evaluation_job_failure_reconciler.go, pkg/tls/proxy.go, pkg/tls/tls.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
