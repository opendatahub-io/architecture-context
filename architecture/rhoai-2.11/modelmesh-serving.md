# Component: ModelMesh Serving

## Metadata
- **Repository**: https://github.com/red-hat-data-services/modelmesh-serving
- **Version**: v1.27.0-rhods-254-g3d48699
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator (Controller)

## Purpose
**Short**: Controller for managing ModelMesh, a general-purpose model serving management and routing layer.

**Detailed**: ModelMesh Serving is a Kubernetes operator that manages the lifecycle of ModelMesh deployments, which provide intelligent model placement, loading, and routing for machine learning inference workloads. It reconciles InferenceService, Predictor, ServingRuntime, and ClusterServingRuntime custom resources to deploy and manage multi-model serving instances. The controller automatically creates and manages ModelMesh pods that run model server runtimes (Triton, MLServer, OpenVINO, TorchServe) with built-in adapters for unified model loading and inference. It integrates with etcd for distributed state management and supports storage backends like S3/MinIO for model artifacts. ModelMesh Serving enables efficient resource utilization by allowing multiple models to share the same serving runtime pods with intelligent model placement and LRU-based memory management.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| modelmesh-controller | Deployment | Main controller reconciling CRDs and managing ModelMesh deployments |
| modelmesh-webhook-server | ValidatingWebhook | Validates ServingRuntime and ClusterServingRuntime CRs on create/update |
| predictor-controller | Controller | Reconciles Predictor and InferenceService CRs to manage model deployments |
| servingruntime-controller | Controller | Reconciles ServingRuntime and ClusterServingRuntime CRs |
| service-controller | Controller | Manages ModelMesh service deployments per namespace |
| modelmesh-runtime | Deployment | ModelMesh pods with model servers and adapters (created per namespace) |
| etcd | StatefulSet | Distributed key-value store for ModelMesh state and coordination |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Defines an inference service with predictor, transformer, and explainer components |
| serving.kserve.io | v1alpha1 | Predictor | Namespaced | Simplified model serving definition with storage, model type, and runtime |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Defines a model server runtime configuration for a specific namespace |
| serving.kserve.io | v1alpha1 | ClusterServingRuntime | Cluster | Cluster-wide model server runtime configuration template |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint |
| /healthz | GET | 8081/TCP | HTTP | None | None | Controller liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Controller readiness probe |
| /validate-serving-modelmesh-io-v1alpha1-servingruntime | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Webhook validation for ServingRuntime CRs |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ModelMesh | 8085/TCP | gRPC | plaintext | None | Internal gRPC interface to ModelMesh service for model management |
| LiteLinks | 8080/TCP | gRPC | plaintext | None | Internal communication between ModelMesh pods |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| etcd | v3.5.4+ | Yes | Distributed state storage for ModelMesh coordination and model registry |
| S3/MinIO | Any | Yes | Object storage for model artifacts |
| Triton Inference Server | 2.x | No | NVIDIA model server for TensorFlow, PyTorch, ONNX, TensorRT models |
| MLServer | 1.x | No | Seldon's Python-based model server for scikit-learn, XGBoost models |
| OpenVINO Model Server | 1.x | No | Intel's model server for optimized inference on Intel hardware |
| TorchServe | 0.x | No | PyTorch native model serving |
| modelmesh | v0.11.2 | Yes | Core ModelMesh runtime container for model routing and placement |
| modelmesh-runtime-adapter | v0.11.2 | Yes | Adapter containers for model pulling and runtime integration |
| rest-proxy | v0.11.2 | No | REST to gRPC proxy for KServe V2 REST protocol support |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Service Mesh (Istio) | Network | Optional mTLS and traffic management for model serving endpoints |
| Prometheus Operator | ServiceMonitor | Metrics collection from ModelMesh and controller |
| cert-manager | Certificate | Optional webhook TLS certificate provisioning |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| modelmesh-webhook-server-service | ClusterIP | 9443/TCP | webhook | HTTPS | TLS 1.2+ | K8s API | Internal |
| controller-manager-metrics-service | ClusterIP | 8443/TCP | https | HTTPS | TLS 1.2+ | None | Internal |
| etcd | ClusterIP | 2379/TCP | 2379 | HTTP | None | None | Internal |
| minio | ClusterIP | 9000/TCP | 9000 | HTTP | None | Access Keys | Internal |
| modelmesh-serving | ClusterIP | 8033/TCP | 8033 | gRPC | plaintext | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| N/A | N/A | N/A | N/A | N/A | N/A | N/A | ModelMesh does not expose external ingress directly |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| etcd | 2379/TCP | HTTP | None | None | ModelMesh state coordination |
| S3/MinIO | 443/TCP or 9000/TCP | HTTPS/HTTP | TLS 1.2+ or None | AWS IAM or Access Keys | Model artifact retrieval |
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | CRD operations and watch |

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
| modelmesh-controller-role | serving.kserve.io | inferenceservices, inferenceservices/finalizers, inferenceservices/status | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | serving.kserve.io | predictors, predictors/finalizers, predictors/status | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | serving.kserve.io | servingruntimes, servingruntimes/finalizers, servingruntimes/status | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | serving.kserve.io | clusterservingruntimes, clusterservingruntimes/finalizers, clusterservingruntimes/status | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | autoscaling | horizontalpodautoscalers, horizontalpodautoscalers/status | create, delete, get, list, watch, update |
| modelmesh-controller-role | monitoring.coreos.com | servicemonitors | create, delete, get, list, patch, update, watch |
| leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| modelmesh-controller-rolebinding | cluster-wide | modelmesh-controller-role | modelmesh-controller |
| leader-election-rolebinding | cluster-wide | leader-election-role | modelmesh-controller |
| restricted-scc-rolebinding | cluster-wide | restricted-scc-role | modelmesh-serving |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| model-serving-etcd | Opaque | etcd connection configuration (endpoints, root prefix) | Manual/Operator | No |
| storage-config | Opaque | S3/MinIO credentials and endpoint configuration | Manual | No |
| modelmesh-webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificate | cert-manager or manual | Yes (cert-manager) |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /validate-serving-modelmesh-io-v1alpha1-servingruntime | POST | K8s API Server Token | Webhook Server | ValidatingWebhookConfiguration |
| /metrics | GET | None | N/A | Exposed internally only |
| ModelMesh gRPC | All | None | N/A | Internal service-to-service only |

## Data Flows

### Flow 1: Model Deployment via InferenceService

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Kubernetes API | Webhook Server | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Token |
| 3 | Predictor Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Predictor Controller | ModelMesh gRPC | 8085/TCP | gRPC | plaintext | None |
| 5 | ModelMesh | etcd | 2379/TCP | HTTP | None | None |
| 6 | ModelMesh Runtime Adapter | S3/MinIO | 443/TCP or 9000/TCP | HTTPS/HTTP | TLS 1.2+ or None | AWS IAM or Access Keys |

### Flow 2: ServingRuntime Validation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Kubernetes API | Webhook Server | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Token |
| 3 | Webhook Server | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 3: Model Inference Request

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | ModelMesh Service | 8033/TCP | gRPC | plaintext or mTLS | None or mTLS |
| 2 | ModelMesh | Model Server Runtime | 8001/TCP | gRPC | plaintext | None |
| 3 | ModelMesh | etcd | 2379/TCP | HTTP | None | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| etcd | gRPC/HTTP | 2379/TCP | HTTP | None | Model registry and distributed state |
| Kubernetes API | REST | 6443/TCP | HTTPS | TLS 1.2+ | CRD management and watch |
| Prometheus | HTTP Pull | 8080/TCP | HTTP | None | Metrics scraping |
| S3/MinIO | REST | 443/TCP or 9000/TCP | HTTPS/HTTP | TLS 1.2+ or None | Model artifact storage |
| Triton Server | gRPC | 8001/TCP | gRPC | plaintext | Model inference runtime |
| MLServer | gRPC | 8001/TCP | gRPC | plaintext | Model inference runtime |
| OpenVINO Server | gRPC | 8001/TCP | gRPC | plaintext | Model inference runtime |
| TorchServe | gRPC | 7070/TCP | gRPC | plaintext | Model inference runtime |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| v1.27.0-rhods-254 | 2024 | - Merge upstream release-0.12.0-rc0<br>- Align Go version in Dockerfile.develop.ci<br>- Add Create release Workflow<br>- Increase etcd resources<br>- Sync with upstream KServe changes |
| v0.11.2 | 2024 | - Update component versions (ModelMesh v0.11.2, Runtime Adapter v0.11.2, REST Proxy v0.11.2)<br>- Security updates for golang.org/x/net |
| v0.11.1 | 2024 | - Etcd resource optimization<br>- Upstream synchronization |
| v0.11.0 | 2023 | - Initial stable release with multi-model serving<br>- Support for Triton 2.x, MLServer 1.x, OpenVINO 1.x, TorchServe 0.x |

## Deployment Architecture

### Controller Deployment

The modelmesh-controller runs as a Deployment with:
- **Replicas**: 1 (can be increased to 3 for HA)
- **Resources**: 50m CPU / 96Mi memory (requests), 1 CPU / 512Mi memory (limits)
- **Health Checks**: Liveness (/healthz) and readiness (/readyz) probes on port 8081
- **Leader Election**: Uses ConfigMap-based leader election for HA
- **Pod Anti-Affinity**: Preferred scheduling across availability zones

### ModelMesh Runtime Deployment

Per namespace with enabled ModelMesh, the controller creates:
- **Deployment**: modelmesh-serving-<runtime-name>
- **Containers**:
  - ModelMesh container (Java-based routing layer)
  - Model server container (Triton/MLServer/OpenVINO/TorchServe)
  - Runtime adapter container (unified puller and adapter)
- **Volumes**: Shared emptyDir for model storage and communication
- **Services**: ClusterIP service exposing gRPC endpoints

### NetworkPolicy

| Policy Name | Pod Selector | Ingress Rules | Egress Rules |
|-------------|--------------|---------------|--------------|
| modelmesh-controller | control-plane: modelmesh-controller | Allow 8443/TCP for metrics | Allow all |
| modelmesh-runtimes | modelmesh-service: modelmesh-serving | Allow all from same namespace | Allow all |

## Configuration

### ConfigMaps

| Name | Purpose | Key Configuration |
|------|---------|-------------------|
| model-serving-config-defaults | Default configuration for ModelMesh deployments | Metrics, storage, runtime settings |
| model-serving-config | User overrides for ModelMesh configuration | Custom runtime settings, storage config |

### Environment Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| NAMESPACE | Controller namespace | model-serving |
| POD_NAME | Controller pod name for leader election | (pod name) |
| ETCD_SECRET_NAME | Name of etcd connection secret | model-serving-etcd |
| ENABLE_ISVC_WATCH | Enable InferenceService reconciliation | true |
| ENABLE_CSR_WATCH | Enable ClusterServingRuntime reconciliation | true |
| DEV_MODE_LOGGING | Enable development mode logging | false |

## Observability

### Metrics

- **Endpoint**: :8080/metrics
- **Format**: Prometheus
- **ServiceMonitor**: modelmesh-metrics-monitor (if Prometheus Operator available)
- **Key Metrics**:
  - Controller reconciliation latency
  - Model loading/unloading counts
  - Model inference request counts
  - Memory usage per model

### Logging

- **Format**: JSON (production) or console (dev mode)
- **Level**: Configurable via DEV_MODE_LOGGING
- **Key Events**:
  - CRD reconciliation events
  - Model loading/unloading
  - Webhook validation results
  - Error conditions

## High Availability

- **Controller**: Supports multiple replicas with leader election (default: 1, recommended: 3)
- **etcd**: Should be deployed as clustered StatefulSet (3 or 5 nodes)
- **ModelMesh Runtimes**: Can be scaled via HorizontalPodAutoscaler
- **Model Storage**: S3/MinIO should be highly available

## Disaster Recovery

- **etcd Backup**: Required for model registry state recovery
- **Model Artifacts**: Stored in S3/MinIO with object versioning
- **CRD Backup**: Standard Kubernetes resource backup (Velero)
- **Recovery**: Restore etcd, redeploy CRDs, controller auto-reconciles

## Known Limitations

- ModelMesh pods require shared emptyDir volume for model caching
- No native support for serverless/scale-to-zero (use KServe Serverless mode instead)
- Limited to gRPC inference protocol (REST via optional proxy)
- etcd is single point of failure if not clustered
- Model size limited by available memory in ModelMesh pods
