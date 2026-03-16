# Component: ODH Model Controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/odh-model-controller.git
- **Version**: v1.27.0-rhods-297-g863a266
- **Branch**: rhoai-2.9
- **Distribution**: RHOAI
- **Languages**: Go 1.19
- **Deployment Type**: Kubernetes Operator/Controller

## Purpose
**Short**: OpenShift integration controller that extends KServe with OpenShift Routes, Istio service mesh, and Authorino authentication.

**Detailed**: The ODH Model Controller is a Kubernetes operator that watches KServe InferenceService custom resources and extends their functionality with OpenShift-specific integrations. It bridges KServe's model serving capabilities with OpenShift's ingress (Routes), Red Hat Service Mesh (Istio), and Authorino for authentication/authorization. The controller supports both KServe deployment modes (Serverless and RawDeployment) and ModelMesh, creating the necessary networking, security, and monitoring resources to enable production-grade model serving on OpenShift. It handles automatic creation of Routes for external access, configures mTLS and authorization policies via Istio, manages network policies for pod-to-pod communication, and integrates with OpenShift's monitoring stack through ServiceMonitors and PodMonitors.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| OpenshiftInferenceServiceReconciler | Controller | Main reconciler that watches InferenceService CRDs and delegates to deployment-mode-specific sub-reconcilers (ModelMesh, KServe Serverless, KServe RawDeployment) |
| ModelMeshInferenceServiceReconciler | Sub-Reconciler | Manages OpenShift Routes, ServiceAccounts, and ClusterRoleBindings for ModelMesh-based InferenceServices |
| KserveServerlessInferenceServiceReconciler | Sub-Reconciler | Manages Routes, AuthConfigs, NetworkPolicies, ServiceMonitors/PodMonitors, PeerAuthentication, Telemetry, and SMMR for KServe Serverless deployments |
| KserveRawInferenceServiceReconciler | Sub-Reconciler | Manages resources for KServe RawDeployment mode (non-Knative deployments) |
| StorageSecretReconciler | Controller | Watches and reconciles storage secrets for model access |
| KServeCustomCACertReconciler | Controller | Manages custom CA certificate bundles for KServe components |
| MonitoringReconciler | Controller | Creates RoleBindings to grant OpenShift Prometheus access to namespaces with InferenceServices |
| ModelRegistryInferenceServiceReconciler | Controller | Integrates InferenceServices with Model Registry (optional, enabled via flag) |
| KnativeServiceValidator | Webhook | Validating webhook for Knative Services (enabled when KServe Serverless is active) |

## APIs Exposed

### Custom Resource Definitions (CRDs)

**Note**: This controller does not define its own CRDs. It watches and reconciles external CRDs:

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Primary resource watched - represents a deployed ML model |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Watched to trigger InferenceService reconciliation when runtime changes |
| serving.knative.dev | v1 | Service | Namespaced | Validated by webhook when KServe Serverless is enabled |
| authorino.kuadrant.io | v1beta2 | AuthConfig | Namespaced | Created/managed when Authorino authorization is enabled |
| route.openshift.io | v1 | Route | Namespaced | Created/managed for external HTTP/HTTPS access to models |
| networking.istio.io | v1beta1 | VirtualService | Namespaced | Created/managed for Istio traffic routing |
| security.istio.io | v1beta1 | PeerAuthentication | Namespaced | Created/managed for mTLS configuration |
| security.istio.io | v1beta1 | AuthorizationPolicy | Namespaced | Read to determine authorization configuration |
| telemetry.istio.io | v1alpha1 | Telemetry | Namespaced | Created/managed for Istio telemetry configuration |
| maistra.io | v1 | ServiceMeshMemberRoll | Namespaced | Created/managed to add namespaces to service mesh |
| monitoring.coreos.com | v1 | ServiceMonitor | Namespaced | Created/managed for Prometheus metrics scraping |
| monitoring.coreos.com | v1 | PodMonitor | Namespaced | Created/managed for Prometheus pod metrics scraping |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe for controller health |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe for controller startup |
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint for controller observability |
| /validate-serving-knative-dev-v1-service | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server | Validating webhook for Knative Service resources |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | Controller does not expose gRPC services |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| KServe | v0.11.0 | Yes | Model serving platform - source of InferenceService CRDs |
| Kubernetes | v1.26.4-v1.27.6 | Yes | Container orchestration platform |
| OpenShift Routes API | v3.9.0+ | Yes | OpenShift-specific ingress for external model access |
| Istio Client | v1.17.4 | Conditional | Service mesh integration (when mesh enabled) |
| Authorino | v0.15.0 | Conditional | Authentication/authorization (when enabled via capability) |
| Knative Serving | v0.39.3 | Conditional | Serverless platform (for KServe Serverless mode) |
| Red Hat Service Mesh (Maistra) | N/A | Conditional | OpenShift service mesh control plane |
| Prometheus Operator | v0.64.1 | Conditional | Monitoring integration (when --monitoring-namespace provided) |
| Model Registry | v0.1.1 | Conditional | Model metadata registry (when --model-registry-inference-reconcile enabled) |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| DataScienceCluster CR | CRD Read | Determines if KServe with Service Mesh is enabled |
| DSCInitialization CR | CRD Read | Reads platform configuration and capabilities |
| OpenShift Monitoring Stack | ServiceMonitor | Prometheus instance in monitoring namespace scrapes metrics |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-model-controller-webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | mTLS from API Server | Internal |
| odh-model-controller-metrics-service | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| [InferenceService]-[predictor/transformer] | OpenShift Route | Dynamic (created per ISVC) | 443/TCP | HTTPS | TLS 1.2+ | Edge Termination | External |

**Note**: Routes are dynamically created by the controller for each InferenceService, providing external HTTPS access to deployed models. Route hostnames are assigned by OpenShift Router.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch CRDs, manage resources |
| Authorino Service | 50051/TCP | gRPC | mTLS | Service Mesh | Authorization policy queries (when enabled) |
| Model Registry | varies | gRPC/HTTP | TLS | ServiceAccount | Model metadata retrieval (when enabled) |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-model-controller-role | serving.kserve.io | inferenceservices, inferenceservices/finalizers | get, list, watch, update |
| odh-model-controller-role | serving.kserve.io | servingruntimes, servingruntimes/finalizers | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | networking.istio.io | virtualservices, virtualservices/finalizers | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | security.istio.io | peerauthentications | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | security.istio.io | authorizationpolicies | get, list |
| odh-model-controller-role | telemetry.istio.io | telemetries | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | maistra.io | servicemeshmembers, servicemeshmembers/finalizers | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | maistra.io | servicemeshmemberrolls | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | maistra.io | servicemeshcontrolplanes | get, list, watch, create, update, patch, use |
| odh-model-controller-role | route.openshift.io | routes | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | route.openshift.io | routes/custom-host | create |
| odh-model-controller-role | rbac.authorization.k8s.io | clusterrolebindings, rolebindings | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | networking.k8s.io | networkpolicies | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | networking.k8s.io | ingresses | get, list, watch |
| odh-model-controller-role | monitoring.coreos.com | servicemonitors, podmonitors | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | "" (core) | namespaces, pods, services, endpoints | get, list, watch, create, update, patch |
| odh-model-controller-role | "" (core) | secrets, configmaps, serviceaccounts | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | authorino.kuadrant.io | authconfigs | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | datasciencecluster.opendatahub.io | datascienceclusters | get, list, watch |
| odh-model-controller-role | dscinitialization.opendatahub.io | dscinitializations | get, list, watch |
| odh-model-controller-leader-election-role | "" (core) | configmaps | get, list, watch, create, update, patch, delete |
| odh-model-controller-leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| prometheus-ns-access | "" (core) | services, endpoints, pods | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-model-controller-rolebinding-$(mesh-namespace) | Cluster-wide | odh-model-controller-role | odh-model-controller (in deployment namespace) |
| odh-model-controller-leader-election-rolebinding | Deployment namespace | odh-model-controller-leader-election-role | odh-model-controller |
| prometheus-ns-access | Per InferenceService namespace | prometheus-ns-access (ClusterRole) | prometheus-custom (in monitoring namespace) |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| odh-model-controller-webhook-cert | kubernetes.io/tls | TLS certificate for validating webhook server | service.beta.openshift.io/serving-cert-secret-name annotation | Yes |
| auth-refs | Opaque (ConfigMap) | Stores AUTH_AUDIENCE and AUTHORINO_LABEL configuration | Platform/Admin | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /validate-serving-knative-dev-v1-service | POST | mTLS client cert | Kubernetes API Server | ValidatingWebhookConfiguration |
| InferenceService HTTP/HTTPS (via Route) | ALL | Bearer Token (JWT) or Anonymous | Authorino (when enabled) | AuthConfig per InferenceService |
| InferenceService gRPC (internal mesh) | ALL | mTLS | Istio PeerAuthentication | STRICT mTLS mode in mesh |

**Note**: Authorization mode (anonymous vs authenticated) is determined per InferenceService via annotation `security.opendatahub.io/enable-auth: "true"` or `security.opendatahub.io/enable-auth-odh: "true"`.

## Data Flows

### Flow 1: InferenceService Creation - KServe Serverless Mode

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | Bearer Token (kubeconfig) |
| 2 | Kubernetes API | odh-model-controller | Watch (long-lived HTTPS) | HTTPS | TLS 1.3 | ServiceAccount Token |
| 3 | odh-model-controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |
| 4 | odh-model-controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |

**Details**:
- **Step 1**: User creates InferenceService CR via kubectl/UI
- **Step 2**: Controller receives InferenceService event via watch
- **Step 3**: Controller creates OpenShift Route, NetworkPolicy, PeerAuthentication, Telemetry, ServiceMonitor/PodMonitor, AuthConfig (if auth enabled)
- **Step 4**: Controller adds namespace to ServiceMeshMemberRoll

### Flow 2: External Model Inference Request

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | OpenShift Router | 443/TCP | HTTPS | TLS 1.3 | Bearer Token (optional) |
| 2 | OpenShift Router | Istio Ingress Gateway | varies | HTTP/HTTPS | TLS (mesh) | Bearer Token forwarded |
| 3 | Istio Ingress Gateway | Authorino | 50051/TCP | gRPC | mTLS | Service Mesh cert |
| 4 | Istio Ingress Gateway | InferenceService Pod | varies | HTTP/gRPC | mTLS | Service Mesh cert |
| 5 | InferenceService Pod | Model Storage (S3/PVC) | 443/TCP or local | HTTPS or local | TLS 1.2+ or None | Storage credentials |

**Details**:
- **Step 1**: Client sends inference request to Route hostname
- **Step 2**: Route forwards to Istio gateway (VirtualService routing)
- **Step 3**: Authorino validates JWT token (if auth enabled)
- **Step 4**: Request routed to inference pod via Knative Service
- **Step 5**: Model runtime loads model artifacts from storage

### Flow 3: Monitoring Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus (monitoring NS) | InferenceService Pods | varies | HTTP/HTTPS | TLS (mesh) | ServiceAccount Token |
| 2 | Prometheus (monitoring NS) | odh-model-controller | 8080/TCP | HTTP | None | None |

**Details**:
- **Step 1**: Prometheus scrapes metrics from InferenceService pods via ServiceMonitor/PodMonitor created by controller
- **Step 2**: Prometheus scrapes controller's own metrics endpoint

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| KServe Controller | CRD Watch | 6443/TCP | HTTPS | TLS 1.3 | Watch InferenceService status updates |
| OpenShift Router | Route Creation | N/A | N/A | N/A | Controller creates Routes; Router provisions external endpoints |
| Istio Control Plane | CRD Management | 6443/TCP | HTTPS | TLS 1.3 | Create VirtualServices, PeerAuthentication, Telemetry |
| Authorino | CRD Management | 6443/TCP | HTTPS | TLS 1.3 | Create AuthConfig resources; Authorino enforces at runtime |
| Service Mesh Control Plane | API Calls | 6443/TCP | HTTPS | TLS 1.3 | Update ServiceMeshMemberRoll to include ISVC namespaces |
| Prometheus Operator | CRD Management | 6443/TCP | HTTPS | TLS 1.3 | Create ServiceMonitor/PodMonitor for metrics collection |
| Model Registry | gRPC API | varies | gRPC | TLS | Fetch model metadata (when enabled) |
| DataScienceCluster Operator | CRD Read | 6443/TCP | HTTPS | TLS 1.3 | Determine enabled components and capabilities |

## Deployment Architecture

### Controller Pod Specification

| Property | Value |
|----------|-------|
| Replicas | 3 (high availability) |
| Pod Anti-Affinity | Preferred - spread across nodes |
| Security Context | runAsNonRoot: true, allowPrivilegeEscalation: false |
| User ID | 65532 (non-root) |
| CPU Request | 10m |
| CPU Limit | 500m |
| Memory Request | 64Mi |
| Memory Limit | 2Gi |
| Image Pull Policy | Always |

### Volume Mounts

| Mount Path | Source | Purpose |
|------------|--------|---------|
| /tmp/k8s-webhook-server/serving-certs | odh-model-controller-webhook-cert Secret | TLS certificates for webhook server |

### Environment Variables

| Variable | Source | Purpose |
|----------|--------|---------|
| POD_NAMESPACE | fieldRef: metadata.namespace | Current namespace for controller operations |
| AUTH_AUDIENCE | ConfigMap: auth-refs | JWT audience for Authorino validation |
| AUTHORINO_LABEL | ConfigMap: auth-refs | Label selector for Authorino instance |
| MESH_DISABLED | Flag (default: false) | Disable service mesh integration |

### Command-Line Flags

| Flag | Default | Purpose |
|------|---------|---------|
| --leader-elect | true (in prod) | Enable leader election for HA |
| --metrics-bind-address | :8080 | Port for Prometheus metrics |
| --health-probe-bind-address | :8081 | Port for health/readiness probes |
| --monitoring-namespace | "" | Namespace with Prometheus (enables MonitoringReconciler) |
| --model-registry-inference-reconcile | false | Enable Model Registry integration |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| v1.27.0-rhods-297 | 2024 | - **RHOAIENG-6877**: Fixed issue where controller breaks Knative when KServe-Serverless is not enabled<br>- **Authorization Capability Detection**: Fixed detection for manual service mesh setups (not via DSC)<br>- **RHOAIENG-5299**: Fixed Container Breakout vulnerability (CVE-2024-21626) in containerd<br>- **RHOAIENG-5305**: Fixed golang.org/x/net resource exhaustion vulnerability (CVE-2023-45288)<br>- **Authorino Soft Opt-in**: Added capability-based detection for Authorino (DSCI resource check)<br>- **RBAC Fix**: Corrected DSCI resource name in ClusterRole<br>- **Security Updates**: Multiple dependency upgrades for CVE fixes (protobuf, containerd, knative) |

**Recent Commit Summary (last 20 commits)**:
- Fixed Knative Service webhook registration when KServe-Serverless disabled
- Improved authorization capability detection for manual mesh configurations
- Multiple security vulnerability fixes (container breakout, network DoS)
- Upstream synchronization with opendatahub-io/odh-model-controller release-0.12.0
- Authorization feature soft opt-in via DataScienceCluster capabilities
- RBAC and reconciler improvements for stability

## Notes

### Deployment Modes
The controller supports three InferenceService deployment modes:
1. **ModelMesh**: Multi-model serving with shared runtime pools
2. **KServe Serverless**: Knative-based autoscaling (scale-to-zero)
3. **KServe RawDeployment**: Direct Kubernetes Deployments (no Knative)

Each mode has a dedicated sub-reconciler with mode-specific resource creation logic.

### Service Mesh Integration
Service mesh integration is controlled by:
- **DataScienceCluster CR**: `spec.components.kserve.serving.managementState` and mesh configuration
- **MESH_DISABLED env var**: Can disable mesh features even when available
- **Capability detection**: Controller checks for Authorino CRD availability to enable auth features

When mesh is enabled, the controller creates:
- PeerAuthentication (STRICT mTLS)
- VirtualServices (traffic routing)
- Telemetry resources (observability)
- ServiceMeshMemberRoll updates (namespace enrollment)
- AuthConfig resources (when Authorino available)

### Monitoring Integration
When `--monitoring-namespace` is provided:
- Controller creates RoleBindings in each InferenceService namespace
- Grants `prometheus-custom` ServiceAccount access to scrape metrics
- Creates ServiceMonitors/PodMonitors for model endpoint metrics
- Enables namespace-scoped monitoring without cluster-admin privileges

### Security Considerations
- Controller runs with non-root user (65532)
- SecurityContext prevents privilege escalation
- Webhook uses OpenShift service serving certificates (auto-rotated)
- ClusterRole permissions are scoped to specific API groups and verbs
- Leader election prevents split-brain in multi-replica deployments

### Limitations
- OpenShift-specific: Requires OpenShift Route API (not portable to vanilla Kubernetes)
- Service mesh dependency: Full feature set requires Red Hat Service Mesh (Maistra)
- Authorization requires Authorino: Cannot use other auth providers without code changes
- No custom CRDs: Controller extends KServe but doesn't define its own APIs
