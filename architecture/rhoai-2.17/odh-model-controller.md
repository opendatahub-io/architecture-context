# Component: ODH Model Controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/odh-model-controller
- **Version**: v1.27.0-rhods-728-g2e20486
- **Branch**: rhoai-2.17
- **Distribution**: RHOAI
- **Languages**: Go 1.22.7
- **Deployment Type**: Kubernetes Operator
- **Framework**: Kubebuilder v4

## Purpose
**Short**: Extends KServe model serving capabilities with OpenShift-native integrations for routing, authentication, and monitoring.

**Detailed**: The odh-model-controller is a Kubernetes operator that enhances KServe's InferenceService deployments by automating the creation and management of OpenShift-specific resources. It provides seamless integration with OpenShift Routes for external access, Istio service mesh for traffic management and mTLS, Authorino for authentication/authorization, and Prometheus for metrics collection. The controller supports multiple deployment modes (KServe Serverless, KServe Raw, ModelMesh) and manages the complete lifecycle of model serving infrastructure including networking, security, and observability components. Additionally, it provides NVIDIA NIM (NVIDIA Inference Microservices) account management for GPU-accelerated inference workloads.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| InferenceServiceReconciler | Controller | Orchestrates model serving deployments across KServe Serverless, Raw, and ModelMesh modes |
| ServingRuntimeReconciler | Controller | Manages ServingRuntime resources and monitoring dashboards |
| InferenceGraphReconciler | Controller | Manages multi-model inference pipelines (InferenceGraph CRD) |
| AccountReconciler | Controller | Manages NVIDIA NIM account credentials and configurations |
| ConfigMapReconciler | Controller | Watches and reconciles ConfigMaps for runtime configurations |
| SecretReconciler | Controller | Watches and reconciles Secrets with opendatahub.io/managed label |
| Webhook Server | Webhook | Provides admission webhooks for validation and defaulting |
| Metrics Server | HTTP Service | Exposes controller runtime metrics for Prometheus |
| Health Probes | HTTP Service | Provides liveness and readiness endpoints |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| nim.opendatahub.io | v1 | Account | Namespaced | Manages NVIDIA NIM account credentials and generates NIM-specific ServingRuntime templates, ConfigMaps, and pull secrets |

### Watched External CRDs

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | KServe's primary model serving resource - controller extends with OpenShift integrations |
| serving.kserve.io | v1alpha1 | InferenceGraph | Namespaced | Multi-model inference pipelines - controller manages routing and networking |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Model runtime definitions - controller adds monitoring dashboards |
| serving.kserve.io | v1beta1 | Predictor | Namespaced | ModelMesh predictor resources |
| serving.knative.dev | v1 | Service | Namespaced | Knative Service resources - validated via webhook for serverless mode |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Controller runtime metrics (TODO: migrate to 8443/TLS) |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /mutate-serving-kserve-io-v1alpha1-inferencegraph | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server cert | Mutating webhook for InferenceGraph defaulting |
| /mutate-serving-kserve-io-v1beta1-inferenceservice | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server cert | Mutating webhook for InferenceService defaulting |
| /validate-nim-opendatahub-io-v1-account | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server cert | Validating webhook for NIM Account resources |
| /validate-serving-knative-dev-v1-service | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server cert | Validating webhook for Knative Service resources |
| /validate-serving-kserve-io-v1beta1-inferenceservice | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server cert | Validating webhook for InferenceService resources |

### gRPC Services

None - This component does not expose gRPC services.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| KServe | v0.14.0 | Yes | Core model serving framework - provides InferenceService, ServingRuntime CRDs |
| Kubernetes | v1.31.0 | Yes | Container orchestration platform |
| OpenShift Route | v1 | Yes | External HTTP/HTTPS routing and ingress |
| Istio | v1.23.0 | Conditional | Service mesh for mTLS, traffic management (required if mesh enabled) |
| Authorino | v0.18.1 | Conditional | Token-based authentication/authorization (required if auth enabled) |
| Prometheus Operator | v0.64.1 | Conditional | Metrics collection via ServiceMonitor/PodMonitor |
| Knative Serving | v0.42.2 | Conditional | Serverless runtime for KServe Serverless mode |
| Red Hat Service Mesh (Maistra) | N/A | Conditional | OpenShift service mesh operator (alternative to upstream Istio) |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| DataScienceCluster | Watch CRD | Determines platform configuration and feature enablement |
| DSCInitialization | Watch CRD | Retrieves service mesh and Authorino configuration references |
| Model Registry | HTTP API | Optional integration for tracking model metadata and lineage |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-model-controller-metrics-service | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (TODO: migrate to 8443/TLS) |
| odh-model-controller-webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | K8s API mTLS | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| N/A | N/A | N/A | N/A | N/A | N/A | N/A | Controller creates ingress for managed InferenceServices, not itself |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token | Resource CRUD operations, watches, and status updates |
| Authorino Service | 50051/TCP | gRPC | mTLS | Service Mesh | Create/update AuthConfig resources (if mesh enabled) |
| Istio Pilot | 15010/TCP | gRPC | mTLS | Service Mesh | Gateway and VirtualService management (if mesh enabled) |
| Model Registry API | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token | Model metadata retrieval (if model registry enabled) |
| NVIDIA NGC API | 443/TCP | HTTPS | TLS 1.2+ | API Key | NIM account validation and model catalog access |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-model-controller-role | "" (core) | configmaps, secrets, serviceaccounts, services | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | "" (core) | endpoints, namespaces, pods | create, get, list, patch, update, watch |
| odh-model-controller-role | "" (core) | events | create, patch |
| odh-model-controller-role | authorino.kuadrant.io | authconfigs | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | datasciencecluster.opendatahub.io | datascienceclusters | get, list, watch |
| odh-model-controller-role | dscinitialization.opendatahub.io | dscinitializations | get, list, watch |
| odh-model-controller-role | networking.k8s.io, extensions | ingresses | get, list, watch |
| odh-model-controller-role | maistra.io | servicemeshcontrolplanes | get, list, use, watch |
| odh-model-controller-role | maistra.io | servicemeshmemberrolls | get, list, watch |
| odh-model-controller-role | maistra.io | servicemeshmembers | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | monitoring.coreos.com | podmonitors, servicemonitors | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | networking.istio.io | gateways | get, list, patch, update, watch |
| odh-model-controller-role | networking.istio.io | virtualservices, virtualservices/finalizers | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | nim.opendatahub.io | accounts, accounts/status | get, list, update, watch |
| odh-model-controller-role | nim.opendatahub.io | accounts/finalizers | update |
| odh-model-controller-role | rbac.authorization.k8s.io | clusterrolebindings, rolebindings | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | route.openshift.io | routes/custom-host | create |
| odh-model-controller-role | security.istio.io | authorizationpolicies | get, list |
| odh-model-controller-role | security.istio.io | peerauthentications | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | serving.kserve.io | inferencegraphs | get, list, watch |
| odh-model-controller-role | serving.kserve.io | inferencegraphs/finalizers, servingruntimes/finalizers | update |
| odh-model-controller-role | serving.kserve.io | inferenceservices, inferenceservices/finalizers | get, list, update, watch |
| odh-model-controller-role | serving.kserve.io | servingruntimes | create, get, list, update, watch |
| odh-model-controller-role | telemetry.istio.io | telemetries | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | template.openshift.io | templates | create, delete, get, list, update, watch |
| kserve-prometheus-k8s | "" (core) | namespaces, services, endpoints, pods | get, list, watch |
| kserve-prometheus-k8s | networking.k8s.io | ingresses | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-model-controller-rolebinding | Varies (per deployment) | odh-model-controller-role (ClusterRole) | odh-model-controller |
| odh-model-controller-leader-election-rolebinding | Varies (per deployment) | odh-model-controller-leader-election-role | odh-model-controller |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| odh-model-controller-webhook-cert | kubernetes.io/tls | TLS certificate for webhook server | OpenShift Service CA | Yes |
| Managed by controller | Opaque | NIM pull secrets for container registry authentication | AccountReconciler | No |
| Managed by controller | Opaque | Model storage credentials (S3, PVC, etc.) | User/InferenceService | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None | None | Open (TODO: migrate to token-based auth with RBAC) |
| /healthz, /readyz | GET | None | None | Open (health probes) |
| Webhook endpoints | POST | mTLS client certificate | Kubernetes API Server | Only API server can call webhooks |
| Kubernetes API | ALL | Service Account Token (JWT) | Kubernetes RBAC | ClusterRole permissions enforced |
| Model Registry API | GET, POST | Bearer Token (JWT) | Model Registry | Token passed from controller config |
| NVIDIA NGC API | GET, POST | API Key (from NIM Account Secret) | NGC API Gateway | API key validation |

## Data Flows

### Flow 1: InferenceService Creation (KServe Serverless with Istio)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | kubectl/oc credentials |
| 2 | Kubernetes API | odh-model-controller | 9443/TCP | HTTPS | TLS 1.2+ | K8s API mTLS |
| 3 | odh-model-controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 4 | odh-model-controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 5 | odh-model-controller | Istio Pilot | 15010/TCP | gRPC | mTLS | Service Mesh |

**Description**: Controller receives InferenceService via mutating/validating webhooks (step 2), then creates supporting resources including ServiceAccount, Service, Route, Istio Gateway/VirtualService, PeerAuthentication, AuthConfig, and NetworkPolicy (steps 3-5).

### Flow 2: NIM Account Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | kubectl/oc credentials |
| 2 | Kubernetes API | odh-model-controller | 9443/TCP | HTTPS | TLS 1.2+ | K8s API mTLS |
| 3 | odh-model-controller | NVIDIA NGC API | 443/TCP | HTTPS | TLS 1.2+ | NGC API Key |
| 4 | odh-model-controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |

**Description**: User creates NIM Account resource (step 1), webhook validates (step 2), controller validates API key with NGC (step 3), then creates NIM ConfigMap, ServingRuntime Template, and pull Secret (step 4).

### Flow 3: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | odh-model-controller | odh-model-controller-metrics-service | 8080/TCP | HTTP | None | None |
| 2 | Prometheus | odh-model-controller-metrics-service | 8080/TCP | HTTP | None | None |

**Description**: Controller exposes metrics endpoint (step 1), Prometheus scrapes metrics (step 2). Note: Currently unencrypted (TODO: migrate to 8443/TLS).

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Resource watches, CRUD operations, status updates |
| KServe Controller | Indirect (CRD) | N/A | N/A | N/A | KServe manages pods/deployments, this controller adds OpenShift integrations |
| Istio Control Plane | gRPC API | 15010/TCP | gRPC | mTLS | Gateway, VirtualService, PeerAuthentication management |
| Authorino | Indirect (CRD) | N/A | N/A | N/A | Controller creates AuthConfig resources, Authorino enforces policies |
| OpenShift Router | Indirect (CRD) | N/A | N/A | N/A | Controller creates Route resources for external access |
| Prometheus | HTTP scrape | 8080/TCP | HTTP | None | Metrics collection from controller and managed InferenceServices |
| Model Registry | REST API | 443/TCP | HTTPS | TLS 1.2+ | Model metadata retrieval and inference service metadata updates |
| NVIDIA NGC | REST API | 443/TCP | HTTPS | TLS 1.2+ | NIM account validation, model catalog access |

## Deployment Configuration

### Container Image

- **Build System**: Konflux (RHOAI production builds)
- **Base Image**: registry.redhat.io/ubi8/ubi-minimal (runtime)
- **Build Image**: registry.redhat.io/ubi9/go-toolset:1.22
- **User**: UID 2000 (non-root)
- **Entrypoint**: `/manager`

### Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 10m | 500m |
| Memory | 64Mi | 2Gi |

### Environment Variables

| Variable | Source | Required | Purpose |
|----------|--------|----------|---------|
| POD_NAMESPACE | fieldRef | Yes | Current pod namespace |
| AUTH_AUDIENCE | ConfigMap (auth-refs) | No | Authorino audience for token validation |
| AUTHORINO_LABEL | ConfigMap (auth-refs) | No | Label selector for Authorino instance |
| CONTROL_PLANE_NAME | ConfigMap (service-mesh-refs) | No | Istio/Maistra control plane name |
| MESH_NAMESPACE | ConfigMap (service-mesh-refs) | No | Service mesh control plane namespace |
| NIM_STATE | ConfigMap (odh-model-controller-parameters) | No | Enable/disable NIM account reconciliation |
| ENABLE_WEBHOOKS | Environment | No | Enable/disable admission webhooks (default: true) |
| MESH_DISABLED | Environment | No | Disable service mesh integrations (default: false) |
| MR_SKIP_TLS_VERIFY | Environment | No | Skip TLS verification for Model Registry API (default: false) |

### Command-Line Flags

| Flag | Default | Purpose |
|------|---------|---------|
| --leader-elect | false | Enable leader election for HA deployments |
| --metrics-bind-address | :8080 | Metrics server bind address |
| --health-probe-bind-address | :8081 | Health probe server bind address |
| --metrics-secure | false | Enable TLS for metrics endpoint (TODO: default to true) |
| --enable-http2 | false | Enable HTTP/2 (disabled by default due to CVEs) |
| --monitoring-namespace | "" | Namespace for Prometheus monitoring stack |
| --model-registry-inference-reconcile | false | Enable Model Registry integration |

## Network Policies

### Webhook Traffic

| Direction | Selector | Namespace Selector | Port | Protocol | Purpose |
|-----------|----------|-------------------|------|----------|---------|
| Ingress | control-plane=odh-model-controller | webhook=enabled | 443/TCP | TCP | Allow Kubernetes API server to call webhooks from labeled namespaces |

### Metrics Traffic

| Direction | Selector | Namespace Selector | Port | Protocol | Purpose |
|-----------|----------|-------------------|------|----------|---------|
| Ingress | control-plane=controller-manager | metrics=enabled | 8443/TCP | TCP | Allow Prometheus to scrape metrics from labeled namespaces |

## Managed Resources

The controller creates and manages the following resources for InferenceServices:

### KServe Serverless Mode (with Service Mesh)

- ServiceAccount (per InferenceService)
- Istio Gateway configuration updates
- Istio VirtualService (routing rules)
- Istio PeerAuthentication (mTLS enforcement)
- Istio Telemetry (metrics collection)
- ServiceMeshMember (namespace enrollment)
- Authorino AuthConfig (authentication/authorization)
- OpenShift Route (external access)
- NetworkPolicy (traffic isolation)
- RoleBinding (Prometheus metrics access)
- PodMonitor/ServiceMonitor (metrics collection)

### KServe Raw Mode

- ServiceAccount (per InferenceService)
- OpenShift Route (external access)
- ClusterRoleBinding (model mesh serving role)
- Service (metrics endpoint)
- ServiceMonitor (metrics collection)
- ConfigMap (metrics dashboard)

### ModelMesh Mode

- ServiceAccount (per InferenceService)
- OpenShift Route (external access)
- ClusterRoleBinding (model mesh serving role)

### NIM Account Resources

- Template (ServingRuntime template for NIM)
- ConfigMap (NIM configuration data)
- Secret (NIM container registry pull credentials)

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 2e20486 | 2026-03 | - Update Konflux references (#492) |
| fa641aa | 2026-03 | - Update Konflux references (#491) |
| dca3fc9 | 2026-03 | - Update UBI9 Go toolset base image to cbc354a (#486) |
| 32ff900 | 2026-02 | - Update Konflux references (#478) |
| 7d9bdbf | 2026-02 | - Update Konflux references to b9cb1e1 (#473) |
| bc828b4 | 2026-02 | - Update Konflux references to 944e769 (#467) |
| f5b08ff | 2026-01 | - Update Konflux references (#459) |
| a3f5020 | 2026-01 | - Update Konflux references (#457) |
| 20d84db | 2026-01 | - Update Konflux references to 8b6f22f (#452) |
| 3521114 | 2026-01 | - Update Konflux references (#447) |
| 27cbf7e | 2025-12 | - Update UBI8 minimal base image to c38cc77 (#438) |
| a942fe2 | 2025-12 | - Fix duplicate pipeline configuration (#432) |
| 0226c54 | 2025-12 | - Remove unneeded pipeline files |
| 66548a8 | 2025-12 | - Apply duplicate pipeline fix |
| 754a426 | 2025-11 | - Update Konflux references to 5bc6129 (#422) |

## Architecture Notes

### Multi-Mode Support

The controller supports three distinct InferenceService deployment modes:

1. **KServe Serverless**: Uses Knative Serving for autoscaling, Istio for routing and mTLS, full observability stack
2. **KServe Raw**: Direct Kubernetes deployment without Knative, uses OpenShift Routes for ingress
3. **ModelMesh**: IBM ModelMesh serving framework for multi-model serving with intelligent model placement

The deployment mode is determined by annotations on the InferenceService resource.

### Service Mesh Integration

When service mesh is enabled (default in RHOAI):
- All InferenceService pods are automatically enrolled via ServiceMeshMember
- mTLS is enforced via PeerAuthentication resources
- Istio Gateway provides ingress with SNI-based routing
- VirtualService configures routing rules and traffic splitting
- Telemetry resources enable distributed tracing and metrics

### Authentication Architecture

The controller integrates with Authorino (Kuadrant) for token-based authentication:
- Creates AuthConfig resources per InferenceService
- Supports JWT validation with configurable audiences
- Integrates with OpenShift OAuth for token issuance
- Enforces authentication at Istio Gateway level

### Monitoring Integration

Comprehensive observability through Prometheus Operator:
- ServiceMonitor for scraping model server metrics
- PodMonitor for pod-level metrics in Serverless mode
- Custom Grafana dashboards via ConfigMaps
- RoleBindings grant Prometheus ServiceAccount access to metrics endpoints

### Network Security

Defense-in-depth networking:
- NetworkPolicies isolate InferenceService traffic
- PeerAuthentication enforces mTLS between services
- OpenShift Routes provide TLS termination with cluster certificates
- Webhook traffic restricted to labeled namespaces

### Extensibility

The controller uses a sub-reconciler pattern:
- Core InferenceServiceReconciler delegates to mode-specific reconcilers
- Each reconciler manages a subset of resources (routes, auth, monitoring, etc.)
- Delta processor pattern ensures only changed resources are updated
- Comparator pattern allows custom equality checks for each resource type
