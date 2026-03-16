# Component: Data Science Pipelines Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/data-science-pipelines-operator
- **Version**: cf823f3 (rhoai-2.9 branch)
- **Distribution**: RHOAI, ODH
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes operator that deploys and manages Data Science Pipelines (DSP) instances for ML workflow orchestration.

**Detailed**: The Data Science Pipelines Operator (DSPO) is a Kubernetes operator that enables data scientists to deploy namespace-scoped Data Science Pipelines instances on OpenShift/Kubernetes clusters. Based on upstream Kubeflow Pipelines (KFP), it provides ML workflow orchestration capabilities with support for both Tekton (v1) and Argo Workflows (v2) backends. The operator manages the complete lifecycle of DSP components including API servers, persistence agents, workflow controllers, metadata tracking (MLMD), and optional UI components. It supports flexible deployment configurations with built-in MariaDB/Minio for development or external database/object storage for production environments. DSPO allows data scientists to create, track, and manage ML experiments, pipeline runs, and artifacts through declarative DataSciencePipelinesApplication (DSPA) custom resources.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| DSPO Controller Manager | Operator | Reconciles DataSciencePipelinesApplication CRs and manages DSP component lifecycle |
| API Server | Service | REST/gRPC API for pipeline creation, execution, and management |
| Persistence Agent | Controller | Syncs workflow status to database for pipeline run tracking |
| Scheduled Workflow Controller | Controller | Manages cron-based recurring pipeline executions |
| Workflow Controller | Controller | Argo-specific controller for managing workflow execution (DSP v2 only) |
| MariaDB | Database | Optional built-in metadata storage (development use) |
| Minio | Object Storage | Optional built-in artifact storage (development use) |
| ML Metadata (MLMD) gRPC | Service | ML metadata tracking and lineage service |
| ML Metadata Envoy Proxy | Proxy | OAuth2 proxy for MLMD gRPC service with TLS termination |
| ML Pipelines UI | Frontend | Optional KFP UI for pipeline visualization (unsupported, dev/test only) |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencepipelinesapplications.opendatahub.io | v1alpha1 | DataSciencePipelinesApplication | Namespaced | Defines a complete DSP stack deployment including API server, database, object storage, and optional components |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /apis/v1beta1/* | GET/POST/DELETE | 8888/TCP | HTTP | None | Internal only | DSP API server REST endpoints for pipeline management |
| /apis/v1beta1/healthz | GET | 8888/TCP | HTTP | None | None | API server health check endpoint |
| / | GET/POST | 8443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | OAuth (OpenShift) | API server external access via OAuth proxy |
| /metrics | GET | 8080/TCP | HTTP | None | None | Operator Prometheus metrics endpoint |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator health check endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness check endpoint |
| /oauth/healthz | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | OAuth proxy health check |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ds-pipeline | 8887/TCP | gRPC | None | Internal only | DSP API server gRPC for pipeline operations |
| ds-pipeline-metadata-grpc | 8080/TCP (configurable) | gRPC | None | Internal only | ML Metadata tracking and lineage service |
| ds-pipeline-metadata-envoy | 9090/TCP | gRPC | mTLS | Service-serving-cert | MLMD gRPC with Envoy proxy and OAuth2 authentication |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| OpenShift/Kubernetes | 4.11+ | Yes | Platform for operator deployment |
| OpenShift Pipelines (Tekton) | 1.8+ | Conditional | Required for DSP v1 pipeline execution |
| Argo Workflows | Latest | Conditional | Required for DSP v2 pipeline execution |
| MariaDB/MySQL | 10.3+ | Conditional | External database option for metadata storage |
| S3-compatible Object Storage | N/A | Conditional | External storage option for pipeline artifacts |
| cert-manager or service-serving-cert | N/A | Yes | TLS certificate provisioning for service mesh |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | UI Integration | Provides user interface for pipeline interaction |
| OpenShift OAuth | Authentication | User authentication for API access |
| OpenShift Service Mesh | Service Mesh | mTLS, network policies, and service discovery |
| Prometheus Operator | Monitoring | Metrics collection via ServiceMonitor |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| ds-pipeline-{name} | ClusterIP | 8443/TCP | oauth | HTTPS | TLS 1.2+ (service-serving-cert) | OAuth | External via Route |
| ds-pipeline-{name} | ClusterIP | 8888/TCP | http | HTTP | None | Internal | Internal |
| ds-pipeline-{name} | ClusterIP | 8887/TCP | 8887 | gRPC | None | Internal | Internal |
| ds-pipeline-metadata-grpc-{name} | ClusterIP | 8080/TCP (configurable) | grpc-api | gRPC | None | Internal | Internal |
| ds-pipeline-metadata-envoy-{name} | ClusterIP | 9090/TCP | md-envoy | gRPC | mTLS | Service-serving-cert | Internal |
| ds-pipeline-metadata-envoy-{name} | ClusterIP | 8443/TCP | oauth2-proxy | HTTPS | TLS 1.2+ | OAuth2 | Internal |
| ds-pipeline-ui-{name} | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | OAuth | External via Route |
| mariadb-{name} | ClusterIP | 3306/TCP | 3306 | TCP | None | Password | Internal |
| minio-{name} | ClusterIP | 9000/TCP | 9000 | HTTP | None | Access Key | Internal |
| ds-pipeline-workflow-controller-metrics-{name} | ClusterIP | 9090/TCP | 9090 | HTTP | None | None | Internal |
| controller-manager service | ClusterIP | 8080/TCP | metrics | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| ds-pipeline-{name} | OpenShift Route | Auto-generated | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |
| ds-pipeline-ui-{name} | OpenShift Route | Auto-generated | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |
| ds-pipeline-metadata-envoy-{name} | OpenShift Route | Auto-generated | 9090/TCP | HTTPS | TLS 1.2+ | Reencrypt | External (optional) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| External S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Access Keys | Pipeline artifact storage |
| External Database | 3306/TCP or 5432/TCP | TCP | TLS (optional) | Username/Password | Pipeline metadata storage |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secrets | Pull component container images |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications, datasciencepipelinesapplications/status, datasciencepipelinesapplications/finalizers | create, delete, get, list, patch, update, watch |
| manager-role | apps, "", extensions | deployments, replicasets | * |
| manager-role | "" | services, configmaps, secrets, serviceaccounts, persistentvolumeclaims, persistentvolumes, pods, pods/exec, pods/log, events | create, delete, get, list, patch, update, watch |
| manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| manager-role | rbac.authorization.k8s.io | roles, rolebindings, clusterroles, clusterrolebindings | create, delete, get, list, patch, update, watch |
| manager-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| manager-role | argoproj.io | workflows, workflowtaskresults | * |
| manager-role | tekton.dev | * | * |
| manager-role | monitoring.coreos.com | servicemonitors | create, delete, get, list, patch, update, watch |
| manager-role | authentication.k8s.io | tokenreviews | create |
| manager-role | authorization.k8s.io | subjectaccessreviews | create |
| manager-role | image.openshift.io | imagestreamtags | get |
| ds-pipeline-user-access-{name} | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications | get |
| ds-pipeline-{name} | argoproj.io | workflows, workflowtaskresults | create, get, list, watch, update, patch, delete |
| ds-pipeline-{name} | "" | pods, pods/exec, pods/log, services | create, get, list, watch, update, patch, delete |
| pipeline-runner-{name} | argoproj.io | workflows | get, list, watch |
| pipeline-runner-{name} | "" | pods, pods/log | get, list |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | operator-namespace | manager-role | controller-manager |
| leader-election-rolebinding | operator-namespace | leader-election-role | controller-manager |
| ds-pipeline-{name} | dspa-namespace | ds-pipeline-{name} | ds-pipeline-{name} |
| pipeline-runner-{name} | dspa-namespace | pipeline-runner-{name} | pipeline-runner-{name} |
| ds-pipeline-argo-{name} | dspa-namespace | ds-pipeline-argo-{name} | ds-pipeline-workflow-controller-{name} |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| ds-pipelines-proxy-tls-{name} | kubernetes.io/tls | API server OAuth proxy TLS certificate | service-serving-cert | Yes |
| ds-pipelines-ui-proxy-tls-{name} | kubernetes.io/tls | UI OAuth proxy TLS certificate | service-serving-cert | Yes |
| ds-pipelines-envoy-proxy-tls-{name} | kubernetes.io/tls | MLMD Envoy proxy TLS certificate | service-serving-cert | Yes |
| {custom-db-secret} | Opaque | Database credentials (username, password) | User-provided or auto-generated | No |
| {custom-storage-secret} | Opaque | Object storage credentials (access key, secret key) | User-provided or auto-generated | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /apis/v1beta1/* (external) | GET, POST, DELETE | OpenShift OAuth | OAuth Proxy | User must have route GET permission in namespace |
| /apis/v1beta1/* (internal) | GET, POST, DELETE | Service Account Token | API Server | Service account RBAC |
| gRPC API | * | Service Account Token | API Server | Service account RBAC |
| MLMD Envoy | * | OAuth2 Proxy + mTLS | Envoy Proxy | Service mesh authentication |
| /metrics | GET | None | Network Policy | Restricted to monitoring namespaces |

### Network Policies

| Policy Name | Pod Selector | Ingress From | Ports | Purpose |
|-------------|--------------|--------------|-------|---------|
| ds-pipelines-{name} | app=ds-pipeline-{name} | All sources | 8443/TCP | Allow OAuth proxy access from external |
| ds-pipelines-{name} | app=ds-pipeline-{name} | Monitoring namespaces, DSPA components, workbenches, pipeline pods | 8888/TCP, 8887/TCP | Restrict internal API access to authorized pods |

## Data Flows

### Flow 1: User Submits Pipeline via Dashboard

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | ODH Dashboard | ds-pipeline-{name} Route | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (OAuth) |
| 2 | OAuth Proxy | API Server | 8888/TCP | HTTP | None | Token validation |
| 3 | API Server | MariaDB | 3306/TCP | TCP | None (or TLS) | DB credentials |
| 4 | API Server | Workflow Controller (v2) or Tekton (v1) | 8080/TCP | HTTP | None | Service Account |

### Flow 2: Pipeline Execution and Artifact Storage

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Workflow Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 2 | Pipeline Pod | API Server | 8887/TCP | gRPC | None | Service Account Token |
| 3 | Pipeline Pod | S3 Storage (Minio or external) | 9000/TCP or 443/TCP | HTTP/HTTPS | TLS (if external) | Access Key/Secret Key |
| 4 | Persistence Agent | API Server | 8888/TCP | HTTP | None | Service Account Token |
| 5 | Persistence Agent | MariaDB | 3306/TCP | TCP | None (or TLS) | DB credentials |

### Flow 3: ML Metadata Tracking

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Pipeline Pod | API Server | 8887/TCP | gRPC | None | Service Account Token |
| 2 | API Server | MLMD gRPC | 8080/TCP | gRPC | None | Internal |
| 3 | MLMD gRPC | MariaDB | 3306/TCP | TCP | None (or TLS) | DB credentials |
| 4 | ODH Dashboard | MLMD Envoy Route | 443/TCP | HTTPS | TLS 1.2+ | OAuth2 |
| 5 | Envoy Proxy | MLMD gRPC | 8080/TCP | gRPC | None | Internal |

### Flow 4: Scheduled Pipeline Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Scheduled Workflow Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 2 | Scheduled Workflow Controller | API Server | 8888/TCP | HTTP | None | Service Account Token |
| 3 | API Server | Workflow Controller | 8080/TCP | HTTP | None | Service Account |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Argo Workflows (v2) | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Workflow execution backend for DSP v2 |
| Tekton Pipelines (v1) | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | PipelineRun execution backend for DSP v1 |
| ODH Dashboard | REST API | 8443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | User interface for pipeline management |
| Prometheus Operator | Metrics scrape | 8080/TCP | HTTP | None | Operator metrics collection |
| OpenShift OAuth | OAuth | 443/TCP | HTTPS | TLS 1.2+ | User authentication |
| MariaDB/MySQL | SQL | 3306/TCP | TCP | TLS (optional) | Metadata persistence |
| S3 Storage | S3 API | 9000/TCP or 443/TCP | HTTP/HTTPS | TLS (production) | Artifact storage |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| cf823f3 | 2024 | - Merge pull request #56 from HumairAK/rhoai-2.9 |
| 4549c32 | 2024 | - Add SHAs for UBI images |
| 2b07c71 | 2024 | - Add oauth2-proxy in mlmd envoy proxy pod |
| c103f8f | 2024 | - Merge pull request #619 from DharmitD/update-nb-label |
| 4dda89c | 2024 | - Merge pull request #618 from rimolive/rmartine |
| 76ce525 | 2024 | - Remove unnecessary DSPO parameters |
| c3902a8 | 2024 | - Adding exclusive notebook pod label |
| 61a2209 | 2024 | - Merge pull request #617 from HumairAK/fix_make_functest |
| 0eae400 | 2024 | - Add SSL env to functest |
| 7228357 | 2024 | - Merge pull request #616 from HumairAK/add_params_unittest |
| 0613258 | 2024 | - Pin envtest version |
| b13228d | 2024 | - Replace deprecated calls |
| fb4fe2f | 2024 | - Handle empty syscert and remove unused args |
| cb67134 | 2024 | - Add unittest for extract params cabundle |
| b80afc2 | 2024 | - Merge pull request #614 from HumairAK/RHOAIENG-4709 |
| db78e2b | 2024 | - Merge pull request #615 from VaniHaripriya/RHOAIENG-1676-Fix |
| 0a6a268 | 2024 | - Add integration tests for external storage/db connections |
| 7cab923 | 2024 | - Update func tests for sys certs |
| e5d8a84 | 2024 | - Add system certs when not present |
| 259315b | 2024 | - Merge pull request #589 from DharmitD/testify |

## Component Images

### DSP v1 (Tekton-based)
- **API Server**: quay.io/opendatahub/ds-pipelines-api-server:v1.6.3
- **Persistence Agent**: quay.io/opendatahub/ds-pipelines-persistenceagent:v1.6.3
- **Scheduled Workflow**: quay.io/opendatahub/ds-pipelines-scheduledworkflow:v1.6.3
- **Artifact Manager**: quay.io/opendatahub/ds-pipelines-artifact-manager:v1.6.3
- **MLMD Envoy**: quay.io/opendatahub/ds-pipelines-metadata-envoy:v1.6.3
- **MLMD gRPC**: quay.io/opendatahub/ds-pipelines-metadata-grpc:v1.6.3
- **MLMD Writer**: quay.io/opendatahub/ds-pipelines-metadata-writer:v1.6.3

### DSP v2 (Argo-based)
- **API Server**: quay.io/opendatahub/ds-pipelines-api-server:latest
- **Persistence Agent**: quay.io/opendatahub/ds-pipelines-persistenceagent:latest
- **Scheduled Workflow**: quay.io/opendatahub/ds-pipelines-scheduledworkflow:latest
- **Workflow Controller**: quay.io/opendatahub/ds-pipelines-argo-workflowcontroller:3.3.10-upstream
- **Argo Executor**: quay.io/opendatahub/ds-pipelines-argo-argoexec:3.3.10-upstream
- **Launcher**: quay.io/opendatahub/ds-pipelines-launcher:latest
- **Driver**: quay.io/opendatahub/ds-pipelines-driver:latest
- **MLMD Envoy**: registry.redhat.io/openshift-service-mesh/proxyv2-rhel8@sha256:a744c1b386fd5e4f94e43543e829df1bfdd1b564137917372a11da06872f4bcb
- **MLMD gRPC**: quay.io/opendatahub/mlmd-grpc-server:latest

### Supporting Components
- **OAuth Proxy**: registry.redhat.io/openshift4/ose-oauth-proxy@sha256:ab112105ac37352a2a4916a39d6736f5db6ab4c29bad4467de8d613e80e9bb33
- **MariaDB**: registry.redhat.io/rhel8/mariadb-103@sha256:3d30992e60774f887c4e7959c81b0c41b0d82d042250b3b56f05ab67fd4cdee1
- **Cache Image**: registry.redhat.io/ubi8/ubi-minimal@sha256:5d2d4d4dbec470f8ffb679915e2a8ae25ad754cd9193fa966deee1ecb7b3ee00
- **Move Results Image**: registry.redhat.io/ubi8/ubi-micro@sha256:396baed3d689157d96aa7d8988fdfea7eb36684c8335eb391cf1952573e689c1

## Deployment Configuration

### Operator Configuration
- **Namespace**: datasciencepipelinesapplications-controller (standalone) or opendatahub/redhat-ods-applications (via ODH)
- **Replicas**: 1 (leader election enabled)
- **Max Concurrent Reconciles**: 10 (configurable)
- **Requeue Time**: 20s
- **Log Level**: info (configurable via ZAP_LOG_LEVEL)
- **Health Check Timeouts**: Database: 15s, Object Store: 15s

### DSPA Instance Configuration
Per-namespace deployment via DataSciencePipelinesApplication CR:
- **API Server**: Always deployed (default: true)
- **Persistence Agent**: Always deployed (default: true)
- **Scheduled Workflow**: Always deployed (default: true)
- **Workflow Controller**: Conditional (v2 only, default: true)
- **MariaDB**: Optional (mutually exclusive with external DB)
- **Minio**: Optional (mutually exclusive with external storage)
- **MLMD**: Optional (default: false)
- **UI**: Optional (unsupported, dev/test only)

## Notes

- **Multi-version Support**: Operator supports both DSP v1 (Tekton) and v2 (Argo Workflows) backends via `spec.dspVersion`
- **Production Deployments**: Built-in MariaDB and Minio are for development only; production should use external database and S3-compatible storage
- **Network Isolation**: Network policies enforce strict pod-to-pod communication; external access only via OAuth-protected routes
- **Certificate Management**: TLS certificates auto-provisioned via OpenShift service-serving-cert annotation
- **Health Checks**: Configurable database and object storage health checks can be disabled for development
- **Custom CA Bundles**: Supports custom CA bundles for TLS connections to external databases/object stores
- **Metrics**: Exposes custom metrics for DSPA component readiness (apiserver, persistence agent, scheduled workflow)
- **Sample Pipelines**: Optional sample pipeline deployment for testing (disabled by default)
