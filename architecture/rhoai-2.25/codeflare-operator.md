# Component: CodeFlare Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/codeflare-operator.git
- **Version**: 1.15.0 (rhoai-2.25 branch)
- **Distribution**: RHOAI (also available in ODH)
- **Languages**: Go 1.25
- **Deployment Type**: Operator (Kubernetes controller)

## Purpose
**Short**: Manages distributed AI/ML workload orchestration through RayCluster and AppWrapper custom resources.

**Detailed**: The CodeFlare Operator provides automated lifecycle management for Ray distributed computing clusters and AppWrapper workload groups within Kubernetes/OpenShift environments. It embeds two controllers: the RayCluster controller enhances KubeRay-managed RayClusters with enterprise features like OAuth-based dashboard access, mTLS encryption for client connections, and network isolation policies; the AppWrapper controller enables Kueue-based batch scheduling by treating groups of Kubernetes resources as single logical units with automatic fault detection and recovery. The operator is designed specifically for RHOAI/ODH deployments, providing secure multi-tenant distributed computing capabilities for machine learning workloads.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Manager Pod | Deployment | Main operator controller running RayCluster and AppWrapper reconciliation loops |
| RayCluster Controller | Controller | Watches RayCluster CRDs and creates supporting resources (OAuth, mTLS, networking) |
| AppWrapper Controller | Controller | Manages AppWrapper CRDs for grouped resource deployment with Kueue integration |
| Mutating Webhook | AdmissionWebhook | Modifies RayCluster and AppWrapper resources on CREATE/UPDATE |
| Validating Webhook | AdmissionWebhook | Validates RayCluster and AppWrapper resources on CREATE/UPDATE |
| Metrics Service | Service | Exposes Prometheus metrics for operator monitoring |
| Webhook Service | Service | Serves admission webhook requests over TLS |
| Cert Controller | Component | Manages certificate rotation for webhook TLS |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| workload.codeflare.dev | v1beta2 | AppWrapper | Namespaced | Groups Kubernetes resources for batch scheduling with Kueue |
| ray.io | v1 | RayCluster | Namespaced | Ray distributed computing cluster (watched, provided by KubeRay) |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics scraping |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /mutate-workload-codeflare-dev-v1beta2-appwrapper | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Mutating webhook for AppWrapper |
| /mutate-ray-io-v1-raycluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Mutating webhook for RayCluster |
| /validate-workload-codeflare-dev-v1beta2-appwrapper | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Validating webhook for AppWrapper |
| /validate-ray-io-v1-raycluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Validating webhook for RayCluster |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| Ray Client (managed) | 10001/TCP | gRPC | mTLS (optional) | Client certificates | Ray cluster client API access |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| KubeRay Operator | v1.2.1 | Yes | Provides RayCluster CRD and base Ray cluster management |
| Kueue | v0.10.1+ | No | Workload queueing and batch scheduling for AppWrappers |
| cert-controller | v0.12.0 | Yes | Manages TLS certificate rotation for webhooks |
| Kubernetes | 1.31+ | Yes | Container orchestration platform |
| OpenShift | 4.11+ | No | OAuth proxy integration and Route resources |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | User facing | Users create RayCluster instances via notebook UI |
| ODH Operator | CRD/API | Reads DSCInitialization for configuration settings |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| codeflare-operator-manager-metrics | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (Prometheus) |
| codeflare-operator-webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | K8s API Server mTLS | Internal (API Server) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| ray-dashboard-* (per cluster) | Route (OpenShift) | ray-dashboard-{cluster}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | edge | External (when OAuth enabled) |
| ray-dashboard-* (per cluster) | Ingress (K8s) | ray-dashboard-{cluster}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External (when OAuth disabled) |
| ray-client-* (per cluster) | Route (OpenShift) | ray-client-{cluster}.{domain} | 10001/TCP | gRPC | TLS 1.2+ (mTLS) | passthrough | External (when mTLS enabled) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token | Watch resources, create/update objects |
| KubeRay Operator | N/A | N/A | N/A | N/A | Relies on KubeRay for RayCluster base resources |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | "" | events | create, patch, update, watch |
| manager-role | "" | nodes | get, list, watch |
| manager-role | "" | pods, services | create, delete, get, list, patch, update, watch |
| manager-role | "" | secrets | create, delete, get, list, patch, update, watch |
| manager-role | "" | serviceaccounts | create, delete, get, list, patch, update, watch |
| manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | get, list, update, watch |
| manager-role | apiextensions.k8s.io | customresourcedefinitions | get, list, watch |
| manager-role | apps | deployments, statefulsets | create, delete, get, list, patch, update, watch |
| manager-role | authentication.k8s.io | tokenreviews | create |
| manager-role | authorization.k8s.io | subjectaccessreviews | create |
| manager-role | batch | jobs | create, delete, get, list, patch, update, watch |
| manager-role | config.openshift.io | ingresses | get |
| manager-role | dscinitialization.opendatahub.io | dscinitializations | get, list, watch |
| manager-role | jobset.x-k8s.io | jobsets | create, delete, get, list, patch, update, watch |
| manager-role | kubeflow.org | pytorchjobs | create, delete, get, list, patch, update, watch |
| manager-role | networking.k8s.io | ingresses, networkpolicies | create, delete, get, list, patch, update, watch |
| manager-role | ray.io | rayclusters, rayjobs | create, delete, get, list, patch, update, watch |
| manager-role | ray.io | rayclusters/finalizers | update |
| manager-role | ray.io | rayclusters/status | get, patch, update |
| manager-role | rbac.authorization.k8s.io | clusterrolebindings | create, delete, get, list, patch, update, watch |
| manager-role | route.openshift.io | routes, routes/custom-host | create, delete, get, list, patch, update, watch |
| manager-role | scheduling.sigs.k8s.io, scheduling.x-k8s.io | podgroups | create, delete, get, list, patch, update, watch |
| manager-role | workload.codeflare.dev | appwrappers | create, delete, get, list, patch, update, watch |
| manager-role | workload.codeflare.dev | appwrappers/finalizers | update |
| manager-role | workload.codeflare.dev | appwrappers/status | get, patch, update |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | cluster-wide | manager-role (ClusterRole) | controller-manager |
| leader-election-rolebinding | operator namespace | leader-election-role (Role) | controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| codeflare-operator-webhook-server-cert | kubernetes.io/tls | TLS certificate for admission webhooks | cert-controller | Yes |
| {cluster}-ca | Opaque | CA certificate and private key for mTLS | RayCluster controller | No |
| {cluster}-tls | kubernetes.io/tls | OAuth proxy TLS certificates (OpenShift) | RayCluster controller | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None | Service | Public within cluster |
| /healthz, /readyz | GET | None | Service | Public within cluster |
| /mutate-*, /validate-* | POST | mTLS client certificate | Webhook Service | Kubernetes API server only |
| Ray Dashboard (OAuth) | GET, POST | OAuth Bearer Token | OAuth Proxy (OpenShift) | OpenShift user authentication |
| Ray Dashboard (non-OAuth) | GET, POST | None | Ingress | Public (namespace-scoped) |
| Ray Client (mTLS) | gRPC | mTLS client certificate | Ray head node | Client certificate validation |

### Network Policies

| Policy Name | Selectors | Ingress Rules | Purpose |
|-------------|-----------|---------------|---------|
| {cluster}-head-* | ray.io/node-type=head | From: Same cluster pods (all ports)<br>From: KubeRay namespaces (10001/TCP, 8265/TCP)<br>From: Namespace clients (8443/TCP, 10001/TCP when mTLS) | Restricts access to Ray head node |
| {cluster}-workers-* | ray.io/node-type=worker | From: Same cluster pods only | Isolates Ray worker nodes to cluster-internal communication |

## Data Flows

### Flow 1: RayCluster Creation with OAuth (OpenShift)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Notebook | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | Bearer Token (ServiceAccount) |
| 2 | Kubernetes API | Webhook Service | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (API Server) |
| 3 | Webhook Service | Kubernetes API | Response | HTTPS | TLS 1.2+ | mTLS |
| 4 | Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | Bearer Token |
| 5 | Controller | Route API (OpenShift) | 6443/TCP | HTTPS | TLS 1.3 | Bearer Token |
| 6 | Controller | Kubernetes API (create Service) | 6443/TCP | HTTPS | TLS 1.3 | Bearer Token |
| 7 | Controller | Kubernetes API (create NetworkPolicy) | 6443/TCP | HTTPS | TLS 1.3 | Bearer Token |
| 8 | User | OAuth Proxy via Route | 443/TCP | HTTPS | TLS 1.2+ edge | OAuth Bearer Token |
| 9 | OAuth Proxy | Ray Dashboard | 8265/TCP | HTTP | None | None (internal pod) |

### Flow 2: AppWrapper Scheduling with Kueue

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API (create AppWrapper) | 6443/TCP | HTTPS | TLS 1.3 | Bearer Token |
| 2 | Kubernetes API | Webhook Service (validate) | 9443/TCP | HTTPS | TLS 1.2+ | mTLS |
| 3 | Kueue Controller | Kubernetes API (update AppWrapper status) | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount token |
| 4 | AppWrapper Controller | Kubernetes API (watch status) | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount token |
| 5 | AppWrapper Controller | Kubernetes API (create wrapped resources) | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount token |

### Flow 3: Ray Client Connection with mTLS

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | Ray Client Route/Ingress | 443/TCP | HTTPS | TLS 1.2+ passthrough | Client Certificate |
| 2 | Route/Ingress | Ray Head Service | 10001/TCP | gRPC | mTLS | Client Certificate |
| 3 | Ray Head Pod | Ray Workers | Internal | gRPC | mTLS | Client Certificate |

### Flow 4: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | Metrics Service | 8080/TCP | HTTP | None | Bearer Token (ServiceAccount) |
| 2 | Metrics Service | Manager Pod | 8080/TCP | HTTP | None | Internal pod network |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.3 | Resource CRUD operations, watches |
| KubeRay Operator | CRD dependency | N/A | N/A | N/A | Provides RayCluster CRD, base cluster lifecycle |
| Kueue | CRD updates | 6443/TCP | HTTPS | TLS 1.3 | AppWrapper admission and status updates |
| OpenShift OAuth | OAuth proxy | 443/TCP | HTTPS | TLS 1.2+ | User authentication for Ray dashboard |
| Prometheus | Metrics scraping | 8080/TCP | HTTP | None | Operator health and performance monitoring |
| ODH Operator | CRD reads | 6443/TCP | HTTPS | TLS 1.3 | Read DSCInitialization for configuration |
| cert-controller | Certificate management | N/A | In-process | N/A | Webhook TLS certificate rotation |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| d76d8d4 | 2025-01 | - Update UBI9 go-toolset base image to 1.25<br>- Update dependencies for security patches |
| 355ef72 | 2025-01 | - Sync Konflux pipeline runs with central configuration |
| e948884 | 2025-01 | - Update UBI9 minimal base image for runtime container |
| 355c892 | 2025-01 | - Update go-toolset digest for build reproducibility |
| 32e7ca7 | 2024-12 | - Upgrade Go toolset version to 1.25 |
| ec62aab | 2024-12 | - Sync Konflux pipeline configurations |
| 2385889 | 2024-11 | - Sync Konflux pipeline updates |

## Configuration

### ConfigMap: codeflare-operator-config

| Setting | Default | Purpose |
|---------|---------|---------|
| clientConnection.qps | 50 | API server client QPS limit |
| clientConnection.burst | 100 | API server client burst limit |
| metrics.bindAddress | :8080 | Metrics server listen address |
| health.bindAddress | :8081 | Health probe server listen address |
| kuberay.rayDashboardOAuthEnabled | true | Enable OAuth proxy for Ray dashboard (OpenShift only) |
| kuberay.mTLSEnabled | true | Enable mTLS for Ray client connections |
| kuberay.ingressDomain | (auto-detected) | Base domain for ingress/route creation |
| appwrapper.enabled | false | Enable embedded AppWrapper controller |

## Container Images

| Image | Base | Purpose | Build Method |
|-------|------|---------|--------------|
| odh-codeflare-operator-container | registry.redhat.io/ubi9/ubi-minimal | Operator runtime | Konflux (FIPS-enabled Go build) |
| ose-oauth-proxy | registry.redhat.io/openshift4/ose-oauth-proxy | OAuth sidecar for Ray dashboard | External (OpenShift) |
| ubi9 cert-generator | registry.redhat.io/ubi9 | TLS certificate generation | External (Red Hat) |

## Operational Notes

### Resource Requirements

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| Manager | 1 core | 1 core | 1Gi | 1Gi |

### High Availability

- Single replica deployment (leader election enabled but not required for webhooks)
- Webhooks run in both leader and follower instances
- Certificate rotation independent of leader election

### Monitoring

- Prometheus metrics exposed on :8080/metrics
- Health checks: liveness (:8081/healthz), readiness (:8081/readyz)
- ServiceMonitor resource created for automatic Prometheus discovery

### Security Posture

- FIPS-compliant Go runtime (strictfipsruntime build tag)
- Non-root container execution (UID 65532)
- Minimal attack surface (UBI minimal base)
- No privileged escalation allowed
- Network policies for pod isolation
- mTLS for service-to-service communication (optional)
- OAuth integration for user authentication (OpenShift)
