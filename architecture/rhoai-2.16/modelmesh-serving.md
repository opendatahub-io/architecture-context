# Component: ModelMesh Serving Controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/modelmesh-serving.git
- **Version**: v-2160-127-gc61104d
- **Branch**: rhoai-2.16
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Manages the lifecycle of ModelMesh-based model serving deployments and routes inference requests to ML models.

**Detailed**: ModelMesh Serving Controller is a Kubernetes operator that manages ModelMesh, a high-performance model serving platform designed for high-scale, high-density, and frequently-changing model use cases. The controller reconciles custom resources (Predictors, ServingRuntimes, and optionally InferenceServices) to deploy and manage model serving infrastructure. It coordinates with etcd for distributed state management, deploys model runtime pods with appropriate adapters, and provides both gRPC and REST inference endpoints. The controller handles model loading/unloading, placement optimization across pods, and integrates with various ML frameworks (Triton, MLServer, OpenVINO, TorchServe) through a runtime adapter pattern. It supports features like autoscaling, metrics collection, TLS encryption, and multi-tenant model serving with namespace isolation.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| modelmesh-controller | Go Operator | Reconciles Predictor, ServingRuntime, and ClusterServingRuntime CRs; manages model serving deployments |
| ModelMesh | Java Service | Model placement, routing, and lifecycle management across serving pods |
| REST Proxy | Go Service | Translates KServe V2 REST API to gRPC for inference requests |
| Runtime Adapter/Puller | Go Service | Pulls models from storage (S3, PVC, etc.) and adapts between ModelMesh and ML framework containers |
| etcd | Key-Value Store | Distributed coordination and state management for ModelMesh cluster |
| Serving Runtime Pods | Container Group | Model server containers (Triton, MLServer, OpenVINO, TorchServe) with ModelMesh sidecar |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1alpha1 | Predictor | Namespaced | Defines a model to be served, including storage location, runtime, and model type |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Defines a model serving runtime template (container specs, supported model types) |
| serving.kserve.io | v1alpha1 | ClusterServingRuntime | Cluster | Cluster-wide ServingRuntime template available to all namespaces |
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Optional KServe InferenceService support for compatibility (controlled by ENABLE_ISVC_WATCH) |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Controller Prometheus metrics |
| /readyz | GET | 8081/TCP | HTTP | None | None | Controller readiness probe |
| /healthz | GET | 8081/TCP | HTTP | None | None | Controller liveness probe |
| /validate-serving-modelmesh-io-v1alpha1-servingruntime | POST | 9443/TCP | HTTPS | TLS 1.2+ | Webhook | Validating webhook for ServingRuntime resources |
| /oauth/healthz | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth | Auth proxy health check |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth | Controller metrics via auth proxy |
| /v2/models/*/infer | POST | 8008/TCP | HTTP/HTTPS | Optional TLS | Optional | REST inference endpoint (KServe V2 protocol) |
| /ready | GET | 8089/TCP | HTTP | None | None | ModelMesh pod readiness |
| /live | GET | 8089/TCP | HTTP | None | None | ModelMesh pod liveness |
| /metrics | GET | 2112/TCP | HTTP | None | None | ModelMesh runtime pod Prometheus metrics |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| inference.GRPCInferenceService | 8033/TCP | gRPC | Optional mTLS | Optional | KServe V2 gRPC inference protocol endpoint |
| modelmesh.ModelRuntime | 8033/TCP | gRPC | Optional mTLS | Optional | Internal ModelMesh runtime API |
| modelmesh.ModelMesh | 8033/TCP | gRPC | Optional mTLS | Optional | Internal ModelMesh management API |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| etcd | 3.x | Yes | Distributed key-value store for ModelMesh coordination and model registry |
| Kubernetes | 1.23+ | Yes | Container orchestration platform |
| cert-manager | v1.0+ | No | Certificate management for webhook TLS (optional) |
| Prometheus Operator | v0.50+ | No | ServiceMonitor CRD for metrics collection (optional) |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| kserve/modelmesh | Container Image | Core model mesh runtime for model placement and routing |
| kserve/rest-proxy | Container Image | REST to gRPC translation for HTTP inference requests |
| kserve/modelmesh-runtime-adapter | Container Image | Multi-purpose adapter and storage puller for model loading |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | https | HTTPS | TLS 1.2+ | OAuth | Internal |
| modelmesh-webhook-server-service | ClusterIP | 9443/TCP | webhook | HTTPS | TLS 1.2+ | Webhook | Internal |
| modelmesh-serving (per ServingRuntime) | ClusterIP or Headless | 8033/TCP | 8033 | gRPC | Optional mTLS | Optional | Internal/External |
| modelmesh-serving (REST) | ClusterIP | 8008/TCP | 8008 | HTTP/HTTPS | Optional TLS | Optional | Internal/External |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| Configured by platform | Istio Gateway / Route | Platform-dependent | 8033/TCP | gRPC | Optional TLS | SIMPLE | External |
| Configured by platform | Istio Gateway / Route | Platform-dependent | 8008/TCP | HTTPS | Optional TLS | SIMPLE | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| S3-compatible storage | 443/TCP | HTTPS | TLS 1.2+ | AWS Signature V4 | Model artifact retrieval from S3 buckets |
| etcd service | 2379/TCP | TCP | Optional TLS | Optional mTLS | ModelMesh coordination and state management |
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | CR reconciliation and resource management |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| modelmesh-controller-role | "" | configmaps, secrets, services, namespaces | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | "" | endpoints, persistentvolumeclaims | get, list, watch |
| modelmesh-controller-role | apps | deployments | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | serving.kserve.io | predictors, servingruntimes, clusterservingruntimes, inferenceservices | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | serving.kserve.io | predictors/status, servingruntimes/status, clusterservingruntimes/status, inferenceservices/status | get, patch, update |
| modelmesh-controller-role | serving.kserve.io | predictors/finalizers, servingruntimes/finalizers, clusterservingruntimes/finalizers, inferenceservices/finalizers | get, patch, update |
| modelmesh-controller-role | autoscaling | horizontalpodautoscalers | create, delete, get, list, watch, update |
| modelmesh-controller-role | monitoring.coreos.com | servicemonitors | create, delete, get, list, patch, update, watch |
| predictor-editor-role | serving.kserve.io | predictors | create, delete, get, list, patch, update, watch |
| predictor-viewer-role | serving.kserve.io | predictors | get, list, watch |
| servingruntime-editor-role | serving.kserve.io | servingruntimes | create, delete, get, list, patch, update, watch |
| servingruntime-viewer-role | serving.kserve.io | servingruntimes | get, list, watch |
| leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| modelmesh-controller-rolebinding | All or controller namespace | modelmesh-controller-role | modelmesh-controller |
| leader-election-rolebinding | Controller namespace | leader-election-role | modelmesh-controller |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| model-serving-etcd | Opaque | etcd connection credentials (username, password, endpoints) | Administrator | No |
| model-serving-proxy-tls | kubernetes.io/tls | TLS certificates for service mesh proxy | cert-manager or admin | Yes (cert-manager) |
| storage-config | Opaque | S3 or storage credentials for model artifact retrieval | Administrator | No |
| modelmesh-webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificate | cert-manager | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| :8033/inference.* | gRPC | Optional mTLS | Istio/Service Mesh | PeerAuthentication PERMISSIVE/STRICT |
| :8008/v2/* | POST | Optional Bearer Token | Application/Istio | AuthorizationPolicy |
| :9443/validate-* | POST | Kubernetes API Server | kube-apiserver | ValidatingWebhookConfiguration |
| :8443/metrics | GET | OAuth Proxy | kube-rbac-proxy | TokenReview + SubjectAccessReview |

### Network Policies

| Policy Name | Pod Selector | Ingress Rules | Purpose |
|-------------|--------------|---------------|---------|
| modelmesh-controller | control-plane=modelmesh-controller | Allow 8443/TCP | Restrict controller metrics access |
| modelmesh-runtimes | modelmesh-service exists | Allow 8033, 8008, 8080, 2112/TCP from modelmesh pods and external | Restrict runtime pod access to inference and metrics |
| etcd | component=model-mesh-etcd | Allow 2379/TCP from modelmesh-enabled namespaces | Restrict etcd access to modelmesh components |

## Data Flows

### Flow 1: Model Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | modelmesh-controller | etcd | 2379/TCP | TCP | Optional TLS | Optional mTLS |
| 3 | modelmesh-controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | modelmesh-controller (creates Deployment) | kubelet | N/A | Internal | N/A | N/A |
| 5 | Runtime Pod (puller) | S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS Signature V4 |
| 6 | Runtime Pod (adapter) | ModelMesh | 8033/TCP | gRPC | Optional mTLS | Optional |
| 7 | Runtime Pod (ModelMesh) | etcd | 2379/TCP | TCP | Optional TLS | Optional mTLS |

### Flow 2: Inference Request (gRPC)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | Istio Gateway/Route | 443/TCP | HTTPS | TLS 1.3 | Optional Bearer Token |
| 2 | Istio Proxy | modelmesh-serving Service | 8033/TCP | gRPC | Optional mTLS | Optional |
| 3 | ModelMesh | Runtime Adapter | UDS or 8080/TCP | gRPC | None (local) | None |
| 4 | Runtime Adapter | Model Server Container | UDS or runtime-specific | Framework-specific | None (local) | None |

### Flow 3: Inference Request (REST)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | Istio Gateway/Route | 443/TCP | HTTPS | TLS 1.3 | Optional Bearer Token |
| 2 | Istio Proxy | modelmesh-serving Service | 8008/TCP | HTTP/HTTPS | Optional TLS | Optional |
| 3 | REST Proxy | ModelMesh | 8033/TCP | gRPC | Optional mTLS | Optional |
| 4 | ModelMesh | Runtime Adapter | UDS or 8080/TCP | gRPC | None (local) | None |
| 5 | Runtime Adapter | Model Server Container | UDS or runtime-specific | Framework-specific | None (local) | None |

### Flow 4: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | Controller metrics service | 8443/TCP | HTTPS | TLS 1.2+ | OAuth |
| 2 | Prometheus | Runtime pods | 2112/TCP | HTTP | None | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| etcd | TCP Client | 2379/TCP | TCP | Optional TLS | Distributed state and model registry for ModelMesh coordination |
| Kubernetes API | REST Client | 6443/TCP | HTTPS | TLS 1.2+ | CR reconciliation, deployment management, secret/configmap access |
| Prometheus | HTTP Scrape | 2112/TCP, 8080/TCP, 8443/TCP | HTTP/HTTPS | Varies | Metrics collection from controller and runtime pods |
| S3/Storage | HTTP Client | 443/TCP | HTTPS | TLS 1.2+ | Model artifact retrieval during deployment |
| Istio/Service Mesh | Sidecar Proxy | Various | Various | mTLS | Traffic management, authorization, telemetry |
| cert-manager | Certificate Request | N/A | Kubernetes CR | N/A | TLS certificate provisioning for webhooks and services |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| v-2160-127 | 2026-03-04 | - Update UBI8 minimal base image to digest b880e16<br>- Dependency updates for security patches |
| v-2160-126 | 2026-02-24 | - Update UBI8 minimal base image to digest 6ed9271 |
| v-2160-125 | 2026-02-23 | - Update UBI8 minimal base image to digest 4189e1e |
| v-2160-124 | 2026-02-11 | - Update UBI8 minimal base image to digest 48adecc<br>- Update Go toolset to 1.25.5 (digest 82b82ec) |
| v-2160-123 | 2026-02-10 | - Sync Konflux pipeline runs with central config |
| v-2160-122 | 2026-02-09 | - Multiple Dockerfile digest updates for base images |
| v-2160-121 | 2026-02-04 | - Update UBI8 minimal to digest 000dd8e |
| v-2160-120 | 2026-02-02 | - Update Go version to 1.25.5 in go.mod<br>- Update Go toolset base image |

## Deployment Configuration

### Manifests Location
The kustomize deployment manifests are located in `config/` with the following structure:
- **Base manifests**: `config/default/`, `config/manager/`, `config/rbac/`, `config/webhook/`
- **CRDs**: `config/crd/bases/`
- **ODH/RHOAI overlays**: `config/overlays/odh/`
- **Internal runtime templates**: `config/internal/base/` (Go templates for runtime deployments)

### Key Configuration
The controller uses a layered configuration approach:
1. **Default config**: `config/default/config-defaults.yaml` (embedded in controller)
2. **User config**: ConfigMap `model-serving-config` in controller namespace
3. **Environment variables**: Various feature flags (ENABLE_ISVC_WATCH, ENABLE_CSR_WATCH, NAMESPACE_SCOPE)

### Deployment Modes
- **Cluster Scope** (default): Controller manages all namespaces, requires ClusterRole
- **Namespace Scope**: Controller manages only its own namespace, uses namespaced Role

### High Availability
- Controller supports multiple replicas with leader election (lease-based or leader-for-life)
- Default: 1 replica, can safely increase to 3 for HA
- Runtime pods: Configurable via `podsPerRuntime` (default: 2)

## Container Images

| Image | Purpose | Build Method |
|-------|---------|--------------|
| odh-modelmesh-serving-controller-rhel8 | Controller binary | Multi-stage build via Dockerfile.konflux (Go 1.25.5, UBI8 minimal runtime) |
| kserve/modelmesh | ModelMesh runtime | External dependency (configured in config-defaults) |
| kserve/rest-proxy | REST to gRPC proxy | External dependency (configured in config-defaults) |
| kserve/modelmesh-runtime-adapter | Storage puller and adapter | External dependency (configured in config-defaults) |
