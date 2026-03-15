# Component: ModelMesh Serving

## Metadata
- **Repository**: https://github.com/red-hat-data-services/modelmesh-serving
- **Version**: v1.27.0-rhods-168 (upstream: v0.11.0)
- **Branch**: rhoai-2.7
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator with Webhooks

## Purpose
**Short**: Model serving management and routing layer for deploying and serving machine learning models at scale.

**Detailed**: ModelMesh Serving is a Kubernetes operator that provides intelligent model placement, routing, and lifecycle management for serving machine learning models. It acts as a controller for the ModelMesh framework, which orchestrates multiple model server runtimes (Triton, MLServer, OpenVINO, TorchServe) within shared pods to maximize resource utilization. The controller manages Custom Resource Definitions (InferenceService, ServingRuntime, Predictor) that define model deployments, watches for changes, and reconciles the desired state by creating and managing Kubernetes resources. ModelMesh uses etcd as a distributed key-value store for model metadata and placement decisions, enabling horizontal scaling and high availability. The component includes a REST proxy to translate HTTP inference requests to gRPC, runtime adapters for model loading/unloading, and comprehensive RBAC controls for multi-tenant deployments.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| ModelMesh Controller | Go Operator (Deployment) | Reconciles InferenceService, ServingRuntime, Predictor CRDs; manages model serving deployments |
| Webhook Server | Validating Admission Webhook | Validates ServingRuntime custom resources before creation/update |
| ModelMesh Runtime Pods | Managed Deployments | Contains ModelMesh container, runtime adapter, model server, and optional REST proxy |
| etcd | External Dependency | Distributed key-value store for model metadata, placement, and routing decisions |
| Runtime Adapter | Sidecar Container | Intermediary between ModelMesh and model server; handles model pull, load, unload operations |
| REST Proxy | Optional Sidecar | Translates KServe V2 REST API to gRPC for inference requests |
| Model Servers | Runtime Containers | Triton, MLServer, OpenVINO, or TorchServe containers that execute model inference |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Declarative API for deploying ML models with predictor, transformer, explainer components |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Template defining model server container, supported formats, and runtime configuration |
| serving.kserve.io | v1alpha1 | ClusterServingRuntime | Cluster | Cluster-scoped ServingRuntime template available to all namespaces |
| serving.kserve.io | v1alpha1 | Predictor | Namespaced | ModelMesh-specific predictor resource for model deployment with storage and runtime selection |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for controller |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | kube-rbac-proxy | Authenticated Prometheus metrics via auth proxy |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe for controller health |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe for controller health |
| /validate-serving-modelmesh-io-v1alpha1-servingruntime | POST | 9443/TCP | HTTPS | TLS 1.2+ | cert-manager CA | Validating webhook for ServingRuntime CR |
| /v2/models/{model}/infer | POST | 8008/TCP | HTTP | None | None | KServe V2 REST inference endpoint (via REST proxy) |
| /v2/models/{model}/ready | GET | 8008/TCP | HTTP | None | None | Model readiness check (via REST proxy) |
| /metrics | GET | 2112/TCP | HTTP | None | None | Prometheus metrics from ModelMesh runtime pods |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| inference.GRPCInferenceService | 8033/TCP | gRPC | None | None | KServe V2 gRPC inference protocol endpoint |
| ModelMesh | 8033/TCP | gRPC | None | None | Internal ModelMesh management and routing |
| ModelRuntime | 8001/TCP | gRPC | None | None | Model server management endpoint (Triton) |
| ModelRuntime | 8085/TCP | gRPC | None | None | Model server inference endpoint (Triton) |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| etcd | v3.5.4+ | Yes | Distributed key-value store for model metadata and placement decisions |
| cert-manager | v1.x | Yes | TLS certificate provisioning for webhook server |
| Prometheus Operator | v0.x | No | ServiceMonitor CRD for metrics collection |
| S3-compatible storage | Any | Yes | Object storage for model artifacts (MinIO, AWS S3, etc.) |
| KServe CRDs | v0.11.1 | Yes | InferenceService and runtime CRD definitions |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH/RHOAI Dashboard | UI Integration | Model serving deployment management interface |
| ODH/RHOAI Monitoring | Metrics Collection | ServiceMonitor watches modelmesh-serving metrics endpoints |
| Service Mesh (Istio) | Network Proxy | Optional ingress/egress routing and mTLS for inference endpoints |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | https | HTTPS | TLS 1.2+ | kube-rbac-proxy | Internal |
| modelmesh-webhook-server-service | ClusterIP | 9443/TCP | webhook | HTTPS | TLS 1.2+ | cert-manager CA | Internal (K8s API) |
| modelmesh-serving (per namespace) | ClusterIP | 8033/TCP | 8033 | gRPC | None | None | Internal/External* |
| modelmesh-serving (REST proxy) | ClusterIP | 8008/TCP | 8008 | HTTP | None | None | Internal/External* |

*Exposure depends on Istio VirtualService or Route configuration

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| Webhook (Kubernetes API) | ValidatingWebhookConfiguration | N/A | 9443/TCP | HTTPS | TLS 1.2+ | Server Auth | Internal (K8s control plane) |
| Inference (optional) | Istio VirtualService | user-defined | 8033/TCP or 8008/TCP | gRPC/HTTP | TLS 1.2+ (optional) | SIMPLE | External (if configured) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| etcd | 2379/TCP | HTTP | None | Optional (etcd auth) | Model metadata storage and retrieval |
| S3-compatible storage | 443/TCP | HTTPS | TLS 1.2+ | AWS Signature V4 | Model artifact download during loading |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Registry auth | Pull runtime and adapter container images |
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token | Watch CRDs, manage resources |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| modelmesh-controller-role | "" | configmaps, secrets, services, namespaces | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | "" | endpoints, persistentvolumeclaims | get, list, watch |
| modelmesh-controller-role | apps | deployments, deployments/finalizers | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | serving.kserve.io | inferenceservices, predictors, servingruntimes, clusterservingruntimes | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | serving.kserve.io | inferenceservices/status, predictors/status, servingruntimes/status | get, patch, update |
| modelmesh-controller-role | autoscaling | horizontalpodautoscalers | create, delete, get, list, update, watch |
| modelmesh-controller-role | monitoring.coreos.com | servicemonitors | create, delete, get, list, patch, update, watch |
| inferenceservice-editor-role | serving.kserve.io | inferenceservices, predictors | create, delete, get, list, patch, update, watch |
| inferenceservice-viewer-role | serving.kserve.io | inferenceservices, predictors | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| modelmesh-controller-rolebinding (ClusterRoleBinding) | N/A | modelmesh-controller-role (ClusterRole) | modelmesh-controller (controller namespace) |
| modelmesh-controller-rolebinding (RoleBinding) | controller namespace | modelmesh-controller-role (Role) | modelmesh-controller |
| leader-election-rolebinding | controller namespace | leader-election-role | modelmesh-controller |
| proxy-rolebinding | controller namespace | proxy-role | modelmesh-controller |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| model-serving-etcd | Opaque | etcd connection configuration (endpoints, root_prefix) | User/Admin | No |
| storage-config | Opaque | S3 credentials and configuration for model storage | User/Admin | No |
| webhook-server-cert | kubernetes.io/tls | TLS certificate for validating webhook server | cert-manager | Yes |
| modelmesh-serving-sa-token | kubernetes.io/service-account-token | ServiceAccount token for runtime pods | Kubernetes | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics (8443) | GET | Bearer Token (ServiceAccount) | kube-rbac-proxy | ClusterRole: cluster-monitoring-view |
| /validate-* (9443) | POST | X.509 Client Cert | Kubernetes API Server | ValidatingWebhookConfiguration |
| Inference endpoints (8033, 8008) | POST, GET | None (default) | Application (optional Istio) | None (application-defined) |
| Kubernetes API | All | Bearer Token (ServiceAccount) | Kubernetes API Server | ClusterRole: modelmesh-controller-role |

## Data Flows

### Flow 1: Model Deployment via InferenceService

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CLI | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Kubernetes API | Controller Webhook | 9443/TCP | HTTPS | TLS 1.2+ | K8s API cert |
| 3 | Webhook | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 4 | Kubernetes API | Controller (Reconcile) | N/A | Watch API | TLS 1.2+ | ServiceAccount token |
| 5 | Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 6 | Controller | etcd | 2379/TCP | HTTP | None | Optional |

### Flow 2: Model Inference Request (gRPC)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | modelmesh-serving Service | 8033/TCP | gRPC | None | Application-defined |
| 2 | Service | ModelMesh Pod | 8033/TCP | gRPC | None | None |
| 3 | ModelMesh | etcd | 2379/TCP | HTTP | None | Optional |
| 4 | ModelMesh | Runtime Adapter | 8001/TCP | gRPC | None | None |
| 5 | Runtime Adapter | Model Server | 8085/TCP | gRPC | None | None |

### Flow 3: Model Inference Request (REST)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | modelmesh-serving Service | 8008/TCP | HTTP | None | Application-defined |
| 2 | Service | REST Proxy | 8008/TCP | HTTP | None | None |
| 3 | REST Proxy | ModelMesh | 8033/TCP | gRPC | None | None |
| 4 | ModelMesh | etcd | 2379/TCP | HTTP | None | Optional |
| 5 | ModelMesh | Runtime Adapter | 8001/TCP | gRPC | None | None |
| 6 | Runtime Adapter | Model Server | 8085/TCP | gRPC | None | None |

### Flow 4: Model Loading from Storage

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Runtime Adapter (puller) | S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Access Keys |
| 2 | Runtime Adapter | Local Filesystem | N/A | N/A | N/A | N/A |
| 3 | Runtime Adapter | Model Server | 8001/TCP | gRPC | None | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| etcd | Client Connection | 2379/TCP | HTTP | None | Model registry, placement, and routing metadata |
| Kubernetes API | Watch/Reconcile | 6443/TCP | HTTPS | TLS 1.2+ | CRD management and resource reconciliation |
| Prometheus | Scrape Metrics | 8443/TCP, 2112/TCP | HTTPS, HTTP | TLS 1.2+ (8443) | Operator and runtime metrics collection |
| S3 Storage | Object Retrieval | 443/TCP | HTTPS | TLS 1.2+ | Model artifact storage backend |
| Model Servers (Triton, MLServer, etc.) | gRPC Management | 8001/TCP, 8085/TCP | gRPC | None | Model load/unload and inference execution |
| Istio Service Mesh (optional) | Sidecar Injection | N/A | N/A | mTLS (optional) | Ingress routing, observability, mTLS |

## Network Policies

### Controller Network Policy

| Policy Name | Pod Selector | Ingress Allowed | Ports |
|-------------|--------------|-----------------|-------|
| modelmesh-controller | control-plane: modelmesh-controller | Any source | 8443/TCP (metrics) |
| modelmesh-webhook | control-plane: modelmesh-controller | Any source (K8s API) | 9443/TCP (webhook) |

### Runtime Network Policy

| Policy Name | Pod Selector | Ingress Allowed | Ports |
|-------------|--------------|-----------------|-------|
| modelmesh-runtimes | modelmesh-service: exists | Any source | 8033/TCP, 8008/TCP (inference) |
| modelmesh-runtimes | modelmesh-service: exists | Pods with label: app.kubernetes.io/managed-by: modelmesh-controller | 8033/TCP, 8080/TCP (internal) |
| modelmesh-runtimes | modelmesh-service: exists | Any source | 2112/TCP (metrics) |

### etcd Network Policy

| Policy Name | Pod Selector | Ingress Allowed | Ports |
|-------------|--------------|-----------------|-------|
| etcd | component: model-mesh-etcd | Namespace with label: modelmesh-enabled: "true" | 2379/TCP |
| etcd | component: model-mesh-etcd | Same namespace pods | 2379/TCP |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| v1.27.0-rhods-168 | 2024-01-17 | - Merged upstream release-0.11.1<br>- Applied patch to remove empty caBundle string<br>- Fixed docker build failures<br>- Updated Knative serving dependencies |
| v1.27.0-rhods-160 | 2024-01-16 | - Address CVE-2023-37788: github.com/elazarl/goproxy DoS vulnerability<br>- Fix CVE-2023-48795: Stack-based buffer overflow in protobuf<br>- Resolve github.com/pkg/sftp DoS vulnerability<br>- Fix vulnerabilities in otelhttp dependency |
| v0.11.1.0 | 2023-10-30 | - Update image tags to ODH builds v0.11.1.0<br>- Promote 0.11.1 branch for stable release<br>- Fix conflicts in 0.11.1 merge |
| v0.11.0.0 | 2023-10-27 | - Update image tags to ODH build v0.11.0.0<br>- Merge upstream release-0.11.0 |
| CVE Fixes | 2023-10-20 | - [RHODS-12555] Fix CVE-2023-44487 (HTTP/2 Rapid Reset vulnerability) |

## Component Versions

Based on upstream KServe ModelMesh v0.11.0/v0.11.1:

| Component | Version | Image |
|-----------|---------|-------|
| ModelMesh Controller | v1.27.0-rhods-168 | modelmesh-controller:latest |
| ModelMesh Runtime | v0.11.1 | kserve/modelmesh:v0.11.1 |
| Runtime Adapter | v0.11.1 | kserve/modelmesh-runtime-adapter:v0.11.1 |
| REST Proxy | v0.11.1 | kserve/rest-proxy:v0.11.1 |
| Triton Server | 2.x | tritonserver-2:replace |
| MLServer | 1.x | seldonio/mlserver:replace |
| OpenVINO Model Server | 1.x | openvino/model_server:replace |
| TorchServe | 0.x | pytorch/torchserve:replace |

## Deployment Modes

### Cluster-Scope Mode (Default)
- Controller watches all namespaces
- Requires ClusterRole and ClusterRoleBinding
- Manages InferenceServices across cluster
- Enables ClusterServingRuntime resources

### Namespace-Scope Mode
- Controller watches single namespace (own namespace)
- Uses Role and RoleBinding (namespace-scoped)
- Isolated to specific namespace
- ClusterServingRuntime not available
- Set via environment variable: `NAMESPACE_SCOPE=true`

## Configuration

### Controller Configuration (ConfigMap: model-serving-config-defaults)

| Setting | Default | Purpose |
|---------|---------|---------|
| podsPerRuntime | 2 | Number of runtime pods created per ServingRuntime |
| headlessService | true | Create headless service for runtime pods |
| modelMeshImage | kserve/modelmesh:v0.11.1 | ModelMesh framework container image |
| restProxy.enabled | true | Enable REST proxy sidecar for HTTP inference |
| restProxy.port | 8008 | REST proxy listen port |
| storageHelperImage | kserve/modelmesh-runtime-adapter:v0.11.1 | Runtime adapter/puller image |
| serviceAccountName | modelmesh-serving-sa | ServiceAccount for runtime pods |
| metrics.enabled | true | Enable Prometheus metrics collection |
| builtInServerTypes | triton, mlserver, ovms, torchserve | Pre-configured model server runtimes |

## Known Limitations

1. **Storage**: Models must be stored in S3-compatible object storage; local storage not supported
2. **Protocol**: Primary inference protocol is gRPC; REST requires proxy container overhead
3. **Scaling**: Horizontal autoscaling requires manual HPA configuration; not auto-configured
4. **Security**: Inference endpoints have no built-in authentication; requires external auth (Istio, OAuth proxy)
5. **Multi-tenancy**: Network isolation requires NetworkPolicy support in cluster
6. **etcd**: Single point of failure if not configured for HA; production deployments need etcd clustering
7. **Model Size**: Large models may exceed runtime adapter timeout (90s default); requires tuning
8. **GPU**: GPU scheduling requires cluster GPU operator; not handled by ModelMesh controller

## Observability

### Metrics Endpoints

| Endpoint | Port | Purpose | Scraped By |
|----------|------|---------|------------|
| /metrics | 8443/TCP | Controller metrics (reconciliation, webhook) | Prometheus Operator (ServiceMonitor) |
| /metrics | 2112/TCP | Runtime metrics (inference latency, model load time, cache hit rate) | Prometheus Operator (PodMonitor or ServiceMonitor) |

### Health Checks

| Endpoint | Port | Type | Purpose |
|----------|------|------|---------|
| /healthz | 8081/TCP | Liveness | Controller process health |
| /readyz | 8081/TCP | Readiness | Controller ready to handle webhooks and reconciliation |

### Logging

- **Controller**: Structured JSON logging to stdout (controllable via DEV_MODE_LOGGING env var)
- **ModelMesh Runtime**: Container logs to stdout/stderr
- **Model Servers**: Server-specific logging to stdout/stderr

## Troubleshooting

### Common Issues

1. **InferenceService Stuck in Pending**: Check ServingRuntime exists, storage secret configured, etcd connectivity
2. **Webhook Errors**: Verify cert-manager running, webhook service reachable from K8s API server
3. **Model Load Failures**: Check storage credentials, network egress to S3, runtime adapter logs
4. **Inference 503 Errors**: Verify model loaded (check Predictor status), ModelMesh pod health, etcd connectivity
5. **Controller Crash Loop**: Check RBAC permissions, namespace configuration, leader election lock

### Debug Commands

```bash
# Check controller logs
kubectl logs -n <namespace> deployment/modelmesh-controller

# Check runtime pod logs
kubectl logs -n <namespace> <modelmesh-pod> -c mm

# Check predictor status
kubectl get predictors -n <namespace> <name> -o yaml

# Check etcd connectivity
kubectl exec -n <namespace> <modelmesh-pod> -c mm -- curl http://etcd:2379/health

# Verify webhook configuration
kubectl get validatingwebhookconfigurations modelmesh-validating-webhook-configuration

# Check ServiceMonitor
kubectl get servicemonitor -n <namespace> modelmesh-service-monitor
```
