# Analyzer Synthesis Context: data-science-pipelines-operator

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 25 crds facts extracted [source: config/argo/crds/crd.applications.yaml:1, config/argo/crds/crd.clusterworkflowtemplates.yaml:1, config/argo/crds/crd.cronworkflows.yaml:1, config/argo/crds/crd.viewers.yaml:1, config/argo/crds/crd.workflowartifactgctasks.yaml:2, config/argo/crds/crd.workfloweventbinding.yaml:2, config/argo/crds/crd.workflows.yaml:1, config/argo/crds/crd.workflowtaskresult.yaml:2, config/argo/crds/crd.workflowtaskset.yaml:1, config/argo/crds/crd.workflowtemplate.yaml:1, config/crd/bases/components.platform.opendatahub.io_aipipelines.yaml:2, config/crd/bases/datasciencepipelinesapplications.opendatahub.io_datasciencepipelinesapplications.yaml:2, config/crd/bases/pipelines.kubeflow.org_pipelines.yaml:2, config/crd/bases/pipelines.kubeflow.org_pipelineversions.yaml:2, config/crd/bases/scheduledworkflows.yaml:1]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 2 http_endpoints facts extracted [source: main.go:421, main.go:425]
- **services (not-verified)**: 0 services facts extracted; absence is not proven by the available coverage
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References

- **controller**: AIPipelinesArgoReconciler —watches-reference→ api/aipipelines/v1alpha1/AIPipelines; api/aipipelines/v1alpha1/AIPipelines [source: controllers/aipipelines_argo_controller.go:334, controllers/aipipelines_argo_controller.go:94]
- **controller**: AIPipelinesReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: controllers/aipipelines_controller.go:180, controllers/dspipeline_params.go:1062]
- **controller**: AIPipelinesReconciler —watches-reference→ api/aipipelines/v1alpha1/AIPipelines; api/aipipelines/v1alpha1/AIPipelines [source: controllers/aipipelines_argo_controller.go:94, controllers/aipipelines_controller.go:163]
- **controller**: AIPipelinesReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: controllers/aipipelines_controller.go:169, controllers/aipipelines_controller.go:301]
- **controller**: DSPAReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: controllers/dspipeline_controller.go:911, controllers/dspipeline_params.go:1062]
- **controller**: DSPAReconciler —watches-reference→ /v1/Secret; /v1/Secret [source: controllers/dspipeline_controller.go:910, controllers/dspipeline_params.go:259]
- **controller**: DSPAReconciler —watches-reference→ /v1/Service; /v1/Service [source: controllers/dspipeline_controller.go:1027, controllers/dspipeline_controller.go:912]
- **controller**: DSPAReconciler —watches-reference→ api/aipipelines/v1alpha1/AIPipelines; api/aipipelines/v1alpha1/AIPipelines [source: controllers/aipipelines_argo_controller.go:94, controllers/dspipeline_controller.go:1051]
- **controller**: DSPAReconciler —watches-reference→ api/v1/DataSciencePipelinesApplication; api/v1/DataSciencePipelinesApplication [source: controllers/database.go:316, controllers/dspipeline_controller.go:908]
- **controller**: DSPAReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: controllers/aipipelines_controller.go:301, controllers/dspipeline_controller.go:909]
- **controller**: DSPAReconciler —watches-reference→ route.openshift.io/v1/Route; route.openshift.io/v1/Route [source: controllers/dspipeline_controller.go:918, controllers/dspipeline_params.go:235]

## Behavioral Evidence

- **named-watch-predicate (unresolved)** controllers.watchArgoAssets: /v1/ConfigMap; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: controllers/aipipelines_argo_controller.go:363-363]
- **named-watch-predicate (unresolved)** controllers.watchArgoAssets: /v1/ServiceAccount; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: controllers/aipipelines_argo_controller.go:364-364]
- **named-watch-predicate (unresolved)** controllers.watchArgoAssets: rbac.authorization.k8s.io/v1/Role; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: controllers/aipipelines_argo_controller.go:365-365]
- **named-watch-predicate (unresolved)** controllers.watchArgoAssets: rbac.authorization.k8s.io/v1/RoleBinding; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: controllers/aipipelines_argo_controller.go:366-366]
- **named-watch-predicate (unresolved)** controllers.watchArgoAssets: rbac.authorization.k8s.io/v1/ClusterRole; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: controllers/aipipelines_argo_controller.go:367-367]
- **named-watch-predicate (unresolved)** controllers.watchArgoAssets: rbac.authorization.k8s.io/v1/ClusterRoleBinding; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: controllers/aipipelines_argo_controller.go:368-368]

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
  **Candidate:** `main.go`:421 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `main.go`:425 (:8081/readyz, None)
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
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/leader_election_role.yaml`:2 (leader-election-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/prometheusrule_role.yaml`:1 (prometheusrule-manager-role)
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
  **Candidate:** `Dockerfile`:41 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:54 (Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `main.go`:166 (data-science-pipelines-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `main.go`:421 (/healthz, GET, main)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `main.go`:425 (/readyz, GET, main)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (API client, Kubernetes API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, Kubeflow Notebooks)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (CRD Watch, KServe InferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (CRD Watch, MLflow CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (CRD Watch, OpenShift Routes)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `config/rbac/role.yaml`:2 (OpenShift Image Streams, REST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `api/aipipelines/v1alpha1/aipipelines_types.go`:20 (Go library, odh-platform-utilities)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, Kubeflow Notebooks (kubeflow.org))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRD Watch, KServe InferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRD Watch, MLflow (mlflow.opendatahub.io))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `config/rbac/role.yaml`:2 (CRUD, Kubernetes API (persistent volumes))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `controllers/dspipeline_controller.go`:1027 (/v1/Service, get operations by DSPAReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `controllers/dspipeline_controller.go`:28 (Go library, mlflow-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `controllers/dspipeline_controller.go`:779 (/v1/Pod, list operations by DSPAReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `controllers/dspipeline_params.go`:1062 (/v1/ConfigMap, create, get, update operations by DSPAParams)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `controllers/dspipeline_params.go`:259 (/v1/Secret, get operations by DSPAParams)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `go.mod` (Go Library, odh-platform-utilities)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `controllers/aipipelines_argo_controller.go`:363-363 (/v1/ConfigMap, controllers.watchArgoAssets)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `controllers/aipipelines_argo_controller.go`:364-364 (/v1/ServiceAccount, controllers.watchArgoAssets)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `controllers/aipipelines_argo_controller.go`:365-365 (controllers.watchArgoAssets, rbac.authorization.k8s.io/v1/Role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `controllers/aipipelines_argo_controller.go`:366-366 (controllers.watchArgoAssets, rbac.authorization.k8s.io/v1/RoleBinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `controllers/aipipelines_argo_controller.go`:367-367 (controllers.watchArgoAssets, rbac.authorization.k8s.io/v1/ClusterRole)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `controllers/aipipelines_argo_controller.go`:368-368 (controllers.watchArgoAssets, rbac.authorization.k8s.io/v1/ClusterRoleBinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/aipipelines_controller.go`:180 (/v1/ConfigMap, AIPipelinesReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/dspipeline_controller.go`:910 (/v1/Secret, DSPAReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/dspipeline_controller.go`:911 (/v1/ConfigMap, DSPAReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/dspipeline_controller.go`:912 (/v1/Service, DSPAReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/dspipeline_controller.go`:913 (/v1/ServiceAccount, DSPAReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `controllers/dspipeline_controller.go`:914 (/v1/PersistentVolumeClaim, DSPAReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: main.go:421]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: main.go:425]
- Argo Workflow CRDs (argoproj.io) methods=Kubernetes API mechanism=RBAC aggregation (aggregate-to-admin/edit/view ClusterRoles) enforcement=kube-apiserver policy=admin: full CRUD on all Argo resources; edit: full CRUD excl. WorkflowTaskSets; view: read-only [source: config/argo/clusterrole.argo-aggregate-to-admin.yaml:2]
- Argo Workflow agent secrets methods=Kubernetes API mechanism=RBAC with resourceNames restriction enforcement=kube-apiserver policy=argo-cluster-role restricts secret access to argo-workflows-agent-ca-certificates only [source: config/argo/clusterrole.argo-cluster-role.yaml:1]
- Argo Workflow agent secrets methods=Kubernetes API mechanism=RBAC with resourceNames restriction enforcement=kube-apiserver policy=argo-cluster-role restricts secret access to argo-workflows-agent-ca-certificates only [source: config/argo/clusterrole.argo-cluster-role.yaml:1]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: main.go:421]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: main.go:425]
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
- odh-platform-utilities interaction=Go Library role=runtime-library purpose=Platform detection, manifest rendering, and deployment helpers [source: go.mod]
- odh-platform-utilities interaction=Go library role=runtime-library purpose=Use runtime packages from github.com/opendatahub-io/odh-platform-utilities [source: api/aipipelines/v1alpha1/aipipelines_types.go:20]
- prometheus-operator interaction=CRD CRUD role=unknown purpose=Manage Prometheus monitoring resources [source: config/rbac/role.yaml:2]

## Cross-Cutting Evidence

### deployment_topology

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:deployment_topology]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by main [source: main.go:421]
- **observed**: HTTP GET /readyz is owned by main [source: main.go:425]
### security

- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: main.go:421]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: main.go:425]
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
- **observed**: RBAC role manager-role grants 39 rule(s) [source: config/rbac/role.yaml:2]
- **observed**: RBAC role prometheusrule-manager-role grants 1 rule(s) [source: config/rbac/prometheusrule_role.yaml:1]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: controllers/database.go, controllers/storage.go, tls_profile.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
