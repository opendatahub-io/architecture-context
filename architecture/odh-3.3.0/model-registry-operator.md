# Component: Model Registry Operator

## Metadata
- **Repository**: https://github.com/opendatahub-io/model-registry-operator.git
- **Version**: f8a6863
- **Distribution**: ODH and RHOAI (both)
- **Languages**: Go, YAML
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes operator that deploys and manages Model Registry instances for tracking, versioning, and organizing machine learning models.

**Detailed**: The Model Registry Operator is a Kubernetes controller that deploys and manages instances of the OpenShift AI Model Registry service. Model Registry provides a centralized repository for tracking ML model metadata, versioning, lineage, and artifacts across the ML lifecycle from development to production. The operator reconciles ModelRegistry custom resources to deploy the Model Registry service with configurable database backends (PostgreSQL or MySQL), authentication mechanisms (OAuth Proxy integration), and secure communication (TLS/SSL). It handles database initialization, service exposure via Kubernetes Services and OpenShift Routes, NetworkPolicy creation for database access control, and RBAC provisioning for user authorization. The operator supports both plain HTTP services and OAuth-secured HTTPS endpoints with integration into OpenShift's authentication system. Model Registry integrates with data science workflows, allowing data scientists to register models from notebooks, track model versions, associate models with experiments, and promote models through staging to production environments.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Model Registry Operator | Go Controller | Reconciles ModelRegistry CRs and manages service deployments |
| ModelRegistry Controller | Reconciler | Deploys Model Registry service with database and networking |
| Model Registry Service | REST API Service | Provides HTTP/gRPC API for model metadata management |
| Database Proxy | Sidecar Container | Handles secure database connections with TLS (optional) |
| OAuth Proxy | Sidecar Container | Provides authentication and authorization for REST API (optional) |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| modelregistry.opendatahub.io | v1alpha1 (deprecated) | ModelRegistry | Namespaced | Deploy and configure a Model Registry instance |
| modelregistry.opendatahub.io | v1beta1 | ModelRegistry | Namespaced | Deploy and configure a Model Registry instance (current) |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /api/model_registry/v1alpha3/registered_models | GET, POST | 8080/TCP | HTTP | TLS 1.2+ (OAuth) | Bearer Token (OAuth) | List and create registered models |
| /api/model_registry/v1alpha3/model_versions | GET, POST | 8080/TCP | HTTP | TLS 1.2+ (OAuth) | Bearer Token (OAuth) | List and create model versions |
| /api/model_registry/v1alpha3/model_artifacts | GET, POST | 8080/TCP | HTTP | TLS 1.2+ (OAuth) | Bearer Token (OAuth) | List and create model artifacts |
| /api/model_registry/v1alpha3/serving_environments | GET, POST | 8080/TCP | HTTP | TLS 1.2+ (OAuth) | Bearer Token (OAuth) | Manage serving environments |
| /api/model_registry/v1alpha3/inference_services | GET, POST | 8080/TCP | HTTP | TLS 1.2+ (OAuth) | Bearer Token (OAuth) | Track inference service deployments |
| /health | GET | 8080/TCP | HTTP | None | None | Health check endpoint |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | mTLS | Prometheus metrics for operator |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| MLMetadataService | 9090/TCP | gRPC | TLS 1.2+ (optional) | mTLS (optional) | ML Metadata API (ML Metadata protocol) |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| PostgreSQL | 13+ | Yes (or MySQL) | Backend database for model metadata storage |
| MySQL | 8.0+ | Yes (or PostgreSQL) | Alternative backend database for model metadata |
| OAuth Proxy | Latest | No | Authentication and authorization for REST API |
| ML Metadata | 1.x | Yes | Core metadata storage library (embedded in service) |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | UI Integration | Provides UI for browsing and managing registered models |
| Notebooks | REST API Client | Register models from data science workbenches |
| Data Science Pipelines | REST API Client | Track models created in pipeline runs |
| KServe | Integration | Link InferenceServices to registered model versions |
| TrustyAI | API Client | Access model metadata for monitoring and explainability |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| modelregistry-sample | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |
| modelregistry-sample-grpc | ClusterIP | 9090/TCP | 9090 | gRPC | TLS 1.2+ (optional) | mTLS (optional) | Internal |
| modelregistry-sample-oauth | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | Bearer Token | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| modelregistry-sample-http | OpenShift Route | *.apps.cluster | 80/TCP | HTTP | None | None | External |
| modelregistry-sample-https | OpenShift Route | *.apps.cluster | 443/TCP | HTTPS | TLS 1.2+ | Edge Termination | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| PostgreSQL Database | 5432/TCP | PostgreSQL | TLS 1.2+ (optional) | Password | Store and retrieve model metadata |
| MySQL Database | 3306/TCP | MySQL | TLS 1.2+ (optional) | Password | Alternative database for model metadata |
| OAuth Service | 443/TCP | HTTPS | TLS 1.2+ | OAuth | Validate user tokens for authorization |
| S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS credentials | Store model artifacts (URI references only) |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | "" | services, secrets, configmaps, serviceaccounts, persistentvolumeclaims | create, delete, get, list, patch, update, watch |
| manager-role | apps | deployments | create, delete, get, list, patch, update, watch |
| manager-role | modelregistry.opendatahub.io | modelregistries | create, delete, get, list, patch, update, watch |
| manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| manager-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| manager-role | authorization.k8s.io | subjectaccessreviews, tokenreviews | create |
| registry-user-<registry-name> | "" | services | get |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | opendatahub | manager-role | model-registry-operator |
| <custom-rolebinding> | <registry-namespace> | registry-user-<registry-name> | <user-serviceaccount> |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| model-registry-db-credential | Opaque | Database connection credentials (host, port, user, password) | User-provided / Operator | No |
| <registry-name>-oauth-proxy | kubernetes.io/tls | TLS certificate and key for OAuth proxy | cert-manager / OpenShift Service CA | Yes |
| model-registry-db-tls | Opaque | CA certificate for TLS database connections | User-provided | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| REST API (OAuth) | GET, POST, PATCH, DELETE | Bearer Token (JWT) | OAuth Proxy | OpenShift RBAC via registry-user Role |
| REST API (non-OAuth) | GET, POST, PATCH, DELETE | None | None | Open access (internal only) |
| gRPC API | gRPC methods | mTLS (optional) | Service | Client certificate validation |
| Operator Metrics | GET | mTLS | kube-rbac-proxy | Mutual TLS client certificates |

## Data Flows

### Flow 1: Model Registration from Notebook

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Notebook Pod | OAuth Proxy | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | OAuth Proxy | Model Registry Service | 8080/TCP | HTTP | None | Validated Token |
| 3 | Model Registry Service | PostgreSQL DB | 5432/TCP | PostgreSQL | TLS 1.2+ (optional) | Password |
| 4 | Model Registry Service | OAuth Proxy (response) | 8080/TCP | HTTP | None | N/A |
| 5 | OAuth Proxy | Notebook Pod (response) | 8443/TCP | HTTPS | TLS 1.2+ | N/A |

### Flow 2: Model Query from Dashboard

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Route | 443/TCP | HTTPS | TLS 1.2+ | Session Cookie |
| 2 | OpenShift Router | OAuth Proxy | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 3 | OAuth Proxy | Model Registry Service | 8080/TCP | HTTP | None | Validated Token |
| 4 | Model Registry Service | PostgreSQL DB | 5432/TCP | PostgreSQL | TLS 1.2+ (optional) | Password |
| 5 | Model Registry Service | User Browser (via route) | 443/TCP | HTTPS | TLS 1.2+ | N/A |

### Flow 3: ModelRegistry CR Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Dashboard | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Operator | Deployment (create) | N/A | N/A | N/A | N/A |
| 4 | Operator | Service, Route (create) | N/A | N/A | N/A | N/A |
| 5 | Operator | NetworkPolicy (create) | N/A | N/A | N/A | N/A |
| 6 | Model Registry Pod | PostgreSQL DB | 5432/TCP | PostgreSQL | TLS 1.2+ (optional) | Password |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Manage resources (Deployments, Services, Routes, NetworkPolicies) |
| PostgreSQL/MySQL Database | Database Protocol | 5432/3306 | PostgreSQL/MySQL | TLS 1.2+ (optional) | Persist model metadata and lineage |
| OAuth Service | HTTP API | 443/TCP | HTTPS | TLS 1.2+ | Validate bearer tokens for user authorization |
| Prometheus | Metrics Scraping | 8443/TCP | HTTPS | TLS 1.2+ | Collect operator metrics |
| ODH Dashboard | REST API Client | 8080/8443 | HTTP/HTTPS | TLS 1.2+ (OAuth) | UI for model browsing and management |
| ML Pipelines | REST API Client | 8080/8443 | HTTP/HTTPS | TLS 1.2+ (OAuth) | Register models from pipeline runs |
| KServe | REST API Client | 8080/8443 | HTTP/HTTPS | TLS 1.2+ (OAuth) | Link deployed models to registry entries |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| f8a6863 | 2025-01 | - Bump helm/kind-action to 1.14.0<br>- Bump actions/cache from 4 to 5<br>- Disable govulncheck while waiting for UBI Go 1.25.8<br>- Add NetworkPolicy for PostgreSQL database access control<br>- Improve postgres secret initialization in catalog |
| 279acc6 | 2025-01 | - Sync security config files<br>- Remove redundant .coderabbit.yaml<br>- Bump golang.org/x/oauth2 to 0.27.0<br>- Bump Go to 1.25.7<br>- Enable gateway domain configuration via GATEWAY_DOMAIN env var |
| 7e6d06e | 2024-12 | - Add secure PostgreSQL sample with TLS/SSL support<br>- Update install docs<br>- Use MySQL image from Oracle<br>- Use 127.0.0.1 instead of localhost for MySQL liveness probe<br>- Fix MR service label selector<br>- Cleanup gRPC field validation<br>- Add brief delay before marking CR available |
