# Component: KServe

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kserve
- **Version**: 81bf82134 (rhoai-2.12)
- **Distribution**: RHOAI
- **Languages**: Go, Python
- **Deployment Type**: Kubernetes Operator + Model Serving Runtime

## Purpose
**Short**: Model serving platform for deploying and managing machine learning models on Kubernetes with autoscaling, multi-framework support, and inference graphs.

**Detailed**: KServe provides a Kubernetes Custom Resource Definition framework for serving machine learning models on arbitrary frameworks. It aims to solve production model serving use cases by providing performant, high abstraction interfaces for common ML frameworks like TensorFlow, XGBoost, ScikitLearn, PyTorch, ONNX, and others.

KServe encapsulates the complexity of autoscaling, networking, health checking, and server configuration to bring cutting edge serving features like GPU Autoscaling, Scale to Zero, and Canary Rollouts to ML deployments. It enables a complete story for production ML serving including prediction, pre-processing, post-processing, and explainability. The platform integrates with Knative for serverless deployments, Istio for networking and traffic management, and supports both serverless and raw Kubernetes deployment modes. It also provides ModelMesh integration for high-scale, high-density model serving scenarios.

KServe supports advanced deployment patterns including canary rollouts, A/B testing through traffic splitting, inference pipelines via InferenceGraphs, and ensemble models. The storage initializer component downloads models from various cloud storage backends (S3, GCS, Azure, PVC) to make them available to model servers.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kserve-controller-manager | Go Operator | Reconciles InferenceService, ServingRuntime, and related CRDs; manages model deployment lifecycle |
| kserve-agent | Go Sidecar | Provides logging, batching, and observability for model servers |
| kserve-router | Go Service | Implements InferenceGraph routing and orchestration for multi-step inference pipelines |
| storage-initializer | Python InitContainer | Downloads models from cloud storage (S3, GCS, Azure, PVC) to local volumes |
| model-servers | Python Servers | Runtime servers for specific ML frameworks (TensorFlow, PyTorch, SKLearn, XGBoost, etc.) |
| webhook-server | Go Service | Validates and mutates InferenceService resources; injects storage-initializer into pods |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Defines a model serving deployment with predictor, transformer, and explainer components |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Defines a model server runtime template for specific ML frameworks |
| serving.kserve.io | v1alpha1 | ClusterServingRuntime | Cluster | Cluster-scoped serving runtime template available across all namespaces |
| serving.kserve.io | v1alpha1 | ClusterStorageContainer | Cluster | Defines storage initialization behavior for model downloads |
| serving.kserve.io | v1alpha1 | InferenceGraph | Namespaced | Defines multi-step inference pipelines with routing logic |
| serving.kserve.io | v1alpha1 | TrainedModel | Namespaced | Represents a trained ML model artifact with storage location |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Controller liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Controller readiness probe |
| /mutate-serving-kserve-io-v1beta1-inferenceservice | POST | 9443/TCP | HTTPS | TLS | mTLS | Mutating webhook for InferenceService resources |
| /validate-serving-kserve-io-v1beta1-inferenceservice | POST | 9443/TCP | HTTPS | TLS | mTLS | Validating webhook for InferenceService resources |
| /mutate-pods | POST | 9443/TCP | HTTPS | TLS | mTLS | Pod mutation webhook for injecting storage-initializer |
| /validate-serving-kserve-io-v1alpha1-trainedmodel | POST | 9443/TCP | HTTPS | TLS | mTLS | Validating webhook for TrainedModel resources |
| /validate-serving-kserve-io-v1alpha1-inferencegraph | POST | 9443/TCP | HTTPS | TLS | mTLS | Validating webhook for InferenceGraph resources |
| /validate-serving-kserve-io-v1alpha1-servingruntime | POST | 9443/TCP | HTTPS | TLS | mTLS | Validating webhook for ServingRuntime resources |
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint for model servers |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| tensorflow-serving | 9000/TCP | gRPC | None | None | TensorFlow model inference via gRPC |
| triton-grpc | 8001/TCP | gRPC | None | None | Triton Inference Server gRPC endpoint |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.28.x | Yes | Container orchestration platform |
| Knative Serving | 0.39.x | Conditional | Serverless deployment mode with autoscaling and scale-to-zero |
| Istio | 1.19.x | Conditional | Service mesh for traffic management, mTLS, and virtual services |
| cert-manager | latest | Yes | TLS certificate management for webhooks |
| Cloud Storage | N/A | Conditional | S3/GCS/Azure blob storage for model artifacts |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Service Mesh (Istio) | VirtualService CRD | Creates Istio VirtualServices for traffic routing and canary deployments |
| Knative Serving | Knative Service CRD | Creates Knative Services for serverless model deployments |
| ODH Dashboard | UI Integration | Model serving UI and endpoint discovery |
| Model Registry | Metadata API | Model versioning and lineage tracking |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kserve-controller-manager-service | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS | None | Internal |
| kserve-webhook-server-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | mTLS | Internal |
| <isvc-name>-predictor | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (via Istio/Knative) |
| <isvc-name>-predictor | ClusterIP | 9000/TCP | 9000 | gRPC | None | None | Internal (TensorFlow gRPC) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| <isvc-name>-virtualservice | Istio VirtualService | *.example.com | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External |
| knative-ingress-gateway | Istio Gateway | * | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External |
| knative-local-gateway | Istio Gateway | *.svc.cluster.local | 80/TCP | HTTP | None | None | Internal |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| S3 (*.amazonaws.com) | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Access Keys | Model artifact downloads |
| GCS (storage.googleapis.com) | 443/TCP | HTTPS | TLS 1.2+ | GCP Service Account | Model artifact downloads |
| Azure Blob (*.blob.core.windows.net) | 443/TCP | HTTPS | TLS 1.2+ | Azure SAS/Access Keys | Model artifact downloads |
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | CRD reconciliation and status updates |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kserve-manager-role | serving.kserve.io | inferenceservices, inferenceservices/finalizers, inferenceservices/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | servingruntimes, servingruntimes/finalizers, servingruntimes/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | clusterservingruntimes, clusterservingruntimes/finalizers, clusterservingruntimes/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | clusterstoragecontainers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | inferencegraphs, inferencegraphs/finalizers, inferencegraphs/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.kserve.io | trainedmodels, trainedmodels/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | serving.knative.dev | services, services/finalizers, services/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | networking.istio.io | virtualservices, virtualservices/finalizers, virtualservices/status | create, delete, get, list, patch, update, watch |
| kserve-manager-role | apps | deployments | create, delete, get, list, patch, update, watch |
| kserve-manager-role | autoscaling | horizontalpodautoscalers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | "" | services, secrets, configmaps, events | create, delete, get, list, patch, update |
| kserve-manager-role | "" | namespaces, pods | get, list, watch |
| kserve-manager-role | networking.k8s.io | ingresses | create, delete, get, list, patch, update, watch |
| kserve-manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | create, delete, get, list, patch, update, watch |
| kserve-leader-election-role | "" | configmaps | create, get, update |
| kserve-leader-election-role | "" | events | create |
| kserve-leader-election-role | coordination.k8s.io | leases | create, get, update |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kserve-manager-rolebinding | kserve | kserve-manager-role | kserve-controller-manager |
| kserve-leader-election-rolebinding | kserve | kserve-leader-election-role | kserve-controller-manager |
| kserve-proxy-rolebinding | kserve | kserve-proxy-role | kserve-controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| kserve-webhook-server-cert | kubernetes.io/tls | TLS certificate for webhook server | cert-manager | Yes |
| kserve-webhook-server-secret | Opaque | Webhook server configuration secrets | KServe operator | No |
| storage-config | Opaque | Cloud storage credentials (S3/GCS/Azure) | User/Admin | No |
| <custom-secret> | Opaque | Model-specific storage credentials (via annotation) | User | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| Webhook Server (/mutate-*, /validate-*) | POST | mTLS client certs | kube-apiserver | Kubernetes admission control |
| Model Inference Endpoints | POST, GET | Bearer Token (optional) | Istio AuthorizationPolicy | Custom per InferenceService |
| Controller Manager Metrics | GET | None | Network Policy | Internal cluster only |
| Kubernetes API | GET, PATCH, UPDATE | ServiceAccount Token | kube-apiserver | RBAC ClusterRole |

## Data Flows

### Flow 1: Model Deployment and Serving

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (kubeconfig) |
| 2 | Kubernetes API | kserve-webhook-server | 443/TCP | HTTPS | TLS 1.2+ | mTLS |
| 3 | kserve-controller-manager | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | kserve-controller-manager | Knative Serving API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | storage-initializer | S3/GCS/Azure | 443/TCP | HTTPS | TLS 1.2+ | Cloud Credentials |
| 6 | Client | Istio Ingress Gateway | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (optional) |
| 7 | Istio Ingress Gateway | InferenceService Pod | 8080/TCP | HTTP | mTLS (if enabled) | Istio AuthZ |

### Flow 2: InferenceGraph Multi-Step Inference

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | kserve-router | 8080/TCP | HTTP | mTLS (via Istio) | Istio AuthZ |
| 2 | kserve-router | Transformer Service | 8080/TCP | HTTP | mTLS (via Istio) | ServiceAccount Token |
| 3 | kserve-router | Predictor Service | 8080/TCP | HTTP | mTLS (via Istio) | ServiceAccount Token |
| 4 | kserve-router | Client | 8080/TCP | HTTP | mTLS (via Istio) | Response |

### Flow 3: Logging and Observability

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Model Server | kserve-agent (sidecar) | localhost | HTTP | None | None |
| 2 | kserve-agent | CloudEvents Broker | 8080/TCP | HTTP | TLS (optional) | None |
| 3 | Prometheus | Model Server | 8080/TCP | HTTP | None | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Knative Serving | Kubernetes API (CRD) | 6443/TCP | HTTPS | TLS 1.2+ | Serverless deployments with autoscaling |
| Istio | Kubernetes API (CRD) | 6443/TCP | HTTPS | TLS 1.2+ | Traffic management, mTLS, and routing |
| cert-manager | Kubernetes API (Certificate) | 6443/TCP | HTTPS | TLS 1.2+ | TLS certificate provisioning for webhooks |
| Prometheus | Metrics Scraping | 8080/TCP | HTTP | None | Model server metrics collection |
| S3/GCS/Azure Storage | HTTPS API | 443/TCP | HTTPS | TLS 1.2+ | Model artifact storage and retrieval |
| Kubernetes API | REST API | 6443/TCP | HTTPS | TLS 1.2+ | CRD reconciliation and resource management |

## Recent Changes

| Commit | Date | Changes |
|---------|------|---------|
| 81bf821 | 2024-12 | - Merge pull request #608: Update kserve-agent-212 component |
| 165e5dc | 2024-12 | - Merge branch rhoai-2.12 for agent updates |
| c37cc8b | 2024-12 | - Merge pull request #611: Update kserve-storage-initializer-212 |
| 469be5c | 2024-12 | - Update kserve-storage-initializer-212 to 42b29e4 |
| ec10925 | 2024-12 | - Merge pull request #610: Update kserve-controller-212 |
| a8af26a | 2024-12 | - Merge pull request #609: Update kserve-router-212 |
| 128772a | 2024-12 | - Update kserve-controller-212 to 8d2369f |
| 281cd70 | 2024-12 | - Update kserve-router-212 to 270ad61 |
| 65e9b41 | 2024-12 | - Update kserve-agent-212 to c62798c |
| 2e71495 | 2024-11 | - Merge pull request #599: Update Konflux references for rhoai-2.12 |
| 60cf608 | 2024-11 | - Update Konflux references |
| 0595881 | 2024-11 | - Merge pull request #594: Update kserve-controller-212 |
| 63ff1da | 2024-11 | - Update kserve-controller-212 to 351b839 |
| 8d0138a | 2024-11 | - Update kserve-controller-212-push.yaml |
| 3219b31 | 2024-11 | - Merge pull request #583: Update SHA |
| 7822b81 | 2024-11 | - Update controller SHA |
| 5de48b4 | 2024-11 | - Merge pull request #580: Update kserve-storage-initializer-212 |
| c9e3eb3 | 2024-11 | - Update kserve-storage-initializer-212 to 2c891fa |
| bd18823 | 2024-11 | - Merge pull request #579: Remove base image |
| c72a54b | 2024-11 | - Base image removed from build configuration |

## Deployment Configuration

### Container Images (Built via Konflux)

| Image | Dockerfile | Base Image | Build Context | Purpose |
|-------|-----------|------------|---------------|---------|
| quay.io/modh/kserve-controller | Dockerfile | registry.access.redhat.com/ubi8/go-toolset:1.21 | . | Controller/Manager binary |
| quay.io/modh/kserve-agent | agent.Dockerfile | registry.access.redhat.com/ubi8/go-toolset:1.21 | . | Agent sidecar binary |
| quay.io/modh/kserve-router | router.Dockerfile | registry.access.redhat.com/ubi8/go-toolset:1.21 | . | Router binary for InferenceGraphs |
| quay.io/modh/kserve-storage-initializer | python/storage-initializer.Dockerfile | Python base | python/ | Storage initializer for model downloads |

### Pre-configured Serving Runtimes

| Runtime | Framework | Protocol | Auto-Select | Priority |
|---------|-----------|----------|-------------|----------|
| kserve-tensorflow-serving | TensorFlow 1.x, 2.x | HTTP, gRPC | Yes | 2 |
| kserve-tritonserver | ONNX, TensorRT, PyTorch, TensorFlow | HTTP, gRPC | Yes | 1 |
| kserve-mlserver | SKLearn, XGBoost, MLflow | HTTP | Yes | 1 |
| kserve-sklearnserver | SKLearn | HTTP | Yes | 1 |
| kserve-xgbserver | XGBoost | HTTP | Yes | 1 |
| kserve-torchserve | PyTorch | HTTP | Yes | 1 |
| kserve-huggingfaceserver | HuggingFace Transformers | HTTP | Yes | 1 |
| kserve-lgbserver | LightGBM | HTTP | Yes | 1 |
| kserve-paddleserver | PaddlePaddle | HTTP | Yes | 1 |
| kserve-pmmlserver | PMML | HTTP | Yes | 1 |

### Storage Support

| Storage Type | Protocol | Authentication | Purpose |
|-------------|----------|----------------|---------|
| S3 | HTTPS | AWS IAM / Access Keys | Model artifact storage |
| GCS | HTTPS | GCP Service Account | Model artifact storage |
| Azure Blob | HTTPS | SAS Token / Access Keys | Model artifact storage |
| PVC | N/A | N/A | Direct volume mount for models |
| HTTP/HTTPS | HTTPS | None / Basic Auth | Public model repositories |
| OCI | OCI Registry API | Registry credentials | Container image-based models (with modelcar) |

### Network Policies

| Policy Name | Pod Selector | Ingress Rules | Egress Rules |
|-------------|-------------|---------------|--------------|
| kserve-controller-manager | control-plane: kserve-controller-manager | Allow all | Not specified |

## Configuration Management

### ConfigMaps

| ConfigMap Name | Namespace | Purpose |
|---------------|-----------|---------|
| inferenceservice-config | kserve | Global configuration for deployment mode, storage, credentials, ingress, logger, batcher, agent, router, metrics |

### Key Configuration Options

| Section | Key | Default | Purpose |
|---------|-----|---------|---------|
| deploy | defaultDeploymentMode | Serverless | Deployment mode: Serverless, RawDeployment, or ModelMesh |
| storageInitializer | image | kserve/storage-initializer:latest | Storage initializer container image |
| storageInitializer | enableDirectPvcVolumeMount | true | Allow direct PVC mounting instead of copying |
| storageInitializer | enableModelcar | false | Enable OCI container image-based model loading |
| ingress | ingressGateway | knative-serving/knative-ingress-gateway | Istio gateway for external traffic |
| ingress | ingressClassName | istio | Ingress controller class |
| ingress | urlScheme | http | URL scheme for inference services |
| ingress | disableIstioVirtualHost | false | Disable Istio VirtualService creation |
| agent | image | kserve/agent:latest | Agent sidecar image for logging/batching |
| router | image | kserve/router:latest | Router image for InferenceGraphs |
| credentials | s3AccessKeyIDName | AWS_ACCESS_KEY_ID | S3 access key environment variable |
| credentials | s3SecretAccessKeyName | AWS_SECRET_ACCESS_KEY | S3 secret key environment variable |

## Operational Characteristics

### Resource Requirements (Controller)

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|------------|-----------|----------------|--------------|
| manager | 100m | 100m | 200Mi | 300Mi |

### Health Checks

| Component | Endpoint | Port | Initial Delay | Timeout | Failure Threshold |
|-----------|----------|------|---------------|---------|-------------------|
| manager (liveness) | /healthz | 8081 | 10s | 5s | 5 |
| manager (readiness) | /readyz | 8081 | 10s | 5s | 10 |

### High Availability

- Controller runs as a single replica with leader election
- Leader election uses ConfigMaps and Leases in the kserve namespace
- Model servers scale based on Knative/HPA configuration

### Security Context

- Controller runs as non-root user (UID 1000)
- No privilege escalation allowed
- Storage initializer and model servers run as UID 1000
