# Component: Data Science Pipelines Operator (DSPO)

## Metadata
- **Repository**: https://github.com/red-hat-data-services/data-science-pipelines-operator
- **Version**: rhoai-2.25 (commit 763811f)
- **Distribution**: RHOAI (also supports ODH)
- **Languages**: Go 1.25.5
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Manages the lifecycle of Data Science Pipelines (DSP) applications on OpenShift/Kubernetes clusters.

**Detailed**: The Data Science Pipelines Operator (DSPO) is a Kubernetes operator that deploys and manages namespace-scoped Data Science Pipeline stacks based on upstream Kubeflow Pipelines (KFP). It enables data scientists to create, track, and manage ML pipeline workflows for data preparation, model training, validation, and experimentation. The operator watches DataSciencePipelinesApplication (DSPA) custom resources and reconciles the deployment of all required components including API servers, persistence agents, workflow controllers, and optional components like databases, object storage, UI, and ML metadata services. DSPO supports both DSP v1 (using Tekton) and v2 (using Argo Workflows), with v2 being the default and recommended version.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| DSPO Controller | Kubernetes Operator | Manages lifecycle of DSPA resources and reconciles all DSP components |
| API Server | HTTP/gRPC Service | Main DSP API server for pipeline management, execution, and artifact access |
| Persistence Agent | Background Service | Syncs workflow execution status to database for persistence |
| Scheduled Workflow Controller | Background Service | Manages scheduled/recurring pipeline executions |
| Workflow Controller | Argo Controller | Namespace-scoped Argo Workflows controller for pipeline orchestration (DSP v2) |
| MariaDB (Optional) | Database | Metadata database for pipeline definitions and execution history |
| Minio (Optional) | Object Storage | S3-compatible object storage for pipeline artifacts |
| ML Pipelines UI (Optional) | Web Frontend | Upstream KFP UI for pipeline visualization and management |
| MLMD Envoy (Optional) | Proxy | Envoy proxy for ML Metadata service with OAuth authentication |
| MLMD gRPC (Optional) | gRPC Service | ML Metadata service for artifact lineage tracking |
| Webhook Server | Admission Controller | Validates and mutates PipelineVersion resources |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencepipelinesapplications.opendatahub.io | v1 | DataSciencePipelinesApplication | Namespaced | Primary CRD for defining a DSP deployment with all configuration |
| datasciencepipelinesapplications.opendatahub.io | v1alpha1 | DataSciencePipelinesApplication | Namespaced | Legacy API version (deprecated) |
| pipelines.kubeflow.org | v1 | Pipeline | Namespaced | Pipeline definitions (when pipelineStore=kubernetes) |
| pipelines.kubeflow.org | v1 | PipelineVersion | Namespaced | Pipeline version definitions (when pipelineStore=kubernetes) |
| argoproj.io | v1alpha1 | Workflow | Namespaced | Argo workflow definitions for pipeline execution |
| argoproj.io | v1alpha1 | WorkflowTemplate | Namespaced | Reusable workflow templates |
| kubeflow.org | v1beta1 | ScheduledWorkflow | Namespaced | Scheduled pipeline runs |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator health check endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness check endpoint |
| /metrics | GET | 8080/TCP | HTTP | None | None | Operator Prometheus metrics |
| /apis/v2beta1/* | ALL | 8888/TCP | HTTP | TLS 1.2+ | OAuth/Bearer | DSP API v2beta1 endpoints (pipelines, runs, experiments, artifacts) |
| /apis/v1/* | ALL | 8888/TCP | HTTP | TLS 1.2+ | OAuth/Bearer | DSP API v1 endpoints (legacy) |
| / | ALL | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Proxy | OAuth-protected API Server access via Route |
| /webhooks/validate-pipelineversion | POST | 8443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Webhook validation for PipelineVersion resources |
| /webhooks/mutate-pipelineversion | POST | 8443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Webhook mutation for PipelineVersion resources |
| / | ALL | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Proxy | ML Pipelines UI (optional) |
| / | ALL | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Proxy | MLMD Envoy proxy (optional) |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ml_metadata.MetadataStoreService | 8887/TCP | gRPC | TLS 1.2+ | mTLS (optional) | DSP API Server internal metadata service |
| ml_metadata.MetadataStoreService | 8080/TCP | gRPC | TLS 1.2+ (if podToPodTLS) | mTLS (if podToPodTLS) | MLMD gRPC server for artifact lineage |
| ml_metadata.MetadataStoreService | 9090/TCP | gRPC/HTTP2 | TLS 1.2+ | OAuth/mTLS | MLMD Envoy proxy (external access) |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| OpenShift/Kubernetes | 4.11+ | Yes | Container orchestration platform |
| Argo Workflows | 3.5.14 | Yes (DSP v2) | Workflow orchestration engine |
| OpenShift Pipelines (Tekton) | 1.8+ | Yes (DSP v1) | Workflow orchestration for DSP v1 |
| S3-compatible Object Storage | Any | Yes | Pipeline artifact storage (external or Minio) |
| MySQL/MariaDB | 10.3+ | Yes | Metadata persistence (external or deployed) |
| OAuth Proxy | v4.12+ | Yes | Authentication for external access |
| Envoy Proxy | OSSM 2.x | No (MLMD only) | Service mesh proxy for MLMD |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | Web UI Integration | Provides DSP UI integration in ODH Dashboard |
| OpenShift Route | Kubernetes Resource | External access to API Server and UI |
| Service Mesh (Istio) | Network Policy | Optional service mesh integration for mTLS |
| cert-manager | Certificate Management | Optional TLS certificate provisioning |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| ds-pipeline-{name} | ClusterIP | 8443/TCP | oauth | HTTPS | TLS 1.2+ | OAuth Proxy | Internal |
| ds-pipeline-{name} | ClusterIP | 8888/TCP | http | HTTP | None/TLS 1.2+ | None/mTLS | Internal |
| ds-pipeline-{name} | ClusterIP | 8887/TCP | 8887 | gRPC | TLS 1.2+ | mTLS (optional) | Internal |
| mariadb-{name} | ClusterIP | 3306/TCP | 3306 | MySQL | None/TLS 1.2+ | MySQL Auth | Internal |
| minio-{name} | ClusterIP | 9000/TCP | 9000 | HTTP | None | S3 Auth | Internal |
| minio-service | ClusterIP | 9000/TCP | 9000 | HTTP | None | S3 Auth | Internal |
| ds-pipeline-md-{name} | ClusterIP | 9090/TCP | 9090 | gRPC/HTTP2 | TLS 1.2+ | OAuth/mTLS | Internal |
| ds-pipeline-md-{name} | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | OAuth Proxy | Internal |
| ds-pipeline-metadata-grpc-{name} | ClusterIP | 8080/TCP | 8080 | gRPC | TLS 1.2+ (if podToPodTLS) | mTLS (if podToPodTLS) | Internal |
| ds-pipeline-ui-{name} | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | OAuth Proxy | Internal |
| ds-pipelines-webhook | ClusterIP | 8443/TCP | webhook | HTTPS | TLS 1.2+ | K8s API Server | Internal (DSPO namespace) |
| ds-pipeline-workflow-controller-metrics-{name} | ClusterIP | 9090/TCP | 9090 | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| ds-pipeline-{name} | OpenShift Route | *.apps.cluster.domain | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |
| ds-pipeline-ui-{name} | OpenShift Route | *.apps.cluster.domain | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External (optional) |
| ds-pipeline-md-{name} | OpenShift Route | *.apps.cluster.domain | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External (optional) |
| minio-{name} | OpenShift Route | *.apps.cluster.domain | 9000/TCP | HTTPS | TLS 1.2+ | Edge | External (optional) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| External S3 (AWS/compatible) | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/S3 Keys | Pipeline artifact storage |
| External Database | 3306/TCP | MySQL | TLS 1.2+ (optional) | DB Credentials | Pipeline metadata storage |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Registry Auth | Pull pipeline step images |
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account | Resource management and watches |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | "" | configmaps, secrets, serviceaccounts, services, persistentvolumeclaims, pods, events | create, delete, get, list, patch, update, watch |
| manager-role | apps | deployments, replicasets | create, delete, get, list, patch, update, watch |
| manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications | create, delete, get, list, patch, update, watch |
| manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications/status | get, patch, update |
| manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications/finalizers | update |
| manager-role | argoproj.io | workflows, workflowartifactgctasks, workflowtaskresults | create, delete, get, list, patch, update, watch |
| manager-role | pipelines.kubeflow.org | pipelines, pipelineversions | create, delete, get, list, patch, update, watch |
| manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| manager-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| manager-role | rbac.authorization.k8s.io | roles, rolebindings, clusterroles, clusterrolebindings | create, delete, get, list, update, watch |
| manager-role | monitoring.coreos.com | servicemonitors | create, delete, get, list, patch, update, watch |
| manager-role | serving.kserve.io | inferenceservices | create, delete, get, list, patch |
| manager-role | ray.io | rayclusters, rayjobs, rayservices | create, delete, get, list, patch |
| manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | create, delete, get, list, patch, update, watch |
| manager-argo-role | argoproj.io | workflows, workflowtemplates, cronworkflows, workflowartifactgctasks | create, delete, get, list, patch, update, watch |
| manager-argo-role | "" | pods, pods/exec, configmaps, secrets, serviceaccounts, persistentvolumeclaims | create, delete, get, list, patch, update, watch |
| manager-argo-role | coordination.k8s.io | leases | create, get, update |
| ds-pipeline-user-access-{name} | argoproj.io | workflows, workflowartifactgctasks | get, list, watch |
| ds-pipeline-{name} | argoproj.io | workflows, workflowartifactgctasks | create, delete, deletecollection, get, list, patch, update, watch |
| ds-pipeline-{name} | "" | pods, pods/log, configmaps, secrets, services, events | create, delete, get, list, patch, watch |
| ds-pipeline-{name} | serving.kserve.io | inferenceservices | create, delete, get, list, patch |
| pipeline-runner-{name} | "" | secrets, configmaps, serviceaccounts | get |
| pipeline-runner-{name} | argoproj.io | workflows | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | DSPO namespace | manager-role (ClusterRole) | data-science-pipelines-operator-controller-manager |
| manager-argo-rolebinding | DSPO namespace | manager-argo-role (ClusterRole) | data-science-pipelines-operator-controller-manager |
| ds-pipeline-{name} | DSPA namespace | ds-pipeline-{name} (Role) | ds-pipeline-{name} |
| pipeline-runner-{name} | DSPA namespace | pipeline-runner-{name} (Role) | pipeline-runner-{name} |
| ds-pipeline-workflow-controller-{name} | DSPA namespace | manager-argo-role (ClusterRole) | ds-pipeline-workflow-controller-{name} |
| ds-pipeline-persistenceagent-{name} | DSPA namespace | ds-pipeline-{name} (Role) | ds-pipeline-persistenceagent-{name} |
| ds-pipeline-scheduledworkflow-{name} | DSPA namespace | ds-pipeline-{name} (Role) | ds-pipeline-scheduledworkflow-{name} |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| ds-pipelines-proxy-tls-{name} | kubernetes.io/tls | TLS certificate for OAuth proxy | service.beta.openshift.io annotation | Yes |
| ds-pipelines-envoy-proxy-tls-{name} | kubernetes.io/tls | TLS certificate for MLMD Envoy proxy | service.beta.openshift.io annotation | Yes |
| ds-pipelines-webhook-tls | kubernetes.io/tls | TLS certificate for webhook server | service.beta.openshift.io annotation | Yes |
| mariadb-{name} | Opaque | MariaDB root password | DSPO (generated) | No |
| mlpipeline-minio-artifact | Opaque | Minio access credentials | DSPO (generated) or User | No |
| {custom}-db-secret | Opaque | External database credentials | User | No |
| {custom}-storage-secret | Opaque | External S3 storage credentials | User | No |
| ds-pipeline-metadata-grpc-tls-config-{name} | Opaque | MLMD gRPC TLS configuration | DSPO (if podToPodTLS) | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /apis/v2beta1/* (via Route) | ALL | OAuth Proxy (OpenShift) | OAuth Proxy container | OpenShift RBAC + OAuth |
| /apis/v2beta1/* (internal) | ALL | Bearer Token (K8s SA) | API Server | Kubernetes RBAC |
| /metrics (MLMD Envoy via Route) | GET | OAuth Proxy (OpenShift) | OAuth Proxy container | OpenShift RBAC |
| MLMD gRPC (internal) | ALL | mTLS (if podToPodTLS=true) | Envoy Proxy | Certificate-based |
| Webhook endpoints | POST | K8s API Server certs | Kubernetes API Server | Admission control |
| MariaDB | ALL | MySQL username/password | MariaDB server | Database authentication |
| Minio/S3 | ALL | S3 Access/Secret Keys | Minio/S3 server | S3 authentication |

### Network Policies

| Policy Name | Target Pods | Ingress Rules | Purpose |
|-------------|-------------|---------------|---------|
| mariadb-{name} | app=mariadb-{name} | Allow 3306/TCP from API Server, MLMD gRPC, DSPO | Restrict database access to authorized components |
| ds-pipeline-metadata-grpc-{name} | app=ds-pipeline-metadata-grpc-{name} | Allow 8080/TCP from v2 pipeline components and DSP components | Restrict MLMD gRPC access to pipeline executions |
| policy-{name} | app=ds-pipeline-{name} | Allow 8443/TCP from all, 8888/TCP from DSP components | Restrict API Server access patterns |

## Data Flows

### Flow 1: Pipeline Submission via API

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Client | OpenShift Route | 443/TCP | HTTPS | TLS 1.2+ | OAuth (OpenShift) |
| 2 | Route | OAuth Proxy (API Server Pod) | 8443/TCP | HTTPS | TLS 1.2+ | Service Cert |
| 3 | OAuth Proxy | API Server Container | 8888/TCP | HTTP | None/TLS 1.2+ | Bearer Token |
| 4 | API Server | MariaDB Service | 3306/TCP | MySQL | None/TLS 1.2+ | DB Credentials |
| 5 | API Server | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account |
| 6 | API Server | MLMD gRPC (optional) | 8080/TCP | gRPC | TLS 1.2+ (if podToPodTLS) | mTLS (if podToPodTLS) |

### Flow 2: Pipeline Execution (Workflow)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Workflow Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account |
| 2 | Workflow Controller | Pod (creates pipeline step) | N/A | N/A | N/A | N/A |
| 3 | Pipeline Step Pod | S3/Minio Service | 9000/TCP or 443/TCP | HTTP/HTTPS | TLS 1.2+ (external) | S3 Credentials |
| 4 | Pipeline Step Pod | MLMD gRPC | 8080/TCP | gRPC | TLS 1.2+ (if podToPodTLS) | mTLS (if podToPodTLS) |
| 5 | Persistence Agent | Kubernetes API (watch Workflows) | 6443/TCP | HTTPS | TLS 1.2+ | Service Account |
| 6 | Persistence Agent | MariaDB Service | 3306/TCP | MySQL | None/TLS 1.2+ | DB Credentials |

### Flow 3: Artifact Access

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/UI | API Server Route | 443/TCP | HTTPS | TLS 1.2+ | OAuth |
| 2 | API Server | S3/Minio Service | 9000/TCP or 443/TCP | HTTP/HTTPS | TLS 1.2+ (external) | S3 Credentials |
| 3 | API Server | User (signed URL) | 443/TCP | HTTPS | TLS 1.2+ | Signed URL (60s TTL) |

### Flow 4: MLMD Metadata Query

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Client | MLMD Envoy Route | 443/TCP | HTTPS | TLS 1.2+ | OAuth |
| 2 | Route | OAuth Proxy (Envoy Pod) | 8443/TCP | HTTPS | TLS 1.2+ | Service Cert |
| 3 | OAuth Proxy | Envoy Container | 9090/TCP | HTTP/gRPC | None | Bearer Token |
| 4 | Envoy | MLMD gRPC Service | 8080/TCP | gRPC | TLS 1.2+ (if podToPodTLS) | mTLS (if podToPodTLS) |
| 5 | MLMD gRPC | MariaDB Service | 3306/TCP | MySQL | None/TLS 1.2+ | DB Credentials |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Resource management, watches, and orchestration |
| OpenShift OAuth | OAuth2 | 443/TCP | HTTPS | TLS 1.2+ | User authentication for external access |
| Argo Workflows | Controller | N/A | In-Process | N/A | Pipeline execution orchestration (v2) |
| Tekton Pipelines | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Pipeline execution (v1) |
| Container Registry | Image Pull | 443/TCP | HTTPS | TLS 1.2+ | Pipeline step container images |
| S3-compatible Storage | S3 API | 443/TCP or 9000/TCP | HTTPS/HTTP | TLS 1.2+ (external) | Pipeline artifact storage and retrieval |
| Prometheus | Metrics Scrape | 8080/TCP | HTTP | None | Operator and component metrics collection |
| KServe/ModelMesh | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Model serving integration for pipelines |
| Ray | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Distributed computing integration for pipelines |
| ODH Dashboard | Web UI | 443/TCP | HTTPS | TLS 1.2+ | DSP UI integration in ODH Dashboard |

## Deployment Architecture

### Operator Deployment
- **Namespace**: Configured via DataScienceCluster (typically `opendatahub` or `redhat-ods-applications`)
- **Replicas**: 1 (with leader election support)
- **Resource Requirements**: Configurable via deployment manifests
- **Configuration**: Via ConfigMap loaded from file, environment variables, and params.env

### DSPA Instance Deployment
- **Namespace**: Per-DSPA namespace (user-defined)
- **Isolation**: Each DSPA instance is namespace-scoped with dedicated resources
- **Resource Quotas**: Configurable per-component via DSPA spec
- **Scaling**: Horizontal scaling not supported; multiple DSPA instances for multi-tenancy

### Storage Architecture
- **Database**: MariaDB (deployed) or external MySQL/MariaDB
- **Object Storage**: Minio (deployed, dev/test only) or external S3-compatible storage
- **Persistent Volumes**: Used for MariaDB and Minio when deployed
- **Storage Classes**: Configurable via DSPA spec

## Monitoring & Observability

### Metrics Exposed

| Metric Name | Type | Purpose |
|-------------|------|---------|
| data_science_pipelines_application_ready | Gauge | DSPA overall readiness status (1=Ready, 0=Not Ready) |
| data_science_pipelines_application_apiserver_ready | Gauge | API Server readiness (1=Ready, 0=Not Ready) |
| data_science_pipelines_application_persistenceagent_ready | Gauge | Persistence Agent readiness (1=Ready, 0=Not Ready) |
| data_science_pipelines_application_scheduledworkflow_ready | Gauge | Scheduled Workflow readiness (1=Ready, 0=Not Ready) |
| controller_runtime_* | Various | Standard controller-runtime metrics |
| workqueue_* | Various | Controller workqueue metrics |

### ServiceMonitor
- **Enabled**: Via Prometheus Operator ServiceMonitor CRD
- **Endpoint**: `/metrics` on port 8080
- **Labels**: `component: data-science-pipelines`

### Logging
- **Log Level**: Configurable via `ZAP_LOG_LEVEL` (default: info)
- **Format**: Structured JSON logging via zap
- **Timestamp Format**: RFC3339

## Configuration

### Operator Configuration
- **Images**: Configured via `config/base/params.env`
- **Max Concurrent Reconciles**: Default 10, configurable via `--MaxConcurrentReconciles` flag
- **Requeue Time**: 20s (DSPO_REQUEUE_TIME)
- **Health Check Timeouts**: 15s for DB and object storage connections
- **FIPS Mode**: Supported via GOEXPERIMENT=strictfipsruntime

### DSPA Configuration Options
- **DSP Version**: v1 (Tekton) or v2 (Argo, default)
- **Pod-to-Pod TLS**: Enable/disable mTLS between components (default: true)
- **Component Enablement**: Each component (API Server, Persistence Agent, etc.) can be enabled/disabled
- **Resource Requests/Limits**: Per-component resource configuration
- **Custom Images**: Override default images per component
- **Pipeline Store**: Database or Kubernetes (Pipeline/PipelineVersion CRDs)
- **Cache Enablement**: Enable/disable pipeline step caching (default: true)
- **Managed Pipelines**: Auto-import managed pipelines (e.g., InstructLab)

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 763811f | 2025-03 | - chore(deps): update registry.access.redhat.com/ubi9/go-toolset:1.25 docker digest to 3cdf0d1 |
| 0618512 | 2025-03 | - chore(deps): update registry.access.redhat.com/ubi9/go-toolset:1.25 docker digest to 3cdf0d1 |
| f868ba0 | 2025-03 | - sync pipelineruns with konflux-central - 19bdad4 |
| e779030 | 2025-02 | - chore(deps): update registry.access.redhat.com/ubi9/ubi-minimal docker digest to 69f5c98 |
| 3677051 | 2025-02 | - chore(deps): update registry.access.redhat.com/ubi9/go-toolset:1.25 docker digest to 6da1160 |
| e0a0c2f | 2025-02 | - chore(deps): update Go to 1.25.5 to address CVE-2025-61729 [rhoai-2.25] |
| 88d9924 | 2025-01 | - chore(deps): update registry.access.redhat.com/ubi9/ubi-minimal docker digest to c7d4414 |
| 685512d | 2025-01 | - sync pipelineruns with konflux-central - 07ea5e7 |

## Build & Release

### Container Build
- **Primary Build**: Konflux-based builds using `Dockerfile.konflux`
- **Base Image**: registry.access.redhat.com/ubi9/go-toolset:1.25 (builder)
- **Runtime Image**: registry.access.redhat.com/ubi9/ubi-minimal (runtime)
- **FIPS Compliance**: Built with strictfipsruntime tag
- **User**: Non-root user (UID 65532)

### Distribution
- **RHOAI**: Official Red Hat productized distribution
- **ODH**: Open Data Hub community distribution
- **Overlays**: Separate kustomize overlays for RHOAI and ODH in `config/overlays/`

### Testing
- **Unit Tests**: `make unittest`
- **Functional Tests**: `make functest`
- **Integration Tests**: Kind-based testing via `config/overlays/kind-tests`
- **E2E Tests**: Full pipeline execution tests in `tests/` directory

## Known Limitations & Considerations

1. **Minio Deployment**: The built-in Minio deployment is for development/testing only and not supported in production. External S3-compatible storage should be used for production deployments.

2. **ML Pipelines UI**: The upstream KFP UI is unsupported and primarily for exploration/development. Production use should integrate with ODH Dashboard.

3. **Namespace Scope**: Each DSPA instance is namespace-scoped. For multi-tenant deployments, create multiple DSPA instances in separate namespaces.

4. **Pod-to-Pod TLS**: Enabled by default in DSP v2 on OpenShift. May require additional configuration for external Kubernetes.

5. **Workflow Controller**: DSP v2 deploys a namespace-scoped Argo Workflows controller. Ensure no cluster-scoped Argo installation conflicts exist.

6. **Database Migrations**: Database schema migrations are handled automatically by the API Server on startup.

7. **Artifact Signed URLs**: Default expiry is 60 seconds for artifact download links. Configurable via `artifactSignedURLExpirySeconds`.

8. **Health Checks**: Can be disabled per-component via `disableHealthCheck` flags (useful for development/testing when external dependencies are unreachable).

## Version Compatibility

| Component | DSPO Version | Compatible Versions |
|-----------|--------------|---------------------|
| OpenShift | rhoai-2.25 | 4.11+ |
| Kubernetes | rhoai-2.25 | 1.27+ |
| Argo Workflows | rhoai-2.25 | 3.5.14 |
| Tekton Pipelines | rhoai-2.25 | 1.8+ (for DSP v1) |
| KFP SDK | rhoai-2.25 | 2.x (v2 pipelines) |
| Go | rhoai-2.25 | 1.25.5 |

## Additional Resources

- **Upstream Project**: https://github.com/kubeflow/pipelines
- **Documentation**: See `docs/` directory in repository
- **Sample Pipelines**: See `config/samples/` directory
- **Proposal Documents**: See `proposals/` directory
- **Architecture Diagrams**: Refer to upstream Kubeflow Pipelines architectural overview
