# Component: TrustyAI Service Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/trustyai-service-operator
- **Version**: e9bffad (rhoai-2.6 branch)
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator (Kubebuilder)

## Purpose
**Short**: Manages deployment and lifecycle of TrustyAI explainability and bias monitoring services for machine learning models.

**Detailed**: The TrustyAI Service Operator is a Kubernetes operator that simplifies the deployment and management of TrustyAI services on OpenShift clusters. It watches for TrustyAIService custom resources and automatically provisions the necessary infrastructure including deployments, services, persistent storage, Prometheus monitoring, and OAuth-protected routes. The operator integrates with KServe InferenceServices to provide explainability and fairness metrics for deployed ML models. It manages the complete lifecycle including storage provisioning, OAuth authentication setup, metrics collection configuration, and secure external access through OpenShift Routes.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Operator Manager | Controller | Reconciles TrustyAIService CRs and manages deployed resources |
| TrustyAI Service Deployment | Managed Workload | Provides explainability/bias metrics for ML models |
| OAuth Proxy Sidecar | Security Proxy | Authenticates requests to TrustyAI service endpoints |
| Persistent Volume Claims | Storage | Stores inference data and metrics |
| Service Monitors | Monitoring | Exposes metrics to Prometheus for collection |
| OpenShift Routes | Ingress | Provides external HTTPS access with TLS termination |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| trustyai.opendatahub.io | v1alpha1 | TrustyAIService | Namespaced | Defines a TrustyAI service instance with storage, data format, and metrics configuration |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness probe |
| /metrics | GET | 8080/TCP | HTTP | None | Bearer Token | Operator metrics for Prometheus |
| /q/metrics | GET | 8080/TCP | HTTP | None | None | TrustyAI service metrics (internal) |
| /q/metrics | GET | 80/TCP | HTTP | TLS re-encrypt | OAuth/mTLS | TrustyAI service metrics (via service) |
| / | ALL | 443/TCP | HTTPS | TLS 1.2+ | OAuth | TrustyAI API via OAuth proxy (external) |
| /oauth/healthz | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | OAuth proxy health check |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | No gRPC services |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.19+ | Yes | Cluster orchestration platform |
| OpenShift | 4.6+ | No | Route and OAuth integration (OpenShift-specific features) |
| Prometheus Operator | N/A | Yes | ServiceMonitor CRD for metrics collection |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KServe | CRD Watch (InferenceService, ServingRuntime) | Monitors InferenceServices to configure bias/explainability monitoring |
| Model Mesh | Environment Injection | Patches ModelMesh deployments with TrustyAI payload processor configuration |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8080/TCP | 8080 | HTTP | None | Bearer Token | Internal |
| {instance-name} | ClusterIP | 80/TCP | 8080 | HTTP | TLS re-encrypt | None | Internal |
| {instance-name}-tls | ClusterIP | 443/TCP | 8443 | HTTPS | TLS 1.2+ (serving-cert) | OAuth | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {instance-name} | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ | Passthrough | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | CRD reconciliation and resource management |
| InferenceService Pods | 8080/TCP | HTTP | None | None | Collect inference data for bias monitoring |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | trustyai.opendatahub.io | trustyaiservices, trustyaiservices/status, trustyaiservices/finalizers | create, delete, get, list, patch, update, watch |
| manager-role | apps | deployments, deployments/status, deployments/finalizers | create, delete, get, list, patch, update, watch |
| manager-role | "" | services, pods, configmaps, secrets, serviceaccounts, persistentvolumeclaims | create, delete, get, list, patch, update, watch |
| manager-role | "" | persistentvolumes, events | get, list, watch, create, patch, update |
| manager-role | monitoring.coreos.com | servicemonitors | create, list, watch |
| manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| manager-role | serving.kserve.io | inferenceservices, inferenceservices/finalizers, servingruntimes, servingruntimes/status | get, list, patch, update, watch, create, delete |
| manager-role | rbac.authorization.k8s.io | clusterrolebindings | create, delete, get, list, update, watch |
| proxy-role | authentication.k8s.io | tokenreviews | create |
| proxy-role | authorization.k8s.io | subjectaccessreviews | create |
| leader-election-role | "" | configmaps, events | create, delete, get, list, patch, update, watch |
| leader-election-role | coordination.k8s.io | leases | create, delete, get, list, patch, update, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | Cluster-wide | manager-role (ClusterRole) | controller-manager (operator namespace) |
| proxy-rolebinding | Cluster-wide | proxy-role (ClusterRole) | controller-manager (operator namespace) |
| leader-election-rolebinding | Operator namespace | leader-election-role (Role) | controller-manager |
| {instance}-{namespace}-proxy-rolebinding | Cluster-wide | trustyai-service-operator-proxy-role (ClusterRole) | {instance}-proxy (per TrustyAIService) |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {instance-name}-tls | kubernetes.io/tls | TLS certificate for OAuth proxy | service.beta.openshift.io/serving-cert-secret-name annotation | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics (operator) | GET | Bearer Token (ServiceAccount) | Prometheus ServiceMonitor | Kubernetes RBAC |
| / (TrustyAI service) | ALL | OAuth (OpenShift) | OAuth Proxy Sidecar | OpenShift SAR check (pods.get in namespace) |
| /q/metrics (TrustyAI) | GET | None (skip-auth-regex) | OAuth Proxy | Unauthenticated for metrics scraping |
| /apis/v1beta1/healthz | GET | None (skip-auth-regex) | OAuth Proxy | Unauthenticated for health checks |

## Data Flows

### Flow 1: TrustyAI Service Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | kubeconfig credentials |
| 2 | Kubernetes API | Operator Manager | N/A | Watch | N/A | N/A |
| 3 | Operator Manager | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Operator Manager | Kubernetes API (create PVC) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | Operator Manager | Kubernetes API (create Deployment) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 6 | Operator Manager | Kubernetes API (create Service) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 7 | Operator Manager | Kubernetes API (create Route) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 8 | Operator Manager | Kubernetes API (create ServiceMonitor) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: External Access to TrustyAI Service

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External User | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | OpenShift Router | OAuth Proxy (TrustyAI pod) | 8443/TCP | HTTPS | TLS 1.2+ (serving-cert) | TLS passthrough |
| 3 | OAuth Proxy | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth redirect |
| 4 | OAuth Proxy | Kubernetes API (SAR check) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | OAuth Proxy | TrustyAI Service Container | 8080/TCP | HTTP | None | localhost trust |
| 6 | TrustyAI Service Container | PersistentVolume | Local | Filesystem | None | Pod UID/GID |

### Flow 3: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | TrustyAI Service (via Service) | 80/TCP | HTTP | None | None |
| 2 | TrustyAI Service | TrustyAI Service Container | 8080/TCP | HTTP | None | localhost |
| 3 | Prometheus | Operator Manager | 8080/TCP | HTTP | None | Bearer Token |

### Flow 4: InferenceService Monitoring

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Operator Manager | Kubernetes API (watch InferenceService) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Operator Manager | Kubernetes API (patch Deployment env) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | InferenceService Pod | TrustyAI Service | 8080/TCP | HTTP | None | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| KServe InferenceService | CR Watch/Patch | 6443/TCP | HTTPS | TLS 1.2+ | Monitor and configure inference services for explainability |
| KServe ServingRuntime | CR Watch | 6443/TCP | HTTPS | TLS 1.2+ | Track serving runtime deployments |
| Prometheus | ServiceMonitor | 80/TCP (service), 8080/TCP (operator) | HTTP | None | Metrics collection for bias/fairness monitoring |
| OpenShift OAuth | OAuth Redirect | 443/TCP | HTTPS | TLS 1.2+ | User authentication for TrustyAI service access |
| OpenShift Router | Route | 443/TCP | HTTPS | TLS 1.2+ (passthrough) | External ingress to TrustyAI service |
| Model Mesh | Environment Variable Injection | N/A | N/A | N/A | Configure payload processors for inference data |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| e9bffad | Recent | - Merge pull request #13 from trustyai-explainability/main |
| c87bce3 | Recent | - Change metrics service pod target to 8080 (#187) |
| e1c8615 | Recent | - Merge pull request #12 from red-hat-data-services/RHOAIENG-2190 |
| 2b96433 | Recent | - [RHOAIENG-2190] Change ose-auth-proxy image `latest` to SHA |
| 4f97fcd | Recent | - Merge pull request #11 from trustyai-explainability/main |
| df6296a | Recent | - [RHOAIENG-2135] Add unique ClusterRoleBinding names (#185) |
| bd4d72e | Recent | - Fix typo in README.md (#183) |
| 673c4bd | Recent | - Merge pull request #10 from trustyai-explainability/main |
| 4b6b8e0 | Recent | - Rename TrustyAI `apiGroup` to `trustyai.opendatahub.io` (#169) |
| a6f4a3d | Recent | - Merge pull request #9 from trustyai-explainability/main |
| dba4132 | Recent | - RHOAIENG-1740: go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp to fix CVE-2022-21698 (#181) |
| fe17e2b | Recent | - RHOAIENG-1739: Bump github.com/elazarl/goproxy to fix CVE-2023-37788 (#178) |
| dc5d489 | Recent | - Correct operator's instance label (#176) |
| ce98f16 | Recent | - Remove obsolete patches (#172) |
| 3af6912 | Recent | - Add OAuth to external endpoints (#140) |
| 650d129 | Recent | - Add YAML linting workflow and fix YAML formatting (#163) |

## Deployment Configuration

### Operator Deployment

- **Image**: quay.io/trustyai/trustyai-service-operator:latest (configurable via params.env)
- **Replicas**: 1
- **Service Account**: controller-manager
- **Health Probes**:
  - Liveness: /healthz on port 8081 (15s initial delay, 20s period)
  - Readiness: /readyz on port 8081 (5s initial delay, 10s period)
- **Resource Limits**: 500m CPU, 128Mi memory
- **Resource Requests**: 10m CPU, 64Mi memory
- **Security Context**: runAsNonRoot, no privilege escalation, drop all capabilities

### Managed TrustyAI Service Deployment

- **Image**: quay.io/trustyai/trustyai-service:latest (configurable via ConfigMap)
- **OAuth Proxy Image**: registry.redhat.io/openshift4/ose-oauth-proxy@sha256:ab112105ac37352a2a4916a39d6736f5db6ab4c29bad4467de8d613e80e9bb33
- **Replicas**: 1 (configurable in TrustyAIService CR)
- **Containers**:
  1. TrustyAI Service (port 8080)
  2. OAuth Proxy (port 8443)
- **Volumes**:
  - PersistentVolumeClaim (size configurable in CR)
  - TLS secret for OAuth proxy
- **Environment Variables**:
  - STORAGE_DATA_FILENAME
  - SERVICE_STORAGE_FORMAT
  - STORAGE_DATA_FOLDER
  - SERVICE_DATA_FORMAT
  - SERVICE_METRICS_SCHEDULE
  - SERVICE_BATCH_SIZE

## Storage Configuration

- **Type**: PersistentVolumeClaim (PVC)
- **Access Mode**: ReadWriteOnce
- **Size**: Configurable in TrustyAIService CR (e.g., "1Gi")
- **Format**: Configurable (PVC)
- **Mount Path**: Configurable in TrustyAIService CR (e.g., "/inputs")
- **Purpose**: Stores inference data and metrics for bias/fairness analysis

## Monitoring and Observability

### ServiceMonitors

1. **Operator Metrics**:
   - Name: controller-manager-metrics-monitor
   - Path: /metrics
   - Port: https (8080)
   - Scheme: https with bearer token

2. **Local TrustyAI Service Monitor** (per instance):
   - Name: {instance-name}
   - Path: /q/metrics
   - Port: http (80)
   - Interval: 4s
   - Scheme: http
   - Metrics: trustyai_spd, trustyai_dir
   - Namespace: Same as TrustyAIService instance

3. **Central TrustyAI Service Monitor**:
   - Name: trustyai-metrics
   - Path: /q/metrics
   - Port: http (80)
   - Interval: 4s
   - Namespace Selector: Any
   - Label Selector: app.kubernetes.io/part-of=trustyai

### Prometheus Metrics Exposed

- **trustyai_spd**: Statistical Parity Difference (fairness metric)
- **trustyai_dir**: Disparate Impact Ratio (fairness metric)
- Additional custom metrics from TrustyAI service

## Key Features

1. **Automated Deployment**: Provisions complete TrustyAI infrastructure from single CR
2. **OAuth Integration**: Automatic setup of OpenShift OAuth for secure access
3. **KServe Integration**: Monitors and configures InferenceServices for bias detection
4. **Persistent Storage**: Manages PVCs for inference data and metrics storage
5. **Prometheus Integration**: Automatic ServiceMonitor creation for metrics collection
6. **OpenShift Routes**: Automatic external access configuration with TLS
7. **Leader Election**: High availability with leader election for operator instances
8. **Finalizer Support**: Proper cleanup of external dependencies on deletion
