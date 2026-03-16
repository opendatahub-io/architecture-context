# Component: ModelMesh Serving

## Metadata
- **Repository**: https://github.com/red-hat-data-services/modelmesh-serving.git
- **Version**: v1.27.0-rhods-256-g653c9b3
- **Branch**: rhoai-2.10
- **Distribution**: RHOAI
- **Languages**: Go, YAML (Kustomize)
- **Deployment Type**: Kubernetes Operator (Controller + Runtime Pods)

## Purpose
**Short**: Kubernetes controller for managing ModelMesh, a general-purpose model serving management and routing layer.

**Detailed**: ModelMesh Serving is a Kubernetes operator that orchestrates the deployment and lifecycle management of machine learning model serving infrastructure. It provides a controller that watches custom resources (Predictors, ServingRuntimes, InferenceServices) and dynamically creates runtime pods containing ModelMesh containers alongside model server runtimes (Triton, MLServer, OpenVINO, TorchServe). The controller manages model placement, routing, and scaling across multiple runtime pods, with support for multi-model serving where each pod can host multiple models. ModelMesh uses etcd for distributed coordination and model metadata storage, and provides both gRPC and REST inference endpoints. The architecture enables efficient resource utilization by loading models on-demand and sharing runtime containers across multiple models.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| modelmesh-controller | Kubernetes Operator | Reconciles Predictor, ServingRuntime, and InferenceService CRDs; creates runtime deployments and services |
| ModelMesh Runtime Pods | Deployment | Dynamically created pods containing ModelMesh routing layer, model server runtime, REST proxy, and storage puller |
| ModelMesh Container | Java Service | Routes inference requests, manages model loading/unloading, coordinates with etcd |
| Runtime Adapter | Go Service | Bridges ModelMesh and model server containers (Triton/MLServer/OVMS/TorchServe) |
| REST Proxy | Go Service | Translates KServe V2 REST API to gRPC for ModelMesh |
| Storage Puller | Go Service | Pulls models from S3/PVC storage before loading into runtime |
| etcd | Datastore | Stores model metadata, coordinates model placement across pods |
| Validating Webhook | Admission Controller | Validates ServingRuntime CR specifications |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1alpha1 | Predictor | Namespaced | Defines a model to be served, including model type, storage location, and runtime requirements |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Defines a model server runtime configuration (container image, supported formats, resource limits) |
| serving.kserve.io | v1alpha1 | ClusterServingRuntime | Cluster | Cluster-scoped ServingRuntime available to all namespaces |
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | KServe InferenceService CR for compatibility with KServe API (optional) |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /v2/models/{model}/infer | POST | 8008/TCP | HTTP | None | None | KServe V2 REST inference endpoint via proxy |
| /metrics | GET | 2112/TCP | HTTP | None | None | Prometheus metrics for runtime pods |
| /metrics | GET | 8080/TCP | HTTPS | TLS 1.2+ | mTLS | Controller metrics endpoint (auth proxy) |
| /healthz | GET | 8081/TCP | HTTP | None | None | Controller liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Controller readiness probe |
| /ready | GET | 8089/TCP | HTTP | None | None | ModelMesh container readiness probe |
| /validate-serving-modelmesh-io-v1alpha1-servingruntime | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API | Webhook validation for ServingRuntime CRs |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ModelMesh Inference | 8033/TCP | gRPC | None | None | KServe V2 gRPC inference protocol for model predictions |
| ModelMesh Internal | 8080/TCP | gRPC | None | None | Internal ModelMesh pod-to-pod communication for routing |
| Runtime Management | 8001/TCP | gRPC | None | None | Triton runtime management endpoint (internal to pod) |
| Triton Inference | 8085/TCP | gRPC | None | None | Triton gRPC inference endpoint (internal to pod) |
| Storage Puller | 8086/TCP | gRPC | None | None | Model download and storage management (internal to pod) |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| etcd | 3.x | Yes | Distributed key-value store for model metadata and pod coordination |
| S3-compatible storage | - | No | Object storage for model artifacts (alternative: PVC) |
| Prometheus | - | No | Metrics collection via ServiceMonitor |
| cert-manager | - | No | TLS certificate generation for webhooks |
| Triton Inference Server | 2.x | No | Nvidia model server runtime (one of multiple options) |
| MLServer | 1.x | No | Seldon Python model server runtime (one of multiple options) |
| OpenVINO Model Server | 1.x | No | Intel model server runtime (one of multiple options) |
| TorchServe | 0.x | No | PyTorch model server runtime (one of multiple options) |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| dashboard | UI/API | Dashboard integration for model management |
| monitoring | ServiceMonitor | Prometheus scraping of runtime and controller metrics |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| modelmesh-webhook-server-service | ClusterIP | 9443/TCP | webhook | HTTPS | TLS 1.2+ | K8s API | Internal |
| modelmesh-controller-metrics-service | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | mTLS | Internal |
| etcd | ClusterIP | 2379/TCP | 2379 | HTTP | None | None | Internal |
| {runtime-name}-{namespace} | ClusterIP or Headless | 8033/TCP | 8033 | gRPC | None | None | Internal |
| {runtime-name}-{namespace} | ClusterIP or Headless | 8008/TCP | 8008 | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| N/A | N/A | N/A | N/A | N/A | N/A | N/A | Internal only (no default ingress) |

Note: ModelMesh services are cluster-internal by default. External exposure requires user-created Route/Ingress.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| S3 endpoints | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM or access keys | Model artifact retrieval from object storage |
| etcd | 2379/TCP | HTTP | None | Optional basic auth | Model metadata read/write operations |
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token | CRD reconciliation and resource management |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| modelmesh-controller-role | "" | configmaps, secrets, services, namespaces, endpoints, persistentvolumeclaims | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | apps | deployments | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | serving.kserve.io | predictors, servingruntimes, clusterservingruntimes, inferenceservices | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | serving.kserve.io | predictors/status, servingruntimes/status, clusterservingruntimes/status, inferenceservices/status | get, patch, update |
| modelmesh-controller-role | autoscaling | horizontalpodautoscalers | create, delete, get, list, watch, update |
| modelmesh-controller-role | monitoring.coreos.com | servicemonitors | create, delete, get, list, patch, update, watch |
| leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| leader-election-role | "" | events | create, patch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| modelmesh-controller-rolebinding | cluster-wide | modelmesh-controller-role (ClusterRole) | modelmesh-controller |
| leader-election-rolebinding | controller-namespace | leader-election-role (Role) | modelmesh-controller |
| restricted-scc-rolebinding | controller-namespace | restricted-scc-role (ClusterRole) | modelmesh-serving-sa |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| model-serving-etcd | Opaque | etcd connection credentials (username, password) | User/Operator | No |
| storage-config | Opaque | S3/storage access credentials for model retrieval | User | No |
| model-serving-proxy-tls | kubernetes.io/tls | TLS certificates for metrics auth proxy | cert-manager or manual | No |
| modelmesh-webhook-server-cert | kubernetes.io/tls | TLS certificates for validating webhook | cert-manager | Yes (if cert-manager) |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics (controller) | GET | mTLS | kube-rbac-proxy | ServiceAccount token + ClusterRole |
| /validate-serving-* | POST | TLS client auth | K8s API server | Webhook admission controller |
| gRPC inference (8033) | POST | None (default) | Application-level | Optional user-defined AuthorizationPolicy |
| REST inference (8008) | POST | None (default) | Application-level | Optional user-defined AuthorizationPolicy |
| etcd | ALL | Basic auth (optional) | etcd server | Configured via secret |

## Data Flows

### Flow 1: Model Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | kubectl/ServiceAccount |
| 2 | Kubernetes API | modelmesh-controller | N/A | Watch | N/A | ServiceAccount token |
| 3 | modelmesh-controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount token |
| 4 | modelmesh-controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount token |

**Description**: User creates a Predictor CR → controller watches event → controller reconciles and creates/updates Deployment → runtime pods are scheduled.

### Flow 2: Model Loading

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | ModelMesh container | etcd | 2379/TCP | HTTP | None | Basic auth (optional) |
| 2 | ModelMesh container | Storage Puller | 8086/TCP | gRPC | None | None |
| 3 | Storage Puller | S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS credentials |
| 4 | Runtime Adapter | Model Server Runtime | 8001/TCP | gRPC | None | None |

**Description**: ModelMesh registers model in etcd → instructs puller to download → puller fetches from S3 → adapter loads into runtime server.

### Flow 3: Inference Request

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | Runtime Service | 8008/TCP | HTTP | None | None |
| 2 | REST Proxy | ModelMesh container | 8033/TCP | gRPC | None | None |
| 3 | ModelMesh container | etcd | 2379/TCP | HTTP | None | Basic auth |
| 4 | ModelMesh container | Runtime Pod (target) | 8080/TCP | gRPC | None | None |
| 5 | Model Server Runtime | ModelMesh container | 8085/TCP | gRPC | None | None |

**Description**: Client sends REST request → proxy converts to gRPC → ModelMesh routes to pod with loaded model → runtime executes inference → response returned.

### Flow 4: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | Runtime Pods | 2112/TCP | HTTP | None | None |
| 2 | Prometheus | Controller Metrics Service | 8443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |

**Description**: Prometheus scrapes metrics from runtime pods (direct HTTP) and controller (via auth proxy with mTLS).

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| etcd | Client connection | 2379/TCP | HTTP | None | Model metadata storage and distributed coordination |
| Kubernetes API | Client library | 6443/TCP | HTTPS | TLS 1.3 | CRD reconciliation and resource management |
| S3 Storage | HTTP client | 443/TCP | HTTPS | TLS 1.2+ | Model artifact retrieval |
| Prometheus | ServiceMonitor | 2112/TCP, 8443/TCP | HTTP/HTTPS | TLS for controller | Metrics scraping |
| Model Server Runtimes | gRPC adapter | 8001/TCP, 8085/TCP | gRPC | None | Model loading and inference execution |
| KServe InferenceService | CRD watch | N/A | N/A | N/A | Optional compatibility with KServe API |

## Network Policies

### Controller Network Policy

| Name | Pod Selector | Ingress Rules | Egress Rules |
|------|-------------|---------------|--------------|
| modelmesh-controller | control-plane=modelmesh-controller | Allow 8443/TCP (metrics) | Implicit allow all |

### Runtime Pods Network Policy

| Name | Pod Selector | Ingress Rules | Egress Rules |
|------|-------------|---------------|--------------|
| modelmesh-runtimes | modelmesh-service exists | Allow 8033/TCP (gRPC), 8008/TCP (REST), 2112/TCP (metrics), 8080/TCP (internal) from modelmesh pods; Allow 8033/TCP, 8008/TCP, 2112/TCP from any | Implicit allow all |

## Deployment Configuration

### Controller Deployment

- **Replicas**: 1 (can be increased to 3 for HA)
- **Leader Election**: Configurable (lease or leader-for-life)
- **Resource Requests**: CPU 50m, Memory 96Mi
- **Resource Limits**: CPU 1, Memory 512Mi
- **Health Probes**: Liveness (/healthz:8081), Readiness (/readyz:8081)
- **Service Account**: modelmesh-controller

### Runtime Deployments (Per ServingRuntime)

- **Replicas**: 2 (default, configurable via podsPerRuntime)
- **Containers**:
  - **mm** (ModelMesh): CPU 300m-3, Memory 448Mi
  - **runtime** (Triton/MLServer/OVMS/TorchServe): Varies by runtime
  - **rest-proxy**: CPU 50m-1, Memory 96Mi-512Mi
  - **storage-puller**: CPU 50m-2, Memory 96Mi-512Mi
- **Service Account**: modelmesh-serving-sa
- **Volumes**: models-dir, domain-socket, etcd-config, storage-config

### Configuration

| ConfigMap | Purpose | Key Parameters |
|-----------|---------|----------------|
| model-serving-config-defaults | Default runtime configuration | podsPerRuntime: 2, modelMeshImage, storageHelperImage, restProxy.enabled: true |
| model-serving-config | User overrides (optional) | User-customizable runtime parameters |

## Recent Changes

Note: Recent commits unavailable in the current checkout. Version v1.27.0-rhods-256-g653c9b3 represents the RHOAI 2.10 release branch.

| Version | Date | Changes |
|---------|------|---------|
| v1.27.0-rhods-256 | 2024-2026 | - RHOAI 2.10 release branch<br>- Integration with OpenDataHub operator<br>- Support for multiple model server runtimes<br>- Enhanced network policies for security |

## Component Versions

Default runtime images (configurable):
- **ModelMesh**: kserve/modelmesh:latest
- **REST Proxy**: kserve/rest-proxy:latest
- **Runtime Adapter**: kserve/modelmesh-runtime-adapter:latest
- **Triton Server**: tritonserver-2:replace
- **MLServer**: Seldon MLServer 1.x
- **OpenVINO**: OVMS 1.x
- **TorchServe**: TorchServe 0.x

## Operational Notes

### Namespace Scoping

The controller supports two modes:
- **Cluster-scope** (default): Watches and manages resources across all namespaces
- **Namespace-scope**: Operates only within its own namespace (set NAMESPACE_SCOPE=true)

### Model Storage

Supports multiple storage backends:
- **S3-compatible object storage**: Primary method, configured via storage-config secret
- **PersistentVolumeClaim**: Alternative for on-cluster storage
- **Storage providers**: AWS S3, MinIO, Ceph, etc.

### High Availability

- Controller supports multiple replicas with leader election
- Runtime pods can be scaled via podsPerRuntime configuration
- ModelMesh automatically rebalances models across available pods
- etcd should be deployed with 3+ replicas for production

### Monitoring

- Prometheus metrics exposed on port 2112 (runtimes) and 8443 (controller)
- ServiceMonitor automatically created if Prometheus Operator is available
- Metrics include: model load time, inference latency, request count, cache hit ratio

### Security Hardening

- Runtime pods run with restricted SCC
- Capabilities dropped: ALL
- Network policies restrict ingress to required ports
- Webhook validates ServingRuntime specifications
- Optional mTLS for inter-pod communication (requires service mesh)
