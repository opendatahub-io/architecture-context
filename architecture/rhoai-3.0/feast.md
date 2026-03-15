# Component: Feast Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/feast
- **Version**: e43f213a4
- **Branch**: rhoai-3.0
- **Distribution**: RHOAI (with ODH overlay available)
- **Languages**: Go (operator), Python (feature servers), Java, TypeScript/React (UI)
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes operator that deploys and manages Feast feature stores for machine learning workloads.

**Detailed**: The Feast Operator is a Kubernetes operator that automates the deployment and lifecycle management of Feast (Feature Store) instances. Feast is an open-source feature store for machine learning that provides a consistent interface for managing and serving ML features across training and inference workloads. The operator manages the deployment of feature registry servers, online stores (for low-latency real-time feature serving), offline stores (for historical feature data and batch processing), and optional UI components. It supports multiple storage backends including SQLite, Snowflake, Cassandra, and cloud object stores, with configurable authentication (OIDC, Kubernetes RBAC) and TLS encryption. The operator reconciles FeatureStore custom resources and creates the necessary Kubernetes deployments, services, configmaps, and RBAC resources to run a production-ready feature store infrastructure.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| feast-operator | Go Operator | Kubernetes operator that reconciles FeatureStore CRs and manages feast service deployments |
| feature-server (offline) | Python Service | Serves historical feature data for training and batch inference |
| feature-server (online) | Python Service | Low-latency serving of real-time features for online inference |
| feature-server (registry) | Python Service | Manages feature definitions, metadata, and feature store configuration |
| feast-ui | Python/React Service | Web UI for feature discovery, exploration, and monitoring |
| cronjob | Kubernetes CronJob | Executes scheduled feast commands (e.g., materialization) |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| feast.dev | v1alpha1 | FeatureStore | Namespaced | Defines a complete Feast feature store deployment including services, storage backends, authentication, and TLS configuration |

### HTTP Endpoints

#### Operator Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness probe |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | Prometheus metrics (secured) |

#### Feast Online Store Server

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /get-online-features | POST | 6566/TCP | HTTP | None | Configurable (OIDC/K8s/None) | Retrieve real-time features for inference |
| /get-online-features | POST | 6567/TCP | HTTPS | TLS 1.2+ | Configurable (OIDC/K8s/None) | Retrieve real-time features for inference (TLS) |
| /push | POST | 6566/TCP | HTTP | None | Configurable (OIDC/K8s/None) | Push feature values to online store |
| /push | POST | 6567/TCP | HTTPS | TLS 1.2+ | Configurable (OIDC/K8s/None) | Push feature values to online store (TLS) |

#### Feast Offline Store Server

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /get-historical-features | POST | 8815/TCP | HTTP | None | Configurable (OIDC/K8s/None) | Retrieve historical features for training |
| /get-historical-features | POST | 8816/TCP | HTTPS | TLS 1.2+ | Configurable (OIDC/K8s/None) | Retrieve historical features for training (TLS) |
| /offline-store-plan | POST | 8815/TCP | HTTP | None | Configurable (OIDC/K8s/None) | Query offline store execution plan |
| /offline-store-plan | POST | 8816/TCP | HTTPS | TLS 1.2+ | Configurable (OIDC/K8s/None) | Query offline store execution plan (TLS) |

#### Feast Registry Server

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /proto/* | GET/POST | 6570/TCP | gRPC | None | Configurable (OIDC/K8s/None) | gRPC registry operations |
| /proto/* | GET/POST | 6571/TCP | gRPC | TLS 1.2+ | Configurable (OIDC/K8s/None) | gRPC registry operations (TLS) |
| /registry/* | GET/POST | 6572/TCP | HTTP | None | Configurable (OIDC/K8s/None) | REST registry operations |
| /registry/* | GET/POST | 6573/TCP | HTTPS | TLS 1.2+ | Configurable (OIDC/K8s/None) | REST registry operations (TLS) |

#### Feast UI

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| / | GET | 8888/TCP | HTTP | None | Configurable (OIDC/K8s/None) | Web UI for feature discovery |
| / | GET | 8443/TCP | HTTPS | TLS 1.2+ | Configurable (OIDC/K8s/None) | Web UI for feature discovery (TLS) |
| /api/* | GET/POST | 8888/TCP | HTTP | None | Configurable (OIDC/K8s/None) | UI backend API |
| /api/* | GET/POST | 8443/TCP | HTTPS | TLS 1.2+ | Configurable (OIDC/K8s/None) | UI backend API (TLS) |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| feast.core.RegistryServer | 6570/TCP | gRPC/HTTP2 | None | Configurable (OIDC/K8s/None) | Feature registry metadata operations |
| feast.core.RegistryServer | 6571/TCP | gRPC/HTTP2 | TLS 1.2+ | Configurable (OIDC/K8s/None) | Feature registry metadata operations (TLS) |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.11.3+ | Yes | Operator runtime platform |
| Python | 3.11 | Yes | Runtime for feature servers |
| Go | 1.22 | Yes (build) | Operator development and build |
| Storage Backend | Various | Yes | Persistent storage (SQLite/Postgres/Snowflake/S3/GCS/Cassandra) |
| OpenShift Routes | 4.x | Optional | External routing (OpenShift only) |
| cert-manager | Any | Optional | TLS certificate management |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| odh-trusted-ca-bundle | ConfigMap Injection | Custom CA certificates for TLS connections to external services |
| Service Mesh (Istio) | Network | Optional service mesh integration for mTLS and traffic management |
| OpenShift OAuth | OIDC | Optional integration for user authentication via OpenShift OAuth |

## Network Architecture

### Services

#### Operator Service

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | None | Internal |

#### Feast Services (Created by Operator per FeatureStore CR)

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {name}-online | ClusterIP | 80/TCP | 6566 | HTTP | None | Configurable | Internal |
| {name}-online | ClusterIP | 443/TCP | 6567 | HTTPS | TLS 1.2+ | Configurable | Internal |
| {name}-offline | ClusterIP | 80/TCP | 8815 | HTTP | None | Configurable | Internal |
| {name}-offline | ClusterIP | 443/TCP | 8816 | HTTPS | TLS 1.2+ | Configurable | Internal |
| {name}-registry | ClusterIP | 80/TCP | 6572 | HTTP/gRPC | None | Configurable | Internal |
| {name}-registry | ClusterIP | 443/TCP | 6573 | HTTPS/gRPC | TLS 1.2+ | Configurable | Internal |
| {name}-ui | ClusterIP | 80/TCP | 8888 | HTTP | None | Configurable | Internal |
| {name}-ui | ClusterIP | 443/TCP | 8443 | HTTPS | TLS 1.2+ | Configurable | Internal |

Note: `{name}` is the FeatureStore CR metadata.name

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {name}-{service}-route | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ | Edge/Passthrough | External (if configured) |

Note: Routes are created automatically on OpenShift for services when configured in FeatureStore CR

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Storage Backend (S3/GCS) | 443/TCP | HTTPS | TLS 1.2+ | Cloud IAM/Keys | Feature data persistence |
| Database (Postgres/Snowflake) | 5432/TCP or 443/TCP | Postgres/HTTPS | TLS 1.2+ | DB Credentials | Feature registry and online store |
| OIDC Provider | 443/TCP | HTTPS | TLS 1.2+ | Client Secret | User authentication |
| Git Repository | 443/TCP | HTTPS | TLS 1.2+ | Token/SSH Key | Feature definition source |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | apps | deployments | create, delete, get, list, update, watch |
| manager-role | batch | cronjobs | create, delete, get, list, patch, update, watch |
| manager-role | "" | configmaps, persistentvolumeclaims, serviceaccounts, services | create, delete, get, list, update, watch |
| manager-role | "" | namespaces, pods, secrets | get, list, watch |
| manager-role | "" | pods/exec | create |
| manager-role | feast.dev | featurestores | create, delete, get, list, patch, update, watch |
| manager-role | feast.dev | featurestores/finalizers | update |
| manager-role | feast.dev | featurestores/status | get, patch, update |
| manager-role | rbac.authorization.k8s.io | clusterrolebindings, clusterroles, rolebindings, roles, subjectaccessreviews | create, delete, get, list, update, watch |
| manager-role | route.openshift.io | routes | create, delete, get, list, update, watch |
| manager-role | authentication.k8s.io | tokenreviews | create |
| leader-election-role | "" | configmaps | get, list, watch, create, update, patch |
| leader-election-role | "" | events | create, patch |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch |
| metrics-reader | "" | services, endpoints, pods | get, list, watch |
| featurestore-editor-role | feast.dev | featurestores | create, delete, get, list, patch, update, watch |
| featurestore-viewer-role | feast.dev | featurestores | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | N/A (Cluster) | manager-role | controller-manager (system namespace) |
| leader-election-rolebinding | system | leader-election-role | controller-manager |
| metrics-auth-rolebinding | system | metrics-auth-role | controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {name}-tls | kubernetes.io/tls | TLS certificates for feast services | User/cert-manager | No/Yes |
| {name}-client-tls | kubernetes.io/tls | Client TLS certificates for mTLS | User/cert-manager | No/Yes |
| oidc-secret | Opaque | OIDC authentication credentials (client_id, client_secret, etc.) | User | No |
| {storage}-credentials | Opaque | Storage backend credentials (S3/GCS access keys, DB passwords) | User | No |
| git-token | Opaque | Git repository access token for feature repo sync | User | No |

Note: `{name}` is the FeatureStore CR metadata.name

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /get-online-features | POST | OIDC Bearer Token | Feature Server | JWT validation against OIDC provider |
| /get-online-features | POST | Kubernetes RBAC | Feature Server | SubjectAccessReview checks for feast.dev permissions |
| /get-historical-features | POST | OIDC Bearer Token | Feature Server | JWT validation against OIDC provider |
| /get-historical-features | POST | Kubernetes RBAC | Feature Server | SubjectAccessReview checks for feast.dev permissions |
| /registry/* | GET/POST | OIDC Bearer Token | Registry Server | JWT validation against OIDC provider |
| /registry/* | GET/POST | Kubernetes RBAC | Registry Server | SubjectAccessReview checks for feast.dev permissions |
| UI endpoints | GET/POST | OIDC Bearer Token | UI Server | JWT validation against OIDC provider |
| UI endpoints | GET/POST | Kubernetes RBAC | UI Server | SubjectAccessReview checks for feast.dev permissions |

Note: Authentication can be configured as: no_auth, kubernetes, or oidc per FeatureStore CR

## Data Flows

### Flow 1: Feature Retrieval for Online Inference

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | ML Model/Client | {name}-online Service | 80/TCP or 443/TCP | HTTP/HTTPS | TLS 1.2+ (if HTTPS) | OIDC/K8s RBAC |
| 2 | Online Store Pod | Registry Service | 80/TCP or 443/TCP | HTTP/HTTPS | TLS 1.2+ (if HTTPS) | Internal |
| 3 | Online Store Pod | Storage Backend (DB/Redis/Cassandra) | Varies | Native Protocol | TLS 1.2+ | DB Credentials |
| 4 | Online Store Pod | ML Model/Client | 80/TCP or 443/TCP | HTTP/HTTPS | TLS 1.2+ (if HTTPS) | N/A (response) |

### Flow 2: Feature Retrieval for Training (Historical Features)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Data Scientist/Notebook | {name}-offline Service | 80/TCP or 443/TCP | HTTP/HTTPS | TLS 1.2+ (if HTTPS) | OIDC/K8s RBAC |
| 2 | Offline Store Pod | Registry Service | 80/TCP or 443/TCP | HTTP/HTTPS | TLS 1.2+ (if HTTPS) | Internal |
| 3 | Offline Store Pod | Storage Backend (S3/GCS/Snowflake) | 443/TCP | HTTPS/Native | TLS 1.2+ | Cloud IAM/Credentials |
| 4 | Offline Store Pod | Data Scientist/Notebook | 80/TCP or 443/TCP | HTTP/HTTPS | TLS 1.2+ (if HTTPS) | N/A (response) |

### Flow 3: Feature Materialization (Offline to Online)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | CronJob Pod | Registry Service | 80/TCP or 443/TCP | HTTP/HTTPS | TLS 1.2+ (if HTTPS) | Internal |
| 2 | CronJob Pod | Offline Store Service | 80/TCP or 443/TCP | HTTP/HTTPS | TLS 1.2+ (if HTTPS) | Internal |
| 3 | CronJob Pod | Online Store Service | 80/TCP or 443/TCP | HTTP/HTTPS | TLS 1.2+ (if HTTPS) | Internal |
| 4 | Online Store Pod | Storage Backend | Varies | Native Protocol | TLS 1.2+ | DB Credentials |

### Flow 4: Feature Registry Management

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Feast CLI/Client | {name}-registry Service | 80/TCP or 443/TCP | gRPC/HTTP | TLS 1.2+ (if HTTPS) | OIDC/K8s RBAC |
| 2 | Registry Pod | Storage Backend (S3/DB/File) | 443/TCP or Varies | HTTPS/Native | TLS 1.2+ | Credentials/IAM |
| 3 | Registry Pod | Feast CLI/Client | 80/TCP or 443/TCP | gRPC/HTTP | TLS 1.2+ (if HTTPS) | N/A (response) |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Operator watches FeatureStore CRs and manages resources |
| Prometheus | Metrics Scrape | 8443/TCP | HTTPS | TLS 1.2+ | Operator metrics collection |
| OIDC Provider | REST API | 443/TCP | HTTPS | TLS 1.2+ | User authentication and token validation |
| S3-compatible Storage | REST API | 443/TCP | HTTPS | TLS 1.2+ | Feature data persistence (registry, offline, online stores) |
| PostgreSQL/Snowflake | Database Protocol | 5432/TCP or 443/TCP | Postgres/HTTPS | TLS 1.2+ | Feature data persistence |
| Git Repository | HTTPS/SSH | 443/TCP or 22/TCP | HTTPS/SSH | TLS 1.2+/SSH | Feature definition synchronization |
| Redis/Cassandra/DynamoDB | Native Protocol | Varies | Native | TLS 1.2+ | Online feature store backend |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| e43f213a4 | 2026-03 | - Sync pipelineruns with konflux-central - 6d9b15d |
| 879451a85 | 2026-03 | - chore(deps): update konflux references (#187) |

Note: Limited commit history available. For complete changelog, see [CHANGELOG.md](CHANGELOG.md) in the repository.

## Deployment Configuration

### Kustomize Structure

The operator uses Kustomize for deployment with the following structure:

- **Base**: `infra/feast-operator/config/`
  - `crd/`: CRD definitions
  - `rbac/`: RBAC resources (ClusterRole, ServiceAccount, RoleBindings)
  - `manager/`: Operator deployment manifest
  - `default/`: Default kustomization with metrics and patches
  - `prometheus/`: ServiceMonitor for metrics
  - `samples/`: 18 example FeatureStore CR configurations

- **Overlays**:
  - `overlays/odh/`: OpenDataHub-specific configuration
  - `overlays/rhoai/`: RHOAI-specific configuration

### Container Images

Two primary container images are built via Konflux:

1. **odh-feast-operator-rhel9** (`Dockerfiles/Dockerfile.feast-operator.konflux`)
   - Base: `registry.access.redhat.com/ubi9/go-toolset:1.22.9`
   - Runtime: `registry.access.redhat.com/ubi9/ubi-minimal`
   - Features: CGO enabled, strict FIPS mode
   - User: 65532 (non-root)

2. **odh-feature-server-rhel9** (`Dockerfiles/Dockerfile.feature-server.konflux`)
   - Base: `registry.access.redhat.com/ubi9/python-311`
   - Features: Multi-arch support (ppc64le prebuild), Python 3.11, DuckDB, Apache Arrow
   - User: 1001 (non-root)

### Resource Requirements

Default operator resource limits:
- **CPU**: 1000m (limit), 10m (request)
- **Memory**: 256Mi (limit), 64Mi (request)

Default PVC storage requests (per FeatureStore):
- **Offline Store**: 20Gi
- **Online Store**: 5Gi
- **Registry**: 5Gi

## Configuration Examples

The operator supports 18 sample configurations demonstrating various deployment scenarios:

- Basic ephemeral deployment
- Remote servers (offline, online, registry, UI)
- Database persistence (PostgreSQL, Snowflake)
- Object store persistence (S3, GCS)
- PVC persistence
- TLS configuration
- Kubernetes RBAC authentication
- OIDC authentication
- CronJob scheduling
- Git-based feature repositories
- Volume and environment customization

## Notes

- The operator is designed for both OpenDataHub (ODH) and Red Hat OpenShift AI (RHOAI) distributions
- Supports multiple authentication methods: no authentication, Kubernetes RBAC, and OIDC
- TLS can be configured for all service endpoints with custom or cert-manager-issued certificates
- Custom CA bundle injection is supported via OpenShift trusted CA bundle mechanism
- The operator creates dynamic Kubernetes resources based on the FeatureStore CR specification
- Feature servers support multiple storage backends without code changes (abstracted via Feast SDK)
- The operator manages the complete lifecycle including upgrades and cleanup via finalizers
