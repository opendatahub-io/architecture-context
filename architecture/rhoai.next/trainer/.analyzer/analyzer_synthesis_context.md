# Analyzer Synthesis Context: trainer

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 5 crds facts extracted [source: manifests/base/crds/trainer.kubeflow.org_clustertrainingruntimes.yaml:16, manifests/base/crds/trainer.kubeflow.org_optimizationjobs.yaml:16, manifests/base/crds/trainer.kubeflow.org_trainingruntimes.yaml:16, manifests/base/crds/trainer.kubeflow.org_trainjobs.yaml:16, pkg/apis/config/v1alpha1/configuration_types.go:29]
- **grpc_services (not-verified)**: 0 grpc_services facts extracted; absence is not proven by the available coverage
- **http_endpoints (observed)**: 5 http_endpoints facts extracted [source: cmd/trainer-controller-manager/main.go:235, cmd/trainer-controller-manager/main.go:246, pkg/statusserver/server.go:89, pkg/statusserver/setup.go:78, pkg/statusserver/setup.go:81]
- **services (observed)**: 1 services facts extracted [source: manifests/base/manager/manager.yaml:92]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (observed)**: 4 webhooks facts extracted [source: manifests/base/webhook/patch_mutating.yaml:1, manifests/base/webhook/patch_validating.yaml:1, pkg/webhooks/clustertrainingruntime_webhook.go:32, pkg/webhooks/trainingruntime_webhook.go:48, pkg/webhooks/trainjob_webhook.go:37, pkg/webhooks/trainjob_webhook.go:95]

## Deterministic Cross-References

- **controller**: Flux —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: pkg/runtime/core/snapshot.go:48, pkg/runtime/framework/plugins/flux/flux.go:235]
- **controller**: Flux —watches-reference→ /v1/Secret; /v1/Secret [source: pkg/runtime/framework/plugins/flux/flux.go:243, pkg/runtime/framework/plugins/mpi/mpi.go:264]
- **controller**: MPI —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: pkg/runtime/core/snapshot.go:48, pkg/runtime/framework/plugins/mpi/mpi.go:238]
- **controller**: MPI —watches-reference→ /v1/Secret; /v1/Secret [source: pkg/runtime/framework/plugins/mpi/mpi.go:246, pkg/runtime/framework/plugins/mpi/mpi.go:264]
- **controller**: OptimizationJobReconciler —watches-reference→ /v1/Service; /v1/Service [source: pkg/controller/optimizationjob_controller.go:342, pkg/controller/optimizationjob_controller.go:450]
- **controller**: OptimizationJobReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: pkg/controller/optimizationjob_controller.go:316, pkg/controller/optimizationjob_controller.go:449]
- **security**: GET /healthz —protected-by→ None; N/A: Kubernetes health probe; unauthenticated by design [source: cmd/trainer-controller-manager/main.go:235]
- **security**: GET /readyz —protected-by→ None; N/A: Kubernetes readiness probe; unauthenticated by design [source: cmd/trainer-controller-manager/main.go:246]
- **security**: GET /status-server-healthz —protected-by→ None; N/A: Kubernetes health probe; unauthenticated by design [source: pkg/statusserver/setup.go:78]
- **security**: GET /status-server-readyz —protected-by→ None; N/A: Kubernetes readiness probe; unauthenticated by design [source: pkg/statusserver/setup.go:81]
- **webhook**: defaulter.trainjob.trainer.kubeflow.org —served-by→ kubeflow-trainer-controller-manager; admission webhook declares an explicit service reference [source: manifests/base/manager/manager.yaml:92, manifests/base/webhook/patch_mutating.yaml:1, pkg/webhooks/trainjob_webhook.go:37]
- **webhook**: validator.clustertrainingruntime.trainer.kubeflow.org —served-by→ kubeflow-trainer-controller-manager; admission webhook declares an explicit service reference [source: manifests/base/manager/manager.yaml:92, manifests/base/webhook/patch_validating.yaml:1, pkg/webhooks/clustertrainingruntime_webhook.go:32]
- **webhook**: validator.trainingruntime.trainer.kubeflow.org —served-by→ kubeflow-trainer-controller-manager; admission webhook declares an explicit service reference [source: manifests/base/manager/manager.yaml:92, manifests/base/webhook/patch_validating.yaml:1, pkg/webhooks/trainingruntime_webhook.go:48]
- **webhook**: validator.trainjob.trainer.kubeflow.org —served-by→ kubeflow-trainer-controller-manager; admission webhook declares an explicit service reference [source: manifests/base/manager/manager.yaml:92, manifests/base/webhook/patch_validating.yaml:1, pkg/webhooks/trainjob_webhook.go:95]

## Behavioral Evidence

No bounded behavioral evidence was extracted.

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
  **Candidate:** `manifests/base/webhook/patch_validating.yaml`:1 (Kubernetes admission, Operator webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `manifests/rhoai/manager_config_patch.yaml`:1 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `manifests/rhoai/manager_config_patch.yaml`:1 (:8081/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `pkg/statusserver/setup.go`:78 (/status-server-healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `pkg/statusserver/setup.go`:81 (/status-server-readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/base/rbac/public_configmap_role.yaml`:15 (kubeflow-trainer-public)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `manifests/base/rbac/public_configmap_role_binding.yaml`:15 (kubeflow-trainer-public)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `manifests/base/rbac/role_binding.yaml`:16 (kubeflow-trainer-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/rhoai/kubeflow-training-roles.yaml`:3 (training-edit)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/rhoai/kubeflow-training-roles.yaml`:44 (training-admin)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/rhoai/kubeflow-training-roles.yaml`:73 (training-view)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/rhoai/rbac/tls/clusterrole.yaml`:1 (trainer-tls-profile)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `manifests/rhoai/rbac/tls/clusterrolebinding.yaml`:1 (trainer-tls-profile)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/rhoai/rbac/tls/metrics-reader-clusterrole.yaml`:1 (trainer-metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `manifests/rhoai/rbac/tls/metrics-reader-clusterrolebinding.yaml`:1 (trainer-metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/rhoai/rbac_progression_patch.yaml`:1 (kubeflow-trainer-controller-manager)
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
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
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
  **Candidate:** `pkg/runtime/core/snapshot.go`:48 (/v1/ConfigMap, get operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/runtime/framework/plugins/coscheduling/coscheduling.go`:268 (Kubernetes Scheduler Plugins (CoScheduling), PodGroup CRD Watch)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/runtime/framework/plugins/jobset/jobset.go`:263 (CRD Watch, JobSet)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/runtime/framework/plugins/mpi/mpi.go`:264 (/v1/Secret, get operations by MPI, Status)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/runtime/framework/plugins/volcano/volcano.go`:116 (get operations by Volcano, scheduling.k8s.io/v1/PriorityClass)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/runtime/framework/plugins/volcano/volcano.go`:339 (PodGroup CRD Watch, Volcano Scheduler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controller/optimizationjob_controller.go`:447 (OptimizationJobReconciler, pkg/apis/trainer/v1alpha1/OptimizationJob)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controller/optimizationjob_controller.go`:448 (OptimizationJobReconciler, pkg/apis/trainer/v1alpha1/TrainJob)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controller/optimizationjob_controller.go`:449 (OptimizationJobReconciler, apps/v1/Deployment)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/controller/optimizationjob_controller.go`:450 (/v1/Service, OptimizationJobReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `pkg/runtime/core/snapshot.go`:48 (/v1/ConfigMap, get operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/runtime/framework/plugins/coscheduling/coscheduling.go`:268 (CoScheduling, scheduling/v1alpha1/PodGroup)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/runtime/framework/plugins/flux/flux.go`:235 (/v1/ConfigMap, Flux)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/runtime/framework/plugins/flux/flux.go`:243 (/v1/Secret, Flux)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/runtime/framework/plugins/jobset/jobset.go`:263 (JobSet, jobset/v1alpha2/JobSet)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/runtime/framework/plugins/mpi/mpi.go`:238 (/v1/ConfigMap, MPI)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/runtime/framework/plugins/mpi/mpi.go`:246 (/v1/Secret, MPI)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/runtime/framework/plugins/volcano/volcano.go`:339 (Volcano, scheduling/v1beta1/PodGroup)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `manifests/base/manager/manager.yaml`:92 (kubeflow-trainer-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `manifests/rhoai/manager_config_patch.yaml`:1 (kubeflow-trainer-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### webhooks

- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `manifests/base/webhook/patch_mutating.yaml`:1 (/mutate-trainer-kubeflow-org-v1alpha1-trainjob, defaulter.trainjob.trainer.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `manifests/base/webhook/patch_validating.yaml`:1 (/validate-trainer-kubeflow-org-v1alpha1-clustertrainingruntime, validator.clustertrainingruntime.trainer.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `manifests/base/webhook/patch_validating.yaml`:1 (/validate-trainer-kubeflow-org-v1alpha1-trainingruntime, validator.trainingruntime.trainer.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `manifests/base/webhook/patch_validating.yaml`:1 (/validate-trainer-kubeflow-org-v1alpha1-trainjob, validator.trainjob.trainer.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/webhooks/clustertrainingruntime_webhook.go`:32 (/validate-trainer-kubeflow-org-v1alpha1-clustertrainingruntime, validator.clustertrainingruntime.trainer.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/webhooks/trainingruntime_webhook.go`:48 (/validate-trainer-kubeflow-org-v1alpha1-trainingruntime, validator.trainingruntime.trainer.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/webhooks/trainjob_webhook.go`:37 (/mutate-trainer-kubeflow-org-v1alpha1-trainjob, defaulter.trainjob.trainer.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/webhooks/trainjob_webhook.go`:95 (/validate-trainer-kubeflow-org-v1alpha1-trainjob, validator.trainjob.trainer.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- /healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: cmd/trainer-controller-manager/main.go:235]
- /readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/trainer-controller-manager/main.go:246]
- /status-server-healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: pkg/statusserver/setup.go:78]
- /status-server-readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: pkg/statusserver/setup.go:81]
- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes liveness probe endpoint [source: manifests/rhoai/manager_config_patch.yaml:1]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes readiness probe endpoint [source: manifests/rhoai/manager_config_patch.yaml:1]
- Operator webhook methods=CREATE mechanism=Kubernetes admission enforcement=ValidatingWebhookConfiguration policy=Admission validation [source: manifests/base/webhook/patch_validating.yaml:1]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/trainer-controller-manager [source: cmd/trainer-controller-manager/main.go:235]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/trainer-controller-manager [source: cmd/trainer-controller-manager/main.go:246]
- GET /status-server-healthz on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/statusserver [source: pkg/statusserver/setup.go:78]
- GET /status-server-readyz on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/statusserver [source: pkg/statusserver/setup.go:81]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/statusserver [source: pkg/statusserver/server.go:89]
### internal_dependencies

- JobSet interaction=CRD Watch role=runtime-integration purpose=Create and reconcile replicated distributed training jobs [source: pkg/runtime/framework/plugins/jobset/jobset.go:263]
- Kubernetes Scheduler Plugins (CoScheduling) interaction=PodGroup CRD Watch role=runtime-integration purpose=Coordinate gang scheduling through scheduler-plugins PodGroups [source: pkg/runtime/framework/plugins/coscheduling/coscheduling.go:268]
- Volcano Scheduler interaction=PodGroup CRD Watch role=runtime-integration purpose=Coordinate gang scheduling through Volcano PodGroups [source: pkg/runtime/framework/plugins/volcano/volcano.go:339]
### services

- kubeflow-trainer-controller-manager port=10443 target=status-server protocol=TCP encryption= auth= [source: manifests/base/manager/manager.yaml:92]
- kubeflow-trainer-controller-manager port=443 target=webhook protocol=TCP encryption= auth= [source: manifests/base/manager/manager.yaml:92]
- kubeflow-trainer-controller-manager port=8443 target=metrics protocol=TCP encryption= auth= [source: manifests/base/manager/manager.yaml:92]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload kubeflow-trainer-controller-manager uses service account kubeflow-trainer-controller-manager and 1 container(s) [source: manifests/rhoai/manager_config_patch.yaml:1]
- **observed**: Service kubeflow-trainer-controller-manager targets kubeflow-trainer-controller-manager with 3 port(s) [source: manifests/base/manager/manager.yaml:92]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by cmd/trainer-controller-manager [source: cmd/trainer-controller-manager/main.go:235]
- **observed**: HTTP GET /readyz is owned by cmd/trainer-controller-manager [source: cmd/trainer-controller-manager/main.go:246]
- **observed**: HTTP GET /status-server-healthz is owned by pkg/statusserver [source: pkg/statusserver/setup.go:78]
- **observed**: HTTP GET /status-server-readyz is owned by pkg/statusserver [source: pkg/statusserver/setup.go:81]
- **observed**: HTTP Unknown / is owned by pkg/statusserver [source: pkg/statusserver/server.go:89]
### security

- **observed**: CREATE Operator webhook uses Kubernetes admission at ValidatingWebhookConfiguration; policy=Admission validation [source: manifests/base/webhook/patch_validating.yaml:1]
- **observed**: GET /healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: cmd/trainer-controller-manager/main.go:235]
- **observed**: GET /readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/trainer-controller-manager/main.go:246]
- **observed**: GET /status-server-healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: pkg/statusserver/setup.go:78]
- **observed**: GET /status-server-readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: pkg/statusserver/setup.go:81]
- **observed**: GET :8081/healthz uses None at N/A; policy=Unauthenticated Kubernetes liveness probe endpoint [source: manifests/rhoai/manager_config_patch.yaml:1]
- **observed**: GET :8081/readyz uses None at N/A; policy=Unauthenticated Kubernetes readiness probe endpoint [source: manifests/rhoai/manager_config_patch.yaml:1]
- **observed**: RBAC role kubeflow-trainer-controller-manager grants 18 rule(s) [source: manifests/rhoai/rbac_progression_patch.yaml:1]
- **observed**: RBAC role kubeflow-trainer-public grants 1 rule(s) [source: manifests/base/rbac/public_configmap_role.yaml:15]
- **observed**: RBAC role trainer-metrics-reader grants 1 rule(s) [source: manifests/rhoai/rbac/tls/metrics-reader-clusterrole.yaml:1]
- **observed**: RBAC role trainer-tls-profile grants 2 rule(s) [source: manifests/rhoai/rbac/tls/clusterrole.yaml:1]
- **observed**: RBAC role training-admin grants 2 rule(s) [source: manifests/rhoai/kubeflow-training-roles.yaml:44]
- **observed**: RBAC role training-edit grants 4 rule(s) [source: manifests/rhoai/kubeflow-training-roles.yaml:3]
- **observed**: RBAC role training-view grants 2 rule(s) [source: manifests/rhoai/kubeflow-training-roles.yaml:73]
- **dependency-signal**: rbac-ref targets kubernetes: Kubernetes client library (RBAC capable) [source: cmd/initializers/dataset/requirements.txt:3]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: cmd/trainer-controller-manager/main.go, pkg/config/config.go, pkg/metrics/setup.go, pkg/statusserver/server.go, pkg/statusserver/setup.go, pkg/tls/tls.go, pkg/util/cert/cert.go, pkg/util/tlsconfig/tlsconfig.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
