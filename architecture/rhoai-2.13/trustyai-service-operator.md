# Component: TrustyAI Service Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/trustyai-service-operator
- **Version**: 1.17.0 (commit a9e7fb8, branch rhoai-2.13)
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator (Controller-Runtime based)

## Purpose
**Short**: Manages deployment and lifecycle of TrustyAI explainability services for AI model monitoring and bias detection.

**Detailed**: The TrustyAI Service Operator is a Kubernetes operator that simplifies the deployment and management of TrustyAI explainability services on Kubernetes and OpenShift clusters. It watches for custom resources of kind `TrustyAIService` in the `trustyai.opendatahub.io` API group and manages deployments, services, routes, and ServiceMonitors corresponding to these resources. The operator integrates with KServe InferenceServices to provide AI explainability and fairness metrics (SPD, DIR) for deployed models, ensuring proper configuration for Prometheus metrics scraping and external accessibility via OAuth-protected routes on OpenShift. TrustyAI services can store data in PersistentVolumeClaims or external databases (PostgreSQL, MySQL) and automatically inject payload processors into KServe model serving deployments for monitoring.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| TrustyAI Service Operator | Go Controller | Reconciles TrustyAIService CRDs and manages service lifecycle |
| TrustyAI Service | Quarkus Application | Provides AI explainability and bias detection metrics |
| OAuth Proxy | Sidecar Container | Provides OpenShift OAuth authentication for service access |
| ServiceMonitor | Prometheus Resource | Configures Prometheus to scrape TrustyAI metrics |
| PVC Storage | Persistent Volume | Stores model inference data (optional, alternative to database) |
| Database Backend | External Service | PostgreSQL/MySQL for model data persistence (optional) |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| trustyai.opendatahub.io | v1alpha1 | TrustyAIService | Namespaced | Defines TrustyAI service deployment with storage, metrics schedule, and data format configuration |

### HTTP Endpoints

#### Operator Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Operator metrics for Prometheus |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness probe |

#### TrustyAI Service Endpoints (Managed Resources)

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /q/metrics | GET | 8080/TCP | HTTP | None | Internal | TrustyAI metrics endpoint (internal) |
| /q/metrics | GET | 4443/TCP | HTTPS | TLS 1.2+ | Service cert | TrustyAI metrics endpoint (internal TLS) |
| /* | ALL | 8443/TCP | HTTPS | TLS 1.2+ | OAuth proxy | External access via OAuth proxy |
| /oauth/healthz | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | OAuth proxy health check |
| /* | ALL | 443/TCP | HTTPS | TLS 1.2+ (Re-encrypt) | OpenShift OAuth | External access via OpenShift Route |

### gRPC Services

No gRPC services exposed.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.19+ | Yes | Container orchestration platform |
| OpenShift | 4.6+ | No | Route and OAuth integration (optional) |
| Prometheus Operator | v0.x | No | ServiceMonitor CRD support for metrics |
| cert-manager | Any | No | Optional for custom certificate management |
| PostgreSQL/MySQL | Any | No | Optional database backend for data storage |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KServe | CRD Patching | Patches InferenceService deployments to add TrustyAI payload processors |
| Model Mesh | Environment Variables | Injects MM_PAYLOAD_PROCESSORS env vars into model serving pods |
| ODH Dashboard | Route Discovery | TrustyAI routes discoverable for dashboard integration |
| Prometheus | ServiceMonitor | Exposes AI fairness metrics (trustyai_spd, trustyai_dir) |

## Network Architecture

### Services

#### Operator Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | 8080 | HTTPS | TLS 1.2+ | Bearer Token | Internal |

#### Managed TrustyAI Services (Created by Operator)

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {name} | ClusterIP | 80/TCP | 8080 | HTTP | None | None | Internal |
| {name} | ClusterIP | 443/TCP | 4443 | HTTPS | TLS 1.2+ (service cert) | Service cert | Internal |
| {name}-tls | ClusterIP | 443/TCP | 8443 | HTTPS | TLS 1.2+ | OAuth | Internal (pre-Route) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {name} | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ | Re-encrypt | External (OpenShift only) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| KServe InferenceServices | 443/TCP | HTTPS | TLS 1.2+ | mTLS (service cert) | Inject payload processors for monitoring |
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) | Manage resources, watch CRDs |
| Database Service (if configured) | 3306/5432/TCP | JDBC | TLS 1.2+ (optional) | DB credentials | Store model inference data |
| Model Mesh Services | 443/TCP | HTTPS | TLS 1.2+ | Service cert | Configure payload processors |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | trustyai.opendatahub.io | trustyaiservices, trustyaiservices/status, trustyaiservices/finalizers | get, list, watch, create, update, patch, delete |
| manager-role | apps | deployments, deployments/status, deployments/finalizers | get, list, watch, create, update, patch, delete |
| manager-role | "" | services, configmaps, pods, secrets, serviceaccounts, persistentvolumeclaims | get, list, watch, create, update, patch, delete |
| manager-role | "" | persistentvolumes | get, list, watch |
| manager-role | "" | events | create, patch, update |
| manager-role | monitoring.coreos.com | servicemonitors | create, list, watch |
| manager-role | route.openshift.io | routes | get, list, watch, create, update, patch, delete |
| manager-role | serving.kserve.io | inferenceservices, inferenceservices/finalizers, servingruntimes, servingruntimes/status | get, list, watch, update, patch, delete, create |
| manager-role | rbac.authorization.k8s.io | clusterrolebindings | get, list, watch, create, update, delete |
| manager-role | coordination.k8s.io | leases | get, create, update |
| auth-proxy-client-clusterrole | authentication.k8s.io | tokenreviews | create |
| auth-proxy-client-clusterrole | authorization.k8s.io | subjectaccessreviews | create |
| leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| leader-election-role | "" | events | create, patch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | All namespaces (ClusterRoleBinding) | manager-role | controller-manager |
| leader-election-rolebinding | Operator namespace | leader-election-role | controller-manager |
| auth-proxy-client-clusterrolebinding | All namespaces (ClusterRoleBinding) | auth-proxy-client-clusterrole | controller-manager |
| {name}-proxy (per TrustyAIService) | Service namespace | OAuth SAR permissions | {name}-proxy |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {name}-tls | kubernetes.io/tls | TLS cert for OAuth proxy service | service.beta.openshift.io/serving-cert | Yes (OpenShift) |
| {name}-internal | kubernetes.io/tls | TLS cert for internal service communication | service.beta.openshift.io/serving-cert | Yes (OpenShift) |
| {name}-db-credentials | Opaque | Database connection credentials (optional) | User/External | No |
| {name}-db-tls | kubernetes.io/tls | Database TLS certificates (optional) | User/External | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /* (via Route) | ALL | OpenShift OAuth (Bearer Token) | OAuth Proxy | SAR: namespace={ns}, resource=pods, verb=get |
| /q/metrics (internal) | GET | None (internal only) | Service Network | ClusterIP (not routable externally) |
| /metrics (operator) | GET | Bearer Token | kube-rbac-proxy | ServiceAccount token from Prometheus |
| Kubernetes API | ALL | ServiceAccount Bearer Token | Kubernetes API Server | RBAC policies per ClusterRole |
| Database (optional) | ALL | Username/Password (JDBC) | Application | Credentials from Secret |

## Data Flows

### Flow 1: TrustyAI Service Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Kubernetes API | Operator Controller | N/A | Watch | N/A | N/A |
| 3 | Operator Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | SA Bearer Token |
| 4 | Operator Controller | Kubernetes API (create Deployment) | 6443/TCP | HTTPS | TLS 1.2+ | SA Bearer Token |
| 5 | Operator Controller | Kubernetes API (create Services) | 6443/TCP | HTTPS | TLS 1.2+ | SA Bearer Token |
| 6 | Operator Controller | Kubernetes API (create Route) | 6443/TCP | HTTPS | TLS 1.2+ | SA Bearer Token |
| 7 | Operator Controller | Kubernetes API (create ServiceMonitor) | 6443/TCP | HTTPS | TLS 1.2+ | SA Bearer Token |

### Flow 2: External User Access (via Route)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External User | OpenShift Router | 443/TCP | HTTPS | TLS 1.3 (edge) | None |
| 2 | OpenShift Router | {name}-tls Service | 443/TCP | HTTPS | TLS 1.2+ (re-encrypt) | None |
| 3 | {name}-tls Service | OAuth Proxy Container | 8443/TCP | HTTPS | TLS 1.2+ | None |
| 4 | OAuth Proxy | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth flow |
| 5 | OAuth Proxy (authenticated) | TrustyAI Service Container | 8080/TCP | HTTP | None (localhost) | None |

### Flow 3: Prometheus Metrics Scraping

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | {name} Service | 80/TCP | HTTP | None | None |
| 2 | {name} Service | TrustyAI Service Container | 8080/TCP | HTTP | None | None |
| 3 | TrustyAI Service | Prometheus | Response | HTTP | None | None |

### Flow 4: KServe InferenceService Integration

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Operator Controller | Kubernetes API (list InferenceServices) | 6443/TCP | HTTPS | TLS 1.2+ | SA Bearer Token |
| 2 | Operator Controller | Kubernetes API (patch Deployment env vars) | 6443/TCP | HTTPS | TLS 1.2+ | SA Bearer Token |
| 3 | Model Serving Pod | TrustyAI Service (payload processing) | 443/TCP | HTTPS | TLS 1.2+ | Service cert |

### Flow 5: Database Storage (Optional)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | TrustyAI Service | Database Service | 3306/5432/TCP | JDBC | TLS 1.2+ (optional) | DB credentials |
| 2 | Database Service | TrustyAI Service | Response | JDBC | TLS 1.2+ (optional) | N/A |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API (Watch/CRUD) | 6443/TCP | HTTPS | TLS 1.2+ | Manage TrustyAIService CRDs and resources |
| Prometheus | Metrics Scraping (Pull) | 80/TCP | HTTP | None | Collect fairness metrics (trustyai_spd, trustyai_dir) |
| KServe InferenceServices | CRD Patching | 6443/TCP | HTTPS | TLS 1.2+ | Inject payload processors for model monitoring |
| OpenShift OAuth Server | OAuth 2.0 | 443/TCP | HTTPS | TLS 1.2+ | Authenticate external users |
| OpenShift Router | Route/Ingress | 443/TCP | HTTPS | TLS 1.2+ (re-encrypt) | External service exposure |
| PostgreSQL/MySQL (optional) | JDBC | 3306/5432/TCP | JDBC | TLS 1.2+ (optional) | Persist model inference data |
| Model Mesh Services | HTTPS Payload | 443/TCP | HTTPS | TLS 1.2+ | Receive inference payloads for analysis |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 1.17.0 | 2025 | - Current stable version for RHOAI 2.13 |
| a9e7fb8 | 2025 | - Update Konflux references to 998b546 |
| a6fbf2f | 2025 | - Update Konflux references to 998b546 |
| 0b270ec | 2025 | - Update Konflux references to 998b546 |
| b6ce458 | 2024 | - Update Konflux references |
| 4fda2f9 | 2024 | - Update Konflux references |
| 8be7fe3 | 2024 | - Update Konflux references |
| 3afa97d | 2024 | - Update Konflux references to c232f24 |
| 933c1c3 | 2024 | - Update Konflux references to c232f24 |
| a3cc45d | 2024 | - Update Konflux references to c232f24 |
| 47c82a0 | 2024 | - Update Konflux references to afc2b5a |

## Deployment Configuration

### Kustomize Structure

The operator uses Kustomize for deployment with the following structure:
- **Base**: `config/base/` - Core operator deployment, RBAC, and CRDs
- **Overlays**:
  - `config/overlays/rhoai/` - RHOAI-specific configuration
  - `config/overlays/odh/` - ODH-specific configuration
  - `config/overlays/testing/` - Testing configuration

### Container Images

| Image | Default | Purpose |
|-------|---------|---------|
| Operator | quay.io/trustyai/trustyai-service-operator:latest | TrustyAI Service Operator controller |
| Service | quay.io/trustyai/trustyai-service:latest | TrustyAI explainability service |
| OAuth Proxy | registry.redhat.io/openshift4/ose-oauth-proxy@sha256:ab112105... | OpenShift OAuth authentication |

### Resource Requirements

| Component | CPU Request | Memory Request | CPU Limit | Memory Limit |
|-----------|-------------|----------------|-----------|--------------|
| Operator Manager | 10m | 64Mi | 500m | 128Mi |
| TrustyAI Service | (default) | (default) | (default) | (default) |
| OAuth Proxy | 100m | 64Mi | 100m | 64Mi |

## Storage Options

The operator supports two storage backends for TrustyAI services:

1. **PVC Storage** (default):
   - Format: `PVC`
   - Configurable size (default: 1Gi)
   - Folder path for data storage
   - Data format: CSV or other formats

2. **Database Storage** (optional):
   - Format: `DATABASE`
   - Supported: PostgreSQL, MySQL
   - JDBC connection via secrets
   - Optional TLS certificate support
   - Hibernate ORM for data persistence

## Monitoring and Observability

### Metrics Exposed

| Metric Name | Type | Description |
|-------------|------|-------------|
| trustyai_spd | Gauge | Statistical Parity Difference (fairness metric) |
| trustyai_dir | Gauge | Disparate Impact Ratio (fairness metric) |
| controller_runtime_* | Various | Standard controller-runtime metrics |

### Health Checks

| Endpoint | Port | Protocol | Container | Purpose |
|----------|------|----------|-----------|---------|
| /healthz | 8081/TCP | HTTP | Operator | Liveness probe |
| /readyz | 8081/TCP | HTTP | Operator | Readiness probe |
| /oauth/healthz | 8443/TCP | HTTPS | OAuth Proxy | Liveness and readiness |

## Security Considerations

1. **Encryption in Transit**:
   - All external access via HTTPS with TLS 1.2+
   - Re-encrypt termination for OpenShift Routes
   - Internal service-to-service TLS optional (via service certs)

2. **Authentication**:
   - OpenShift OAuth for external user access
   - ServiceAccount tokens for Kubernetes API access
   - Database credentials stored in Secrets

3. **Authorization**:
   - OpenShift SAR (SubjectAccessReview) for OAuth proxy
   - RBAC policies for operator permissions
   - Namespace isolation for multi-tenant deployments

4. **Secret Management**:
   - TLS certificates auto-provisioned by OpenShift service cert controller
   - Database credentials managed by users
   - No hardcoded secrets in operator code

5. **Network Policies**:
   - No default NetworkPolicies defined
   - Users should implement namespace-level network policies as needed
   - Service mesh integration possible via Istio annotations

## Limitations and Constraints

1. **Platform Support**:
   - Route and OAuth features require OpenShift (Kubernetes requires alternative ingress)
   - ServiceMonitor requires Prometheus Operator

2. **Scalability**:
   - Operator runs single replica with leader election support
   - TrustyAI services default to 1 replica (configurable)

3. **Storage**:
   - PVC storage requires ReadWriteMany for multi-replica deployments
   - Database mode recommended for high-availability scenarios

4. **KServe Integration**:
   - Requires KServe v1alpha1 or v1beta1 APIs
   - Supports ModelMesh and Serverless deployment modes
   - Automatic payload processor injection may require model redeployment
