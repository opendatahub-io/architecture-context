# Component: Llama Stack Kubernetes Operator

## Metadata
- **Repository**: https://github.com/opendatahub-io/llama-stack-k8s-operator
- **Version**: 0.0.1
- **Distribution**: ODH, RHOAI
- **Languages**: Go
- **Deployment Type**: Operator

## Purpose
**Short**: Kubernetes operator for deploying and managing Llama Stack LLM inference servers.

**Detailed**: The Llama Stack Kubernetes Operator automates the deployment and lifecycle management of Llama Stack servers on Kubernetes. It provides a declarative API via the LlamaStackDistribution custom resource to deploy LLM inference servers with support for multiple distribution backends including Ollama and vLLM. The operator handles server configuration, volume management for model storage, network access controls, and autoscaling. It simplifies running Meta's Llama models and other LLMs by abstracting away infrastructure complexity while providing production-ready features like horizontal pod autoscaling, network policies, and external route exposure.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Llama Stack Operator Controller | Operator Controller | Reconciles LlamaStackDistribution resources and manages server lifecycle |
| Llama Stack Server | LLM Server | Runs the Llama Stack inference server with configured distribution |
| Ollama Backend | Inference Backend | Lightweight LLM inference using Ollama (optional) |
| vLLM Backend | Inference Backend | High-performance LLM inference with GPU support (optional) |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| llamastack.io | v1alpha1 | LlamaStackDistribution | Namespaced | Defines a Llama Stack server deployment with distribution, storage, and network config |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness probe |
| /v1/chat/completions | POST | 8000/TCP | HTTP | TLS 1.2+ | API Key | Llama Stack chat completions endpoint |
| /v1/completions | POST | 8000/TCP | HTTP | TLS 1.2+ | API Key | Llama Stack text completions endpoint |
| /v1/inference/* | POST | 8000/TCP | HTTP | TLS 1.2+ | API Key | Llama Stack inference API |
| /health | GET | 8000/TCP | HTTP | None | None | Llama Stack server health check |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | No gRPC services exposed |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.24+ | Yes | Container orchestration platform |
| Ollama | latest | No | Lightweight LLM inference backend |
| vLLM | latest | No | High-performance GPU-accelerated LLM inference |
| Hugging Face Hub | N/A | No | Model download and distribution |
| Persistent Storage | N/A | Yes | Model storage via PVC |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Operator | CRD | Managed via DataScienceCluster for ODH deployments |
| KServe | Integration | Alternative LLM serving option |
| Model Registry | API | Model versioning and tracking (future) |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {llsd-name}-service | ClusterIP | 8000/TCP | 8000 | HTTP | TLS 1.2+ | API Key | Internal |
| {llsd-name}-service (with route) | ClusterIP | 8000/TCP | 8000 | HTTPS | TLS 1.2+ | API Key | External |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {llsd-name}-route | OpenShift Route | {llsd-name}-{namespace}.{cluster-domain} | 443/TCP | HTTPS | TLS 1.2+ | Edge | External (if exposeRoute=true) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Ollama Server | 11434/TCP | HTTP | None | None | Inference requests to Ollama backend |
| Hugging Face Hub | 443/TCP | HTTPS | TLS 1.3 | API Token | Model downloads |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret | Pull Llama Stack container images |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | "" | configmaps | create, get, list, patch, update, watch |
| manager-role | "" | persistentvolumeclaims | create, get, list, watch |
| manager-role | "" | serviceaccounts, services | create, delete, get, list, patch, update, watch |
| manager-role | apps | deployments | create, delete, get, list, patch, update, watch |
| manager-role | autoscaling | horizontalpodautoscalers | create, delete, get, list, patch, update, watch |
| manager-role | llamastack.io | llamastackdistributions | create, delete, get, list, patch, update, watch |
| manager-role | llamastack.io | llamastackdistributions/finalizers | update |
| manager-role | llamastack.io | llamastackdistributions/status | get, patch, update |
| manager-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| llsd-editor-role | llamastack.io | llamastackdistributions | create, delete, get, list, patch, update, watch |
| llsd-viewer-role | llamastack.io | llamastackdistributions | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | llama-stack-operator-system | manager-role | controller-manager |
| leader-election-rolebinding | llama-stack-operator-system | leader-election-role | controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| hf-token-secret | Opaque | Hugging Face API token for model downloads | User | No |
| {llsd-name}-api-key | Opaque | API key for Llama Stack server authentication | Operator | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /v1/* | All | API Key (Bearer Token) | Application Layer | Custom auth in Llama Stack server |
| Kubernetes API | All | ServiceAccount Token | Kubernetes API Server | RBAC |
| Ollama Backend | All | None (internal) | Network Policy | Namespace isolation |

## Data Flows

### Flow 1: Model Download and Initialization

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Operator | Kubernetes API (Deployment create) | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount |
| 2 | Llama Stack Pod Init | Hugging Face Hub | 443/TCP | HTTPS | TLS 1.3 | API Token |
| 3 | Llama Stack Pod Init | PVC (model storage) | N/A | Local | N/A | None |
| 4 | Llama Stack Pod | Ollama Server (if using Ollama) | 11434/TCP | HTTP | None | None |

### Flow 2: Inference Request (Internal)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client Pod | Llama Stack Service | 8000/TCP | HTTP | TLS 1.2+ | API Key |
| 2 | Llama Stack Server | Ollama/vLLM Backend | 11434/TCP or internal | HTTP | None | None |
| 3 | Llama Stack Server | GPU (if vLLM) | N/A | Local | N/A | None |

### Flow 3: Inference Request (External via Route)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | API Key |
| 2 | OpenShift Router | Llama Stack Service | 8000/TCP | HTTP | None | None |
| 3 | Llama Stack Server | Ollama/vLLM Backend | 11434/TCP or internal | HTTP | None | None |

### Flow 4: Network Policy Enforcement

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Operator | Kubernetes API (NetworkPolicy create) | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount |
| 2 | Allowed Namespace Pod | Llama Stack Service | 8000/TCP | HTTP | TLS 1.2+ | API Key |
| 3 | Blocked Namespace Pod | Llama Stack Service (rejected) | N/A | N/A | N/A | Network Policy |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API | REST API | 6443/TCP | HTTPS | TLS 1.3 | Resource management and orchestration |
| Ollama Server | HTTP API | 11434/TCP | HTTP | None | LLM inference backend |
| vLLM Server | HTTP API | 8000/TCP | HTTP | None | GPU-accelerated LLM inference |
| Hugging Face Hub | REST API | 443/TCP | HTTPS | TLS 1.3 | Model downloads |
| Persistent Storage | PVC | N/A | Local | N/A | Model artifact storage |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 0.0.1 | 2025-03 | - Add v1alpha2 operator-generated config specification<br>- Add termination grace period to PodOverrides<br>- Update Go to 1.25 for CVE-2025-61729<br>- Migrate golangci-lint to v2.8.0<br>- Fix CA bundle volume conflict during operator upgrade<br>- Update networkpolicy to remove podSelectors<br>- Add support for Network config<br>- Add network resources error handling<br>- Support for Ollama and vLLM distributions |
