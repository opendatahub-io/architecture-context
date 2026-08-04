# Analyzer Synthesis Context: trustyai-service-operator

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 8 crds facts extracted [source: api/evalhub/v1/evalhub_types.go:28, api/evalhub/v1alpha1/evalhub_types.go:15, api/gorch/v1alpha1/guardrailsorchestrator_types.go:134, api/lmes/v1alpha1/lmevaljob_types.go:693, api/nemo_guardrails/v1alpha1/nemoguardrails_types.go:137, api/tas/v1/trustyaiservice_types.go:13, api/tas/v1alpha1/trustyaiservice_types.go:27, config/crd/bases/components.platform.opendatahub.io_trustyais.yaml:3]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 2 http_endpoints facts extracted [source: cmd/main.go:191, cmd/main.go:195]
- **services (observed)**: 3 services facts extracted [source: config/prometheus/metrics-service.yaml:1, config/rbac-base/auth_proxy_service.yaml:1, controllers/tas/templates/service/service-tls.tmpl.yaml:1]
- **ingress (observed)**: 2 ingress facts extracted [source: controllers/tas/templates/service/route.tmpl.yaml:1, controllers/tas/templates/service/virtual-service.tmpl.yaml:1]
- **webhooks (observed)**: 1 webhooks facts extracted [source: config/components/evalhub/patches/webhook_in_evalhubs.yaml:2, config/components/tas/patches/webhook_in_trustyaiservices.yaml:2]

## Deterministic Cross-References

- **controller**: EvalHubReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: controllers/dsc/config.go:49, controllers/evalhub/evalhub_controller.go:344]
- **controller**: EvalHubReconciler —watches-reference→ /v1/Namespace; /v1/Namespace [source: controllers/evalhub/evalhub_controller.go:153, controllers/evalhub/evalhub_controller.go:345]
- **controller**: EvalHubReconciler —watches-reference→ /v1/Service; /v1/Service [source: controllers/evalhub/evalhub_controller.go:343, controllers/evalhub/mcp_service.go:42]
- **controller**: EvalHubReconciler —watches-reference→ api/evalhub/v1/EvalHub; api/evalhub/v1/EvalHub [source: controllers/evalhub/evalhub_controller.go:341, controllers/evalhub/evalhub_controller.go:81]
- **controller**: EvalHubReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: controllers/evalhub/deployment.go:34, controllers/evalhub/evalhub_controller.go:342]
- **controller**: GuardrailsOrchestratorReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: controllers/dsc/config.go:49, controllers/gorch/guardrailsorchestrator_controller.go:415]
- **controller**: GuardrailsOrchestratorReconciler —watches-reference→ api/gorch/v1alpha1/GuardrailsOrchestrator; api/gorch/v1alpha1/GuardrailsOrchestrator [source: controllers/gorch/config_generation.go:431, controllers/gorch/guardrailsorchestrator_controller.go:410]
- **controller**: GuardrailsOrchestratorReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: controllers/evalhub/deployment.go:34, controllers/gorch/guardrailsorchestrator_controller.go:411]
- **controller**: LMEvalJobReconciler —watches-reference→ /v1/Pod; /v1/Pod [source: controllers/evalhub/evaluation_job_failure_reconciler.go:471, controllers/lmes/lmevaljob_controller.go:347]
- **controller**: LMEvalJobReconciler —watches-reference→ api/lmes/v1alpha1/LMEvalJob; api/lmes/v1alpha1/LMEvalJob [source: controllers/lmes/lmevaljob_controller.go:186, controllers/lmes/lmevaljob_controller.go:341]
- **controller**: NemoGuardrailsReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: controllers/dsc/config.go:49, controllers/nemo_guardrails/nemoguardrail_controller.go:266]
- **controller**: NemoGuardrailsReconciler —watches-reference→ api/nemo_guardrails/v1alpha1/NemoGuardrails; api/nemo_guardrails/v1alpha1/NemoGuardrails [source: controllers/nemo_guardrails/ca.go:152, controllers/nemo_guardrails/nemoguardrail_controller.go:262]
- **controller**: TrustyAIReconciler —watches-reference→ api/module/v1alpha1/TrustyAI; api/module/v1alpha1/TrustyAI [source: controllers/module/module_controller.go:311, controllers/module/module_controller.go:52]
- **controller**: TrustyAIServiceReconciler —watches-reference→ api/tas/v1/TrustyAIService; api/tas/v1/TrustyAIService [source: controllers/tas/statuses.go:34, controllers/tas/trustyaiservice_controller.go:279]
- **controller**: TrustyAIServiceReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: controllers/evalhub/deployment.go:34, controllers/tas/trustyaiservice_controller.go:280]

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/main.go`:191 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `controllers/evalhub/kueue_workloads_discovery.go`:22 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `controllers/tas/templates/service/deployment.tmpl.yaml`:1 (:9443/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/rbac-base/auth-delegator.yml`:1 (manager-auth-delegator, system:auth-delegator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac-base/auth_proxy_client_clusterrole.yaml`:1 (metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac-base/auth_proxy_role.yaml`:1 (proxy-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/rbac-base/auth_proxy_role_binding.yaml`:1 (proxy-role, proxy-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac-base/leader_election_role.yaml`:1 (leader-election-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/rbac-base/leader_election_role_binding.yaml`:1 (leader-election-role, leader-election-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac-base/tls_profile_role.yaml`:1 (tls-profile-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/rbac-base/tls_profile_role_binding.yaml`:1 (tls-profile-reader, tls-profile-reader-binding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `controllers/evalhub/service_accounts.go`:505 (trustyai-service-operator-evalhub-auth-reviewer-role, {name}-{namespace}-auth-reviewer-crb)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `controllers/tas/service_accounts.go`:69 (trustyai-service-operator-proxy-role, {name}-{namespace}-proxy-rolebinding)
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
  **Candidate:** `Dockerfile.orchestrator`:84 (Dockerfile.orchestrator:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime behavior depends on this configuration default, and can deployment values override it?
  **Expected signal:** default value, environment/config key, flag, or override branch
  **Candidate:** `api/gorch/v1alpha1/guardrailsorchestrator_types.go`:84 (Orchestrator.Spec.OTelExporter.OTLPProtocol)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/lmes_driver/main.go`:78 (lmes_driver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/main.go`:92 (cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `tests/Dockerfile`:59 (tests/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `controllers/evalhub/kueue_workloads_discovery.go`:22 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `controllers/lmes/lmevaljob_controller.go`:128 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/main.go`:191 (/healthz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `controllers/dsc/config.go`:49 (/v1/ConfigMap, create, get, list, update operations by DSCConfigReader, EvalHubReconciler, GuardrailsOrchestratorReconciler, LMEvalJobReconciler, NemoGuardrailsReconciler, TrustyAIServiceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `controllers/evalhub/evalhub_controller.go`:153 (/v1/Namespace, get, list operations by EvalHubReconciler, evalHubTenantNamespaces)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `controllers/evalhub/evalhub_controller.go`:349 (Controller watch (conditional), prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `controllers/evalhub/evaluation_job_failure_reconciler.go`:471 (/v1/Pod, delete, list operations by EvalHubEvaluationJobFailureReconciler, LMEvalJobReconciler, TrustyAIServiceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `controllers/evalhub/mcp_service.go`:42 (/v1/Service, create, get, update operations by EvalHubReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `controllers/gorch/config_generation.go`:431 (api/gorch/v1alpha1/GuardrailsOrchestrator, get, list, patch, update operations by GuardrailsOrchestratorReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `controllers/gorch/guardrailsorchestrator_controller.go`:449 (Controller watch, KServe InferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `controllers/lmes/lmevaljob_controller.go`:186 (api/lmes/v1alpha1/LMEvalJob, get, update operations by LMEvalJobReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `controllers/lmes/storage.go`:49 (/v1/PersistentVolumeClaim, create, get operations by LMEvalJobReconciler, TrustyAIServiceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `controllers/module/module_controller.go`:52 (api/module/v1alpha1/TrustyAI, get, update operations by TrustyAIReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `controllers/utils/secrets.go`:15 (/v1/Secret, get operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/tls/tls.go`:97 (APIServer resource read, OpenShift Cluster Configuration)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `controllers/dsc/config.go`:49 (/v1/ConfigMap, create, get, list, update operations by DSCConfigReader, EvalHubReconciler, GuardrailsOrchestratorReconciler, LMEvalJobReconciler, NemoGuardrailsReconciler, TrustyAIServiceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `controllers/evalhub/evalhub_controller.go`:153 (/v1/Namespace, get, list operations by EvalHubReconciler, evalHubTenantNamespaces)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/evalhub/evalhub_controller.go`:344 (/v1/ConfigMap, EvalHubReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/evalhub/evaluation_failed_kueue_workloads_reconciler.go`:86 (kueue/v1beta1/Workload)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `controllers/evalhub/evaluation_job_failure_reconciler.go`:471 (/v1/Pod, delete, list operations by EvalHubEvaluationJobFailureReconciler, LMEvalJobReconciler, TrustyAIServiceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/evalhub/evaluation_job_failure_reconciler.go`:192 (/v1/Namespace)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/gorch/guardrailsorchestrator_controller.go`:415 (/v1/ConfigMap, GuardrailsOrchestratorReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/lmes/lmevaljob_controller.go`:347 (/v1/Pod, LMEvalJobReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `controllers/lmes/storage.go`:49 (/v1/PersistentVolumeClaim, create, get operations by LMEvalJobReconciler, TrustyAIServiceReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/module/module_controller.go`:311 (TrustyAIReconciler, api/module/v1alpha1/TrustyAI)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/nemo_guardrails/nemoguardrail_controller.go`:266 (/v1/ConfigMap, NemoGuardrailsReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/tas/trustyaiservice_controller.go`:279 (TrustyAIServiceReconciler, api/tas/v1/TrustyAIService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `config/manager/manager.yaml`:1 (controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `config/prometheus/metrics-service.yaml`:1 (controller-manager, metrics-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `config/rbac-base/auth_proxy_service.yaml`:1 (controller-manager, controller-manager-metrics-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `controllers/tas/templates/service/deployment.tmpl.yaml`:1 ({template-value}, {template-value}-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `controllers/tas/templates/service/service-tls.tmpl.yaml`:1 ({registry-name}, {template-value})
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

- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: cmd/main.go:191]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/main.go:195]
- :9443/healthz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes liveness probe endpoint [source: controllers/tas/templates/service/deployment.tmpl.yaml:1]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via proxy-role ClusterRole; SA controller-manager [source: controllers/evalhub/kueue_workloads_discovery.go:22]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/main.go:191]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/main.go:195]
### internal_dependencies

- KServe InferenceService interaction=Controller watch role=runtime-integration purpose=Read model serving state [source: controllers/gorch/guardrailsorchestrator_controller.go:449]
- OpenShift Cluster Configuration interaction=APIServer resource read role=runtime-integration purpose=Read cluster-wide API server configuration [source: pkg/tls/tls.go:97]
- prometheus-operator interaction=Controller watch (conditional) role=runtime-integration purpose=Manage Prometheus monitoring resources [source: controllers/evalhub/evalhub_controller.go:349]
### services

- controller-manager-metrics-service port=8443 target=https protocol=TCP encryption= auth= [source: config/rbac-base/auth_proxy_service.yaml:1]
- metrics-service port=8080 target=8080 protocol=TCP encryption= auth= [source: config/prometheus/metrics-service.yaml:1]
- {registry-name} port=443 target=8443 protocol=TCP encryption= auth= [source: controllers/tas/templates/service/service-tls.tmpl.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Controller-created Deployment workload {template-value} uses service account {template-value}-proxy and 2 container(s) [source: controllers/tas/templates/service/deployment.tmpl.yaml:1]
- **observed**: Deployment workload controller-manager uses service account controller-manager and 1 container(s) [source: config/manager/manager.yaml:1]
- **observed**: Service controller-manager-metrics-service targets controller-manager with 1 port(s) [source: config/rbac-base/auth_proxy_service.yaml:1]
- **observed**: Service metrics-service targets controller-manager with 1 port(s) [source: config/prometheus/metrics-service.yaml:1]
- **observed**: Service {registry-name} targets {template-value} with 1 port(s) [source: controllers/tas/templates/service/service-tls.tmpl.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by cmd [source: cmd/main.go:191]
- **observed**: HTTP GET /readyz is owned by cmd [source: cmd/main.go:195]
- **observed**: Route {registry-name} serves host  via TLS; backend={template-value}; transport=HTTPS [source: controllers/tas/templates/service/route.tmpl.yaml:1]
- **observed**: VirtualService {template-value} serves host {registry-name}.registry namespace.svc.cluster.local via plaintext; backend={registry-name}.registry namespace.svc.cluster.local; transport=HTTP [source: controllers/tas/templates/service/virtual-service.tmpl.yaml:1]
### security

- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: cmd/main.go:191]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/main.go:195]
- **observed**: GET :9443/healthz uses None at N/A; policy=Unauthenticated Kubernetes liveness probe endpoint [source: controllers/tas/templates/service/deployment.tmpl.yaml:1]
- **observed**: RBAC role leader-election-role grants 3 rule(s) [source: config/rbac-base/leader_election_role.yaml:1]
- **observed**: RBAC role metrics-reader grants 1 rule(s) [source: config/rbac-base/auth_proxy_client_clusterrole.yaml:1]
- **observed**: RBAC role proxy-role grants 2 rule(s) [source: config/rbac-base/auth_proxy_role.yaml:1]
- **observed**: RBAC role tls-profile-reader grants 1 rule(s) [source: config/rbac-base/tls_profile_role.yaml:1]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via proxy-role ClusterRole; SA controller-manager [source: controllers/evalhub/kueue_workloads_discovery.go:22]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: controllers/evalhub/evaluation_job_failure_reconciler.go, pkg/tls/tls.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
