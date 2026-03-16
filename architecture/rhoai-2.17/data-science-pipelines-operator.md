# Component: Data Science Pipelines Operator (DSPO)

## Metadata
- **Repository**: https://github.com/red-hat-data-services/data-science-pipelines-operator.git
- **Version**: 15f468f (rhoai-2.17 branch)
- **Distribution**: RHOAI
- **Languages**: Go 1.21
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Manages lifecycle of Data Science Pipelines instances through custom resources on OpenShift/Kubernetes clusters.

**Detailed**: The Data Science Pipelines Operator (DSPO) is an OpenShift Operator that deploys and manages single namespace-scoped Data Science Pipeline stacks onto individual OpenShift namespaces. Based on upstream Kubeflow Pipelines (KFP), DSPO enables data scientists to create, track, and manage ML workflows for data preparation, model training, and validation. The operator reconciles DataSciencePipelinesApplication (DSPA) custom resources, deploying and configuring all necessary components including API servers, persistence agents, workflow controllers, and optional components like databases, object storage, and ML metadata tracking. DSPO integrates with Argo Workflows for pipeline execution orchestration and provides OAuth-secured routes for external access.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| DSPO Controller Manager | Operator | Reconciles DSPA custom resources and manages lifecycle of pipeline components |
| DS Pipelines API Server | Deployment | RESTful/gRPC API server for pipeline management and execution |
| Persistence Agent | Deployment | Syncs workflow state from Argo to database for persistence |
| Scheduled Workflow Controller | Deployment | Manages scheduled/recurring pipeline runs |
| Workflow Controller | Deployment | Namespace-scoped Argo Workflow controller for pipeline execution orchestration |
| MariaDB (Optional) | StatefulSet | MySQL-compatible database for pipeline metadata storage |
| Minio (Optional) | Deployment | S3-compatible object storage for pipeline artifacts |
| ML Metadata gRPC (Optional) | Deployment | gRPC service for ML metadata artifact lineage tracking |
| ML Metadata Envoy (Optional) | Deployment | Envoy proxy for ML metadata service with OAuth authentication |
| ML Pipelines UI (Optional) | Deployment | Web interface for pipeline visualization and management |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencepipelinesapplications.opendatahub.io | v1 | DataSciencePipelinesApplication | Namespaced | Defines a complete Data Science Pipelines stack configuration including API server, database, storage, and optional components |
| argoproj.io | v1alpha1 | Workflow | Namespaced | Argo Workflow for executing individual pipeline runs |
| argoproj.io | v1alpha1 | WorkflowTemplate | Namespaced | Reusable workflow templates for pipelines |
| argoproj.io | v1alpha1 | CronWorkflow | Namespaced | Scheduled/recurring workflow executions |
| kubeflow.org | v1beta1 | ScheduledWorkflow | Namespaced | KFP-specific scheduled workflow management |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /apis/v2beta1/* | GET, POST, DELETE | 8888/TCP | HTTP | None (internal) | None | DS Pipelines API v2beta1 - internal access |
| /apis/v1beta1/* | GET, POST, DELETE | 8888/TCP | HTTP | None (internal) | None | DS Pipelines API v1beta1 - internal access |
| /oauth/* | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth2 Proxy | External OAuth authentication endpoint |
| / | GET, POST | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token (OAuth) | DS Pipelines API - external access via OAuth proxy |
| /metrics | GET | 8080/TCP | HTTP | None | None | Operator Prometheus metrics endpoint |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness probe |
| /apis/v2beta1/artifacts/{id} | GET | 8888/TCP | HTTP | None (internal) | None | Artifact download with signed URLs |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ml-pipeline | 8887/TCP | gRPC | mTLS (optional) | Service Account Token | DS Pipelines gRPC API for pipeline execution |
| metadata-grpc | 8080/TCP | gRPC | mTLS (pod-to-pod) | Service Account Token | ML Metadata gRPC service for artifact lineage |
| metadata-envoy | 9090/TCP | gRPC/HTTP2 | TLS 1.2+ | OAuth2 Proxy | ML Metadata Envoy proxy for external access |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.27+ | Yes | Container orchestration platform |
| OpenShift | 4.11+ | No | Preferred platform with enhanced features (Routes, OAuth) |
| OpenShift Pipelines (Tekton) | 1.8+ | No (DSPv1 only) | Required for DSPv1; not needed for DSPv2 |
| Argo Workflows | 3.x | Yes (embedded) | Workflow execution engine (namespace-scoped deployment) |
| MariaDB | 10.3+ | No | Default metadata database (can use external MySQL-compatible DB) |
| Minio | RELEASE.2019-08-14T20-37-41Z | No | Default object storage (can use external S3-compatible storage) |
| S3-Compatible Storage | Any | Yes | Object storage for pipeline artifacts and metadata |
| MySQL-Compatible Database | 5.7+ | Yes | Database for pipeline metadata and run history |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | Route/API | Provides UI integration for pipeline management and visualization |
| OpenShift OAuth | OAuth2 Proxy | Authentication and authorization for external API access |
| OpenShift Service CA | Certificate | Generates service-serving certificates for internal TLS |
| User Workload Monitoring | ServiceMonitor | Prometheus metrics collection for operator and pipeline components |
| ODH Monitoring Stack | NetworkPolicy | Authorized to scrape metrics from API server |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| ds-pipeline-{name} | ClusterIP | 8443/TCP | oauth | HTTPS | TLS 1.2+ | OAuth2 Proxy | Internal |
| ds-pipeline-{name} | ClusterIP | 8888/TCP | http | HTTP | None | None | Internal |
| ds-pipeline-{name} | ClusterIP | 8887/TCP | 8887 | gRPC | mTLS (optional) | SA Token | Internal |
| mariadb-{name} | ClusterIP | 3306/TCP | 3306 | MySQL | TLS (pod-to-pod) | Password | Internal |
| minio-{name} | ClusterIP | 9000/TCP | 9000 | HTTP | None | Access/Secret Key | Internal |
| ds-pipeline-metadata-grpc-{name} | ClusterIP | 8080/TCP | 8080 | gRPC | mTLS (pod-to-pod) | SA Token | Internal |
| ds-pipeline-metadata-envoy-{name} | ClusterIP | 9090/TCP | 9090 | gRPC/HTTP2 | TLS 1.2+ | OAuth2 Proxy | Internal |
| ds-pipeline-ui-{name} | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | OAuth2 Proxy | Internal |
| workflow-controller-metrics-{name} | ClusterIP | 9090/TCP | 9090 | HTTP | None | None | Internal |
| controller-manager service | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| ds-pipeline-{name} | OpenShift Route | cluster-specific | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |
| ds-pipeline-ui-{name} | OpenShift Route | cluster-specific | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |
| ds-pipeline-metadata-envoy-{name} | OpenShift Route | cluster-specific | 9090/TCP | HTTPS | TLS 1.2+ | Reencrypt | External (optional) |
| minio-{name} | OpenShift Route | cluster-specific | 9000/TCP | HTTP | None | Edge | External (optional) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| External S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM / Access Keys | Pipeline artifact storage and retrieval |
| External Database | 3306/TCP | MySQL | TLS 1.2+ | Username/Password | Pipeline metadata persistence |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secrets | Pull pipeline component images |
| OpenShift API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token | Workflow execution and resource management |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications | get, list, watch, create, update, patch, delete |
| manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications/status | get, update, patch |
| manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications/finalizers | update |
| manager-role | apps, "", extensions | deployments, replicasets | * |
| manager-role | "" | pods, pods/exec, pods/log, services | * |
| manager-role | "" | configmaps, secrets, serviceaccounts, persistentvolumeclaims, persistentvolumes | create, delete, get, list, patch, update, watch |
| manager-role | rbac.authorization.k8s.io | roles, rolebindings, clusterroles, clusterrolebindings | create, delete, get, list, update, watch, patch |
| manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| manager-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| manager-role | argoproj.io | workflows, workflowartifactgctasks, workflowtaskresults | * |
| manager-role | kubeflow.org | * | * |
| manager-role | batch | jobs | * |
| manager-role | monitoring.coreos.com | servicemonitors | create, delete, get, list, patch, update, watch |
| manager-role | ray.io | rayclusters, rayjobs, rayservices | create, delete, get, list, patch |
| manager-role | machinelearning.seldon.io | seldondeployments | * |
| manager-role | workload.codeflare.dev | appwrappers | * |
| ds-pipeline-user-access-{name} | argoproj.io | workflows, workflowtemplates | create, get, list, watch, update, patch, delete |
| ds-pipeline-{name} | authorization.k8s.io | subjectaccessreviews | create |
| pipeline-runner-{name} | "" | secrets, configmaps | get, list, watch |
| pipeline-runner-{name} | argoproj.io | workflows | get, list, watch, update, patch |
| argo-aggregate-to-admin | argoproj.io | workflows, workflowtemplates, cronworkflows, clusterworkflowtemplates | create, delete, deletecollection, get, list, patch, update, watch |
| argo-aggregate-to-edit | argoproj.io | workflows, workflowtemplates, cronworkflows | create, delete, deletecollection, get, list, patch, update, watch |
| argo-aggregate-to-view | argoproj.io | workflows, workflowtemplates, cronworkflows | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | Cluster-wide | manager-role (ClusterRole) | controller-manager |
| leader-election-rolebinding | operator-namespace | leader-election-role | controller-manager |
| ds-pipeline-{name} | DSPA namespace | ds-pipeline-{name} | ds-pipeline-{name} |
| pipeline-runner-{name} | DSPA namespace | pipeline-runner-{name} | pipeline-runner-{name} |
| ds-pipeline-user-access-{name} | DSPA namespace | ds-pipeline-user-access-{name} | ds-pipeline-{name} |
| argo-binding | DSPA namespace | argo-role | argo |
| ds-pipeline-persistenceagent-{name} | DSPA namespace | ds-pipeline-persistenceagent-{name} | ds-pipeline-persistenceagent-{name} |
| ds-pipeline-scheduledworkflow-{name} | DSPA namespace | ds-pipeline-scheduledworkflow-{name} | ds-pipeline-scheduledworkflow-{name} |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| ds-pipeline-db-{name} | Opaque | MariaDB credentials (username, password) | DSPO or User | No |
| ds-pipeline-s3-{name} | Opaque | S3 storage credentials (accesskey, secretkey) | DSPO or User | No |
| ds-pipelines-proxy-tls-{name} | kubernetes.io/tls | OAuth proxy serving certificate | OpenShift Service CA | Yes |
| ds-pipeline-metadata-grpc-tls-{name} | Opaque | ML Metadata gRPC mTLS certificates | DSPO | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /oauth/* (8443) | GET, POST | OAuth2 Proxy | OpenShift OAuth | User authentication via OpenShift identity providers |
| / (8443) | ALL | Bearer Token (OAuth) | OAuth2 Proxy Sidecar | Validates OAuth token before proxying to API server |
| /apis/* (8888) | GET, POST, DELETE | None (internal) | NetworkPolicy | Only authorized pods can access internal HTTP port |
| gRPC (8887) | ALL | Service Account Token | API Server | Validates Kubernetes SA tokens for gRPC calls |
| ML Metadata gRPC (8080) | ALL | Service Account Token | NetworkPolicy + gRPC | Only pipeline pods and components can access |
| Metrics (8080) | GET | None | NetworkPolicy | Only Prometheus namespaces can scrape |

### Network Policies

| Policy Name | Selector | Ingress Rules | Purpose |
|-------------|----------|---------------|---------|
| ds-pipelines-{name} | app=ds-pipeline-{name} | Port 8443 (all sources), Ports 8888/8887 (authorized pods only) | Restricts API server access to OAuth proxy and internal components |
| mariadb-{name} | app=mariadb-{name} | Port 3306 from DSPO, API server, MLMD gRPC pods | Restricts database access to authorized pipeline components |
| ds-pipeline-metadata-grpc-{name} | app=ds-pipeline-metadata-grpc-{name} | Port 8080 from pipeline v2 components | Restricts MLMD gRPC access to pipeline execution pods |

## Data Flows

### Flow 1: Pipeline Submission via UI

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | ds-pipeline Route | 443/TCP | HTTPS | TLS 1.3 | OAuth2 (redirect) |
| 2 | OpenShift OAuth | User Browser | 443/TCP | HTTPS | TLS 1.3 | User credentials |
| 3 | User Browser | ds-pipeline Route | 443/TCP | HTTPS | TLS 1.3 | Bearer Token (OAuth) |
| 4 | Route | OAuth2 Proxy Sidecar | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token validation |
| 5 | OAuth2 Proxy | API Server Container | 8888/TCP | HTTP | None | Trusted sidecar |
| 6 | API Server | MariaDB Service | 3306/TCP | MySQL | TLS (pod-to-pod) | Username/Password |
| 7 | API Server | Workflow Controller | 8080/TCP | HTTP | None | Service Account Token |

### Flow 2: Pipeline Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Workflow Controller | OpenShift API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 2 | Pipeline Pod | API Server | 8887/TCP | gRPC | mTLS (optional) | Service Account Token |
| 3 | Pipeline Pod | MLMD gRPC | 8080/TCP | gRPC | mTLS (pod-to-pod) | Service Account Token |
| 4 | Pipeline Pod | Minio/S3 | 9000/TCP or 443/TCP | HTTP/HTTPS | TLS (external) | Access/Secret Keys |
| 5 | Persistence Agent | API Server | 8887/TCP | gRPC | mTLS (optional) | Service Account Token |
| 6 | Persistence Agent | MariaDB | 3306/TCP | MySQL | TLS (pod-to-pod) | Username/Password |

### Flow 3: Artifact Storage

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Pipeline Executor | Minio/S3 Service | 9000/TCP or 443/TCP | HTTP/HTTPS | TLS (if external) | Access/Secret Keys |
| 2 | Pipeline Executor | MLMD gRPC | 8080/TCP | gRPC | mTLS (pod-to-pod) | Service Account Token |
| 3 | MLMD gRPC | MariaDB | 3306/TCP | MySQL | TLS (pod-to-pod) | Username/Password |

### Flow 4: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | Operator Service | 8080/TCP | HTTP | None | None (NetworkPolicy) |
| 2 | Prometheus | Workflow Controller | 9090/TCP | HTTP | None | None (NetworkPolicy) |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| OpenShift OAuth | OAuth2 Redirect | 443/TCP | HTTPS | TLS 1.2+ | User authentication for external API access |
| OpenShift API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Resource creation and management for workflows |
| ODH Dashboard | HTTP/Route | 443/TCP | HTTPS | TLS 1.2+ | UI integration for pipeline visualization |
| Prometheus (User Workload) | Metrics Scraping | 8080/TCP, 9090/TCP | HTTP | None | Operator and component metrics collection |
| Argo Workflows | CRD/API | In-process | N/A | N/A | Workflow execution orchestration engine |
| Kubeflow Pipelines SDK | gRPC/HTTP | 8887/TCP, 8888/TCP | gRPC/HTTP | mTLS/TLS via OAuth | Pipeline submission and management |
| External S3 Storage | S3 API | 443/TCP | HTTPS | TLS 1.2+ | Artifact persistence and retrieval |
| External MySQL Database | MySQL Protocol | 3306/TCP | MySQL | TLS 1.2+ | Metadata and run history persistence |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 15f468f | 2026-03 | - chore(deps): update konflux references (#290) |
| db3fcd2 | 2026-03 | - chore(deps): update konflux references (#284) |
| d535b3f | 2026-03 | - chore(deps): update konflux references to b9cb1e1 (#277) |
| 98add63 | 2026-02 | - chore(deps): update konflux references to 944e769 (#271) |
| 424df3b | 2026-02 | - chore(deps): update konflux references (#266) |
| 62f2669 | 2026-02 | - chore(deps): update konflux references (#265) |
| 8b6fc46 | 2026-02 | - chore(deps): update konflux references to 8b6f22f (#258) |
| b73f080 | 2026-02 | - chore(deps): update konflux references to 8b6f22f (#256) |
| cccc38a | 2026-02 | - chore(deps): update konflux references to 8b6f22f (#255) |
| 4f1e68b | 2026-01 | - chore(deps): update konflux references (#249) |
| 9affb10 | 2026-01 | - chore(deps): update registry.redhat.io/ubi8/ubi-minimal docker digest to c38cc77 (#244) |
| 79eb544 | 2026-01 | - chore(deps): update konflux references to 5bc6129 (#236) |
| af562e9 | 2025-12 | - Update Konflux references to b78123a (#228) |
| 596d379 | 2025-12 | - Update Konflux references to b78123a (#227) |
| 660d265 | 2025-12 | - Update Konflux references |
| 9091b3e | 2025-12 | - Update Konflux references to 5a78c42 |
| 33c97ae | 2025-11 | - Update Konflux references |
| 4c8a0fe | 2025-11 | - Merge pull request #206 (CVE-2024-45339 fix) |
| 262ac15 | 2025-11 | - Update Konflux references to e603b3d |
| f6460c1 | 2025-11 | - CVE Resolution: update glog to 1.2.4 resolves CVE-2024-45339 |

## Deployment Configuration

### Kustomize Structure

The operator uses Kustomize for deployment manifests located in the `config/` directory:

- **Base**: `config/base/` - Core operator deployment (controller-manager)
- **CRDs**: `config/crd/bases/` - DataSciencePipelinesApplication CRD definition
- **RBAC**: `config/rbac/` - ClusterRole, Role, ServiceAccount, and Bindings
- **Manager**: `config/manager/` - Operator deployment and service
- **Argo**: `config/argo/` - Argo Workflows CRDs and RBAC for namespace-scoped deployment
- **Overlays**:
  - `config/overlays/rhoai/` - RHOAI-specific configurations
  - `config/overlays/odh/` - ODH-specific configurations
- **Internal Templates**: `config/internal/` - Go templates for DSPA component manifests

### Container Images

Built using Konflux CI/CD pipeline with `Dockerfile.konflux`:

- **Base Image**: registry.redhat.io/ubi8/ubi-minimal
- **Build Image**: registry.redhat.io/ubi8/go-toolset:1.21
- **User**: Non-root (UID 65532)
- **Security**: Capabilities dropped, non-root, read-only root filesystem

### Component Images (Configured via ConfigMap)

- **API Server**: Data Science Pipelines API server (v2)
- **Persistence Agent**: Syncs workflow state to database
- **Scheduled Workflow**: Manages scheduled pipeline runs
- **Argo Launcher/Driver**: Pipeline execution containers
- **MLMD Envoy**: Envoy proxy for ML Metadata
- **MLMD gRPC**: ML Metadata gRPC server
- **MariaDB**: MariaDB 10.3
- **OAuth Proxy**: OpenShift OAuth proxy

## Operational Notes

### High Availability
- Operator: Single replica with leader election support
- DSPA Components: Single replica per component (MariaDB uses PVC for persistence)
- Database: Uses PersistentVolumeClaim for data durability

### Resource Requirements
- **Operator**: 200m CPU / 400Mi memory (requests), 1 CPU / 4Gi memory (limits)
- **API Server**: Configurable per DSPA
- **MariaDB**: Configurable per DSPA (default 10Gi PVC)
- **Minio**: Configurable per DSPA (default 10Gi PVC)

### Monitoring
- Prometheus ServiceMonitor for operator metrics at `/metrics`
- Custom metrics for DSPA component readiness
- Workflow Controller metrics endpoint

### Pod-to-Pod TLS
- Configurable via `spec.podToPodTLS` (default: true)
- Enables mTLS between DSPA components (API Server, MLMD, MariaDB)
- Uses OpenShift Service CA for certificate generation
