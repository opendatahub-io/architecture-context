# Component: ODH Model Controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/odh-model-controller.git
- **Version**: v1.27.0-rhods-341-gfcca5f2
- **Branch**: rhoai-2.10
- **Distribution**: RHOAI
- **Languages**: Go 1.21
- **Deployment Type**: Kubernetes Operator (Controller)

## Purpose
**Short**: Extends KServe and ModelMesh serving controllers with OpenShift-specific capabilities including ingress integration, service mesh configuration, and authentication policies.

**Detailed**: The ODH Model Controller is a Kubernetes operator that watches InferenceService and ServingRuntime custom resources to provide OpenShift-native extensions for KServe and ModelMesh model serving platforms. It reconciles platform-specific resources such as OpenShift Routes for external access, Istio service mesh configurations (VirtualServices, PeerAuthentications, Telemetries), Authorino authentication policies, Prometheus monitoring integrations (ServiceMonitors, PodMonitors), and network policies. The controller handles three deployment modes: ModelMesh (for multi-model serving), KServe Serverless (Knative-based autoscaling), and KServe Raw (direct Kubernetes deployments). It also manages storage configuration secrets by aggregating data connection credentials into ModelMesh/KServe-compatible formats and handles custom CA certificate propagation for secure S3 storage access.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| InferenceService Controller | Reconciler | Main controller that routes reconciliation to ModelMesh, KServe Serverless, or KServe Raw reconcilers based on deployment mode |
| StorageSecret Controller | Reconciler | Aggregates data connection secrets into storage-config secrets for ModelMesh/KServe consumption |
| KServeCustomCACert Controller | Reconciler | Propagates custom CA certificates from trusted CA bundles to inference namespaces |
| Monitoring Controller | Reconciler | Creates RoleBindings in inference namespaces for Prometheus ServiceAccount access |
| ModelRegistry InferenceService Controller | Reconciler | Synchronizes InferenceService deployments with Model Registry metadata (optional feature) |
| Knative Service Validator | Webhook | Validating webhook for Knative Services created by KServe Serverless mode |
| KServe Route Reconciler | Sub-reconciler | Creates OpenShift Routes for external access to KServe InferenceServices |
| KServe AuthConfig Reconciler | Sub-reconciler | Creates Authorino AuthConfig resources for inference authentication |
| KServe NetworkPolicy Reconciler | Sub-reconciler | Creates NetworkPolicies for inference namespace isolation |
| KServe Istio PeerAuthentication Reconciler | Sub-reconciler | Configures mTLS policies for inference services in service mesh |
| KServe Istio Telemetry Reconciler | Sub-reconciler | Configures Istio telemetry for metrics collection |
| KServe Istio SMMR Reconciler | Sub-reconciler | Manages ServiceMeshMemberRoll entries for inference namespaces |
| KServe ServiceMonitor Reconciler | Sub-reconciler | Creates ServiceMonitor for Prometheus metrics scraping |
| KServe PodMonitor Reconciler | Sub-reconciler | Creates PodMonitor for direct pod metrics collection |
| KServe Metrics Service Reconciler | Sub-reconciler | Creates Service for exposing metrics endpoints |
| KServe Prometheus RoleBinding Reconciler | Sub-reconciler | Creates RoleBindings for Prometheus ServiceAccount |
| ModelMesh Route Reconciler | Sub-reconciler | Creates OpenShift Routes for ModelMesh predictors |
| ModelMesh ServiceAccount Reconciler | Sub-reconciler | Creates ServiceAccounts for ModelMesh deployments |
| ModelMesh ClusterRoleBinding Reconciler | Sub-reconciler | Creates ClusterRoleBindings for ModelMesh ServiceAccounts |

## APIs Exposed

### Custom Resource Definitions (CRDs)

Note: This controller does not define its own CRDs but watches external CRDs from KServe, Istio, OpenShift, and other components.

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Watched - Triggers reconciliation of OpenShift/Istio resources for model inference |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Managed - Creates default serving runtimes (OVMS, TGIS, Caikit, vLLM) |
| authorino.kuadrant.io | v1beta2 | AuthConfig | Namespaced | Managed - Authentication/authorization policies for inference endpoints |
| networking.istio.io | v1beta1 | VirtualService | Namespaced | Managed - Istio routing rules for inference services |
| security.istio.io | v1beta1 | PeerAuthentication | Namespaced | Managed - mTLS configuration for inference workloads |
| security.istio.io | v1beta1 | AuthorizationPolicy | Cluster | Watched - Read-only to check existing policies |
| telemetry.istio.io | v1alpha1 | Telemetry | Namespaced | Managed - Istio metrics collection configuration |
| route.openshift.io | v1 | Route | Namespaced | Managed - OpenShift external access routes for inference endpoints |
| monitoring.coreos.com | v1 | ServiceMonitor | Namespaced | Managed - Prometheus scrape configuration for services |
| monitoring.coreos.com | v1 | PodMonitor | Namespaced | Managed - Prometheus scrape configuration for pods |
| maistra.io | v1 | ServiceMeshMember | Namespaced | Managed - Adds namespaces to ServiceMesh |
| maistra.io | v1 | ServiceMeshMemberRoll | Namespaced | Managed - Batch namespace membership in ServiceMesh |
| serving.knative.dev | v1 | Service | Namespaced | Validated - Webhook validates Knative Services for KServe Serverless |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for controller operations |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /validate-serving-knative-dev-v1-service | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Validating webhook for Knative Services |

### gRPC Services

This controller does not expose gRPC services.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| KServe | v0.11.0 | Yes | Core model serving platform providing InferenceService CRD |
| Istio | v1.17+ | Optional | Service mesh for traffic management, mTLS, telemetry |
| Authorino | v0.15.0 | Optional | Authorization service for inference endpoint authentication |
| OpenShift Service Mesh (Maistra) | v2.x | Optional | OpenShift-managed Istio distribution |
| Prometheus Operator | v0.64.1 | Optional | Monitoring stack for ServiceMonitor/PodMonitor CRDs |
| Knative Serving | v0.37.1 | Optional | Serverless platform for KServe Serverless mode |
| Model Registry | v0.1.1 | Optional | ML model metadata registry integration |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KServe Controller | CRD Watching | Watches InferenceService/ServingRuntime CRDs created by KServe |
| ModelMesh Serving | CRD Watching | Watches Predictor CRDs created by ModelMesh |
| ODH Dashboard | ConfigMap/Template | Provides serving runtime templates deployed as ConfigMaps |
| DataScienceCluster | CRD Reading | Reads DSC to determine if KServe/ModelMesh/ServiceMesh features are enabled |
| DSCInitialization | CRD Reading | Reads DSCI for Authorino configuration and ServiceMesh settings |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-model-controller-metrics-service | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (Prometheus) |
| odh-model-controller-webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS (OpenShift Service CA) | K8s API Server mTLS | Internal (API Server) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| odh-model-controller (NetworkPolicy) | NetworkPolicy Ingress | N/A | 9443/TCP | HTTPS | TLS 1.2+ | N/A | Restricted to API Server |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch/manage CRDs, create resources |
| User Namespaces (InferenceService) | Various | Various | Varies | ServiceAccount RBAC | Create/manage Routes, Services, AuthConfigs in inference namespaces |
| ServiceMesh Control Plane Namespace | Various | Various | Varies | ServiceAccount RBAC | Manage ServiceMeshMemberRoll, ServiceMeshMember |
| Monitoring Namespace (OpenShift) | N/A | N/A | N/A | ServiceAccount RBAC | Create RoleBindings for Prometheus access |

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
| odh-model-controller-role | networking.k8s.io | networkpolicies, ingresses | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | rbac.authorization.k8s.io | clusterrolebindings, rolebindings | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | monitoring.coreos.com | servicemonitors, podmonitors | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | "" | services, secrets, configmaps, serviceaccounts | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | "" | namespaces, pods, endpoints | get, list, watch, create, update, patch |
| odh-model-controller-role | authorino.kuadrant.io | authconfigs | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | datasciencecluster.opendatahub.io | datascienceclusters | get, list, watch |
| odh-model-controller-role | dscinitialization.opendatahub.io | dscinitializations | get, list, watch |
| leader-election-role (namespaced) | "" | configmaps, events | get, list, watch, create, update, patch, delete |
| leader-election-role (namespaced) | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-model-controller-rolebinding-$(mesh-namespace) | Cluster-scoped | odh-model-controller-role (ClusterRole) | odh-model-controller (in mesh namespace) |
| leader-election-rolebinding | mesh-namespace (e.g., opendatahub) | leader-election-role (Role) | odh-model-controller |
| prometheus-ns-access | Inference namespaces | prometheus-ns-access (ClusterRole) | prometheus-custom (in monitoring namespace) |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| odh-model-controller-webhook-cert | kubernetes.io/tls | TLS certificate for validating webhook server | OpenShift Service CA | Yes (OpenShift) |
| storage-config | Opaque | Aggregated S3 credentials for ModelMesh/KServe model storage | StorageSecret Controller | No (user-managed) |
| Data connection secrets | Opaque | Individual S3/storage credentials (watched by controller) | Users/Dashboard | No (user-managed) |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /validate-serving-knative-dev-v1-service | POST | K8s API Server mTLS | API Server Admission Control | ValidatingWebhookConfiguration |
| /metrics | GET | None | N/A | Internal-only (ClusterIP service) |
| /healthz, /readyz | GET | None | N/A | Internal-only health checks |

## Data Flows

### Flow 1: InferenceService Reconciliation (KServe Serverless Mode)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Dashboard | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | User Token |
| 2 | Kubernetes API Server | odh-model-controller | N/A | Watch Stream | TLS 1.2+ | ServiceAccount Token |
| 3 | odh-model-controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | odh-model-controller | User Namespace | N/A | API Calls | TLS 1.2+ | ServiceAccount Token |

**Description**: User creates InferenceService → Controller watches event → Creates OpenShift Route, Istio VirtualService, Authorino AuthConfig, NetworkPolicy, ServiceMonitor, PodMonitor in user namespace.

### Flow 2: StorageSecret Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Dashboard | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | User Token |
| 2 | Kubernetes API Server | odh-model-controller | N/A | Watch Stream | TLS 1.2+ | ServiceAccount Token |
| 3 | odh-model-controller | User Namespace | N/A | API Calls | TLS 1.2+ | ServiceAccount Token |

**Description**: User creates data connection Secret with label `opendatahub.io/managed=true` → Controller watches → Aggregates all labeled secrets in namespace → Creates/updates storage-config secret in same namespace.

### Flow 3: Custom CA Certificate Propagation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | OpenShift CA Operator | odh-trusted-ca-bundle ConfigMap | N/A | ConfigMap Inject | N/A | Cluster Operator |
| 2 | odh-model-controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | odh-model-controller | Inference Namespace | N/A | API Calls | TLS 1.2+ | ServiceAccount Token |

**Description**: OpenShift injects cluster CA bundle into labeled ConfigMap → Controller watches → Copies CA bundle to odh-kserve-custom-ca-bundle ConfigMap in inference namespaces → Updates storage-config secrets with certificate field.

### Flow 4: Monitoring RoleBinding Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | User Token |
| 2 | Kubernetes API Server | odh-model-controller | N/A | Watch Stream | TLS 1.2+ | ServiceAccount Token |
| 3 | odh-model-controller | Inference Namespace | N/A | API Calls | TLS 1.2+ | ServiceAccount Token |

**Description**: User creates InferenceService in namespace → Controller reconciles → Creates RoleBinding in namespace granting prometheus-custom ServiceAccount access to prometheus-ns-access ClusterRole → Prometheus can scrape metrics from namespace.

### Flow 5: Knative Service Validation (Webhook)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | KServe Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Kubernetes API Server | odh-model-controller-webhook-service | 443/TCP | HTTPS | TLS (Service CA) | API Server mTLS |
| 3 | odh-model-controller | Response to API Server | N/A | AdmissionReview | TLS | mTLS |

**Description**: KServe creates Knative Service for InferenceService → API Server intercepts via ValidatingWebhookConfiguration → Calls webhook endpoint → Controller validates service configuration → Returns admission decision.

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | Watch/API | 6443/TCP | HTTPS | TLS 1.2+ | Watch InferenceService, ServingRuntime, Secret, ConfigMap events; create/update resources |
| Prometheus | ServiceMonitor | N/A | Metrics Scrape | Varies | Controller creates ServiceMonitors/PodMonitors for inference workloads |
| Authorino | AuthConfig CRD | N/A | CRD Creation | N/A | Controller creates AuthConfig resources for inference authentication |
| Istio Control Plane | Istio CRDs | N/A | CRD Creation | N/A | Controller creates VirtualServices, PeerAuthentications, Telemetries |
| OpenShift Router | Route CRD | N/A | CRD Creation | N/A | Controller creates Routes for external inference access |
| OpenShift Service Mesh | ServiceMesh CRDs | N/A | CRD Creation | N/A | Controller creates ServiceMeshMember/Roll for namespace inclusion |
| Model Registry | gRPC API | 8080/TCP | gRPC | TLS (optional) | Optional integration to sync InferenceService with model metadata |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| v1.27.0-rhods-341 | 2024-10-10 | - Added instant-merge workflow for CI/CD automation |
| v1.27.0-rhods | 2024-08-19 | - Fixed Authorino Subject Access Review (SAR) to be more fine-grained<br>- Improved authorization policy checks |
| v1.27.0 | 2024-08-12 | - Updated Golang version to 1.21 (RHOAIENG-8613) |
| v0.12.0 | 2024-06-19 | - Fixed vLLM ServingRuntime template (cherry-pick to 2.10 branch) |
| v0.12.0 | 2024-06-01 | - Synced release-0.12.0 with main branch<br>- Updated runtime images to MODH versions |
| v0.12.0 | 2024-05-31 | - Added NetworkPolicy for controller pod (port 9443 ingress)<br>- Mitigated auth race condition in Authorino integration<br>- Updated runtime image tags to stable versions |

## Serving Runtime Templates

The controller deploys the following default ServingRuntime templates:

| Runtime | Template File | Purpose | Protocol |
|---------|--------------|---------|----------|
| OpenVINO Model Server (MM) | ovms-mm-template.yaml | Multi-model serving with OpenVINO for ModelMesh | gRPC |
| OpenVINO Model Server (KServe) | ovms-kserve-template.yaml | Single-model serving with OpenVINO for KServe | gRPC/HTTP |
| Caikit-TGIS | caikit-tgis-template.yaml | Text Generation Inference Server with Caikit NLP framework | gRPC |
| TGIS Standalone | tgis-template.yaml | Text Generation Inference Server for LLMs | gRPC |
| vLLM | vllm-template.yaml | High-throughput LLM serving with vLLM engine | HTTP |

## Deployment Configuration

| Parameter | Value | Description |
|-----------|-------|-------------|
| Replicas | 3 | High availability with leader election |
| Anti-Affinity | Preferred | Spread pods across nodes (weight: 100) |
| Resource Requests | CPU: 10m, Memory: 64Mi | Minimal resource footprint |
| Resource Limits | CPU: 500m, Memory: 2Gi | Prevent resource exhaustion |
| Leader Election | Enabled | Only one active reconciler at a time |
| Service Account | odh-model-controller | Dedicated SA with cluster-scoped permissions |
| Security Context | runAsNonRoot: true, allowPrivilegeEscalation: false | Security-hardened |
| Webhook Certificates | OpenShift Service CA | Auto-rotated TLS certificates |

## Environment Variables

| Variable | Source | Purpose |
|----------|--------|---------|
| POD_NAMESPACE | fieldRef: metadata.namespace | Identifies controller's namespace |
| AUTH_AUDIENCE | ConfigMap: auth-refs | Authorino audience for token validation |
| AUTHORINO_LABEL | ConfigMap: auth-refs | Label selector for Authorino instances |
| CONTROL_PLANE_NAME | ConfigMap: service-mesh-refs | ServiceMesh control plane name |
| MESH_NAMESPACE | ConfigMap: service-mesh-refs | ServiceMesh control plane namespace |
| MESH_DISABLED | Environment (optional) | Disables service mesh integration if true |

## Notes

- The controller supports three InferenceService deployment modes: ModelMesh (multi-model serving), KServe Serverless (Knative-based autoscaling), and KServe Raw (standard Kubernetes deployments)
- Service mesh integration (Istio) is optional and can be disabled via MESH_DISABLED environment variable
- Authorino authentication is optional and enabled only when DSCInitialization CR configures it
- Monitoring RoleBinding creation requires --monitoring-namespace flag to be set
- Model Registry integration requires --model-registry-inference-reconcile flag
- The controller uses leader election to ensure only one replica actively reconciles resources
- NetworkPolicy restricts ingress to webhook port 9443 only
- Storage secrets are auto-aggregated from data connection secrets with label opendatahub.io/managed=true
- Custom CA certificates are propagated from cluster-wide trusted CA bundle to inference namespaces
- All created resources are labeled with opendatahub.io/managed=true for lifecycle management
- Kustomize overlays: dev (development), odh (Open Data Hub), base (production)
- Webhook server requires TLS certificate from OpenShift Service CA Operator
