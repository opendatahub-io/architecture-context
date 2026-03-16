# Component: Data Science Pipelines Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/data-science-pipelines-operator
- **Version**: a30d30f
- **Branch**: rhoai-2.13
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Manages lifecycle of Data Science Pipelines deployments on OpenShift/Kubernetes clusters.

**Detailed**: The Data Science Pipelines Operator (DSPO) is a Kubernetes operator that deploys and manages namespace-scoped Data Science Pipelines (DSP) instances. Based on upstream Kubeflow Pipelines (KFP), it enables data scientists to create, track, and manage ML workflows for data preparation, model training, validation, and experimentation. The operator watches DataSciencePipelinesApplication custom resources and reconciles all required components including API servers, persistence agents, workflow controllers, databases, and object storage. It supports both DSP v1 (Tekton-based) and v2 (Argo Workflows-based) deployments with flexible configuration for development and production environments.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| DSPO Controller Manager | Operator Deployment | Reconciles DataSciencePipelinesApplication CRs and manages component lifecycle |
| API Server | Deployment | REST and gRPC API server for pipeline management and execution |
| Persistence Agent | Deployment | Watches workflows and persists execution metadata to database |
| Scheduled Workflow | Deployment | Manages scheduled and recurring pipeline runs |
| Workflow Controller | Deployment | Argo-specific component managing workflow orchestration (v2 only) |
| MariaDB | StatefulSet (optional) | Metadata database for pipeline and experiment tracking |
| Minio | Deployment (optional) | S3-compatible object storage for artifacts (development/testing) |
| ML Pipelines UI | Deployment (optional) | Web interface for pipeline visualization and management |
| ML Metadata (MLMD) gRPC | Deployment (optional) | gRPC server for ML metadata tracking |
| ML Metadata Envoy | Deployment (optional) | Envoy proxy providing authentication and routing for MLMD |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencepipelinesapplications.opendatahub.io | v1alpha1 | DataSciencePipelinesApplication | Namespaced | Defines configuration for DSP stack deployment including API server, database, object storage, and optional components |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /apis/v2beta1/* | GET/POST/DELETE | 8888/TCP | HTTP | None | OAuth (when route enabled) | DSP API v2 endpoints for pipeline management |
| /healthz | GET | 8081/TCP | HTTP | None | None | DSPO controller liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | DSPO controller readiness probe |
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint (controller) |
| /artifacts/{id} | GET | 8888/TCP | HTTP | None | OAuth | Artifact download with signed URLs |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| DSP API Server | 8887/TCP | gRPC | TLS (optional) | mTLS (optional) | gRPC interface for pipeline operations |
| ML Metadata gRPC | 8080/TCP | gRPC | TLS (optional) | mTLS (optional) | Metadata lineage and artifact tracking |
| ML Metadata Envoy | 9090/TCP | gRPC | TLS 1.2+ | OAuth proxy | Authenticated access to MLMD gRPC |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| OpenShift/Kubernetes | 4.11+ | Yes | Container orchestration platform |
| OpenShift Pipelines (Tekton) | 1.8+ | Conditional | Required for DSP v1 deployments |
| Argo Workflows | Latest | Conditional | Required for DSP v2 deployments |
| External Database (MariaDB/MySQL) | 10.3+ | Optional | Production metadata storage (alternative to embedded MariaDB) |
| External Object Storage (S3/compatible) | N/A | Optional | Production artifact storage (alternative to Minio) |
| cert-manager or OpenShift service CA | N/A | Yes | TLS certificate provisioning for services |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | UI Integration | Provides integrated UI for pipeline management |
| opendatahub-operator | CR Watch | Deploys DSPO when datasciencepipelines component enabled in DataScienceCluster |
| Elyra | Client SDK | Authoring tool for creating and submitting pipelines |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| ds-pipeline-{name} | ClusterIP | 8443/TCP | oauth | HTTPS | TLS 1.2+ | OAuth proxy | Internal |
| ds-pipeline-{name} | ClusterIP | 8888/TCP | http | HTTP | None | None | Internal |
| ds-pipeline-{name} | ClusterIP | 8887/TCP | 8887 | gRPC | TLS (optional) | mTLS (optional) | Internal |
| mariadb-{name} | ClusterIP | 3306/TCP | 3306 | MySQL | TLS (optional) | Password | Internal |
| minio-{name} | ClusterIP | 9000/TCP | 9000 | HTTP | None | Access Key/Secret | Internal |
| minio-{name} | ClusterIP | 80/TCP | 9000 | HTTP | None | Access Key/Secret | Internal |
| ds-pipeline-metadata-grpc-{name} | ClusterIP | 8080/TCP | 8080 | gRPC | TLS (optional) | None | Internal |
| ds-pipeline-md-{name} | ClusterIP | 9090/TCP | 9090 | gRPC | TLS (optional) | None | Internal |
| ds-pipeline-md-{name} | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | OAuth proxy | Internal |
| controller-manager-metrics-service | ClusterIP | 8443/TCP | https | HTTPS | TLS 1.2+ | Token review | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| ds-pipeline-{name} | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |
| ds-pipeline-ui-{name} | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |
| minio-{name} | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External (optional) |
| ds-pipeline-md-{name} | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External (optional) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| External S3 (AWS/compatible) | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Access Keys | Artifact storage and retrieval |
| External Database | 3306/TCP or 5432/TCP | MySQL/PostgreSQL | TLS 1.2+ (optional) | Username/Password | Metadata persistence |
| Container Registries | 443/TCP | HTTPS | TLS 1.2+ | Token/Basic Auth | Pull pipeline component images |
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Resource management and monitoring |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications | create, delete, get, list, patch, update, watch |
| manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications/status | get, patch, update |
| manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications/finalizers | update |
| manager-role | "" | deployments, services, configmaps, secrets, serviceaccounts, persistentvolumeclaims | create, delete, get, list, patch, update, watch |
| manager-role | apps | deployments | create, delete, get, list, patch, update, watch |
| manager-role | argoproj.io | workflows | * |
| manager-role | argoproj.io | workflowtaskresults | create, patch |
| manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| manager-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| manager-role | rbac.authorization.k8s.io | roles, rolebindings | create, delete, get, list, patch, update, watch |
| manager-role | rbac.authorization.k8s.io | clusterroles, clusterrolebindings | create, delete, get, list, update, watch |
| manager-role | monitoring.coreos.com | servicemonitors | create, delete, get, list, patch, update, watch |
| manager-role | authentication.k8s.io | tokenreviews | create |
| manager-role | authorization.k8s.io | subjectaccessreviews | create |
| manager-role | batch | jobs | * |
| manager-role | "" | pods, pods/exec, pods/log | * |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| leader-election-rolebinding | datasciencepipelinesapplications-controller | leader-election-role | controller-manager |
| manager-rolebinding | datasciencepipelinesapplications-controller | manager-role | controller-manager |
| ds-pipeline-{name} | {user-namespace} | ds-pipeline-{name} | ds-pipeline-{name} |
| ds-pipeline-user-access-{name} | {user-namespace} | ds-pipeline-user-access-{name} | default |
| pipeline-runner-{name} | {user-namespace} | pipeline-runner-{name} | pipeline-runner-{name} |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| ds-pipelines-proxy-tls-{name} | kubernetes.io/tls | TLS certificate for OAuth proxy | OpenShift service CA | No |
| ds-pipelines-envoy-proxy-tls-{name} | kubernetes.io/tls | TLS certificate for MLMD envoy proxy | OpenShift service CA | No |
| {db-secret-name} | Opaque | Database credentials (username, password) | User or DSPO | No |
| {storage-secret-name} | Opaque | Object storage credentials (access key, secret key) | User or DSPO | No |
| {name}-mariadb | Opaque | Auto-generated MariaDB credentials | DSPO | No |
| {name}-minio | Opaque | Auto-generated Minio credentials | DSPO | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /apis/v2beta1/* (route) | GET/POST/DELETE/PUT | OAuth Bearer Token (JWT) | OpenShift OAuth Proxy | RBAC on DSPA resource |
| /apis/v2beta1/* (service) | GET/POST/DELETE/PUT | None | None | Internal cluster access only |
| gRPC API | All | mTLS client certificates (optional) | gRPC server | Mutual TLS verification |
| ML Metadata Envoy | All | OAuth Bearer Token (JWT) | OAuth Proxy | RBAC on ServiceAccount |
| Kubernetes API | All | ServiceAccount Token | Kubernetes API | RBAC policies |
| MariaDB | All | Username/Password | Database server | MySQL authentication |
| Minio/S3 | All | Access Key/Secret Key | Object store server | S3 signature validation |

### Network Policies

| Policy Name | Pod Selector | Ingress From | Ingress Ports | Purpose |
|-------------|--------------|--------------|---------------|---------|
| ds-pipeline-metadata-grpc-{name} | app=ds-pipeline-metadata-grpc-{name} | pipelines.kubeflow.org/v2_component=true, component=data-science-pipelines | 8080/TCP | Restrict MLMD gRPC access to pipeline components only |

## Data Flows

### Flow 1: Pipeline Submission and Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Client | ds-pipeline-{name} (Route) | 443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token |
| 2 | OAuth Proxy | API Server Pod | 8888/TCP | HTTP | None | ServiceAccount Token |
| 3 | API Server | MariaDB | 3306/TCP | MySQL | TLS (optional) | Username/Password |
| 4 | API Server | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | Kubernetes API | Argo Workflow Controller | Internal | N/A | N/A | N/A |
| 6 | Workflow Controller | Pipeline Pods | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: Artifact Storage and Retrieval

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Pipeline Component Pod | Minio/S3 | 9000/TCP or 443/TCP | HTTP or HTTPS | TLS (S3), None (Minio) | Access Key/Secret |
| 2 | API Server | Minio/S3 | 9000/TCP or 443/TCP | HTTP or HTTPS | TLS (S3), None (Minio) | Access Key/Secret |
| 3 | User/Client | API Server /artifacts/* | 443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token |
| 4 | API Server | Returns signed URL | 443/TCP | HTTPS | TLS 1.2+ | Signed URL token |
| 5 | User/Client | Minio/S3 (direct) | 443/TCP | HTTPS | TLS 1.2+ | Signed URL |

### Flow 3: Metadata Tracking (MLMD)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Pipeline Component Pod | ds-pipeline-metadata-grpc-{name} | 8080/TCP | gRPC | TLS (optional) | None |
| 2 | MLMD gRPC Server | MariaDB | 3306/TCP | MySQL | TLS (optional) | Username/Password |
| 3 | External Client | ds-pipeline-md-{name} (Route) | 443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token |
| 4 | Envoy Proxy | MLMD gRPC Server | 8080/TCP | gRPC | None | None |

### Flow 4: Persistence Agent Workflow Sync

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Persistence Agent | Kubernetes API (watch) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Persistence Agent | MariaDB | 3306/TCP | MySQL | TLS (optional) | Username/Password |
| 3 | Persistence Agent | Minio/S3 | 9000/TCP or 443/TCP | HTTP or HTTPS | TLS (S3), None (Minio) | Access Key/Secret |

### Flow 5: Scheduled Workflow Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Scheduled Workflow Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Scheduled Workflow Controller | MariaDB | 3306/TCP | MySQL | TLS (optional) | Username/Password |
| 3 | Scheduled Workflow Controller | API Server | 8888/TCP | HTTP | None | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Resource CRUD, watches, status updates |
| MariaDB/MySQL | SQL | 3306/TCP | MySQL | TLS (optional) | Metadata persistence and queries |
| Minio/S3 | S3 API | 9000/TCP or 443/TCP | HTTP or HTTPS | TLS (S3), None (Minio) | Artifact storage and retrieval |
| Argo Workflows | CRD Watch | 6443/TCP | HTTPS | TLS 1.2+ | Workflow orchestration (v2 only) |
| OpenShift Pipelines (Tekton) | CRD Management | 6443/TCP | HTTPS | TLS 1.2+ | Pipeline execution (v1 only) |
| Prometheus | Metrics Scrape | 8080/TCP or 8443/TCP | HTTP or HTTPS | TLS (optional) | Monitoring and alerting |
| ODH Dashboard | REST API | 443/TCP | HTTPS | TLS 1.2+ | UI integration for pipeline management |
| OAuth Provider (OpenShift) | OAuth2 | 443/TCP | HTTPS | TLS 1.2+ | User authentication and authorization |

## Deployment Configuration

### Kustomize Structure

The operator uses Kustomize for deployment with manifests located in `config/`:

- **config/base**: Base operator deployment (manager, RBAC, service)
- **config/crd**: Custom Resource Definitions
- **config/rbac**: RBAC policies (roles, bindings, service accounts)
- **config/manager**: Operator deployment specification
- **config/internal**: Component templates deployed per DSPA instance
  - apiserver: API server deployment, service, routes, RBAC
  - mariadb: MariaDB statefulset, service, PVC, network policy
  - minio: Minio deployment, service, PVC, route
  - ml-metadata: MLMD gRPC and Envoy deployments, services, network policies
  - mlpipelines-ui: UI deployment, service, route
  - persistence-agent: Persistence agent deployment, RBAC
  - scheduled-workflow: Scheduled workflow deployment, RBAC
  - workflow-controller: Argo workflow controller (v2)
- **config/argo**: Argo Workflows installation manifests (v2)
- **config/samples**: Example DSPA custom resources

### Container Images

Built using **Dockerfile.konflux** with:
- Base: `registry.redhat.io/ubi8/go-toolset:1.21` (builder)
- Runtime: `registry.redhat.io/ubi8/ubi-minimal` (runtime)
- User: 65532 (non-root)
- Security: No privilege escalation, all capabilities dropped

## Monitoring

### Custom Metrics

| Metric Name | Type | Labels | Purpose |
|-------------|------|--------|---------|
| data_science_pipelines_application_apiserver_ready | Gauge | namespace, name | APIServer readiness status (1=Ready, 0=Not Ready) |
| data_science_pipelines_application_persistenceagent_ready | Gauge | namespace, name | PersistenceAgent readiness status |
| data_science_pipelines_application_scheduledworkflow_ready | Gauge | namespace, name | ScheduledWorkflow readiness status |
| data_science_pipelines_application_ready | Gauge | namespace, name | Overall DSPA readiness status |

### Health Endpoints

| Endpoint | Port | Purpose |
|----------|------|---------|
| /healthz | 8081/TCP | Operator liveness probe |
| /readyz | 8081/TCP | Operator readiness probe |
| /metrics | 8080/TCP | Prometheus metrics scraping |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| a30d30f | 2025-03-12 | - Update konflux references |
| 9778a8b | 2025-03-11 | - Update konflux references to d00d159 |
| b3aa8ab | 2025-03-11 | - Update konflux references |
| cb57ab9 | 2025-03-11 | - Update konflux references |
| d2c89b9 | 2025-03-11 | - Update konflux references |
| bb65a9f | 2025-03-10 | - Update konflux references to 493a872 |
| a791d24 | 2025-03-05 | - Update konflux references |
| 566ba95 | 2025-03-05 | - Update konflux references |
| 1df8164 | 2025-03-03 | - Update konflux references |
| 1e5a040 | 2025-03-02 | - Update konflux references to b9cb1e1 |

## Configuration

### Environment Variables (Operator)

| Variable | Default | Purpose |
|----------|---------|---------|
| IMAGES_APISERVER | (required) | DSP API Server container image |
| IMAGES_PERSISTENTAGENT | (required) | Persistence Agent container image |
| IMAGES_SCHEDULEDWORKFLOW | (required) | Scheduled Workflow container image |
| IMAGES_ARTIFACT | (required) | Artifact manager container image |
| IMAGES_OAUTHPROXY | (required) | OAuth proxy container image |
| IMAGES_MARIADB | (required) | MariaDB container image |
| IMAGES_MLMDENVOY | (required) | ML Metadata Envoy container image |
| IMAGES_MLMDGRPC | (required) | ML Metadata gRPC container image |
| V2_LAUNCHER_IMAGE | (required) | KFP v2 launcher image |
| V2_DRIVER_IMAGE | (required) | KFP v2 driver image |
| IMAGESV2_ARGO_WORKFLOWCONTROLLER | (required) | Argo workflow controller image (v2) |
| IMAGESV2_ARGO_ARGOEXEC | (required) | Argo executor image (v2) |
| ZAP_LOG_LEVEL | info | Operator log level (debug, info, error) |
| MAX_CONCURRENT_RECONCILES | 1 | Maximum concurrent DSPA reconciliations |
| DSPO_REQUEUE_TIME | 30s | Reconciliation requeue interval |

### DSPA Specification Fields

Key configuration options in DataSciencePipelinesApplication CR:
- `dspVersion`: "v1" (Tekton) or "v2" (Argo)
- `podToPodTLS`: Enable mTLS between pods (default: true, v2 only)
- `apiServer.enableRoute`: Create OpenShift Route (default: true)
- `apiServer.enableSamplePipeline`: Deploy sample pipelines (default: false)
- `database.mariaDB.deploy`: Deploy MariaDB (default: true)
- `database.externalDB`: Configure external database
- `objectStorage.minio.deploy`: Deploy Minio (default: false, dev only)
- `objectStorage.externalStorage`: Configure external S3
- `mlpipelineUI.deploy`: Deploy ML Pipelines UI (default: false)
- `mlmd.deploy`: Deploy ML Metadata tracking (default: false)

## Notes

- **Development vs Production**: Minio and embedded MariaDB are for development/testing only. Production deployments should use external S3-compatible storage and managed databases.
- **Version Support**: DSP v1 uses Tekton pipelines; DSP v2 uses Argo Workflows. Version determined by `dspVersion` field in DSPA CR.
- **Namespace Scope**: Each DSPA instance is namespace-scoped, allowing multiple independent DSP deployments per cluster.
- **OAuth Integration**: Routes use OpenShift OAuth proxy for authentication, providing SSO integration with cluster identity providers.
- **CA Bundle Support**: Custom CA certificates can be injected for TLS connections to external databases and object storage.
- **Health Checks**: Can be disabled via `disableHealthCheck` for development/testing when external services are unreachable.
- **Artifact Expiry**: Artifact download URLs expire after 60 seconds by default (configurable via `artifactSignedURLExpirySeconds`).
- **Pipeline Root**: Object storage path for artifacts configurable via `objectStorage.basePath`.
