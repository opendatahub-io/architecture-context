# Analyzer Synthesis Context: data-science-pipelines

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 2 crds facts extracted [source: manifests/kustomize/base/crds/pipelines.kubeflow.org_pipelines.yaml:2, manifests/kustomize/base/crds/pipelines.kubeflow.org_pipelineversions.yaml:2]
- **grpc_services (observed)**: 10 grpc_services facts extracted [source: backend/src/apiserver/main.go:364, backend/src/apiserver/main.go:365, backend/src/apiserver/main.go:366, backend/src/apiserver/main.go:367, backend/src/apiserver/main.go:368, backend/src/apiserver/main.go:369, backend/src/apiserver/main.go:371, backend/src/apiserver/main.go:378, backend/src/apiserver/main.go:381, backend/src/apiserver/main.go:383]
- **http_endpoints (observed)**: 27 http_endpoints facts extracted [source: backend/src/apiserver/main.go:508, backend/src/apiserver/main.go:509, backend/src/apiserver/main.go:510, backend/src/apiserver/main.go:514, backend/src/apiserver/main.go:515, backend/src/apiserver/main.go:516, backend/src/apiserver/main.go:521, backend/src/apiserver/main.go:524, backend/src/apiserver/main.go:525, backend/src/apiserver/main.go:533, backend/src/apiserver/main.go:548, backend/src/apiserver/main.go:549, backend/src/crd/controller/scheduledworkflow/main.go:170, sdk/python/kfp/cli/component_test.py:480, sdk/python/kfp/client/auth_test.py:43, sdk/python/kfp/client/auth_test.py:46, sdk/python/kfp/client/auth_test.py:79, sdk/python/kfp/client/client_test.py:289, sdk/python/kfp/client/client_test.py:298, sdk/python/kfp/client/client_test.py:306, sdk/python/kfp/client/client_test.py:332, sdk/python/kfp/client/client_test.py:382, sdk/python/kfp/local/logging_utils_test.py:27, sdk/python/kfp/registry/registry_client_test.py:158, sdk/python/kfp/registry/registry_client_test.py:191, sdk/python/kfp/registry/registry_client_test.py:255, sdk/python/kfp/registry/registry_client_test.py:403]
- **services (observed)**: 9 services facts extracted [source: manifests/kustomize/base/cache/cache-service.yaml:1, manifests/kustomize/base/metadata/base/metadata-envoy-service.yaml:1, manifests/kustomize/base/metadata/base/metadata-grpc-service.yaml:1, manifests/kustomize/base/pipeline/ml-pipeline-ui-service.yaml:1, manifests/kustomize/base/pipeline/ml-pipeline-visualization-service.yaml:1, manifests/kustomize/env/cert-manager/platform-agnostic-k8s-native/patches/service.json:1, manifests/kustomize/third-party/mysql/base/mysql-service.yaml:1, manifests/kustomize/third-party/seaweedfs/base/seaweedfs/seaweedfs-service.yaml:3, sdk/python/kfp/client/auth_test.py:43]
- **ingress (observed)**: 1 ingress facts extracted [source: manifests/kustomize/base/metadata/options/istio/virtual-service.yaml:1]
- **webhooks (observed)**: 2 webhooks facts extracted [source: manifests/kustomize/env/cert-manager/platform-agnostic-k8s-native/patches/mutating-webhook.yaml:1, manifests/kustomize/env/cert-manager/platform-agnostic-k8s-native/patches/validating-webhook.yaml:1]

## Deterministic Cross-References

- **webhook**: pipelineversions.pipelines.kubeflow.org —served-by→ ml-pipeline; admission webhook declares an explicit service reference [source: manifests/kustomize/env/cert-manager/platform-agnostic-k8s-native/patches/service.json:1, manifests/kustomize/env/cert-manager/platform-agnostic-k8s-native/patches/validating-webhook.yaml:1]

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `backend/src/apiserver/client/util.go`:33 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `backend/src/common/util/service.go`:64 (Kubernetes API, kubeconfig credential chain)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `manifests/kustomize/env/cert-manager/platform-agnostic-k8s-native/patches/role.yaml`:1 (Named Secret access (kfp-mlflow-credentials), RBAC with resourceNames restriction)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `manifests/kustomize/env/cert-manager/platform-agnostic-k8s-native/patches/validating-webhook.yaml`:1 (Kubernetes admission, Operator webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `manifests/kustomize/third-party/mysql/options/istio/istio-authorization-policy.yaml`:1 (Istio source principal, mysql)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `sdk/python/kfp/client/auth_test.py`:43 (HTTP API, None (no auth middleware detected))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/kustomize/base/cache-deployer/cache-deployer-role.yaml`:1 (kubeflow-pipelines-cache-deployer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/kustomize/base/cache/cache-role.yaml`:1 (kubeflow-pipelines-cache-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/kustomize/base/pipeline/metadata-writer/metadata-writer-role.yaml`:1 (kubeflow-pipelines-metadata-writer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `manifests/kustomize/base/pipeline/metadata-writer/metadata-writer-rolebinding.yaml`:1 (kubeflow-pipelines-metadata-writer-binding, kubeflow-pipelines-metadata-writer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `manifests/kustomize/base/pipeline/ml-pipeline-apiserver-rolebinding.yaml`:1 (ml-pipeline)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/kustomize/base/pipeline/ml-pipeline-persistenceagent-role.yaml`:1 (ml-pipeline-persistenceagent-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/kustomize/base/pipeline/ml-pipeline-scheduledworkflow-role.yaml`:1 (ml-pipeline-scheduledworkflow-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/kustomize/base/pipeline/ml-pipeline-ui-role.yaml`:1 (ml-pipeline-ui)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/kustomize/base/pipeline/ml-pipeline-viewer-crd-role.yaml`:1 (ml-pipeline-viewer-controller-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/kustomize/base/pipeline/pipeline-runner-role.yaml`:1 (pipeline-runner)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/kustomize/base/pipeline/public_configmap_role.yaml`:1 (kubeflow-pipelines-public)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/kustomize/env/cert-manager/platform-agnostic-k8s-native/patches/role.yaml`:1 (ml-pipeline)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `backend/Dockerfile`:120 (backend/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `backend/Dockerfile.cacheserver`:43 (backend/Dockerfile.cacheserver:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `backend/Dockerfile.conformance`:49 (backend/Dockerfile.conformance:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `backend/Dockerfile.driver`:55 (backend/Dockerfile.driver:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `backend/Dockerfile.konflux.api`:51 (backend/Dockerfile.konflux.api:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `backend/Dockerfile.konflux.driver`:44 (backend/Dockerfile.konflux.driver:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `backend/Dockerfile.konflux.launcher`:43 (backend/Dockerfile.konflux.launcher:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `backend/Dockerfile.konflux.persistenceagent`:50 (backend/Dockerfile.konflux.persistenceagent:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `backend/Dockerfile.konflux.scheduledworkflow`:45 (backend/Dockerfile.konflux.scheduledworkflow:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `backend/Dockerfile.launcher`:56 (backend/Dockerfile.launcher:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `backend/Dockerfile.persistenceagent`:66 (backend/Dockerfile.persistenceagent:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `backend/Dockerfile.scheduledworkflow`:66 (backend/Dockerfile.scheduledworkflow:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `backend/src/apiserver/client/util.go`:33 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `backend/src/apiserver/client_manager/client_manager.go`:1051 (AWS SDK S3 client, S3-compatible storage)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `backend/src/cache/client/kubernetes_core.go`:34 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `backend/src/common/util/service.go`:99 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `backend/src/crd/controller/scheduledworkflow/main.go`:91 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `backend/src/v2/client_manager/client_manager.go`:96 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `backend/src/v2/component/importer_launcher.go`:94 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `backend/src/v2/driver/k8s.go`:1200 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `backend/src/v2/driver/root_dag.go`:40 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `backend/src/v2/objectstore/object_store.go`:342 (AWS SDK S3 client, S3-compatible storage)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `tools/metadatastore-upgrade/main.go`:112 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### grpc_services

- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `backend/src/apiserver/main.go`:381 (ArtifactService, backend/src/apiserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/src/apiserver/main.go`:521 (/apis/v1alpha1/runs/{run_id}/nodes/{node_id}/log, Unknown, backend/src/apiserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/src/crd/controller/scheduledworkflow/main.go`:170 (/metrics, Unknown, backend/src/crd/controller/scheduledworkflow)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where are runtime routes registered on this server?
  **Expected signal:** router construction or route registration
  **Candidate:** `backend/src/crd/controller/scheduledworkflow/main.go`:180 (HTTP, metrics)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `sdk/python/kfp/cli/component_test.py`:480 (PATCH, kfp.__version__)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `sdk/python/kfp/client/auth_test.py`:43 (PATCH, builtins.input)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `sdk/python/kfp/client/client_test.py`:298 (PATCH, kfp.Client._get_url_prefix)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `sdk/python/kfp/local/logging_utils_test.py`:27 (PATCH, sys.stdout)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `sdk/python/kfp/registry/registry_client_test.py`:255 (PATCH, requests.delete)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `backend/src/apiserver/client_manager/client_manager.go`:1051 (File storage client, S3-compatible storage)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `manifests/kustomize/env/cert-manager/platform-agnostic-k8s-native/patches/role.yaml`:1 (CRD CRUD, Kubeflow Notebooks)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `manifests/kustomize/env/cert-manager/platform-agnostic-k8s-native/patches/service.json`:1 (Inbound scrape, Prometheus)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `backend/src/apiserver/auth/authenticator_token_review.go`:78 (authentication/v1/TokenReview, create operations by TokenReviewAuthenticator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `backend/src/apiserver/resource/resource_manager.go`:2323 (authorization/v1/SubjectAccessReview, create operations by ResourceManager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `backend/src/crd/controller/viewer/reconciler/reconciler.go`:150 (/v1/Service, get operations by Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `backend/src/v2/driver/k8s.go`:943 (/v1/PersistentVolumeClaim, create operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `manifests/kustomize/env/cert-manager/platform-agnostic-k8s-native/patches/role.yaml`:1 (CRD CRUD, Kubeflow Notebooks (kubeflow.org))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `manifests/kustomize/env/cert-manager/platform-agnostic-k8s-native/patches/service.json`:1 (Prometheus, monitoring)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `backend/src/apiserver/auth/authenticator_token_review.go`:78 (authentication/v1/TokenReview, create operations by TokenReviewAuthenticator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `backend/src/apiserver/resource/resource_manager.go`:2323 (authorization/v1/SubjectAccessReview, create operations by ResourceManager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `backend/src/crd/controller/viewer/main.go`:94 (/v1/Service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `backend/src/crd/controller/viewer/reconciler/reconciler.go`:150 (/v1/Service, get operations by Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `backend/src/v2/driver/k8s.go`:943 (/v1/PersistentVolumeClaim, create operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `.github/resources/manifests/base/ci-stability-tuning.yaml`:1 (ml-pipeline)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `.github/resources/manifests/base/metadata-writer-pull-policy.yaml`:1 (kubeflow-pipelines-metadata-writer, metadata-writer)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `manifests/kustomize/base/cache/cache-service.yaml`:1 (cache-server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `manifests/kustomize/base/metadata/base/metadata-envoy-service.yaml`:1 (metadata-envoy-deployment, metadata-envoy-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `manifests/kustomize/base/metadata/base/metadata-grpc-service.yaml`:1 (metadata-grpc-deployment, metadata-grpc-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `manifests/kustomize/base/pipeline/ml-pipeline-persistenceagent-deployment.yaml`:1 (ml-pipeline-persistenceagent)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `manifests/kustomize/base/pipeline/ml-pipeline-ui-service.yaml`:1 (ml-pipeline-ui)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `manifests/kustomize/base/pipeline/ml-pipeline-visualization-service.yaml`:1 (ml-pipeline-visualizationserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `manifests/kustomize/env/cert-manager/platform-agnostic-k8s-native/patches/service.json`:1 (ml-pipeline)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `manifests/kustomize/third-party/mysql/base/mysql-service.yaml`:1 (mysql)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `manifests/kustomize/third-party/seaweedfs/base/seaweedfs/seaweedfs-service.yaml`:3 (seaweedfs)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `sdk/python/kfp/client/auth_test.py`:43 (data-science-pipelines)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### webhooks

- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `manifests/kustomize/env/cert-manager/platform-agnostic-k8s-native/patches/mutating-webhook.yaml`:1 (/webhooks/mutate-pipelineversion, pipelineversions.pipelines.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `manifests/kustomize/env/cert-manager/platform-agnostic-k8s-native/patches/validating-webhook.yaml`:1 (/webhooks/validate-pipelineversion, pipelineversions.pipelines.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- HTTP API methods=All mechanism=None (no auth middleware detected) enforcement=FastAPI/Starlette application policy=No authentication middleware registered [source: sdk/python/kfp/client/auth_test.py:43]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via kubeflow-pipelines-cache-deployer-role Role; SA kubeflow-pipelines-cache-deployer-sa [source: backend/src/apiserver/client/util.go:33]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via kubeflow-pipelines-cache-role Role; SA kubeflow-pipelines-cache [source: backend/src/apiserver/client/util.go:33]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via kubeflow-pipelines-metadata-writer-role Role; SA kubeflow-pipelines-metadata-writer [source: backend/src/apiserver/client/util.go:33]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via ml-pipeline Role; SA ml-pipeline [source: backend/src/apiserver/client/util.go:33]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via ml-pipeline-persistenceagent-role Role; SA ml-pipeline-persistenceagent [source: backend/src/apiserver/client/util.go:33]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via ml-pipeline-scheduledworkflow-role Role; SA ml-pipeline-scheduledworkflow [source: backend/src/apiserver/client/util.go:33]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via ml-pipeline-ui Role; SA ml-pipeline-ui [source: backend/src/apiserver/client/util.go:33]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via ml-pipeline-viewer-controller-role Role; SA ml-pipeline-viewer-crd-service-account [source: backend/src/apiserver/client/util.go:33]
- Kubernetes API methods=REST mechanism=kubeconfig credential chain enforcement=kube-apiserver policy=Kubeconfig-based authentication using user-provided credentials [source: backend/src/common/util/service.go:64]
- Named Secret access (kfp-mlflow-credentials) methods=Kubernetes API mechanism=RBAC with resourceNames restriction enforcement=kube-apiserver policy=ml-pipeline restricts secret access to kfp-mlflow-credentials only [source: manifests/kustomize/env/cert-manager/platform-agnostic-k8s-native/patches/role.yaml:1]
- Operator webhook methods=CREATE mechanism=Kubernetes admission enforcement=ValidatingWebhookConfiguration policy=Admission validation [source: manifests/kustomize/env/cert-manager/platform-agnostic-k8s-native/patches/validating-webhook.yaml:1]
- mysql methods=PATCH mechanism=Istio source principal enforcement=Istio sidecar proxy AuthorizationPolicy policy=Istio AuthorizationPolicy for app=mysql; allows principals: cluster.local/ns/kubeflow/sa/ml-pipeline, cluster.local/ns/kubeflow/sa/ml-pipeline-ui, cluster.local/ns/kubeflow/sa/ml-pipeline-persistenceagent, cluster.local/ns/kubeflow/sa/ml-pipeline-scheduledworkflow, cluster.local/ns/kubeflow/sa/ml-pipeline-viewer-crd-service-account, cluster.local/ns/kubeflow/sa/kubeflow-pipelines-ca... [source: manifests/kustomize/third-party/mysql/options/istio/istio-authorization-policy.yaml:1]
### http_endpoints

- PATCH builtins.input on port ; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/kfp/client/auth_test.py:43]
- PATCH kfp.Client._get_url_prefix on port ; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/kfp/client/client_test.py:298]
- PATCH kfp.Client.get_experiment on port ; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/kfp/client/client_test.py:289]
- PATCH kfp.Client.get_user_namespace on port ; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/kfp/client/client_test.py:332]
- PATCH kfp.__version__ on port ; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/kfp/cli/component_test.py:480]
- PATCH kfp.client.auth.get_auth_response_local on port ; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/kfp/client/auth_test.py:79]
- PATCH kfp.client.auth.is_ipython on port ; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/kfp/client/auth_test.py:46]
- PATCH kfp_server_api.HealthzServiceApi.healthz_service_get_healthz on port ; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/kfp/client/client_test.py:382]
- PATCH kfp_server_api.V2beta1Experiment on port ; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/kfp/client/client_test.py:306]
- PATCH requests.delete on port ; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/kfp/registry/registry_client_test.py:255]
- PATCH requests.get on port ; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/kfp/registry/registry_client_test.py:158]
- PATCH requests.patch on port ; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/kfp/registry/registry_client_test.py:403]
- PATCH requests.post on port ; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/kfp/registry/registry_client_test.py:191]
- PATCH sys.stdout on port ; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/kfp/local/logging_utils_test.py:27]
- Unknown /apis/v1alpha1/runs/{run_id}/nodes/{node_id}/log on port ; transport=HTTP/1.1 encryption= auth= owner=backend/src/apiserver [source: backend/src/apiserver/main.go:521]
- Unknown /apis/v1beta1/healthz on port ; transport=HTTP/1.1 encryption= auth= owner=backend/src/apiserver [source: backend/src/apiserver/main.go:510]
- Unknown /apis/v1beta1/pipelines/upload on port ; transport=HTTP/1.1 encryption= auth= owner=backend/src/apiserver [source: backend/src/apiserver/main.go:508]
- Unknown /apis/v1beta1/pipelines/upload_version on port ; transport=HTTP/1.1 encryption= auth= owner=backend/src/apiserver [source: backend/src/apiserver/main.go:509]
- Unknown /apis/v1beta1/runs/{run_id}/nodes/{node_id}/artifacts/{artifact_name}:read on port ; transport=HTTP/1.1 encryption= auth= owner=backend/src/apiserver [source: backend/src/apiserver/main.go:524]
- Unknown /apis/v2beta1/healthz on port ; transport=HTTP/1.1 encryption= auth= owner=backend/src/apiserver [source: backend/src/apiserver/main.go:516]
- Unknown /apis/v2beta1/pipelines/upload on port ; transport=HTTP/1.1 encryption= auth= owner=backend/src/apiserver [source: backend/src/apiserver/main.go:514]
- Unknown /apis/v2beta1/pipelines/upload_version on port ; transport=HTTP/1.1 encryption= auth= owner=backend/src/apiserver [source: backend/src/apiserver/main.go:515]
- Unknown /apis/v2beta1/runs/{run_id}/nodes/{node_id}/artifacts/{artifact_name}:read on port ; transport=HTTP/1.1 encryption= auth= owner=backend/src/apiserver [source: backend/src/apiserver/main.go:525]
- Unknown /metrics on port ; transport=HTTP/1.1 encryption= auth= owner=backend/src/apiserver [source: backend/src/apiserver/main.go:533]
- Unknown /metrics on port ; transport=HTTP/1.1 encryption= auth= owner=backend/src/crd/controller/scheduledworkflow [source: backend/src/crd/controller/scheduledworkflow/main.go:170]
- Unknown /webhooks/mutate-pipelineversion on port ; transport=HTTP/1.1 encryption= auth= owner=backend/src/apiserver [source: backend/src/apiserver/main.go:549]
- Unknown /webhooks/validate-pipelineversion on port ; transport=HTTP/1.1 encryption= auth= owner=backend/src/apiserver [source: backend/src/apiserver/main.go:548]
### integrations

- Kubeflow Notebooks interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Create and manage notebook workbenches [source: manifests/kustomize/env/cert-manager/platform-agnostic-k8s-native/patches/role.yaml:1]
- Prometheus interaction=Inbound scrape role=unknown protocol=HTTP purpose=Metrics collection via prometheus.io/scrape annotation [source: manifests/kustomize/env/cert-manager/platform-agnostic-k8s-native/patches/service.json:1]
- S3-compatible storage interaction=File storage client role=runtime-integration protocol=HTTP/HTTPS purpose=Runtime object storage [source: backend/src/apiserver/client_manager/client_manager.go:1051]
### internal_dependencies

- Kubeflow Notebooks (kubeflow.org) interaction=CRD CRUD role=unknown purpose=Create and manage notebook workbenches [source: manifests/kustomize/env/cert-manager/platform-agnostic-k8s-native/patches/role.yaml:1]
- Prometheus interaction=monitoring role=unknown purpose=Metrics scraping via service annotations [source: manifests/kustomize/env/cert-manager/platform-agnostic-k8s-native/patches/service.json:1]
### services

- cache-server port=443 target=webhook-api protocol=TCP encryption= auth= [source: manifests/kustomize/base/cache/cache-service.yaml:1]
- metadata-envoy-service port=9090 target=9090 protocol=TCP encryption= auth= [source: manifests/kustomize/base/metadata/base/metadata-envoy-service.yaml:1]
- metadata-grpc-service port=8080 target=8080 protocol=TCP encryption= auth= [source: manifests/kustomize/base/metadata/base/metadata-grpc-service.yaml:1]
- ml-pipeline port=8443 target=8443 protocol=TCP encryption= auth= [source: manifests/kustomize/env/cert-manager/platform-agnostic-k8s-native/patches/service.json:1]
- ml-pipeline port=8887 target=8887 protocol=TCP encryption= auth= [source: manifests/kustomize/env/cert-manager/platform-agnostic-k8s-native/patches/service.json:1]
- ml-pipeline port=8888 target=8888 protocol=TCP encryption= auth= [source: manifests/kustomize/env/cert-manager/platform-agnostic-k8s-native/patches/service.json:1]
- ml-pipeline-ui port=80 target=3000 protocol=TCP encryption= auth= [source: manifests/kustomize/base/pipeline/ml-pipeline-ui-service.yaml:1]
- ml-pipeline-visualizationserver port=8888 target=8888 protocol=TCP encryption= auth= [source: manifests/kustomize/base/pipeline/ml-pipeline-visualization-service.yaml:1]
- mysql port=3306 target=3306 protocol=TCP encryption= auth= [source: manifests/kustomize/third-party/mysql/base/mysql-service.yaml:1]
- seaweedfs port=18888 target=18888 protocol=TCP encryption= auth= [source: manifests/kustomize/third-party/seaweedfs/base/seaweedfs/seaweedfs-service.yaml:3]
- seaweedfs port=19333 target=19333 protocol=TCP encryption= auth= [source: manifests/kustomize/third-party/seaweedfs/base/seaweedfs/seaweedfs-service.yaml:3]
- seaweedfs port=8111 target=8111 protocol=TCP encryption= auth= [source: manifests/kustomize/third-party/seaweedfs/base/seaweedfs/seaweedfs-service.yaml:3]
- seaweedfs port=8333 target=8333 protocol=TCP encryption= auth= [source: manifests/kustomize/third-party/seaweedfs/base/seaweedfs/seaweedfs-service.yaml:3]
- seaweedfs port=8888 target=8888 protocol=TCP encryption= auth= [source: manifests/kustomize/third-party/seaweedfs/base/seaweedfs/seaweedfs-service.yaml:3]
- seaweedfs port=9000 target=8333 protocol=TCP encryption= auth= [source: manifests/kustomize/third-party/seaweedfs/base/seaweedfs/seaweedfs-service.yaml:3]
- seaweedfs port=9333 target=9333 protocol=TCP encryption= auth= [source: manifests/kustomize/third-party/seaweedfs/base/seaweedfs/seaweedfs-service.yaml:3]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload cache-deployer-deployment uses service account kubeflow-pipelines-cache-deployer-sa and 1 container(s) [source: .github/resources/manifests/base/cache-deployer-pull-policy.yaml:1]
- **observed**: Deployment workload cache-server uses service account kubeflow-pipelines-cache and 1 container(s) [source: .github/resources/manifests/base/cache-server-pull-policy.yaml:1]
- **observed**: Deployment workload metadata-envoy-deployment uses service account  and 1 container(s) [source: .github/resources/manifests/base/metadata-envoy-pull-policy.yaml:1]
- **observed**: Deployment workload metadata-grpc-deployment uses service account metadata-grpc-server and 1 container(s) [source: .github/resources/manifests/base/grpc-specs.yaml:1]
- **observed**: Deployment workload metadata-writer uses service account kubeflow-pipelines-metadata-writer and 1 container(s) [source: .github/resources/manifests/base/metadata-writer-pull-policy.yaml:1]
- **observed**: Deployment workload ml-pipeline uses service account ml-pipeline and 1 container(s) [source: .github/resources/manifests/base/ci-stability-tuning.yaml:1]
- **observed**: Deployment workload ml-pipeline-persistenceagent uses service account ml-pipeline-persistenceagent and 1 container(s) [source: manifests/kustomize/base/pipeline/ml-pipeline-persistenceagent-deployment.yaml:1]
- **observed**: Deployment workload ml-pipeline-scheduledworkflow uses service account ml-pipeline-scheduledworkflow and 1 container(s) [source: manifests/kustomize/base/pipeline/ml-pipeline-scheduledworkflow-deployment.yaml:1]
- **observed**: Deployment workload ml-pipeline-ui uses service account ml-pipeline-ui and 1 container(s) [source: manifests/kustomize/base/pipeline/ml-pipeline-ui-deployment.yaml:1]
- **observed**: Deployment workload ml-pipeline-viewer-crd uses service account ml-pipeline-viewer-crd-service-account and 1 container(s) [source: .github/resources/manifests/base/viewer-crd-pull-policy.yaml:1]
- **observed**: Deployment workload ml-pipeline-visualizationserver uses service account ml-pipeline-visualizationserver and 1 container(s) [source: manifests/kustomize/base/pipeline/ml-pipeline-visualization-deployment.yaml:1]
- **observed**: Deployment workload mysql uses service account mysql and 1 container(s) [source: manifests/kustomize/third-party/mysql/base/mysql-deployment.yaml:1]
- **observed**: Deployment workload seaweedfs uses service account seaweedfs and 1 container(s) [source: .github/resources/manifests/base/ci-stability-tuning.yaml:20]
- **observed**: Deployment workload workflow-controller uses service account  and 1 container(s) [source: manifests/kustomize/third-party/argo/installs/namespace/workflow-controller-deployment-patch.json:1]
- **observed**: Service cache-server targets cache-server with 1 port(s) [source: manifests/kustomize/base/cache/cache-service.yaml:1]
- **observed**: Service data-science-pipelines targets  with 0 port(s) [source: sdk/python/kfp/client/auth_test.py:43]
- **observed**: Service metadata-envoy-service targets metadata-envoy-deployment with 1 port(s) [source: manifests/kustomize/base/metadata/base/metadata-envoy-service.yaml:1]
- **observed**: Service metadata-grpc-service targets metadata-grpc-deployment with 1 port(s) [source: manifests/kustomize/base/metadata/base/metadata-grpc-service.yaml:1]
- **observed**: Service ml-pipeline targets ml-pipeline with 3 port(s) [source: manifests/kustomize/env/cert-manager/platform-agnostic-k8s-native/patches/service.json:1]
- **observed**: Service ml-pipeline-ui targets ml-pipeline-ui with 1 port(s) [source: manifests/kustomize/base/pipeline/ml-pipeline-ui-service.yaml:1]
- **observed**: Service ml-pipeline-visualizationserver targets ml-pipeline-visualizationserver with 1 port(s) [source: manifests/kustomize/base/pipeline/ml-pipeline-visualization-service.yaml:1]
- **observed**: Service mysql targets mysql with 1 port(s) [source: manifests/kustomize/third-party/mysql/base/mysql-service.yaml:1]
- **observed**: Service seaweedfs targets seaweedfs with 7 port(s) [source: manifests/kustomize/third-party/seaweedfs/base/seaweedfs/seaweedfs-service.yaml:3]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP Unknown /apis/v1alpha1/runs/{run_id}/nodes/{node_id}/log is owned by backend/src/apiserver [source: backend/src/apiserver/main.go:521]
- **observed**: HTTP Unknown /apis/v1beta1/healthz is owned by backend/src/apiserver [source: backend/src/apiserver/main.go:510]
- **observed**: HTTP Unknown /apis/v1beta1/pipelines/upload is owned by backend/src/apiserver [source: backend/src/apiserver/main.go:508]
- **observed**: HTTP Unknown /apis/v1beta1/pipelines/upload_version is owned by backend/src/apiserver [source: backend/src/apiserver/main.go:509]
- **observed**: HTTP Unknown /apis/v1beta1/runs/{run_id}/nodes/{node_id}/artifacts/{artifact_name}:read is owned by backend/src/apiserver [source: backend/src/apiserver/main.go:524]
- **observed**: HTTP Unknown /apis/v2beta1/healthz is owned by backend/src/apiserver [source: backend/src/apiserver/main.go:516]
- **observed**: HTTP Unknown /apis/v2beta1/pipelines/upload is owned by backend/src/apiserver [source: backend/src/apiserver/main.go:514]
- **observed**: HTTP Unknown /apis/v2beta1/pipelines/upload_version is owned by backend/src/apiserver [source: backend/src/apiserver/main.go:515]
- **observed**: HTTP Unknown /apis/v2beta1/runs/{run_id}/nodes/{node_id}/artifacts/{artifact_name}:read is owned by backend/src/apiserver [source: backend/src/apiserver/main.go:525]
- **observed**: HTTP Unknown /metrics is owned by backend/src/apiserver [source: backend/src/apiserver/main.go:533]
- **observed**: HTTP Unknown /metrics is owned by backend/src/crd/controller/scheduledworkflow [source: backend/src/crd/controller/scheduledworkflow/main.go:170]
- **observed**: HTTP Unknown /webhooks/mutate-pipelineversion is owned by backend/src/apiserver [source: backend/src/apiserver/main.go:549]
- **observed**: HTTP Unknown /webhooks/validate-pipelineversion is owned by backend/src/apiserver [source: backend/src/apiserver/main.go:548]
- **observed**: VirtualService metadata-grpc serves host * via plaintext; backend=metadata-envoy-service.kubeflow.svc.cluster.local; transport=HTTP [source: manifests/kustomize/base/metadata/options/istio/virtual-service.yaml:1]
### security

- **observed**: All HTTP API uses None (no auth middleware detected) at FastAPI/Starlette application; policy=No authentication middleware registered [source: sdk/python/kfp/client/auth_test.py:43]
- **observed**: CREATE Operator webhook uses Kubernetes admission at ValidatingWebhookConfiguration; policy=Admission validation [source: manifests/kustomize/env/cert-manager/platform-agnostic-k8s-native/patches/validating-webhook.yaml:1]
- **observed**: Kubernetes API Named Secret access (kfp-mlflow-credentials) uses RBAC with resourceNames restriction at kube-apiserver; policy=ml-pipeline restricts secret access to kfp-mlflow-credentials only [source: manifests/kustomize/env/cert-manager/platform-agnostic-k8s-native/patches/role.yaml:1]
- **observed**: PATCH mysql uses Istio source principal at Istio sidecar proxy AuthorizationPolicy; policy=Istio AuthorizationPolicy for app=mysql; allows principals: cluster.local/ns/kubeflow/sa/ml-pipeline, cluster.local/ns/kubeflow/sa/ml-pipeline-ui, cluster.local/ns/kubeflow/sa/ml-pipeline-persistenceagent, cluster.local/ns/kubeflow/sa/ml-pipeline-scheduledworkflow, cluster.local/ns/kubeflow/sa/ml-pipeline-viewer-crd-service-account, cluster.local/ns/kubeflow/sa/kubeflow-pipelines-cache, cluster.local/ns/kubeflow/sa/metadata-grpc-server [source: manifests/kustomize/third-party/mysql/options/istio/istio-authorization-policy.yaml:1]
- **observed**: RBAC role kubeflow-pipelines-metadata-writer-role grants 3 rule(s) [source: manifests/kustomize/base/pipeline/metadata-writer/metadata-writer-role.yaml:1]
- **observed**: RBAC role ml-pipeline grants 12 rule(s) [source: manifests/kustomize/env/cert-manager/platform-agnostic-k8s-native/patches/role.yaml:1]
- **observed**: RBAC role ml-pipeline-persistenceagent-role grants 4 rule(s) [source: manifests/kustomize/base/pipeline/ml-pipeline-persistenceagent-role.yaml:1]
- **observed**: RBAC role ml-pipeline-scheduledworkflow-role grants 4 rule(s) [source: manifests/kustomize/base/pipeline/ml-pipeline-scheduledworkflow-role.yaml:1]
- **observed**: RBAC role ml-pipeline-ui grants 5 rule(s) [source: manifests/kustomize/base/pipeline/ml-pipeline-ui-role.yaml:1]
- **observed**: RBAC role ml-pipeline-viewer-controller-role grants 2 rule(s) [source: manifests/kustomize/base/pipeline/ml-pipeline-viewer-crd-role.yaml:1]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via kubeflow-pipelines-cache-deployer-role Role; SA kubeflow-pipelines-cache-deployer-sa [source: backend/src/apiserver/client/util.go:33]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via kubeflow-pipelines-cache-role Role; SA kubeflow-pipelines-cache [source: backend/src/apiserver/client/util.go:33]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via kubeflow-pipelines-metadata-writer-role Role; SA kubeflow-pipelines-metadata-writer [source: backend/src/apiserver/client/util.go:33]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via ml-pipeline Role; SA ml-pipeline [source: backend/src/apiserver/client/util.go:33]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via ml-pipeline-persistenceagent-role Role; SA ml-pipeline-persistenceagent [source: backend/src/apiserver/client/util.go:33]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via ml-pipeline-scheduledworkflow-role Role; SA ml-pipeline-scheduledworkflow [source: backend/src/apiserver/client/util.go:33]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via ml-pipeline-ui Role; SA ml-pipeline-ui [source: backend/src/apiserver/client/util.go:33]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via ml-pipeline-viewer-controller-role Role; SA ml-pipeline-viewer-crd-service-account [source: backend/src/apiserver/client/util.go:33]
- **observed**: REST Kubernetes API uses kubeconfig credential chain at kube-apiserver; policy=Kubeconfig-based authentication using user-provided credentials [source: backend/src/common/util/service.go:64]
- **literal**: rbac-ref targets CreateSubjectAccessReviewClientOrFatal: Token or subject access review call [source: backend/src/apiserver/client_manager/client_manager.go:343]
- **literal**: rbac-ref targets CreateTokenReviewClientOrFatal: Token or subject access review call [source: backend/src/apiserver/client_manager/client_manager.go:344]
- **literal**: rbac-ref targets GetTokenReviewAudience: Token or subject access review call [source: backend/src/apiserver/auth/auth.go:41, backend/src/apiserver/client/token_review_fake.go:32]
- **literal**: rbac-ref targets NewFakeSubjectAccessReviewClient: Token or subject access review call [source: backend/src/apiserver/resource/client_manager_fake.go:89]
- **literal**: rbac-ref targets NewFakeTokenReviewClient: Token or subject access review call [source: backend/src/apiserver/resource/client_manager_fake.go:90, backend/src/apiserver/resource/client_manager_fake.go:95]
- **literal**: rbac-ref targets SubjectAccessReviewClient: Token or subject access review call [source: backend/src/apiserver/resource/resource_manager.go:175]
- **literal**: rbac-ref targets SubjectAccessReviews: Token or subject access review call [source: backend/src/apiserver/client/subject_access_review.go:37]
- **literal**: rbac-ref targets TokenReviewClient: Token or subject access review call [source: backend/src/apiserver/resource/resource_manager.go:176]
- **literal**: rbac-ref targets TokenReviews: Token or subject access review call [source: backend/src/apiserver/client/token_review.go:37]
- **literal**: rbac-ref targets doTokenReview: Token or subject access review call [source: backend/src/apiserver/auth/authenticator_token_review.go:53]
- **dependency-signal**: rbac-ref targets kubernetes: Kubernetes client library (RBAC capable) [source: components/aws/sagemaker/requirements_v2.txt:5]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: backend/src/agent/persistence/client/pipeline_client.go, backend/src/agent/persistence/main.go, backend/src/apiserver/client_manager/client_manager.go, backend/src/apiserver/main.go, backend/src/common/client/api_server/util.go, backend/src/common/client/api_server/v2/experiment_client.go, backend/src/common/client/api_server/v2/healthz_client.go, backend/src/common/client/api_server/v2/pipeline_client.go, backend/src/common/client/api_server/v2/pipeline_upload_client.go, backend/src/common/client/api_server/v2/recurring_run_client.go, backend/src/common/client/api_server/v2/run_client.go, backend/src/common/plugins/mlflow/config.go, backend/src/common/util/service.go, backend/src/common/util/tls_config.go, backend/src/crd/controller/scheduledworkflow/main.go, backend/src/v2/cacheutils/cache.go, backend/src/v2/client_manager/client_manager.go, backend/src/v2/cmd/driver/main.go, backend/src/v2/metadata/client.go]
- **dependency-signal**: tls-config targets google.golang.org/grpc/credentials: TLS configuration import [source: backend/src/apiserver/main.go, backend/src/common/util/service.go, backend/src/v2/cacheutils/cache.go, backend/src/v2/metadata/client.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
