# Component: KServe

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kserve
- **Version**: v0.15 (commit c694cea31)
- **Branch**: rhoai-3.3
- **Distribution**: RHOAI
- **Languages**: Go (controller), Python (SDK, serving runtimes)
- **Deployment Type**: Kubernetes Operator with multiple components

## Purpose
**Short**: KServe provides Kubernetes-native model serving for predictive and generative ML models with standardized inference protocols and autoscaling.

**Detailed**: KServe is a production-ready model serving platform for Kubernetes that provides high abstraction interfaces for serving TensorFlow, XGBoost, scikit-learn, PyTorch, Hugging Face Transformer/LLM models, and more. It implements standardized data plane protocols including OpenAI specification for generative models. The platform encapsulates the complexity of autoscaling (including GPU autoscaling and scale-to-zero), networking, health checking, and server configuration. KServe supports both serverless deployment (via Knative) and raw Kubernetes deployment modes, enabling advanced deployment patterns like canary rollouts, multi-model inference graphs, and high-density model serving. For RHOAI, it serves as the core inference serving layer integrating with OpenShift's security model and Istio service mesh.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kserve-controller-manager | Kubernetes Operator (Go) | Main reconciliation controller managing InferenceService, ServingRuntime, InferenceGraph, and LLM inference resources |
| kserve-webhook-server | Admission Webhook (Go) | Validates and mutates InferenceService, ServingRuntime, TrainedModel, InferenceGraph, and pod resources |
| storage-initializer | Init Container (Python) | Downloads ML models from S3, GCS, Azure Blob, PVC, or OCI registries before serving containers start |
| agent | Sidecar Container (Go) | Provides logging, request batching, and monitoring capabilities for inference pods |
| router | Deployment (Go) | Routes requests through InferenceGraph multi-model pipelines with header propagation |
| localmodel-manager | Controller (Go) | Manages local model caching on cluster nodes for improved performance |
| localmodelnode-agent | DaemonSet (Go) | Node-level agent for local model cache management and reconciliation |
| llm-scheduler | Service (Go) | Schedules and manages LLM inference workloads with disaggregated prefill/decode architecture |
| Python Serving Runtimes | Containers (Python) | Framework-specific serving containers (sklearn, xgboost, pytorch, huggingface, triton, etc.) |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Primary API for deploying ML models with predictor, transformer, and explainer components |
| serving.kserve.io | v1alpha1 | ClusterServingRuntime | Cluster | Cluster-wide template defining how to serve models of specific frameworks |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Namespace-scoped template defining how to serve models of specific frameworks |
| serving.kserve.io | v1alpha1 | InferenceGraph | Namespaced | Defines multi-step inference pipelines routing requests through multiple models |
| serving.kserve.io | v1alpha1 | TrainedModel | Namespaced | References trained models that can be loaded into multi-model serving runtimes |
| serving.kserve.io | v1alpha1 | ClusterStorageContainer | Cluster | Cluster-wide storage container configuration for model storage backends |
| serving.kserve.io | v1alpha1 | LocalModelCache | Namespaced | Defines local disk caching strategy for frequently accessed models |
| serving.kserve.io | v1alpha1 | LocalModelNode | Cluster | Represents a node's local model cache capabilities and state |
| serving.kserve.io | v1alpha1 | LocalModelNodeGroup | Cluster | Groups nodes with similar local model caching capabilities |
| serving.kserve.io | v1 | LLMInferenceService | Namespaced | Specialized inference service for large language models with disaggregated architecture |
| serving.kserve.io | v1 | LLMInferenceServiceConfig | Namespaced | Configuration for LLM inference services (scheduler, router, worker templates) |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /mutate-serving-kserve-io-v1beta1-inferenceservice | POST | 443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Mutating webhook for InferenceService resources |
| /validate-serving-kserve-io-v1beta1-inferenceservice | POST | 443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Validating webhook for InferenceService resources |
| /validate-serving-kserve-io-v1alpha1-trainedmodel | POST | 443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Validating webhook for TrainedModel resources |
| /validate-serving-kserve-io-v1alpha1-inferencegraph | POST | 443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Validating webhook for InferenceGraph resources |
| /validate-serving-kserve-io-v1alpha1-clusterservingruntime | POST | 443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Validating webhook for ClusterServingRuntime resources |
| /validate-serving-kserve-io-v1alpha1-servingruntime | POST | 443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Validating webhook for ServingRuntime resources |
| /validate-serving-kserve-io-v1alpha1-localmodelcache | POST | 443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Validating webhook for LocalModelCache resources |
| /validate-serving-kserve-io-v1-llminferenceservice | POST | 443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Validating webhook for LLMInferenceService resources |
| /validate-serving-kserve-io-v1-llminferenceserviceconfig | POST | 443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Validating webhook for LLMInferenceServiceConfig resources |
| /mutate-pods | POST | 443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Mutating webhook for pods with inferenceservice label |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token (ServiceAccount) | Prometheus metrics endpoint for controller |
| /healthz | GET | 8081/TCP | HTTP | None | None | Controller liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Controller readiness probe |
| /v1/models/:name:predict | POST | 8000/TCP | HTTP/HTTPS | TLS (optional) | Bearer/None | KServe v1 prediction endpoint (runtime-specific) |
| /v1/models/:name:explain | POST | 8000/TCP | HTTP/HTTPS | TLS (optional) | Bearer/None | KServe v1 explainability endpoint (runtime-specific) |
| /v2/models/:name/infer | POST | 8000/TCP | HTTP/HTTPS | TLS (optional) | Bearer/None | KServe v2 (NVIDIA Triton) inference endpoint |
| /openai/v1/completions | POST | 8000/TCP | HTTP/HTTPS | TLS (optional) | Bearer Token | OpenAI-compatible completions endpoint (LLM runtimes) |
| /openai/v1/chat/completions | POST | 8000/TCP | HTTP/HTTPS | TLS (optional) | Bearer Token | OpenAI-compatible chat completions endpoint (LLM runtimes) |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| inference.GRPCInferenceService | 8081/TCP | gRPC/HTTP2 | TLS (optional) | mTLS (optional) | KServe v2 gRPC inference protocol for high-performance inference |
| LLMScheduler | 9003/TCP | gRPC/HTTP2 | TLS (optional) | mTLS (optional) | LLM request scheduling and routing for disaggregated serving |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Knative Serving | v1.x | No (serverless mode only) | Provides serverless autoscaling, revision management, and traffic routing |
| Istio | v1.x | No (recommended) | Service mesh for traffic management, VirtualServices, and DestinationRules |
| cert-manager | v1.x | Yes | Manages TLS certificates for webhook server (self-signed issuer) |
| KEDA | v2.x | No (optional) | Advanced autoscaling for raw deployment mode with custom metrics |
| OpenTelemetry Operator | v1beta1 | No (optional) | Metrics collection and export for autoscaling and observability |
| Prometheus Operator | v1.x | No (optional) | ServiceMonitor and PodMonitor resources for metrics scraping |
| Gateway API | v1.x | No (optional) | Alternative to Istio for ingress/egress traffic management |
| LeaderWorkerSet | v1.x | No (multi-node LLM only) | Manages multi-node distributed LLM inference workloads |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Service Mesh (OSSM) | Istio VirtualServices, DestinationRules, Gateways | Traffic routing, mTLS, canary deployments, and external ingress |
| OpenShift Routes | Route resources | Exposes inference services externally via OpenShift router |
| ODH Dashboard | API/UI | Provides user interface for creating and managing InferenceServices |
| OpenShift OAuth | OAuth Proxy (auth-proxy sidecar) | Authentication for controller metrics endpoint |
| Model Registry | Storage Integration | Stores and versions trained models accessed via storage-initializer |
| Data Science Pipelines | MLflow/S3 Integration | Inference services consume models produced by pipeline runs |
| Authorino | Authorization Policies | Optional external authorization for inference endpoints |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kserve-controller-manager-service | ClusterIP | 8443/TCP | https | HTTPS | TLS 1.2+ | Bearer Token | Internal |
| kserve-webhook-server-service | ClusterIP | 443/TCP | webhook-server (9443) | HTTPS | TLS 1.2+ | K8s API Server mTLS | Internal |
| <isvc-name>-predictor | ClusterIP or Knative Service | 8000/TCP | 8000 | HTTP/HTTPS | TLS (optional via Istio) | Bearer/None | Internal/External via VirtualService |
| <isvc-name>-transformer | ClusterIP or Knative Service | 8000/TCP | 8000 | HTTP/HTTPS | TLS (optional via Istio) | Bearer/None | Internal |
| <isvc-name>-explainer | ClusterIP or Knative Service | 8000/TCP | 8000 | HTTP/HTTPS | TLS (optional via Istio) | Bearer/None | Internal |
| <graph-name>-router | ClusterIP | 8000/TCP | 8000 | HTTP/HTTPS | TLS (optional via Istio) | Bearer/None | Internal/External via VirtualService |
| llm-scheduler | ClusterIP | 9003/TCP | 9003 | gRPC/HTTP2 | TLS (optional via Istio) | Bearer/None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| <isvc-name> VirtualService | Istio VirtualService | <isvc>-<namespace>.<domain> | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External (via Istio IngressGateway) |
| <isvc-name> Route | OpenShift Route | <isvc>-<namespace>.<domain> | 443/TCP | HTTPS | TLS 1.2+ | edge/reencrypt | External (via OpenShift Router) |
| <graph-name> VirtualService | Istio VirtualService | <graph>-<namespace>.<domain> | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External (via Istio IngressGateway) |
| Gateway API HTTPRoute | HTTPRoute | <isvc>-<namespace>.<domain> | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External (Gateway API mode) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| S3-compatible storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/AccessKey | Model artifact download from S3 buckets |
| Google Cloud Storage | 443/TCP | HTTPS | TLS 1.2+ | GCP Service Account | Model artifact download from GCS buckets |
| Azure Blob Storage | 443/TCP | HTTPS | TLS 1.2+ | Azure credentials | Model artifact download from Azure storage |
| Container Registries | 443/TCP | HTTPS | TLS 1.2+ | Registry credentials | Pull OCI model images (modelcar feature) |
| Knative Eventing Broker | 8080/TCP | HTTP | None/TLS via Istio | None | Send inference request/response logs |
| External Explainability Services | 8000/TCP | HTTP/HTTPS | TLS (optional) | Bearer/None | Call external explainer models |
| Prometheus Pushgateway | 9091/TCP | HTTP | None | None | Push custom metrics |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kserve-manager-role | serving.kserve.io | inferenceservices, inferenceservices/finalizers, inferenceservices/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | clusterservingruntimes, clusterservingruntimes/finalizers, clusterservingruntimes/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | servingruntimes, servingruntimes/finalizers, servingruntimes/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | inferencegraphs, inferencegraphs/finalizers, inferencegraphs/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | trainedmodels, trainedmodels/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | llminferenceservices, llminferenceservices/finalizers, llminferenceservices/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | llminferenceserviceconfigs, llminferenceserviceconfigs/finalizers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | localmodelcaches | get, list, watch |
| kserve-manager-role | serving.kserve.io | clusterstoragecontainers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.knative.dev | services, services/finalizers, services/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | networking.istio.io | virtualservices, virtualservices/finalizers, virtualservices/status, destinationrules | create, delete, get, list, patch, update, watch |
| kserve-manager-role | apps | deployments | create, delete, get, list, patch, update, watch |
| kserve-manager-role | "" (core) | services, serviceaccounts, secrets, events, configmaps | create, delete, get, list, patch, update, watch |
| kserve-manager-role | "" (core) | namespaces, pods | get, list, watch |
| kserve-manager-role | autoscaling | horizontalpodautoscalers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | networking.k8s.io | ingresses | create, delete, get, list, patch, update, watch |
| kserve-manager-role | route.openshift.io | routes, routes/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | gateway.networking.k8s.io | gatewayclasses, gateways, httproutes | create, delete, get, list, patch, update, watch |
| kserve-manager-role | keda.sh | scaledobjects, scaledobjects/finalizers, scaledobjects/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | monitoring.coreos.com | servicemonitors, podmonitors | create, delete, get, list, patch, update, watch |
| kserve-manager-role | opentelemetry.io | opentelemetrycollectors, opentelemetrycollectors/finalizers, opentelemetrycollectors/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | leaderworkerset.x-k8s.io | leaderworkersets | create, delete, get, list, patch, update, watch |
| kserve-manager-role | inference.networking.k8s.io, inference.networking.x-k8s.io | inferencepools, inferencemodels, inferenceobjectives | create, delete, get, list, patch, update, watch |
| kserve-manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | create, delete, get, list, patch, update, watch |
| kserve-manager-role | rbac.authorization.k8s.io | clusterrolebindings, rolebindings, roles | create, delete, get, list, patch, update, watch |
| kserve-manager-role | authentication.k8s.io | tokenreviews, subjectaccessreviews | create |
| kserve-manager-role | security.openshift.io | securitycontextconstraints (openshift-ai-llminferenceservice-scc) | use |
| kserve-manager-role | discovery.k8s.io | endpointslices | get, list, watch |
| kserve-manager-role | "" (non-resource URLs) | /metrics | get |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kserve-leader-election-rolebinding | kserve | kserve-leader-election-role | kserve-controller-manager |
| kserve-manager-rolebinding | kserve (ClusterRoleBinding) | kserve-manager-role | kserve-controller-manager |
| kserve-proxy-rolebinding | kserve | kserve-proxy-role | kserve-controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| kserve-webhook-server-cert | kubernetes.io/tls | TLS certificate for webhook server | cert-manager (selfsigned-issuer) | No (self-signed) |
| storage-config | Opaque | Default S3/GCS credentials for model download | User/Admin | No |
| <custom-secret> | Opaque | Per-service storage credentials referenced via annotation | User | No |
| <sa>-token | kubernetes.io/service-account-token | ServiceAccount token for RBAC | Kubernetes | Yes (auto-rotation) |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics (controller) | GET | Bearer Token (OAuth Proxy) | kube-rbac-proxy sidecar | Requires system:serviceaccount:kserve:kserve-controller-manager |
| Webhook endpoints | POST | mTLS (client cert) | Kubernetes API Server | API Server validates webhook service certificate |
| InferenceService endpoints | GET, POST | Bearer Token (optional) | Istio AuthorizationPolicy or Authorino | Configured per-InferenceService via annotations |
| InferenceService endpoints | GET, POST | mTLS (optional) | Istio PeerAuthentication | Can require mTLS for all traffic in namespace |
| Storage download (S3) | GET | AWS IAM (IRSA) or Access Keys | storage-initializer | Uses credentials from secret or ServiceAccount annotations |
| Storage download (GCS) | GET | GCP Workload Identity or Service Account Key | storage-initializer | Uses GOOGLE_APPLICATION_CREDENTIALS or Workload Identity |

## Data Flows

### Flow 1: Model Deployment and Inference Request

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Dashboard | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (OAuth) |
| 2 | Kubernetes API Server | kserve-webhook-server | 443/TCP | HTTPS | TLS 1.2+ | mTLS (API Server client cert) |
| 3 | kserve-controller-manager | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (ServiceAccount) |
| 4 | storage-initializer (init container) | S3/GCS/Azure Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/GCP SA/Azure credentials |
| 5 | External Client | Istio IngressGateway or OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (optional) |
| 6 | Istio IngressGateway | InferenceService VirtualService | Internal | HTTP/HTTPS | mTLS (optional via Istio) | Bearer Token (optional) |
| 7 | Knative/Istio Routing | Predictor Pod | 8000/TCP | HTTP/HTTPS | TLS via Istio (optional) | Bearer Token (optional) |
| 8 | Predictor (if logging enabled) | Knative Eventing Broker | 8080/TCP | HTTP | TLS via Istio (optional) | None |

### Flow 2: InferenceGraph Multi-Model Pipeline

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | Istio IngressGateway | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (optional) |
| 2 | Istio IngressGateway | Router Service (InferenceGraph) | 8000/TCP | HTTP/HTTPS | mTLS (optional via Istio) | Bearer Token (propagated) |
| 3 | Router | Step 1 InferenceService (preprocessor) | 8000/TCP | HTTP/HTTPS | mTLS (optional via Istio) | Bearer Token (propagated) |
| 4 | Router | Step 2 InferenceService (predictor) | 8000/TCP | HTTP/HTTPS | mTLS (optional via Istio) | Bearer Token (propagated) |
| 5 | Router | Step 3 InferenceService (postprocessor) | 8000/TCP | HTTP/HTTPS | mTLS (optional via Istio) | Bearer Token (propagated) |
| 6 | Router | External Client (response) | Return path | HTTP/HTTPS | TLS 1.2+ | N/A |

### Flow 3: LLM Disaggregated Inference (Prefill/Decode)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | Istio IngressGateway | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (optional) |
| 2 | Istio IngressGateway | LLM Router Service | 8000/TCP | HTTP/HTTPS | mTLS (optional via Istio) | Bearer Token (optional) |
| 3 | LLM Router | LLM Scheduler | 9003/TCP | gRPC/HTTP2 | mTLS (optional via Istio) | None |
| 4 | LLM Scheduler | Prefill Worker (LeaderWorkerSet) | 8000/TCP | HTTP/gRPC | mTLS (optional via Istio) | None |
| 5 | LLM Scheduler | Decode Worker (LeaderWorkerSet) | 8001/TCP | HTTP/gRPC | mTLS (optional via Istio) | None |
| 6 | LLM Router | External Client (streaming response) | Return path | HTTP/HTTPS | TLS 1.2+ | N/A |

### Flow 4: Local Model Cache

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | localmodel-manager | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (ServiceAccount) |
| 2 | localmodel-manager | Kubernetes Job (download) | N/A | N/A | N/A | ServiceAccount |
| 3 | Download Job Pod (storage-initializer) | S3/GCS Storage | 443/TCP | HTTPS | TLS 1.2+ | Storage credentials |
| 4 | Download Job Pod | Node PersistentVolume | N/A | Filesystem | None | Filesystem permissions (fsGroup: 1000) |
| 5 | localmodelnode-agent (DaemonSet) | Local Disk | N/A | Filesystem | None | Filesystem permissions |
| 6 | InferenceService Pod | Local PV (direct mount) | N/A | Filesystem | None | Filesystem permissions |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API Client | 6443/TCP | HTTPS | TLS 1.2+ | Create/update/watch resources (Deployments, Services, etc.) |
| Knative Serving | Knative Service CRs | 6443/TCP | HTTPS (K8s API) | TLS 1.2+ | Serverless deployment with autoscaling and revision management |
| Istio Control Plane | VirtualService/DestinationRule CRs | 6443/TCP | HTTPS (K8s API) | TLS 1.2+ | Traffic routing, canary deployments, mTLS enforcement |
| cert-manager | Certificate CRs | 6443/TCP | HTTPS (K8s API) | TLS 1.2+ | Request and renew TLS certificates for webhooks |
| KEDA | ScaledObject CRs | 6443/TCP | HTTPS (K8s API) | TLS 1.2+ | Custom metric-based autoscaling (raw deployment mode) |
| OpenTelemetry Operator | OpenTelemetryCollector CRs | 6443/TCP | HTTPS (K8s API) | TLS 1.2+ | Deploy OTel collectors for metrics scraping and export |
| Prometheus Operator | ServiceMonitor/PodMonitor CRs | 6443/TCP | HTTPS (K8s API) | TLS 1.2+ | Configure Prometheus to scrape inference metrics |
| OpenShift OAuth | OAuth Proxy (sidecar) | 8443/TCP | HTTPS | TLS 1.2+ | Protect controller metrics with OpenShift authentication |
| LeaderWorkerSet Operator | LeaderWorkerSet CRs | 6443/TCP | HTTPS (K8s API) | TLS 1.2+ | Manage multi-node distributed inference workloads |
| Gateway API | Gateway/HTTPRoute CRs | 6643/TCP | HTTPS (K8s API) | TLS 1.2+ | Alternative ingress management (when enabled) |

## Recent Changes

Based on the last 20 commits in the rhoai-3.3 branch:

| Commit | Date | Changes |
|--------|------|---------|
| c694cea31 | 5 days ago | - Handle missing LeaderWorkerSet CRD in multi-node workload reconciliation<br>- Improves resilience when LeaderWorkerSet CRD is not installed |
| aa3ff703f | 9 days ago | - Sync Konflux pipeline runs with konflux-central repository |
| 6cf4df992 | 3 weeks ago | - Merge pull request for storage initializer fixes |
| 5bb530bc6 | 3 weeks ago | - Add RHOAI 3.3.0 to Konflux pipeline<br>- Disable hermetic build for storage initializer |
| ec447ab9d | 3 weeks ago | - Fix build failure for storage initializer on ppc64le and s390x architectures |
| 3833f373e | 4 weeks ago | - Backport restart handling improvements to rhoai-3.3 |
| e5d28ca12 | 4 weeks ago | - Handle Predictor/Decoder upgrade scenarios |
| c73c4cc75 | 5 weeks ago | - Scheduler component upgrade for RHOAI 3.3 |
| 1109795cd | 4 weeks ago | - Storage initializer upgrade for RHOAI 3.3 |
| 766c1afaf | 5 weeks ago | - RHOAIENG-48696: Preserve existing auth proxy containers during 2.x to 3.x upgrade |
| 16a07d667 | 5 weeks ago | - RHOAIENG-34472: Support auto-migration to InferencePool v1 API |
| ddf201abe | 5 weeks ago | - RHOAIENG-34472: Fix conversion between InferencePool v1alpha2 and v1<br>- Evaluate v1 readiness conditions |
| 56ccad630 | 5 weeks ago | - Support auto-migration to InferencePool v1 (backported from v0.15) |
| f0a95fadf | 6 weeks ago | - Merge cherry-pick PR for vLLM updates |
| 5c3ef9d7f | 6 weeks ago | - Update vLLM block-size parameter configuration |
| d5d9ffc08 | 6 weeks ago | - Remove deprecated enable-auth annotation |
| dea21d5cb | 6 weeks ago | - Update precise prefix cache sample configuration |

**Key Themes**:
- Multi-architecture support improvements (ppc64le, s390x)
- Konflux build system integration and pipeline updates
- LLM inference improvements (scheduler, disaggregated architecture)
- Upgrade path enhancements (2.x to 3.x migration, auth proxy preservation)
- InferencePool API v1 migration
- vLLM runtime configuration updates
- Stability improvements (LeaderWorkerSet CRD handling)
