# Component: ModelMesh Serving

## Metadata
- **Repository**: https://github.com/red-hat-data-services/modelmesh-serving
- **Version**: v1.27.0-rhods-188 (based on upstream KServe v0.11.0)
- **Branch**: rhoai-2.9
- **Distribution**: RHOAI
- **Languages**: Go 1.19
- **Deployment Type**: Kubernetes Operator + Model Serving Runtime

## Purpose
**Short**: Controller for managing ModelMesh, a general-purpose model serving management and routing layer for multi-model inference workloads.

**Detailed**: ModelMesh Serving is a Kubernetes operator that manages the lifecycle of ModelMesh deployments, which provide efficient multi-model serving capabilities. It reconciles InferenceService and Predictor custom resources to deploy and manage machine learning models across various runtime engines (Triton, MLServer, OpenVINO, TorchServe). The controller dynamically creates model serving pods that include the ModelMesh orchestration layer, runtime adapters, REST/gRPC proxies, and model server containers. ModelMesh optimizes resource utilization by loading multiple models into shared serving pods and intelligently routing inference requests, making it ideal for environments with many small to medium-sized models. The system integrates with etcd for distributed model metadata storage and supports S3-compatible object storage for model artifacts.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| modelmesh-controller | Kubernetes Operator (Deployment) | Reconciles InferenceService, Predictor, ServingRuntime CRDs; manages ModelMesh runtime deployments |
| ModelMesh Runtime Pods | Multi-container Deployments | Serves ML models with ModelMesh orchestration, runtime adapters, and inference servers |
| Webhook Server | ValidatingWebhookConfiguration | Validates ServingRuntime and ClusterServingRuntime resources on CREATE/UPDATE |
| etcd | Key-Value Store | Stores model metadata, placement decisions, and cluster coordination data |
| REST Proxy | HTTP-to-gRPC Proxy | Translates KServe V2 REST API to gRPC for model inference |
| OAuth Proxy | Authentication Proxy | Provides OpenShift OAuth authentication for inference endpoints |
| Runtime Adapters | Container Sidecar | Intermediary between ModelMesh and model servers; handles model loading/unloading |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Defines a model deployment with predictor, transformer, and explainer components |
| serving.kserve.io | v1alpha1 | Predictor | Namespaced | Legacy CRD for defining model serving workloads with specific runtime requirements |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Defines namespace-scoped model server runtime configurations (Triton, MLServer, etc.) |
| serving.kserve.io | v1alpha1 | ClusterServingRuntime | Cluster | Defines cluster-wide model server runtime configurations available to all namespaces |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Controller liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Controller readiness probe |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth/mTLS | Controller Prometheus metrics (via oauth-proxy) |
| /v2/models/{model}/infer | POST | 8008/TCP | HTTP | None | Internal | KServe V2 REST inference endpoint (internal) |
| /v2/models/{model}/infer | POST | 8443/TCP | HTTPS | TLS 1.2+ | OAuth | KServe V2 REST inference endpoint (via oauth-proxy) |
| /oauth/healthz | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | OAuth proxy health check |
| /metrics | GET | 2112/TCP | HTTP | None | Internal | ModelMesh runtime Prometheus metrics |
| /ready | GET | 8089/TCP | HTTP | None | Internal | ModelMesh container readiness probe |
| /live | GET | 8089/TCP | HTTP | None | Internal | ModelMesh container liveness probe |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ModelMesh | 8033/TCP | gRPC | None | Internal | Model inference requests (KServe V2 gRPC protocol) |
| ModelMesh Internal | 8080/TCP | gRPC | None | Internal | Inter-pod ModelMesh communication for model placement and routing |
| Runtime Management | 8001/TCP | gRPC | None | Internal | Triton runtime management port for model loading/unloading |
| Runtime Adapter | 8085/TCP | gRPC | None | Internal | gRPC endpoint for runtime adapter communication |

### Webhook Endpoints

| Path | Port | Protocol | Encryption | Purpose |
|------|------|----------|------------|---------|
| /validate-serving-modelmesh-io-v1alpha1-servingruntime | 9443/TCP | HTTPS | TLS 1.2+ | Validates ServingRuntime and ClusterServingRuntime resources |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| etcd | v3.2.32+ | Yes | Distributed key-value store for model metadata and cluster coordination |
| S3-compatible Storage | N/A | Yes | Object storage for model artifacts (AWS S3, MinIO, IBM COS, etc.) |
| Prometheus Operator | v0.55.0 | No | Metrics collection via ServiceMonitor CRDs |
| cert-manager | Latest | No | TLS certificate provisioning for webhooks and services |
| Triton Inference Server | 2.x | No | NVIDIA inference runtime for TensorFlow, PyTorch, ONNX, TensorRT models |
| MLServer | 1.x | No | Seldon Python-based inference runtime |
| OpenVINO Model Server | 1.x | No | Intel OpenVINO inference runtime |
| TorchServe | 0.x | No | PyTorch native inference server |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| OpenShift OAuth | OAuth Proxy | User authentication for model inference endpoints |
| OpenShift Monitoring | ServiceMonitor | Metrics integration with cluster monitoring stack |
| RHOAI Dashboard | UI Integration | Model serving management and monitoring interface |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | https | HTTPS | TLS 1.2+ | OAuth | Internal |
| modelmesh-webhook-server-service | ClusterIP | 9443/TCP | webhook (9443) | HTTPS | TLS 1.2+ | mTLS | Internal |
| {service-name} (per InferenceService) | ClusterIP | 8033/TCP | 8033 | gRPC | None | Internal | Internal |
| {service-name} (per InferenceService) | ClusterIP | 8008/TCP | 8008 | HTTP | None | Internal | Internal |
| {service-name}-https (per InferenceService) | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | OAuth | Internal/External |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| Route (per InferenceService) | OpenShift Route | {model-name}-{namespace}.{cluster-domain} | 8443/TCP | HTTPS | TLS 1.2+ | Edge Termination | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| etcd Service | 2379/TCP | gRPC | None | None | Model metadata storage and retrieval |
| S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/S3 Keys | Model artifact download during loading |
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | CRD reconciliation and resource management |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| modelmesh-controller-role | "" | configmaps, secrets, services | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | "" | namespaces, endpoints, persistentvolumeclaims | get, list, watch |
| modelmesh-controller-role | apps | deployments | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | serving.kserve.io | inferenceservices, predictors, servingruntimes, clusterservingruntimes | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | serving.kserve.io | inferenceservices/status, predictors/status, servingruntimes/status, clusterservingruntimes/status | get, patch, update |
| modelmesh-controller-role | serving.kserve.io | inferenceservices/finalizers, predictors/finalizers, servingruntimes/finalizers, clusterservingruntimes/finalizers | get, patch, update |
| modelmesh-controller-role | autoscaling | horizontalpodautoscalers | create, delete, get, list, watch, update |
| modelmesh-controller-role | monitoring.coreos.com | servicemonitors | create, delete, get, list, patch, update, watch |
| inferenceservice-editor-role | serving.kserve.io | inferenceservices | create, delete, get, list, patch, update, watch |
| inferenceservice-viewer-role | serving.kserve.io | inferenceservices | get, list, watch |
| predictor-editor-role | serving.kserve.io | predictors | create, delete, get, list, patch, update, watch |
| predictor-viewer-role | serving.kserve.io | predictors | get, list, watch |
| servingruntime-editor-role | serving.kserve.io | servingruntimes | create, delete, get, list, patch, update, watch |
| servingruntime-viewer-role | serving.kserve.io | servingruntimes | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| modelmesh-controller-rolebinding (ClusterRoleBinding) | All | modelmesh-controller-role | modelmesh-controller |
| leader-election-rolebinding | Controller Namespace | leader-election-role | modelmesh-controller |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| model-serving-proxy-tls | kubernetes.io/tls | TLS certificate for OAuth proxy on runtime pods | cert-manager/Manual | No |
| modelmesh-webhook-server-cert | kubernetes.io/tls | TLS certificate for validating webhook server | cert-manager | Yes |
| storage-config | Opaque | S3 credentials and endpoint configuration for model storage | User/Admin | No |
| model-serving-etcd | Opaque | etcd connection credentials (if authentication enabled) | User/Admin | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics (Controller) | GET | OpenShift OAuth | OAuth Proxy | Users with services.get permission in namespace |
| /v2/models/*/infer (Runtime) | POST | OpenShift OAuth | OAuth Proxy | Users with services.get permission in namespace |
| Webhook Validation | POST | Kubernetes API Server mTLS | API Server | API server validates webhook server certificate |
| etcd | READ/WRITE | None (internal) | Network Policy | Only ModelMesh pods can access etcd service |

### Network Policies

| Policy Name | Pod Selector | Ingress Rules | Egress Rules |
|-------------|--------------|---------------|--------------|
| modelmesh-controller | control-plane=modelmesh-controller | Port 8443/TCP from any | Kubernetes API, etcd |
| modelmesh-runtimes | modelmesh-service exists | Ports 8033,8008,2112/TCP from any; 8033,8080/TCP from modelmesh pods | S3 storage, etcd |
| modelmesh-webhook | control-plane=modelmesh-controller | Port 9443/TCP from API server | Kubernetes API |

## Data Flows

### Flow 1: Model Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | Bearer Token (ServiceAccount/User) |
| 2 | Kubernetes API | modelmesh-controller | N/A | Watch | N/A | ServiceAccount Token |
| 3 | modelmesh-controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |
| 4 | modelmesh-controller | etcd | 2379/TCP | gRPC | None | None |
| 5 | Runtime Adapter (puller) | S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | S3 Credentials |
| 6 | Runtime Adapter | Model Server | 8001/TCP | gRPC | None | None |
| 7 | ModelMesh | etcd | 2379/TCP | gRPC | None | None |

### Flow 2: Model Inference (REST)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | OpenShift Router | 443/TCP | HTTPS | TLS 1.3 | None |
| 2 | OpenShift Router | OAuth Proxy | 8443/TCP | HTTPS | TLS 1.2+ | None |
| 3 | OAuth Proxy | OpenShift OAuth | 6443/TCP | HTTPS | TLS 1.3 | OAuth Token |
| 4 | OAuth Proxy | REST Proxy | 8008/TCP | HTTP | None | None |
| 5 | REST Proxy | ModelMesh | 8033/TCP | gRPC | None | None |
| 6 | ModelMesh | Model Server | 8001/TCP | gRPC | None | None |

### Flow 3: Model Inference (gRPC)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | InferenceService | 8033/TCP | gRPC | None | Internal |
| 2 | ModelMesh | Model Server | 8001/TCP | gRPC | None | None |

### Flow 4: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | Controller OAuth Proxy | 8443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | OAuth Proxy | Controller | Internal | HTTP | None | None |
| 3 | Prometheus | Runtime Pods | 2112/TCP | HTTP | None | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API Client | 6443/TCP | HTTPS | TLS 1.3 | CRD reconciliation, resource management |
| etcd | gRPC Client | 2379/TCP | gRPC | None | Model metadata storage, placement decisions |
| S3 Storage | HTTP Client | 443/TCP | HTTPS | TLS 1.2+ | Model artifact retrieval |
| Prometheus | Metrics Scrape Target | 2112,8443/TCP | HTTP/HTTPS | TLS 1.2+ (controller) | Performance and health metrics |
| OpenShift OAuth | OAuth 2.0 Client | 6443/TCP | HTTPS | TLS 1.3 | User authentication for inference endpoints |
| Model Server Runtimes | gRPC Client | 8001,8085/TCP | gRPC | None | Model loading, unloading, inference requests |

## Deployment Configuration

### Controller Deployment

- **Replicas**: 1 (can be increased to 3 for HA with leader election)
- **Image**: Based on registry.access.redhat.com/ubi8/ubi-minimal:8.7
- **Resources**:
  - Requests: 50m CPU, 96Mi memory
  - Limits: 1 CPU, 512Mi memory
- **Probes**:
  - Readiness: HTTP GET /readyz on port 8081
  - Liveness: HTTP GET /healthz on port 8081
- **Security Context**: Drop all capabilities
- **Service Account**: modelmesh-controller

### Runtime Deployment Template

- **Replicas**: 2 (configurable via podsPerRuntime)
- **Containers**:
  - **ModelMesh**: Model orchestration and routing layer
    - Resources: 300m-3 CPU, 448Mi memory
  - **Runtime Adapter**: Intermediary for model server communication
  - **Model Server**: Triton/MLServer/OpenVINO/TorchServe
    - Resources: 500m-5 CPU, 1Gi memory (example for Triton)
  - **REST Proxy**: HTTP-to-gRPC translation
    - Resources: 50m-1 CPU, 96Mi-512Mi memory
  - **OAuth Proxy**: Authentication proxy
    - Image: registry.redhat.io/openshift4/ose-oauth-proxy@sha256:4bef31...
    - Resources: 100m CPU, 256Mi memory
- **Termination Grace Period**: 90 seconds (allows model propagation)
- **Rolling Update Strategy**: 75% maxSurge, 15% maxUnavailable
- **Service Account**: modelmesh-serving-sa

### Built-in Runtime Types

- **Triton**: Multi-framework inference (TensorFlow, PyTorch, ONNX, TensorRT)
- **MLServer**: Python-based inference with scikit-learn, XGBoost support
- **OpenVINO**: Intel-optimized inference runtime
- **TorchServe**: PyTorch native model serving

## Recent Changes

| Date | Commit | Changes |
|------|--------|---------|
| 2026-03 | a87b2d2 | - Update UBI9 Go toolset to 1.25<br>- Dependency updates for base images |
| 2026-03 | 69216f0 | - Sync pipeline runs with konflux-central |
| 2026-03 | 5692e94 | - Update controller-gen to 0.17.0 |
| 2026-03 | d2afd1e | - Align envtest and Kubernetes version |
| 2026-03 | 4d979f3 | - CVE-2025-61729: Fix excessive resource consumption in crypto/x509<br>- Upgrade to Go 1.25.7 |
| 2026-02 | 1747623 | - Update to Go 1.25.7 for CVE fixes |
| 2026-02 | Multiple | - Regular dependency updates for UBI minimal base images |
| 2025-12 | Multiple | - Merge upstream stable-2.x branch changes |
| 2025-11 | Multiple | - CI improvements and test updates |

## Configuration

### ConfigMap: model-serving-config-defaults

Default configuration values:

- **podsPerRuntime**: 2 (number of runtime pods per ServingRuntime)
- **headlessService**: true (enables headless service for direct pod access)
- **modelMeshImage**: kserve/modelmesh:v0.11.1
- **restProxy.enabled**: true
- **restProxy.port**: 8008
- **metrics.enabled**: true
- **builtInServerTypes**: triton, mlserver, ovms, torchserve

### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| NAMESPACE | model-serving | Controller namespace |
| POD_NAME | (injected) | Controller pod name for leader election |
| ETCD_SECRET_NAME | model-serving-etcd | Secret containing etcd credentials |
| ENABLE_ISVC_WATCH | false | Enable InferenceService CRD reconciliation |
| ENABLE_CSR_WATCH | true | Enable ClusterServingRuntime CRD reconciliation |
| ENABLE_SECRET_WATCH | false | Enable Secret watching for storage config updates |
| NAMESPACE_SCOPE | false | Limit controller to single namespace |
| DEV_MODE_LOGGING | false | Enable development mode logging |

## Limitations and Constraints

1. **Model Size**: ModelMesh is optimized for small to medium models that fit in memory; large LLMs are better served by single-model deployments
2. **Storage Backend**: Requires S3-compatible object storage; local PVC storage not supported for multi-pod deployments
3. **Protocol Support**: Primary support for KServe V2 gRPC/REST; limited support for V1 protocol
4. **Runtime Compatibility**: Not all model formats are supported by all runtimes; compatibility matrix required
5. **etcd Dependency**: Single point of failure if etcd is not deployed in HA mode
6. **Network Policies**: May conflict with strict network policies that block inter-pod communication

## Troubleshooting

### Common Issues

1. **Models Fail to Load**
   - Check storage-config secret has valid S3 credentials
   - Verify model path is accessible from runtime pods
   - Review runtime adapter logs for download errors

2. **Inference Requests Timeout**
   - Verify ModelMesh can reach model server on port 8001
   - Check model is in "Loaded" state via Predictor status
   - Review etcd connectivity from ModelMesh pods

3. **Webhook Validation Failures**
   - Ensure modelmesh-webhook-server-cert secret exists
   - Verify webhook service is reachable from API server
   - Check certificate is valid and not expired

### Diagnostic Commands

```bash
# Check controller logs
kubectl logs -n modelmesh-serving deployment/modelmesh-controller

# Check runtime pod logs
kubectl logs -n <namespace> <pod-name> -c mm  # ModelMesh container
kubectl logs -n <namespace> <pod-name> -c triton  # Runtime container

# Check Predictor status
kubectl get predictor <name> -o yaml

# Test inference endpoint
curl -k https://<route>/v2/models/<model>/infer -d @request.json
```

## Additional Resources

- **Upstream Documentation**: https://github.com/kserve/modelmesh-serving
- **Runtime Adapters**: https://github.com/kserve/modelmesh-runtime-adapter
- **ModelMesh Core**: https://github.com/kserve/modelmesh
- **KServe V2 Protocol**: https://github.com/kserve/kserve/tree/master/docs/predict-api/v2
