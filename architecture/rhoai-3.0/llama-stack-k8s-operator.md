# Component: Llama Stack Kubernetes Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/llama-stack-k8s-operator
- **Version**: v0.4.0
- **Distribution**: RHOAI
- **Languages**: Go 1.24
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes operator that automates the deployment and lifecycle management of Llama Stack AI inference servers.

**Detailed**: The Llama Stack Kubernetes Operator provides a declarative, Kubernetes-native approach to deploying and managing Llama Stack servers. It abstracts the complexity of deploying AI inference infrastructure by managing multiple backend distributions (Ollama, vLLM, TGI, Bedrock, Together, etc.) through a single Custom Resource Definition (LlamaStackDistribution). The operator handles the full lifecycle of inference deployments including persistent storage provisioning, network policy enforcement, service creation, and health monitoring. It supports customizable server configurations, volume management for model storage, and integrates with OpenShift's security context constraints. The operator enables data scientists and ML engineers to deploy production-ready AI inference endpoints without deep Kubernetes expertise.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Operator Controller Manager | Deployment | Main operator process that reconciles LlamaStackDistribution CRDs |
| LlamaStackDistribution Controller | Go Controller | Watches and reconciles LlamaStackDistribution custom resources |
| Llama Stack Server Deployment | Managed Deployment | Container running the actual llama-stack inference server |
| Kustomize Transformer | Internal Library | Dynamically generates Kubernetes manifests from templates |
| Distribution Resolver | Internal Component | Maps distribution names to container images |
| Network Policy Manager | Internal Component | Creates and manages network isolation policies |
| Storage Provisioner | Internal Component | Creates and manages PersistentVolumeClaims for model storage |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| llamastack.io | v1alpha1 | LlamaStackDistribution | Namespaced | Defines desired state of Llama Stack server deployments including distribution type, replicas, storage, and runtime configuration |

### HTTP Endpoints

#### Operator Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | Bearer Token | Prometheus metrics endpoint (internal only, localhost-bound) |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token | Secured metrics via kube-rbac-proxy |

#### Managed Llama Stack Server Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /v1/* | POST/GET | 8321/TCP | HTTP | None | None | Llama Stack API endpoints for inference requests |
| /providers | GET | 8321/TCP | HTTP | None | None | Provider configuration and health status endpoint |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | No gRPC services exposed |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.20+ | Yes | Container orchestration platform |
| controller-runtime | v0.20+ | Yes | Kubernetes operator framework |
| Kustomize | embedded | Yes | Manifest templating and transformation |
| Prometheus Operator | N/A | No | Metrics collection via ServiceMonitor |
| OpenShift SCC | N/A | No | Security context constraints on OpenShift |
| Inference Provider (Ollama/vLLM/etc) | varies | Yes | Backend inference engine for model serving |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| None | N/A | Standalone operator with no direct ODH component dependencies |

## Network Architecture

### Services

#### Operator Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | https | HTTPS | TLS 1.2+ | Bearer Token (kube-rbac-proxy) | Internal |

#### Managed Llama Stack Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {instance-name}-service | ClusterIP | 8321/TCP | 8321 | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| N/A | N/A | N/A | N/A | N/A | N/A | N/A | No ingress resources created by default |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token | CRD watch, resource creation/updates |
| Inference Provider Service | varies/TCP | HTTP/HTTPS | varies | varies | Connect to backend inference engines (Ollama, vLLM, etc.) |
| Container Registry (quay.io) | 443/TCP | HTTPS | TLS 1.2+ | None/Token | Pull llama-stack distribution images |
| HuggingFace Hub | 443/TCP | HTTPS | TLS 1.2+ | Token | Download AI models (when configured) |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | llamastack.io | llamastackdistributions | get, list, watch, create, update, patch, delete |
| manager-role | llamastack.io | llamastackdistributions/status | get, patch, update |
| manager-role | llamastack.io | llamastackdistributions/finalizers | update |
| manager-role | apps | deployments | get, list, watch, create, update, patch, delete |
| manager-role | "" (core) | services | get, list, watch, create, update, patch, delete |
| manager-role | "" (core) | serviceaccounts | get, list, watch, create, update, patch, delete |
| manager-role | "" (core) | persistentvolumeclaims | get, list, watch, create |
| manager-role | "" (core) | configmaps | get, list, watch, create, update, patch |
| manager-role | networking.k8s.io | networkpolicies | get, list, watch, create, update, patch, delete |
| manager-role | rbac.authorization.k8s.io | rolebindings | get, list, watch, create, update, patch, delete |
| manager-role | rbac.authorization.k8s.io | clusterroles | get, list, watch |
| manager-role | rbac.authorization.k8s.io | clusterrolebindings | get, list, delete |
| manager-role | security.openshift.io | securitycontextconstraints | use |
| manager-role | security.openshift.io | securitycontextconstraints (anyuid) | use |
| leader-election-role | "" (core) | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| leader-election-role | "" (core) | events | create, patch |
| metrics-reader | "" (core) | pods | get, list, watch |
| metrics-reader | "" (core) | services | get |
| llsd-editor-role | llamastack.io | llamastackdistributions | create, delete, get, list, patch, update, watch |
| llsd-viewer-role | llamastack.io | llamastackdistributions | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-role-binding | Cluster | manager-role (ClusterRole) | controller-manager |
| leader-election-role-binding | redhat-ods-applications | leader-election-role (Role) | controller-manager |
| metrics-auth-rolebinding | redhat-ods-applications | metrics-reader (ClusterRole) | controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| N/A | N/A | No secrets managed by operator | N/A | N/A |
| hf-token-secret (user-provided) | Opaque | HuggingFace API token for model downloads | User | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics (8443) | GET | Bearer Token (JWT) | kube-rbac-proxy | Kubernetes RBAC |
| /metrics (8080) | GET | None (localhost only) | Network binding | Bind to 127.0.0.1 |
| /healthz, /readyz (8081) | GET | None | Application | Public within cluster |
| Llama Stack API (8321) | POST, GET | None | NetworkPolicy | Restricted to same namespace + operator namespace |

### Network Policies

| Policy Name | Selectors | Ingress Rules | Egress Rules |
|-------------|-----------|---------------|--------------|
| {instance-name}-network-policy | app=llama-stack, app.kubernetes.io/instance={name} | Allow from pods with app.kubernetes.io/part-of=llama-stack (any namespace); Allow from operator namespace on port 8321/TCP | Not specified (allow all) |

## Data Flows

### Flow 1: LlamaStackDistribution Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | kubectl/ServiceAccount |
| 2 | Kubernetes API | Operator Controller | N/A | Watch | N/A | ServiceAccount Token |
| 3 | Operator Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Operator Controller | Kubernetes API (create Deployment) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | Operator Controller | Kubernetes API (create Service) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 6 | Operator Controller | Kubernetes API (create NetworkPolicy) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 7 | Operator Controller | Kubernetes API (create PVC) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: Llama Stack Server Health Check

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Operator Controller | Llama Stack Service | 8321/TCP | HTTP | None | None |
| 2 | Llama Stack Service | Llama Stack Pod | 8321/TCP | HTTP | None | None |
| 3 | Llama Stack Pod | Operator Controller (response) | 8321/TCP | HTTP | None | None |
| 4 | Operator Controller | Kubernetes API (status update) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 3: Inference Request to Llama Stack

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client Application | Llama Stack Service | 8321/TCP | HTTP | None | None |
| 2 | Llama Stack Service | Llama Stack Pod | 8321/TCP | HTTP | None | None |
| 3 | Llama Stack Pod | Inference Provider (Ollama/vLLM) | varies/TCP | HTTP/gRPC | None | None |
| 4 | Inference Provider | Llama Stack Pod (response) | varies/TCP | HTTP/gRPC | None | None |
| 5 | Llama Stack Pod | Client Application (response) | 8321/TCP | HTTP | None | None |

### Flow 4: Operator Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | kube-rbac-proxy | 8443/TCP | HTTPS | TLS (insecureSkipVerify) | Bearer Token |
| 2 | kube-rbac-proxy | Operator Manager | 8080/TCP (localhost) | HTTP | None | None |
| 3 | Operator Manager | kube-rbac-proxy (response) | 8080/TCP (localhost) | HTTP | None | None |
| 4 | kube-rbac-proxy | Prometheus (response) | 8443/TCP | HTTPS | TLS (insecureSkipVerify) | Bearer Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | CRD reconciliation, resource management |
| Prometheus (optional) | Metrics scrape | 8443/TCP | HTTPS | TLS | Operator metrics collection |
| Ollama Server | HTTP API | 11434/TCP | HTTP | None | Backend inference for ollama distribution |
| vLLM Server | HTTP API | 8000/TCP | HTTP | None | Backend inference for vllm distributions |
| TGI Server | HTTP API | 8080/TCP | HTTP | None | Backend inference for tgi distribution |
| HuggingFace Hub | REST API | 443/TCP | HTTPS | TLS 1.2+ | Model downloads (when configured) |
| Container Registry (quay.io) | Container Image Pull | 443/TCP | HTTPS | TLS 1.2+ | Pull llama-stack distribution images |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| v0.4.0 | 2025-10-17 | - Update release versions for 3.0<br>- Remove dependency on cluster-scoped resources<br>- Use new CLI to run the server |
| v0.3.x | 2025-10-31 | - Fix version detection for pre-release versions |
| v0.2.x | 2025-11-03 | - Multiple dependency updates (UBI base images, Go toolset)<br>- Konflux CI/CD integration |
| continuous | 2026-01-01 to 2026-02-05 | - Regular security updates to UBI9 minimal base image<br>- Konflux reference updates<br>- Automated dependency management via Renovate |

## Deployment Architecture

### Operator Deployment

The operator is deployed as a single-replica Deployment in the `redhat-ods-applications` namespace with:
- **Image**: Built using Dockerfile.konflux from UBI9 Go toolset 1.24
- **Security Context**: Runs as non-root (UID 1001), drops all capabilities, disables privilege escalation
- **Resource Limits**: 500m CPU / 1Gi memory
- **Resource Requests**: 10m CPU / 256Mi memory
- **Health Checks**: Liveness on /healthz, readiness on /readyz
- **Leader Election**: Enabled with lease-based coordination (ID: 54e06e98.llamastack.io)

### Managed Llama Stack Deployments

For each LlamaStackDistribution CR, the operator creates:
1. **ServiceAccount**: For RBAC permissions to access PVCs
2. **RoleBinding**: Grants ServiceAccount access to cluster-scoped PVC reader role
3. **PersistentVolumeClaim**: For model storage (default: 10Gi, configurable)
4. **Deployment**:
   - Replicas: Configurable (default: 1)
   - Container: Llama Stack server from configured distribution image
   - Port: 8321/TCP (configurable)
   - Volume Mounts: PVC mounted at /opt/app-root/src/.llama/distributions/rh/ (configurable)
   - Init Containers: Optional CA bundle injection for custom certificates
5. **Service**: ClusterIP service exposing port 8321
6. **NetworkPolicy**: Restricts ingress to pods with app.kubernetes.io/part-of=llama-stack label and operator namespace

## Supported Distributions

The operator embeds a distributions.json mapping that supports:

| Distribution Name | Image | Use Case |
|-------------------|-------|----------|
| starter | docker.io/llamastack/distribution-starter:latest | Basic starter distribution |
| ollama | docker.io/llamastack/distribution-ollama:latest | Ollama-based inference |
| bedrock | docker.io/llamastack/distribution-bedrock:latest | AWS Bedrock integration |
| remote-vllm | docker.io/llamastack/distribution-remote-vllm:latest | Remote vLLM inference |
| tgi | docker.io/llamastack/distribution-tgi:latest | HuggingFace TGI integration |
| together | docker.io/llamastack/distribution-together:latest | Together AI integration |
| vllm-gpu | docker.io/llamastack/distribution-vllm-gpu:latest | GPU-accelerated vLLM |
| custom | User-specified image | Custom distribution image |

## Configuration Features

### Storage Configuration
- **Size**: Configurable via `.spec.server.storage.size` (default: 10Gi)
- **Mount Path**: Configurable via `.spec.server.storage.mountPath` (default: /opt/app-root/src/.llama/distributions/rh/)
- **Storage Class**: Uses cluster default StorageClass

### TLS Configuration
- **CA Bundle**: Support for custom CA certificates via ConfigMap reference
- **Certificate Injection**: Init container injects certificates into system trust store
- **Multiple Sources**: Supports multiple ConfigMap keys for certificate concatenation

### User Configuration
- **ConfigMap-based**: Users can provide run.yaml configuration via ConfigMap
- **Namespace Isolation**: ConfigMap can be in same or different namespace
- **Watch Updates**: ConfigMap changes trigger pod restarts

### Pod Customization
- **Service Account**: Custom ServiceAccount override
- **Volumes**: Additional volume mounts beyond storage PVC
- **Environment Variables**: Custom env vars for runtime configuration
- **Commands/Args**: Override container command and arguments
- **Resource Limits**: Configurable CPU/memory requests and limits

## Observability

### Metrics
- **Endpoint**: /metrics on port 8443 (secured) or 8080 (localhost)
- **Format**: Prometheus format
- **Collection**: ServiceMonitor resource for Prometheus Operator integration
- **Metrics Included**: Controller runtime metrics (reconciliation, API calls, queue depth)

### Status Reporting
The LlamaStackDistribution status includes:
- **Phase**: Pending, Initializing, Ready, Failed, Terminating
- **Version Info**: Operator version and llama-stack server version
- **Available Replicas**: Count of ready replicas
- **Service URL**: Internal Kubernetes service URL
- **Distribution Config**: Active distribution and provider health status
- **Conditions**: Standard Kubernetes condition types for detailed state

### Logging
- **Framework**: controller-runtime with zap logger
- **Level**: Configurable via flags
- **Stack Traces**: Only on panic level (not on errors)
- **Structured**: JSON-formatted logs in production mode
