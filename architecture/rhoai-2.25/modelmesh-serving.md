# Component: ModelMesh Serving

## Metadata
- **Repository**: https://github.com/red-hat-data-services/modelmesh-serving.git
- **Version**: 1.27.0-rhods-480-ge5d8db5
- **Branch**: rhoai-2.25
- **Distribution**: RHOAI
- **Languages**: Go 1.25.7
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes controller that manages the lifecycle of ModelMesh Serving custom resources and associated infrastructure for multi-model serving.

**Detailed**: ModelMesh Serving is a controller that orchestrates ModelMesh, a high-performance, general-purpose model serving management and routing layer. It manages the deployment and lifecycle of inference runtimes (Triton, MLServer, OpenVINO, TorchServe) as Kubernetes resources, handling model placement, routing, and scaling across a cluster. The controller reconciles ServingRuntime and InferenceService custom resources, creating and managing the underlying deployments, services, and configurations needed for serving machine learning models at scale. It integrates with ETCD for distributed model metadata storage and supports multiple model formats and runtimes through a pluggable adapter architecture.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| modelmesh-controller | Kubernetes Operator | Main controller managing ServingRuntime, Predictor, and InferenceService resources |
| ModelMesh | Java Runtime | Model serving orchestration layer for model placement and request routing |
| REST Proxy | HTTP Proxy | Translates KServe V2 REST API to gRPC for model inference |
| Runtime Adapter | Container Sidecar | Intermediary between ModelMesh and model server containers (puller) |
| Storage Helper (Puller) | Init/Sidecar Container | Retrieves models from storage backends (S3, PVC) before loading |
| ETCD | Key-Value Store | Distributed storage for model metadata and cluster state |
| Webhook Server | Admission Controller | Validates ServingRuntime and ClusterServingRuntime resources |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Defines a serving runtime template for model servers in a namespace |
| serving.kserve.io | v1alpha1 | ClusterServingRuntime | Cluster | Defines a cluster-wide serving runtime template available to all namespaces |
| serving.kserve.io | v1alpha1 | Predictor | Namespaced | Defines a single model to be served (legacy API) |
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Defines a model inference service with predictor, transformer, and explainer |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Controller liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Controller readiness probe |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token | Prometheus metrics endpoint (controller) |
| /metrics | GET | 2112/TCP | HTTP | None | None | Prometheus metrics endpoint (runtime pods) |
| /v2/models/{model}/infer | POST | 8008/TCP | HTTP | None | None | KServe V2 REST inference endpoint (REST proxy) |
| /validate-serving-modelmesh-io-v1alpha1-servingruntime | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | ValidatingWebhook for ServingRuntime |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ModelMesh | 8033/TCP | gRPC | None | None | KServe V2 gRPC inference protocol (external serving) |
| ModelMesh (internal) | 8080/TCP | gRPC | None | None | Internal ModelMesh cluster communication |
| Puller | 8086/TCP | gRPC | None | None | Model storage pulling and loading coordination |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| ETCD | v3.5.9 | Yes | Distributed key-value store for model metadata and cluster coordination |
| Kubernetes | 1.28+ | Yes | Container orchestration platform |
| cert-manager | Latest | No | Automatic TLS certificate provisioning for webhooks (can use manual certs) |
| Prometheus Operator | v0.55.0 | No | ServiceMonitor CRD for metrics collection |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KServe | CRD | Shares InferenceService CRD schema (v1beta1) |
| Object Storage (S3) | Storage API | Model artifact storage backend |
| OpenShift Service Mesh | Network | Optional service mesh integration for mTLS and traffic management |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| modelmesh-webhook-server-service | ClusterIP | 9443/TCP | webhook | HTTPS | TLS 1.2+ | K8s API Server cert | Internal |
| controller-manager-metrics-service | ClusterIP | 8443/TCP | https | HTTPS | TLS 1.2+ | Bearer Token | Internal |
| modelmesh-serving (per runtime) | ClusterIP/Headless | 8033/TCP | 8033 | gRPC | None | None | Internal/External |
| modelmesh-serving (per runtime) | ClusterIP/Headless | 8008/TCP | 8008 | HTTP | None | None | Internal/External |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| N/A | N/A | N/A | N/A | N/A | N/A | N/A | Services exposed via OpenShift Routes or Istio VirtualServices (configured externally) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| ETCD | 2379/TCP | HTTP/gRPC | Optional TLS | Optional mTLS | Model metadata storage and retrieval |
| S3-compatible storage | 443/TCP | HTTPS | TLS 1.2+ | AWS Signature V4 / IAM | Model artifact retrieval |
| PVC storage | N/A | Filesystem | None | K8s RBAC | Model artifact retrieval from persistent volumes |
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token | Resource reconciliation and management |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| modelmesh-controller-role | "" | configmaps | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | "" | endpoints, persistentvolumeclaims | get, list, watch |
| modelmesh-controller-role | "" | namespaces, namespaces/finalizers | get, list, patch, update, watch |
| modelmesh-controller-role | "" | secrets | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | "" | services, services/finalizers | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | apps | deployments, deployments/finalizers | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | monitoring.coreos.com | servicemonitors | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | serving.kserve.io | inferenceservices, inferenceservices/finalizers, inferenceservices/status | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | serving.kserve.io | predictors, predictors/finalizers, predictors/status | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | serving.kserve.io | servingruntimes, servingruntimes/finalizers, servingruntimes/status | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | serving.kserve.io | clusterservingruntimes, clusterservingruntimes/finalizers, clusterservingruntimes/status | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | autoscaling | horizontalpodautoscalers, horizontalpodautoscalers/status | get, list, watch, create, delete, update |
| inferenceservice-editor-role | serving.kserve.io | inferenceservices | create, delete, get, list, patch, update, watch |
| inferenceservice-viewer-role | serving.kserve.io | inferenceservices | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| modelmesh-controller-rolebinding | Cluster-wide | modelmesh-controller-role (ClusterRole) | modelmesh-controller |
| modelmesh-controller-leader-election | Controller namespace | leader-election-role (Role) | modelmesh-controller |
| modelmesh-auth-proxy | Controller namespace | proxy-role (ClusterRole) | modelmesh-controller |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| storage-config | Opaque | S3/storage credentials for model retrieval | User/Admin | No |
| model-serving-etcd | Opaque | ETCD connection configuration and credentials | User/Admin | No |
| webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificate | cert-manager or manual | Yes (cert-manager) |
| modelmesh-webhook-server-cert | kubernetes.io/tls | Webhook TLS certificate (alternative) | cert-manager | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics (8443) | GET | Bearer Token (ServiceAccount) | kube-rbac-proxy | Kubernetes RBAC via TokenReview |
| /validate-* (9443) | POST | Kubernetes API Server client cert | Webhook server | K8s admission control |
| Inference endpoints (8033, 8008) | POST | Optional (application-level) | Application code | User-defined (can integrate with Service Mesh) |
| ETCD (2379) | ALL | Optional mTLS | ETCD server | ETCD auth (if enabled) |

### Network Policies

| Policy Name | Selector | Ingress Rules | Egress Rules |
|-------------|----------|---------------|--------------|
| modelmesh-controller | control-plane: modelmesh-controller | Allow 8443/TCP from all | N/A (default allow) |
| modelmesh-webhook | control-plane: modelmesh-controller | Allow 9443/TCP from all | N/A (default allow) |
| modelmesh-runtimes | modelmesh-service: * | Allow 8033/TCP, 8008/TCP, 2112/TCP from all; Allow 8080/TCP from modelmesh pods | N/A (default allow) |
| etcd | component: model-mesh-etcd | Allow 2379/TCP from modelmesh-enabled namespaces | N/A (default allow) |

## Data Flows

### Flow 1: Model Serving Request (gRPC)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External client | modelmesh-serving Service | 8033/TCP | gRPC | None | Optional (app-level) |
| 2 | modelmesh-serving Service | ModelMesh container | 8033/TCP | gRPC | None | None |
| 3 | ModelMesh container | Model runtime container | UDS or 8001/TCP | gRPC | None | None |
| 4 | ModelMesh container | ETCD | 2379/TCP | HTTP/gRPC | Optional TLS | Optional |

### Flow 2: Model Serving Request (REST)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External client | modelmesh-serving Service | 8008/TCP | HTTP | None | Optional (app-level) |
| 2 | modelmesh-serving Service | REST Proxy container | 8008/TCP | HTTP | None | None |
| 3 | REST Proxy container | ModelMesh container | 8033/TCP | gRPC | None | None |
| 4 | ModelMesh container | Model runtime container | UDS or 8001/TCP | gRPC | None | None |

### Flow 3: InferenceService Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/kubectl | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Kubernetes API | Webhook server | 9443/TCP | HTTPS | TLS 1.2+ | K8s API cert |
| 3 | Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 4 | Controller | ETCD (via created deployment) | 2379/TCP | HTTP/gRPC | Optional TLS | Optional |

### Flow 4: Model Loading from Storage

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Puller container (init) | storage-config Secret | N/A | K8s API | TLS 1.2+ | ServiceAccount |
| 2 | Puller container | S3/Storage endpoint | 443/TCP | HTTPS | TLS 1.2+ | AWS Signature V4 |
| 3 | Puller container | Shared volume | N/A | Filesystem | None | None |
| 4 | Runtime container | Shared volume | N/A | Filesystem | None | None |

### Flow 5: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | controller-manager-metrics-service | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Prometheus | Runtime pod metrics | 2112/TCP | HTTP | None | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Resource management and reconciliation |
| ETCD | gRPC/HTTP | 2379/TCP | gRPC/HTTP | Optional TLS | Model metadata storage and cluster coordination |
| Prometheus | HTTP Pull | 8443/TCP, 2112/TCP | HTTPS/HTTP | TLS 1.2+ (8443) | Metrics collection |
| S3-compatible storage | REST API | 443/TCP | HTTPS | TLS 1.2+ | Model artifact storage |
| KServe InferenceService | CRD | N/A | N/A | N/A | Shared API schema for inference services |
| ModelMesh (Java runtime) | gRPC | 8033/TCP, 8080/TCP | gRPC | None | Model serving and routing |
| Runtime adapters (Triton, MLServer, etc.) | gRPC | UDS or 8001/TCP | gRPC | None | Model inference execution |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 1.27.0-rhods-480 | 2026-03 | - Update UBI9 go-toolset base image<br>- Update controller-gen to 0.17.0<br>- Align envtest and k8s version<br>- Fix CVE-2025-61729 (crypto/x509) by upgrading to Go 1.25.7 |
| 1.27.0-rhods-460 | 2026-02 | - Sync pipelineruns with konflux-central<br>- Update UBI9 minimal base image<br>- CI fixes for setup-envtest |
| 1.27.0-rhods-440 | 2026-01 | - Security updates for base images<br>- Dependency updates via Renovate |

## Deployment Architecture

ModelMesh Serving follows a hub-and-spoke architecture:

1. **Controller Pod** (modelmesh-controller): Single-instance operator managing CRDs
2. **Runtime Pods** (per ServingRuntime): Multi-replica deployments containing:
   - ModelMesh container (Java-based routing/orchestration)
   - REST Proxy container (optional, HTTP→gRPC translation)
   - Model runtime container (Triton/MLServer/OpenVINO/TorchServe)
   - Storage helper/puller container (init container for model loading)
3. **ETCD Cluster**: Shared state storage for model metadata across runtime pods
4. **Per-namespace Services**: ClusterIP or headless services exposing inference endpoints

The controller watches for ServingRuntime and InferenceService resources, creating/updating the corresponding deployments with proper sidecar injection, volume mounts, and networking configuration.

## Configuration

Configuration is managed through:
- **ConfigMap** (`model-serving-config-defaults`): System defaults (pods per runtime, images, resources)
- **ConfigMap** (`model-serving-config`): User overrides
- **Secrets** (`storage-config`): Storage backend credentials
- **Secrets** (`model-serving-etcd`): ETCD connection details
- **Environment Variables**: Controller behavior flags (ENABLE_ISVC_WATCH, NAMESPACE_SCOPE, etc.)

## Monitoring and Observability

- **Metrics**: Prometheus-compatible metrics exposed on ports 8443 (controller) and 2112 (runtimes)
- **Health Checks**: Liveness (/healthz:8081) and readiness (/readyz:8081) probes
- **ServiceMonitor**: CRD for Prometheus Operator integration
- **Logging**: Structured logging via go-logr/zap
- **Dashboard**: Grafana dashboard template (ModelMeshMetricsDashboard.json) included

## High Availability

- Controller supports multi-replica deployment with leader election (lease-based)
- Runtime pods can scale horizontally (default: 2 pods per runtime)
- ETCD provides distributed coordination and failover
- Pod anti-affinity rules spread replicas across availability zones
- Headless services enable direct pod-to-pod communication for ModelMesh clustering
