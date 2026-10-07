# Analyzer Synthesis Context: data-science-pipelines-tekton

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 3 crds facts extracted [source: manifests/kustomize/base/pipeline/cluster-scoped/scheduled-workflow-crd.yaml:1, manifests/kustomize/base/pipeline/cluster-scoped/viewer-crd.yaml:1, manifests/kustomize/third-party/application/cluster-scoped/application-crd.yaml:1]
- **grpc_services (observed)**: 8 grpc_services facts extracted [source: backend/src/apiserver/main.go:100, backend/src/apiserver/main.go:101, backend/src/apiserver/main.go:108, backend/src/apiserver/main.go:95, backend/src/apiserver/main.go:96, backend/src/apiserver/main.go:97, backend/src/apiserver/main.go:98, backend/src/apiserver/main.go:99]
- **http_endpoints (observed)**: 5 http_endpoints facts extracted [source: backend/src/apiserver/main.go:143, backend/src/apiserver/main.go:144, backend/src/apiserver/main.go:145, backend/src/apiserver/main.go:151, backend/src/apiserver/main.go:156]
- **services (not-verified)**: 0 services facts extracted; absence is not proven by the available coverage
- **ingress (observed)**: 1 ingress facts extracted [source: manifests/kustomize/base/metadata/options/istio/virtual-service.yaml:1]
- **webhooks (observed)**: 1 webhooks facts extracted [source: manifests/kustomize/third-party/tekton/upstream/manifests/base/tektoncd-install/tekton-release.yaml:1029, manifests/kustomize/third-party/tekton/upstream/manifests/base/tektoncd-install/tekton-release.yaml:478, manifests/kustomize/third-party/tekton/upstream/manifests/base/tektoncd-install/tekton-release.yaml:541, manifests/kustomize/third-party/tekton/upstream/manifests/base/tektoncd-install/tekton-release.yaml:620, manifests/kustomize/third-party/tekton/upstream/manifests/base/tektoncd-install/tekton-release.yaml:947]

## Deterministic Cross-References


## Behavioral Evidence

No bounded behavioral evidence was extracted.

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `backend/src/apiserver/client/util.go`:24 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `manifests/kustomize/third-party/minio/options/istio/istio-authorization-policy.yaml`:1 (Istio source principal, minio-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `manifests/kustomize/third-party/mysql/options/istio/istio-authorization-policy.yaml`:1 (Istio source principal, mysql)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/kustomize/base/cache-deployer/cluster-scoped/cache-deployer-clusterrole.yaml`:1 (kubeflow-pipelines-cache-deployer-clusterrole)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `manifests/kustomize/base/cache-deployer/cluster-scoped/cache-deployer-clusterrolebinding.yaml`:1 (kubeflow-pipelines-cache-deployer-clusterrole, kubeflow-pipelines-cache-deployer-clusterrolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `backend/Dockerfile`:45 (backend/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `backend/Dockerfile.cacheserver`:42 (backend/Dockerfile.cacheserver:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `backend/Dockerfile.persistenceagent`:37 (backend/Dockerfile.persistenceagent:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `backend/Dockerfile.scheduledworkflow`:44 (backend/Dockerfile.scheduledworkflow:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `backend/Dockerfile.viewercontroller`:45 (backend/Dockerfile.viewercontroller:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `backend/Dockerfile.visualization`:40 (backend/Dockerfile.visualization:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `backend/artifact_manager/Dockerfile`:6 (backend/artifact_manager/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `backend/metadata_writer/Dockerfile`:7 (backend/metadata_writer/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `backend/src/cache/deployer/Dockerfile`:23 (backend/src/cache/deployer/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `frontend/Dockerfile`:40 (frontend/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `manifests/gcp_marketplace/deployer/Dockerfile`:24 (manifests/gcp_marketplace/deployer/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `scripts/deploy/iks/Dockerfile`:20 (scripts/deploy/iks/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `backend/src/apiserver/client/util.go`:32 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `backend/src/apiserver/template/tekton_template.go`:484 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `backend/src/cache/client/kubernetes_core.go`:35 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `backend/src/common/util/service.go`:68 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `backend/src/crd/controller/scheduledworkflow/main.go`:66 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `tekton-catalog/kubectl-wrapper/go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `tools/metadatastore-upgrade/main.go`:112 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### grpc_services

- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `backend/src/apiserver/main.go`:100 (ReportService, backend/src/apiserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `backend/src/apiserver/main.go`:101 (VisualizationService, backend/src/apiserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `backend/src/apiserver/main.go`:108 (AuthService, backend/src/apiserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `backend/src/apiserver/main.go`:95 (PipelineService, backend/src/apiserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `backend/src/apiserver/main.go`:96 (ExperimentService, backend/src/apiserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `backend/src/apiserver/main.go`:97 (RunService, backend/src/apiserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `backend/src/apiserver/main.go`:98 (TaskService, backend/src/apiserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `backend/src/apiserver/main.go`:99 (JobService, backend/src/apiserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/src/apiserver/main.go`:143 (/apis/v1beta1/pipelines/upload, Unknown, backend/src/apiserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/src/apiserver/main.go`:144 (/apis/v1beta1/pipelines/upload_version, Unknown, backend/src/apiserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/src/apiserver/main.go`:145 (/apis/v1beta1/healthz, Unknown, backend/src/apiserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/src/apiserver/main.go`:151 (/apis/v1beta1/runs/{run_id}/nodes/{node_id}/log, Unknown, backend/src/apiserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/src/apiserver/main.go`:156 (/metrics, Unknown, backend/src/apiserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `backend/src/apiserver/auth/authenticator_token_review.go`:78 (authentication/v1/TokenReview, create operations by TokenReviewAuthenticator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `backend/src/apiserver/resource/resource_manager.go`:1246 (authorization/v1/SubjectAccessReview, create operations by ResourceManager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `backend/src/crd/controller/viewer/reconciler/reconciler.go`:124 (apps/v1/Deployment, get operations by Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `backend/src/crd/controller/viewer/reconciler/reconciler.go`:150 (/v1/Service, get operations by Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `backend/src/apiserver/auth/authenticator_token_review.go`:78 (authentication/v1/TokenReview, create operations by TokenReviewAuthenticator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `backend/src/apiserver/resource/resource_manager.go`:1246 (authorization/v1/SubjectAccessReview, create operations by ResourceManager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `backend/src/crd/controller/viewer/main.go`:86 (backend/src/crd/pkg/apis/viewer/v1beta1/Viewer)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `backend/src/crd/controller/viewer/main.go`:87 (apps/v1/Deployment)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `backend/src/crd/controller/viewer/main.go`:88 (/v1/Service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `backend/src/crd/controller/viewer/reconciler/reconciler.go`:124 (apps/v1/Deployment, get operations by Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `backend/src/crd/controller/viewer/reconciler/reconciler.go`:150 (/v1/Service, get operations by Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### webhooks

- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `manifests/kustomize/third-party/tekton/upstream/manifests/base/tektoncd-install/tekton-release.yaml`:1029 (/convert, clustertasks.tekton.dev)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `manifests/kustomize/third-party/tekton/upstream/manifests/base/tektoncd-install/tekton-release.yaml`:478 (/convert, clustertasks.tekton.dev)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `manifests/kustomize/third-party/tekton/upstream/manifests/base/tektoncd-install/tekton-release.yaml`:541 (/convert, clustertasks.tekton.dev)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `manifests/kustomize/third-party/tekton/upstream/manifests/base/tektoncd-install/tekton-release.yaml`:620 (/convert, clustertasks.tekton.dev)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `manifests/kustomize/third-party/tekton/upstream/manifests/base/tektoncd-install/tekton-release.yaml`:947 (/convert, clustertasks.tekton.dev)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=In-cluster configuration provides automatic ServiceAccount token authentication [source: backend/src/apiserver/client/util.go:24]
- minio-service methods=ALL mechanism=Istio source principal enforcement=Istio sidecar proxy AuthorizationPolicy policy=Istio AuthorizationPolicy for app=minio; action=ALLOW; allows principals: cluster.local/ns/kubeflow/sa/ml-pipeline; allows principals: cluster.local/ns/kubeflow/sa/ml-pipeline-ui [source: manifests/kustomize/third-party/minio/options/istio/istio-authorization-policy.yaml:1]
- mysql methods=ALL mechanism=Istio source principal enforcement=Istio sidecar proxy AuthorizationPolicy policy=Istio AuthorizationPolicy for app=mysql; allows principals: cluster.local/ns/kubeflow/sa/ml-pipeline, cluster.local/ns/kubeflow/sa/ml-pipeline-ui, cluster.local/ns/kubeflow/sa/ml-pipeline-persistenceagent, cluster.local/ns/kubeflow/sa/ml-pipeline-scheduledworkflow, cluster.local/ns/kubeflow/sa/ml-pipeline-viewer-crd-service-account, cluster.local/ns/kubeflow/sa/kubeflow-pipelines-cach... [source: manifests/kustomize/third-party/mysql/options/istio/istio-authorization-policy.yaml:1]
### http_endpoints

- Unknown /apis/v1beta1/healthz on port ; transport=HTTP/1.1 encryption= auth= owner=backend/src/apiserver [source: backend/src/apiserver/main.go:145]
- Unknown /apis/v1beta1/pipelines/upload on port ; transport=HTTP/1.1 encryption= auth= owner=backend/src/apiserver [source: backend/src/apiserver/main.go:143]
- Unknown /apis/v1beta1/pipelines/upload_version on port ; transport=HTTP/1.1 encryption= auth= owner=backend/src/apiserver [source: backend/src/apiserver/main.go:144]
- Unknown /apis/v1beta1/runs/{run_id}/nodes/{node_id}/log on port ; transport=HTTP/1.1 encryption= auth= owner=backend/src/apiserver [source: backend/src/apiserver/main.go:151]
- Unknown /metrics on port ; transport=HTTP/1.1 encryption= auth= owner=backend/src/apiserver [source: backend/src/apiserver/main.go:156]

## Cross-Cutting Evidence

### deployment_topology

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:deployment_topology]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP Unknown /apis/v1beta1/healthz is owned by backend/src/apiserver [source: backend/src/apiserver/main.go:145]
- **observed**: HTTP Unknown /apis/v1beta1/pipelines/upload is owned by backend/src/apiserver [source: backend/src/apiserver/main.go:143]
- **observed**: HTTP Unknown /apis/v1beta1/pipelines/upload_version is owned by backend/src/apiserver [source: backend/src/apiserver/main.go:144]
- **observed**: HTTP Unknown /apis/v1beta1/runs/{run_id}/nodes/{node_id}/log is owned by backend/src/apiserver [source: backend/src/apiserver/main.go:151]
- **observed**: HTTP Unknown /metrics is owned by backend/src/apiserver [source: backend/src/apiserver/main.go:156]
- **observed**: VirtualService metadata-grpc serves host * via plaintext; backend=metadata-envoy-service.kubeflow.svc.cluster.local; transport=HTTP [source: manifests/kustomize/base/metadata/options/istio/virtual-service.yaml:1]
### security

- **observed**: ALL minio-service uses Istio source principal at Istio sidecar proxy AuthorizationPolicy; policy=Istio AuthorizationPolicy for app=minio; action=ALLOW; allows principals: cluster.local/ns/kubeflow/sa/ml-pipeline; allows principals: cluster.local/ns/kubeflow/sa/ml-pipeline-ui [source: manifests/kustomize/third-party/minio/options/istio/istio-authorization-policy.yaml:1]
- **observed**: ALL mysql uses Istio source principal at Istio sidecar proxy AuthorizationPolicy; policy=Istio AuthorizationPolicy for app=mysql; allows principals: cluster.local/ns/kubeflow/sa/ml-pipeline, cluster.local/ns/kubeflow/sa/ml-pipeline-ui, cluster.local/ns/kubeflow/sa/ml-pipeline-persistenceagent, cluster.local/ns/kubeflow/sa/ml-pipeline-scheduledworkflow, cluster.local/ns/kubeflow/sa/ml-pipeline-viewer-crd-service-account, cluster.local/ns/kubeflow/sa/kubeflow-pipelines-cache, cluster.local/ns/kubeflow/sa/metadata-grpc-server [source: manifests/kustomize/third-party/mysql/options/istio/istio-authorization-policy.yaml:1]
- **observed**: Istio AuthorizationPolicy minio-service applies authentication Istio source principal [source: manifests/kustomize/third-party/minio/options/istio/istio-authorization-policy.yaml:1]
- **observed**: Istio AuthorizationPolicy mysql applies authentication Istio source principal [source: manifests/kustomize/third-party/mysql/options/istio/istio-authorization-policy.yaml:1]
- **observed**: RBAC role kubeflow-pipelines-cache-deployer-clusterrole grants 3 rule(s) [source: manifests/kustomize/base/cache-deployer/cluster-scoped/cache-deployer-clusterrole.yaml:1]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=In-cluster configuration provides automatic ServiceAccount token authentication [source: backend/src/apiserver/client/util.go:24]
- **literal**: rbac-ref targets CreateSubjectAccessReviewClientOrFatal: Token or subject access review call [source: backend/src/apiserver/client_manager.go:199]
- **literal**: rbac-ref targets CreateTokenReviewClientOrFatal: Token or subject access review call [source: backend/src/apiserver/client_manager.go:200]
- **literal**: rbac-ref targets GetTokenReviewAudience: Token or subject access review call [source: backend/src/apiserver/auth/auth.go:41, backend/src/apiserver/client/token_review_fake.go:33]
- **literal**: rbac-ref targets NewFakeSubjectAccessReviewClient: Token or subject access review call [source: backend/src/apiserver/resource/client_manager_fake.go:89]
- **literal**: rbac-ref targets NewFakeSubjectAccessReviewClientUnauthorized: Token or subject access review call [source: backend/src/apiserver/server/test_util.go:128]
- **literal**: rbac-ref targets NewFakeTokenReviewClient: Token or subject access review call [source: backend/src/apiserver/resource/client_manager_fake.go:90, backend/src/apiserver/resource/client_manager_fake.go:94]
- **literal**: rbac-ref targets SubjectAccessReviewClient: Token or subject access review call [source: backend/src/apiserver/resource/resource_manager.go:117]
- **literal**: rbac-ref targets SubjectAccessReviews: Token or subject access review call [source: backend/src/apiserver/client/subject_access_review.go:37]
- **literal**: rbac-ref targets TokenReviewClient: Token or subject access review call [source: backend/src/apiserver/resource/resource_manager.go:118]
- **literal**: rbac-ref targets TokenReviews: Token or subject access review call [source: backend/src/apiserver/client/token_review.go:39]
- **literal**: rbac-ref targets doTokenReview: Token or subject access review call [source: backend/src/apiserver/auth/authenticator_token_review.go:53]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
