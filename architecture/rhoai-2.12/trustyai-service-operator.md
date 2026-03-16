# Component: TrustyAI Service Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/trustyai-service-operator
- **Version**: 1.17.0 (git: 65f1454)
- **Distribution**: RHOAI, ODH
- **Languages**: Go 1.21
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Manages deployment and lifecycle of TrustyAI explainability services for AI/ML model monitoring and bias detection.

**Detailed**: The TrustyAI Service Operator is a Kubernetes operator that simplifies the deployment and management of TrustyAI services on Kubernetes and OpenShift clusters. It watches for custom resources of kind `TrustyAIService` in the `trustyai.opendatahub.io` API group and automatically manages the corresponding deployments, services, routes, and ServiceMonitors. The operator integrates with KServe InferenceServices to inject payload processors for collecting inference data, which is then analyzed for fairness metrics (SPD, DIR) and explainability. It supports both PVC-based and database-based storage backends, includes OAuth proxy integration for secure access on OpenShift, and provides Prometheus metrics integration for monitoring.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Operator Controller Manager | Deployment | Reconciles TrustyAIService CRs and manages TrustyAI service deployments |
| TrustyAI Service | Deployment | Quarkus-based service providing explainability and fairness metrics analysis |
| OAuth Proxy | Container Sidecar | Provides OpenShift OAuth authentication for TrustyAI service endpoints |
| ServiceMonitor | Custom Resource | Enables Prometheus to scrape TrustyAI metrics |
| Route | OpenShift Route | Exposes TrustyAI service externally with TLS termination |
| PVC Storage | PersistentVolumeClaim | Optional storage backend for inference data (CSV format) |
| Database Storage | External Database | Optional storage backend for inference data (PostgreSQL, MariaDB, MySQL) |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| trustyai.opendatahub.io | v1alpha1 | TrustyAIService | Namespaced | Defines desired state of TrustyAI service including storage, metrics schedule, and data format |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /q/metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint (internal) |
| /q/metrics | GET | 80/TCP | HTTP | None | None | Prometheus metrics via ClusterIP service |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness probe |
| /* | ALL | 443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token | External access via OAuth proxy and Route (Reencrypt) |
| /* | ALL | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token | OAuth proxy target port |
| /* | ALL | 4443/TCP | HTTPS | TLS 1.2+ | Service Serving Cert | Internal HTTPS service |

### gRPC Services

None - This component uses HTTP/REST APIs only.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | v1.19+ | Yes | Container orchestration platform |
| OpenShift | v4.6+ | No | Provides Route API and OAuth integration (optional) |
| Prometheus Operator | v0.64.1 | No | ServiceMonitor CRD for metrics scraping |
| cert-manager or OpenShift Cert Service | N/A | Yes | TLS certificate provisioning for services |
| PostgreSQL/MariaDB/MySQL | N/A | No | Optional database backend for storage |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KServe | CRD (InferenceService) | Patches InferenceServices to inject payload processor environment variables for data collection |
| Model Mesh | Deployment Patching | Injects MM_PAYLOAD_PROCESSORS environment variable into ModelMesh serving deployments |
| ODH Dashboard | N/A | TrustyAI services can be accessed through ODH/RHOAI dashboard |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {instance-name} | ClusterIP | 80/TCP | 8080 | HTTP | None | None | Internal |
| {instance-name} | ClusterIP | 443/TCP | 4443 | HTTPS | TLS 1.2+ (Service Serving Cert) | None | Internal |
| {instance-name}-tls | ClusterIP | 443/TCP | 8443 | HTTPS | TLS 1.2+ (Service Serving Cert) | OAuth Bearer Token | Internal (for Route) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {instance-name} | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| KServe InferenceServices | Various | HTTPS | TLS 1.2+ | mTLS | Receive inference payloads for analysis |
| External Database | 5432/TCP, 3306/TCP | PostgreSQL/MySQL Protocol | TLS 1.2+ (optional) | Username/Password | Store inference data and metrics |
| Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Reconcile resources, watch CRDs |
| ModelMesh Serving | Various | HTTPS | TLS 1.2+ | mTLS | Collect payload data from MM deployments |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | "" | configmaps, events, pods, secrets, serviceaccounts, services, persistentvolumeclaims, persistentvolumes | get, list, watch, create, update, patch, delete |
| manager-role | apps | deployments, deployments/finalizers, deployments/status | get, list, watch, create, update, patch, delete |
| manager-role | serving.kserve.io | inferenceservices, inferenceservices/finalizers, servingruntimes, servingruntimes/status | get, list, watch, create, update, patch, delete |
| manager-role | trustyai.opendatahub.io | trustyaiservices, trustyaiservices/status, trustyaiservices/finalizers | get, list, watch, create, update, patch, delete |
| manager-role | monitoring.coreos.com | servicemonitors | create, list, watch |
| manager-role | route.openshift.io | routes | get, list, watch, create, update, patch, delete |
| manager-role | rbac.authorization.k8s.io | clusterrolebindings | get, list, watch, create, update, delete |
| manager-role | coordination.k8s.io | leases | get, create, update |
| proxy-role | authentication.k8s.io | tokenreviews | create |
| proxy-role | authorization.k8s.io | subjectaccessreviews | create |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | operator-namespace | manager-role | controller-manager |
| leader-election-rolebinding | operator-namespace | leader-election-role | controller-manager |
| {instance}-{namespace}-proxy-rolebinding | Cluster-wide | trustyai-service-operator-proxy-role | {instance}-proxy |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {instance}-internal | kubernetes.io/tls | Internal service TLS certificate | OpenShift Service Serving Cert | Yes |
| {instance}-tls | kubernetes.io/tls | OAuth proxy service TLS certificate | OpenShift Service Serving Cert | Yes |
| {instance}-db-credentials | Opaque | Database connection credentials (username, password, host, port, database name) | User/Admin | No |
| {instance}-db-tls | kubernetes.io/tls | Database TLS certificates for secure connections | User/cert-manager | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| External Route /* | ALL | OAuth Bearer Token (OpenShift) | OAuth Proxy Sidecar | OpenShift OAuth, TokenReview API |
| Internal Service /* | ALL | None | N/A | Internal cluster access only |
| Metrics Endpoint /q/metrics | GET | None (HTTP) | N/A | ServiceMonitor scrapes internal port |
| Operator API (webhooks) | ALL | ServiceAccount Token | Kubernetes API Server | RBAC policies |

## Data Flows

### Flow 1: Inference Data Collection from KServe

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | KServe InferenceService | TrustyAI Service | 443/TCP | HTTPS | TLS 1.2+ (Service Serving Cert) | mTLS |
| 2 | TrustyAI Service | PVC or Database | N/A or 5432/TCP | Filesystem or PostgreSQL | None or TLS 1.2+ | Filesystem or DB Credentials |

### Flow 2: Metrics Scraping

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | TrustyAI Service | 80/TCP | HTTP | None | None (internal) |
| 2 | TrustyAI Service | Prometheus | Response | HTTP | None | None |

### Flow 3: External User Access

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.3 | None |
| 2 | OpenShift Router | TrustyAI Route | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Route Admission |
| 3 | TrustyAI Route | OAuth Proxy Service | 443/TCP | HTTPS | TLS 1.2+ (Service Serving Cert) | None |
| 4 | OAuth Proxy Sidecar | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth Client |
| 5 | OAuth Proxy Sidecar | TrustyAI Service Container | 8080/TCP | HTTP | None (localhost) | OAuth Token Validated |

### Flow 4: Operator Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Operator Controller | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Operator Controller | Created Resources | Various | Various | Various | Controller Owner Reference |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| KServe InferenceServices | CRD Patching | 443/TCP | HTTPS (K8s API) | TLS 1.2+ | Inject payload processor URLs into InferenceService deployments |
| Model Mesh | Deployment Patching | 443/TCP | HTTPS (K8s API) | TLS 1.2+ | Inject MM_PAYLOAD_PROCESSORS environment variable |
| Prometheus | ServiceMonitor | 80/TCP | HTTP | None | Scrape trustyai_spd and trustyai_dir metrics |
| OpenShift OAuth | OAuth Token Validation | 443/TCP | HTTPS | TLS 1.2+ | Validate user authentication tokens |
| OpenShift Routes | Route API | 443/TCP | HTTPS (K8s API) | TLS 1.2+ | Expose services externally |

## Recent Changes

**Note**: This repository is on the `rhoai-2.12` branch with minimal recent commit history.

| Version | Date | Changes |
|---------|------|---------|
| 1.17.0 | 2024 | - Current stable version<br>- Support for database storage backend<br>- PVC to database migration capability<br>- OAuth proxy integration<br>- KServe InferenceService integration<br>- ServiceMonitor support for Prometheus |

## Deployment Configuration

### Kustomize Structure

- **Base**: `config/base/` - Core operator deployment manifests
- **CRD**: `config/crd/` - TrustyAIService CRD definitions
- **RBAC**: `config/rbac/` - ClusterRoles, RoleBindings, ServiceAccounts
- **Manager**: `config/manager/` - Operator deployment specification
- **Overlays**:
  - `config/overlays/odh/` - Open Data Hub specific configuration
  - `config/overlays/rhoai/` - RHOAI specific configuration
  - `config/overlays/testing/` - Testing environment configuration

### Container Images

| Image | Registry | Purpose |
|-------|----------|---------|
| trustyai-service-operator | quay.io/trustyai/trustyai-service-operator:latest | Operator controller manager |
| trustyai-service | quay.io/trustyai/trustyai-service:latest | TrustyAI service application (Quarkus) |
| ose-oauth-proxy | registry.redhat.io/openshift4/ose-oauth-proxy@sha256:ab112105... | OAuth proxy sidecar |

### Resource Requirements

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| Operator Manager | 10m | 500m | 64Mi | 128Mi |
| TrustyAI Service | Not specified | Not specified | Not specified | Not specified |
| OAuth Proxy | Not specified | Not specified | Not specified | Not specified |

## Operational Characteristics

### High Availability

- Operator supports leader election for HA deployments
- TrustyAI service instances support configurable replicas (default: 1)
- Rolling update strategy for zero-downtime updates

### Storage Options

1. **PVC Mode**:
   - AccessMode: ReadWriteOnce
   - Configurable size (default: 1Gi)
   - Stores data in CSV format
   - Single file per TrustyAI instance

2. **Database Mode**:
   - Supported databases: PostgreSQL, MariaDB, MySQL
   - Connection details via Secret
   - Optional TLS encryption
   - Migration path from PVC to database

### Metrics

- Endpoint: `/q/metrics` (Prometheus format)
- Key metrics: `trustyai_spd`, `trustyai_dir`
- Scrape interval: 4s (configurable in ServiceMonitor)
- Metric relabeling: Only trustyai_* metrics exported

### Security Posture

- Non-root container execution (UID 65532)
- No privileged escalation
- Capabilities dropped: ALL
- Seccomp profile: RuntimeDefault
- Service Mesh ready (mTLS support via certificate volumes)
