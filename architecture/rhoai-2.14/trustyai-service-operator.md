# Component: TrustyAI Service Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/trustyai-service-operator
- **Version**: 1.17.0 (commit: 07f7237)
- **Branch**: rhoai-2.14
- **Distribution**: RHOAI
- **Languages**: Go (operator), YAML (manifests)
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes operator that manages TrustyAI service deployments for AI/ML model explainability, fairness monitoring, and bias detection.

**Detailed**: The TrustyAI Service Operator simplifies the deployment and management of TrustyAI services on Kubernetes and OpenShift clusters. It watches for custom resources of kind `TrustyAIService` in the `trustyai.opendatahub.io` API group and automatically provisions the necessary infrastructure including deployments, services, routes, storage (PVC or database), and Prometheus ServiceMonitors. The operator also integrates with KServe InferenceServices to inject payload processors for model monitoring, enabling automated bias detection and explainability metrics collection. It supports both PVC-based storage and external database backends with TLS encryption, and provides OAuth proxy authentication for secure external access on OpenShift.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Operator Controller Manager | Go Application | Reconciles TrustyAIService CRDs and manages lifecycle of TrustyAI services |
| TrustyAI Service Deployment | Pod Deployment | Runs the TrustyAI explainability service (Quarkus application) |
| OAuth Proxy Sidecar | Container | Provides authentication layer for external access |
| Internal Service | Kubernetes Service | ClusterIP service for internal HTTP/HTTPS communication |
| TLS Service | Kubernetes Service | ClusterIP service for OAuth proxy with TLS termination |
| Route | OpenShift Route | External access with re-encryption TLS termination |
| ServiceMonitor | Prometheus Operator | Enables metrics scraping for monitoring |
| PersistentVolumeClaim | Storage | Optional persistent storage for data and models |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| trustyai.opendatahub.io | v1alpha1 | TrustyAIService | Namespaced | Declarative configuration for TrustyAI service instances with storage, metrics, and data specifications |

**TrustyAIService Spec Fields**:
- `replicas`: Number of replicas (optional)
- `storage`: Storage configuration (format: PVC or DATABASE, size, folder, database configurations)
- `data`: Data configuration (filename, format)
- `metrics`: Metrics configuration (schedule, batchSize)

### HTTP Endpoints

#### Operator Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | Bearer Token | Prometheus metrics for operator health and performance |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness probe |

#### TrustyAI Service Endpoints (created by operator)

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /q/metrics | GET | 8080/TCP | HTTP | None | Internal | Quarkus metrics endpoint for Prometheus scraping |
| /* | ALL | 8080/TCP | HTTP | None | Internal | TrustyAI service HTTP API (internal access) |
| /* | ALL | 4443/TCP | HTTPS | TLS | Service Certificate | TrustyAI service HTTPS API (internal with TLS) |
| /oauth/healthz | GET | 8443/TCP | HTTPS | TLS | None | OAuth proxy health check |
| /* | ALL | 8443/TCP | HTTPS | TLS | OAuth/Bearer Token | External API access via OAuth proxy |

### gRPC Services

No gRPC services are exposed by this component.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | v1.19+ | Yes | Container orchestration platform |
| OpenShift (optional) | v4.6+ | No | For Route and OAuth integration features |
| Prometheus Operator | N/A | No | For ServiceMonitor support and metrics collection |
| cert-manager (optional) | N/A | No | For automated certificate management |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KServe | CRD Watch/Patch | Monitors InferenceServices and patches ModelMesh deployments with payload processor configuration |
| TrustyAI Service | Deployment Management | Creates and manages TrustyAI service deployments (separate component) |
| OAuth Proxy | Sidecar Container | Provides authentication for external access on OpenShift |
| ODH Trusted CA Bundle | ConfigMap Injection | Injects custom CA certificates for database TLS connections |

## Network Architecture

### Services

#### Operator Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | https | HTTPS | TLS | Bearer Token | Internal |

#### TrustyAI Service Services (created per TrustyAIService CR)

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {instance-name} | ClusterIP | 80/TCP | 8080 | HTTP | None | None | Internal |
| {instance-name} | ClusterIP | 443/TCP | 4443 | HTTPS | TLS (service certificate) | mTLS | Internal |
| {instance-name}-tls | ClusterIP | 443/TCP | 8443 | HTTPS | TLS (service certificate) | OAuth | Internal |

**Service Annotations**:
- `service.beta.openshift.io/serving-cert-secret-name`: Triggers automatic TLS certificate provisioning
- `prometheus.io/scrape: 'true'`: Enables Prometheus auto-discovery
- `prometheus.io/path: /q/metrics`: Specifies metrics endpoint path

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {instance-name} | OpenShift Route | Dynamic (assigned by cluster) | 443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |

**Route Configuration**:
- Termination: Reencrypt (edge TLS terminated, re-encrypted to backend)
- Insecure Edge Termination Policy: Redirect (HTTP → HTTPS)
- Target Service: {instance-name}-tls
- Backend Port: oauth-proxy (8443)

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| External Database | Varies/TCP | JDBC | TLS 1.2+ (optional) | Username/Password | Database storage backend (when DATABASE mode enabled) |
| KServe InferenceService Pods | 8080/TCP | HTTP | None | None | Payload processing injection for model monitoring |
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Operator control plane operations |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | "" | configmaps | create, delete, get, list, patch, update, watch |
| manager-role | "" | events | create, patch, update |
| manager-role | "" | pods | create, delete, get, list, patch, update, watch |
| manager-role | "" | secrets | create, delete, get, list, patch, update, watch |
| manager-role | "" | serviceaccounts | create, delete, get, list, update, watch |
| manager-role | "" | services | create, delete, get, list, patch, update, watch |
| manager-role | "" | persistentvolumeclaims | create, delete, get, list, patch, update, watch |
| manager-role | "" | persistentvolumes | get, list, watch |
| manager-role | apps | deployments | create, delete, get, list, patch, update, watch |
| manager-role | apps | deployments/finalizers | update |
| manager-role | apps | deployments/status | get, patch, update |
| manager-role | coordination.k8s.io | leases | create, get, update |
| manager-role | monitoring.coreos.com | servicemonitors | create, list, watch |
| manager-role | rbac.authorization.k8s.io | clusterrolebindings | create, delete, get, list, update, watch |
| manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| manager-role | serving.kserve.io | inferenceservices | get, list, patch, update, watch |
| manager-role | serving.kserve.io | inferenceservices/finalizers | delete, get, list, patch, update, watch |
| manager-role | serving.kserve.io | servingruntimes | create, delete, get, list, patch, update, watch |
| manager-role | serving.kserve.io | servingruntimes/status | get, patch, update |
| manager-role | trustyai.opendatahub.io | trustyaiservices | create, delete, get, list, patch, update, watch |
| manager-role | trustyai.opendatahub.io | trustyaiservices/finalizers | update |
| manager-role | trustyai.opendatahub.io | trustyaiservices/status | get, patch, update |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch |
| leader-election-role | "" | configmaps | get, list, watch, create, update, patch |
| leader-election-role | "" | events | create, patch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | System-wide (ClusterRoleBinding) | manager-role | controller-manager |
| leader-election-rolebinding | operator-namespace | leader-election-role | controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {instance-name}-internal | kubernetes.io/tls | TLS certificate for internal service communication | service.beta.openshift.io annotation | Yes |
| {instance-name}-tls | kubernetes.io/tls | TLS certificate for OAuth proxy service | service.beta.openshift.io annotation | Yes |
| {instance-name}-db-credentials | Opaque | Database connection credentials (username, password, service, port, name) | User/External System | No |
| {instance-name}-db-tls | kubernetes.io/tls | Database TLS certificates for secure connections | User/External System | No |

**Secret Data Keys** (for database credentials):
- `databaseKind`: Database type (e.g., postgresql, mysql)
- `databaseUsername`: Database username
- `databasePassword`: Database password
- `databaseService`: Database service hostname
- `databasePort`: Database port
- `databaseName`: Database name
- `databaseGeneration`: Database schema generation strategy

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics (operator) | GET | Bearer Token (ServiceAccount) | Kubernetes RBAC | ServiceMonitor bearer token authentication |
| /* (TrustyAI via Route) | ALL | OAuth/Bearer Token (JWT) | OAuth Proxy Sidecar | OpenShift OAuth integration with session cookies or bearer tokens |
| /* (TrustyAI internal) | ALL | None (internal traffic) | Network Policy (if configured) | ClusterIP services not exposed externally |
| Kubernetes API | ALL | ServiceAccount Token | Kubernetes API Server | RBAC policies defined in ClusterRole/ClusterRoleBinding |

**OAuth Proxy Configuration**:
- Image: `registry.redhat.io/openshift4/ose-oauth-proxy:latest` (default)
- Port: 8443/TCP
- Upstream: http://localhost:8080 (TrustyAI service)
- TLS: Enabled with automatic certificate from service annotation

## Data Flows

### Flow 1: TrustyAI Service Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/System | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token/Client Cert |
| 2 | Kubernetes API | Operator Controller | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Operator Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

**Description**: User creates TrustyAIService CR → Kubernetes API notifies operator → Operator reconciles by creating Deployment, Services, Route, PVC, ServiceMonitor, and ServiceAccount.

### Flow 2: External User Access to TrustyAI Service

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External User | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | None (unauthenticated) |
| 2 | OpenShift Router | OAuth Proxy | 8443/TCP | HTTPS | TLS 1.2+ (re-encrypt) | OAuth Session Cookie/Bearer Token |
| 3 | OAuth Proxy | TrustyAI Service | 8080/TCP | HTTP | None | None (trusted sidecar) |

**Description**: User accesses Route → Edge TLS terminated → Re-encrypted to OAuth Proxy → OAuth validates authentication → Proxies to TrustyAI service on localhost.

### Flow 3: Prometheus Metrics Scraping

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | TrustyAI Service | 80/TCP | HTTP | None | Bearer Token (ServiceAccount) |

**Description**: Prometheus discovers ServiceMonitor → Scrapes /q/metrics endpoint on TrustyAI service → Collects fairness and bias metrics.

### Flow 4: KServe InferenceService Integration

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Operator Controller | Kubernetes API (watch InferenceServices) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Operator Controller | Kubernetes API (patch Deployments) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | ModelMesh Pods | TrustyAI Service | 80/TCP | HTTP | None | None |

**Description**: Operator watches InferenceServices → Patches ModelMesh deployments with MM_PAYLOAD_PROCESSORS env var → ModelMesh sends inference payloads to TrustyAI for monitoring.

### Flow 5: Database Storage Mode

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | TrustyAI Service | External Database | Varies/TCP | JDBC | TLS 1.2+ (optional, via sslMode=verify-ca) | Username/Password |

**Description**: When DATABASE storage mode is configured, TrustyAI service connects to external database using credentials from secret, optionally with TLS certificate verification.

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| KServe InferenceServices | CRD Watch & Patch | 6443/TCP | HTTPS (K8s API) | TLS 1.2+ | Monitor and configure inference services for bias detection |
| ModelMesh Serving | Env Var Injection | 8080/TCP | HTTP | None | Inject payload processor URL into ModelMesh deployments |
| Prometheus | Metrics Pull | 80/TCP | HTTP | None | Collect fairness metrics (SPD, DIR) via ServiceMonitor |
| OpenShift Router | Route Ingress | 8443/TCP | HTTPS | TLS 1.2+ | Provide external access to TrustyAI services |
| OpenShift OAuth | Authentication | N/A | HTTPS | TLS 1.2+ | Authenticate users via OAuth proxy integration |
| External Database | JDBC Connection | Varies/TCP | JDBC | TLS 1.2+ (optional) | Persistent storage backend for metrics and data |
| Persistent Volumes | Volume Mount | N/A | Filesystem | None | Local storage backend for metrics and data |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 07f7237 | Recent | - Merge from upstream trustyai-explainability repository |
| 96a523d | Recent | - RHOAIENG-12274: Update operator's overlays |
| 1c92fc6 | Recent | - CI: Run tests from trustyai-tests |
| 4458d0d | Recent | - feat: Add support for custom DB names |
| d552762 | Recent | - fix: Correct maxSurge and maxUnavailable in rolling update strategy |
| 91ba2c5 | Recent | - Add TLS endpoint for ModelMesh payload processors |
| 1515872 | Recent | - feat: Add support for custom certificates in database connection |
| c537e14 | Recent | - feat: ConfigMap key to disable KServe Serverless configuration |
| ec4462e | Recent | - fix: Skip InferenceService patching for KServe RawDeployment |
| 4a52d65 | Recent | - Add operator installation robustness improvements |

## Deployment Configuration

### Operator Deployment

**Namespace**: Configured via Kustomize overlay (typically `redhat-ods-applications` or `opendatahub`)

**Resource Requirements**:
- CPU Request: 10m
- CPU Limit: 500m
- Memory Request: 64Mi
- Memory Limit: 128Mi

**Security Context**:
- Run as non-root: true
- Allow privilege escalation: false
- Capabilities: All dropped
- Seccomp profile: RuntimeDefault

**High Availability**:
- Leader election: Enabled (single active controller)
- Lease duration: Default Kubernetes lease
- Cluster-scoped operator (watches all namespaces)

### TrustyAI Service Deployment (created by operator)

**Resource Requirements**:
- CPU Request: Configurable
- Memory Request: Configurable

**Replicas**: 1 (default, configurable via CR spec)

**Rolling Update Strategy**:
- Max Unavailable: 1
- Max Surge: 0

**Storage Options**:
1. PVC mode: ReadWriteOnce PVC with configurable size
2. DATABASE mode: External database with JDBC connection

**Environment Variables** (PVC mode):
- `SERVICE_STORAGE_FORMAT`: "PVC"
- `STORAGE_DATA_FILENAME`: Data filename
- `STORAGE_DATA_FOLDER`: Data folder path
- `SERVICE_DATA_FORMAT`: Data format (e.g., CSV)
- `SERVICE_METRICS_SCHEDULE`: Metrics calculation schedule
- `SERVICE_BATCH_SIZE`: Batch size for metrics (default: 5000)

**Environment Variables** (DATABASE mode):
- `SERVICE_STORAGE_FORMAT`: "DATABASE"
- `QUARKUS_HIBERNATE_ORM_ACTIVE`: "true"
- `QUARKUS_DATASOURCE_DB_KIND`: From secret
- `QUARKUS_DATASOURCE_USERNAME`: From secret
- `QUARKUS_DATASOURCE_PASSWORD`: From secret
- `QUARKUS_DATASOURCE_JDBC_URL`: Constructed with optional TLS
- `DATABASE_SERVICE`: From secret
- `DATABASE_PORT`: From secret
- `DATABASE_NAME`: From secret

## Observability

### Metrics Exposed

**Operator Metrics** (port 8080):
- Standard controller-runtime metrics
- Reconciliation duration and count
- API client metrics

**TrustyAI Service Metrics** (port 8080, path /q/metrics):
- `trustyai_spd`: Statistical Parity Difference metric
- `trustyai_dir`: Disparate Impact Ratio metric
- Custom fairness and bias metrics

**ServiceMonitor Configuration**:
- Scrape interval: 4s (for local metrics)
- Metric relabeling: Keep only `trustyai_*` metrics
- Bearer token authentication for operator metrics

### Logging

**Log Levels**: Configurable via zap logger flags
- Development mode: Enabled by default
- Structured logging: JSON format

### Health Checks

**Operator**:
- Liveness: /healthz on port 8081
- Readiness: /readyz on port 8081

**TrustyAI Service**:
- Readiness: /oauth/healthz on OAuth proxy (port 8443)

## Configuration

### Operator Configuration (ConfigMap: trustyai-service-operator-config)

| Key | Default Value | Purpose |
|-----|---------------|---------|
| trustyaiServiceImage | quay.io/trustyai/trustyai-service:latest | TrustyAI service container image |
| oauthProxyImage | quay.io/openshift/origin-oauth-proxy:4.14.0 | OAuth proxy container image |
| kServeServerless | disabled | Enable/disable KServe Serverless integration |

### TrustyAI Service Configuration (per CR instance)

**Storage Configuration**:
- Format: PVC or DATABASE (enum)
- Size: PVC size (e.g., "1Gi")
- Folder: Data folder path (e.g., "/inputs")
- Database Configurations: Secret name for database credentials

**Metrics Configuration**:
- Schedule: Metrics calculation interval (e.g., "5s")
- Batch Size: Number of records per batch (default: 5000)

**Data Configuration**:
- Filename: Data file name (e.g., "data.csv")
- Format: Data format (e.g., "CSV")

## Status Conditions

The TrustyAIService CR tracks several conditions in its status field:

| Condition Type | Reason | Description |
|----------------|--------|-------------|
| InferenceServicesPresent | InferenceServicesFound | InferenceServices detected in namespace |
| InferenceServicesPresent | InferenceServicesNotFound | No InferenceServices found (does not affect Ready status) |
| PVCAvailable | PVCFound | PersistentVolumeClaim is bound and ready |
| PVCAvailable | PVCNotFound | PersistentVolumeClaim not found (sets Ready to False) |
| RouteAvailable | RouteFound | OpenShift Route is created and available |
| RouteAvailable | RouteNotFound | OpenShift Route not found |
| Available | AllComponentsReady | All required components are ready |
| Available | NotAllComponentsReady | Some components are not ready |

**Ready Status**: Aggregated condition based on PVC availability (if PVC mode) and deployment readiness.
