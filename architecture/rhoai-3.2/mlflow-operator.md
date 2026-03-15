# Component: MLflow Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/mlflow-operator
- **Version**: cd9ad05 (rhoai-3.2 branch)
- **Distribution**: RHOAI and ODH
- **Languages**: Go 1.24.6
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes operator for automated deployment and lifecycle management of MLflow experiment tracking and model registry instances.

**Detailed**: The MLflow Operator provides declarative, Kubernetes-native management of MLflow deployments on OpenShift and Kubernetes clusters. It uses Helm charts internally to render and apply Kubernetes manifests, offering a Custom Resource API for MLflow configuration. The operator supports both RHOAI (deploying to `redhat-ods-applications`) and OpenDataHub (deploying to `opendatahub`) modes. MLflow instances deployed by the operator include built-in Kubernetes authentication using `self_subject_access_review`, TLS termination within the MLflow container via uvicorn, and automatic certificate provisioning on OpenShift via service-ca-operator. The operator enables flexible storage configurations including local PVC-based storage for development or remote storage (PostgreSQL databases and S3-compatible object storage) for production deployments, with support for the MLflow workspaces feature to organize experiments by Kubernetes namespace.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| mlflow-operator | Go Operator (controller-runtime) | Reconciles MLflow CRs and manages MLflow instance lifecycle |
| mlflow-operator-manager | Deployment | Runs the operator controller manager with leader election |
| mlflow instances | MLflow Server (Python/uvicorn) | MLflow tracking server with kubernetes-auth, TLS, and workspace support |
| Helm chart renderer | Embedded Helm library (helm.sh/helm/v3) | Renders MLflow Helm charts to Kubernetes manifests |
| ConsoleLink manager | Operator subcontroller | Creates OpenShift console links for MLflow instances |
| HTTPRoute manager | Operator subcontroller | Creates Gateway API routes for MLflow instances |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| mlflow.opendatahub.io | v1 | MLflow | Cluster | Declarative configuration for MLflow instances including storage, authentication, and scaling |

### HTTP Endpoints

#### Operator Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token (ServiceAccount) | Prometheus metrics for operator health and reconciliation stats |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness probe |

#### MLflow Instance Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /api/* | ALL | 8443/TCP | HTTPS | TLS 1.3 | Bearer Token (k8s-auth) | MLflow REST API for experiments, runs, models, and artifacts |
| /health | GET | 8443/TCP | HTTPS | TLS 1.3 | None | MLflow instance health check |
| /* | GET | 8443/TCP | HTTPS | TLS 1.3 | Bearer Token (k8s-auth) | MLflow web UI for experiment tracking and model registry |

### gRPC Services

None - MLflow uses HTTP REST API only.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.11.3+ | Yes | Platform for operator and MLflow deployment |
| OpenShift (optional) | 4.x | No | Provides service-ca for automatic TLS cert provisioning and ConsoleLink CRD |
| PostgreSQL (optional) | 9.6+ | No | Remote backend/registry store for production deployments |
| S3-compatible storage (optional) | N/A | No | Remote artifact storage for production deployments |
| Gateway API | v1 | No | HTTPRoute support for ingress routing (optional) |
| Prometheus Operator | v1 | No | ServiceMonitor for operator metrics collection |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| service-ca-operator (OpenShift) | TLS Secret Injection | Automatic provisioning of TLS certificates for MLflow Service via annotation |
| Gateway (OpenShift/ODH) | HTTPRoute | Ingress routing to MLflow instances through shared gateway |
| OpenShift Console | ConsoleLink | Application menu integration for MLflow instances |

## Network Architecture

### Services

#### Operator Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | Bearer Token | Internal (Prometheus) |

#### MLflow Instance Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| mlflow | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.3 | Bearer Token | Internal (routed via HTTPRoute) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| mlflow (HTTPRoute) | Gateway API HTTPRoute | gateway-host/mlflow | 8443/TCP | HTTPS | TLS 1.3 | Passthrough | External (via Gateway) |

### Egress

#### Operator Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | CRD/resource management, RBAC operations |

#### MLflow Instance Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| PostgreSQL (optional) | 5432/TCP | PostgreSQL | TLS 1.2+ (optional) | DB Credentials | Backend/registry store connections |
| S3 (optional) | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Access Keys | Artifact storage operations |
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Namespace listing for workspaces, self_subject_access_review auth |

### Network Policies

| Policy Name | Pod Selector | Ingress Rules | Egress Rules | Purpose |
|-------------|--------------|---------------|--------------|---------|
| mlflow | app=mlflow | Allow 8443/TCP from all | Allow all | Allow HTTPS ingress to MLflow, unrestricted egress for DB/S3/API access |

## Security

### RBAC - Cluster Roles

#### Operator ClusterRole

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | mlflow.opendatahub.io | mlflows, mlflows/status, mlflows/finalizers | get, list, watch, create, update, patch, delete |
| manager-role | "" | namespaces | get, list, watch |
| manager-role | rbac.authorization.k8s.io | clusterroles, clusterrolebindings | get, list, watch, create, update, patch, delete |
| manager-role | console.openshift.io | consolelinks | get, list, watch, create, update, patch, delete |
| manager-role | gateway.networking.k8s.io | httproutes | get, list, watch, create, update, patch, delete |

#### MLflow Instance ClusterRole

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| mlflow | "" | namespaces | get, list, watch |

#### Aggregate Roles

| Role Name | API Group | Resources | Verbs | Aggregates To |
|-----------|-----------|-----------|-------|---------------|
| mlflow-view | mlflow.opendatahub.io | mlflows, mlflows/status | get, list, watch | view, edit, admin |
| mlflow-edit | mlflow.opendatahub.io | mlflows, mlflows/finalizers | create, delete, deletecollection, patch, update | edit, admin |

### RBAC - Namespace Roles

#### Operator Namespace Role

| Role Name | Namespace | API Group | Resources | Verbs |
|-----------|-----------|-----------|-----------|-------|
| manager-role | redhat-ods-applications (RHOAI) or opendatahub (ODH) | "" | serviceaccounts, services, secrets, persistentvolumeclaims | get, list, watch, create, update, patch, delete |
| manager-role | redhat-ods-applications (RHOAI) or opendatahub (ODH) | apps | deployments | get, list, watch, create, update, patch, delete |
| manager-role | redhat-ods-applications (RHOAI) or opendatahub (ODH) | networking.k8s.io | networkpolicies | get, list, watch, create, update, patch, delete |

### RBAC - Role Bindings

#### Operator ClusterRoleBindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | N/A (cluster-scoped) | manager-role (ClusterRole) | controller-manager (operator namespace) |

#### Operator Namespace RoleBindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | redhat-ods-applications (RHOAI) or opendatahub (ODH) | manager-role (Role) | controller-manager (operator namespace) |

#### MLflow Instance ClusterRoleBindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| mlflow | N/A (cluster-scoped) | mlflow (ClusterRole) | mlflow-sa (instance namespace) |

### Secrets

#### Operator Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| controller-manager-token | kubernetes.io/service-account-token | Operator ServiceAccount token | Kubernetes | Yes |

#### MLflow Instance Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| mlflow-tls | kubernetes.io/tls | TLS certificate and key for HTTPS | service-ca-operator (OpenShift) or manual | Yes (OpenShift) / No (manual) |
| mlflow-sa-token | kubernetes.io/service-account-token | MLflow ServiceAccount token for k8s API access | Kubernetes | Yes |
| mlflow-db-credentials (optional) | Opaque | Database connection URIs with credentials | User/External | No |
| aws-credentials (optional) | Opaque | S3 access credentials (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY) | User/External | No |

### Authentication & Authorization

#### Operator Authentication

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | Bearer Token (ServiceAccount) | kube-rbac-proxy or ServiceMonitor | Prometheus ServiceAccount must have metrics-reader role |
| /healthz, /readyz | GET | None | None | Publicly accessible for probes |
| Kubernetes API | ALL | ServiceAccount Token | Kubernetes API Server | manager-role ClusterRole + namespace Role permissions |

#### MLflow Instance Authentication

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /api/*, / | ALL | Bearer Token (Kubernetes) | MLflow kubernetes-auth app | self_subject_access_review - caller token validated by k8s API, no special RBAC required |
| /health | GET | None | MLflow | Public health check endpoint |

### Pod Security

#### Operator Pod Security

| Setting | Value | Purpose |
|---------|-------|---------|
| runAsNonRoot | true | Prevent root execution |
| seccompProfile | RuntimeDefault | Apply default seccomp profile |
| readOnlyRootFilesystem | true | Prevent filesystem writes |
| allowPrivilegeEscalation | false | Prevent privilege escalation |
| capabilities | DROP ALL | Remove all Linux capabilities |

#### MLflow Instance Pod Security

| Setting | Value | Purpose |
|---------|-------|---------|
| runAsNonRoot | true | Prevent root execution |
| seccompProfile | RuntimeDefault | Apply default seccomp profile |
| readOnlyRootFilesystem | false | Allow SQLite writes to /mlflow (when using PVC) |
| allowPrivilegeEscalation | false | Prevent privilege escalation |

## Data Flows

### Flow 1: MLflow Instance Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | User Bearer Token |
| 2 | Kubernetes API | mlflow-operator | N/A | Controller Watch | N/A | N/A (internal watch) |
| 3 | mlflow-operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | mlflow-operator | service-ca-operator (OpenShift) | N/A | Annotation-triggered | N/A | N/A (annotation) |
| 5 | service-ca-operator | mlflow-tls Secret | N/A | Secret Creation | N/A | N/A (internal) |

### Flow 2: MLflow API Request (User → MLflow)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | Gateway (HTTPRoute) | 443/TCP | HTTPS | TLS 1.3 | Bearer Token (in header) |
| 2 | Gateway | mlflow Service | 8443/TCP | HTTPS | TLS 1.3 | Bearer Token (forwarded) |
| 3 | mlflow Service | mlflow Pod | 8443/TCP | HTTPS | TLS 1.3 | Bearer Token (forwarded) |
| 4 | mlflow Pod | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Client Bearer Token (self_subject_access_review) |

### Flow 3: MLflow → PostgreSQL (Backend Store)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | mlflow Pod | PostgreSQL | 5432/TCP | PostgreSQL | TLS 1.2+ (optional) | DB Credentials (from secret) |

### Flow 4: MLflow → S3 (Artifact Storage)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | mlflow Pod | S3 Endpoint | 443/TCP | HTTPS | TLS 1.2+ | AWS Signature v4 (from secret) |

### Flow 5: Prometheus Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | controller-manager-metrics-service | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token (ServiceAccount) |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | CRD management, resource reconciliation, RBAC operations |
| service-ca-operator (OpenShift) | Annotation-based | N/A | N/A | N/A | Automatic TLS certificate injection for MLflow Service |
| Gateway API | HTTPRoute CRD | N/A | N/A | N/A | Ingress routing configuration for MLflow instances |
| OpenShift Console | ConsoleLink CRD | N/A | N/A | N/A | Application menu integration for MLflow UI access |
| Prometheus | ServiceMonitor | 8443/TCP | HTTPS | TLS 1.2+ | Operator metrics collection and monitoring |
| PostgreSQL (optional) | PostgreSQL Protocol | 5432/TCP | PostgreSQL | TLS 1.2+ (optional) | Backend and registry store for MLflow metadata |
| S3 (optional) | S3 REST API | 443/TCP | HTTPS | TLS 1.2+ | Artifact storage for MLflow models and files |
| Container Registry | OCI Registry API | 443/TCP | HTTPS | TLS 1.2+ | MLflow and operator image distribution |

## Deployment Configuration

### Kustomize Overlays

| Overlay | Target Namespace | Mode | Purpose |
|---------|------------------|------|---------|
| config/overlays/rhoai | redhat-ods-applications | RHOAI | Production RHOAI deployment with specific image references |
| config/overlays/odh | opendatahub | OpenDataHub | OpenDataHub deployment with community image references |
| config/overlays/openshift | system (configurable) | OpenShift | Generic OpenShift deployment with service-ca and metrics patches |
| config/overlays/dev | system (configurable) | Development | Development overlay for local testing |

### Environment Variables (Operator)

| Variable | Default | Purpose |
|----------|---------|---------|
| MLFLOW_IMAGE | (from overlay) | Default MLflow container image for instances |
| GATEWAY_NAME | (from overlay) | Gateway name for HTTPRoute creation |
| MLFLOW_URL | (from overlay) | Base URL for ConsoleLink href construction |
| SECTION_TITLE | (from overlay) | Console application menu section title |

### Environment Variables (MLflow Instance)

| Variable | Default | Purpose |
|----------|---------|---------|
| MLFLOW_BACKEND_STORE_URI | sqlite:////mlflow/mlflow.db | Backend store URI (from spec or secretRef) |
| MLFLOW_REGISTRY_STORE_URI | (inherits backend) | Registry store URI (from spec or secretRef) |
| MLFLOW_K8S_AUTH_AUTHORIZATION_MODE | self_subject_access_review | Kubernetes auth mode for MLflow |
| MLFLOW_LOGGING_LEVEL | INFO | MLflow logging level |
| AWS_ACCESS_KEY_ID (optional) | (from secret) | S3 access key for artifact storage |
| AWS_SECRET_ACCESS_KEY (optional) | (from secret) | S3 secret key for artifact storage |
| AWS_DEFAULT_REGION (optional) | (from spec) | S3 region for artifact storage |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| cd9ad05 | 2026-03 | - Update registry.access.redhat.com/ubi9/go-toolset Docker digest to 82b82ec |
| a6e53fe | 2026-03 | - Update registry.access.redhat.com/ubi9/go-toolset Docker digest to 6983c6e |
| 53e32e0 | 2026-03 | - Update registry.access.redhat.com/ubi9/ubi-minimal Docker digest to 759f5f4 |
| b332b98 | 2026-03 | - Update Dockerfile Digest Updates |
| 81b57e2 | 2026-02 | - Update registry.access.redhat.com/ubi9/ubi-minimal Docker digest to bb08f23 |
| dbacba8 | 2026-02 | - Update registry.access.redhat.com/ubi9/go-toolset Docker digest to 3f4236f |
| c2a93d7 | 2026-02 | - Update Dockerfile Digest Updates |
| cb5528e | 2026-02 | - sync pipelineruns with konflux-central - 8cf301f |

## Build and Container Information

### Container Images

| Image | Registry | Purpose | Build System |
|-------|----------|---------|--------------|
| odh-mlflow-operator-rhel9 | quay.io/rhoai | MLflow operator controller manager | Konflux |
| mlflow | quay.io/opendatahub/mlflow | MLflow server with kubernetes-auth | Upstream/ODH |

### Dockerfile.konflux Build

| Stage | Base Image | Purpose |
|-------|-----------|---------|
| builder | registry.access.redhat.com/ubi9/go-toolset@sha256:82b82ec... | Build operator binary with CGO_ENABLED=1, FIPS-compliant Go |
| runtime | registry.access.redhat.com/ubi9/ubi-minimal@sha256:759f5f4... | Minimal runtime with operator binary and embedded Helm charts |

### Build Features

- **FIPS Compliance**: Built with `GOEXPERIMENT=strictfipsruntime` and `-tags strictfipsruntime`
- **Multi-arch**: Supports TARGETOS/TARGETARCH build args for cross-platform builds
- **Embedded Charts**: Helm charts copied into container at `/charts/mlflow` for runtime rendering
- **Minimal Runtime**: UBI9 minimal base for reduced attack surface
- **Non-root**: Runs as UID 1001 with non-root restrictions

## Operational Considerations

### High Availability

- **Operator**: Single replica with leader election (supports multiple replicas with one active leader)
- **MLflow Instances**: Supports multiple replicas when using remote storage (RollingUpdate strategy)
- **MLflow Instances with PVC**: Single replica only (Recreate strategy due to ReadWriteOnce PVC)

### Scaling

| Component | Horizontal Scaling | Vertical Scaling | Notes |
|-----------|-------------------|------------------|-------|
| Operator | Yes (leader election) | Yes | Default: 1 replica, 200m CPU / 400Mi RAM requests |
| MLflow (remote storage) | Yes | Yes | RollingUpdate strategy, default 1 replica, configurable via spec.replicas |
| MLflow (PVC storage) | No (single replica) | Yes | Recreate strategy due to ReadWriteOnce volume constraint |

### Resource Requirements

#### Operator

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 200m | 1 |
| Memory | 400Mi | 4Gi |

#### MLflow Instance (default)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 250m | 1 |
| Memory | 512Mi | 1Gi |

### Storage

| Storage Type | Use Case | Volume Mode | Capacity | Notes |
|--------------|----------|-------------|----------|-------|
| PVC (local) | Development, testing, local artifacts | ReadWriteOnce | 2Gi (default, configurable) | Limits to single replica, requires Recreate strategy |
| PostgreSQL (remote) | Production metadata storage | N/A | N/A | Recommended for multi-replica deployments |
| S3 (remote) | Production artifact storage | N/A | N/A | Recommended for multi-replica and large artifact workloads |

### Monitoring and Observability

| Metric Source | Endpoint | Format | Collection Method |
|--------------|----------|--------|-------------------|
| Operator | /metrics (8443/TCP) | Prometheus | ServiceMonitor (Prometheus Operator) |
| MLflow Instance | /health (8443/TCP) | HTTP 200 | Liveness/Readiness probes |

### Logging

| Component | Log Destination | Format | Level |
|-----------|----------------|--------|-------|
| Operator | stdout/stderr | Structured (controller-runtime) | Info (default) |
| MLflow Instance | stdout/stderr | MLflow format | INFO (default, configurable via spec.env) |

## Known Limitations

1. **Single MLflow CR per cluster**: MLflow CR name is validated to be "mlflow" only (enforced by CRD validation)
2. **PVC constraints**: Using local PVC storage limits to single replica with Recreate deployment strategy
3. **Certificate management**: Manual TLS certificate provisioning required outside OpenShift (no automatic cert rotation)
4. **Shared ClusterRole**: The "mlflow" ClusterRole is shared across all instances with multiple owner references (not standard controller ownership)
5. **Namespace enumeration**: MLflow workspaces feature requires cluster-wide namespace list/get/watch permissions
6. **Gateway dependency**: HTTPRoute creation requires Gateway API CRDs and configured Gateway
7. **ConsoleLink dependency**: ConsoleLink creation requires OpenShift ConsoleLink CRD
