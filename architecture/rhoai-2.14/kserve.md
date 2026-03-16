# Component: KServe

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kserve.git
- **Version**: 1fdf877e7 (rhoai-2.14)
- **Distribution**: RHOAI
- **Languages**: Go, Python
- **Deployment Type**: Kubernetes Operator + Model Serving Runtime

## Purpose
**Short**: KServe is a Kubernetes-native model serving platform for production ML inference workloads.

**Detailed**: KServe provides a Kubernetes Custom Resource Definition (CRD) based solution for serving machine learning models on arbitrary frameworks. It aims to solve production model serving use cases by providing performant, high abstraction interfaces for common ML frameworks like TensorFlow, XGBoost, ScikitLearn, PyTorch, ONNX, HuggingFace, and others. The platform encapsulates the complexity of autoscaling, networking, health checking, and server configuration to bring cutting-edge serving features like GPU autoscaling, scale-to-zero, canary rollouts, and multi-model serving. KServe enables a complete story for production ML serving including prediction, pre-processing, post-processing, and explainability through modular components.

KServe supports multiple deployment modes: serverless deployment (using Knative for autoscaling and scale-to-zero), raw Kubernetes deployment (lightweight without Knative), and ModelMesh integration (for high-density, frequently-changing model workloads). The platform integrates with Istio for advanced networking, traffic management, and service mesh capabilities.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kserve-controller-manager | Go Operator | Reconciles InferenceService, ServingRuntime, InferenceGraph CRDs; manages Knative Services, Istio VirtualServices, K8s Deployments |
| kserve-webhook-server | Go Webhook | Mutates and validates KServe CRDs; injects storage-initializer and agent sidecars into InferenceService pods |
| kserve-agent | Go Sidecar | Pulls models dynamically, logs requests/responses, batches inference requests, provides readiness/liveness probes |
| kserve-router | Go Service | Routes and orchestrates multi-step inference pipelines defined in InferenceGraph resources |
| storage-initializer | Python InitContainer | Downloads models from cloud storage (S3, GCS, Azure Blob, HDFS) at pod startup |
| sklearn-server | Python Runtime | Serves scikit-learn models with V1/V2 inference protocol |
| xgboost-server | Python Runtime | Serves XGBoost models with V1/V2 inference protocol |
| lightgbm-server | Python Runtime | Serves LightGBM models with V1/V2 inference protocol |
| huggingface-server | Python Runtime | Serves HuggingFace transformer models |
| pytorch-server | Python Runtime | Serves PyTorch models via TorchServe |
| tensorflow-server | Container Runtime | Serves TensorFlow models via TensorFlow Serving |
| triton-server | Container Runtime | Serves models via NVIDIA Triton Inference Server |
| alibi-explainer | Python Sidecar | Provides model explainability using Alibi framework |
| art-explainer | Python Sidecar | Provides adversarial robustness analysis using IBM ART |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Defines an ML model deployment with predictor, transformer, explainer components; supports canary rollouts and autoscaling |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Defines a reusable model server template for specific frameworks; specifies container image, args, resource limits |
| serving.kserve.io | v1alpha1 | ClusterServingRuntime | Cluster | Cluster-scoped ServingRuntime template available across all namespaces |
| serving.kserve.io | v1alpha1 | InferenceGraph | Namespaced | Defines multi-step inference pipeline with routing, ensembling, sequential steps |
| serving.kserve.io | v1alpha1 | TrainedModel | Namespaced | Represents a trained model artifact to be loaded into a serving runtime; supports multi-model serving |
| serving.kserve.io | v1alpha1 | ClusterStorageContainer | Cluster | Defines storage backend configuration for model downloads (S3, GCS, Azure, etc.) |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /v1/models/{model}:predict | POST | 8080/TCP | HTTP | None | None | V1 prediction endpoint for model inference |
| /v2/models/{model}/infer | POST | 8080/TCP | HTTP | None | None | V2 inference endpoint (KServe standard) |
| /v1/models/{model}/explain | POST | 8080/TCP | HTTP | None | None | Model explanation endpoint (Alibi/ART) |
| /healthz | GET | 8081/TCP | HTTP | None | None | Controller manager liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Controller manager readiness probe |
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint for controller |
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint for model servers |
| /mutate-serving-kserve-io-v1beta1-inferenceservice | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Mutating webhook for InferenceService |
| /validate-serving-kserve-io-v1beta1-inferenceservice | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook for InferenceService |
| /mutate-pods | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Pod mutation webhook (injects storage-initializer, agent) |
| /validate-serving-kserve-io-v1alpha1-trainedmodel | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook for TrainedModel |
| /validate-serving-kserve-io-v1alpha1-inferencegraph | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook for InferenceGraph |
| /validate-serving-kserve-io-v1alpha1-servingruntime | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook for ServingRuntime |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| inference.GRPCInferenceService | 8081/TCP | gRPC/HTTP2 | None | None | V2 gRPC inference protocol (supported by Triton, TorchServe) |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Knative Serving | 1.x | Conditional | Serverless autoscaling, scale-to-zero, traffic splitting for InferenceServices |
| Istio | 1.x | Conditional | Service mesh networking, VirtualServices, traffic routing, mTLS |
| Kubernetes | 1.26+ | Yes | Core platform for CRDs, operators, deployments, services |
| cert-manager | 1.x | Conditional | TLS certificate management for webhooks |
| Prometheus | 2.x | No | Metrics collection from model servers and controller |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Service Mesh (Istio) | Istio VirtualService CRD | KServe controller creates VirtualServices for InferenceService routing; relies on Istio for traffic management |
| Model Registry | Optional Integration | Can reference models stored in ODH Model Registry for versioning and lineage |
| Data Science Pipelines | Optional Integration | InferenceServices can be deployed as pipeline outputs |
| Authorino | Optional Integration | External authorization for inference endpoints via service mesh |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kserve-controller-manager-service | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | None | Internal |
| kserve-webhook-server-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | mTLS | Internal |
| {isvc-name}-predictor-default | ClusterIP | 80/TCP | 8080 | HTTP | None | Optional | Internal/External |
| {isvc-name}-predictor-default (Knative) | ClusterIP | 80/TCP | 8012 | HTTP | None | Optional | Internal |
| {isvc-name}-transformer-default | ClusterIP | 80/TCP | 8080 | HTTP | None | Optional | Internal |
| {isvc-name}-explainer-default | ClusterIP | 80/TCP | 8080 | HTTP | None | Optional | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {isvc-name}-ingress | Kubernetes Ingress | {name}-{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External |
| {isvc-name} | Istio VirtualService | {name}-{namespace}.{domain} | 80/TCP, 443/TCP | HTTP/HTTPS | TLS 1.2+ | SIMPLE | External |
| knative-ingress-gateway | Istio Gateway | *.{domain} | 80/TCP, 443/TCP | HTTP/HTTPS | TLS 1.2+ | SIMPLE | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| s3.amazonaws.com | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Access Keys | Download models from S3 |
| storage.googleapis.com | 443/TCP | HTTPS | TLS 1.2+ | GCP Service Account | Download models from GCS |
| {azure}.blob.core.windows.net | 443/TCP | HTTPS | TLS 1.2+ | Azure Storage Keys | Download models from Azure Blob |
| HDFS namenode | 8020/TCP | HDFS | Optional Kerberos | Kerberos | Download models from HDFS |
| Knative Activator | 8012/TCP | HTTP | None | None | Route requests to scaled-to-zero services |
| default-broker | 80/TCP | HTTP | None | CloudEvents | Send request/response logs as CloudEvents |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kserve-manager-role | serving.kserve.io | inferenceservices, inferenceservices/finalizers, inferenceservices/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | servingruntimes, clusterservingruntimes, servingruntimes/finalizers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | inferencegraphs, inferencegraphs/finalizers, inferencegraphs/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | trainedmodels, trainedmodels/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | clusterstoragecontainers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.knative.dev | services, services/finalizers, services/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | networking.istio.io | virtualservices, virtualservices/finalizers, virtualservices/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | apps | deployments | create, delete, get, list, patch, update, watch |
| kserve-manager-role | "" (core) | services, secrets, configmaps, events | create, delete, get, list, patch, update, watch |
| kserve-manager-role | "" (core) | namespaces, pods, serviceaccounts | get, list, watch |
| kserve-manager-role | autoscaling | horizontalpodautoscalers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | networking.k8s.io | ingresses | create, delete, get, list, patch, update, watch |
| kserve-manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | create, delete, get, list, patch, update, watch |
| kserve-leader-election-role | "" (core) | configmaps | get, update, create |
| kserve-leader-election-role | coordination.k8s.io | leases | get, update, create |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kserve-manager-rolebinding | kserve | kserve-manager-role (ClusterRole) | kserve-controller-manager |
| kserve-leader-election-rolebinding | kserve | kserve-leader-election-role (ClusterRole) | kserve-controller-manager |
| kserve-proxy-rolebinding | kserve | kserve-proxy-role (ClusterRole) | kserve-controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| kserve-webhook-server-cert | kubernetes.io/tls | TLS certificate for webhook server | cert-manager | Yes |
| storage-config | Opaque | Cloud storage credentials (S3, GCS, Azure) | User/Admin | No |
| {sa}-token | kubernetes.io/service-account-token | Service account token for IRSA/Workload Identity | Kubernetes | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /v1/models/{model}:predict | POST | Optional Bearer Token | Istio AuthorizationPolicy | User-defined |
| /v2/models/{model}/infer | POST | Optional Bearer Token | Istio AuthorizationPolicy | User-defined |
| Webhook endpoints | POST | mTLS client certificates | kube-apiserver | Kubernetes built-in |
| Controller manager metrics | GET | None | NetworkPolicy | Internal cluster only |
| Model download (S3) | GET | AWS IAM Role (IRSA) or Access Keys | S3 API | Bucket policy |
| Model download (GCS) | GET | GCP Service Account (Workload Identity) | GCS API | Bucket IAM |

## Data Flows

### Flow 1: InferenceService Creation and Model Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User (kubectl) | kube-apiserver | 6443/TCP | HTTPS | TLS 1.3 | kubeconfig credentials |
| 2 | kube-apiserver | kserve-webhook-server | 9443/TCP | HTTPS | TLS 1.2+ | mTLS |
| 3 | kube-apiserver | kserve-controller-manager | N/A | K8s Watch API | N/A | ServiceAccount token |
| 4 | kserve-controller-manager | kube-apiserver | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount token |
| 5 | storage-initializer (InitContainer) | S3/GCS/Azure | 443/TCP | HTTPS | TLS 1.2+ | IAM Role/Service Account/Access Key |
| 6 | storage-initializer | model-server (shared volume) | N/A | Local filesystem | N/A | None |

### Flow 2: Model Inference Request (Serverless Mode)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | Istio Ingress Gateway | 443/TCP | HTTPS | TLS 1.3 | Optional Bearer Token |
| 2 | Istio Ingress Gateway | Istio VirtualService | 80/TCP | HTTP | None (mTLS optional) | Istio AuthorizationPolicy |
| 3 | Istio VirtualService | Knative Activator (if scaled to zero) | 8012/TCP | HTTP | None (mTLS optional) | None |
| 4 | Knative Activator | InferenceService Pod (kserve-agent) | 8012/TCP | HTTP | None | None |
| 5 | kserve-agent | model-server | 8080/TCP | HTTP | None | None |
| 6 | model-server | kserve-agent | 8080/TCP | HTTP | None | None |
| 7 | kserve-agent (logger) | CloudEvents broker | 80/TCP | HTTP | None | CloudEvents |

### Flow 3: Model Inference Request (Raw Deployment Mode)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | Kubernetes Ingress | 443/TCP | HTTPS | TLS 1.3 | Optional Bearer Token |
| 2 | Kubernetes Ingress | InferenceService Pod (model-server) | 8080/TCP | HTTP | None | Optional |
| 3 | model-server | response | 8080/TCP | HTTP | None | None |

### Flow 4: InferenceGraph Multi-Step Pipeline

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | Istio Ingress Gateway | 443/TCP | HTTPS | TLS 1.3 | Optional Bearer Token |
| 2 | Istio Ingress Gateway | kserve-router | 8080/TCP | HTTP | None (mTLS optional) | Optional |
| 3 | kserve-router | Step 1 InferenceService | 80/TCP | HTTP | None (mTLS optional) | Header propagation |
| 4 | kserve-router | Step 2 InferenceService | 80/TCP | HTTP | None (mTLS optional) | Header propagation |
| 5 | kserve-router | External Client | 8080/TCP | HTTP | None | None |

### Flow 5: Dynamic Model Loading (TrainedModel)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User (kubectl) | kube-apiserver | 6443/TCP | HTTPS | TLS 1.3 | kubeconfig credentials |
| 2 | kube-apiserver | kserve-controller-manager | N/A | K8s Watch API | N/A | ServiceAccount token |
| 3 | kserve-controller-manager | Running InferenceService Pod (kserve-agent) | 9081/TCP | HTTP | None | Internal |
| 4 | kserve-agent | S3/GCS/Azure | 443/TCP | HTTPS | TLS 1.2+ | IAM Role/Service Account |
| 5 | kserve-agent | model-server | Unix socket | HTTP | None | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Knative Serving | Kubernetes CRD (serving.knative.dev/v1.Service) | N/A | K8s API | TLS 1.3 | Controller creates Knative Services for serverless InferenceServices |
| Istio | Kubernetes CRD (networking.istio.io/v1.VirtualService) | N/A | K8s API | TLS 1.3 | Controller creates VirtualServices for traffic routing |
| Kubernetes Ingress | Kubernetes CRD (networking.k8s.io/v1.Ingress) | N/A | K8s API | TLS 1.3 | Controller creates Ingresses for raw deployment mode |
| cert-manager | Kubernetes CRD (cert-manager.io/v1.Certificate) | N/A | K8s API | TLS 1.3 | Webhook certificates provisioned via cert-manager |
| Prometheus | HTTP scrape | 8080/TCP | HTTP | None | Model server and controller metrics exported |
| CloudEvents Broker | HTTP POST | 80/TCP | HTTP | None | Request/response logging as CloudEvents |
| S3-compatible storage | S3 API | 443/TCP | HTTPS | TLS 1.2+ | Model artifact storage and retrieval |
| GCS | GCS API | 443/TCP | HTTPS | TLS 1.2+ | Model artifact storage and retrieval |
| Azure Blob Storage | Azure Blob API | 443/TCP | HTTPS | TLS 1.2+ | Model artifact storage and retrieval |
| HDFS | HDFS protocol | 8020/TCP | HDFS | Optional Kerberos | Model artifact storage and retrieval |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 1fdf877e7 | 2026-03-15 | - Merge pull request for kserve-agent-214 component updates |
| aed857750 | 2026-03-15 | - Merge branch rhoai-2.14 into konflux component updates |
| b04bb7408 | 2026-03-15 | - Merge pull request for kserve-storage-initializer-214 updates |
| e758b0c0a | 2026-03-15 | - Update kserve-storage-initializer-214 to commit 498574b |
| 4cdb4b553 | 2026-03-15 | - Merge pull request for kserve-router-214 component updates |
| 3a8443ac6 | 2026-03-15 | - Merge pull request for kserve-controller-214 component updates |
| 8f4b7e0b3 | 2026-03-15 | - Update kserve-agent-214 to commit dfd06d8 |
| 362257f04 | 2026-03-15 | - Update kserve-router-214 to commit c583256 |
| 25c69eb33 | 2026-03-15 | - Update kserve-controller-214 to commit 6fc5bea |
| 46ee17a97 | 2026-03-15 | - Merge remote-tracking branch from upstream master into rhoai-2.14 |
| 58b312809 | 2026-03-15 | - Merge remote-tracking branch from upstream release-v0.12.1 |
| ca74f5971 | 2026-03-15 | - [RHOAIENG-13712] Security fix for CVE-2024-6119 Type Confusion vulnerability |
| b6746e808 | 2026-03-15 | - Merge pull request for kserve-storage-initializer-214 updates |
| 361e3c382 | 2026-03-15 | - Update kserve-storage-initializer-214 to commit 8930d0f |
| 6b24b1114 | 2026-03-15 | - Merge pull request for kserve-controller-214 component updates |

## Deployment Architecture

### Serverless Deployment Mode (Default)

KServe creates **Knative Services** for each InferenceService component:
- **Predictor**: Main model serving container with autoscaling (including scale-to-zero)
- **Transformer**: Optional preprocessing/postprocessing with autoscaling
- **Explainer**: Optional model explanation with autoscaling

**Istio VirtualServices** are created for routing:
- Top-level VirtualService routes external traffic through Istio Ingress Gateway
- Component VirtualServices route between predictor, transformer, explainer

**Pod Structure** (Serverless):
```
Pod: {isvc-name}-predictor-default-{revision}-{hash}
├── queue-proxy (Knative sidecar for autoscaling metrics)
├── storage-initializer (InitContainer - downloads model)
├── kserve-agent (Sidecar - optional for logging, batching, multi-model)
└── {model-server} (sklearn, xgboost, tensorflow, etc.)
```

### Raw Deployment Mode

KServe creates **Kubernetes Deployments** and **Services**:
- Standard Deployment with configurable replicas (no autoscaling)
- Standard ClusterIP Service
- Optional Kubernetes Ingress or Istio VirtualService for external access

**Pod Structure** (Raw):
```
Pod: {isvc-name}-predictor-default-{hash}
├── storage-initializer (InitContainer - downloads model)
└── {model-server} (sklearn, xgboost, tensorflow, etc.)
```

### InferenceGraph Deployment

Creates a **kserve-router** Deployment that orchestrates multi-step pipelines:
- Router reads InferenceGraph spec and routes requests through defined steps
- Supports sequential steps, routing (switch/split), and ensembling
- Can propagate headers (Authorization, Trace-Id, etc.) between steps

## Configuration

### ConfigMap: inferenceservice-config

Key configurations in `kserve` namespace:

| Configuration | Purpose | Default |
|---------------|---------|---------|
| deploy.defaultDeploymentMode | Deployment mode (Serverless/RawDeployment/ModelMesh) | Serverless |
| storageInitializer.image | Storage initializer container image | kserve/storage-initializer:latest |
| storageInitializer.enableDirectPvcVolumeMount | Allow direct PVC mounting | true |
| ingress.ingressGateway | Istio gateway for external traffic | knative-serving/knative-ingress-gateway |
| ingress.ingressDomain | Base domain for InferenceService URLs | example.com |
| ingress.urlScheme | URL scheme (http/https) | http |
| agent.image | Agent sidecar image | kserve/agent:latest |
| router.image | Router image for InferenceGraph | kserve/router:latest |
| batcher.maxBatchSize | Max batch size for request batching | 32 |
| batcher.maxLatency | Max batching latency (ms) | 5000 |
| explainers.alibi.image | Alibi explainer image | kserve/alibi-explainer:latest |
| credentials.s3.s3AccessKeyIDName | S3 access key env var name | AWS_ACCESS_KEY_ID |

### ClusterServingRuntimes

Pre-configured model serving runtimes (deployed in `kserve` namespace):

| Runtime | Framework | Protocol | Auto-Select | Image |
|---------|-----------|----------|-------------|-------|
| kserve-sklearnserver | scikit-learn | V1, V2 | Yes | kserve-sklearnserver |
| kserve-xgbserver | XGBoost | V1, V2 | Yes | kserve-xgbserver |
| kserve-lgbserver | LightGBM | V1, V2 | Yes | kserve-lgbserver |
| kserve-huggingfaceserver | HuggingFace | V1, V2 | Yes | kserve-huggingfaceserver |
| kserve-mlserver | MLServer (multi-framework) | V2 | No | seldonio/mlserver |
| kserve-tensorflow-serving | TensorFlow | V1, V2 | Yes | tensorflow/serving |
| kserve-torchserve | PyTorch | V1, V2 | Yes | pytorch/torchserve |
| kserve-tritonserver | NVIDIA Triton (multi-framework) | V2 | No | nvcr.io/nvidia/tritonserver |
| kserve-paddleserver | PaddlePaddle | V1, V2 | Yes | kserve-paddleserver |
| kserve-pmmlserver | PMML | V1, V2 | Yes | kserve-pmmlserver |

## Observability

### Metrics

- **Controller metrics**: Exposed on port 8080, scraped by Prometheus
  - InferenceService reconciliation duration
  - Reconciliation errors and retries
  - Webhook validation/mutation latency

- **Model server metrics**: Exposed on port 8080 (configurable)
  - Inference request count, latency, errors
  - Model loading time
  - Queue depth (for batching)

### Logging

- **Controller logs**: Structured JSON logs to stdout (reconciliation events, errors)
- **Model server logs**: Application logs to stdout
- **Request/Response logging**: Optional via kserve-agent sidecar
  - Sends CloudEvents to configured broker
  - Supports "request", "response", or "all" logging modes

### Tracing

- Compatible with Istio distributed tracing
- Propagates trace headers (B3, Jaeger, etc.) through InferenceGraph steps

## Known Limitations

1. **Serverless Mode**: Requires Knative Serving and Istio installation
2. **Scale-to-Zero**: Cold start latency when pod scales from zero (model download + loading time)
3. **Multi-Model Serving**: TrainedModel API (v1alpha1) is still in development
4. **GPU Support**: GPU autoscaling requires cluster autoscaler and GPU node pools
5. **ModelMesh Integration**: Separate installation required for high-density use cases
6. **Storage Backends**: Direct PVC mounting requires `enableDirectPvcVolumeMount: true` configuration
