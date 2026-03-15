# Component: ModelMesh Serving

## Metadata
- **Repository**: https://github.com/red-hat-data-services/modelmesh-serving.git
- **Version**: v1.27.0-rhods-169-g911dcec
- **Branch**: rhoai-2.6
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes controller that manages ModelMesh, a general-purpose model serving management and routing layer for deploying machine learning models at scale.

**Detailed**: ModelMesh Serving is a Kubernetes operator that orchestrates the deployment and lifecycle management of machine learning models using the ModelMesh framework. It provides a control plane for managing model serving runtimes (Triton, MLServer, OpenVINO, TorchServe) and routes inference requests to the appropriate model instances. The controller watches custom resources (Predictors, InferenceServices, ServingRuntimes) and dynamically provisions model serving pods with intelligent model placement, caching, and multi-model serving capabilities. ModelMesh enables efficient resource utilization by packing multiple models into shared runtime pods and provides a unified inference API (KServe V2 protocol) across different model frameworks.

The architecture consists of the modelmesh-controller operator, which manages deployments containing ModelMesh containers (model routing/orchestration), runtime adapter containers (interface between ModelMesh and model servers), storage helper/puller containers (model artifact retrieval), runtime containers (TensorFlow, PyTorch, etc.), and an optional REST proxy for HTTP inference requests.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| modelmesh-controller | Deployment | Kubernetes operator managing ModelMesh serving infrastructure lifecycle |
| ModelMesh | Container | Model routing, placement, and caching orchestration layer |
| Runtime Adapter | Container | Bridges ModelMesh gRPC interface to specific model server implementations |
| Storage Helper/Puller | Container | Retrieves model artifacts from object storage (S3, PVC, etc.) |
| Model Runtime | Container | Executes inference (Triton, MLServer, OpenVINO, TorchServe) |
| REST Proxy | Container | Translates KServe V2 REST requests to gRPC for ModelMesh |
| Validating Webhook | Webhook | Validates ServingRuntime and ClusterServingRuntime CRDs on CREATE/UPDATE |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1alpha1 | Predictor | Namespaced | Defines a deployed model with storage location, model type, and runtime |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Configures model server runtime (containers, supported formats, endpoints) |
| serving.kserve.io | v1alpha1 | ClusterServingRuntime | Cluster | Cluster-wide template for ServingRuntime configurations |
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | KServe-compatible API for model deployment (limited ModelMesh support) |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token | Prometheus metrics scraping |
| /healthz | GET | 8081/TCP | HTTP | None | None | Controller liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Controller readiness probe |
| /validate-serving-modelmesh-io-v1alpha1-servingruntime | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Webhook validation for ServingRuntimes |
| /v2/models/{model}/infer | POST | 8008/TCP | HTTP | None | None | KServe V2 REST inference (via REST proxy) |
| /v2/models/{model}/ready | GET | 8008/TCP | HTTP | None | None | Model readiness check (REST) |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ModelMesh | 8085/TCP | gRPC | mTLS (optional) | mTLS client certs | Model lifecycle management (register, unregister, ensureLoaded) |
| KServe V2 Inference | 8085/TCP | gRPC | mTLS (optional) | mTLS client certs | Model inference requests (gRPC predict protocol) |
| Runtime Management | 8001/TCP | gRPC | None | None | Internal runtime-adapter to model-server communication |
| Storage Helper | 8086/TCP | gRPC | None | None | Model pulling coordination |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| etcd | 3.x | Yes | Distributed key-value store for model registry and state |
| cert-manager | v1.x | Optional | Automated TLS certificate provisioning for webhooks |
| Prometheus Operator | v0.x | Optional | ServiceMonitor CRD for metrics collection |
| S3-compatible storage | N/A | Optional | Model artifact storage (AWS S3, MinIO, Ceph) |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH/RHOAI Dashboard | Web UI | Model deployment and management interface |
| Service Mesh (Istio) | NetworkPolicy | Optional mTLS and authorization for inference endpoints |
| Prometheus | ServiceMonitor | Metrics collection for model serving performance |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| modelmesh-webhook-server-service | ClusterIP | 9443/TCP | 9443 | HTTPS | TLS 1.2+ | K8s API Server | Internal |
| controller-manager-metrics-service | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | Bearer Token | Internal |
| modelmesh-serving | ClusterIP/Headless | 8033/TCP | 8033 | gRPC | mTLS (optional) | mTLS client certs | Internal |
| {predictor-name} | ClusterIP | 8008/TCP, 8085/TCP | 8008, 8085 | HTTP, gRPC | None/mTLS | None/mTLS | Internal/External (via Istio) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| N/A (Service Mesh) | Istio VirtualService | User-defined | 8008/TCP | HTTP | TLS 1.3 | SIMPLE | External (optional) |
| Webhook Admission | K8s API Server | modelmesh-webhook-server-service | 9443/TCP | HTTPS | TLS 1.2+ | Server-side TLS | Internal |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| etcd cluster | 2379/TCP | HTTPS | TLS 1.2+ | Client cert | Model registry state persistence |
| S3 endpoint | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Access Key | Model artifact retrieval from object storage |
| K8s API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token | CRD watch, resource management |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull secrets | Runtime image pulls |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| modelmesh-controller-role | "" | configmaps, secrets, services, namespaces | get, list, watch, create, update, patch, delete |
| modelmesh-controller-role | "" | endpoints, persistentvolumeclaims | get, list, watch |
| modelmesh-controller-role | apps | deployments, deployments/finalizers | get, list, watch, create, update, patch, delete |
| modelmesh-controller-role | serving.kserve.io | predictors, servingruntimes, clusterservingruntimes, inferenceservices | get, list, watch, create, update, patch, delete |
| modelmesh-controller-role | serving.kserve.io | predictors/status, servingruntimes/status, clusterservingruntimes/status, inferenceservices/status | get, patch, update |
| modelmesh-controller-role | serving.kserve.io | predictors/finalizers, servingruntimes/finalizers, clusterservingruntimes/finalizers, inferenceservices/finalizers | get, patch, update |
| modelmesh-controller-role | autoscaling | horizontalpodautoscalers | get, list, watch, create, update, delete |
| modelmesh-controller-role | monitoring.coreos.com | servicemonitors | get, list, watch, create, update, patch, delete |
| inferenceservice-editor-role | serving.kserve.io | inferenceservices | get, list, watch, create, update, patch, delete |
| predictor-editor-role | serving.kserve.io | predictors | get, list, watch, create, update, patch, delete |
| servingruntime-editor-role | serving.kserve.io | servingruntimes | get, list, watch, create, update, patch, delete |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| modelmesh-controller-rolebinding | modelmesh-serving | modelmesh-controller-role | modelmesh-controller |
| leader-election-rolebinding | modelmesh-serving | leader-election-role | modelmesh-controller |
| modelmesh-controller-proxy-rolebinding | modelmesh-serving | modelmesh-controller-proxy-role | modelmesh-controller |
| restricted-scc-rolebinding | User namespace | system:openshift:scc:restricted | modelmesh-serving-sa |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| model-serving-etcd | Opaque | etcd connection string and credentials | Manual/Operator | No |
| modelmesh-webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificate | cert-manager | Yes (cert-manager) |
| {tls-secret-name} | kubernetes.io/tls | ModelMesh mTLS certificates (optional) | Manual/cert-manager | No/Yes |
| storage-config | Opaque | S3 access keys, credentials for model storage | Manual | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics (8443) | GET | Bearer Token (ServiceAccount) | kube-rbac-proxy | K8s RBAC |
| Webhook (9443) | POST | K8s API Server mTLS | API Server | K8s admission control |
| ModelMesh gRPC (8085) | All | mTLS client certs (optional) | ModelMesh container | TLS client auth |
| Inference REST (8008) | POST, GET | None (default) | Service Mesh (optional) | Istio AuthorizationPolicy |
| Inference gRPC (8085) | All | None (default) | Service Mesh (optional) | Istio AuthorizationPolicy |

### Network Policies

| Policy Name | Selector | Ingress Rules | Egress Rules |
|-------------|----------|---------------|--------------|
| modelmesh-controller | control-plane=modelmesh-controller | Allow 8443/TCP (metrics) | All allowed |
| modelmesh-runtimes | modelmesh-service=modelmesh-serving | Allow from controller, Allow from namespace | etcd, S3, API server |

## Data Flows

### Flow 1: Model Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Dashboard | K8s API Server | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | K8s API Server | modelmesh-controller | N/A | Watch | N/A | ServiceAccount token |
| 3 | modelmesh-controller | K8s API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 4 | modelmesh-controller | etcd | 2379/TCP | HTTPS | TLS 1.2+ | Client cert |
| 5 | Storage Helper | S3 Endpoint | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Access Key |

### Flow 2: Model Inference (REST)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | Istio Gateway (optional) | 443/TCP | HTTPS | TLS 1.3 | Bearer Token/None |
| 2 | Istio Gateway | REST Proxy | 8008/TCP | HTTP | None | None |
| 3 | REST Proxy | ModelMesh | 8085/TCP | gRPC | mTLS (optional) | mTLS client cert |
| 4 | ModelMesh | Runtime Adapter | 8085/TCP | gRPC | None | None |
| 5 | Runtime Adapter | Model Runtime | 8001/TCP | gRPC | None | None |

### Flow 3: Model Loading

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | ModelMesh | Storage Helper | 8086/TCP | gRPC | None | None |
| 2 | Storage Helper | S3 Endpoint | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Access Key |
| 3 | Storage Helper | ModelMesh | 8086/TCP | gRPC | None | None |
| 4 | ModelMesh | Runtime Adapter | 8085/TCP | gRPC | None | None |
| 5 | Runtime Adapter | Model Runtime | 8001/TCP | gRPC | None | None |

### Flow 4: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | kube-rbac-proxy | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | kube-rbac-proxy | modelmesh-controller | 8081/TCP | HTTP | None | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| etcd | gRPC Client | 2379/TCP | gRPC/HTTPS | TLS 1.2+ | Model registry, distributed state management |
| Prometheus | HTTP Scrape | 8443/TCP | HTTPS | TLS 1.2+ | Metrics collection for observability |
| K8s API Server | REST Client | 6443/TCP | HTTPS | TLS 1.2+ | CRD watching, resource reconciliation |
| cert-manager | Certificate Request | N/A | K8s API | N/A | Webhook certificate provisioning |
| S3 Object Storage | S3 API | 443/TCP | HTTPS | TLS 1.2+ | Model artifact storage and retrieval |
| Service Mesh (Istio) | sidecar injection | N/A | N/A | N/A | mTLS enforcement, traffic management |
| ODH Dashboard | K8s API | 6443/TCP | HTTPS | TLS 1.2+ | User interface for model deployment |

## Deployment Configuration

### Controller Deployment

| Setting | Value | Purpose |
|---------|-------|---------|
| Replicas | 1 (can scale to 3 for HA) | Leader election enabled for HA |
| Resource Requests | cpu: 50m, memory: 96Mi | Minimum resource guarantees |
| Resource Limits | cpu: 1, memory: 512Mi | Maximum resource constraints |
| Liveness Probe | /healthz on 8081, 15s initial, 10s period | Restart unhealthy pods |
| Readiness Probe | /readyz on 8081, 10s initial, 5s period | Traffic routing to ready pods |

### Runtime Deployment (per ServingRuntime)

| Component | Default Replicas | CPU Request | Memory Request | Purpose |
|-----------|------------------|-------------|----------------|---------|
| ModelMesh | 2 (podsPerRuntime) | 300m | 448Mi | Model routing and orchestration |
| Runtime Adapter | 1 per pod | Included in runtime | Included | gRPC adapter layer |
| Storage Helper | 1 per pod | 50m | 96Mi | Model artifact pulling |
| REST Proxy | 1 per pod | 50m | 96Mi | REST to gRPC translation |
| Model Runtime | 1 per pod | 500m (varies) | 1Gi (varies) | Inference execution |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 911dcec | 2024 | - RHOAI 2.6 release build<br>- Based on upstream KServe v0.11.1<br>- Red Hat downstream patches |

**Note**: No recent git history available in this checkout (3 months back yielded no results). This is a stable RHOAI 2.6 release branch.

## Component Versions

| Component | Version | Repository |
|-----------|---------|------------|
| ModelMesh | v0.11.1 | github.com/kserve/modelmesh |
| Runtime Adapter | v0.11.1 | github.com/kserve/modelmesh-runtime-adapter |
| REST Proxy | v0.11.1 | github.com/kserve/rest-proxy |
| Triton Runtime | 2.x | nvcr.io/nvidia/tritonserver |
| MLServer Runtime | 1.x | docker.io/seldonio/mlserver |
| OpenVINO Runtime | 1.x | openvino/model_server |
| TorchServe Runtime | 0.x | pytorch/torchserve |

## Supported Model Formats

| Runtime | Model Formats | Auto-Select |
|---------|--------------|-------------|
| Triton | TensorFlow 1.x/2.x, PyTorch, ONNX, TensorRT, Keras | Yes |
| MLServer | SKLearn, XGBoost, LightGBM, MLflow | Yes |
| OpenVINO | OpenVINO IR, ONNX, TensorFlow | Yes |
| TorchServe | PyTorch, TorchScript | Yes |

## Notes

- **Deployment Modes**: Supports both cluster-scoped (watching all namespaces) and namespace-scoped deployments
- **Model Caching**: ModelMesh automatically caches frequently-used models in memory across pods
- **Multi-Model Serving**: Multiple models can be served from a single runtime pod for resource efficiency
- **Protocol Support**: KServe V2 gRPC (native) and REST (via proxy) inference protocols
- **Storage Backends**: S3, PVC, HTTP(S), inline model data
- **High Availability**: Controller supports leader election; runtime pods use StatefulSet-like behavior for stable network identity
- **TLS Configuration**: Optional mTLS for ModelMesh internal communication; webhook TLS required
- **Namespace Enablement**: Namespaces must have label `modelmesh-enabled=true` for controller to manage resources
- **Runtime Selection**: Automatic runtime selection based on model format, or explicit via `spec.runtime.name`
- **Horizontal Pod Autoscaling**: Optional HPA support for scaling runtime pods based on metrics
- **Network Isolation**: NetworkPolicies restrict controller and runtime pod communication
- **Security Context Constraints**: Runs with OpenShift restricted SCC (non-root, no capabilities)
