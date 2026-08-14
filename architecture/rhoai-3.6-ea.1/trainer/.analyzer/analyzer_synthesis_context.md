# Analyzer Synthesis Context: trainer

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 4 crds facts extracted [source: manifests/base/crds/trainer.kubeflow.org_clustertrainingruntimes.yaml:16, manifests/base/crds/trainer.kubeflow.org_trainingruntimes.yaml:16, manifests/base/crds/trainer.kubeflow.org_trainjobs.yaml:16, pkg/apis/config/v1alpha1/configuration_types.go:29]
- **grpc_services (not-verified)**: 0 grpc_services facts extracted; absence is not proven by the available coverage
- **http_endpoints (observed)**: 3 http_endpoints facts extracted [source: cmd/trainer-controller-manager/main.go:205, cmd/trainer-controller-manager/main.go:216, pkg/statusserver/server.go:88]
- **services (observed)**: 1 services facts extracted [source: manifests/base/manager/manager.yaml:92]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (observed)**: 4 webhooks facts extracted [source: manifests/base/webhook/patch_mutating.yaml:1, manifests/base/webhook/patch_validating.yaml:1, pkg/webhooks/clustertrainingruntime_webhook.go:32, pkg/webhooks/trainingruntime_webhook.go:47, pkg/webhooks/trainjob_webhook.go:36, pkg/webhooks/trainjob_webhook.go:94]

## Deterministic Cross-References

- **controller**: Flux —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: pkg/runtime/core/snapshot.go:48, pkg/runtime/framework/plugins/flux/flux.go:244]
- **controller**: Flux —watches-reference→ /v1/Secret; /v1/Secret [source: pkg/runtime/framework/plugins/flux/flux.go:252, pkg/runtime/framework/plugins/mpi/mpi.go:266]
- **controller**: MPI —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: pkg/runtime/core/snapshot.go:48, pkg/runtime/framework/plugins/mpi/mpi.go:238]
- **controller**: MPI —watches-reference→ /v1/Secret; /v1/Secret [source: pkg/runtime/framework/plugins/mpi/mpi.go:246, pkg/runtime/framework/plugins/mpi/mpi.go:266]
- **security**: GET /healthz —protected-by→ None; N/A: Kubernetes health probe; unauthenticated by design [source: cmd/trainer-controller-manager/main.go:205]
- **security**: GET /readyz —protected-by→ None; N/A: Kubernetes readiness probe; unauthenticated by design [source: cmd/trainer-controller-manager/main.go:216]
- **webhook**: defaulter.trainjob.trainer.kubeflow.org —served-by→ kubeflow-trainer-controller-manager; admission webhook declares an explicit service reference [source: manifests/base/manager/manager.yaml:92, manifests/base/webhook/patch_mutating.yaml:1, pkg/webhooks/trainjob_webhook.go:36]
- **webhook**: validator.clustertrainingruntime.trainer.kubeflow.org —served-by→ kubeflow-trainer-controller-manager; admission webhook declares an explicit service reference [source: manifests/base/manager/manager.yaml:92, manifests/base/webhook/patch_validating.yaml:1, pkg/webhooks/clustertrainingruntime_webhook.go:32]
- **webhook**: validator.trainingruntime.trainer.kubeflow.org —served-by→ kubeflow-trainer-controller-manager; admission webhook declares an explicit service reference [source: manifests/base/manager/manager.yaml:92, manifests/base/webhook/patch_validating.yaml:1, pkg/webhooks/trainingruntime_webhook.go:47]
- **webhook**: validator.trainjob.trainer.kubeflow.org —served-by→ kubeflow-trainer-controller-manager; admission webhook declares an explicit service reference [source: manifests/base/manager/manager.yaml:92, manifests/base/webhook/patch_validating.yaml:1, pkg/webhooks/trainjob_webhook.go:94]

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/trainer-controller-manager/main.go`:205 (/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `manifests/base/webhook/patch_validating.yaml`:1 (Kubernetes admission, Operator webhook)
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
  **Candidate:** `cmd/trainer-controller-manager/main.go`:74 (trainer-controller-manager)
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
  **Candidate:** `cmd/trainer-controller-manager/main.go`:205 (/healthz, GET, cmd/trainer-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `pkg/statusserver/server.go`:88 (/, Unknown, pkg/statusserver)
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
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/runtime/core/snapshot.go`:48 (/v1/ConfigMap, get operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/runtime/framework/plugins/coscheduling/coscheduling.go`:270 (Kubernetes Scheduler Plugins (CoScheduling), PodGroup CRD Watch)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/runtime/framework/plugins/jobset/jobset.go`:263 (CRD Watch, JobSet)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/runtime/framework/plugins/mpi/mpi.go`:266 (/v1/Secret, get operations by MPI, Status)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/runtime/framework/plugins/volcano/volcano.go`:118 (get operations by Volcano, scheduling.k8s.io/v1/PriorityClass)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/runtime/framework/plugins/volcano/volcano.go`:343 (PodGroup CRD Watch, Volcano Scheduler)
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
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `pkg/runtime/core/snapshot.go`:48 (/v1/ConfigMap, get operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/runtime/framework/plugins/coscheduling/coscheduling.go`:270 (CoScheduling, scheduling/v1alpha1/PodGroup)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/runtime/framework/plugins/flux/flux.go`:244 (/v1/ConfigMap, Flux)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/runtime/framework/plugins/jobset/jobset.go`:263 (JobSet, jobset/v1alpha2/JobSet)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `pkg/runtime/framework/plugins/mpi/mpi.go`:266 (/v1/Secret, get operations by MPI, Status)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/runtime/framework/plugins/mpi/mpi.go`:238 (/v1/ConfigMap, MPI)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `pkg/runtime/framework/plugins/volcano/volcano.go`:118 (get operations by Volcano, scheduling.k8s.io/v1/PriorityClass)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/runtime/framework/plugins/volcano/volcano.go`:343 (Volcano, scheduling/v1beta1/PodGroup)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `pkg/tls/tls.go`:104 (config.openshift.io/v1/apiservers, get operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `manifests/base/manager/manager.yaml`:92 (kubeflow-trainer-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `manifests/rhoai/manager_metrics_patch.yaml`:1 (kubeflow-trainer-controller-manager)
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
  **Candidate:** `pkg/webhooks/clustertrainingruntime_webhook.go`:32 (/validate-trainer-kubeflow-org-v1alpha1-clustertrainingruntime, validator.clustertrainingruntime.trainer.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/webhooks/trainingruntime_webhook.go`:47 (/validate-trainer-kubeflow-org-v1alpha1-trainingruntime, validator.trainingruntime.trainer.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/webhooks/trainjob_webhook.go`:36 (/mutate-trainer-kubeflow-org-v1alpha1-trainjob, defaulter.trainjob.trainer.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- /healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: cmd/trainer-controller-manager/main.go:205]
- /readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/trainer-controller-manager/main.go:216]
- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes liveness probe endpoint [source: manifests/rhoai/manager_metrics_patch.yaml:1]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes readiness probe endpoint [source: manifests/rhoai/manager_metrics_patch.yaml:1]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via kubeflow-trainer-controller-manager ClusterRole; SA kubeflow-trainer-controller-manager [source: pkg/tls/tls.go:99]
- Operator webhook methods=CREATE mechanism=Kubernetes admission enforcement=ValidatingWebhookConfiguration policy=Admission validation [source: manifests/base/webhook/patch_validating.yaml:1]
- RBAC-aggregated resources (trainer.kubeflow.org) methods=Kubernetes API mechanism=RBAC aggregation (aggregate-to-admin/edit/view ClusterRoles) enforcement=kube-apiserver policy=Built-in admin, edit, and view roles inherit permissions from training-admin, training-edit, and training-view [source: manifests/rhoai/kubeflow-training-roles.yaml:45]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/trainer-controller-manager [source: cmd/trainer-controller-manager/main.go:205]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/trainer-controller-manager [source: cmd/trainer-controller-manager/main.go:216]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/statusserver [source: pkg/statusserver/server.go:88]
### internal_dependencies

- JobSet interaction=CRD Watch role=runtime-integration purpose=Create and reconcile replicated distributed training jobs [source: pkg/runtime/framework/plugins/jobset/jobset.go:263]
- Kubernetes Scheduler Plugins (CoScheduling) interaction=PodGroup CRD Watch role=runtime-integration purpose=Coordinate gang scheduling through scheduler-plugins PodGroups [source: pkg/runtime/framework/plugins/coscheduling/coscheduling.go:270]
- Volcano Scheduler interaction=PodGroup CRD Watch role=runtime-integration purpose=Coordinate gang scheduling through Volcano PodGroups [source: pkg/runtime/framework/plugins/volcano/volcano.go:343]
### services

- kubeflow-trainer-controller-manager port=10443 target=status-server protocol=TCP encryption= auth= [source: manifests/base/manager/manager.yaml:92]
- kubeflow-trainer-controller-manager port=443 target=webhook protocol=TCP encryption= auth= [source: manifests/base/manager/manager.yaml:92]
- kubeflow-trainer-controller-manager port=8443 target=metrics protocol=TCP encryption= auth= [source: manifests/base/manager/manager.yaml:92]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload kubeflow-trainer-controller-manager uses service account kubeflow-trainer-controller-manager and 1 container(s) [source: manifests/rhoai/manager_metrics_patch.yaml:1]
- **observed**: Service kubeflow-trainer-controller-manager targets kubeflow-trainer-controller-manager with 3 port(s) [source: manifests/base/manager/manager.yaml:92]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by cmd/trainer-controller-manager [source: cmd/trainer-controller-manager/main.go:205]
- **observed**: HTTP GET /readyz is owned by cmd/trainer-controller-manager [source: cmd/trainer-controller-manager/main.go:216]
- **observed**: HTTP Unknown / is owned by pkg/statusserver [source: pkg/statusserver/server.go:88]
### security

- **observed**: CREATE Operator webhook uses Kubernetes admission at ValidatingWebhookConfiguration; policy=Admission validation [source: manifests/base/webhook/patch_validating.yaml:1]
- **observed**: GET /healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: cmd/trainer-controller-manager/main.go:205]
- **observed**: GET /readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/trainer-controller-manager/main.go:216]
- **observed**: GET :8081/healthz uses None at N/A; policy=Unauthenticated Kubernetes liveness probe endpoint [source: manifests/rhoai/manager_metrics_patch.yaml:1]
- **observed**: GET :8081/readyz uses None at N/A; policy=Unauthenticated Kubernetes readiness probe endpoint [source: manifests/rhoai/manager_metrics_patch.yaml:1]
- **observed**: Kubernetes API RBAC-aggregated resources (trainer.kubeflow.org) uses RBAC aggregation (aggregate-to-admin/edit/view ClusterRoles) at kube-apiserver; policy=Built-in admin, edit, and view roles inherit permissions from training-admin, training-edit, and training-view [source: manifests/rhoai/kubeflow-training-roles.yaml:45]
- **observed**: RBAC role kubeflow-trainer-controller-manager grants 13 rule(s) [source: manifests/rhoai/rbac_progression_patch.yaml:1]
- **observed**: RBAC role kubeflow-trainer-public grants 1 rule(s) [source: manifests/base/rbac/public_configmap_role.yaml:15]
- **observed**: RBAC role training-admin grants 2 rule(s) [source: manifests/rhoai/kubeflow-training-roles.yaml:45]
- **observed**: RBAC role training-edit grants 4 rule(s) [source: manifests/rhoai/kubeflow-training-roles.yaml:3]
- **observed**: RBAC role training-view grants 2 rule(s) [source: manifests/rhoai/kubeflow-training-roles.yaml:75]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via kubeflow-trainer-controller-manager ClusterRole; SA kubeflow-trainer-controller-manager [source: pkg/tls/tls.go:99]
- **dependency-signal**: rbac-ref targets kubernetes: Kubernetes client library (RBAC capable) [source: cmd/initializers/dataset/requirements.txt:3]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: cmd/trainer-controller-manager/main.go, pkg/config/config.go, pkg/statusserver/server.go, pkg/statusserver/setup.go, pkg/tls/tls.go, pkg/util/cert/cert.go, pkg/util/tlsconfig/tlsconfig.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
