# Component: CodeFlare Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/codeflare-operator.git
- **Version**: v1.9.0
- **Branch**: rhoai-2.14
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes operator for lifecycle management of the CodeFlare distributed workload stack, providing Ray cluster orchestration and batch job scheduling.

**Detailed**: The CodeFlare Operator manages distributed AI/ML workloads on Kubernetes by orchestrating Ray clusters and AppWrapper resources. It extends KubeRay's RayCluster CRD with enterprise security features including OAuth-based authentication, mutual TLS (mTLS) encryption, and network isolation policies. The operator embeds the AppWrapper controller to provide advanced batch scheduling capabilities, integrating with Kueue for resource quota management and fair sharing. It automatically provisions secure ingress/routes, manages TLS certificates, and enforces network policies to isolate workload communication. The operator is designed for OpenShift and vanilla Kubernetes, providing a unified distributed computing platform for RHOAI.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Operator Manager | Deployment | Main controller process managing RayCluster and AppWrapper reconciliation |
| RayCluster Controller | Reconciler | Watches RayCluster CRs and adds OAuth, mTLS, network policies, ingress/routes |
| AppWrapper Controller | Reconciler | Manages AppWrapper CRs for batch workload scheduling and lifecycle |
| RayCluster Webhook | MutatingWebhook | Injects OAuth sidecar, mTLS init containers, and security configurations into RayCluster pods |
| AppWrapper Webhook | MutatingWebhook | Validates and mutates AppWrapper resources for Kueue integration |
| Certificate Rotator | Controller | Manages webhook TLS certificates and rotation |
| Metrics Exporter | HTTP Server | Exposes Prometheus metrics on operator performance |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| workload.codeflare.dev | v1beta2 | AppWrapper | Namespaced | Wraps multiple Kubernetes resources (Jobs, RayClusters, PyTorchJobs) as a single schedulable unit with quota reservation |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint for operator monitoring |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint (waits for certificate generation) |
| /mutate-workload-codeflare-dev-v1beta2-appwrapper | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS client cert | Mutating webhook for AppWrapper resources |
| /validate-workload-codeflare-dev-v1beta2-appwrapper | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS client cert | Validating webhook for AppWrapper resources |
| /mutate-ray-io-v1-raycluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS client cert | Mutating webhook for RayCluster resources |
| /validate-ray-io-v1-raycluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS client cert | Validating webhook for RayCluster resources |

### Watched External CRDs

| Group | Version | Kind | Source | Purpose |
|-------|---------|------|--------|---------|
| ray.io | v1 | RayCluster | KubeRay Operator | Distributed Ray compute clusters - operator adds security and networking |
| ray.io | v1 | RayJob | KubeRay Operator | Ray job submissions - managed as AppWrapper components |
| kueue.x-k8s.io | v1beta1 | Workload | Kueue | Job queue integration for AppWrapper quota management |
| dscinitialization.opendatahub.io | v1 | DSCInitialization | ODH Operator | Platform configuration to locate KubeRay operator namespace |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| KubeRay Operator | v1.1.0 | Yes | Manages Ray cluster lifecycle (pods, services) |
| Kueue | v0.8.1 | No | Job queueing and quota management for AppWrappers |
| cert-controller | Latest | Yes | Automatic webhook certificate generation and rotation |
| OpenShift Route API | v1 | No | Ingress via Routes on OpenShift (alternatives: Kubernetes Ingress) |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | CRD (RayCluster) | Users create RayCluster resources from dashboard UI |
| OpenShift OAuth | OAuth Proxy | Authenticates users accessing Ray dashboard |
| OpenShift Monitoring | ServiceMonitor | Scrapes operator metrics for platform monitoring |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| codeflare-operator-webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | mTLS | Internal |
| codeflare-operator-manager-metrics | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |
| {raycluster}-head-svc (per cluster) | ClusterIP | 8265/TCP, 10001/TCP | 8265, 10001 | HTTP/gRPC | Varies | Varies | Internal |
| {raycluster}-oauth (per cluster) | ClusterIP | 443/TCP | 8443 | HTTPS | TLS 1.2+ | OAuth | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {raycluster}-dashboard (OpenShift) | Route | auto-generated | 443/TCP | HTTPS | TLS 1.2+ | Edge | External |
| {raycluster}-client (OpenShift) | Route | auto-generated | 443/TCP | HTTPS | TLS 1.2+ | Edge | External |
| {raycluster}-dashboard (Kubernetes) | Ingress | {cluster}-{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | Edge | External |
| {raycluster}-client (Kubernetes) | Ingress | {cluster}-{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | Edge | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | CRD reconciliation and resource management |
| KubeRay Operator | 8265/TCP, 10001/TCP | HTTP/gRPC | Optional mTLS | None/mTLS | Monitor RayCluster status and health |
| Kueue API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Workload admission and quota checks |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| codeflare-operator-manager-role | "" | pods, services, secrets, serviceaccounts, events | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | "" | nodes | get, list, watch |
| codeflare-operator-manager-role | apps | deployments, statefulsets | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | batch | jobs | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | ray.io | rayclusters, rayclusters/status, rayclusters/finalizers | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | ray.io | rayjobs | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | workload.codeflare.dev | appwrappers, appwrappers/status, appwrappers/finalizers | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | kueue.x-k8s.io | workloads, workloads/status, workloads/finalizers | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | kueue.x-k8s.io | clusterqueues, resourceflavors, workloadpriorityclasses | get, list, watch, update, patch |
| codeflare-operator-manager-role | networking.k8s.io | ingresses, networkpolicies | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | rbac.authorization.k8s.io | clusterrolebindings | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | route.openshift.io | routes, routes/custom-host | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | get, list, watch, update |
| codeflare-operator-manager-role | apiextensions.k8s.io | customresourcedefinitions | get, list, watch |
| codeflare-operator-manager-role | config.openshift.io | ingresses | get |
| codeflare-operator-manager-role | dscinitialization.opendatahub.io | dscinitializations | get, list, watch |
| codeflare-operator-manager-role | kubeflow.org | pytorchjobs | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | scheduling.k8s.io | priorityclasses | get, list, watch |
| codeflare-operator-manager-role | scheduling.sigs.k8s.io, scheduling.x-k8s.io | podgroups | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | authentication.k8s.io | tokenreviews | create |
| codeflare-operator-manager-role | authorization.k8s.io | subjectaccessreviews | create |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| codeflare-operator-manager-rolebinding | Cluster-wide | codeflare-operator-manager-role | {namespace}/codeflare-operator-controller-manager |
| codeflare-operator-leader-election-rolebinding | {operator-namespace} | codeflare-operator-leader-election-role | {namespace}/codeflare-operator-controller-manager |

### RBAC - Per-RayCluster Resources

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| {raycluster}-oauth-crb | Cluster-wide | system:auth-delegator | {namespace}/{raycluster}-oauth-proxy |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| codeflare-operator-webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificate | cert-controller | Yes |
| {raycluster}-ca-secret (per cluster) | Opaque | Self-signed CA for mTLS between Ray components | codeflare-operator | No |
| {raycluster}-oauth-config (per cluster) | Opaque | OAuth proxy configuration (cookie secret, provider config) | codeflare-operator | No |
| {raycluster}-tls (per cluster) | kubernetes.io/tls | TLS certificate for OAuth proxy service | OpenShift Route / cert-manager | Yes (OpenShift) |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| Ray Dashboard (via Route) | GET, POST | OpenShift OAuth (Browser redirect) | OAuth Proxy Sidecar | Requires valid OpenShift user session |
| Ray Client (port 10001) | gRPC | mTLS client certificates | Ray Head Pod | Requires valid client cert signed by cluster CA |
| Ray Dashboard (internal, port 8265) | GET, POST | None (protected by NetworkPolicy) | NetworkPolicy | Only accessible from same namespace pods |
| Webhook Endpoints | POST | Kubernetes API Server mTLS | Kubernetes API Server | Valid API server client certificate required |
| Metrics Endpoint | GET | None (protected by NetworkPolicy) | NetworkPolicy | Accessible from openshift-monitoring namespace only |

### Network Policies

| Policy Name | Selector | Ingress Rules | Egress Rules |
|-------------|----------|---------------|--------------|
| {raycluster}-head | ray.io/node-type=head | All traffic from same cluster pods; Port 10001,8265 from same namespace; Port 8080 from openshift-monitoring; Ports 8443,10001 (if mTLS) unrestricted | N/A (default allow) |
| {raycluster}-workers | ray.io/node-type=worker | All traffic from same cluster pods only | N/A (default allow) |

## Data Flows

### Flow 1: User Accesses Ray Dashboard (OpenShift)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | OpenShift Router | {raycluster}-oauth Route | 443/TCP | HTTPS | TLS 1.2+ (Edge) | None |
| 3 | Route | OAuth Proxy Sidecar (RayCluster Head Pod) | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Token (cookie) |
| 4 | OAuth Proxy | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | Client credentials |
| 5 | OAuth Proxy | Ray Dashboard (localhost) | 8265/TCP | HTTP | None | None (local) |

### Flow 2: RayCluster Creation and Security Setup

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Dashboard | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (User SA) |
| 2 | API Server | CodeFlare Webhook | 9443/TCP | HTTPS | TLS 1.2+ | mTLS |
| 3 | API Server | CodeFlare Operator (Watch) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (Operator SA) |
| 4 | CodeFlare Operator | Kubernetes API Server (Create NetworkPolicy) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (Operator SA) |
| 5 | CodeFlare Operator | Kubernetes API Server (Create Route/Ingress) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (Operator SA) |
| 6 | CodeFlare Operator | Kubernetes API Server (Create OAuth Resources) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (Operator SA) |
| 7 | KubeRay Operator | Kubernetes API Server (Create Ray Pods) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (KubeRay SA) |

### Flow 3: AppWrapper Admission and Workload Scheduling

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | API Server | CodeFlare AppWrapper Webhook | 9443/TCP | HTTPS | TLS 1.2+ | mTLS |
| 3 | API Server | CodeFlare Operator (Watch AppWrapper) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (Operator SA) |
| 4 | CodeFlare Operator | Kubernetes API Server (Create Kueue Workload) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (Operator SA) |
| 5 | Kueue | Kubernetes API Server (Update Workload Status) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (Kueue SA) |
| 6 | CodeFlare Operator | Kubernetes API Server (Deploy Wrapped Resources) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (Operator SA) |

### Flow 4: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus (openshift-monitoring) | codeflare-operator-manager-metrics Service | 8080/TCP | HTTP | None | ServiceAccount Token (Bearer) |
| 2 | Prometheus | Ray Head Pod (metrics endpoint) | 8080/TCP | HTTP | None | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| KubeRay Operator | CRD Watch | 6443/TCP | HTTPS | TLS 1.2+ | Monitor RayCluster CRDs to add security enhancements |
| Kueue | CRD (Workload API) | 6443/TCP | HTTPS | TLS 1.2+ | Submit AppWrapper workloads for quota-based scheduling |
| OpenShift OAuth | OAuth 2.0 / OIDC | 443/TCP | HTTPS | TLS 1.2+ | Authenticate users accessing Ray dashboards |
| OpenShift Router | Route API | 6443/TCP | HTTPS | TLS 1.2+ | Expose Ray clusters via external routes |
| OpenShift Monitoring | ServiceMonitor API | 6443/TCP | HTTPS | TLS 1.2+ | Automatic metrics discovery and scraping |
| ODH Dashboard | CRD Creation | 6443/TCP | HTTPS | TLS 1.2+ | Users create RayCluster/AppWrapper via UI |

## Configuration

### ConfigMap

| Name | Namespace | Purpose | Key Parameters |
|------|-----------|---------|----------------|
| codeflare-operator-config | {operator-namespace} | Operator runtime configuration | `kuberay.rayDashboardOAuthEnabled` (default: true), `kuberay.mTLSEnabled` (default: true), `kuberay.ingressDomain`, `appwrapper.enabled` (default: false) |

### Environment Variables

| Name | Source | Purpose |
|------|--------|---------|
| NAMESPACE | Downward API (metadata.namespace) | Determine operator deployment namespace for webhook cert secret |

## Deployment Architecture

### Operator Deployment

| Property | Value |
|----------|-------|
| Replicas | 1 |
| Resource Requests | CPU: 1, Memory: 1Gi |
| Resource Limits | CPU: 1, Memory: 1Gi |
| Security Context | runAsNonRoot: true, allowPrivilegeEscalation: false, capabilities dropped: ALL |
| Image Pull Policy | Always |
| Service Account | codeflare-operator-controller-manager |

### High Availability

| Feature | Implementation |
|---------|----------------|
| Leader Election | Optional (disabled by default) - single active replica |
| Webhook HA | Webhook server runs in both primary and secondary instances (no leader election requirement) |
| Failure Recovery | Kubernetes Deployment auto-restart on failure |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 59a1d23 | 2024 Q4 | Update dependency versions for release v1.9.0 |
| 9c10a6a | 2024 Q4 | Update appwrappers to v0.25.0 |
| f500555 | 2024 Q4 | Create kueue resources as part of test execution |
| a54b426 | 2024 Q4 | Update codeflare-common version to remove replace for prometheus/common |

## Operational Notes

### Monitoring

- **Metrics**: Exposed on port 8080 at `/metrics` endpoint (Prometheus format)
- **ServiceMonitor**: Automatically discovered by OpenShift cluster monitoring
- **Key Metrics**: Controller reconciliation rates, webhook latency, certificate expiration

### Health Checks

- **Liveness**: `/healthz` on port 8081 (simple ping)
- **Readiness**: `/readyz` on port 8081 (checks webhook certificate readiness)

### Certificate Management

- **Webhook Certificates**: Auto-generated and rotated by cert-controller
- **Ray CA Certificates**: Self-signed, generated per RayCluster, stored in `{raycluster}-ca-secret`
- **Certificate Lifetime**: Webhook certs rotate automatically; Ray CA certs persist with cluster lifecycle

### Troubleshooting

| Symptom | Likely Cause | Resolution |
|---------|--------------|------------|
| RayCluster pods fail admission | Webhook certificate not ready | Check readiness probe, wait for cert-controller |
| Ray dashboard inaccessible | OAuth proxy misconfiguration | Check {raycluster}-oauth-config secret, verify OAuth ClusterRoleBinding |
| mTLS connection failures | Missing/invalid CA certificate | Verify {raycluster}-ca-secret exists and is mounted correctly |
| AppWrapper stuck in pending | Kueue workload API unavailable | Check Kueue installation, verify CRDs installed |
| Network policy blocking traffic | Incorrect namespace labels | Verify KubeRay operator namespace matches DSCInitialization.spec.applicationsNamespace |

### Scaling Considerations

- **Operator**: Single replica sufficient for most deployments (no horizontal scaling needed)
- **RayClusters**: Operator manages unlimited RayClusters across namespaces
- **AppWrappers**: Performance depends on Kueue cluster queue configuration
- **Webhook Latency**: Single replica can handle 100s of requests/sec

## Known Limitations

1. **AppWrapper Controller**: Disabled by default, requires Kueue installation and manual config map update to enable
2. **OpenShift OAuth**: Only available on OpenShift; vanilla Kubernetes uses basic ingress without OAuth
3. **mTLS Certificate Rotation**: Ray CA certificates don't auto-rotate; requires RayCluster recreation for rotation
4. **Namespace Isolation**: Network policies assume KubeRay operator is in known namespace(s)
5. **Single Ingress Domain**: All RayClusters share same ingress domain configured in operator config map
