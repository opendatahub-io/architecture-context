# Component: TrustyAI Service Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/trustyai-service-operator
- **Version**: 1.17.0 (commit: 13e5065)
- **Branch**: rhoai-2.15
- **Distribution**: RHOAI (also supports ODH)
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator
- **Container Build**: Konflux (Dockerfile.konflux)

## Purpose
**Short**: Kubernetes operator that manages the deployment and lifecycle of TrustyAI service instances for AI/ML model explainability and bias detection.

**Detailed**: The TrustyAI Service Operator simplifies the deployment and management of TrustyAI services on Kubernetes and OpenShift clusters. It watches for custom resources of kind `TrustyAIService` in the `trustyai.opendatahub.io` API group and manages all associated resources including deployments, services, routes, ServiceMonitors, and storage. The operator automatically integrates TrustyAI with KServe InferenceServices for model monitoring, configures OAuth-based authentication via sidecar proxies, provisions Prometheus metrics collection, and manages both PVC-based and database-backed storage options. It also handles Istio service mesh integration with VirtualServices and DestinationRules for secure communication within the mesh.

The operator ensures that TrustyAI services are properly secured with TLS, discoverable by Prometheus for metrics scraping, accessible via OpenShift Routes, and configured to monitor InferenceServices for explainability metrics like Statistical Parity Difference (SPD) and Disparate Impact Ratio (DIR).

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| TrustyAI Service Operator | Go Operator | Reconciles TrustyAIService CRDs and manages all associated Kubernetes resources |
| TrustyAI Service Deployment | Managed Deployment | Deployed instances of TrustyAI service with OAuth proxy sidecar |
| OAuth Proxy Sidecar | Authentication Proxy | Provides OpenShift OAuth authentication for TrustyAI service access |
| ServiceMonitor Controller | Sub-controller | Creates and manages Prometheus ServiceMonitor resources |
| InferenceService Handler | Sub-controller | Patches KServe InferenceServices with TrustyAI payload processor configuration |
| Storage Manager | Sub-controller | Manages PVC provisioning or database configuration validation |
| Route Controller | Sub-controller | Creates and manages OpenShift Routes for external access |
| Istio Integration | Sub-controller | Manages VirtualServices and DestinationRules for service mesh traffic |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| trustyai.opendatahub.io | v1alpha1 | TrustyAIService | Namespaced | Defines a TrustyAI service instance with storage, metrics scheduling, and data format configuration |

**TrustyAIService Spec Fields:**
- `storage.format`: PVC or DATABASE storage backend
- `storage.folder`: Data folder path for PVC storage
- `storage.size`: PVC size (e.g., "1Gi")
- `storage.databaseConfigurations`: Secret name containing database credentials
- `data.filename`: Data file name (e.g., "data.csv")
- `data.format`: Data format (CSV or HIBERNATE)
- `metrics.schedule`: Metrics collection schedule (e.g., "5s")
- `metrics.batchSize`: Batch size for metrics processing (default: 5000)
- `replicas`: Number of replicas (optional)

**TrustyAIService Status Conditions:**
- `InferenceServicesPresent`: Tracks availability of KServe InferenceServices
- `PVCAvailable`: Tracks PersistentVolumeClaim availability
- `RouteAvailable`: Tracks OpenShift Route availability
- `DBAvailable`: Tracks database connection status
- `Available`: Overall service availability

### HTTP Endpoints

#### Operator Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for operator |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator health check (liveness) |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness check |

#### TrustyAI Service Endpoints (Managed by Operator)

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /q/health/ready | GET | 8080/TCP | HTTP | None | Internal | TrustyAI service readiness probe |
| /q/health/live | GET | 8080/TCP | HTTP | None | Internal | TrustyAI service liveness probe |
| /q/metrics | GET | 8080/TCP | HTTP | None | Internal | Prometheus metrics (trustyai_spd, trustyai_dir) |
| /oauth/healthz | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | OAuth proxy health check |
| /* | ALL | 8443/TCP | HTTPS | TLS 1.2+ | OpenShift OAuth | Proxied access to TrustyAI service APIs |

### gRPC Services

No gRPC services exposed.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.19+ | Yes | Container orchestration platform |
| OpenShift | 4.6+ | No | Enhanced features (Routes, OAuth, service-serving certs) |
| Prometheus Operator | N/A | No | ServiceMonitor support for metrics collection |
| Istio | N/A | No | Service mesh integration with VirtualServices and DestinationRules |
| cert-manager | N/A | No | Alternative certificate management (not required with OpenShift) |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KServe | CRD Watch/Patch | Monitors and patches InferenceServices with payload processor configuration |
| TrustyAI Service | Container Image | Managed service deployment (quay.io/trustyai/trustyai-service:latest) |
| Model Mesh | Label Matching | Integrates with Model Mesh serving deployments via MM_PAYLOAD_PROCESSORS env var |
| OpenShift OAuth Proxy | Sidecar Container | Authentication for TrustyAI service access |
| Prometheus | ServiceMonitor | Metrics scraping for model fairness metrics |
| PostgreSQL/MariaDB | Database | Optional external database storage backend |

## Network Architecture

### Services

#### Operator Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | 8081 | HTTPS | TLS 1.2+ | Bearer Token | Internal (Prometheus) |

#### TrustyAI Service Services (Managed Resources)

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {name} | ClusterIP | 80/TCP | 8080 | HTTP | None | None | Internal |
| {name} | ClusterIP | 443/TCP | 4443 | HTTPS | TLS 1.2+ | service-serving-cert | Internal |
| {name}-tls | ClusterIP | 443/TCP | 8443 | HTTPS | TLS 1.2+ | OAuth Proxy | Internal/Route Backend |

**Notes:**
- `{name}` represents the TrustyAIService CR name
- Services use OpenShift service-serving certificates for automatic TLS cert provisioning
- Annotations include: `service.beta.openshift.io/serving-cert-secret-name`

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {name} | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |

**Route Configuration:**
- Backend Service: `{name}-tls`
- Target Port: `oauth-proxy` (8443)
- TLS Termination: Reencrypt (edge terminated, re-encrypted to backend)
- Insecure Traffic Policy: Redirect to HTTPS
- Requires OpenShift platform

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| KServe InferenceServices | 80/TCP, 443/TCP | HTTP/HTTPS | Varies | mTLS (in mesh) | Monitor model inference requests for explainability data |
| PostgreSQL/MariaDB | 5432/TCP, 3306/TCP | JDBC | TLS 1.2+ (optional) | Username/Password | Database storage backend (when DATABASE mode enabled) |
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Reconciliation, resource management |

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
| manager-role | apiextensions.k8s.io | customresourcedefinitions | get, list, watch |
| manager-role | coordination.k8s.io | leases | create, get, update |
| manager-role | monitoring.coreos.com | servicemonitors | create, list, watch |
| manager-role | networking.istio.io | destinationrules | create, delete, get, list, patch, update, watch |
| manager-role | networking.istio.io | virtualservices | create, delete, get, list, patch, update, watch |
| manager-role | rbac.authorization.k8s.io | clusterrolebindings | create, delete, get, list, update, watch |
| manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| manager-role | serving.kserve.io | inferenceservices | get, list, patch, update, watch |
| manager-role | serving.kserve.io | inferenceservices/finalizers | delete, get, list, patch, update, watch |
| manager-role | serving.kserve.io | servingruntimes | create, delete, get, list, patch, update, watch |
| manager-role | serving.kserve.io | servingruntimes/status | get, patch, update |
| manager-role | trustyai.opendatahub.io | trustyaiservices | create, delete, get, list, patch, update, watch |
| manager-role | trustyai.opendatahub.io | trustyaiservices/finalizers | update |
| manager-role | trustyai.opendatahub.io | trustyaiservices/status | get, patch, update |
| leader-election-role | coordination.k8s.io | leases | get, create, update |
| auth-proxy-role | "" | pods | get |
| auth-proxy-role | authentication.k8s.io | tokenreviews | create |
| auth-proxy-role | authorization.k8s.io | subjectaccessreviews | create |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | (cluster-wide) | manager-role (ClusterRole) | controller-manager |
| leader-election-rolebinding | system | leader-election-role (Role) | controller-manager |
| auth-proxy-rolebinding | system | auth-proxy-role (ClusterRole) | controller-manager |

**TrustyAI Service RBAC (Managed Resources):**

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| {name}-proxy | {namespace} | ClusterRole (pods get) | {name}-proxy |

**OAuth Proxy SAR Check:**
- Namespace: {namespace}
- Resource: pods
- Verb: get

### Secrets

#### Operator Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| controller-manager-token | kubernetes.io/service-account-token | ServiceAccount token | Kubernetes | Yes |

#### TrustyAI Service Secrets (Managed Resources)

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {name}-tls | kubernetes.io/tls | TLS certificates for OAuth proxy service | OpenShift service-serving-cert | Yes |
| {name}-internal | kubernetes.io/tls | Internal TLS certificates for service-to-service | OpenShift service-serving-cert | Yes |
| {name}-db-credentials | Opaque | Database connection credentials (username, password, host, port, kind, generation) | User/External | No |
| {name}-db-ca | Opaque | Database CA certificate for TLS connections | User/External | No |
| {name}-proxy-token | kubernetes.io/service-account-token | ServiceAccount token for OAuth proxy | Kubernetes | Yes |

**Database Secret Keys (when DATABASE storage mode):**
- `databaseKind`: Database type (postgresql, mariadb)
- `databaseUsername`: Database username
- `databasePassword`: Database password
- `databaseService`: Database hostname/service
- `databasePort`: Database port
- `databaseName`: Database name
- `databaseGeneration`: Database schema generation strategy

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics (operator) | GET | None | None | Prometheus scraping endpoint (internal) |
| /healthz, /readyz | GET | None | None | Health checks (internal) |
| /* (TrustyAI service) | ALL | OpenShift OAuth | OAuth Proxy Sidecar | Subject Access Review (namespace:{ns}, resource:pods, verb:get) |
| /q/metrics (TrustyAI) | GET | None (internal) | ServiceMonitor | Prometheus scraping with bearer token |
| Database | ALL | Username/Password + TLS Client Cert (optional) | Application | JDBC connection authentication |

**OAuth Proxy Configuration:**
- Provider: OpenShift
- Cookie Secret: Auto-generated
- HTTPS Address: :8443
- Email Domain: * (all)
- Upstream: http://localhost:8080
- Skip Auth Regex: `(^/apis/v1beta1/healthz)` (health endpoints)
- TLS: Certificate from `{name}-tls` secret

## Data Flows

### Flow 1: User Access to TrustyAI Service (External)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | OpenShift Router | {name}-tls Service | 443/TCP | HTTPS | TLS 1.2+ (reencrypt) | None |
| 3 | {name}-tls Service | OAuth Proxy Container | 8443/TCP | HTTPS | TLS 1.2+ | OpenShift OAuth |
| 4 | OAuth Proxy | TrustyAI Service Container | 8080/TCP | HTTP | None | Proxied Auth |

### Flow 2: Prometheus Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | {name} Service | 80/TCP | HTTP | None | Bearer Token (ServiceAccount) |
| 2 | {name} Service | TrustyAI Service Container | 8080/TCP | HTTP | None | None |
| 3 | TrustyAI Service | /q/metrics endpoint | - | - | - | - |

### Flow 3: Operator Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Operator | Watch TrustyAIService CRDs | - | - | - | - |
| 3 | Operator | Create/Update Managed Resources | - | - | - | - |

### Flow 4: TrustyAI to InferenceService (Model Monitoring)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | InferenceService (patched) | TrustyAI Service | 80/TCP or 443/TCP | HTTP/HTTPS | mTLS (if in mesh) | ServiceAccount Token |
| 2 | InferenceService | Sends inference payload data | - | - | - | - |
| 3 | TrustyAI Service | Stores data and computes metrics | - | - | - | - |

### Flow 5: TrustyAI to Database (DATABASE Storage Mode)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | TrustyAI Service Container | Database Service | 5432/TCP or 3306/TCP | JDBC | TLS 1.2+ (if configured) | Username/Password + CA Cert |
| 2 | TrustyAI Service | Writes/reads inference data | - | - | - | - |

### Flow 6: Istio Service Mesh Integration

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Istio Sidecar | VirtualService Match | 80/TCP | HTTP | None | None |
| 2 | VirtualService | Route to port 443 | 443/TCP | HTTPS | TLS (SIMPLE mode) | None |
| 3 | DestinationRule | Apply TLS policy | - | - | - | - |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API | REST API | 6443/TCP | HTTPS | TLS 1.2+ | CRD watching, resource reconciliation |
| KServe InferenceServices | CRD Patch/Watch | N/A | N/A | N/A | Inject payload processor configuration, monitor inference services |
| Model Mesh Deployments | Environment Variable Injection | N/A | N/A | N/A | Configure MM_PAYLOAD_PROCESSORS for model monitoring |
| Prometheus | ServiceMonitor | 80/TCP | HTTP | None | Scrape fairness metrics (trustyai_spd, trustyai_dir) |
| OpenShift Routes | Route Creation | 443/TCP | HTTPS | TLS (Reencrypt) | External access provisioning |
| OpenShift OAuth | Authentication Delegation | N/A | HTTPS | TLS 1.2+ | User authentication and authorization |
| Istio | VirtualService/DestinationRule | 80/TCP, 443/TCP | HTTP/HTTPS | TLS (SIMPLE) | Service mesh traffic management |
| PVC Storage | Volume Mount | N/A | Filesystem | None | Persistent data storage for CSV files |
| PostgreSQL/MariaDB | JDBC | 5432/TCP, 3306/TCP | JDBC | TLS 1.2+ (optional) | Relational database storage backend |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 13e5065 | 2024-10-19 | Merge remote-tracking branch 'upstream/main' into rhoai-2.15 |
| ddd093a | 2024-10-18 | - Support for VirtualServices for InferenceLogger traffic (#332) |
| fb54647 | 2024-10-17 | - Add correct CA cert to JDBC (#324) |
| 4e3091f | 2024-10-17 | - Update overlay images (#331) |
| 4893d79 | 2024-10-15 | - Enable KServe serverless in the rhoai overlay (#321) |
| 7979767 | 2024-10-14 | - Add readiness probes (#312) |
| 91237c5 | 2024-10-14 | - Fix operator metrics service target port (#320) |
| d11408c | 2024-10-10 | - Add check if DestinationRule CRD is present before creating it (#316) |
| 97a5a5d | 2024-10-10 | - Add KServe destination rule for Inference Services in the ServiceMesh (#315) |

**Key Recent Features:**
- Enhanced Istio/Service Mesh support with VirtualServices and DestinationRules
- Improved database TLS certificate handling
- KServe serverless mode support in RHOAI overlay
- Better health checking with readiness probes
- Metrics service port fixes

## Deployment Architecture

### Operator Deployment

**Namespace**: Deployed to operator namespace (typically `redhat-ods-applications` or `opendatahub`)

**Container**: Single container deployment
- Image: Built via Konflux from `Dockerfile.konflux`
- Base Images:
  - Builder: `registry.redhat.io/ubi8/go-toolset`
  - Runtime: `registry.redhat.io/ubi8/ubi-minimal`
- Command: `/manager`
- Args: `--leader-elect`
- Resources:
  - Limits: 500m CPU, 128Mi memory
  - Requests: 10m CPU, 64Mi memory

**Security Context**:
- Run as non-root: true
- Seccomp profile: RuntimeDefault
- Capabilities: Drop ALL
- Allow privilege escalation: false

**Leader Election**: Enabled (lease-based in coordination.k8s.io)

### TrustyAI Service Deployment (Managed Resource)

**Containers**: Multi-container pod
1. **trustyai-service**: Main application container
   - Image: `quay.io/trustyai/trustyai-service:latest` (configurable via ConfigMap)
   - Ports: 8080/TCP
   - Health Probes: /q/health/ready, /q/health/live
   - Volume Mounts:
     - PVC mount (when PVC storage mode)
     - TLS certificate mounts (internal, db-ca)

2. **oauth-proxy**: Authentication sidecar
   - Image: `registry.redhat.io/openshift4/ose-oauth-proxy:latest` (configurable)
   - Ports: 8443/TCP
   - Health Probes: /oauth/healthz
   - Resources:
     - Limits: 100m CPU, 64Mi memory
     - Requests: 100m CPU, 64Mi memory

**Strategy**: RollingUpdate (maxUnavailable: 1, maxSurge: 0)

**Replicas**: 1 (configurable via TrustyAIService spec)

## Configuration

### ConfigMap: trustyai-service-operator-config

| Key | Default Value | Purpose |
|-----|---------------|---------|
| trustyaiServiceImage | quay.io/trustyai/trustyai-service:latest | TrustyAI service container image |
| oauthProxyImage | registry.redhat.io/openshift4/ose-oauth-proxy:latest | OAuth proxy sidecar image |
| kServeServerless | true (in RHOAI overlay) | Enable KServe serverless mode |

### Environment Variables (TrustyAI Service Container)

| Variable | Source | Purpose |
|----------|--------|---------|
| SERVICE_STORAGE_FORMAT | TrustyAIService spec | PVC or DATABASE |
| STORAGE_DATA_FILENAME | TrustyAIService spec | Data filename for PVC mode |
| STORAGE_DATA_FOLDER | TrustyAIService spec | Data folder path |
| SERVICE_DATA_FORMAT | TrustyAIService spec | CSV or HIBERNATE |
| SERVICE_METRICS_SCHEDULE | TrustyAIService spec | Metrics collection schedule |
| SERVICE_BATCH_SIZE | TrustyAIService spec | Batch size (default: 5000) |
| QUARKUS_HIBERNATE_ORM_ACTIVE | Computed | true for DATABASE, false for PVC |
| QUARKUS_DATASOURCE_* | Database secret | Database connection parameters |
| DATABASE_SERVICE | Database secret | Database hostname |
| DATABASE_PORT | Database secret | Database port |
| DATABASE_NAME | Database secret | Database name |

## Monitoring & Observability

### Metrics

**Operator Metrics** (Port 8443/TCP, path /metrics):
- Standard controller-runtime metrics
- Reconciliation metrics
- Leader election metrics

**TrustyAI Service Metrics** (Port 80/TCP, path /q/metrics):
- `trustyai_spd`: Statistical Parity Difference metric
- `trustyai_dir`: Disparate Impact Ratio metric
- Custom fairness and explainability metrics
- Prometheus annotations: `prometheus.io/scrape: 'true'`

**ServiceMonitor Configuration**:
- Interval: 4s
- Metric relabelings: Keep only `trustyai_.*` metrics
- Bearer token authentication
- Namespace selector: Matches TrustyAIService namespace

### Health Checks

**Operator**:
- Liveness: /healthz on port 8081 (initial delay: 15s, period: 20s)
- Readiness: /readyz on port 8081 (initial delay: 5s, period: 10s)

**TrustyAI Service**:
- Liveness: /q/health/live on port 8080 (initial delay: 10s, period: 5s, timeout: 2s)
- Readiness: /q/health/ready on port 8080 (initial delay: 10s, period: 5s, timeout: 2s)

**OAuth Proxy**:
- Liveness: /oauth/healthz on port 8443 (initial delay: 30s, period: 5s)
- Readiness: /oauth/healthz on port 8443 (initial delay: 5s, period: 5s)

## Storage Options

### PVC Storage Mode

**Configuration**:
- Format: "PVC"
- Size: User-defined (e.g., "1Gi", "10Gi")
- Folder: Mount path (e.g., "/inputs")
- Data Filename: CSV filename

**PVC Provisioning**:
- Automatically created by operator
- Naming: `{trustyaiservice-name}-pvc`
- Storage class: Default or specified
- Access mode: ReadWriteOnce

### Database Storage Mode

**Supported Databases**:
- PostgreSQL
- MariaDB

**Configuration**:
- Format: "DATABASE"
- Database Configurations: Secret name containing credentials
- TLS Support: Optional CA certificate via `{name}-db-ca` secret

**Connection String (with TLS)**:
```
jdbc:${DB_KIND}://${HOST}:${PORT}/${NAME}?requireSSL=true&sslMode=verify-ca&serverSslCert=/etc/tls/db/ca.crt
```

**Migration Support**:
- PVC to Database migration via annotation: `trustyai.opendatahub.io/db-migration`
- Migrates existing CSV data to database schema

## Troubleshooting

### Status Conditions

TrustyAIService status provides detailed condition information:

**PVCAvailable**:
- `PVCFound`: PVC is available
- `PVCNotFound`: PVC not found or not ready

**InferenceServicesPresent**:
- `InferenceServicesFound`: KServe InferenceServices detected
- `InferenceServicesNotFound`: No InferenceServices in namespace

**DBAvailable** (DATABASE mode):
- `DBAvailable`: Successfully connected to database
- `DBCredentialsNotFound`: Database credentials secret not found
- `DBCredentialsError`: Database credentials malformed
- `DBConnectionError`: Unable to connect to database

**Available**:
- `AllComponentsReady`: Service is fully operational
- `NotAllComponentsReady`: Some components not ready

### Common Issues

1. **PVC Not Ready**: Service will not start until PVC is bound
2. **Database Connection Failures**: Check credentials secret and network connectivity
3. **OAuth Proxy Authentication**: Requires OpenShift platform for OAuth provider
4. **Route Not Created**: Requires OpenShift platform for Route resource
5. **ServiceMonitor Not Created**: Requires Prometheus Operator installed
6. **InferenceService Patching**: Requires KServe CRDs installed

## Security Considerations

1. **Certificate Management**:
   - Uses OpenShift service-serving certificates for automatic rotation
   - TLS certificates automatically provisioned and renewed
   - Support for custom CA bundles via ConfigMap injection

2. **Authentication**:
   - OAuth proxy enforces OpenShift user authentication
   - Subject Access Review (SAR) checks for authorization
   - ServiceAccount token-based authentication for service-to-service

3. **Network Security**:
   - All external traffic encrypted via TLS
   - Internal service-to-service communication can use service mesh mTLS
   - Database connections support TLS with client certificates

4. **Secret Management**:
   - Database credentials stored in Kubernetes secrets
   - TLS certificates managed by OpenShift service-serving-cert controller
   - No secrets stored in ConfigMaps or environment variables (except via secretKeyRef)

5. **RBAC**:
   - Minimal required permissions for operator
   - Separate service accounts for operator and managed services
   - ClusterRole scoped appropriately for multi-namespace operation
