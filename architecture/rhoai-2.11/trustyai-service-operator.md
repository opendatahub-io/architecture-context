# Component: TrustyAI Service Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/trustyai-service-operator
- **Version**: 1.17.0 (git: 707be21, branch: rhoai-2.11)
- **Distribution**: RHOAI
- **Languages**: Go 1.21
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes operator that manages TrustyAI service deployments for AI model explainability, fairness monitoring, and bias detection.

**Detailed**: The TrustyAI Service Operator simplifies the deployment and management of TrustyAI service instances on Kubernetes and OpenShift clusters. It watches for custom resources of kind `TrustyAIService` in the `trustyai.opendatahub.io` API group and automatically creates and manages corresponding deployments, services, persistent storage, and monitoring infrastructure. The operator ensures that TrustyAI services are properly configured with secure access (OAuth proxy on OpenShift), are discoverable by Prometheus for metrics scraping, and can monitor KServe InferenceServices for AI model fairness and explainability metrics. It handles the complete lifecycle of TrustyAI service instances including storage provisioning, TLS certificate management, and integration with the model serving infrastructure.

The operator integrates with KServe to automatically configure payload processors on ModelMesh deployments, enabling real-time monitoring of inference data for bias detection and explainability analysis. It supports flexible storage backends (PVC-based) and configurable metrics collection schedules for automated fairness assessments.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| TrustyAIServiceReconciler | Controller | Reconciles TrustyAIService CRDs and manages TrustyAI service lifecycle |
| OAuth Proxy Sidecar | Authentication Proxy | Provides OpenShift authentication for TrustyAI service access |
| TrustyAI Service Container | Application | Core explainability and fairness monitoring service |
| PVC Manager | Storage Controller | Provisions and manages persistent storage for metrics and data |
| ServiceMonitor Manager | Metrics Controller | Creates Prometheus ServiceMonitors for metrics collection |
| Route Manager | Network Controller | Manages OpenShift Routes for external access with TLS |
| InferenceService Integrator | Integration Controller | Patches KServe InferenceServices with payload processors |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| trustyai.opendatahub.io | v1alpha1 | TrustyAIService | Namespaced | Defines desired state of TrustyAI service instances with storage, data format, and metrics configuration |

### HTTP Endpoints

#### Operator Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Operator metrics for Prometheus scraping |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator liveness health check |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness health check |

#### TrustyAI Service Endpoints (Managed Instances)

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /q/metrics | GET | 8080/TCP | HTTP | None | Internal | TrustyAI service metrics endpoint (internal) |
| /apis/v1beta1/healthz | GET | 8080/TCP | HTTP | None | None | TrustyAI service health check (no auth) |
| /* | ALL | 8443/TCP | HTTPS | TLS 1.2+ | OAuth (OpenShift) | TrustyAI service APIs via OAuth proxy |
| /* | ALL | 443/TCP | HTTPS | TLS 1.2+ | OAuth (OpenShift) | TrustyAI service via external Route (reencrypt) |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | No gRPC services exposed |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.19+ | Yes | Kubernetes cluster platform |
| OpenShift | 4.6+ | No | OpenShift-specific features (Routes, OAuth) |
| Prometheus Operator | N/A | Yes | ServiceMonitor CRD for metrics collection |
| cert-manager or service-ca | N/A | Yes | TLS certificate generation for services |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KServe | CRD (InferenceService) | Monitors and patches InferenceServices with payload processors for data collection |
| ModelMesh | Environment Variables | Configures MM_PAYLOAD_PROCESSORS on ModelMesh deployments |
| Prometheus | ServiceMonitor | Exposes TrustyAI metrics for collection and alerting |

## Network Architecture

### Services

#### Operator Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | 8080 | HTTP | None | None | Internal |

#### TrustyAI Service Instances (Managed Resources)

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {instance-name} | ClusterIP | 80/TCP | 8080 | HTTP | None | Internal | Internal |
| {instance-name} | ClusterIP | 443/TCP | 4443 | HTTPS | TLS (internal cert) | Internal | Internal |
| {instance-name}-tls | ClusterIP | 443/TCP | 8443 | HTTPS | TLS (service-ca) | OAuth | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {instance-name} | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | CRD reconciliation and resource management |
| KServe InferenceServices | Variable | HTTPS | TLS 1.2+ | ServiceAccount Token | Patch InferenceService resources |
| Prometheus | Variable | HTTP/HTTPS | Conditional | ServiceAccount Token | Metrics exposure via ServiceMonitor |

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
| manager-role | apps | deployments/status | get, patch, update |
| manager-role | apps | deployments/finalizers | update |
| manager-role | coordination.k8s.io | leases | create, get, update |
| manager-role | monitoring.coreos.com | servicemonitors | create, list, watch |
| manager-role | rbac.authorization.k8s.io | clusterrolebindings | create, delete, get, list, update, watch |
| manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| manager-role | serving.kserve.io | inferenceservices | get, list, patch, update, watch |
| manager-role | serving.kserve.io | inferenceservices/finalizers | delete, get, list, patch, update, watch |
| manager-role | serving.kserve.io | servingruntimes | create, delete, get, list, patch, update, watch |
| manager-role | serving.kserve.io | servingruntimes/status | get, patch, update |
| manager-role | trustyai.opendatahub.io | trustyaiservices | create, delete, get, list, patch, update, watch |
| manager-role | trustyai.opendatahub.io | trustyaiservices/status | get, patch, update |
| manager-role | trustyai.opendatahub.io | trustyaiservices/finalizers | update |
| trustyaiservice-editor-role | trustyai.opendatahub.io | trustyaiservices | create, delete, get, list, patch, update, watch |
| trustyaiservice-viewer-role | trustyai.opendatahub.io | trustyaiservices | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | system | manager-role (ClusterRole) | controller-manager |
| leader-election-rolebinding | system | leader-election-role | controller-manager |
| {instance-name}-proxy | {instance-ns} | cluster-admin (created per instance) | {instance-name}-proxy |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {instance-name}-tls | kubernetes.io/tls | TLS certificate for OAuth proxy external access | service-ca (OpenShift) | Yes |
| {instance-name}-internal | kubernetes.io/tls | TLS certificate for internal service communication | service-ca (OpenShift) | Yes |
| oauth-cookie-secret | Opaque | OAuth proxy cookie encryption | Operator | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /apis/v1beta1/healthz | GET | None (skip-auth-regex) | OAuth Proxy | Unauthenticated health check |
| /* (TrustyAI APIs) | ALL | OpenShift OAuth + SAR | OAuth Proxy | Requires OpenShift login + pod get permission in namespace |
| /q/metrics (internal) | GET | None | Network Policy | Internal cluster access only |
| Operator /metrics | GET | Bearer Token (ServiceAccount) | kube-rbac-proxy | ServiceAccount authentication |

## Data Flows

### Flow 1: TrustyAI Service Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/ODH Dashboard | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (User) |
| 2 | Kubernetes API | Operator Controller | N/A | Internal | N/A | Watch Event |
| 3 | Operator Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) |
| 4 | Operator Controller | Kubernetes API (create PVC) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) |
| 5 | Operator Controller | Kubernetes API (create Deployment) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) |
| 6 | Operator Controller | Kubernetes API (create Services) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) |
| 7 | Operator Controller | Kubernetes API (create Route) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) |
| 8 | Operator Controller | Kubernetes API (create ServiceMonitor) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) |

### Flow 2: InferenceService Integration

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Operator Controller | Kubernetes API (list InferenceServices) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) |
| 2 | Operator Controller | Kubernetes API (patch InferenceService env) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) |
| 3 | InferenceService Pod | TrustyAI Service | 80/TCP | HTTP | None | Internal |

### Flow 3: External Access to TrustyAI Service

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External User | OpenShift Route | 443/TCP | HTTPS | TLS 1.2+ (edge) | None |
| 2 | OpenShift Router | TrustyAI Service (TLS) | 443/TCP | HTTPS | TLS 1.2+ (reencrypt) | None |
| 3 | Service | OAuth Proxy Container | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Token |
| 4 | OAuth Proxy | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth Flow |
| 5 | OAuth Proxy (authenticated) | TrustyAI Service Container | 8080/TCP | HTTP | None | Proxy-added headers |

### Flow 4: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | TrustyAI Service | 80/TCP | HTTP | None | ServiceAccount Token |
| 2 | TrustyAI Service | Prometheus | Response | HTTP | None | N/A |
| 3 | Prometheus | Operator Metrics Service | 8443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API | REST API | 6443/TCP | HTTPS | TLS 1.2+ | CRD reconciliation and resource management |
| KServe InferenceServices | CRD Patch | 6443/TCP | HTTPS | TLS 1.2+ | Configure payload processors for data collection |
| Prometheus | ServiceMonitor | 80/TCP | HTTP | None | Metrics exposure and collection |
| OpenShift OAuth | OAuth 2.0 | 443/TCP | HTTPS | TLS 1.2+ | User authentication for TrustyAI service access |
| ModelMesh Serving | Environment Variables | N/A | N/A | N/A | Configure payload processor endpoints |
| OpenShift Service CA | Certificate Request | 6443/TCP | HTTPS | TLS 1.2+ | TLS certificate provisioning |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 707be21 | N/A | - Merge from upstream trustyai-explainability/main |
| 45027a6 | N/A | - Update Go builder and toolset to 1.21 |
| b28a212 | N/A | - Add testing overlay for deployment configurations |
| 49661e5 | N/A | - Add internal service TLS for secure pod-to-pod communication |
| dc9bb48 | N/A | - Move test image to UBI base |
| 114eb66 | N/A | - Update builder and base image tags |
| 1d15f74 | N/A | - RHOAIENG-3845: Remove requeueing from finalizer to prevent blocking deletions |
| b0eeed7 | N/A | - Add ODH and RHOAI overlays for distribution-specific configurations |
| d369df6 | N/A | - Fix: Change route termination to reencrypt for enhanced security |
| c170426 | N/A | - Revert multi-arch changes |
| c99d958 | N/A | - Security: Replace golang.org/x/net 0.18.0 -> 0.23.0 |
| 3d95529 | N/A | - RHOAIENG-4870: Replace go-sdk version |
| 8efb55f | N/A | - RHOAIENG-4870: Update sdk-go version |
| 899b163 | N/A | - Add checks to ensure ODH operator has spun up before proceeding |

## Configuration

### ConfigMap Parameters

| ConfigMap | Key | Default Value | Purpose |
|-----------|-----|---------------|---------|
| trustyai-service-operator-config | trustyaiServiceImage | quay.io/trustyai/trustyai-service:latest | TrustyAI service container image |
| trustyai-service-operator-config | oauthProxyImage | registry.redhat.io/openshift4/ose-oauth-proxy:latest | OAuth proxy sidecar image |

### TrustyAIService Spec Parameters

| Parameter | Type | Required | Purpose |
|-----------|------|----------|---------|
| storage.format | string | Yes | Storage backend format (PVC) |
| storage.folder | string | Yes | Mount path for data storage |
| storage.size | string | Yes | PVC size (e.g., "1Gi") |
| data.filename | string | Yes | Data file name for metrics storage |
| data.format | string | Yes | Data format (e.g., CSV) |
| metrics.schedule | string | Yes | Metrics collection schedule interval |
| metrics.batchSize | int | No | Batch size for metrics processing (default: 5000) |
| replicas | int | No | Number of TrustyAI service replicas (default: 1) |

### Status Conditions

| Type | Reason | Status | Description |
|------|--------|--------|-------------|
| InferenceServicesPresent | InferenceServicesFound | True | InferenceServices detected in namespace |
| InferenceServicesPresent | InferenceServicesNotFound | False | No InferenceServices found (non-blocking) |
| PVCAvailable | PVCFound | True | PersistentVolumeClaim is available |
| PVCAvailable | PVCNotFound | False | PVC not found (blocks Ready status) |
| RouteAvailable | RouteFound | True | OpenShift Route created successfully |
| RouteAvailable | RouteNotFound | False | Route not found or not on OpenShift |
| Available | AllComponentsReady | True | All required components are ready |
| Available | NotAllComponentsReady | False | Some components are not ready |

## Deployment Architecture

### Operator Deployment

- **Namespace**: Varies by installation (e.g., opendatahub, redhat-ods-applications)
- **Replicas**: 1 (with leader election support)
- **Resource Limits**: CPU: 500m, Memory: 128Mi
- **Resource Requests**: CPU: 10m, Memory: 64Mi
- **Security Context**: runAsNonRoot, drop ALL capabilities, seccomp RuntimeDefault
- **Health Checks**: Liveness (/healthz:8081), Readiness (/readyz:8081)

### TrustyAI Service Instance Deployment (Managed)

- **Namespace**: User-specified namespace
- **Replicas**: Configurable (default: 1)
- **Containers**:
  - **trustyai-service**: Core explainability service
  - **oauth-proxy**: OpenShift authentication sidecar
- **Volumes**:
  - PVC for data persistence
  - TLS secrets for certificate management
  - Optional: Custom CA bundle ConfigMap
- **Service Account**: Created per instance with cluster-admin binding for OpenShift OAuth delegation
