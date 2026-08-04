# Analyzer Synthesis Context: trainer

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 4 crds facts extracted [source: manifests/base/crds/trainer.kubeflow.org_clustertrainingruntimes.yaml:2, manifests/base/crds/trainer.kubeflow.org_trainingruntimes.yaml:2, manifests/base/crds/trainer.kubeflow.org_trainjobs.yaml:2, pkg/apis/config/v1alpha1/configuration_types.go:29]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 2 http_endpoints facts extracted [source: cmd/trainer-controller-manager/main.go:179, cmd/trainer-controller-manager/main.go:190]
- **services (observed)**: 1 services facts extracted [source: manifests/base/manager/manager.yaml:59]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (observed)**: 3 webhooks facts extracted [source: manifests/base/webhook/patch.yaml:1, pkg/webhooks/clustertrainingruntime_webhook.go:46, pkg/webhooks/trainingruntime_webhook.go:61, pkg/webhooks/trainjob_webhook.go:44]

## Deterministic Cross-References

- **controller**: MPI —watches-reference→ /v1/Secret; /v1/Secret [source: pkg/runtime/framework/plugins/mpi/mpi.go:238, pkg/runtime/framework/plugins/mpi/mpi.go:256]
- **security**: GET /healthz —protected-by→ None; N/A: Kubernetes health probe; unauthenticated by design [source: cmd/trainer-controller-manager/main.go:179]
- **security**: GET /readyz —protected-by→ None; N/A: Kubernetes readiness probe; unauthenticated by design [source: cmd/trainer-controller-manager/main.go:190]
- **webhook**: validator.clustertrainingruntime.trainer.kubeflow.org —served-by→ kubeflow-trainer-controller-manager; admission webhook declares an explicit service reference [source: manifests/base/manager/manager.yaml:59, manifests/base/webhook/patch.yaml:1, pkg/webhooks/clustertrainingruntime_webhook.go:46]
- **webhook**: validator.trainingruntime.trainer.kubeflow.org —served-by→ kubeflow-trainer-controller-manager; admission webhook declares an explicit service reference [source: manifests/base/manager/manager.yaml:59, manifests/base/webhook/patch.yaml:1, pkg/webhooks/trainingruntime_webhook.go:61]
- **webhook**: validator.trainjob.trainer.kubeflow.org —served-by→ kubeflow-trainer-controller-manager; admission webhook declares an explicit service reference [source: manifests/base/manager/manager.yaml:59, manifests/base/webhook/patch.yaml:1, pkg/webhooks/trainjob_webhook.go:44]

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/trainer-controller-manager/main.go`:179 (/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `manifests/base/webhook/patch.yaml`:1 (Kubernetes admission, Operator webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `manifests/rhoai/kubeflow-training-roles.yaml`:45 (RBAC aggregation (aggregate-to-admin/edit/view ClusterRoles), RBAC-aggregated resources (trainer.kubeflow.org))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `manifests/rhoai/manager_metrics_patch.yaml`:1 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `pkg/tls/tls.go`:99 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `manifests/base/rbac/role_binding.yaml`:2 (kubeflow-trainer-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/rhoai/kubeflow-training-roles.yaml`:3 (training-edit)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/rhoai/rbac_progression_patch.yaml`:1 (kubeflow-trainer-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/initializers/dataset/Dockerfile`:12 (cmd/initializers/dataset/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/initializers/model/Dockerfile`:12 (cmd/initializers/model/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/trainer-controller-manager/Dockerfile`:20 (cmd/trainer-controller-manager/Dockerfile:ENTRYPOINT)
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
  **Candidate:** `cmd/trainer-controller-manager/main.go`:70 (trainer-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pkg/tls/tls.go`:99 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/trainer-controller-manager/main.go`:179 (/healthz, GET, cmd/trainer-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/rhai/networkpolicy.go`:157 (get, update operations, networking.k8s.io/v1/NetworkPolicy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/rhai/progression/progression.go`:147 (/v1/Pod, list operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/runtime/framework/plugins/coscheduling/coscheduling.go`:268 (Kubernetes Scheduler Plugins (CoScheduling), PodGroup CRD Watch)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/runtime/framework/plugins/jobset/jobset.go`:198 (CRD Watch, JobSet)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/runtime/framework/plugins/mpi/mpi.go`:256 (/v1/Secret, get operations by MPI)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/runtime/framework/plugins/volcano/volcano.go`:118 (get operations by Volcano, scheduling.k8s.io/v1/PriorityClass)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/runtime/framework/plugins/volcano/volcano.go`:341 (PodGroup CRD Watch, Volcano Scheduler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/tls/tls.go`:104 (config.openshift.io/v1/apiservers, get operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `pkg/rhai/networkpolicy.go`:157 (get, update operations, networking.k8s.io/v1/NetworkPolicy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `pkg/rhai/progression/progression.go`:147 (/v1/Pod, list operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/runtime/framework/plugins/coscheduling/coscheduling.go`:268 (CoScheduling, scheduling/v1alpha1/PodGroup)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/runtime/framework/plugins/jobset/jobset.go`:198 (JobSet, jobset/v1alpha2/JobSet)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `pkg/runtime/framework/plugins/mpi/mpi.go`:256 (/v1/Secret, get operations by MPI)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/runtime/framework/plugins/mpi/mpi.go`:230 (/v1/ConfigMap, MPI)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `pkg/runtime/framework/plugins/volcano/volcano.go`:118 (get operations by Volcano, scheduling.k8s.io/v1/PriorityClass)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/runtime/framework/plugins/volcano/volcano.go`:341 (Volcano, scheduling/v1beta1/PodGroup)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `pkg/tls/tls.go`:104 (config.openshift.io/v1/apiservers, get operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `manifests/base/manager/manager.yaml`:59 (kubeflow-trainer-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `manifests/rhoai/manager_metrics_patch.yaml`:1 (kubeflow-trainer-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### webhooks

- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `manifests/base/webhook/patch.yaml`:1 (/validate-trainer-kubeflow-org-v1alpha1-clustertrainingruntime, validator.clustertrainingruntime.trainer.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/webhooks/clustertrainingruntime_webhook.go`:46 (/validate-trainer-kubeflow-org-v1alpha1-clustertrainingruntime, validator.clustertrainingruntime.trainer.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/webhooks/trainingruntime_webhook.go`:61 (/validate-trainer-kubeflow-org-v1alpha1-trainingruntime, validator.trainingruntime.trainer.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/webhooks/trainjob_webhook.go`:44 (/validate-trainer-kubeflow-org-v1alpha1-trainjob, validator.trainjob.trainer.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- /healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: cmd/trainer-controller-manager/main.go:179]
- /readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/trainer-controller-manager/main.go:190]
- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes liveness probe endpoint [source: manifests/rhoai/manager_metrics_patch.yaml:1]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes readiness probe endpoint [source: manifests/rhoai/manager_metrics_patch.yaml:1]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via kubeflow-trainer-controller-manager ClusterRole; SA kubeflow-trainer-controller-manager [source: pkg/tls/tls.go:99]
- Operator webhook methods=CREATE mechanism=Kubernetes admission enforcement=ValidatingWebhookConfiguration policy=Admission validation [source: manifests/base/webhook/patch.yaml:1]
- RBAC-aggregated resources (trainer.kubeflow.org) methods=Kubernetes API mechanism=RBAC aggregation (aggregate-to-admin/edit/view ClusterRoles) enforcement=kube-apiserver policy=Built-in admin, edit, and view roles inherit permissions from training-admin, training-edit, and training-view [source: manifests/rhoai/kubeflow-training-roles.yaml:45]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/trainer-controller-manager [source: cmd/trainer-controller-manager/main.go:179]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/trainer-controller-manager [source: cmd/trainer-controller-manager/main.go:190]
### internal_dependencies

- JobSet interaction=CRD Watch role=runtime-integration purpose=Create and reconcile replicated distributed training jobs [source: pkg/runtime/framework/plugins/jobset/jobset.go:198]
- Kubernetes Scheduler Plugins (CoScheduling) interaction=PodGroup CRD Watch role=runtime-integration purpose=Coordinate gang scheduling through scheduler-plugins PodGroups [source: pkg/runtime/framework/plugins/coscheduling/coscheduling.go:268]
- Volcano Scheduler interaction=PodGroup CRD Watch role=runtime-integration purpose=Coordinate gang scheduling through Volcano PodGroups [source: pkg/runtime/framework/plugins/volcano/volcano.go:341]
### services

- kubeflow-trainer-controller-manager port=443 target=9443 protocol=TCP encryption= auth= [source: manifests/base/manager/manager.yaml:59]
- kubeflow-trainer-controller-manager port=8080 target=8080 protocol=TCP encryption= auth= [source: manifests/base/manager/manager.yaml:59]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload kubeflow-trainer-controller-manager uses service account kubeflow-trainer-controller-manager and 1 container(s) [source: manifests/rhoai/manager_metrics_patch.yaml:1]
- **observed**: Service kubeflow-trainer-controller-manager targets kubeflow-trainer-controller-manager with 2 port(s) [source: manifests/base/manager/manager.yaml:59]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by cmd/trainer-controller-manager [source: cmd/trainer-controller-manager/main.go:179]
- **observed**: HTTP GET /readyz is owned by cmd/trainer-controller-manager [source: cmd/trainer-controller-manager/main.go:190]
### security

- **observed**: CREATE Operator webhook uses Kubernetes admission at ValidatingWebhookConfiguration; policy=Admission validation [source: manifests/base/webhook/patch.yaml:1]
- **observed**: GET /healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: cmd/trainer-controller-manager/main.go:179]
- **observed**: GET /readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/trainer-controller-manager/main.go:190]
- **observed**: GET :8081/healthz uses None at N/A; policy=Unauthenticated Kubernetes liveness probe endpoint [source: manifests/rhoai/manager_metrics_patch.yaml:1]
- **observed**: GET :8081/readyz uses None at N/A; policy=Unauthenticated Kubernetes readiness probe endpoint [source: manifests/rhoai/manager_metrics_patch.yaml:1]
- **observed**: Kubernetes API RBAC-aggregated resources (trainer.kubeflow.org) uses RBAC aggregation (aggregate-to-admin/edit/view ClusterRoles) at kube-apiserver; policy=Built-in admin, edit, and view roles inherit permissions from training-admin, training-edit, and training-view [source: manifests/rhoai/kubeflow-training-roles.yaml:45]
- **observed**: RBAC role kubeflow-trainer-controller-manager grants 13 rule(s) [source: manifests/rhoai/rbac_progression_patch.yaml:1]
- **observed**: RBAC role training-admin grants 2 rule(s) [source: manifests/rhoai/kubeflow-training-roles.yaml:45]
- **observed**: RBAC role training-edit grants 4 rule(s) [source: manifests/rhoai/kubeflow-training-roles.yaml:3]
- **observed**: RBAC role training-view grants 2 rule(s) [source: manifests/rhoai/kubeflow-training-roles.yaml:75]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via kubeflow-trainer-controller-manager ClusterRole; SA kubeflow-trainer-controller-manager [source: pkg/tls/tls.go:99]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: pkg/tls/tls.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
