# Component: Feast Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/feast.git
- **Version**: 0.58.0 (rhoai-3.2 branch, commit 4436b3c0e)
- **Distribution**: RHOAI
- **Languages**: Go (operator), Python (feature server)
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes operator that deploys and manages Feast, an open source feature store for machine learning workloads.

**Detailed**: The Feast Operator is a Kubernetes controller that automates the deployment and lifecycle management of Feast feature store instances. Feast (Feature Store) provides ML platform teams with consistent feature access for both training and serving by managing an offline store for historical data processing, a low-latency online store for real-time predictions, and feature servers for serving pre-computed features. The operator watches FeatureStore custom resources and reconciles the desired state by deploying registry services, online/offline stores, web UI, and supporting infrastructure. It integrates with OpenShift Routes for external access, supports both Kubernetes RBAC and OIDC authentication, and provides optional integration with Kubeflow Notebooks for data science workflows. The operator manages persistent storage, TLS certificates, and feature materialization jobs, making it seamless to productionize ML feature pipelines in RHOAI environments.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Feast Operator Controller | Go Operator (Deployment) | Reconciles FeatureStore CRs and manages lifecycle of Feast deployments |
| Registry Service | Python gRPC/REST Server | Stores and serves feature store metadata (feature definitions, data sources) |
| Online Store | Python HTTP Server | Low-latency serving of pre-computed features for real-time inference |
| Offline Store | Python HTTP Server | Processes historical feature data for batch scoring and model training |
| Web UI | Python HTTP Server | Web interface for exploring features and feature store configurations |
| Feature Server Deployments | Kubernetes Deployments | Container deployments for registry/online/offline/UI services |
| Client ConfigMaps | ConfigMaps | Feast client configuration for Jupyter notebook integration |
| Namespace Registry | ConfigMap | Tracks FeatureStore instances across namespaces |
| CronJobs | Kubernetes CronJobs | Scheduled feature materialization and maintenance tasks |
| Metrics Service | HTTPS Service | Prometheus metrics endpoint for operator monitoring |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| feast.dev | v1 | FeatureStore | Namespaced | Defines a Feast feature store deployment with registry, online/offline stores, persistence, and authorization |
| feast.dev | v1alpha1 | FeatureStore | Namespaced | Legacy API version (deprecated, use v1) |

### HTTP Endpoints

#### Operator Manager

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token | Prometheus metrics endpoint with authentication |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness probe |

#### Registry Service (Managed by Operator)

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /registry/* | gRPC | 6570/TCP | HTTP | None | Configurable | Feature registry gRPC API (non-TLS) |
| /registry/* | gRPC | 6571/TCP | HTTPS | TLS 1.2+ | Configurable | Feature registry gRPC API (TLS) |
| /registry/* | REST | 6572/TCP | HTTP | None | Configurable | Feature registry REST API (non-TLS) |
| /registry/* | REST | 6573/TCP | HTTPS | TLS 1.2+ | Configurable | Feature registry REST API (TLS) |

#### Online Store (Managed by Operator)

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /online/* | POST | 6566/TCP | HTTP | None | Configurable | Real-time feature retrieval (non-TLS) |
| /online/* | POST | 6567/TCP | HTTPS | TLS 1.2+ | Configurable | Real-time feature retrieval (TLS) |

#### Offline Store (Managed by Operator)

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /offline/* | POST | 8815/TCP | HTTP | None | Configurable | Historical feature processing (non-TLS) |
| /offline/* | POST | 8816/TCP | HTTPS | TLS 1.2+ | Configurable | Historical feature processing (TLS) |

#### Web UI (Managed by Operator)

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| / | GET | 8888/TCP | HTTP | None | Configurable | Feature exploration web interface (non-TLS) |
| / | GET | 8443/TCP | HTTPS | TLS 1.2+ | Configurable | Feature exploration web interface (TLS) |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| feast.core.RegistryService | 6570/TCP | gRPC | None | Configurable | Feature metadata operations (non-TLS) |
| feast.core.RegistryService | 6571/TCP | gRPC | TLS 1.2+ | Configurable | Feature metadata operations (TLS) |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.11.3+ | Yes | Operator runtime platform |
| Go Toolset | 1.22.9 | Build | Operator compilation |
| Python | 3.11 | Yes | Feature server runtime |
| UBI 9 Minimal | 9.5 | Yes | Operator base image |
| UBI 9 Python | 3.11 | Yes | Feature server base image |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Kubeflow Notebooks | CRD Watch | Optional integration to inject Feast client configs into notebook pods |
| OpenShift Routes | API (route.openshift.io/v1) | External access to feature services (OpenShift only) |
| Prometheus Operator | ServiceMonitor CRD | Metrics collection from operator |
| ODH Trusted CA Bundle | ConfigMap Injection | Custom CA certificates for TLS connections |

## Network Architecture

### Services

#### Operator Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ (self-signed) | Bearer Token + SubjectAccessReview | Internal |

#### Feature Store Services (Managed by Operator)

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| feast-{name}-registry | ClusterIP | 80/TCP | 6570 | HTTP | None | Configurable | Internal |
| feast-{name}-registry | ClusterIP | 443/TCP | 6571 | HTTPS | TLS 1.2+ | Configurable | Internal |
| feast-{name}-registry-rest | ClusterIP | 80/TCP | 6572 | HTTP | None | Configurable | Internal |
| feast-{name}-registry-rest | ClusterIP | 443/TCP | 6573 | HTTPS | TLS 1.2+ | Configurable | Internal |
| feast-{name}-online | ClusterIP | 80/TCP | 6566 | HTTP | None | Configurable | Internal |
| feast-{name}-online | ClusterIP | 443/TCP | 6567 | HTTPS | TLS 1.2+ | Configurable | Internal |
| feast-{name}-offline | ClusterIP | 80/TCP | 8815 | HTTP | None | Configurable | Internal |
| feast-{name}-offline | ClusterIP | 443/TCP | 8816 | HTTPS | TLS 1.2+ | Configurable | Internal |
| feast-{name}-ui | ClusterIP | 80/TCP | 8888 | HTTP | None | Configurable | Internal |
| feast-{name}-ui | ClusterIP | 443/TCP | 8443 | HTTPS | TLS 1.2+ | Configurable | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| feast-{name}-{service}-route | OpenShift Route | *.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ | Edge/Passthrough | External (OpenShift) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token | CRD operations, resource management |
| Git Repository (optional) | 443/TCP | HTTPS | TLS 1.2+ | Token/SSH | Feature repository synchronization |
| S3-compatible Storage (optional) | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Access Keys | Registry persistence, object store |
| PostgreSQL (optional) | 5432/TCP | PostgreSQL | TLS 1.2+ (optional) | Username/Password | Online/offline/registry database |
| Snowflake (optional) | 443/TCP | HTTPS | TLS 1.2+ | OAuth/Key Pair | Cloud data warehouse integration |
| Cassandra (optional) | 9042/TCP | CQL | TLS 1.2+ (optional) | Username/Password | Online store database |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | feast.dev | featurestores, featurestores/status, featurestores/finalizers | get, list, watch, create, update, patch, delete |
| manager-role | apps | deployments | get, list, watch, create, update, delete |
| manager-role | "" | services, configmaps, persistentvolumeclaims, serviceaccounts | get, list, watch, create, update, delete |
| manager-role | "" | secrets, pods, namespaces | get, list, watch |
| manager-role | "" | pods/exec | create |
| manager-role | batch | cronjobs | get, list, watch, create, update, patch, delete |
| manager-role | rbac.authorization.k8s.io | roles, rolebindings, clusterroles, clusterrolebindings, subjectaccessreviews | get, list, watch, create, update, delete |
| manager-role | route.openshift.io | routes | get, list, watch, create, update, delete |
| manager-role | apiextensions.k8s.io | customresourcedefinitions | get, list |
| manager-role | authentication.k8s.io | tokenreviews | create |
| manager-role | kubeflow.org | notebooks | get, list, watch |
| metrics-auth-role | authentication.k8s.io | tokenreviews | create |
| metrics-auth-role | authorization.k8s.io | subjectaccessreviews | create |
| featurestore-editor-role | feast.dev | featurestores | get, list, watch, create, update, patch, delete |
| featurestore-viewer-role | feast.dev | featurestores, featurestores/status | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| controller-manager-rolebinding | system | ClusterRole/manager-role | controller-manager |
| leader-election-rolebinding | system | Role/leader-election-role | controller-manager |
| metrics-auth-rolebinding | system | ClusterRole/metrics-auth-role | controller-manager |

### RBAC - Namespaced Roles (Leader Election)

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| leader-election-role | "" | events | create, patch |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {name}-tls | kubernetes.io/tls | TLS certificates for feature services | User/cert-manager | No |
| {name}-oidc | Opaque | OIDC client credentials (client_id, client_secret, username, password) | User | No |
| {name}-git-auth | Opaque | Git repository access token for feature repo sync | User | No |
| {name}-db-credentials | Opaque | Database connection credentials (PostgreSQL, Snowflake, etc.) | User | No |
| {name}-s3-credentials | Opaque | S3/object store access keys | User | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics (operator) | GET | Bearer Token (JWT) + SubjectAccessReview | kube-rbac-proxy | TokenReview + SubjectAccessReview to metrics-reader role |
| Feature Services | GET, POST | Configurable: None, Kubernetes RBAC, OIDC | Feature Server | User-defined via FeatureStore CR authz config |
| Kubernetes API | ALL | Service Account Token | Kubernetes API Server | RBAC policies via manager-role ClusterRole |

### Feature Store Authorization Modes

| Mode | Mechanism | Configuration | Purpose |
|------|-----------|---------------|---------|
| No Auth | None | Default | No authentication/authorization (development only) |
| Kubernetes RBAC | ServiceAccount + Roles | authz.kubernetes.roles | Use Kubernetes RBAC for feature access control |
| OIDC | OAuth 2.0/OpenID Connect | authz.oidc.secretRef | External IdP for feature access (Auth0, Keycloak, etc.) |

## Data Flows

### Flow 1: FeatureStore Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/kubectl | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Kubernetes API | Feast Operator | N/A | Watch | N/A | Service Account Token |
| 3 | Feast Operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |

**Description**: User creates FeatureStore CR → API Server notifies operator → Operator reconciles and creates Deployments, Services, ConfigMaps, PVCs, etc.

### Flow 2: Feature Retrieval (Online)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | ML Application | Online Store Service | 6566/TCP or 6567/TCP | HTTP/HTTPS | TLS 1.2+ (optional) | Configurable |
| 2 | Online Store | SQLite/PostgreSQL/Cassandra | Varies | Varies | TLS 1.2+ (optional) | DB Credentials |

**Description**: Application requests features → Online store queries database → Returns low-latency feature values

### Flow 3: Feature Metadata Access

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Feast Client | Registry Service | 6570/TCP or 6571/TCP | gRPC/HTTP | TLS 1.2+ (optional) | Configurable |
| 2 | Registry Service | File/SQL/S3 Storage | Varies | Varies | TLS 1.2+ (optional) | Storage credentials |

**Description**: Client queries feature definitions → Registry reads from persistent storage → Returns metadata

### Flow 4: Notebook Integration

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Notebook Controller | Feast Operator | N/A | Watch | N/A | N/A |
| 2 | Feast Operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 3 | Notebook Pod | ConfigMap | N/A | Mount | N/A | N/A |

**Description**: Notebook controller creates notebook → Operator injects Feast client ConfigMap → Notebook has Feast configuration

### Flow 5: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | Metrics Service | 8443/TCP | HTTPS | TLS 1.2+ (self-signed) | Bearer Token |
| 2 | Metrics Service | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |

**Description**: Prometheus scrapes metrics → Service validates token via TokenReview → Returns operator metrics

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Resource management, watches, RBAC |
| Kubeflow Notebooks | CRD Watch | N/A | Informer | N/A | Inject Feast client configs into notebooks |
| OpenShift Router | Route CRD | 443/TCP | HTTPS | TLS 1.2+ | External access via Routes (OpenShift) |
| Prometheus | ServiceMonitor | 8443/TCP | HTTPS | TLS 1.2+ | Metrics scraping |
| Git Server | HTTP/SSH | 443/TCP or 22/TCP | HTTPS/SSH | TLS 1.2+/SSH | Feature repository synchronization |
| Object Storage (S3) | S3 API | 443/TCP | HTTPS | TLS 1.2+ | Registry persistence, offline store |
| PostgreSQL | PostgreSQL | 5432/TCP | PostgreSQL | TLS 1.2+ (optional) | Online/offline/registry persistence |
| Snowflake | REST API | 443/TCP | HTTPS | TLS 1.2+ | Cloud data warehouse for features |

## Deployment Architecture

### Operator Deployment

- **Replicas**: 1 (leader election enabled)
- **Container**: odh-feast-operator (Go binary)
- **Resources**: CPU 10m-1000m, Memory 64Mi-256Mi
- **Security Context**: runAsNonRoot, drop ALL capabilities
- **Image Build**: Konflux (FIPS-enabled, strict FIPS runtime)

### Feature Store Deployments (Per FeatureStore CR)

- **Registry Deployment**: 1+ replicas, Python 3.11
- **Online Store Deployment**: 1+ replicas, Python 3.11
- **Offline Store Deployment**: 1+ replicas, Python 3.11
- **UI Deployment**: 1+ replicas, Python 3.11
- **Image Build**: Konflux (multi-arch: amd64, arm64, ppc64le)

## Storage

### Persistent Volumes

| Volume | Type | Default Size | Purpose | Access Mode |
|--------|------|--------------|---------|-------------|
| registry-storage | PVC | 5Gi | Registry database (file-based) | ReadWriteOnce |
| online-storage | PVC | 5Gi | Online store database (SQLite) | ReadWriteOnce |
| offline-storage | PVC | 20Gi | Offline store data (Parquet, DuckDB) | ReadWriteOnce |

### ConfigMaps

| ConfigMap | Purpose | Content |
|-----------|---------|---------|
| feast-{name}-client | Feast client configuration | feature_store.yaml with connection details |
| feast-{name}-ca-bundle | Custom CA certificates | Trusted CA bundle for TLS connections |
| feast-configs-registry | Namespace registry | Maps namespaces to FeatureStore instances |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 4436b3c0e | 2026-03 | - Sync pipelineruns with konflux-central<br>- Updated Tekton configurations |
| 5c4078b75 | 2026-03 | - Remove commented restart line from YAML file |
| 18999dd4b | 2026-03 | - Merge pull request #194 for git-auth secret configuration |
| 3177860dc | 2026-03 | - Add git-auth secret to Tekton pipeline configuration |
| e8f97ca13 | 2026-02 | - Update Konflux references (deps) |
| 88edb1c2c | 2026-02 | - Downgrade pyarrow to fix Feast compatibility issues |
| 01a6fa98e | 2026-02 | - Notebook controller to use Kubeflow v1 API |
| d0ca55aee | 2026-02 | - Feast Controller to hold feast Client configmaps for notebook integration |

## Build Configuration

### Container Images

| Image | Dockerfile | Build System | Base Image | Purpose |
|-------|------------|--------------|------------|---------|
| odh-feast-operator | Dockerfiles/Dockerfile.feast-operator.konflux | Konflux | UBI 9 Minimal | Operator manager binary |
| odh-feature-server | Dockerfiles/Dockerfile.feature-server.konflux | Konflux | UBI 9 Python 3.11 | Feature server services |

### Build Features

- **FIPS Mode**: Enabled (GO strictfipsruntime experiment, CGO_ENABLED=1)
- **Multi-arch**: amd64, arm64, ppc64le (conditional prebuild for Power)
- **Security**: Non-root user (65532 for operator, 1001 for feature server)
- **Registry**: Built and pushed via Konflux CI/CD

## Operational Considerations

### High Availability

- **Operator**: Single replica with leader election (lease-based)
- **Feature Services**: Configurable replicas per service type
- **State**: Leader election via Kubernetes leases in operator namespace

### Monitoring

- **Metrics**: Prometheus endpoint at /metrics (8443/TCP)
- **Health Checks**: /healthz (liveness), /readyz (readiness) at 8081/TCP
- **ServiceMonitor**: Automatic discovery by Prometheus Operator

### Backup/Restore

- **Registry**: Backup PVC or database (file/SQL/S3)
- **Online Store**: Backup PVC or database
- **Configuration**: FeatureStore CRs are source of truth

### Troubleshooting

- **Logs**: `kubectl logs -n {namespace} deployment/{feast-operator}`
- **Events**: `kubectl get events -n {namespace}`
- **Status**: `kubectl get featurestore {name} -o yaml` (check .status.conditions)
- **CRD Validation**: Server-side apply required due to CRD size (v1 + v1alpha1)

## Limitations

- **CRD Size**: CRD includes both v1 and v1alpha1, requires `--server-side` for kubectl apply
- **OpenShift Routes**: Only available on OpenShift (falls back to Services on vanilla Kubernetes)
- **TLS Certificates**: Manual provisioning required (no cert-manager integration by default)
- **Notebook Integration**: Optional, requires Kubeflow Notebook CRD
- **Database Support**: Limited to specific backends (SQLite, PostgreSQL, Snowflake, Cassandra)

## Security Hardening

- **Pod Security**: runAsNonRoot, drop ALL capabilities, no privilege escalation
- **Network**: No NetworkPolicy defined (relies on cluster policies)
- **Secrets**: Externally managed (user provides TLS certs, DB credentials, OIDC secrets)
- **Image Scanning**: Konflux pipeline includes vulnerability scanning
- **SBOM**: Software Bill of Materials generated during Konflux build
