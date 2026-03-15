# Component: Model Registry Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/model-registry-operator
- **Version**: b068597 (rhoai-3.2 branch)
- **Distribution**: RHOAI
- **Languages**: Go 1.24.4
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes operator that manages the lifecycle of Model Registry instances and their associated resources.

**Detailed**: The Model Registry Operator is a Kubernetes controller that reconciles `ModelRegistry` custom resources to deploy and manage Model Registry service instances. It handles the deployment of REST API services backed by PostgreSQL or MySQL databases, with optional security through OAuth proxy or kube-rbac-proxy. The operator creates and manages all necessary Kubernetes resources including deployments, services, service accounts, RBAC policies, routes, and optionally Istio service mesh configurations. It supports both v1alpha1 (deprecated) and v1beta1 API versions with automatic conversion webhooks. The operator can also provision PostgreSQL database instances automatically and supports TLS encryption for database connections and service endpoints.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| model-registry-operator | Operator Controller | Reconciles ModelRegistry CRs and manages lifecycle of model registry instances |
| model-registry REST API | HTTP Service | Provides REST API for model registry operations |
| PostgreSQL/MySQL Database | Data Store | Backend database for model registry metadata storage |
| OAuth Proxy | Security Proxy | Optional OpenShift OAuth authentication proxy for REST API |
| kube-rbac-proxy | Security Proxy | Optional Kubernetes RBAC authentication proxy for REST API |
| Webhook Server | Admission Controller | Validates and mutates ModelRegistry CR operations |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| modelregistry.opendatahub.io | v1alpha1 | ModelRegistry | Namespaced | Deprecated API for model registry configuration |
| modelregistry.opendatahub.io | v1beta1 | ModelRegistry | Namespaced | Current API for model registry configuration with conversion webhook |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /api/model_registry/v1alpha3/* | REST | 8080/TCP | HTTP | None | None | Model Registry REST API (internal) |
| /api/model_registry/v1alpha3/* | REST | 8443/TCP | HTTPS | TLS 1.2+ | OAuth/RBAC | Model Registry REST API (secured via proxy) |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator health check endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness check endpoint |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | mTLS | Prometheus metrics endpoint (kube-rbac-proxy protected) |
| /mutate-modelregistry-opendatahub-io-modelregistry | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Mutating webhook for ModelRegistry CR |
| /validate-modelregistry-opendatahub-io-modelregistry | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Validating webhook for ModelRegistry CR |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| model-registry (deprecated) | 9090/TCP | gRPC | None | None | Legacy gRPC API (deprecated in v1beta1) |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| PostgreSQL | 16+ | Yes (or MySQL) | Backend database for model registry metadata |
| MySQL | 8.0+ | Yes (or PostgreSQL) | Alternative backend database for model registry metadata |
| OpenShift OAuth Proxy | latest | No | Optional authentication proxy for REST API |
| kube-rbac-proxy | latest | No | Optional Kubernetes RBAC proxy for REST API |
| cert-manager | Any | No | Optional TLS certificate management |
| Istio Service Mesh | 1.20+ | No | Optional service mesh integration with Authorino |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| odh-model-metadata-collection | Image Reference | Provides catalog and benchmark data for model registry |
| Authorino | Service Mesh Auth | Optional Istio-based authentication via AuthConfig CRDs |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {registry-name} | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (plain mode) |
| {registry-name} | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | OAuth/RBAC | Internal (secured via proxy) |
| controller-manager-metrics-service | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | mTLS | Internal (operator metrics) |
| webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | K8s API Server | Internal (webhooks) |
| {registry-name}-db | ClusterIP | 5432/TCP | 5432 | PostgreSQL | TLS 1.2+ (optional) | Password | Internal (PostgreSQL) |
| {registry-name}-db | ClusterIP | 3306/TCP | 3306 | MySQL | TLS 1.2+ (optional) | Password | Internal (MySQL) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {registry-name}-http | OpenShift Route | {domain} | 80/TCP | HTTP | None | N/A | External (plain mode) |
| {registry-name}-https | OpenShift Route | {domain} | 443/TCP | HTTPS | TLS 1.2+ | Edge | External (OAuth/RBAC proxy) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| PostgreSQL/MySQL Database | 5432/TCP or 3306/TCP | PostgreSQL/MySQL | TLS 1.2+ (optional) | Password/TLS Client Cert | Database connections from model registry |
| Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token | CR reconciliation and resource management |
| Authorino Service | 50051/TCP | gRPC | mTLS | Service Mesh | Optional Istio authentication via Authorino |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | "" | configmaps, persistentvolumeclaims, secrets, serviceaccounts, services | create, delete, get, list, patch, update, watch |
| manager-role | "" | endpoints, pods, pods/log | get, list, watch |
| manager-role | "" | events | create, patch |
| manager-role | apps | deployments | create, delete, get, list, patch, update, watch |
| manager-role | modelregistry.opendatahub.io | modelregistries | create, delete, get, list, patch, update, watch |
| manager-role | modelregistry.opendatahub.io | modelregistries/status | get, patch, update |
| manager-role | modelregistry.opendatahub.io | modelregistries/finalizers | update |
| manager-role | rbac.authorization.k8s.io | clusterrolebindings, rolebindings, roles | create, delete, get, list, patch, update, watch |
| manager-role | route.openshift.io | routes, routes/custom-host | create, delete, get, list, patch, update, watch |
| manager-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| manager-role | user.openshift.io | groups | create, delete, get, list, patch, update, watch |
| manager-role | authentication.k8s.io | tokenreviews | create |
| manager-role | authorization.k8s.io | subjectaccessreviews | create |
| manager-role | config.openshift.io | ingresses | get, list, watch |
| manager-role | apiextensions.k8s.io | customresourcedefinitions | get, list, watch |
| manager-role | migration.k8s.io | storageversionmigrations | create, delete, get, list, patch, update, watch |
| proxy-role | authentication.k8s.io | tokenreviews | create |
| proxy-role | authorization.k8s.io | subjectaccessreviews | create |
| registry-user-{registry-name} | "" | services | get |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | {operator-namespace} | manager-role (ClusterRole) | controller-manager |
| leader-election-rolebinding | {operator-namespace} | leader-election-role (Role) | controller-manager |
| proxy-rolebinding | {operator-namespace} | proxy-role (ClusterRole) | controller-manager |
| {registry-name}-rolebinding | {registry-namespace} | registry-user-{registry-name} (Role) | Created per user/SA by admin |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {registry-name}-oauth-proxy | kubernetes.io/tls | OAuth proxy TLS certificate | OpenShift Service CA / User | Yes (OpenShift) / No (User) |
| {registry-name}-kube-rbac-proxy | kubernetes.io/tls | kube-rbac-proxy TLS certificate | OpenShift Service CA / User | Yes (OpenShift) / No (User) |
| webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificate | cert-manager / OpenShift | Yes |
| {registry-name}-db | Opaque | Database credentials (password, SSL certs) | User / Operator | No |
| model-registry-operator-controller-manager-metrics-service | kubernetes.io/tls | Operator metrics TLS certificate | OpenShift Service CA | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /api/model_registry/* (port 8443) | All REST | Bearer Token (OAuth) | OpenShift OAuth Proxy | OpenShift user/service account with GET on service |
| /api/model_registry/* (port 8443) | All REST | Bearer Token (RBAC) | kube-rbac-proxy | Kubernetes user/service account with GET on service |
| /api/model_registry/* (port 8080) | All REST | None | N/A | Disabled by default (serviceRoute: disabled) |
| /metrics | GET | mTLS | kube-rbac-proxy | Service account with subjectaccessreview/tokenreview permissions |
| /mutate-*, /validate-* | POST | K8s API Server Auth | Kubernetes API Server | API server authenticates requests to webhooks |
| Istio Gateway (optional) | All | JWT Token | Authorino AuthConfig | Configured via Istio AuthorizationPolicy |

## Data Flows

### Flow 1: Model Registry CR Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/System | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.3 | kubectl/oc credentials |
| 2 | API Server | Webhook Service | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server cert |
| 3 | Webhook Service | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.3 | Service Account Token |
| 4 | API Server | Controller Manager | N/A | Watch API | TLS 1.3 | Service Account Token |
| 5 | Controller Manager | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.3 | Service Account Token |

### Flow 2: Model Registry API Request (OAuth Secured)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | Router | OAuth Proxy | 8443/TCP | HTTPS | TLS 1.2+ | None |
| 3 | OAuth Proxy | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 4 | OAuth Proxy | Model Registry Pod | 8080/TCP | HTTP | None | Validated Token (header) |
| 5 | Model Registry | Database | 5432/TCP or 3306/TCP | PostgreSQL/MySQL | TLS 1.2+ (optional) | Password/Client Cert |

### Flow 3: Database Connection Initialization

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Model Registry Pod | Database Service | 5432/TCP or 3306/TCP | PostgreSQL/MySQL | TLS 1.2+ (optional) | Password from Secret |
| 2 | Model Registry Pod | Database | N/A | SQL | TLS 1.2+ (optional) | CREATE DATABASE (if enabled) |
| 3 | Model Registry Pod | Database | N/A | SQL | TLS 1.2+ (optional) | Schema migration (if enabled) |

### Flow 4: Operator Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | kube-rbac-proxy | 8443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 2 | kube-rbac-proxy | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.3 | SubjectAccessReview |
| 3 | kube-rbac-proxy | Controller Manager | 8443/TCP | HTTPS | TLS 1.2+ | Authorized |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 443/TCP | HTTPS | TLS 1.3 | CR reconciliation, resource management |
| PostgreSQL Database | SQL Protocol | 5432/TCP | PostgreSQL | TLS 1.2+ (optional) | Model registry metadata storage |
| MySQL Database | SQL Protocol | 3306/TCP | MySQL | TLS 1.2+ (optional) | Alternative metadata storage |
| OpenShift OAuth Server | OAuth 2.0 | 443/TCP | HTTPS | TLS 1.2+ | User authentication for proxied services |
| OpenShift Router | HTTP Proxy | 80/TCP, 443/TCP | HTTP/HTTPS | TLS 1.2+ (443) | External route exposure |
| Authorino (Istio) | gRPC | 50051/TCP | gRPC | mTLS | Service mesh authentication |
| Prometheus | Metrics Scrape | 8443/TCP | HTTPS | TLS 1.2+ | Operator metrics collection |
| cert-manager | Certificate Provisioning | N/A | CRD | N/A | Automatic TLS certificate management |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| b068597 | 2026-03-15 | - Update UBI9 minimal base image digest to 759f5f4<br>- Dependency updates for security patches |
| 4891f5e | 2026-03-14 | - Update UBI9 minimal base image digest to ecd4751<br>- Ongoing dependency maintenance |
| 480604d | 2026-03-10 | - Update UBI9 minimal base image digest to bb08f23<br>- Container security updates |
| a89051f | 2026-03-05 | - Update UBI9 minimal base image digest to 90bd85d<br>- Base image security patches |
| 43c8069 | 2026-03-03 | - Re-enable default catalogs<br>- Bug fix for catalog functionality |

## Additional Notes

### Deployment Modes

The operator supports multiple deployment configurations:

1. **Plain HTTP Mode**: Model Registry REST API exposed on port 8080 without authentication (serviceRoute: disabled by default)
2. **OAuth Proxy Mode**: REST API secured via OpenShift OAuth Proxy on port 8443 with automatic TLS certificates
3. **kube-rbac-proxy Mode**: REST API secured via kube-rbac-proxy on port 8443 with Kubernetes RBAC authorization
4. **Istio Service Mesh Mode**: Optional Istio Gateway and Authorino integration for advanced authentication

### Database Support

- **PostgreSQL**: Primary supported database (version 16+)
  - Auto-provisioning supported via `generateDeployment` flag
  - SSL/TLS support with client certificates
  - Connection string format: `postgresql://user:pass@host:port/db?sslmode=...`

- **MySQL**: Alternative database support (version 8.0+)
  - Manual provisioning required
  - SSL/TLS support with client certificates and CA validation
  - Connection string format: `user:pass@tcp(host:port)/db?charset=utf8mb4`

### API Version Migration

- **v1alpha1**: Deprecated API version, marked for removal in future releases
- **v1beta1**: Current stable API version with conversion webhook support
- Automatic conversion between v1alpha1 and v1beta1 via webhook
- Storage version migration support via `migration.k8s.io` API

### Security Considerations

- Operator runs as non-root user (UID 65532)
- Pod security context enforces `restricted-v2` SCC in OpenShift
- All containers drop ALL capabilities
- Network policies restrict ingress to OpenShift router namespace only
- Webhook server requires TLS certificates from cert-manager or OpenShift
- Database passwords stored in Kubernetes Secrets
- Optional TLS encryption for database connections with client certificate authentication
