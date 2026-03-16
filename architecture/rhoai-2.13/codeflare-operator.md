# Component: CodeFlare Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/codeflare-operator
- **Version**: 8679c4a (rhoai-2.13 branch)
- **Distribution**: RHOAI (also available in ODH)
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Manages the lifecycle of CodeFlare distributed workload stack components including RayClusters and AppWrappers.

**Detailed**: The CodeFlare Operator is a Kubernetes operator that provides installation and lifecycle management for the CodeFlare distributed workload stack. It orchestrates Ray clusters for distributed AI/ML workloads by reconciling RayCluster custom resources, managing their networking, security, and access configurations. The operator also embeds the AppWrapper controller to provide advanced workload scheduling and resource management capabilities through integration with Kueue. It automatically configures OAuth authentication for Ray dashboards, sets up mTLS encryption for Ray cluster communication, and manages network policies to secure distributed workloads. The operator supports both vanilla Kubernetes and OpenShift environments, adapting its behavior based on the platform (e.g., using Routes on OpenShift vs Ingresses on Kubernetes).

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Manager | Operator Deployment | Main operator process managing RayCluster and AppWrapper reconciliation |
| RayCluster Controller | Controller | Reconciles RayCluster resources, manages networking, secrets, and authentication |
| AppWrapper Controller | Embedded Controller | Manages AppWrapper resources for workload scheduling (optional, configurable) |
| RayCluster Webhook | Admission Webhook | Mutates and validates RayCluster resources on create/update |
| AppWrapper Webhook | Admission Webhook | Mutates and validates AppWrapper resources on create/update |
| Metrics Server | HTTP Server | Exposes Prometheus metrics on port 8080 |
| Health Probes | HTTP Server | Provides liveness and readiness endpoints on port 8081 |
| Certificate Controller | Cert Rotator | Manages webhook TLS certificates with automatic rotation |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| ray.io | v1 | RayCluster | Namespaced | Managed by KubeRay operator; CodeFlare operator watches and augments with security/networking |
| workload.codeflare.dev | v1beta2 | AppWrapper | Namespaced | Wraps multiple resources for gang scheduling and quota management |
| kueue.x-k8s.io | v1beta1 | Workload | Namespaced | Managed for AppWrapper integration with Kueue scheduling |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | Bearer Token | Prometheus metrics endpoint |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe |
| /mutate-ray-io-v1-raycluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Mutating webhook for RayCluster |
| /validate-ray-io-v1-raycluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Validating webhook for RayCluster |
| /mutate-workload-codeflare-dev-v1beta2-appwrapper | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Mutating webhook for AppWrapper |
| /validate-workload-codeflare-dev-v1beta2-appwrapper | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Validating webhook for AppWrapper |

### gRPC Services

None - This operator does not expose gRPC services.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| KubeRay Operator | v1.1.1 | Yes | Manages RayCluster CRD and Ray cluster lifecycle; CodeFlare operator enhances with security features |
| Kueue | v0.7.0+ | No | Provides workload scheduling and quota management for AppWrappers |
| AppWrapper CRD | v0.23.0 | No | Required only if AppWrapper controller is enabled |
| cert-manager | Any | No | Alternative to built-in cert rotation for webhook certificates |
| OpenShift API | v4.x | No | Required only on OpenShift for Route and config.openshift.io resources |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| opendatahub-operator | CRD Watch | Reads DSCInitialization to determine application namespace for network policies |
| oauth-proxy | Sidecar Container | Injected into RayCluster head pods for OAuth authentication to Ray dashboard |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| codeflare-operator-webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | K8s API Server mTLS | Internal |
| codeflare-operator-manager-metrics | ClusterIP | 8080/TCP | 8080 | HTTP | None | Bearer Token | Internal |
| {raycluster}-head-svc (managed) | ClusterIP | 8443/TCP, 10001/TCP | varies | HTTPS, gRPC | TLS 1.2+, mTLS | OAuth, mTLS | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {raycluster}-ingress (Kubernetes) | Ingress | {cluster}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | Passthrough | External |
| {raycluster}-route (OpenShift) | Route | {cluster}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | Passthrough | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Resource reconciliation, watching CRDs |
| KubeRay Operator | N/A | N/A | N/A | N/A | Watches RayCluster CRDs managed by KubeRay |
| Kueue API | N/A | N/A | N/A | N/A | Manages Workload resources for AppWrapper scheduling |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | ray.io | rayclusters, rayclusters/status, rayclusters/finalizers, rayjobs | get, list, watch, create, update, patch, delete |
| manager-role | workload.codeflare.dev | appwrappers, appwrappers/status, appwrappers/finalizers | get, list, watch, create, update, patch, delete |
| manager-role | kueue.x-k8s.io | workloads, workloads/status, workloads/finalizers, resourceflavors, workloadpriorityclasses | get, list, watch, create, update, patch, delete |
| manager-role | "" (core) | pods, services, secrets, serviceaccounts, events, nodes | get, list, watch, create, update, patch, delete |
| manager-role | apps | deployments, statefulsets | get, list, watch, create, update, patch, delete |
| manager-role | batch | jobs | get, list, watch, create, update, patch, delete |
| manager-role | networking.k8s.io | ingresses, networkpolicies | get, list, watch, create, update, patch, delete |
| manager-role | rbac.authorization.k8s.io | clusterrolebindings | get, list, watch, create, update, patch, delete |
| manager-role | route.openshift.io | routes, routes/custom-host | get, list, watch, create, update, patch, delete |
| manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | get, list, watch, update |
| manager-role | apiextensions.k8s.io | customresourcedefinitions | get, list, watch |
| manager-role | config.openshift.io | ingresses | get |
| manager-role | dscinitialization.opendatahub.io | dscinitializations | get, list, watch |
| manager-role | authentication.k8s.io | tokenreviews | create |
| manager-role | authorization.k8s.io | subjectaccessreviews | create |
| manager-role | scheduling.k8s.io | priorityclasses | get, list, watch |
| manager-role | scheduling.sigs.k8s.io | podgroups | get, list, watch, create, update, patch, delete |
| manager-role | scheduling.x-k8s.io | podgroups | get, list, watch, create, update, patch, delete |
| manager-role | kubeflow.org | pytorchjobs | get, list, watch, create, update, patch, delete |
| leader-election-role | "" (core) | configmaps, events | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | Cluster-wide | manager-role (ClusterRole) | controller-manager |
| leader-election-rolebinding | Operator namespace | leader-election-role (Role) | controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| codeflare-operator-webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificate for admission webhooks | cert-controller (built-in) | Yes |
| {raycluster}-ca-secret | Opaque | CA certificate and private key for RayCluster mTLS | RayCluster Controller | No |
| {raycluster}-tls | kubernetes.io/tls | TLS certificates for RayCluster head and worker nodes | RayCluster Controller | No |
| {raycluster}-oauth-config | Opaque | OAuth proxy configuration for Ray dashboard authentication | RayCluster Controller | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | Bearer Token (ServiceAccount) | ServiceMonitor scraper | Prometheus requires valid SA token |
| /healthz, /readyz | GET | None | None | Public health endpoints |
| Webhook endpoints | POST | mTLS Client Certificate | Kubernetes API Server | API server authenticates using client cert |
| Ray Dashboard (via Ingress/Route) | ALL | OAuth Proxy | OAuth Proxy Sidecar | OpenShift OAuth or configured OAuth provider |
| Ray Head Service (port 10001) | ALL | mTLS | Ray Client | Ray nodes authenticate using cluster CA certificates |
| Ray Dashboard HTTPS (port 8443) | ALL | mTLS + OAuth | Ray + OAuth Proxy | Double authentication layer |

## Data Flows

### Flow 1: RayCluster Creation and Security Setup

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/SDK | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Kubernetes API Server | codeflare-operator webhook | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (API server client cert) |
| 3 | Webhook | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Kubernetes API Server | KubeRay Operator | N/A | N/A | N/A | N/A |
| 5 | codeflare-operator controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 6 | codeflare-operator controller | RayCluster namespace | N/A | N/A | N/A | N/A |

### Flow 2: Ray Dashboard Access via OAuth

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router / Ingress Controller | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | Router | OAuth Proxy (RayCluster head pod) | 8443/TCP | HTTPS | TLS 1.2+ (passthrough) | None |
| 3 | OAuth Proxy | OAuth Provider | 443/TCP | HTTPS | TLS 1.2+ | OAuth flow |
| 4 | OAuth Proxy | Ray Dashboard (localhost) | 8265/TCP | HTTP | None | Localhost trust |
| 5 | Ray Dashboard | User Browser | 443/TCP | HTTPS | TLS 1.2+ | OAuth session cookie |

### Flow 3: Ray Worker to Head Communication (mTLS)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Ray Worker Pod | Ray Head Service | 10001/TCP | gRPC | mTLS | Client Certificate from cluster CA |
| 2 | Ray Worker Pod | Ray Head Service | 6379/TCP | Redis Protocol | mTLS (if enabled) | Client Certificate |
| 3 | Ray Head | Ray Worker | Dynamic | gRPC | mTLS | Server Certificate from cluster CA |

### Flow 4: AppWrapper Scheduling with Kueue

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | API Server | codeflare-operator webhook | 9443/TCP | HTTPS | TLS 1.2+ | mTLS |
| 3 | codeflare-operator controller | Kubernetes API Server (Workload CRD) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Kueue Controller | Workload resources | N/A | N/A | N/A | N/A |
| 5 | codeflare-operator controller | Wrapped resources (RayCluster, etc.) | N/A | N/A | N/A | N/A |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API Client | 6443/TCP | HTTPS | TLS 1.2+ | Resource reconciliation, CRD watching |
| KubeRay Operator | CRD Watch | N/A | N/A | N/A | Monitors RayCluster resources managed by KubeRay |
| Kueue | CRD Management | N/A | N/A | N/A | Creates/manages Workload resources for AppWrapper scheduling |
| Prometheus | Metrics Scraping | 8080/TCP | HTTP | None | Collects operator metrics |
| OpenShift OAuth | HTTP Redirect | 443/TCP | HTTPS | TLS 1.2+ | User authentication for Ray dashboards |
| DSCInitialization | CRD Read | N/A | N/A | N/A | Determines ODH application namespace for network policies |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 8679c4a | 2025-03-12 | - Update Konflux references (#376) |
| 6d4df01 | 2025-03-12 | - Update Konflux references (#370) |
| 862a110 | 2025-03-11 | - Update Konflux references to d00d159 (#369) |
| d92ae07 | 2025-03-11 | - Update Konflux references to d00d159 (#368) |
| b7a842f | 2025-03-11 | - Update Konflux references (#359) |
| fffd858 | 2025-03-11 | - Update Konflux references (#358) |
| 27b7bea | 2025-03-11 | - Update Konflux references to e1d365c (#355) |
| a5bea68 | 2025-03-11 | - Update Konflux references (#351) |
| ccd56f1 | 2025-03-11 | - Update Konflux references (#350) |
| 31b40b8 | 2025-03-10 | - Update Konflux references to 493a872 (#341) |
| fda954f | 2025-03-10 | - Update Konflux references to 493a872 (#340) |
| d57ba78 | 2025-03-10 | - Update Konflux references to 493a872 (#339) |
| 915d843 | 2025-03-05 | - Update Konflux references (#320) |
| fdf6389 | 2025-03-04 | - Update UBI8 go-toolset Docker digest (#316) |
| 9a17a51 | 2025-03-03 | - Update Konflux references (#309) |
| 14c1cb8 | 2025-03-02 | - Update Konflux references to b9cb1e1 (#303) |
| d167e4b | 2025-02-28 | - Update Konflux references to 944e769 (#296) |
| 8b40ab0 | 2025-02-27 | - Update Konflux references (#285) |
| 9ddf5b8 | 2025-02-27 | - Update Konflux references to 8b6f22f (#278) |
| 9d64759 | 2025-02-27 | - Update Konflux references to 8b6f22f (#275) |

## Configuration

### Operator Configuration

The operator is configured via a ConfigMap (`codeflare-operator-config`) with the following key settings:

| Parameter | Default | Purpose |
|-----------|---------|---------|
| kuberay.rayDashboardOAuthEnabled | true | Enable OAuth proxy for Ray dashboard access |
| kuberay.mTLSEnabled | true | Enable mTLS encryption for Ray cluster internal communication |
| kuberay.ingressDomain | Auto-detected | Domain for creating Ingresses/Routes |
| appwrapper.enabled | false | Enable embedded AppWrapper controller |
| clientConnection.qps | 50 | Kubernetes API client QPS limit |
| clientConnection.burst | 100 | Kubernetes API client burst limit |
| metrics.bindAddress | :8080 | Metrics server bind address |
| health.bindAddress | :8081 | Health probe server bind address |

### Network Policies Created

The operator creates NetworkPolicy resources for each RayCluster:

**{raycluster}-head NetworkPolicy**:
- Allows ingress to port 8443/TCP from any namespace (OAuth dashboard access)
- Allows ingress to port 10001/TCP from same namespace if mTLS enabled (Ray GCS)
- Allows ingress from worker pods in same namespace

**{raycluster}-workers NetworkPolicy**:
- Allows ingress from worker pods in same RayCluster
- Allows ingress from head pod in same RayCluster

### Security Context

The operator deployment runs with:
- `runAsNonRoot: true`
- `allowPrivilegeEscalation: false`
- Capabilities: All dropped
- User: 65532 (non-root)

## Build Information

- **Container Base Image**: registry.access.redhat.com/ubi8/ubi-minimal
- **Build Tool**: Konflux CI/CD
- **Go Version**: 1.22
- **Build Tags**: strictfipsruntime (FIPS 140-2 compliance)
- **CGO**: Enabled (required for FIPS)
