# Component: Data Science Pipelines Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/data-science-pipelines-operator
- **Version**: a91ea11 (rhoai-2.10 branch, 2024-05-10)
- **Distribution**: RHOAI, ODH
- **Languages**: Go 1.20
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Deploys and manages Data Science Pipelines instances for ML workflow orchestration on OpenShift.

**Detailed**: The Data Science Pipelines Operator (DSPO) is a Kubernetes operator that deploys and manages namespace-scoped Data Science Pipelines stacks. Based on Kubeflow Pipelines, it enables data scientists to create, track, and execute ML workflows for data preparation, model training, and validation. The operator manages the full lifecycle of pipeline infrastructure components including API servers, metadata stores, workflow schedulers, and optional UI components. It supports both v1 (Tekton-based) and v2 (Argo-based) pipeline execution engines, with flexible storage and database backends for production and development environments.

DSPO reconciles `DataSciencePipelinesApplication` custom resources to deploy a complete pipeline stack per namespace, including automated secret management, network policy enforcement, and OAuth-based route exposure. The operator handles health checking of external dependencies, automated TLS certificate provisioning, and RBAC configuration for pipeline execution.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| DSPO Controller Manager | Go Operator | Reconciles DataSciencePipelinesApplication CRs and deploys pipeline infrastructure |
| DS Pipelines API Server | Microservice | REST/gRPC API for pipeline management, run submission, and artifact tracking |
| Persistence Agent | Microservice | Synchronizes workflow execution state to metadata database |
| Scheduled Workflow Controller | Microservice | Manages cron-based pipeline execution schedules |
| Workflow Controller | Argo Workflows | Orchestrates pipeline execution as Kubernetes workflows (DSP v2) |
| ML Metadata (MLMD) | Optional Service | Tracks ML artifacts, lineage, and metadata using MLMD gRPC and Envoy proxy |
| MariaDB | Optional Database | Metadata persistence for pipelines, runs, and experiments |
| Minio | Optional Storage | S3-compatible object storage for pipeline artifacts and outputs |
| ML Pipelines UI | Optional Frontend | Web interface for pipeline visualization and management |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencepipelinesapplications.opendatahub.io | v1alpha1 | DataSciencePipelinesApplication | Namespaced | Declares a Data Science Pipelines stack with database, storage, and component configuration |
| argoproj.io | v1alpha1 | Workflow | Namespaced | Argo workflow resources for pipeline execution (v2 only, managed by deployed components) |
| argoproj.io | v1alpha1 | WorkflowTemplate | Namespaced | Reusable workflow templates (v2 only, managed by deployed components) |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator health check |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness check |
| /metrics | GET | 8080/TCP | HTTP | None | None | Operator Prometheus metrics |
| /apis/* | ALL | 8888/TCP | HTTP | TLS 1.2+ (in-cluster) | Bearer Token | DS Pipelines REST API (pipeline CRUD, runs, experiments) |
| /apis/* | ALL | 8443/TCP | HTTPS | TLS 1.3 (Reencrypt) | OAuth Proxy | DS Pipelines REST API via OpenShift Route |
| / | GET | 8443/TCP | HTTPS | TLS 1.3 | OAuth Proxy | ML Pipelines UI web interface |
| / | GET,PUT | 9000/TCP | HTTP | None (internal) | S3 Signature | Minio object storage API |
| /envoy-admin | GET | 9901/TCP | HTTP | None | None | MLMD Envoy admin interface |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ml_metadata.MetadataStoreService | 8080/TCP | gRPC | None (internal) | None | ML Metadata store for artifact and lineage tracking |
| ds-pipeline API | 8887/TCP | gRPC | None (internal) | Bearer Token | DS Pipelines gRPC API for workflow submission |
| MLMD Envoy Proxy | 9090/TCP | gRPC | None (internal) | None | Envoy proxy for MLMD gRPC service |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| OpenShift / Kubernetes | 4.11+ | Yes | Container orchestration platform |
| Argo Workflows | 3.x | Yes (v2) | Workflow execution engine for DSP v2 |
| Tekton Pipelines | 1.8+ | Yes (v1) | Pipeline execution engine for DSP v1 (deprecated) |
| MariaDB or MySQL | 10.3+ / 5.7+ | No | Metadata database (can use external or deployed instance) |
| S3-compatible storage | N/A | No | Object storage for artifacts (can use external or deployed Minio) |
| OAuth Proxy | v4.12.0+ | Yes | Authentication for exposed routes |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | UI Integration | Displays pipeline runs and links to pipeline UI |
| opendatahub-operator | CRD Watch | Deployed via DataScienceCluster when datasciencepipelines component is enabled |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| ds-pipeline-{name} | ClusterIP | 8443/TCP | oauth | HTTPS | TLS 1.2+ | OAuth Proxy | Internal |
| ds-pipeline-{name} | ClusterIP | 8888/TCP | http | HTTP | None | Bearer Token | Internal |
| ds-pipeline-{name} | ClusterIP | 8887/TCP | 8887 | gRPC | None | Bearer Token | Internal |
| ds-pipeline-ui-{name} | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | OAuth Proxy | Internal |
| ds-pipeline-metadata-grpc-{name} | ClusterIP | 8080/TCP | 8080 | gRPC | None | None | Internal |
| ds-pipeline-metadata-envoy-{name} | ClusterIP | 9090/TCP | 9090 | gRPC | None | None | Internal |
| mariadb-{name} | ClusterIP | 3306/TCP | 3306 | TCP | TLS (optional) | MySQL Auth | Internal |
| minio-{name} | ClusterIP | 9000/TCP | 9000 | HTTP | None | S3 Signature | Internal |
| minio-{name} | ClusterIP | 80/TCP | 9000 | HTTP | None | S3 Signature | Internal |
| data-science-pipelines-operator-service | ClusterIP | 8080/TCP | metrics | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| ds-pipeline-{name} | OpenShift Route | {generated}.cluster.local | 8443/TCP | HTTPS | TLS 1.3 | Reencrypt | External |
| ds-pipeline-ui-{name} | OpenShift Route | {generated}.cluster.local | 8443/TCP | HTTPS | TLS 1.3 | Reencrypt | External |
| ds-pipeline-metadata-envoy-{name} | OpenShift Route | {generated}.cluster.local | 8443/TCP | HTTPS | TLS 1.3 | Reencrypt | External (optional) |
| minio-{name} | OpenShift Route | {generated}.cluster.local | 9000/TCP | HTTP | None | Edge | External (dev only) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| External S3 Endpoint | 443/TCP | HTTPS | TLS 1.2+ | AWS Signature v4 | Upload/download pipeline artifacts to external object storage |
| External MySQL/MariaDB | 3306/TCP | TCP | TLS (optional) | MySQL Auth | Store pipeline metadata in external database |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token | Pull pipeline component container images |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications, datasciencepipelinesapplications/status, datasciencepipelinesapplications/finalizers | create, delete, get, list, patch, update, watch |
| manager-role | "" | configmaps, secrets, services, serviceaccounts, persistentvolumeclaims, pods | create, delete, get, list, patch, update, watch |
| manager-role | apps | deployments, replicasets | create, delete, get, list, patch, update, watch |
| manager-role | rbac.authorization.k8s.io | roles, rolebindings, clusterroles, clusterrolebindings | create, delete, get, list, patch, update, watch |
| manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| manager-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| manager-role | argoproj.io | workflows, workflowtaskresults | create, patch, get, list, watch |
| manager-role | tekton.dev | pipelineruns, taskruns, tasks, conditions, runs | * |
| manager-role | monitoring.coreos.com | servicemonitors | create, delete, get, list, patch, update, watch |
| manager-role | batch | jobs | * |
| manager-role | kubeflow.org | * | * |
| manager-role | ray.io | rayclusters, rayjobs, rayservices | create, delete, get, list, patch |
| manager-role | machinelearning.seldon.io | seldondeployments | * |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | operator-namespace | manager-role (ClusterRole) | controller-manager |
| ds-pipeline-{name} | user-namespace | ds-pipeline-{name} (Role) | ds-pipeline-{name} |
| pipeline-runner-{name} | user-namespace | pipeline-runner-{name} (Role) | pipeline-runner-{name} |
| ds-pipeline-metadata-grpc-{name} | user-namespace | ds-pipeline-metadata-grpc-{name} (Role) | ds-pipeline-metadata-grpc-{name} |
| ds-pipeline-metadata-writer-{name} | user-namespace | ds-pipeline-metadata-writer-{name} (Role) | ds-pipeline-metadata-writer-{name} |
| ds-pipeline-persistenceagent-{name} | user-namespace | ds-pipeline-persistenceagent-{name} (Role) | ds-pipeline-persistenceagent-{name} |
| ds-pipeline-scheduledworkflow-{name} | user-namespace | ds-pipeline-scheduledworkflow-{name} (Role) | ds-pipeline-scheduledworkflow-{name} |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| ds-pipelines-proxy-tls-{name} | kubernetes.io/tls | TLS certificate for API Server OAuth proxy | service-serving-cert-signer | Yes |
| ds-pipelines-ui-proxy-tls-{name} | kubernetes.io/tls | TLS certificate for UI OAuth proxy | service-serving-cert-signer | Yes |
| ds-pipeline-db-{name} | Opaque | MariaDB root password (auto-generated) | DSPO | No |
| {custom-db-secret} | Opaque | External database credentials | User | No |
| ds-pipeline-s3-{name} | Opaque | Minio access/secret keys (auto-generated) | DSPO | No |
| {custom-storage-secret} | Opaque | External S3 credentials (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY) | User | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /apis/* (Route) | ALL | OAuth Proxy (Bearer Token) | OpenShift OAuth Proxy sidecar | User must have access to namespace |
| /apis/* (Service) | ALL | Bearer Token (K8s SA token) | API Server | Validates K8s service account token |
| /metrics | GET | None | N/A | Open for Prometheus scraping |
| Minio S3 API | ALL | AWS Signature v4 | Minio server | Validates access/secret key from secret |
| MariaDB | TCP | MySQL native auth | MariaDB server | Username/password from secret |
| MLMD gRPC | gRPC | None (network policy restricted) | NetworkPolicy | Only accessible from API Server, MLMD writer |

### Network Policies

| Policy Name | Namespace | Pod Selector | Ingress From | Ingress Ports | Purpose |
|-------------|-----------|--------------|--------------|---------------|---------|
| mariadb-{name} | user-namespace | app=mariadb-{name} | DSPO operator pods, ds-pipeline API server, MLMD gRPC | 3306/TCP | Restrict MariaDB access to pipeline components only |
| mlmd-envoy-dashboard-access-{name} | user-namespace | app=ds-pipeline-metadata-envoy-{name} | Dashboard pods, UI pods | 8443/TCP | Allow dashboard access to MLMD Envoy UI |

## Data Flows

### Flow 1: Pipeline Submission via API

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Client | ds-pipeline Route | 8443/TCP | HTTPS | TLS 1.3 | Bearer Token (OAuth) |
| 2 | OAuth Proxy | ds-pipeline API Server | 8888/TCP | HTTP | None | Bearer Token |
| 3 | API Server | MariaDB | 3306/TCP | TCP | TLS (optional) | MySQL Auth |
| 4 | API Server | Minio | 9000/TCP | HTTP | None | S3 Signature |
| 5 | API Server | Argo Workflows | 8001/TCP | HTTP | None | SA Token |

### Flow 2: Pipeline Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Scheduled Workflow | API Server | 8888/TCP | HTTP | None | Bearer Token |
| 2 | API Server | Argo Workflow Controller | 8001/TCP | HTTP | None | SA Token |
| 3 | Workflow Pod | Minio | 9000/TCP | HTTP | None | S3 Signature |
| 4 | Workflow Pod | MLMD gRPC | 8080/TCP | gRPC | None | None (network restricted) |
| 5 | Persistence Agent | MariaDB | 3306/TCP | TCP | TLS (optional) | MySQL Auth |

### Flow 3: Artifact Retrieval

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | UI User | ds-pipeline-ui Route | 8443/TCP | HTTPS | TLS 1.3 | Bearer Token (OAuth) |
| 2 | UI Pod | API Server | 8888/TCP | HTTP | None | Bearer Token |
| 3 | UI Pod | Minio | 80/TCP | HTTP | None | S3 Signature |
| 4 | UI Pod | MLMD Envoy | 9090/TCP | gRPC | None | None |

### Flow 4: Metadata Lineage Tracking

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Workflow Pod | MLMD Writer | 8080/TCP | gRPC | None | None (network restricted) |
| 2 | MLMD Writer | MLMD gRPC | 8080/TCP | gRPC | None | None |
| 3 | MLMD gRPC | MariaDB | 3306/TCP | TCP | TLS (optional) | MySQL Auth |
| 4 | API Server | MLMD Envoy | 9090/TCP | gRPC | None | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Argo Workflows | Kubernetes API | 8001/TCP | HTTP | None | Submit and monitor workflow executions for DSP v2 pipelines |
| Tekton Pipelines | Kubernetes API | 8001/TCP | HTTP | None | Submit and monitor pipeline runs for DSP v1 pipelines (deprecated) |
| MariaDB/MySQL | Database Connection | 3306/TCP | TCP | TLS (optional) | Persist pipeline metadata, runs, experiments, and ML metadata |
| S3 Storage | S3 API | 443/TCP or 9000/TCP | HTTPS/HTTP | TLS 1.2+ or None | Store pipeline artifacts, outputs, and logs |
| Prometheus | Metrics Scrape | 8080/TCP | HTTP | None | Collect operator and DSPA component health metrics |
| OpenShift OAuth | OAuth Callback | 8443/TCP | HTTPS | TLS 1.3 | Authenticate users accessing pipeline API and UI routes |
| ODH Dashboard | Kubernetes API | 8001/TCP | HTTP | None | List DSPAs and provide navigation links to pipeline UI |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| a91ea11 | 2024-05-10 | - Merged release-2.2 changes<br>- Generated params for version 2.2 |
| c92e56a | 2024-05-10 | - Deploy MariaDB network policy with MariaDB deployment |
| 8f9a2bb | 2024-05-10 | - Removed image health check validation |
| ddc452d | 2024-05-10 | - Updated release automation for DSP v2 |
| da3fc1a | 2024-05-10 | - Refactored params.env configuration structure |
| 3af7b77 | 2024-05-08 | - Refactored ConfigMap and Secret paths for TLS-enabled DB/Storage |
| 9a8f5c2 | 2024-04-30 | - Added network policy to restrict MariaDB access from DSPO namespace |

## Deployment Notes

### Component Manifests Location
Kustomize deployment manifests are located in: `config/`
- Base manifests: `config/base/`
- RBAC: `config/rbac/`
- CRDs: `config/crd/`
- Component templates: `config/internal/`
- Overlays: `config/overlays/rhoai/` and `config/overlays/odh/`

### Version Support
- **DSP v2** (current): Uses Argo Workflows for pipeline execution
- **DSP v1** (deprecated): Uses Tekton Pipelines for pipeline execution

### Optional Components
The following components are optional and configured per DSPA instance:
- **MariaDB**: Set `spec.database.mariaDB.deploy: true` (mutually exclusive with externalDB)
- **Minio**: Set `spec.objectStorage.minio.deploy: true` (mutually exclusive with externalStorage)
- **ML Pipelines UI**: Set `spec.mlpipelineUI.deploy: true`
- **MLMD**: Set `spec.mlmd.deploy: true`

### Health Checks
- Database and object storage health checks can be disabled via `spec.database.disableHealthCheck` and `spec.objectStorage.disableHealthCheck`
- Useful for local development or when health check endpoints are not accessible

### Metrics Exposed
DSPO exposes the following custom metrics:
- `data_science_pipelines_application_ready`: Overall DSPA readiness (0/1)
- `data_science_pipelines_application_apiserver_ready`: API Server readiness (0/1)
- `data_science_pipelines_application_persistenceagent_ready`: Persistence Agent readiness (0/1)
- `data_science_pipelines_application_scheduledworkflow_ready`: Scheduled Workflow readiness (0/1)
