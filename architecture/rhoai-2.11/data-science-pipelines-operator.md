# Component: Data Science Pipelines Operator (DSPO)

## Metadata
- **Repository**: https://github.com/red-hat-data-services/data-science-pipelines-operator.git
- **Version**: 8d084e4 (rhoai-2.11 branch)
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes operator that deploys and manages Data Science Pipelines (DSP) stacks for ML workflow orchestration in individual namespaces.

**Detailed**: The Data Science Pipelines Operator (DSPO) is an OpenShift Operator that deploys single namespace-scoped Data Science Pipeline stacks based on Kubeflow Pipelines. It enables data scientists to create, track, and execute ML workflows for data preparation, model training, validation, and experimentation. The operator manages two versions: DSP v1 (Tekton-based) and DSP v2 (Argo Workflows-based). When users create a DataSciencePipelinesApplication custom resource, DSPO automatically provisions the required infrastructure including API servers, persistence layers, schedulers, and optional components like databases, object storage, UI, and ML metadata tracking. The operator handles the full lifecycle management of these components, including configuration, secret management, TLS certificate provisioning, and health monitoring.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| DSPO Controller Manager | Operator Controller | Reconciles DataSciencePipelinesApplication CRs and deploys DSP stack components |
| API Server | REST/gRPC Service | Kubeflow Pipelines API server for pipeline/run management |
| Persistence Agent | Service | Syncs workflow state to database for persistence |
| Scheduled Workflow Controller | Service | Manages scheduled/recurring pipeline executions |
| Workflow Controller | Service | Argo Workflows controller for DSP v2 pipeline execution |
| MariaDB (Optional) | Database | MySQL-compatible database for pipeline metadata storage |
| Minio (Optional) | Object Storage | S3-compatible storage for pipeline artifacts |
| ML Pipelines UI (Optional) | Web UI | Upstream KFP UI for pipeline visualization and management |
| ML Metadata (MLMD) (Optional) | Metadata Service | ML artifact lineage and metadata tracking (Envoy proxy + gRPC server) |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencepipelinesapplications.opendatahub.io | v1alpha1 | DataSciencePipelinesApplication | Namespaced | Defines DSP stack deployment configuration including API server, database, object storage, and optional components |
| argoproj.io | v1alpha1 | Workflow | Namespaced | Argo workflow definitions for DSP v2 pipeline execution |
| argoproj.io | v1alpha1 | WorkflowTemplate | Namespaced | Reusable workflow templates for Argo-based pipelines |
| argoproj.io | v1alpha1 | CronWorkflow | Namespaced | Scheduled/recurring Argo workflows |
| argoproj.io | v1alpha1 | ClusterWorkflowTemplate | Cluster | Cluster-scoped reusable workflow templates |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /apis/v1beta1/* | GET, POST, DELETE | 8888/TCP | HTTP | TLS 1.2+ (via Route) | OAuth Proxy | KFP API for pipelines, runs, experiments management |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator manager health check |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator manager readiness check |
| /metrics | GET | 8080/TCP | HTTP | None | None | Operator Prometheus metrics |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ml-pipeline | 8887/TCP | gRPC | TLS 1.2+ | mTLS | KFP pipeline execution and artifact tracking |
| metadata-grpc | 9090/TCP | gRPC | TLS 1.2+ | mTLS | ML Metadata artifact lineage queries |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| OpenShift | 4.13+ | Yes | Kubernetes platform with Routes, ServiceMonitors |
| Argo Workflows | 3.3.10 | Yes (DSP v2) | Workflow execution engine for v2 pipelines |
| OpenShift Pipelines (Tekton) | 1.8+ | Yes (DSP v1) | Workflow execution engine for v1 pipelines |
| MariaDB | 10.3 | No | MySQL-compatible database (can use external DB) |
| Minio | RELEASE.2019-08-14T20-37-41Z | No | S3-compatible object storage (can use external S3) |
| Kubeflow Pipelines | 2.0.5 (v2), 1.5.1-tekton (v1) | Yes | Upstream KFP components and SDK |
| ML Metadata | 1.14.0 | No (v1), Yes (v2) | Artifact and lineage metadata tracking |
| Envoy Proxy | 1.22.11 | No | Reverse proxy for ML Metadata gRPC service |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| opendatahub-operator | CRD | Deployed via DataScienceCluster CR's datasciencepipelines component |
| odh-dashboard | Web UI | Integration point for pipeline UI access and project management |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| ds-pipeline-{name} | ClusterIP | 8888/TCP | 8888 | HTTP | None (internal) | OAuth (via proxy) | Internal |
| ds-pipeline-{name} | ClusterIP | 8887/TCP | 8887 | gRPC | TLS 1.2+ | mTLS | Internal |
| ds-pipeline-{name} | ClusterIP | 8443/TCP | oauth | HTTPS | TLS 1.2+ | OAuth Proxy | Internal |
| mariadb-{name} | ClusterIP | 3306/TCP | 3306 | MySQL | TLS 1.2+ (optional) | Password | Internal |
| minio-{name} | ClusterIP | 9000/TCP | 9000 | HTTP | TLS 1.2+ (optional) | Access Key/Secret | Internal |
| minio-{name} | ClusterIP | 80/TCP | 9000 | HTTP | TLS 1.2+ (optional) | Access Key/Secret | Internal |
| ds-pipeline-ui-{name} | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | OAuth Proxy | Internal |
| ds-pipeline-md-{name} | ClusterIP | 9090/TCP | 9090 | gRPC | TLS 1.2+ | mTLS | Internal |
| ds-pipeline-md-{name} | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | OAuth Proxy | Internal |
| workflow-controller (metrics) | ClusterIP | 9090/TCP | 9090 | HTTP | None | None | Internal |
| controller-manager (metrics) | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| ds-pipeline-{name} | OpenShift Route | Auto-generated | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |
| ds-pipeline-ui-{name} | OpenShift Route | Auto-generated | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |
| ds-pipeline-md-{name} | OpenShift Route | Auto-generated | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| External S3 (AWS/Compatible) | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Access Keys | Pipeline artifact storage |
| External MySQL/MariaDB | 3306/TCP | MySQL | TLS 1.2+ (optional) | Password | Pipeline metadata storage |
| Container Registries | 443/TCP | HTTPS | TLS 1.2+ | Token | Pull pipeline component images |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications | create, delete, get, list, patch, update, watch |
| manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications/status | get, patch, update |
| manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications/finalizers | update |
| manager-role | apps | deployments | create, delete, get, list, patch, update, watch |
| manager-role | "" | services, configmaps, secrets, serviceaccounts, persistentvolumeclaims | create, delete, get, list, patch, update, watch |
| manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| manager-role | argoproj.io | workflows | * |
| manager-role | batch | jobs | * |
| manager-role | monitoring.coreos.com | servicemonitors | create, delete, get, list, patch, update, watch |
| manager-role | rbac.authorization.k8s.io | roles, rolebindings | create, delete, get, list, patch, update, watch |
| manager-role | authentication.k8s.io | tokenreviews | create |
| manager-role | authorization.k8s.io | subjectaccessreviews | create |
| argo-cluster-role | argoproj.io | workflows, workflowtemplates, cronworkflows | * |
| argo-cluster-role | "" | pods, pods/log, configmaps | get, list, watch |
| argo-cluster-role | "" | pods, pods/exec | create, delete, patch |
| pipeline-runner-{name} | route.openshift.io | routes | get, list, watch |
| pipeline-runner-{name} | "" | pods, services | get, list, create, delete, patch |
| pipeline-runner-{name} | argoproj.io | workflows | get, list, watch, create, patch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | {operator-namespace} | manager-role | controller-manager |
| argo-binding | {dspa-namespace} | argo-cluster-role | argo |
| ds-pipeline-{name} | {dspa-namespace} | ds-pipeline-role | ds-pipeline-{name} |
| pipeline-runner-{name} | {dspa-namespace} | pipeline-runner-role | pipeline-runner-{name} |
| ds-pipeline-metadata-writer-{name} | {dspa-namespace} | metadata-writer-role | ds-pipeline-metadata-writer-{name} |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| ds-pipelines-proxy-tls-{name} | kubernetes.io/tls | API Server OAuth proxy TLS cert | service.beta.openshift.io/serving-cert | Yes |
| ds-pipelines-ui-proxy-tls-{name} | kubernetes.io/tls | UI OAuth proxy TLS cert | service.beta.openshift.io/serving-cert | Yes |
| ds-pipelines-envoy-proxy-tls-{name} | kubernetes.io/tls | MLMD Envoy OAuth proxy TLS cert | service.beta.openshift.io/serving-cert | Yes |
| ds-pipeline-db-{name} | Opaque | MariaDB password | User/Operator | No |
| ds-pipeline-s3-{name} | Opaque | Object storage credentials (accesskey, secretkey) | User/Operator | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /apis/v1beta1/* | GET, POST, DELETE, PATCH | OAuth Bearer Token | OAuth Proxy sidecar | OpenShift RBAC |
| ds-pipeline-ui-{name}:8443 | GET | OAuth Bearer Token | OAuth Proxy sidecar | OpenShift RBAC |
| ds-pipeline-md-{name}:8443 | GET, POST | OAuth Bearer Token | OAuth Proxy sidecar | OpenShift RBAC |
| mariadb:3306 | * | Username/Password | MariaDB Server | Database ACL |
| minio:9000 | GET, PUT, DELETE | Access Key ID/Secret | Minio Server | S3 IAM Policy |
| External S3 | GET, PUT, DELETE | AWS IAM credentials | AWS | S3 Bucket Policy |

## Data Flows

### Flow 1: Pipeline Submission and Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/SDK | ds-pipeline-{name} (Route) | 443/TCP | HTTPS | TLS 1.3 | Bearer Token (OAuth) |
| 2 | OAuth Proxy | ds-pipeline-{name} (API Server) | 8888/TCP | HTTP | None | None (internal) |
| 3 | API Server | MariaDB | 3306/TCP | MySQL | TLS 1.2+ (optional) | Password |
| 4 | API Server | Workflow Controller | 8887/TCP | gRPC | TLS 1.2+ | mTLS |
| 5 | Workflow Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |
| 6 | Pipeline Pod | Minio/S3 | 9000/TCP or 443/TCP | HTTP/HTTPS | TLS 1.2+ (S3) | Access Key/Secret |
| 7 | Persistence Agent | MariaDB | 3306/TCP | MySQL | TLS 1.2+ (optional) | Password |

### Flow 2: Artifact Metadata Tracking (MLMD)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Pipeline Pod | ds-pipeline-md-{name} (Envoy) | 9090/TCP | gRPC | TLS 1.2+ | mTLS |
| 2 | Envoy Proxy | metadata-grpc | 8080/TCP | gRPC | None (internal) | None |
| 3 | metadata-grpc | MariaDB | 3306/TCP | MySQL | TLS 1.2+ (optional) | Password |

### Flow 3: DSPA Custom Resource Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | Bearer Token |
| 2 | Kubernetes API | DSPO Controller Manager | N/A | Watch | N/A | ServiceAccount Token |
| 3 | DSPO Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.3 | Resource management and watch events |
| Argo Workflow Controller | gRPC/Controller | 8887/TCP | gRPC | TLS 1.2+ | Workflow execution for DSP v2 |
| OpenShift Pipelines (Tekton) | CRD/Controller | 6443/TCP | HTTPS | TLS 1.3 | Workflow execution for DSP v1 |
| Prometheus | HTTP Metrics | 8080/TCP | HTTP | None | Operator and component metrics scraping |
| Service Mesh (Istio) | Envoy Proxy | Various | HTTP/gRPC | mTLS | Optional service mesh integration |
| ODH Dashboard | Web UI | 443/TCP | HTTPS | TLS 1.2+ | Pipeline UI access and project integration |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 2.3 | 2024-06-14 | - Generated params for DSP 2.3<br>- Updated compatibility documentation for 2.3<br>- Updated Go toolset to 1.21<br>- Updated precommit image and toolchain |
| 2024-06 | 2024-06-07 | - Disabled GKE metadata in KFP UI<br>- Added DSPO CI tests against custom pip server behind self-signed cert |
| 2024-05 | 2024-05-27 | - Fixed DSPA status update on reconciliation (RHOAIENG-6278)<br>- Improved envoy route reconciliation<br>- Added option to enable/disable envoy route<br>- Added routes permissions to pipeline runner |
| 2024-05 | 2024-05-21 | - Updated metadata envoy service name and host in mlpipelines-ui deployment<br>- Updated functional tests with new metadata envoy host |
| 2024-05 | 2024-05-20 | - Updated ubi8 image (RHOAIENG-7423) |

## Deployment Configuration

**Manifests Location**: `config/overlays/rhoai/`

The operator uses Kustomize for deployment with the following structure:
- **Base**: `config/base/` - Core operator deployment
- **RHOAI Overlay**: `config/overlays/rhoai/` - RHOAI-specific configurations
  - `dspo/` - Operator deployment customization
  - `argo/` - Argo Workflows v2 components
- **CRDs**: `config/crd/bases/` - DataSciencePipelinesApplication CRD
- **RBAC**: `config/rbac/` - ClusterRole, RoleBindings, ServiceAccounts
- **Internal Templates**: `config/internal/` - Go templates for deployed DSPA components

**Key Configuration**:
- Operator is deployed via ODH's DataScienceCluster CR with `datasciencepipelines.managementState: Managed`
- Each DSPA instance is namespace-scoped and creates isolated DSP stack
- Supports both v1 (Tekton) and v2 (Argo) pipeline backends via `spec.dspVersion`
- Optional components (MariaDB, Minio, UI, MLMD) configured per DSPA CR

## Component Health Monitoring

The operator exposes custom metrics for monitoring DSPA health:
- `data_science_pipelines_application_apiserver_ready` - API Server readiness (1=Ready, 0=Not Ready)
- `data_science_pipelines_application_persistenceagent_ready` - Persistence Agent readiness
- `data_science_pipelines_application_scheduledworkflow_ready` - Scheduled Workflow readiness
- `data_science_pipelines_application_ready` - Overall DSPA readiness

These metrics are exposed on port 8080/TCP and can be scraped by Prometheus via ServiceMonitor.
