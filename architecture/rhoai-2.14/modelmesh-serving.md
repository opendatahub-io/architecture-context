# Component: ModelMesh Serving

## Metadata
- **Repository**: https://github.com/red-hat-data-services/modelmesh-serving
- **Version**: v1.27.0-rhods-261-ga0b0401
- **Branch**: rhoai-2.14
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes controller for managing ModelMesh, a general-purpose model serving management and routing layer.

**Detailed**: ModelMesh Serving is a Kubernetes operator that orchestrates the deployment and lifecycle management of machine learning model inference workloads. It manages the ModelMesh framework which provides intelligent model placement, routing, and auto-scaling across a pool of inference runtime containers. The controller watches custom resources (Predictors, ServingRuntimes, InferenceServices) and dynamically provisions model serving deployments with support for multiple runtime backends including Triton, MLServer, OpenVINO, and TorchServe. It integrates with etcd for distributed coordination, provides REST and gRPC inference APIs, and includes features for model loading from various storage backends (S3, PVC, etc.).

ModelMesh optimizes resource utilization by allowing multiple models to share runtime pods, with intelligent loading/unloading based on usage patterns. The controller manages the complete stack including the model mesh layer, runtime adapters, storage helpers (pullers), and optional REST-to-gRPC proxies for KServe V2 API compatibility.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| modelmesh-controller | Deployment | Main controller that reconciles CRs and manages ModelMesh deployments |
| modelmesh | Container | Model serving orchestration layer in runtime pods |
| modelmesh-runtime-adapter | Container | Adapter between ModelMesh and model server containers |
| rest-proxy | Container | KServe V2 REST to gRPC translation proxy |
| storage-helper (puller) | Init Container | Downloads models from storage before loading |
| etcd | Deployment | Distributed coordination and metadata storage |
| webhook-server | Service | Validating webhook for ServingRuntime CRs |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1alpha1 | Predictor | Namespaced | Defines a model to be served with storage location, model type, and runtime selection |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Defines a model serving runtime configuration with container specs and supported model formats |
| serving.kserve.io | v1alpha1 | ClusterServingRuntime | Cluster | Cluster-scoped version of ServingRuntime available to all namespaces |
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | KServe InferenceService support for compatibility (optional) |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Controller metrics (internal) |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token | Controller metrics (external via kube-rbac-proxy) |
| /healthz | GET | 8081/TCP | HTTP | None | None | Controller liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Controller readiness probe |
| /validate-serving-modelmesh-io-v1alpha1-servingruntime | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server | Validating webhook for ServingRuntime CRs |
| /v2/models/{model}/infer | POST | 8008/TCP | HTTP | None | None | KServe V2 REST inference API (via REST proxy) |
| /metrics | GET | 2112/TCP | HTTP | None | None | Runtime pod Prometheus metrics |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ModelMesh Inference | 8033/TCP | gRPC | None | None | Model inference requests (KServe V2 gRPC protocol) |
| ModelMesh Internal | 8080/TCP | gRPC | None | None | Internal ModelMesh coordination (Litelinks RPC) |
| Runtime Management | 8085/TCP | gRPC | None | None | Runtime adapter management endpoint |
| Runtime Data | 8001/TCP | gRPC | None | None | Model server gRPC endpoint (e.g., MLServer) |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| etcd | v3.5+ | Yes | Distributed coordination, model registry, and metadata storage |
| S3-compatible storage | Any | Yes* | Model artifact storage (MinIO, AWS S3, etc.) |
| PersistentVolume | Any | Yes* | Alternative model storage via PVCs |
| cert-manager | v1.0+ | No | Certificate management for webhooks (optional) |
| Prometheus Operator | v0.55+ | No | ServiceMonitor for metrics collection |

*Note: Either S3 storage or PersistentVolume is required for model storage

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KServe | CRD/API | Imports ServingRuntime and InferenceService CRD definitions |
| ODH Dashboard | UI | Provides user interface for model serving management |
| ODH Operator | Controller | Manages ModelMesh Serving installation and configuration |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| modelmesh-controller-metrics-service | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | Bearer Token | Internal |
| modelmesh-webhook-server-service | ClusterIP | 9443/TCP | webhook | HTTPS | TLS 1.2+ | Kubernetes API | Internal |
| modelmesh-serving (per runtime) | ClusterIP | 8033/TCP | 8033 | gRPC | None | None | Internal/External* |
| modelmesh-serving (REST) | ClusterIP | 8008/TCP | 8008 | HTTP | None | None | Internal/External* |
| modelmesh-serving (metrics) | ClusterIP | 2112/TCP | 2112 | HTTP | None | None | Internal |
| etcd | ClusterIP | 2379/TCP | 2379 | HTTP | None | Credentials | Internal |

*Note: Inference services can be exposed externally via Istio Gateway or OpenShift Route

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| model-route-{name} | OpenShift Route | *.apps.cluster | 8033/TCP | gRPC | TLS passthrough | SIMPLE | External |
| model-route-{name}-rest | OpenShift Route | *.apps.cluster | 8008/TCP | HTTP | None/Edge | None | External |
| model-gateway | Istio Gateway | Custom | 443/TCP | HTTPS | TLS 1.3 | SIMPLE | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| S3 endpoints | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Access Keys | Model artifact download |
| S3 endpoints | 9000/TCP | HTTP | None | Access Keys | MinIO local storage (dev/test) |
| etcd | 2379/TCP | HTTP | None | Basic Auth/mTLS | Model registry and coordination |
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | CR reconciliation and resource management |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| modelmesh-controller-role | "" | configmaps | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | "" | secrets | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | "" | services, services/finalizers | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | "" | namespaces, namespaces/finalizers | get, list, patch, update, watch |
| modelmesh-controller-role | "" | endpoints, persistentvolumeclaims | get, list, watch |
| modelmesh-controller-role | apps | deployments, deployments/finalizers | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | serving.kserve.io | predictors, predictors/status, predictors/finalizers | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | serving.kserve.io | servingruntimes, servingruntimes/status, servingruntimes/finalizers | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | serving.kserve.io | clusterservingruntimes, clusterservingruntimes/status, clusterservingruntimes/finalizers | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | serving.kserve.io | inferenceservices, inferenceservices/status, inferenceservices/finalizers | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | monitoring.coreos.com | servicemonitors | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | autoscaling | horizontalpodautoscalers, horizontalpodautoscalers/status | create, delete, get, list, watch, update |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| modelmesh-controller-rolebinding | All/Cluster | modelmesh-controller-role | modelmesh-controller |
| modelmesh-leader-election-rolebinding | Controller NS | modelmesh-leader-election-role | modelmesh-controller |
| modelmesh-serving-sa-restricted-scc | Runtime NS | modelmesh-restricted-scc-role | modelmesh-serving-sa |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| model-serving-etcd | Opaque | etcd connection config and credentials | User/Operator | No |
| storage-config | Opaque | Model storage credentials (S3, etc.) | User/Operator | No |
| modelmesh-webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificate | cert-manager/Controller | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics (8443) | GET | Bearer Token (ServiceAccount) | kube-rbac-proxy | Kubernetes RBAC |
| /validate-* (9443) | POST | Kubernetes API Server mTLS | ValidatingWebhookConfiguration | Kubernetes admission |
| Inference (8033, 8008) | POST | None (delegated to service mesh) | NetworkPolicy/Istio | Application-defined |
| etcd (2379) | ALL | Basic Auth/Client Certs | etcd server | etcd auth |

### Network Policies

| Policy Name | Selector | Ingress Rules | Purpose |
|-------------|----------|---------------|---------|
| modelmesh-controller | control-plane=modelmesh-controller | Allow 8443/TCP from all | Expose metrics endpoint |
| modelmesh-runtimes | modelmesh-service=* | Allow 8033,8080/TCP from modelmesh pods; Allow 8033,8008,2112/TCP from all | Runtime inference and metrics |
| modelmesh-webhook | control-plane=modelmesh-controller | Allow 9443/TCP from apiserver | Webhook admission |

## Data Flows

### Flow 1: Model Inference Request (gRPC)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | Istio Gateway/Route | 443/TCP | HTTPS | TLS 1.3 | Bearer Token/mTLS |
| 2 | Gateway | modelmesh-serving Service | 8033/TCP | gRPC | None | None |
| 3 | Service | ModelMesh container | 8033/TCP | gRPC | None | None |
| 4 | ModelMesh | Runtime Adapter | 8085/TCP | gRPC | None | None |
| 5 | Runtime Adapter | Model Server (e.g., MLServer) | 8001/TCP | gRPC | None | None |
| 6 | Model Server | Return inference result | - | gRPC | None | None |

### Flow 2: Model Inference Request (REST)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | Istio Gateway/Route | 443/TCP | HTTPS | TLS 1.3 | Bearer Token |
| 2 | Gateway | modelmesh-serving Service (REST) | 8008/TCP | HTTP | None | None |
| 3 | REST Proxy | ModelMesh container | 8033/TCP | gRPC | None | None |
| 4 | ModelMesh | Runtime via adapter (as above) | 8085/TCP | gRPC | None | None |

### Flow 3: Model Loading

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Controller | etcd | 2379/TCP | HTTP | None | Basic Auth |
| 2 | Controller | Runtime Deployment | - | Kubernetes API | TLS 1.2+ | ServiceAccount Token |
| 3 | Storage Helper (Init) | S3/MinIO | 443/TCP or 9000/TCP | HTTPS or HTTP | TLS 1.2+ or None | Access Keys |
| 4 | Storage Helper | Shared Volume | - | Filesystem | None | None |
| 5 | Runtime Adapter | Model Server | 8001/TCP | gRPC | None | None |

### Flow 4: Controller Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Kubernetes API | Controller | - | Watch | TLS 1.2+ | ServiceAccount Token |
| 2 | Controller | etcd | 2379/TCP | HTTP | None | Basic Auth |
| 3 | Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Controller | Runtime Deployment | - | Kubernetes API | TLS 1.2+ | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| etcd | gRPC Client | 2379/TCP | HTTP | None | Model registry, runtime coordination, leader election |
| Kubernetes API | REST Client | 6443/TCP | HTTPS | TLS 1.2+ | CR reconciliation, deployment management |
| ModelMesh Core | gRPC Client | 8033/TCP | gRPC | None | Model event stream, status updates |
| Prometheus | Scrape Target | 8443/TCP, 2112/TCP | HTTPS, HTTP | TLS 1.2+, None | Metrics collection |
| KServe | CRD Import | - | - | - | Reuse ServingRuntime and InferenceService definitions |
| S3/MinIO | S3 API | 443/TCP, 9000/TCP | HTTPS, HTTP | TLS 1.2+, None | Model artifact storage |

## Runtime Configurations

### Built-in ServingRuntimes

| Runtime | Model Formats | gRPC Port | HTTP Port | Adapter Type |
|---------|---------------|-----------|-----------|--------------|
| mlserver-1.x | sklearn, xgboost, lightgbm | 8001/TCP | 8002/TCP | builtin |
| triton-2.x | tensorflow, pytorch, onnx, tensorrt | 8001/TCP | 8002/TCP | builtin |
| ovms-1.x | openvino_ir, onnx | 9000/TCP | - | builtin |
| torchserve-0.x | pytorch-mar | 7070/TCP | 7071/TCP | builtin |

### Controller Configuration

| ConfigMap Key | Default | Purpose |
|---------------|---------|---------|
| podsPerRuntime | 2 | Number of runtime pods per ServingRuntime |
| headlessService | true | Use headless service for runtime pods |
| restProxy.enabled | true | Enable REST-to-gRPC proxy |
| restProxy.port | 8008 | REST proxy listen port |
| metrics.enabled | true | Enable Prometheus metrics |

## Deployment Modes

| Mode | Scope | Description |
|------|-------|-------------|
| Cluster Scope | All Namespaces | Controller watches all namespaces (requires cluster permissions) |
| Namespace Scope | Single Namespace | Controller watches only its own namespace (requires NAMESPACE_SCOPE=true) |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| a0b0401 | 2024 | Latest commit in rhoai-2.14 branch |

Note: Detailed commit history available via `git log --oneline --since="3 months ago"` in repository.

## Component Versions

Based on `version` file and dependencies:
- Upstream KServe/ModelMesh version: v0.11.0
- RHOAI version: v1.27.0 (corresponds to RHOAI 2.14)
- KServe integration: v0.12.0
- etcd client: v3.5.9
- Kubernetes: v0.28.4

## Additional Notes

### High Availability
- Controller supports leader election (lease-based or leader-for-life)
- Multiple controller replicas can be deployed (default: 1, recommended: 3)
- Runtime pods can be scaled via `podsPerRuntime` configuration

### Model Placement Strategy
- ModelMesh uses intelligent placement across runtime pods
- Models automatically loaded/unloaded based on usage
- Supports GPU requirements (required/preferred)

### Storage Backends
- S3-compatible storage (AWS S3, MinIO, etc.)
- PersistentVolumeClaims (requires ReadWriteMany)
- Custom storage via parameters

### Observability
- Prometheus metrics exposed for controller and runtimes
- ServiceMonitor CRD support for automatic scraping
- Health/readiness probes for controller
- Model-level status tracking in Predictor CRs
