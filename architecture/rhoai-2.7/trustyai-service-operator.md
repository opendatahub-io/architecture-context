# Component: TrustyAI Service Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/trustyai-service-operator
- **Version**: eb7d626
- **Branch**: rhoai-2.7
- **Distribution**: RHOAI
- **Languages**: Go 1.19
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes operator that manages the deployment and lifecycle of TrustyAI explainability services for AI/ML model monitoring and fairness metrics.

**Detailed**: The TrustyAI Service Operator simplifies the deployment and management of TrustyAI services on Kubernetes and OpenShift clusters. It watches for custom resources of kind `TrustyAIService` in the `trustyai.opendatahub.io` API group and automatically manages corresponding deployments, services, routes, and monitoring resources. The operator integrates with KServe InferenceServices (both ModelMesh and native KServe modes) to provide AI explainability and fairness monitoring capabilities. It automatically configures payload processors for ModelMesh deployments and inference loggers for KServe deployments, enabling real-time monitoring of model predictions. The operator ensures services are properly secured with OAuth authentication, discoverable by Prometheus for metrics scraping, and accessible via OpenShift Routes with TLS encryption.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Operator Controller Manager | Go Binary | Reconciles TrustyAIService CRs and manages lifecycle of TrustyAI deployments |
| TrustyAIService Controller | Reconciler | Watches TrustyAIService, InferenceService, and ServingRuntime resources |
| Service Deployment | Kubernetes Deployment | Runs TrustyAI service with OAuth proxy sidecar for authentication |
| OAuth Proxy | Sidecar Container | Provides OpenShift OAuth authentication for TrustyAI service endpoints |
| Persistent Volume Claim | Storage | Stores model inference data and metrics data |
| Service Monitors | Prometheus Integration | Enables metrics collection from TrustyAI services |
| Routes | OpenShift Route | Provides external HTTPS access to TrustyAI services |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| trustyai.opendatahub.io | v1alpha1 | TrustyAIService | Namespaced | Declares desired state of TrustyAI service deployment including storage, data format, and metrics configuration |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Operator controller manager metrics |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness probe |
| /q/metrics | GET | 8080/TCP | HTTP | None | Internal | TrustyAI service metrics (internal) |
| /consumer/kserve/v2 | POST | 8080/TCP | HTTP | None | Internal | KServe v2 payload consumer endpoint |
| / | ALL | 8443/TCP | HTTPS | TLS 1.2+ | OAuth | OAuth proxy authenticated access to TrustyAI service |
| /oauth/healthz | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | OAuth proxy health check |

### gRPC Services

None - TrustyAI operator uses HTTP/REST APIs only.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | v1.19+ | Yes | Container orchestration platform |
| OpenShift | v4.6+ | No | Provides Route, OAuth, and TLS certificate services |
| Prometheus Operator | v0.64.1 | Yes | ServiceMonitor CRD for metrics collection |
| KServe | v0.11.0 | No | InferenceService and ServingRuntime CRDs for ML model serving integration |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KServe | CRD Watch/Update | Monitors InferenceServices and configures payload logging to TrustyAI |
| ModelMesh | Deployment Patch | Injects MM_PAYLOAD_PROCESSORS environment variable into ModelMesh deployments |
| Prometheus | ServiceMonitor | Exposes TrustyAI fairness and bias metrics for collection |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| [instance-name] | ClusterIP | 80/TCP | 8080 | HTTP | None | None | Internal |
| [instance-name]-tls | ClusterIP | 443/TCP | 8443 | HTTPS | TLS (OpenShift service-ca) | OAuth | Internal |
| controller-manager-metrics-service | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS | Bearer Token | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| [instance-name] | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ | Passthrough | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch CRDs and manage resources |
| InferenceService Pods | 8080/TCP | HTTP | None | None | Receive inference payloads from KServe/ModelMesh |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | trustyai.opendatahub.io | trustyaiservices, trustyaiservices/status, trustyaiservices/finalizers | get, list, watch, create, update, patch, delete |
| manager-role | apps | deployments, deployments/status, deployments/finalizers | get, list, watch, create, update, patch, delete |
| manager-role | "" (core) | services, pods, configmaps, secrets, serviceaccounts, persistentvolumeclaims, persistentvolumes, events | get, list, watch, create, update, patch, delete |
| manager-role | serving.kserve.io | inferenceservices, inferenceservices/finalizers, servingruntimes, servingruntimes/status | get, list, watch, update, patch, delete, create |
| manager-role | route.openshift.io | routes | get, list, watch, create, update, patch, delete |
| manager-role | monitoring.coreos.com | servicemonitors | list, watch, create |
| manager-role | rbac.authorization.k8s.io | clusterrolebindings | get, list, watch, create, update, delete |
| proxy-role | authentication.k8s.io | tokenreviews | create |
| proxy-role | authorization.k8s.io | subjectaccessreviews | create |
| leader-election-role | "" (core) | configmaps, leases | get, list, watch, create, update, patch |
| trustyai-service-operator-proxy-role | authentication.k8s.io | tokenreviews | create |
| trustyai-service-operator-proxy-role | authorization.k8s.io | subjectaccessreviews | create |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | Cluster-wide | manager-role (ClusterRole) | controller-manager (operator namespace) |
| proxy-rolebinding | Cluster-wide | proxy-role (ClusterRole) | controller-manager (operator namespace) |
| leader-election-rolebinding | Operator namespace | leader-election-role (Role) | controller-manager (operator namespace) |
| [instance-name]-[namespace]-proxy-rolebinding | Cluster-wide | trustyai-service-operator-proxy-role (ClusterRole) | [instance-name]-proxy (instance namespace) |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| [instance-name]-tls | kubernetes.io/tls | TLS certificate for OAuth proxy service | OpenShift service-ca | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| / (via Route) | ALL | OpenShift OAuth + SAR | OAuth Proxy | User must have 'get pods' permission in TrustyAI service namespace |
| /apis/v1beta1/healthz | GET | None (skip-auth-regex) | OAuth Proxy | Public health check endpoint |
| /metrics (operator) | GET | Bearer Token (ServiceAccount) | Kubernetes RBAC | Requires tokenreviews and subjectaccessreviews permissions |

## Data Flows

### Flow 1: TrustyAI Service Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | kubeconfig credentials |
| 2 | Kubernetes API | Operator Controller | N/A | Internal | N/A | ServiceAccount Token |
| 3 | Operator Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Operator Controller | Kubernetes API (create PVC, Deployment, Service, Route) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: KServe Inference Logging to TrustyAI

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | KServe InferenceService | TrustyAI Service | 8080/TCP | HTTP | None | None |
| 2 | TrustyAI Service | PVC Storage | N/A | Filesystem | None | N/A |
| 3 | TrustyAI Service | TrustyAI Service /q/metrics | 8080/TCP | HTTP | None | None |

### Flow 3: External User Access to TrustyAI Service

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External User | OpenShift Route | 443/TCP | HTTPS | TLS 1.2+ (Route cert) | None |
| 2 | OpenShift Router | OAuth Proxy (Service) | 443/TCP | HTTPS | TLS 1.2+ (service-ca) | None |
| 3 | OAuth Proxy | OpenShift OAuth | 443/TCP | HTTPS | TLS 1.2+ | None |
| 4 | OAuth Proxy | Kubernetes API (SAR check) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | OAuth Proxy | TrustyAI Service | 8080/TCP | HTTP | None | None |

### Flow 4: Prometheus Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | TrustyAI Service | 80/TCP | HTTP | None | None |
| 2 | TrustyAI Service | Return metrics from /q/metrics | 80/TCP | HTTP | None | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| KServe InferenceService | CR Update | 6443/TCP | HTTPS | TLS 1.2+ | Configure Logger spec to send payloads to TrustyAI |
| ModelMesh Deployment | Deployment Patch | 6443/TCP | HTTPS | TLS 1.2+ | Inject MM_PAYLOAD_PROCESSORS environment variable |
| Prometheus | ServiceMonitor CR | N/A | N/A | N/A | Define metrics scrape configuration |
| OpenShift OAuth | HTTP API | 443/TCP | HTTPS | TLS 1.2+ | Authenticate users accessing TrustyAI services |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| eb7d626 | 2024-02-09 | - Merged changes from upstream trustyai-explainability/main |
| 921e941 | 2024-02-09 | - Remove /metrics from skip-auth regex to require authentication |
| 085c916 | 2024-02-09 | - Merged patch to update ose-auth-proxy image |
| 079b8a7 | 2024-02-09 | - Update ose-auth-proxy image SHA |
| 790a412 | 2024-02-08 | - Add missing labels to OAuth service (#192) |
| 7282090 | 2024-02-06 | - [RHOAIENG-2304] Refactor deployment to use templates (#189) |
| c87bce3 | 2024-01-30 | - Change metrics service pod target to 8080 (#187) |
| df6296a | 2024-01-25 | - [RHOAIENG-2135] Add unique ClusterRoleBinding names (#185) |
| bd4d72e | 2024-01-24 | - Fix typo in README.md (#183) |
| 4b6b8e0 | 2024-01-18 | - Rename TrustyAI apiGroup to trustyai.opendatahub.io (#169) |
| dba4132 | 2024-01-17 | - RHOAIENG-1740: Update go.opentelemetry.io to fix CVE-2022-21698 (#181) |
| fe17e2b | 2024-01-16 | - RHOAIENG-1739: Bump github.com/elazarl/goproxy to fix CVE-2023-37788 (#178) |
| dc5d489 | 2023-12-21 | - Correct operator's instance label (#176) |
| ce98f16 | 2023-12-20 | - Remove obsolete patches (#172) |

## Deployment Configuration

### Container Images

| Container | Default Image | Purpose | Configurable Via |
|-----------|---------------|---------|------------------|
| Operator Manager | quay.io/trustyai/trustyai-service-operator:latest | Operator controller manager | Deployment manifest |
| TrustyAI Service | quay.io/trustyai/trustyai-service:latest | AI explainability service | ConfigMap: trustyai-service-operator-config (trustyaiServiceImage) |
| OAuth Proxy | registry.redhat.io/openshift4/ose-oauth-proxy:latest | Authentication proxy | ConfigMap: trustyai-service-operator-config (oauthProxyImage) |

### Resource Requirements

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| Operator Manager | 10m | 500m | 64Mi | 128Mi |
| OAuth Proxy | 100m | 100m | 64Mi | 64Mi |

### Security Context

| Component | runAsNonRoot | allowPrivilegeEscalation | Capabilities | seccompProfile |
|-----------|--------------|--------------------------|--------------|----------------|
| Operator Manager | true | false | DROP ALL | RuntimeDefault |
| TrustyAI Service | Default | Default | Default | Default |
| OAuth Proxy | Default | Default | Default | Default |

## Storage

| Type | Access Mode | Default Size | Purpose |
|------|-------------|--------------|---------|
| PersistentVolumeClaim | ReadWriteOnce | User-specified (e.g., 1Gi) | Store inference data and metrics data |

## Monitoring & Observability

### Metrics Exposed

| Metric Pattern | Type | Purpose | Scrape Interval |
|----------------|------|---------|-----------------|
| trustyai_spd | Gauge | Statistical Parity Difference fairness metric | 4s |
| trustyai_dir | Gauge | Disparate Impact Ratio fairness metric | 4s |
| trustyai_* | Various | TrustyAI-specific metrics | 4s |

### ServiceMonitor Configuration

| Type | Namespace | Selector | Path | Scheme |
|------|-----------|----------|------|--------|
| Local | TrustyAI instance namespace | app.kubernetes.io/part-of=trustyai | /q/metrics | http |
| Central | Operator namespace | app.kubernetes.io/part-of=trustyai | /q/metrics | http |
| Operator | Operator namespace | control-plane=controller-manager | /metrics | https |

## Known Limitations & Considerations

1. **Platform Dependency**: OAuth proxy and Route features require OpenShift; on vanilla Kubernetes, these features are unavailable
2. **Storage**: PVC must be created and bound before TrustyAI deployment becomes ready
3. **InferenceService Integration**: Automatically patches InferenceServices in the same namespace; ModelMesh deployments must have label `modelmesh-service=modelmesh-serving`
4. **Authentication**: Skip-auth-regex only applies to `/apis/v1beta1/healthz` endpoint; all other endpoints require OpenShift OAuth authentication
5. **Metrics Batch Size**: Default batch size is 5000; configurable via TrustyAIService spec
6. **Leader Election**: Operator supports leader election with lease-based coordination

## Example TrustyAIService Custom Resource

```yaml
apiVersion: trustyai.opendatahub.io/v1alpha1
kind: TrustyAIService
metadata:
  name: trustyai-service-example
  namespace: trustyai-demo
spec:
  storage:
    format: "PVC"
    folder: "/inputs"
    size: "1Gi"
  data:
    filename: "data.csv"
    format: "CSV"
  metrics:
    schedule: "5s"
    batchSize: 5000
  replicas: 1
```
