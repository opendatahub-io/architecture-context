# Component: Data Science Pipelines Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/data-science-pipelines-operator.git
- **Version**: 6bcc644 (rhoai-2.12 branch)
- **Distribution**: RHOAI, ODH
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Deploys and manages Data Science Pipeline (Kubeflow Pipelines) stacks in individual OpenShift namespaces.

**Detailed**: The Data Science Pipelines Operator (DSPO) is a Kubernetes operator that automates the deployment and lifecycle management of Data Science Pipelines, which is based on the upstream Kubeflow Pipelines (KFP) project. It allows data scientists to create, track, and manage machine learning workflows for data preparation, model training, model validation, and experimentation. The operator watches for `DataSciencePipelinesApplication` custom resources and deploys a complete pipeline stack including API server, persistence agents, metadata tracking, optional UI, and optional storage/database components. It supports both v1 (Tekton-based) and v2 (Argo Workflows-based) pipeline implementations, with v2 being the current focus. The operator enables namespace-scoped deployments, allowing multiple independent pipeline instances across different projects within the same cluster.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Controller Manager | Kubernetes Operator | Reconciles DataSciencePipelinesApplication CRs and deploys pipeline components |
| DS Pipelines API Server | Deployment | REST/gRPC API for pipeline management, execution, and artifact retrieval |
| Persistence Agent | Deployment | Syncs workflow execution status to metadata database |
| Scheduled Workflow Controller | Deployment | Manages scheduled and recurring pipeline runs |
| MariaDB | StatefulSet (optional) | Stores pipeline and ML metadata (or use external MySQL) |
| Minio | Deployment (optional) | Object storage for pipeline artifacts (or use external S3-compatible storage) |
| ML Pipelines UI | Deployment (optional) | Web interface for pipeline visualization and management |
| ML Metadata (MLMD) gRPC | Deployment (optional) | gRPC service for ML metadata artifact lineage tracking |
| ML Metadata Envoy | Deployment (optional) | Envoy proxy providing HTTP/gRPC access to MLMD with OAuth |
| ML Metadata Writer | Deployment (optional, v1 only) | Writes execution metadata to MLMD store |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencepipelinesapplications.opendatahub.io | v1alpha1 | DataSciencePipelinesApplication | Namespaced | Defines a complete Data Science Pipeline stack deployment with configuration for API server, storage, database, UI, and optional components |
| N/A | N/A | ScheduledWorkflow | Namespaced | Secondary CRD for scheduled pipeline runs (deployed by operator but not managed as primary resource) |

### HTTP Endpoints

#### Operator Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for operator monitoring |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness probe |

#### DS Pipelines API Server Endpoints (per DSPA instance)

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /apis/v2beta1/* | GET, POST, DELETE | 8888/TCP | HTTP | None (internal) | None (internal) | Pipeline v2 API - internal cluster access |
| /apis/v1beta1/* | GET, POST, DELETE | 8888/TCP | HTTP | None (internal) | None (internal) | Pipeline v1 API - internal cluster access (deprecated) |
| /apis/v2beta1/* | GET, POST, DELETE | 8443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | OAuth2 Bearer Token | External route access to Pipeline API via OAuth proxy |
| /apis/v2beta1/artifacts/{id} | GET | 8888/TCP | HTTP | None (internal) | None (internal) | Artifact download with signed URLs |

#### ML Pipelines UI Endpoints (per DSPA instance)

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /* | GET | 8443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | OAuth2 Bearer Token | Web UI for pipeline management and visualization |

#### ML Metadata Envoy Endpoints (per DSPA instance, optional)

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /ml_metadata.MetadataStoreService/* | POST | 9090/TCP | gRPC | None (internal) | None (internal) | Internal gRPC access to ML Metadata |
| /* | GET, POST | 8443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | OAuth2 Bearer Token | External OAuth-protected access to MLMD |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| DS Pipelines API Server (gRPC) | 8887/TCP | gRPC | None (internal) | None | Internal gRPC API for pipeline operations |
| ML Metadata gRPC | Variable/TCP (default: 8080) | gRPC | None (internal) | None | ML Metadata artifact lineage tracking |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| OpenShift/Kubernetes | 4.11+ | Yes | Container orchestration platform |
| Argo Workflows | Latest stable | Yes (v2) | Workflow execution engine for DSP v2 pipelines |
| OpenShift Pipelines (Tekton) | 1.8+ | Yes (v1) | Workflow execution engine for DSP v1 pipelines (deprecated) |
| MariaDB/MySQL | 10.3+ | No | Pipeline metadata storage (can be external or deployed) |
| S3-compatible Object Storage | N/A | No | Pipeline artifact storage (can be external or use Minio) |
| OAuth Proxy | v4.12.0+ | Yes | Authentication and authorization for external routes |
| Service CA Operator | Included in OpenShift | Yes | TLS certificate provisioning for inter-service communication |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | UI Integration | Provides integrated pipeline UI and management interface |
| DataScienceCluster CR | CRD/Operator | Manages DSPO deployment as part of ODH/RHOAI platform |

## Network Architecture

### Services

#### Operator Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| service | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (Prometheus metrics) |

#### DSPA Instance Services (per DataSciencePipelinesApplication)

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| ds-pipeline-{name} | ClusterIP | 8443/TCP | oauth | HTTPS | TLS (service CA cert) | OAuth2 | Internal (via Route) |
| ds-pipeline-{name} | ClusterIP | 8888/TCP | http | HTTP | None | None | Internal only |
| ds-pipeline-{name} | ClusterIP | 8887/TCP | 8887 | gRPC | None | None | Internal only |
| ds-pipeline-ui-{name} | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS (service CA cert) | OAuth2 | Internal (via Route) |
| mariadb-{name} | ClusterIP | 3306/TCP | 3306 | MySQL | None | Password | Internal only |
| minio-{name} | ClusterIP | 9000/TCP | 9000 | HTTP | None | Access/Secret Key | Internal only |
| minio-{name} | ClusterIP | 80/TCP | 9000 | HTTP | None | Access/Secret Key | Internal only (UI workaround) |
| ds-pipeline-metadata-grpc-{name} | ClusterIP | Variable/TCP | Variable | gRPC | None | None | Internal only |
| ds-pipeline-md-{name} | ClusterIP | 9090/TCP | 9090 | gRPC | None | None | Internal only |
| ds-pipeline-md-{name} | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS (service CA cert) | OAuth2 | Internal (via Route) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| ds-pipeline-{name} | OpenShift Route | Auto-generated | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |
| ds-pipeline-ui-{name} | OpenShift Route | Auto-generated | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |
| minio-{name} | OpenShift Route (optional) | Auto-generated | 9000/TCP | HTTP | None (can enable TLS) | Edge/Passthrough | External (optional) |
| ds-pipeline-md-{name} | OpenShift Route (optional) | Auto-generated | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External (optional) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| External S3 Storage (if configured) | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM or Access/Secret Keys | Pipeline artifact storage |
| External MySQL/MariaDB (if configured) | 3306/TCP | MySQL | TLS (optional) | Username/Password | Pipeline metadata storage |
| Container Registries | 443/TCP | HTTPS | TLS 1.2+ | Token-based | Pull pipeline component images |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications, datasciencepipelinesapplications/status, datasciencepipelinesapplications/finalizers | create, delete, get, list, patch, update, watch |
| manager-role | apps | deployments, replicasets | create, delete, get, list, patch, update, watch, * |
| manager-role | "" | configmaps, persistentvolumeclaims, persistentvolumes, secrets, serviceaccounts, services, pods, pods/exec, pods/log, events | create, delete, get, list, patch, update, watch, * |
| manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| manager-role | rbac.authorization.k8s.io | roles, rolebindings, clusterroles, clusterrolebindings | create, delete, get, list, update, watch, patch |
| manager-role | networking.k8s.io | networkpolicies, ingresses | create, delete, get, list, patch, update, watch |
| manager-role | argoproj.io | workflows, workflowtaskresults | *, create, patch |
| manager-role | tekton.dev | * | * |
| manager-role | monitoring.coreos.com | servicemonitors | create, delete, get, list, patch, update, watch |
| manager-role | authentication.k8s.io | tokenreviews | create |
| manager-role | authorization.k8s.io | subjectaccessreviews | create |
| manager-role | batch | jobs | * |
| manager-role | image.openshift.io | imagestreamtags | get |
| manager-role | kubeflow.org | * | * |
| manager-role | machinelearning.seldon.io | seldondeployments | * |
| manager-role | ray.io | rayclusters, rayjobs, rayservices | create, delete, get, list, patch |
| manager-role | snapshot.storage.k8s.io | volumesnapshots | create, delete, get |
| manager-role | workload.codeflare.dev | appwrappers, appwrappers/finalizers, appwrappers/status | create, delete, deletecollection, get, list, patch, update, watch |
| manager-role | custom.tekton.dev | pipelineloops | * |
| leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| leader-election-role | "" | events | create, patch |
| argo-role (Argo v2) | argoproj.io | workflows, workflowtaskresults, workflowtemplates, cronworkflows, clusterworkflowtemplates | * |
| argo-role (Argo v2) | "" | pods, pods/log, configmaps, events, serviceaccounts | * |
| aggregate-dspa-edit | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications | create, delete, deletecollection, get, list, patch, update, watch |
| aggregate-dspa-view | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| role-binding | operator-namespace | manager-role | controller-manager |
| leader-election-role-binding | operator-namespace | leader-election-role | controller-manager |
| argo-role-binding (per DSPA) | dspa-namespace | argo-role | argo |
| ds-pipeline-persistenceagent-binding (per DSPA) | dspa-namespace | ds-pipeline-persistenceagent-role | ds-pipeline-persistenceagent-{name} |
| ds-pipeline-scheduledworkflow-binding (per DSPA) | dspa-namespace | ds-pipeline-scheduledworkflow-role | ds-pipeline-scheduledworkflow-{name} |
| ds-pipeline-ui-binding (per DSPA) | dspa-namespace | ds-pipeline-ui-role | ds-pipeline-ui-{name} |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| ds-pipelines-proxy-tls-{name} | kubernetes.io/tls | TLS cert for API server OAuth proxy | Service CA Operator | Yes |
| ds-pipelines-ui-proxy-tls-{name} | kubernetes.io/tls | TLS cert for UI OAuth proxy | Service CA Operator | Yes |
| ds-pipelines-envoy-proxy-tls-{name} | kubernetes.io/tls | TLS cert for MLMD Envoy proxy | Service CA Operator | Yes |
| {custom-db-secret} | Opaque | Database credentials (username/password) | User or DSPO (for MariaDB) | No |
| {custom-storage-secret} | Opaque | Object storage credentials (access key/secret key) | User or DSPO (for Minio) | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /apis/v2beta1/* (Route) | GET, POST, DELETE | OAuth2 Bearer Token (JWT) | OAuth Proxy (sidecar) | OpenShift RBAC via SAR |
| /apis/v2beta1/* (Service) | GET, POST, DELETE | None (internal cluster) | Network isolation | ClusterIP only |
| ML Pipelines UI (Route) | GET, POST | OAuth2 Bearer Token (JWT) | OAuth Proxy (sidecar) | OpenShift RBAC via SAR |
| MLMD Envoy (Route, optional) | GET, POST | OAuth2 Bearer Token (JWT) | OAuth Proxy (sidecar) | OpenShift RBAC via SAR |
| MariaDB (Service) | N/A | MySQL username/password | Application-level | Secret-based credentials |
| Minio (Service) | GET, PUT | S3 Access Key/Secret Key | Application-level | Secret-based credentials |

### Network Policies

| Policy Name | Namespace | Pod Selector | Ingress Rules | Purpose |
|-------------|-----------|--------------|---------------|---------|
| mariadb-{name} | dspa-namespace | app=mariadb-{name} | Allow from: operator namespace (dspo pods), same namespace (apiserver, mlmd-grpc) on port 3306/TCP | Restrict MariaDB access to authorized pipeline components only |

## Data Flows

### Flow 1: Pipeline Submission (External User to API Server)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/SDK | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ (Edge) | None |
| 2 | OpenShift Router | ds-pipeline Route | 8443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | None |
| 3 | Route | OAuth Proxy (sidecar) | 8443/TCP | HTTPS | TLS 1.2+ (Service CA) | OAuth2 Bearer Token |
| 4 | OAuth Proxy | DS Pipelines API Server | 8888/TCP | HTTP | None (localhost) | Delegated from OAuth |
| 5 | DS Pipelines API Server | MariaDB | 3306/TCP | MySQL | None (internal) | Username/Password |
| 6 | DS Pipelines API Server | Minio/S3 | 9000/TCP or 443/TCP | HTTP or HTTPS | None or TLS 1.2+ | Access/Secret Keys |

### Flow 2: Pipeline Execution (API Server to Workflow Engine)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | DS Pipelines API Server | Argo Workflow Controller (v2) or Tekton (v1) | 443/TCP (K8s API) | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Workflow Engine | Pipeline Runner Pods | N/A | N/A | N/A | ServiceAccount Token |
| 3 | Pipeline Runner Pods | Minio/S3 | 9000/TCP or 443/TCP | HTTP or HTTPS | None or TLS 1.2+ | Access/Secret Keys |

### Flow 3: ML Metadata Tracking (Pipeline to MLMD)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Pipeline Runner Pods | MLMD Envoy | 9090/TCP | gRPC | None (internal) | None |
| 2 | MLMD Envoy | MLMD gRPC Server | Variable/TCP | gRPC | None (internal) | None |
| 3 | MLMD gRPC Server | MariaDB | 3306/TCP | MySQL | None (internal) | Username/Password |

### Flow 4: UI Access (User to ML Pipelines UI)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ (Edge) | None |
| 2 | OpenShift Router | ds-pipeline-ui Route | 8443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | None |
| 3 | Route | OAuth Proxy (sidecar) | 8443/TCP | HTTPS | TLS 1.2+ (Service CA) | OAuth2 Bearer Token |
| 4 | OAuth Proxy | ML Pipelines UI | 3000/TCP | HTTP | None (localhost) | Delegated from OAuth |
| 5 | ML Pipelines UI | DS Pipelines API Server | 8888/TCP | HTTP | None (internal) | ServiceAccount Token |

### Flow 5: Metrics Collection (Prometheus to Operator)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | Operator Service | 8080/TCP | HTTP | None | ServiceAccount Token (via ServiceMonitor) |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Argo Workflows | Kubernetes API (CRD) | 443/TCP (K8s API) | HTTPS | TLS 1.2+ | Execute DSP v2 pipeline workflows |
| Tekton Pipelines | Kubernetes API (CRD) | 443/TCP (K8s API) | HTTPS | TLS 1.2+ | Execute DSP v1 pipeline workflows (deprecated) |
| ODH Dashboard | HTTP/HTTPS API | 8443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Embedded pipeline UI and management |
| Prometheus | HTTP (metrics) | 8080/TCP | HTTP | None | Operator and DSPA metrics collection |
| OpenShift OAuth | OAuth2 Token Review | 443/TCP (K8s API) | HTTPS | TLS 1.2+ | User authentication and authorization |
| External S3 Storage | S3 API | 443/TCP | HTTPS | TLS 1.2+ | Pipeline artifact persistence |
| External MySQL/MariaDB | MySQL Protocol | 3306/TCP | MySQL | TLS (optional) | Pipeline metadata persistence |
| Service CA Operator | Kubernetes API | 443/TCP (K8s API) | HTTPS | TLS 1.2+ | TLS certificate provisioning for services |
| Kfp-tekton SDK (v1) | REST/gRPC API | 8443/TCP (Route) | HTTPS | TLS 1.2+ (Reencrypt) | Pipeline authoring and submission (deprecated) |
| KFP SDK (v2) | REST/gRPC API | 8443/TCP (Route) | HTTPS | TLS 1.2+ (Reencrypt) | Pipeline authoring and submission |
| Elyra | REST API | 8443/TCP (Route) | HTTPS | TLS 1.2+ (Reencrypt) | Visual pipeline authoring and execution |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 6bcc644 | 1 year, 8 months ago | - Merged remote-tracking branch 'upstream/main' into rhoai-2.12 |
| b820bfa | 1 year, 8 months ago | - Merged pull request #60 from red-hat-data-services/main |
| 8469ebf | 1 year, 8 months ago | - Merged pull request #677 from HumairAK/stable |
| f4c3873 | 1 year, 8 months ago | - Increased default expiry for signed URL |
| 3dae311 | 1 year, 8 months ago | - Merged remote-tracking branch 'upstream/main' into rhoai-2.12 |
| d3ae899 | 1 year, 8 months ago | - Merged pull request #673 from dsp-developers/release-2.4<br>- Generated params for 2.4 |
| c1c1618 | 1 year, 8 months ago | - Merged pull request #672 from HumairAK/2.14-doc |
| 03a9bd3 | 1 year, 8 months ago | - Updated compatibility doc for 2.4 |
| 174be7f | 1 year, 8 months ago | - Merged pull request #656 from HumairAK/RHOAIENG-4968 |
| cf1bd60 | 1 year, 8 months ago | - Added service CA bundle for pod to pod TLS |
| a290b86 | 1 year, 8 months ago | - Added apiserver TLS support |
| bd4b501 | 1 year, 8 months ago | - Merged pull request #670 from HumairAK/RHOAIENG-8225 |
| 5a8177c | 1 year, 8 months ago | - Added the ability to configure artifact download link expiry |
| 4c179f5 | 1 year, 8 months ago | - Merged pull request #671 from HumairAK/up_res_db |
| 8417c79 | 1 year, 8 months ago | - Increased integration DB resources |
| 12c1549 | 1 year, 8 months ago | - Merged pull request #668 from hbelmiro/RHOAIENG-6580 |
| 89921c5 | 1 year, 8 months ago | - Enabled sample pipeline in DSPA samples |
| 8280dcd | 1 year, 9 months ago | - Merged pull request #667 from gmfrasca/wc-podspecs |
| fa280ae | 1 year, 9 months ago | - Added WorkflowController item to dspa_all_fields sample |

## Deployment Architecture

### Operator Deployment
The Data Science Pipelines Operator deploys as a single controller-manager pod in the operator namespace (typically `opendatahub` or managed by `DataScienceCluster`). The operator watches for `DataSciencePipelinesApplication` CRs across all namespaces (or namespaces it has access to) and reconciles the desired state by deploying the pipeline infrastructure components.

### DSPA Instance Deployment
When a user creates a `DataSciencePipelinesApplication` CR in a namespace, the operator deploys the following components in that namespace:

**Always Deployed:**
- API Server (1 replica) - Main pipeline API and orchestration
- Persistence Agent (1 replica) - Syncs workflow state to database
- Scheduled Workflow Controller (1 replica) - Manages scheduled/recurring runs

**Conditionally Deployed (based on DSPA spec):**
- MariaDB (1 replica) - If `spec.database.mariaDB.deploy: true` (default)
- Minio (1 replica) - If `spec.objectStorage.minio.deploy: true`
- ML Pipelines UI (1 replica) - If `spec.mlpipelineUI.deploy: true`
- ML Metadata components (3 deployments) - If `spec.mlmd.deploy: true`:
  - metadata-grpc server
  - metadata-envoy proxy
  - metadata-writer (v1 only)

### High Availability
The operator and DSPA components are deployed with single replicas by default. For production deployments requiring high availability:
- The operator supports leader election when multiple replicas are configured
- DSPA components (API Server, Persistence Agent, Scheduled Workflow) can be scaled horizontally, though this requires external database/storage for state consistency
- Database and object storage should use external, highly-available services for production

### Resource Requirements
Default resource allocations per the manifests:
- **Operator**: 200m CPU / 400Mi RAM (requests), 1 CPU / 4Gi RAM (limits)
- **API Server**: Configurable via DSPA CR, defaults set by operator
- **Persistence Agent**: Configurable via DSPA CR
- **Scheduled Workflow**: Configurable via DSPA CR
- **MariaDB**: 10Gi PVC by default, configurable

### Manifests Location
Kustomize deployment manifests are located in: `config/` directory with the following key subdirectories:
- `config/base/` - Base operator deployment
- `config/overlays/odh/` - ODH-specific overlays
- `config/overlays/rhoai/` - RHOAI-specific overlays
- `config/internal/` - Templates for DSPA component deployments (embedded in operator image)
- `config/crd/` - CRD definitions
- `config/rbac/` - RBAC manifests
- `config/manager/` - Operator deployment and service
