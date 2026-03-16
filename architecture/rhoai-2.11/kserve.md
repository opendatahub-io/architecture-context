# Component: KServe

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kserve.git
- **Version**: 0.12.1
- **Branch**: rhoai-2.11
- **Distribution**: RHOAI (Red Hat OpenShift AI)
- **Languages**: Go (operator/controllers), Python (model servers, storage initializer)
- **Deployment Type**: Kubernetes Operator
- **Build System**: Konflux (Tekton pipelines in `.tekton/`)

## Purpose
**Short**: KServe is a Kubernetes operator that provides a standardized, cloud-agnostic platform for serving machine learning models with support for autoscaling, multi-framework inference, and advanced deployment strategies.

**Detailed**: KServe provides Custom Resource Definitions (CRDs) and controllers for deploying machine learning models on Kubernetes. It abstracts the complexity of model serving by managing the entire lifecycle including storage initialization, model loading, autoscaling (including scale-to-zero), networking configuration, and health checking. The platform supports multiple ML frameworks (TensorFlow, PyTorch, XGBoost, Scikit-learn, ONNX, etc.) through pluggable serving runtimes and provides both REST and gRPC inference protocols. KServe integrates deeply with Knative Serving for serverless deployment, Istio for traffic management, and supports advanced features like canary rollouts, inference graphs (model chaining/ensembles), explainability, and request/response transformations. The operator manages InferenceServices which can include predictor, transformer, and explainer components, along with storage initialization and model routing capabilities.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kserve-controller-manager | Go Operator | Main controller reconciling InferenceServices, ServingRuntimes, InferenceGraphs, and TrainedModels |
| kserve-webhook-server | Go Webhook Server | Admission webhooks for validating and mutating InferenceService/Pod resources |
| kserve-agent | Go Sidecar | Agent injected into inference pods for model pulling, logging, and batching |
| kserve-router | Go Router | Routes requests in InferenceGraphs for model chaining and ensembles |
| storage-initializer | Python Init Container | Downloads models from cloud storage (S3, GCS, Azure, etc.) to model serving pods |
| Model Servers | Python | Framework-specific inference servers (sklearn, xgboost, lgb, paddle, pmml, huggingface) |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Primary resource for deploying ML models with predictor/transformer/explainer components |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Defines container specs and configurations for serving specific model formats |
| serving.kserve.io | v1alpha1 | ClusterServingRuntime | Cluster | Cluster-scoped serving runtime templates for model formats (sklearn, xgboost, etc.) |
| serving.kserve.io | v1alpha1 | InferenceGraph | Namespaced | Defines DAG of inference steps for model chaining, ensembles, and routing |
| serving.kserve.io | v1alpha1 | TrainedModel | Namespaced | Represents individual model versions for multi-model serving scenarios |
| serving.kserve.io | v1alpha1 | ClusterStorageContainer | Cluster | Defines storage initialization containers for different storage protocols |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Controller manager liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Controller manager readiness probe |
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for controller manager |
| /mutate-serving-kserve-io-v1beta1-inferenceservice | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Mutating webhook for InferenceService |
| /validate-serving-kserve-io-v1beta1-inferenceservice | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook for InferenceService |
| /mutate-pods | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Mutating webhook for pod injection (agent sidecar) |
| /validate-serving-kserve-io-v1alpha1-trainedmodel | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook for TrainedModel |
| /validate-serving-kserve-io-v1alpha1-inferencegraph | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook for InferenceGraph |
| /validate-serving-kserve-io-v1alpha1-servingruntime | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook for ServingRuntime |

### Model Inference Endpoints (Created by InferenceServices)

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /v1/models/{model}:predict | POST | 8080/TCP | HTTP/HTTPS | TLS via Istio | Bearer/mTLS | V1 inference protocol prediction endpoint |
| /v1/models/{model}:explain | POST | 8080/TCP | HTTP/HTTPS | TLS via Istio | Bearer/mTLS | V1 model explanation endpoint |
| /v1/models/{model} | GET | 8080/TCP | HTTP/HTTPS | TLS via Istio | Bearer/mTLS | V1 model metadata endpoint |
| /v2/models/{model}/infer | POST | 8080/TCP | HTTP/HTTPS | TLS via Istio | Bearer/mTLS | V2 inference protocol inference endpoint |
| /v2/models/{model}/ready | GET | 8080/TCP | HTTP/HTTPS | TLS via Istio | Bearer/mTLS | V2 model readiness check |
| /v2/models/{model} | GET | 8080/TCP | HTTP/HTTPS | TLS via Istio | Bearer/mTLS | V2 model metadata endpoint |
| /v2/health/live | GET | 8080/TCP | HTTP/HTTPS | TLS via Istio | Bearer/mTLS | V2 server liveness endpoint |
| /v2/health/ready | GET | 8080/TCP | HTTP/HTTPS | TLS via Istio | Bearer/mTLS | V2 server readiness endpoint |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| inference.GRPCInferenceService | 8081/TCP | gRPC/HTTP2 | TLS via Istio | mTLS | V2 gRPC inference protocol for model serving |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.25+ | Yes | Container orchestration platform |
| Knative Serving | 0.39.3 | Yes | Serverless request-based autoscaling and revision management |
| Istio | 1.19.4 | Yes | Service mesh for traffic routing, VirtualServices, and mTLS |
| cert-manager | Latest | Yes | TLS certificate management for webhooks |
| Prometheus | Latest | No | Metrics collection from model servers and controller |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Service Mesh (Istio) | VirtualService CRD | Creates Istio VirtualServices for inference endpoint routing and canary deployments |
| Model Registry | External API | References stored model artifacts and metadata |
| S3 Storage | S3 API | Downloads model artifacts from object storage during initialization |
| Monitoring | Prometheus API | Exposes inference metrics, latency, and throughput to cluster monitoring |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kserve-controller-manager-service | ClusterIP | 8443/TCP | https | HTTPS | TLS 1.2+ | mTLS | Internal |
| kserve-webhook-server-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | mTLS | Internal |
| {isvc-name}-predictor | ClusterIP | 80/TCP | 8080 | HTTP | TLS via Istio | Bearer/mTLS | Internal/External via Istio Gateway |
| {isvc-name}-transformer | ClusterIP | 80/TCP | 8080 | HTTP | TLS via Istio | Bearer/mTLS | Internal |
| {isvc-name}-explainer | ClusterIP | 80/TCP | 8080 | HTTP | TLS via Istio | Bearer/mTLS | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {isvc-name} VirtualService | Istio VirtualService | {isvc-name}.{namespace}.svc.cluster.local | 80/TCP | HTTP/HTTPS | TLS 1.2+ | ISTIO_MUTUAL | Internal |
| Knative Route | Knative Route | {isvc-name}.{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE/MUTUAL | External via Istio Gateway |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| S3 endpoints | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Access Keys | Download model artifacts during storage initialization |
| GCS endpoints | 443/TCP | HTTPS | TLS 1.2+ | GCP Service Account | Download model artifacts from Google Cloud Storage |
| Azure Blob Storage | 443/TCP | HTTPS | TLS 1.2+ | Azure credentials | Download model artifacts from Azure storage |
| HTTP(S) servers | 80,443/TCP | HTTP/HTTPS | TLS 1.2+ | None/Basic/Bearer | Download models from generic HTTP endpoints |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kserve-manager-role | serving.kserve.io | inferenceservices, inferenceservices/finalizers, inferenceservices/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | servingruntimes, servingruntimes/finalizers, servingruntimes/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | clusterservingruntimes, clusterservingruntimes/finalizers, clusterservingruntimes/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | inferencegraphs, inferencegraphs/finalizers, inferencegraphs/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | trainedmodels, trainedmodels/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | clusterstoragecontainers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.knative.dev | services, services/finalizers, services/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | networking.istio.io | virtualservices, virtualservices/finalizers, virtualservices/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | apps | deployments | create, delete, get, list, patch, update, watch |
| kserve-manager-role | autoscaling | horizontalpodautoscalers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | "" (core) | services, secrets, configmaps, pods, namespaces, events, serviceaccounts | various |
| kserve-manager-role | networking.k8s.io | ingresses | create, delete, get, list, patch, update, watch |
| kserve-manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | create, delete, get, list, patch, update, watch |
| kserve-leader-election-role | "" (core) | configmaps, leases | get, create, update |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kserve-manager-rolebinding | - (cluster) | kserve-manager-role (ClusterRole) | kserve-controller-manager (kserve namespace) |
| kserve-leader-election-rolebinding | kserve | kserve-leader-election-role (Role) | kserve-controller-manager (kserve namespace) |
| kserve-proxy-rolebinding | - (cluster) | kserve-proxy-role (ClusterRole) | kserve-controller-manager (kserve namespace) |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| kserve-webhook-server-cert | kubernetes.io/tls | TLS certificate for admission webhooks | cert-manager | Yes |
| kserve-webhook-server-secret | Opaque | Webhook server secret placeholder | KServe installation | No |
| storage-config | Opaque | S3/GCS/Azure credentials for model downloads | User/Admin | No |
| {custom}-sa-token | kubernetes.io/service-account-token | Service account tokens for inference pods | Kubernetes | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| Webhook endpoints (/mutate-*, /validate-*) | POST | mTLS client certificates | kube-apiserver | Kubernetes API server validates client certs |
| Inference endpoints (/v1/models/*, /v2/*) | GET, POST | Bearer Token/mTLS | Istio AuthorizationPolicy | Configured via Istio/ServiceMesh policies |
| Controller metrics (/metrics) | GET | None | Network Policy | Internal cluster access only |
| Health probes (/healthz, /readyz) | GET | None | Kubernetes | Kubelet access for health checking |

### Network Policies

| Policy Name | Pod Selector | Ingress Rules | Egress Rules |
|-------------|--------------|---------------|--------------|
| kserve-controller-manager | control-plane: kserve-controller-manager | Allow all ingress | Not specified (allow all) |

## Data Flows

### Flow 1: InferenceService Creation and Model Serving

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Client | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (kubeconfig) |
| 2 | Kubernetes API Server | kserve-webhook-server | 443/TCP | HTTPS | TLS 1.2+ | mTLS |
| 3 | kserve-controller-manager | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 4 | storage-initializer (init container) | S3/GCS/Azure | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/GCP SA/Azure creds |
| 5 | Client | Istio Gateway | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token/mTLS |
| 6 | Istio Gateway | Knative Service (InferenceService predictor) | 80/TCP | HTTP | mTLS | Istio mutual TLS |
| 7 | Model Server | Prometheus | 8080/TCP | HTTP | None | None |

### Flow 2: InferenceGraph Request Routing

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | Istio Gateway | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Istio Gateway | kserve-router | 8080/TCP | HTTP | mTLS | Istio mutual TLS |
| 3 | kserve-router | InferenceService 1 (transformer) | 80/TCP | HTTP | mTLS | Istio mutual TLS |
| 4 | InferenceService 1 | InferenceService 2 (predictor) | 80/TCP | HTTP | mTLS | Istio mutual TLS |
| 5 | InferenceService 2 | kserve-router | 80/TCP | HTTP | mTLS | Istio mutual TLS |
| 6 | kserve-router | Client (via Istio) | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |

### Flow 3: Storage Initialization

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | storage-initializer (init) | S3 bucket | 443/TCP | HTTPS | TLS 1.2+ | AWS Access Keys/IAM Role |
| 2 | storage-initializer | Local filesystem (/mnt/models) | - | Filesystem | None | POSIX permissions |
| 3 | Model server container | Local filesystem (/mnt/models) | - | Filesystem | None | Shared emptyDir volume |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Knative Serving | Kubernetes API (CRD) | 6443/TCP | HTTPS | TLS 1.2+ | Creates Knative Services for serverless autoscaling and revisions |
| Istio | Kubernetes API (CRD) | 6443/TCP | HTTPS | TLS 1.2+ | Creates VirtualServices for traffic routing and canary deployments |
| cert-manager | Kubernetes API (CRD) | 6443/TCP | HTTPS | TLS 1.2+ | Provisions and rotates TLS certificates for webhooks |
| Prometheus | HTTP API | 8080/TCP | HTTP | None | Scrapes metrics from model servers and controller |
| S3-compatible storage | S3 API | 443/TCP | HTTPS | TLS 1.2+ | Downloads model artifacts during pod initialization |
| Model Registry | HTTP API | 443/TCP | HTTPS | TLS 1.2+ | Retrieves model metadata and artifact locations |

## Container Images (Built via Konflux)

| Image Name | Dockerfile | Purpose | Base Image |
|------------|------------|---------|------------|
| kserve-controller | Dockerfile | Main controller manager | registry.access.redhat.com/ubi8/ubi-minimal |
| kserve-agent | agent.Dockerfile | Inference pod sidecar agent | registry.access.redhat.com/ubi8/ubi-minimal |
| kserve-router | router.Dockerfile | InferenceGraph router | registry.access.redhat.com/ubi8/ubi-minimal |
| storage-initializer | python/storage-initializer.Dockerfile | Model download init container | registry.access.redhat.com/ubi8/ubi-minimal |
| kserve-sklearnserver | python/sklearn.Dockerfile | Scikit-learn model server | registry.access.redhat.com/ubi8/python-39 |
| kserve-xgbserver | python/xgb.Dockerfile | XGBoost model server | registry.access.redhat.com/ubi8/python-39 |
| kserve-lgbserver | python/lgb.Dockerfile | LightGBM model server | registry.access.redhat.com/ubi8/python-39 |

## Configuration

### ConfigMaps

| ConfigMap Name | Namespace | Purpose | Key Configuration |
|----------------|-----------|---------|-------------------|
| inferenceservice-config | kserve | Global InferenceService configuration | Storage initializer settings, explainer configs, runtime defaults, credentials config |

### Key Configuration Parameters

| Parameter | Location | Default | Purpose |
|-----------|----------|---------|---------|
| storageInitializer.image | inferenceservice-config | kserve/storage-initializer:latest | Storage initializer container image |
| storageInitializer.memoryRequest | inferenceservice-config | 100Mi | Memory request for storage init container |
| storageInitializer.cpuRequest | inferenceservice-config | 100m | CPU request for storage init container |
| explainers.alibi.image | inferenceservice-config | kserve/alibi-explainer | Alibi explainer runtime image |
| credentials.s3.s3Endpoint | inferenceservice-config | - | S3 endpoint URL for model downloads |

## Deployment Architecture

KServe follows a **multi-component operator pattern** with the following deployment model:

1. **Controller Manager**: Single replica deployment in `kserve` namespace with leader election support
2. **Webhooks**: Co-located with controller manager, exposed via ClusterIP service
3. **Per-InferenceService Components**: Each InferenceService creates:
   - Knative Service (managed by Knative) for serverless deployment
   - Istio VirtualService for traffic routing
   - Storage initializer init container in inference pods
   - Optional: Agent sidecar for advanced features
   - Optional: Transformer and explainer services

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 0.12.1 | 2024-Q1 | - Stable release for RHOAI 2.11<br>- Konflux-based build pipeline<br>- Support for multiple model formats via ClusterServingRuntime<br>- InferenceGraph for model chaining |

## Notes

- **Serverless Architecture**: KServe heavily relies on Knative Serving for request-based autoscaling, including scale-to-zero capability
- **Service Mesh Integration**: Istio is required for production deployments to enable traffic splitting, canary rollouts, and mTLS
- **Storage Flexibility**: Supports S3, GCS, Azure Blob Storage, PVC, and HTTP(S) for model artifacts
- **Protocol Support**: Implements both V1 (TensorFlow Serving-like) and V2 (KServe standard) inference protocols
- **Multi-Framework**: Pluggable serving runtime architecture supports any ML framework via container images
- **Raw Deployment Mode**: Can optionally deploy without Knative using standard Kubernetes Deployments (loses serverless features)
- **Model Chaining**: InferenceGraph allows complex workflows with multiple models in sequence or parallel
