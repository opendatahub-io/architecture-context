# Component: Feast (Feature Store)

## Metadata
- **Repository**: https://github.com/red-hat-data-services/feast.git
- **Version**: 98a224e7c (rhoai-3.3 branch)
- **Distribution**: RHOAI
- **Languages**: Go (operator), Python (feature servers), Java, TypeScript/React (UI)
- **Deployment Type**: Kubernetes Operator + Feature Server Services
- **Manifests Location**: infra/feast-operator/config

## Purpose
**Short**: Kubernetes operator for managing Feast, an open-source feature store for machine learning that provides consistent feature access for training and serving.

**Detailed**:

Feast (Feature Store) is a comprehensive feature store platform that enables ML teams to manage, serve, and track features for machine learning models. The Feast Operator automates the deployment and lifecycle management of Feast feature store instances in Kubernetes/OpenShift environments. It provides a declarative approach to configuring feature stores with support for multiple persistence backends (SQLite, PostgreSQL, S3, Redis), authentication mechanisms (OIDC, Kubernetes RBAC), and deployment topologies.

The operator manages multiple microservices that work together: an online feature server for low-latency real-time predictions, an offline feature server for batch scoring and training, a registry server for feature metadata management, and an optional web UI for feature discovery. It ensures point-in-time correct feature retrieval, preventing data leakage during model training, and provides a unified data access layer that decouples ML workloads from underlying storage infrastructure.

The platform supports various materialization strategies through CronJobs, enabling scheduled feature updates from offline to online stores. It integrates with RHOAI's authentication and monitoring infrastructure, supporting OpenShift Routes for external access and Prometheus metrics for observability.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Feast Operator | Kubernetes Operator | Manages FeatureStore custom resources, deploying and configuring Feast services |
| Online Feature Server | Python FastAPI Service | Serves features for real-time inference with low latency |
| Offline Feature Server | Python FastAPI Service | Serves historical features for model training and batch scoring |
| Registry Server | Python gRPC/REST Service | Manages feature metadata (entities, feature views, data sources) |
| UI Server | React/TypeScript Web App | Provides web interface for feature discovery and exploration |
| Client ConfigMap | ConfigMap | Contains feature_store.yaml configuration for client access |
| CronJob (Optional) | Kubernetes CronJob | Executes scheduled materialization tasks |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| feast.dev | v1 | FeatureStore | Namespaced | Defines a Feast feature store deployment with registry, online/offline stores, authentication, and persistence configuration |

### HTTP Endpoints

#### Online Feature Server

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /health | GET | 6566/TCP | HTTP | None | None | Health check endpoint |
| /get-online-features | POST | 6566/TCP | HTTP | None | Bearer/mTLS/None | Retrieve online features for real-time inference |
| /push | POST | 6566/TCP | HTTP | None | Bearer/mTLS/None | Push feature data to online store |
| /materialize | POST | 6566/TCP | HTTP | None | Bearer/mTLS/None | Trigger feature materialization |
| /health | GET | 6567/TCP | HTTPS | TLS 1.2+ | None | Health check endpoint (TLS) |
| /get-online-features | POST | 6567/TCP | HTTPS | TLS 1.2+ | Bearer/mTLS | Retrieve online features (TLS) |
| /metrics | GET | 8000/TCP | HTTP | None | None | Prometheus metrics |

#### Offline Feature Server

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /health | GET | 8815/TCP | HTTP | None | None | Health check endpoint |
| /get-historical-features | POST | 8815/TCP | HTTP | None | Bearer/mTLS/None | Retrieve historical features for training |
| /health | GET | 8816/TCP | HTTPS | TLS 1.2+ | None | Health check endpoint (TLS) |
| /get-historical-features | POST | 8816/TCP | HTTPS | TLS 1.2+ | Bearer/mTLS | Retrieve historical features (TLS) |
| /metrics | GET | 8000/TCP | HTTP | None | None | Prometheus metrics |

#### Registry Server (REST)

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /health | GET | 6572/TCP | HTTP | None | None | Health check endpoint |
| /registry | GET/POST/PUT/DELETE | 6572/TCP | HTTP | None | Bearer/mTLS/None | REST API for registry operations |
| /health | GET | 6573/TCP | HTTPS | TLS 1.2+ | None | Health check endpoint (TLS) |
| /registry | GET/POST/PUT/DELETE | 6573/TCP | HTTPS | TLS 1.2+ | Bearer/mTLS | REST API for registry operations (TLS) |

#### UI Server

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| / | GET | 8888/TCP | HTTP | None | None | Web UI for feature exploration |
| /api/* | GET/POST | 8888/TCP | HTTP | None | None | UI backend API |
| / | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | Web UI for feature exploration (TLS) |
| /api/* | GET/POST | 8443/TCP | HTTPS | TLS 1.2+ | None | UI backend API (TLS) |

#### Feast Operator

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | Token Review | Prometheus metrics for operator |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe |

### gRPC Services

#### ServingService (Online Features)

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| feast.serving.ServingService | 6566/TCP | gRPC | None | None | Get online features for inference |
| feast.serving.ServingService | 6567/TCP | gRPC | mTLS | Client Cert | Get online features for inference (TLS) |
| GetFeastServingInfo | 6566/TCP | gRPC | None | None | Retrieve Feast version information |
| GetOnlineFeatures | 6566/TCP | gRPC | None | Bearer/mTLS/None | Synchronously retrieve online features |

#### RegistryServer (Feature Metadata)

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| feast.registry.RegistryServer | 6570/TCP | gRPC | None | None | Manage feature registry metadata |
| feast.registry.RegistryServer | 6571/TCP | gRPC | mTLS | Client Cert | Manage feature registry metadata (TLS) |
| ApplyEntity | 6570/TCP | gRPC | None | Bearer/mTLS/None | Create/update entity definitions |
| GetEntity | 6570/TCP | gRPC | None | Bearer/mTLS/None | Retrieve entity definitions |
| ApplyFeatureView | 6570/TCP | gRPC | None | Bearer/mTLS/None | Create/update feature view definitions |
| GetFeatureView | 6570/TCP | gRPC | None | Bearer/mTLS/None | Retrieve feature view definitions |
| ApplyFeatureService | 6570/TCP | gRPC | None | Bearer/mTLS/None | Create/update feature service definitions |
| ListFeatures | 6570/TCP | gRPC | None | Bearer/mTLS/None | List all features in registry |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | v1.11.3+ | Yes | Container orchestration platform |
| Python | 3.11 | Yes | Runtime for feature servers |
| Go | 1.22+ | Yes (build) | Runtime for operator |
| SQLite | 3.x | No | Default embedded registry/online store |
| PostgreSQL | 9.6+ | No | Optional persistent registry/online store |
| Redis | 5.0+ | No | Optional online store for high-performance serving |
| S3-compatible storage | - | No | Optional object store for registry/offline data |
| OpenShift | 4.17+ | No | Optional for Routes and enhanced RBAC |

### Internal RHOAI/ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| OpenShift Routes | API (route.openshift.io/v1) | External access to feature servers and UI |
| Kubeflow Notebooks | CRD Watch (kubeflow.org/notebooks) | Inject client configuration into notebook environments |
| cert-manager | TLS Secrets | Optional TLS certificate provisioning for services |
| Prometheus | Metrics Scraping | Monitoring feature server and operator metrics |
| OpenShift OAuth | OIDC Authentication | Optional user authentication for feature access |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {name}-online | ClusterIP | 80/TCP | 6566 | HTTP | None | None | Internal |
| {name}-online | ClusterIP | 443/TCP | 6567 | HTTPS | TLS 1.2+ | mTLS | Internal |
| {name}-offline | ClusterIP | 80/TCP | 8815 | HTTP | None | None | Internal |
| {name}-offline | ClusterIP | 443/TCP | 8816 | HTTPS | TLS 1.2+ | mTLS | Internal |
| {name}-registry | ClusterIP | 80/TCP | 6570 | gRPC | None | None | Internal |
| {name}-registry | ClusterIP | 443/TCP | 6571 | gRPC | TLS 1.2+ | mTLS | Internal |
| {name}-registry-rest | ClusterIP | 80/TCP | 6572 | HTTP | None | None | Internal |
| {name}-registry-rest | ClusterIP | 443/TCP | 6573 | HTTPS | TLS 1.2+ | mTLS | Internal |
| {name}-ui | ClusterIP | 80/TCP | 8888 | HTTP | None | None | Internal |
| {name}-ui | ClusterIP | 443/TCP | 8443 | HTTPS | TLS 1.2+ | None | Internal |
| feast-operator-metrics | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | Token Review | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {name}-online | OpenShift Route | {name}-online-{namespace}.apps.cluster | 443/TCP | HTTPS | TLS 1.2+ | Edge | External |
| {name}-offline | OpenShift Route | {name}-offline-{namespace}.apps.cluster | 443/TCP | HTTPS | TLS 1.2+ | Edge | External |
| {name}-registry | OpenShift Route | {name}-registry-{namespace}.apps.cluster | 443/TCP | HTTPS | TLS 1.2+ | Edge | External |
| {name}-ui | OpenShift Route | {name}-ui-{namespace}.apps.cluster | 443/TCP | HTTPS | TLS 1.2+ | Edge | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| PostgreSQL (optional) | 5432/TCP | PostgreSQL | TLS 1.2+ | Password | Persistent registry/online store |
| Redis (optional) | 6379/TCP | Redis | TLS 1.2+ | Password | High-performance online store |
| S3/Object Storage (optional) | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Access Key | Registry persistence and offline data |
| External Git (optional) | 443/TCP | HTTPS | TLS 1.2+ | Token/SSH Key | Feature repository synchronization |
| OIDC Provider (optional) | 443/TCP | HTTPS | TLS 1.2+ | None | Authentication token validation |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | feast.dev | featurestores | get, list, watch, create, update, patch, delete |
| manager-role | feast.dev | featurestores/status | get, update, patch |
| manager-role | feast.dev | featurestores/finalizers | update |
| manager-role | apps | deployments | get, list, watch, create, update, delete |
| manager-role | "" (core) | services, configmaps, persistentvolumeclaims, serviceaccounts | get, list, watch, create, update, delete |
| manager-role | "" (core) | secrets, pods, namespaces | get, list, watch |
| manager-role | "" (core) | pods/exec | create |
| manager-role | "" (core) | configmaps | create, delete, get, list, patch, update, watch |
| manager-role | batch | cronjobs | get, list, watch, create, update, patch, delete |
| manager-role | rbac.authorization.k8s.io | roles, rolebindings, clusterroles, clusterrolebindings | get, list, watch, create, update, delete |
| manager-role | rbac.authorization.k8s.io | subjectaccessreviews | create |
| manager-role | authentication.k8s.io | tokenreviews | create |
| manager-role | route.openshift.io | routes | get, list, watch, create, update, delete |
| manager-role | kubeflow.org | notebooks | get, list, watch |
| manager-role | apiextensions.k8s.io | customresourcedefinitions | get, list |
| featurestore-editor-role | feast.dev | featurestores | get, list, watch, create, update, patch, delete |
| featurestore-viewer-role | feast.dev | featurestores | get, list, watch |
| leader-election-role | "" (core) | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| metrics-auth-role | authentication.k8s.io | tokenreviews | create |
| metrics-auth-role | authorization.k8s.io | subjectaccessreviews | create |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-role-binding | feast-operator-system | manager-role (ClusterRole) | controller-manager |
| leader-election-role-binding | feast-operator-system | leader-election-role | controller-manager |
| metrics-auth-role-binding | feast-operator-system | metrics-auth-role (ClusterRole) | controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {name}-client-tls | kubernetes.io/tls | TLS certificates for client mTLS | User/cert-manager | No |
| {name}-server-tls | kubernetes.io/tls | TLS certificates for server endpoints | User/cert-manager | No |
| {name}-oidc | Opaque | OIDC credentials (client_id, client_secret, etc.) | User | No |
| {name}-db-secret | Opaque | Database credentials for PostgreSQL | User | No |
| {name}-redis-secret | Opaque | Redis connection credentials | User | No |
| {name}-s3-secret | Opaque | S3 access credentials | User | No |
| {name}-git-token | Opaque | Git repository access token | User | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /get-online-features | POST | Bearer Token (JWT) | Feature Server | OIDC token validation |
| /get-online-features | POST | mTLS | Feature Server | Client certificate validation |
| /get-online-features | POST | Kubernetes RBAC | Feature Server | SubjectAccessReview for FeatureStore resource |
| /get-historical-features | POST | Bearer Token (JWT) | Feature Server | OIDC token validation |
| /registry/* | GET/POST/PUT/DELETE | Bearer Token (JWT) | Registry Server | OIDC token validation |
| /registry/* | GET/POST/PUT/DELETE | Kubernetes RBAC | Registry Server | SubjectAccessReview for FeatureStore resource |
| /metrics | GET | Token Review | Operator | Kubernetes TokenReview API |
| gRPC ServingService | All | Bearer Token (JWT) | Feature Server | OIDC token validation via metadata |
| gRPC RegistryServer | All | Bearer Token (JWT) | Registry Server | OIDC token validation via metadata |

## Data Flows

### Flow 1: Online Feature Retrieval (Real-time Inference)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | ML Application | Online Feature Server | 6566/TCP or 6567/TCP | gRPC/HTTP | TLS 1.2+ (optional) | Bearer/mTLS/None |
| 2 | Online Feature Server | SQLite/Redis/PostgreSQL | 6379/TCP or 5432/TCP | Redis/PostgreSQL | TLS 1.2+ (optional) | Password |
| 3 | Online Feature Server | Registry Server | 6570/TCP or 6571/TCP | gRPC | TLS 1.2+ (optional) | Bearer/mTLS/None |
| 4 | Online Feature Server | ML Application | - | gRPC/HTTP | TLS 1.2+ (optional) | - |

### Flow 2: Historical Feature Retrieval (Training)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Training Job | Offline Feature Server | 8815/TCP or 8816/TCP | HTTP/HTTPS | TLS 1.2+ (optional) | Bearer/mTLS/None |
| 2 | Offline Feature Server | Registry Server | 6570/TCP or 6571/TCP | gRPC | TLS 1.2+ (optional) | Bearer/mTLS/None |
| 3 | Offline Feature Server | S3/Object Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM |
| 4 | Offline Feature Server | Training Job | - | HTTP/HTTPS | TLS 1.2+ (optional) | - |

### Flow 3: Feature Materialization (Offline to Online)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | CronJob | Online Feature Server | 6566/TCP or 6567/TCP | HTTP/HTTPS | TLS 1.2+ (optional) | Bearer/mTLS/None |
| 2 | Online Feature Server | Offline Feature Server | 8815/TCP or 8816/TCP | HTTP/HTTPS | TLS 1.2+ (optional) | Bearer/mTLS/None |
| 3 | Online Feature Server | SQLite/Redis/PostgreSQL | 6379/TCP or 5432/TCP | Redis/PostgreSQL | TLS 1.2+ (optional) | Password |

### Flow 4: Feature Registry Management

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | feast CLI / SDK | Registry Server | 6570/TCP or 6571/TCP | gRPC | TLS 1.2+ (optional) | Bearer/mTLS/None |
| 2 | Registry Server | SQLite/PostgreSQL/S3 | 5432/TCP or 443/TCP | PostgreSQL/HTTPS | TLS 1.2+ (optional) | Password/AWS IAM |
| 3 | Registry Server | feast CLI / SDK | - | gRPC | TLS 1.2+ (optional) | - |

### Flow 5: Operator Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Feast Operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | Service Account Token |
| 2 | Feast Operator | Managed Deployments | - | - | - | - |
| 3 | Feast Operator | OpenShift Route API | 6443/TCP | HTTPS | TLS 1.3 | Service Account Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubeflow Notebooks | ConfigMap Injection | - | - | - | Automatically inject feast client configuration into notebooks |
| Prometheus | Metrics Scraping | 8000/TCP | HTTP | None | Monitor feature server performance and usage |
| Prometheus | Metrics Scraping | 8443/TCP | HTTPS | TLS 1.2+ | Monitor operator health and reconciliation |
| OpenShift Routes | Route API | 6443/TCP | HTTPS | TLS 1.3 | Create external access points for feature servers |
| PostgreSQL | Database Protocol | 5432/TCP | PostgreSQL | TLS 1.2+ | Persistent storage for registry and online features |
| Redis | Redis Protocol | 6379/TCP | Redis | TLS 1.2+ | High-performance online feature storage |
| S3/Object Storage | S3 API | 443/TCP | HTTPS | TLS 1.2+ | Store offline features and registry metadata |
| OIDC Provider | OIDC Discovery | 443/TCP | HTTPS | TLS 1.2+ | Validate authentication tokens for feature access |
| Git Repository | Git Protocol | 443/TCP | HTTPS | TLS 1.2+ | Synchronize feature definitions from Git |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 98a224e7c | 2026-03-13 | - sync pipelineruns with konflux-central - 9fd8f6f |
| 1dc378c5a | 2026-03 | - Update odh-feature-server-v3-3-push.yaml |
| ee5b7a760 | 2026-02 | - Clean up document endpoints |
| 77311deab | 2026-02 | - Update cython to fix pyarrow v22 build |
| 590a26068 | 2026-02 | - Upgrade pyarrow |
| 6214d0596 | 2025-12 | - Release 0.59.0 |
| ab3562bee | 2025-12 | - Add progress bar to CLI from feast apply |
| b997361ba | 2025-12 | - Add dbt integration for importing models as FeatureViews |
| f6116f9b8 | 2025-12 | - Improve lambda materialization engine |
| a536bc24e | 2025-11 | - Make operator include full OIDC secret in repo config |

## Deployment Configuration

### Container Images

| Image | Purpose | Build Method | Base Image |
|-------|---------|--------------|------------|
| odh-feast-operator | Kubernetes operator | Konflux | registry.access.redhat.com/ubi9/ubi-minimal |
| odh-feature-server | Feature servers (online/offline/registry/ui) | Konflux | registry.access.redhat.com/ubi9/python-311 |
| origin-cli:4.17 | CronJob executor | External | OpenShift CLI tools |

### Resource Requirements

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| Feast Operator | 10m | 1000m | 64Mi | 256Mi |
| Online Feature Server | 100m (default) | 1000m (default) | 128Mi (default) | 512Mi (default) |
| Offline Feature Server | 100m (default) | 1000m (default) | 128Mi (default) | 512Mi (default) |
| Registry Server | 100m (default) | 1000m (default) | 128Mi (default) | 512Mi (default) |
| UI Server | 100m (default) | 1000m (default) | 128Mi (default) | 512Mi (default) |

### Storage Requirements

| Component | Default Size | Access Mode | Purpose |
|-----------|--------------|-------------|---------|
| Registry PVC | 5Gi | ReadWriteOnce | SQLite registry persistence |
| Online Store PVC | 5Gi | ReadWriteOnce | SQLite online store persistence |
| Offline Store PVC | 20Gi | ReadWriteOnce | Offline feature data storage |

## Observability

### Metrics Exposed

| Metric Name | Type | Port | Purpose |
|-------------|------|------|---------|
| feast_server_requests_total | Counter | 8000/TCP | Total number of feature requests |
| feast_server_request_duration_seconds | Histogram | 8000/TCP | Feature request latency |
| feast_server_features_served_total | Counter | 8000/TCP | Total number of features served |
| feast_server_errors_total | Counter | 8000/TCP | Total number of errors |
| controller_runtime_reconcile_total | Counter | 8443/TCP | Operator reconciliation count |
| controller_runtime_reconcile_errors_total | Counter | 8443/TCP | Operator reconciliation errors |

### Health Probes

| Component | Liveness Path | Readiness Path | Port | Protocol |
|-----------|---------------|----------------|------|----------|
| Feast Operator | /healthz | /readyz | 8081/TCP | HTTP |
| Online Feature Server | /health | /health | 6566/TCP | HTTP |
| Offline Feature Server | /health | /health | 8815/TCP | HTTP |
| Registry Server | TCP Check | /health (REST) | 6570/TCP (gRPC) | gRPC/HTTP |
| UI Server | /health | /health | 8888/TCP | HTTP |

## Configuration

### FeatureStore CR Examples

**Minimal Configuration:**
```yaml
apiVersion: feast.dev/v1
kind: FeatureStore
metadata:
  name: sample
spec:
  feastProject: my_project
```

**With PostgreSQL and OIDC:**
```yaml
apiVersion: feast.dev/v1
kind: FeatureStore
metadata:
  name: feast-postgres
spec:
  feastProject: production
  authz:
    oidc:
      secretRef:
        name: feast-oidc-secret
  services:
    registry:
      persistence:
        dbPersistence:
          type: postgresql
          host: postgres.database.svc
          port: 5432
          database: feast_registry
          secretRef:
            name: postgres-secret
    online:
      persistence:
        dbPersistence:
          type: postgresql
          host: postgres.database.svc
          port: 5432
          database: feast_online
          secretRef:
            name: postgres-secret
```

## Known Limitations

1. **Scalability**: Online feature server is designed for low-latency single-instance deployment; horizontal scaling requires external load balancing
2. **Storage**: Default SQLite storage is single-node only; multi-node deployments require PostgreSQL or Redis
3. **Feature Materialization**: CronJob-based materialization may have latency depending on data volume
4. **TLS Configuration**: Requires manual certificate provisioning unless cert-manager is available
5. **Multi-tenancy**: Single FeatureStore CR per namespace recommended; cross-namespace access not supported

## Troubleshooting

### Common Issues

| Issue | Symptom | Resolution |
|-------|---------|------------|
| FeatureStore not ready | Status shows `FailedReason` | Check operator logs and deployment status |
| Feature retrieval timeout | gRPC/HTTP timeout errors | Verify network connectivity and service readiness |
| Registry not found | "Registry not found" errors | Ensure registry is properly initialized and accessible |
| OIDC auth failures | 401 Unauthorized errors | Validate OIDC secret configuration and token validity |
| PVC mount failures | Pods stuck in `Pending` | Check PVC provisioning and storage class availability |

### Debug Commands

```bash
# Check FeatureStore status
kubectl get featurestore -n <namespace>
kubectl describe featurestore <name> -n <namespace>

# Check operator logs
kubectl logs -n feast-operator-system deployment/feast-operator-controller-manager

# Check feature server logs
kubectl logs -n <namespace> deployment/<name>-online
kubectl logs -n <namespace> deployment/<name>-registry

# Test feature retrieval
curl -X POST http://<name>-online.<namespace>.svc/get-online-features \
  -H "Content-Type: application/json" \
  -d '{"features": ["feature_view:feature_name"], "entities": {"entity_id": [1]}}'
```
