# Component: CodeFlare Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/codeflare-operator.git
- **Version**: 4e58587 (rhoai-2.12 branch)
- **Distribution**: RHOAI
- **Languages**: Go 1.22.2
- **Deployment Type**: Kubernetes Operator
- **Manifests Location**: config/ (kustomize)

## Purpose
**Short**: Operator for installation and lifecycle management of CodeFlare distributed workload stack.

**Detailed**: The CodeFlare Operator manages the deployment and lifecycle of the CodeFlare distributed workload orchestration stack on Kubernetes and OpenShift. It provides cluster-scoped reconciliation of RayCluster resources and optional AppWrapper resources for job queueing and resource management. The operator enhances RayCluster deployments with OAuth-protected dashboard access, mutual TLS (mTLS) for inter-node communication, and network policies for secure pod-to-pod communication. It integrates with Kueue for workload queue management and supports both vanilla Kubernetes and OpenShift environments with platform-specific features like Routes and OAuth proxy integration.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| codeflare-operator-manager | Go Operator (Deployment) | Reconciles RayCluster and AppWrapper CRDs, manages webhooks, and configures security features |
| RayCluster Controller | Controller | Watches RayCluster CRs and creates supporting resources (services, ingresses/routes, secrets, network policies) |
| AppWrapper Controller | Controller (Optional) | Manages AppWrapper workload queuing with Kueue integration when enabled |
| Mutating Webhook | Admission Webhook | Injects OAuth proxy sidecar and mTLS init containers into RayCluster pods |
| Validating Webhook | Admission Webhook | Validates RayCluster and AppWrapper specifications on create/update |
| Certificate Manager | cert-controller | Manages webhook TLS certificates and CA certificates for mTLS |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| workload.codeflare.dev | v1beta2 | AppWrapper | Namespaced | Wraps Kubernetes resources for batch job scheduling with Kueue integration |

**Note**: The operator also watches and mutates RayCluster CRDs from ray.io/v1 (owned by KubeRay operator).

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for operator monitoring |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint (checks webhook cert readiness) |
| /mutate-workload-codeflare-dev-v1beta2-appwrapper | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Mutating webhook for AppWrapper CREATE |
| /validate-workload-codeflare-dev-v1beta2-appwrapper | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Validating webhook for AppWrapper CREATE/UPDATE |
| /mutate-ray-io-v1-raycluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Mutating webhook for RayCluster CREATE (injects OAuth/mTLS) |
| /validate-ray-io-v1-raycluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Validating webhook for RayCluster CREATE/UPDATE |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| KubeRay Operator | v1.1.1 | Yes | Provides RayCluster CRD and manages Ray cluster lifecycle |
| Kueue | v0.7.0 (ODH fork) | No | Workload queue management for AppWrapper resources |
| cert-manager or OCP cert-controller | N/A | Yes | Certificate rotation for webhooks and mTLS CA |
| Istio Service Mesh | N/A | No | Optional service mesh integration for enhanced security |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| opendatahub-operator | CRD Watch (DSCInitialization) | Detects ODH/RHOAI platform presence and configuration |
| Prometheus | ServiceMonitor | Metrics collection for operator monitoring |
| OpenShift OAuth | OAuth Proxy | Dashboard authentication on OpenShift platforms |
| OpenShift Routes | API (route.openshift.io/v1) | External ingress for Ray dashboard on OpenShift |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| codeflare-operator-webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | K8s API Server mTLS | Internal (API Server) |
| codeflare-operator-manager-metrics | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (Prometheus) |
| {raycluster}-head-svc | ClusterIP | 443/TCP | 8443 | HTTPS | TLS 1.2+ | OAuth Bearer Token | Internal (via Ingress/Route) |

**Note**: RayCluster services are created dynamically per cluster by the controller.

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {raycluster}-ingress | Ingress (K8s) | {cluster}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | Edge/Passthrough | External |
| {raycluster}-route | Route (OpenShift) | {cluster}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | Edge | External |

**Note**: Ingress or Route created per RayCluster for dashboard access, platform-dependent.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch CRDs, manage resources |
| OpenShift API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Query cluster domain, manage Routes (OpenShift only) |

### Network Policies

The operator creates NetworkPolicies for each RayCluster to control pod-to-pod communication:

| Policy | Direction | Ports | Purpose |
|--------|-----------|-------|---------|
| Ray Head Ingress | Ingress | 8443/TCP (OAuth), 8080/TCP (Dashboard) | Allow OAuth proxy and dashboard traffic |
| Ray Worker Egress | Egress | All | Allow workers to communicate with head node |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| codeflare-operator-manager-role | "" | pods, services, secrets, serviceaccounts, events, nodes | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | apps | deployments, statefulsets | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | batch | jobs | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | ray.io | rayclusters, rayclusters/status, rayclusters/finalizers, rayjobs | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | workload.codeflare.dev | appwrappers, appwrappers/status, appwrappers/finalizers | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | kueue.x-k8s.io | workloads, workloads/status, workloads/finalizers, resourceflavors, workloadpriorityclasses | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | networking.k8s.io | ingresses, networkpolicies | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | route.openshift.io | routes, routes/custom-host | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | rbac.authorization.k8s.io | clusterrolebindings | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | get, list, watch, update |
| codeflare-operator-manager-role | apiextensions.k8s.io | customresourcedefinitions | get, list, watch |
| codeflare-operator-manager-role | authentication.k8s.io | tokenreviews | create |
| codeflare-operator-manager-role | authorization.k8s.io | subjectaccessreviews | create |
| codeflare-operator-manager-role | config.openshift.io | ingresses | get |
| codeflare-operator-manager-role | dscinitialization.opendatahub.io | dscinitializations | get, list, watch |
| codeflare-operator-manager-role | kubeflow.org | pytorchjobs | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | scheduling.k8s.io | priorityclasses | get, list, watch |
| codeflare-operator-manager-role | scheduling.sigs.k8s.io, scheduling.x-k8s.io | podgroups | get, list, watch, create, update, patch, delete |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| codeflare-operator-manager-rolebinding | All (ClusterRoleBinding) | codeflare-operator-manager-role | {namespace}/codeflare-operator-controller-manager |
| codeflare-operator-leader-election-rolebinding | {namespace} | codeflare-operator-leader-election-role | {namespace}/codeflare-operator-controller-manager |

**Note**: OAuth proxy service accounts are created per RayCluster with OpenShift-specific permissions.

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| codeflare-operator-webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificate | cert-controller | Yes |
| {raycluster}-ca-secret | Opaque | CA certificate and private key for mTLS | codeflare-operator | No |
| {raycluster}-oauth-proxy-tls | kubernetes.io/tls | TLS certificate for OAuth proxy service | codeflare-operator (self-signed) | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None | None | Open to cluster network |
| /healthz, /readyz | GET | None | None | Open to cluster network |
| Webhook endpoints | POST | mTLS | API Server | API Server validates client cert |
| Ray Dashboard (via OAuth) | GET, POST | OAuth Bearer Token (JWT) | OAuth Proxy Sidecar | OpenShift OAuth validation |
| Ray Dashboard (direct) | GET, POST | None (behind OAuth proxy) | Network Policy | Internal cluster only |

### mTLS Configuration

The operator automatically configures mTLS for RayCluster inter-node communication when `mTLSEnabled: true` (default):

| Component | Certificate | Purpose |
|-----------|-------------|---------|
| Ray Head Init Container | Self-signed cert from CA | Generates node certificate |
| Ray Worker Init Container | Self-signed cert from CA | Generates node certificate |
| CA Secret | {raycluster}-ca-secret | Shared CA for cluster-wide trust |

**Environment Variables Set for mTLS**:
- `RAY_TLS_SERVER_CERT`, `RAY_TLS_SERVER_KEY`, `RAY_TLS_CA_CERT`

## Data Flows

### Flow 1: User Creates RayCluster

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User (kubectl/oc) | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | API Server | codeflare-operator (mutating webhook) | 9443/TCP | HTTPS | TLS 1.2+ (mTLS) | API Server client cert |
| 3 | API Server | codeflare-operator (validating webhook) | 9443/TCP | HTTPS | TLS 1.2+ (mTLS) | API Server client cert |
| 4 | codeflare-operator | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

**Details**: Operator mutates RayCluster to inject OAuth proxy sidecar and mTLS init containers, then validates configuration. Controller reconciles by creating Secrets, Services, ServiceAccounts, NetworkPolicies, and Ingress/Route.

### Flow 2: User Accesses Ray Dashboard

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | Ingress/Route | 443/TCP | HTTPS | TLS 1.2+ | None (OAuth redirect) |
| 2 | Ingress/Route | Ray Head Service (OAuth Proxy) | 8443/TCP | HTTPS | TLS 1.2+ | None |
| 3 | OAuth Proxy | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth client credentials |
| 4 | OAuth Proxy (authenticated) | Ray Dashboard (localhost) | 8080/TCP | HTTP | None | None (localhost) |

**Details**: OAuth proxy validates bearer token from OpenShift and proxies authenticated requests to Ray dashboard running on localhost.

### Flow 3: AppWrapper Job Submission (with Kueue)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | API Server | codeflare-operator (webhook) | 9443/TCP | HTTPS | TLS 1.2+ (mTLS) | API Server client cert |
| 3 | codeflare-operator (controller) | Kueue (via Workload CR) | N/A | In-cluster | N/A | ServiceAccount Token |
| 4 | Kueue | codeflare-operator (AppWrapper status) | N/A | In-cluster | N/A | ServiceAccount Token |

**Details**: AppWrapper controller creates Kueue Workload resource, Kueue admits workload, controller deploys wrapped resources.

### Flow 4: Ray Node mTLS Communication

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Ray Worker Pod | Ray Head Pod | 6379/TCP, 10001/TCP | TCP | mTLS (TLS 1.2+) | Client certificate |
| 2 | Ray Head Pod | Ray Worker Pod | 10001/TCP | TCP | mTLS (TLS 1.2+) | Client certificate |

**Details**: All Ray internal communication uses mTLS with certificates generated by init containers from shared CA.

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| KubeRay Operator | CRD Watch (ray.io) | N/A | In-cluster | N/A | Watches RayCluster CRs created by KubeRay |
| Kueue | CRD Create/Update (kueue.x-k8s.io) | N/A | In-cluster | N/A | Creates Workload resources for AppWrapper scheduling |
| Prometheus | HTTP Scrape | 8080/TCP | HTTP | None | Scrapes /metrics endpoint via ServiceMonitor |
| OpenShift OAuth | HTTPS | 443/TCP | HTTPS | TLS 1.2+ | OAuth token validation for dashboard access |
| OpenShift API (config.openshift.io) | HTTPS | 443/TCP | HTTPS | TLS 1.2+ | Queries cluster ingress domain |
| OpenDataHub Operator | CRD Watch (dscinitialization.opendatahub.io) | N/A | In-cluster | N/A | Detects ODH/RHOAI installation |

## Configuration

The operator is configured via ConfigMap `codeflare-operator-config` with the following key settings:

| Setting | Default | Purpose |
|---------|---------|---------|
| `kuberay.rayDashboardOAuthEnabled` | true | Enable OAuth proxy injection for RayCluster dashboard |
| `kuberay.mTLSEnabled` | true | Enable mTLS certificate injection for Ray node communication |
| `kuberay.ingressDomain` | Auto-detected | Cluster ingress domain for Route/Ingress creation |
| `appwrapper.enabled` | false | Enable embedded AppWrapper controller |
| `metrics.bindAddress` | `:8080` | Metrics server bind address |
| `health.bindAddress` | `:8081` | Health probe server bind address |
| `clientConnection.qps` | 50 | Kubernetes API client QPS limit |
| `clientConnection.burst` | 100 | Kubernetes API client burst limit |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 4e58587 | 2024 | - Merge remote-tracking branch 'upstream/main' |
| ca81c46 | 2024 | - Downgrade StatusReasonConflict errors to debug messages |
| c6e4ff0 | 2024 | - Update AppWrapper to v0.23.0 |
| ef081f9 | 2024 | - Merge remote-tracking branch 'upstream/main' |
| 3658620 | 2024 | - Update dependency versions for release v1.6.0 |
| 41aa363 | 2024 | - Update AppWrappers to v0.22.0 |
| 2cd228e | 2024 | - Make sure that negative unit tests use own fork of RayCluster CR |
| 133db94 | 2024 | - Unit test for head pod imagePullSecrets |
| bce6909 | 2024 | - Add a check for head pod imagePullSecrets |
| 28a02a0 | 2024 | - Merge remote-tracking branch 'pcf-cfo/main' into synctoODH |
| 6ccf23e | 2024 | - Upload KinD pod logs even when CFO deployment fails |
| d82a77d | 2024 | - Merge remote-tracking branch 'upstream/main' |
| 0962592 | 2024 | - Remove ODH integration tests from CFO repo |
| 749b846 | 2024 | - Adjust e2e tests to verify deletion of resources |
| c2d1f78 | 2024 | - Merge remote-tracking branch 'upstream/main' |
| 26a1276 | 2024 | - Generate AppWrapper name to provide unique workloads |
| 2876cf1 | 2024 | - Merge remote-tracking branch 'upstream/main' |
| 03d5bee | 2024 | - Update AppWrappers to v0.21.1 |
| 106955b | 2024 | - Merge remote-tracking branch 'upstream/main' |
| 6f29c03 | 2024 | - Fix setup-go action to use Go version from go.mod |

## Deployment Architecture

### Container Images

| Image | Base | User | Purpose |
|-------|------|------|---------|
| codeflare-operator | ubi8-minimal:8.8 | 65532 (non-root) | Main operator container |

### Resource Requirements

| Container | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| manager | 1 | 1 | 1Gi | 1Gi |

### Health Checks

| Type | Endpoint | Port | Initial Delay | Period |
|------|----------|------|---------------|--------|
| Liveness | /healthz | 8081/TCP | 15s | 20s |
| Readiness | /readyz | 8081/TCP | 5s | 10s |

**Note**: Readiness probe checks webhook certificate availability before marking pod ready.

## Platform-Specific Features

### OpenShift

| Feature | Implementation | Purpose |
|---------|----------------|---------|
| Routes | route.openshift.io/v1 API | External ingress for Ray dashboard |
| OAuth Proxy | Injected sidecar container | Dashboard authentication using OpenShift OAuth |
| Cluster Domain Detection | config.openshift.io/v1/Ingress | Auto-detect cluster ingress domain |
| SecurityContextConstraints | Defaults to restricted | Runs as non-root user 65532 |

### Vanilla Kubernetes

| Feature | Implementation | Purpose |
|---------|----------------|---------|
| Ingress | networking.k8s.io/v1 | External ingress for Ray dashboard |
| OAuth Proxy | Not injected | Dashboard access without authentication (secured by network policy) |
| Cluster Domain | Manual configuration | Must be set in operator ConfigMap |

## Observability

### Metrics Exported

The operator exposes Prometheus metrics on port 8080:

| Metric Type | Purpose |
|-------------|---------|
| controller-runtime metrics | Controller reconciliation rate, errors, duration |
| Workqueue metrics | Work queue depth, latency, retries |
| Go runtime metrics | Memory, goroutines, GC stats |
| Leader election metrics | Leader election status |

### Logging

| Level | Usage |
|-------|-------|
| Info | Standard reconciliation events |
| Debug (V=2) | Detailed controller actions (OAuth/mTLS injection) |
| Error | Reconciliation failures, webhook errors |

### ServiceMonitor

When Prometheus operator is available, the operator can be monitored via:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: codeflare-operator-manager-metrics
spec:
  endpoints:
  - path: /metrics
    port: https
    scheme: https
    bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
    tlsConfig:
      insecureSkipVerify: true
```

## Known Limitations

1. **AppWrapper Controller**: Disabled by default; requires Kueue Workload API to be available before operator starts
2. **Certificate Rotation**: Webhook certificates auto-rotate via cert-controller, but Ray mTLS certificates do not auto-rotate
3. **OpenShift Domain Detection**: Requires access to config.openshift.io/v1/Ingress; fails gracefully on vanilla Kubernetes
4. **Leader Election**: Not enabled by default; must be configured for multi-replica deployments
5. **Namespace Scope**: Operator runs cluster-scoped but can be configured for specific namespaces via RBAC

## Troubleshooting

| Issue | Diagnostic | Resolution |
|-------|------------|------------|
| Webhook not ready | Check `/readyz` returns 503 | Wait for cert-controller to generate certificates |
| RayCluster OAuth fails | Check OAuth proxy logs in head pod | Verify OpenShift OAuth is configured and accessible |
| mTLS connection failures | Check init container logs | Verify CA secret exists and is readable |
| AppWrapper not scheduling | Check Kueue Workload API availability | Install Kueue or disable AppWrapper controller |
| Ingress/Route not created | Check operator logs for domain errors | Set `kuberay.ingressDomain` in ConfigMap |
