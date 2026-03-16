# Component: ModelMesh Serving

## Metadata
- **Repository**: https://github.com/red-hat-data-services/modelmesh-serving
- **Version**: v1.27.0-rhods-267 (based on upstream KServe ModelMesh v0.11.0)
- **Branch**: rhoai-2.15
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Controller for managing ModelMesh, a high-performance model serving management and routing layer for ML model inference.

**Detailed**: ModelMesh Serving is a Kubernetes operator that manages the lifecycle of ModelMesh deployments, which provide intelligent model placement, routing, and multi-model serving capabilities. The controller reconciles Custom Resources (Predictors, InferenceServices, ServingRuntimes) and automatically deploys and manages model serving pods with runtime adapters that interface with various ML frameworks (Triton, MLServer, OpenVINO, TorchServe). It orchestrates model loading/unloading from object storage, manages etcd-backed metadata, and provides both gRPC and REST inference endpoints. ModelMesh enables efficient multi-model serving by packing multiple models into shared runtime pods, reducing resource overhead compared to single-model-per-pod architectures.

The controller supports both namespace-scoped and cluster-scoped serving runtimes, integrates with Prometheus for metrics, implements validation webhooks for runtime specifications, and manages network policies to secure inter-component communication. It dynamically creates Deployments for each ServingRuntime containing ModelMesh containers, runtime-specific model server containers, and storage helper containers.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| modelmesh-controller | Deployment | Main operator that reconciles CRDs and manages ModelMesh infrastructure |
| ModelMesh Runtime Pods | Deployment | Per-runtime pods containing ModelMesh, runtime adapter, model server, and optional REST proxy |
| etcd | External Dependency | Distributed key-value store for model metadata and routing information |
| Validation Webhook | Webhook Server | Validates ServingRuntime and ClusterServingRuntime specifications |
| Metrics Service | Service | Exposes Prometheus metrics for monitoring |
| Storage Helper | Init/Sidecar Container | Pulls models from object storage (S3, PVC, etc.) |
| REST Proxy | Sidecar Container | Translates REST API to gRPC for inference requests |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | KServe-compatible inference service definition (watched by controller) |
| serving.kserve.io | v1alpha1 | Predictor | Namespaced | Defines a model to be served with storage location and runtime |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Defines a namespace-scoped model serving runtime configuration |
| serving.kserve.io | v1alpha1 | ClusterServingRuntime | Cluster | Defines a cluster-wide model serving runtime configuration |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics from controller |
| /healthz | GET | 8081/TCP | HTTP | None | None | Controller liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Controller readiness probe |
| /metrics | GET | 8443/TCP | HTTPS | TLS | Token | Kube RBAC proxy protected metrics |
| /v2/models/{model}/infer | POST | 8008/TCP | HTTP | TLS (optional) | None | KServe V2 REST inference endpoint (via REST proxy) |
| /v2/models/{model}/ready | GET | 8008/TCP | HTTP | TLS (optional) | None | Model readiness check via REST |
| /metrics | GET | 2112/TCP | HTTP | None | None | ModelMesh runtime metrics |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| inference.GRPCInferenceService | 8033/TCP | gRPC | mTLS (optional) | None | KServe V2 gRPC inference protocol (default port) |
| ModelMesh Management | 8085/TCP | gRPC | None | None | Internal ModelMesh control plane for model management |
| Runtime Management | 8001/TCP | gRPC | None | None | Communication between adapter and runtime (Triton, etc.) |
| Validation Webhook | 9443/TCP | HTTPS | TLS | K8s API Server | Validates ServingRuntime/ClusterServingRuntime CREATE/UPDATE |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| etcd | v3.2+ | Yes | Stores model metadata, routing tables, and cluster coordination |
| Object Storage (S3/MinIO/etc) | N/A | Yes | Stores trained model artifacts to be loaded into runtimes |
| cert-manager | v1.0+ | No | Generates TLS certificates for webhooks (alternative: manual certs) |
| Prometheus Operator | v0.50+ | No | Enables ServiceMonitor for automated metrics scraping |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Service Mesh (Istio) | Network Policy | Optional mTLS for inference traffic and service discovery |
| Monitoring Stack | Metrics API | Sends metrics via ServiceMonitor for observability |
| Model Registry | Storage Reference | Models may be registered in ODH model registry before serving |

## Runtime Dependencies (Model Servers)

| Runtime | Image | Protocol | Supported Formats | Purpose |
|---------|-------|----------|-------------------|---------|
| Triton Inference Server | tritonserver-2:latest | gRPC-V2 | TensorFlow, PyTorch, ONNX, TensorRT, Keras | NVIDIA's multi-framework inference server |
| MLServer | mlserver-1:latest | gRPC-V2, REST | SKLearn, XGBoost, LightGBM, MLflow | Seldon's Python-based inference server |
| OpenVINO Model Server | ovms-1:latest | gRPC-V2 | OpenVINO IR, ONNX, TensorFlow | Intel's optimized inference for CPUs |
| TorchServe | torchserve-0:latest | gRPC-V2 | PyTorch, TorchScript | PyTorch native serving framework |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | https | HTTPS | TLS | Token Auth | Internal |
| modelmesh-webhook-server-service | ClusterIP | 9443/TCP | webhook | HTTPS | TLS | K8s API Server | Internal |
| modelmesh-serving | ClusterIP or Headless | 8033/TCP | 8033 | gRPC | mTLS (optional) | None | Internal |
| modelmesh-serving | ClusterIP or Headless | 8008/TCP | 8008 | HTTP/HTTPS | TLS (optional) | None | Internal |
| etcd | ClusterIP | 2379/TCP | 2379 | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| N/A | N/A | N/A | N/A | N/A | N/A | N/A | Services are internal; ingress configured via Service Mesh or external Ingress |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| etcd | 2379/TCP | HTTP/HTTPS | TLS (optional) | Client cert (optional) | Read/write model metadata and routing info |
| S3/MinIO | 443/TCP or 9000/TCP | HTTPS/HTTP | TLS (configurable) | AWS SigV4 or Access Keys | Pull model artifacts from object storage |
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch CRDs, create/update Deployments and Services |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| modelmesh-controller-role | serving.kserve.io | inferenceservices, predictors, servingruntimes, clusterservingruntimes | get, list, watch, create, update, patch, delete |
| modelmesh-controller-role | serving.kserve.io | inferenceservices/finalizers, predictors/finalizers, servingruntimes/finalizers, clusterservingruntimes/finalizers | get, patch, update |
| modelmesh-controller-role | serving.kserve.io | inferenceservices/status, predictors/status, servingruntimes/status, clusterservingruntimes/status | get, patch, update |
| modelmesh-controller-role | "" | configmaps, secrets, services | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | "" | namespaces, endpoints, persistentvolumeclaims | get, list, watch |
| modelmesh-controller-role | apps | deployments | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | monitoring.coreos.com | servicemonitors | create, delete, get, list, patch, update, watch |
| modelmesh-controller-role | autoscaling | horizontalpodautoscalers | get, list, watch, create, delete, update |
| leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| auth-proxy-role | authentication.k8s.io | tokenreviews | create |
| auth-proxy-role | authorization.k8s.io | subjectaccessreviews | create |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| modelmesh-controller-rolebinding | All namespaces | modelmesh-controller-role (ClusterRole) | modelmesh-controller |
| leader-election-rolebinding | Controller namespace | leader-election-role | modelmesh-controller |
| proxy-rolebinding | Controller namespace | auth-proxy-role | modelmesh-controller |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| model-serving-etcd | Opaque | etcd connection configuration (endpoints, root prefix, TLS certs) | Admin/Operator | No |
| storage-config | Opaque | Object storage credentials (S3 keys, endpoints, buckets) | User/Admin | No |
| webhook-server-cert | kubernetes.io/tls | TLS certificate for validation webhook server | cert-manager or manual | Yes (cert-manager) |
| modelmesh-serving-tls | kubernetes.io/tls | Optional TLS certificate for inference endpoints | cert-manager or manual | Yes (cert-manager) |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics (8443) | GET | Bearer Token (ServiceAccount) | kube-rbac-proxy | Requires tokenreviews/subjectaccessreviews RBAC |
| Validation Webhook (9443) | POST | mTLS Client Certificate | Kubernetes API Server | API server validates webhook server cert |
| Inference gRPC (8033) | POST | None (default), mTLS (optional) | Service Mesh (optional) | Configured via PeerAuthentication/AuthorizationPolicy |
| Inference REST (8008) | POST | None (default), Token (optional) | Application/Service Mesh | Custom auth can be added via Istio policies |

### Network Policies

| Policy Name | Pod Selector | Ingress Rules | Egress Rules |
|-------------|--------------|---------------|--------------|
| modelmesh-controller | control-plane=modelmesh-controller | Allow 8443/TCP (metrics) | Implicit (all) |
| modelmesh-runtimes | modelmesh-service=modelmesh-serving | Allow 8033/TCP, 8008/TCP, 2112/TCP | Implicit (all) |
| modelmesh-webhook | control-plane=modelmesh-controller | Allow 9443/TCP | Implicit (all) |

## Data Flows

### Flow 1: Model Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/System | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Kubernetes API | Controller Webhook | 9443/TCP | HTTPS | TLS | mTLS |
| 3 | Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Controller | etcd | 2379/TCP | HTTP/HTTPS | TLS (optional) | Client Cert (optional) |

### Flow 2: Model Loading

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Storage Helper | S3/MinIO | 443/TCP or 9000/TCP | HTTPS/HTTP | TLS (configurable) | AWS SigV4 or Keys |
| 2 | Runtime Adapter | Model Server | 8001/TCP | gRPC | None | None |
| 3 | Runtime Adapter | ModelMesh | 8085/TCP | gRPC | None | None |
| 4 | ModelMesh | etcd | 2379/TCP | HTTP/HTTPS | TLS (optional) | Client Cert (optional) |

### Flow 3: Inference Request

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | ModelMesh Service | 8033/TCP or 8008/TCP | gRPC or HTTP | mTLS/TLS (optional) | None (default) |
| 2 | REST Proxy (if REST) | ModelMesh | 8033/TCP | gRPC | None | None |
| 3 | ModelMesh | Runtime Adapter | 8085/TCP | gRPC | None | None |
| 4 | Runtime Adapter | Model Server | 8001/TCP | gRPC | None | None |

### Flow 4: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | Controller Metrics | 8443/TCP | HTTPS | TLS | ServiceAccount Token |
| 2 | Prometheus | ModelMesh Metrics | 2112/TCP | HTTP | None | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Watch/manage CRDs, Deployments, Services, ConfigMaps |
| etcd | Client API | 2379/TCP | HTTP/HTTPS | TLS (optional) | Store model routing metadata and cluster state |
| Object Storage (S3) | S3 API | 443/TCP | HTTPS | TLS | Retrieve model artifacts for loading |
| Prometheus | Metrics Scrape | 8443/TCP, 2112/TCP | HTTP/HTTPS | TLS (8443) | Export operational metrics |
| Service Mesh (Istio) | Envoy Sidecar | N/A | N/A | mTLS | Optional traffic encryption and authorization |
| cert-manager | Certificate API | 6443/TCP | HTTPS | TLS 1.2+ | Automated certificate provisioning for webhooks |

## Configuration

### ConfigMap: model-serving-config-defaults

| Key | Default Value | Purpose |
|-----|---------------|---------|
| podsPerRuntime | 2 | Number of replicas for each ServingRuntime deployment |
| headlessService | true | Use headless service for direct pod addressing |
| modelMeshImage.name | kserve/modelmesh | ModelMesh container image |
| modelMeshImage.tag | latest | ModelMesh image tag |
| restProxy.enabled | true | Enable REST proxy sidecar |
| restProxy.port | 8008 | REST proxy listening port |
| storageHelperImage.name | kserve/modelmesh-runtime-adapter | Storage puller/adapter image |
| serviceAccountName | modelmesh-serving-sa | ServiceAccount for runtime pods |
| builtInServerTypes | triton, mlserver, ovms, torchserve | Enabled runtime adapters |

### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| NAMESPACE | (detected) | Namespace where controller is running |
| POD_NAME | (required) | Controller pod name for leader election |
| ETCD_SECRET_NAME | model-serving-etcd | Name of etcd connection secret |
| ENABLE_ISVC_WATCH | false | Watch InferenceService CRs (KServe compatibility) |
| ENABLE_CSR_WATCH | true | Watch ClusterServingRuntime CRs |
| ENABLE_SECRET_WATCH | false | Watch Secret changes for auto-reload |
| NAMESPACE_SCOPE | false | Limit controller to single namespace (vs cluster-wide) |
| DEV_MODE_LOGGING | false | Enable verbose development logging |

## Deployment Architecture

### Controller Deployment

```
modelmesh-controller (Deployment)
├── replicas: 1 (can be scaled to 3+ for HA with leader election)
├── container: manager
│   ├── image: odh-modelmesh-serving-controller-rhel8
│   ├── resources: 50m CPU / 96Mi RAM (request), 1 CPU / 512Mi RAM (limit)
│   ├── probes: liveness (8081/healthz), readiness (8081/readyz)
│   └── volumeMounts: config-defaults ConfigMap
├── serviceAccount: modelmesh-controller
└── affinity: pod anti-affinity (spread across zones)
```

### Runtime Deployment (per ServingRuntime)

```
modelmesh-serving-<runtime> (Deployment)
├── replicas: 2 (configurable via podsPerRuntime)
├── initContainer: storage-initializer (optional)
│   ├── image: modelmesh-runtime-adapter (puller mode)
│   └── purpose: Pre-load models from storage
├── container: modelmesh
│   ├── image: kserve/modelmesh
│   ├── resources: 300m CPU / 448Mi RAM (request), 3 CPU / 448Mi RAM (limit)
│   └── env: etcd config, grpc settings, metrics config
├── container: runtime-adapter
│   ├── image: modelmesh-runtime-adapter
│   └── purpose: Translate ModelMesh gRPC to runtime-specific API
├── container: <runtime-server> (triton/mlserver/ovms/torchserve)
│   ├── image: runtime-specific (e.g., tritonserver-2)
│   ├── resources: 500m CPU / 1Gi RAM (request), 5 CPU / 1Gi RAM (limit)
│   └── ports: 8001 (management), 8000 (HTTP health)
├── container: rest-proxy (optional)
│   ├── image: kserve/rest-proxy
│   ├── resources: 50m CPU / 96Mi RAM (request), 1 CPU / 512Mi RAM (limit)
│   └── purpose: Expose KServe V2 REST API (translates to gRPC)
└── serviceAccount: modelmesh-serving-sa
```

## Build Process

Built using Konflux CI/CD pipeline:
- Base: UBI9 Go Toolset for build, UBI8 Minimal for runtime
- Go version: 1.21
- Build: Multi-stage Dockerfile.konflux
  - Stage 1: Compile Go binary from source
  - Stage 2: Minimal runtime image with binary only
- Output: `odh-modelmesh-serving-controller-rhel8` container
- Labels: Component metadata for RHOAI ecosystem

## Recent Changes

Recent development focuses on RHOAI 2.15 stabilization and upstream KServe compatibility. This branch tracks `rhoai-2.15` and is based on upstream KServe ModelMesh v0.11.0 with Red Hat specific patches.

Key capabilities in this version:
- Multi-model serving with intelligent placement
- Support for 4 built-in runtimes (Triton, MLServer, OVMS, TorchServe)
- Custom ServingRuntime extensibility
- Automatic storage pulling from S3/PVC
- Optional REST proxy for HTTP inference
- Prometheus metrics integration
- Validation webhooks for runtime specs
- Leader election for HA controller deployments
- Network policies for pod isolation
- OpenShift Security Context Constraints (SCC) support

## Operational Considerations

### High Availability
- Controller supports replica scaling (set replicas > 1)
- Leader election prevents split-brain (lease-based or leader-for-life)
- Runtime pods can scale via `podsPerRuntime` configuration
- etcd should be deployed with clustering for production

### Monitoring
- Controller metrics: /metrics on port 8080 (internal) and 8443 (RBAC-protected)
- ModelMesh metrics: /metrics on port 2112
- ServiceMonitor CR enables auto-discovery by Prometheus Operator
- Key metrics: model load time, inference latency, memory usage, model count

### Storage
- Models must be accessible via S3-compatible API or PVC
- etcd stores model metadata (small, frequent writes)
- No persistent storage required for controller
- Runtime pods use ephemeral storage for model cache

### Scaling Considerations
- Each ServingRuntime creates separate Deployment
- Models are packed into runtime pods (multi-tenancy)
- Horizontal scaling via `podsPerRuntime`
- Vertical scaling via runtime container resource limits
- Scale-to-zero support available via configuration

### Troubleshooting
- Check controller logs: `kubectl logs -n <namespace> deployment/modelmesh-controller`
- Check runtime logs: `kubectl logs -n <namespace> <pod> -c modelmesh`
- Verify etcd connectivity: Check `model-serving-etcd` secret and service
- Validate storage: Check `storage-config` secret and object storage access
- Check CRD status: `kubectl get predictor,servingruntime -A`
- Webhook validation errors: Check ValidatingWebhookConfiguration and cert validity
