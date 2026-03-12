# Component: ODH Model Controller

## Metadata
- **Repository**: https://github.com/opendatahub-io/odh-model-controller.git
- **Version**: $TAG_NAME-45-g3902d61
- **Distribution**: ODH and RHOAI (both)
- **Languages**: Go, YAML
- **Deployment Type**: Kubernetes Operator / Extension Controller

## Purpose
**Short**: Extension controller for KServe that adds OpenShift-specific integrations including ingress, routing, and LLM inference service management.

**Detailed**: The ODH Model Controller is a Kubernetes controller that extends KServe functionality with OpenShift-specific capabilities and additional model serving features. It watches KServe InferenceService and ServingRuntime resources to provide OpenShift Router integration for external model access, manage NVIDIA NIM (NVIDIA Inference Microservices) accounts and configurations for GPU-accelerated inference, orchestrate LLM inference services with flow control and authentication policies, integrate with Istio AuthorizationPolicy for service mesh security, manage ConfigMaps and Secrets for model serving runtimes, and handle serving runtime templates for various ML frameworks (TensorFlow, PyTorch, ONNX, MLServer, vLLM). The controller automatically creates OpenShift Routes and Kubernetes Gateway HTTPRoutes for model endpoints, manages NIM-specific resources for air-gapped deployments, and provides custom metrics for MLServer and other runtimes. It serves as a bridge between KServe's cloud-native model serving and OpenShift's platform features.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Model Controller | Go Controller | Extends KServe with OpenShift integrations and LLM support |
| InferenceService Controller | Reconciler | Manages OpenShift Routes and ingress for KServe InferenceServices |
| ServingRuntime Controller | Reconciler | Manages serving runtime templates and configurations |
| LLM InferenceService Controller | Reconciler | Orchestrates LLM inference services with flow control and auth |
| InferenceGraph Controller | Reconciler | Manages multi-model inference graphs |
| NIM Account Controller | Reconciler | Manages NVIDIA NIM accounts and NGC API integration |
| ConfigMap Controller | Watcher | Syncs NIM model configurations and runtime settings |
| Pod Controller | Watcher | Monitors model serving pod status and metrics |
| Secret Controller | Watcher | Manages NGC secrets and model serving credentials |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| nim.opendatahub.io | v1 | Account | Namespaced | Manage NVIDIA NIM accounts for GPU inference |
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Watched (not owned) - KServe InferenceService extension |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Watched (not owned) - KServe ServingRuntime extension |
| serving.kserve.io | v1alpha1 | InferenceGraph | Namespaced | Watched (not owned) - Multi-model inference graphs |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for controller and model serving |
| /healthz | GET | 8081/TCP | HTTP | None | None | Controller health check endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Controller readiness endpoint |

### gRPC Services
No gRPC services are exposed by the controller. Model serving endpoints use KServe's standard inference protocol.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| KServe | 0.14+ | Yes | Core model serving framework that this controller extends |
| NVIDIA NIM | Latest | No | NVIDIA Inference Microservices for GPU-accelerated serving |
| Istio | 1.20+ | No | Service mesh for mTLS, traffic routing, and AuthorizationPolicy |
| OpenShift Router | 4.x | Yes | Exposes InferenceService endpoints via OpenShift Routes |
| Kubernetes Gateway API | v1beta1 | No | Alternative ingress via HTTPRoutes |
| KEDA | 2.x | No | Auto-scaling for inference workloads based on metrics |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KServe | CRD Extension | Extends InferenceService and ServingRuntime resources |
| Model Registry | Integration | Links deployed models to registry metadata |
| ODH Dashboard | UI Integration | Provides model serving UI and management |
| S3 Storage | Model Storage | Access model artifacts for serving |
| TrustyAI | Sidecar Integration | Monitors model inferences for fairness and explainability |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| <inferenceservice>-predictor | ClusterIP | 80/TCP | 8080 | HTTP | TLS 1.2+ (Istio) | Bearer Token / mTLS | Internal |
| <inferenceservice>-predictor-grpc | ClusterIP | 81/TCP | 9000 | gRPC | mTLS (Istio) | cert | Internal |
| odh-model-controller-metrics | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| <inferenceservice>-route | OpenShift Route | *.apps.cluster | 443/TCP | HTTPS | TLS 1.2+ | Edge Termination | External |
| <inferenceservice>-httproute | Gateway HTTPRoute | *.apps.cluster | 443/TCP | HTTPS | TLS 1.2+ | Gateway TLS | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS credentials | Download model artifacts for serving |
| NVIDIA NGC API | 443/TCP | HTTPS | TLS 1.2+ | API Key | Download NIM models and configurations |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Token | Pull serving runtime container images |
| Model Registry API | 8080/TCP | HTTP | None | Bearer Token | Retrieve model metadata |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-model-controller-role | "" | services, configmaps, secrets, serviceaccounts, pods, namespaces, endpoints | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | serving.kserve.io | inferenceservices, servingruntimes, inferencegraphs | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | gateway.networking.k8s.io | gateways, httproutes | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | security.istio.io | authorizationpolicies | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | nim.opendatahub.io | accounts | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | networking.k8s.io | ingresses | get, list, watch |
| odh-model-controller-role | keda.sh | triggerauthentications, scaledobjects | create, delete, get, list, patch, update, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-model-controller-rolebinding | opendatahub | odh-model-controller-role | odh-model-controller |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| <nim-account>-ngc-secret | Opaque | NVIDIA NGC API key for NIM model downloads | User-provided | No |
| aws-s3-credentials | Opaque | S3 access credentials for model artifacts | User-provided | No |
| <inferenceservice>-sa-token | kubernetes.io/service-account-token | Service account token for KServe predictor pods | Kubernetes | Yes |
| istio-ca-cert | kubernetes.io/tls | Istio CA certificate for mTLS | cert-manager / Istio | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| InferenceService Predictor | GET, POST | Bearer Token / mTLS | Istio AuthorizationPolicy | Token validation or client cert |
| LLM InferenceService | GET, POST | Bearer Token + Flow Control | Istio AuthorizationPolicy | Token + rate limiting |
| Controller Metrics | GET | None | None | Internal access only |
| NIM API Calls | GET, POST | API Key | NGC Service | API key in request header |

## Data Flows

### Flow 1: InferenceService Creation with Route

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Dashboard | Kubernetes API (create InferenceService) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | KServe Controller | Predictor Pod (create) | N/A | N/A | N/A | N/A |
| 3 | ODH Model Controller | OpenShift Router (create Route) | N/A | N/A | N/A | N/A |
| 4 | Predictor Pod | S3 Storage (download model) | 443/TCP | HTTPS | TLS 1.2+ | AWS credentials |
| 5 | Client | OpenShift Route | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 6 | OpenShift Router | Predictor Pod | 8080/TCP | HTTP | mTLS (Istio) | mTLS cert |

### Flow 2: NIM Model Serving

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API (create Account CR) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | ODH Model Controller | NVIDIA NGC API | 443/TCP | HTTPS | TLS 1.2+ | API Key |
| 3 | ODH Model Controller | ConfigMap (create NIM config) | N/A | N/A | N/A | N/A |
| 4 | ODH Model Controller | InferenceService (create/update) | N/A | N/A | N/A | N/A |
| 5 | NIM Predictor Pod | NGC API (download model) | 443/TCP | HTTPS | TLS 1.2+ | API Key |
| 6 | Client | NIM Inference Endpoint | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |

### Flow 3: LLM InferenceService with Flow Control

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | OpenShift Route | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Istio Gateway | Istio AuthorizationPolicy (check) | N/A | N/A | N/A | N/A |
| 3 | Istio Proxy | LLM Predictor Pod | 8080/TCP | HTTP | mTLS | mTLS cert |
| 4 | LLM Predictor Pod | S3 Storage (model artifacts) | 443/TCP | HTTPS | TLS 1.2+ | AWS credentials |
| 5 | LLM Predictor Pod | Client (response) | 443/TCP | HTTPS | TLS 1.2+ | N/A |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| KServe Controller | CRD Watching | 6443/TCP | HTTPS | TLS 1.2+ | Extend InferenceService with OpenShift features |
| OpenShift Router | Resource Creation | N/A | N/A | N/A | Expose InferenceServices externally via Routes |
| Istio | AuthorizationPolicy CRD | 6443/TCP | HTTPS | TLS 1.2+ | Manage mTLS and auth policies for model endpoints |
| Kubernetes Gateway API | HTTPRoute CRD | 6443/TCP | HTTPS | TLS 1.2+ | Alternative ingress for InferenceServices |
| NVIDIA NGC API | HTTP API | 443/TCP | HTTPS | TLS 1.2+ | Download NIM models and retrieve configurations |
| S3 Storage | HTTP API | 443/TCP | HTTPS | TLS 1.2+ | Access model artifacts for serving |
| Prometheus | Metrics Scraping | 8080/TCP | HTTP | None | Collect controller and model serving metrics |
| KEDA | CRD Integration | 6443/TCP | HTTPS | TLS 1.2+ | Auto-scale inference workloads based on metrics |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 3902d61 | 2025-01 | - Add metrics support for MLServer runtime<br>- Update Tekton for ODH 3.4<br>- Add ONNX model format in MLServer ServingRuntime template<br>- Remove MaaS-related webhooks, AuthPolicy, and tiers<br>- Update KServe dependency |
| f003373 | 2025-01 | - FIPS Compliance: replace math/rand with crypto/rand<br>- Reduce RBAC permissions scope for odh-model-controller<br>- Make LLM ISVC AuthPolicy auth rules apply as OR<br>- Update runtime versions on rhoai-3.4ea1 branch |
| d563157 | 2024-12 | - Reduce NIM ConfigMap size by storing only required model fields<br>- Add workflows to update runtime and component versions<br>- Support flow control for LLMInferenceService<br>- Add K8s probes for MLServer template<br>- NIM air-gapped mode: skip external API calls and NGC secret injection |
