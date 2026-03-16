# Component: KServe

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kserve.git
- **Version**: 0.12.1 (branch: rhoai-2.15, commit: 69e97c64d)
- **Distribution**: RHOAI
- **Languages**: Go (operator/controller), Python (model serving runtimes)
- **Deployment Type**: Kubernetes Operator with Model Serving Framework

## Purpose
**Short**: Cloud-native model inference platform providing standardized ML model serving on Kubernetes with autoscaling, canary deployments, and multi-framework support.

**Detailed**: KServe is a Kubernetes-based model inference platform that provides a standardized, serverless architecture for deploying machine learning models across multiple frameworks including TensorFlow, PyTorch, XGBoost, Scikit-Learn, ONNX, and Hugging Face transformers. It encapsulates the complexity of model serving by providing automated storage initialization, request/response batching, model monitoring, and explainability features.

The platform consists of a control plane (kserve-controller-manager) that manages custom resources and reconciles InferenceService deployments, along with a data plane that includes model servers, an agent for logging/batching, a router for inference graphs, and a storage initializer for model artifact retrieval. KServe supports both serverless deployment (via Knative) and raw Kubernetes deployment modes, enabling scale-to-zero capabilities for cost optimization while maintaining high performance for production workloads.

KServe integrates deeply with OpenShift service mesh (Istio) for traffic management, enabling advanced deployment patterns like canary rollouts, A/B testing, and multi-model inference graphs. It supports model storage from S3-compatible object storage, Google Cloud Storage, Azure Blob Storage, PVC, and HTTP/HTTPS sources with credential management through Kubernetes secrets.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kserve-controller-manager | Kubernetes Operator | Reconciles InferenceService, ServingRuntime, InferenceGraph, and TrainedModel CRDs; manages deployments, services, and virtual services |
| kserve-webhook-server | Admission Webhook | Validates and mutates InferenceService resources; injects agent, batcher, and storage initializer sidecars into pods |
| storage-initializer | Init Container | Downloads model artifacts from S3, GCS, Azure Blob, PVC, or HTTP/HTTPS sources before model server starts |
| kserve-agent | Sidecar Container | Provides request logging, response logging, and model pull/push capabilities for batch inference |
| kserve-router | Inference Router | Routes requests through multi-step inference graphs with conditional logic and ensembling |
| Model Server Runtimes | Container Images | Framework-specific serving containers (sklearn, xgboost, tensorflow, pytorch, triton, mlserver, huggingface, etc.) |
| Explainer Servers | Container Images | Model explanation services (Alibi, ART) for interpretability |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Primary API for deploying ML models with predictor, transformer, and explainer components |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Defines model server runtime configuration for specific ML frameworks |
| serving.kserve.io | v1alpha1 | ClusterServingRuntime | Cluster | Cluster-scoped serving runtime templates available across all namespaces |
| serving.kserve.io | v1alpha1 | InferenceGraph | Namespaced | Defines multi-step inference pipelines with routing logic and model ensembles |
| serving.kserve.io | v1alpha1 | TrainedModel | Namespaced | Represents a trained model artifact that can be loaded into a serving runtime |
| serving.kserve.io | v1alpha1 | ClusterStorageContainer | Cluster | Defines storage backend configurations for model artifact retrieval |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Controller manager liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Controller manager readiness probe |
| /mutate-serving-kserve-io-v1beta1-inferenceservice | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Mutating webhook for InferenceService resources |
| /mutate-pods | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Mutating webhook for pod injection (agent, batcher, storage-initializer) |
| /validate-serving-kserve-io-v1beta1-inferenceservice | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook for InferenceService resources |
| /validate-serving-kserve-io-v1alpha1-inferencegraph | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook for InferenceGraph resources |
| /validate-serving-kserve-io-v1alpha1-trainedmodel | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook for TrainedModel resources |
| /validate-serving-kserve-io-v1alpha1-servingruntime | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook for ServingRuntime resources |
| /v1/models/{model_name}:predict | POST | 8080/TCP | HTTP/HTTPS | TLS 1.2+ (configurable) | Bearer Token/None | V1 inference protocol prediction endpoint (model server data plane) |
| /v2/models/{model_name}/infer | POST | 8080/TCP | HTTP/HTTPS | TLS 1.2+ (configurable) | Bearer Token/None | V2 inference protocol prediction endpoint (model server data plane) |
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics from model servers |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| inference.GRPCInferenceService | 8081/TCP | gRPC | mTLS (configurable) | client cert | V2 gRPC inference protocol (Triton, MLServer) |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.28+ | Yes | Container orchestration platform |
| Knative Serving | 0.39.3 | No | Serverless deployment mode with scale-to-zero and request-based autoscaling |
| Istio | 1.19+ | Yes | Service mesh for traffic management, mTLS, and virtual services |
| cert-manager | Latest | No | TLS certificate management (RHOAI uses OpenShift service certificates) |
| Prometheus | Latest | No | Metrics collection and monitoring |
| S3/GCS/Azure Storage | N/A | No | Model artifact storage backends |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Service Mesh (Istio) | VirtualService/Gateway CRDs | Traffic routing, mTLS encryption, canary deployments, A/B testing |
| OpenShift OAuth | Service Account Tokens | Authentication and authorization for inference endpoints |
| Model Registry | HTTP API | Model metadata and versioning (optional integration) |
| ODH Dashboard | HTTP API | User interface for creating and managing InferenceServices |
| Knative Serving | Knative Service CRDs | Serverless deployment with autoscaling in serverless mode |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kserve-webhook-server-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | mTLS | Internal |
| kserve-controller-manager-service | ClusterIP | 8443/TCP | https | HTTPS | TLS 1.2+ | Bearer Token | Internal |
| {isvc-name}-predictor | ClusterIP/Knative | 80/TCP, 443/TCP | 8080 | HTTP/HTTPS | TLS 1.2+ (via Istio) | Bearer Token/mTLS | Internal/External via Istio |
| {isvc-name}-transformer | ClusterIP/Knative | 80/TCP, 443/TCP | 8080 | HTTP/HTTPS | TLS 1.2+ (via Istio) | Bearer Token/mTLS | Internal |
| {isvc-name}-explainer | ClusterIP/Knative | 80/TCP, 443/TCP | 8080 | HTTP/HTTPS | TLS 1.2+ (via Istio) | Bearer Token/mTLS | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {isvc-name}-ingress | Istio VirtualService | {isvc-name}.{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External via Istio Ingress Gateway |
| {isvc-name}-local | Istio VirtualService | {isvc-name}.{namespace}.svc.cluster.local | 80/TCP | HTTP | mTLS | MUTUAL | Internal cluster traffic |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| S3-compatible storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Access Keys | Model artifact download during storage initialization |
| GCS (storage.googleapis.com) | 443/TCP | HTTPS | TLS 1.2+ | GCP Service Account | Model artifact download from Google Cloud Storage |
| Azure Blob Storage | 443/TCP | HTTPS | TLS 1.2+ | Azure credentials | Model artifact download from Azure |
| Knative Serving API | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token | Creating/updating Knative Services in serverless mode |
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token | CRUD operations on Deployments, Services, VirtualServices, ConfigMaps |

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
| kserve-manager-role | apps | deployments | create, delete, get, list, patch, update, watch |
| kserve-manager-role | "" (core) | services, configmaps, events | create, delete, get, list, patch, update, watch |
| kserve-manager-role | "" (core) | secrets | create, delete, get, patch, update |
| kserve-manager-role | "" (core) | namespaces, pods, serviceaccounts | get, list, watch |
| kserve-manager-role | serving.knative.dev | services, services/finalizers, services/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | networking.istio.io | virtualservices, virtualservices/finalizers, virtualservices/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | networking.k8s.io | ingresses | create, delete, get, list, patch, update, watch |
| kserve-manager-role | autoscaling | horizontalpodautoscalers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | create, delete, get, list, patch, update, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kserve-manager-rolebinding | kserve | kserve-manager-role | kserve-controller-manager |
| kserve-leader-election-rolebinding | kserve | kserve-leader-election-role | kserve-controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| kserve-webhook-server-cert | kubernetes.io/tls | TLS certificate for webhook server | OpenShift service-ca (service.beta.openshift.io/serving-cert-secret-name annotation) | Yes |
| storage-config | Opaque | S3/GCS/Azure credentials for model artifact download | User/Admin | No |
| {custom-secret} | Opaque | User-provided secrets referenced by serving.kserve.io/storageSecretName annotation | User | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| Webhook endpoints (/mutate-*, /validate-*) | POST | mTLS client certificate | kserve-webhook-server | Kubernetes API Server validates client cert via caBundle |
| Inference endpoints (predictor/transformer/explainer) | POST, GET | Bearer Token (OpenShift OAuth), mTLS | Istio sidecar proxy | AuthorizationPolicy enforced by service mesh |
| Controller health endpoints (/healthz, /readyz) | GET | None | kserve-controller-manager | Unprotected health checks |
| Kubernetes API (from controller) | ALL | Service Account Token | Kubernetes API Server | RBAC ClusterRole/RoleBinding |
| Storage backends (S3/GCS/Azure) | GET | AWS IAM/Access Keys/GCP SA/Azure credentials | Storage client in storage-initializer | Cloud provider IAM policies |

### Network Policies

| Policy Name | Selector | Ingress Rules | Egress Rules |
|-------------|----------|---------------|--------------|
| kserve-controller-manager | control-plane: kserve-controller-manager | Allow all ingress | Not specified (default allow all) |

## Data Flows

### Flow 1: InferenceService Creation and Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/ODH Dashboard | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (OpenShift OAuth) |
| 2 | Kubernetes API Server | kserve-webhook-server | 9443/TCP | HTTPS | TLS 1.2+ | mTLS |
| 3 | kserve-webhook-server | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 4 | kserve-controller-manager (watch) | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 5 | kserve-controller-manager | Kubernetes API Server (create resources) | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 6 | storage-initializer (init container) | S3/GCS/Azure Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/GCP SA/Azure credentials |
| 7 | storage-initializer | Model server container (shared volume) | N/A | Filesystem | None | None (local volume) |

### Flow 2: Inference Request (Serverless Mode with Istio)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External client/Application | Istio Ingress Gateway | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token/None |
| 2 | Istio Ingress Gateway | Knative Activator (if scaled to zero) | 80/TCP | HTTP | mTLS | mTLS |
| 3 | Knative Activator | Model server pod (predictor) | 8080/TCP | HTTP | mTLS | mTLS |
| 4 | Model server (if transformer exists) | Transformer pod | 8080/TCP | HTTP | mTLS | mTLS |
| 5 | Transformer/Predictor | Response to client (via Istio) | 443/TCP | HTTPS | TLS 1.2+ | N/A |

### Flow 3: Inference Request with Explainer

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | Istio Ingress Gateway | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Istio VirtualService | Predictor service | 8080/TCP | HTTP | mTLS | mTLS |
| 3 | Istio VirtualService (path: /v1/models/{name}:explain) | Explainer service | 8080/TCP | HTTP | mTLS | mTLS |
| 4 | Explainer | Predictor service (internal call) | 8080/TCP | HTTP | mTLS | mTLS |
| 5 | Explainer | Response to client (via Istio) | 443/TCP | HTTPS | TLS 1.2+ | N/A |

### Flow 4: InferenceGraph Multi-Step Routing

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | InferenceGraph endpoint (via Istio) | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | kserve-router | Step 1 InferenceService | 8080/TCP | HTTP | mTLS | mTLS |
| 3 | kserve-router | Step 2 InferenceService (based on router logic) | 8080/TCP | HTTP | mTLS | mTLS |
| 4 | kserve-router | Step N InferenceService (ensemble/switch) | 8080/TCP | HTTP | mTLS | mTLS |
| 5 | kserve-router | Response to client (via Istio) | 443/TCP | HTTPS | TLS 1.2+ | N/A |

### Flow 5: Request Logging and Batching

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client request | kserve-agent sidecar (batcher) | 8080/TCP | HTTP | mTLS | mTLS |
| 2 | kserve-agent (batching) | Model server container | 8080/TCP | HTTP | None (localhost) | None |
| 3 | Model server | kserve-agent (logging) | N/A | In-process | None | None |
| 4 | kserve-agent | Knative Eventing Broker | 80/TCP | HTTP | mTLS | mTLS |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Knative Serving | Knative Service CRD API | 6443/TCP | HTTPS | TLS 1.2+ | Serverless deployment, scale-to-zero, request-based autoscaling |
| Istio Service Mesh | VirtualService/DestinationRule/Gateway CRDs | 6443/TCP | HTTPS | TLS 1.2+ | Traffic routing, canary deployments, mTLS encryption, A/B testing |
| OpenShift Service CA | Certificate/Secret annotations | N/A | N/A | N/A | Automatic TLS certificate generation for webhook server |
| Knative Eventing | CloudEvents over HTTP | 80/TCP | HTTP | mTLS | Request/response logging to event brokers |
| Prometheus | /metrics endpoint scraping | 8080/TCP | HTTP | None | Model server and controller metrics collection |
| S3/GCS/Azure Storage | REST API | 443/TCP | HTTPS | TLS 1.2+ | Model artifact storage and retrieval |
| ODH Model Registry | REST API | 443/TCP | HTTPS | TLS 1.2+ | Model metadata, versioning, and lineage tracking (optional) |
| ODH Dashboard | REST API | 443/TCP | HTTPS | TLS 1.2+ | User interface for InferenceService management |

## Deployment Manifests Location

**Manifests Folder**: `config:kserve`

The kustomize deployment manifests are located in the `config/` directory with the following structure:

- **config/default**: Main kustomization overlay with network policies (ODH-specific)
- **config/crd**: Custom Resource Definitions for all serving.kserve.io API types
- **config/manager**: Controller manager deployment and service manifests
- **config/webhook**: Webhook service and admission webhook configurations
- **config/rbac**: ClusterRole, ClusterRoleBinding, and ServiceAccount manifests
- **config/configmap**: InferenceService configuration (storage, explainers, ingress, etc.)
- **config/runtimes**: ClusterServingRuntime templates for model serving frameworks
- **config/overlays/odh**: OpenShift Data Hub specific overlays and patches
- **config/certmanager**: Certificate manager resources (not used in RHOAI; uses OpenShift service-ca)

Key deployment modes:
1. **Serverless Mode** (default): Uses Knative Serving for scale-to-zero and request-based autoscaling
2. **RawDeployment Mode**: Traditional Kubernetes Deployments and Services without Knative
3. **ModelMesh Mode**: High-density model serving for frequently-changing models (separate component)

## Container Images

| Image | Dockerfile | Purpose | Base Image |
|-------|-----------|---------|------------|
| kserve-controller | Dockerfile | Controller manager binary | registry.access.redhat.com/ubi8/ubi-minimal:latest |
| kserve-agent | agent.Dockerfile | Request logging, batching, model pull/push | UBI-based Go image |
| kserve-router | router.Dockerfile | InferenceGraph router | UBI-based Go image |
| kserve-storage-initializer | python/storage-initializer.Dockerfile | Model artifact downloader | Python UBI image |
| kserve-sklearnserver | python/sklearn.Dockerfile | Scikit-Learn model server | Python UBI image |
| kserve-xgbserver | python/xgb.Dockerfile | XGBoost model server | Python UBI image |
| kserve-lgbserver | python/lgb.Dockerfile | LightGBM model server | Python UBI image |
| huggingface-server | python/huggingface_server.Dockerfile | Hugging Face transformers server | Python UBI image |
| kserve-pmmlserver | python/pmml.Dockerfile | PMML model server | Python UBI image |
| kserve-paddleserver | python/paddle.Dockerfile | PaddlePaddle model server | Python UBI image |
| alibi-explainer | python/alibiexplainer.Dockerfile | Alibi explainability server | Python UBI image |
| art-explainer | python/artexplainer.Dockerfile | ART explainability server | Python UBI image |

**Note**: All images are built via Red Hat Konflux CI/CD for RHOAI distribution (as evidenced by Konflux update commits).

## Recent Changes

| Date | Commit | Changes |
|------|--------|---------|
| 2024-10-07 | 69e97c64d | - Update params.env for RHOAI 2.15 release configuration |
| 2024-10-07 | 756c1be36, 89f0bba04 | - Tekton pipeline changes for RHOAI 2.15 CI/CD integration |
| 2024-10-07 | e66774038, 39a83afcc, 11b8a3a7a | - Red Hat Konflux updates for kserve-storage-initializer, kserve-router, and kserve-controller images (RHOAI 2.15) |
| 2024-10-07 | 4bdd4d8fe, a07e6c59d | - Red Hat Konflux update for kserve-agent image (RHOAI 2.15) |
| 2024-10-06 | 58b312809 | - Merge upstream release-v0.12.1 branch updates |
| 2024-10-05 | ca74f5971 | - **[RHOAIENG-13712]** Fix CVE-2024-6119 Type Confusion vulnerability |
| 2024-10-04 | b2a450e85 | - **[RHOAIENG-12260]** Fix hermetic build failure for storage-initializer in Konflux |
| 2024-09-24 | 0004af671 | - Merge upstream release-v0.12.1 updates |
| 2024-09-23 | a292015ff | - Cherry-pick: Set volume mount readonly annotation based on ISVC annotation |
| 2024-09-19 | 97cc24c21, 81e044dce | - Fix missing comma in inferenceservice-config-patch.yaml<br>- Merge upstream release-v0.12.1 updates |

**Version**: KServe 0.12.1 (upstream), customized for Red Hat OpenShift AI 2.15

**Key Features in v0.12.1**:
- InferenceGraph for multi-model inference pipelines
- Storage-initializer improvements for OCI image support (modelcar)
- Enhanced security with CVE fixes
- Improved Konflux/Tekton build integration for RHOAI
- Volume mount security enhancements
- Better integration with OpenShift service mesh and service certificates

## Configuration

**Primary ConfigMap**: `inferenceservice-config` (namespace: kserve)

Key configuration areas:
- **Storage Initializer**: Image, resource limits, CA bundle, PVC direct mount, OCI modelcar support
- **Explainers**: Alibi and ART explainer runtime images and versions
- **Credentials**: S3/GCS/Azure storage authentication configuration
- **Ingress**: Istio gateway configuration, domain templates, URL schemes
- **Logger/Batcher/Agent**: Sidecar container images and resource configurations
- **Router**: InferenceGraph router image and header propagation rules
- **Deploy**: Default deployment mode (Serverless/RawDeployment/ModelMesh)
- **Metrics Aggregator**: Prometheus scraping and metric aggregation settings

## Notes

- **Deployment Mode**: RHOAI primarily uses Serverless mode with Knative Serving for autoscaling
- **Certificate Management**: Uses OpenShift service-ca instead of cert-manager for webhook TLS certificates
- **Network Security**: All inter-service communication within the cluster uses mTLS via Istio service mesh
- **Storage Backends**: Supports S3-compatible storage (primary for RHOAI), GCS, Azure Blob, PVC, and HTTP/HTTPS
- **Model Formats**: Supports 10+ ML frameworks through ClusterServingRuntime templates
- **Inference Protocols**: Supports both V1 (TensorFlow Serving) and V2 (KServe standard) protocols over HTTP and gRPC
- **Canary Deployments**: Enabled through traffic splitting in InferenceService spec with Istio VirtualService management
- **Explainability**: Optional explainer component for model interpretability using Alibi or ART
- **Batching**: Optional agent-based batching for improved throughput with configurable batch size and latency
- **Monitoring**: Prometheus metrics exposed at /metrics endpoint on model servers (port 8080)
- **Konflux Integration**: All container images built and signed via Red Hat Konflux CI/CD pipeline
