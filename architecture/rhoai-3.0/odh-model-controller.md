# Component: odh-model-controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/odh-model-controller.git
- **Version**: 1.27.0-rhods-1087-ga27ba4e
- **Branch**: rhoai-3.0
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Controller/Operator

## Purpose
**Short**: Extends KServe controller to provide OpenShift-native model serving capabilities including ingress, security, and monitoring integration.

**Detailed**: The odh-model-controller is a Kubernetes controller that extends KServe's model serving functionality with OpenShift-specific features. It watches KServe InferenceService, ServingRuntime, and LLMInferenceService resources to automatically provision supporting infrastructure including OpenShift Routes for ingress, network policies for security, RBAC roles and bindings, Prometheus monitoring (ServiceMonitors/PodMonitors), and integration with service mesh components (Istio EnvoyFilters, Kuadrant AuthPolicies). The controller also manages Nvidia NIM (Inference Microservices) accounts through custom CRDs, enabling seamless deployment of NIM-based models. Additionally, it provides webhook-based validation and mutation for model serving resources, KEDA autoscaling integration, and optional model registry synchronization.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| InferenceService Controller | Reconciler | Watches KServe InferenceServices and provisions Routes, NetworkPolicies, RBAC, monitoring |
| ServingRuntime Controller | Reconciler | Manages ServingRuntime lifecycle and supporting resources |
| LLMInferenceService Controller | Reconciler | Handles LLM-specific inference services with Gateway API integration |
| InferenceGraph Controller | Reconciler | Manages multi-model inference graphs |
| NIM Account Controller | Reconciler | Manages Nvidia NIM account integration, API keys, pull secrets, runtime templates |
| Pod Controller | Reconciler | Mutates predictor pods for KServe integration |
| Secret Controller | Reconciler | Manages secrets for model serving workloads |
| ConfigMap Controller | Reconciler | Manages configuration for model serving |
| Webhook Server | Validating/Mutating Webhooks | Validates and mutates Pods, InferenceServices, InferenceGraphs, LLMInferenceServices, NIM Accounts |
| Metrics Server | HTTP Server | Exposes Prometheus metrics on /metrics endpoint |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| nim.opendatahub.io | v1 | Account | Namespaced | Manages Nvidia NIM account credentials, model lists, pull secrets, and runtime templates |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | Bearer Token | Prometheus metrics endpoint (TODO: migrate to HTTPS/8443) |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /validate/* | POST | 9443/TCP | HTTPS | TLS 1.2+ | None | Webhook validation endpoints for Pods, InferenceServices, Accounts |
| /mutate/* | POST | 9443/TCP | HTTPS | TLS 1.2+ | None | Webhook mutation endpoints for Pods, InferenceServices |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| KServe | v0.13+ | Yes | Provides core InferenceService, ServingRuntime CRDs |
| OpenShift Routes | 4.x | Yes | External ingress for model serving endpoints |
| Prometheus Operator | N/A | No | ServiceMonitor/PodMonitor creation for metrics collection |
| Istio Service Mesh | 1.x | No | EnvoyFilter for SSL/TLS passthrough |
| Kuadrant | N/A | No | AuthPolicy for authentication/authorization |
| KEDA | 2.x | No | TriggerAuthentication for autoscaling based on metrics |
| Gateway API | v1 | No | HTTPRoute for LLM inference services |
| Nvidia NGC | N/A | No | NIM account validation and model catalog access |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Model Registry | HTTP API | Optional integration to register deployed models |
| DSC Initialization | CRD Watch | Reads DataScienceCluster and DSCInitialization for platform configuration |
| OpenShift Service CA | Certificate | Provides webhook TLS certificates via service annotation |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-model-controller-metrics-service | ClusterIP | 8080/TCP | 8080 | HTTP | None | Bearer Token | Internal |
| odh-model-controller-webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| N/A | N/A | N/A | N/A | N/A | N/A | N/A | Controller creates Routes for InferenceServices but does not expose itself externally |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token | Watch/reconcile CRDs, create resources |
| Nvidia NGC API | 443/TCP | HTTPS | TLS 1.2+ | API Key | Validate NIM accounts and fetch model catalogs |
| Model Registry | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token | Register deployed models (optional) |
| OpenShift Template API | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token | Process NIM runtime templates |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-model-controller-role | "" | configmaps, secrets, serviceaccounts, services | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | "" | endpoints, namespaces, pods | create, get, list, patch, update, watch |
| odh-model-controller-role | "" | events | create, patch |
| odh-model-controller-role | serving.kserve.io | inferenceservices | get, list, patch, update, watch |
| odh-model-controller-role | serving.kserve.io | inferenceservices/finalizers | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | serving.kserve.io | servingruntimes | create, get, list, update, watch |
| odh-model-controller-role | serving.kserve.io | servingruntimes/finalizers | update |
| odh-model-controller-role | serving.kserve.io | llminferenceservices | get, list, patch, post, update, watch |
| odh-model-controller-role | serving.kserve.io | llminferenceservices/status | get, patch, update |
| odh-model-controller-role | serving.kserve.io | llminferenceservices/finalizers | patch, update |
| odh-model-controller-role | serving.kserve.io | inferencegraphs, llminferenceserviceconfigs | get, list, watch |
| odh-model-controller-role | serving.kserve.io | inferencegraphs/finalizers | update |
| odh-model-controller-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | route.openshift.io | routes/custom-host | create |
| odh-model-controller-role | rbac.authorization.k8s.io | clusterrolebindings, roles, rolebindings | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | networking.k8s.io | ingresses | get, list, watch |
| odh-model-controller-role | monitoring.coreos.com | servicemonitors, podmonitors | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | networking.istio.io | envoyfilters | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | kuadrant.io | authpolicies | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | kuadrant.io | authpolicies/status | get, patch, update |
| odh-model-controller-role | keda.sh | triggerauthentications | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | gateway.networking.k8s.io | gateways | get, list, patch, update, watch |
| odh-model-controller-role | gateway.networking.k8s.io | gateways/finalizers | patch, update |
| odh-model-controller-role | gateway.networking.k8s.io | httproutes | get, list, watch |
| odh-model-controller-role | nim.opendatahub.io | accounts | get, list, patch, update, watch |
| odh-model-controller-role | nim.opendatahub.io | accounts/status | get, list, update, watch |
| odh-model-controller-role | nim.opendatahub.io | accounts/finalizers | update |
| odh-model-controller-role | template.openshift.io | templates | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | datasciencecluster.opendatahub.io | datascienceclusters | get, list, watch |
| odh-model-controller-role | dscinitialization.opendatahub.io | dscinitializations | get, list, watch |
| odh-model-controller-role | metrics.k8s.io | nodes, pods | get, list, watch |
| odh-model-controller-role | config.openshift.io | authentications | get, list, watch |
| leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| leader-election-role | "" | events | create, patch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-model-controller-rolebinding | system | odh-model-controller-role | odh-model-controller |
| leader-election-rolebinding | system | leader-election-role | odh-model-controller |
| odh-model-controller-metrics-auth-rolebinding | system | metrics-auth-role | odh-model-controller |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| odh-model-controller-webhook-cert | kubernetes.io/tls | Webhook server TLS certificate | OpenShift Service CA | Yes |
| NIM API Key Secrets | Opaque | Nvidia NGC API keys for NIM account validation | User/Admin | No |
| Model Pull Secrets | kubernetes.io/dockerconfigjson | Container image pull credentials for NIM models | Controller (from NIM account) | No |
| Managed Secrets | Opaque | InferenceService secrets (labeled opendatahub.io/managed=true) | Controller | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | Bearer Token (ServiceAccount) | kube-rbac-proxy (when secure) | metrics-reader ClusterRole |
| /healthz | GET | None | None | Public (internal only) |
| /readyz | GET | None | None | Public (internal only) |
| Webhook endpoints (/validate/*, /mutate/*) | POST | TLS client auth | Kubernetes API Server | Webhook configuration |
| Kubernetes API (client) | ALL | Bearer Token (ServiceAccount) | Kubernetes API Server | odh-model-controller-role ClusterRole |

## Data Flows

### Flow 1: InferenceService Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/System | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Kubernetes API | Controller (webhook) | 9443/TCP | HTTPS | TLS 1.2+ | TLS client cert |
| 3 | Controller | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 4 | Controller | Kubernetes API (create Route) | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 5 | Controller | Kubernetes API (create NetworkPolicy) | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 6 | Controller | Kubernetes API (create ServiceMonitor) | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |

### Flow 2: NIM Account Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API (create Account CR) | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Kubernetes API | Controller (webhook validation) | 9443/TCP | HTTPS | TLS 1.2+ | TLS client cert |
| 3 | Controller | Nvidia NGC API | 443/TCP | HTTPS | TLS 1.2+ | API Key |
| 4 | Controller | Kubernetes API (create pull secret) | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 5 | Controller | OpenShift Template API | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 6 | Controller | Kubernetes API (update Account status) | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |

### Flow 3: Model Registry Integration (Optional)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Controller | Model Registry API | 443/TCP | HTTPS | TLS 1.2+ (skip verify configurable) | Bearer Token |
| 2 | Controller | Kubernetes API (update InferenceService) | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |

### Flow 4: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | Metrics Service | 8080/TCP | HTTP | None (TODO: TLS) | Bearer Token |
| 2 | Controller | Prometheus endpoint | N/A | N/A | N/A | Exposes metrics |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 443/TCP | HTTPS | TLS 1.2+ | Watch CRDs, create/update resources |
| KServe Controller | CRD Watch | N/A | N/A | N/A | Monitors InferenceService, ServingRuntime CRDs |
| OpenShift Router | Route Creation | N/A | N/A | N/A | Creates Routes for external access to models |
| Prometheus Operator | CRD Creation | N/A | N/A | N/A | Creates ServiceMonitor/PodMonitor for scraping |
| Istio Service Mesh | CRD Creation | N/A | N/A | N/A | Creates EnvoyFilter for SSL passthrough |
| Kuadrant Operator | CRD Creation | N/A | N/A | N/A | Creates AuthPolicy for authentication |
| KEDA Operator | CRD Creation | N/A | N/A | N/A | Creates TriggerAuthentication for autoscaling |
| Gateway API | CRD Watch | N/A | N/A | N/A | Manages HTTPRoute for LLM services |
| Nvidia NGC | REST API | 443/TCP | HTTPS | TLS 1.2+ | Validates NIM accounts, fetches model catalogs |
| Model Registry | REST API | 443/TCP | HTTPS | TLS 1.2+ | Registers deployed models (optional) |

## Deployment Configuration

### Container Image
- **Build**: Dockerfile.konflux (FIPS-compliant Go build with CGO_ENABLED=1)
- **Base Image**: registry.access.redhat.com/ubi9/ubi-minimal
- **User**: 2000 (non-root)
- **Entrypoint**: /manager

### Resource Requirements
- **Requests**: CPU: 10m, Memory: 64Mi
- **Limits**: CPU: 500m, Memory: 2Gi

### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| NIM_STATE | managed | Controls NIM controller: managed/removed |
| KSERVE_STATE | replace | KServe integration state |
| MODELREGISTRY_STATE | replace | Model registry integration state |
| ENABLE_WEBHOOKS | true | Enable/disable webhook server |
| POD_NAMESPACE | (from fieldRef) | Namespace where controller runs |
| MR_SKIP_TLS_VERIFY | false | Skip TLS verification for model registry |

### Runtime Templates

The controller deploys the following pre-configured ServingRuntime templates:

| Template | Purpose | Hardware |
|----------|---------|----------|
| vllm-cuda-template | vLLM runtime for LLMs | NVIDIA GPU (CUDA) |
| vllm-cpu-template | vLLM runtime for LLMs | CPU |
| vllm-rocm-template | vLLM runtime for LLMs | AMD GPU (ROCm) |
| vllm-gaudi-template | vLLM runtime for LLMs | Intel Gaudi |
| vllm-multinode-template | vLLM runtime for distributed LLMs | Multi-node NVIDIA GPU |
| vllm-spyre-x86-template | vLLM runtime with Spyre acceleration | x86_64 CPU |
| vllm-spyre-s390x-template | vLLM runtime with Spyre acceleration | IBM s390x |
| ovms-kserve-template | OpenVINO Model Server | CPU/GPU |
| hf-detector-template | HuggingFace model detector | CPU |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| a27ba4e | 2025 | - Updated UBI minimal base image digest to bb08f23 |
| 5a624ce | 2025 | - Updated UBI minimal base image digest to 90bd85d |
| 92918b7 | 2025 | - Updated Konflux pipeline references |
| 1094d97 | 2025 | - Updated Konflux pipeline references |
| 2cf51e0 | 2025 | - Updated Konflux pipeline references |
| 007d7bc | 2025 | - Updated Konflux pipeline references |
| 8fbf9d8 | 2025 | - Updated Konflux pipeline references |
| 2b8a0df | 2025 | - Updated Konflux pipeline references |
| 18f72d8 | 2025 | - Updated Konflux pipeline references |
| 81ed0df | 2025 | - Updated Konflux pipeline references |
| 0ed99be | 2025 | - Updated Konflux pipeline references |
| 2f171fb | 2025 | - Updated Konflux pipeline references |
| f3fc3ff | 2025 | - Updated Konflux pipeline references |

## Controller Behavior

### Reconciliation Logic

The controller implements reconciliation loops for:

1. **InferenceService**: Creates/updates Routes, NetworkPolicies, RBAC, ServiceMonitors, PodMonitors, KEDA TriggerAuthentications
2. **ServingRuntime**: Manages runtime lifecycle and finalizers
3. **LLMInferenceService**: Creates AuthPolicies, EnvoyFilters, HTTPRoutes for Gateway API
4. **InferenceGraph**: Manages multi-model graph dependencies and finalizers
5. **NIM Account**: Validates NGC credentials, creates pull secrets, processes runtime templates, syncs model catalogs
6. **Pods**: Mutates predictor pods with labels and annotations
7. **Secrets/ConfigMaps**: Watches for changes to managed resources (opendatahub.io/managed=true)

### Webhook Operations

| Resource | Operation | Purpose |
|----------|-----------|---------|
| Pod | Mutate | Inject sidecar configurations for KServe predictor pods |
| InferenceService | Validate/Mutate | Enforce policies, set defaults |
| InferenceGraph | Validate/Mutate | Validate graph structure, set defaults |
| LLMInferenceService | Validate | Enforce tier configurations and quotas |
| NIM Account | Validate | Verify NGC API key secret exists |

## Notes

- The controller uses label-based caching for Secrets (`opendatahub.io/managed=true`) and Pods (`component=predictor`) to reduce memory footprint
- Metrics endpoint currently uses HTTP on port 8080 - migration to HTTPS on 8443 is planned
- Model Registry integration is optional and controlled via MODELREGISTRY_STATE environment variable
- NIM functionality can be completely disabled by setting NIM_STATE=removed
- The controller supports both Istio-based (EnvoyFilter) and Gateway API-based (HTTPRoute) ingress patterns
- All builds are FIPS-compliant using Go strict FIPS runtime mode
- Leader election is enabled by default to support high-availability deployments
