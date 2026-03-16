# Component: ModelMesh Serving

## Metadata
- **Repository**: https://github.com/red-hat-data-services/modelmesh-serving
- **Version**: v1.27.0-rhods-217 (based on upstream kserve/modelmesh-serving v0.11.0)
- **Branch**: rhoai-2.8
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Controller for managing ModelMesh, a multi-model serving system that provides intelligent model placement and routing.

**Detailed**: ModelMesh Serving is a Kubernetes operator that manages the lifecycle of ModelMesh, a general-purpose model serving management and routing layer. It orchestrates the deployment of model serving runtimes (Triton, MLServer, OpenVINO, TorchServe) and manages model placement across pods for efficient resource utilization. The controller reconciles custom resources (Predictors, ServingRuntimes, InferenceServices) and creates the necessary Kubernetes resources (Deployments, Services) to serve machine learning models at scale. It uses etcd for distributed state management and supports both gRPC and REST inference protocols.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| modelmesh-controller | Deployment | Kubernetes operator that reconciles CRDs and manages ModelMesh runtime deployments |
| ModelMesh Runtime Pods | Deployment | Per-ServingRuntime deployments containing model mesh, runtime adapter, puller, and model server containers |
| etcd | StatefulSet | Distributed key-value store for ModelMesh state management and model placement coordination |
| REST Proxy | Container (sidecar) | Translates KServe V2 REST protocol to gRPC for inference requests |
| Storage Helper (Puller) | Init/Sidecar Container | Retrieves models from object storage (S3, PVC) before loading |
| Webhook Server | Service | Validates ServingRuntime custom resources |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1alpha1 | Predictor | Namespaced | Defines a model deployment with storage location, model type, and runtime selection |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Defines a model serving runtime container and its supported model formats |
| serving.kserve.io | v1alpha1 | ClusterServingRuntime | Cluster | Cluster-scoped serving runtime available across all namespaces |
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | KServe InferenceService compatibility (optional, can be disabled) |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Controller metrics endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Controller readiness probe |
| /healthz | GET | 8081/TCP | HTTP | None | None | Controller liveness probe |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token | Controller metrics (auth proxy) |
| /validate-serving-modelmesh-io-v1alpha1-servingruntime | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server cert | Webhook validation for ServingRuntime |
| /v2/models/{model}/infer | POST | 8008/TCP | HTTP | None | None | KServe V2 REST inference (via REST proxy) |
| /metrics | GET | 2112/TCP | HTTP | None | None | ModelMesh runtime pod Prometheus metrics |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| inference.GRPCInferenceService | 8033/TCP | gRPC | plaintext | None | KServe V2 gRPC inference endpoint |
| ModelMesh internal | 8080/TCP | gRPC | plaintext | None | Internal ModelMesh container communication (litelinks) |
| Runtime adapter | 8085/TCP | gRPC | plaintext | None | Adapter to model server communication |
| Model server data | 8001/TCP | gRPC | plaintext | None | Runtime-specific model management endpoint |
| Puller service | 8086/TCP | gRPC | plaintext | None | Model loading/unloading orchestration |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| etcd | v3.5.4+ | Yes | Distributed state management for model placement and routing |
| Object Storage (S3/Minio) | N/A | Yes | Model artifact storage |
| cert-manager | v1.0+ | No | TLS certificate management for webhooks (optional) |
| Prometheus Operator | v0.55+ | No | Service Monitor CRD for metrics collection |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| kserve | CRD Compatibility | Optionally reconciles KServe InferenceService CRDs |
| Model Registry | Storage Integration | Models stored in S3-compatible storage configured via secrets |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | https | HTTPS | TLS 1.2+ | Bearer Token | Internal |
| modelmesh-webhook-server-service | ClusterIP | 9443/TCP | webhook | HTTPS | TLS 1.2+ | K8s API cert | Internal |
| modelmesh-serving (per namespace) | ClusterIP | 8033/TCP | 8033 | gRPC | plaintext | None | Internal |
| modelmesh-serving (headless, optional) | ClusterIP (headless) | 8033/TCP | 8033 | gRPC | plaintext | None | Internal |
| etcd | ClusterIP | 2379/TCP | 2379 | HTTP | plaintext | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| N/A | N/A | N/A | N/A | N/A | N/A | N/A | Inference traffic typically routed through Istio Gateway or OpenShift Route (configured externally) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| S3/Minio Storage | 443/TCP or 9000/TCP | HTTPS/HTTP | TLS 1.2+ or plaintext | AWS IAM or Access Keys | Model artifact retrieval |
| etcd | 2379/TCP | HTTP | plaintext | Optional (TLS/Basic Auth) | State management and coordination |
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | CRD reconciliation and resource management |

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
| modelmesh-controller-role | autoscaling | horizontalpodautoscalers | create, delete, get, list, update, watch |
| modelmesh-controller-role | monitoring.coreos.com | servicemonitors | create, delete, get, list, patch, update, watch |
| leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| auth-proxy-role | authentication.k8s.io | tokenreviews | create |
| auth-proxy-role | authorization.k8s.io | subjectaccessreviews | create |
| predictor-editor-role | serving.kserve.io | predictors | create, delete, get, list, patch, update, watch |
| servingruntime-editor-role | serving.kserve.io | servingruntimes | create, delete, get, list, patch, update, watch |
| inferenceservice-editor-role | serving.kserve.io | inferenceservices | create, delete, get, list, patch, update, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| modelmesh-controller-rolebinding | (cluster-scope) | modelmesh-controller-role | modelmesh-controller |
| leader-election-rolebinding | modelmesh-serving | leader-election-role | modelmesh-controller |
| auth-proxy-rolebinding | modelmesh-serving | auth-proxy-role | modelmesh-controller |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| model-serving-etcd | Opaque | etcd connection configuration (endpoints, auth, root_prefix) | User/Operator | No |
| storage-config | Opaque | S3/object storage credentials for model retrieval | User | No |
| modelmesh-webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificate | cert-manager or manual | Yes (cert-manager) |
| controller-manager-metrics-tls | kubernetes.io/tls | Metrics endpoint TLS certificate | Service CA or cert-manager | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics (8443) | GET | Bearer Token (ServiceAccount) | kube-rbac-proxy sidecar | TokenReview + SubjectAccessReview |
| /validate-* (9443) | POST | Kubernetes API Server mutual TLS | Kubernetes Admission Controller | API server validates webhook config |
| etcd (2379) | gRPC | Optional Basic Auth or TLS client certs | etcd server | Configured in etcd_connection secret |
| Inference (8033, 8008) | POST | None (application-level auth external) | Application or Service Mesh | User configures AuthorizationPolicy |

## Data Flows

### Flow 1: Model Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | Bearer Token |
| 2 | Kubernetes API | modelmesh-controller webhook | 9443/TCP | HTTPS | TLS 1.2+ | K8s API cert |
| 3 | modelmesh-controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |
| 4 | modelmesh-controller | etcd | 2379/TCP | HTTP | plaintext | Optional Basic Auth |

### Flow 2: Model Loading

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Puller init container | S3/Minio | 443/TCP or 9000/TCP | HTTPS/HTTP | TLS 1.2+ or plaintext | AWS IAM or Access Keys |
| 2 | Puller | Model Server | 8001/TCP | gRPC | plaintext | None |
| 3 | Runtime Adapter | Model Server | 8085/TCP | gRPC | plaintext | None |
| 4 | ModelMesh | etcd | 2379/TCP | HTTP | plaintext | Optional Basic Auth |

### Flow 3: Inference Request

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | modelmesh-serving Service | 8033/TCP or 8008/TCP | gRPC or HTTP | plaintext | None (app-level) |
| 2 | REST Proxy (if REST) | ModelMesh | 8033/TCP | gRPC | plaintext | None |
| 3 | ModelMesh | Runtime Adapter | 8085/TCP | gRPC | plaintext | None |
| 4 | Runtime Adapter | Model Server | 8001/TCP | gRPC | plaintext | None |

### Flow 4: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | controller-manager-metrics-service | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Prometheus | modelmesh-serving pods | 2112/TCP | HTTP | plaintext | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API | REST API Client | 6443/TCP | HTTPS | TLS 1.3 | CRD reconciliation, resource management |
| etcd | gRPC Client | 2379/TCP | HTTP | plaintext | Model placement state, distributed coordination |
| Object Storage (S3) | REST API Client | 443/TCP | HTTPS | TLS 1.2+ | Model artifact storage and retrieval |
| Prometheus | Metrics Scrape | 8443/TCP, 2112/TCP | HTTPS/HTTP | TLS 1.2+/plaintext | Monitoring and observability |
| cert-manager | Certificate Consumer | N/A | N/A | N/A | Webhook and metrics TLS certificates |
| Service Mesh (Istio) | Service Integration | 8033/TCP, 8008/TCP | gRPC/HTTP | mTLS (optional) | Inference traffic routing and security |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| v1.27.0-rhods-217 | 2025-09-02 | - Update UBI minimal base image to resolve security vulnerabilities<br>- Konflux build pipeline updates |
| v1.27.0-rhods-216 | 2025-07-31 | - Update base images for security patches<br>- Upgrade k8s.io/apimachinery to resolve CVE-2023-44487 |
| v1.27.0-rhods-215 | 2025-07-12 | - Resolve CVE-2023-44487 (HTTP/2 Rapid Reset attack)<br>- Update Golang dependencies |
| v1.27.0-rhods-200+ | 2025-03-20 to 2025-06-23 | - Regular UBI base image security updates<br>- Konflux CI/CD pipeline enhancements<br>- Dependency version bumps for security patches |

## Network Policies

### Controller Network Policy

| Policy Name | Pod Selector | Ingress Rules | Egress Rules |
|-------------|--------------|---------------|--------------|
| modelmesh-controller | control-plane: modelmesh-controller | Allow 8443/TCP (metrics) from any | Default allow all |

### Runtime Network Policy

| Policy Name | Pod Selector | Ingress Rules | Egress Rules |
|-------------|--------------|---------------|--------------|
| modelmesh-runtimes | modelmesh-service exists | Allow 8033/TCP, 8008/TCP (inference) from any<br>Allow 8033/TCP, 8080/TCP from modelmesh pods<br>Allow 2112/TCP (metrics) from any | Default allow all |

### etcd Network Policy

| Policy Name | Pod Selector | Ingress Rules | Egress Rules |
|-------------|--------------|---------------|--------------|
| etcd | component: model-mesh-etcd | Allow 2379/TCP from modelmesh-enabled namespaces | Default allow all |

## Deployment Configuration

### Controller Pod Specification

| Setting | Value | Purpose |
|---------|-------|---------|
| Replicas | 1 (recommended 3 for HA) | Controller instances |
| CPU Request | 50m | Minimum CPU allocation |
| Memory Request | 96Mi | Minimum memory allocation |
| CPU Limit | 1000m | Maximum CPU usage |
| Memory Limit | 512Mi | Maximum memory usage |
| Service Account | modelmesh-controller | RBAC identity |
| Leader Election | Enabled | High availability coordination |
| Readiness Probe | /readyz:8081 | Traffic routing readiness |
| Liveness Probe | /healthz:8081 | Pod health check |

### Runtime Pod Specification (Default)

| Container | CPU Request | Memory Request | CPU Limit | Memory Limit |
|-----------|-------------|----------------|-----------|--------------|
| modelmesh | 300m | 448Mi | 3000m | 448Mi |
| rest-proxy | 50m | 96Mi | 1000m | 512Mi |
| puller | 50m | 96Mi | 2000m | 512Mi |
| runtime (e.g., mlserver) | 500m | 1Gi | 5000m | 1Gi |

## Configuration

### ConfigMap: model-serving-config-defaults

| Setting | Default | Purpose |
|---------|---------|---------|
| podsPerRuntime | 2 | Number of runtime pods per ServingRuntime |
| headlessService | true | Enable headless service for direct pod access |
| modelMeshImage | kserve/modelmesh:v0.11.1 | ModelMesh container image |
| restProxy.enabled | true | Enable REST to gRPC proxy |
| restProxy.port | 8008 | REST proxy listening port |
| storageHelperImage | kserve/modelmesh-runtime-adapter:v0.11.1 | Puller/adapter image |
| serviceAccountName | modelmesh-serving-sa | Service account for runtime pods |
| metrics.enabled | true | Enable Prometheus metrics |
| builtInServerTypes | triton, mlserver, ovms, torchserve | Supported runtime types |

## Built-in Serving Runtimes

| Runtime | Model Formats | Protocol | Port | Image |
|---------|---------------|----------|------|-------|
| Triton 2.x | tensorflow, pytorch, onnx, tensorrt | grpc-v2 | 8001 | triton-inference-server |
| MLServer 1.x | sklearn, xgboost, lightgbm | grpc-v2 | 8001 | seldon/mlserver |
| OpenVINO 1.x | openvino_ir, onnx | grpc-v2 | 8001 | openvino/model_server |
| TorchServe 0.x | pytorch | grpc-v2 | 8085 | pytorch/torchserve |

## Operational Notes

1. **Namespace Scoping**: Controller can operate in cluster-scope (all namespaces) or namespace-scope (single namespace) mode via `NAMESPACE_SCOPE` environment variable
2. **Leader Election**: Supports both "lease" (recommended) and "leader-for-life" election modes for high availability
3. **etcd Dependency**: etcd is required for ModelMesh coordination; failures will prevent model loading
4. **Storage Configuration**: Models must be accessible via S3-compatible storage or PVCs; credentials configured in `storage-config` secret
5. **Port Reservations**: Ports 11881-11899 and standard ModelMesh ports (8033, 8080, 8086) are reserved and cannot be used by custom runtime containers
6. **Metrics**: Controller and runtime pods expose Prometheus metrics; ServiceMonitor created automatically if Prometheus Operator CRD exists
7. **Webhook Certificates**: Requires valid TLS certificates for webhook validation; can be provisioned by cert-manager or manually
8. **Model Caching**: Models are cached in emptyDir volumes within runtime pods; storage size should be planned accordingly
