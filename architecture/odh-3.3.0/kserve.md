# Component: KServe

## Metadata
- **Repository**: https://github.com/opendatahub-io/kserve
- **Version**: 0.17.0-rc0
- **Distribution**: ODH, RHOAI
- **Languages**: Go, Python
- **Deployment Type**: Operator + Serving Runtime

## Purpose
**Short**: Standardized platform for generative and predictive AI model inference on Kubernetes.

**Detailed**: KServe is a CNCF incubating project that provides a standardized, scalable, multi-framework model serving platform for both generative AI (LLMs) and predictive AI (traditional ML) workloads on Kubernetes. It supports advanced features including canary rollouts, autoscaling with scale-to-zero, intelligent request routing, inference graphs, and model explainability. KServe abstracts away infrastructure complexity, providing a simple InferenceService CRD while supporting enterprise-scale deployments with GPU acceleration, model caching, and OpenAI-compatible APIs. It supports multiple serving runtimes including vLLM, TensorFlow Serving, TorchServe, Triton Inference Server, and Hugging Face Transformers.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| KServe Controller Manager | Operator Controller | Reconciles InferenceService CRDs and manages model serving lifecycle |
| KServe Agent | Sidecar Agent | Manages model storage, logging, and batching within predictor pods |
| KServe Router | Traffic Router | Intelligent request routing between predictor, transformer, and explainer |
| LLM Inference Service Controller | Operator Controller | Manages LLM-specific inference services with vLLM/llm-d backends |
| Local Model Controller | Operator Controller | Manages local model caching and node-level model distribution |
| Local Model Node Controller | Node Agent | Node-level controller for local model management |
| Serving Runtime Containers | Model Server | Pluggable model serving containers (TensorFlow, PyTorch, Triton, vLLM, etc.) |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Defines a deployed model with predictor, transformer, and explainer |
| serving.kserve.io | v1alpha1 | TrainedModel | Namespaced | Represents a trained ML model stored externally |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Defines model server runtime configuration for a namespace |
| serving.kserve.io | v1alpha1 | ClusterServingRuntime | Cluster | Cluster-scoped serving runtime templates |
| serving.kserve.io | v1alpha1 | InferenceGraph | Namespaced | Defines multi-step inference pipelines and ensembles |
| serving.kserve.io | v1alpha1 | ClusterStorageContainer | Cluster | Cluster-scoped storage container configurations |
| serving.kserve.io | v1alpha1 | LLMInferenceService | Namespaced | LLM-specific inference service with vLLM/llm-d backend |
| serving.kserve.io | v1alpha1 | LLMInferenceServiceConfig | Namespaced | Configuration for LLM inference service templates |
| serving.kserve.io | v1alpha1 | LocalModelCache | Namespaced | Manages local model caching for fast loading |
| serving.kserve.io | v1alpha1 | LocalModelNode | Namespaced | Represents a node with local model cache |
| serving.kserve.io | v1alpha1 | LocalModelNodeGroup | Namespaced | Groups of nodes for local model distribution |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Controller liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Controller readiness probe |
| /v1/models/{name}:predict | POST | 8080/TCP | HTTP | TLS 1.2+ | Bearer/None | KServe v1 prediction API |
| /v2/models/{name}/infer | POST | 8080/TCP | HTTP | TLS 1.2+ | Bearer/None | KServe v2 inference protocol |
| /v1/chat/completions | POST | 8080/TCP | HTTPS | TLS 1.2+ | Bearer | OpenAI-compatible chat API for LLMs |
| /v1/completions | POST | 8080/TCP | HTTPS | TLS 1.2+ | Bearer | OpenAI-compatible completions API |
| /v1/models/{name}/explain | POST | 8080/TCP | HTTP | TLS 1.2+ | Bearer/None | Model explanation endpoint |
| /metrics | GET | 8080/TCP or 8082/TCP | HTTP | None | None | Prometheus metrics |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| inference.GRPCInferenceService | 9000/TCP | gRPC | TLS 1.2+ | mTLS/None | KServe v2 gRPC inference protocol |
| tensorflow.serving.PredictionService | 9000/TCP | gRPC | TLS 1.2+ | mTLS/None | TensorFlow Serving gRPC API |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.24+ | Yes | Container orchestration platform |
| Knative Serving | 1.10+ | No | Serverless deployment, autoscaling, traffic management |
| Istio | 1.17+ | No | Service mesh for mTLS, traffic routing, observability |
| cert-manager | 1.12+ | No | TLS certificate management for webhooks |
| Prometheus | 2.40+ | No | Metrics collection and monitoring |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | UI Integration | Model serving UI and monitoring |
| Model Registry | API | Model versioning and lineage tracking |
| ODH Operator | CRD | Managed via DataScienceCluster for ODH deployments |
| OpenShift Serverless | Knative | Serverless inference with autoscaling |
| OpenShift Service Mesh | Istio | mTLS, AuthZ, traffic management |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kserve-webhook-server-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | Webhook | Internal |
| {isvc-name}-predictor | ClusterIP or LoadBalancer | 8080/TCP | 8080 | HTTP or HTTPS | TLS 1.2+ | Bearer/mTLS | Internal/External |
| {isvc-name}-predictor-grpc | ClusterIP | 9000/TCP | 9000 | gRPC | TLS 1.2+ | mTLS | Internal |
| {isvc-name}-transformer | ClusterIP | 8080/TCP | 8080 | HTTP | TLS 1.2+ | Bearer | Internal |
| {isvc-name}-explainer | ClusterIP | 8080/TCP | 8080 | HTTP | TLS 1.2+ | Bearer | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {isvc-name}-ingress | Istio VirtualService | {isvc-name}.{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE/MUTUAL | External |
| {isvc-name}-grpc-ingress | Istio VirtualService | {isvc-name}-grpc.{namespace}.{domain} | 443/TCP | gRPC | TLS 1.2+ | SIMPLE/MUTUAL | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| S3/Minio | 443/TCP or 9000/TCP | HTTPS | TLS 1.2+ | AWS SigV4 | Model artifact download |
| GCS | 443/TCP | HTTPS | TLS 1.3 | OAuth2 | Model artifact download from Google Cloud Storage |
| Azure Blob | 443/TCP | HTTPS | TLS 1.3 | Azure AD | Model artifact download from Azure |
| HTTP/HTTPS URIs | 80/TCP or 443/TCP | HTTP/HTTPS | TLS 1.2+ | Various | Custom model storage locations |
| PVC | N/A | Local | N/A | None | Persistent volume model storage |
| Hugging Face Hub | 443/TCP | HTTPS | TLS 1.3 | API Token | Download models from Hugging Face |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kserve-manager-role | "" | configmaps, events, services | create, delete, get, list, patch, update, watch |
| kserve-manager-role | "" | namespaces, pods | get, list, watch |
| kserve-manager-role | "" | secrets | get |
| kserve-manager-role | apps | deployments | create, delete, get, list, patch, update, watch |
| kserve-manager-role | autoscaling | horizontalpodautoscalers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | inferenceservices, trainedmodels, servingruntimes, clusterservingruntimes, inferencegraphs | all |
| kserve-manager-role | serving.knative.dev | services, revisions | create, delete, get, list, patch, update, watch |
| kserve-manager-role | networking.istio.io | virtualservices, destinationrules | create, delete, get, list, patch, update, watch |
| kserve-manager-role | gateway.networking.k8s.io | httproutes | create, delete, get, list, patch, update, watch |
| kserve-manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | create, delete, get, list, patch, update, watch |
| llmisvc-manager-role | serving.kserve.io | llminferenceservices, llminferenceserviceconfigs | all |
| localmodel-manager-role | serving.kserve.io | localmodelcaches, localmodelnodes, localmodelnodegroups | all |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kserve-manager-rolebinding | kserve | kserve-manager-role | kserve-controller-manager |
| kserve-leader-election-rolebinding | kserve | leader-election-role | kserve-controller-manager |
| llmisvc-manager-rolebinding | kserve | llmisvc-manager-role | llmisvc-controller-manager |
| localmodel-manager-rolebinding | kserve | localmodel-manager-role | localmodel-controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| kserve-webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificates | cert-manager | Yes |
| storage-config | Opaque | S3/GCS/Azure storage credentials for model download | User/Admin | No |
| {isvc-name}-sa-token | kubernetes.io/service-account-token | Service account token for model server | Kubernetes | Yes |
| llm-api-key | Opaque | API keys for LLM providers (Hugging Face, OpenAI) | User | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /v1/models/* | POST | Bearer Token or mTLS | Istio AuthorizationPolicy | RBAC via K8s SA tokens |
| /v2/models/* | POST | Bearer Token or mTLS | Istio AuthorizationPolicy | RBAC via K8s SA tokens |
| /v1/chat/completions | POST | Bearer Token (API key) | Application Layer | Custom auth in LLM runtime |
| Webhook API | POST | mTLS | Webhook Server | Certificate validation |

## Data Flows

### Flow 1: Model Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Client | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | Bearer Token |
| 2 | KServe Controller | Kubernetes API (Deployment create) | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount |
| 3 | Model Server Pod Init | S3/Minio | 443/TCP or 9000/TCP | HTTPS | TLS 1.2+ | AWS SigV4 |
| 4 | Model Server Pod Init | PVC (optional) | N/A | Local | N/A | None |

### Flow 2: Inference Request (HTTP)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | Istio Ingress Gateway | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Istio Gateway | KServe Router (optional) | 8080/TCP | HTTP | mTLS | Service Identity |
| 3 | Router | Transformer (optional) | 8080/TCP | HTTP | mTLS | Service Identity |
| 4 | Transformer | Predictor | 8080/TCP | HTTP | mTLS | Service Identity |
| 5 | Predictor | Explainer (optional) | 8080/TCP | HTTP | mTLS | Service Identity |

### Flow 3: LLM Inference Request (OpenAI API)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client/SDK | OpenShift Route or Istio Gateway | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Ingress | LLM Inference Service (vLLM) | 8080/TCP | HTTP | mTLS | Service Identity |
| 3 | vLLM Runtime | GPU Memory | N/A | Local | N/A | None |
| 4 | vLLM Runtime (KV Cache) | CPU/Disk (offload) | N/A | Local | N/A | None |

### Flow 4: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | Model Server /metrics | 8080/TCP or 8082/TCP | HTTP | TLS 1.2+ | ServiceMonitor |
| 2 | Prometheus | Istio Envoy /metrics | 15090/TCP | HTTP | None | ServiceMonitor |
| 3 | Prometheus | KServe Controller /metrics | 8080/TCP | HTTP | None | ServiceMonitor |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Knative Serving | CRD | N/A | N/A | N/A | Serverless autoscaling and traffic management |
| Istio | CRD | N/A | N/A | N/A | Service mesh for mTLS, routing, observability |
| Kubernetes API | REST API | 6443/TCP | HTTPS | TLS 1.3 | Resource management and orchestration |
| S3/Minio | S3 API | 443/TCP or 9000/TCP | HTTPS | TLS 1.2+ | Model artifact storage |
| Prometheus | Scrape | 8080/TCP or 8082/TCP | HTTP | TLS 1.2+ | Metrics collection |
| Hugging Face Hub | REST API | 443/TCP | HTTPS | TLS 1.3 | Model download and caching |
| Model Registry | REST API | 443/TCP | HTTPS | TLS 1.2+ | Model versioning and lineage |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 0.17.0-rc0 | 2025-03 | - Add Prometheus metrics collection for LLMInferenceService<br>- Enforce runAsNonRoot for all LLMInferenceServiceConfig templates<br>- Add accelerator-specific LLMInferenceServiceConfig templates with labels<br>- Add Istio DestinationRules and CA-signed certs via build tags<br>- Add distro build tag hooks for platform-specific logic<br>- Log CloudEvents occurrence and record time<br>- Add Makefile.overrides.mk for midstream-only targets<br>- Resolve LWS leader address for ZMQ and increase /dev/shm<br>- Add CSV and Parquet marshallers<br>- Change kserve chart name to kserve-resources |
