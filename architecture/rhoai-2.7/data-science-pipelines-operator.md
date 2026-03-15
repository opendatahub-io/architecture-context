# Component: Data Science Pipelines Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/data-science-pipelines-operator.git
- **Version**: 025e77a (rhoai-2.7 branch)
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Manages deployment and lifecycle of Data Science Pipelines (DSP) instances for ML workflow orchestration.

**Detailed**: The Data Science Pipelines Operator (DSPO) is a Kubernetes operator that deploys and manages single-namespace scoped Data Science Pipeline stacks. Based on upstream Kubeflow Pipelines (KFP) with kfp-tekton backend, it enables data scientists to create, track, and iterate on ML workflows for data preparation, model training, model validation, and experimentation. The operator reconciles `DataSciencePipelinesApplication` custom resources to deploy a complete pipeline stack including API server, persistence agent, scheduled workflow controller, and optional components like MariaDB, Minio, ML Pipelines UI, and ML Metadata (MLMD) services. Pipelines are executed as Tekton PipelineRuns rather than Argo workflows.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| DSPO Controller Manager | Operator Deployment | Reconciles DataSciencePipelinesApplication CRs and manages DSP component lifecycle |
| API Server | Deployment (per DSPA) | KFP API server providing HTTP/gRPC endpoints for pipeline submission, execution, and metadata retrieval |
| Persistence Agent | Deployment (per DSPA) | Syncs Tekton PipelineRun metadata to the database for tracking and visualization |
| Scheduled Workflow | Deployment (per DSPA) | Manages scheduled and recurring pipeline executions with cron-based triggers |
| MariaDB | Deployment (optional per DSPA) | Metadata database for storing pipeline definitions, runs, experiments, and artifacts |
| Minio | Deployment (optional per DSPA) | S3-compatible object storage for pipeline artifacts (development/testing only, not production) |
| ML Pipelines UI | Deployment (optional per DSPA) | Web UI for browsing pipelines, experiments, and runs (unsupported, development/testing only) |
| MLMD Envoy | Deployment (optional per DSPA) | Envoy proxy for ML Metadata gRPC service |
| MLMD gRPC Server | Deployment (optional per DSPA) | ML Metadata gRPC service for artifact lineage and metadata tracking |
| MLMD Writer | Deployment (optional per DSPA) | Writes metadata to the MLMD store during pipeline execution |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencepipelinesapplications.opendatahub.io | v1alpha1 | DataSciencePipelinesApplication | Namespaced | Declares a DSP stack deployment with database, object storage, and component configurations |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /apis/v1beta1/* | GET/POST/PUT/DELETE | 8888/TCP | HTTP | None (internal) | Service token | KFP API server endpoints for pipeline management (internal pod-to-pod) |
| /apis/v1beta1/healthz | GET | 8888/TCP | HTTP | None | None | API server health check |
| /metrics | GET | 8080/TCP | HTTP | None | None | Operator controller metrics (Prometheus) |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator controller health check |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator controller readiness check |
| /* | GET/POST/PUT/DELETE | 8443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | OAuth Bearer Token | External API access via OAuth proxy on Route |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ml_pipelines.PipelineService | 8887/TCP | gRPC/HTTP2 | None (internal) | Service token | KFP gRPC API for pipeline operations |
| ml_metadata.MetadataStoreService | 8080/TCP | gRPC/HTTP2 | None (internal) | None | MLMD metadata store service |
| ml_metadata_envoy | 9090/TCP | gRPC/HTTP2 | None (internal) | None | MLMD Envoy proxy for metadata access |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| OpenShift/Kubernetes | 4.9+ | Yes | Platform for operator and workload deployment |
| OpenShift Pipelines (Tekton) | 1.8+ | Yes | Pipeline execution engine (kfp-tekton requires Tekton for PipelineRuns) |
| MariaDB | 10.x (or external SQL) | Yes | Metadata storage for pipelines, runs, experiments, and artifacts |
| S3-compatible Object Storage | N/A | Yes | Artifact storage (Minio for dev/test, AWS S3/external for production) |
| OAuth Proxy | Latest | Yes (for external access) | OAuth2 authentication for external route access |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | UI Integration | Provides integrated pipeline UI experience within ODH dashboard |
| OpenShift Monitoring | ServiceMonitor | Operator metrics collected by user workload monitoring |
| OpenShift Routes | Route CRD | Exposes API server and UI via HTTPS routes with OAuth |
| OpenShift Service CA | TLS Certificate | Auto-generates TLS certificates for OAuth proxy services |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| ds-pipeline-{name} | ClusterIP | 8443/TCP | oauth | HTTPS | TLS (service-ca) | OAuth Bearer Token | Internal/External (via Route) |
| ds-pipeline-{name} | ClusterIP | 8888/TCP | http | HTTP | None | Service token | Internal only |
| ds-pipeline-{name} | ClusterIP | 8887/TCP | 8887 | gRPC | None | Service token | Internal only |
| mariadb-{name} | ClusterIP | 3306/TCP | 3306 | MySQL | None | Username/Password | Internal only |
| minio-{name} | ClusterIP | 9000/TCP | 9000 | HTTP | None | Access/Secret Key | Internal only |
| ds-pipeline-ui-{name} | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS (service-ca) | OAuth Bearer Token | Internal/External (via Route) |
| ds-pipeline-metadata-grpc-{name} | ClusterIP | 8080/TCP | 8080 | gRPC | None | None | Internal only |
| ds-pipeline-metadata-envoy-{name} | ClusterIP | 9090/TCP | 9090 | gRPC | None | None | Internal only |
| data-science-pipelines-operator/service | ClusterIP | 8080/TCP | metrics | HTTP | None | None | Internal (monitoring) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| ds-pipeline-{name} | OpenShift Route | Auto-generated | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |
| ds-pipeline-ui-{name} | OpenShift Route | Auto-generated | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| External S3 (AWS/etc) | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM or Access/Secret Key | Upload/download pipeline artifacts to external object storage |
| External Database | 3306/TCP or 5432/TCP | MySQL/PostgreSQL | TLS 1.2+ (optional) | Username/Password | Connect to external metadata database |
| Tekton Pipelines API | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token | Create and manage Tekton PipelineRuns for pipeline execution |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull secrets | Pull pipeline task container images |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications, datasciencepipelinesapplications/status, datasciencepipelinesapplications/finalizers | create, delete, get, list, patch, update, watch |
| manager-role | "", apps | deployments, services, configmaps, secrets, serviceaccounts, persistentvolumeclaims | create, delete, get, list, patch, update, watch |
| manager-role | rbac.authorization.k8s.io | roles, rolebindings, clusterroles, clusterrolebindings | create, delete, get, list, patch, update, watch |
| manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| manager-role | tekton.dev | * | * |
| manager-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| manager-role | monitoring.coreos.com | servicemonitors | create, delete, get, list, patch, update, watch |
| manager-role | authentication.k8s.io | tokenreviews | create |
| manager-role | authorization.k8s.io | subjectaccessreviews | create |
| manager-role | argoproj.io | workflows | * |
| manager-role | kubeflow.org | * | * |
| manager-role | custom.tekton.dev | pipelineloops | * |
| manager-role | machinelearning.seldon.io | seldondeployments | * |
| manager-role | ray.io | rayclusters, rayjobs, rayservices | create, delete, get, list, patch |
| manager-role | mcad.ibm.com, workload.codeflare.dev | appwrappers | create, delete, get, list, patch, update, watch |
| manager-role | snapshot.storage.k8s.io | volumesnapshots | create, delete, get |
| manager-role | batch | jobs | * |
| manager-role | "" | pods, pods/exec, pods/log, events | create, delete, get, list, patch, update, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | All (ClusterRoleBinding) | manager-role | datasciencepipelinesapplications-controller/controller-manager |
| ds-pipeline-{name} | {dspa-namespace} | ds-pipeline-{name} | {dspa-namespace}/ds-pipeline-{name} |
| pipeline-runner-{name} | {dspa-namespace} | pipeline-runner-{name} | {dspa-namespace}/pipeline-runner-{name} |
| ds-pipeline-scheduledworkflow-{name} | {dspa-namespace} | ds-pipeline-scheduledworkflow-{name} | {dspa-namespace}/ds-pipeline-scheduledworkflow-{name} |
| ds-pipeline-persistenceagent-{name} | {dspa-namespace} | ds-pipeline-persistenceagent-{name} | {dspa-namespace}/ds-pipeline-persistenceagent-{name} |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| ds-pipeline-db-{name} | Opaque | MariaDB password for DSP API server | DSPO | No |
| mlpipeline-minio-artifact | Opaque | S3 access/secret keys for object storage | User or DSPO (Minio) | No |
| ds-pipelines-proxy-tls-{name} | kubernetes.io/tls | TLS certificate for OAuth proxy on API server | OpenShift Service CA | Yes |
| ds-pipelines-ui-proxy-tls-{name} | kubernetes.io/tls | TLS certificate for OAuth proxy on UI | OpenShift Service CA | Yes |
| mariadb-{name} | Opaque | MariaDB root password (internal Minio deployment) | DSPO | No |
| minio-{name} | Opaque | Minio access/secret keys (internal Minio deployment) | DSPO | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| ds-pipeline-{name} Route (8443/TCP) | GET, POST, PUT, DELETE | OAuth Bearer Token (JWT) | OAuth Proxy sidecar | OpenShift OAuth |
| ds-pipeline-ui-{name} Route (8443/TCP) | GET, POST | OAuth Bearer Token (JWT) | OAuth Proxy sidecar | OpenShift OAuth |
| API Server (8888/TCP internal) | GET, POST, PUT, DELETE | Service Account Token | NetworkPolicy | Namespace-scoped pod selector |
| MariaDB (3306/TCP) | SQL | Username/Password | MySQL auth | DSPA namespace isolation |
| Minio (9000/TCP) | S3 API | Access/Secret Key | Minio auth | DSPA namespace isolation |
| MLMD gRPC (8080/TCP) | gRPC | None (internal only) | NetworkPolicy | Namespace-scoped pod selector |

### Network Policies

| Policy Name | Namespace | Pod Selector | Ingress Rules | Purpose |
|-------------|-----------|--------------|---------------|---------|
| ds-pipelines-{name} | {dspa-namespace} | app: ds-pipeline-{name} | Allow 8443/TCP from all; Allow 8888/TCP and 8887/TCP from DSPA components and monitoring namespaces | Isolate API server to OAuth proxy (external) and DSPA pods (internal) |

**NetworkPolicy Details**:
- **Port 8443/TCP**: Open to all sources (OAuth proxy endpoint)
- **Ports 8888/TCP, 8887/TCP**: Only accessible from:
  - Pods with label `component: data-science-pipelines` in same namespace
  - Namespace `openshift-user-workload-monitoring` (monitoring)
  - Namespace `redhat-ods-monitoring` (RHOAI monitoring)
  - Specific DSPA pods: mariadb, minio, ui, persistenceagent, scheduledworkflow, mlmd components

## Data Flows

### Flow 1: External User Submits Pipeline via UI

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | None (public ingress) |
| 2 | OpenShift Router | ds-pipeline-ui-{name} Route | 8443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | OAuth Bearer Token |
| 3 | UI OAuth Proxy | UI Pod | 3000/TCP | HTTP | None (pod-local) | None |
| 4 | UI Pod | ds-pipeline-{name} Service | 8888/TCP | HTTP | None (internal) | Service Account Token |
| 5 | API Server | MariaDB | 3306/TCP | MySQL | None (internal) | Username/Password |
| 6 | API Server | Minio/S3 | 9000/TCP or 443/TCP | HTTP/HTTPS | TLS (if S3) | Access/Secret Key |
| 7 | API Server | Tekton API | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token |

### Flow 2: Pipeline Execution via kfp-tekton SDK

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Notebook/Script | ds-pipeline-{name} Route | 8443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | OAuth Bearer Token |
| 2 | API Server | MariaDB | 3306/TCP | MySQL | None (internal) | Username/Password |
| 3 | API Server | Tekton API | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 4 | Tekton PipelineRun | Pipeline Task Pods | Various | Various | TLS (if external) | Pull secrets |
| 5 | Pipeline Task Pods | Minio/S3 | 9000/TCP or 443/TCP | HTTP/HTTPS | TLS (if S3) | Access/Secret Key |
| 6 | Persistence Agent | Tekton API | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 7 | Persistence Agent | API Server | 8888/TCP | HTTP | None (internal) | Service Account Token |

### Flow 3: Scheduled Pipeline Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Scheduled Workflow Controller | API Server | 8888/TCP | HTTP | None (internal) | Service Account Token |
| 2 | API Server | Tekton API | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 3 | Tekton PipelineRun | Pipeline Task Pods | Various | Various | TLS (if external) | Pull secrets |
| 4 | Pipeline Task Pods | Minio/S3 | 9000/TCP or 443/TCP | HTTP/HTTPS | TLS (if S3) | Access/Secret Key |
| 5 | Persistence Agent | MariaDB | 3306/TCP | MySQL | None (internal) | Username/Password |

### Flow 4: ML Metadata Tracking

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Pipeline Task Pod | MLMD Envoy | 9090/TCP | gRPC/HTTP2 | None (internal) | None |
| 2 | MLMD Envoy | MLMD gRPC Server | 8080/TCP | gRPC/HTTP2 | None (internal) | None |
| 3 | MLMD gRPC Server | MariaDB | 3306/TCP | MySQL | None (internal) | Username/Password |
| 4 | MLMD Writer | MLMD gRPC Server | 8080/TCP | gRPC/HTTP2 | None (internal) | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| OpenShift Pipelines (Tekton) | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | Create PipelineRuns, TaskRuns; watch execution status |
| ODH Dashboard | HTTP/gRPC API | 8443/TCP (via Route) | HTTPS | TLS 1.2+ | Integrated pipeline UI and management |
| OpenShift Monitoring | ServiceMonitor (Prometheus) | 8080/TCP | HTTP | None | Collect operator and DSPA component metrics |
| OpenShift OAuth | OAuth2 Proxy | 443/TCP | HTTPS | TLS 1.2+ | User authentication and authorization |
| External S3 Storage | S3 API | 443/TCP | HTTPS | TLS 1.2+ | Store and retrieve pipeline artifacts |
| External Database (MySQL/PostgreSQL) | SQL Protocol | 3306/TCP or 5432/TCP | MySQL/PostgreSQL | TLS (optional) | Pipeline metadata persistence |
| Container Registry (Quay/etc) | OCI Registry API | 443/TCP | HTTPS | TLS 1.2+ | Pull task container images |
| Elyra / kfp-tekton SDK | HTTP/gRPC API | 8443/TCP (via Route) | HTTPS | TLS 1.2+ | Submit and manage pipelines programmatically |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 025e77a | 2024 | - Merge pull request #540 from HumairAK/stable<br>- Update to latest 1.5 DSP images<br>- Add support for CA bundle injection for TLS connections |
| 4ad7227 | 2024 | - Merge remote-tracking branch 'odh/v1.5.x' into stable |
| 6c9550c | 2024 | - Merge pull request #525 from HumairAK/v1.5.x |
| 961edf9 | 2024 | - Update pre-commit to support golang 1.19<br>- Correct linting<br>- Upgrade to Go 1.19 |
| e874fa4 | 2024 | - Add support for ca bundle injection |
| b5c93c5 | 2024 | - Update golang grpc pkg<br>- Update x/net pkg |
| c3393ab | 2024 | - Add params for v1.4.1 |
| 5907202 | 2024 | - Add support for ca bundle injection |
| 7a590dd | 2024 | - Update http2/grpc packages<br>- Update GO version to 1.19 |
| 9a5ce76 | 2024 | - Update http2/grpc packages |

## Deployment Configuration

The operator uses Kustomize for deployment manifest generation. The manifests folder specified is `config:data-science-pipelines-operator`, indicating that deployment configurations are in the `config/` directory.

**Key Kustomize Bases**:
- `config/base`: Base operator deployment
- `config/manager`: Controller manager deployment and service
- `config/rbac`: RBAC roles and bindings
- `config/crd`: Custom Resource Definitions
- `config/internal`: Component templates for DSPA deployments (API server, MariaDB, Minio, MLMD, UI, etc.)
- `config/samples`: Example DSPA custom resources
- `config/prometheus`: ServiceMonitor for metrics

**Template System**: The operator uses Go templates (`.tmpl` files) in `config/internal/` to dynamically generate Kubernetes manifests for each DSPA instance. Templates are parameterized with values from the DSPA spec and operator config.

## Metrics

The operator exposes the following custom metrics for monitoring DSPA status:

| Metric Name | Type | Labels | Purpose |
|-------------|------|--------|---------|
| data_science_pipelines_application_apiserver_ready | Gauge | name, namespace | Indicates if DSPA API Server is ready (1=Ready, 0=Not Ready) |
| data_science_pipelines_application_persistenceagent_ready | Gauge | name, namespace | Indicates if DSPA Persistence Agent is ready (1=Ready, 0=Not Ready) |
| data_science_pipelines_application_scheduledworkflow_ready | Gauge | name, namespace | Indicates if DSPA Scheduled Workflow is ready (1=Ready, 0=Not Ready) |
| data_science_pipelines_application_ready | Gauge | name, namespace | Indicates if DSPA is fully ready (1=Ready, 0=Not Ready) |

Additionally, standard operator-sdk controller metrics are exposed on port 8080 for Prometheus scraping.

## Notes

- **Production Object Storage**: Minio deployment is unsupported for production use. Configure `spec.objectStorage.externalStorage` with AWS S3, Azure Blob, or other S3-compatible storage.
- **Production Database**: MariaDB deployment is suitable for development/testing. For production, use `spec.database.externalDB` with a managed database service.
- **ML Pipelines UI**: The KFP UI is unsupported and will be replaced by ODH Dashboard integration. Use for development/experimentation only.
- **Tekton Backend**: DSPO uses kfp-tekton (not Argo) for pipeline execution, requiring OpenShift Pipelines (Tekton) to be installed.
- **Namespace Isolation**: Each DSPA is namespace-scoped. Multiple DSPA instances can exist in different namespaces but not in the same namespace.
- **Pipeline Runner Permissions**: The `pipeline-runner-{name}` service account has extensive permissions within the DSPA namespace to support various ML workload integrations (Ray, Seldon, CodeFlare, etc.).
