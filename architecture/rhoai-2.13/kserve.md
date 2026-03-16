# Component: KServe

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kserve.git
- **Version**: v0.12.1 (rhoai-2.13 branch: 261e500ef)
- **Distribution**: RHOAI (Red Hat OpenShift AI fork of upstream KServe)
- **Languages**: Go (operator/controller), Python (storage initializer, model servers)
- **Deployment Type**: Kubernetes Operator with multiple runtime components

## Purpose
**Short**: Model serving platform providing Kubernetes-native serving infrastructure for machine learning models with autoscaling, monitoring, and multi-framework support.

**Detailed**: KServe is a Kubernetes Custom Resource Definition-based platform for serving machine learning models. It provides a standardized inference protocol across ML frameworks (TensorFlow, PyTorch, XGBoost, ScikitLearn, ONNX, etc.) with production-grade features including autoscaling (including scale-to-zero on CPU/GPU), canary rollouts, A/B testing, and inference pipelines via InferenceGraph. The platform integrates with Knative Serving for serverless deployment and Istio for advanced networking and traffic management. KServe abstracts the complexity of model deployment by providing a consistent API while supporting prediction, pre-processing, post-processing, and explainability workflows. In RHOAI, it serves as the primary model serving infrastructure for deployed ML models.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kserve-controller-manager | Kubernetes Operator | Reconciles InferenceService, InferenceGraph, TrainedModel, and ServingRuntime CRDs; manages deployments, services, and virtual services |
| kserve-agent | Sidecar Container | Provides model pulling, request/response logging, request batching, and health checking for inference workloads |
| kserve-router | Router Service | Routes and orchestrates requests through InferenceGraph workflows with step-by-step execution |
| kserve-storage-initializer | Init Container | Downloads model artifacts from storage backends (S3, GCS, PVC, HTTP) to shared volumes |
| Webhook Server | Admission Controller | Validates and mutates InferenceService, TrainedModel, ServingRuntime, and Pod resources |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Main API for deploying ML models with predictor, transformer, and explainer components |
| serving.kserve.io | v1alpha1 | InferenceGraph | Namespaced | Defines multi-step inference pipelines with routing logic (sequence, switch, ensemble) |
| serving.kserve.io | v1alpha1 | TrainedModel | Namespaced | Manages trained model artifacts and associates them with InferenceServices |
| serving.kserve.io | v1alpha1 | ClusterServingRuntime | Cluster | Cluster-scoped template defining container specs for specific model frameworks |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Namespace-scoped template defining container specs for specific model frameworks |
| serving.kserve.io | v1alpha1 | ClusterStorageContainer | Cluster | Cluster-scoped configuration for storage backend initialization containers |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /mutate-serving-kserve-io-v1beta1-inferenceservice | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Mutating webhook for InferenceService defaulting |
| /validate-serving-kserve-io-v1beta1-inferenceservice | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Validating webhook for InferenceService validation |
| /mutate-pods | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Mutating webhook to inject agent sidecar into inference pods |
| /validate-serving-kserve-io-v1alpha1-trainedmodel | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Validating webhook for TrainedModel validation |
| /validate-serving-kserve-io-v1alpha1-inferencegraph | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Validating webhook for InferenceGraph validation |
| /validate-serving-kserve-io-v1alpha1-clusterservingruntime | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Validating webhook for ClusterServingRuntime validation |
| /validate-serving-kserve-io-v1alpha1-servingruntime | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Validating webhook for ServingRuntime validation |
| /healthz | GET | 8081/TCP | HTTP | None | None | Controller liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Controller readiness probe |
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint for controller |
| :9081 | ALL | 9081/TCP | HTTP | None | Bearer Token (optional) | Agent proxy endpoint for inference traffic |
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint for model server containers |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| inference.GRPCInferenceService | 8081/TCP | gRPC/HTTP2 | None/TLS 1.2+ | None/mTLS | KServe v2 inference protocol (when gRPC enabled) |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.25+ | Yes | Platform for deploying and managing resources |
| Knative Serving | 0.39+ | Optional | Serverless deployment with autoscaling and scale-to-zero |
| Istio | 1.19+ | Optional | Service mesh for VirtualServices, traffic splitting, and advanced routing |
| cert-manager | Any | Recommended | Automatic TLS certificate provisioning for webhooks |
| Prometheus | Any | Optional | Metrics collection from controller and model servers |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| odh-model-controller | CRD Watch | Creates InferenceServices from ODH ServingRuntime resources |
| odh-dashboard | REST API | Dashboard displays and manages InferenceServices |
| Service Mesh (OSSM) | Istio VirtualService | Traffic routing, mTLS, and authorization policies for inference endpoints |
| Model Registry | Storage URI | References model artifacts stored in model registry |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kserve-controller-manager-service | ClusterIP | 8443/TCP | https | HTTPS | TLS 1.2+ | None | Internal |
| kserve-webhook-server-service | ClusterIP | 443/TCP | webhook-server (9443) | HTTPS | TLS 1.2+ | K8s API Server mTLS | Internal |
| {isvc-name}-predictor | ClusterIP | 80/TCP | 8080 | HTTP | None | None (Istio mTLS) | Internal |
| {isvc-name}-predictor-default (Knative) | ClusterIP | 80/TCP, 443/TCP | 8012, 8112 | HTTP/HTTPS | TLS 1.2+ (443) | Istio mTLS | Internal |
| {ig-name}-router | ClusterIP | 8080/TCP | 8080 | HTTP | None | Istio mTLS | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {isvc-name}-ingress (Istio Gateway) | Istio VirtualService | {isvc-name}.{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External via OpenShift Route |
| Knative Serving (Serverless) | Knative Route | {isvc-name}.{namespace}.svc.cluster.local | 80/TCP, 443/TCP | HTTP/HTTPS | TLS 1.2+ | PASSTHROUGH | Internal/External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| S3 Storage (AWS/Minio) | 443/TCP | HTTPS | TLS 1.2+ | AWS Signature v4 | Download model artifacts during initialization |
| Google Cloud Storage | 443/TCP | HTTPS | TLS 1.2+ | GCP Service Account | Download model artifacts during initialization |
| HTTP(S) URLs | 80/TCP, 443/TCP | HTTP/HTTPS | TLS 1.2+ (HTTPS) | None/Bearer | Download models from HTTP endpoints |
| CloudEvents Sink | 80/TCP, 443/TCP | HTTP/HTTPS | TLS 1.2+ (HTTPS) | None/Bearer | Send request/response logs to external sinks |
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token | Watch CRDs, create/update resources |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kserve-manager-role | serving.kserve.io | inferenceservices, inferenceservices/finalizers, inferenceservices/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | inferencegraphs, inferencegraphs/finalizers, inferencegraphs/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | trainedmodels, trainedmodels/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | clusterservingruntimes, clusterservingruntimes/finalizers, clusterservingruntimes/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | servingruntimes, servingruntimes/finalizers, servingruntimes/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | clusterstoragecontainers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.knative.dev | services, services/finalizers, services/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | networking.istio.io | virtualservices, virtualservices/finalizers, virtualservices/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | "" (core) | services, secrets, configmaps, events | create, delete, get, list, patch, update, watch |
| kserve-manager-role | "" (core) | namespaces, pods, serviceaccounts | get, list, watch |
| kserve-manager-role | apps | deployments | create, delete, get, list, patch, update, watch |
| kserve-manager-role | autoscaling | horizontalpodautoscalers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | networking.k8s.io | ingresses | create, delete, get, list, patch, update, watch |
| kserve-manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | create, delete, get, list, patch, update, watch |
| kserve-leader-election-role | "" (core) | configmaps | get, create, update |
| kserve-proxy-role | authentication.k8s.io | tokenreviews | create |
| kserve-proxy-role | authorization.k8s.io | subjectaccessreviews | create |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kserve-manager-rolebinding | All namespaces (ClusterRoleBinding) | kserve-manager-role | kserve-controller-manager (kserve namespace) |
| kserve-leader-election-rolebinding | kserve | kserve-leader-election-role | kserve-controller-manager |
| kserve-proxy-rolebinding | kserve | kserve-proxy-role | kserve-controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| kserve-webhook-server-cert | kubernetes.io/tls | TLS certificate for admission webhooks | cert-manager | Yes |
| kserve-webhook-server-secret | Opaque | Additional webhook configuration secrets | KServe Operator | No |
| storage-config | Opaque | S3/GCS credentials for storage initializer | User/Admin | No |
| {custom}-sa-token | kubernetes.io/service-account-token | Service account tokens for inference pods | Kubernetes | Yes (rotation enabled) |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| Admission Webhooks (/mutate-*, /validate-*) | POST | Kubernetes API Server mTLS | kube-apiserver | API server validates webhook server certificate |
| Inference Endpoints (predictor services) | POST, GET | Istio mTLS (service mesh) | Envoy sidecar | AuthorizationPolicy enforces namespace isolation |
| Agent Proxy (:9081) | ALL | Optional Bearer Token | kserve-agent | Token validation if logging/metrics enabled |
| Controller Metrics (/metrics:8080) | GET | None (internal) | Network Policy | Pod-to-pod network restrictions |
| Storage Backend (S3/GCS) | GET, HEAD | AWS Signature v4 / GCP IAM | Storage Provider | Credentials from mounted secrets |

## Data Flows

### Flow 1: InferenceService Creation and Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/ODH Dashboard | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (user SA) |
| 2 | Kubernetes API Server | kserve-webhook-server | 9443/TCP | HTTPS | TLS 1.2+ | mTLS |
| 3 | kserve-webhook-server | Kubernetes API Server (response) | - | HTTPS | TLS 1.2+ | mTLS |
| 4 | kserve-controller | Kubernetes API Server (watch) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) |
| 5 | kserve-controller | Kubernetes API Server (create resources) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) |

### Flow 2: Model Initialization and Serving

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | storage-initializer (init) | S3/GCS/HTTP | 443/TCP | HTTPS | TLS 1.2+ | AWS SigV4 / GCP IAM / Bearer |
| 2 | storage-initializer (init) | Shared EmptyDir Volume | - | Filesystem | None | None |
| 3 | Model Server Container | Shared EmptyDir Volume | - | Filesystem | None | None |
| 4 | Model Server Container | Agent Sidecar | 8080/TCP | HTTP | None | None (localhost) |
| 5 | Agent Sidecar | External (readiness probe) | 9081/TCP | HTTP | None | None |

### Flow 3: Inference Request (via Istio/Knative)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | OpenShift Router/Istio Gateway | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (optional) |
| 2 | Istio Gateway | Istio VirtualService | 443/TCP | HTTPS | TLS 1.2+ | Istio mTLS |
| 3 | Istio VirtualService | Knative Service (activator) | 80/TCP | HTTP | Istio mTLS | Istio AuthorizationPolicy |
| 4 | Knative Activator | Agent Sidecar (queue-proxy) | 8012/TCP | HTTP | Istio mTLS | None |
| 5 | Agent Sidecar | Model Server Container | 8080/TCP | HTTP | None | None (localhost) |
| 6 | Agent Sidecar (optional) | CloudEvents Sink | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |

### Flow 4: InferenceGraph Router Workflow

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | InferenceGraph Router Service | 8080/TCP | HTTP | Istio mTLS | Istio AuthorizationPolicy |
| 2 | Router | Step 1 InferenceService | 80/TCP | HTTP | Istio mTLS | None |
| 3 | Step 1 InferenceService | Step 1 Model Server | 8080/TCP | HTTP | None | None (localhost) |
| 4 | Router | Step 2 InferenceService | 80/TCP | HTTP | Istio mTLS | None |
| 5 | Router | External Client (response) | 8080/TCP | HTTP | Istio mTLS | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Knative Serving | CRD API (serving.knative.dev/v1) | 6443/TCP | HTTPS | TLS 1.2+ | Controller creates Knative Services for serverless autoscaling |
| Istio | CRD API (networking.istio.io/v1beta1) | 6443/TCP | HTTPS | TLS 1.2+ | Controller creates VirtualServices for traffic routing and canary |
| Kubernetes API Server | Watch/CRUD Operations | 6443/TCP | HTTPS | TLS 1.2+ | Reconcile CRDs, create Deployments, Services, ConfigMaps, Secrets |
| Prometheus | Metrics Scraping | 8080/TCP | HTTP | None | Scrapes controller and model server metrics |
| S3 Compatible Storage | S3 API | 443/TCP | HTTPS | TLS 1.2+ | Download model artifacts with AWS SDK |
| Google Cloud Storage | GCS API | 443/TCP | HTTPS | TLS 1.2+ | Download model artifacts with GCP SDK |
| CloudEvents Sinks | CloudEvents v1.0 | 80/TCP, 443/TCP | HTTP/HTTPS | TLS 1.2+ (HTTPS) | Send inference request/response logs |
| Model Registry | Storage URI References | Varies | Varies | Varies | Retrieve model artifact locations |
| cert-manager | Certificate CRD | 6443/TCP | HTTPS | TLS 1.2+ | Automatic certificate provisioning for webhooks |

## Recent Changes

| Version/Commit | Date | Changes |
|----------------|------|---------|
| 261e500ef | 2024 | - Update kserve-agent image sha |
| a13da4361 | 2024 | - Update kserve-storage-initializer-213 to d80bc72 |
| 80edb3293 | 2024 | - Update kserve-controller-213 to bfa0e8c |
| cabc558f2 | 2024 | - Update kserve-router-213 to 4fbb998 |
| b4e0f7c67 | 2024 | - [RHOAIENG-14313] KServe - Type Confusion security fix [rhoai-2.13] |
| 1c5fb349e | 2024 | - Fix apiGroups in aggregate roles on manifests |
| d6d458abf | 2024 | - Merge remote-tracking branch 'upstream/master' into rhoai-2.13 |
| 2f65fc58b | 2024 | - Merge remote-tracking branch 'upstream/release-v0.12.1' |

## Deployment Architecture

### Component Container Images (RHOAI 2.13)

| Component | Registry | Built By | Base Image |
|-----------|----------|----------|------------|
| kserve-controller | quay.io/modh/kserve-controller | Konflux CI | registry.access.redhat.com/ubi8/ubi-minimal:latest |
| kserve-agent | quay.io/modh/kserve-agent | Konflux CI | registry.access.redhat.com/ubi8/ubi-minimal:latest |
| kserve-router | quay.io/modh/kserve-router | Konflux CI | registry.access.redhat.com/ubi8/ubi-minimal:latest |
| kserve-storage-initializer | quay.io/modh/kserve-storage-initializer | Konflux CI | registry.access.redhat.com/ubi8/ubi-minimal:latest |

### Deployment Model

KServe follows a **multi-layer deployment model**:

1. **Control Plane**: kserve-controller-manager Deployment in `kserve` namespace (or configured namespace) watches CRDs and reconciles infrastructure
2. **Data Plane - Serverless (Knative)**: InferenceServices deployed as Knative Services with autoscaling (0-N pods)
3. **Data Plane - Raw Kubernetes**: InferenceServices deployed as standard Deployments without Knative
4. **Router Plane**: InferenceGraph router Deployments orchestrate multi-step inference workflows
5. **Storage Initialization**: Init containers in inference pods download models before serving starts

### Configuration Management

- **ConfigMap**: `inferenceservice-config` in `kserve` namespace contains global settings (storage initializer config, explainer images, runtime defaults)
- **ClusterServingRuntime CRs**: Define available model serving frameworks (TensorFlow, PyTorch, SKLearn, etc.)
- **ServingRuntime CRs**: Namespace-scoped runtime definitions
- **ODH Overlays**: RHOAI-specific customizations in `config/overlays/odh/` (image references, resource limits)

## Model Serving Runtimes Supported

KServe includes built-in serving runtimes for:
- **HuggingFace** (Transformers, NLP models)
- **LightGBM** (Gradient boosting)
- **MLServer** (Multi-framework: SKLearn, XGBoost, LightGBM, MLflow)
- **Paddle** (PaddlePaddle)
- **PMML** (Predictive Model Markup Language)
- **SKLearn** (Scikit-learn)
- **TensorFlow** (via TFServing)
- **PyTorch** (via TorchServe)
- **XGBoost**
- **ONNX** (Open Neural Network Exchange)
- **Custom** (user-defined containers implementing KServe protocol)

Each runtime is defined as a ClusterServingRuntime with container specs, supported model formats, and protocol versions (v1/v2).
