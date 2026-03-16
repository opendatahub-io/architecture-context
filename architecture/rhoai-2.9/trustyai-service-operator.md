# Component: TrustyAI Service Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/trustyai-service-operator.git
- **Version**: f6fd5aa (rhoai-2.9 branch)
- **Distribution**: RHOAI
- **Languages**: Go 1.21
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes operator that manages deployment and lifecycle of TrustyAI explainability services for model monitoring and bias detection.

**Detailed**: The TrustyAI Service Operator simplifies deployment and management of TrustyAI explainability services on Kubernetes and OpenShift clusters. It watches for TrustyAIService custom resources and automatically provisions the required infrastructure including deployments, services, persistent storage, Prometheus monitoring, and OAuth-protected external access routes. The operator integrates with KServe InferenceServices to enable automated payload logging and model monitoring, providing fairness metrics (SPD, DIR) and explainability capabilities. It manages both ModelMesh and KServe deployment modes, automatically configuring payload processors or inference loggers to capture prediction data for analysis.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| controller-manager | Deployment | Operator controller that reconciles TrustyAIService CRs |
| TrustyAI Service Instance | Deployment | Managed TrustyAI service pods with OAuth proxy sidecar |
| PersistentVolumeClaim | Storage | Persistent storage for TrustyAI data and metrics |
| ServiceMonitor | Monitoring | Prometheus metrics scraping configuration |
| Route | Ingress | OpenShift external access with TLS passthrough |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| trustyai.opendatahub.io | v1alpha1 | TrustyAIService | Namespaced | Defines TrustyAI service deployment with storage, data format, and metrics configuration |

### HTTP Endpoints

#### Operator Manager

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe for operator |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe for operator |
| /metrics | GET | 8080/TCP | HTTP | None | None | Operator metrics endpoint |

#### TrustyAI Service (Internal)

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /q/metrics | GET | 8080/TCP | HTTP | None | None | Service metrics for Prometheus |
| /consumer/kserve/v2 | POST | 8080/TCP | HTTP | None | None | KServe payload consumer endpoint |
| /apis/v1beta1/healthz | GET | 8080/TCP | HTTP | None | None | Health check endpoint |

#### TrustyAI Service (External via OAuth)

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /* | ALL | 8443/TCP | HTTPS | TLS 1.2+ | OpenShift OAuth | Protected API access via oauth-proxy |
| /oauth/healthz | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | OAuth proxy health check |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.19+ | Yes | Container orchestration platform |
| OpenShift | 4.6+ | No | Optional for Route and OAuth integration |
| Prometheus Operator | v0.64.1 | No | Optional for ServiceMonitor support |
| cert-manager or service-ca | N/A | Yes | TLS certificate provisioning for OAuth service |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KServe | CRD/API | Configures InferenceService payload logging to TrustyAI |
| ModelMesh | Environment Variables | Injects MM_PAYLOAD_PROCESSORS into ModelMesh deployments |
| Prometheus | ServiceMonitor | Exposes fairness and bias metrics (trustyai_spd, trustyai_dir) |

## Network Architecture

### Services

#### Operator Manager (not exposed externally)

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| None | N/A | N/A | N/A | N/A | N/A | N/A | Internal only |

#### TrustyAI Service Instance (created per TrustyAIService CR)

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {cr-name} | ClusterIP | 80/TCP | 8080 | HTTP | None | None | Internal |
| {cr-name}-tls | ClusterIP | 443/TCP | 8443 | HTTPS | TLS 1.2+ | OpenShift OAuth | Internal/External |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {cr-name} | OpenShift Route | {generated-hostname} | 443/TCP | HTTPS | TLS 1.2+ | Passthrough | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | CR reconciliation and resource management |
| OpenShift OAuth | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | OAuth authentication validation |
| PersistentVolume | N/A | Filesystem | None | None | Data storage access |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | trustyai.opendatahub.io | trustyaiservices, trustyaiservices/status, trustyaiservices/finalizers | get, list, watch, create, update, patch, delete |
| manager-role | apps | deployments, deployments/status, deployments/finalizers | get, list, watch, create, update, patch, delete |
| manager-role | "" | services, configmaps, pods, secrets, serviceaccounts, persistentvolumeclaims | get, list, watch, create, update, patch, delete |
| manager-role | "" | persistentvolumes, events | get, list, watch |
| manager-role | monitoring.coreos.com | servicemonitors | list, watch, create |
| manager-role | route.openshift.io | routes | get, list, watch, create, update, patch, delete |
| manager-role | serving.kserve.io | inferenceservices, inferenceservices/finalizers, servingruntimes, servingruntimes/status | get, list, watch, create, update, patch, delete |
| manager-role | rbac.authorization.k8s.io | clusterrolebindings | get, list, watch, create, update, delete |
| manager-role | coordination.k8s.io | leases | get, create, update |
| leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| leader-election-role | "" | events | create, patch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | system | manager-role (ClusterRole) | controller-manager |
| leader-election-rolebinding | system | leader-election-role | controller-manager |
| {cr-name}-proxy | {instance-namespace} | SAR delegation | {cr-name}-proxy |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {cr-name}-tls | kubernetes.io/tls | TLS certificate for OAuth service | service.beta.openshift.io/serving-cert-secret-name annotation | Yes |
| oauth-cookie-secret | Opaque | OAuth proxy cookie encryption (hardcoded) | Operator | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /{cr-name}-tls:443/* | ALL | OpenShift OAuth Bearer Token | oauth-proxy sidecar | SubjectAccessReview: namespace={ns}, resource=pods, verb=get |
| /apis/v1beta1/healthz | GET | None (skip-auth-regex) | oauth-proxy | Public |
| /{cr-name}:80/* | ALL | None | None | Internal cluster access only |
| /consumer/kserve/v2 | POST | None | None | Called by KServe InferenceService containers |

## Data Flows

### Flow 1: User Access to TrustyAI Service

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External User | OpenShift Route | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | OpenShift Router | {cr-name}-tls Service | 443/TCP | HTTPS | TLS 1.2+ (passthrough) | None |
| 3 | Service | oauth-proxy container | 8443/TCP | HTTPS | TLS 1.2+ | OpenShift OAuth Token |
| 4 | oauth-proxy | trustyai-service container | 8080/TCP | HTTP | None | None (localhost) |

### Flow 2: Prometheus Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | {cr-name} Service | 80/TCP | HTTP | None | ServiceAccount Token |
| 2 | Service | trustyai-service container | 8080/TCP | HTTP | None | None |
| 3 | trustyai-service | /q/metrics endpoint | 8080/TCP | HTTP | None | None |

### Flow 3: KServe Payload Logging (KServe Mode)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | InferenceService Predictor | {cr-name} Service | 80/TCP | HTTP | None | None |
| 2 | Service | trustyai-service container | 8080/TCP | HTTP | None | None |
| 3 | trustyai-service | /consumer/kserve/v2 endpoint | 8080/TCP | HTTP | None | None |
| 4 | trustyai-service | PVC storage | Filesystem | N/A | None | None |

### Flow 4: ModelMesh Payload Logging (ModelMesh Mode)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | ModelMesh Pod (via MM_PAYLOAD_PROCESSORS env) | {cr-name} Service | 80/TCP | HTTP | None | None |
| 2 | Service | trustyai-service container | 8080/TCP | HTTP | None | None |
| 3 | trustyai-service | /consumer/kserve/v2 endpoint | 8080/TCP | HTTP | None | None |
| 4 | trustyai-service | PVC storage | Filesystem | N/A | None | None |

### Flow 5: Operator Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | controller-manager | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | controller-manager | Creates/Updates Deployment, Service, Route, PVC, ServiceMonitor | N/A | API | TLS 1.2+ | RBAC |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API | REST API | 443/TCP | HTTPS | TLS 1.2+ | Resource management and CR watching |
| KServe InferenceServices | CR Patching | N/A | API | TLS 1.2+ | Configure Logger.URL for payload logging |
| ModelMesh Deployments | Env Var Injection | N/A | API | TLS 1.2+ | Inject MM_PAYLOAD_PROCESSORS environment variable |
| Prometheus | ServiceMonitor | 80/TCP | HTTP | None | Scrape fairness metrics (trustyai_spd, trustyai_dir) |
| OpenShift OAuth | Token Validation | 443/TCP | HTTPS | TLS 1.2+ | User authentication for external access |
| PersistentVolumeClaim | Volume Mount | Filesystem | N/A | None | Store model inference data and metrics |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| f6fd5aa | 2024-09-13 | - Merge pull request #23 from ruivieira/rhoai-2.9 |
| 81f45d8 | 2024-09-12 | - Update Go builder and mod from 1.19 -> 1.21 |
| 3d95529 | 2024-03-28 | - RHOAIENG-4870: Replace go-sdk version |
| 8efb55f | 2024-03-28 | - RHOAIENG-4870: Update sdk-go version |
| 899b163 | 2024-03-28 | - Add checks to ensure ODH operator has spun up before proceeding |
| 5092f91 | 2024-03-05 | - Add GH Actions smoke tests to the operator |
| 752afed | 2024-02-27 | - Prevent automatically generated TLS secret to be mounted if the CA bundle is detected |
| e70a3bd | 2024-02-26 | - Add coordination and leases permissions |
| 65fde44 | 2024-02-15 | - Add version information to resources |
| da1cff5 | 2024-02-15 | - Fix copying of odh setup files from service CI |
| cbaf9bd | 2024-02-14 | - Add CA bundle handling |
| 3e76f38 | 2024-02-13 | - Fix incorrect image path in bot comment |
| d0096be | 2024-02-13 | - Update CI tests for ODH V2 operator |
| 1b7c2a3 | 2024-02-13 | - RHOAIENG-3118: Replace route object with template |
| cc400f8 | 2024-02-13 | - RHOAIENG-3049: Refactor Service to template |
| 1e0cc2c | 2024-02-13 | - RHOAIENG-2775: Refactor operator's ServiceMonitors into templates |
| b324474 | 2024-02-12 | - Auto push manifests to CI branch |

## Deployment Configuration

### Operator Deployment (config/manager/manager.yaml)

- **Replicas**: 1
- **Container Image**: Parameterized via $(trustyaiOperatorImage)
- **Resources**:
  - Requests: 10m CPU, 64Mi memory
  - Limits: 500m CPU, 128Mi memory
- **Security Context**:
  - runAsNonRoot: true
  - allowPrivilegeEscalation: false
  - seccompProfile: RuntimeDefault
  - capabilities: drop ALL
- **Probes**:
  - Liveness: /healthz on port 8081
  - Readiness: /readyz on port 8081
- **Leader Election**: Enabled with ID b7e9931f.trustyai.opendatahub.io

### TrustyAI Service Instance Deployment (per CR)

- **Replicas**: 1 (configurable via CR spec.replicas)
- **Containers**:
  1. **trustyai-service**:
     - Image: Configurable via ConfigMap (default: quay.io/trustyai/trustyai-service:latest)
     - Environment variables: Storage format, data folder, metrics schedule, batch size
     - Volume mounts: PVC at configured folder path
  2. **oauth-proxy**:
     - Image: Configurable via ConfigMap (default: registry.redhat.io/openshift4/ose-oauth-proxy:latest)
     - Port: 8443/TCP
     - Resources: 100m CPU / 64Mi memory (requests and limits)
     - Volume mounts: TLS secret, optional CA bundle
     - OAuth configuration: OpenShift provider with SAR authorization

### Storage Configuration

- **PersistentVolumeClaim**: Created per TrustyAIService CR
- **Access Mode**: ReadWriteOnce
- **Size**: Configurable via CR spec.storage.size
- **Storage Format**: Configurable (PVC, Database, etc.)
- **Data Format**: CSV (configurable via CR spec.data.format)

### Monitoring Configuration

- **Local ServiceMonitor**: Created per TrustyAIService instance
  - Namespace: Same as TrustyAIService CR
  - Scrape interval: 4s
  - Path: /q/metrics
  - Metric filtering: Keep only trustyai_* metrics
- **Central ServiceMonitor**: Created once in operator namespace
  - Aggregates metrics from all TrustyAI instances
  - Matches on app.kubernetes.io/part-of: trustyai label

## Custom Resource Specification

### TrustyAIService CR Example

```yaml
apiVersion: trustyai.opendatahub.io/v1alpha1
kind: TrustyAIService
metadata:
  name: trustyai-service-example
  namespace: model-namespace
spec:
  replicas: 1  # Optional
  storage:
    format: "PVC"
    folder: "/inputs"
    size: "1Gi"
  data:
    filename: "data.csv"
    format: "CSV"
  metrics:
    schedule: "5s"
    batchSize: 5000  # Optional, defaults to 5000
```

### Status Fields

- **phase**: Current deployment phase
- **replicas**: Number of running replicas
- **ready**: Overall readiness status (True/False)
- **conditions**: Array of condition objects with types:
  - InferenceServicesPresent (InferenceServicesFound / InferenceServicesNotFound)
  - PVCAvailable (PVCFound / PVCNotFound)
  - RouteAvailable (RouteFound / RouteNotFound)
  - Available (AllComponentsReady / NotAllComponentsReady)

## Image Configuration

Images can be customized via ConfigMap `trustyai-service-operator-config`:
- **trustyaiServiceImage**: TrustyAI service container image (default: quay.io/trustyai/trustyai-service:latest)
- **oauthProxyImage**: OAuth proxy container image (default: registry.redhat.io/openshift4/ose-oauth-proxy:latest)

## Build Information

- **Base Image**: registry.access.redhat.com/ubi8/go-toolset:1.21 (builder)
- **Runtime Image**: registry.access.redhat.com/ubi8/ubi-minimal:8.9
- **Build Method**: Multi-stage Docker build
- **Binary**: /manager (statically compiled Go binary)
- **User**: 65532:65532 (non-root)
- **Container Label**: odh-trustyai-service-operator-rhel8
