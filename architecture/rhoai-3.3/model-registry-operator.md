# Component: Model Registry Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/model-registry-operator
- **Version**: 4fdd8de (rhoai-3.3)
- **Distribution**: RHOAI
- **Languages**: Go 1.25.7
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Manages the lifecycle of Model Registry instances for ML model metadata storage and retrieval in RHOAI.

**Detailed**: The Model Registry Operator is a Kubernetes controller that deploys and manages Model Registry instances within a namespace. It reconciles ModelRegistry Custom Resources to provision a complete model registry stack including the REST API service, optional PostgreSQL or MySQL database, authentication proxy (kube-rbac-proxy or legacy OAuth proxy), and all necessary Kubernetes resources (Services, Deployments, RBAC, NetworkPolicies, and OpenShift Routes). The operator supports both standalone deployments and integration with Istio service mesh for advanced networking and authorization. It handles database schema migrations, TLS certificate management, and provides flexible authentication options suitable for both development and production environments.

The operator also includes an optional Model Catalog feature that provides curated collections of pre-registered model metadata and benchmarks, enabling teams to quickly populate their model registries with common model information.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| model-registry-operator | Go Operator | Reconciles ModelRegistry CRs and manages lifecycle of model registry instances |
| model-registry REST service | Deployment | HTTP REST API for model metadata operations (port 8080) |
| kube-rbac-proxy | Sidecar Container | RBAC-based authentication proxy for securing REST API access (port 8443) |
| PostgreSQL/MySQL database | Deployment or External | Persistent storage for model registry metadata |
| webhook service | Service | Admission webhook for CR validation and defaulting (port 9443) |
| Model Catalog (optional) | Deployment | Provides curated model metadata collections and benchmarks |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| modelregistry.opendatahub.io | v1alpha1 | ModelRegistry | Namespaced | (Deprecated) Legacy API for model registry instances - use v1beta1 |
| modelregistry.opendatahub.io | v1beta1 | ModelRegistry | Namespaced | Defines desired state of a model registry instance with database, authentication, and networking configuration |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /api/model_registry/v1alpha3/* | GET/POST/PUT/PATCH/DELETE | 8080/TCP | HTTP | None | None (internal) | Model registry REST API - metadata CRUD operations |
| /api/model_registry/v1alpha3/* | GET/POST/PUT/PATCH/DELETE | 8443/TCP | HTTPS | TLS 1.2+ | kube-rbac-proxy (Bearer Token) | Secured model registry REST API via proxy |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator manager health check |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator manager readiness check |
| /validate-modelregistry-opendatahub-io-v1alpha1-modelregistry | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Admission webhook for v1alpha1 CR validation |
| /validate-modelregistry-opendatahub-io-v1beta1-modelregistry | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Admission webhook for v1beta1 CR validation |
| /mutate-modelregistry-opendatahub-io-v1alpha1-modelregistry | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Admission webhook for v1alpha1 CR defaulting |
| /mutate-modelregistry-opendatahub-io-v1beta1-modelregistry | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Admission webhook for v1beta1 CR defaulting |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | 9090/TCP | gRPC | None | None | gRPC endpoint deprecated - functionality removed in v1beta1 |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| PostgreSQL | 16+ (default: postgresql-16-c10s) | Yes (or MySQL) | Primary metadata storage backend |
| MySQL | 3306+ | Yes (or PostgreSQL) | Alternative metadata storage backend |
| kube-rbac-proxy | latest | No | Authentication and authorization proxy for REST API |
| cert-manager | N/A | No | Optional TLS certificate provisioning |
| OpenShift Service Certificates | N/A | No | Automatic TLS cert generation on OpenShift |
| Istio/Service Mesh | N/A | No | Optional service mesh integration for advanced networking |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| components.platform.opendatahub.io | CRD watch | Platform component integration and status reporting |
| services.platform.opendatahub.io | CRD watch (auths) | Authentication configuration discovery |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {registry-name} | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ (OpenShift Serving Cert) | kube-rbac-proxy | Internal |
| {registry-name} | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (no proxy mode) |
| {registry-name}-postgres | ClusterIP | 5432/TCP | 5432 | PostgreSQL | Optional TLS | Password/cert | Internal (auto-provisioned DB) |
| webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | K8s API Server mTLS | Internal |
| controller-manager-metrics-service | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | kube-rbac-proxy | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {registry-name}-https | OpenShift Route | {registry-name}-rest.{domain} | 443/TCP | HTTPS | TLS 1.2+ | reencrypt | External (OpenShift only) |
| {registry-name}-http | OpenShift Route | {registry-name}-rest.{domain} | 80/TCP | HTTP | None | N/A | External (no proxy mode, disabled by default) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| PostgreSQL/MySQL database | 5432/TCP or 3306/TCP | PostgreSQL/MySQL | Optional TLS | Password/cert | Model metadata persistence |
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token | CR reconciliation and resource management |
| OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth token | User authentication (legacy OAuth proxy mode) |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | modelregistry.opendatahub.io | modelregistries, modelregistries/status, modelregistries/finalizers | get, list, watch, create, update, patch, delete |
| manager-role | "" | services, serviceaccounts, configmaps, secrets, persistentvolumeclaims | get, list, watch, create, update, patch, delete |
| manager-role | "" | endpoints, pods, pods/log | get, list, watch |
| manager-role | "" | events | create, patch |
| manager-role | apps | deployments | get, list, watch, create, update, patch, delete |
| manager-role | networking.k8s.io | networkpolicies | get, list, watch, create, update, patch, delete |
| manager-role | rbac.authorization.k8s.io | roles, rolebindings, clusterrolebindings | get, list, watch, create, update, patch, delete |
| manager-role | route.openshift.io | routes, routes/custom-host | get, list, watch, create, update, patch, delete |
| manager-role | user.openshift.io | groups | get, list, watch, create, update, patch, delete |
| manager-role | authentication.k8s.io | tokenreviews | create |
| manager-role | authorization.k8s.io | subjectaccessreviews | create |
| manager-role | config.openshift.io | ingresses | get, list, watch |
| manager-role | migration.k8s.io | storageversionmigrations | get, list, watch, create, update, patch, delete |
| manager-role | apiextensions.k8s.io | customresourcedefinitions | get, list, watch |
| manager-role | components.platform.opendatahub.io | modelregistries | get, list, watch |
| manager-role | services.platform.opendatahub.io | auths | get, list, watch |
| modelregistry-admin-role | modelregistry.opendatahub.io | modelregistries | get, list, watch, create, update, patch, delete |
| modelregistry-editor-role | modelregistry.opendatahub.io | modelregistries | get, list, watch, create, update, patch |
| modelregistry-viewer-role | modelregistry.opendatahub.io | modelregistries | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | {operator-namespace} | manager-role (ClusterRole) | controller-manager |
| leader-election-rolebinding | {operator-namespace} | leader-election-role (Role) | controller-manager |
| proxy-rolebinding | {operator-namespace} | proxy-role (ClusterRole) | controller-manager |
| registry-user-{registry-name}-binding | {registry-namespace} | registry-user-{registry-name} (Role) | Created by admin for user access |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {registry-name}-kube-rbac-proxy | kubernetes.io/tls | TLS certificate for kube-rbac-proxy HTTPS endpoint | OpenShift Service CA or user | Yes (OpenShift), No (user-provided) |
| {registry-name}-oauth-proxy (legacy) | kubernetes.io/tls | TLS certificate for OAuth proxy HTTPS endpoint | OpenShift Service CA or user | Yes (OpenShift), No (user-provided) |
| {db-credential-secret} | Opaque | Database password for model registry service | User or operator | No |
| {postgres-ssl-cert-secret} | Opaque | PostgreSQL client SSL certificate | User or cert-manager | No |
| {postgres-ssl-key-secret} | Opaque | PostgreSQL client SSL private key | User or cert-manager | No |
| {postgres-ssl-rootcert-secret} | Opaque | PostgreSQL CA certificate | User or cert-manager | No |
| webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificate | cert-manager | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /api/model_registry/v1alpha3/* (8443) | ALL | Bearer Token (K8s user/SA) | kube-rbac-proxy | SubjectAccessReview on Service resource |
| /api/model_registry/v1alpha3/* (8080) | ALL | None | N/A | Internal cluster access only |
| Webhook endpoints (9443) | POST | mTLS client cert | Kubernetes API Server | API server validates webhook CA |
| PostgreSQL database (5432) | ALL | Password or client cert | PostgreSQL server | Database authentication |

## Data Flows

### Flow 1: External User Access to Model Registry (Secured)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | OpenShift Router | 443/TCP | HTTPS | TLS 1.3 | N/A |
| 2 | OpenShift Router | {registry-name} Service | 8443/TCP | HTTPS | TLS 1.2+ (reencrypt) | N/A |
| 3 | kube-rbac-proxy sidecar | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 4 | kube-rbac-proxy (SubjectAccessReview) | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer token validation |
| 5 | kube-rbac-proxy sidecar | model-registry container | 8080/TCP | HTTP | None (localhost) | Passed through after authz |
| 6 | model-registry container | PostgreSQL Service | 5432/TCP | PostgreSQL | Optional TLS | Password or client cert |

### Flow 2: Operator Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | controller-manager | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 2 | Kubernetes API | Webhook Service | 443/TCP | HTTPS | TLS 1.2+ | mTLS |
| 3 | controller-manager | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token (create/update resources) |

### Flow 3: Internal Model Registry Access (No Proxy)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Internal Pod | {registry-name} Service | 8080/TCP | HTTP | None | None |
| 2 | model-registry container | PostgreSQL Service | 5432/TCP | PostgreSQL | Optional TLS | Password or client cert |

### Flow 4: Database Initialization (Auto-Provisioned PostgreSQL)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | controller-manager | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token (create PVC, Deployment, Service) |
| 2 | model-registry container | {registry-name}-postgres Service | 5432/TCP | PostgreSQL | Optional TLS | Password from secret |
| 3 | model-registry container | PostgreSQL database | 5432/TCP | PostgreSQL | Optional TLS | Schema creation/migration |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | CR reconciliation, resource CRUD, admission webhooks |
| PostgreSQL Database | PostgreSQL wire protocol | 5432/TCP | PostgreSQL | Optional TLS | Metadata persistence and retrieval |
| MySQL Database | MySQL wire protocol | 3306/TCP | MySQL | Optional TLS | Alternative metadata persistence |
| OpenShift Router | HTTP/HTTPS | 443/TCP, 80/TCP | HTTPS/HTTP | TLS 1.3 | External ingress via Routes |
| kube-rbac-proxy | HTTP reverse proxy | 8443/TCP → 8080/TCP | HTTPS → HTTP | TLS 1.2+ → None | Authentication and authorization |
| OpenShift Service CA | Certificate injection | N/A | N/A | N/A | Automatic TLS certificate provisioning |
| cert-manager | Certificate management | N/A | N/A | N/A | Webhook and optional service certificate provisioning |
| Istio Gateway (optional) | Istio VirtualService | 443/TCP | HTTPS | mTLS | Service mesh ingress with Authorino authz |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 4fdd8de | 2026-03-12 | - Update go-toolset to 1.25<br>- Update UBI9 base images |
| 501d531 | 2026-03-10 | - **Security**: Add NetworkPolicy for PostgreSQL database access control<br>- Restrict database access to only model-registry pods |
| c7aa063 | 2026-03-10 | - **Catalog**: Improve PostgreSQL secret initialization for Model Catalog |
| 99f3e35 | 2026-03-10 | - Upgrade to Go 1.25.7 |
| 71a5ca5 | 2026-01-15 | - **Fix**: Correct model registry service label selector |
| 0cc196d | 2026-01-14 | - **Fix**: Cleanup gRPC field validation (gRPC deprecated) |
| a3695f1 | 2026-01-13 | - **Fix**: Add brief delay before marking CR available to ensure deployment readiness |

## Notes

### Key Features
- **Multi-Database Support**: Supports both PostgreSQL and MySQL backends with optional TLS encryption
- **Authentication Options**: kube-rbac-proxy (recommended) for Kubernetes RBAC-based auth, legacy OAuth proxy for backward compatibility
- **Auto-Provisioning**: Can automatically deploy and manage PostgreSQL database instances
- **OpenShift Integration**: Native support for Routes, Service Certificates, and OAuth
- **Service Mesh Ready**: Optional Istio integration with Gateway and Authorino-based authorization
- **Migration Support**: Handles CRD version conversion (v1alpha1 → v1beta1) and database schema migrations
- **Network Security**: Automatic NetworkPolicy creation for database isolation
- **Webhook Validation**: Admission webhooks enforce CR validation and apply defaults

### Deployment Patterns
1. **Development**: Auto-provisioned PostgreSQL, HTTP-only access (no proxy)
2. **Production (OpenShift)**: External database with TLS, kube-rbac-proxy, Routes for external access
3. **Production (Vanilla K8s)**: External database with TLS, kube-rbac-proxy, manual Ingress/Gateway configuration
4. **Service Mesh**: Istio Gateway with Authorino for fine-grained authorization policies

### Security Considerations
- Default deployment uses kube-rbac-proxy requiring valid Kubernetes user/serviceaccount bearer tokens
- Database passwords stored in Kubernetes Secrets (recommended: use external secret management)
- TLS certificates auto-provisioned on OpenShift via Service CA annotation
- NetworkPolicies restrict database access to model registry pods only
- Operator runs as non-root with restricted SCC (restricted-v2)
- gRPC endpoint deprecated and removed in v1beta1 to reduce attack surface

### Model Catalog
- Optional feature providing curated model metadata and benchmarks
- Enables teams to quickly populate registries with common model information
- Requires separate PostgreSQL database instance
- Controlled via operator environment variables (`ENABLE_MODEL_CATALOG`)
