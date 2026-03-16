# Component: ODH Model Controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/odh-model-controller
- **Version**: v1.27.0-rhods-527-g5597309
- **Branch**: rhoai-2.13
- **Distribution**: RHOAI
- **Languages**: Go 1.21
- **Deployment Type**: Kubernetes Operator/Controller

## Purpose
**Short**: Kubernetes controller that extends KServe functionality with OpenShift-specific integrations for model serving workloads.

**Detailed**: The ODH Model Controller is a Kubernetes operator developed with Kubebuilder that watches KServe InferenceService resources and extends their capabilities with OpenShift-specific features. It provides seamless integration with OpenShift Routes for ingress, Istio Service Mesh for secure communication, and Prometheus for monitoring. The controller supports multiple deployment modes including KServe Serverless (Knative-based), KServe Raw (Kubernetes deployments), and ModelMesh (multi-model serving). It automates the creation and management of networking resources (Routes, VirtualServices, Gateways), security configurations (AuthConfigs, PeerAuthentications, NetworkPolicies), and monitoring resources (ServiceMonitors, PodMonitors, dashboards) to provide a production-ready model serving platform.

The controller implements reconciliation logic for different deployment scenarios and integrates with the ODH/RHOAI ecosystem including the Model Registry for tracking model versions and lineage. It handles storage configuration by aggregating data connection secrets into a unified storage-config secret consumed by KServe and ModelMesh runtimes.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| OpenshiftInferenceServiceReconciler | Controller | Main reconciler for KServe InferenceServices, orchestrates sub-reconcilers based on deployment mode |
| ModelMeshInferenceServiceReconciler | Controller | Handles ModelMesh-specific reconciliation (routes, service accounts, cluster role bindings) |
| KserveServerlessInferenceServiceReconciler | Controller | Handles KServe Serverless mode (Knative-based) with service mesh integration |
| KserveRawInferenceServiceReconciler | Controller | Handles KServe Raw deployment mode (standard Kubernetes deployments) |
| StorageSecretReconciler | Controller | Aggregates data connection secrets into unified storage-config for model storage access |
| KServeCustomCACertReconciler | Controller | Manages custom CA certificate bundles for secure storage endpoint access |
| MonitoringReconciler | Controller | Creates namespace-scoped monitoring RoleBindings for Prometheus access |
| ModelRegistryInferenceServiceReconciler | Controller | Integrates InferenceServices with Model Registry for versioning and metadata |
| KnativeServiceValidatingWebhook | Webhook | Validates Knative Service resources when KServe Serverless is enabled |
| Manager Deployment | Workload | HA deployment (3 replicas) running all controllers with leader election |

## APIs Exposed

### Custom Resource Definitions (CRDs)

**Note**: This controller does not define its own CRDs. It watches and reconciles external CRDs:

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Watched resource - model serving workload definition |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Created/managed - runtime configuration for model servers |
| serving.knative.dev | v1 | Service | Namespaced | Validated via webhook when serverless mode enabled |
| datasciencecluster.opendatahub.io | v1 | DataScienceCluster | Cluster | Read - determines if KServe/ServiceMesh components enabled |
| dscinitialization.opendatahub.io | v1 | DSCInitialization | Cluster | Read - cluster initialization configuration |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | Bearer Token | Prometheus metrics endpoint for controller metrics |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /validate-serving-knative-dev-v1-service | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Auth | Validating webhook for Knative Services |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | This component does not expose gRPC services |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| KServe | v0.12.1 | Yes | Core model serving platform - provides InferenceService CRD and serving logic |
| Knative Serving | v0.39.3 | Conditional | Required for KServe Serverless mode - provides autoscaling and traffic management |
| Istio Service Mesh | v1.19.4 | Conditional | Required when mesh enabled - provides mTLS, traffic management, observability |
| Authorino | v0.15.0 | Conditional | Required when authentication enabled - provides API authorization |
| Prometheus Operator | v0.64.1 | Conditional | Required for metrics - provides ServiceMonitor/PodMonitor CRDs |
| OpenShift Routes API | v3.9.0+ | Yes | OpenShift-specific ingress - creates external access to inference endpoints |
| Maistra ServiceMesh | v2.x | Conditional | OpenShift Service Mesh distribution - provides ServiceMeshMember CRD |
| Model Registry | v0.1.1 | Optional | Model versioning and metadata tracking |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| odh-dashboard | ConfigMap/Secret Labels | Consumes data connections created by dashboard (opendatahub.io/dashboard=true labels) |
| kserve-controller | CRD Watch | Relies on KServe controller to manage InferenceService deployment lifecycle |
| modelmesh-controller | CRD Watch | Works alongside ModelMesh controller for multi-model serving deployments |
| odh-operator | DSC/DSCI CRDs | Reads DataScienceCluster resources to determine component enablement |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-model-controller-webhook-service | ClusterIP | 443/TCP | 9443 (webhook-server) | HTTPS | TLS 1.2+ | K8s API Server mTLS | Internal (API Server) |
| odh-model-controller-metrics-service | ClusterIP | 8080/TCP | 8080 (metrics) | HTTP | None | Bearer Token | Internal (Prometheus) |
| [per-isvc]-predictor | ClusterIP | 80/TCP, 443/TCP | varies | HTTP/HTTPS | TLS 1.2+ (conditional) | Bearer/mTLS (conditional) | Internal (Created for each InferenceService) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| [isvc-name]-[namespace] | OpenShift Route | [isvc-name]-[namespace].[cluster-domain] | 443/TCP | HTTPS | TLS 1.2+ | Edge/Passthrough | External (Created per InferenceService) |
| kserve-local-gateway | Istio Gateway | * | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | Internal (Service Mesh ingress for serverless) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Controller reconciliation - watch/update CRDs |
| S3-compatible Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/AccessKey | Model artifact storage access (via InferenceService pods) |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret | Pull serving runtime container images |
| Model Registry gRPC | varies/TCP | gRPC | mTLS | Client Cert | Query model metadata when model-registry integration enabled |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-model-controller-role | serving.kserve.io | inferenceservices, inferenceservices/finalizers | get, list, watch, update |
| odh-model-controller-role | serving.kserve.io | servingruntimes, servingruntimes/finalizers | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | networking.istio.io | virtualservices, virtualservices/finalizers, gateways | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | security.istio.io | peerauthentications | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | security.istio.io | authorizationpolicies | get, list |
| odh-model-controller-role | telemetry.istio.io | telemetries | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | route.openshift.io | routes, routes/custom-host | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | "" (core) | services, secrets, configmaps, serviceaccounts | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | "" (core) | namespaces, pods, endpoints | get, list, watch, create, update, patch |
| odh-model-controller-role | networking.k8s.io | networkpolicies, ingresses | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | monitoring.coreos.com | servicemonitors, podmonitors | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | authorino.kuadrant.io | authconfigs | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | maistra.io | servicemeshmembers, servicemeshmemberrolls, servicemeshcontrolplanes | get, list, watch, create, update, patch, delete, use |
| odh-model-controller-role | rbac.authorization.k8s.io | clusterrolebindings, rolebindings | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | datasciencecluster.opendatahub.io | datascienceclusters | get, list, watch |
| odh-model-controller-role | dscinitialization.opendatahub.io | dscinitializations | get, list, watch |
| odh-model-controller-leader-election-role | "" (core) | configmaps | get, list, watch, create, update, patch, delete |
| odh-model-controller-leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| odh-model-controller-leader-election-role | "" (core) | events | create, patch |
| prometheus-ns-access | "" (core) | services, endpoints, pods | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-model-controller-role-binding | system (kustomize var) | odh-model-controller-role (ClusterRole) | odh-model-controller |
| odh-model-controller-leader-election-binding | system (kustomize var) | odh-model-controller-leader-election-role (Role) | odh-model-controller |
| prometheus-ns-access | [each isvc namespace] | prometheus-ns-access (ClusterRole) | prometheus-custom (openshift-monitoring) |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| odh-model-controller-webhook-cert | kubernetes.io/tls | TLS certificate for validating webhook server | OpenShift service-ca-operator (serving cert) | Yes (30 days) |
| storage-config | Opaque | Aggregated S3 storage credentials for model access | StorageSecretReconciler | No |
| [data-connection-name] | Opaque | Individual S3 storage credentials (source for storage-config) | ODH Dashboard | No |
| odh-trusted-ca-bundle | Opaque | Custom CA certificates for storage endpoints | Cluster admin | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /validate-serving-knative-dev-v1-service | POST | K8s API Server authentication (client cert/token) | kube-apiserver | ValidatingWebhookConfiguration admission control |
| /metrics | GET | Bearer Token (ServiceAccount) | Application code | Prometheus ServiceMonitor with bearerTokenFile |
| InferenceService endpoints (when auth enabled) | ALL | Bearer Token (JWT) / OAuth | Authorino (external) | AuthConfig CR with security.opendatahub.io/enable-auth label |
| InferenceService endpoints (service mesh) | ALL | mTLS (mutual TLS) | Istio sidecar proxy | PeerAuthentication CR with STRICT mTLS mode |

### Network Policies

| Policy Name | Namespace | Pod Selector | Ingress Rules |
|-------------|-----------|--------------|---------------|
| odh-model-controller | controller namespace | app: odh-model-controller, control-plane: odh-model-controller | Allow TCP/9443 from any (webhook access from API server) |

## Data Flows

### Flow 1: InferenceService Creation and Route Setup (KServe Serverless)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Dashboard | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (user) |
| 2 | KServe Controller | Knative Serving | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | ODH Model Controller | Kubernetes API (watch) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | ODH Model Controller | Kubernetes API (create Route) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | ODH Model Controller | Kubernetes API (create VirtualService) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 6 | ODH Model Controller | Kubernetes API (create PeerAuthentication) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 7 | External Client | OpenShift Router (Route) | 443/TCP | HTTPS | TLS 1.2+ (edge) | None/Bearer (conditional) |
| 8 | OpenShift Router | Istio Ingress Gateway | 443/TCP | HTTPS | mTLS | mTLS |
| 9 | Istio Gateway | Knative Activator/Predictor Pod | 8080/TCP | HTTP | mTLS (mesh internal) | mTLS |
| 10 | Predictor Pod | S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS Access Key |

### Flow 2: Storage Configuration Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | ODH Dashboard | Kubernetes API (create Secret) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | StorageSecretReconciler | Kubernetes API (watch Secrets) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | StorageSecretReconciler | Kubernetes API (list data connections) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | StorageSecretReconciler | Kubernetes API (create/update storage-config) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | KServe/ModelMesh Runtime | Kubernetes API (read storage-config) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 3: Monitoring Configuration

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | MonitoringReconciler | Kubernetes API (create RoleBinding) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | KServe Reconcilers | Kubernetes API (create ServiceMonitor) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Prometheus Operator | Kubernetes API (watch ServiceMonitors) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Prometheus | odh-model-controller-metrics-service | 8080/TCP | HTTPS | TLS (from Service CA) | Bearer Token |
| 5 | Prometheus | InferenceService metrics endpoint | varies/TCP | HTTP/HTTPS | TLS (conditional) | Bearer Token |

### Flow 4: Model Registry Integration

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | ModelRegistryISVCReconciler | Model Registry gRPC API | varies/TCP | gRPC | mTLS | Client Cert |
| 2 | ModelRegistryISVCReconciler | Kubernetes API (annotate InferenceService) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | Watch/Update CRDs | 6443/TCP | HTTPS | TLS 1.2+ | Controller reconciliation loop - watch InferenceServices, create Routes/VirtualServices |
| OpenShift Router | Route CR | varies/TCP | HTTPS | TLS 1.2+ | Expose InferenceService endpoints externally via OpenShift Routes |
| Istio Control Plane | VirtualService/Gateway/PeerAuth CRs | varies/TCP | HTTPS | TLS 1.2+ | Configure service mesh routing, security for serverless InferenceServices |
| Authorino | AuthConfig CR | varies/TCP | HTTPS | TLS 1.2+ | Configure API authentication/authorization for InferenceServices |
| Prometheus | ServiceMonitor/PodMonitor CRs | 8080/TCP | HTTPS | TLS (service CA) | Metrics collection from controller and InferenceService workloads |
| Knative Serving | Webhook validation | 6443/TCP | HTTPS | TLS 1.2+ | Validate Knative Service resources when serverless mode enabled |
| Model Registry | gRPC API | varies/TCP | gRPC | mTLS | Query/update model version metadata and lineage |
| ODH Dashboard | Secret labels | 6443/TCP | HTTPS | TLS 1.2+ | Consume data connection secrets created by dashboard |

## Deployment Configuration

### Container Image

- **Built with**: Konflux (RHOAI build system)
- **Base images**:
  - Builder: `registry.redhat.io/ubi8/go-toolset:1.21`
  - Runtime: `registry.redhat.io/ubi8/ubi-minimal`
- **Registry**: `quay.io/rhoai/odh-model-controller` (production)
- **Security**: Runs as non-root user (UID 2000), no privilege escalation

### Deployment Spec

- **Replicas**: 3 (high availability)
- **Leader Election**: Enabled (single active reconciler)
- **Resource Limits**: CPU 500m, Memory 2Gi
- **Resource Requests**: CPU 10m, Memory 64Mi
- **Pod Anti-Affinity**: Preferred - spread across nodes
- **Probes**:
  - Liveness: HTTP GET /healthz:8081 (15s delay, 20s period)
  - Readiness: HTTP GET /readyz:8081 (5s delay, 10s period)

### Environment Variables

| Variable | Source | Purpose |
|----------|--------|---------|
| POD_NAMESPACE | Field Ref (metadata.namespace) | Determine controller's namespace |
| AUTH_AUDIENCE | ConfigMap: auth-refs | JWT audience for Authorino authentication |
| AUTHORINO_LABEL | ConfigMap: auth-refs | Label selector for Authorino instance |
| CONTROL_PLANE_NAME | ConfigMap: service-mesh-refs | ServiceMesh control plane name (default: data-science-smcp) |
| MESH_NAMESPACE | ConfigMap: service-mesh-refs | ServiceMesh namespace (default: istio-system) |
| MESH_DISABLED | Environment | Disable service mesh integration (default: false) |

### Serving Runtime Templates

The controller deploys the following ServingRuntime templates:

| Runtime | Container | Model Format | Protocol | Recommended Accelerator |
|---------|-----------|--------------|----------|------------------------|
| vLLM | vllm-openai-api-server | vLLM | REST (OpenAI compatible) | nvidia.com/gpu |
| TGIS | text-generation-inference | HuggingFace Text Gen | gRPC | nvidia.com/gpu |
| Caikit-TGIS | caikit-nlp + TGIS | Caikit NLP | gRPC | nvidia.com/gpu |
| Caikit Standalone | caikit-nlp | Caikit NLP | gRPC | nvidia.com/gpu |
| OVMS (KServe) | openvino_model_server | OpenVINO IR, ONNX, TensorFlow | gRPC/REST | CPU/GPU |
| OVMS (ModelMesh) | openvino_model_server | OpenVINO IR, ONNX | gRPC | CPU/GPU |

## Recent Changes

No recent commits found (this is a tagged release checkout at v1.27.0-rhods-527-g5597309 on branch rhoai-2.13).

**Note**: This is a stable release snapshot. For recent development changes, refer to the main development branch or release notes.

## Reconciliation Logic Summary

### InferenceService Reconciliation

The controller determines the deployment mode (ModelMesh vs KServe Serverless vs KServe Raw) and invokes the appropriate reconciler:

**ModelMesh Mode**:
- Creates OpenShift Route for external access
- Creates ServiceAccount for model storage access
- Creates ClusterRoleBinding for ModelMesh integration
- No service mesh integration

**KServe Serverless Mode** (Knative-based):
- Creates ServiceMeshMember to join namespace to mesh
- Creates OpenShift Route pointing to Istio Gateway
- Creates/updates Istio Gateway with TLS configuration
- Creates Istio VirtualService for traffic routing
- Creates Istio PeerAuthentication (STRICT mTLS for predictor pods)
- Creates Istio Telemetry for observability
- Creates NetworkPolicy for ingress control
- Creates AuthConfig for API authentication (when enabled)
- Creates Service for metrics endpoint
- Creates ServiceMonitor for Prometheus scraping
- Creates PodMonitor for Istio proxy metrics
- Creates RoleBinding for Prometheus namespace access
- Creates ConfigMap with Grafana dashboard JSON

**KServe Raw Mode** (standard Kubernetes):
- Creates OpenShift Route for external access
- Minimal additional resources (no mesh integration)

### Storage Configuration Reconciliation

Watches Secrets with labels `opendatahub.io/managed=true` and `opendatahub.io/dashboard=true`:
- Aggregates all data connection secrets in a namespace
- Creates unified `storage-config` secret with JSON-encoded storage configs
- Includes custom CA bundle if `odh-trusted-ca-bundle` ConfigMap exists
- Deletes `storage-config` when no data connections remain

### CA Certificate Reconciliation

Watches ConfigMap `odh-trusted-ca-bundle`:
- Extracts custom CA bundle
- Creates/updates `odh-kserve-custom-ca-bundle` ConfigMap in each namespace with InferenceServices
- Triggers storage-config reconciliation to include CA in storage configurations

### Monitoring Reconciliation

Watches ServingRuntime resources:
- Creates `prometheus-ns-access` RoleBinding in each namespace with ServingRuntimes
- Grants `prometheus-custom` ServiceAccount (from openshift-monitoring) access to scrape metrics
- Enables Prometheus to discover and scrape InferenceService metrics

## Observability

### Metrics Exposed

The controller exposes standard controller-runtime metrics:
- Reconciliation duration/count/errors (per controller)
- Workqueue depth/latency
- Client-go API call duration/errors
- Leader election status
- Go runtime metrics (goroutines, memory, GC)

### Logging

- Structured logging via go-logr/zap
- Log levels: Info (default), Debug (-v 1), Trace (-v 2)
- Context includes: controller name, InferenceService name/namespace, reconciliation phase

### Dashboards

Creates Grafana dashboards (as ConfigMaps) for each InferenceService with:
- Request rate (requests/second)
- Request duration (p50, p95, p99)
- CPU/Memory usage
- Model server specific metrics (varies by runtime)

## Known Limitations

- Requires OpenShift (uses OpenShift Route API and service-ca-operator)
- Service Mesh integration only supports Maistra/OpenShift Service Mesh
- Authentication integration only supports Authorino
- Storage configuration limited to S3-compatible backends
- ServingRuntime templates are statically defined (not dynamically configurable)
- Model Registry integration is optional and requires separate deployment
