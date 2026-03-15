# Component: KServe

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kserve.git
- **Version**: 27c1e99b7
- **Branch**: rhoai-3.2
- **Distribution**: RHOAI (Red Hat OpenShift AI)
- **Languages**: Go, Python
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Model inference platform for serving predictive and generative AI models on Kubernetes with autoscaling and advanced deployment features.

**Detailed**: KServe is a Kubernetes-native model serving platform that provides standardized inference protocols for machine learning models. It offers high-abstraction interfaces for TensorFlow, XGBoost, ScikitLearn, PyTorch, and Hugging Face models. The platform encapsulates autoscaling (including GPU autoscaling and scale-to-zero), networking, health checking, and server configuration complexity. It supports serverless inference with Knative, raw Kubernetes deployments, and ModelMesh for high-density serving. KServe enables production ML serving including prediction, pre-processing, post-processing, explainability, canary rollouts, multi-model serving graphs, and A/B testing through InferenceGraph resources.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kserve-controller-manager | Kubernetes Operator | Main reconciliation controller managing InferenceService, ServingRuntime, and InferenceGraph CRDs |
| agent | Sidecar Container | Provides request logging, batching, and model agent capabilities for inference services |
| router | Routing Service | Implements InferenceGraph request routing with header propagation and load balancing |
| storage-initializer | Init Container | Downloads and mounts ML models from cloud storage (S3, GCS, PVC, OCI) before inference container starts |
| localmodel-manager | Controller | Manages local model caching on nodes for improved performance |
| localmodelnode-agent | DaemonSet Agent | Node-level agent for local model cache management and reconciliation |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Defines ML model serving deployments with predictor, transformer, and explainer components |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Defines model server runtime templates (e.g., TensorFlow Serving, Triton, vLLM) for specific model formats |
| serving.kserve.io | v1alpha1 | ClusterServingRuntime | Cluster | Cluster-scoped serving runtime templates available to all namespaces |
| serving.kserve.io | v1alpha1 | ClusterStorageContainer | Cluster | Defines storage initialization containers for custom storage backends |
| serving.kserve.io | v1alpha1 | InferenceGraph | Namespaced | Defines multi-step inference pipelines with routing, ensembles, and transformations |
| serving.kserve.io | v1alpha1 | TrainedModel | Namespaced | Represents individual trained models for multi-model serving scenarios |
| serving.kserve.io | v1alpha1 | LLMInferenceService | Namespaced | Specialized inference service for large language models with disaggregated serving architecture |
| serving.kserve.io | v1alpha1 | LLMInferenceServiceConfig | Namespaced | Configuration templates for LLM inference services (router, scheduler, workers) |
| serving.kserve.io | v1alpha1 | LocalModelCache | Namespaced | Manages local model caching on nodes for faster model loading |
| serving.kserve.io | v1alpha1 | LocalModelNode | Namespaced | Represents a node in the local model cache system |
| serving.kserve.io | v1alpha1 | LocalModelNodeGroup | Namespaced | Groups nodes for local model cache management |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Controller liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Controller readiness probe |
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint |
| /validate-* | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Webhook validation for CRD create/update operations |
| /mutate-* | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Webhook mutation for CRD defaulting and injection |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | KServe controller does not expose gRPC services directly (inference services may expose gRPC) |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.28+ | Yes | Container orchestration platform |
| Knative Serving | 0.44.0 | Optional | Serverless deployment mode with autoscaling and scale-to-zero |
| Istio | 1.24+ | Optional | Service mesh for routing, mTLS, and traffic splitting |
| KEDA | 2.16+ | Optional | Event-driven autoscaling for raw deployments |
| cert-manager | Latest | Optional | TLS certificate management (alternative: OpenShift service CA) |
| Gateway API | 1.2.1 | Optional | Modern ingress routing (alternative to Istio VirtualService) |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Service Mesh (Istio) | VirtualService, DestinationRule | Traffic routing, mTLS, authorization policies for inference endpoints |
| OpenShift OAuth | ServiceAccount tokens | Authentication for inference service access in multi-tenant environments |
| Authorino | AuthorizationPolicy | Token-based authorization for inference endpoints |
| ODH Dashboard | REST API | Model serving UI integration and InferenceService lifecycle management |
| Model Registry | REST API | Model metadata and versioning integration |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kserve-controller-manager-service | ClusterIP | 8443/TCP | https | HTTPS | TLS 1.2+ | None | Internal |
| kserve-webhook-server-service | ClusterIP | 443/TCP | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Internal |
| <isvc-name>-predictor | ClusterIP | 80/TCP, 443/TCP | 8080/TCP | HTTP/HTTPS | TLS (Istio sidecar) | Bearer/mTLS | Internal/External |
| <isvc-name>-transformer | ClusterIP | 80/TCP, 443/TCP | 8080/TCP | HTTP/HTTPS | TLS (Istio sidecar) | Bearer/mTLS | Internal |
| <isvc-name>-explainer | ClusterIP | 80/TCP, 443/TCP | 8080/TCP | HTTP/HTTPS | TLS (Istio sidecar) | Bearer/mTLS | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| Istio VirtualService | Istio VirtualService | <isvc>-<namespace>.<domain> | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External |
| Knative Service Route | Knative Route | <isvc>-<namespace>.<domain> | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External |
| Gateway API HTTPRoute | HTTPRoute | <isvc>-<namespace>.<domain> | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External |
| OpenShift Route | Route | <isvc>-<namespace>.apps.<cluster> | 443/TCP | HTTPS | TLS 1.2+ (edge) | Edge | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| S3 Storage Endpoints | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Access Keys | Model artifact downloads from S3-compatible storage |
| GCS Storage Endpoints | 443/TCP | HTTPS | TLS 1.2+ | GCP Service Account | Model artifact downloads from Google Cloud Storage |
| Container Registries | 443/TCP | HTTPS | TLS 1.2+ | Pull Secrets | Pulling model server container images |
| Knative Serving API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Creating and managing Knative Services for serverless mode |
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | CRD reconciliation and resource management |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kserve-manager-role | serving.kserve.io | inferenceservices, servingruntimes, clusterservingruntimes, inferencegraphs, trainedmodels, llminferenceservices | create, delete, get, list, patch, update, watch |
| kserve-manager-role | "" | services, secrets, serviceaccounts, configmaps, events | create, delete, get, list, patch, update, watch |
| kserve-manager-role | apps | deployments | create, delete, get, list, patch, update, watch |
| kserve-manager-role | autoscaling | horizontalpodautoscalers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.knative.dev | services | create, delete, get, list, patch, update, watch |
| kserve-manager-role | networking.istio.io | virtualservices, destinationrules | create, delete, get, list, patch, update, watch |
| kserve-manager-role | gateway.networking.k8s.io | gateways, httproutes | create, delete, get, list, patch, update, watch |
| kserve-manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| kserve-manager-role | keda.sh | scaledobjects | create, delete, get, list, patch, update, watch |
| kserve-manager-role | monitoring.coreos.com | servicemonitors, podmonitors | create, delete, get, list, patch, update, watch |
| kserve-manager-role | admissionregistration.k8s.io | validatingwebhookconfigurations, mutatingwebhookconfigurations | create, delete, get, list, patch, update, watch |
| kserve-manager-role | rbac.authorization.k8s.io | rolebindings, roles | create, delete, get, list, patch, update, watch |
| kserve-manager-role | opentelemetry.io | opentelemetrycollectors | create, delete, get, list, patch, update, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kserve-manager-rolebinding | kserve | kserve-manager-role | kserve-controller-manager |
| kserve-leader-election-rolebinding | kserve | kserve-leader-election-role | kserve-controller-manager |
| kserve-proxy-rolebinding | kserve | kserve-proxy-role | kserve-controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| kserve-webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificate for admission webhooks | cert-manager or service-ca-operator | Yes |
| kserve-webhook-server-secret | Opaque | Webhook server configuration secrets | KServe controller | No |
| storage-config | Opaque | Cloud storage credentials (S3, GCS) for model downloads | User/Admin | No |
| <sa-name>-dockercfg-* | kubernetes.io/dockerconfigjson | Container image pull secrets for private registries | Kubernetes/OpenShift | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| Webhook endpoints (/validate-*, /mutate-*) | POST | mTLS client certificates | kube-apiserver | API server validates webhook TLS certificate |
| Inference Service endpoints | GET, POST | Bearer Token (JWT) | Istio/Authorino | AuthorizationPolicy validates tokens via OIDC |
| Inference Service endpoints (internal) | GET, POST | mTLS (service-to-service) | Istio sidecar | PeerAuthentication enforces STRICT mTLS mode |
| Metrics endpoint (/metrics) | GET | None (internal only) | NetworkPolicy | Restricted to ServiceMonitor scraping |

## Data Flows

### Flow 1: Model Deployment via InferenceService

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (ServiceAccount/User) |
| 2 | kube-apiserver | kserve-webhook-server | 9443/TCP | HTTPS | TLS 1.2+ (mTLS) | mTLS client cert |
| 3 | kserve-controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | kserve-controller | Knative API / K8s Deployment API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | storage-initializer (init container) | S3/GCS endpoint | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM / GCP Service Account |

### Flow 2: Inference Request (Serverless Mode)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | Istio Ingress Gateway | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (optional) |
| 2 | Istio Gateway | Knative Activator / Predictor Pod | 8012/TCP or 8080/TCP | HTTP | mTLS (Istio) | mTLS + Bearer Token |
| 3 | Predictor Pod | Model Server Container | 8080/TCP | HTTP | None (localhost) | None |
| 4 | Predictor (if transformer) | Transformer Service | 8080/TCP | HTTP | mTLS (Istio) | mTLS |
| 5 | Transformer | Predictor Service | 8080/TCP | HTTP | mTLS (Istio) | mTLS |

### Flow 3: InferenceGraph Multi-Step Routing

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | Router Service | 8080/TCP | HTTP | mTLS (Istio) | Bearer Token |
| 2 | Router | Step 1 InferenceService | 8080/TCP | HTTP | mTLS (Istio) | Propagated Headers |
| 3 | Router | Step 2 InferenceService | 8080/TCP | HTTP | mTLS (Istio) | Propagated Headers |
| 4 | Router | Client | 8080/TCP | HTTP | mTLS (Istio) | None |

### Flow 4: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | kserve-controller-manager | 8080/TCP | HTTP | None | None (NetworkPolicy restricted) |
| 2 | Prometheus | Inference Service Pods | 8080/TCP or 9090/TCP | HTTP | None | ServiceMonitor scraping |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Knative Serving | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Serverless deployment with autoscaling and scale-to-zero |
| Istio | CRD (VirtualService, DestinationRule) | 6443/TCP | HTTPS | TLS 1.2+ | Traffic routing, mTLS, canary deployments, A/B testing |
| KEDA | CRD (ScaledObject) | 6443/TCP | HTTPS | TLS 1.2+ | Event-driven autoscaling for raw deployments based on metrics |
| Gateway API | CRD (HTTPRoute) | 6443/TCP | HTTPS | TLS 1.2+ | Modern ingress routing as alternative to Istio VirtualService |
| OpenTelemetry | CRD (OpenTelemetryCollector) | 6443/TCP | HTTPS | TLS 1.2+ | Metrics collection for KEDA autoscaling integration |
| Prometheus Operator | CRD (ServiceMonitor) | 6443/TCP | HTTPS | TLS 1.2+ | Automated metrics scraping configuration |
| OpenShift Service CA | Certificate injection annotations | N/A | N/A | N/A | Automated TLS certificate provisioning for webhooks |
| OpenShift Routes | CRD (Route) | 6443/TCP | HTTPS | TLS 1.2+ | External ingress on OpenShift clusters |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 27c1e99b7 | 2024-12 | - Merge precise prefix cache scorer example updates |
| b007b91ad | 2024-12 | - Update vLLM block-size parameter configuration |
| 7bd3e976c | 2024-12 | - Remove enable-auth annotation |
| 6c0c7b900 | 2024-12 | - Update precise prefix cache sample configurations |
| ceb4f0b86 | 2024-12 | - Merge upstream changes from main branch to rhoai-3.2 |
| 16ddf9f59 | 2024-12 | - Update precise prefix routing examples |
| 087472d3e | 2024-11 | - Merge remote-tracking branch upstream/main |
| ed1d009d6 | 2024-11 | - Update poetry lock file dependencies |
| 99713e22c | 2024-11 | - Merge upstream changes to rhoai-3.2 branch |
| 732005ea3 | 2024-11 | - Update params.env for image configuration |
| 05c269dfd | 2024-11 | - Update params.env with deployment parameters |
| faec54868 | 2024-11 | - RHOAIENG-42021: Update params.env configuration |
| b643bdd92 | 2024-11 | - RHOAIENG-42021: Add missing images to params.env |

## Container Images

| Image | Purpose | Base Image | User |
|-------|---------|------------|------|
| odh-kserve-controller | Main controller managing InferenceService reconciliation | registry.access.redhat.com/ubi9/ubi-minimal | 1000 (kserve) |
| odh-kserve-agent | Sidecar for logging, batching, and model agent | registry.access.redhat.com/ubi9/ubi-minimal | 1000 (kserve) |
| odh-kserve-router | InferenceGraph routing service | registry.access.redhat.com/ubi9/ubi-minimal | 1000 (kserve) |
| odh-kserve-storage-initializer | Init container for model downloads | registry.access.redhat.com/ubi9/ubi-minimal | Non-root |
| odh-kserve-localmodel-manager | Local model cache manager | registry.access.redhat.com/ubi9/ubi-minimal | 1000 (kserve) |
| odh-kserve-localmodel-agent | Node-level local model cache agent | registry.access.redhat.com/ubi9/ubi-minimal | 1000 (kserve) |

## Deployment Modes

| Mode | Description | Components | Use Case |
|------|-------------|------------|----------|
| Serverless | Knative-based with autoscaling and scale-to-zero | Knative Serving, Istio, KServe Controller | Variable workloads, cost optimization, automatic scaling |
| RawDeployment | Standard Kubernetes Deployment with optional HPA | K8s Deployment, Service, Ingress/HTTPRoute, optional KEDA | Stable workloads, predictable traffic, no Knative dependency |
| ModelMesh | High-density multi-model serving | ModelMesh Controller, KServe Controller | Large number of small models, frequent model updates |

## Model Server Runtimes

KServe supports pluggable model serving runtimes via ServingRuntime CRDs:

| Runtime | Model Formats | Protocol | Use Case |
|---------|---------------|----------|----------|
| TensorFlow Serving | SavedModel, TensorFlow | gRPC, REST v1 | TensorFlow models |
| Triton Inference Server | TensorRT, ONNX, PyTorch, TensorFlow | gRPC, REST v2 | Multi-framework, GPU-optimized |
| TorchServe | PyTorch (.pt, .pth, .mar) | gRPC, REST v1/v2 | PyTorch models |
| MLServer | SKLearn, XGBoost, LightGBM | gRPC, REST v2 | Scikit-learn and tree-based models |
| vLLM | HuggingFace Transformers | OpenAI-compatible REST | Large language models (LLMs) |
| Text Generation Inference (TGI) | HuggingFace Transformers | gRPC, REST v2 | Optimized text generation models |
| Custom Servers | User-defined | gRPC, REST v1/v2 | Custom model servers implementing KServe protocol |

## Configuration

KServe is configured via the `inferenceservice-config` ConfigMap in the `kserve` namespace:

| Configuration | Default Value | Purpose |
|---------------|---------------|---------|
| defaultDeploymentMode | Serverless | Deployment mode (Serverless, RawDeployment, ModelMesh) |
| ingressDomain | example.com | Base domain for inference service URLs |
| urlScheme | http | URL scheme (http/https) for inference endpoints |
| enableGatewayApi | false | Use Gateway API instead of Istio VirtualService |
| storageInitializer.image | kserve/storage-initializer:latest | Storage initializer container image |
| agent.image | kserve/agent:latest | Agent sidecar container image |
| router.image | kserve/router:latest | InferenceGraph router container image |

## Performance and Scaling

| Metric | Value | Notes |
|--------|-------|-------|
| Controller CPU Request | 100m | Configurable via resource patches |
| Controller Memory Request | 200Mi | Configurable via resource patches |
| Controller CPU Limit | 100m | Configurable via resource patches |
| Controller Memory Limit | 300Mi | Configurable via resource patches |
| Default Autoscaling | Knative KPA | Based on request concurrency |
| Scale to Zero | Yes (Serverless) | Scales to 0 pods after idle timeout |
| GPU Autoscaling | Yes | Supported via KEDA ScaledObjects |
