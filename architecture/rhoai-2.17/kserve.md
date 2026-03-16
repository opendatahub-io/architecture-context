# Component: KServe

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kserve.git
- **Version**: 6a07b522b (rhoai-2.17)
- **Distribution**: RHOAI
- **Languages**: Go, Python
- **Deployment Type**: Kubernetes Operator with Model Serving Runtime
- **Python SDK Version**: 0.14.0

## Purpose
**Short**: KServe provides Kubernetes-native model serving for predictive and generative ML models with standardized inference protocols.

**Detailed**: KServe is a Kubernetes Custom Resource Definition-based platform for serving machine learning models. It provides a unified interface for deploying and managing ML models across various frameworks (TensorFlow, PyTorch, Scikit-Learn, XGBoost, Hugging Face, etc.) with production-grade features including autoscaling, canary deployments, and multi-model serving. The platform consists of a control plane (KServe operator) that manages InferenceService resources and a data plane with model servers, storage initializers, and routing components. KServe abstracts the complexity of model deployment by providing standardized protocols (OpenAPI, V2 Inference Protocol), automatic scaling (including scale-to-zero on CPU/GPU), and intelligent routing through InferenceGraphs for complex ML pipelines.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kserve-controller-manager | Go Operator | Reconciles InferenceService, InferenceGraph, ServingRuntime, TrainedModel CRDs; manages lifecycle of model deployments |
| kserve-agent | Go Sidecar | Downloads models from storage, provides health checks, handles batching requests, manages model lifecycle within pods |
| kserve-router | Go Service | Routes requests through InferenceGraph pipelines, enables multi-model ensembles and complex inference workflows |
| storage-initializer | Python Init Container | Downloads models from cloud storage (S3, GCS, Azure, PVC) into serving containers |
| Model Servers | Python Runtimes | Framework-specific inference servers: sklearn, xgboost, lgb, paddle, pmml, huggingface, custom models |
| Explainers | Python Services | Model explanation services: ART (Adversarial Robustness), AIF360 (AI Fairness), Alibi |
| Webhooks | Go Service | Validates and mutates InferenceService resources, injects sidecars and init containers into pods |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Primary API for deploying ML models with predictor, transformer, explainer components |
| serving.kserve.io | v1alpha1 | InferenceGraph | Namespaced | Defines DAG-based inference pipelines for multi-model serving and ensembles |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Defines model server runtime templates for specific ML frameworks |
| serving.kserve.io | v1alpha1 | ClusterServingRuntime | Cluster | Cluster-scoped serving runtime templates available across all namespaces |
| serving.kserve.io | v1alpha1 | TrainedModel | Namespaced | Represents individual trained models for multi-model serving scenarios |
| serving.kserve.io | v1alpha1 | ClusterLocalModel | Cluster | Defines models stored on local node storage for high-performance serving |
| serving.kserve.io | v1alpha1 | LocalModelNodeGroup | Namespaced | Manages groups of nodes with local model storage capabilities |
| serving.kserve.io | v1alpha1 | ClusterStorageContainer | Cluster | Defines storage backend configurations for model artifacts |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /mutate-serving-kserve-io-v1beta1-inferenceservice | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Mutating webhook for InferenceService defaults and transformations |
| /validate-serving-kserve-io-v1beta1-inferenceservice | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Validating webhook for InferenceService resource validation |
| /mutate-pods | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Pod mutator for injecting agent, storage-initializer sidecars |
| /validate-serving-kserve-io-v1alpha1-trainedmodel | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Validating webhook for TrainedModel resources |
| /validate-serving-kserve-io-v1alpha1-inferencegraph | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Validating webhook for InferenceGraph resources |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe for controller manager |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe for controller manager |
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint for controller manager |
| /v1/models/:model/infer | POST | 8080/TCP | HTTP/HTTPS | Optional TLS | Optional Bearer | KServe V1 inference protocol endpoint (served by model servers) |
| /v2/models/:model/infer | POST | 8080/TCP | HTTP/HTTPS | Optional TLS | Optional Bearer | KServe V2 inference protocol endpoint (served by model servers) |
| /v1/chat/completions | POST | 8080/TCP | HTTP/HTTPS | Optional TLS | Optional Bearer | OpenAI-compatible endpoint for LLM inference |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| inference.GRPCInferenceService | 9000/TCP | gRPC | Optional mTLS | Optional cert | V2 inference protocol over gRPC for high-performance inference |
| GRPCInferenceService | 8081/TCP | gRPC | Optional mTLS | Optional cert | Custom model gRPC inference endpoint |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.24+ | Yes | Container orchestration platform for running KServe |
| Knative Serving | 1.8+ | No | Serverless autoscaling and traffic routing (serverless mode) |
| Istio | 1.16+ | No | Service mesh for advanced networking, mTLS, authorization (recommended) |
| cert-manager | 1.9+ | No | Automated TLS certificate management for webhooks |
| Kubernetes Horizontal Pod Autoscaler | Built-in | No | Autoscaling for raw Kubernetes deployments |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Service Mesh (Istio) | VirtualService, Gateway | External access to InferenceServices, traffic splitting for canary deployments |
| Authorino | AuthorizationPolicy | Request authentication and authorization for inference endpoints |
| ODH Model Registry | HTTP API | Model metadata and versioning integration |
| ODH Dashboard | HTTP API | UI integration for managing InferenceServices |
| DataScienceCluster | CRD Watch | Managed by opendatahub-operator, enables/disables KServe component |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kserve-controller-manager-service | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | Prometheus scraping | Internal |
| kserve-webhook-server-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Internal |
| {isvc-name}-predictor | ClusterIP | 80/TCP | 8080 | HTTP/HTTPS | Optional TLS | Optional Bearer/mTLS | Internal |
| {isvc-name}-predictor-default (Knative) | ClusterIP | 80/TCP | 8012 | HTTP | None | Istio mTLS | Internal |
| {isvc-name}-transformer | ClusterIP | 80/TCP | 8080 | HTTP/HTTPS | Optional TLS | Optional Bearer/mTLS | Internal |
| {isvc-name}-explainer | ClusterIP | 80/TCP | 8080 | HTTP/HTTPS | Optional TLS | Optional Bearer/mTLS | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {isvc-name}-ingress | Kubernetes Ingress | {isvc-name}.{namespace}.{domain} | 80/TCP | HTTP | None | N/A | External |
| {isvc-name} | Istio Gateway/VirtualService | {isvc-name}.{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External |
| {isvc-name} (Knative) | Knative Route | {isvc-name}.{namespace}.svc.cluster.local | 80/TCP | HTTP | Istio mTLS | MUTUAL | Internal |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| S3-compatible storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM or Access Keys | Model artifact download during initialization |
| Google Cloud Storage | 443/TCP | HTTPS | TLS 1.2+ | GCP Service Account | Model artifact download during initialization |
| Azure Blob Storage | 443/TCP | HTTPS | TLS 1.2+ | Azure credentials | Model artifact download during initialization |
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token | Watch CRDs, update status, create resources |
| Knative Serving API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token | Create/update Knative Services (serverless mode) |
| Istio Pilot | 15010/TCP | gRPC | mTLS | Istio cert | Service mesh configuration and discovery |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kserve-manager-role | "" | configmaps | create, get, update |
| kserve-manager-role | "" | events, services | create, delete, get, list, patch, update, watch |
| kserve-manager-role | "" | namespaces, pods | get, list, watch |
| kserve-manager-role | "" | secrets, serviceaccounts | get |
| kserve-manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | create, delete, get, list, patch, update, watch |
| kserve-manager-role | apps | deployments | create, delete, get, list, patch, update, watch |
| kserve-manager-role | autoscaling | horizontalpodautoscalers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | networking.istio.io | virtualservices, virtualservices/finalizers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | networking.istio.io | virtualservices/status | get, patch, update |
| kserve-manager-role | networking.k8s.io | ingresses | create, delete, get, list, patch, update, watch |
| kserve-manager-role | route.openshift.io | routes | get, list, watch |
| kserve-manager-role | serving.knative.dev | services, services/finalizers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.knative.dev | services/status | get, patch, update |
| kserve-manager-role | serving.kserve.io | clusterlocalmodels | get, list |
| kserve-manager-role | serving.kserve.io | clusterservingruntimes, clusterservingruntimes/finalizers, clusterstoragecontainers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | inferencegraphs, inferencegraphs/finalizers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | inferenceservices, inferenceservices/finalizers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | servingruntimes, servingruntimes/finalizers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | trainedmodels | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | clusterservingruntimes/status, inferencegraphs/status, inferenceservices/status, servingruntimes/status, trainedmodels/status | get, patch, update |
| kserve-leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| kserve-leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| kserve-leader-election-role | "" | events | create, patch |
| kserve-proxy-role | authentication.k8s.io | tokenreviews | create |
| kserve-proxy-role | authorization.k8s.io | subjectaccessreviews | create |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kserve-manager-rolebinding | cluster-wide | kserve-manager-role | kserve/kserve-controller-manager |
| kserve-leader-election-rolebinding | kserve | kserve-leader-election-role | kserve/kserve-controller-manager |
| kserve-proxy-rolebinding | cluster-wide | kserve-proxy-role | kserve/kserve-controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| kserve-webhook-server-cert | kubernetes.io/tls | TLS certificate for webhook server HTTPS endpoint | cert-manager or manual | Yes (cert-manager) |
| kserve-webhook-server-secret | Opaque | Internal secret for webhook configuration | KServe operator | No |
| storage-config | Opaque | S3/GCS/Azure credentials for model storage access | User/Platform admin | No |
| {isvc-name}-sa | kubernetes.io/service-account-token | Service account token for InferenceService pods | Kubernetes | Yes (auto) |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /mutate-* /validate-* | POST | Kubernetes API Server mTLS | kube-apiserver | Webhook configurations with client CA |
| /v1/models/:model/infer | POST | Optional Bearer Token (JWT) | Istio AuthorizationPolicy | User-defined authorization policies |
| /v2/models/:model/infer | POST | Optional Bearer Token (JWT) | Istio AuthorizationPolicy | User-defined authorization policies |
| Knative InferenceServices | ALL | Istio mTLS (internal) | Istio PeerAuthentication | STRICT mTLS for pod-to-pod communication |
| Model Storage (S3/GCS) | GET | AWS IAM/GCP SA/Access Keys | storage-initializer | Cloud provider IAM policies |
| Kubernetes API | ALL | ServiceAccount Token | kube-apiserver | RBAC policies defined above |

## Data Flows

### Flow 1: Model Deployment and Initialization

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | kubectl/oc with user credentials |
| 2 | Kubernetes API | kserve-webhook-server-service | 443/TCP | HTTPS | TLS 1.2+ | mTLS with webhook cert |
| 3 | kserve-controller-manager | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 4 | kserve-controller-manager | Knative/Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 5 | storage-initializer (init) | S3/GCS/Azure | 443/TCP | HTTPS | TLS 1.2+ | Cloud credentials from secret |
| 6 | kserve-agent (sidecar) | Model server container | localhost | HTTP | None | None (same pod) |

### Flow 2: Model Inference Request (Serverless Mode with Istio)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External client | Istio Gateway | 443/TCP | HTTPS | TLS 1.3 | Optional Bearer Token |
| 2 | Istio Gateway | Istio VirtualService | 80/TCP | HTTP | mTLS | Istio peer authentication |
| 3 | Istio VirtualService | Knative Activator | 8012/TCP | HTTP | mTLS | Istio peer authentication |
| 4 | Knative Activator | InferenceService Pod | 8012/TCP | HTTP | mTLS | Istio peer authentication |
| 5 | kserve-agent queue-proxy | Model server container | 8080/TCP | HTTP | None | None (same pod) |
| 6 | Model server | kserve-agent (response) | localhost | HTTP | None | None (same pod) |
| 7 | InferenceService Pod | Client (via Istio) | reverse | HTTP/HTTPS | TLS 1.3 | N/A |

### Flow 3: Model Inference with Transformer (Pre/Post Processing)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External client | Istio Gateway | 443/TCP | HTTPS | TLS 1.3 | Optional Bearer Token |
| 2 | Istio Gateway | Transformer Service | 80/TCP | HTTP | mTLS | Istio peer authentication |
| 3 | Transformer | Predictor Service | 80/TCP | HTTP | mTLS | Istio peer authentication |
| 4 | Predictor (model server) | Transformer (response) | 80/TCP | HTTP | mTLS | Istio peer authentication |
| 5 | Transformer | Client (via Istio) | reverse | HTTPS | TLS 1.3 | N/A |

### Flow 4: InferenceGraph Multi-Model Routing

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External client | Istio Gateway | 443/TCP | HTTPS | TLS 1.3 | Optional Bearer Token |
| 2 | Istio Gateway | kserve-router | 8080/TCP | HTTP | mTLS | Istio peer authentication |
| 3 | kserve-router | Model A predictor | 80/TCP | HTTP | mTLS | Istio peer authentication |
| 4 | kserve-router | Model B predictor | 80/TCP | HTTP | mTLS | Istio peer authentication |
| 5 | kserve-router | Ensemble node | 80/TCP | HTTP | mTLS | Istio peer authentication |
| 6 | Ensemble node | Client (via Istio) | reverse | HTTPS | TLS 1.3 | N/A |

### Flow 5: Controller Reconciliation Loop

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | kserve-controller-manager | Kubernetes API (watch) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 2 | Kubernetes API | kserve-controller-manager (event) | N/A | N/A | N/A | N/A |
| 3 | kserve-controller-manager | Kubernetes API (create Deployment/Service) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 4 | kserve-controller-manager | Knative API (create KService) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 5 | kserve-controller-manager | Istio API (create VirtualService) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 6 | kserve-controller-manager | Kubernetes API (update status) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | CRD management, resource creation, status updates |
| Knative Serving | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Serverless autoscaling and traffic routing |
| Istio Service Mesh | xDS API | 15010/TCP | gRPC | mTLS | Service discovery, traffic management, security policies |
| Prometheus | HTTP scrape | 8080/TCP | HTTP | None | Metrics collection from controller and model servers |
| S3-compatible Storage | S3 API | 443/TCP | HTTPS | TLS 1.2+ | Model artifact storage and retrieval |
| Google Cloud Storage | GCS API | 443/TCP | HTTPS | TLS 1.2+ | Model artifact storage and retrieval |
| Azure Blob Storage | Azure API | 443/TCP | HTTPS | TLS 1.2+ | Model artifact storage and retrieval |
| cert-manager | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Automated webhook certificate provisioning |
| ODH Dashboard | REST API | 8080/TCP | HTTP | Istio mTLS | InferenceService management UI integration |
| Model Registry | REST API | 8080/TCP | HTTP/HTTPS | Optional TLS | Model metadata and lineage tracking |
| Authorino | Authorization API | 5001/TCP | gRPC | mTLS | External authorization for inference requests |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 6a07b522b | 2025-02-20 | Merge pull request #1104: Konflux component update for kserve-controller-217 |
| 3ad725026 | 2025-02-20 | Merge pull request #1102: Konflux component update for kserve-router-217 |
| 8896e2d9d | 2025-02-20 | chore(deps): Update kserve-controller-217 to commit 3bb5625 |
| 834e3926a | 2025-02-20 | chore(deps): Update kserve-router-217 to commit 0d30ea7 |
| f54af8dff | 2025-02-18 | Security fix: Cleanup filepath in createNewFile to avoid path traversal vulnerability |
| ee0f9a890 | 2025-02-15 | fix: Use correct SHA for image references |
| e3e9f74da | 2025-02-10 | Merge pull request #804: Konflux component update for kserve-agent-217 |
| 12a061dc5 | 2025-02-10 | Merge pull request #805: Konflux component update for kserve-storage-initializer-217 |
| 75fec9033 | 2025-02-10 | Update kserve-storage-initializer-217 to commit 680fdb6 |
| 24e935eee | 2025-02-08 | Merge pull request #803: Konflux component update for kserve-controller-217 |
| 7bed37c23 | 2025-02-08 | Update kserve-agent-217 to commit edaad51 |
| 8f3b91cfb | 2025-02-08 | Update kserve-controller-217 to commit 5b7a8b5 |
| 21d102c08 | 2025-02-05 | Remove starlette pinned version from requirements |
| ac47bc92c | 2025-02-03 | Merge pull request #763: Add OAuth proxy integration for RHOAI 2.17 |
| 9ada8078d | 2025-02-03 | Add oauth-proxy image to params.env for authentication integration |
| d7567fb91 | 2025-02-01 | Merge pull request #759: Konflux component update for kserve-controller-217 |
| b459a38b6 | 2025-02-01 | Merge branch rhoai-2.17 into konflux component update branch |
| 4d5c3a4fc | 2025-01-30 | Merge pull request #761: Konflux component update for kserve-router-217 |
| 2fb89ade5 | 2025-01-30 | Merge branch rhoai-2.17 into konflux router update branch |

## Deployment Architecture

### Container Images (Built via Konflux)

| Image | Dockerfile | Base Image | Purpose | Build Pipeline |
|-------|-----------|------------|---------|----------------|
| kserve-controller | Dockerfile | ubi8/ubi-minimal | Controller manager for reconciling CRDs | .tekton/kserve-controller-217-push.yaml |
| kserve-agent | agent.Dockerfile | ubi8/ubi-minimal | Model agent sidecar for storage and health | .tekton/kserve-agent-217-push.yaml |
| kserve-router | router.Dockerfile | ubi8/ubi-minimal | InferenceGraph routing component | .tekton/kserve-router-217-push.yaml |
| kserve-storage-initializer | python/storage-initializer.Dockerfile | ubi8/python-39 | Init container for model download | .tekton/kserve-storage-initializer-217-push.yaml |
| kserve-sklearnserver | python/sklearn.Dockerfile | ubi8/python-39 | Scikit-learn model server | N/A |
| kserve-xgbserver | python/xgb.Dockerfile | ubi8/python-39 | XGBoost model server | N/A |
| kserve-lgbserver | python/lgb.Dockerfile | ubi8/python-39 | LightGBM model server | N/A |
| kserve-pmmlserver | python/pmml.Dockerfile | ubi8/python-39 | PMML model server | N/A |
| kserve-paddleserver | python/paddle.Dockerfile | ubi8/python-39 | PaddlePaddle model server | N/A |
| kserve-huggingfaceserver | python/huggingface_server.Dockerfile | ubi8/python-39 | Hugging Face transformers/LLM server | N/A |
| kserve-artexplainer | python/artexplainer.Dockerfile | ubi8/python-39 | ART explainer for adversarial robustness | N/A |
| kserve-aiffairnessexplainer | python/aiffairness.Dockerfile | ubi8/python-39 | AIF360 explainer for fairness metrics | N/A |

### Serving Runtime Templates

KServe includes 12 pre-configured ClusterServingRuntime templates:
- kserve-huggingfaceserver (single-node and multi-node variants)
- kserve-lgbserver
- kserve-mlserver (multi-framework support)
- kserve-paddleserver
- kserve-pmmlserver
- kserve-sklearnserver
- kserve-tensorflow-serving
- kserve-torchserve
- kserve-tritonserver (NVIDIA Triton)
- kserve-xgbserver

### Configuration Management

| ConfigMap | Namespace | Purpose | Key Parameters |
|-----------|-----------|---------|----------------|
| inferenceservice-config | kserve | Global configuration for InferenceService behavior | explainers, storageInitializer, credentials, ingress, logger, batcher |

### Key Configuration Parameters

**Storage Initializer**:
- image: Container image for storage-initializer
- memoryRequest/memoryLimit: Resource limits for init container
- cpuRequest/cpuLimit: CPU resource limits
- enableDirectPvcVolumeMount: Enable direct PVC mounting
- enableModelcar: Enable OCI container image model storage
- caBundleConfigMapName: Custom CA certificates for storage access

**Credentials**:
- S3 configuration: Access keys, endpoint, region, SSL verification
- GCS configuration: Service account credentials
- Azure configuration: Storage account credentials

**Ingress**:
- ingressGateway: Istio gateway for external access
- ingressClassName: Kubernetes ingress class
- domainTemplate: Template for generating inference service URLs

**Deployment Modes**:
- **Serverless Mode** (default): Uses Knative Serving for scale-to-zero and request-based autoscaling
- **RawDeployment Mode**: Uses standard Kubernetes Deployments with HPA for autoscaling
- **ModelMesh Mode**: High-density multi-model serving for frequently changing models

## Supported ML Frameworks

| Framework | Runtime | Protocol | Auto-Select | Notes |
|-----------|---------|----------|-------------|-------|
| Scikit-Learn | kserve-sklearnserver | V1, V2 | Yes | Pickle/joblib format |
| XGBoost | kserve-xgbserver | V1, V2 | Yes | XGBoost native format |
| LightGBM | kserve-lgbserver | V1, V2 | Yes | LightGBM native format |
| TensorFlow | kserve-tensorflow-serving | V1, gRPC | Yes | SavedModel format |
| PyTorch | kserve-torchserve | V1, V2, gRPC | Yes | TorchScript, eager mode |
| ONNX | kserve-tritonserver | V2, gRPC-V2 | Yes | ONNX format via Triton |
| TensorRT | kserve-tritonserver | V2, gRPC-V2 | Yes | TensorRT optimized models |
| PMML | kserve-pmmlserver | V1, V2 | Yes | PMML XML format |
| PaddlePaddle | kserve-paddleserver | V1, V2 | Yes | Paddle inference format |
| Hugging Face | kserve-huggingfaceserver | V1, V2, OpenAI | Yes | Transformers, LLMs, text-generation-inference |
| MLflow | kserve-mlserver | V2 | Yes | MLflow model format |
| Custom | Custom container | V1, V2, gRPC | N/A | User-provided container image |
