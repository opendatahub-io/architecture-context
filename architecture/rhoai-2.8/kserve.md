# Component: KServe

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kserve.git
- **Version**: c7788a198 (rhoai-2.8)
- **Distribution**: RHOAI
- **Languages**: Go, Python
- **Deployment Type**: Operator with multiple runtime components

## Purpose
**Short**: Model serving platform that provides serverless inference for machine learning models on Kubernetes with support for multiple ML frameworks.

**Detailed**: KServe is a Kubernetes-native model inference platform that provides a standardized, cloud-agnostic solution for deploying machine learning models in production. It abstracts the complexity of autoscaling, networking, health checking, and server configuration to enable high-performance serving for frameworks including TensorFlow, PyTorch, XGBoost, Scikit-Learn, ONNX, and others. KServe supports advanced deployment patterns such as canary rollouts, multi-model serving with ModelMesh, inference pipelines with InferenceGraph, and provides integrated explainability and monitoring. It builds on Knative Serving for serverless capabilities including scale-to-zero and request-based autoscaling, and integrates with Istio for advanced traffic management and service mesh features.

The platform consists of a control plane (KServe Controller Manager) that reconciles custom resources, a webhook server for validation and mutation, runtime components (agent for model pulling, router for inference graphs, storage initializer for model loading), and a Python SDK that enables both custom model server development and provides pre-built serving runtimes for popular ML frameworks.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| KServe Controller Manager | Go Operator | Reconciles InferenceService, ServingRuntime, and InferenceGraph CRDs; manages Knative Services and Istio VirtualServices |
| Webhook Server | Admission Controller | Validates and mutates InferenceService, TrainedModel, InferenceGraph, and ServingRuntime resources; injects model puller containers |
| Agent | Sidecar Container | Downloads models from storage (S3, GCS, PVC, HTTP) to local filesystem for serving containers |
| Router | Inference Component | Routes requests through InferenceGraph pipelines enabling transformers, ensembles, and switches |
| Storage Initializer | Init Container | Pre-loads models into shared volume before serving container starts (alternative to agent sidecar) |
| Python SDK | Library/Runtime | Provides model server framework and pre-built serving runtimes (sklearn, xgboost, pytorch, tensorflow, etc.) |
| Model Servers | Runtime Containers | Framework-specific serving containers (TorchServe, TFServing, Triton, ONNX, custom) |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Primary API for deploying ML models with predictor, transformer, and explainer components |
| serving.kserve.io | v1alpha1 | InferenceGraph | Namespaced | Defines inference pipelines with multiple nodes for transformers, ensembles, routers, and switches |
| serving.kserve.io | v1alpha1 | TrainedModel | Namespaced | Represents individual models for multi-model serving on shared ServingRuntimes |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Templates for model server deployments supporting specific model formats |
| serving.kserve.io | v1alpha1 | ClusterServingRuntime | Cluster | Cluster-wide ServingRuntime templates available to all namespaces |
| serving.kserve.io | v1alpha1 | ClusterStorageContainer | Cluster | Cluster-wide storage configuration for model downloads |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /v1/models/{model}:predict | POST | 8080/TCP | HTTP | None | None | V1 prediction protocol for model inference |
| /v2/models/{model}/infer | POST | 8080/TCP | HTTP | None | None | V2 inference protocol (KServe standard) |
| /v2/models/{model}/ready | GET | 8080/TCP | HTTP | None | None | Model readiness probe |
| /v2/health/ready | GET | 8080/TCP | HTTP | None | None | Server readiness probe |
| /v2/health/live | GET | 8080/TCP | HTTP | None | None | Server liveness probe |
| /mutate-serving-kserve-io-v1beta1-inferenceservice | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Mutating webhook for InferenceService |
| /validate-serving-kserve-io-v1beta1-inferenceservice | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook for InferenceService |
| /mutate-pods | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Mutating webhook for pod injection (agent, storage-initializer) |
| /validate-serving-kserve-io-v1alpha1-trainedmodel | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook for TrainedModel |
| /validate-serving-kserve-io-v1alpha1-inferencegraph | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook for InferenceGraph |
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint (controller and model servers) |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| inference.GRPCInferenceService | 8081/TCP | gRPC/HTTP2 | None | None | V2 gRPC inference protocol for high-performance serving |
| inference.ModelRepository | 8081/TCP | gRPC/HTTP2 | None | None | Model repository management (load/unload models) |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.26+ | Yes | Container orchestration platform |
| Knative Serving | 0.39.3 | Yes (serverless mode) | Serverless deployment, autoscaling, revision management |
| Istio | 1.17+ | Yes | Service mesh for traffic routing, VirtualServices, mTLS |
| cert-manager | 1.5+ | Yes | TLS certificate management for webhooks |
| Prometheus | 2.x | No | Metrics collection and monitoring |
| AWS SDK | 1.44.264 | No | S3 model storage access |
| Google Cloud Storage | 1.33.0 | No | GCS model storage access |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Service Mesh (Istio) | VirtualService/Gateway CRDs | Traffic routing, ingress, canary deployments |
| Model Registry | HTTP API | Model metadata and versioning (optional integration) |
| Data Science Pipelines | REST API | Automated model deployment from pipelines |
| Authorino | AuthorizationPolicy | Token-based authentication for inference endpoints (optional) |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kserve-controller-manager-service | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | Bearer Token | Internal |
| kserve-webhook-server-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | mTLS (K8s API) | Internal |
| {inferenceservice}-predictor | ClusterIP | 80/TCP | 8080 | HTTP | None | None | Internal (Istio ingress) |
| {inferenceservice}-transformer | ClusterIP | 80/TCP | 8080 | HTTP | None | None | Internal (Istio ingress) |
| {inferenceservice}-explainer | ClusterIP | 80/TCP | 8080 | HTTP | None | None | Internal (Istio ingress) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {inferenceservice}-ingress | Istio VirtualService | {isvc}.{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External |
| kserve-local-gateway | Istio Gateway | * | 80/TCP | HTTP | None | None | Internal (cluster-local) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| S3 endpoints (AWS) | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Access Keys | Model artifact download |
| GCS endpoints (Google) | 443/TCP | HTTPS | TLS 1.2+ | Service Account | Model artifact download |
| HTTP(S) URLs | 80/TCP, 443/TCP | HTTP/HTTPS | TLS 1.2+ (HTTPS) | Basic/None | Model artifact download |
| Container registries | 443/TCP | HTTPS | TLS 1.2+ | Registry credentials | Runtime image pulls |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kserve-manager-role | serving.kserve.io | inferenceservices, inferenceservices/finalizers, inferenceservices/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | servingruntimes, clusterservingruntimes, servingruntimes/finalizers, clusterservingruntimes/finalizers, servingruntimes/status, clusterservingruntimes/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | inferencegraphs, inferencegraphs/finalizers, inferencegraphs/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | trainedmodels, trainedmodels/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | clusterstoragecontainers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.knative.dev | services, services/finalizers, services/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | networking.istio.io | virtualservices, virtualservices/finalizers, virtualservices/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | apps | deployments | create, delete, get, list, patch, update, watch |
| kserve-manager-role | "" (core) | services, secrets, configmaps | create, delete, get, list, patch, update, watch |
| kserve-manager-role | "" (core) | events | create, delete, get, list, patch, update, watch |
| kserve-manager-role | "" (core) | namespaces, pods, serviceaccounts | get, list, watch |
| kserve-manager-role | autoscaling | horizontalpodautoscalers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | networking.k8s.io | ingresses | create, delete, get, list, patch, update, watch |
| kserve-manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | create, delete, get, list, patch, update, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kserve-manager-rolebinding | kserve | kserve-manager-role (ClusterRole) | kserve-controller-manager |
| kserve-leader-election-rolebinding | kserve | kserve-leader-election-role | kserve-controller-manager |
| kserve-proxy-rolebinding | kserve | kserve-proxy-role | kserve-controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| kserve-webhook-server-cert | kubernetes.io/tls | TLS certificate for webhook server | cert-manager | Yes |
| kserve-webhook-server-secret | Opaque | Webhook server configuration | KServe installer | No |
| {storage}-secret | Opaque | S3/GCS/Azure credentials for model storage | User/External secrets operator | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /v1/models/* | POST, GET | None (default) | None | Open (can be secured with Istio AuthorizationPolicy) |
| /v2/models/* | POST, GET | None (default) | None | Open (can be secured with Istio AuthorizationPolicy) |
| Webhook endpoints | POST | mTLS | Kubernetes API Server | Kubernetes API client certificate |
| Controller metrics | GET | None | None | Internal only |

## Data Flows

### Flow 1: Model Inference Request (Serverless Mode)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | Istio Ingress Gateway | 443/TCP | HTTPS | TLS 1.2+ | None/Bearer Token (optional) |
| 2 | Istio Ingress Gateway | Knative Activator | 80/TCP | HTTP | mTLS (Istio) | None |
| 3 | Knative Activator | InferenceService Pod (Predictor) | 8080/TCP | HTTP | mTLS (Istio) | None |
| 4 | Predictor Container | Model Files (PVC/emptyDir) | Local | Filesystem | None | None |
| 5 | Predictor Container | Knative Activator | 8080/TCP | HTTP | mTLS (Istio) | None |
| 6 | Knative Activator | Istio Ingress Gateway | 80/TCP | HTTP | mTLS (Istio) | None |
| 7 | Istio Ingress Gateway | External Client | 443/TCP | HTTPS | TLS 1.2+ | None |

### Flow 2: Model Deployment (InferenceService Creation)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | kubectl/API Client | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (K8s) |
| 2 | Kubernetes API Server | KServe Webhook Server | 443/TCP | HTTPS | TLS 1.2+ | mTLS |
| 3 | KServe Webhook Server | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 4 | Kubernetes API Server | KServe Controller Manager | Watch/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 5 | KServe Controller Manager | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 6 | Controller | Knative Serving API | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token |

### Flow 3: Model Download (Storage Initializer)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Storage Initializer Init Container | S3/GCS/Azure Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/GCP SA/Azure AD |
| 2 | Storage Initializer | Local Volume (emptyDir) | Local | Filesystem | None | None |
| 3 | Model Server Container | Local Volume (emptyDir) | Local | Filesystem | None | None |

### Flow 4: InferenceGraph Request (Multi-Step Pipeline)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | Istio Ingress Gateway | 443/TCP | HTTPS | TLS 1.2+ | None/Bearer Token |
| 2 | Istio Gateway | InferenceGraph Router | 8080/TCP | HTTP | mTLS (Istio) | None |
| 3 | Router | Transformer Service | 8080/TCP | HTTP | mTLS (Istio) | None |
| 4 | Router | Predictor Service | 8080/TCP | HTTP | mTLS (Istio) | None |
| 5 | Router | Istio Ingress Gateway | 8080/TCP | HTTP | mTLS (Istio) | None |
| 6 | Istio Gateway | External Client | 443/TCP | HTTPS | TLS 1.2+ | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Knative Serving | CRD Watch/Reconcile | 443/TCP | HTTPS | TLS 1.2+ | Create Knative Services for serverless deployment |
| Istio (VirtualService) | CRD Create/Update | 443/TCP | HTTPS | TLS 1.2+ | Configure traffic routing, canary rollouts |
| Kubernetes API Server | CRD Watch/Reconcile | 443/TCP | HTTPS | TLS 1.2+ | Manage Deployments, Services, ConfigMaps, Secrets |
| Prometheus | HTTP Scrape | 8080/TCP | HTTP | None | Metrics collection from controller and model servers |
| cert-manager | Certificate CRD | 443/TCP | HTTPS | TLS 1.2+ | Request and manage webhook TLS certificates |
| Object Storage (S3/GCS) | S3/GCS API | 443/TCP | HTTPS | TLS 1.2+ | Download model artifacts |
| Container Registry | Docker Registry API | 443/TCP | HTTPS | TLS 1.2+ | Pull model server images |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| c7788a198 | 2024-Q4 | - Cleanup filepath to avoid path traversal issue (#484)<br>- Update requirements.txt to latest versions<br>- Fix starlette Allocation of Resources Without Limits or Throttling (RHOAIENG-16422)<br>- Fix fastapi Regular Expression Denial of Service (RHOAIENG-16424)<br>- Fix anyio Race Condition (RHOAIENG-16425)<br>- Fix Type Confusion vulnerability (RHOAIENG-13713, CVE-2024-6119)<br>- Fix incorrect handling of ZIP files (RHOAIENG-9991) |
| 313233743 | 2024-Q4 | - Update requirements.txt to reflect latest updates |
| 4f95ba6de | 2024-Q4 | - Fix starlette resource allocation issues |
| 8ec5cb896 | 2024-Q4 | - Fix fastapi ReDoS vulnerability |
| b6397f17c | 2024-Q4 | - Fix anyio race condition vulnerability |

## Deployment Architecture

### Controller Deployment

The KServe Controller Manager runs as a single-replica Deployment in the `kserve` namespace with:
- **Resource Limits**: 100m CPU, 300Mi memory
- **Resource Requests**: 100m CPU, 200Mi memory
- **Security Context**: runAsNonRoot, no privilege escalation
- **Webhook Server Port**: 9443/TCP (TLS)
- **Certificate Volume**: Mounted from `kserve-webhook-server-cert` secret

### Inference Service Deployment

When an InferenceService is created, KServe generates:
1. **Knative Service** (serverless mode) or **Deployment** (RawDeployment mode)
2. **Istio VirtualService** for traffic routing and canary rollouts
3. **Service** resources for predictor, transformer, and explainer components
4. **ConfigMap** with model configuration injected into pods
5. **Init Container** (storage-initializer) or **Sidecar** (agent) for model downloads

### Model Server Pod Structure

Each InferenceService pod contains:
- **Init Container** (storage-initializer): Downloads model from object storage
- **Main Container** (model server): Serves inference requests using framework runtime
- **Agent Sidecar** (optional): Alternative to init container for dynamic model loading
- **Queue Proxy** (Knative): Request queuing and concurrency control
- **Istio Sidecar** (envoy): Service mesh features, mTLS, telemetry

## Configuration

### Key ConfigMaps

| ConfigMap | Namespace | Purpose |
|-----------|-----------|---------|
| inferenceservice-config | kserve | Global configuration for explainers, storage initializer, ingress, logger |
| {servingruntime}-config | User namespace | Model configuration for multi-model serving |

### Environment Variables

**Controller Manager**:
- `POD_NAMESPACE`: Controller pod namespace
- `SECRET_NAME`: Webhook certificate secret name

**Model Servers** (Python SDK):
- `STORAGE_URI`: Model storage location (s3://, gs://, pvc://, file://)
- `MODEL_NAME`: Model name for inference endpoint
- `PROTOCOL`: Inference protocol (v1, v2, grpc-v2)
- `PORT`: HTTP server port (default: 8080)
- `GRPC_PORT`: gRPC server port (default: 8081)

## Observability

### Metrics

**Controller Metrics** (Prometheus format on :8080/metrics):
- `kserve_inferenceservice_reconcile_duration_seconds`: Reconciliation latency
- `kserve_inferenceservice_reconcile_total`: Reconciliation count by result
- `kserve_inferenceservice_ready_total`: Ready InferenceServices count

**Model Server Metrics** (Prometheus format on :8080/metrics):
- `kserve_model_infer_duration_seconds`: Inference latency histogram
- `kserve_model_infer_total`: Total inference requests
- `kserve_model_loaded`: Model load status (0=unloaded, 1=loaded)

### Logging

All components use structured logging:
- **Controller**: JSON logs with reconciliation events, errors
- **Model Servers**: JSON logs with request/response details, model loading events
- **Agent**: Model download progress, errors

### Tracing

When integrated with Jaeger/Zipkin via Istio:
- Request tracing through transformer → predictor → explainer pipeline
- Distributed tracing across InferenceGraph nodes
- Integration with Knative request tracing

## Scaling

### Autoscaling

**Serverless Mode** (Knative):
- **Scale to Zero**: Pods scale to 0 when idle (configurable timeout)
- **Request-based Autoscaling**: HPA based on concurrent requests (default target: 100)
- **Target Utilization**: Configurable via annotations (autoscaling.knative.dev/target)

**RawDeployment Mode**:
- **Horizontal Pod Autoscaler**: CPU/memory-based autoscaling
- **Manual Scaling**: Replica count set in InferenceService spec

### Resource Management

- **CPU/GPU requests**: Configurable per component (predictor, transformer, explainer)
- **Memory limits**: Prevents OOM for large models
- **Storage**: emptyDir for model cache, PVC for persistent model storage
- **Node affinity**: GPU node selection for accelerated inference

## High Availability

- **Controller**: Single replica with leader election (can run multiple replicas)
- **Webhooks**: Multiple replicas supported, load balanced by K8s Service
- **Model Servers**: Multiple replicas via autoscaling or manual configuration
- **InferenceGraph Router**: Replicated for high availability

## Limitations & Constraints

- **Model Size**: Limited by available storage and memory (init containers have configurable limits)
- **Cold Start**: Scale-to-zero introduces latency on first request (mitigated by min-scale)
- **Knative Dependency**: Serverless features require Knative installation
- **Istio Dependency**: Traffic management and service mesh features require Istio
- **GPU Support**: Requires GPU nodes and device plugins in cluster
- **Multi-tenancy**: Namespace isolation, no cross-namespace InferenceService references
