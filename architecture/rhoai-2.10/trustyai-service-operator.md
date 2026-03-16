# Component: TrustyAI Service Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/trustyai-service-operator
- **Version**: a77b326 (rhoai-2.10 branch)
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Manages TrustyAI service deployments for AI/ML model explainability and fairness monitoring on Kubernetes and OpenShift.

**Detailed**: The TrustyAI Service Operator is a Kubernetes operator that automates the deployment and lifecycle management of TrustyAI services. It watches for custom resources of kind `TrustyAIService` and orchestrates the creation of deployments, services, routes (on OpenShift), persistent storage, and monitoring infrastructure. The operator integrates with KServe InferenceServices to enable model monitoring by patching payload processor environment variables in ModelMesh deployments. It provides OAuth-based authentication via an OpenShift OAuth proxy sidecar, automated TLS certificate management, and Prometheus metrics exposure. The operator ensures TrustyAI services are properly configured for collecting and analyzing inference data to detect bias, monitor fairness metrics, and provide model explainability.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| TrustyAI Service Operator | Kubernetes Controller | Reconciles TrustyAIService CRDs and manages lifecycle of TrustyAI service instances |
| TrustyAI Service (Managed) | Quarkus Application | Provides explainability and fairness metrics for AI/ML models |
| OAuth Proxy Sidecar | Authentication Proxy | Provides OpenShift OAuth authentication for TrustyAI service endpoints |
| Service Monitor | Prometheus CRD | Enables Prometheus scraping of TrustyAI metrics |
| PersistentVolumeClaim | Storage | Stores inference data and model metadata |
| OpenShift Route | Ingress | Provides external HTTPS access with re-encrypt TLS termination |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| trustyai.opendatahub.io | v1alpha1 | TrustyAIService | Namespaced | Defines desired state of TrustyAI service deployment including storage, data format, metrics schedule, and replica count |

### HTTP Endpoints

#### Operator Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Operator metrics endpoint for Prometheus scraping |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator health check endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness check endpoint |

#### TrustyAI Service Endpoints (Managed Workload)

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /* | ALL | 8080/TCP | HTTP | None | None (Internal Only) | TrustyAI service API - internal container port |
| /q/metrics | GET | 8080/TCP | HTTP | None | None (Internal Only) | TrustyAI service Prometheus metrics |
| /* | ALL | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Proxy (OpenShift SAR) | TrustyAI service API via OAuth proxy |
| /oauth/healthz | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | OAuth proxy health check |
| /apis/v1beta1/healthz | GET | 8443/TCP | HTTPS | TLS 1.2+ | None (Skipped Auth) | TrustyAI service health check (auth bypass) |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | No gRPC services exposed |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.19+ | Yes | Container orchestration platform |
| OpenShift | 4.6+ | No | Provides Route API, OAuth proxy, service-ca for TLS certificates |
| KServe | v1alpha1, v1beta1 | No | Model serving platform - operator watches InferenceServices and ServingRuntimes |
| Prometheus Operator | v1 | No | Enables ServiceMonitor for metrics scraping |
| cert-manager or service-ca | N/A | Yes | Provides TLS certificates for OAuth proxy (service-ca on OpenShift) |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KServe InferenceServices | CRD Watch & Patch | Patches ModelMesh deployment environment variables with TrustyAI service URL for payload forwarding |
| KServe ServingRuntimes | CRD Watch | Monitors serving runtime changes to maintain TrustyAI integration |
| ModelMesh Serving | Environment Variable Injection | Injects MM_PAYLOAD_PROCESSORS env var into deployments labeled modelmesh-service=modelmesh-serving |
| OpenShift OAuth Server | OAuth Authentication | Validates user tokens via Subject Access Review (SAR) for namespace pod access |

## Network Architecture

### Services

#### Operator Service

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| N/A (Direct Pod Access) | N/A | 8080/TCP | 8080 | HTTP | None | None | Internal Metrics |
| N/A (Direct Pod Access) | N/A | 8081/TCP | 8081 | HTTP | None | None | Internal Health |

#### TrustyAI Service (Managed Workload)

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {instance-name} | ClusterIP | 80/TCP | 8080 | HTTP | None | None | Internal Only |
| {instance-name}-tls | ClusterIP | 443/TCP | 8443 | HTTPS | TLS 1.2+ (service-ca) | OAuth Proxy | Internal & External via Route |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {instance-name} | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ | Re-encrypt | External |

### Egress

#### Operator Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token | CRD/resource management, watch operations |
| Container Registry (quay.io, registry.redhat.io) | 443/TCP | HTTPS | TLS 1.2+ | Pull Secrets | Image verification and metadata queries |

#### TrustyAI Service Egress (Managed Workload)

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| ModelMesh InferenceServices | Varies | HTTP/gRPC | None or TLS | None or mTLS | Receives forwarded inference payloads from ModelMesh |
| OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth tokens | Token validation for OAuth proxy |
| Custom CA Bundle Endpoint | 443/TCP | HTTPS | Custom CA Bundle | None | External connections when custom certificates configured |

## Security

### RBAC - Cluster Roles

#### Operator Manager Role

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | "" | configmaps | create, delete, get, list, patch, update, watch |
| manager-role | "" | events | create, patch, update |
| manager-role | "" | pods | create, delete, get, list, patch, update, watch |
| manager-role | "" | secrets | create, delete, get, list, patch, update, watch |
| manager-role | "" | serviceaccounts | create, delete, get, list, update, watch |
| manager-role | "" | persistentvolumeclaims | create, delete, get, list, patch, update, watch |
| manager-role | "" | persistentvolumes | get, list, watch |
| manager-role | "" | services | create, delete, get, list, patch, update, watch |
| manager-role | apps | deployments | create, delete, get, list, patch, update, watch |
| manager-role | apps | deployments/finalizers | update |
| manager-role | apps | deployments/status | get, patch, update |
| manager-role | coordination.k8s.io | leases | create, get, update |
| manager-role | monitoring.coreos.com | servicemonitors | create, list, watch |
| manager-role | rbac.authorization.k8s.io | clusterrolebindings | create, delete, get, list, update, watch |
| manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| manager-role | serving.kserve.io | inferenceservices | get, list, patch, update, watch |
| manager-role | serving.kserve.io | inferenceservices/finalizers | delete, get, list, patch, update, watch |
| manager-role | serving.kserve.io | servingruntimes | create, delete, get, list, patch, update, watch |
| manager-role | serving.kserve.io | servingruntimes/status | get, patch, update |
| manager-role | trustyai.opendatahub.io | trustyaiservices | create, delete, get, list, patch, update, watch |
| manager-role | trustyai.opendatahub.io | trustyaiservices/finalizers | update |
| manager-role | trustyai.opendatahub.io | trustyaiservices/status | get, patch, update |

#### OAuth Proxy Role

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| trustyai-service-operator-proxy-role | authentication.k8s.io | tokenreviews | create |
| trustyai-service-operator-proxy-role | authorization.k8s.io | subjectaccessreviews | create |

#### Metrics Reader Role

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| metrics-reader | N/A (non-resource) | /metrics | get |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | operator-namespace | manager-role (ClusterRole) | controller-manager |
| leader-election-rolebinding | operator-namespace | leader-election-role (Role) | controller-manager |
| {instance-name}-{namespace}-proxy-rolebinding | Cluster-scoped | trustyai-service-operator-proxy-role (ClusterRole) | {instance-name}-proxy (per TrustyAIService) |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {instance-name}-tls | kubernetes.io/tls | TLS certificate for OAuth proxy service | OpenShift service-ca | Yes (service-ca controller) |
| oauth-proxy-cookie-secret | Opaque | OAuth proxy session cookie secret | OAuth proxy (generated) | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /* (TrustyAI Service via OAuth) | ALL | OpenShift OAuth + SAR | OAuth Proxy Sidecar | Users must have namespace.pods.get permission |
| /apis/v1beta1/healthz | GET | None (Bypassed) | OAuth Proxy Sidecar | Regex-based auth skip for health endpoint |
| Operator Metrics/Health | GET | None | N/A | Internal endpoints only |
| Kubernetes API (Operator) | ALL | Service Account Token | Kubernetes API Server | RBAC policies defined in ClusterRole |

## Data Flows

### Flow 1: TrustyAIService Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (kubectl) |
| 2 | Kubernetes API | Operator Controller | N/A (Watch) | N/A | N/A | N/A (Internal Watch) |
| 3 | Operator Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 4 | Operator Controller | Kubernetes API (create PVC) | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 5 | Operator Controller | Kubernetes API (create ServiceAccount) | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 6 | Operator Controller | Kubernetes API (create Services) | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 7 | Operator Controller | Kubernetes API (create Deployment) | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 8 | Operator Controller | Kubernetes API (create Route) | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 9 | Operator Controller | Kubernetes API (create ServiceMonitor) | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |

### Flow 2: User Access to TrustyAI Service

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ (Router Cert) | None |
| 2 | OpenShift Router | {instance-name}-tls Service | 443/TCP | HTTPS | TLS 1.2+ (service-ca) | None |
| 3 | Service | OAuth Proxy Container | 8443/TCP | HTTPS | TLS 1.2+ (service-ca) | None |
| 4 | OAuth Proxy | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth Flow |
| 5 | OAuth Proxy (post-auth) | TrustyAI Service Container | 8080/TCP | HTTP | None (localhost) | None (authenticated by proxy) |

### Flow 3: ModelMesh Integration

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Operator Controller | Kubernetes API (list InferenceServices) | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 2 | Operator Controller | Kubernetes API (get ModelMesh Deployments) | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 3 | Operator Controller | Kubernetes API (patch Deployment env vars) | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 4 | ModelMesh Pod | TrustyAI Service | 80/TCP | HTTP | None | None (internal ClusterIP) |

### Flow 4: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | TrustyAI Service | 80/TCP | HTTP | None | None (ServiceMonitor config) |
| 2 | Service | TrustyAI Service Container | 8080/TCP | HTTP | None | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Resource CRUD operations, watch streams |
| KServe InferenceServices | CRD Watch & Patch | 6443/TCP | HTTPS | TLS 1.2+ | Monitor InferenceServices and patch ModelMesh deployments |
| OpenShift OAuth Server | OAuth 2.0 | 443/TCP | HTTPS | TLS 1.2+ | User authentication via OAuth proxy |
| OpenShift service-ca | Certificate Injection | N/A | N/A | N/A | Automatic TLS certificate provisioning for services |
| Prometheus | Metrics Scraping | 80/TCP | HTTP | None | Scrape TrustyAI fairness and explainability metrics |
| ModelMesh Serving | HTTP Payload Forwarding | 80/TCP | HTTP | None | Receive inference data for analysis |
| Container Registries (Quay.io, Red Hat Registry) | OCI Image Pull | 443/TCP | HTTPS | TLS 1.2+ | Pull operator and service container images |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| a77b326 | 2024 | - Merge rhoai-2.10 branch<br>- Update Go builder to 1.21<br>- Update builder and base image tags |
| 1d15f74 | 2024 | - RHOAIENG-3845: Remove requeueing from finalizer to prevent deletion delays |
| b0eeed7 | 2024 | - Add ODH and RHOAI overlays for multi-distribution support |
| d369df6 | 2024 | - Change route termination to reencrypt for enhanced security<br>- Revert multi-arch build changes |
| c99d958 | 2024 | - Replace golang.org/x/net 0.18.0 → 0.23.0 for security patches |
| 3d95529 | 2024 | - RHOAIENG-4870: Replace go-sdk version for compatibility |
| 899b163 | 2024 | - Add checks to ensure ODH operator readiness before proceeding with reconciliation |
| 5092f91 | 2024 | - Add GitHub Actions smoke tests for operator validation |
| 752afed | 2024 | - Prevent auto-generated TLS secret mounting when custom CA bundle detected |
| e70a3bd | 2024 | - Add coordination and leases permissions for leader election |

## Deployment Architecture

### Operator Deployment

- **Replicas**: 1 (single controller with leader election support)
- **Resources**:
  - Requests: 10m CPU, 64Mi memory
  - Limits: 500m CPU, 128Mi memory
- **Security Context**:
  - runAsNonRoot: true
  - allowPrivilegeEscalation: false
  - Capabilities dropped: ALL
  - seccompProfile: RuntimeDefault
- **Health Checks**:
  - Liveness: /healthz on port 8081 (15s initial delay, 20s period)
  - Readiness: /readyz on port 8081 (5s initial delay, 10s period)

### TrustyAI Service Deployment (Managed by Operator)

- **Replicas**: 1 (configurable via TrustyAIService CR spec.replicas)
- **Containers**:
  1. **trustyai-service**: Main application container
     - Image: quay.io/trustyai/trustyai-service:latest (configurable via ConfigMap)
     - Port: 8080/TCP
     - Storage: PVC mounted at configurable path (default: /inputs)
  2. **oauth-proxy**: Authentication sidecar
     - Image: registry.redhat.io/openshift4/ose-oauth-proxy:latest (configurable via ConfigMap)
     - Port: 8443/TCP
     - Resources: 100m CPU / 64Mi memory (requests and limits)
     - Health: /oauth/healthz on port 8443
- **Service Account**: {instance-name}-proxy with OAuth redirect annotations
- **Volumes**:
  - PVC: User-specified size (e.g., 1Gi) with ReadWriteOnce access
  - TLS Secret: Auto-provisioned by service-ca
  - Optional: Custom CA bundle ConfigMap

## Configuration

### Operator Configuration

Operator behavior can be customized via ConfigMap `trustyai-service-operator-config`:

| Key | Default | Purpose |
|-----|---------|---------|
| trustyaiServiceImage | quay.io/trustyai/trustyai-service:latest | TrustyAI service container image |
| oauthProxyImage | registry.redhat.io/openshift4/ose-oauth-proxy:latest | OAuth proxy sidecar image |

### TrustyAIService CR Configuration

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| spec.replicas | int32 | No | Number of TrustyAI service replicas (default: 1) |
| spec.storage.format | string | Yes | Storage format: "PVC" |
| spec.storage.folder | string | Yes | Mount path for data storage (e.g., "/inputs") |
| spec.storage.size | string | Yes | PVC size (e.g., "1Gi") |
| spec.data.filename | string | Yes | Data filename (e.g., "data.csv") |
| spec.data.format | string | Yes | Data format: "CSV" |
| spec.metrics.schedule | string | Yes | Metrics calculation interval (e.g., "5s") |
| spec.metrics.batchSize | int | No | Batch size for metrics processing (default: 5000) |

## Status Conditions

The operator maintains status conditions on TrustyAIService CRs:

| Type | Reason | Status | Meaning |
|------|--------|--------|---------|
| InferenceServicesPresent | InferenceServicesFound | True | KServe InferenceServices detected and configured |
| InferenceServicesPresent | InferenceServicesNotFound | False | No InferenceServices found (non-blocking) |
| PVCAvailable | PVCFound | True | PersistentVolumeClaim is bound and ready |
| PVCAvailable | PVCNotFound | False | PVC not found or not bound (blocks Ready status) |
| RouteAvailable | RouteFound | True | OpenShift Route created successfully |
| RouteAvailable | RouteNotFound | False | Route creation failed |
| Available | AllComponentsReady | True | All components deployed and healthy |
| Available | NotAllComponentsReady | False | One or more components not ready |

## Notes

- **Platform Support**: Primarily designed for OpenShift; can run on vanilla Kubernetes with limited functionality (no Route or OAuth proxy)
- **Leader Election**: Operator supports leader election for high availability (disabled by default, enabled via --leader-elect flag)
- **Finalizers**: Uses finalizer `trustyai.opendatahub.io/finalizer` to clean up external dependencies (e.g., patched InferenceServices) on deletion
- **Custom Certificates**: Supports custom CA bundle injection via ConfigMap for environments with enterprise PKI
- **ModelMesh Integration**: Automatically discovers and configures ModelMesh deployments labeled `modelmesh-service=modelmesh-serving`
- **Metrics**: Exposes both operator metrics (port 8080) and TrustyAI service metrics (via /q/metrics endpoint)
- **TLS**: Uses OpenShift service-ca for automatic certificate lifecycle management; certificates auto-rotate
