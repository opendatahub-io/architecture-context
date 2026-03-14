# Component: Llama Stack Kubernetes Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/llama-stack-k8s-operator
- **Version**: 0.3.0 (Llama Stack Server: 0.2.22)
- **Distribution**: RHOAI
- **Languages**: Go 1.24
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes operator that automates deployment and lifecycle management of Llama Stack servers on Kubernetes.

**Detailed**: The Llama Stack Kubernetes Operator is a controller that manages the deployment of Meta's Llama Stack inference servers across various distribution types including Ollama, vLLM, TGI, Bedrock, and others. It provides Kubernetes-native resource management through custom resources (LlamaStackDistribution CRDs), handling automated deployment, configuration, persistent storage, network policies, and service exposure. The operator supports multiple inference backends, customizable server configurations, volume management for model storage, and optional network isolation with ingress/egress controls. It enables teams to deploy and manage AI inference workloads using declarative Kubernetes manifests while abstracting the complexity of configuring different LLM serving frameworks.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Operator Controller Manager | Deployment | Reconciles LlamaStackDistribution CRDs and manages lifecycle of Llama Stack servers |
| LlamaStackDistribution Controller | Controller | Watches LlamaStackDistribution CRDs, creates Deployments, Services, PVCs, NetworkPolicies, and Ingresses |
| Kustomize-based Deployment Engine | Library | Uses kustomize plugins to dynamically generate Kubernetes manifests from templates |
| Feature Flags Manager | ConfigMap | Controls optional features like NetworkPolicy creation via ConfigMap configuration |
| Distribution Image Mapper | ConfigMap | Maps distribution names (starter, ollama, vllm) to container images with override support |
| Network Policy Transformer | Plugin | Dynamically generates NetworkPolicy ingress rules based on spec.network.allowedFrom configuration |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| llamastack.io | v1alpha1 | LlamaStackDistribution | Namespaced | Defines desired state of a Llama Stack server deployment including distribution type, replicas, storage, network, and TLS configuration |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for operator monitoring |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe for operator health |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe for operator startup |
| /metrics | GET | 8443/TCP | HTTPS | TLS | Bearer Token | Secured metrics endpoint via kube-rbac-proxy |

### Managed Service Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| / | ALL | 8321/TCP | HTTP | Optional TLS | None | Llama Stack server API endpoint (default port, configurable via spec.server.containerSpec.port) |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | v1.20+ | Yes | Cluster platform for operator and workloads |
| controller-runtime | v0.19.4 | Yes | Kubernetes controller framework |
| kustomize | sigs.k8s.io/kustomize/kyaml v0.18.1 | Yes | Manifest templating and transformation |
| Inference Provider (Ollama/vLLM/TGI) | Various | Yes | Backend inference engine for LLM serving |
| Prometheus Operator | N/A | No | Metrics collection via ServiceMonitor |
| cert-manager | N/A | No | Optional TLS certificate management |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| OpenShift Monitoring | ServiceMonitor CRD | Exposes operator metrics to cluster monitoring stack |
| OpenShift Security Context Constraints | SCC 'anyuid' | Allows managed pods to run with specific UID requirements |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | https | HTTPS | TLS | Bearer Token | Internal (operator namespace) |
| {instance-name}-service | ClusterIP | 8321/TCP | 8321 | HTTP | Optional (via spec.tlsConfig) | None | Internal (per LlamaStackDistribution namespace) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {instance-name}-ingress | Ingress | Configured by cluster Ingress controller | 80/TCP or 443/TCP | HTTP/HTTPS | Depends on cluster IngressClass | Passthrough/Edge | External (when spec.network.exposeRoute=true) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | CRD reconciliation, resource management |
| Container Registry (docker.io, quay.io) | 443/TCP | HTTPS | TLS 1.2+ | Image pull secrets | Pull Llama Stack distribution images |
| Inference Provider Services | Various | HTTP/HTTPS | Various | Various | Connect to backend inference engines (Ollama, vLLM, etc.) |
| HuggingFace Hub | 443/TCP | HTTPS | TLS 1.2+ | HF Token (for vLLM) | Download LLM model weights |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | llamastack.io | llamastackdistributions | get, list, watch, create, update, patch, delete |
| manager-role | llamastack.io | llamastackdistributions/status | get, update, patch |
| manager-role | llamastack.io | llamastackdistributions/finalizers | update |
| manager-role | apps | deployments | get, list, watch, create, update, patch, delete |
| manager-role | "" | services, serviceaccounts | get, list, watch, create, update, patch, delete |
| manager-role | "" | persistentvolumeclaims | get, list, watch, create |
| manager-role | "" | configmaps | get, list, watch, create, update, patch |
| manager-role | networking.k8s.io | ingresses, networkpolicies | get, list, watch, create, update, patch, delete |
| manager-role | rbac.authorization.k8s.io | clusterrolebindings | get, list, watch, create, update, patch, delete |
| manager-role | rbac.authorization.k8s.io | clusterroles | get, list, watch |
| manager-role | security.openshift.io | securitycontextconstraints | use |
| manager-role | security.openshift.io (resourceName: anyuid) | securitycontextconstraints | use |
| auth-proxy-role | authentication.k8s.io | tokenreviews | create |
| auth-proxy-role | authorization.k8s.io | subjectaccessreviews | create |
| metrics-reader | "" | endpoints, services, pods | get, list, watch |
| llsd-editor-role | llamastack.io | llamastackdistributions | get, list, watch, create, update, patch, delete |
| llsd-viewer-role | llamastack.io | llamastackdistributions | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | cluster-wide | manager-role (ClusterRole) | controller-manager (operator namespace) |
| leader-election-rolebinding | operator namespace | leader-election-role (Role) | controller-manager |
| auth-proxy-rolebinding | operator namespace | auth-proxy-role (ClusterRole) | controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| hf-token-secret | Opaque | HuggingFace API token for model downloads (vLLM distributions) | User | No |
| {instance-name}-ca-bundle | Opaque | Custom CA certificates for TLS verification (via spec.tlsConfig.caBundle) | User/cert-manager | No |
| User-provided image pull secrets | kubernetes.io/dockerconfigjson | Authenticate to private container registries | User | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics (8443) | GET | Bearer Token (ServiceAccount JWT) | kube-rbac-proxy sidecar | TokenReview + SubjectAccessReview |
| /metrics (8080) | GET | None | Operator container | Unsecured, internal only |
| /healthz, /readyz | GET | None | Operator container | Unauthenticated health checks |
| Llama Stack Service | ALL | Configurable per distribution | Llama Stack server | Depends on distribution configuration |

### Network Policies

The operator can create NetworkPolicy resources for each LlamaStackDistribution when enabled via feature flag:

**Default Ingress Rules** (when `enableNetworkPolicy: true`):
- Allow from pods with label `app.kubernetes.io/part-of: llama-stack` in same namespace
- Allow from operator namespace (`llama-stack-k8s-operator-system`)
- Allow from namespaces specified in `spec.network.allowedFrom.namespaces`
- Allow from namespaces matching labels in `spec.network.allowedFrom.labels`

**Configuration**:
```yaml
# Enable via ConfigMap in operator namespace
apiVersion: v1
kind: ConfigMap
metadata:
  name: llama-stack-operator-config
  namespace: llama-stack-k8s-operator-system
data:
  featureFlags: |
    enableNetworkPolicy:
      enabled: true
```

## Data Flows

### Flow 1: LlamaStackDistribution Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Operator Manager | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount JWT |
| 2 | Operator Manager | Operator Manager (internal) | N/A | In-process | N/A | N/A |
| 3 | Operator Manager | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount JWT |

**Description**: Operator watches LlamaStackDistribution CRDs, generates Deployment/Service/PVC/NetworkPolicy manifests using kustomize templates, and applies them to the cluster.

### Flow 2: User Inference Request (with Ingress)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | Ingress Controller | 443/TCP | HTTPS | TLS 1.2+ (if configured) | Optional (application-level) |
| 2 | Ingress Controller | Llama Stack Service | 8321/TCP | HTTP | None (internal cluster network) | None |
| 3 | Llama Stack Service | Llama Stack Pod | 8321/TCP | HTTP | None | None |
| 4 | Llama Stack Pod | Inference Provider (Ollama/vLLM) | Various | HTTP/gRPC | Various | Various |

**Description**: External user sends inference request through Ingress, routed to Llama Stack service, which forwards to backend inference provider.

### Flow 3: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | kube-rbac-proxy (operator pod) | 8443/TCP | HTTPS | TLS | Bearer Token |
| 2 | kube-rbac-proxy | Operator Manager | 8080/TCP | HTTP | None (localhost) | None |

**Description**: Prometheus scrapes operator metrics through kube-rbac-proxy which validates ServiceAccount tokens.

### Flow 4: ConfigMap-driven Configuration Update

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Operator Manager | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount JWT |
| 3 | Operator Manager | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount JWT |

**Description**: User updates ConfigMap (feature flags or image overrides), operator watches ConfigMap changes, reconciles affected LlamaStackDistributions, and restarts pods with new configuration.

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | CRD management, resource reconciliation |
| Prometheus (via ServiceMonitor) | HTTP scrape | 8443/TCP | HTTPS | TLS | Operator metrics collection |
| Ollama Server | HTTP API | 11434/TCP | HTTP | None | Inference backend for ollama distribution |
| vLLM Server | HTTP API | 8000/TCP | HTTP | None | Inference backend for vllm distribution |
| TGI Server | HTTP API | 8080/TCP | HTTP | None | Inference backend for TGI distribution |
| Container Registry | Image pull | 443/TCP | HTTPS | TLS 1.2+ | Fetch Llama Stack distribution images |
| ConfigMap (operator-config) | Watch API | 6443/TCP | HTTPS | TLS 1.2+ | Feature flags and image override configuration |
| ConfigMap (user-config) | Volume mount | N/A | Filesystem | None | User-provided run.yaml configuration for Llama Stack |
| ConfigMap (ca-bundle) | Volume mount | N/A | Filesystem | None | Custom CA certificates for TLS verification |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 0.3.0 | 2025-03 | - Current RHOAI 2.25 release version<br>- Llama Stack Server v0.2.22<br>- NetworkPolicy improvements removing podSelectors<br>- Multiple UBI base image updates<br>- Konflux pipeline synchronizations |
| 0.0.1 | 2025-01 | - Initial fork from upstream llama-stack-k8s-operator<br>- Added RHOAI/ODH-specific configurations<br>- Integrated Konflux build system<br>- Red Hat UBI base images<br>- OpenShift security context constraints support |

**Recent Commit Highlights** (last 3 months):
- **4a5fc41**: Fix: Update networkpolicy to remove podSelectors - improved NetworkPolicy isolation model
- **Multiple dependency updates**: Continuous security updates to UBI9 go-toolset and ubi-minimal base images
- **Konflux integration**: Regular synchronization with konflux-central pipeline definitions for RHOAI builds

## Deployment Configuration

### Kustomize Overlays

The operator supports two distribution-specific overlays:

| Overlay | Path | Purpose |
|---------|------|---------|
| RHOAI | config/overlays/rhoai/ | Red Hat OpenShift AI specific configuration |
| ODH | config/overlays/odh/ | Open Data Hub specific configuration |

### Feature Flags (ConfigMap-based)

| Feature Flag | Default | Description |
|--------------|---------|-------------|
| enableNetworkPolicy | false | When true, creates NetworkPolicy for each LlamaStackDistribution |

### Image Overrides (ConfigMap-based)

Supports independent patching of Llama Stack distribution images via ConfigMap:

```yaml
data:
  image-overrides: |
    starter: quay.io/opendatahub/llama-stack:starter-latest
    ollama: quay.io/opendatahub/llama-stack:ollama-latest
    vllm-gpu: quay.io/opendatahub/llama-stack:vllm-gpu-latest
```

### Supported Distributions

| Distribution | Image | Purpose |
|--------------|-------|---------|
| starter | docker.io/llamastack/distribution-starter:latest | Basic starter distribution |
| ollama | docker.io/llamastack/distribution-ollama:latest | Ollama inference backend |
| bedrock | docker.io/llamastack/distribution-bedrock:latest | AWS Bedrock integration |
| remote-vllm | docker.io/llamastack/distribution-remote-vllm:latest | Remote vLLM server |
| tgi | docker.io/llamastack/distribution-tgi:latest | HuggingFace Text Generation Inference |
| together | docker.io/llamastack/distribution-together:latest | Together AI integration |
| vllm-gpu | docker.io/llamastack/distribution-vllm-gpu:latest | vLLM with GPU acceleration |

## Operational Considerations

### Resource Requirements

**Operator Pod**:
- CPU: 10m (request), 500m (limit)
- Memory: 256Mi (request), 1Gi (limit)

**Managed Llama Stack Pods**:
- Configurable via `spec.server.containerSpec.resources`
- Default: No limits/requests (inherits namespace defaults)

### Storage

**Persistent Volume Claims** (optional per instance):
- Default size: 10Gi
- Configurable via `spec.server.storage.size`
- Mount path: `/opt/app-root/src/.llama/distributions/rh/` (default, configurable)
- Purpose: Store model weights, configuration, and runtime data

### High Availability

- Operator: Single replica with leader election (can scale with leader-elect flag)
- Managed workloads: Configurable replicas via `spec.replicas` (default: 1)

### Monitoring

**Operator Metrics**:
- Exposed via Prometheus ServiceMonitor
- Endpoint: `/metrics` on port 8443 (secured) or 8080 (unsecured internal)
- Standard controller-runtime metrics (reconciliation duration, errors, queue depth)

**Health Checks**:
- Liveness: `/healthz` on port 8081
- Readiness: `/readyz` on port 8081

### Disaster Recovery

- All configuration in declarative CRDs (recoverable from git)
- Persistent data in PVCs (requires PV backup strategy)
- ConfigMap-based configuration (backup with cluster backups)
- Operator is stateless (recreate from manifests)
