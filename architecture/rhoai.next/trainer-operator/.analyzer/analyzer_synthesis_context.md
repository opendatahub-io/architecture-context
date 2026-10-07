# Analyzer Synthesis Context: trainer-operator

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 5 crds facts extracted [source: config/crd/bases/components.platform.opendatahub.io_trainers.yaml:2, manifests/trainer/base/crds/trainer.kubeflow.org_clustertrainingruntimes.yaml:16, manifests/trainer/base/crds/trainer.kubeflow.org_optimizationjobs.yaml:16, manifests/trainer/base/crds/trainer.kubeflow.org_trainingruntimes.yaml:16, manifests/trainer/base/crds/trainer.kubeflow.org_trainjobs.yaml:16]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 2 http_endpoints facts extracted [source: cmd/main.go:199, cmd/main.go:203]
- **services (observed)**: 1 services facts extracted [source: manifests/trainer/base/manager/manager.yaml:92]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (observed)**: 4 webhooks facts extracted [source: manifests/trainer/base/webhook/patch_mutating.yaml:1, manifests/trainer/base/webhook/patch_validating.yaml:1]

## Deterministic Cross-References

- **webhook**: defaulter.trainjob.trainer.kubeflow.org —served-by→ kubeflow-trainer-controller-manager; admission webhook declares an explicit service reference [source: manifests/trainer/base/manager/manager.yaml:92, manifests/trainer/base/webhook/patch_mutating.yaml:1]
- **webhook**: validator.clustertrainingruntime.trainer.kubeflow.org —served-by→ kubeflow-trainer-controller-manager; admission webhook declares an explicit service reference [source: manifests/trainer/base/manager/manager.yaml:92, manifests/trainer/base/webhook/patch_validating.yaml:1]
- **webhook**: validator.trainingruntime.trainer.kubeflow.org —served-by→ kubeflow-trainer-controller-manager; admission webhook declares an explicit service reference [source: manifests/trainer/base/manager/manager.yaml:92, manifests/trainer/base/webhook/patch_validating.yaml:1]
- **webhook**: validator.trainjob.trainer.kubeflow.org —served-by→ kubeflow-trainer-controller-manager; admission webhook declares an explicit service reference [source: manifests/trainer/base/manager/manager.yaml:92, manifests/trainer/base/webhook/patch_validating.yaml:1]

## Behavioral Evidence

- **conditional-metrics-enforcement (unresolved)** controller-runtime metrics: controller-runtime metrics serving surface; limitations=The controller-runtime manager Metrics binding does not use one direct lexical options object with a stable SecureServing condition [source: cmd/main.go:115-115]
- **named-watch-predicate (unresolved)** internal/controller.NewReconciler: apps/v1/Deployment; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/trainer_controller.go:194-195]

## Gap Evidence Index

### authentication

- **Question:** Under which configuration branch does the metrics serving surface install authentication and authorization?
  **Expected signal:** a direct SecureServing condition and controller-runtime authn/authz FilterProvider assignment
  **Candidate:** `cmd/main.go`:115-115 (controller-runtime metrics, controller-runtime metrics serving surface)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/main.go`:199 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/main.go`:203 (:8081/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `manifests/trainer/base/webhook/patch_validating.yaml`:1 (Kubernetes admission, Operator webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/metrics_reader_role.yaml`:1 (metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/role.yaml`:2 (manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/trainer_admin_role.yaml`:8 (trainer-admin-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/trainer_viewer_role.yaml`:8 (trainer-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/trainer/base/rbac/public_configmap_role.yaml`:15 (kubeflow-trainer-public)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `manifests/trainer/base/rbac/role_binding.yaml`:16 (kubeflow-trainer-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/trainer/rhoai/kubeflow-training-roles.yaml`:3 (training-edit)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/trainer/rhoai/kubeflow-training-roles.yaml`:44 (training-admin)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/trainer/rhoai/kubeflow-training-roles.yaml`:73 (training-view)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/trainer/rhoai/rbac/tls/clusterrole.yaml`:1 (trainer-tls-profile)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/trainer/rhoai/rbac/tls/metrics-reader-clusterrole.yaml`:1 (trainer-metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/trainer/rhoai/rbac_progression_patch.yaml`:1 (kubeflow-trainer-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:30 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:31 (Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/main.go`:71 (cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/main.go`:199 (/healthz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/main.go`:203 (/readyz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (CRD Watch, OLM (operators.coreos.com))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (OpenShift Image Streams, REST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `cmd/main.go`:45 (Go library, odh-platform-utilities)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `go.mod` (Go Library, odh-platform-utilities)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/trainer_controller.go`:313 (/v1/Namespace, create, get operations by trainerActions)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/trainer_controller.go`:658 (/v1/ConfigMap, get operations by trainerActions)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/trainer_controller.go`:194-195 (apps/v1/Deployment, internal/controller.NewReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/trainer_controller.go`:196 (/v1/Service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/trainer_controller.go`:197 (/v1/ConfigMap)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/trainer_controller.go`:198 (admissionregistration/v1/ValidatingWebhookConfiguration)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/controller/trainer_controller.go`:313 (/v1/Namespace, create, get operations by trainerActions)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/controller/trainer_controller.go`:658 (/v1/ConfigMap, get operations by trainerActions)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `manifests/trainer/base/manager/manager.yaml`:92 (kubeflow-trainer-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `manifests/trainer/rhoai/manager_config_patch.yaml`:1 (kubeflow-trainer-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### webhooks

- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `manifests/trainer/base/webhook/patch_mutating.yaml`:1 (/mutate-trainer-kubeflow-org-v1alpha1-trainjob, defaulter.trainjob.trainer.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `manifests/trainer/base/webhook/patch_validating.yaml`:1 (/validate-trainer-kubeflow-org-v1alpha1-clustertrainingruntime, validator.clustertrainingruntime.trainer.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `manifests/trainer/base/webhook/patch_validating.yaml`:1 (/validate-trainer-kubeflow-org-v1alpha1-trainingruntime, validator.trainingruntime.trainer.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `manifests/trainer/base/webhook/patch_validating.yaml`:1 (/validate-trainer-kubeflow-org-v1alpha1-trainjob, validator.trainjob.trainer.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: cmd/main.go:199]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/main.go:203]
- Operator webhook methods=CREATE mechanism=Kubernetes admission enforcement=ValidatingWebhookConfiguration policy=Admission validation [source: manifests/trainer/base/webhook/patch_validating.yaml:1]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/main.go:199]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: cmd/main.go:203]
### integrations

- OLM (operators.coreos.com) interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Operator subscription status [source: config/rbac/role.yaml:2]
- OpenShift Image Streams interaction=REST role=runtime-transport protocol=HTTPS purpose=Image stream access [source: config/rbac/role.yaml:2]
- prometheus-operator interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage Prometheus monitoring resources [source: config/rbac/role.yaml:2]
### internal_dependencies

- odh-platform-utilities interaction=Go Library role=runtime-library purpose=Platform detection, manifest rendering, and deployment helpers [source: go.mod]
- odh-platform-utilities interaction=Go library role=runtime-library purpose=Use runtime packages from github.com/opendatahub-io/odh-platform-utilities [source: cmd/main.go:45]
- prometheus-operator interaction=CRD CRUD role=unknown purpose=Manage Prometheus monitoring resources [source: config/rbac/role.yaml:2]
### services

- kubeflow-trainer-controller-manager port=10443 target=status-server protocol=TCP encryption= auth= [source: manifests/trainer/base/manager/manager.yaml:92]
- kubeflow-trainer-controller-manager port=443 target=webhook protocol=TCP encryption= auth= [source: manifests/trainer/base/manager/manager.yaml:92]
- kubeflow-trainer-controller-manager port=8443 target=metrics protocol=TCP encryption= auth= [source: manifests/trainer/base/manager/manager.yaml:92]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload kubeflow-trainer-controller-manager uses service account kubeflow-trainer-controller-manager and 1 container(s) [source: manifests/trainer/rhoai/manager_config_patch.yaml:1]
- **observed**: Service kubeflow-trainer-controller-manager targets kubeflow-trainer-controller-manager with 3 port(s) [source: manifests/trainer/base/manager/manager.yaml:92]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by cmd [source: cmd/main.go:199]
- **observed**: HTTP GET /readyz is owned by cmd [source: cmd/main.go:203]
### security

- **observed**: CREATE Operator webhook uses Kubernetes admission at ValidatingWebhookConfiguration; policy=Admission validation [source: manifests/trainer/base/webhook/patch_validating.yaml:1]
- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: cmd/main.go:199]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/main.go:203]
- **observed**: RBAC role kubeflow-trainer-controller-manager grants 14 rule(s) [source: manifests/trainer/rhoai/rbac_progression_patch.yaml:1]
- **observed**: RBAC role kubeflow-trainer-public grants 1 rule(s) [source: manifests/trainer/base/rbac/public_configmap_role.yaml:15]
- **observed**: RBAC role manager-role grants 36 rule(s) [source: config/rbac/role.yaml:2]
- **observed**: RBAC role metrics-reader grants 1 rule(s) [source: config/rbac/metrics_reader_role.yaml:1]
- **observed**: RBAC role trainer-admin-role grants 2 rule(s) [source: config/rbac/trainer_admin_role.yaml:8]
- **observed**: RBAC role trainer-metrics-reader grants 1 rule(s) [source: manifests/trainer/rhoai/rbac/tls/metrics-reader-clusterrole.yaml:1]
- **observed**: RBAC role trainer-tls-profile grants 2 rule(s) [source: manifests/trainer/rhoai/rbac/tls/clusterrole.yaml:1]
- **observed**: RBAC role trainer-viewer-role grants 2 rule(s) [source: config/rbac/trainer_viewer_role.yaml:8]
- **observed**: RBAC role training-admin grants 2 rule(s) [source: manifests/trainer/rhoai/kubeflow-training-roles.yaml:44]
- **observed**: RBAC role training-edit grants 4 rule(s) [source: manifests/trainer/rhoai/kubeflow-training-roles.yaml:3]
- **observed**: RBAC role training-view grants 2 rule(s) [source: manifests/trainer/rhoai/kubeflow-training-roles.yaml:73]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: internal/tls/metrics.go, internal/tls/profile.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
