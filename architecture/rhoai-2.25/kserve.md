# Component: KServe

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kserve
- **Version**: 4211a5da7 (rhoai-2.25 branch)
- **Distribution**: RHOAI
- **Languages**: Go (operator/controllers), Python (inference servers/SDK)
- **Deployment Type**: Kubernetes Operator + Model Serving Runtime

## Purpose
**Short**: KServe provides a Kubernetes Custom Resource Definition for serving predictive and generative machine learning models with high abstraction interfaces and standardized data plane protocols.

**Detailed**: KServe is the model inference platform for RHOAI that enables production deployment of machine learning models on Kubernetes. It provides a standardized serverless inference protocol across multiple ML frameworks including TensorFlow, PyTorch, Scikit-Learn, XGBoost, HuggingFace, and more. The operator manages the lifecycle of InferenceServices, automatically handling model deployment, autoscaling (including scale-to-zero and GPU autoscaling), networking setup, health checking, and canary rollouts. It integrates deeply with Knative for serverless capabilities, Istio for service mesh networking, and supports both serverless and raw Kubernetes deployment modes. KServe also enables advanced inference patterns including pre/post-processing transformers, model explainability, inference graphs for complex pipelines, and multi-node distributed inference for large language models.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kserve-controller-manager | Go Operator | Reconciles InferenceService, ServingRuntime, TrainedModel, InferenceGraph, and LLMInferenceService CRDs; orchestrates model deployments |
| storage-initializer | Python Init Container | Downloads models from S3, GCS, Azure Blob, HTTP, or PVC storage into pod volumes before inference container starts |
| agent | Go Sidecar | Handles model pulling, request batching, request/response logging to event sinks, and health probing for inference pods |
| router | Go Service | Routes inference requests through InferenceGraph steps; implements sequence, switch, and splitter patterns for multi-model pipelines |
| model-servers | Python/Various | Framework-specific inference servers (MLServer, TensorFlow Serving, TorchServe, Triton, etc.) that load models and serve predictions |
| localmodel-controller | Go Controller | Manages local model caching for edge deployments; creates download jobs and manages persistent volumes for cached models |
| localmodel-node-agent | Go DaemonSet | Node-level agent for local model management; monitors and reconciles model files on local disk |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Primary API for deploying ML models; defines predictor, transformer, and explainer components with traffic splitting |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Defines reusable runtime templates for model servers with container specs, supported formats, and protocol versions |
| serving.kserve.io | v1alpha1 | ClusterServingRuntime | Cluster | Cluster-wide runtime templates available to all namespaces; includes built-in runtimes for TensorFlow, PyTorch, etc. |
| serving.kserve.io | v1alpha1 | TrainedModel | Namespaced | Represents a trained model for multi-model serving; loaded dynamically into existing runtime without pod restart |
| serving.kserve.io | v1alpha1 | InferenceGraph | Namespaced | Defines multi-step inference pipelines with routing logic (sequence, switch, ensemble) across multiple models |
| serving.kserve.io | v1alpha1 | LLMInferenceService | Namespaced | Specialized API for deploying large language models with multi-node distributed inference and vLLM support |
| serving.kserve.io | v1alpha1 | LLMInferenceServiceConfig | Namespaced | Configuration for LLM inference workloads including model parameters, GPU resources, and scheduling policies |
| serving.kserve.io | v1alpha1 | ClusterStorageContainer | Cluster | Defines storage container templates for model artifact retrieval from various cloud storage providers |
| serving.kserve.io | v1alpha1 | LocalModelCache | Namespaced | Manages cached models on persistent volumes for edge/disconnected deployments |
| serving.kserve.io | v1alpha1 | LocalModelNode | Namespaced | Tracks model cache state on individual nodes for local model management |
| serving.kserve.io | v1alpha1 | LocalModelNodeGroup | Namespaced | Groups nodes for local model distribution and scheduling policies |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics from controller manager |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe for controller manager |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe for controller manager |
| /v1/models/{model}:predict | POST | 8080/TCP | HTTP/HTTPS | TLS 1.2+ (in-mesh) | Bearer/mTLS | V1 inference protocol prediction endpoint on model servers |
| /v2/models/{model}/infer | POST | 8080/TCP | HTTP/HTTPS | TLS 1.2+ (in-mesh) | Bearer/mTLS | V2 inference protocol prediction endpoint on model servers |
| /v1/models/{model} | GET | 8080/TCP | HTTP/HTTPS | TLS 1.2+ (in-mesh) | Bearer/mTLS | Model metadata endpoint (name, versions, inputs/outputs) |
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics from model server pods |
| / | POST | 9081/TCP | HTTP | None | None | Agent sidecar proxy endpoint for batching and logging |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| inference.GRPCInferenceService | 9000/TCP | gRPC/HTTP2 | mTLS (in-mesh) | mTLS cert | V2 inference protocol over gRPC for high-performance inference |

### Webhook Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /mutate-serving-kserve-io-v1beta1-inferenceservice | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API | Mutating webhook for InferenceService defaulting and storage injection |
| /validate-serving-kserve-io-v1beta1-inferenceservice | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API | Validating webhook for InferenceService validation |
| /mutate-serving-kserve-io-v1alpha1-trainedmodel | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API | Mutating webhook for TrainedModel defaulting |
| /validate-serving-kserve-io-v1alpha1-trainedmodel | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API | Validating webhook for TrainedModel validation |
| /mutate-pods | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API | Mutating webhook for pod injection (agent, storage-initializer) |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Knative Serving | v1.x | No (optional) | Serverless deployment mode with autoscaling and traffic splitting; alternative is raw Kubernetes deployment |
| Istio | 1.x | No (optional) | Service mesh for traffic management, mTLS, telemetry; can use other Knative-compatible networking layers |
| KEDA | v2.x | No (optional) | Event-driven autoscaling with ScaledObjects for advanced metrics-based scaling |
| OpenTelemetry Operator | v1beta1 | No (optional) | Observability and metrics collection for LLM inference services |
| Prometheus Operator | v1 | No (optional) | Metrics scraping with ServiceMonitor and PodMonitor resources |
| Gateway API | v1 | No (optional) | Kubernetes Gateway API for ingress; alternative to Istio VirtualServices or Ingress |
| cert-manager | v1.x | No (optional) | TLS certificate management for webhooks and services |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| OpenDataHub Operator | CRD Watch | Watches DataScienceCluster and DSCInitialization CRDs to enable/disable KServe component in ODH deployments |
| ServiceMesh (Istio) | Network Policy | Integrates with RHOAI service mesh for secure inference endpoint exposure and mTLS |
| Dashboard | REST API | RHOAI dashboard uses KServe Python SDK to create and manage InferenceServices via Kubernetes API |
| Model Registry | Storage Reference | InferenceServices can reference models registered in ODH Model Registry via storage URIs |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kserve-controller-manager-service | ClusterIP | 8443/TCP | https | HTTPS | TLS 1.2+ | Bearer Token | Internal |
| kserve-webhook-server-service | ClusterIP | 443/TCP | webhook-server (9443) | HTTPS | TLS 1.2+ | Kubernetes API Server | Internal |
| {isvc-name}-predictor-default | ClusterIP | 80/TCP | 8080 | HTTP | None (plaintext) | None | Internal |
| {isvc-name}-predictor-default (mesh) | ClusterIP | 80/TCP | 8080 | HTTP | mTLS | Client cert | Internal |
| {isvc-name}-predictor-default-private | ClusterIP | 80/TCP | 8012 | HTTP | mTLS | Client cert | Internal (Knative) |
| {isvc-name}-transformer-default | ClusterIP | 80/TCP | 8080 | HTTP | mTLS | Client cert | Internal |
| {isvc-name}-explainer-default | ClusterIP | 80/TCP | 8080 | HTTP | mTLS | Client cert | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {isvc-name}-ingress | Istio VirtualService | {isvc}.{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External |
| {isvc-name}-route | OpenShift Route | {isvc}-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ | Edge | External (OpenShift) |
| {isvc-name}-gateway | Gateway API HTTPRoute | {isvc}.{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External |
| {isvc-name}-local | Istio VirtualService | {isvc}.{namespace}.svc.cluster.local | 80/TCP | HTTP | mTLS | MUTUAL | Internal |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| s3.amazonaws.com | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Secret Key | Model artifact download from S3-compatible storage |
| storage.googleapis.com | 443/TCP | HTTPS | TLS 1.2+ | GCP Service Account | Model artifact download from Google Cloud Storage |
| blob.core.windows.net | 443/TCP | HTTPS | TLS 1.2+ | Azure credentials | Model artifact download from Azure Blob Storage |
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token | Controller watches resources, updates status |
| Knative Serving API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token | Controller manages Knative Services |
| Event Sink | 80/TCP or 443/TCP | HTTP/HTTPS | TLS 1.2+ (if HTTPS) | Bearer Token | Agent sends request/response logs to configured event broker |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kserve-manager-role | serving.kserve.io | inferenceservices, servingruntimes, clusterservingruntimes, trainedmodels, inferencegraphs, llminferenceservices, llminferenceserviceconfigs | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | inferenceservices/status, servingruntimes/status, trainedmodels/status, inferencegraphs/status, llminferenceservices/status | get, patch, update |
| kserve-manager-role | serving.kserve.io | localmodelcaches | get, list, watch |
| kserve-manager-role | serving.knative.dev | services | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.knative.dev | services/status | get, patch, update |
| kserve-manager-role | networking.istio.io | virtualservices, destinationrules | create, delete, get, list, patch, update, watch |
| kserve-manager-role | apps | deployments | create, delete, get, list, patch, update, watch |
| kserve-manager-role | autoscaling | horizontalpodautoscalers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | "" | services, secrets, serviceaccounts, events, configmaps | create, delete, get, list, patch, update, watch |
| kserve-manager-role | "" | namespaces, pods | get, list, watch |
| kserve-manager-role | networking.k8s.io | ingresses | create, delete, get, list, patch, update, watch |
| kserve-manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| kserve-manager-role | gateway.networking.k8s.io | httproutes, gateways, gatewayclasses | create, delete, get, list, patch, update, watch |
| kserve-manager-role | keda.sh | scaledobjects | create, delete, get, list, patch, update, watch |
| kserve-manager-role | opentelemetry.io | opentelemetrycollectors | create, delete, get, list, patch, update, watch |
| kserve-manager-role | monitoring.coreos.com | servicemonitors, podmonitors | create, delete, get, list, patch, update, watch |
| kserve-manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | create, delete, get, list, patch, update, watch |
| kserve-manager-role | rbac.authorization.k8s.io | clusterrolebindings, rolebindings, roles | create, delete, get, list, patch, update, watch |
| kserve-manager-role | security.openshift.io | securitycontextconstraints | use (openshift-ai-llminferenceservice-scc) |
| kserve-manager-role | leaderworkerset.x-k8s.io | leaderworkersets | create, delete, get, list, patch, update, watch |
| kserve-manager-role | inference.networking.x-k8s.io | inferencemodels, inferencepools | create, delete, get, list, patch, update, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kserve-manager-rolebinding | kserve | kserve-manager-role (ClusterRole) | kserve-controller-manager |
| kserve-leader-election-rolebinding | kserve | kserve-leader-election-role | kserve-controller-manager |
| kserve-proxy-rolebinding | kserve | kserve-proxy-role | kserve-controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| kserve-webhook-server-cert | kubernetes.io/tls | TLS certificate for webhook server HTTPS endpoint | cert-manager or manual | Yes (cert-manager) |
| kserve-webhook-server-secret | Opaque | Webhook configuration secret | KServe installation | No |
| storage-config | Opaque | Default storage credentials (S3/GCS keys) referenced by InferenceServices | User/Admin | No |
| {custom-secret} | Opaque | User-provided storage credentials specified via annotations or storageSpec | User | No |
| {service-account-token} | kubernetes.io/service-account-token | Auto-mounted SA token for Kubernetes API access | Kubernetes | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| InferenceService /v1/models/:predict | POST | Bearer Token (JWT) or mTLS | Istio AuthorizationPolicy | User must have access to namespace; optional token validation |
| InferenceService /v2/models/:infer | POST | Bearer Token (JWT) or mTLS | Istio AuthorizationPolicy | User must have access to namespace; optional token validation |
| Webhook Server | POST | Kubernetes API Server cert | kube-apiserver | Controller service account must have webhook permissions |
| Controller Manager Metrics | GET | None (ClusterIP internal) | Network Policy | Only cluster-internal access allowed |
| Model Storage (S3/GCS) | GET | AWS IAM, GCS Service Account, or Secret Keys | Storage Provider | Credentials from secrets or IRSA/Workload Identity |

## Data Flows

### Flow 1: Model Deployment - InferenceService Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Dashboard | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (User) |
| 2 | Kubernetes API | kserve-webhook-server | 9443/TCP | HTTPS | TLS 1.2+ | API Server cert |
| 3 | kserve-webhook-server | Kubernetes API (response) | - | - | - | - |
| 4 | Kubernetes API | kserve-controller-manager (watch) | - | - | - | - |
| 5 | kserve-controller-manager | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 6 | kserve-controller-manager | Knative API (create Service) | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |

### Flow 2: Model Loading - Storage Initialization

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | storage-initializer (init) | S3/GCS/Azure | 443/TCP | HTTPS | TLS 1.2+ | IAM/Service Account/Secret Key |
| 2 | storage-initializer | Shared Volume (/mnt/models) | - | Filesystem | - | - |
| 3 | model-server | Shared Volume (/mnt/models) | - | Filesystem | - | - |
| 4 | model-server | Kubernetes API (readiness) | - | - | - | - |

### Flow 3: Inference Request - Serverless Mode with Istio

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | Istio Ingress Gateway | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (optional) |
| 2 | Istio Gateway | Istio VirtualService | - | - | - | - |
| 3 | Istio VirtualService | Knative Service (Activator or Pod) | 80/TCP | HTTP | mTLS | Client cert |
| 4 | Knative Pod (agent sidecar) | Knative Pod (model-server) | 8080/TCP | HTTP | None (localhost) | None |
| 5 | model-server | Response | - | - | - | - |
| 6 | agent sidecar (if logging enabled) | Event Sink | 80/TCP or 443/TCP | HTTP/HTTPS | TLS 1.2+ (if HTTPS) | Bearer Token |

### Flow 4: Multi-Model Inference Graph

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | Istio Gateway | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Istio Gateway | InferenceGraph Router Pod | 80/TCP | HTTP | mTLS | Client cert |
| 3 | Router | Model A Service | 80/TCP | HTTP | mTLS | Client cert |
| 4 | Router | Model B Service | 80/TCP | HTTP | mTLS | Client cert |
| 5 | Router | External Client (response) | 443/TCP | HTTPS | TLS 1.2+ | - |

### Flow 5: LLM Multi-Node Distributed Inference

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | Gateway/Route | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Gateway | LeaderWorkerSet Leader Pod (vLLM) | 8080/TCP | HTTP | mTLS | Client cert |
| 3 | Leader Pod | Worker Pods (Ray cluster) | 6379/TCP, 8265/TCP | TCP | None (Pod network) | None |
| 4 | Worker Pods | Shared Storage (model shards) | - | Filesystem | - | - |
| 5 | Leader Pod | Response | - | - | - | - |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Knative Serving | Kubernetes API (CRD) | 6443/TCP | HTTPS | TLS 1.2+ | Create and manage Knative Services for serverless InferenceService deployments |
| Istio (Service Mesh) | Kubernetes API (CRD) | 6443/TCP | HTTPS | TLS 1.2+ | Create VirtualServices and DestinationRules for traffic routing, canary rollouts, and mTLS |
| Prometheus | HTTP Scrape | 8080/TCP | HTTP | None | Scrape metrics from controller and model server pods via ServiceMonitor |
| KEDA | Kubernetes API (CRD) | 6443/TCP | HTTPS | TLS 1.2+ | Create ScaledObjects for custom metrics-based autoscaling (queue depth, RPS) |
| OpenTelemetry | gRPC/HTTP | 4317/TCP, 4318/TCP | gRPC/HTTP | TLS 1.2+ | Send traces and metrics to OTel Collector for LLM inference observability |
| Gateway API | Kubernetes API (CRD) | 6443/TCP | HTTPS | TLS 1.2+ | Create HTTPRoutes for ingress as alternative to Istio VirtualServices |
| OpenShift Routes | Kubernetes API (CRD) | 6443/TCP | HTTPS | TLS 1.2+ | Create Routes for external ingress on OpenShift clusters |
| Event Mesh (Knative Eventing) | HTTP/CloudEvents | 80/TCP | HTTP | None | Send request/response logs as CloudEvents to brokers or sinks |
| S3-Compatible Storage | S3 API | 443/TCP | HTTPS | TLS 1.2+ | Download model artifacts during pod initialization |
| Google Cloud Storage | GCS API | 443/TCP | HTTPS | TLS 1.2+ | Download model artifacts from GCS buckets |
| Azure Blob Storage | Azure API | 443/TCP | HTTPS | TLS 1.2+ | Download model artifacts from Azure containers |

## Recent Changes

Based on recent commits (last 3 months on rhoai-2.25 branch):

| Commit | Date | Changes |
|--------|------|---------|
| 4211a5da7 | 2026-03 | - Sync Konflux pipelineruns with konflux-central configuration |
| 21d08f7b7 | 2026-03 | - Sync Konflux pipelineruns for automated builds |
| c151ad940 | 2026-03 | - Merge pull request #4133 for RHOAI 2.25 updates |
| 2bb03dff7 | 2026-03 | - Add RHOAI 2.25.0 to Konflux pipeline<br>- Disable hermetic build for storage initializer on ppc64le and s390x architectures |
| b75066923 | 2026-03 | - Fix build failure for storage initializer on ppc64le and s390x architectures |
| 92537eee3 | 2026-01 | - Merge pull request #4128 for security fix RHOAIENG-47407 |
| bb03ddbbe | 2026-01 | - **SECURITY**: Reject root path and narrow path traversal check in createNewFile to prevent directory traversal attacks |
| 16e11a862 | 2026-01 | - **SECURITY**: Prevent path traversal vulnerability in HTTPS storage downloader (#4796) |
| 4e4db3215 | 2026-01 | - Merge pull request #4126 for RHOAIENG-49718 |
| b6adeec7f | 2026-01 | - Remove unnecessary files from storage-initializer runtime container to reduce image size and attack surface |
| 67658a1ec | 2026-01 | - Merge remote-tracking branch from upstream stable-2.x into rhoai-2.25 |
| 76585dc13 | 2026-01 | - Add proxy configuration support (#1080) for environments requiring HTTP/HTTPS proxies |
| f476c74c7 | 2026-01 | - Update dependency lock file (#4091) |

**Key Themes:**
- **Multi-architecture support**: Fixes for ppc64le and s390x builds in Konflux pipeline
- **Security hardening**: Path traversal vulnerability fixes in storage components
- **Build optimization**: Container image size reduction and hermetic build improvements
- **Proxy support**: Enhanced support for corporate proxy environments
- **Konflux integration**: Continuous updates to Konflux CI/CD pipeline definitions for RHOAI builds
