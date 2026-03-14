# Component: ODH Model Controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/odh-model-controller
- **Version**: 1.27.0-rhods-1121-g0ce874f
- **Branch**: rhoai-2.25
- **Distribution**: RHOAI
- **Languages**: Go 1.25.7
- **Deployment Type**: Kubernetes Operator (Kubebuilder v4)
- **Build System**: Konflux (FIPS compliant with strictfipsruntime)

## Purpose
**Short**: Extends KServe model serving with OpenShift integration, service mesh, authentication, monitoring, and automated resource management.

**Detailed**:
The ODH Model Controller is a Kubernetes operator that extends the functionality of KServe (both serverless and raw deployment modes) and ModelMesh for model serving in OpenShift AI. It eliminates manual steps when deploying machine learning models by automatically managing infrastructure resources including OpenShift Routes, Istio service mesh components (VirtualServices, Gateways, PeerAuthentication), network policies, RBAC, monitoring (ServiceMonitors, PodMonitors), authentication (Authorino AuthConfigs), and KEDA autoscaling.

The controller watches KServe InferenceService, InferenceGraph, ServingRuntime, and LLMInferenceService resources, reconciling them with OpenShift-specific and service mesh configurations. It also provides NVIDIA NIM (NVIDIA Inference Microservices) integration through a custom Account CRD that manages NGC API keys, pull secrets, and runtime templates. The controller supports multiple serving runtimes including vLLM (CPU, CUDA, Gaudi, ROCm, multinode), Caikit, OVMS, and HuggingFace, and integrates with Model Registry for model metadata tracking.

The controller runs as a single-replica deployment with leader election support, exposing metrics for Prometheus and webhooks for admission control (mutating and validating) of inference workloads and pods.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| InferenceService Controller | Reconciler | Manages KServe InferenceService resources, creates Routes, VirtualServices, auth configs, monitoring |
| InferenceGraph Controller | Reconciler | Manages KServe InferenceGraph resources for multi-model inference pipelines |
| LLMInferenceService Controller | Reconciler | Specialized controller for LLM-specific inference services |
| NIM Account Controller | Reconciler | Manages NVIDIA NIM accounts, API keys, pull secrets, and runtime templates |
| ServingRuntime Controller | Reconciler | Manages ServingRuntime resources and templates |
| ConfigMap Controller | Reconciler | Watches ConfigMaps for configuration changes |
| Secret Controller | Reconciler | Watches Secrets (labeled opendatahub.io/managed=true) for credential management |
| Pod Controller | Reconciler | Watches predictor Pods for runtime metrics and validation |
| Pod Mutating Webhook | Admission Controller | Mutates Pod specs for inference workloads |
| InferenceService Webhook | Admission Controller | Validates and mutates InferenceService resources |
| InferenceGraph Webhook | Admission Controller | Validates and mutates InferenceGraph resources |
| NIM Account Webhook | Admission Controller | Validates NIM Account resources |
| Knative Service Webhook | Admission Controller | Validates Knative Service resources (serverless mode only) |
| Metrics Server | HTTP Endpoint | Exposes Prometheus metrics on port 8080 |
| Health Probe Server | HTTP Endpoint | Exposes liveness/readiness probes on port 8081 |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| nim.opendatahub.io | v1 | Account | Namespaced | Manages NVIDIA NIM account integration, NGC API keys, pull secrets, model configs, and ServingRuntime templates |

### Watched External CRDs

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | KServe model serving instances - controller adds Routes, mesh config, auth |
| serving.kserve.io | v1alpha1 | InferenceGraph | Namespaced | Multi-model inference pipelines - controller adds mesh and monitoring |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Model server runtime definitions - controller manages templates |
| serving.kserve.io | v1alpha1 | LLMInferenceService | Namespaced | LLM-specific inference services with custom reconciliation |
| serving.knative.dev | v1 | Service | Namespaced | Knative Services (serverless mode) - validated by webhook |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint (TODO: migrate to 8443 HTTPS with TLS) |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe for controller health |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe for controller startup |
| /mutate--v1-pod | POST | 443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Mutating webhook for Pod resources |
| /mutate-serving-kserve-io-v1beta1-inferenceservice | POST | 443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Mutating webhook for InferenceService |
| /mutate-serving-kserve-io-v1alpha1-inferencegraph | POST | 443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Mutating webhook for InferenceGraph |
| /validate-nim-opendatahub-io-v1-account | POST | 443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Validating webhook for NIM Account |
| /validate-serving-kserve-io-v1beta1-inferenceservice | POST | 443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Validating webhook for InferenceService |
| /validate-serving-kserve-io-v1alpha1-inferencegraph | POST | 443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Validating webhook for InferenceGraph |
| /validate-serving-knative-dev-v1-service | POST | 443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Validating webhook for Knative Service |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| KServe | v0.13+ | Yes | Core model serving platform - controller extends its functionality |
| Istio/Maistra Service Mesh | v2.5+ | No | Service mesh for mTLS, routing, telemetry (optional, controlled by MESH_DISABLED env) |
| OpenShift Route API | v1 | Yes | Creates Routes for external access to inference endpoints |
| Authorino | v0.14+ | No | Authentication/authorization for inference endpoints |
| Kuadrant AuthPolicy | v1beta3 | No | Alternative auth mechanism (optional) |
| Prometheus Operator | v0.68+ | No | Metrics collection via ServiceMonitor/PodMonitor |
| KEDA | v2.14+ | No | Event-driven autoscaling for inference workloads |
| cert-manager | v1.13+ | No | TLS certificate management for webhooks |
| OpenShift Template API | v1 | Yes | Template processing for NIM runtime creation |
| NVIDIA NGC | API | No | NVIDIA NIM model catalog and image registry (for NIM Account feature) |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| DataScienceCluster | CRD Watch | Reads DSC configuration to determine component enablement state |
| DSCInitialization | CRD Watch | Reads initialization config for service mesh and auth settings |
| Model Registry | REST API | Registers inference services and tracks model metadata (optional, controlled by MODELREGISTRY_STATE) |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-model-controller-metrics-service | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (TODO: change to 8443 HTTPS) |
| webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | K8s API Server mTLS | Internal (K8s API server to webhook) |

### Network Policies

| Policy Name | Target Pods | Type | Source | Port | Protocol | Purpose |
|-------------|-------------|------|--------|------|----------|---------|
| allow-metrics-traffic | control-plane=controller-manager | Ingress | Namespaces with label metrics=enabled | 8443/TCP | TCP | Allow Prometheus to scrape metrics |
| odh-model-controller | control-plane=odh-model-controller | Ingress | Namespaces with label webhook=enabled | 443/TCP | TCP | Allow K8s API server webhook traffic |

### Managed Resources

The controller creates and manages the following resources for InferenceService workloads:

| Resource Type | Purpose | Scope |
|---------------|---------|-------|
| Route (OpenShift) | External HTTPS access to inference endpoints | Per InferenceService |
| VirtualService (Istio) | Service mesh routing for predictor/transformer | Per InferenceService |
| Gateway (Istio) | Ingress gateway configuration updates | Shared (knative-local-gateway) |
| PeerAuthentication (Istio) | mTLS enforcement for inference Pods | Per namespace |
| Telemetry (Istio) | Metrics collection configuration | Per namespace |
| ServiceMeshMember (Maistra) | Namespace enrollment in service mesh | Per namespace |
| NetworkPolicy | Egress/ingress rules for model serving | Per namespace |
| AuthConfig (Authorino) | Authentication/authorization policies | Per InferenceService |
| AuthPolicy (Kuadrant) | Alternative auth mechanism | Per InferenceService |
| ServiceMonitor (Prometheus) | Metrics scraping for inference endpoints | Per InferenceService |
| PodMonitor (Prometheus) | Pod-level metrics collection | Per InferenceService |
| TriggerAuthentication (KEDA) | Credentials for autoscaling triggers | Per InferenceService |
| ClusterRoleBinding | RBAC for inference workload access | Per InferenceService (raw mode) |
| RoleBinding | Namespace-scoped RBAC | Per namespace |
| ServiceAccount | Identity for inference Pods | Per namespace |
| Secret | TLS certificates, pull secrets, credentials | Per namespace/InferenceService |
| ConfigMap | Runtime configuration, model lists (NIM) | Per namespace/Account |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-model-controller-role | "" | configmaps, secrets, serviceaccounts, services | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | "" | endpoints, namespaces, pods | create, get, list, patch, update, watch |
| odh-model-controller-role | "" | events | create, patch |
| odh-model-controller-role | serving.kserve.io | inferenceservices, llminferenceservices | get, list, patch, update, watch |
| odh-model-controller-role | serving.kserve.io | inferenceservices/finalizers, llminferenceservices/finalizers | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | serving.kserve.io | inferencegraphs | get, list, watch |
| odh-model-controller-role | serving.kserve.io | inferencegraphs/finalizers, servingruntimes/finalizers | update |
| odh-model-controller-role | serving.kserve.io | servingruntimes | create, get, list, update, watch |
| odh-model-controller-role | networking.istio.io | virtualservices, virtualservices/finalizers | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | networking.istio.io | gateways | get, list, patch, update, watch |
| odh-model-controller-role | security.istio.io | peerauthentications | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | security.istio.io | authorizationpolicies | get, list |
| odh-model-controller-role | telemetry.istio.io | telemetries | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | maistra.io | servicemeshmembers | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | maistra.io | servicemeshmemberrolls | get, list, watch |
| odh-model-controller-role | maistra.io | servicemeshcontrolplanes | get, list, use, watch |
| odh-model-controller-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | route.openshift.io | routes/custom-host | create |
| odh-model-controller-role | monitoring.coreos.com | servicemonitors, podmonitors | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | authorino.kuadrant.io | authconfigs | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | kuadrant.io | authpolicies | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | networking.k8s.io, extensions | ingresses | get, list, watch |
| odh-model-controller-role | keda.sh | triggerauthentications | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | rbac.authorization.k8s.io | clusterrolebindings, rolebindings, roles | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | nim.opendatahub.io | accounts | get, list, patch, update, watch |
| odh-model-controller-role | nim.opendatahub.io | accounts/status | get, list, update, watch |
| odh-model-controller-role | nim.opendatahub.io | accounts/finalizers | update |
| odh-model-controller-role | datasciencecluster.opendatahub.io | datascienceclusters | get, list, watch |
| odh-model-controller-role | dscinitialization.opendatahub.io | dscinitializations | get, list, watch |
| odh-model-controller-role | template.openshift.io | templates | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | metrics.k8s.io | pods, nodes | get, list, watch |
| leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| leader-election-role | "" | events | create, patch |
| kserve-prometheus-metrics | "" | namespaces | get |
| kserve-prometheus-metrics | "" | services, endpoints, pods | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-model-controller-role-binding | All namespaces | odh-model-controller-role (ClusterRole) | odh-model-controller |
| leader-election-rolebinding | odh-model-controller namespace | leader-election-role (Role) | odh-model-controller |
| odh-model-controller-metrics-auth-rolebinding | odh-model-controller namespace | metrics-auth-role (ClusterRole) | odh-model-controller |
| odh-model-controller-auth-proxy-rolebinding | odh-model-controller namespace | auth-proxy-role (ClusterRole) | odh-model-controller |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| webhook-server-cert | kubernetes.io/tls | TLS certificate for admission webhooks | cert-manager | Yes |
| {isvc-name}-sa-token | kubernetes.io/service-account-token | ServiceAccount token for inference Pods | Kubernetes | Yes |
| {account-name}-nim-pull-secret | kubernetes.io/dockerconfigjson | NVIDIA NGC registry pull secret (NIM) | NIM Account Controller | No |
| ray-tls-{namespace} | Opaque | Ray cluster TLS certificates (for distributed LLM serving) | Controller (cross-namespace copy) | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | Bearer Token (ServiceAccount) | kube-rbac-proxy | ClusterRole: metrics-reader |
| Webhook endpoints | POST | mTLS client certificate | Kubernetes API Server | API server validates controller certificate |
| InferenceService endpoints | GET, POST | Bearer Token (JWT), mTLS, or Authorino | Istio + Authorino/AuthPolicy | Per-InferenceService AuthConfig or AuthPolicy |

## Data Flows

### Flow 1: InferenceService Creation and Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth | Action |
|------|--------|-------------|------|----------|------------|------|--------|
| 1 | User/Client | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.3 | OIDC/Bearer Token | Submit InferenceService CR |
| 2 | Kubernetes API Server | odh-model-controller webhook | 443/TCP | HTTPS | TLS 1.2+ | mTLS | Validate/mutate InferenceService |
| 3 | odh-model-controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token | Watch InferenceService changes |
| 4 | odh-model-controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token | Create Route, VirtualService, AuthConfig, ServiceMonitor, NetworkPolicy |
| 5 | KServe Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token | Create Knative Service or K8s Deployment |
| 6 | Knative/K8s | Container Registry | 443/TCP | HTTPS | TLS 1.3 | Pull Secret | Pull model server image |
| 7 | Model Server Pod | S3/Storage | 443/TCP | HTTPS | TLS 1.2+ | IAM/Access Key | Load model artifacts |

### Flow 2: Inference Request (Serverless with Service Mesh)

| Step | Source | Destination | Port | Protocol | Encryption | Auth | Action |
|------|--------|-------------|------|----------|------------|------|--------|
| 1 | Client | OpenShift Route | 443/TCP | HTTPS | TLS 1.3 | None/Bearer | Send inference request |
| 2 | OpenShift Router | Istio Ingress Gateway | 8080/TCP | HTTP | None | None | Forward to service mesh |
| 3 | Istio Ingress Gateway | Authorino (if enabled) | 5001/TCP | gRPC | mTLS | None | Validate auth token |
| 4 | Istio Ingress Gateway | Knative Activator | 8012/TCP | HTTP | None | None | Route to activator (if scaled to zero) |
| 5 | Knative Activator | Inference Pod | 8080/TCP | HTTP | mTLS (if PeerAuth enabled) | None | Forward to predictor |
| 6 | Inference Pod | Model Transformer (optional) | 8080/TCP | HTTP | mTLS | None | Pre/post-process request |
| 7 | Inference Pod | Client | 443/TCP | HTTPS | TLS 1.3 | None | Return inference result via route chain |

### Flow 3: NIM Account Management

| Step | Source | Destination | Port | Protocol | Encryption | Auth | Action |
|------|--------|-------------|------|----------|------------|------|--------|
| 1 | User/Client | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.3 | OIDC/Bearer Token | Create NIM Account CR with NGC API key secret |
| 2 | Kubernetes API Server | odh-model-controller webhook | 443/TCP | HTTPS | TLS 1.2+ | mTLS | Validate Account spec |
| 3 | NIM Account Controller | NVIDIA NGC API | 443/TCP | HTTPS | TLS 1.3 | NGC API Key | Validate account, fetch model list |
| 4 | NIM Account Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token | Create ConfigMap (model list), Secret (pull secret), Template (ServingRuntime) |
| 5 | NIM Account Controller | NVIDIA NGC API | 443/TCP | HTTPS | TLS 1.3 | NGC API Key | Periodic refresh (default: 24h) for model list and validation |

### Flow 4: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth | Action |
|------|--------|-------------|------|----------|------------|------|--------|
| 1 | Prometheus | odh-model-controller | 8080/TCP | HTTP | None | Bearer Token (via ServiceMonitor) | Scrape controller metrics at /metrics |
| 2 | Prometheus | Inference Pod | 8080/TCP | HTTP | mTLS (if configured) | Bearer Token | Scrape inference metrics (via ServiceMonitor/PodMonitor) |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API (client-go) | 6443/TCP | HTTPS | TLS 1.3 | Watch/create/update all Kubernetes resources |
| KServe Controller | CRD Watch (shared) | N/A | N/A | N/A | Coordinate InferenceService reconciliation |
| Istio Control Plane | CRD Management | 15017/TCP | gRPC | mTLS | Create VirtualServices, Gateways, PeerAuthentication, Telemetry |
| Authorino | CRD Management | N/A | N/A | N/A | Create AuthConfig resources for inference endpoint auth |
| Prometheus | ServiceMonitor | 8080/TCP | HTTP | None | Expose controller and inference metrics |
| OpenShift Template API | REST API | 6443/TCP | HTTPS | TLS 1.3 | Process templates for NIM runtime creation |
| NVIDIA NGC API | REST API | 443/TCP | HTTPS | TLS 1.3 | Validate accounts, fetch model catalog (NIM feature) |
| Model Registry | REST API | 443/TCP | HTTPS | TLS 1.2+ | Register InferenceService metadata (optional) |
| KEDA Operator | CRD Management | N/A | N/A | N/A | Create TriggerAuthentication for autoscaling |

## Deployment Configuration

### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| POD_NAMESPACE | (from fieldRef) | Controller's running namespace |
| KSERVE_STATE | replace | Control KServe component reconciliation (managed/removed/replace) |
| MODELMESH_STATE | replace | Control ModelMesh component reconciliation |
| NIM_STATE | replace | Control NIM feature (managed/removed/replace) |
| MODELREGISTRY_STATE | replace | Enable Model Registry integration |
| MESH_DISABLED | false | Disable service mesh integration entirely |
| MR_SKIP_TLS_VERIFY | false | Skip TLS verification for Model Registry API calls |
| ENABLE_WEBHOOKS | true | Enable admission webhooks |
| AUTH_AUDIENCE | (from ConfigMap auth-refs) | JWT audience for Authorino |
| AUTHORINO_LABEL | (from ConfigMap auth-refs) | Label selector for Authorino instance |
| CONTROL_PLANE_NAME | (from ConfigMap service-mesh-refs) | Service mesh control plane name |
| MESH_NAMESPACE | (from ConfigMap service-mesh-refs) | Service mesh control plane namespace |

### Resource Limits

| Container | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| manager | 10m | 500m | 64Mi | 2Gi |

### Pod Security

| Setting | Value | Purpose |
|---------|-------|---------|
| runAsNonRoot | true | Security: prevent root execution |
| runAsUser | 2000 | Non-privileged user ID |
| allowPrivilegeEscalation | false | Prevent privilege escalation |
| capabilities.drop | ALL | Drop all Linux capabilities |
| FIPS Mode | strictfipsruntime | FIPS 140-2 compliant crypto (Konflux build) |

## Serving Runtime Templates

The controller deploys the following built-in ServingRuntime templates:

| Runtime | Model Types | Accelerator | Use Case |
|---------|-------------|-------------|----------|
| caikit-standalone | Text generation | CPU/GPU | IBM Caikit framework for NLP models |
| caikit-tgis | Text generation | GPU | Caikit with IBM Text Generation Inference Server |
| ovms-kserve | TensorFlow, PyTorch, ONNX | CPU/GPU | OpenVINO Model Server (KServe mode) |
| ovms-mm | TensorFlow, PyTorch, ONNX | CPU/GPU | OpenVINO Model Server (ModelMesh mode) |
| vllm-cpu | LLMs | CPU | vLLM inference on CPU |
| vllm-cuda | LLMs | NVIDIA GPU (CUDA) | vLLM inference on NVIDIA GPUs |
| vllm-gaudi | LLMs | Intel Gaudi | vLLM inference on Intel Gaudi accelerators |
| vllm-rocm | LLMs | AMD GPU (ROCm) | vLLM inference on AMD GPUs |
| vllm-spyre | LLMs | Spyre accelerators | vLLM inference on Spyre hardware |
| vllm-multinode | Large LLMs | Multi-node GPU clusters | Distributed vLLM for very large models with Ray |
| hf-detector | Text classification | CPU/GPU | HuggingFace-based content detection |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 0ce874f | 2025-03-13 | - Sync pipelineruns with konflux-central (19bdad4) |
| 2ecf302 | 2025-03 | - [RHOAIENG-46367] FIPS Compliance: replace math/rand with crypto/rand for security (#712) |
| 0e532f3 | 2025-03 | - Upgrade Go to 1.25.7 (#696) |
| 834fbf7 | 2025-03 | - Update vLLM Gaudi version on template |
| 190ddd2 | 2025-02 | - Fix: reduce NIM ConfigMap size by storing only required model fields |
| a9db5f6 | 2025-02 | - Add rhoai-version parameter to Tekton pipeline configuration |
| 594032c | 2025-02 | - Update base image version in Dockerfile.konflux |
| 06907cd | 2025-02 | - Fix UID mismatch error when updating ray-tls secrets across namespaces (#621) |
| fb84cf6 | 2025-02 | - Update vLLM version on vLLM Gaudi template |
| 9a6f65a | 2025-02 | - Update vLLM versions on 2.25 branch (#647) |
| 3230abb | 2025-02 | - Fix CVE-2025-68156: Update expr-lang/expr to v1.17.7 (#640) |

## Notes

- **Migration in Progress**: Metrics endpoint currently uses HTTP on port 8080; migration to HTTPS on port 8443 with TLS is planned (multiple TODOs in code)
- **Conditional Features**: Service mesh, Model Registry, and NIM features can be independently enabled/disabled via environment variables
- **Multi-Mode Support**: Supports KServe serverless (Knative), KServe raw (Kubernetes), and ModelMesh deployment modes
- **OpenShift Native**: Heavily integrated with OpenShift-specific APIs (Route, Template) and Maistra service mesh
- **Security Hardened**: Built with FIPS compliance, runs as non-root user (UID 2000), drops all capabilities
- **Webhook Architecture**: Uses kubebuilder scaffolding with separate mutating/validating webhooks for different resource types
- **Label-Based Caching**: Optimizes memory by caching only labeled Secrets (opendatahub.io/managed=true) and predictor Pods
- **Leader Election**: Supports high availability with leader election (LeaderElectionID: odh-model-controller.opendatahub.io)
