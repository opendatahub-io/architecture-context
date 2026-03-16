# Component: CodeFlare Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/codeflare-operator.git
- **Version**: v-2160 (rhoai-2.9 branch, commit f0697e4)
- **Distribution**: RHOAI
- **Languages**: Go 1.20
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Enhances KubeRay RayClusters with OAuth authentication, mTLS encryption, and network security policies.

**Detailed**: The CodeFlare operator is a Kubernetes operator that manages the lifecycle and security configuration of Ray distributed computing clusters. It watches for RayCluster custom resources (provided by the KubeRay operator) and automatically enhances them with enterprise-grade security features including OAuth-based authentication for the Ray Dashboard (on OpenShift), mutual TLS encryption for Ray cluster communication, and NetworkPolicies for pod-level network segmentation. The operator also manages external access through OpenShift Routes or Kubernetes Ingresses, and provides certificate management for both webhook server certificates and Ray cluster CA certificates. It acts as a security and networking layer on top of the KubeRay operator, making Ray clusters production-ready for ODH/RHOAI deployments.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| RayCluster Controller | Reconciler | Watches RayCluster CRDs and creates OAuth proxies, mTLS certificates, NetworkPolicies, Routes/Ingresses |
| RayCluster Mutating Webhook | Admission Webhook | Injects OAuth proxy sidecar and mTLS init containers into RayCluster pods |
| RayCluster Validating Webhook | Admission Webhook | Validates RayCluster configuration for OAuth and mTLS requirements |
| Certificate Controller | Certificate Manager | Rotates and manages webhook server TLS certificates |
| Operator Manager | Deployment | Runs controller, webhooks, metrics, and health endpoints |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| ray.io | v1 | RayCluster | Namespaced | Watches external CRD from KubeRay operator (does not define it) |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe (waits for webhook certs) |
| /mutate-ray-io-v1-raycluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Mutating admission webhook for RayCluster |
| /validate-ray-io-v1-raycluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Validating admission webhook for RayCluster |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | No gRPC services exposed |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| KubeRay Operator | v1.1.0 | Yes | Provides RayCluster CRD and manages Ray cluster lifecycle |
| cert-controller | v0.10.1 | Yes | Rotates webhook TLS certificates |
| OpenShift OAuth Proxy | latest | No | OAuth authentication for Ray Dashboard (OpenShift only) |
| OpenShift Routes API | N/A | No | External access to Ray Dashboard (OpenShift only) |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| DSCInitialization | CRD Read | Optional: discovers ODH/RHOAI application namespace for KubeRay operator location |
| KubeRay Operator (ODH-deployed) | NetworkPolicy | Creates NetworkPolicies allowing KubeRay operator to communicate with Ray clusters |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| codeflare-operator-webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | K8s API Server mTLS | Internal |
| codeflare-operator-manager-metrics | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |
| {raycluster-name}-oauth (created per RayCluster) | ClusterIP | 443/TCP | 8443 | HTTPS | TLS 1.2+ (OpenShift service-serving-cert) | OAuth proxy | Internal (OpenShift) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| ray-dashboard-{cluster} (created per RayCluster) | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ | Re-encrypt | External (OpenShift) |
| rayclient-{cluster} (created per RayCluster) | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ | Passthrough | External (OpenShift) |
| ray-dashboard-{cluster} (created per RayCluster) | Ingress | Configured via IngressDomain | 443/TCP | HTTPS | TLS | None (handled by ingress controller) | External (Kubernetes) |
| rayclient-{cluster} (created per RayCluster) | Ingress | Configured via IngressDomain | 443/TCP | HTTPS | TLS | Passthrough (nginx annotation) | External (Kubernetes) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token | Controller operations, webhook calls |
| OpenShift Config API | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token | Retrieve cluster ingress domain (OpenShift) |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | "" | secrets | get, list, watch, update, create, patch, delete |
| manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | get, list, watch, update |
| manager-role | apiextensions.k8s.io | customresourcedefinitions | get, list, watch |
| manager-role | authentication.k8s.io | tokenreviews | create |
| manager-role | authorization.k8s.io | subjectaccessreviews | create |
| manager-role | config.openshift.io | ingresses | get |
| manager-role | "" | services, serviceaccounts | get, create, update, patch, delete |
| manager-role | dscinitialization.opendatahub.io | dscinitializations | get, list, watch |
| manager-role | networking.k8s.io | ingresses, networkpolicies | get, create, update, patch, delete |
| manager-role | ray.io | rayclusters | get, list, watch, create, update, patch, delete |
| manager-role | ray.io | rayclusters/status | get, update, patch |
| manager-role | ray.io | rayclusters/finalizers | update |
| manager-role | rbac.authorization.k8s.io | clusterrolebindings | get, create, update, patch, delete |
| manager-role | route.openshift.io | routes, routes/custom-host | get, create, update, patch, delete |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | Operator namespace | manager-role (ClusterRole) | controller-manager |
| leader-election-rolebinding | Operator namespace | leader-election-role (Role) | controller-manager |
| {cluster}-{namespace}-auth (created per RayCluster) | Cluster-wide | system:auth-delegator (ClusterRole) | {cluster}-oauth-proxy |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| codeflare-operator-webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificate | cert-controller | Yes |
| {cluster}-oauth-config (per RayCluster) | Opaque | OAuth proxy cookie secret | CodeFlare operator | No |
| {cluster}-proxy-tls-secret (per RayCluster) | kubernetes.io/tls | OAuth proxy service TLS certificate | OpenShift service-serving-cert | Yes (OpenShift) |
| ca-secret-{cluster} (per RayCluster) | Opaque | Ray cluster CA private key and certificate for mTLS | CodeFlare operator | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /mutate-ray-io-v1-raycluster | POST | K8s API Server mTLS | Kubernetes API Server | K8s RBAC |
| /validate-ray-io-v1-raycluster | POST | K8s API Server mTLS | Kubernetes API Server | K8s RBAC |
| /metrics | GET | None | None | ServiceMonitor with bearer token (when enabled) |
| /healthz, /readyz | GET | None | None | Open (for kubelet probes) |
| Ray Dashboard (via OAuth proxy) | GET, POST | OpenShift OAuth | OAuth proxy sidecar | OpenShift RBAC (delegate to pod get verb) |
| RayClient (mTLS) | gRPC | mTLS client certificates | Ray head node | Ray cluster CA |

## Data Flows

### Flow 1: RayCluster Creation with OAuth and mTLS (OpenShift)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/KubeRay Operator | K8s API Server | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 2 | K8s API Server | CodeFlare Mutating Webhook | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS |
| 3 | Mutating Webhook | K8s API Server (response) | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 4 | K8s API Server | CodeFlare Validating Webhook | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS |
| 5 | CodeFlare Controller | K8s API Server | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 6 | CodeFlare Controller | K8s API Server (create CA Secret) | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 7 | CodeFlare Controller | K8s API Server (create OAuth Secret) | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 8 | CodeFlare Controller | K8s API Server (create OAuth Service) | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 9 | CodeFlare Controller | K8s API Server (create Route) | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 10 | CodeFlare Controller | K8s API Server (create NetworkPolicies) | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token |

### Flow 2: User Access to Ray Dashboard via OAuth (OpenShift)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router (Route) | 443/TCP | HTTPS | TLS 1.2+ | None (redirects to OAuth) |
| 2 | OpenShift Router | OAuth Proxy Sidecar (in Ray head pod) | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Token |
| 3 | OAuth Proxy | Ray Dashboard (localhost) | 8265/TCP | HTTP | None (localhost) | None (localhost trust) |

### Flow 3: KubeRay Operator Managing Ray Cluster

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | KubeRay Operator | Ray Head Service | 8265/TCP | HTTP | None | None |
| 2 | KubeRay Operator | Ray Head Service (client port) | 10001/TCP | TCP | mTLS (if enabled) | mTLS client cert |

### Flow 4: Ray Worker to Ray Head (mTLS enabled)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Ray Worker Pod | Ray Head Pod | 10001/TCP | TCP | mTLS | Ray cluster CA |
| 2 | Ray Worker Pod | Ray Head Pod | 8265/TCP | HTTP | None | Internal cluster |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| KubeRay Operator | Watch CRD | 443/TCP | HTTPS | TLS 1.2+ | Watches for rayclusters.ray.io CRD to become available |
| KubeRay Operator | NetworkPolicy | 8265/TCP, 10001/TCP | HTTP, gRPC | mTLS (port 10001) | Allows KubeRay operator to manage Ray clusters |
| OpenShift OAuth | HTTP Redirect | 443/TCP | HTTPS | TLS 1.2+ | OAuth authentication for Ray Dashboard access |
| Prometheus (OpenShift Monitoring) | ServiceMonitor | 8080/TCP | HTTPS | TLS (via service-serving-cert) | Scrapes operator metrics |
| cert-controller | Certificate Rotation | Internal API | Internal | Internal | Manages webhook certificate lifecycle |

## Network Policies Created by Operator

### NetworkPolicy: {cluster}-head (per RayCluster)

**Pod Selector**: `ray.io/cluster={cluster}, ray.io/node-type=head`

**Ingress Rules**:
1. **From same Ray cluster pods**: All ports, all protocols
2. **From any pod in same namespace**: Ports 10001/TCP (RayClient, if mTLS), 8265/TCP (Dashboard)
3. **From KubeRay operator**: Ports 8265/TCP, 10001/TCP
   - Source: Pods with label `app.kubernetes.io/component=kuberay-operator`
   - Namespaces: `opendatahub`, `redhat-ods-applications`, or DSCInitialization.spec.applicationsNamespace
4. **From OpenShift monitoring**: Port 8080/TCP
   - Source: Namespace `openshift-monitoring`
5. **OAuth/mTLS secured ports**: Ports 8443/TCP (OAuth), 10001/TCP (mTLS, if enabled)
   - Source: Any

### NetworkPolicy: {cluster}-workers (per RayCluster)

**Pod Selector**: `ray.io/cluster={cluster}, ray.io/node-type=worker`

**Ingress Rules**:
1. **From same Ray cluster pods**: All ports, all protocols
   - Source: Pods with label `ray.io/cluster={cluster}`

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| f0697e4 | 2024 | - PATCH: use namespace from ray cluster |
| f04e3fe | 2024 | - PATCH: Start RayCluster controller only after CRD is established |
| eb5a70f | 2024 | - CARRY: Add workflow to release ODH/CFO with compiled test binaries |
| 100d94c | 2024 | - PATCH: Adjust DSC source path for CodeFlare |
| cb9363b | 2024 | - CARRY: update(manifests): use default namespace from ODH |
| 1e0c1e8 | 2024 | - CARRY: Generate CodeFlare stack config map |
| 8122767 | 2024 | - CARRY: Add Makefile and configuration files for e2e execution on OpenShift CI |
| 12b72cb | 2024 | - Altered network policy to allow all traffic for head & worker pods |
| fa700fa | 2024 | - Fix OLM PR check by creating ConfigMap disabling oauth |
| v1.4.0 | 2024 | - Update dependency versions for release v1.4.0<br>- Add cfg check for mtls before enabling access to client<br>- Add entry for rayclient to allow all connections<br>- Fix missing certificate volume mounts to RayCluster<br>- Update RayCluster CA certificate common and issuer names<br>- Generate RayCluster CA certificate Secret |

## Deployment Configuration

### Container Image
- **Build**: Multi-stage Dockerfile using UBI8 Go toolset 1.20.10
- **Base Image**: registry.access.redhat.com/ubi8/ubi-minimal:8.8
- **Build Flags**: CGO_ENABLED=1, GOOS=linux, GOARCH=amd64, -tags strictfipsruntime
- **User**: 65532:65532 (non-root)

### Resource Requirements
- **CPU Request**: 1 core
- **CPU Limit**: 1 core
- **Memory Request**: 1Gi
- **Memory Limit**: 1Gi

### ConfigMap Configuration
- **Name**: codeflare-operator-config
- **Purpose**: Operator configuration
- **Key Settings**:
  - `rayDashboardOAuthEnabled`: Enable OAuth proxy (default: true)
  - `mTLSEnabled`: Enable mTLS for Ray clusters (default: true)
  - `ingressDomain`: Domain for Kubernetes Ingresses (auto-detected on OpenShift)
  - `clientConnection.qps`: API server QPS (default: 50)
  - `clientConnection.burst`: API server burst (default: 100)
  - `metrics.bindAddress`: Metrics endpoint (default: :8080)
  - `health.bindAddress`: Health endpoint (default: :8081)

## Operational Notes

### Prerequisites
1. **KubeRay Operator** must be deployed and the RayCluster CRD must be established before CodeFlare operator starts reconciliation
2. **DSCInitialization** (optional) for discovering ODH/RHOAI application namespace
3. **OpenShift** (optional) for OAuth proxy and Routes functionality

### Platform Detection
- Operator detects OpenShift vs vanilla Kubernetes by checking for `*.openshift.io` API groups
- On OpenShift: Creates Routes and OAuth proxy sidecars
- On Kubernetes: Creates Ingresses (requires IngressDomain configuration)

### Certificate Management
- Webhook certificates are automatically rotated by cert-controller
- Ray cluster CA certificates are generated once per cluster and stored in secrets
- OAuth proxy TLS certificates are managed by OpenShift service-serving-cert controller

### Monitoring
- Prometheus metrics exposed on port 8080
- ServiceMonitor can be created for automatic Prometheus scraping
- Health probes on port 8081 for liveness and readiness

### Failure Modes
- Operator waits indefinitely for RayCluster CRD to be established before starting controller
- Webhook readiness check blocks until certificates are ready
- RayCluster reconciliation requeues every 10 seconds on errors
