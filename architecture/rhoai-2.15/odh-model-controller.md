# Component: ODH Model Controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/odh-model-controller.git
- **Version**: v1.27.0-rhods-478-g099ff49
- **Branch**: rhoai-2.15
- **Distribution**: RHOAI
- **Languages**: Go 1.21
- **Deployment Type**: Kubernetes Operator (Controller)

## Purpose
**Short**: Extends KServe functionality with OpenShift-specific integrations for model serving infrastructure.

**Detailed**:
The ODH Model Controller is a Kubernetes operator that watches KServe InferenceService custom resources and automatically configures OpenShift-specific infrastructure components required for production model serving. It eliminates manual configuration steps by orchestrating the deployment of OpenShift Routes for external access, Istio service mesh components for traffic management and security, Prometheus monitoring resources for observability, and Authorino authentication policies.

The controller supports multiple deployment modes including KServe Serverless (with Knative), KServe Raw (direct Kubernetes deployments), and ModelMesh (for multi-model serving). It manages a set of pre-configured serving runtime templates for popular inference frameworks including vLLM, TGIS, Caikit, and OpenVINO Model Server. By automating the integration between KServe and OpenShift platform services, it enables data scientists to deploy models without needing deep knowledge of service mesh, networking, or monitoring configuration.

The controller also provides a validating webhook for Knative Services to ensure proper configuration in service mesh environments, and reconciles storage secrets and custom CA certificates used by inference services for accessing model artifacts.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| odh-model-controller | Deployment | Main controller manager pod that reconciles InferenceService resources |
| OpenshiftInferenceServiceReconciler | Controller | Primary reconciler that orchestrates different deployment modes (ModelMesh, KServe Serverless, KServe Raw) |
| StorageSecretReconciler | Controller | Manages storage credentials for accessing model artifacts from S3, PVC, etc. |
| KServeCustomCACertReconciler | Controller | Manages custom CA certificate bundles for secure communication |
| MonitoringReconciler | Controller | Creates ServiceMonitor and PodMonitor resources for Prometheus integration |
| ModelRegistryInferenceServiceReconciler | Controller | Integrates InferenceServices with ODH Model Registry for model lineage tracking |
| Knative Service Validator | Webhook | Validates Knative Service configurations for service mesh compatibility |
| Serving Runtime Templates | ConfigMap Templates | Pre-configured runtime definitions for vLLM, TGIS, Caikit, OVMS inference engines |

## APIs Exposed

### Custom Resource Definitions (CRDs)

The controller watches but does not define these CRDs (they are owned by external components):

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Primary resource watched - defines model serving deployments |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Defines inference runtime configurations (created/managed by controller) |
| authorino.kuadrant.io | v1beta2 | AuthConfig | Namespaced | Authentication policies for inference endpoints (created by controller) |
| datasciencecluster.opendatahub.io | v1 | DataScienceCluster | Cluster | ODH platform configuration (read-only) |
| dscinitialization.opendatahub.io | v1 | DSCInitialization | Cluster | ODH initialization settings (read-only) |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | Bearer Token | Prometheus metrics endpoint for controller metrics |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /validate-serving-knative-dev-v1-service | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Validating webhook for Knative Service resources |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| KServe | v0.12.1 | Yes | Provides InferenceService and ServingRuntime CRDs for model serving |
| Knative Serving | v0.39.3 | Conditional | Required for KServe Serverless deployment mode |
| Istio Service Mesh | v1.19.4 | Conditional | Service mesh for traffic management, mTLS, and observability |
| Authorino | v0.15.0 | Conditional | Authentication/authorization for inference endpoints |
| Prometheus Operator | v0.64.1 | No | Enables ServiceMonitor/PodMonitor for metrics collection |
| OpenShift Route API | v3.9.0+ | Yes | External access to inference services on OpenShift |
| Red Hat Service Mesh (Maistra) | N/A | Conditional | OpenShift service mesh implementation |
| controller-runtime | v0.16.3 | Yes | Kubernetes controller framework |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KServe Controller | Watches CRDs | Primary component being extended - manages core InferenceService lifecycle |
| ODH Dashboard | ConfigMap Labels | Serving runtime templates labeled for dashboard discovery |
| Model Registry | API/CRD | Optional integration for model versioning and lineage tracking |
| ODH Operator | CRD Watch | Reads DataScienceCluster and DSCInitialization for platform configuration |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-model-controller-metrics-service | ClusterIP | 8080/TCP | 8080 | HTTP | None | Bearer Token | Internal (Prometheus) |
| odh-model-controller-webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | K8s API Server cert | Internal (K8s API Server) |

### Ingress

The controller itself does not have ingress but creates ingress for InferenceServices:

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {isvc-name} Route | OpenShift Route | {isvc-name}-{namespace}.{cluster-domain} | 443/TCP | HTTPS | TLS 1.2+ | Edge | External |
| {isvc-name} VirtualService | Istio VirtualService | {isvc-name}.{namespace}.svc.cluster.local | 80/TCP, 443/TCP | HTTP/HTTPS | TLS 1.2+ (mTLS) | MUTUAL | Internal (Service Mesh) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Read/write K8s resources (InferenceServices, Routes, etc.) |
| Prometheus (optional) | 9090/TCP | HTTP | None | Bearer Token | Metrics federation (if monitoring enabled) |

### Network Policies

| Name | Ingress Rules | Egress Rules | Purpose |
|------|---------------|--------------|---------|
| odh-model-controller | Allow 9443/TCP to pods with label app=odh-model-controller | Not specified (default allow) | Restrict webhook traffic to authorized sources |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-model-controller-role | serving.kserve.io | inferenceservices, inferenceservices/finalizers | get, list, watch, update |
| odh-model-controller-role | serving.kserve.io | servingruntimes, servingruntimes/finalizers | get, list, watch, create, update, delete, patch |
| odh-model-controller-role | networking.istio.io | virtualservices, virtualservices/finalizers | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | networking.istio.io | gateways | get, list, watch, update, patch |
| odh-model-controller-role | security.istio.io | peerauthentications | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | security.istio.io | authorizationpolicies | get, list |
| odh-model-controller-role | telemetry.istio.io | telemetries | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | maistra.io | servicemeshmembers | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | maistra.io | servicemeshmemberrolls, servicemeshcontrolplanes | get, list, watch, use |
| odh-model-controller-role | route.openshift.io | routes, routes/custom-host | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | networking.k8s.io | networkpolicies | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | networking.k8s.io, extensions | ingresses | get, list, watch |
| odh-model-controller-role | monitoring.coreos.com | servicemonitors, podmonitors | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | authorino.kuadrant.io | authconfigs | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | rbac.authorization.k8s.io | clusterrolebindings, rolebindings | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | "" (core) | services | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | "" (core) | secrets, configmaps, serviceaccounts | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | "" (core) | namespaces, pods, endpoints | get, list, watch, create, update, patch |
| odh-model-controller-role | datasciencecluster.opendatahub.io | datascienceclusters | get, list, watch |
| odh-model-controller-role | dscinitialization.opendatahub.io | dscinitializations | get, list, watch |
| odh-model-controller-leader-election-role | "" (core) | configmaps | get, list, watch, create, update, patch, delete |
| odh-model-controller-leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| odh-model-controller-leader-election-role | "" (core) | events | create, patch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-model-controller-rolebinding | Cluster-wide | odh-model-controller-role | odh-model-controller (per deployment namespace) |
| odh-model-controller-leader-election-rolebinding | Controller namespace | odh-model-controller-leader-election-role | odh-model-controller |
| odh-model-controller-metrics-binding | Controller namespace | odh-model-controller-metrics-reader | odh-model-controller |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| odh-model-controller-webhook-cert | kubernetes.io/tls | TLS certificate for validating webhook | service.beta.openshift.io/serving-cert-secret-name annotation | Yes (OpenShift service CA) |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | Bearer Token (ServiceAccount) | Kubernetes RBAC | Requires metrics-reader role binding |
| /validate-serving-knative-dev-v1-service | POST | mTLS + K8s API Server | Kubernetes API Server | Validated by K8s admission control |
| /healthz, /readyz | GET | None | N/A | Public within cluster (health checks) |

## Data Flows

### Flow 1: InferenceService Reconciliation (KServe Serverless)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Kubernetes API | odh-model-controller | Internal | K8s Watch | N/A | ServiceAccount Token |
| 3 | odh-model-controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | odh-model-controller | Kubernetes API (create Route) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | odh-model-controller | Kubernetes API (create VirtualService) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 6 | odh-model-controller | Kubernetes API (create PeerAuthentication) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 7 | odh-model-controller | Kubernetes API (create ServiceMonitor) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 8 | odh-model-controller | Kubernetes API (create AuthConfig) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: Monitoring Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | odh-model-controller-metrics-service | 8080/TCP | HTTP | None | Bearer Token |
| 2 | odh-model-controller | Prometheus metrics endpoint | 8080/TCP | HTTP | None | Bearer Token |

### Flow 3: Knative Service Validation (Webhook)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Kubernetes API Server | odh-model-controller-webhook-service | 443/TCP | HTTPS | TLS 1.2+ | mTLS (API Server client cert) |
| 2 | odh-model-controller webhook | Validation logic | Internal | N/A | N/A | N/A |
| 3 | odh-model-controller webhook | Kubernetes API Server (response) | 443/TCP | HTTPS | TLS 1.2+ | mTLS |

### Flow 4: Serving Runtime Template Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | odh-model-controller | Kubernetes API (create ServingRuntime) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | KServe Controller | Knative Service creation | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | odh-model-controller webhook | Validate Knative Service | 443/TCP | HTTPS | TLS 1.2+ | mTLS |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | CRUD operations on all managed resources |
| KServe Controller | Shared CRD Watch | 6443/TCP | HTTPS | TLS 1.2+ | Co-manages InferenceService resources |
| Istio Control Plane | CRD Management | 6443/TCP | HTTPS | TLS 1.2+ | Creates VirtualServices, PeerAuthentications, Telemetries |
| Authorino | CRD Management | 6443/TCP | HTTPS | TLS 1.2+ | Creates AuthConfig resources for inference endpoint auth |
| Prometheus | ServiceMonitor | 8080/TCP | HTTP | None | Scrapes controller metrics |
| OpenShift Router | Route Creation | 6443/TCP | HTTPS | TLS 1.2+ | Creates Routes for external inference access |
| Service Mesh Operator | ServiceMeshMember | 6443/TCP | HTTPS | TLS 1.2+ | Manages service mesh membership for inference namespaces |
| Model Registry | gRPC API (optional) | 9090/TCP | gRPC | mTLS | Associates InferenceServices with registered models |

## Serving Runtime Templates

The controller manages pre-configured serving runtime templates for deployment:

| Runtime | Protocol | Model Format | GPU Support | Use Case |
|---------|----------|--------------|-------------|----------|
| vLLM | REST (OpenAI-compatible) | vLLM | Required (nvidia.com/gpu) | High-throughput LLM inference |
| TGIS | gRPC | Flan-T5, Llama, etc. | Required | Text generation with IBM TGIS |
| Caikit-TGIS | gRPC | Caikit text generation | Required | Caikit framework with TGIS backend |
| Caikit Standalone | gRPC | Caikit models | Optional | General Caikit model serving |
| OVMS (ModelMesh) | gRPC | ONNX, OpenVINO, TensorFlow | Optional | Multi-model serving with ModelMesh |
| OVMS (KServe) | gRPC/REST | ONNX, OpenVINO, TensorFlow | Optional | Single model serving with KServe |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| v1.27.0-rhods-478-g099ff49 | 2024-10-25 | - Update vLLM image reference<br>- Update OVMS runtime reference<br>- Update Caikit-TGIS and TGIS images |
| v1.27.0-rhods-475-g1756fa9 | 2024-10-22 | - Merge PR #153: Update OVMS runtime SHA<br>- Update vLLM image SHA |
| v1.27.0-rhods-472-g342f513 | 2024-10-21 | - Merge PR #149: Update 2.15 Caikit images |
| v1.27.0-rhods-470-gb71a61f | 2024-10-17 | - Merge upstream main into rhoai-2.15<br>- Add Renovate.json config for dependency management<br>- Merge PR #143: Konflux 2.16 support |
| v1.27.0-rhods-467-g2877f7f | 2024-10-15 | - Review Dockerfile for Konflux builds<br>- Update Caikit-TGIS and TGIS images |
| v1.27.0-rhods-465-g9a523a8 | 2024-10-11 | - Update vLLM image<br>- Auto-merge nudging PRs for vLLM-CUDA |
| v1.27.0-rhods-462-gd0b6eb0 | 2024-10-09 | - Review Dockerfile for Konflux build optimization |

## Deployment Configuration

### Container Build

- **Build System**: Konflux (Red Hat's cloud-native CI/CD)
- **Base Images**:
  - Builder: `registry.redhat.io/ubi8/go-toolset` (SHA-pinned)
  - Runtime: `registry.redhat.io/ubi8/ubi-minimal` (SHA-pinned)
- **Build File**: `Dockerfile.konflux` (primary), `Containerfile` (legacy)
- **Binary**: Single Go binary `/manager`
- **User**: Non-root (UID 2000)

### Runtime Configuration

- **Replicas**: 1 (with leader election)
- **Anti-Affinity**: Preferred pod anti-affinity on hostname topology
- **Resource Limits**: CPU 500m, Memory 2Gi
- **Resource Requests**: CPU 10m, Memory 64Mi
- **Probes**:
  - Liveness: HTTP GET /healthz:8081 (15s initial delay, 20s period)
  - Readiness: HTTP GET /readyz:8081 (5s initial delay, 10s period)
- **Environment Variables**:
  - `POD_NAMESPACE`: Controller's namespace
  - `AUTH_AUDIENCE`: Authorino audience (optional, from configmap)
  - `AUTHORINO_LABEL`: Authorino instance label (optional, from configmap)
  - `CONTROL_PLANE_NAME`: Service mesh control plane name (optional, from configmap)
  - `MESH_NAMESPACE`: Service mesh namespace (optional, from configmap)
  - `MESH_DISABLED`: Disable service mesh integration (optional, boolean)
- **Command-line Flags**:
  - `--leader-elect`: Enable leader election (default in deployment)
  - `--metrics-bind-address`: Metrics server address (default :8080)
  - `--health-probe-bind-address`: Health probe address (default :8081)
  - `--monitoring-namespace`: Prometheus namespace (optional)
  - `--model-registry-inference-reconcile`: Enable model registry integration (optional, boolean)

### Volume Mounts

| Path | Source | Purpose |
|------|--------|---------|
| /tmp/k8s-webhook-server/serving-certs | Secret: odh-model-controller-webhook-cert | TLS certificates for webhook server |

## Controller Reconciliation Logic

### Deployment Mode Detection

The controller determines the InferenceService deployment mode and applies appropriate reconciliation:

1. **ModelMesh Mode**: Multi-model serving with ModelMesh runtime
   - Creates Routes for external access
   - Manages ServiceAccounts and ClusterRoleBindings
   - No service mesh integration (ModelMesh handles internal routing)

2. **KServe Serverless Mode**: Knative-based autoscaling deployment
   - Creates Routes, VirtualServices, Gateways
   - Manages PeerAuthentications for mTLS
   - Creates ServiceMonitors and PodMonitors for Prometheus
   - Configures Authorino AuthConfigs for authentication
   - Manages ServiceMeshMember resources
   - Creates NetworkPolicies for traffic control
   - Validates Knative Services via webhook

3. **KServe Raw Mode**: Direct Kubernetes deployment without Knative
   - Minimal reconciliation (primarily Route creation)
   - No service mesh or advanced networking features

### Reconciler Components

| Reconciler | Deployment Mode | Resources Created |
|------------|-----------------|-------------------|
| ModelMeshInferenceServiceReconciler | ModelMesh | Routes, ServiceAccounts, ClusterRoleBindings |
| KServeServerlessInferenceServiceReconciler | KServe Serverless | Routes, VirtualServices, PeerAuthentications, ServiceMonitors, AuthConfigs, NetworkPolicies, ServiceMeshMembers, Telemetries |
| KServeRawInferenceServiceReconciler | KServe Raw | Routes (minimal) |
| StorageSecretReconciler | All | Storage credential secrets (S3, PVC access) |
| KServeCustomCACertReconciler | All | Custom CA certificate ConfigMaps |
| MonitoringReconciler | All (optional) | ServiceMonitors, PodMonitors in monitoring namespace |
| ModelRegistryInferenceServiceReconciler | All (optional) | Model Registry associations |

## Notes

- The controller does not define its own CRDs; it extends existing KServe CRDs with OpenShift integrations
- Service mesh integration is conditional based on `MESH_DISABLED` environment variable and DataScienceCluster configuration
- The controller caches Secrets with label `opendatahub.io/managed: true` for performance
- AuthorizationPolicy resources are explicitly excluded from client cache (always fetched live)
- Leader election ensures only one active controller instance at a time
- The webhook is only activated when KServe with service mesh is enabled in the DataScienceCluster
- All runtime templates are labeled with `opendatahub.io/dashboard: true` for ODH Dashboard discovery
- The controller creates namespace-scoped resources that are cleaned up when no InferenceServices remain in a namespace
