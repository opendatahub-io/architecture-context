# Component: KServe

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kserve
- **Version**: 7418735ff (based on v0.11.1)
- **Branch**: rhoai-2.6
- **Distribution**: RHOAI (Red Hat OpenShift AI)
- **Languages**: Go (controller/operator), Python (SDK and model servers)
- **Deployment Type**: Kubernetes Operator with Custom Resource Definitions

## Purpose
**Short**: KServe provides a Kubernetes-native platform for serving machine learning models with support for multiple frameworks, autoscaling, and advanced deployment patterns.

**Detailed**: KServe is a standard, cloud-agnostic model inference platform on Kubernetes that provides performant, high abstraction interfaces for serving ML models on frameworks like TensorFlow, XGBoost, ScikitLearn, PyTorch, ONNX, and others. It encapsulates the complexity of autoscaling (including GPU autoscaling and scale-to-zero), networking, health checking, and server configuration to provide enterprise-grade serving features like canary rollouts, A/B testing, and inference graphs for chaining models. The platform consists of a Go-based controller that manages custom resources and Python-based model servers that implement the actual inference endpoints. KServe integrates with Knative for serverless deployments and Istio for advanced traffic routing, providing both serverless and raw deployment modes for different use cases.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kserve-controller-manager | Go Operator | Kubernetes controller that reconciles InferenceService, InferenceGraph, TrainedModel, and ServingRuntime CRDs |
| kserve-webhook-server | Webhook Server | Admission webhook for validating and mutating InferenceService and related resources |
| agent | Go Service | Sidecar container providing request logging, batching, and model pulling capabilities |
| router | Go Service | Routes requests through InferenceGraph nodes for multi-model pipelines |
| storage-initializer | Python Init Container | Downloads models from cloud storage (S3, GCS, Azure, PVC) to local volumes |
| model-servers | Python Servers | Framework-specific servers (sklearn, xgboost, tensorflow, pytorch, triton, etc.) that serve predictions |
| Python SDK | Library | Client SDK and server framework for building custom model servers |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Primary resource for deploying ML models with predictor, transformer, and explainer components |
| serving.kserve.io | v1alpha1 | InferenceGraph | Namespaced | Defines multi-step inference pipelines with routing logic (sequence, switch, splitter, ensemble) |
| serving.kserve.io | v1alpha1 | TrainedModel | Namespaced | Represents trained model artifacts for multi-model serving use cases |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Defines namespace-scoped model server runtime configurations |
| serving.kserve.io | v1alpha1 | ClusterServingRuntime | Cluster | Defines cluster-scoped model server runtime configurations (e.g., kserve-sklearnserver, kserve-tensorflow-serving) |
| serving.kserve.io | v1alpha1 | ClusterStorageContainer | Cluster | Configures storage initialization for model downloads |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /mutate-serving-kserve-io-v1beta1-inferenceservice | POST | 443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Mutating webhook for InferenceService resources |
| /validate-serving-kserve-io-v1beta1-inferenceservice | POST | 443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Validating webhook for InferenceService resources |
| /mutate-pods | POST | 443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Pod mutation for adding agent sidecar and storage initializer |
| /validate-serving-kserve-io-v1alpha1-trainedmodel | POST | 443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Validating webhook for TrainedModel resources |
| /validate-serving-kserve-io-v1alpha1-inferencegraph | POST | 443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Validating webhook for InferenceGraph resources |
| /validate-serving-kserve-io-v1alpha1-servingruntime | POST | 443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Validating webhook for ServingRuntime resources |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | Prometheus scraping | Controller manager metrics endpoint |
| /v1/models/{model_name}:predict | POST | 8080/TCP | HTTP | None | Optional Bearer Token | Model inference endpoint (KServe v1 protocol) |
| /v2/models/{model_name}/infer | POST | 8080/TCP | HTTP | None | Optional Bearer Token | Model inference endpoint (KServe v2 protocol) |
| /v1/models/{model_name} | GET | 8080/TCP | HTTP | None | Optional Bearer Token | Model metadata endpoint |
| /v2/models/{model_name}/ready | GET | 8080/TCP | HTTP | None | None | Model readiness probe |
| / | POST | 8080/TCP | HTTP | None | Optional Bearer Token | InferenceGraph router endpoint |
| /healthz | GET | 9081/TCP | HTTP | None | None | Agent health check endpoint |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| inference.GRPCInferenceService | 8081/TCP | gRPC/HTTP2 | None | Optional mTLS | Model inference (KServe v2 gRPC protocol) |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.23+ | Yes | Container orchestration platform |
| Istio | 1.15+ | No | Service mesh for traffic routing and mTLS (optional for serverless mode) |
| Knative Serving | 0.26+ | No | Serverless workload management (required for serverless deployment mode) |
| cert-manager | 1.9+ | No | TLS certificate management for webhooks (OpenShift uses service-ca instead) |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ServiceMesh (Istio) | Istio VirtualService CRD | Creates routing rules for InferenceService endpoints |
| Authorino | Authorization Policy | External authorization for model endpoints (RHOAI integration) |
| S3 Storage | HTTP/S3 API | Stores and retrieves trained model artifacts |
| Model Registry | REST API | Tracks model versions and metadata (optional integration) |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kserve-webhook-server-service | ClusterIP | 443/TCP | webhook-server (9443) | HTTPS | TLS 1.2+ | Kubernetes API Server cert | Internal |
| kserve-controller-manager-service | ClusterIP | 8443/TCP | https | HTTPS | TLS 1.2+ | mTLS | Internal |
| {isvc-name}-predictor | ClusterIP | 80/TCP | 8080 | HTTP | None | Optional Bearer/mTLS | Internal |
| {isvc-name}-transformer | ClusterIP | 80/TCP | 8080 | HTTP | None | Optional Bearer/mTLS | Internal |
| {isvc-name}-explainer | ClusterIP | 80/TCP | 8080 | HTTP | None | Optional Bearer/mTLS | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {isvc-name} VirtualService | Istio VirtualService | {name}-{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External |
| InferenceService Knative Route | Knative Route | {name}.{namespace}.svc.cluster.local | 80/TCP | HTTP | None | N/A | Internal |
| istio-ingressgateway | Istio Gateway | *.{ingressDomain} | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| S3 endpoints (AWS/Minio) | 443/TCP | HTTPS | TLS 1.2+ | AWS Signature v4 / Secret Key | Download model artifacts |
| GCS endpoints | 443/TCP | HTTPS | TLS 1.2+ | GCP Service Account JSON | Download model artifacts |
| Azure Blob Storage | 443/TCP | HTTPS | TLS 1.2+ | Azure Storage Key | Download model artifacts |
| Knative Eventing Broker | 80/TCP | HTTP | None | None | Send inference request/response logs |
| External explainer services | 8080/TCP | HTTP | None | Optional Bearer Token | Invoke external explanation services |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kserve-manager-role | serving.kserve.io | inferenceservices, inferenceservices/finalizers, inferenceservices/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | inferencegraphs, inferencegraphs/finalizers, inferencegraphs/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | trainedmodels, trainedmodels/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | servingruntimes, servingruntimes/finalizers, servingruntimes/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | clusterservingruntimes, clusterservingruntimes/finalizers, clusterservingruntimes/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | clusterstoragecontainers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.knative.dev | services, services/finalizers, services/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | networking.istio.io | virtualservices, virtualservices/finalizers, virtualservices/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | apps | deployments | create, delete, get, list, patch, update, watch |
| kserve-manager-role | autoscaling | horizontalpodautoscalers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | "" (core) | services, secrets, configmaps | create, delete, get, list, patch, update, watch |
| kserve-manager-role | "" (core) | namespaces, pods, serviceaccounts | get, list, watch |
| kserve-manager-role | "" (core) | events | create, delete, get, list, patch, update, watch |
| kserve-manager-role | networking.k8s.io | ingresses | create, delete, get, list, patch, update, watch |
| kserve-manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | create, delete, get, list, patch, update, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kserve-manager-rolebinding | cluster-wide | kserve-manager-role (ClusterRole) | kserve-controller-manager |
| kserve-leader-election-rolebinding | kserve | leader-election-role (Role) | kserve-controller-manager |
| kserve-proxy-rolebinding | kserve | kserve-proxy-role (ClusterRole) | kserve-controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| kserve-webhook-server-cert | kubernetes.io/tls | TLS certificate for admission webhooks | cert-manager or service-ca-operator (OpenShift) | Yes |
| kserve-webhook-server-secret | Opaque | Webhook server configuration | KServe installer | No |
| storage-config | Opaque | S3/GCS/Azure credentials for model downloads (optional) | User | No |
| {sa-name}-token | kubernetes.io/service-account-token | Service account tokens for model server pods | Kubernetes | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| Webhook endpoints | POST | mTLS (Kubernetes API Server cert) | kserve-webhook-server (Go native TLS) | Kubernetes API server verifies webhook TLS |
| InferenceService predictor | POST, GET | Optional Bearer Token / Istio mTLS | Istio sidecar / Authorino | Configured via Istio AuthorizationPolicy |
| Controller metrics | GET | mTLS (optional) | Prometheus ServiceMonitor | OpenShift monitoring RBAC |
| Model inference (user-facing) | POST, GET | Optional Bearer Token / Istio mTLS | Istio Ingress Gateway / VirtualService | Configured per-InferenceService |
| Storage download | GET | AWS IAM / GCP SA / Azure SAS / Secret | storage-initializer init container | Cloud provider IAM or static credentials |

## Data Flows

### Flow 1: Model Deployment and Serving

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API | 443/TCP | HTTPS | TLS 1.3 | Bearer Token (kubeconfig) |
| 2 | Kubernetes API | kserve-webhook-server | 443/TCP | HTTPS | TLS 1.2+ | mTLS (API server cert) |
| 3 | kserve-controller-manager | Kubernetes API | 443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |
| 4 | kserve-controller-manager | Knative/Istio APIs | 443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |
| 5 | storage-initializer (init) | S3/GCS/Azure | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM / GCP SA / Azure Key |
| 6 | Model Server Pod | Local Volume (/mnt/models) | N/A | Filesystem | None | None |

### Flow 2: Inference Request (External → Model)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | Istio Ingress Gateway | 443/TCP | HTTPS | TLS 1.3 | Optional Bearer Token |
| 2 | Istio Ingress Gateway | Istio VirtualService | 80/TCP | HTTP | mTLS (Istio sidecar) | Istio Peer Authentication |
| 3 | Istio VirtualService | Knative Service (if serverless) | 80/TCP | HTTP | mTLS (Istio sidecar) | Istio Authorization Policy |
| 4 | Knative Activator | Model Server Pod (agent sidecar) | 9081/TCP | HTTP | None | None |
| 5 | Agent Sidecar | Model Server Container | 8080/TCP | HTTP | None | None |
| 6 | Agent Sidecar | Knative Eventing Broker (logs) | 80/TCP | HTTP | None | None |

### Flow 3: InferenceGraph Multi-Model Pipeline

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | Router Service | 8080/TCP | HTTP | Optional TLS | Optional Bearer Token |
| 2 | Router | First InferenceService | 80/TCP | HTTP | Optional mTLS | Optional Token |
| 3 | First InferenceService | Second InferenceService | 80/TCP | HTTP | Optional mTLS | Optional Token |
| 4 | Router | Client | 80/TCP | HTTP | Optional TLS | N/A |

### Flow 4: Explainer Request

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | InferenceService (/explain endpoint) | 443/TCP | HTTPS | TLS 1.3 | Optional Bearer Token |
| 2 | Explainer Container | Predictor Service | 80/TCP | HTTP | Optional mTLS | None |
| 3 | Explainer Container | Model Storage | 8080/TCP | HTTP | None | None |
| 4 | Explainer Container | Client | 80/TCP | HTTP | Optional TLS | N/A |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Knative Serving | Kubernetes API (CRD) | 443/TCP | HTTPS | TLS 1.3 | Create serverless Services for InferenceService pods with autoscaling |
| Istio Service Mesh | Kubernetes API (CRD) | 443/TCP | HTTPS | TLS 1.3 | Create VirtualServices for traffic routing and canary deployments |
| Prometheus | HTTP scraping | 8080/TCP | HTTP | None | Scrape model server and agent metrics for monitoring |
| Knative Eventing | CloudEvents/HTTP | 80/TCP | HTTP | None | Send inference request/response logs to event brokers |
| S3-compatible storage | S3 API | 443/TCP | HTTPS | TLS 1.2+ | Store and retrieve model artifacts |
| Container Registry | Docker Registry API | 443/TCP | HTTPS | TLS 1.2+ | Pull model server and runtime images |
| OpenShift Service CA | Kubernetes API (annotation) | 443/TCP | HTTPS | TLS 1.3 | Generate TLS certificates for webhooks (RHOAI-specific) |
| Authorino | Kubernetes API (CRD) | 443/TCP | HTTPS | TLS 1.3 | Configure external authorization for InferenceService endpoints (RHOAI) |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 7418735ff | 2024 | - Merge pull request #61: Update image SHAs<br>- Update image SHAs with builds of commit 1093de3 |
| 1093de3b4 | 2024 | - Merge pull request #60: Cherry-pick changes for RHOAI 2.6<br>- Merge branch rhods_master into rhods_2.6_cherry_pick |
| 31e193d52 | 2024 | - Merge pull request #58: Disable git actions for 2.6 branch<br>- Disable all gitaction for 2.6 branch |
| 1e1c35b53 | 2024 | - Merge pull request #174: RHOAIENG-1995<br>- Fix Authentication Bypass by Primary Weakness |
| 1bf8e83a0 | 2024 | - Merge pull request #172: RHOAIENG-1943<br>- Fix (sdk-go) Denial of Service (DoS) vulnerability |
| b9a7fc9e7 | 2024 | - Update the image tag to refer latest images of rhoai-2.6 |
| 3075720a4 | 2024 | - Empty commit to trigger new image build |
| 38a814c7f | 2024 | - Merge pull request #170: RHOAIENG-1463<br>- Update knative-serving dependency |
| cf3a3dfd0 | 2024 | - Merge pull request #171: RHOAIENG-1778<br>- Fixes vulnerabilities on the otelhttp dependency |
| fa314ef12 | 2024 | - Fixes CVE-2023-37788 - github.com/elazarl/goproxy Denial of Service (DoS) |
| 1889f7ea0 | 2024 | - Fix Stack-based Buffer Overflow on protobuf |
| f0b51d062 | 2024 | - Fixes CVE-2023-48795 (SSH vulnerability) |

## Additional Notes

### Deployment Modes

KServe supports three deployment modes configured via the `deploy` ConfigMap section:

1. **Serverless** (default): Uses Knative Serving for scale-to-zero and request-based autoscaling
2. **RawDeployment**: Uses standard Kubernetes Deployments without Knative dependencies
3. **ModelMesh**: High-density multi-model serving for frequently changing models (separate component)

### Storage Initializer

The storage-initializer runs as an init container in model server pods and supports:
- **S3**: AWS S3, MinIO, and S3-compatible storage with IAM or static credentials
- **GCS**: Google Cloud Storage with service account JSON credentials
- **Azure**: Azure Blob Storage with storage account keys
- **PVC**: Direct mounting of PersistentVolumeClaims
- **HTTP/HTTPS**: Direct URI downloads

### Model Server Runtimes

Pre-configured ClusterServingRuntimes included:
- **kserve-sklearnserver**: Scikit-learn models (v1, v2 protocol)
- **kserve-xgbserver**: XGBoost models
- **kserve-lgbserver**: LightGBM models
- **kserve-tensorflow-serving**: TensorFlow SavedModel format
- **kserve-torchserve**: PyTorch TorchServe (.mar archives)
- **kserve-tritonserver**: NVIDIA Triton Inference Server (multi-framework)
- **kserve-pmmlserver**: PMML model format
- **kserve-paddleserver**: PaddlePaddle models
- **kserve-mlserver**: Multi-framework server supporting MLflow, Hugging Face

### Protocol Support

KServe supports two inference protocols:
- **V1 Protocol**: TensorFlow Serving API format (`/v1/models/{name}:predict`)
- **V2 Protocol**: KServe/Triton inference protocol (`/v2/models/{name}/infer`) with gRPC support

### High Availability

- Controller manager runs as single replica (leader election enabled)
- Model server pods can be scaled horizontally via HPA or Knative autoscaling
- No persistent state in controller (all state in Kubernetes etcd)
