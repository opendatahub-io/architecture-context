# Analyzer Synthesis Context: trainer

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 6 crds facts extracted [source: pkg/apis/config/v1alpha1/configuration_types.go:29, pkg/apis/trainer/v1alpha1/optimizationjob_types.go:37, pkg/apis/trainer/v1alpha1/trainingruntime_types.go:43, pkg/apis/trainer/v1alpha1/trainingruntime_types.go:79, pkg/apis/trainer/v1alpha1/trainjob_types.go:40, rhoai/operator/config/crd/bases/components.platform.opendatahub.io_trainers.yaml:2]
- **grpc_services (not-verified)**: 0 grpc_services facts extracted; absence is not proven by the available coverage
- **http_endpoints (observed)**: 7 http_endpoints facts extracted [source: cmd/trainer-controller-manager/main.go:235, cmd/trainer-controller-manager/main.go:246, pkg/statusserver/server.go:89, pkg/statusserver/setup.go:78, pkg/statusserver/setup.go:81, rhoai/operator/cmd/main.go:200, rhoai/operator/cmd/main.go:204]
- **services (observed)**: 1 services facts extracted [source: rhoai/operator/config/default/metrics_service.yaml:5]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (observed)**: 5 webhooks facts extracted [source: pkg/webhooks/clustertrainingruntime_webhook.go:32, pkg/webhooks/optimizationjob_webhook.go:31, pkg/webhooks/trainingruntime_webhook.go:50, pkg/webhooks/trainjob_webhook.go:38, pkg/webhooks/trainjob_webhook.go:96]

## Deterministic Cross-References

- **controller**: Flux —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: pkg/runtime/core/snapshot.go:48, pkg/runtime/framework/plugins/flux/flux.go:241]
- **controller**: Flux —watches-reference→ /v1/Secret; /v1/Secret [source: pkg/runtime/framework/plugins/flux/flux.go:249, pkg/runtime/framework/plugins/mpi/mpi.go:302]
- **controller**: MPI —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: pkg/runtime/core/snapshot.go:48, pkg/runtime/framework/plugins/mpi/mpi.go:276]
- **controller**: MPI —watches-reference→ /v1/Secret; /v1/Secret [source: pkg/runtime/framework/plugins/mpi/mpi.go:284, pkg/runtime/framework/plugins/mpi/mpi.go:302]
- **controller**: OptimizationJobReconciler —watches-reference→ /v1/Service; /v1/Service [source: pkg/controller/optimizationjob_controller.go:342, pkg/controller/optimizationjob_controller.go:450]
- **controller**: OptimizationJobReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: pkg/controller/optimizationjob_controller.go:316, pkg/controller/optimizationjob_controller.go:449]
- **security**: GET /healthz —protected-by→ None; N/A: Kubernetes health probe; unauthenticated by design [source: cmd/trainer-controller-manager/main.go:235]
- **security**: GET /readyz —protected-by→ None; N/A: Kubernetes readiness probe; unauthenticated by design [source: cmd/trainer-controller-manager/main.go:246]
- **security**: GET /status-server-healthz —protected-by→ None; N/A: Kubernetes health probe; unauthenticated by design [source: pkg/statusserver/setup.go:78]
- **security**: GET /status-server-readyz —protected-by→ None; N/A: Kubernetes readiness probe; unauthenticated by design [source: pkg/statusserver/setup.go:81]

## Behavioral Evidence

- **conditional-metrics-enforcement (unresolved)** controller-runtime metrics: controller-runtime metrics serving surface; limitations=The controller-runtime manager Metrics binding does not use one direct lexical options object with a stable SecureServing condition [source: rhoai/operator/cmd/main.go:115-115]
- **named-watch-predicate (unresolved)** internal/controller.NewReconciler: apps/v1/Deployment; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: rhoai/operator/internal/controller/trainer_controller.go:204-205]

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/trainer-controller-manager/main.go`:235 (/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/trainer-controller-manager/main.go`:246 (/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `pkg/statusserver/setup.go`:78 (/status-server-healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `pkg/statusserver/setup.go`:81 (/status-server-readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `pkg/webhooks/clustertrainingruntime_webhook.go`:32 (Kubernetes admission, Operator webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Under which configuration branch does the metrics serving surface install authentication and authorization?
  **Expected signal:** a direct SecureServing condition and controller-runtime authn/authz FilterProvider assignment
  **Candidate:** `rhoai/operator/cmd/main.go`:115-115 (controller-runtime metrics, controller-runtime metrics serving surface)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `rhoai/operator/cmd/main.go`:200 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `rhoai/operator/cmd/main.go`:204 (:8081/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `rhoai/operator/config/rbac/metrics_reader_role.yaml`:1 (metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `rhoai/operator/config/rbac/metrics_reader_role.yaml`:1 (trainer-operator-metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `rhoai/operator/config/rbac/role.yaml`:2 (manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `rhoai/operator/config/rbac/role.yaml`:2 (trainer-operator-manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `rhoai/operator/config/rbac/role_binding.yaml`:1 (manager-role, manager-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `rhoai/operator/config/rbac/role_binding.yaml`:1 (trainer-operator-manager-role, trainer-operator-manager-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `rhoai/operator/config/rbac/trainer_admin_role.yaml`:8 (trainer-admin-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `rhoai/operator/config/rbac/trainer_admin_role.yaml`:8 (trainer-operator-trainer-admin-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `rhoai/operator/config/rbac/trainer_viewer_role.yaml`:8 (trainer-operator-trainer-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `rhoai/operator/config/rbac/trainer_viewer_role.yaml`:8 (trainer-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/initializers/dataset/Dockerfile`:30 (cmd/initializers/dataset/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/initializers/model/Dockerfile`:30 (cmd/initializers/model/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/trainer-controller-manager/Dockerfile`:34 (cmd/trainer-controller-manager/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/trainer-controller-manager/Dockerfile.odh`:26 (cmd/trainer-controller-manager/Dockerfile.odh:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/trainer-controller-manager/Dockerfile.rhoai.konflux`:24 (cmd/trainer-controller-manager/Dockerfile.rhoai.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/trainer-controller-manager/main.go`:78 (trainer-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `rhoai/operator/Dockerfile`:37 (rhoai/operator/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `rhoai/operator/Dockerfile.konflux`:39 (rhoai/operator/Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `rhoai/operator/cmd/main.go`:71 (cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `rhoai/operator/go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/trainer-controller-manager/main.go`:235 (/healthz, GET, cmd/trainer-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/trainer-controller-manager/main.go`:246 (/readyz, GET, cmd/trainer-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `pkg/statusserver/server.go`:89 (/, Unknown, pkg/statusserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `pkg/statusserver/setup.go`:78 (/status-server-healthz, GET, pkg/statusserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `pkg/statusserver/setup.go`:81 (/status-server-readyz, GET, pkg/statusserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `rhoai/operator/cmd/main.go`:200 (/healthz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `rhoai/operator/cmd/main.go`:204 (/readyz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `rhoai/operator/config/rbac/role.yaml`:2 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `rhoai/operator/config/rbac/role.yaml`:2 (CRD Watch, OLM (operators.coreos.com))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `rhoai/operator/config/rbac/role.yaml`:2 (OpenShift Image Streams, REST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/controller/optimizationjob_controller.go`:316 (apps/v1/Deployment, delete, get operations by OptimizationJobReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/controller/optimizationjob_controller.go`:342 (/v1/Service, delete operations by OptimizationJobReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/rhai/progression/progression.go`:147 (/v1/Pod, list operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/runtime/core/snapshot.go`:48 (/v1/ConfigMap, get operations by trainerActions)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/runtime/framework/plugins/coscheduling/coscheduling.go`:268 (Kubernetes Scheduler Plugins (CoScheduling), PodGroup CRD Watch)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/runtime/framework/plugins/jobset/jobset.go`:308 (CRD Watch, JobSet)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/runtime/framework/plugins/mpi/mpi.go`:302 (/v1/Secret, get operations by MPI, Status)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/runtime/framework/plugins/volcano/volcano.go`:266 (PodGroup CRD Watch, Volcano Scheduler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `rhoai/operator/cmd/main.go`:45 (Go library, odh-platform-utilities)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `rhoai/operator/config/rbac/role.yaml`:2 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `rhoai/operator/go.mod` (Go Library, odh-platform-utilities)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `rhoai/operator/internal/controller/trainer_controller.go`:323 (/v1/Namespace, create, get operations by trainerActions)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controller/optimizationjob_controller.go`:447 (OptimizationJobReconciler, pkg/apis/trainer/v1alpha1/OptimizationJob)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controller/optimizationjob_controller.go`:449 (OptimizationJobReconciler, apps/v1/Deployment)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controller/optimizationjob_controller.go`:450 (/v1/Service, OptimizationJobReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/runtime/framework/plugins/flux/flux.go`:241 (/v1/ConfigMap, Flux)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/runtime/framework/plugins/flux/flux.go`:249 (/v1/Secret, Flux)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/runtime/framework/plugins/jobset/jobset.go`:308 (JobSet, jobset/v1alpha2/JobSet)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/runtime/framework/plugins/mpi/mpi.go`:276 (/v1/ConfigMap, MPI)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/runtime/framework/plugins/mpi/mpi.go`:284 (/v1/Secret, MPI)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `rhoai/operator/internal/controller/trainer_controller.go`:204-205 (apps/v1/Deployment, internal/controller.NewReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `rhoai/operator/internal/controller/trainer_controller.go`:206 (/v1/Service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `rhoai/operator/internal/controller/trainer_controller.go`:207 (/v1/ConfigMap)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `rhoai/operator/internal/controller/trainer_controller.go`:208 (admissionregistration/v1/ValidatingWebhookConfiguration)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `rhoai/operator/config/default/cert_metrics_manager_patch.yaml`:1 (trainer-operator-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `rhoai/operator/config/default/metrics_service.yaml`:5 (trainer-operator-controller-manager, trainer-operator-controller-manager-metrics-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### webhooks

- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/webhooks/clustertrainingruntime_webhook.go`:32 (/validate-trainer-kubeflow-org-v1alpha1-clustertrainingruntime, validator.clustertrainingruntime.trainer.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/webhooks/optimizationjob_webhook.go`:31 (/validate-trainer-kubeflow-org-v1alpha1-optimizationjob, validator.optimizationjob.trainer.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/webhooks/trainingruntime_webhook.go`:50 (/validate-trainer-kubeflow-org-v1alpha1-trainingruntime, validator.trainingruntime.trainer.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/webhooks/trainjob_webhook.go`:38 (/mutate-trainer-kubeflow-org-v1alpha1-trainjob, defaulter.trainjob.trainer.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/webhooks/trainjob_webhook.go`:96 (/validate-trainer-kubeflow-org-v1alpha1-trainjob, validator.trainjob.trainer.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- /healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: cmd/trainer-controller-manager/main.go:235]
- /readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/trainer-controller-manager/main.go:246]
- /status-server-healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: pkg/statusserver/setup.go:78]
- /status-server-readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: pkg/statusserver/setup.go:81]
- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: rhoai/operator/cmd/main.go:200]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: rhoai/operator/cmd/main.go:204]
- Operator webhook methods=CREATE mechanism=Kubernetes admission enforcement=ValidatingWebhookConfiguration policy=Admission validation [source: pkg/webhooks/clustertrainingruntime_webhook.go:32]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: rhoai/operator/cmd/main.go:200]
- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/trainer-controller-manager [source: cmd/trainer-controller-manager/main.go:235]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: rhoai/operator/cmd/main.go:204]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/trainer-controller-manager [source: cmd/trainer-controller-manager/main.go:246]
- GET /status-server-healthz on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/statusserver [source: pkg/statusserver/setup.go:78]
- GET /status-server-readyz on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/statusserver [source: pkg/statusserver/setup.go:81]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/statusserver [source: pkg/statusserver/server.go:89]
### integrations

- OLM (operators.coreos.com) interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Operator subscription status [source: rhoai/operator/config/rbac/role.yaml:2]
- OpenShift Image Streams interaction=REST role=runtime-transport protocol=HTTPS purpose=Image stream access [source: rhoai/operator/config/rbac/role.yaml:2]
- prometheus-operator interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage Prometheus monitoring resources [source: rhoai/operator/config/rbac/role.yaml:2]
### internal_dependencies

- JobSet interaction=CRD Watch role=runtime-integration purpose=Create and reconcile replicated distributed training jobs [source: pkg/runtime/framework/plugins/jobset/jobset.go:308]
- Kubernetes Scheduler Plugins (CoScheduling) interaction=PodGroup CRD Watch role=runtime-integration purpose=Coordinate gang scheduling through scheduler-plugins PodGroups [source: pkg/runtime/framework/plugins/coscheduling/coscheduling.go:268]
- Volcano Scheduler interaction=PodGroup CRD Watch role=runtime-integration purpose=Coordinate gang scheduling through Volcano PodGroups [source: pkg/runtime/framework/plugins/volcano/volcano.go:266]
- odh-platform-utilities interaction=Go Library role=runtime-library purpose=Platform detection, manifest rendering, and deployment helpers [source: rhoai/operator/go.mod]
- odh-platform-utilities interaction=Go library role=runtime-library purpose=Use runtime packages from github.com/opendatahub-io/odh-platform-utilities [source: rhoai/operator/cmd/main.go:45]
- prometheus-operator interaction=CRD CRUD role=unknown purpose=Manage Prometheus monitoring resources [source: rhoai/operator/config/rbac/role.yaml:2]
### services

- trainer-operator-controller-manager-metrics-service port=8443 target=metrics protocol=TCP encryption= auth= [source: rhoai/operator/config/default/metrics_service.yaml:5]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload trainer-operator-controller-manager uses service account trainer-operator-controller-manager and 1 container(s) [source: rhoai/operator/config/default/cert_metrics_manager_patch.yaml:1]
- **observed**: Service trainer-operator-controller-manager-metrics-service targets trainer-operator-controller-manager with 1 port(s) [source: rhoai/operator/config/default/metrics_service.yaml:5]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by cmd [source: rhoai/operator/cmd/main.go:200]
- **observed**: HTTP GET /healthz is owned by cmd/trainer-controller-manager [source: cmd/trainer-controller-manager/main.go:235]
- **observed**: HTTP GET /readyz is owned by cmd [source: rhoai/operator/cmd/main.go:204]
- **observed**: HTTP GET /readyz is owned by cmd/trainer-controller-manager [source: cmd/trainer-controller-manager/main.go:246]
- **observed**: HTTP GET /status-server-healthz is owned by pkg/statusserver [source: pkg/statusserver/setup.go:78]
- **observed**: HTTP GET /status-server-readyz is owned by pkg/statusserver [source: pkg/statusserver/setup.go:81]
- **observed**: HTTP Unknown / is owned by pkg/statusserver [source: pkg/statusserver/server.go:89]
### security

- **observed**: CREATE Operator webhook uses Kubernetes admission at ValidatingWebhookConfiguration; policy=Admission validation [source: pkg/webhooks/clustertrainingruntime_webhook.go:32]
- **observed**: GET /healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: cmd/trainer-controller-manager/main.go:235]
- **observed**: GET /readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/trainer-controller-manager/main.go:246]
- **observed**: GET /status-server-healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: pkg/statusserver/setup.go:78]
- **observed**: GET /status-server-readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: pkg/statusserver/setup.go:81]
- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: rhoai/operator/cmd/main.go:200]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: rhoai/operator/cmd/main.go:204]
- **observed**: RBAC role manager-role grants 39 rule(s) [source: rhoai/operator/config/rbac/role.yaml:2]
- **observed**: RBAC role metrics-reader grants 1 rule(s) [source: rhoai/operator/config/rbac/metrics_reader_role.yaml:1]
- **observed**: RBAC role trainer-admin-role grants 2 rule(s) [source: rhoai/operator/config/rbac/trainer_admin_role.yaml:8]
- **observed**: RBAC role trainer-operator-manager-role grants 39 rule(s) [source: rhoai/operator/config/rbac/role.yaml:2]
- **observed**: RBAC role trainer-operator-metrics-reader grants 1 rule(s) [source: rhoai/operator/config/rbac/metrics_reader_role.yaml:1]
- **observed**: RBAC role trainer-operator-trainer-admin-role grants 2 rule(s) [source: rhoai/operator/config/rbac/trainer_admin_role.yaml:8]
- **observed**: RBAC role trainer-operator-trainer-viewer-role grants 2 rule(s) [source: rhoai/operator/config/rbac/trainer_viewer_role.yaml:8]
- **observed**: RBAC role trainer-viewer-role grants 2 rule(s) [source: rhoai/operator/config/rbac/trainer_viewer_role.yaml:8]
- **dependency-signal**: rbac-ref targets kubernetes: Kubernetes client library (RBAC capable) [source: cmd/initializers/dataset/requirements.txt:3]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: cmd/trainer-controller-manager/main.go, pkg/config/config.go, pkg/metrics/setup.go, pkg/statusserver/server.go, pkg/statusserver/setup.go, pkg/tls/tls.go, pkg/util/cert/cert.go, pkg/util/tlsconfig/tlsconfig.go, rhoai/operator/internal/tls/metrics.go, rhoai/operator/internal/tls/operand.go, rhoai/operator/internal/tls/profile.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
