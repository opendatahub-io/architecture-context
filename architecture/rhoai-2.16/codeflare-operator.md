# Component: CodeFlare Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/codeflare-operator.git
- **Version**: v0.0.0-dev (rhoai-2.16 branch)
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Manages lifecycle of CodeFlare distributed workload stack including RayCluster and AppWrapper resources for distributed ML/AI workloads.

**Detailed**: The CodeFlare Operator is a Kubernetes operator that provides installation and lifecycle management for the CodeFlare distributed workload stack. It manages two primary resource types: RayCluster (via KubeRay integration) and AppWrapper (via embedded controller). The operator enhances RayCluster deployments with OpenShift-specific features including OAuth-secured dashboards, network policies for mTLS communication, and automatic ingress/route creation. It integrates with Kueue for workload scheduling and queuing, making it suitable for multi-tenant AI/ML environments. The operator automatically configures security contexts, TLS certificates, and network isolation for Ray clusters while maintaining compatibility with both OpenShift and vanilla Kubernetes environments.

The operator supports configurable mTLS between Ray cluster components, automatic OAuth proxy injection for secure dashboard access on OpenShift, and network policy-based isolation for Ray workloads. It integrates with the broader OpenDataHub/RHOAI ecosystem through DSCInitialization custom resources and works alongside KubeRay, Kueue, and other distributed workload components.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| codeflare-operator-manager | Deployment | Main operator controller managing RayCluster and AppWrapper lifecycle |
| RayCluster Controller | Controller | Reconciles RayCluster resources, injects OAuth proxy, creates network policies and routes |
| AppWrapper Controller | Embedded Controller | Manages AppWrapper resources for batch job scheduling (conditionally enabled) |
| Mutating Webhook | AdmissionWebhook | Mutates RayCluster and AppWrapper resources on CREATE operations |
| Validating Webhook | AdmissionWebhook | Validates RayCluster and AppWrapper resources on CREATE/UPDATE operations |
| Cert Controller | Certificate Manager | Manages webhook TLS certificates with automatic rotation |
| Metrics Server | HTTP Server | Exposes Prometheus metrics on port 8080 |
| Health Server | HTTP Server | Provides liveness and readiness probes on port 8081 |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| workload.codeflare.dev | v1beta2 | AppWrapper | Namespaced | Wraps multiple Kubernetes resources for batch scheduling with Kueue integration |
| ray.io | v1 | RayCluster | Namespaced | Managed by KubeRay operator; CodeFlare operator enhances with OAuth, mTLS, network policies |

**Note**: The operator does not define these CRDs but watches and enhances them. AppWrapper CRDs are sourced from github.com/project-codeflare/appwrapper v0.27.0. RayCluster CRDs are provided by KubeRay operator.

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | ServiceAccount Token | Prometheus metrics endpoint for operator monitoring |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint (checks webhook cert readiness) |
| /mutate-workload-codeflare-dev-v1beta2-appwrapper | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Mutating webhook for AppWrapper CREATE operations |
| /mutate-ray-io-v1-raycluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Mutating webhook for RayCluster CREATE operations |
| /validate-workload-codeflare-dev-v1beta2-appwrapper | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Validating webhook for AppWrapper CREATE/UPDATE operations |
| /validate-ray-io-v1-raycluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Validating webhook for RayCluster CREATE/UPDATE operations |

### gRPC Services

No gRPC services exposed.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| KubeRay Operator | v1.1.0+ | Yes | Provides RayCluster CRD and base reconciliation logic |
| Kueue | v0.8.3 (ODH v0.7.0-odh-2) | Conditional | Provides workload queuing and resource management for AppWrapper |
| cert-controller | v0.10.1 | Yes | Manages webhook TLS certificate rotation |
| Kubernetes | 1.29+ | Yes | Container orchestration platform |
| OpenShift (Optional) | 4.11+ | No | For OAuth proxy, Routes, and enhanced security features |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| opendatahub-operator | CRD (DSCInitialization) | Discovers ODH/RHOAI application namespace for network policy configuration |
| KubeRay (ODH deployment) | Namespace Discovery | Locates KubeRay operator deployment for network policy ingress rules |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| codeflare-operator-manager-metrics | ClusterIP | 8080/TCP | metrics (8080) | HTTP | None | ServiceAccount Token | Internal (Prometheus) |
| codeflare-operator-webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | Kubernetes API mTLS | Internal (API Server) |

### Services Created for RayClusters (per cluster)

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {cluster}-oauth-proxy | ClusterIP | 443/TCP | 8443 | HTTPS | TLS | OAuth2 | Internal/External via Route |
| {cluster}-head-svc | ClusterIP | 8265/TCP | 8265 | HTTP | Optional mTLS | None/mTLS | Internal |
| {cluster}-head-svc | ClusterIP | 10001/TCP | 10001 | TCP | mTLS | Client Cert | Internal (Ray client) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {cluster}-dashboard | Ingress (Kubernetes) | {cluster}-dashboard-{ns}.{domain} | 8265/TCP | HTTP | None | N/A | External |
| {cluster}-rayclient | Ingress (Kubernetes) | {cluster}-rayclient-{ns}.{domain} | 10001/TCP | TCP | mTLS | PASSTHROUGH | External |
| {cluster}-oauth-proxy | Route (OpenShift) | Auto-generated | 443/TCP | HTTPS | TLS | Edge | External |
| {cluster}-rayclient | Route (OpenShift) | Auto-generated | 10001/TCP | TCP | mTLS | Passthrough | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch CRDs, manage resources |
| KubeRay Operator | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Coordinate RayCluster reconciliation |
| OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth2 | Authenticate dashboard users (OpenShift only) |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| codeflare-operator-manager-role | "" | events | create, patch, update, watch |
| codeflare-operator-manager-role | "" | nodes | get, list, watch |
| codeflare-operator-manager-role | "" | pods, services | create, delete, get, list, patch, update, watch |
| codeflare-operator-manager-role | "" | secrets | create, delete, get, list, patch, update, watch |
| codeflare-operator-manager-role | "" | serviceaccounts | create, delete, get, list, patch, update, watch |
| codeflare-operator-manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | get, list, update, watch |
| codeflare-operator-manager-role | apiextensions.k8s.io | customresourcedefinitions | get, list, watch |
| codeflare-operator-manager-role | apps | deployments, statefulsets | create, delete, get, list, patch, update, watch |
| codeflare-operator-manager-role | authentication.k8s.io | tokenreviews | create |
| codeflare-operator-manager-role | authorization.k8s.io | subjectaccessreviews | create |
| codeflare-operator-manager-role | batch | jobs | create, delete, get, list, patch, update, watch |
| codeflare-operator-manager-role | config.openshift.io | ingresses | get |
| codeflare-operator-manager-role | dscinitialization.opendatahub.io | dscinitializations | get, list, watch |
| codeflare-operator-manager-role | kubeflow.org | pytorchjobs | create, delete, get, list, patch, update, watch |
| codeflare-operator-manager-role | kueue.x-k8s.io | clusterqueues | get, list, patch, update, watch |
| codeflare-operator-manager-role | kueue.x-k8s.io | resourceflavors, workloadpriorityclasses | get, list, watch |
| codeflare-operator-manager-role | kueue.x-k8s.io | workloads, workloads/finalizers, workloads/status | create, delete, get, list, patch, update, watch |
| codeflare-operator-manager-role | networking.k8s.io | ingresses, networkpolicies | create, delete, get, list, patch, update, watch |
| codeflare-operator-manager-role | ray.io | rayclusters, rayclusters/finalizers, rayclusters/status | create, delete, get, list, patch, update, watch |
| codeflare-operator-manager-role | ray.io | rayjobs | create, delete, get, list, patch, update, watch |
| codeflare-operator-manager-role | rbac.authorization.k8s.io | clusterrolebindings | create, delete, get, list, patch, update, watch |
| codeflare-operator-manager-role | route.openshift.io | routes, routes/custom-host | create, delete, get, list, patch, update, watch |
| codeflare-operator-manager-role | scheduling.k8s.io | priorityclasses | get, list, watch |
| codeflare-operator-manager-role | scheduling.sigs.k8s.io, scheduling.x-k8s.io | podgroups | create, delete, get, list, patch, update, watch |
| codeflare-operator-manager-role | workload.codeflare.dev | appwrappers, appwrappers/finalizers, appwrappers/status | create, delete, get, list, patch, update, watch |
| codeflare-operator-leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| codeflare-operator-leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| codeflare-operator-leader-election-role | "" | events | create, patch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| codeflare-operator-manager-rolebinding | system (opendatahub) | codeflare-operator-manager-role | codeflare-operator-controller-manager |
| codeflare-operator-leader-election-rolebinding | system (opendatahub) | codeflare-operator-leader-election-role | codeflare-operator-controller-manager |
| {cluster}-{namespace}-auth (per RayCluster) | Cluster-scoped | system:auth-delegator | {cluster}-oauth-proxy |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| codeflare-operator-webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificate | cert-controller | Yes |
| {cluster}-oauth-secret | Opaque | OAuth proxy session secret and cookie salt | codeflare-operator | No |
| {cluster}-ca-secret | Opaque | Ray cluster CA certificate and key for mTLS | codeflare-operator | No |
| {cluster}-tls-secret | kubernetes.io/tls | OAuth proxy TLS serving certificate | codeflare-operator | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | Bearer Token (ServiceAccount) | Kubernetes NetworkPolicy | Allow from openshift-monitoring namespace |
| /healthz, /readyz | GET | None | None | Publicly accessible within cluster |
| Webhook endpoints | POST | mTLS (API Server Client Cert) | Kubernetes API Server | API server authenticates to webhook via client cert |
| RayCluster Dashboard (OpenShift) | GET, POST | OAuth2 (OpenShift) | oauth-proxy sidecar | OpenShift user authentication via OAuth |
| RayCluster Dashboard (Kubernetes) | GET, POST | None (Ingress) | Network level | No authentication (user responsibility) |
| RayCluster Client Port (10001) | TCP | mTLS Client Certificates | Ray cluster | Client certificate validation when mTLS enabled |

### Network Policies Created (per RayCluster)

#### Head Node Network Policy

| Rule | Source | Destination | Port | Protocol | Purpose |
|------|--------|-------------|------|----------|---------|
| 1 | Same RayCluster pods | Head node | All | All | Internal cluster communication |
| 2 | Same namespace (all pods) | Head node | 10001/TCP | TCP | Ray client access (mTLS) |
| 3 | Same namespace (all pods) | Head node | 8265/TCP | TCP | Ray dashboard HTTP |
| 4 | KubeRay operator namespace | Head node | 8265/TCP, 10001/TCP | TCP | KubeRay operator reconciliation |
| 5 | openshift-monitoring namespace | Head node | 8080/TCP | TCP | Prometheus metrics scraping |
| 6 | Any | Head node | 8443/TCP | TCP | OAuth proxy HTTPS (OpenShift) |
| 7 (if mTLS) | Any | Head node | 10001/TCP | TCP | Ray client mTLS endpoint |

#### Worker Node Network Policy

| Rule | Source | Destination | Port | Protocol | Purpose |
|------|--------|-------------|------|----------|---------|
| 1 | Same RayCluster pods | Worker node | All | All | Internal cluster communication only |

## Data Flows

### Flow 1: User Creates RayCluster Resource

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/kubectl | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | User credential (kubeconfig) |
| 2 | Kubernetes API Server | codeflare-operator webhook | 9443/TCP | HTTPS | TLS 1.2+ | API Server client cert (mTLS) |
| 3 | codeflare-operator webhook | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | codeflare-operator controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | codeflare-operator controller | KubeRay Operator (via API) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: User Accesses Ray Dashboard (OpenShift)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.3 | None |
| 2 | OpenShift Router | oauth-proxy sidecar | 8443/TCP | HTTPS | TLS 1.2+ | None |
| 3 | oauth-proxy | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth2 |
| 4 | oauth-proxy | Ray Dashboard | 8265/TCP | HTTP | None | Proxied session |

### Flow 3: Ray Client Connects to Cluster (mTLS enabled)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Ray Client Pod | Ray Head Service | 10001/TCP | TCP | mTLS | Client Certificate |
| 2 | Ray Head | Ray Workers | Various/TCP | TCP | mTLS | mTLS |

### Flow 4: Operator Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus (openshift-monitoring) | codeflare-operator-manager-metrics | 8080/TCP | HTTP | None | ServiceAccount Token |

### Flow 5: AppWrapper Workload Scheduling (when enabled)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | User credential |
| 2 | Kubernetes API Server | codeflare-operator webhook | 9443/TCP | HTTPS | TLS 1.2+ | API Server client cert |
| 3 | codeflare-operator controller | Kueue Workload API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Kueue | AppWrapper Controller (via watch) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| KubeRay Operator | CRD Watch/Update | 6443/TCP | HTTPS | TLS 1.2+ | Monitor RayCluster lifecycle, inject enhancements |
| Kueue | CRD Watch/Create | 6443/TCP | HTTPS | TLS 1.2+ | Create Workload resources for AppWrapper scheduling |
| OpenShift OAuth | OAuth2 HTTP | 443/TCP | HTTPS | TLS 1.2+ | Authenticate users accessing Ray dashboards |
| OpenShift Router | Route Ingress | 80/TCP, 443/TCP | HTTP/HTTPS | TLS 1.3 | External access to Ray dashboards and client ports |
| Prometheus | Metrics Scrape | 8080/TCP | HTTP | None | Operator health and performance metrics |
| opendatahub-operator | CRD Read | 6443/TCP | HTTPS | TLS 1.2+ | Discover ODH application namespace for network policies |
| Kubernetes Ingress Controller | Ingress (vanilla K8s) | 80/TCP, 443/TCP | HTTP/HTTPS | Variable | External access on non-OpenShift clusters |

## Configuration

The operator is configured via ConfigMap `codeflare-operator-config` with the following structure:

| Parameter | Type | Default | Purpose |
|-----------|------|---------|---------|
| kuberay.rayDashboardOAuthEnabled | bool | true | Enable OAuth proxy for Ray dashboard (OpenShift) |
| kuberay.mTLSEnabled | bool | true | Enable mTLS for Ray cluster communication |
| kuberay.ingressDomain | string | Auto-detected | Cluster ingress domain for route/ingress creation |
| appwrapper.enabled | bool | false | Enable embedded AppWrapper controller |
| clientConnection.qps | float32 | 50 | API server client QPS limit |
| clientConnection.burst | int32 | 100 | API server client burst limit |
| metrics.bindAddress | string | :8080 | Metrics server bind address |
| health.bindAddress | string | :8081 | Health probe server bind address |
| leaderElection.* | object | - | Leader election configuration for HA deployments |

## Deployment Architecture

The operator is deployed as a single-replica Deployment in the `opendatahub` namespace (RHOAI) with:
- **Resource Limits**: 1 CPU, 1Gi Memory
- **Resource Requests**: 1 CPU, 1Gi Memory
- **Security Context**: Non-root user (65532:65532), no privilege escalation, all capabilities dropped
- **Leader Election**: Configurable for HA (disabled by default)
- **Webhook Server**: Runs in-process on port 9443 with cert-controller managed certificates

## Build Information

- **Base Image (Build)**: registry.access.redhat.com/ubi8/go-toolset:1.25
- **Base Image (Runtime)**: registry.access.redhat.com/ubi8/ubi-minimal
- **Build Tags**: strictfipsruntime (FIPS 140-2 compliance)
- **CGO**: Enabled
- **User**: 65532:65532 (non-root)

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| cf25c0f | 2025-03 | chore(deps): update registry.access.redhat.com/ubi8/go-toolset:1.25 docker digest to e20b9b4 |
| e9a1a77 | 2025-03 | chore(deps): update registry.access.redhat.com/ubi8/go-toolset:1.25 docker digest to 10bd7b9 |
| 53e51a8 | 2025-03 | chore(deps): update registry.access.redhat.com/ubi8/ubi-minimal docker digest to b880e16 |
| 225d041 | 2025-03 | chore(deps): update registry.access.redhat.com/ubi8/go-toolset:1.25 docker digest to ff71f60 |
| 781ab81 | 2025-03 | chore(deps): update registry.access.redhat.com/ubi8/go-toolset:1.25 docker digest to d308645 |
| cd019ee | 2025-03 | Add PipelineRun configuration for odh-codeflare-operator-v2-16 on pull requests |
| 37f0ec1 | 2025-02 | Hardcode 1.25 go toolset version |
| 388ecab | 2025-02 | fix go toolset CVE |

**Note**: Recent changes primarily focus on dependency updates and Konflux pipeline configuration for RHOAI 2.16 release.

## Key Features

1. **Automatic OAuth Integration (OpenShift)**: Injects oauth-proxy sidecar into RayCluster head pods for secure dashboard access
2. **mTLS Support**: Configurable mutual TLS for Ray cluster internal communication
3. **Network Isolation**: Automatically creates NetworkPolicies to restrict RayCluster traffic
4. **Multi-Platform**: Works on both OpenShift (with enhanced features) and vanilla Kubernetes
5. **Kueue Integration**: AppWrapper controller integrates with Kueue for advanced workload scheduling
6. **Certificate Management**: Automated TLS certificate generation and rotation for webhooks and Ray clusters
7. **Monitoring**: Prometheus metrics and ServiceMonitor integration
8. **Dynamic Configuration**: Runtime configuration via ConfigMap without operator restart

## Known Limitations

1. AppWrapper controller requires Kueue workload API to be available at startup; otherwise requires operator restart when Kueue becomes available
2. OAuth dashboard access only available on OpenShift; vanilla Kubernetes deployments have no authentication on dashboard by default
3. Operator runs single replica by default (leader election configurable but not enabled)
4. Network policies assume KubeRay operator is in opendatahub or redhat-ods-applications namespace
