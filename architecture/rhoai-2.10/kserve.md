# Component: KServe

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kserve
- **Version**: c3b84e599 (rhoai-2.10)
- **Distribution**: RHOAI
- **Languages**: Go, Python
- **Deployment Type**: Kubernetes Operator
- **Manifests Location**: config/kserve

## Purpose
**Short**: KServe is a Kubernetes operator that provides standardized, serverless ML model serving with autoscaling, multi-framework support, and advanced deployment patterns.

**Detailed**: KServe provides a Kubernetes Custom Resource Definition for serving machine learning models on arbitrary frameworks. It aims to solve production model serving use cases by providing performant, high abstraction interfaces for common ML frameworks like TensorFlow, XGBoost, ScikitLearn, PyTorch, ONNX, HuggingFace, and others. The operator encapsulates the complexity of autoscaling, networking, health checking, and server configuration to bring cutting edge serving features like GPU Autoscaling, Scale to Zero, and Canary Rollouts to ML deployments.

KServe enables a complete production ML serving story including prediction, pre-processing, post-processing, and explainability. It supports three deployment modes: Serverless (using Knative for request-based autoscaling), RawDeployment (lightweight Kubernetes deployments), and ModelMesh (high-scale, high-density model serving). The operator integrates with Istio for advanced traffic management and supports model storage from S3, GCS, PVC, and OCI registries.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kserve-controller-manager | Kubernetes Controller | Main operator that reconciles InferenceService, ServingRuntime, TrainedModel, and InferenceGraph CRDs |
| kserve-webhook-server | Admission Webhook | Validates and mutates InferenceService and related resources, injects sidecars into pods |
| kserve-agent | Sidecar Container | Provides logging, batching, and metrics aggregation for model servers |
| kserve-router | Inference Router | Implements InferenceGraph routing to orchestrate multi-model inference pipelines |
| storage-initializer | Init Container | Downloads model artifacts from S3, GCS, PVC, or OCI registries before model server starts |
| Model Server Runtimes | Python Services | Framework-specific inference servers (sklearn, xgboost, tensorflow, pytorch, huggingface, etc.) |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Primary CRD for deploying ML models with predictor, transformer, and explainer components |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Defines runtime templates for model servers (container image, ports, protocols, supported model formats) |
| serving.kserve.io | v1alpha1 | TrainedModel | Namespaced | Represents a trained model artifact with storage location and serving runtime reference |
| serving.kserve.io | v1alpha1 | InferenceGraph | Namespaced | Defines multi-step inference pipelines with routing logic between models |
| serving.kserve.io | v1alpha1 | ClusterStorageContainer | Cluster | Cluster-scoped storage container definitions for model initialization |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Controller manager liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Controller manager readiness probe |
| /mutate-serving-kserve-io-v1beta1-inferenceservice | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (K8s API) | Mutating webhook for InferenceService resources |
| /validate-serving-kserve-io-v1beta1-inferenceservice | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (K8s API) | Validating webhook for InferenceService resources |
| /mutate-pods | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (K8s API) | Pod mutating webhook for sidecar injection |
| /validate-serving-kserve-io-v1alpha1-trainedmodel | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (K8s API) | Validating webhook for TrainedModel resources |
| /validate-serving-kserve-io-v1alpha1-inferencegraph | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (K8s API) | Validating webhook for InferenceGraph resources |
| /validate-serving-kserve-io-v1alpha1-servingruntime | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (K8s API) | Validating webhook for ServingRuntime resources |
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint (controller manager) |
| /v1/models/{model_name}:predict | POST | 8080/TCP | HTTP/HTTPS | TLS (optional) | Bearer/None | V1 inference protocol prediction endpoint (model servers) |
| /v2/models/{model_name}/infer | POST | 8080/TCP | HTTP/HTTPS | TLS (optional) | Bearer/None | V2 inference protocol endpoint (model servers) |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| inference.GRPCInferenceService | 8081/TCP | gRPC | mTLS (optional) | Token/mTLS | V2 gRPC inference protocol for model servers |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.24+ | Yes | Platform for running operator and model workloads |
| Knative Serving | 1.8+ | Optional | Serverless deployment mode with request-based autoscaling and scale-to-zero |
| Istio | 1.16+ | Optional | Service mesh for traffic management, virtual services, and ingress gateway |
| cert-manager | 1.9+ | Yes | Webhook certificate provisioning and rotation |
| S3-compatible Storage | Any | Optional | Model artifact storage (AWS S3, MinIO, etc.) |
| Google Cloud Storage | Any | Optional | Model artifact storage |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Service Mesh (Istio) | VirtualService CRD | KServe creates Istio VirtualServices for traffic routing and canary deployments |
| Knative Serving | Knative Service CRD | KServe creates Knative Services in serverless mode for autoscaling |
| Model Registry | API (future) | Optional integration for model metadata and lineage tracking |
| Data Science Pipelines | API | Model deployment from pipeline runs |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kserve-controller-manager-service | ClusterIP | 8443/TCP | https | HTTPS | TLS 1.2+ | mTLS | Internal (metrics) |
| kserve-webhook-server-service | ClusterIP | 443/TCP | webhook-server (9443) | HTTPS | TLS 1.2+ | mTLS | Internal (K8s API server) |
| {isvc-name}-predictor | ClusterIP/Knative | 80/TCP, 443/TCP | 8080 | HTTP/HTTPS | TLS (Istio) | Bearer/mTLS | Internal/External (via Istio Gateway) |
| {isvc-name}-transformer | ClusterIP/Knative | 80/TCP, 443/TCP | 8080 | HTTP/HTTPS | TLS (Istio) | Bearer/mTLS | Internal |
| {isvc-name}-explainer | ClusterIP/Knative | 80/TCP, 443/TCP | 8080 | HTTP/HTTPS | TLS (Istio) | Bearer/mTLS | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {isvc-name} VirtualService | Istio VirtualService | {isvc-name}.{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE/MUTUAL | External (via Istio Gateway) |
| Knative Ingress Gateway | Istio Gateway | knative-serving/knative-ingress-gateway | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External |
| Knative Local Gateway | Istio Gateway | knative-serving/knative-local-gateway | 80/TCP | HTTP | None | N/A | Internal (cluster) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| S3 endpoint | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Access Key | Model artifact download from S3-compatible storage |
| GCS endpoint | 443/TCP | HTTPS | TLS 1.2+ | GCP Service Account | Model artifact download from Google Cloud Storage |
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | CRD reconciliation and resource management |
| Knative Serving API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Creating and managing Knative Services |
| Istio Pilot (istiod) | 15012/TCP | gRPC | mTLS | mTLS | Service mesh configuration and certificate management |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kserve-manager-role | serving.kserve.io | inferenceservices, inferenceservices/finalizers, inferenceservices/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | servingruntimes, servingruntimes/finalizers, servingruntimes/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | trainedmodels, trainedmodels/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | inferencegraphs, inferencegraphs/finalizers, inferencegraphs/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | clusterstoragecontainers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.knative.dev | services, services/finalizers, services/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | networking.istio.io | virtualservices, virtualservices/finalizers, virtualservices/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | apps | deployments | create, delete, get, list, patch, update, watch |
| kserve-manager-role | "" (core) | services, configmaps, secrets, pods, namespaces, events | create, delete, get, list, patch, update, watch |
| kserve-manager-role | "" (core) | serviceaccounts | get |
| kserve-manager-role | autoscaling | horizontalpodautoscalers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | networking.k8s.io | ingresses | create, delete, get, list, patch, update, watch |
| kserve-manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | create, delete, get, list, patch, update, watch |
| kserve-leader-election-role | "" (core) | configmaps | create, get, update |
| kserve-leader-election-role | coordination.k8s.io | leases | create, get, update |
| kserve-proxy-role | authentication.k8s.io | tokenreviews | create |
| kserve-proxy-role | authorization.k8s.io | subjectaccessreviews | create |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kserve-manager-rolebinding | cluster-scoped | kserve-manager-role (ClusterRole) | kserve-controller-manager |
| kserve-leader-election-rolebinding | kserve | kserve-leader-election-role (Role) | kserve-controller-manager |
| kserve-proxy-rolebinding | kserve | kserve-proxy-role (ClusterRole) | kserve-controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| kserve-webhook-server-cert | kubernetes.io/tls | TLS certificate for webhook server HTTPS endpoints | cert-manager | Yes |
| kserve-webhook-server-secret | Opaque | Additional webhook server secrets (deprecated) | Manual | No |
| storage-config | Opaque | S3/GCS credentials for model storage access (user-provided) | User/Admin | No |
| {sa-name}-token | kubernetes.io/service-account-token | ServiceAccount token for model pods to access K8s API | Kubernetes | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| Webhook endpoints | POST | mTLS client certificate | kube-apiserver | K8s API server validates webhook service CA bundle |
| Inference endpoints (external) | GET, POST | Bearer Token (JWT) / OAuth2 | Istio AuthorizationPolicy | Configured per InferenceService via Istio policies |
| Inference endpoints (internal) | GET, POST | mTLS (service mesh) | Istio PeerAuthentication | PERMISSIVE or STRICT mode based on mesh config |
| Controller metrics | GET | None (internal only) | NetworkPolicy | Restricted to cluster internal access |
| Model storage (S3) | GET | AWS IAM Role / Access Key | storage-initializer | Credentials in storage-config secret or IAM for SA |
| Model storage (GCS) | GET | GCP Service Account JSON | storage-initializer | Credentials in storage-config secret |

## Data Flows

### Flow 1: InferenceService Creation and Model Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (kubeconfig) |
| 2 | Kubernetes API | kserve-webhook-server | 443/TCP (service) -> 9443/TCP | HTTPS | TLS 1.2+ | mTLS (CA bundle) |
| 3 | kserve-webhook-server | Kubernetes API (response) | - | HTTPS | TLS 1.2+ | mTLS |
| 4 | kserve-controller-manager | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | kserve-controller-manager | Knative API (serverless mode) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 6 | kserve-controller-manager | Istio API (VirtualService) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: Model Inference Request (Serverless Mode)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | Istio Ingress Gateway | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (optional) |
| 2 | Istio Ingress Gateway | Knative Activator (if scaled to zero) | 8012/TCP | HTTP | mTLS (Istio) | mTLS |
| 3 | Knative Activator | Predictor Pod | 8080/TCP | HTTP | mTLS (Istio) | mTLS |
| 4 | storage-initializer (init) | S3/GCS endpoint | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/GCS SA |
| 5 | Predictor Pod | storage-initializer volume | local | - | - | - |
| 6 | kserve-agent (sidecar) | Model Server (same pod) | 8080/TCP | HTTP | None (localhost) | None |
| 7 | Model Server | kserve-agent (response) | - | HTTP | None (localhost) | None |

### Flow 3: InferenceGraph Multi-Model Pipeline

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | Istio Ingress Gateway | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (optional) |
| 2 | Istio Ingress Gateway | kserve-router | 8080/TCP | HTTP | mTLS (Istio) | mTLS |
| 3 | kserve-router | Preprocessing InferenceService | 80/TCP | HTTP | mTLS (Istio) | mTLS |
| 4 | kserve-router | Main Model InferenceService | 80/TCP | HTTP | mTLS (Istio) | mTLS |
| 5 | kserve-router | Postprocessing InferenceService | 80/TCP | HTTP | mTLS (Istio) | mTLS |
| 6 | kserve-router | Client (response) | - | HTTP | TLS 1.2+ (via Istio) | - |

### Flow 4: Model Update with Canary Rollout

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API (update InferenceService) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | kserve-controller-manager | Knative API (create new revision) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | kserve-controller-manager | Istio API (update traffic split) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Istio VirtualService | Predictor v1 (90% traffic) | 80/TCP | HTTP | mTLS (Istio) | mTLS |
| 5 | Istio VirtualService | Predictor v2 (10% traffic) | 80/TCP | HTTP | mTLS (Istio) | mTLS |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Knative Serving | CRD (Knative Service) | 6443/TCP | HTTPS | TLS 1.2+ | KServe creates Knative Services for serverless autoscaling and traffic routing |
| Istio Service Mesh | CRD (VirtualService) | 6443/TCP | HTTPS | TLS 1.2+ | KServe creates VirtualServices for ingress, traffic splitting, and canary rollouts |
| Istio Ingress Gateway | HTTP/HTTPS proxy | 443/TCP | HTTPS | TLS 1.2+ | External traffic entry point, routes to InferenceServices based on hostname |
| cert-manager | Certificate CRD | 6443/TCP | HTTPS | TLS 1.2+ | Automatic webhook certificate provisioning via Certificate resources |
| Kubernetes API Server | Webhook callback | 9443/TCP | HTTPS | TLS 1.2+ | API server calls webhook endpoints for admission control |
| S3-compatible storage | S3 API | 443/TCP | HTTPS | TLS 1.2+ | storage-initializer downloads model artifacts using S3 SDK |
| Google Cloud Storage | GCS API | 443/TCP | HTTPS | TLS 1.2+ | storage-initializer downloads model artifacts using GCS SDK |
| Prometheus | Metrics scraping | 8080/TCP | HTTP | None | Prometheus scrapes controller and model server metrics |
| OpenShift Service Mesh | ServiceMeshMember | 6443/TCP | HTTPS | TLS 1.2+ | Integration with OpenShift Service Mesh for multi-tenant isolation |
| Model Registry (future) | REST API | 443/TCP | HTTPS | TLS 1.2+ | Model metadata retrieval for lineage and versioning |

## Deployment Modes

KServe supports three deployment modes (configured via `deploy.defaultDeploymentMode` in inferenceservice-config ConfigMap):

### Serverless Mode (Default in RHOAI)
- **Description**: Uses Knative Serving for request-based autoscaling including scale-to-zero
- **Dependencies**: Knative Serving, Istio
- **Features**: Automatic scaling, GPU autoscaling, canary rollouts, traffic splitting
- **Use Case**: Cost-effective serving with variable traffic patterns

### RawDeployment Mode
- **Description**: Standard Kubernetes Deployments without serverless features
- **Dependencies**: Kubernetes only (Istio optional)
- **Features**: Simpler architecture, HPA-based autoscaling
- **Use Case**: Always-on services, environments without Knative

### ModelMesh Mode
- **Description**: High-density multi-model serving with intelligent routing
- **Dependencies**: ModelMesh controller
- **Features**: In-memory model loading/unloading, resource pooling, low-latency serving
- **Use Case**: Large number of small models, cost optimization

## Configuration

### Key ConfigMaps

| ConfigMap Name | Namespace | Purpose | Key Configuration Options |
|----------------|-----------|---------|---------------------------|
| inferenceservice-config | kserve | Global configuration for InferenceService behavior | defaultDeploymentMode, ingress settings, storage initializer config, agent/router images |

### Important Configuration Fields

| Field | Location | Default | Purpose |
|-------|----------|---------|---------|
| defaultDeploymentMode | inferenceservice-config/deploy | "Serverless" | Controls default deployment mode (Serverless/RawDeployment/ModelMesh) |
| ingressGateway | inferenceservice-config/ingress | "knative-serving/knative-ingress-gateway" | Istio gateway for external traffic |
| storageInitializer.image | inferenceservice-config | "kserve/storage-initializer:latest" | Container image for model download init container |
| agent.image | inferenceservice-config | "kserve/agent:latest" | Container image for logging/batching sidecar |
| router.image | inferenceservice-config | "kserve/router:latest" | Container image for InferenceGraph router |

## Model Server Runtimes

KServe includes built-in runtimes for popular ML frameworks:

| Runtime Name | Framework | Protocol | Image | Features |
|--------------|-----------|----------|-------|----------|
| kserve-sklearnserver | Scikit-learn | V1, V2 | Python-based | Joblib, pickle model loading |
| kserve-xgbserver | XGBoost | V1, V2 | Python-based | Native XGBoost format |
| kserve-tensorflow-serving | TensorFlow | V1, V2, gRPC | TensorFlow Serving | Optimized C++ runtime, GPU support |
| kserve-torchserve | PyTorch | V1, V2 | TorchServe | TorchScript, eager mode |
| kserve-tritonserver | Multi-framework | V2, gRPC | NVIDIA Triton | TensorRT, ONNX, TensorFlow, PyTorch |
| kserve-huggingfaceserver | HuggingFace | V1, V2 | Python-based | Transformers library, auto model loading |
| kserve-lgbserver | LightGBM | V1, V2 | Python-based | Native LightGBM format |
| kserve-pmmlserver | PMML | V1, V2 | Python-based | PMML standard format |
| kserve-paddleserver | PaddlePaddle | V1, V2 | Python-based | PaddlePaddle framework |
| kserve-mlserver | Multi-framework | V2 | Seldon MLServer | Extensible Python runtime |

## Recent Changes

| Commit | Date | Changes |
|---------|------|---------|
| c3b84e599 | Recent | - Merge pull request #555: Update Konflux references for rhoai-2.10 |
| 891ccb4ed | Recent | - Update Konflux references |
| 08e3d7328 | Recent | - Merge pull request #662: RHOAIENG-13713-2.10 |
| 695669875 | Recent | - [RHOAIENG-13713] Fix CVE-2024-6119 - Type Confusion vulnerability |
| f54d214bd | Recent | - Fix apiGroups in aggregate roles on manifests |
| 0330418f7 | Recent | - Merge pull request #386: Component updates for kserve-storage-initializer-210 |
| 39a2f161a | Recent | - Update kserve-storage-initializer-210 to eca4267 |
| 76f003a97 | Recent | - Merge pull request #385: Component updates for kserve-router-210 |
| afe1a6fb2 | Recent | - Update kserve-router-210 to 0478db5 |
| 8c9c5e296 | Recent | - Merge pull request #383: Component updates for kserve-agent-210 |
| 0248b9d80 | Recent | - Update kserve-agent-210 to 632b1b1 |
| dc8f02d68 | Recent | - Update Konflux references for rhoai-2.10 |
| ba8174b66 | Recent | - Update Konflux references |
| 8466a1d75 | Recent | - Component updates for kserve-router-210 |
| 9332b0b8f | Recent | - Merge branch rhoai-2.10 into component updates |
| b9b49ea55 | Recent | - Component updates for kserve-storage-initializer-210 |
| ebd437736 | Recent | - Update kserve-storage-initializer-210 to 3c4e69f |
| 4d921836d | Recent | - Component updates for kserve-agent-210 |
| 9a3594628 | Recent | - Update kserve-router-210 to 477048b |
| 04de5ed63 | Recent | - Update kserve-agent-210 to ff852cd |

## Known Limitations

1. **ClusterServingRuntime**: Not supported in ODH/RHOAI (commented out in kustomization), only namespaced ServingRuntime is available
2. **Multi-tenancy**: Namespace-scoped resources only; cluster-wide runtime definitions not available
3. **Storage**: ModelMesh mode requires separate installation and configuration
4. **Istio Dependency**: Serverless mode requires Istio for advanced networking features
5. **Knative Dependency**: Serverless mode requires Knative Serving for autoscaling capabilities

## Operational Considerations

### Resource Requirements

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| kserve-controller-manager | 100m | 100m | 200Mi | 300Mi |
| storage-initializer (init) | 100m | 1 | 100Mi | 1Gi |
| kserve-agent (sidecar) | 100m | 1 | 100Mi | 1Gi |
| kserve-router | 100m | 1 | 100Mi | 1Gi |

### Health Checks

| Component | Liveness Path | Readiness Path | Port | Initial Delay |
|-----------|---------------|----------------|------|---------------|
| kserve-controller-manager | /healthz | /readyz | 8081/TCP | 10s |

### Monitoring

| Metric Type | Endpoint | Port | Purpose |
|-------------|----------|------|---------|
| Controller Metrics | /metrics | 8080/TCP | Controller reconciliation metrics, queue depth, error rates |
| Model Server Metrics | /metrics | 8080/TCP | Inference latency, throughput, error rates (framework-specific) |
| Queue Proxy Metrics | /metrics | 9090/TCP | Request queue metrics, autoscaling signals (Knative) |

## Troubleshooting Guide

### Common Issues

1. **InferenceService stuck in "Unknown" state**
   - Check: kserve-controller-manager logs
   - Check: Knative Service status (serverless mode)
   - Check: Deployment status (raw mode)

2. **Model download failures**
   - Check: storage-initializer init container logs
   - Verify: S3/GCS credentials in storage-config secret
   - Verify: Network policies allow egress to storage endpoints

3. **Webhook certificate errors**
   - Check: cert-manager is running and has created Certificate
   - Verify: kserve-webhook-server-cert secret exists
   - Check: CA bundle injection in webhook configurations

4. **Traffic routing issues**
   - Check: Istio VirtualService created correctly
   - Verify: Ingress gateway configuration
   - Check: DNS resolution for InferenceService hostname

## References

- **Upstream Documentation**: https://kserve.github.io/website/
- **API Reference**: https://kserve.github.io/website/master/reference/api/
- **Developer Guide**: https://kserve.github.io/website/master/developer/developer/
- **Inference Protocols**: https://kserve.github.io/website/master/modelserving/data_plane/
- **OpenShift Guide**: https://github.com/kserve/kserve/blob/master/docs/OPENSHIFT_GUIDE.md
