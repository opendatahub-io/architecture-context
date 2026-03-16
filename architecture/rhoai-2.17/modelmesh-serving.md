# Component: ModelMesh Serving

## Metadata
- **Repository**: https://github.com/red-hat-data-services/modelmesh-serving.git
- **Version**: v1.27.0-rhods-348-g1691d80
- **Branch**: rhoai-2.17
- **Distribution**: RHOAI
- **Languages**: Go 1.21
- **Deployment Type**: Kubernetes Operator
- **Build System**: Konflux (Dockerfile.konflux)

## Purpose
**Short**: ModelMesh Serving is a Kubernetes operator that manages the lifecycle of ModelMesh-based model serving runtimes and inference services.

**Detailed**: ModelMesh Serving provides a controller for managing ModelMesh, a general-purpose model serving management and routing layer. It enables multi-model serving with intelligent model placement, loading/unloading, and routing across a cluster of model servers. The controller manages Custom Resources (InferenceServices, Predictors, ServingRuntimes) to deploy and orchestrate machine learning models using various runtime backends (Triton, MLServer, OVMS, TorchServe). It integrates with etcd for distributed state management, S3-compatible storage for model artifacts, and provides both gRPC and REST inference endpoints.

The operator creates and manages deployments of ModelMesh runtime pods, each containing multiple containers: the ModelMesh router, a model server runtime (e.g., Triton), a runtime adapter for protocol translation, and an optional REST proxy for HTTP/REST inference requests. It handles autoscaling through HPA integration, provides Prometheus metrics, and enforces network policies for secure multi-tenant model serving.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| modelmesh-controller | Go Operator | Reconciles ServingRuntime, Predictor, and InferenceService CRDs; manages ModelMesh deployments |
| Webhook Server | Validating Webhook | Validates ServingRuntime and ClusterServingRuntime resources on CREATE/UPDATE |
| ModelMesh Runtime Pods | Deployment | Multi-container pods running ModelMesh router, model server, adapter, and REST proxy |
| ModelMesh Router | Java Container | Routes inference requests to loaded models; handles model placement and lifecycle |
| Runtime Adapter | Go Container | Adapts between ModelMesh gRPC protocol and model server native protocols |
| REST Proxy | Go Container | Translates KServe V2 REST API to gRPC for inference requests |
| Storage Helper (Puller) | Go Init Container | Downloads model artifacts from S3-compatible storage before model loading |
| etcd | StatefulSet | Distributed key-value store for ModelMesh state coordination across replicas |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Defines a model deployment with predictor/transformer/explainer components |
| serving.kserve.io | v1alpha1 | Predictor | Namespaced | Defines a single model instance with storage location, model type, and runtime |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Defines a model server runtime configuration (namespace-scoped) |
| serving.kserve.io | v1alpha1 | ClusterServingRuntime | Cluster | Defines a model server runtime configuration (cluster-scoped) |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /readyz | GET | 8081/TCP | HTTP | None | None | Controller readiness probe |
| /healthz | GET | 8081/TCP | HTTP | None | None | Controller liveness probe |
| /metrics | GET | 8443/TCP | HTTPS | TLS | kube-rbac-proxy | Controller Prometheus metrics (via auth proxy) |
| /validate-serving-modelmesh-io-v1alpha1-servingruntime | POST | 9443/TCP | HTTPS | TLS 1.2+ | Webhook cert | Validation webhook for ServingRuntime CRDs |
| /v2/models/{model}/infer | POST | 8008/TCP | HTTP | None | None | KServe V2 REST inference endpoint (via REST proxy) |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| inference.GRPCInferenceService | 8033/TCP | gRPC | None | None | KServe V2 gRPC inference endpoint (ModelMesh) |
| ModelMesh Internal | 8080/TCP | gRPC/Thrift | None | None | Internal ModelMesh litelinks communication between replicas |
| Runtime Adapter | 8085/TCP | gRPC | None | None | ModelMesh to runtime adapter communication |
| Triton gRPC | 8001/TCP | gRPC | None | None | Triton inference server gRPC endpoint (runtime-internal) |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| etcd | v3.5.x | Yes | Distributed state coordination for ModelMesh cluster membership and model assignments |
| S3-compatible storage | N/A | Yes | Object storage for model artifacts (e.g., AWS S3, MinIO, IBM Cloud Object Storage) |
| Kubernetes | v1.25+ | Yes | Container orchestration platform |
| cert-manager | v1.x | No | Automatic TLS certificate provisioning for webhooks (or manual cert injection) |
| Prometheus Operator | v0.55+ | No | ServiceMonitor CRD for metrics collection |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KServe | CRD Schema | Uses KServe API definitions (InferenceService, ServingRuntime CRDs) |
| OpenShift Service Mesh / Istio | Network | Optional integration for mTLS, traffic management, and authorization policies |
| OpenShift Monitoring | ServiceMonitor | Prometheus scraping of controller and runtime metrics |

### ModelMesh Component Dependencies

| Component | Repository | Version | Purpose |
|-----------|-----------|---------|---------|
| ModelMesh | kserve/modelmesh | v0.11.2 | Model serving management/routing layer (Java container) |
| Runtime Adapter | kserve/modelmesh-runtime-adapter | v0.11.2 | Unified puller and protocol adapter for model servers |
| REST Proxy | kserve/rest-proxy | v0.11.2 | REST to gRPC protocol translation |

### Supported Model Server Runtimes

| Runtime | Version | Model Formats | Purpose |
|---------|---------|---------------|---------|
| Triton Inference Server | 2.x | TensorFlow, PyTorch, ONNX, TensorRT, Keras, sklearn, xgboost, lightgbm | NVIDIA's multi-framework inference server |
| MLServer (Seldon) | 1.x | sklearn, xgboost, lightgbm, MLflow | Python-based inference server |
| OpenVINO Model Server | 1.x | OpenVINO IR, ONNX | Intel OpenVINO optimized inference |
| TorchServe | 0.x | PyTorch | PyTorch native model serving |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| modelmesh-webhook-server-service | ClusterIP | 9443/TCP | webhook (9443) | HTTPS | TLS 1.2+ | Webhook cert | Internal (API server) |
| controller-manager-metrics-service | ClusterIP | 8443/TCP | https | HTTPS | TLS | kube-rbac-proxy | Internal (Prometheus) |
| modelmesh-serving (per namespace) | ClusterIP | 8033/TCP | 8033 | gRPC | None | None | Internal/External (inference) |
| modelmesh-serving (REST) | ClusterIP | 8008/TCP | 8008 | HTTP | None | None | Internal/External (inference) |
| etcd | ClusterIP | 2379/TCP | 2379 | HTTP | None | None | Internal (ModelMesh only) |
| minio (dev/test) | ClusterIP | 9000/TCP | 9000 | HTTP | None | S3 credentials | Internal (model download) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| N/A (default) | N/A | N/A | N/A | N/A | N/A | N/A | Ingress/Routes configured by users or external controllers |

**Note**: ModelMesh Serving does not deploy ingress resources by default. Users or platform administrators configure OpenShift Routes or Kubernetes Ingress to expose inference services externally.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| S3 endpoints | 443/TCP | HTTPS | TLS 1.2+ | AWS Signature v4 / S3 API keys | Model artifact downloads from object storage |
| etcd service | 2379/TCP | HTTP | None | None | ModelMesh state synchronization |
| Kubernetes API server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account token | Controller API operations (watch/reconcile resources) |

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
| modelmesh-controller-role | serving.kserve.io | inferenceservices, predictors, servingruntimes, clusterservingruntimes | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | serving.kserve.io | inferenceservices/status, predictors/status, servingruntimes/status, clusterservingruntimes/status | get, patch, update |
| modelmesh-controller-role | serving.kserve.io | inferenceservices/finalizers, predictors/finalizers, servingruntimes/finalizers, clusterservingruntimes/finalizers | get, patch, update |
| modelmesh-controller-role | autoscaling | horizontalpodautoscalers, horizontalpodautoscalers/status | create, delete, get, list, update, watch |
| modelmesh-controller-role | monitoring.coreos.com | servicemonitors | create, delete, get, list, patch, update, watch |
| leader-election-role | "" | configmaps | get, list, watch, create, update, patch |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch |
| auth-proxy-client-clusterrole | authentication.k8s.io | tokenreviews | create |
| auth-proxy-client-clusterrole | authorization.k8s.io | subjectaccessreviews | create |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| modelmesh-controller-role-binding | cluster-wide | ClusterRole: modelmesh-controller-role | modelmesh-controller (controller namespace) |
| modelmesh-controller-role-binding | per-namespace | Role: modelmesh-controller-role | modelmesh-controller (controller namespace) |
| leader-election-role-binding | controller namespace | Role: leader-election-role | modelmesh-controller |
| auth-proxy-role-binding | controller namespace | Role: auth-proxy-role | modelmesh-controller |
| restricted-scc-role-binding | per-namespace | Role: restricted-scc-role | modelmesh-serving-sa |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| storage-config | Opaque | S3-compatible storage credentials (access_key_id, secret_access_key, endpoint_url) | User/Admin | No |
| model-serving-etcd | Opaque | etcd connection string and root prefix | Admin/Operator | No |
| modelmesh-webhook-server-cert | kubernetes.io/tls | TLS certificate for validating webhook (serving on port 9443) | cert-manager or manual | Depends on provisioner |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /validate-serving-modelmesh-io-v1alpha1-servingruntime (9443/TCP) | POST | TLS client cert (API server to webhook) | Kubernetes API server | ValidatingWebhookConfiguration |
| /metrics (8443/TCP) | GET | kube-rbac-proxy (Bearer token) | kube-rbac-proxy sidecar | RBAC SubjectAccessReview |
| gRPC inference (8033/TCP) | Unary RPC | None (default) | N/A | Optional: Istio AuthorizationPolicy |
| REST inference (8008/TCP) | POST | None (default) | N/A | Optional: Istio AuthorizationPolicy |
| S3 storage egress | GET | AWS Signature v4 / S3 API keys | S3 endpoint | Bucket policies |

### Network Policies

| Policy Name | Pod Selector | Ingress Rules | Ports | Purpose |
|-------------|--------------|---------------|-------|---------|
| modelmesh-controller | control-plane=modelmesh-controller | Allow from any | 8443/TCP | Metrics scraping |
| modelmesh-webhook | control-plane=modelmesh-controller | Allow from any | 9443/TCP | Webhook endpoint for API server |
| modelmesh-runtimes | modelmesh-service exists | 1. From app.kubernetes.io/managed-by=modelmesh-controller<br>2. From any | 1. 8033/TCP, 8080/TCP<br>2. 8033/TCP, 8008/TCP, 2112/TCP | 1. Internal communication<br>2. Inference + metrics |

## Data Flows

### Flow 1: Model Deployment (User → Controller → Runtime Pods)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Admin | Kubernetes API server | 6443/TCP | HTTPS | TLS 1.2+ | kubeconfig credentials |
| 2 | Kubernetes API server | modelmesh-controller webhook | 9443/TCP | HTTPS | TLS 1.2+ | Webhook TLS cert |
| 3 | modelmesh-controller | Kubernetes API server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account token |
| 4 | modelmesh-controller | etcd | 2379/TCP | HTTP | None | None |
| 5 | ModelMesh pod (storage-helper init container) | S3 storage | 443/TCP | HTTPS | TLS 1.2+ | S3 credentials (from storage-config secret) |
| 6 | ModelMesh pod (adapter) | Model server runtime (Triton/MLServer) | 8001/TCP | gRPC | None | None |

### Flow 2: gRPC Inference Request

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client application | modelmesh-serving service | 8033/TCP | gRPC | None | None (optional: mTLS via Istio) |
| 2 | ModelMesh router | Runtime adapter | 8085/TCP | gRPC | None | None |
| 3 | Runtime adapter | Model server (Triton/MLServer) | 8001/TCP | gRPC | None | None |
| 4 | Model server | Runtime adapter | 8001/TCP | gRPC | None | None |
| 5 | Runtime adapter | ModelMesh router | 8085/TCP | gRPC | None | None |
| 6 | ModelMesh router | Client application | 8033/TCP | gRPC | None | None |

### Flow 3: REST Inference Request

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client application | modelmesh-serving service (REST proxy) | 8008/TCP | HTTP | None | None (optional: Istio) |
| 2 | REST proxy | ModelMesh router | 8033/TCP | gRPC | None | None |
| 3 | ModelMesh router | Runtime adapter | 8085/TCP | gRPC | None | None |
| 4 | Runtime adapter | Model server | 8001/TCP | gRPC | None | None |
| 5 | Model server → Runtime adapter → ModelMesh → REST proxy → Client | (reverse path) | 8001→8085→8033→8008 | gRPC→HTTP | None | None |

### Flow 4: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | controller-manager-metrics-service | 8443/TCP | HTTPS | TLS | Bearer token (via kube-rbac-proxy) |
| 2 | Prometheus | ModelMesh runtime pods | 2112/TCP | HTTP | None | None |

### Flow 5: Model State Synchronization (ModelMesh ↔ etcd)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | ModelMesh router (all replicas) | etcd service | 2379/TCP | HTTP | None | None |
| 2 | ModelMesh router (leader election, model assignments) | etcd service | 2379/TCP | HTTP | None | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Controller watches and reconciles CRDs; webhook validation |
| etcd | Client API | 2379/TCP | HTTP | None | Distributed state management for ModelMesh cluster |
| S3-compatible storage | REST API | 443/TCP | HTTPS | TLS 1.2+ | Model artifact storage and retrieval |
| Prometheus | Metrics scraping | 8443/TCP, 2112/TCP | HTTPS, HTTP | TLS (controller), None (runtimes) | Observability and monitoring |
| Triton/MLServer/OVMS/TorchServe | gRPC | 8001/TCP (varies by runtime) | gRPC | None | Model inference execution |
| Istio/Service Mesh | Envoy sidecar | N/A | N/A | mTLS | Optional: Traffic encryption, authorization, observability |
| OpenShift Monitoring | ServiceMonitor CRD | 8443/TCP, 2112/TCP | HTTPS, HTTP | TLS (controller), None | Metrics federation to cluster monitoring |

## Deployment Architecture

### Controller Deployment

| Component | Replicas | Resource Requests | Resource Limits | Affinity |
|-----------|----------|-------------------|-----------------|----------|
| modelmesh-controller | 1 (HA: 3) | cpu: 50m, memory: 96Mi | cpu: 1, memory: 512Mi | Pod anti-affinity (zone-aware) |

### Runtime Deployments (per ServingRuntime)

| Container | Resource Requests | Resource Limits | Purpose |
|-----------|-------------------|-----------------|---------|
| modelmesh | cpu: 300m, memory: 448Mi | cpu: 3, memory: 448Mi | Model routing and management |
| mm-runtime-adapter | (embedded in modelmesh container) | (embedded) | Protocol adapter |
| rest-proxy | cpu: 50m, memory: 96Mi | cpu: 1, memory: 512Mi | REST to gRPC translation |
| triton (example) | cpu: 500m, memory: 1Gi | cpu: 5, memory: 1Gi | Model inference execution |
| storage-helper (init) | cpu: 50m, memory: 96Mi | cpu: 2, memory: 512Mi | Model artifact download |

## Configuration

### ConfigMaps

| ConfigMap Name | Purpose | Key Configuration |
|----------------|---------|-------------------|
| model-serving-config-defaults | System defaults for ModelMesh deployments | podsPerRuntime: 2, restProxy.enabled: true, metrics.enabled: true, InferenceServicePort: 8033 |
| model-serving-config (optional) | User overrides for system defaults | User-provided overrides for images, resources, ports |

### Environment Variables (Controller)

| Variable | Default | Purpose |
|----------|---------|---------|
| NAMESPACE | (auto-detected) | Controller deployment namespace |
| POD_NAME | (downward API) | Controller pod name for leader election |
| ETCD_SECRET_NAME | model-serving-etcd | Name of secret containing etcd connection configuration |
| ENABLE_ISVC_WATCH | false | Enable watching InferenceService CRDs |
| ENABLE_CSR_WATCH | true | Enable watching ClusterServingRuntime CRDs |
| ENABLE_SECRET_WATCH | false | Enable watching secrets for storage config |
| NAMESPACE_SCOPE | false | Limit controller to namespace scope (vs cluster-wide) |
| DEV_MODE_LOGGING | false | Enable development mode logging |

## Observability

### Metrics

| Metric Source | Port | Path | Encryption | Metrics Exposed |
|---------------|------|------|------------|-----------------|
| Controller | 8443/TCP | /metrics | HTTPS (via kube-rbac-proxy) | controller-runtime metrics, reconciliation loops, webhook latency |
| ModelMesh runtime | 2112/TCP | /metrics | None | Model loading/unloading, inference latency, request counts, cache hit rates |

### Health Checks

| Endpoint | Port | Protocol | Check Type | Purpose |
|----------|------|----------|------------|---------|
| /healthz | 8081/TCP | HTTP | Liveness | Controller process health |
| /readyz | 8081/TCP | HTTP | Readiness | Controller ability to serve requests |

### Logging

| Component | Log Level | Format | Destination |
|-----------|-----------|--------|-------------|
| modelmesh-controller | Info (configurable via DEV_MODE_LOGGING) | Structured (JSON) | stdout/stderr |
| ModelMesh runtime | Info | Java logging | stdout/stderr |
| Runtime adapter | Info | Structured | stdout/stderr |

## Container Images

### Controller Image

| Image | Registry | Tag Pattern | Build |
|-------|----------|-------------|-------|
| odh-modelmesh-serving-controller-rhel8 | registry.redhat.io/managed-open-data-hub | rhoai-2.17 | Konflux (Dockerfile.konflux) |

### Runtime Images

| Image | Purpose | Source |
|-------|---------|--------|
| kserve/modelmesh | ModelMesh router | kserve/modelmesh |
| kserve/modelmesh-runtime-adapter | Runtime adapter + storage helper | kserve/modelmesh-runtime-adapter |
| kserve/rest-proxy | REST to gRPC proxy | kserve/rest-proxy |
| nvcr.io/nvidia/tritonserver | Triton Inference Server | NVIDIA NGC |
| seldonio/mlserver | Seldon MLServer | Seldon |
| openvino/model_server | OpenVINO Model Server | Intel |
| pytorch/torchserve | TorchServe | PyTorch |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| v1.27.0-rhods-348 | 2024 | - Based on upstream kserve/modelmesh-serving v0.11.0<br>- RHOAI 2.17 release branch<br>- Built via Konflux build system<br>- Integration with RHOAI ecosystem<br>- Support for KServe v0.12.0 APIs |

**Note**: This is a stable release branch (rhoai-2.17) with no commits in the last 3 months, indicating a frozen state for the RHOAI 2.17 release.

## Additional Notes

### Deployment Modes

1. **Cluster-scoped** (default): Controller watches all namespaces; ClusterServingRuntimes available cluster-wide
2. **Namespace-scoped**: Controller watches only specific namespace(s); set via NAMESPACE_SCOPE env var

### Multi-tenancy

- Each namespace can have its own ServingRuntimes and InferenceServices
- ClusterServingRuntimes provide shared runtime templates across namespaces
- Network policies isolate runtime pods within namespaces
- RBAC controls who can create/modify inference services

### High Availability

- Controller supports HA deployment (3+ replicas recommended)
- Leader election via Kubernetes leases
- ModelMesh runtime pods scale horizontally (podsPerRuntime config)
- etcd should be deployed as StatefulSet with 3+ replicas for production

### Storage Support

Supported S3-compatible storage providers:
- AWS S3
- IBM Cloud Object Storage
- MinIO
- Google Cloud Storage (S3 compatibility mode)
- Azure Blob Storage (S3 compatibility mode)

### Protocol Support

- **gRPC**: KServe V2 Inference Protocol (primary)
- **REST**: KServe V2 REST Predict Protocol (via rest-proxy)
- Both protocols supported simultaneously when REST proxy is enabled

### Model Formats

Varies by runtime. See [Supported Model Server Runtimes](#supported-model-server-runtimes) for details.

---

**Generated**: 2026-03-16
**Generator**: Claude Code Architecture Analysis
**Source**: Repository analysis of red-hat-data-services/modelmesh-serving (rhoai-2.17 branch)
