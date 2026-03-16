# Component: Data Science Pipelines Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/data-science-pipelines-operator.git
- **Version**: 6b7b774 (rhoai-2.14 branch)
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Manages namespace-scoped Data Science Pipeline stacks for ML workflow orchestration on OpenShift.

**Detailed**: The Data Science Pipelines Operator (DSPO) is a Kubernetes operator that deploys and manages Data Science Pipelines (DSP) stacks within individual OpenShift namespaces. Based on upstream Kubeflow Pipelines (KFP), it enables data scientists to create, track, and execute ML workflows for data preparation, model training, and validation. The operator reconciles DataSciencePipelinesApplication (DSPA) custom resources to deploy a complete pipeline infrastructure including API servers, persistence agents, workflow controllers, metadata tracking, and optional database/storage components. It supports both DSP v1 (Tekton-based) and DSP v2 (Argo Workflows-based) architectures, with v2 being the current focus. The operator integrates with OpenShift-specific features like Routes, OAuth proxy authentication, and service-ca certificates for secure pod-to-pod TLS communication.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| DSPO Controller | Kubernetes Operator | Reconciles DSPA CRs and manages all DSP component lifecycles |
| API Server | REST/gRPC Service | Provides pipeline management APIs (create, run, monitor pipelines) |
| Persistence Agent | Background Service | Synchronizes Argo workflow state to backend database |
| Scheduled Workflow Controller | Controller | Manages scheduled/recurring pipeline runs |
| Workflow Controller | Argo Controller | Orchestrates pipeline workflow execution (DSP v2) |
| MariaDB | Database (Optional) | Stores pipeline metadata, run history, and ML metadata |
| Minio | Object Storage (Optional) | Stores pipeline artifacts and outputs |
| ML Metadata (MLMD) gRPC | gRPC Service (Optional) | Provides ML metadata lineage tracking |
| ML Metadata Envoy | Proxy (Optional) | Provides HTTP/OAuth access to MLMD gRPC service |
| ML Pipelines UI | Web Frontend (Optional) | Upstream KFP UI for pipeline visualization (unsupported) |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencepipelinesapplications.opendatahub.io | v1alpha1 | DataSciencePipelinesApplication | Namespaced | Defines a complete DSP stack deployment with API server, persistence, storage, and optional components |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /apis/v2beta1/* | REST | 8888/TCP | HTTP | TLS (internal) | Bearer/OAuth | Pipeline management API (create, list, run pipelines) |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator controller health check |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator controller readiness check |
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics (operator and DSPA status) |
| / (UI) | HTTP | 3000/TCP | HTTP | TLS (via route) | OAuth | ML Pipelines UI frontend (when enabled) |
| /ml_metadata/* | HTTP | 9090/TCP | HTTP | TLS | OAuth | ML Metadata HTTP API (via Envoy proxy) |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ds-pipelines-api-server | 8887/TCP | gRPC | TLS (pod-to-pod) | mTLS | Pipeline API gRPC interface |
| ds-pipeline-metadata-grpc | 8080/TCP | gRPC | TLS (pod-to-pod) | mTLS | ML Metadata lineage tracking |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| OpenShift | 4.11+ | Yes | Platform for operator deployment, Routes, OAuth |
| Argo Workflows | Latest | Yes (DSP v2) | Workflow orchestration engine |
| Tekton Pipelines | 1.8+ | Yes (DSP v1) | Workflow orchestration engine (legacy) |
| Prometheus Operator | Latest | No | Metrics collection via ServiceMonitor |
| cert-manager or service-ca | Latest | No | TLS certificate generation (uses OpenShift service-ca by default) |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | REST API | Displays pipeline runs, provides UI integration |
| opendatahub-operator | CRD Watch | DSPO deployed via DataScienceCluster CR |
| ODH Notebook Controller | None | Notebooks can submit pipelines via kfp SDK |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| ds-pipeline-{name} | ClusterIP | 8443/TCP | oauth | HTTPS | TLS | OAuth Proxy | Internal (exposed via Route) |
| ds-pipeline-{name} | ClusterIP | 8888/TCP | http | HTTP | TLS (internal) | Bearer | Internal |
| ds-pipeline-{name} | ClusterIP | 8887/TCP | 8887 | gRPC | TLS (internal) | mTLS | Internal |
| mariadb-{name} | ClusterIP | 3306/TCP | 3306 | MySQL | TLS (when podToPodTLS=true) | Password | Internal |
| minio-{name} | ClusterIP | 9000/TCP | 9000 | HTTP | None | AccessKey/SecretKey | Internal |
| minio-{name} | ClusterIP | 80/TCP | 9000 | HTTP | None | AccessKey/SecretKey | Internal (KFP UI workaround) |
| ds-pipeline-metadata-grpc-{name} | ClusterIP | 8080/TCP | 8080 | gRPC | TLS (when podToPodTLS=true) | mTLS | Internal |
| ds-pipeline-md-{name} | ClusterIP | 9090/TCP | 9090 | HTTP | TLS | None | Internal |
| ds-pipeline-md-{name} | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS | OAuth Proxy | Internal (exposed via Route) |
| controller-manager (operator) | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (metrics) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| ds-pipeline-{name} | OpenShift Route | Auto-generated | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |
| ds-pipeline-ui-{name} | OpenShift Route | Auto-generated | 3000/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |
| ds-pipeline-md-{name} | OpenShift Route | Auto-generated | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External (when MLMD.Envoy.DeployRoute=true) |
| minio-{name} | OpenShift Route | Auto-generated | 9000/TCP | HTTPS | TLS 1.2+ | Edge | External (when ObjectStorage.EnableExternalRoute=true) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| External S3 (AWS/MinIO) | 443/TCP or custom | HTTPS/HTTP | TLS 1.2+ (configurable) | AWS IAM or AccessKey | Pipeline artifact storage |
| External Database | 3306/TCP or custom | MySQL/PostgreSQL | TLS (configurable) | Password | Pipeline metadata storage |
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Resource management (pods, workflows, secrets) |
| Image Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret | Pull pipeline component images |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications | create, delete, get, list, patch, update, watch |
| manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications/status | get, patch, update |
| manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications/finalizers | update |
| manager-role | apps, "", extensions | deployments, replicasets | * |
| manager-role | "" | configmaps, persistentvolumeclaims, secrets, serviceaccounts, services | create, delete, get, list, patch, update, watch |
| manager-role | "" | pods, pods/exec, pods/log | * |
| manager-role | argoproj.io | workflows | * |
| manager-role | argoproj.io | workflowtaskresults | create, patch |
| manager-role | tekton.dev | * | * |
| manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| manager-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| manager-role | rbac.authorization.k8s.io | roles, rolebindings | create, delete, get, list, patch, update, watch |
| manager-role | monitoring.coreos.com | servicemonitors | create, delete, get, list, patch, update, watch |
| manager-role | kubeflow.org | * | * |
| manager-role | ray.io | rayclusters, rayjobs, rayservices | create, delete, get, list, patch |
| manager-role | workload.codeflare.dev | appwrappers | create, delete, deletecollection, get, list, patch, update, watch |
| manager-argo-role | argoproj.io | workflows, workflows/finalizers, workflowtasksets, cronworkflows | get, list, watch, update, patch, delete, create |
| manager-argo-role | "" | pods, pods/exec | create, get, list, watch, update, patch, delete |
| manager-argo-role | "" | persistentvolumeclaims, persistentvolumeclaims/finalizers | create, update, delete, get |
| manager-argo-role | coordination.k8s.io | leases | create, get, update |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| role-binding | datasciencepipelinesapplications-controller | manager-role | controller-manager |
| argo-role-binding | datasciencepipelinesapplications-controller | manager-argo-role | controller-manager |
| ds-pipeline-{name} | {DSPA namespace} | ds-pipeline-{name} | ds-pipeline-{name} |
| pipeline-runner-{name} | {DSPA namespace} | pipeline-runner-{name} | pipeline-runner-{name} |
| ds-pipeline-persistenceagent-{name} | {DSPA namespace} | ds-pipeline-persistenceagent-{name} | ds-pipeline-persistenceagent-{name} |
| ds-pipeline-scheduledworkflow-{name} | {DSPA namespace} | ds-pipeline-scheduledworkflow-{name} | ds-pipeline-scheduledworkflow-{name} |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| ds-pipelines-proxy-tls-{name} | kubernetes.io/tls | OAuth proxy TLS certificate | service-ca-operator | No |
| ds-pipelines-mariadb-tls-{name} | kubernetes.io/tls | MariaDB TLS certificate (when podToPodTLS=true) | service-ca-operator | No |
| ds-pipeline-metadata-grpc-tls-certs-{name} | kubernetes.io/tls | MLMD gRPC TLS certificate | service-ca-operator | No |
| ds-pipelines-envoy-proxy-tls-{name} | kubernetes.io/tls | MLMD Envoy proxy TLS certificate | service-ca-operator | No |
| {user-provided} | Opaque | Database credentials (username, password) | User/Admin | No |
| {user-provided} | Opaque | S3 credentials (accessKey, secretKey) | User/Admin | No |
| ds-pipeline-db-{name} | Opaque | Auto-generated MariaDB password (when mariaDB.deploy=true) | DSPO | No |
| ds-pipeline-s3-{name} | Opaque | Auto-generated Minio credentials (when minio.deploy=true) | DSPO | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /apis/v2beta1/* (external) | REST | Bearer Token (JWT) from OAuth Proxy | OpenShift Route + OAuth Proxy | Authenticated OpenShift users |
| /apis/v2beta1/* (internal) | REST | Bearer Token | API Server | ServiceAccount token validation |
| gRPC (internal) | gRPC | mTLS client certificates | Service mesh / TLS | Pod-to-pod TLS when enabled |
| MariaDB | MySQL | Password authentication | MariaDB | Database credential validation |
| Minio/S3 | S3 API | AWS Signature v4 (AccessKey/SecretKey) | Minio/S3 | S3 credential validation |

## Data Flows

### Flow 1: Pipeline Submission from Notebook

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Jupyter Notebook (kfp SDK) | ds-pipeline-{name} Route | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (user OAuth) |
| 2 | OAuth Proxy | ds-pipeline API Server | 8888/TCP | HTTP | TLS (internal) | Bearer Token (validated) |
| 3 | API Server | MariaDB | 3306/TCP | MySQL | TLS (if podToPodTLS=true) | Password |
| 4 | API Server | Minio/S3 | 9000/TCP or 443/TCP | HTTP/HTTPS | TLS (configurable) | AccessKey/SecretKey |

### Flow 2: Workflow Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Scheduled Workflow Controller | Workflow Controller | 9443/TCP | HTTP | None | ServiceAccount |
| 2 | Workflow Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Workflow Controller | Creates Workflow Pods | N/A | N/A | N/A | N/A |
| 4 | Workflow Pod (pipeline step) | Minio/S3 | 9000/TCP or 443/TCP | HTTP/HTTPS | TLS (configurable) | AccessKey/SecretKey |
| 5 | Workflow Pod | MLMD gRPC (optional) | 8080/TCP | gRPC | TLS (if podToPodTLS=true) | mTLS |

### Flow 3: Workflow State Persistence

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Persistence Agent | Kubernetes API (watch Workflows) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Persistence Agent | API Server | 8888/TCP | HTTP | TLS (internal) | ServiceAccount Token |
| 3 | API Server | MariaDB | 3306/TCP | MySQL | TLS (if podToPodTLS=true) | Password |

### Flow 4: UI Artifact Retrieval

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | ds-pipeline-ui Route | 443/TCP | HTTPS | TLS 1.2+ | OAuth Session |
| 2 | ML Pipelines UI | API Server | 8888/TCP | HTTP | TLS (internal) | Bearer Token |
| 3 | ML Pipelines UI | Minio | 80/TCP | HTTP | None | AccessKey/SecretKey |
| 4 | User Browser | Minio (presigned URL) | 9000/TCP | HTTP | None | Presigned Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Argo Workflows | CRD Management | 6443/TCP | HTTPS | TLS 1.2+ | Create/manage Workflow CRs for pipeline execution |
| Tekton Pipelines (v1) | CRD Management | 6443/TCP | HTTPS | TLS 1.2+ | Create/manage PipelineRun/TaskRun CRs (legacy) |
| Kubernetes API | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Resource lifecycle management |
| ODH Dashboard | REST API | 8888/TCP | HTTP | TLS (internal) | Display pipeline runs and status |
| Prometheus | HTTP Scrape | 8080/TCP | HTTP | None | Metrics collection for DSPA status |
| External S3 (AWS/MinIO/etc) | S3 API | 443/TCP | HTTPS | TLS 1.2+ | Artifact and output storage |
| External Database (MySQL/PostgreSQL) | SQL | 3306/TCP | MySQL/PostgreSQL | TLS (configurable) | Metadata persistence |
| Image Registry (Quay/etc) | HTTPS | 443/TCP | HTTPS | TLS 1.2+ | Pull pipeline component images |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 6b7b774 | 2024-10-10 | - Merge pull request #62 from main |
| 3ded8a1 | 2024-10-10 | - Merge pull request #716 for stable release |
| 005d287 | 2024-10-09 | - Added secrets::list permissions to pipeline runner |
| 882c82e | 2024-09-30 | - Merge pull request #710 for stable release |
| bef7d2e | 2024-09-30 | - Merge remote-tracking branch 'odh/v2.6.x' into stable |
| db7ab93 | 2024-09-30 | - Merge pull request #706 from release-2.6 |
| 70430e5 | 2024-09-28 | - Generate params for 2.6 |
| a54d0a6 | 2024-09-27 | - Update compatibility documentation for 2.6 |
| 52bd7d1 | 2024-08-09 | - Added support for TLS to MLMD GRPC Server |
| b81616c | 2024-09-19 | - Support environment variables as pipeline parameters |
| 7270713 | 2024-08-29 | - Updated MariaDB to serve over TLS |
| a9974ff | 2024-09-18 | - Fix return value of get_dspo_image |
| bbfa6c9 | 2024-09-18 | - Fix suggestions |
| cca3cf0 | 2024-09-18 | - Allow DSPO test suite to run with RHOAI |
| b616f69 | 2024-09-17 | - Move kind-integration.sh content to tests.sh |
| 6cf02ac | 2024-09-17 | - Merge pull request #701 |
| 145f3ca | 2024-09-17 | - Bumped actions/upload-artifact to v4 |
| e101b0f | 2024-09-05 | - Merge pull request #698 |
| 4e140bd | 2024-09-05 | - OWNERS updates |

## Operator Configuration

### Environment Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| IMAGES_DSPO | DSPO operator image | Set via params.env |
| IMAGES_APISERVER | API Server image | Set via params.env |
| IMAGES_PERSISTENTAGENT | Persistence Agent image | Set via params.env |
| IMAGES_SCHEDULEDWORKFLOW | Scheduled Workflow image | Set via params.env |
| IMAGES_MARIADB | MariaDB image | registry.redhat.io/rhel8/mariadb-103 |
| IMAGES_MLMDENVOY | ML Metadata Envoy image | Set via params.env |
| IMAGES_MLMDGRPC | ML Metadata gRPC image | Set via params.env |
| IMAGESV2_ARGO_WORKFLOWCONTROLLER | Argo Workflow Controller image | Set via params.env |
| IMAGESV2_ARGO_ARGOEXEC | Argo Executor image | Set via params.env |
| V2_LAUNCHER_IMAGE | KFP v2 launcher image | Set via params.env |
| V2_DRIVER_IMAGE | KFP v2 driver image | Set via params.env |
| ZAP_LOG_LEVEL | Operator log level | info |
| MAX_CONCURRENT_RECONCILES | Max concurrent reconcile loops | 10 |
| DSPO_REQUEUE_TIME | Reconcile requeue time | 30s |

### Custom Metrics

| Metric Name | Type | Labels | Purpose |
|-------------|------|--------|---------|
| data_science_pipelines_application_apiserver_ready | Gauge | namespace, name | DSPA API Server readiness (1=Ready, 0=Not Ready) |
| data_science_pipelines_application_persistenceagent_ready | Gauge | namespace, name | DSPA Persistence Agent readiness (1=Ready, 0=Not Ready) |
| data_science_pipelines_application_scheduledworkflow_ready | Gauge | namespace, name | DSPA Scheduled Workflow readiness (1=Ready, 0=Not Ready) |
| data_science_pipelines_application_ready | Gauge | namespace, name | Overall DSPA readiness (1=Ready, 0=Not Ready) |

## Deployment Architecture

### Operator Deployment

- **Namespace**: Typically `opendatahub` or `redhat-ods-applications`
- **Replicas**: 1 (leader election enabled)
- **Resources**: CPU: 200m-1, Memory: 400Mi-4Gi
- **Security**: Non-root, capabilities dropped, no privilege escalation
- **Health Probes**: /healthz (liveness), /readyz (readiness) on port 8081

### DSPA Instance Deployment (per namespace)

When a DSPA CR is created, the operator deploys:

1. **API Server** (1 replica)
   - Manages pipeline CRUD operations
   - Handles artifact signed URLs
   - Optional OAuth proxy sidecar for route access

2. **Persistence Agent** (1 replica)
   - Watches Argo Workflow state changes
   - Persists workflow status to database
   - Configurable worker count (default: 2)

3. **Scheduled Workflow Controller** (1 replica)
   - Manages scheduled/recurring pipeline runs
   - Creates Workflow CRs based on schedules

4. **Workflow Controller** (1 replica, DSP v2)
   - Argo Workflows controller instance
   - Orchestrates workflow execution
   - Manages workflow pods

5. **MariaDB** (1 replica, optional)
   - Persistent storage (default: 10Gi PVC)
   - TLS support when podToPodTLS enabled
   - Auto-generated credentials or user-provided

6. **Minio** (1 replica, optional)
   - Persistent storage (default: 10Gi PVC)
   - S3-compatible API
   - Development/testing only (not production)

7. **ML Metadata gRPC** (1 replica, optional)
   - ML metadata lineage tracking
   - TLS support when podToPodTLS enabled

8. **ML Metadata Envoy** (1 replica, optional)
   - HTTP/gRPC proxy for MLMD
   - OAuth proxy sidecar for route access

9. **ML Pipelines UI** (1 replica, optional)
   - Upstream KFP UI
   - Unsupported, for development only
   - OAuth proxy sidecar for route access

## Network Policies

The operator creates NetworkPolicy resources to restrict traffic:

1. **MariaDB NetworkPolicy**
   - Allows ingress on port 3306/TCP only from:
     - DSPO controller pods
     - API Server pods
     - MLMD gRPC pods

2. **MLMD gRPC NetworkPolicy**
   - Allows ingress on port 8080/TCP only from:
     - Pods with label `pipelines.kubeflow.org/v2_component=true` (pipeline steps)
     - Pods with label `component=data-science-pipelines`

## ConfigMaps

| ConfigMap Name | Purpose | Owner |
|---------------|---------|-------|
| dspo-config | Operator configuration (image references) | Operator deployment |
| kfp-launcher | KFP v2 launcher configuration (S3 settings, pipeline root) | DSPA instance |
| ds-pipeline-server-config-{name} | API Server configuration | DSPA instance |
| workflow-controller-configmap-{name} | Argo Workflow Controller configuration | DSPA instance |

## Pod-to-Pod TLS

When `spec.podToPodTLS=true` (default for RHOAI):

- **MariaDB**: Serves on TLS port 3306 with service-ca generated certificate
- **MLMD gRPC**: Serves on TLS with service-ca generated certificate
- **API Server**: Connects to MariaDB and MLMD over TLS
- **Certificate Management**: OpenShift service-ca-operator auto-generates and rotates certificates

## Version Support

| Feature | DSP v1 | DSP v2 |
|---------|--------|--------|
| Workflow Engine | Tekton Pipelines | Argo Workflows |
| Status | Deprecated | Current |
| KFP SDK Version | kfp-tekton 1.5.x | kfp 2.x |
| Production Support | Limited | Full |
| Pod-to-Pod TLS | No | Yes (OpenShift only) |
