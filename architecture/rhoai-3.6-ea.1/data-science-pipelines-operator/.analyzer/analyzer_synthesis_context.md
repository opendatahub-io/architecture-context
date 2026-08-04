# Analyzer Synthesis Context: data-science-pipelines-operator

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 14 crds facts extracted [source: config/argo/crd.applications.yaml:1, config/argo/crd.clusterworkflowtemplates.yaml:1, config/argo/crd.cronworkflows.yaml:1, config/argo/crd.viewers.yaml:1, config/argo/crd.workflowartifactgctasks.yaml:2, config/argo/crd.workfloweventbinding.yaml:2, config/argo/crd.workflows.yaml:1, config/argo/crd.workflowtaskresult.yaml:2, config/argo/crd.workflowtaskset.yaml:1, config/argo/crd.workflowtemplate.yaml:1, config/crd/bases/datasciencepipelinesapplications.opendatahub.io_datasciencepipelinesapplications.yaml:2, config/crd/bases/pipelines.kubeflow.org_pipelines.yaml:2, config/crd/bases/pipelines.kubeflow.org_pipelineversions.yaml:2, config/crd/bases/scheduledworkflows.yaml:1]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 2 http_endpoints facts extracted [source: main.go:376, main.go:380]
- **services (not-verified)**: 0 services facts extracted; absence is not proven by the available coverage
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References

- **controller**: DSPAReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: controllers/dspipeline_controller.go:896, controllers/dspipeline_params.go:1029]
- **controller**: DSPAReconciler —watches-reference→ /v1/Secret; /v1/Secret [source: controllers/dspipeline_controller.go:895, controllers/dspipeline_params.go:251]
- **controller**: DSPAReconciler —watches-reference→ /v1/Service; /v1/Service [source: controllers/dspipeline_controller.go:897, controllers/dspipeline_controller.go:991]
- **controller**: DSPAReconciler —watches-reference→ api/v1/DataSciencePipelinesApplication; api/v1/DataSciencePipelinesApplication [source: controllers/database.go:296, controllers/dspipeline_controller.go:893]
- **controller**: DSPAReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: controllers/dspipeline_controller.go:643, controllers/dspipeline_controller.go:894]
- **controller**: DSPAReconciler —watches-reference→ route.openshift.io/v1/Route; route.openshift.io/v1/Route [source: controllers/dspipeline_controller.go:903, controllers/dspipeline_params.go:230]

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `config/argo/clusterrole.argo-aggregate-to-admin.yaml`:2 (Argo Workflow CRDs (argoproj.io), RBAC aggregation (aggregate-to-admin/edit/view ClusterRoles))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `config/argo/clusterrole.argo-cluster-role.yaml`:1 (Argo Workflow agent secrets, RBAC with resourceNames restriction)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `main.go`:376 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/argo/clusterrole.argo-aggregate-to-admin.yaml`:2 (argo-aggregate-to-admin)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/argo/clusterrole.argo-aggregate-to-edit.yaml`:2 (argo-aggregate-to-edit)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/argo/clusterrole.argo-aggregate-to-view.yaml`:2 (argo-aggregate-to-view)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/argo/clusterrole.argo-cluster-role.yaml`:1 (argo-cluster-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/argo/clusterrolebinding.ds-pipeline-argo-binding.yaml`:2 (argo-cluster-role, ds-pipeline-argo-binding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/argo/role.argo.yaml`:2 (argo-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/aggregate_dspa_role_edit.yaml`:1 (aggregate-dspa-admin-edit)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/aggregate_dspa_role_view.yaml`:1 (aggregate-dspa-admin-view)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/argo_role.yaml`:2 (manager-argo-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/rbac/argo_role_binding.yaml`:1 (manager-argo-role, manager-argo-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/leader_election_role.yaml`:2 (leader-election-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/role.yaml`:2 (manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `.github/scripts/python_package_upload/Dockerfile`:15 (.github/scripts/python_package_upload/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:39 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:52 (Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `main.go`:165 (data-science-pipelines-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `main.go`:376 (/healthz, GET, main)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, Kubeflow Notebooks)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, Kubeflow Notebooks (kubeflow.org))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `controllers/database.go`:296 (api/v1/DataSciencePipelinesApplication, get, list, update operations by DSPAReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `controllers/dspipeline_controller.go`:764 (/v1/Pod, list operations by DSPAReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `controllers/dspipeline_controller.go`:28 (Go library, mlflow-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `controllers/dspipeline_params.go`:1029 (/v1/ConfigMap, create, get, update operations by DSPAParams)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `controllers/database.go`:296 (api/v1/DataSciencePipelinesApplication, get, list, update operations by DSPAReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `controllers/dspipeline_controller.go`:764 (/v1/Pod, list operations by DSPAReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/dspipeline_controller.go`:896 (/v1/ConfigMap, DSPAReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `controllers/dspipeline_params.go`:1029 (/v1/ConfigMap, create, get, update operations by DSPAParams)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: main.go:376]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: main.go:380]
- Argo Workflow CRDs (argoproj.io) methods=Kubernetes API mechanism=RBAC aggregation (aggregate-to-admin/edit/view ClusterRoles) enforcement=kube-apiserver policy=admin: full CRUD on all Argo resources; edit: full CRUD excl. WorkflowTaskSets; view: read-only [source: config/argo/clusterrole.argo-aggregate-to-admin.yaml:2]
- Argo Workflow agent secrets methods=Kubernetes API mechanism=RBAC with resourceNames restriction enforcement=kube-apiserver policy=argo-cluster-role restricts secret access to argo-workflows-agent-ca-certificates only [source: config/argo/clusterrole.argo-cluster-role.yaml:1]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: main.go:376]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: main.go:380]
### integrations

- KServe InferenceService interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read model serving state [source: config/rbac/role.yaml:2]
- Kubeflow Notebooks interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Create and manage notebook workbenches [source: config/rbac/role.yaml:2]
- Kubernetes API interaction=API client role=runtime-integration protocol=HTTPS purpose=Cluster resource management via RBAC [source: config/rbac/role.yaml:2]
- MLflow CR interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read MLflow instances [source: config/rbac/role.yaml:2]
- OpenShift Image Streams interaction=REST role=runtime-transport protocol=HTTPS purpose=Image stream access [source: config/rbac/role.yaml:2]
- OpenShift Routes interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Dashboard route status [source: config/rbac/role.yaml:2]
- prometheus-operator interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage Prometheus monitoring resources [source: config/rbac/role.yaml:2]
### internal_dependencies

- KServe InferenceService interaction=CRD Watch role=runtime-integration purpose=Read model serving state [source: config/rbac/role.yaml:2]
- Kubeflow Notebooks (kubeflow.org) interaction=CRD CRUD role=unknown purpose=Create and manage notebook workbenches [source: config/rbac/role.yaml:2]
- Kubernetes API (persistent volumes) interaction=CRUD role=unknown purpose=persistentvolumes resource access via RBAC [source: config/rbac/role.yaml:2]
- MLflow (mlflow.opendatahub.io) interaction=CRD Watch role=runtime-integration purpose=Read MLflow instances [source: config/rbac/role.yaml:2]
- mlflow-operator interaction=Go library role=runtime-library purpose=Use runtime packages from github.com/opendatahub-io/mlflow-operator/api [source: controllers/dspipeline_controller.go:28]
- prometheus-operator interaction=CRD CRUD role=unknown purpose=Manage Prometheus monitoring resources [source: config/rbac/role.yaml:2]

## Cross-Cutting Evidence

### deployment_topology

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:deployment_topology]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by main [source: main.go:376]
- **observed**: HTTP GET /readyz is owned by main [source: main.go:380]
### security

- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: main.go:376]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: main.go:380]
- **observed**: Kubernetes API Argo Workflow CRDs (argoproj.io) uses RBAC aggregation (aggregate-to-admin/edit/view ClusterRoles) at kube-apiserver; policy=admin: full CRUD on all Argo resources; edit: full CRUD excl. WorkflowTaskSets; view: read-only [source: config/argo/clusterrole.argo-aggregate-to-admin.yaml:2]
- **observed**: Kubernetes API Argo Workflow agent secrets uses RBAC with resourceNames restriction at kube-apiserver; policy=argo-cluster-role restricts secret access to argo-workflows-agent-ca-certificates only [source: config/argo/clusterrole.argo-cluster-role.yaml:1]
- **observed**: RBAC role aggregate-dspa-admin-edit grants 2 rule(s) [source: config/rbac/aggregate_dspa_role_edit.yaml:1]
- **observed**: RBAC role aggregate-dspa-admin-view grants 2 rule(s) [source: config/rbac/aggregate_dspa_role_view.yaml:1]
- **observed**: RBAC role argo-aggregate-to-admin grants 1 rule(s) [source: config/argo/clusterrole.argo-aggregate-to-admin.yaml:2]
- **observed**: RBAC role argo-aggregate-to-edit grants 1 rule(s) [source: config/argo/clusterrole.argo-aggregate-to-edit.yaml:2]
- **observed**: RBAC role argo-aggregate-to-view grants 1 rule(s) [source: config/argo/clusterrole.argo-aggregate-to-view.yaml:2]
- **observed**: RBAC role argo-cluster-role grants 11 rule(s) [source: config/argo/clusterrole.argo-cluster-role.yaml:1]
- **observed**: RBAC role argo-role grants 12 rule(s) [source: config/argo/role.argo.yaml:2]
- **observed**: RBAC role leader-election-role grants 3 rule(s) [source: config/rbac/leader_election_role.yaml:2]
- **observed**: RBAC role manager-argo-role grants 13 rule(s) [source: config/rbac/argo_role.yaml:2]
- **observed**: RBAC role manager-role grants 34 rule(s) [source: config/rbac/role.yaml:2]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: controllers/database.go, controllers/storage.go, tls_profile.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
