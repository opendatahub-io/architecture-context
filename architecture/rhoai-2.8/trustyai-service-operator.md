# Component: TrustyAI Service Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/trustyai-service-operator
- **Version**: 288fadf (rhoai-2.8 branch)
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes operator that manages TrustyAI service deployments for AI/ML explainability and fairness monitoring.

**Detailed**: The TrustyAI Service Operator simplifies the deployment and management of TrustyAI services on Kubernetes and OpenShift clusters. It watches for custom resources of kind `TrustyAIService` in the `trustyai.opendatahub.io` API group and automatically manages corresponding deployments, services, routes, and monitoring resources. The operator integrates with KServe InferenceServices to provide AI explainability and fairness metrics, configuring payload processors for ModelMesh deployments and inference loggers for KServe deployments. It ensures services are properly configured with OAuth authentication, discoverable by Prometheus for metrics scraping, and accessible via Routes on OpenShift with TLS encryption.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| TrustyAI Service Operator | Go Operator | Manages lifecycle of TrustyAI service deployments |
| TrustyAI Service | Deployment | Provides AI explainability and fairness metrics analysis |
| OAuth Proxy | Sidecar Container | Handles authentication and TLS termination for external access |
| Persistent Volume Claim | Storage | Stores inference data and metrics |
| ServiceMonitor (Local) | Monitoring | Per-namespace metrics collection for TrustyAI instances |
| ServiceMonitor (Central) | Monitoring | Cluster-wide metrics aggregation |
| Service Account | RBAC | OAuth authentication and token review permissions |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| trustyai.opendatahub.io | v1alpha1 | TrustyAIService | Namespaced | Declarative configuration for TrustyAI service deployments with storage, data format, and metrics scheduling |

**TrustyAIService Spec Fields**:
- `storage`: PVC configuration (format, folder, size)
- `data`: Data file settings (filename, format - CSV)
- `metrics`: Metrics collection schedule and batch size
- `replicas`: Number of service replicas (optional)

**TrustyAIService Status Fields**:
- `phase`: Current deployment phase
- `replicas`: Actual replica count
- `conditions`: Status conditions (InferenceServicesPresent, PVCAvailable, RouteAvailable, Available)
- `ready`: Overall readiness status

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness probe |
| /metrics | GET | 8080/TCP | HTTP | None | None | Operator Prometheus metrics |
| /oauth/healthz | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | OAuth proxy health check |
| /q/metrics | GET | 8080/TCP | HTTP | None | None | TrustyAI service metrics (internal) |
| /q/metrics | GET | 443/TCP | HTTPS | TLS 1.2+ | OpenShift OAuth | TrustyAI service metrics (external via Route) |
| /consumer/kserve/v2 | POST | 80/TCP | HTTP | None | None | KServe inference payload processor endpoint |
| / | ALL | 443/TCP | HTTPS | TLS 1.2+ | OpenShift OAuth | TrustyAI service API (external via Route) |

### gRPC Services

None - This component uses HTTP/REST APIs only.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.19+ | Yes | Container orchestration platform |
| OpenShift | 4.6+ | No | Enhanced features (Routes, OAuth) |
| Prometheus Operator | N/A | Yes | ServiceMonitor CRD support for metrics collection |
| cert-manager or OpenShift cert service | N/A | Yes | TLS certificate provisioning for OAuth proxy |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KServe | CRD/API | Configures InferenceServices with TrustyAI inference loggers for explainability |
| ModelMesh | Environment Variable | Injects payload processor URLs into ModelMesh deployments |
| Prometheus | ServiceMonitor | Scrapes TrustyAI metrics for fairness and explainability monitoring |
| OpenShift OAuth | Service Account | Authenticates external access to TrustyAI services |
| ODH Dashboard | Integration | TrustyAI metrics displayed in dashboard (indirect) |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {instance-name} | ClusterIP | 80/TCP | 8080 | HTTP | None | None | Internal |
| {instance-name}-tls | ClusterIP | 443/TCP | 8443 | HTTPS | TLS (service cert) | mTLS (service-to-service) | Internal |
| controller-manager-metrics-service | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |

**Service Labels**:
- `app.kubernetes.io/name`: {instance-name}
- `app.kubernetes.io/instance`: {instance-name}
- `app.kubernetes.io/part-of`: trustyai

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {instance-name} | OpenShift Route | Auto-assigned | 443/TCP | HTTPS | TLS 1.2+ | Passthrough | External |

**Route Configuration**:
- Backend service: {instance-name}-tls
- TLS termination: Passthrough (TLS handled by OAuth proxy)
- Admission status tracked in TrustyAIService status conditions

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | CR reconciliation, resource management |
| KServe InferenceServices | Varies | HTTP/HTTPS | Varies | None/mTLS | Update inference logger configuration |
| Custom CA Bundle ConfigMap | N/A | N/A | N/A | None | Trust custom certificates (optional) |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | trustyai.opendatahub.io | trustyaiservices, trustyaiservices/status, trustyaiservices/finalizers | get, list, watch, create, update, patch, delete |
| manager-role | apps | deployments, deployments/status, deployments/finalizers | get, list, watch, create, update, patch, delete |
| manager-role | "" | services, pods, configmaps, secrets, persistentvolumeclaims, serviceaccounts, events | get, list, watch, create, update, patch, delete |
| manager-role | "" | persistentvolumes | get, list, watch |
| manager-role | monitoring.coreos.com | servicemonitors | create, list, watch |
| manager-role | route.openshift.io | routes | get, list, watch, create, update, patch, delete |
| manager-role | serving.kserve.io | inferenceservices, inferenceservices/finalizers | get, list, watch, update, patch, delete |
| manager-role | serving.kserve.io | servingruntimes, servingruntimes/status | get, list, watch, create, update, patch, delete |
| manager-role | rbac.authorization.k8s.io | clusterrolebindings | get, list, watch, create, update, delete |
| proxy-role | authentication.k8s.io | tokenreviews | create |
| proxy-role | authorization.k8s.io | subjectaccessreviews | create |
| leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| leader-election-role | "" | events | create, patch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-role-binding | All | ClusterRole/manager-role | {operator-namespace}/controller-manager |
| leader-election-role-binding | {operator-namespace} | Role/leader-election-role | {operator-namespace}/controller-manager |
| {instance-name}-{namespace}-proxy-rolebinding | Cluster | ClusterRole/trustyai-service-operator-proxy-role | {namespace}/{instance-name}-proxy |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {instance-name}-tls | kubernetes.io/tls | TLS certificate for OAuth proxy | OpenShift service cert signer or custom CA | Yes (OpenShift service certs) |
| {instance-name}-proxy-token | kubernetes.io/service-account-token | OAuth proxy service account token | Kubernetes | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /q/metrics (external) | GET | OpenShift OAuth (Bearer Token) | OAuth Proxy | SAR: namespace/{ns}, resource/pods, verb/get |
| /q/metrics (internal) | GET | None | None | Internal cluster access only |
| / (via Route) | ALL | OpenShift OAuth (Bearer Token) | OAuth Proxy | SAR: namespace/{ns}, resource/pods, verb/get |
| /consumer/kserve/v2 | POST | None | None | Internal from InferenceServices |
| Operator API Server | ALL | ServiceAccount Token | Kubernetes RBAC | ClusterRole bindings |

**OAuth Proxy Configuration**:
- Provider: OpenShift
- Cookie secret: Auto-generated
- HTTPS address: :8443
- Upstream: http://localhost:8080 (TrustyAI service)
- Skip auth regex: `^/apis/v1beta1/healthz` (health checks)
- Subject Access Review: pods.get in deployment namespace

### Network Policies

None defined - relies on OpenShift/Kubernetes default network policies and service mesh configuration if deployed.

## Data Flows

### Flow 1: TrustyAI Service Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Dashboard | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | kubeconfig credentials |
| 2 | Kubernetes API | Operator Manager | N/A | Internal | None | Controller watch |
| 3 | Operator | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Operator | PVC Creation | N/A | API | TLS 1.2+ | ServiceAccount Token |
| 5 | Operator | Deployment Creation | N/A | API | TLS 1.2+ | ServiceAccount Token |
| 6 | Operator | Service Creation (Internal & TLS) | N/A | API | TLS 1.2+ | ServiceAccount Token |
| 7 | Operator | ServiceMonitor Creation | N/A | API | TLS 1.2+ | ServiceAccount Token |
| 8 | Operator | Route Creation (OpenShift) | N/A | API | TLS 1.2+ | ServiceAccount Token |
| 9 | Operator | ServiceAccount Creation | N/A | API | TLS 1.2+ | ServiceAccount Token |
| 10 | Operator | ClusterRoleBinding Creation | N/A | API | TLS 1.2+ | ServiceAccount Token |

### Flow 2: External Metrics Access

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.3 | None |
| 2 | OpenShift Router | {instance-name}-tls Service | 443/TCP | HTTPS | TLS 1.2+ (passthrough) | None |
| 3 | Service | OAuth Proxy Container | 8443/TCP | HTTPS | TLS 1.2+ | None |
| 4 | OAuth Proxy | OpenShift OAuth Server | 6443/TCP | HTTPS | TLS 1.2+ | OAuth flow |
| 5 | OAuth Proxy | TrustyAI Service Container | 8080/TCP | HTTP | None | Validated token |
| 6 | TrustyAI Service | OAuth Proxy | 8080/TCP | HTTP | None | Response |
| 7 | OAuth Proxy | User Browser | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token Cookie |

### Flow 3: KServe Inference Logging

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Operator | InferenceService CR | N/A | API | TLS 1.2+ | ServiceAccount Token |
| 2 | KServe Controller | InferenceService Pod Update | N/A | Internal | None | None |
| 3 | InferenceService | {instance-name} Service | 80/TCP | HTTP | None | None |
| 4 | Service | TrustyAI Service Pod | 8080/TCP | HTTP | None | None |
| 5 | TrustyAI Service | PVC Storage | N/A | Filesystem | None | Pod UID |

### Flow 4: ModelMesh Payload Processing

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Operator | ModelMesh Deployment Patch | N/A | API | TLS 1.2+ | ServiceAccount Token |
| 2 | ModelMesh Pod | {instance-name} Service | 80/TCP | HTTP | None | None |
| 3 | Service | TrustyAI Service Pod /consumer/kserve/v2 | 8080/TCP | HTTP | None | None |
| 4 | TrustyAI Service | PVC Storage | N/A | Filesystem | None | Pod UID |

### Flow 5: Prometheus Metrics Scraping

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | {instance-name} Service | 80/TCP | HTTP | None | ServiceAccount Token (optional) |
| 2 | Service | TrustyAI Service /q/metrics | 8080/TCP | HTTP | None | None |
| 3 | TrustyAI Service | Prometheus | 80/TCP | HTTP | None | Metrics response |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | CR reconciliation and resource management |
| KServe InferenceService | CRD Patch | N/A | HTTPS (API) | TLS 1.2+ | Configure inference logger to TrustyAI service URL |
| KServe Predictor Pods | HTTP Callback | 80/TCP | HTTP | None | Send inference payloads to TrustyAI for analysis |
| ModelMesh Deployments | Environment Variable | 80/TCP | HTTP | None | Payload processor registration via MM_PAYLOAD_PROCESSORS |
| Prometheus | ServiceMonitor | 80/TCP | HTTP | None | Scrape TrustyAI metrics (trustyai_spd, trustyai_dir) |
| OpenShift OAuth | OAuth2 Protocol | 6443/TCP | HTTPS | TLS 1.2+ | User authentication for external TrustyAI access |
| OpenShift Router | Route | 443/TCP | HTTPS | TLS passthrough | External traffic routing to TrustyAI services |
| OpenShift Service CA | Certificate Request | N/A | N/A | N/A | TLS certificate provisioning for OAuth proxy |
| PersistentVolume | Filesystem | N/A | N/A | None | Store inference data and computed metrics |

## Reconciliation Logic

### TrustyAIService Controller Watches

| Resource Type | API Group/Version | Watch Type | Purpose |
|---------------|-------------------|------------|---------|
| TrustyAIService | trustyai.opendatahub.io/v1alpha1 | Primary | Main custom resource managed by operator |
| InferenceService | serving.kserve.io/v1beta1 | Secondary | Trigger reconciliation when InferenceServices change |
| ServingRuntime | serving.kserve.io/v1alpha1 | Secondary | Monitor serving runtime changes affecting payload processing |

### Reconciliation Steps

1. **Finalizer Management**: Add finalizer for cleanup of external dependencies (InferenceService patches)
2. **Service Account Creation**: Create OAuth proxy service account with OAuth redirect annotations
3. **ClusterRoleBinding**: Bind proxy service account to token review cluster role
4. **Custom CA Bundle Check**: Detect `odh-trusted-ca-bundle` ConfigMap for custom certificates
5. **OAuth Service Creation**: Create TLS-enabled service for OAuth proxy (port 443 → 8443)
6. **InferenceService Configuration**:
   - For ModelMesh: Patch `MM_PAYLOAD_PROCESSORS` environment variable in matching deployments
   - For KServe: Add inference logger spec pointing to TrustyAI service URL
   - Wait for deployment replicas to be ready before patching
7. **PVC Provisioning**: Create PersistentVolumeClaim with specified size and ReadWriteOnce access
8. **Deployment Creation**: Create TrustyAI service deployment with:
   - Main container: TrustyAI service with data/storage/metrics configuration
   - Sidecar: OAuth proxy for authentication and TLS termination
   - Volume mounts: PVC and optional custom CA bundle
9. **Service Creation**: Create internal ClusterIP service (port 80 → 8080)
10. **ServiceMonitor Creation**:
    - Local: Per-instance ServiceMonitor in TrustyAI namespace
    - Central: Aggregated ServiceMonitor in operator namespace
11. **Route Creation** (OpenShift only): Create passthrough Route pointing to TLS service
12. **Status Updates**: Update TrustyAIService status conditions:
    - `InferenceServicesPresent`: Detected InferenceServices in namespace
    - `PVCAvailable`: PVC is bound and ready
    - `RouteAvailable`: Route is admitted (OpenShift)
    - `Available`: All components ready

### Requeue Strategy

- Default requeue delay: 1 minute
- Requeue on errors: Immediate with exponential backoff
- Requeue on not-ready replicas: 1 minute delay

## Container Images

| Component | Default Image | Purpose | Build Method |
|-----------|---------------|---------|--------------|
| TrustyAI Service Operator | quay.io/trustyai/trustyai-service-operator:latest | Operator manager | Konflux (UBI8 + Go) |
| TrustyAI Service | quay.io/trustyai/trustyai-service:latest | Explainability/fairness service | Configurable via ConfigMap |
| OAuth Proxy | registry.redhat.io/openshift4/ose-oauth-proxy:latest | Authentication sidecar | Configurable via ConfigMap |

**Image Configuration**: Images can be customized via `trustyai-service-operator-config` ConfigMap with keys:
- `trustyaiServiceImage`
- `trustyaiOperatorImage`
- `oauthProxyImage`

## Resource Requirements

### Operator Manager

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 10m | 500m |
| Memory | 64Mi | 128Mi |

### TrustyAI Service Pod (per instance)

| Container | Resource | Request | Limit |
|-----------|----------|---------|-------|
| trustyai-service | CPU | Not specified | Not specified |
| trustyai-service | Memory | Not specified | Not specified |
| oauth-proxy | CPU | 100m | 100m |
| oauth-proxy | Memory | 64Mi | 64Mi |

### Storage

- PersistentVolumeClaim: User-specified size in TrustyAIService spec (e.g., "1Gi")
- Access Mode: ReadWriteOnce

## Observability

### Metrics Exposed

**Operator Metrics** (port 8080):
- Standard controller-runtime metrics
- Reconciliation metrics
- Leader election metrics

**TrustyAI Service Metrics** (port 8080, path /q/metrics):
- `trustyai_spd`: Statistical Parity Difference fairness metric
- `trustyai_dir`: Disparate Impact Ratio fairness metric
- Custom explainability metrics (model-dependent)

### Prometheus Integration

- **Local ServiceMonitor**: Scrapes individual TrustyAI service instances
  - Namespace: Same as TrustyAIService
  - Selector: `app.kubernetes.io/part-of=trustyai`
  - Interval: 4s
  - Metric relabeling: Keep only `trustyai_.*` metrics
- **Central ServiceMonitor**: Aggregates metrics across namespaces
  - Namespace: Operator namespace
  - Discovers services in all namespaces with trustyai label

### Health Checks

| Component | Endpoint | Port | Protocol | Type |
|-----------|----------|------|----------|------|
| Operator | /healthz | 8081/TCP | HTTP | Liveness |
| Operator | /readyz | 8081/TCP | HTTP | Readiness |
| OAuth Proxy | /oauth/healthz | 8443/TCP | HTTPS | Liveness & Readiness |

### Logging

- Structured logging via controller-runtime/zap
- Log levels: Development mode enabled
- Events emitted for key operations:
  - `PVCCreated`: PersistentVolumeClaim provisioned
  - `InferenceServiceConfigured`: ModelMesh payload processor configured
  - `ServiceMonitorCreated`: Local ServiceMonitor created

## Security Considerations

### Pod Security

- **Security Context**:
  - Run as non-root: true
  - Seccomp profile: RuntimeDefault
  - Capabilities: Drop ALL
  - Privilege escalation: false
- **User ID**: 65532 (non-root user)

### Network Security

- **Internal Communication**: Unencrypted HTTP within cluster (service mesh recommended for mTLS)
- **External Communication**: TLS 1.2+ via OAuth proxy with OpenShift-issued certificates
- **Certificate Management**:
  - Service certificates auto-rotated by OpenShift
  - Custom CA bundle support via ConfigMap injection

### Secrets Management

- OAuth proxy cookie secret: Auto-generated per instance
- TLS certificates: Provisioned by OpenShift service CA
- ServiceAccount tokens: Auto-mounted, short-lived (Kubernetes default)

### RBAC Principle

- Operator requires cluster-wide permissions for cross-namespace InferenceService management
- Per-instance service accounts with minimal permissions (token review only)
- Users require namespace-level pod.get permission to access TrustyAI services via OAuth

## Deployment Configuration

### Kustomize Structure

- **Base** (`config/base`): Default image parameters and kustomization
- **CRD** (`config/crd`): TrustyAIService CustomResourceDefinition
- **Manager** (`config/manager`): Operator deployment manifest
- **RBAC** (`config/rbac`): ClusterRoles, RoleBindings, ServiceAccount
- **Prometheus** (`config/prometheus`): ServiceMonitor for operator metrics
- **Manifests** (`config/manifests`): OLM bundle configuration

### Operator Deployment Flags

- `--metrics-bind-address=:8080`: Prometheus metrics endpoint
- `--health-probe-bind-address=:8081`: Health check endpoint
- `--leader-elect`: Enable leader election for HA

### Namespace Scope

- Operator: Cluster-scoped (empty namespace field in manager config)
- TrustyAIService instances: Namespace-scoped (deployed per-namespace)

## Known Limitations

1. **Platform Dependency**: Routes and OAuth integration require OpenShift (limited functionality on vanilla Kubernetes)
2. **Storage**: Only supports ReadWriteOnce PVCs (single pod access)
3. **InferenceService Integration**: Requires KServe to be installed for ML model monitoring
4. **Authentication**: External access requires OpenShift OAuth (no alternative auth providers)
5. **Metrics Format**: Fixed metric names and formats (customization requires TrustyAI service changes)

## Recent Changes

| Date | Commit | Changes |
|------|--------|---------|
| 2025-01 | 188623a | Update UBI minimal base image digest |
| 2025-01 | 4785855 | Add default tokenizers and missing collection benchmarks to LMEval |
| 2025-01 | 3c29399 | Add support for collections in EvalHub configuration |
| 2025-01 | b5936f0 | Add KUBEFLOW_GARAK_BASE_IMAGE to evalhub garak-kfp provider |
| 2025-01 | 708dbb4 | Change image substitution in EH ConfigMaps using existing variables |
| 2025-01 | b9a5a68 | Update ta-lmes-job image |
| 2025-01 | 8133fca | Remove init container default tag |
| 2025-01 | 9fecbbf | Create missing MLFlow service SA RoleBinding in tenant namespaces |

**Note**: Recent commits show active development on EvalHub (Evaluation Hub) integration for LLM evaluation, suggesting expansion beyond basic explainability metrics.

## Future Considerations

1. **Multi-tenancy**: Consider namespace isolation improvements for shared clusters
2. **HA Support**: Add support for multiple TrustyAI service replicas with load balancing
3. **Authentication Options**: Support additional auth mechanisms beyond OpenShift OAuth
4. **Storage Backends**: Consider S3-compatible object storage for large-scale deployments
5. **Service Mesh Integration**: Explicit support for Istio/Service Mesh mTLS policies
6. **Metrics Export**: Support additional metrics formats (Prometheus remote write, OTLP)
7. **Custom Metrics**: Allow users to define custom fairness/explainability metrics via CRD
