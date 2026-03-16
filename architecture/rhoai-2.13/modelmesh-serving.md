# Component: ModelMesh Serving

## Metadata
- **Repository**: https://github.com/red-hat-data-services/modelmesh-serving
- **Version**: v1.27.0-rhods-292 (based on upstream kserve/modelmesh-serving v0.11.0)
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator (Controller)
- **Build System**: Konflux (Dockerfile.konflux)

## Purpose
**Short**: Controller for managing ModelMesh, a general-purpose model serving management and routing layer for multi-model serving.

**Detailed**: ModelMesh Serving is a Kubernetes operator that manages the lifecycle of ModelMesh deployments and associated resources. It provides a lightweight, scalable solution for serving machine learning models by enabling multiple models to be loaded in the same serving runtime pods, optimizing resource utilization. The controller watches custom resources (Predictors, ServingRuntimes, InferenceServices) and automatically provisions the necessary infrastructure including model serving pods, services, and routes. It coordinates with etcd for model metadata storage and supports multiple runtime backends including Triton, MLServer, OpenVINO Model Server, and TorchServe. The system includes a runtime adapter for model loading/unloading, a REST proxy for KServe V2 protocol translation, and integrated storage helpers for retrieving models from S3-compatible storage.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| modelmesh-controller | Kubernetes Operator | Main controller managing Predictor, ServingRuntime, ClusterServingRuntime, and InferenceService CRDs |
| Predictor Controller | Reconciler | Manages Predictor lifecycle, communicates with ModelMesh gRPC API for model loading/unloading |
| ServingRuntime Controller | Reconciler | Provisions and manages model serving runtime deployments based on ServingRuntime/ClusterServingRuntime specs |
| Service Controller | Reconciler | Creates and manages Kubernetes Services for inference endpoints |
| Autoscaler Controller | Reconciler | Manages HorizontalPodAutoscaler resources for runtime scaling |
| Webhook Server | ValidatingWebhookConfiguration | Validates ServingRuntime and ClusterServingRuntime resource specifications |
| ModelMesh | Java Runtime | Model routing and placement orchestration layer (runs in serving pods) |
| Runtime Adapter | Go Service | Intermediary between ModelMesh and model server containers, handles model pull/load/unload |
| REST Proxy | Go Service | Translates KServe V2 REST API to gRPC for inference requests |
| Storage Helper (Puller) | Go Service | Retrieves models from S3-compatible storage before loading |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1alpha1 | Predictor | Namespaced | Defines a single model to be served, including model type, storage location, and runtime selection |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Defines a model serving runtime template (container specs, supported model formats, resource requirements) |
| serving.kserve.io | v1alpha1 | ClusterServingRuntime | Cluster | Cluster-wide serving runtime template available to all namespaces |
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | KServe InferenceService compatibility (watched but primarily for integration) |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Controller liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Controller readiness probe endpoint |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token | Controller metrics for Prometheus (via kube-rbac-proxy) |
| /metrics | GET | 2112/TCP | HTTP | None | None | ModelMesh runtime metrics for Prometheus |
| /validate-serving-modelmesh-io-v1alpha1-servingruntime | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Webhook validation for ServingRuntime/ClusterServingRuntime |
| /v2/models/{model}/infer | POST | 8008/TCP | HTTP | None | None | KServe V2 REST inference endpoint (translated to gRPC) |
| /v2/models/{model}/ready | GET | 8008/TCP | HTTP | None | None | Model readiness check via REST |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ModelMesh Management | 8033/TCP | gRPC | None | Internal | Model registration, load/unload, status queries (internal to pods) |
| ModelMesh Inference | 8033/TCP | gRPC/HTTP2 | None | Internal/External | KServe V2 gRPC inference protocol for model predictions |
| Runtime Adapter | 8085/TCP | gRPC | None | Internal | Runtime-specific model management interface |
| Storage Helper (Puller) | 8086/TCP | gRPC | None | Internal | Model download and filesystem preparation |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| etcd | v3.5.4+ | Yes | Model metadata storage, coordination, and state management |
| S3-compatible Storage | - | Yes | Model artifact storage (MinIO, AWS S3, etc.) |
| cert-manager | v1.0+ | Optional | TLS certificate provisioning for webhook server (can use custom certs) |
| Prometheus Operator | v0.50+ | Optional | ServiceMonitor-based metrics collection |
| kube-rbac-proxy | - | Yes | Secures metrics endpoint with RBAC authentication |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| kserve/modelmesh | Container Image | Core model mesh runtime (Java-based routing layer) |
| kserve/modelmesh-runtime-adapter | Container Image | Multi-purpose adapter for runtime integration and model pulling |
| kserve/rest-proxy | Container Image | REST-to-gRPC protocol translation |
| Model Server Runtimes | Container Images | Triton, MLServer, OVMS, TorchServe - actual model serving engines |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | https | HTTPS | TLS 1.2+ | Bearer Token (RBAC) | Internal |
| modelmesh-webhook-server-service | ClusterIP | 9443/TCP | webhook | HTTPS | TLS 1.2+ | K8s API Server | Internal |
| etcd | ClusterIP | 2379/TCP | 2379 | HTTP | None | None | Internal |
| {predictor-name} | ClusterIP | 8033/TCP | 8033 | gRPC | None | None | Internal/External |
| {predictor-name} | ClusterIP | 8008/TCP | 8008 | HTTP | None | None | External (REST proxy) |
| minio (quickstart) | ClusterIP | 9000/TCP | 9000 | HTTP | None | Access Key | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| N/A | N/A | N/A | N/A | N/A | N/A | N/A | Services exposed via ClusterIP, external access via Routes/Ingress configured by consuming applications |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| S3-compatible Storage | 443/TCP or 9000/TCP | HTTPS or HTTP | TLS 1.2+ (HTTPS) | AWS IAM or Access Keys | Model artifact retrieval from object storage |
| etcd | 2379/TCP | HTTP | None | None | Model metadata and state coordination |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret | Runtime container image pulls |
| Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | CRD watch, resource management |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| modelmesh-controller-role | "" | configmaps, secrets, services, namespaces, endpoints, persistentvolumeclaims | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | apps | deployments | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | serving.kserve.io | inferenceservices, predictors, servingruntimes, clusterservingruntimes | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | serving.kserve.io | inferenceservices/status, predictors/status, servingruntimes/status, clusterservingruntimes/status | get, patch, update |
| modelmesh-controller-role | serving.kserve.io | inferenceservices/finalizers, predictors/finalizers, servingruntimes/finalizers, clusterservingruntimes/finalizers | get, patch, update |
| modelmesh-controller-role | autoscaling | horizontalpodautoscalers | create, delete, get, list, update, watch |
| modelmesh-controller-role | monitoring.coreos.com | servicemonitors | create, delete, get, list, patch, update, watch |
| leader-election-role | "" | configmaps | get, list, watch, create, update, patch |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch |
| leader-election-role | "" | events | create, patch |
| auth-proxy-client-clusterrole | authentication.k8s.io | tokenreviews | create |
| auth-proxy-client-clusterrole | authorization.k8s.io | subjectaccessreviews | create |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| modelmesh-controller-rolebinding | modelmesh-serving | modelmesh-controller-role (ClusterRole) | modelmesh-controller |
| leader-election-rolebinding | modelmesh-serving | leader-election-role | modelmesh-controller |
| auth-proxy-role-binding | modelmesh-serving | auth-proxy-role | modelmesh-controller |
| restricted-scc-role-binding | modelmesh-serving | restricted-scc-role | modelmesh-serving-sa |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| modelmesh-webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificate | cert-manager or manual | Yes (cert-manager) |
| model-serving-etcd | Opaque | etcd connection configuration (endpoints, root_prefix) | Admin/Install Script | No |
| storage-config | Opaque | S3-compatible storage credentials (access_key_id, secret_access_key, endpoint_url) | Admin/User | No |
| {runtime}-pull-secret | kubernetes.io/dockerconfigjson | Container registry pull credentials for runtime images | Admin | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics (8443) | GET | Bearer Token (ServiceAccount) | kube-rbac-proxy | TokenReview + SubjectAccessReview |
| /validate-* (9443) | POST | K8s API Server Client Cert | Kubernetes API Server | Webhook CA Bundle verification |
| gRPC Inference (8033) | POST | None (application-level) | Application | Configured by consuming application (Istio, etc.) |
| REST Inference (8008) | POST | None (application-level) | Application | Configured by consuming application (Istio, etc.) |

### Network Policies

| Policy Name | Pod Selector | Ingress From | Ingress Ports | Purpose |
|-------------|--------------|--------------|---------------|---------|
| modelmesh-controller | control-plane=modelmesh-controller | Any | 8443/TCP | Allow metrics scraping from controller |
| modelmesh-runtimes | modelmesh-service exists | modelmesh-controller pods | 8033/TCP, 8080/TCP | Internal ModelMesh communication |
| modelmesh-runtimes | modelmesh-service exists | Any | 8033/TCP, 8008/TCP | Inference requests from clients |
| modelmesh-runtimes | modelmesh-service exists | Any | 2112/TCP | Prometheus metrics scraping |
| modelmesh-webhook | control-plane=modelmesh-controller | Any | 9443/TCP | Webhook validation from API server |

## Data Flows

### Flow 1: Model Registration and Loading

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Predictor Controller | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Predictor Controller | etcd | 2379/TCP | HTTP | None | None |
| 4 | Predictor Controller | ModelMesh gRPC (runtime pod) | 8033/TCP | gRPC | None | None |
| 5 | Runtime Adapter | Storage Helper (Puller) | 8086/TCP | gRPC | None | None |
| 6 | Storage Helper | S3 Storage | 443/TCP or 9000/TCP | HTTPS or HTTP | TLS 1.2+ or None | Access Key/IAM |
| 7 | Runtime Adapter | Model Server Runtime | varies | gRPC/HTTP | None | None |
| 8 | Predictor Controller | Predictor Status | - | In-memory | - | - |

### Flow 2: Inference Request (gRPC)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client Application | Service (predictor) | 8033/TCP | gRPC | None | Application-level |
| 2 | Service | ModelMesh Pod | 8033/TCP | gRPC/HTTP2 | None | None |
| 3 | ModelMesh | Runtime Adapter | 8085/TCP | gRPC | None | None |
| 4 | Runtime Adapter | Model Server Runtime | varies | gRPC | None | None |
| 5 | ModelMesh | Client Application | 8033/TCP | gRPC/HTTP2 | None | None |

### Flow 3: Inference Request (REST)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client Application | Service (predictor) | 8008/TCP | HTTP | None | Application-level |
| 2 | Service | REST Proxy Container | 8008/TCP | HTTP | None | None |
| 3 | REST Proxy | ModelMesh Container | 8033/TCP | gRPC | None | None |
| 4 | ModelMesh | Runtime Adapter | 8085/TCP | gRPC | None | None |
| 5 | Runtime Adapter | Model Server Runtime | varies | gRPC | None | None |
| 6 | REST Proxy | Client Application | 8008/TCP | HTTP | None | None |

### Flow 4: ServingRuntime Provisioning

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Admin | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Kubernetes API | Webhook Server | 9443/TCP | HTTPS | TLS 1.2+ | CA Bundle |
| 3 | ServingRuntime Controller | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | ServingRuntime Controller | etcd | 2379/TCP | HTTP | None | None |
| 5 | Kubernetes | Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret |

### Flow 5: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | controller-manager-metrics-service | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | kube-rbac-proxy | Kubernetes API (TokenReview) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | kube-rbac-proxy | Controller Metrics Endpoint | 8081/TCP | HTTP | None | None |
| 4 | Prometheus | ModelMesh Runtime Pods | 2112/TCP | HTTP | None | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 443/TCP | HTTPS | TLS 1.2+ | CRD management, resource orchestration |
| etcd | Client API | 2379/TCP | HTTP | None | Model metadata storage and coordination |
| S3/MinIO Storage | REST API | 443/TCP or 9000/TCP | HTTPS or HTTP | TLS 1.2+ or None | Model artifact retrieval |
| ModelMesh Runtime | gRPC API | 8033/TCP | gRPC | None | Model management and inference routing |
| Runtime Adapter | gRPC API | 8085/TCP | gRPC | None | Runtime-specific model operations |
| Model Servers (Triton/MLServer/OVMS/TorchServe) | gRPC/HTTP | varies | gRPC/HTTP | None | Actual model inference execution |
| Prometheus | Metrics Pull | 8443/TCP, 2112/TCP | HTTPS, HTTP | TLS 1.2+ (8443) | Operational metrics and monitoring |
| cert-manager | Certificate CRD | - | K8s API | - | Automated TLS certificate provisioning |

## Recent Changes

Based on git log from rhoai-2.13 branch (last 20 commits):

| Commit | Date | Changes |
|--------|------|---------|
| 0da3433 | Recent | - Update Konflux references |
| 7308d57 | Recent | - Update Konflux references |
| 07d793a | Recent | - Update Konflux references |
| 4ba773f | Recent | - Update Konflux references to d00d159 |
| ccdffac | Recent | - Update Konflux references |
| 8d5b6ef | Recent | - Update Konflux references |
| 853acc7 | Recent | - Update Konflux references |
| 5f1bbed | Recent | - Update Konflux references |
| 69c5c3d | Recent | - Update Konflux references to 493a872 |
| fba6a7a | Recent | - Update Konflux references |

**Note**: Recent commits primarily focus on Konflux build system integration and dependency updates. The upstream base is kserve/modelmesh-serving v0.11.0.

## Deployment Configuration

**Manifests Location**: `config/model-mesh` (as specified in distribution configuration)

**Kustomize Structure**:
- Base: `config/default/` - Core controller deployment
- CRDs: `config/crd/bases/` - Custom resource definitions
- RBAC: `config/rbac/` - Role-based access control (cluster-scope and namespace-scope)
- Manager: `config/manager/` - Controller deployment spec
- Webhook: `config/webhook/` - ValidatingWebhookConfiguration
- Dependencies: `config/dependencies/` - etcd and storage quickstart resources
- Runtimes: `config/runtimes/` - Built-in ServingRuntime templates (MLServer, Triton, OVMS, TorchServe)
- Overlays: `config/overlays/odh/` - ODH/RHOAI-specific customizations

**Resource Requirements** (Controller):
- Requests: 50m CPU, 96Mi memory
- Limits: 1 CPU, 512Mi memory

**High Availability**:
- Controller supports leader election (can scale to 3 replicas)
- Runtime pods controlled by `podsPerRuntime` configuration (default: 2)
- etcd should be deployed as a cluster in production

## Built-in Runtime Support

| Runtime | Model Formats | Protocol | Image |
|---------|--------------|----------|-------|
| MLServer 1.x | sklearn, xgboost, lightgbm | grpc-v2 | kserve/mlserver |
| Triton 2.x | tensorflow, pytorch, onnx, tensorrt | grpc-v2 | nvcr.io/nvidia/tritonserver |
| OpenVINO 1.x | openvino_ir, onnx | grpc-v2 | openvino/model_server |
| TorchServe 0.x | pytorch | grpc-v2 | pytorch/torchserve |

Custom ServingRuntimes can be defined to add support for additional model servers.
