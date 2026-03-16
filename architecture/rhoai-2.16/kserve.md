# Component: KServe

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kserve
- **Version**: ae15d3843
- **Branch**: rhoai-2.16
- **Distribution**: RHOAI
- **Languages**: Go (operator), Python (inference servers)
- **Deployment Type**: Kubernetes Operator with Model Serving Infrastructure

## Purpose
**Short**: KServe provides a standardized, production-ready platform for serving machine learning models on Kubernetes with support for serverless autoscaling, model versioning, and multi-framework inference.

**Detailed**: KServe is a comprehensive ML model serving solution that abstracts the complexity of deploying and managing inference workloads on Kubernetes. It provides a unified interface for deploying models trained with various ML frameworks (TensorFlow, PyTorch, Scikit-learn, XGBoost, etc.) through Custom Resource Definitions. The platform supports multiple deployment modes including serverless (via Knative), raw Kubernetes deployments, and high-density ModelMesh deployments. KServe handles critical production concerns including model storage retrieval from S3/GCS/Azure, request batching, logging, canary rollouts, A/B testing, and multi-model inference graphs. It integrates deeply with Istio for traffic management and provides standardized prediction protocols (v1/v2 REST and gRPC) that enable consistent inference APIs across different model frameworks.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kserve-controller-manager | Kubernetes Operator | Reconciles InferenceService CRs, manages model deployments, creates Knative Services or K8s Deployments |
| kserve-webhook-server | Admission Webhook | Validates and mutates InferenceService CRs, injects storage initializers into pods |
| storage-initializer | Init Container | Downloads model artifacts from cloud storage (S3/GCS/Azure/HTTP) to local volume |
| agent | Sidecar Container | Handles model pulling, request logging to external systems, request batching |
| router | Container | Routes and orchestrates requests across multiple models in InferenceGraphs |
| Python Inference Servers | Runtime Containers | Framework-specific model servers (sklearn, xgboost, tensorflow, pytorch, huggingface, etc.) |
| Python kserve Library | SDK | Provides standardized data plane API, storage retrieval, and model serving framework |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Primary resource for deploying ML models with predictor, transformer, and explainer components |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Defines model serving runtime configurations for specific ML frameworks |
| serving.kserve.io | v1alpha1 | ClusterServingRuntime | Cluster | Cluster-wide serving runtime templates for ML frameworks |
| serving.kserve.io | v1alpha1 | TrainedModel | Namespaced | Manages individual model versions for multi-model serving |
| serving.kserve.io | v1alpha1 | InferenceGraph | Namespaced | Defines multi-model inference pipelines with conditional routing |
| serving.kserve.io | v1alpha1 | ClusterLocalModel | Cluster | Manages models stored on local node storage |
| serving.kserve.io | v1alpha1 | LocalModelNodeGroup | Namespaced | Groups nodes for local model distribution |
| serving.kserve.io | v1alpha1 | ClusterStorageContainer | Cluster | Defines cluster-wide storage container configurations |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /v1/models/{model}:predict | POST | 8080/TCP | HTTP | TLS optional | Bearer Token optional | v1 inference protocol prediction endpoint |
| /v2/models/{model}/infer | POST | 8080/TCP | HTTP | TLS optional | Bearer Token optional | v2 inference protocol inference endpoint |
| /v1/models/{model}:explain | POST | 8080/TCP | HTTP | TLS optional | Bearer Token optional | Model explanation endpoint |
| /v1/models/{model}/ready | GET | 8080/TCP | HTTP | TLS optional | None | Model readiness probe |
| /v1/models | GET | 8080/TCP | HTTP | TLS optional | None | List available models |
| /metrics | GET | 8080/TCP | HTTP | TLS optional | None | Prometheus metrics endpoint |
| /healthz | GET | 8081/TCP | HTTP | None | None | Controller manager liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Controller manager readiness probe |
| /mutate-serving-kserve-io-v1beta1-inferenceservice | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Mutating webhook for InferenceService CRs |
| /validate-serving-kserve-io-v1beta1-inferenceservice | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook for InferenceService CRs |
| /mutate-pods | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Pod mutating webhook for injecting storage initializer |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| inference.GRPCInferenceService | 8081/TCP | gRPC/HTTP2 | TLS optional | mTLS optional | v2 gRPC inference protocol |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.24+ | Yes | Container orchestration platform |
| Knative Serving | 1.8+ | Optional | Serverless deployment mode with autoscaling and scale-to-zero |
| Istio | 1.16+ | Optional | Service mesh for traffic routing, mTLS, and observability |
| cert-manager | 1.10+ | Optional | TLS certificate management for webhooks |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Service Mesh (Istio) | VirtualService CRs | Traffic routing, canary deployments, A/B testing |
| Knative Serving | Knative Service CRs | Serverless deployments with autoscaling |
| Model Registry | HTTP API | Model metadata and versioning (optional) |
| S3 Storage | S3 API | Model artifact storage and retrieval |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kserve-controller-manager-service | ClusterIP | 8443/TCP | https | HTTPS | TLS 1.2+ | None | Internal |
| kserve-webhook-server-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | mTLS | Internal |
| {isvc-name}-predictor-default | ClusterIP | 80/TCP | 8080 | HTTP | TLS optional via Istio | Bearer Token optional | Internal/External via Ingress |
| {isvc-name}-transformer-default | ClusterIP | 80/TCP | 8080 | HTTP | TLS optional via Istio | Bearer Token optional | Internal |
| {isvc-name}-explainer-default | ClusterIP | 80/TCP | 8080 | HTTP | TLS optional via Istio | Bearer Token optional | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {isvc-name}-ingress | Istio VirtualService | {name}-{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External |
| knative-ingress-gateway | Istio Gateway | *.{cluster-domain} | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External |
| knative-local-gateway | Istio Gateway | *.cluster.local | 80/TCP | HTTP | None | None | Internal |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| S3 Endpoints (s3.amazonaws.com) | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Access Keys | Download model artifacts from S3 |
| GCS Endpoints (storage.googleapis.com) | 443/TCP | HTTPS | TLS 1.2+ | GCP Service Account | Download model artifacts from GCS |
| Azure Blob Storage | 443/TCP | HTTPS | TLS 1.2+ | Azure credentials | Download model artifacts from Azure |
| HTTP/HTTPS Model Sources | 443/TCP or 80/TCP | HTTPS/HTTP | TLS 1.2+ or None | Basic Auth optional | Download models from generic HTTP endpoints |
| Logger Endpoint | 80/TCP or 443/TCP | HTTP/HTTPS | TLS optional | Bearer Token optional | Send inference request/response logs |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kserve-manager-role | serving.kserve.io | inferenceservices, servingruntimes, clusterservingruntimes, trainedmodels, inferencegraphs, clusterstoragecontainers, clusterlocalmodels | get, list, watch, create, update, patch, delete |
| kserve-manager-role | serving.knative.dev | services | get, list, watch, create, update, patch, delete |
| kserve-manager-role | networking.istio.io | virtualservices | get, list, watch, create, update, patch, delete |
| kserve-manager-role | apps | deployments | get, list, watch, create, update, patch, delete |
| kserve-manager-role | networking.k8s.io | ingresses | get, list, watch, create, update, patch, delete |
| kserve-manager-role | autoscaling | horizontalpodautoscalers | get, list, watch, create, update, patch, delete |
| kserve-manager-role | "" (core) | services, events, configmaps | get, list, watch, create, update, patch, delete |
| kserve-manager-role | "" (core) | namespaces, pods | get, list, watch |
| kserve-manager-role | "" (core) | secrets, serviceaccounts | get |
| kserve-manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | get, list, watch, create, update, patch, delete |
| kserve-leader-election-role | "" (core) | configmaps | get, list, watch, create, update, patch, delete |
| kserve-leader-election-role | "" (core) | configmaps/status | get, update, patch |
| kserve-leader-election-role | "" (core) | events | create, patch |
| kserve-leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kserve-manager-rolebinding | cluster-wide | kserve-manager-role | kserve/kserve-controller-manager |
| kserve-leader-election-rolebinding | kserve | kserve-leader-election-role | kserve/kserve-controller-manager |
| kserve-auth-proxy-rolebinding | kserve | kserve-auth-proxy-role | kserve/kserve-controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| kserve-webhook-server-cert | kubernetes.io/tls | TLS certificate for webhook server | cert-manager | Yes |
| storage-config | Opaque | S3/GCS/Azure credentials for model storage | User/Admin | No |
| {custom}-sa-token | Opaque | Service account tokens for authenticated storage access | Kubernetes | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /v1/models/{model}:predict | POST | Bearer Token (optional) | Istio AuthorizationPolicy | User-defined |
| /v2/models/{model}/infer | POST | Bearer Token (optional) | Istio AuthorizationPolicy | User-defined |
| Webhook endpoints | POST | mTLS | Kubernetes API Server | Certificate-based |
| Controller metrics | GET | None | Network Policy | Internal cluster access only |
| Model storage (S3) | GET | AWS IAM/Access Keys | Storage provider | IAM policies |
| Model storage (GCS) | GET | GCP Service Account | Storage provider | IAM policies |

## Data Flows

### Flow 1: Model Deployment - Serverless Mode

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token/Certificate |
| 2 | Kubernetes API | kserve-webhook-server | 9443/TCP | HTTPS | TLS 1.2+ | mTLS |
| 3 | kserve-controller-manager | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 4 | kserve-controller-manager | Knative API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 5 | storage-initializer | S3/GCS/Azure | 443/TCP | HTTPS | TLS 1.2+ | Cloud credentials |
| 6 | Inference Server | Local Volume | N/A | Filesystem | None | None |

### Flow 2: Inference Request - External Client

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | Istio Ingress Gateway | 443/TCP | HTTPS | TLS 1.3 | Bearer Token optional |
| 2 | Istio Gateway | Istio VirtualService | N/A | N/A | N/A | N/A |
| 3 | VirtualService | Knative Service | 80/TCP | HTTP | mTLS (Istio) | None |
| 4 | Knative Activator | Inference Server Pod | 8012/TCP | HTTP | mTLS (Istio) | None |
| 5 | Agent (optional) | Inference Server | 8080/TCP | HTTP | None | None |
| 6 | Inference Server | Response | N/A | N/A | N/A | N/A |

### Flow 3: Multi-Model Inference Graph

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | InferenceGraph Router | 8080/TCP | HTTP | TLS optional | Bearer Token optional |
| 2 | Router | Transformer Service | 80/TCP | HTTP | mTLS (Istio) | None |
| 3 | Router | Predictor-1 Service | 80/TCP | HTTP | mTLS (Istio) | None |
| 4 | Router | Predictor-2 Service | 80/TCP | HTTP | mTLS (Istio) | None |
| 5 | Router | Ensemble/Switch Logic | N/A | N/A | N/A | N/A |
| 6 | Router | Response | N/A | N/A | N/A | N/A |

### Flow 4: Request Logging

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Inference Server | Agent Sidecar | 8080/TCP | HTTP | None | None |
| 2 | Agent | Logger Endpoint | 80/TCP or 443/TCP | HTTP/HTTPS | TLS optional | Bearer Token optional |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Knative Serving | Kubernetes API (Knative Service CRs) | 6443/TCP | HTTPS | TLS 1.2+ | Serverless deployment with autoscaling and scale-to-zero |
| Istio | Kubernetes API (VirtualService CRs) | 6443/TCP | HTTPS | TLS 1.2+ | Traffic routing, canary deployments, mTLS enforcement |
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | CR reconciliation, resource management |
| Prometheus | HTTP scraping | 8080/TCP | HTTP | None | Metrics collection from inference servers |
| S3-compatible Storage | S3 API | 443/TCP | HTTPS | TLS 1.2+ | Model artifact storage and retrieval |
| GCS | GCS API | 443/TCP | HTTPS | TLS 1.2+ | Model artifact storage and retrieval |
| Azure Blob Storage | Azure API | 443/TCP | HTTPS | TLS 1.2+ | Model artifact storage and retrieval |
| cert-manager | Kubernetes API (Certificate CRs) | 6443/TCP | HTTPS | TLS 1.2+ | TLS certificate provisioning for webhooks |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| ae15d3843 | 2026-03 | - sync pipelineruns with konflux-central - 6d3ddaa |
| 02b249210 | 2026-03 | - sync pipelineruns with konflux-central - e46e5ce |
| b01a59dc3 | 2026-03 | - sync pipelineruns with konflux-central - c63b598 |

## Deployment Modes

KServe supports three deployment modes configured via the `inferenceservice-config` ConfigMap:

1. **Serverless (Default)**: Uses Knative Serving for autoscaling including scale-to-zero, requires Knative and Istio
2. **RawDeployment**: Standard Kubernetes Deployment with HPA, no Knative dependency, lightweight option
3. **ModelMesh**: High-density, multi-model serving for frequently changing models, separate ModelMesh installation required

## Model Serving Runtimes

Pre-configured ClusterServingRuntimes for various ML frameworks:

- **kserve-sklearnserver**: Scikit-learn models
- **kserve-xgbserver**: XGBoost models
- **kserve-lgbserver**: LightGBM models
- **kserve-tensorflow-serving**: TensorFlow SavedModel
- **kserve-torchserve**: PyTorch models via TorchServe
- **kserve-tritonserver**: NVIDIA Triton for multi-framework models
- **kserve-huggingfaceserver**: Hugging Face transformer models and LLMs
- **kserve-pmmlserver**: PMML models
- **kserve-paddleserver**: PaddlePaddle models
- **kserve-mlserver**: MLServer for SKLearn, XGBoost, LightGBM with v2 protocol

All runtimes expose port 8080/TCP for HTTP inference requests and support both v1 and v2 inference protocols.

## Storage Support

The storage-initializer component supports downloading models from:

- **S3-compatible** (s3://): AWS S3, MinIO, Ceph with IAM or access key authentication
- **GCS** (gs://): Google Cloud Storage with service account authentication
- **Azure Blob** (https://{account}.blob.core.windows.net/): Azure storage with account credentials
- **HTTP/HTTPS** (http://, https://): Generic web servers with optional basic auth
- **PVC** (pvc://): Kubernetes Persistent Volume Claims for local storage
- **Local filesystem** (file:// or absolute/relative paths): Direct filesystem access

## Observability

- **Metrics**: Prometheus metrics exposed on port 8080/TCP at /metrics endpoint
  - Latency histograms: request_preprocess_seconds, request_predict_seconds, request_postprocess_seconds, request_explain_seconds
  - Request counts, model loading metrics, batch size metrics
- **Logging**: Structured logging from controller and inference servers
  - Optional request/response logging to external endpoints via agent sidecar
- **Tracing**: Distributed tracing support via OpenTelemetry (when configured)
- **Health Checks**: Liveness (/healthz) and readiness (/readyz) probes on controller and inference servers
