# Component: KServe

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kserve
- **Version**: 80cb15e08 (rhoai-2.7 branch)
- **Distribution**: RHOAI
- **Languages**: Go (1.20), Python
- **Deployment Type**: Kubernetes Operator with Multi-Runtime Model Serving

## Purpose
**Short**: Kubernetes Custom Resource Definition (CRD) operator for serving machine learning models with serverless inference, autoscaling, and multi-framework support.

**Detailed**: KServe provides a production-grade platform for deploying, managing, and serving machine learning models on Kubernetes. It abstracts the complexity of model serving by providing high-level CRDs (InferenceService, ServingRuntime, InferenceGraph) that encapsulate autoscaling, networking, health checking, canary rollouts, and multi-framework support (TensorFlow, PyTorch, Scikit-learn, XGBoost, ONNX, etc.). The operator integrates with Knative for serverless deployment (scale-to-zero, request-based autoscaling) and Istio for advanced networking (traffic splitting, VirtualServices). KServe supports multiple deployment modes: Serverless (Knative-based), RawDeployment (standard Kubernetes), and ModelMesh (high-density model serving).

The architecture consists of a Go-based controller manager that reconciles InferenceService CRDs into Knative Services or Kubernetes Deployments, with Python-based model servers for different ML frameworks. An agent sidecar handles model downloading, logging, and batching. The storage initializer downloads models from S3, GCS, Azure, or PVC storage before serving starts. Explainers (Alibi, ART) provide model interpretability, while the router component enables multi-step inference pipelines via InferenceGraph.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kserve-controller-manager | Go Operator (Deployment) | Reconciles InferenceService, ServingRuntime, InferenceGraph CRDs; creates Knative Services or K8s Deployments; manages webhooks |
| agent | Go Sidecar Container | Model pulling, logging, batching, model lifecycle management |
| router | Go Sidecar Container | Routes inference requests for InferenceGraph multi-step pipelines |
| storage-initializer | Python Init Container | Downloads models from S3, GCS, Azure, PVC before pod starts |
| sklearnserver | Python Model Server | Serves scikit-learn models via REST/gRPC with v1/v2 protocol |
| xgbserver | Python Model Server | Serves XGBoost models via REST/gRPC with v1/v2 protocol |
| lgbserver | Python Model Server | Serves LightGBM models via REST/gRPC with v1/v2 protocol |
| paddleserver | Python Model Server | Serves PaddlePaddle models via REST/gRPC with v1/v2 protocol |
| pmmlserver | Python Model Server | Serves PMML models via REST/gRPC with v1/v2 protocol |
| alibiexplainer | Python Explainer | Model interpretability using Alibi library |
| artexplainer | Python Explainer | Adversarial robustness testing using ART library |
| aiffairness | Python Component | Fairness metrics and bias detection |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Main resource for deploying ML models with predictor, transformer, explainer components |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Defines model serving runtime (container, supported formats, protocol) for namespace |
| serving.kserve.io | v1alpha1 | ClusterServingRuntime | Cluster | Defines model serving runtime (container, supported formats, protocol) cluster-wide |
| serving.kserve.io | v1alpha1 | InferenceGraph | Namespaced | Multi-step inference pipeline with routing between nodes |
| serving.kserve.io | v1alpha1 | TrainedModel | Namespaced | Represents a trained model artifact with storage location and framework |
| serving.kserve.io | v1alpha1 | ClusterStorageContainer | Cluster | Storage container configuration for model downloads |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /mutate-serving-kserve-io-v1beta1-inferenceservice | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Mutating webhook for InferenceService CRDs |
| /validate-serving-kserve-io-v1beta1-inferenceservice | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Validating webhook for InferenceService CRDs |
| /mutate-pods | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Pod mutation for agent/storage-initializer injection |
| /validate-serving-kserve-io-v1alpha1-trainedmodel | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Validating webhook for TrainedModel CRDs |
| /validate-serving-kserve-io-v1alpha1-inferencegraph | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Validating webhook for InferenceGraph CRDs |
| /validate-serving-kserve-io-v1alpha1-servingruntime | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Validating webhook for ServingRuntime CRDs |
| /v1/models/:name:predict | POST | 8080/TCP | HTTP | None | None/Token | KServe v1 inference protocol for model predictions |
| /v2/models/:name/infer | POST | 8080/TCP | HTTP | None | None/Token | KServe v2 inference protocol for model predictions |
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics from model servers |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| inference.GRPCInferenceService | 8081/TCP | gRPC | None/mTLS | None/Token | KServe v2 gRPC inference protocol for model predictions |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Knative Serving | v0.39.3 | Optional (Serverless mode) | Serverless deployment, scale-to-zero, request autoscaling |
| Istio | v1.x | Optional (Serverless mode) | Service mesh, VirtualServices, traffic splitting, mTLS |
| Kubernetes | v1.26+ | Yes | Core platform for CRDs, webhooks, controllers |
| cert-manager | v1.x | Optional | Automated TLS certificate provisioning for webhooks |
| AWS S3 | N/A | Optional | Model artifact storage |
| Google Cloud Storage | N/A | Optional | Model artifact storage |
| Azure Blob Storage | N/A | Optional | Model artifact storage |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Service Mesh (Istio) | Istio VirtualService CRDs | Traffic routing, canary deployments, A/B testing for inference services |
| Knative Serving | Knative Service CRDs | Serverless model serving with autoscaling and scale-to-zero |
| Model Registry | Storage URI | Model artifact location metadata |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kserve-controller-manager-service | ClusterIP | 8443/TCP | https | HTTPS | TLS | mTLS | Internal |
| kserve-webhook-server-service | ClusterIP | 443/TCP | webhook-server (9443) | HTTPS | TLS | K8s API Server mTLS | Internal |
| {isvc-name}-predictor | ClusterIP/Knative | 8080/TCP | 8080 | HTTP | None | Optional Token | Internal/External (via Ingress) |
| {isvc-name}-transformer | ClusterIP/Knative | 8080/TCP | 8080 | HTTP | None | Optional Token | Internal |
| {isvc-name}-explainer | ClusterIP/Knative | 8080/TCP | 8080 | HTTP | None | Optional Token | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {isvc-name} VirtualService | Istio VirtualService | {name}-{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External |
| knative-ingress-gateway | Istio Gateway | *.{domain} | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External |
| {isvc-name} Ingress | Kubernetes Ingress | {name}-{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External (RawDeployment mode) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| s3.amazonaws.com | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Access Keys | Download model artifacts from S3 |
| storage.googleapis.com | 443/TCP | HTTPS | TLS 1.2+ | GCP Service Account | Download model artifacts from GCS |
| blob.core.windows.net | 443/TCP | HTTPS | TLS 1.2+ | Azure Storage Key | Download model artifacts from Azure |
| Knative Activator | 8012/TCP | HTTP | None | None | Serverless traffic routing (scale-from-zero) |
| Istio Pilot | 15010/TCP | gRPC | mTLS | Service Account Token | Service mesh control plane |

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
| kserve-manager-role | "" | services, secrets, configmaps | create, delete, get, list, patch, update, watch |
| kserve-manager-role | "" | pods, namespaces, serviceaccounts | get, list, watch |
| kserve-manager-role | autoscaling | horizontalpodautoscalers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | networking.k8s.io | ingresses | create, delete, get, list, patch, update, watch |
| kserve-manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | create, delete, get, list, patch, update, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kserve-manager-rolebinding | kserve | kserve-manager-role | kserve-controller-manager |
| kserve-leader-election-rolebinding | kserve | kserve-leader-election-role | kserve-controller-manager |
| kserve-auth-proxy-rolebinding | kserve | kserve-auth-proxy-role | kserve-controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| kserve-webhook-server-cert | kubernetes.io/tls | TLS certificate for webhook server HTTPS endpoint | cert-manager | Yes |
| storage-config | Opaque | S3/GCS/Azure credentials for model downloads | User/Admin | No |
| {sa-name}-token | kubernetes.io/service-account-token | Service account token for K8s API access | Kubernetes | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| Webhook endpoints (/mutate-*, /validate-*) | POST | mTLS client certificate | kserve-webhook-server-service | K8s API server validates client cert |
| Inference endpoints (/v1/models/*, /v2/models/*) | POST | Optional Bearer Token | Model server container | Optional token validation |
| Prometheus metrics (/metrics) | GET | None | Model server container | No authentication (internal) |
| Controller manager metrics | GET | K8s RBAC + kube-rbac-proxy | kserve-controller-manager-service | ServiceAccount token validation |

## Data Flows

### Flow 1: Model Deployment via InferenceService

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User kubectl | K8s API Server | 6443/TCP | HTTPS | TLS 1.2+ | kubeconfig client cert |
| 2 | K8s API Server | kserve-webhook-server-service | 443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS |
| 3 | kserve-controller-manager | K8s API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 4 | storage-initializer (init) | S3/GCS/Azure | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/GCP SA/Azure Key |
| 5 | Model server pod | K8s API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |

### Flow 2: Inference Request (Serverless Mode)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | Istio Ingress Gateway | 443/TCP | HTTPS | TLS 1.3 | Optional Bearer Token |
| 2 | Istio Ingress Gateway | Knative Activator | 8012/TCP | HTTP | None | None |
| 3 | Knative Activator | Model Predictor Pod | 8080/TCP | HTTP | None | Optional Token |
| 4 | Model Predictor (if transformer) | Model Transformer Pod | 8080/TCP | HTTP | None | Optional Token |
| 5 | Model Predictor (if explainer) | Model Explainer Pod | 8080/TCP | HTTP | None | Optional Token |

### Flow 3: Inference Request (RawDeployment Mode)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | Kubernetes Ingress | 443/TCP | HTTPS | TLS 1.3 | Optional Bearer Token |
| 2 | Kubernetes Ingress | Model Predictor Service | 8080/TCP | HTTP | None | Optional Token |
| 3 | Model Predictor Service | Model Predictor Pod | 8080/TCP | HTTP | None | Optional Token |

### Flow 4: InferenceGraph Multi-Step Pipeline

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | Istio Ingress Gateway | 443/TCP | HTTPS | TLS 1.3 | Optional Bearer Token |
| 2 | Istio Ingress Gateway | Router Pod | 8080/TCP | HTTP | None | Optional Token |
| 3 | Router Pod | Graph Node 1 (Model A) | 8080/TCP | HTTP | None | Optional Token |
| 4 | Router Pod | Graph Node 2 (Model B) | 8080/TCP | HTTP | None | Optional Token |
| 5 | Router Pod | Graph Node 3 (Ensemble) | 8080/TCP | HTTP | None | Optional Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Knative Serving | Knative Service CRD API | 6443/TCP | HTTPS | TLS 1.2+ | Create serverless services for InferenceService predictor/transformer/explainer |
| Istio Service Mesh | Istio VirtualService CRD API | 6443/TCP | HTTPS | TLS 1.2+ | Create traffic routing, canary deployments, A/B testing |
| Kubernetes API | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Manage Deployments, Services, Secrets, ConfigMaps, HPA |
| Prometheus | Metrics scraping | 8080/TCP | HTTP | None | Scrape /metrics endpoint from model servers |
| CloudEvents Broker | HTTP POST | 80/TCP | HTTP | None | Send prediction request/response logs to event broker |
| Model Registry | HTTP API | 443/TCP | HTTPS | TLS 1.2+ | Query model metadata, versions, lineage |
| S3/GCS/Azure | HTTPS API | 443/TCP | HTTPS | TLS 1.2+ | Download model artifacts during pod initialization |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 80cb15e08 | 2024 | - Latest commit on rhoai-2.7 branch<br>- RHOAI 2.7 release preparation<br>- Security patches for CVE-2023-48795, CVE-2022-21698, CVE-2023-45142<br>- Pinned Kubernetes dependencies to v0.26.4/v0.27.x<br>- Updated Go dependencies (controller-runtime v0.14.6, Knative v0.39.3) |

## Deployment Configuration

### Manifests Folder
- **Location**: `config/` (kustomize base)
- **Overlay**: `config/overlays/odh/` (ODH-specific configuration)

### Key Configuration
- **Namespace**: `kserve` (default)
- **Deployment Mode**: Serverless (default, configurable to RawDeployment or ModelMesh)
- **Ingress**: Istio Gateway (serverless), Kubernetes Ingress (RawDeployment)
- **Container Images**:
  - Manager: `ko://github.com/kserve/kserve/cmd/manager`
  - Agent: `kserve/agent:latest`
  - Router: `kserve/router:latest`
  - Storage Initializer: `kserve/storage-initializer:latest`
  - Model Servers: `kserve/{framework}server:latest` (sklearn, xgboost, etc.)

### Resource Limits
- **Manager Pod**: 100m CPU request/limit, 200Mi/300Mi memory request/limit
- **Agent/Logger/Batcher**: 100m CPU request, 1 CPU limit, 100Mi/1Gi memory request/limit
- **Router**: 100m CPU request, 1 CPU limit, 100Mi/1Gi memory request/limit
- **Storage Initializer**: 100m CPU request, 1 CPU limit, 100Mi/1Gi memory request/limit

### Security Context
- **runAsNonRoot**: true
- **allowPrivilegeEscalation**: false
- **Istio Injection**: Disabled for kserve namespace
