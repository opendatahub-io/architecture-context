# Component: Feast (Feature Store)

## Metadata
- **Repository**: https://github.com/red-hat-data-services/feast
- **Version**: 0.54.0 (aad1ebcd0)
- **Distribution**: RHOAI and ODH
- **Languages**: Go (operator), Python (feature servers)
- **Deployment Type**: Kubernetes Operator + Feature Servers

## Purpose
**Short**: Feast Operator deploys and manages Feast, an open-source feature store for machine learning, providing online and offline feature serving capabilities with centralized registry management.

**Detailed**:
Feast (Feature Store) is a comprehensive platform for managing ML features consistently across training and serving environments. The Feast Operator is a Kubernetes controller that automates the deployment and lifecycle management of Feast feature store instances. When users create a `FeatureStore` custom resource, the operator deploys a configurable set of services including an online store for low-latency real-time predictions, an offline store for historical data access during model training, a registry for feature metadata management, and an optional web UI for feature discovery. The operator supports multiple storage backends (SQLite, PostgreSQL, Redis, cloud storage), authentication mechanisms (Kubernetes RBAC, OIDC), and TLS encryption for all services. It enables data science teams to decouple ML models from data infrastructure, avoid data leakage through point-in-time correct feature retrieval, and maintain feature consistency between training and inference environments.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Feast Operator | Kubernetes Operator (Go) | Manages FeatureStore CR lifecycle, deploys and configures Feast services |
| Online Feature Store | Python Service | Low-latency serving of pre-computed features for real-time inference |
| Offline Feature Store | Python Service | Historical feature retrieval for batch scoring and model training |
| Registry Server | Python Service (gRPC/REST) | Centralized metadata repository for feature definitions and schemas |
| UI Server | Python Service (Optional) | Web interface for feature discovery and registry exploration |
| CronJob | Kubernetes CronJob | Scheduled materialization and maintenance tasks (e.g., feature ingestion) |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| feast.dev | v1alpha1 | FeatureStore | Namespaced | Declaratively defines a Feast feature store deployment including services, storage backends, and authorization |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token | Operator metrics for Prometheus |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness probe |
| /get-online-features | POST | 80/TCP or 443/TCP | HTTP/HTTPS | TLS 1.2+ (optional) | OIDC/Kubernetes RBAC (optional) | Online feature retrieval for inference |
| /get-historical-features | POST | 80/TCP or 443/TCP | HTTP/HTTPS | TLS 1.2+ (optional) | OIDC/Kubernetes RBAC (optional) | Offline historical feature retrieval |
| /ui/* | GET | 80/TCP or 443/TCP | HTTP/HTTPS | TLS 1.2+ (optional) | OIDC/Kubernetes RBAC (optional) | Web UI for feature registry browsing |
| /health | GET | 6570/TCP or 6571/TCP | HTTP/HTTPS | TLS 1.2+ (optional) | None | Registry server health check |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ServingService | 6566/TCP or 6567/TCP | gRPC | TLS 1.2+ (optional) | OIDC/Kubernetes RBAC (optional) | Online feature retrieval via gRPC |
| RegistryServer | 6570/TCP or 6571/TCP | gRPC | TLS 1.2+ (optional) | OIDC/Kubernetes RBAC (optional) | Feature registry metadata access |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.11.3+ | Yes | Container orchestration and operator runtime |
| PostgreSQL | Any | No | Optional persistent storage for registry and online store |
| Redis | 7+ | No | Optional high-performance online store backend |
| S3/GCS/Azure Blob | Any | No | Optional object storage for offline data and registry |
| Snowflake | Any | No | Optional cloud data warehouse for offline/online/registry |
| cert-manager | Any | No | Optional automatic TLS certificate provisioning |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | UI Integration | Feature store instances appear in ODH dashboard for discovery |
| Prometheus | Metrics | Operator exposes metrics for monitoring via ServiceMonitor |
| OpenShift OAuth | Authentication | Optional OIDC authentication integration |
| Trusted CA Bundle | ConfigMap Injection | Automatic CA certificate injection for TLS trust |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| feast-operator-controller-manager-metrics-service | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | Bearer Token | Internal |
| {featurestore-name}-online | ClusterIP | 80/TCP or 443/TCP | 6566 or 6567 | HTTP/HTTPS or gRPC | TLS 1.2+ (optional) | OIDC/RBAC (optional) | Internal |
| {featurestore-name}-offline | ClusterIP | 80/TCP or 443/TCP | 8815 or 8816 | HTTP/HTTPS | TLS 1.2+ (optional) | OIDC/RBAC (optional) | Internal |
| {featurestore-name}-registry | ClusterIP | 80/TCP or 443/TCP | 6570 or 6571 | HTTP/HTTPS or gRPC | TLS 1.2+ (optional) | OIDC/RBAC (optional) | Internal |
| {featurestore-name}-ui | ClusterIP | 80/TCP or 443/TCP | 8888 or 8443 | HTTP/HTTPS | TLS 1.2+ (optional) | OIDC/RBAC (optional) | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {featurestore-name}-online | OpenShift Route | {name}-online-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ | Edge/Re-encrypt | External |
| {featurestore-name}-offline | OpenShift Route | {name}-offline-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ | Edge/Re-encrypt | External |
| {featurestore-name}-registry | OpenShift Route | {name}-registry-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ | Edge/Re-encrypt | External |
| {featurestore-name}-ui | OpenShift Route | {name}-ui-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ | Edge/Re-encrypt | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| PostgreSQL Database | 5432/TCP | PostgreSQL Wire Protocol | TLS 1.2+ (optional) | Username/Password | Registry and online store persistence |
| Redis | 6379/TCP | Redis Protocol | TLS 1.2+ (optional) | Password (optional) | Online store backend for low-latency access |
| S3-compatible Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Access Keys | Object storage for offline data and registry files |
| GCS | 443/TCP | HTTPS | TLS 1.2+ | Service Account | Google Cloud Storage for offline/registry |
| Snowflake | 443/TCP | HTTPS | TLS 1.2+ | OAuth/Key Pair | Cloud data warehouse integration |
| Git Repository | 443/TCP | HTTPS | TLS 1.2+ | Token/SSH Key | Feature repository synchronization |
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token | Pod/Service/ConfigMap management |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| feast-operator-manager-role | apps | deployments | create, delete, get, list, update, watch |
| feast-operator-manager-role | batch | cronjobs | create, delete, get, list, patch, update, watch |
| feast-operator-manager-role | "" | configmaps, persistentvolumeclaims, serviceaccounts, services | create, delete, get, list, update, watch |
| feast-operator-manager-role | "" | pods, secrets | get, list |
| feast-operator-manager-role | "" | pods/exec | create |
| feast-operator-manager-role | feast.dev | featurestores | create, delete, get, list, patch, update, watch |
| feast-operator-manager-role | feast.dev | featurestores/status | get, patch, update |
| feast-operator-manager-role | feast.dev | featurestores/finalizers | update |
| feast-operator-manager-role | rbac.authorization.k8s.io | roles, rolebindings | create, delete, get, list, update, watch |
| feast-operator-manager-role | route.openshift.io | routes | create, delete, get, list, update, watch |
| feast-operator-metrics-reader | "" | pods | get, list |
| feast-operator-featurestore-editor-role | feast.dev | featurestores | create, delete, get, list, patch, update, watch |
| feast-operator-featurestore-viewer-role | feast.dev | featurestores | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| feast-operator-leader-election-rolebinding | redhat-ods-applications (RHOAI) or opendatahub (ODH) | leader-election-role | feast-operator-controller-manager |
| feast-operator-manager-rolebinding | cluster-wide | manager-role | feast-operator-controller-manager |
| feast-operator-metrics-auth-rolebinding | redhat-ods-applications (RHOAI) or opendatahub (ODH) | metrics-auth-role | feast-operator-controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {featurestore-name}-tls | kubernetes.io/tls | TLS certificates for HTTPS endpoints | cert-manager or manual | Yes (cert-manager) / No (manual) |
| {featurestore-name}-db-secret | Opaque | Database credentials for PostgreSQL/Snowflake | User | No |
| {featurestore-name}-redis-secret | Opaque | Redis connection password | User | No |
| {featurestore-name}-git-token | Opaque | Git repository access token for feature repo sync | User | No |
| {featurestore-name}-oidc-secret | Opaque | OIDC client credentials (client_id, client_secret, auth_discovery_url) | User | No |
| {featurestore-name}-gcs-key | Opaque | Google Cloud Storage service account JSON key | User | No |
| {featurestore-name}-s3-credentials | Opaque | S3 access key and secret key | User | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | Bearer Token (Service Account) | kube-rbac-proxy | ServiceAccount must have metrics-reader role |
| Online Store | GET, POST | None / Kubernetes RBAC / OIDC | Python middleware | Configurable per FeatureStore CR |
| Offline Store | GET, POST | None / Kubernetes RBAC / OIDC | Python middleware | Configurable per FeatureStore CR |
| Registry | GET, POST | None / Kubernetes RBAC / OIDC | Python middleware | Configurable per FeatureStore CR |
| UI | GET | None / Kubernetes RBAC / OIDC | Python middleware | Configurable per FeatureStore CR |

## Data Flows

### Flow 1: Online Feature Retrieval (Real-time Inference)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | ML Application | OpenShift Route (Ingress) | 443/TCP | HTTPS | TLS 1.2+ | None/OIDC |
| 2 | OpenShift Route | Online Store Service | 80/TCP or 443/TCP | HTTP/HTTPS | TLS 1.2+ (optional) | None/OIDC/RBAC |
| 3 | Online Store Service | Redis/PostgreSQL/SQLite | 6379/TCP or 5432/TCP | Redis/PostgreSQL Protocol | TLS 1.2+ (optional) | Password/Certificate |
| 4 | Online Store Service | Registry Service | 80/TCP or 443/TCP | HTTP/HTTPS or gRPC | TLS 1.2+ (optional) | None/OIDC/RBAC |

### Flow 2: Historical Feature Retrieval (Model Training)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Training Job | Offline Store Service | 80/TCP or 443/TCP | HTTP/HTTPS | TLS 1.2+ (optional) | None/OIDC/RBAC |
| 2 | Offline Store Service | S3/GCS/Snowflake | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Service Account/OAuth |
| 3 | Offline Store Service | Registry Service | 80/TCP or 443/TCP | HTTP/HTTPS or gRPC | TLS 1.2+ (optional) | None/OIDC/RBAC |

### Flow 3: Feature Materialization (Scheduled)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | CronJob Pod | Offline Store Service | 80/TCP or 443/TCP | HTTP/HTTPS | TLS 1.2+ (optional) | Service Account Token |
| 2 | CronJob Pod | Online Store Service | 80/TCP or 443/TCP | HTTP/HTTPS | TLS 1.2+ (optional) | Service Account Token |
| 3 | CronJob Pod | Redis/PostgreSQL | 6379/TCP or 5432/TCP | Redis/PostgreSQL Protocol | TLS 1.2+ (optional) | Password/Certificate |

### Flow 4: Operator Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Feast Operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 2 | Feast Operator | Feature Server Pods | 6566/TCP, 8815/TCP, etc. | HTTP/gRPC | TLS 1.2+ (optional) | None |
| 3 | Prometheus | Operator Metrics Service | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Resource management (Deployments, Services, ConfigMaps, PVCs) |
| Prometheus | ServiceMonitor | 8443/TCP | HTTPS | TLS 1.2+ | Operator health and performance metrics collection |
| OpenShift Router | Route | 80/TCP, 443/TCP | HTTP/HTTPS | TLS 1.2+ | External access to feature stores |
| PostgreSQL | Database Wire Protocol | 5432/TCP | PostgreSQL | TLS 1.2+ (optional) | Persistent storage backend |
| Redis | Redis Protocol | 6379/TCP | Redis | TLS 1.2+ (optional) | High-performance online store |
| S3/GCS/Azure Blob | REST API | 443/TCP | HTTPS | TLS 1.2+ | Object storage for offline data |
| OIDC Provider | OAuth 2.0 | 443/TCP | HTTPS | TLS 1.2+ | User authentication and authorization |
| Git Repository | Git/HTTPS | 443/TCP | HTTPS | TLS 1.2+ | Feature definition repository sync |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| aad1ebcd0 | 2026-03 | - Sync pipelineruns with konflux-central<br>- Update Konflux build references<br>- Bump urllib3 to >2.6.0 for security |
| ea57f3da3 | 2026-02 | - Update Konflux references for build pipeline |
| ced640304 | 2026-01 | - Security: Bump urllib3 to address CVE |

## Deployment Architecture

### RHOAI Deployment
- **Namespace**: `redhat-ods-applications`
- **Images**: Konflux-built container images from internal registry
- **Operator Image**: `odh-feast-operator-rhel9`
- **Feature Server Image**: `odh-feature-server-rhel9`
- **CronJob Image**: `origin-cli:4.17`

### ODH Deployment
- **Namespace**: `opendatahub`
- **Images**: Same Konflux-built images as RHOAI
- **Configuration**: Shared kustomize base with ODH-specific overlays

## Storage Architecture

### Supported Storage Backends

**Online Store Options:**
- SQLite (default, ephemeral or PVC-backed)
- PostgreSQL (recommended for production)
- Redis (high-performance, low-latency)
- Snowflake
- Cassandra/ScyllaDB
- DynamoDB, Bigtable, Datastore (cloud providers)

**Offline Store Options:**
- File-based (Parquet files on PVC/S3/GCS)
- DuckDB (default for local development)
- Dask (distributed processing)
- PostgreSQL
- Snowflake
- Redshift, BigQuery (cloud data warehouses)

**Registry Options:**
- File-based (registry.db on PVC/S3/GCS)
- SQL database (PostgreSQL, MySQL)
- Snowflake

### Persistence Volumes

| Volume Type | Mount Path | Size | Purpose |
|-------------|------------|------|---------|
| feature-repo-data | /feast-data | 20Gi (default) | Offline store Parquet files and feature repository |
| online-store-data | /feast-data | 5Gi (default) | SQLite online store database |
| registry-data | /feast-data | 5Gi (default) | Registry metadata database |

## High Availability Considerations

- **Operator**: Single replica with leader election support
- **Feature Servers**: Horizontal scaling supported via replica count in FeatureStore CR
- **Registry**: Shared storage or database required for multi-replica deployments
- **Online Store**: Redis cluster or PostgreSQL with HA recommended for production
- **Offline Store**: Stateless service, scales horizontally with shared storage backend
