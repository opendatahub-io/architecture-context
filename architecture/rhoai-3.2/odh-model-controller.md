# Component: ODH Model Controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/odh-model-controller.git
- **Version**: v1.27.0-rhods-1125-gd4a76a6
- **Branch**: rhoai-3.2
- **Distribution**: RHOAI
- **Languages**: Go 1.24.4
- **Deployment Type**: Kubernetes Operator (Controller)

## Purpose
**Short**: Extends KServe functionality with OpenShift-specific integrations for model serving workloads.

**Detailed**: The ODH Model Controller is a Kubernetes operator built with Kubebuilder that enhances KServe's model serving capabilities by integrating deeply with OpenShift and RHOAI platform features. It watches KServe InferenceService, ServingRuntime, and InferenceGraph resources to automatically provision supporting infrastructure including OpenShift Routes for ingress, NetworkPolicies for security, monitoring resources (ServiceMonitors/PodMonitors), and authentication policies via Kuadrant.

The controller eliminates manual configuration steps for users deploying ML models by orchestrating the creation of Routes, RBAC bindings, network policies, Istio EnvoyFilters, and autoscaling resources. It also manages NVIDIA NIM (NVIDIA Inference Microservices) integration through custom Account resources, enabling streamlined deployment of optimized inference containers. The controller supports integration with Model Registry for tracking deployed models and implements webhooks for validating and mutating inference workloads.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| InferenceService Controller | Reconciler | Manages KServe InferenceServices, creates Routes, NetworkPolicies, ServiceMonitors, RBAC, and integrates with Model Registry |
| ServingRuntime Controller | Reconciler | Manages KServe ServingRuntime resources and associated infrastructure |
| LLMInferenceService Controller | Reconciler | Manages LLM-specific inference services with AuthPolicies and EnvoyFilters for API routing |
| NIM Account Controller | Reconciler | Manages NVIDIA NIM account integration, validates API keys, provisions pull secrets and runtime templates |
| InferenceGraph Controller | Reconciler | Manages KServe InferenceGraph resources for multi-model inference pipelines |
| Secret Controller | Reconciler | Watches secrets with label `opendatahub.io/managed: true` for lifecycle management |
| ConfigMap Controller | Reconciler | Watches and manages model controller configuration |
| Pod Controller | Reconciler | Handles pod mutations for predictor workloads (label: `component: predictor`) |
| Admission Webhooks | Validating/Mutating | Validates and defaults Pod, InferenceService, InferenceGraph, LLMInferenceService, NIM Account resources |
| Metrics Exporter | HTTP Server | Exports Prometheus metrics on controller operations |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| nim.opendatahub.io | v1 | Account | Namespaced | Manages NVIDIA NIM account integration, API key validation, model lists, and pull secret generation |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | Bearer Token (planned) | Prometheus metrics endpoint for controller runtime metrics |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /mutate--v1-pod | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API | Mutating webhook for Pod resources with predictor label |
| /mutate-serving-kserve-io-v1beta1-inferenceservice | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API | Mutating webhook for InferenceService defaulting |
| /validate-serving-kserve-io-v1beta1-inferenceservice | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API | Validating webhook for InferenceService validation |
| /mutate-serving-kserve-io-v1alpha1-inferencegraph | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API | Mutating webhook for InferenceGraph defaulting |
| /validate-serving-kserve-io-v1alpha1-inferencegraph | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API | Validating webhook for InferenceGraph validation |
| /validate-nim-opendatahub-io-v1-account | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API | Validating webhook for NIM Account resources |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | No gRPC services exposed |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| KServe | v0.15.0 | Yes | Core model serving platform providing InferenceService, ServingRuntime CRDs |
| Istio | v1.26.4 | Yes | Service mesh for EnvoyFilter-based traffic routing and mTLS |
| Kuadrant Operator | v1.2.0 | Yes | Provides AuthPolicy CRD for authentication/authorization |
| Authorino Operator | v0.11.1 | Yes | Executes authorization policies defined by Kuadrant AuthPolicies |
| KEDA | v2.16.1 | Optional | Autoscaling for inference workloads via TriggerAuthentication resources |
| Prometheus Operator | v0.76.2 | Yes | Monitoring via ServiceMonitor and PodMonitor CRDs |
| OpenShift API | 4.x | Yes | Route CRD for external ingress, Template for runtime definitions |
| Gateway API | v1.2.1 | Yes | HTTPRoute and Gateway resources for advanced routing |
| Knative Serving | v0.0.0-20250117084104 | Yes | Knative Service resources used by KServe serverless mode |
| Model Registry | v0.2.19 | Optional | Tracks deployed models when MODELREGISTRY_STATE=managed |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KServe Operator | Watches CRDs | Primary dependency - watches InferenceService/ServingRuntime/InferenceGraph CRDs created by KServe |
| DSC/DSCI | Watches CRDs | Reads DataScienceCluster and DSCInitialization resources to determine platform configuration |
| Model Registry | HTTP API | Optional integration to register deployed InferenceServices when enabled via MODELREGISTRY_STATE env var |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-model-controller-metrics-service | ClusterIP | 8080/TCP | 8080 | HTTP | None | Bearer Token (planned) | Internal |
| odh-model-controller-webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ (service-ca cert) | mTLS (client cert) | Internal (Kubernetes API only) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| Created Routes (per ISVC) | OpenShift Route | Dynamic (per InferenceService) | 443/TCP | HTTPS | TLS 1.2+ | Edge/Reencrypt | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) | Controller operations, watch CRDs, create/update resources |
| Model Registry API (optional) | 443/TCP | HTTPS | TLS 1.2+ (skip verify option) | Bearer Token | Register deployed InferenceServices with model registry |
| NVIDIA NGC API (NIM) | 443/TCP | HTTPS | TLS 1.2+ | API Key | Validate NIM accounts, fetch model lists, generate pull secrets |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-model-controller-role | "" | configmaps, secrets, serviceaccounts, services | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | "" | endpoints, namespaces, pods | create, get, list, patch, update, watch |
| odh-model-controller-role | "" | events | create, patch |
| odh-model-controller-role | serving.kserve.io | inferenceservices, inferenceservices/finalizers | get, list, patch, update, watch, create, delete |
| odh-model-controller-role | serving.kserve.io | servingruntimes, servingruntimes/finalizers | create, get, list, update, watch |
| odh-model-controller-role | serving.kserve.io | inferencegraphs, inferencegraphs/finalizers | get, list, watch, update |
| odh-model-controller-role | serving.kserve.io | llminferenceservices, llminferenceservices/finalizers, llminferenceservices/status | get, list, patch, post, update, watch |
| odh-model-controller-role | route.openshift.io | routes, routes/custom-host | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | rbac.authorization.k8s.io | clusterrolebindings, rolebindings, roles | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | networking.k8s.io | ingresses | get, list, watch |
| odh-model-controller-role | networking.istio.io | envoyfilters | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | kuadrant.io | authpolicies, authpolicies/status | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | kuadrant.io | kuadrants | get, list, watch |
| odh-model-controller-role | monitoring.coreos.com | servicemonitors, podmonitors | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | keda.sh | triggerauthentications | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | nim.opendatahub.io | accounts, accounts/finalizers, accounts/status | get, list, patch, update, watch |
| odh-model-controller-role | datasciencecluster.opendatahub.io | datascienceclusters | get, list, watch |
| odh-model-controller-role | dscinitialization.opendatahub.io | dscinitializations | get, list, watch |
| odh-model-controller-role | gateway.networking.k8s.io | gateways, gateways/finalizers, httproutes | get, list, patch, update, watch |
| odh-model-controller-role | template.openshift.io | templates | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | config.openshift.io | authentications | get, list, watch |
| odh-model-controller-role | operator.authorino.kuadrant.io | authorinos | get, list, watch |
| odh-model-controller-role | metrics.k8s.io | nodes, pods | get, list, watch |
| odh-model-controller-leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| odh-model-controller-leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| odh-model-controller-leader-election-role | "" | events | create, patch |
| kserve-prometheus-metrics | "" | namespaces, pods, services, endpoints | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-model-controller-rolebinding | opendatahub | odh-model-controller-role (ClusterRole) | odh-model-controller |
| odh-model-controller-leader-election-rolebinding | opendatahub | odh-model-controller-leader-election-role | odh-model-controller |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| odh-model-controller-webhook-cert | kubernetes.io/tls | TLS certificate for webhook server | OpenShift service-ca-operator | Yes (service-ca) |
| NGC Pull Secrets (NIM) | kubernetes.io/dockerconfigjson | Image pull secrets for NVIDIA NIM containers | NIM Account Controller | No (managed lifecycle) |
| User-provided secrets | Opaque | Storage credentials, API tokens for model serving | Users/External | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | Bearer Token (ServiceAccount JWT) | Kubernetes RBAC | kube-rbac-proxy (planned) |
| /healthz, /readyz | GET | None | Controller Manager | Open (localhost only) |
| Webhook endpoints | POST | mTLS (client cert) | Kubernetes API Server | API server validates client cert |
| Created InferenceServices | GET, POST | Bearer Token / AuthPolicy | Kuadrant Authorino | User-defined or anonymous via annotations |

## Data Flows

### Flow 1: InferenceService Creation and Route Provisioning

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User (kubectl) | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | Bearer Token (user) |
| 2 | Kubernetes API | Controller (watch) | N/A | In-process | N/A | ServiceAccount Token |
| 3 | Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) |
| 4 | Controller | Model Registry (optional) | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 5 | External User | Route (InferenceService) | 443/TCP | HTTPS | TLS 1.2+ | AuthPolicy (varies) |

### Flow 2: NIM Account Validation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API (create Account CR) | 6443/TCP | HTTPS | TLS 1.3 | Bearer Token (user) |
| 2 | Kubernetes API | Webhook (validation) | 9443/TCP | HTTPS | TLS 1.2+ (service-ca) | mTLS (client cert) |
| 3 | Webhook | Kubernetes API (allow/deny) | N/A | Response | N/A | N/A |
| 4 | Account Controller | NVIDIA NGC API | 443/TCP | HTTPS | TLS 1.2+ | NGC API Key |
| 5 | Account Controller | Kubernetes API (create Secret/ConfigMap) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) |

### Flow 3: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | ServiceMonitor (discovers target) | N/A | N/A | N/A | N/A |
| 2 | Prometheus | Metrics Service | 8080/TCP | HTTP | None | Bearer Token (planned) |
| 3 | Metrics Service | Controller /metrics | 8080/TCP | HTTP | None | None (internal) |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| KServe Controller | CRD Watch | N/A | Kubernetes API | TLS 1.2+ | Watches InferenceService/ServingRuntime CRDs created by KServe, adds finalizers |
| OpenShift Router | Route Creation | 80/TCP, 443/TCP | HTTP/HTTPS | TLS 1.2+ | Creates Routes for InferenceService external access |
| Istio Pilot | EnvoyFilter | N/A | xDS (gRPC) | mTLS | Creates EnvoyFilters for LLM routing and request transformation |
| Kuadrant Authorino | AuthPolicy | N/A | Kubernetes API | TLS 1.2+ | Creates AuthPolicies for InferenceService authentication |
| KEDA Operator | TriggerAuthentication | N/A | Kubernetes API | TLS 1.2+ | Creates autoscaling triggers for InferenceServices |
| Prometheus | ServiceMonitor/PodMonitor | 8080/TCP | HTTP | None | Creates monitoring resources for InferenceService metrics |
| Model Registry | HTTP API | 443/TCP | HTTPS | TLS 1.2+ | Registers deployed InferenceServices (when enabled) |
| NVIDIA NGC | HTTPS API | 443/TCP | HTTPS | TLS 1.2+ | Validates NIM accounts, fetches model lists and pull secrets |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| d4a76a6 | 2025-03 | - Update UBI minimal base image digest to 759f5f4 |
| b3be164 | 2025-03 | - Update UBI minimal base image digest to ecd4751 |
| 4d2069f | 2025-02 | - Update UBI minimal base image digest to bb08f23 |
| 269600a | 2025-01 | - Update UBI minimal base image digest to 90bd85d |
| adfdf86 | 2024-12 | - Update Konflux pipeline references |
| f6dddc4 | 2024-12 | - Update Konflux pipeline references |
| 7d3d3a5 | 2024-12 | - Update Konflux pipeline references |
| ef186fd | 2024-12 | - Update Konflux pipeline references |
| 607aea9 | 2024-12 | - Update Konflux pipeline references |
| eeefd1b | 2024-12 | - Update Konflux pipeline references |
| 80fea2f | 2024-11 | - Add closing parenthesis fix |
| f68c0af | 2024-11 | - Rollback RHOAI OVMS to 2025.3 version |
| 4eb1977 | 2024-11 | - Revert MLServer ServingRuntime template addition |

## Deployment Configuration

### Container Build

- **Build System**: Konflux (RHOAI production builds)
- **Dockerfile**: `Dockerfile.konflux` (primary), `Containerfile` (development)
- **Base Images**:
  - Builder: `registry.access.redhat.com/ubi9/go-toolset:1.24` (FIPS-enabled Go build)
  - Runtime: `registry.access.redhat.com/ubi9/ubi-minimal` (minimal UBI 9)
- **Build Flags**: `CGO_ENABLED=1`, `GOEXPERIMENT=strictfipsruntime`, `-tags strictfipsruntime` (FIPS compliance)
- **User**: Non-root (UID 2000)

### Runtime Configuration

| Environment Variable | Purpose | Default | Managed By |
|---------------------|---------|---------|------------|
| NIM_STATE | Enable/disable NIM account reconciliation | managed | DSC/DSCI |
| KSERVE_STATE | Enable/disable KServe integration | managed | DSC/DSCI |
| MODELREGISTRY_STATE | Enable/disable Model Registry integration | (empty) | DSC/DSCI |
| MAAS_NAMESPACE | Model-as-a-Service namespace | (empty) | DSC/DSCI |
| ENABLE_WEBHOOKS | Enable/disable admission webhooks | true | Deployment config |
| POD_NAMESPACE | Controller pod namespace | (fieldRef) | Kubernetes |
| MR_SKIP_TLS_VERIFY | Skip TLS verification for Model Registry | false | Deployment config |

### Resource Requirements

| Resource | Requests | Limits |
|----------|----------|--------|
| CPU | 10m | 500m |
| Memory | 64Mi | 2Gi |

### Probes

| Probe Type | Path | Port | Initial Delay | Period |
|-----------|------|------|---------------|--------|
| Liveness | /healthz | 8081 | 15s | 20s |
| Readiness | /readyz | 8081 | 5s | 10s |

## Managed Resources

The controller creates and manages the following resources for each InferenceService:

### Per-InferenceService Resources

| Resource Type | Naming Pattern | Purpose |
|--------------|----------------|---------|
| Route | `<isvc-name>` | External HTTPS ingress for model endpoint |
| NetworkPolicy | `allow-from-openshift-ingress` | Allow traffic from OpenShift Router |
| ServiceAccount | `<isvc-name>-sa` | Service account for predictor pods |
| Role | `<isvc-name>-role` | Namespace-scoped permissions for model serving |
| RoleBinding | `<isvc-name>-rolebinding` | Binds role to service account |
| ServiceMonitor | `<isvc-name>-metrics` | Prometheus metrics scraping config |
| PodMonitor | `<isvc-name>-pod-metrics` | Pod-level metrics collection |

### Per-LLMInferenceService Resources

| Resource Type | Naming Pattern | Purpose |
|--------------|----------------|---------|
| AuthPolicy | `<llm-isvc-name>-auth` | Kuadrant authentication/authorization policy |
| EnvoyFilter | `<llm-isvc-name>-filter` | Istio routing and request transformation |
| HTTPRoute | `<llm-isvc-name>-route` | Gateway API routing configuration |

### Per-Namespace Resources (KServe)

| Resource Type | Name | Purpose |
|--------------|------|---------|
| ClusterRoleBinding | `<namespace>-kserve-prometheus-k8s` | Binds prometheus access to namespace |

### NIM Account Resources

| Resource Type | Naming Pattern | Purpose |
|--------------|----------------|---------|
| ConfigMap | `<account-name>-nim-config` | NIM model configuration data |
| Secret | `<account-name>-nim-pull-secret` | Docker registry credentials for NIM images |
| Template | `<account-name>-runtime-template` | OpenShift Template for NIM ServingRuntime |

## Runtime Templates

The controller includes pre-configured ServingRuntime templates for:

| Runtime | Template File | Container Image Parameter | GPU Support |
|---------|--------------|---------------------------|-------------|
| OVMS (KServe) | ovms-kserve-template.yaml | ovms-image | Intel CPU/GPU |
| vLLM CUDA | vllm-cuda-template.yaml | vllm-cuda-image | NVIDIA CUDA |
| vLLM ROCm | vllm-rocm-template.yaml | vllm-rocm-image | AMD ROCm |
| vLLM Gaudi | vllm-gaudi-template.yaml | vllm-gaudi-image | Intel Gaudi |
| vLLM CPU | vllm-cpu-template.yaml | vllm-cpu-image | x86_64 CPU |
| vLLM Spyre x86 | vllm-spyre-x86-template.yaml | vllm-spyre-x86-image | IBM Spyre x86 |
| vLLM Spyre s390x | vllm-spyre-s390x-template.yaml | vllm-spyre-s390x-image | IBM Spyre s390x |
| vLLM Multi-node | vllm-multinode-template.yaml | vllm-cuda-image | NVIDIA Multi-GPU |
| HuggingFace Detector | hf-detector-template.yaml | guardrails-detector-huggingface-runtime-image | Guardrails detection |

## Architecture Notes

### High Availability
- Supports leader election (disabled by default, enabled via `--leader-elect` flag)
- Single replica deployment (replica count: 1)
- Leader election using Kubernetes leases in controller namespace

### Security Posture
- Runs as non-root user (UID 2000)
- Drops all capabilities (`securityContext.capabilities.drop: ALL`)
- No privilege escalation allowed
- FIPS 140-2 compliant builds (strictfipsruntime)
- TLS encryption for webhook endpoints via OpenShift service-ca
- Label-based secret watching (`opendatahub.io/managed: true`) limits secret access scope
- Label-based pod watching (`component: predictor`) limits pod access scope

### Extensibility
- Kubebuilder v4 scaffolding
- Multigroup API structure (nim, serving groups)
- External CRD integration (KServe, KEDA, Istio, Kuadrant, Gateway API)
- Template-based runtime configuration for easy addition of new ML frameworks
