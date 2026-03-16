# Component: ModelMesh Serving

## Metadata
- **Repository**: https://github.com/red-hat-data-services/modelmesh-serving.git
- **Version**: v1.27.0-rhods-254-g3d48699
- **Branch**: rhoai-2.12
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: ModelMesh Serving is a Kubernetes controller that manages ModelMesh, a general-purpose model serving management and routing layer for machine learning models.

**Detailed**: ModelMesh Serving provides a comprehensive solution for deploying and managing ML model serving workloads at scale. The controller orchestrates the deployment of ModelMesh runtime pods, which intelligently route inference requests to multiple model servers (Triton, MLServer, OpenVINO, TorchServe) running within the cluster. It manages the lifecycle of Custom Resources including InferenceServices, Predictors, and ServingRuntimes, automatically creating the necessary Kubernetes deployments, services, and configurations. ModelMesh optimizes resource utilization by allowing multiple models to share the same serving runtime pods, with intelligent model placement and caching. The controller also manages storage integration for pulling models from S3, PVC, and other storage backends, and provides both gRPC and REST inference endpoints with automatic protocol translation.

The system includes a webhook server for validating ServingRuntime configurations, integration with Prometheus for metrics collection, and support for both cluster-scoped and namespace-scoped deployments. It coordinates with etcd for distributed state management and supports horizontal pod autoscaling for runtime deployments.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| modelmesh-controller | Kubernetes Operator | Manages lifecycle of ModelMesh serving resources (InferenceServices, Predictors, ServingRuntimes) |
| ModelMesh Runtime Pods | Deployment | Runtime containers hosting model servers (Triton, MLServer, OpenVINO, TorchServe) with ModelMesh routing layer |
| REST Proxy | Sidecar Container | Translates REST API requests to gRPC for ModelMesh communication |
| Webhook Server | Webhook | Validates ServingRuntime and ClusterServingRuntime resource configurations |
| Storage Puller | Init/Sidecar Container | Pulls models from storage backends (S3, PVC, etc.) before loading |
| Etcd | External Dependency | Distributed KV store for ModelMesh cluster coordination and model metadata |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Defines a model inference service with model location, runtime, and serving configuration |
| serving.kserve.io | v1alpha1 | Predictor | Namespaced | Internal representation of a deployed model predictor instance |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Defines model server runtime configuration (container image, resource limits, supported formats) |
| serving.kserve.io | v1alpha1 | ClusterServingRuntime | Cluster | Cluster-wide ServingRuntime template available to all namespaces |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics from controller |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | kube-rbac-proxy | Authenticated Prometheus metrics endpoint |
| /healthz | GET | 8081/TCP | HTTP | None | None | Controller liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Controller readiness probe |
| /validate-serving-modelmesh-io-v1alpha1-servingruntime | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server | Webhook validation for ServingRuntime/ClusterServingRuntime |
| /v2/models/{model}/infer | POST | 8008/TCP | HTTP | None | None | KServe V2 REST inference endpoint (via REST proxy) |
| /v2/models/{model}/ready | GET | 8008/TCP | HTTP | None | None | Model readiness check via REST |
| /metrics | GET | 2112/TCP | HTTP | None | None | Prometheus metrics from ModelMesh runtime pods |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| inference.GRPCInferenceService | 8033/TCP | gRPC | None | None | KServe V2 gRPC inference protocol for model predictions |
| ModelMesh Internal | 8080/TCP | gRPC | None | None | Internal ModelMesh cluster communication and coordination |
| Runtime Adapter | 8085-8090/TCP | gRPC | None | None | Communication with model server adapters (MLServer, Triton, etc.) |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| etcd | v3.x | Yes | Distributed KV store for ModelMesh cluster state and model metadata |
| Kubernetes | 1.23+ | Yes | Container orchestration platform |
| Prometheus Operator | v0.x | No | ServiceMonitor CRD for metrics scraping configuration |
| cert-manager | v1.x | No | TLS certificate provisioning for webhooks (alternative to manual certs) |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Model Storage (S3/PVC) | Storage API | Pull trained models from object storage or persistent volumes |
| Service Mesh (Istio) | Network Policies | Optional mTLS and traffic management for inference endpoints |
| Monitoring (Prometheus) | Metrics Scraping | Collect and store metrics from controller and runtime pods |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | https | HTTPS | TLS 1.2+ | kube-rbac-proxy | Internal |
| modelmesh-webhook-server-service | ClusterIP | 9443/TCP | webhook | HTTPS | TLS 1.2+ | Kubernetes API | Internal |
| modelmesh-serving (per runtime) | ClusterIP | 8033/TCP | 8033 | gRPC | None | None | Internal/External |
| modelmesh-serving (per runtime) | ClusterIP | 8008/TCP | 8008 | HTTP | None | None | Internal/External |
| modelmesh-serving (per runtime) | ClusterIP | 2112/TCP | 2112 | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| User-defined Route/Ingress | Route/Ingress | user-defined | 8008/TCP or 8033/TCP | HTTP/gRPC | Optional TLS | SIMPLE | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| S3 Object Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Access Keys | Pull model artifacts from S3-compatible storage |
| Etcd Service | 2379/TCP | gRPC | TLS 1.2+ (optional) | mTLS/Password | Connect to etcd for cluster coordination |
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch and manage Kubernetes resources |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| modelmesh-controller-role | "" | configmaps, secrets, services, endpoints, persistentvolumeclaims | get, list, watch, create, update, patch, delete |
| modelmesh-controller-role | "" | namespaces | get, list, watch, patch, update |
| modelmesh-controller-role | apps | deployments | get, list, watch, create, update, patch, delete |
| modelmesh-controller-role | serving.kserve.io | inferenceservices, predictors, servingruntimes, clusterservingruntimes | get, list, watch, create, update, patch, delete |
| modelmesh-controller-role | autoscaling | horizontalpodautoscalers | get, list, watch, create, update, delete |
| modelmesh-controller-role | monitoring.coreos.com | servicemonitors | get, list, watch, create, update, patch, delete |
| leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| auth-proxy-role | authentication.k8s.io | tokenreviews | create |
| auth-proxy-role | authorization.k8s.io | subjectaccessreviews | create |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| modelmesh-controller-rolebinding | system | modelmesh-controller-role (ClusterRole) | modelmesh-controller |
| leader-election-rolebinding | system | leader-election-role | modelmesh-controller |
| auth-proxy-rolebinding | system | auth-proxy-role | modelmesh-controller |
| restricted-scc-rolebinding | user-namespace | restricted-scc-role | modelmesh-serving-sa |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| model-serving-etcd | Opaque | Etcd connection credentials (URL, username, password) | Manual/Operator | No |
| storage-config | Opaque | S3 credentials and storage configuration for model pulling | User/Administrator | No |
| webhook-server-cert | kubernetes.io/tls | TLS certificate for webhook server | cert-manager/Manual | Yes (cert-manager) |
| modelmesh-serving-cert | kubernetes.io/tls | TLS certificate for mTLS between ModelMesh components (optional) | cert-manager/Manual | Yes (cert-manager) |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics (8443) | GET | Bearer Token (ServiceAccount) | kube-rbac-proxy | Requires get on endpoints resource |
| /validate-* (9443) | POST | mTLS client cert | Kubernetes API Server | Kubernetes admission control |
| /v2/models/*/infer (8008) | POST | None (default) | Application/Service Mesh | Optional Istio AuthorizationPolicy |
| inference.GRPCInferenceService (8033) | ALL | None (default) | Application/Service Mesh | Optional Istio AuthorizationPolicy |

### Network Policies

| Policy Name | Pod Selector | Ingress Rules | Egress Rules |
|-------------|--------------|---------------|--------------|
| modelmesh-controller | control-plane=modelmesh-controller | Allow 8443/TCP (metrics) | Allow all |
| modelmesh-runtimes | modelmesh-service exists | Allow 8033/TCP, 8008/TCP (inference), 8080/TCP (internal), 2112/TCP (metrics) from modelmesh pods | Allow all |
| modelmesh-webhook | control-plane=modelmesh-controller | Allow 9443/TCP (webhook) | Allow all |

## Data Flows

### Flow 1: Model Inference Request (gRPC)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client Application | modelmesh-serving Service | 8033/TCP | gRPC | None | None |
| 2 | modelmesh-serving Service | ModelMesh Pod | 8033/TCP | gRPC | None | None |
| 3 | ModelMesh Container | Model Server Container (MLServer/Triton) | 8001-8090/TCP | gRPC | None | None |

### Flow 2: Model Inference Request (REST)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client Application | modelmesh-serving Service | 8008/TCP | HTTP | None | None |
| 2 | modelmesh-serving Service | REST Proxy Container | 8008/TCP | HTTP | None | None |
| 3 | REST Proxy Container | ModelMesh Container | 8033/TCP | gRPC | None | None |
| 4 | ModelMesh Container | Model Server Container | 8001-8090/TCP | gRPC | None | None |

### Flow 3: Model Loading from S3

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Puller Init Container | S3 Object Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS Access Keys |
| 2 | Puller Init Container | Shared Volume (emptyDir) | N/A | Filesystem | None | None |
| 3 | Model Server Container | Shared Volume (emptyDir) | N/A | Filesystem | None | None |

### Flow 4: Controller Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | modelmesh-controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | modelmesh-controller | Etcd Service | 2379/TCP | gRPC | TLS 1.2+ (optional) | mTLS/Password |
| 3 | Kubernetes API Server | modelmesh-webhook-server | 9443/TCP | HTTPS | TLS 1.2+ | mTLS |

### Flow 5: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | controller-manager-metrics-service | 8443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Prometheus | modelmesh-serving ServiceMonitor | 2112/TCP | HTTP | None | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| KServe Inference Services | CRD API | N/A | N/A | N/A | Optional reconciliation of v1beta1 InferenceService resources |
| Etcd | gRPC Client | 2379/TCP | gRPC | TLS 1.2+ (optional) | Distributed state management for ModelMesh cluster |
| Prometheus Operator | ServiceMonitor CRD | N/A | N/A | N/A | Automatic metrics scraping configuration |
| cert-manager | Certificate CRD | N/A | N/A | N/A | Automatic TLS certificate provisioning for webhooks |
| S3/MinIO | S3 API | 443/TCP | HTTPS | TLS 1.2+ | Model artifact storage and retrieval |
| Istio Service Mesh | Istio APIs | N/A | N/A | N/A | Optional mTLS, traffic management, and authorization policies |

## Deployment Manifests

The component is deployed via Kustomize with manifests located in:
- **Base**: `config/default` - Core controller deployment
- **CRDs**: `config/crd` - Custom Resource Definitions
- **RBAC**: `config/rbac/cluster-scope` or `config/rbac/namespace-scope` - Role-based access control
- **Webhook**: `config/webhook` - ValidatingWebhookConfiguration
- **Runtimes**: `config/runtimes` - Default ServingRuntime definitions (MLServer, Triton, OpenVINO, TorchServe)
- **ODH Overlay**: `config/overlays/odh` - OpenDataHub/RHOAI-specific customizations

Key deployment configuration:
- Controller replicas: 1 (can be increased to 3 for HA)
- Leader election: Lease-based (15s duration, 10s renew deadline, 2s retry period)
- Resource requests: 50m CPU, 96Mi memory
- Resource limits: 1 CPU, 512Mi memory
- Deployment modes: Cluster-scoped (default) or namespace-scoped (via NAMESPACE_SCOPE=true)

## Recent Changes

| Date | Commit | Changes |
|------|--------|---------|
| 2024-05-24 | 3d48699 | Merge remote-tracking branch 'upstream/release-0.12.0-rc0' |
| 2024-05-23 | eef2c82 | Merge pull request #33 - Fix merge for 0.12.0-rc0 |
| 2024-05-21 | 5974d94 | Sync with upstream 0.12.0-rc0 |
| 2024-05-20 | 0946111 | Align Go lang version in Dockerfile.develop.ci |
| 2024-05-20 | 24d7d82 | Use latest tag to grab updates upon new build |
| 2024-05-09 | 6e2a877 | Replace image tags with branch placeholders |
| 2024-05-08 | 41ac594 | Modify Regular Expression for the support of suffix with characters |
| 2024-05-08 | 1ee1a00 | Add Create release Workflow |
| 2024-04-30 | 7eadf52 | Merge kserve sync 20240429 |
| 2024-04-27 | df25a60 | Merge remote-tracking branch 'upstream/release-0.11.1' |
| 2024-04-27 | eef8a2b | Increase etcd resources |
| 2024-04-27 | 2f01cad | Increase etcd resources |
| 2024-04-22 | 331a89d | Update golang.org/x/net dependency |

## Component Versions

Based on upstream KServe ModelMesh Serving v0.11.0 with RHOAI-specific patches:

| Component | Version | Repository |
|-----------|---------|------------|
| ModelMesh | v0.11.2 | https://github.com/kserve/modelmesh |
| ModelMesh Runtime Adapter | v0.11.2 | https://github.com/kserve/modelmesh-runtime-adapter |
| REST Proxy | v0.11.2 | https://github.com/kserve/rest-proxy |
| Supported Runtimes | - | Triton, MLServer, OpenVINO, TorchServe |

## Notes

- **Multi-Model Serving**: ModelMesh optimizes resource utilization by serving multiple models per pod with intelligent placement
- **Protocol Support**: Supports both KServe V2 gRPC (native) and REST (via translation proxy)
- **Storage Flexibility**: Pull models from S3, PVC, HTTP, or other storage backends via the unified puller
- **Scaling**: Supports horizontal pod autoscaling for runtime deployments based on CPU/memory metrics
- **High Availability**: Controller supports leader election with configurable lease or leader-for-life modes
- **Security**: Network policies restrict traffic between components; optional mTLS via Istio service mesh
- **Monitoring**: Prometheus metrics exposed from controller (8080/8443) and runtime pods (2112)
- **Deployment Modes**: Can operate in cluster-scoped (all namespaces) or namespace-scoped (single namespace) mode
