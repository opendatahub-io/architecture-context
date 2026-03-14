# Component: MLflow Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/mlflow-operator
- **Version**: rhoai-3.3 (commit 49b5d8d)
- **Distribution**: Both RHOAI and ODH
- **Languages**: Go (operator), Helm (templating)
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes operator that automates deployment and lifecycle management of MLflow experiment tracking and model registry servers.

**Detailed**: The MLflow Operator provides declarative, automated deployment of MLflow instances on Kubernetes and OpenShift platforms. It manages the complete lifecycle of MLflow servers including configuration, TLS certificate provisioning, authentication setup, storage management (both local PVC and remote S3/PostgreSQL), and integration with the ODH/RHOAI platform via Gateway API routing and OpenShift Console links. The operator uses embedded Helm charts to render Kubernetes manifests and supports dual deployment modes for OpenDataHub (opendatahub namespace) and Red Hat OpenShift AI (redhat-ods-applications namespace). Each MLflow instance provides experiment tracking, model registry, and artifact storage capabilities with Kubernetes-native authentication.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| mlflow-operator | Go Controller | Watches MLflow CRs and reconciles desired state by rendering Helm charts and applying manifests |
| Embedded Helm Chart | Template Engine | Renders Kubernetes manifests for MLflow server deployment, services, RBAC, storage, and networking |
| MLflow Server | Python Application | Provides experiment tracking, model registry, and artifact storage REST API with kubernetes-auth |
| HTTPRoute Controller | Reconciler | Creates Gateway API HTTPRoutes to expose MLflow through data-science-gateway |
| ConsoleLink Controller | Reconciler | Creates OpenShift Console application menu links for MLflow instances |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| mlflow.opendatahub.io | v1 | MLflow | Cluster | Declarative configuration for MLflow server deployments including storage, authentication, replicas, and environment settings |

### HTTP Endpoints

#### Operator Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token | Prometheus metrics for operator health and performance |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe for operator pod |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe for operator pod |

#### MLflow Server Endpoints (created instances)

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /health | GET | 8443/TCP | HTTPS | TLS 1.3 | None | Health check endpoint for liveness/readiness probes |
| /api/2.0/* | ALL | 8443/TCP | HTTPS | TLS 1.3 | Bearer Token (K8s) | MLflow REST API for experiments, runs, models, artifacts |
| /mlflow/* | GET | 8443/TCP | HTTPS | TLS 1.3 | Bearer Token (K8s) | MLflow web UI (via HTTPRoute path prefix) |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | No gRPC services exposed |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | v1.11.3+ | Yes | Cluster orchestration platform |
| Go | v1.24.6+ | Yes (build-time) | Operator compilation |
| Helm | v3 (embedded) | Yes (runtime) | Template rendering for MLflow manifests |
| MLflow | v3.6.0 | Yes (runtime) | MLflow server container image |
| PostgreSQL | 9.6+ | No | Optional remote backend/registry store for production |
| S3-compatible storage | Any | No | Optional remote artifact storage for production |
| service-ca-operator | N/A | No | Optional automatic TLS cert provisioning on OpenShift |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| data-science-gateway | Gateway API (HTTPRoute) | Routes external traffic to MLflow instances via /mlflow path prefix |
| OpenShift Console | ConsoleLink CRD | Adds MLflow links to OpenShift application menu |
| Prometheus | ServiceMonitor | Scrapes operator metrics for monitoring |
| ODH/RHOAI Dashboard | Indirect (via Gateway) | Users access MLflow through centralized gateway |

## Network Architecture

### Services

#### Operator Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | Bearer Token | Internal |

#### MLflow Instance Services (per CR)

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| mlflow | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.3 | Bearer Token | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| mlflow (HTTPRoute) | Gateway API HTTPRoute | Via data-science-gateway | 8443/TCP | HTTPS | TLS 1.3 | SIMPLE | External (via gateway) |

### Egress

#### Operator Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch MLflow CRs, create/update resources |

#### MLflow Server Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| PostgreSQL (optional) | 5432/TCP | PostgreSQL | TLS 1.2+ (optional) | Password | Backend/registry store for metadata |
| S3 API (optional) | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Access Keys | Remote artifact storage |
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | List namespaces for workspaces feature, perform self_subject_access_review |

## Security

### RBAC - Cluster Roles

#### Operator ClusterRole

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | "" | namespaces | get, list, watch |
| manager-role | mlflow.opendatahub.io | mlflows | create, delete, get, list, patch, update, watch |
| manager-role | mlflow.opendatahub.io | mlflows/status | get, patch, update |
| manager-role | mlflow.opendatahub.io | mlflows/finalizers | update |
| manager-role | rbac.authorization.k8s.io | clusterroles, clusterrolebindings | create, delete, get, list, patch, update, watch |
| manager-role | console.openshift.io | consolelinks | create, delete, get, list, patch, update, watch |
| manager-role | gateway.networking.k8s.io | httproutes | create, delete, get, list, patch, update, watch |

#### MLflow Server ClusterRole (per instance)

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| mlflow | "" | namespaces | get, list, watch |

### RBAC - Namespace Roles

#### Operator Namespace Role

| Role Name | Namespace | API Group | Resources | Verbs |
|-----------|-----------|-----------|-----------|-------|
| manager-role | opendatahub/redhat-ods-applications | "" | persistentvolumeclaims, secrets, serviceaccounts, services | create, delete, get, list, patch, update, watch |
| manager-role | opendatahub/redhat-ods-applications | apps | deployments | create, delete, get, list, patch, update, watch |
| manager-role | opendatahub/redhat-ods-applications | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-role-binding | opendatahub/redhat-ods-applications | ClusterRole/manager-role | controller-manager |
| namespace-role-binding | opendatahub/redhat-ods-applications | Role/manager-role | controller-manager |
| mlflow | opendatahub/redhat-ods-applications | ClusterRole/mlflow | mlflow-sa |
| leader-election-role-binding | opendatahub/redhat-ods-applications | Role/leader-election-role | controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| mlflow-tls | kubernetes.io/tls | TLS certificate for MLflow server HTTPS endpoint | service-ca-operator (OpenShift) or manual | Yes (OpenShift) |
| mlflow-db-credentials (optional) | Opaque | Database connection URIs with credentials | User | No |
| aws-credentials (optional) | Opaque | AWS access keys for S3 artifact storage | User | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics (operator) | GET | Bearer Token (ServiceAccount) | kube-rbac-proxy | ServiceAccount must have metrics reader role |
| /api/2.0/* (MLflow) | ALL | Bearer Token (kubernetes-auth) | MLflow server | self_subject_access_review authorization mode |
| HTTPRoute traffic | ALL | Passthrough | Gateway (TLS termination) | Gateway handles external TLS, forwards to MLflow HTTPS |

### Network Policies

| Policy Name | Namespace | Selector | Ingress Rules | Egress Rules |
|-------------|-----------|----------|---------------|--------------|
| mlflow | opendatahub/redhat-ods-applications | app=mlflow | Allow TCP/8443 from all namespaces | Allow all destinations/ports |

## Data Flows

### Flow 1: User Access to MLflow via Gateway

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | data-science-gateway (openshift-ingress) | 443/TCP | HTTPS | TLS 1.3 | Bearer Token (K8s) |
| 2 | data-science-gateway | mlflow Service (HTTPRoute backend) | 8443/TCP | HTTPS | TLS 1.3 | Bearer Token (forwarded) |
| 3 | mlflow Service | mlflow Pod | 8443/TCP | HTTPS | TLS 1.3 | Bearer Token (forwarded) |
| 4 | mlflow Pod | Kubernetes API (auth check) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: MLflow Operator Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Operator Pod | Kubernetes API (watch MLflow CRs) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Operator Pod (Helm renderer) | Local filesystem (charts/mlflow) | N/A | N/A | N/A | N/A |
| 3 | Operator Pod | Kubernetes API (create/update resources) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 3: MLflow Artifact Storage (Remote S3)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User (MLflow client) | MLflow Server | 8443/TCP | HTTPS | TLS 1.3 | Bearer Token |
| 2 | MLflow Server | S3 API Endpoint | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Access Keys |

### Flow 4: MLflow Backend Store (Remote PostgreSQL)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | MLflow Server | PostgreSQL Database | 5432/TCP | PostgreSQL | TLS 1.2+ (optional) | Username/Password |

### Flow 5: Prometheus Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | controller-manager-metrics-service | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token (ServiceAccount) |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API | REST API | 6443/TCP | HTTPS | TLS 1.2+ | CRD management, resource reconciliation, RBAC enforcement |
| data-science-gateway | Gateway API (HTTPRoute) | 8443/TCP | HTTPS | TLS 1.3 | External traffic routing to MLflow instances |
| OpenShift Console | ConsoleLink CRD | N/A | N/A | N/A | Application menu integration for easy access |
| Prometheus | ServiceMonitor | 8443/TCP | HTTPS | TLS 1.2+ | Operator metrics scraping |
| service-ca-operator | Annotation-based | N/A | N/A | N/A | Automatic TLS certificate injection for MLflow services |
| PostgreSQL (optional) | PostgreSQL protocol | 5432/TCP | PostgreSQL | TLS 1.2+ | Metadata storage (backend/registry stores) |
| S3 API (optional) | REST API | 443/TCP | HTTPS | TLS 1.2+ | Artifact storage |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 49b5d8d | 2026-03 | - Merge Dockerfile digest updates<br>- Update UBI9 base images |
| 6e4d6ca | 2026-03 | - Update go-toolset digest to 3cdf0d1 |
| 930925f | 2026-03 | - Update ubi-minimal digest to 69f5c98 |
| dc9a34d | 2026-02 | - Add support for tracing APIs<br>- New observability features |
| 0def308 | 2026-02 | - Sync pipelineruns with konflux-central |
| 55b38db | 2026-02 | - Dependency updates for security patches |
| 68150f1 | 2026-02 | - Container image security updates |
| 5337d9d | 2026-02 | - Build toolchain updates |

## Deployment Modes

### RHOAI Mode
- **Namespace**: redhat-ods-applications
- **Target Users**: Red Hat OpenShift AI customers
- **Deployment**: `kustomize build config/overlays/rhoai | kubectl apply -f -`

### OpenDataHub Mode
- **Namespace**: opendatahub
- **Target Users**: Open Data Hub community users
- **Deployment**: `kustomize build config/overlays/odh | kubectl apply -f -`

## Storage Configurations

### Local Storage (Development)
- **Backend Store**: sqlite:////mlflow/mlflow.db
- **Registry Store**: sqlite:////mlflow/mlflow.db
- **Artifacts**: file:///mlflow/artifacts
- **PVC**: Required, default 2Gi
- **Serve Artifacts**: Required (true)

### Remote Storage (Production)
- **Backend Store**: postgresql://user:pass@host:5432/mlflow (via secret)
- **Registry Store**: postgresql://user:pass@host:5432/mlflow (via secret)
- **Artifacts**: s3://bucket/path
- **PVC**: Not required
- **Serve Artifacts**: Optional (can be false for direct client access)

## Key Configuration Parameters

| Parameter | Type | Default | Purpose |
|-----------|------|---------|---------|
| MLFLOW_IMAGE | Environment Variable | quay.io/opendatahub/mlflow:master | Default MLflow container image |
| GATEWAY_NAME | Environment Variable | data-science-gateway | Gateway resource name for HTTPRoute |
| MLFLOW_URL | Environment Variable | https://mlflow.example.com | External URL for ConsoleLink |
| SECTION_TITLE | Environment Variable | MLflow | OpenShift Console section title |
| namespace | CLI Flag | opendatahub | Target namespace for MLflow deployments |

## Health & Monitoring

### Operator Health Probes
- **Liveness**: HTTP GET :8081/healthz (15s initial delay, 20s period)
- **Readiness**: HTTP GET :8081/readyz (5s initial delay, 10s period)

### MLflow Server Health Probes
- **Liveness**: HTTPS GET :8443/health (30s initial delay, 10s period)
- **Readiness**: HTTPS GET :8443/health (5s initial delay, 5s period)

### Metrics
- **Operator Metrics**: Exposed at :8443/metrics (HTTPS, bearer token auth)
- **ServiceMonitor**: Prometheus scrapes operator metrics automatically

## Resource Requirements

### Operator Pod
- **CPU Request**: 200m
- **CPU Limit**: 1 core
- **Memory Request**: 400Mi
- **Memory Limit**: 4Gi

### MLflow Server Pod (default)
- **CPU Request**: 250m
- **CPU Limit**: 1 core
- **Memory Request**: 512Mi
- **Memory Limit**: 1Gi
- **Storage**: 2Gi (if using local storage)

## Security Features

1. **TLS Everywhere**: Operator metrics and MLflow server use HTTPS/TLS
2. **Non-Root Containers**: All containers run as non-root users (UID 1001)
3. **Read-Only Root Filesystem**: Operator uses read-only root filesystem
4. **No Privilege Escalation**: allowPrivilegeEscalation: false
5. **Capabilities Dropped**: All Linux capabilities dropped from operator
6. **Seccomp Profile**: RuntimeDefault seccomp profile enforced
7. **Network Policies**: Ingress restricted to port 8443 only
8. **Kubernetes-Native Auth**: Bearer token authentication with RBAC
9. **Secret References**: Database credentials stored in Kubernetes secrets
10. **Service CA Integration**: Automatic cert rotation on OpenShift
