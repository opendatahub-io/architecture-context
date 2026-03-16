# Component: KServe

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kserve
- **Version**: 5e4621c70
- **Branch**: rhoai-3.0
- **Distribution**: RHOAI
- **Languages**: Go (operator, agent, router), Python (model servers, storage initializer)
- **Deployment Type**: Kubernetes Operator with multiple supporting services

## Purpose
**Short**: Cloud-native model inference platform providing standardized serving for predictive and generative AI models on Kubernetes.

**Detailed**: KServe is a Kubernetes operator that provides a complete model serving platform for production ML deployments. It delivers high-level abstractions for deploying machine learning models from various frameworks (TensorFlow, PyTorch, XGBoost, Scikit-learn, HuggingFace/LLMs) with standardized inference protocols. The platform manages the full lifecycle of model serving including autoscaling (GPU and CPU with scale-to-zero), networking configuration via Istio/Knative or raw Kubernetes, health checking, canary rollouts, and inference graphs for multi-model pipelines. KServe integrates deeply with the service mesh for mTLS, request routing, and observability while supporting both serverless (via Knative) and raw deployment modes for flexibility across different use cases.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kserve-controller-manager | Go Operator | Main controller reconciling InferenceService, ServingRuntime, and related CRDs |
| kserve-agent | Go Sidecar | Model serving agent injected into inference pods for lifecycle management |
| kserve-router | Go Service | Intelligent request router for InferenceGraphs and multi-model routing |
| storage-initializer | Python Init Container | Downloads and initializes model artifacts from S3, GCS, Azure, PVC, HTTP sources |
| localmodel-manager | Go Service | Manages local model caching on worker nodes |
| localmodelnode-agent | Go DaemonSet Agent | Node-level agent for local model cache management |
| HuggingFace Server | Python Service | Serves HuggingFace transformer and LLM models |
| Sklearn Server | Python Service | Serves Scikit-learn models |
| XGBoost Server | Python Service | Serves XGBoost models |
| LightGBM Server | Python Service | Serves LightGBM models |
| Paddle Server | Python Service | Serves PaddlePaddle models |
| PMML Server | Python Service | Serves PMML models |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Primary API for deploying ML model serving workloads with predictor/transformer/explainer |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Defines model server runtime configuration (image, ports, protocols, supported formats) |
| serving.kserve.io | v1alpha1 | ClusterServingRuntime | Cluster | Cluster-scoped serving runtime templates available to all namespaces |
| serving.kserve.io | v1alpha1 | LLMInferenceService | Namespaced | Specialized API for deploying LLM inference services with vLLM/TGI runtimes |
| serving.kserve.io | v1alpha1 | LLMInferenceServiceConfig | Namespaced | Configuration presets for LLM inference deployments |
| serving.kserve.io | v1alpha1 | InferenceGraph | Namespaced | DAG-based multi-model inference pipeline with routing and ensemble logic |
| serving.kserve.io | v1alpha1 | TrainedModel | Namespaced | Represents trained model metadata for ModelMesh multi-model serving |
| serving.kserve.io | v1alpha1 | LocalModelNode | Namespaced | Node resource for local model caching and offline inference |
| serving.kserve.io | v1alpha1 | LocalModelNodeGroup | Namespaced | Groups of nodes for coordinated local model deployment |
| serving.kserve.io | v1alpha1 | LocalModelCache | Namespaced | Manages model cache on local storage for reduced network overhead |
| serving.kserve.io | v1alpha1 | ClusterStorageContainer | Cluster | Cluster-scoped storage configuration for model download (S3, GCS, etc.) |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /mutate-serving-kserve-io-v1beta1-inferenceservice | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Auth | Mutating webhook for InferenceService defaulting |
| /mutate-pods | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Auth | Pod mutation webhook for storage-initializer injection |
| /validate-serving-kserve-io-v1beta1-inferenceservice | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Auth | Validating webhook for InferenceService spec validation |
| /validate-serving-kserve-io-v1alpha1-trainedmodel | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Auth | Validating webhook for TrainedModel validation |
| /validate-serving-kserve-io-v1alpha1-inferencegraph | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Auth | Validating webhook for InferenceGraph validation |
| /validate-serving-kserve-io-v1alpha1-clusterservingruntime | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Auth | Validating webhook for ClusterServingRuntime validation |
| /validate-serving-kserve-io-v1alpha1-servingruntime | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Auth | Validating webhook for ServingRuntime validation |
| /validate-serving-kserve-io-v1alpha1-llminferenceservice | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Auth | Validating webhook for LLMInferenceService validation |
| /validate-serving-kserve-io-v1alpha1-localmodelcache | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Auth | Validating webhook for LocalModelCache validation |
| /healthz | GET | 8081/TCP | HTTP | None | None | Controller liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Controller readiness probe |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token | Prometheus metrics endpoint (kube-rbac-proxy protected) |
| /v1/models/:name:infer | POST | 8080/TCP | HTTP | Configurable | Configurable | KServe V1 inference protocol (model servers) |
| /v2/models/:name/infer | POST | 8080/TCP | HTTP | Configurable | Configurable | KServe V2 inference protocol (model servers) |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| inference.GRPCInferenceService | 8081/TCP | gRPC | Configurable | Configurable | KServe V2 gRPC inference protocol (optional) |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.25+ | Yes | Container orchestration platform |
| cert-manager | 1.0+ | Yes | TLS certificate management for webhooks |
| Knative Serving | 1.8+ | Conditional | Serverless autoscaling and request-based scaling (serverless mode) |
| Istio | 1.17+ | Conditional | Service mesh for mTLS, traffic management, routing (serverless mode) |
| Gateway API | v1beta1+ | Conditional | Alternative to Istio for traffic routing (optional) |
| Prometheus | 2.x | No | Metrics collection and monitoring |
| KEDA | 2.x | No | Event-driven autoscaling for raw deployments |
| OpenTelemetry Collector | 0.x | No | Distributed tracing and telemetry |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Service Mesh (Istio) | VirtualService, DestinationRule, Gateway | Traffic routing, mTLS enforcement, canary deployments |
| Authorino | AuthorizationPolicy | Token-based authorization for inference endpoints |
| Model Registry | HTTP API | Model metadata and versioning integration |
| Data Science Pipelines | CRD/API | ML pipeline integration for model deployment |
| ODH Operator | CRD Watch | Component lifecycle management via DataScienceCluster |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kserve-webhook-server-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | Kubernetes API Server | Internal |
| kserve-controller-manager-service | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | Bearer Token (kube-rbac-proxy) | Internal |
| <isvc-name>-predictor | ClusterIP | 80/TCP | 8080 | HTTP | Configurable | Configurable | Internal (raw mode) |
| <isvc-name>-predictor (Knative) | ClusterIP | 80/TCP | 8012 | HTTP | None | None | Internal (serverless mode) |
| <isvc-name>-transformer | ClusterIP | 80/TCP | 8080 | HTTP | Configurable | Configurable | Internal (if transformer defined) |
| <isvc-name>-explainer | ClusterIP | 80/TCP | 8080 | HTTP | Configurable | Configurable | Internal (if explainer defined) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| <isvc-name> (Serverless) | Istio VirtualService | <isvc-name>.<namespace>.<domain> | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External via Istio Gateway |
| <isvc-name> (Raw) | Kubernetes Ingress | <isvc-name>.<namespace>.<domain> | 443/TCP | HTTPS | TLS 1.2+ | Edge Termination | External via cluster ingress |
| <isvc-name> (OpenShift) | OpenShift Route | <isvc-name>-<namespace>.apps.<cluster> | 443/TCP | HTTPS | TLS 1.2+ | Edge/Reencrypt | External via OpenShift router |
| <llmisvc-name> | Istio VirtualService | <llmisvc-name>.<namespace>.<domain> | 443/TCP | HTTPS | TLS 1.3 | MUTUAL (optional) | External via Istio Gateway |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| S3 Storage (AWS/Minio) | 443/TCP | HTTPS | TLS 1.2+ | AWS SigV4 / Access Key | Model artifact download |
| GCS Storage | 443/TCP | HTTPS | TLS 1.2+ | GCP Service Account | Model artifact download |
| Azure Blob Storage | 443/TCP | HTTPS | TLS 1.2+ | Azure Storage Key | Model artifact download |
| HTTP(S) Model URIs | 443/TCP, 80/TCP | HTTPS, HTTP | TLS 1.2+ (HTTPS) | None/Basic Auth | Generic model download |
| HuggingFace Hub | 443/TCP | HTTPS | TLS 1.2+ | HF Token | HuggingFace model download |
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token | Resource reconciliation, CRD management |
| Prometheus Pushgateway | 9091/TCP | HTTP | None | None | Metrics push (optional) |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kserve-manager-role | "" | configmaps, events, secrets, serviceaccounts, services, namespaces, pods | create, delete, get, list, patch, update, watch |
| kserve-manager-role | apps | deployments | create, delete, get, list, patch, update, watch |
| kserve-manager-role | autoscaling | horizontalpodautoscalers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | inferenceservices, servingruntimes, clusterservingruntimes, trainedmodels, inferencegraphs, llminferenceservices, llminferenceserviceconfigs, localmodelcaches, clusterstoragecontainers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | inferenceservices/status, servingruntimes/status, inferencegraphs/status, llminferenceservices/status, trainedmodels/status | get, patch, update |
| kserve-manager-role | serving.knative.dev | services | create, delete, get, list, patch, update, watch |
| kserve-manager-role | networking.istio.io | virtualservices, destinationrules | create, delete, get, list, patch, update, watch |
| kserve-manager-role | networking.k8s.io | ingresses | create, delete, get, list, patch, update, watch |
| kserve-manager-role | gateway.networking.k8s.io | gateways, httproutes, gatewayclasses | create, delete, get, list, patch, update, watch |
| kserve-manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| kserve-manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | create, delete, get, list, patch, update, watch |
| kserve-manager-role | rbac.authorization.k8s.io | clusterrolebindings, rolebindings, roles | create, delete, get, list, patch, update, watch |
| kserve-manager-role | authentication.k8s.io | tokenreviews, subjectaccessreviews | create |
| kserve-manager-role | keda.sh | scaledobjects | create, delete, get, list, patch, update, watch |
| kserve-manager-role | monitoring.coreos.com | servicemonitors, podmonitors | create, delete, get, list, patch, update, watch |
| kserve-manager-role | opentelemetry.io | opentelemetrycollectors | create, delete, get, list, patch, update, watch |
| kserve-manager-role | leaderworkerset.x-k8s.io | leaderworkersets | create, delete, get, list, patch, update, watch |
| kserve-manager-role | inference.networking.k8s.io, inference.networking.x-k8s.io | inferencepools, inferencemodels, inferenceobjectives | create, delete, get, list, patch, update, watch |
| kserve-manager-role | security.openshift.io | securitycontextconstraints (openshift-ai-llminferenceservice-scc) | use |
| kserve-leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| kserve-leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| kserve-proxy-role | authentication.k8s.io | tokenreviews | create |
| kserve-proxy-role | authorization.k8s.io | subjectaccessreviews | create |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kserve-manager-rolebinding | kserve (cluster-scoped) | kserve-manager-role | kserve-controller-manager |
| kserve-leader-election-rolebinding | kserve | kserve-leader-election-role | kserve-controller-manager |
| kserve-proxy-rolebinding | kserve (cluster-scoped) | kserve-proxy-role | kserve-controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| kserve-webhook-server-cert | kubernetes.io/tls | TLS certificate for webhook server | cert-manager | Yes |
| kserve-webhook-server-secret | Opaque | Webhook configuration secrets | KServe Operator | No |
| storage-config | Opaque | S3/GCS/Azure credentials for model storage | User/External Secrets | No |
| <isvc-name>-sa-token | kubernetes.io/service-account-token | Service account token for inference pods | Kubernetes | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| Webhook Server (:9443) | POST | Kubernetes API Server mTLS | kube-apiserver | API server validates webhook TLS cert |
| Metrics Endpoint (:8443) | GET | Bearer Token (ServiceAccount) | kube-rbac-proxy | RBAC enforced by proxy sidecar |
| Inference Endpoints (:8080) | POST, GET | Configurable (Bearer/mTLS/None) | Istio AuthorizationPolicy / Ingress | User-defined policies via service mesh |
| LLM Inference (Istio) | POST | mTLS + Bearer Token (JWT) | Istio PeerAuthentication + Authorino | Mutual TLS between services, token validation |
| Model Storage (S3/GCS) | GET | AWS SigV4 / GCP Service Account | Storage Provider | Cloud provider IAM |

## Data Flows

### Flow 1: InferenceService Creation and Model Serving

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | kubeconfig Bearer Token |
| 2 | Kubernetes API | KServe Webhook Server | 9443/TCP | HTTPS | TLS 1.2+ | API Server mTLS |
| 3 | KServe Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Storage Initializer (init) | S3/GCS/Azure | 443/TCP | HTTPS | TLS 1.2+ | Cloud Provider Auth |
| 5 | Storage Initializer | Shared Volume (emptyDir/PVC) | Local | Filesystem | None | Pod-level isolation |
| 6 | Model Server Container | Shared Volume | Local | Filesystem | None | Pod-level isolation |
| 7 | Istio Gateway / Ingress | Model Server Pod | 8080/TCP | HTTP | mTLS (Istio) / TLS (Ingress) | Bearer Token / mTLS |
| 8 | Client | Istio Gateway / Route | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token / API Key |

### Flow 2: InferenceGraph Multi-Model Pipeline

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | Istio Gateway | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Istio Gateway | InferenceGraph Router | 8080/TCP | HTTP | mTLS | Service Mesh |
| 3 | InferenceGraph Router | Transformer InferenceService | 80/TCP | HTTP | mTLS | Service Mesh |
| 4 | Transformer | Predictor InferenceService | 80/TCP | HTTP | mTLS | Service Mesh |
| 5 | Predictor | Explainer InferenceService (optional) | 80/TCP | HTTP | mTLS | Service Mesh |
| 6 | Explainer | InferenceGraph Router | 80/TCP | HTTP | mTLS | Service Mesh |
| 7 | InferenceGraph Router | Client (via Istio) | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |

### Flow 3: LLM Inference Service Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Kubernetes API | KServe Webhook Server | 9443/TCP | HTTPS | TLS 1.2+ | API Server mTLS |
| 3 | KServe LLMInferenceService Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Storage Initializer | HuggingFace Hub | 443/TCP | HTTPS | TLS 1.2+ | HF Token |
| 5 | vLLM/TGI Runtime | GPU Node Resources | Local | Local | None | Node-level isolation |
| 6 | Client | OpenShift Route / Istio VirtualService | 443/TCP | HTTPS | TLS 1.3 | Bearer Token (Authorino) |
| 7 | Route/VirtualService | LLM Server Pod | 8080/TCP | HTTP | mTLS (Istio) | Authorino JWT Validation |

### Flow 4: Metrics and Monitoring

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Model Server | Prometheus Endpoint | 8080/TCP | HTTP | None | None |
| 2 | Prometheus | ServiceMonitor (Model Servers) | 8080/TCP | HTTP | None | None |
| 3 | Prometheus | kserve-controller-manager-service | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 4 | OpenTelemetry Collector | Model Server (traces) | 4317/TCP | gRPC | TLS 1.2+ | None |
| 5 | OpenTelemetry Collector | Backend (Jaeger/Tempo) | 443/TCP | HTTPS | TLS 1.2+ | API Key |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | CRD reconciliation, resource management |
| Knative Serving | CRD Reconciliation | 6443/TCP | HTTPS | TLS 1.2+ | Serverless service creation and autoscaling |
| Istio Control Plane | CRD Creation | 6443/TCP | HTTPS | TLS 1.2+ | VirtualService, DestinationRule for traffic routing |
| cert-manager | Certificate CRD | 6443/TCP | HTTPS | TLS 1.2+ | Webhook TLS certificate issuance |
| Prometheus | Metrics Scrape | 8080/TCP, 8443/TCP | HTTP, HTTPS | TLS 1.2+ (controller) | Metrics collection from model servers and controller |
| KEDA | ScaledObject CRD | 6443/TCP | HTTPS | TLS 1.2+ | Event-driven autoscaling for raw deployments |
| Gateway API | HTTPRoute/Gateway CRD | 6443/TCP | HTTPS | TLS 1.2+ | Alternative traffic routing without Istio |
| OpenShift Router | Route CRD | 6443/TCP | HTTPS | TLS 1.2+ | External access via OpenShift Routes |
| Authorino | AuthorizationPolicy | 6443/TCP | HTTPS | TLS 1.2+ | Token-based authorization for inference endpoints |
| Model Registry | HTTP API | 8080/TCP | HTTP | TLS 1.2+ | Model metadata lookup and versioning |
| OpenTelemetry | Trace Export | 4317/TCP | gRPC | TLS 1.2+ | Distributed tracing for inference requests |
| Service Mesh (mTLS) | Mutual TLS | All ports | HTTPS/gRPC | mTLS | Pod-to-pod encrypted communication |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 5e4621c70 | 2026-03-14 | - Merge pull request #4098: Cherry-pick precise prefix routing updates to rhoai-3.0<br>- Update precise prefix routing example |
| 545427e44 | 2026-03-14 | - Update precise prefix routing example for InferenceGraph configurations |

## Deployment Modes

KServe supports three primary deployment modes configured via the `inferenceservice-config` ConfigMap:

1. **Serverless Mode (Default)**: Uses Knative Serving for request-based autoscaling with scale-to-zero, Istio for traffic management and mTLS. Provides canary deployments and advanced routing.

2. **Raw Deployment Mode**: Lightweight mode using standard Kubernetes Deployments and Services. No Knative dependency, suitable for resource-constrained environments or where scale-to-zero is not needed.

3. **ModelMesh Mode**: High-density multi-model serving for frequently changing model workloads, providing intelligent model placement and loading.

## Model Server Runtimes

The following ClusterServingRuntimes are provided out-of-box in `config/runtimes/`:

- **kserve-huggingfaceserver**: HuggingFace transformers and LLMs (single-node)
- **kserve-huggingfaceserver-multinode**: HuggingFace LLMs with multi-node/multi-GPU support
- **kserve-sklearn**: Scikit-learn models (via KServe native server)
- **kserve-xgbserver**: XGBoost models
- **kserve-lgbserver**: LightGBM models
- **kserve-paddleserver**: PaddlePaddle models
- **kserve-pmmlserver**: PMML models
- **kserve-mlserver**: MLServer runtime (multi-framework support)
- **kserve-tensorflow-serving**: TensorFlow Serving
- **kserve-torchserve**: PyTorch TorchServe
- **kserve-tritonserver**: NVIDIA Triton Inference Server

All model servers support KServe V1 and/or V2 inference protocols and expose Prometheus metrics on port 8080.

## Container Images (Konflux Build)

The following container images are built via Konflux CI/CD pipeline:

1. **odh-kserve-controller**: KServe controller manager (Go)
2. **odh-kserve-agent**: Model serving agent sidecar (Go)
3. **odh-kserve-router**: InferenceGraph router (Go)
4. **odh-kserve-storage-initializer**: Model storage initializer (Python)
5. **odh-kserve-localmodel**: Local model cache manager (Go)
6. **odh-kserve-localmodel-agent**: Local model node agent (Go)

All images are built with FIPS 140-2 compliance (strictfipsruntime) and use Red Hat UBI 9 base images.
