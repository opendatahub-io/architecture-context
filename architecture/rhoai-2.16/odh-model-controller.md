# Component: ODH Model Controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/odh-model-controller.git
- **Version**: v-2160-184-g3a90bd4
- **Branch**: rhoai-2.16
- **Distribution**: RHOAI
- **Languages**: Go 1.23.0
- **Deployment Type**: Kubernetes Operator
- **Build System**: Konflux (Dockerfile.konflux)

## Purpose
**Short**: Extends KServe/ModelMesh functionality with OpenShift-native integrations for model serving.

**Detailed**: The ODH Model Controller is a Kubernetes operator that watches InferenceService custom resources and extends the KServe and ModelMesh-serving controllers with OpenShift-specific capabilities. It eliminates manual steps when deploying machine learning models by automatically configuring OpenShift Routes, Istio service mesh integration, authentication via Authorino, monitoring with Prometheus, and storage configurations. The controller also manages NVIDIA NIM (NVIDIA Inference Microservices) account integration for deploying proprietary NVIDIA models. It supports both KServe Serverless (Knative), KServe RawDeployment, and ModelMesh deployment modes, automatically reconciling the necessary networking, RBAC, and observability resources for each mode. The controller acts as a critical bridge between upstream KServe and the OpenShift/RHOAI platform.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| InferenceService Controller | Reconciler | Watches KServe InferenceServices and delegates to mode-specific reconcilers (ModelMesh, KServe Serverless, KServe Raw) |
| ModelMesh Reconciler | Sub-Reconciler | Manages Routes, ServiceAccounts, and ClusterRoleBindings for ModelMesh deployments |
| KServe Serverless Reconciler | Sub-Reconciler | Manages Istio Gateways, VirtualServices, AuthConfigs, NetworkPolicies, and PeerAuthentication for serverless inference |
| KServe Raw Reconciler | Sub-Reconciler | Manages Routes for raw KServe deployments without service mesh |
| NIM Account Controller | Reconciler | Manages NVIDIA NIM accounts, creates Templates, ConfigMaps, and Secrets for NIM model deployments |
| Storage Secret Controller | Reconciler | Aggregates data connection secrets into a unified storage-config secret for KServe/ModelMesh |
| Custom CA Cert Controller | Reconciler | Synchronizes ODH global CA certificates to KServe-specific ConfigMaps |
| Monitoring Controller | Reconciler | Creates RoleBindings to grant Prometheus access to namespaces with InferenceServices |
| Model Registry Controller | Reconciler | (Optional) Synchronizes InferenceServices with Model Registry metadata |
| Knative Service Webhook | Validating Webhook | Validates Knative Service resources for KServe Serverless deployments |
| NIM Account Webhook | Validating Webhook | Validates NIM Account custom resources |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| nim.opendatahub.io | v1 | Account | Namespaced | Manages NVIDIA NIM account credentials and auto-generates ServingRuntime templates for NIM models |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | Bearer Token | Prometheus metrics scraping |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /validate-serving-knative-dev-v1-service | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Knative Service validation webhook |
| /validate-nim-opendatahub-io-v1-account | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | NIM Account validation webhook |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | No gRPC services exposed |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.29+ | Yes | Cluster orchestration platform |
| KServe | 0.12.1 | Yes | Core model serving platform (InferenceService CRD provider) |
| Knative Serving | 0.39.3 | Conditional | Required for KServe Serverless mode |
| Istio | 1.21.5 | Conditional | Service mesh for KServe Serverless mode |
| Authorino | 0.15.0 | Conditional | Token-based authentication for InferenceServices |
| OpenShift Routes | 3.9.0+ | Yes | External ingress via OpenShift Router |
| Prometheus Operator | 0.64.1 | No | Monitoring and metrics collection |
| cert-manager | Latest | No | TLS certificate provisioning for webhooks (can use OpenShift service-ca) |
| ModelMesh | Latest | Conditional | Multi-model serving runtime |
| Model Registry | 0.1.1 | No | ML model metadata and lineage tracking |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| DataScienceCluster | CRD Watch | Determines if KServe service mesh is enabled in the platform |
| DSCInitialization | CRD Watch | Reads platform initialization configuration |
| KServe Operator | CRD Interaction | Watches and updates InferenceServices and ServingRuntimes |
| ModelMesh Operator | CRD Interaction | Watches InferenceServices using ModelMesh mode |
| Service Mesh (Maistra) | CRD Interaction | Creates ServiceMeshMembers, reads ServiceMeshMemberRolls |
| Dashboard | Label Convention | Watches secrets labeled by ODH Dashboard for data connections |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-model-controller-webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | mTLS (K8s API Server) | Internal (Webhooks) |
| odh-model-controller-metrics-service | ClusterIP | 8080/TCP | 8080 | HTTP | None | Bearer Token | Internal (Prometheus) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| N/A (Managed by controller) | OpenShift Route | Dynamic (per InferenceService) | 443/TCP | HTTPS | TLS 1.2+ | Edge Termination | External |
| N/A (Managed by controller) | Istio Gateway | Dynamic (per InferenceService) | 443/TCP | HTTPS | TLS 1.3 | SIMPLE/MUTUAL | External (Service Mesh) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch CRDs, create/update resources |
| NGC API (nvcr.io) | 443/TCP | HTTPS | TLS 1.2+ | NGC API Key | NIM account validation and image pull secret creation |
| S3-compatible storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM or Access Keys | Model artifact storage (via InferenceService) |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-model-controller-role | "" | configmaps, secrets, serviceaccounts | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | "" | namespaces, pods, endpoints | create, get, list, patch, update, watch |
| odh-model-controller-role | "" | services | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | serving.kserve.io | inferenceservices | get, list, update, watch |
| odh-model-controller-role | serving.kserve.io | inferenceservices/finalizers | get, list, update, watch |
| odh-model-controller-role | serving.kserve.io | servingruntimes | create, get, list, update, watch |
| odh-model-controller-role | serving.kserve.io | servingruntimes/finalizers | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | networking.istio.io | virtualservices | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | networking.istio.io | virtualservices/finalizers | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | networking.istio.io | gateways | get, list, patch, update, watch |
| odh-model-controller-role | security.istio.io | peerauthentications | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | security.istio.io | authorizationpolicies | get, list |
| odh-model-controller-role | telemetry.istio.io | telemetries | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | maistra.io | servicemeshmembers | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | maistra.io | servicemeshmemberrolls | get, list, watch |
| odh-model-controller-role | maistra.io | servicemeshcontrolplanes | get, list, use, watch |
| odh-model-controller-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | route.openshift.io | routes/custom-host | create |
| odh-model-controller-role | rbac.authorization.k8s.io | clusterrolebindings, rolebindings | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | networking.k8s.io | ingresses | get, list, watch |
| odh-model-controller-role | extensions | ingresses | get, list, watch |
| odh-model-controller-role | monitoring.coreos.com | servicemonitors, podmonitors | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | authorino.kuadrant.io | authconfigs | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | datasciencecluster.opendatahub.io | datascienceclusters | get, list, watch |
| odh-model-controller-role | dscinitialization.opendatahub.io | dscinitializations | get, list, watch |
| odh-model-controller-role | nim.opendatahub.io | accounts | get, list, update, watch |
| odh-model-controller-role | nim.opendatahub.io | accounts/status | get, list, update, watch |
| odh-model-controller-role | nim.opendatahub.io | accounts/finalizers | update |
| odh-model-controller-role | template.openshift.io | templates | create, delete, get, list, update, watch |
| odh-model-controller-leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| odh-model-controller-leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| odh-model-controller-leader-election-role | "" | events | create, patch |
| prometheus-ns-access | "" | services, endpoints, pods | get, list, watch |
| kserve-prometheus-metrics-reader | "" | services | get, list |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-model-controller-role-binding | All (ClusterRoleBinding) | odh-model-controller-role | odh-model-controller |
| odh-model-controller-leader-election-rolebinding | Controller Namespace | odh-model-controller-leader-election-role | odh-model-controller |
| prometheus-ns-access | Per InferenceService NS | prometheus-ns-access (ClusterRole) | prometheus-custom (openshift-monitoring) |
| auth-delegator | Controller Namespace | system:auth-delegator | odh-model-controller |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| odh-model-controller-webhook-cert | kubernetes.io/tls | Webhook server TLS certificate | OpenShift service-ca-operator | Yes |
| storage-config | Opaque | Aggregated storage credentials for KServe/ModelMesh | Storage Secret Controller | No (reconciled on change) |
| NIM pull secrets | kubernetes.io/dockerconfigjson | NVIDIA NGC image pull credentials | NIM Account Controller | No |
| Data connection secrets | Opaque | S3-compatible storage credentials | ODH Dashboard (user-created) | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | Bearer Token (ServiceAccount) | Kubernetes RBAC | Read-only metrics access |
| /healthz, /readyz | GET | None | N/A | Public (internal network only) |
| Webhook endpoints | POST | mTLS (Kubernetes API Server) | Kubernetes API Server | ValidatingWebhookConfiguration admission control |
| InferenceService endpoints | ALL | Bearer Token (JWT) or mTLS | Authorino + Istio | Per-namespace AuthConfig (when service mesh enabled) |

## Data Flows

### Flow 1: InferenceService Creation (KServe Serverless Mode)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Client | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (kubectl/oc) |
| 2 | Kubernetes API Server | odh-model-controller | N/A (watch) | Internal | N/A | ServiceAccount Token |
| 3 | odh-model-controller | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | odh-model-controller | Istio Control Plane | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | odh-model-controller | Authorino | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: NIM Account Provisioning

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Kubernetes API Server | odh-model-controller (webhook) | 9443/TCP | HTTPS | TLS 1.2+ | mTLS |
| 3 | odh-model-controller | NGC API | 443/TCP | HTTPS | TLS 1.2+ | NGC API Key |
| 4 | odh-model-controller | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 3: Storage Configuration Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | ODH Dashboard | 443/TCP | HTTPS | TLS 1.2+ | OAuth Token |
| 2 | ODH Dashboard | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Kubernetes API Server | odh-model-controller | N/A (watch) | Internal | N/A | ServiceAccount Token |
| 4 | odh-model-controller | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 4: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | odh-model-controller-metrics-service | 8080/TCP | HTTP | None | Bearer Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| KServe Controller | CRD Watch/Update | 443/TCP | HTTPS | TLS 1.2+ | Watch InferenceServices, update status and finalizers |
| Istio Control Plane | CRD Create/Update | 443/TCP | HTTPS | TLS 1.2+ | Create VirtualServices, Gateways, PeerAuthentications, Telemetries |
| Authorino | CRD Create/Update | 443/TCP | HTTPS | TLS 1.2+ | Create AuthConfigs for token-based authentication |
| OpenShift Router | CRD Create/Update | 443/TCP | HTTPS | TLS 1.2+ | Create Routes for external access |
| Service Mesh (Maistra) | CRD Create/Update | 443/TCP | HTTPS | TLS 1.2+ | Create ServiceMeshMembers to add namespaces to mesh |
| Prometheus | Metrics Scrape | 8080/TCP | HTTP | None | Scrape controller metrics via ServiceMonitor |
| ODH Dashboard | Label Convention | 443/TCP | HTTPS | TLS 1.2+ | Watch secrets with opendatahub.io/dashboard=true label |
| Model Registry | gRPC API | 9090/TCP | gRPC | mTLS | (Optional) Sync InferenceService metadata |
| NGC API | REST API | 443/TCP | HTTPS | TLS 1.2+ | Validate NIM accounts and fetch model catalog |

## Deployment Configuration

### Container Image
- **Build**: Multi-stage build with UBI9 Go toolset builder and UBI8 minimal runtime
- **Base Images**:
  - Builder: `registry.redhat.io/ubi9/go-toolset:1.25.5`
  - Runtime: `registry.redhat.io/ubi8/ubi-minimal`
- **User**: Non-root (UID 2000)
- **Entrypoint**: `/manager`

### Resource Requirements
- **Requests**: CPU 10m, Memory 64Mi
- **Limits**: CPU 500m, Memory 2Gi

### Probes
- **Liveness**: HTTP GET /healthz:8081 (initial 15s, period 20s)
- **Readiness**: HTTP GET /readyz:8081 (initial 5s, period 10s)

### Environment Variables
- **POD_NAMESPACE**: Controller's namespace
- **AUTH_AUDIENCE**: Authorino audience (from auth-refs ConfigMap)
- **AUTHORINO_LABEL**: Authorino label selector (from auth-refs ConfigMap)
- **CONTROL_PLANE_NAME**: Service mesh control plane name (from service-mesh-refs ConfigMap)
- **MESH_NAMESPACE**: Service mesh namespace (from service-mesh-refs ConfigMap)
- **MESH_DISABLED**: Feature flag to disable service mesh integration

### Command-line Flags
- `--leader-elect`: Enable leader election (default: true in production)
- `--metrics-bind-address`: Metrics server address (default: :8080)
- `--health-probe-bind-address`: Health probe address (default: :8081)
- `--monitoring-namespace`: Prometheus namespace for RoleBinding creation
- `--model-registry-inference-reconcile`: Enable Model Registry integration

### Network Policy
- **Ingress**: Allow TCP/9443 to pods with control-plane=odh-model-controller label
- **Egress**: Unrestricted (default)

## Runtime Templates Managed

| Template Name | Purpose | Container Port |
|---------------|---------|----------------|
| caikit-standalone | IBM Caikit standalone runtime | 8080/TCP |
| caikit-tgis | IBM Caikit with TGIS backend | 8080/TCP |
| ovms-kserve | OpenVINO Model Server (KServe mode) | N/A (defined in template) |
| ovms-mm | OpenVINO Model Server (ModelMesh mode) | N/A (defined in template) |
| tgis | Text Generation Inference Server | N/A (defined in template) |
| vllm | vLLM inference engine | N/A (defined in template) |
| vllm-gaudi | vLLM for Intel Gaudi accelerators | N/A (defined in template) |
| vllm-multinode | vLLM multi-node deployment | N/A (defined in template) |
| vllm-rocm | vLLM for AMD ROCm GPUs | N/A (defined in template) |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| v-2160-184-g3a90bd4 | 2026-03 | - Update vllm-gaudi runtime to ac6de57<br>- Add PipelineRun configuration for RHOAI 2.16<br>- Sync PipelineRuns with konflux-central |
| Ongoing | 2025-12 to 2026-03 | - Regular Dockerfile digest updates from Konflux dependency automation<br>- UBI9 Go toolset updates (1.25.5)<br>- Automated dependency maintenance via Konflux pipelines |
| Previous | 2025-11 | - Added pull request template for contributions |

## Known Limitations

1. **Service Mesh Dependency**: KServe Serverless mode requires Istio/Maistra service mesh. Cannot function without it.
2. **OpenShift-Specific**: Routes and service-ca integration are OpenShift-specific and won't work on vanilla Kubernetes.
3. **Single Controller Instance**: Leader election ensures only one active controller, limiting horizontal scalability.
4. **Secret Label Convention**: Storage secret reconciliation depends on specific labels (`opendatahub.io/managed=true`, `opendatahub.io/dashboard=true`) set by ODH Dashboard.
5. **NGC API Dependency**: NIM account validation requires outbound access to NVIDIA NGC API.

## Future Considerations

1. **Multi-tenancy**: Consider namespace-scoped controller deployments for better isolation.
2. **Webhook HA**: Single webhook pod could be a bottleneck; consider multi-replica with proper cert management.
3. **Observability**: Add OpenTelemetry tracing for better debugging of reconciliation loops.
4. **Storage Provider Abstraction**: Currently tightly coupled to S3-compatible storage; consider supporting additional backends.
5. **Validation Enhancement**: Expand webhook validation to catch more configuration errors before reconciliation.
