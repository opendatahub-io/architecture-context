# Component: Feast (Feature Store)

## Metadata
- **Repository**: https://github.com/feast-dev/feast
- **Version**: 0.61.0
- **Distribution**: ODH and RHOAI
- **Languages**: Python (primary), Go, Java, TypeScript/React
- **Deployment Type**: Kubernetes Operator + Microservices

## Purpose
**Short**: Feature store for machine learning that manages features consistently for training and serving.

**Detailed**: Feast (Feature Store) is an open source feature store for machine learning that helps ML platform teams manage features consistently for training and serving. It provides an offline store to process historical data for batch scoring or model training, a low-latency online store to power real-time predictions, and a battle-tested feature server to serve pre-computed features online. Feast ensures point-in-time correctness to prevent data leakage during model training and decouples ML from data infrastructure by providing a single data access layer that abstracts feature storage from feature retrieval. The system includes a Kubernetes operator that manages the deployment and lifecycle of Feast components, including registry services, feature servers, UI, and optional CronJobs for materialization tasks.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Feast Operator | Kubernetes Operator | Manages FeatureStore CRs and deploys Feast services |
| Feature Server (Online) | HTTP/gRPC Service | Serves pre-computed features for real-time inference |
| Feature Server (Offline) | HTTP Service | Serves historical features for batch scoring/training |
| Registry Service | HTTP/gRPC Service | Stores and serves feature definitions and metadata |
| Transformation Service | HTTP Service | Executes on-demand feature transformations |
| UI Service | Web Application | Web interface for exploring and managing features |
| Online Store | Database Backend | Low-latency storage for online features (Redis, PostgreSQL, etc.) |
| Offline Store | Data Backend | Historical feature storage (BigQuery, Snowflake, Spark, etc.) |
| Python SDK | Client Library | Feature definition and data access for Python applications |
| Go SDK | Client Library | Feature serving for Go applications |
| Java SDK | Client Library | Feature serving for Java applications |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| feast.dev | v1 | FeatureStore | Namespaced | Defines a Feast feature store deployment with online/offline stores, registry, UI, and authorization |
| feast.dev | v1alpha1 | FeatureStore | Namespaced | Legacy API version for FeatureStore (same functionality as v1) |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /get-online-features | POST | 80/TCP | HTTP | None | Optional Bearer/mTLS | Retrieve online features for real-time inference |
| /push | POST | 80/TCP | HTTP | None | Optional Bearer/mTLS | Push features to online/offline stores |
| /materialize | POST | 80/TCP | HTTP | None | Optional Bearer/mTLS | Trigger feature materialization from offline to online |
| /materialize-incremental | POST | 80/TCP | HTTP | None | Optional Bearer/mTLS | Trigger incremental materialization |
| /health | GET | 80/TCP | HTTP | None | None | Health check endpoint |
| /metrics | GET | 8000/TCP | HTTP | None | None | Prometheus metrics endpoint |
| /ui | GET | 80/TCP | HTTP | None | Optional OIDC | Web UI for feature exploration |
| /registry/* | GET/POST | 6572/TCP | HTTP | None | Optional Bearer | REST API for registry operations |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ServingService | 6566/TCP | gRPC | None | Optional mTLS | Get online features via gRPC (GetOnlineFeatures, GetFeastServingInfo) |
| RegistryServer | 6570/TCP | gRPC | None | Optional mTLS | Feature registry operations via gRPC |
| TransformationService | 6569/TCP | gRPC | None | Optional mTLS | Execute feature transformations |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.19+ | Yes | Container orchestration platform |
| Python | 3.10+ | Yes | Runtime for Python SDK and services |
| Go | 1.21+ | No | Build Go-based feature server |
| FastAPI | 0.68.0+ | Yes | HTTP API framework for feature server |
| Uvicorn | 0.30.6-0.34.0 | Yes | ASGI server for Python services |
| Gunicorn | Latest | Yes (Linux) | WSGI HTTP server for production |
| Protobuf | 4.24.0+ | Yes | Data serialization and gRPC definitions |
| Pandas | 1.4.3-3.x | Yes | Data manipulation for features |
| PyArrow | 21.0.0+ | Yes | Columnar data format |
| SQLAlchemy | 1.x+ | Yes | Database abstraction layer |
| Redis | Latest | No | Optional online store backend |
| PostgreSQL | 9.6+ | No | Optional online/offline store backend |
| BigQuery | N/A | No | Optional offline store backend |
| Snowflake | N/A | No | Optional online/offline store backend |
| AWS DynamoDB | N/A | No | Optional online store backend |
| AWS S3 | N/A | No | Optional registry file backend |
| GCS | N/A | No | Optional registry file backend |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Service Mesh (Istio) | mTLS/AuthorizationPolicy | Optional mutual TLS and authorization |
| OpenShift Route | HTTP Ingress | Optional external access to UI and APIs |
| Prometheus | Metrics Scraping | Monitoring and observability |
| cert-manager | TLS Certificates | Optional TLS certificate provisioning |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {name}-feast-online | ClusterIP | 80/TCP | 6566 | HTTP/gRPC | None | Optional | Internal |
| {name}-feast-offline | ClusterIP | 80/TCP | 8815 | HTTP | None | Optional | Internal |
| {name}-feast-registry | ClusterIP | 80/TCP | 6570 | gRPC | None | Optional | Internal |
| {name}-feast-registry-rest | ClusterIP | 80/TCP | 6572 | HTTP | None | Optional | Internal |
| {name}-feast-ui | ClusterIP | 80/TCP | 8888 | HTTP | None | Optional OIDC | Internal |
| {name}-feast-transformation | ClusterIP | 80/TCP | 6569 | gRPC | None | Optional | Internal |
| feast-operator-metrics | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | Bearer Token | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {name}-feast-ui-route | OpenShift Route | *.cluster.local | 443/TCP | HTTPS | TLS 1.2+ | Edge Termination | External |
| {name}-feast-online-ingress | Kubernetes Ingress | Configurable | 443/TCP | HTTPS | TLS 1.2+ | TLS Termination | External (Optional) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| External Database (PostgreSQL) | 5432/TCP | PostgreSQL | TLS 1.2+ | User/Password | Online/offline store backend |
| External Database (Redis) | 6379/TCP | Redis | TLS (Optional) | Password | Online store backend |
| AWS S3 | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM | Registry file backend |
| GCS | 443/TCP | HTTPS | TLS 1.2+ | GCP Service Account | Registry file backend |
| BigQuery | 443/TCP | HTTPS | TLS 1.2+ | GCP Service Account | Offline store backend |
| Snowflake | 443/TCP | HTTPS | TLS 1.2+ | User/Password/OAuth | Online/offline store backend |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | feast.dev | featurestores, featurestores/status, featurestores/finalizers | get, list, watch, create, update, patch, delete |
| manager-role | apps | deployments | get, list, watch, create, update, delete |
| manager-role | "" | services, configmaps, persistentvolumeclaims, serviceaccounts | get, list, watch, create, update, delete |
| manager-role | "" | secrets, pods, namespaces | get, list, watch |
| manager-role | "" | pods/exec | create |
| manager-role | rbac.authorization.k8s.io | roles, rolebindings, clusterroles, clusterrolebindings, subjectaccessreviews | get, list, watch, create, update, delete |
| manager-role | authentication.k8s.io | tokenreviews | create |
| manager-role | route.openshift.io | routes | get, list, watch, create, update, delete |
| manager-role | batch | cronjobs | get, list, watch, create, update, patch, delete |
| manager-role | autoscaling | horizontalpodautoscalers | get, list, watch, create, update, patch, delete |
| manager-role | policy | poddisruptionbudgets | get, list, watch, create, update, patch, delete |
| manager-role | apiextensions.k8s.io | customresourcedefinitions | get, list |
| featurestore-editor-role | feast.dev | featurestores, featurestores/status | get, list, watch, create, update, patch, delete |
| featurestore-viewer-role | feast.dev | featurestores, featurestores/status | get, list, watch |
| metrics-reader | "" | pods, services, endpoints | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | feast-operator-system | manager-role | feast-operator-controller-manager |
| leader-election-rolebinding | feast-operator-system | leader-election-role | feast-operator-controller-manager |
| metrics-auth-rolebinding | feast-operator-system | metrics-auth-role | feast-operator-controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {name}-feast-tls | kubernetes.io/tls | TLS certificates for HTTPS endpoints | cert-manager | Yes |
| {name}-feast-secret | Opaque | Database credentials and API keys | User/External Secrets Operator | No |
| {name}-feast-registry-secret | Opaque | Registry backend credentials (S3, GCS) | User/External Secrets Operator | No |
| {name}-feast-oidc-secret | Opaque | OIDC client credentials for UI authentication | User | No |
| feast-operator-webhook-server-cert | kubernetes.io/tls | Webhook server certificate (future use) | cert-manager | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /get-online-features | POST | Bearer Token (JWT) | FastAPI middleware | Optional, configured via authz.kubernetes or authz.oidc |
| /push | POST | Bearer Token (JWT) | FastAPI middleware | Optional, requires WRITE permission |
| /materialize | POST | Bearer Token (JWT) | FastAPI middleware | Optional, requires WRITE permission |
| gRPC ServingService | All | mTLS client certificates | Istio PeerAuthentication | Optional, Istio-based |
| /ui | GET | OIDC (OpenID Connect) | FastAPI OAuth2 | Optional, configured via authz.oidc |
| /metrics | GET | None | None | Unauthenticated, internal only |
| Operator Metrics | GET | Bearer Token (ServiceAccount) | kube-rbac-proxy | Kubernetes RBAC |

## Data Flows

### Flow 1: Real-Time Feature Retrieval (Online Serving)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | ML Application | Feature Server (Online) | 80/TCP | HTTP | None | Optional Bearer Token |
| 2 | Feature Server (Online) | Registry Service | 6570/TCP | gRPC | None | None |
| 3 | Feature Server (Online) | Online Store (Redis/PostgreSQL) | 6379/5432/TCP | Redis/PostgreSQL | TLS (Optional) | Password/mTLS |
| 4 | Feature Server (Online) | Transformation Service | 6569/TCP | gRPC | None | None |
| 5 | Feature Server (Online) | ML Application | 80/TCP | HTTP | None | None |

### Flow 2: Historical Feature Retrieval (Offline Serving)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | ML Training Job | Feature Server (Offline) | 8815/TCP | HTTP | None | Optional Bearer Token |
| 2 | Feature Server (Offline) | Registry Service | 6570/TCP | gRPC | None | None |
| 3 | Feature Server (Offline) | Offline Store (BigQuery/Snowflake) | 443/TCP | HTTPS | TLS 1.2+ | Cloud IAM |
| 4 | Feature Server (Offline) | ML Training Job | 8815/TCP | HTTP | None | None |

### Flow 3: Feature Materialization (Offline to Online)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CronJob | Feature Server (Online) | 80/TCP | HTTP | None | Bearer Token |
| 2 | Feature Server (Online) | Offline Store (BigQuery/Snowflake) | 443/TCP | HTTPS | TLS 1.2+ | Cloud IAM |
| 3 | Feature Server (Online) | Online Store (Redis/PostgreSQL) | 6379/5432/TCP | Redis/PostgreSQL | TLS (Optional) | Password |

### Flow 4: Feature Push (Stream to Online/Offline)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Stream Processing App | Feature Server (Online) | 80/TCP | HTTP | None | Bearer Token |
| 2 | Feature Server (Online) | Online Store (Redis/PostgreSQL) | 6379/5432/TCP | Redis/PostgreSQL | TLS (Optional) | Password |
| 3 | Feature Server (Online) | Offline Store (Optional) | 443/TCP | HTTPS | TLS 1.2+ | Cloud IAM |

### Flow 5: Operator Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Feast Operator | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Feast Operator | FeatureStore Deployments | N/A | N/A | N/A | N/A |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| MLflow | Python SDK | N/A | Python API | N/A | Feature selection and model lifecycle integration |
| Kubeflow | Python SDK | N/A | Python API | N/A | Feature serving in ML pipelines |
| Seldon Core | gRPC/HTTP | 6566/80/TCP | gRPC/HTTP | Optional TLS | Feature retrieval for model serving |
| KServe | gRPC/HTTP | 6566/80/TCP | gRPC/HTTP | Optional TLS | Feature retrieval for model serving |
| Apache Spark | Python SDK | N/A | Python API | N/A | Batch feature engineering and offline store |
| Dask | Python SDK | N/A | Python API | N/A | Distributed batch feature engineering |
| Ray | Python SDK | N/A | Python API | N/A | Distributed batch feature engineering |
| Kafka | Python SDK | 9092/TCP | Kafka | TLS (Optional) | Streaming feature ingestion |
| OpenLineage | Python SDK | 443/TCP | HTTP | TLS 1.2+ | Data lineage tracking |
| OpenTelemetry | OTLP | 4317/TCP | gRPC | Optional TLS | Distributed tracing and metrics |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 0.61.0 | 2025-01 | - Added MongoDB online store support<br>- Feature server high-availability on Kubernetes<br>- Added materialization, freshness, latency, and push metrics<br>- Support for ARM Docker builds<br>- MLflow integration for feature selection<br>- Optimized DynamoDB batch reads with parallelization<br>- Fixed duplicate feature view name checks<br>- Added non-entity retrieval for ClickHouse offline store |
| 0.60.x | 2024-12 | - Enhanced Kubeflow integration<br>- Added OpenLineage integration example<br>- Improved registry REST API tests for OpenShift<br>- Feature view source made optional<br>- Added optional name field to Aggregation |
| 0.59.x | 2024-11 | - Performance optimizations for timestamp conversion<br>- Component-based test organization<br>- Enhanced Ray and Spark test coverage |

## Deployment Configurations

### Deployment Modes

| Mode | Description | Components Deployed |
|------|-------------|---------------------|
| Online Only | Real-time feature serving | Feature Server (Online), Registry, Online Store |
| Offline Only | Historical feature retrieval | Feature Server (Offline), Registry, Offline Store |
| Full | Complete feature store | All components (Online, Offline, Registry, UI, Transformation) |
| UI | Web UI for exploration | UI Service, Registry |
| Registry | Standalone registry | Registry Service |

### Persistence Options

| Storage Type | Supported Backends | Use Case |
|--------------|-------------------|----------|
| Online Store | Redis, PostgreSQL, DynamoDB, Bigtable, Cassandra, ClickHouse, MongoDB, Snowflake, SQLite | Low-latency online features |
| Offline Store | BigQuery, Snowflake, Redshift, PostgreSQL, Spark, Dask, DuckDB, Trino | Historical features for training |
| Registry | PostgreSQL, SQLite, S3, GCS, File (PVC) | Feature definitions and metadata |

### Scaling Configuration

| Configuration | Type | Purpose |
|--------------|------|---------|
| Horizontal Pod Autoscaler | Autoscaling | Auto-scale feature server pods based on CPU/memory |
| Manual Replicas | Static Scaling | Set fixed replica count (requires DB-backed persistence) |
| Pod Disruption Budget | High Availability | Ensure minimum pods during disruptions |

## Security Considerations

1. **Authentication**: Supports optional OIDC for UI, Kubernetes RBAC for feature-level authorization, and bearer tokens for API access
2. **Authorization**: Fine-grained permissions via Kubernetes RBAC (read/write on feature views, services, etc.)
3. **Encryption in Transit**: Optional TLS for external databases, Istio mTLS for service mesh integration
4. **Encryption at Rest**: Depends on backend storage (Cloud KMS, database encryption)
5. **Secret Management**: Kubernetes Secrets for credentials, External Secrets Operator integration recommended
6. **Network Policies**: Not included by default, can be added for namespace isolation
7. **Pod Security**: Runs as non-root user (configurable), no default SecurityContext constraints
8. **Audit Logging**: Available via Kubernetes audit logs and application logs

## Observability

| Metric Type | Endpoint | Port | Purpose |
|-------------|----------|------|---------|
| Prometheus Metrics | /metrics | 8000/TCP | Feature server request latency, materialization metrics, feature freshness, push metrics |
| Operator Metrics | /metrics | 8443/TCP | Operator reconciliation metrics, CR status |
| Health Checks | /health | 80/TCP | Liveness and readiness probes |
| Logs | stdout/stderr | N/A | Structured JSON logs (configurable log level) |
| Tracing | OTLP endpoint | 4317/TCP | Distributed tracing with OpenTelemetry (optional) |

## Known Limitations

1. **Scaling**: Autoscaling and replicas > 1 require database-backed persistence for online store, offline store, and registry
2. **Service Mesh**: Istio integration is optional and not configured by default
3. **Multi-tenancy**: Single FeatureStore CR per namespace (namespace registry tracks deployments)
4. **Backward Compatibility**: v1alpha1 API is deprecated, v1 is the storage version
5. **Storage Backends**: Some online/offline store combinations have limitations (check Feast documentation)
6. **Transformation Service**: Python transformations only (Go transformations experimental)
