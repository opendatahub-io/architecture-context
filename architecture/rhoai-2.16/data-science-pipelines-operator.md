# Component: Data Science Pipelines Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/data-science-pipelines-operator.git
- **Version**: v-2160-160-g9e432d9
- **Branch**: rhoai-2.16
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Manages lifecycle of namespace-scoped Data Science Pipeline stacks for ML workflow orchestration.

**Detailed**: The Data Science Pipelines Operator (DSPO) is a Kubernetes operator that deploys and manages single namespace-scoped Data Science Pipeline (DSP) stacks on OpenShift/Kubernetes clusters. Based on upstream Kubeflow Pipelines (KFP), it enables data scientists to create, track, and manage ML workflows for data preparation, model training, validation, and experimentation. The operator reconciles DataSciencePipelinesApplication custom resources to deploy and configure all necessary pipeline infrastructure components including API servers, workflow controllers, metadata storage, and object storage. It supports both DSP v1 (OpenShift Pipelines/Tekton-based) and DSP v2 (Argo Workflows-based) architectures, with v2 deploying a namespace-scoped Argo Workflow Controller for enhanced isolation and multi-tenancy.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| DSPO Controller Manager | Kubernetes Operator | Reconciles DataSciencePipelinesApplication CRs and manages DSP component lifecycle |
| DS Pipelines API Server | REST/gRPC API Server | Provides KFP API for pipeline management, execution, and artifact tracking |
| Persistence Agent | Background Worker | Syncs Argo Workflow state to database for persistence and querying |
| Scheduled Workflow Controller | CronJob Controller | Manages scheduled and recurring pipeline executions |
| Workflow Controller | Argo Workflows Controller | Orchestrates pipeline execution as Kubernetes workflows (DSP v2) |
| ML Metadata (MLMD) gRPC Server | gRPC Service | Stores ML metadata and lineage information |
| MLMD Envoy Proxy | HTTP/gRPC Proxy | Provides OAuth-protected access to MLMD gRPC server |
| MariaDB | Relational Database | Stores pipeline metadata, run history, and ML metadata (default, optional) |
| Minio | Object Storage | Stores pipeline artifacts and logs (default, optional) |
| ML Pipelines UI | Web Frontend | Graphical interface for pipeline management (optional, unsupported) |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencepipelinesapplications.opendatahub.io | v1 | DataSciencePipelinesApplication | Namespaced | Defines a complete DSP deployment with API server, storage, database, and optional components |
| datasciencepipelinesapplications.opendatahub.io | v1alpha1 | DataSciencePipelinesApplication | Namespaced | Legacy API version for DSP deployment configuration |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /apis/v2beta1/* | GET, POST, PUT, DELETE | 8888/TCP | HTTP | TLS 1.3 (pod-to-pod) | None (internal) | KFP v2 REST API for pipeline management |
| /apis/v1beta1/* | GET, POST, PUT, DELETE | 8888/TCP | HTTP | TLS 1.3 (pod-to-pod) | None (internal) | KFP v1 REST API (legacy) |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator health check |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness check |
| /metrics | GET | 8080/TCP | HTTP | None | None | Operator Prometheus metrics |
| / (API Server Route) | GET, POST, PUT, DELETE | 8443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | OAuth2 Proxy | External access to DSP API via OpenShift Route |
| / (MLMD Envoy Route) | * | 8443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | OAuth2 Proxy | External access to MLMD via OpenShift Route |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ds-pipeline (API Server) | 8887/TCP | gRPC | TLS 1.3 (pod-to-pod) | None (internal) | Internal KFP gRPC API for pipeline operations |
| ds-pipeline-metadata-grpc | Configurable/TCP (default 8080) | gRPC | TLS 1.3 (pod-to-pod, optional) | mTLS (optional) | ML Metadata storage and retrieval |
| ds-pipeline-md (MLMD Envoy) | 9090/TCP | gRPC/HTTP2 | TLS 1.3 (pod-to-pod) | None (internal) | Envoy proxy for MLMD gRPC traffic |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| OpenShift/Kubernetes | 4.11+ | Yes | Container orchestration platform |
| OpenShift Pipelines (Tekton) | 1.8+ | Yes (DSP v1 only) | Workflow execution engine for DSP v1 |
| Argo Workflows | 3.x | No (bundled for v2) | Workflow execution engine for DSP v2 (deployed by operator) |
| MariaDB or External DB | 10.x+ | Yes | Pipeline metadata and run history storage |
| S3-compatible Storage | Any | Yes | Artifact and log storage (Minio or external) |
| OAuth Proxy | Latest | Yes | Authentication for external access via Routes |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | REST API, OAuth | Pipeline UI integration and user access control |
| OpenShift Service CA | TLS Certificate Provisioning | Pod-to-pod mTLS certificate generation via service annotations |
| User Workload Monitoring | ServiceMonitor | Prometheus metrics collection from DSP components |
| RHOAI Monitoring | ServiceMonitor | Centralized metrics collection for RHOAI dashboards |
| Workbenches (Notebooks) | KFP SDK Client | Pipeline authoring and submission from notebook environments |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| ds-pipeline-{name} | ClusterIP | 8888/TCP | http | HTTP | TLS 1.3 (pod-to-pod) | None | Internal |
| ds-pipeline-{name} | ClusterIP | 8887/TCP | 8887 | gRPC | TLS 1.3 (pod-to-pod) | None | Internal |
| ds-pipeline-{name} | ClusterIP | 8443/TCP | oauth | HTTPS | TLS 1.3 | OAuth2 | Internal (via Route) |
| mariadb-{name} | ClusterIP | 3306/TCP | 3306 | TCP (MySQL) | TLS 1.2+ (optional) | DB Password | Internal |
| minio-{name} | ClusterIP | 9000/TCP | 9000 | HTTP | None (plaintext) | S3 Access Keys | Internal |
| minio-{name} | ClusterIP | 80/TCP | 9000 | HTTP | None (plaintext) | S3 Access Keys | Internal |
| ds-pipeline-metadata-grpc-{name} | ClusterIP | Configurable/TCP | Configurable | gRPC | TLS 1.3 (optional) | mTLS (optional) | Internal |
| ds-pipeline-md-{name} | ClusterIP | 9090/TCP | 9090 | gRPC/HTTP2 | TLS 1.3 (pod-to-pod) | None | Internal |
| ds-pipeline-md-{name} | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.3 | OAuth2 | Internal (via Route) |
| ds-pipeline-workflow-controller-metrics-{name} | ClusterIP | 9090/TCP | 9090 | HTTP | None | None | Internal |
| controller-manager (operator) | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| ds-pipeline-{name} | OpenShift Route | Auto-generated | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |
| ds-pipeline-md-{name} | OpenShift Route | Auto-generated | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External (optional) |
| minio-{name} | OpenShift Route | Auto-generated | 9000/TCP | HTTP/HTTPS | TLS 1.2+ (optional) | Edge (optional) | External (optional) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| External S3 (AWS/GCS/Azure) | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Service Principal | Artifact storage in external object storage |
| External Database | 3306/TCP or 5432/TCP | MySQL/PostgreSQL | TLS 1.2+ | DB Credentials | External database connection for metadata storage |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secrets | Pull container images for pipeline steps |
| Git Repositories | 443/TCP | HTTPS | TLS 1.2+ | Git Credentials | Fetch pipeline definitions and code |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications, datasciencepipelinesapplications/status, datasciencepipelinesapplications/finalizers | get, list, watch, create, update, patch, delete |
| manager-role | apps, "" | deployments, services | create, delete, get, list, patch, update, watch |
| manager-role | "" | configmaps, secrets, serviceaccounts, persistentvolumeclaims, persistentvolumes | create, delete, get, list, patch, update, watch |
| manager-role | "" | pods, pods/exec, pods/log | * (all) |
| manager-role | "" | events | create, list, patch |
| manager-role | rbac.authorization.k8s.io | roles, rolebindings, clusterroles, clusterrolebindings | create, delete, get, list, patch, update, watch |
| manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| manager-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| manager-role | networking.k8s.io | ingresses | get, list |
| manager-role | monitoring.coreos.com | servicemonitors | create, delete, get, list, patch, update, watch |
| manager-role | argoproj.io | workflows, workflowtaskresults, workflowartifactgctasks, workflowartifactgctasks/finalizers | *, create, patch |
| manager-role | batch | jobs | * (all) |
| manager-role | kubeflow.org | * | * (all) |
| manager-role | image.openshift.io | imagestreamtags | get |
| manager-role | authentication.k8s.io | tokenreviews | create |
| manager-role | authorization.k8s.io | subjectaccessreviews | create |
| manager-role | snapshot.storage.k8s.io | volumesnapshots | create, delete, get |
| manager-role | ray.io | rayclusters, rayjobs, rayservices | create, delete, get, list, patch |
| manager-role | workload.codeflare.dev | appwrappers, appwrappers/finalizers, appwrappers/status | create, delete, deletecollection, get, list, patch, update, watch |
| manager-role | machinelearning.seldon.io | seldondeployments | * (all) |
| ds-pipeline-{name} | "" | secrets, configmaps | get, list, watch |
| ds-pipeline-{name} | argoproj.io | workflows | get, list, watch, create, update, patch, delete |
| pipeline-runner-{name} | argoproj.io | workflows | get, list, watch, create, update, patch, delete |
| pipeline-runner-{name} | "" | pods, pods/log | get, list, watch |
| argo-aggregate-to-admin | argoproj.io | workflows, workflowtemplates, cronworkflows, clusterworkflowtemplates | create, delete, deletecollection, get, list, patch, update, watch |
| argo-aggregate-to-edit | argoproj.io | workflows, workflowtemplates, cronworkflows | create, delete, deletecollection, get, list, patch, update, watch |
| argo-aggregate-to-view | argoproj.io | workflows, workflowtemplates, cronworkflows, clusterworkflowtemplates | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | datasciencepipelinesapplications-controller | manager-role (ClusterRole) | controller-manager |
| leader-election-rolebinding | datasciencepipelinesapplications-controller | leader-election-role (Role) | controller-manager |
| ds-pipeline-{name} | {user-namespace} | ds-pipeline-{name} (Role) | ds-pipeline-{name} |
| pipeline-runner-{name} | {user-namespace} | pipeline-runner-{name} (Role) | pipeline-runner-{name} |
| argo-binding (ClusterRoleBinding) | cluster-wide | argo-cluster-role | argo (per namespace) |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| ds-pipelines-proxy-tls-{name} | kubernetes.io/tls | TLS certificate for OAuth proxy on API Server | OpenShift Service CA | Yes |
| ds-pipelines-envoy-proxy-tls-{name} | kubernetes.io/tls | TLS certificate for OAuth proxy on MLMD Envoy | OpenShift Service CA | Yes |
| ds-pipeline-metadata-grpc-tls-certs-{name} | kubernetes.io/tls | TLS certificate for MLMD gRPC server (pod-to-pod) | OpenShift Service CA | Yes |
| ds-pipelines-mariadb-tls-{name} | kubernetes.io/tls | TLS certificate for MariaDB (pod-to-pod, optional) | OpenShift Service CA | Yes |
| mariadb-{name} | Opaque | MariaDB root password | User/Operator | No |
| {s3-secret-name} | Opaque | S3 access key and secret key | User | No |
| {db-password-secret} | Opaque | External database password | User | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /apis/* (via Route) | GET, POST, PUT, DELETE | OAuth2 Proxy (OpenShift OAuth) | OpenShift Route + OAuth Proxy Sidecar | Cluster RBAC + namespace access |
| /apis/* (internal) | GET, POST, PUT, DELETE | None (trusted pod network) | NetworkPolicy | Pod label selector restrictions |
| MLMD Envoy (via Route) | * | OAuth2 Proxy (OpenShift OAuth) | OpenShift Route + OAuth Proxy Sidecar | Cluster RBAC + namespace access |
| MariaDB | * | MySQL username/password | MariaDB Server | Database user authentication |
| Minio | S3 API | AWS Signature v4 (Access Key/Secret) | Minio Server | S3 IAM-style policies |
| Workflow Controller Metrics | GET | None | NetworkPolicy | Internal monitoring namespace access only |

### Network Policies

| Policy Name | Selector | Ingress Rules | Egress Rules |
|-------------|----------|---------------|--------------|
| ds-pipelines-{name} | app: ds-pipeline-{name} | Port 8443/TCP from all; Ports 8888/8887/TCP from: monitoring namespaces, DSP component pods, workbenches, pipeline pods | Not specified (default allow) |
| ds-pipelines-envoy-{name} | app: ds-pipeline-metadata-envoy-{name} | Port 8443/TCP from all; Port 9090/TCP from DSP component pods | Not specified (default allow) |
| mariadb-{name} | app: mariadb-{name} | Port 3306/TCP from DSP component pods only | Not specified (default allow) |
| metadata-grpc-{name} | app: ds-pipeline-metadata-grpc-{name} | Configurable port from DSP component pods only | Not specified (default allow) |

## Data Flows

### Flow 1: Pipeline Submission (via UI/SDK)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser/SDK | OpenShift Route (ds-pipeline) | 443/TCP | HTTPS | TLS 1.2+ | OAuth2 Token |
| 2 | OpenShift Route | OAuth Proxy Sidecar | 8443/TCP | HTTPS | TLS 1.3 | OAuth2 Validation |
| 3 | OAuth Proxy | DS Pipeline API Server | 8888/TCP | HTTP | TLS 1.3 (pod-to-pod) | None (trusted) |
| 4 | DS Pipeline API Server | MariaDB | 3306/TCP | MySQL Protocol | TLS 1.2+ (optional) | DB Password |
| 5 | DS Pipeline API Server | Workflow Controller | Internal | gRPC/HTTP | TLS 1.3 (pod-to-pod) | ServiceAccount Token |

### Flow 2: Pipeline Execution (Workflow Orchestration)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Workflow Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Workflow Controller | Pipeline Pod (created) | N/A | N/A | N/A | N/A |
| 3 | Pipeline Pod | Minio/S3 | 9000/TCP or 443/TCP | HTTP or HTTPS | TLS 1.2+ (external S3) | S3 Access Keys |
| 4 | Pipeline Pod | DS Pipeline API Server | 8887/TCP | gRPC | TLS 1.3 (pod-to-pod) | ServiceAccount Token |

### Flow 3: Metadata Recording (MLMD)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | DS Pipeline API Server | MLMD Envoy Proxy | 9090/TCP | gRPC/HTTP2 | TLS 1.3 (pod-to-pod) | None (trusted) |
| 2 | MLMD Envoy Proxy | MLMD gRPC Server | Configurable/TCP | gRPC | TLS 1.3 (optional) | mTLS (optional) |
| 3 | MLMD gRPC Server | MariaDB | 3306/TCP | MySQL Protocol | TLS 1.2+ (optional) | DB Password |

### Flow 4: Persistence Agent Sync

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Persistence Agent | Kubernetes API (Workflow CRDs) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Persistence Agent | DS Pipeline API Server | 8887/TCP | gRPC | TLS 1.3 (pod-to-pod) | ServiceAccount Token |
| 3 | DS Pipeline API Server | MariaDB | 3306/TCP | MySQL Protocol | TLS 1.2+ (optional) | DB Password |

### Flow 5: Scheduled Workflow Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Scheduled Workflow Controller | DS Pipeline API Server | 8887/TCP | gRPC | TLS 1.3 (pod-to-pod) | ServiceAccount Token |
| 2 | DS Pipeline API Server | Workflow Controller | Internal | gRPC/HTTP | TLS 1.3 (pod-to-pod) | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | CR reconciliation, resource management |
| OpenShift OAuth | OAuth2 | 443/TCP | HTTPS | TLS 1.2+ | User authentication for external access |
| Prometheus (User Workload Monitoring) | ServiceMonitor Scrape | 8080/TCP, 9090/TCP | HTTP | None | Metrics collection from operator and DSP components |
| ODH Dashboard | REST API via Route | 443/TCP | HTTPS | TLS 1.2+ | Pipeline management UI integration |
| Workbenches/Notebooks | KFP SDK (REST/gRPC) | 443/TCP (via Route) | HTTPS | TLS 1.2+ | Pipeline authoring and submission |
| Elyra | KFP SDK (REST API) | 443/TCP (via Route) | HTTPS | TLS 1.2+ | Visual pipeline authoring and submission |
| Argo Workflows (bundled v2) | Controller API | Internal | HTTP | TLS 1.3 (pod-to-pod) | Workflow execution orchestration |
| OpenShift Service CA | Certificate Provisioning | N/A | N/A | N/A | Automatic TLS certificate generation for pod-to-pod communication |

## Deployment Configuration

### Kustomize Structure

The operator uses Kustomize for deployment manifests located in `config/`:

| Directory | Purpose |
|-----------|---------|
| config/manager/ | Operator deployment, service, and configuration |
| config/rbac/ | ClusterRole, RoleBindings, ServiceAccounts |
| config/crd/ | DataSciencePipelinesApplication CRD definition |
| config/argo/ | Argo Workflows CRDs and RBAC for DSP v2 |
| config/internal/ | Templates for DSP component deployments (used by operator at runtime) |
| config/base/ | Base kustomization and parameters |

### Internal Component Templates

The operator deploys DSP components using Go templates from `config/internal/`:

- **apiserver/**: API Server deployment, services, routes, RBAC
- **persistence-agent/**: Persistence Agent deployment, RBAC
- **scheduled-workflow/**: Scheduled Workflow controller deployment, RBAC
- **workflow-controller/**: Argo Workflow Controller deployment, ConfigMap, service, RBAC
- **ml-metadata/**: MLMD gRPC server and Envoy proxy deployments, services, routes
- **mariadb/**: MariaDB deployment, PVC, service, NetworkPolicy
- **minio/**: Minio deployment, PVC, service, route
- **mlpipelines-ui/**: ML Pipelines UI deployment, service, route
- **common/**: Shared NetworkPolicies and authorization policies

## Configuration Options

### DSPVersion

- **v1**: Uses OpenShift Pipelines (Tekton) for workflow execution
- **v2** (default): Uses Argo Workflows for workflow execution

### PodToPodTLS

- **true** (default): Enables mTLS between DSP components using OpenShift Service CA
- **false**: Disables pod-to-pod encryption (not recommended for production)

### Component Deployment Flags

All major components have a `deploy` boolean flag:
- **apiServer.deploy** (default: true)
- **persistenceAgent.deploy** (default: true)
- **scheduledWorkflow.deploy** (default: true)
- **workflowController.deploy** (default: true)
- **database.mariaDB.deploy** (default: true) - or use externalDB
- **objectStorage.minio.deploy** (default: false) - or use externalStorage
- **mlpipelineUI.deploy** (default: false) - unsupported, for testing only
- **mlmd.deploy** (default: false)

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 9e432d9 | 2026-03-09 | - Update ubi8/go-toolset:1.25 docker digest to e20b9b4 |
| 836eca3 | 2026-03-09 | - Update ubi8/go-toolset:1.25 docker digest to 10bd7b9 |
| cd26d42 | 2026-03-04 | - Update ubi8/ubi-minimal docker digest to b880e16 |
| ac38a28 | 2026-02-26 | - Update ubi8/go-toolset:1.25 docker digest to ff71f60 |
| 1382195 | 2026-02-25 | - Update ubi8/go-toolset:1.25 docker digest to d308645 |
| 7f88de6 | 2026-02-24 | - Update ubi8/ubi-minimal docker digest to 6ed9271 |
| 23ce2c9 | 2026-02-23 | - Update ubi8/ubi-minimal docker digest to 4189e1e |
| fa2ccf4 | 2026-02-17 | - Update ubi8/go-toolset:1.25 docker digest to ad14167 |
| 4594a0d | 2026-02-11 | - Update ubi8/ubi-minimal docker digest to 48adecc |
| d7fa990 | 2026-02-10 | - Add PipelineRun Configuration for odh-data-science-pipelines-operator-controller for rhoai-2.16<br>- Sync pipelineruns with konflux-central |
| 3ea4f9d | 2026-02-04 | - Update ubi8/ubi-minimal docker digest to 000dd8e |
| 263a487 | 2026-01-30 | - Update MariaDB images to match main branch |
| 62c31c2 | 2026-01-29 | - Use kubectl instead of oc for CI tests |
| 866380b | 2026-01-28 | - Update to ubuntu-latest for Kind tests |

## Build Information

### Container Build

- **Build System**: Konflux (RHOAI standard)
- **Dockerfile**: `Dockerfile.konflux` (multi-stage build)
- **Base Images**:
  - Builder: `registry.access.redhat.com/ubi8/go-toolset:1.25`
  - Runtime: `registry.redhat.io/ubi8/ubi-minimal`
- **Binary**: `/manager` (Go compiled, CGO disabled)
- **User**: 65532 (non-root)
- **Component Label**: `odh-data-science-pipelines-operator-controller-container`

### Operator Configuration

- **Metrics Port**: 8080/TCP
- **Health Probe Port**: 8081/TCP
- **Leader Election**: Enabled in production
- **Config Path**: `/home/config` (mounted from ConfigMap `dspo-config`)
- **Max Concurrent Reconciles**: Configurable (default from code)
- **Templates Path**: `config/internal/` (bundled in container)

## Metrics

The operator and DSP components expose Prometheus metrics:

| Component | Endpoint | Port | Metrics |
|-----------|----------|------|---------|
| DSPO Controller | /metrics | 8080/TCP | Operator reconciliation metrics, queue depth, error rates |
| Workflow Controller | /metrics | 9090/TCP | Argo workflow execution metrics |
| API Server | /metrics | 8888/TCP | KFP API request rates, latencies, pipeline execution metrics |

ServiceMonitors are automatically created for integration with OpenShift User Workload Monitoring and RHOAI Monitoring.

## Notes

- **Multi-tenancy**: Each DataSciencePipelinesApplication CR creates an isolated DSP stack within a single namespace
- **Storage**: Supports both internal (Minio/MariaDB) and external (S3/RDS/CloudSQL) storage backends
- **Networking**: Pod-to-pod TLS is highly recommended for production (default enabled on OpenShift)
- **Routes**: External access via OpenShift Routes with OAuth2 proxy for authentication
- **Pipeline Execution**: DSP v2 uses namespace-scoped Argo Workflow Controller to avoid cluster-wide dependencies
- **Conflict Detection**: Operator prevents multiple DSPA CRs in the same namespace to avoid resource conflicts
- **Artifact Storage**: Pipeline artifacts stored in S3-compatible object storage with signed URL access
- **Metadata Tracking**: Optional MLMD deployment for ML lineage and experiment tracking
