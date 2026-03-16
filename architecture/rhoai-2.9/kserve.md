# Component: KServe

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kserve.git
- **Version**: 69cb9fee0 (rhoai-2.9 branch)
- **Distribution**: RHOAI
- **Languages**: Go (operator, agent, router), Python (serving runtimes)
- **Deployment Type**: Kubernetes Operator with sidecar components

## Purpose
**Short**: KServe provides a Kubernetes-native platform for serving machine learning models with standardized inference protocols, autoscaling, and traffic management.

**Detailed**: KServe is a model inference platform that enables production ML serving on Kubernetes. It provides Custom Resource Definitions for deploying ML models on various frameworks (TensorFlow, PyTorch, Scikit-learn, XGBoost, etc.) with built-in support for autoscaling, canary rollouts, and multi-model inference graphs. The platform abstracts the complexity of model serving by managing the entire lifecycle including model loading from cloud storage, inference serving with standardized protocols (KServe v1/v2, Open Inference Protocol), request routing, logging, and batching. KServe integrates with Knative for serverless deployments and Istio for advanced traffic management, supporting both serverless (scale-to-zero) and raw Kubernetes deployment modes.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kserve-controller-manager | Go Operator | Reconciles InferenceService, ServingRuntime, and InferenceGraph CRDs; creates Knative Services or K8s Deployments |
| kserve-agent | Go Sidecar | Model puller, logger, and batcher sidecar injected into inference pods |
| kserve-router | Go Service | Routes inference requests in multi-model InferenceGraph pipelines |
| storage-initializer | Python Init Container | Downloads models from S3, GCS, Azure, PVC, or HTTP storage to local volumes |
| sklearn-server | Python Runtime | Serves Scikit-learn models via KServe inference protocol |
| xgboost-server | Python Runtime | Serves XGBoost models via KServe inference protocol |
| lightgbm-server | Python Runtime | Serves LightGBM models via KServe inference protocol |
| paddle-server | Python Runtime | Serves PaddlePaddle models via KServe inference protocol |
| pmml-server | Python Runtime | Serves PMML models via KServe inference protocol |
| mlserver | Python Runtime | Multi-framework serving runtime supporting MLflow, Scikit-learn, XGBoost |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Primary CR for deploying ML models with predictor, transformer, and explainer components |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Defines runtime containers and configurations for serving specific model formats |
| serving.kserve.io | v1alpha1 | ClusterServingRuntime | Cluster | Cluster-scoped runtime templates for model serving (sklearn, tensorflow, pytorch, etc.) |
| serving.kserve.io | v1alpha1 | InferenceGraph | Namespaced | Defines multi-step inference pipelines with routing logic between models |
| serving.kserve.io | v1alpha1 | TrainedModel | Namespaced | Represents individual trained models that can be loaded dynamically into multi-model servers |
| serving.kserve.io | v1alpha1 | ClusterStorageContainer | Cluster | Defines init container configurations for downloading models from various storage backends |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /mutate-serving-kserve-io-v1beta1-inferenceservice | POST | 443/TCP | HTTPS | TLS 1.2+ | K8s API Server cert | Mutating webhook for InferenceService validation and defaulting |
| /mutate-pods | POST | 443/TCP | HTTPS | TLS 1.2+ | K8s API Server cert | Pod mutator webhook for injecting storage-initializer and agent sidecars |
| /validate-serving-kserve-io-v1beta1-inferenceservice | POST | 443/TCP | HTTPS | TLS 1.2+ | K8s API Server cert | Validating webhook for InferenceService spec validation |
| /validate-serving-kserve-io-v1alpha1-trainedmodel | POST | 443/TCP | HTTPS | TLS 1.2+ | K8s API Server cert | Validating webhook for TrainedModel spec validation |
| /validate-serving-kserve-io-v1alpha1-inferencegraph | POST | 443/TCP | HTTPS | TLS 1.2+ | K8s API Server cert | Validating webhook for InferenceGraph spec validation |
| /validate-serving-kserve-io-v1alpha1-servingruntime | POST | 443/TCP | HTTPS | TLS 1.2+ | K8s API Server cert | Validating webhook for ServingRuntime spec validation |
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint for controller manager |
| /v1/models/{model}:predict | POST | 8080/TCP | HTTP | mTLS (Istio) | Service mesh | KServe v1 inference protocol endpoint (served by runtime containers) |
| /v2/models/{model}/infer | POST | 8080/TCP | HTTP | mTLS (Istio) | Service mesh | KServe v2 / Open Inference Protocol endpoint (served by runtime containers) |
| /v2/health/ready | GET | 8080/TCP | HTTP | mTLS (Istio) | Service mesh | Runtime readiness probe |
| /v2/health/live | GET | 8080/TCP | HTTP | mTLS (Istio) | Service mesh | Runtime liveness probe |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| inference.GRPCInferenceService | 8081/TCP | gRPC | mTLS (Istio) | Service mesh | Open Inference Protocol over gRPC for high-performance inference |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Knative Serving | 1.x | Yes (Serverless mode) | Provides serverless serving with scale-to-zero and request-based autoscaling |
| Istio | 1.x | Yes (RHOAI) | Service mesh for traffic routing, mTLS, and VirtualService management |
| cert-manager | 1.x | Yes | Manages TLS certificates for webhook server |
| Kubernetes | 1.23+ | Yes | Container orchestration platform |
| Prometheus | 2.x | No | Metrics collection and monitoring |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| model-mesh | CRD sharing | Alternative high-density model serving for multi-model use cases |
| odh-model-controller | Service coordination | Model registry integration and model deployment orchestration |
| authorino | Authorization | OAuth/OIDC token validation for inference endpoints (when configured) |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kserve-webhook-server-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | K8s API Server | Internal (API Server only) |
| kserve-controller-manager-service | ClusterIP | 8443/TCP | https | HTTPS | TLS 1.2+ | mTLS (service mesh) | Internal |
| kserve-controller-manager-metrics-service | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (Prometheus) |
| {isvc-name}-predictor | ClusterIP | 80/TCP | 8080 | HTTP | mTLS (Istio) | Service mesh | Internal |
| {isvc-name}-predictor-private | ClusterIP | 80/TCP | 9081 | HTTP | mTLS (Istio) | Service mesh | Internal (K8s probes) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {isvc-name}-ingress | Istio VirtualService | {name}-{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External (via Istio Gateway) |
| knative-ingress-gateway | Istio Gateway | *.{cluster-domain} | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| S3 endpoints (AWS, Minio, etc.) | 443/TCP | HTTPS | TLS 1.2+ | AWS SigV4 / Access Keys | Model artifact download from S3-compatible storage |
| GCS endpoints | 443/TCP | HTTPS | TLS 1.2+ | GCP Service Account | Model artifact download from Google Cloud Storage |
| Azure Blob Storage | 443/TCP | HTTPS | TLS 1.2+ | Azure credentials | Model artifact download from Azure |
| HTTP model repositories | 80/TCP, 443/TCP | HTTP/HTTPS | TLS 1.2+ (HTTPS) | Basic Auth / Token | Model artifact download from HTTP servers |

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
| kserve-manager-role | autoscaling | horizontalpodautoscalers | create, delete, get, list, patch, update, watch |
| kserve-manager-role | "" | services, configmaps, secrets | create, delete, get, list, patch, update, watch |
| kserve-manager-role | "" | namespaces, pods, serviceaccounts, events | get, list, watch |
| kserve-manager-role | networking.k8s.io | ingresses | create, delete, get, list, patch, update, watch |
| kserve-manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | create, delete, get, list, patch, update, watch |
| kserve-leader-election-role | "" | configmaps | get, list, watch, create, update |

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
| storage-config | Opaque | Default credentials for S3/GCS/Azure storage access | User/Admin | No |
| {user-secret} | Opaque | User-provided storage credentials (referenced by annotation) | User | No |
| {gcp-sa-secret} | Opaque | GCP service account JSON key for GCS access | User | No |
| {aws-secret} | Opaque | AWS access key/secret for S3 access | User | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /v1/models/{model}:predict | POST | mTLS (Istio service mesh) | Istio sidecar proxy | Namespace-scoped network policies |
| /v2/models/{model}/infer | POST | mTLS (Istio service mesh) | Istio sidecar proxy | Namespace-scoped network policies |
| Webhook endpoints | POST | mTLS client certificate | Kubernetes API Server | API server authentication |
| External inference endpoint | POST | OAuth2/OIDC (optional via Authorino) | Istio AuthorizationPolicy | Token validation at ingress gateway |

## Data Flows

### Flow 1: Model Deployment via InferenceService

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | K8s token/cert |
| 2 | Kubernetes API Server | kserve-webhook-server | 443/TCP | HTTPS | TLS 1.2+ | API Server cert |
| 3 | kserve-controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service account token |
| 4 | kserve-controller | Knative Serving API | 6443/TCP | HTTPS | TLS 1.2+ | Service account token |
| 5 | storage-initializer | S3/GCS/Azure | 443/TCP | HTTPS | TLS 1.2+ | Storage credentials |
| 6 | storage-initializer | Local volume (/mnt/models) | N/A | Filesystem | None | None |

### Flow 2: Inference Request (Serverless Mode)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | Istio Ingress Gateway | 443/TCP | HTTPS | TLS 1.2+ | OAuth2 token (optional) |
| 2 | Istio Ingress Gateway | Knative Activator | 8012/TCP | HTTP | mTLS | Service mesh |
| 3 | Knative Activator | InferenceService Pod | 8080/TCP | HTTP | mTLS | Service mesh |
| 4 | kserve-agent (sidecar) | Runtime Container | 8080/TCP | HTTP | None (localhost) | None |
| 5 | Runtime Container | Model files (/mnt/models) | N/A | Filesystem | None | None |
| 6 | Runtime Container | kserve-agent | 8080/TCP | HTTP | None (localhost) | None |

### Flow 3: Multi-Model InferenceGraph Request

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | Istio Ingress Gateway | 443/TCP | HTTPS | TLS 1.2+ | OAuth2 token (optional) |
| 2 | Istio Ingress Gateway | kserve-router | 8080/TCP | HTTP | mTLS | Service mesh |
| 3 | kserve-router | Model A InferenceService | 80/TCP | HTTP | mTLS | Service mesh |
| 4 | kserve-router | Model B InferenceService | 80/TCP | HTTP | mTLS | Service mesh |
| 5 | kserve-router | Client (via gateway) | 80/TCP | HTTP | mTLS | Service mesh |

### Flow 4: Logging and Monitoring

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | kserve-agent | Knative Eventing Broker | 80/TCP | HTTP | mTLS | Service mesh |
| 2 | Runtime Container | Prometheus (scrape) | 8080/TCP | HTTP | mTLS | Service mesh |
| 3 | kserve-controller | Kubernetes API (events) | 6443/TCP | HTTPS | TLS 1.2+ | Service account token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Knative Serving | CRD reconciliation | 6443/TCP | HTTPS | TLS 1.2+ | Create/manage Knative Services for serverless inference |
| Istio | VirtualService CRD | 6443/TCP | HTTPS | TLS 1.2+ | Configure traffic routing, canary rollouts, and mTLS |
| cert-manager | Certificate CRD | 6443/TCP | HTTPS | TLS 1.2+ | Provision TLS certificates for webhook server |
| Prometheus | Metrics scraping | 8080/TCP | HTTP | mTLS | Collect controller and runtime metrics |
| Knative Eventing | CloudEvents API | 80/TCP | HTTP | mTLS | Send inference request/response logs |
| S3/GCS/Azure | Object storage API | 443/TCP | HTTPS | TLS 1.2+ | Download model artifacts during pod initialization |
| External model registries | HTTP/gRPC API | 443/TCP | HTTPS | TLS 1.2+ | Retrieve model metadata and download URIs |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 69cb9fee0 | 2024-06-12 | - Merge pull request for updating kserve 2.9<br>- Updated kserve 2.9 Tekton to add floating tags |
| 3f44989c4 | 2024-06-12 | - Updating kserve 2.9 Tekton to add floating tags |
| cb89d4dc4 | 2024-06-12 | - Red Hat Konflux update for kserve-agent-29 |
| db6878951 | 2024-06-12 | - Red Hat Konflux update for kserve-controller-29 |
| 9b0c25051 | 2024-06-12 | - Red Hat Konflux update for kserve-router-29 |
| 6459799cc | 2024-06-12 | - Red Hat Konflux update for kserve-storage-initializer-29 |

## Deployment Configuration

### Kustomize Structure

The component is deployed using Kustomize with manifests located in `config/`:

- **Base configuration**: `config/default/` - Contains base deployment manifests
- **CRDs**: `config/crd/` - All KServe Custom Resource Definitions
- **RBAC**: `config/rbac/` - ClusterRoles, RoleBindings, ServiceAccounts
- **Manager**: `config/manager/` - Controller manager deployment and service
- **Webhook**: `config/webhook/` - Webhook configurations and certificates
- **Runtimes**: `config/runtimes/` - Default ClusterServingRuntime definitions
- **Overlays**: `config/overlays/odh/` - ODH/RHOAI-specific configuration patches

### Container Images

| Image | Build Method | Purpose |
|-------|--------------|---------|
| kserve-controller | Dockerfile (Go multi-stage) | Controller manager binary |
| kserve-agent | agent.Dockerfile (Go multi-stage) | Agent/logger/batcher sidecar |
| kserve-router | router.Dockerfile (Go multi-stage) | InferenceGraph routing service |
| kserve-storage-initializer | storage-initializer.Dockerfile (Python) | Model download init container |
| kserve-sklearnserver | sklearn.Dockerfile (Python) | Scikit-learn serving runtime |
| kserve-xgbserver | xgb.Dockerfile (Python) | XGBoost serving runtime |
| kserve-lgbserver | lgb.Dockerfile (Python) | LightGBM serving runtime |

### Build Pipeline

All images are built using **Red Hat Konflux** CI/CD pipelines defined in `.tekton/`:

- `kserve-controller-29-push.yaml` - Controller image build and push
- `kserve-agent-29-push.yaml` - Agent image build and push
- `kserve-router-29-push.yaml` - Router image build and push
- `kserve-storage-initializer-29-push.yaml` - Storage initializer image build and push

## Configuration

### ConfigMaps

| ConfigMap Name | Namespace | Purpose |
|----------------|-----------|---------|
| inferenceservice-config | kserve | Global configuration for deployment mode, ingress, storage initializer, logger, batcher, agent, router settings |

### Key Configuration Options

**Deployment Mode**:
- `Serverless` (default for RHOAI): Uses Knative Serving with scale-to-zero
- `RawDeployment`: Uses standard Kubernetes Deployments without Knative

**Ingress Configuration**:
- Gateway: `knative-serving/knative-ingress-gateway`
- Ingress service: `istio-ingressgateway.istio-system.svc.cluster.local`
- Domain template: `{{ .Name }}-{{ .Namespace }}.{{ .IngressDomain }}`
- Istio VirtualHost creation is enabled by default

**Storage Initializer**:
- Memory request: 100Mi, limit: 1Gi
- CPU request: 100m, limit: 1
- Direct PVC volume mount: disabled (uses symlinks)

## Operational Considerations

### Resource Requirements

**Controller Manager**:
- CPU: 100m request, 100m limit
- Memory: 200Mi request, 300Mi limit

**Agent/Logger/Batcher Sidecars**:
- CPU: 100m-1 request, 1 limit
- Memory: 100Mi-1Gi request, 1Gi limit

**Runtime Containers** (defaults):
- CPU: 1 request, 1 limit
- Memory: 2Gi request, 2Gi limit

### High Availability

- Controller manager supports leader election (configurable via `--leader-elect` flag)
- Default: Single replica (leader election disabled for simplified deployment)
- Webhook server is stateless and can be scaled horizontally

### Observability

**Metrics**:
- Controller metrics exposed on port 8080 at `/metrics`
- Runtime container metrics exposed on port 8080 at `/metrics`
- Prometheus annotations configured on ServingRuntimes

**Logging**:
- Structured logging using zap logger
- Request/response logging via kserve-agent sidecar
- CloudEvents emitted to Knative Eventing broker (when configured)

**Health Checks**:
- Readiness: `/v2/health/ready` on runtime containers
- Liveness: `/v2/health/live` on runtime containers
- Webhook server: Kubernetes API Server performs health checks

### Backup and Recovery

**State Storage**:
- All state stored in Kubernetes resources (CRDs)
- etcd backup includes all InferenceService definitions

**Model Storage**:
- Models stored externally in S3/GCS/Azure/PVC
- No local persistent state in KServe components
- Re-deployment pulls models from source storage

### Troubleshooting

**Common Issues**:
1. **Model download failures**: Check storage credentials in secrets, verify network connectivity to S3/GCS
2. **Pod not ready**: Check storage-initializer logs, verify model URI format
3. **503 errors**: Check Knative Serving configuration, verify Istio VirtualService creation
4. **Webhook failures**: Verify cert-manager is running, check webhook certificate validity

**Debug Commands**:
```bash
# Check InferenceService status
kubectl get inferenceservice -n <namespace>

# View controller logs
kubectl logs -n kserve deployment/kserve-controller-manager

# Check webhook configuration
kubectl get mutatingwebhookconfigurations,validatingwebhookconfigurations | grep kserve

# Verify storage-initializer execution
kubectl logs <pod-name> -n <namespace> -c storage-initializer

# Check runtime logs
kubectl logs <pod-name> -n <namespace> -c kserve-container
```
