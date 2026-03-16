# Component: CodeFlare Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/codeflare-operator.git
- **Version**: v1.10.0 (commit: 9d7b418)
- **Branch**: rhoai-2.15
- **Distribution**: RHOAI
- **Languages**: Go 1.22.2
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Manages installation and lifecycle of CodeFlare distributed workload stack components including RayClusters and AppWrappers.

**Detailed**: The CodeFlare Operator is a Kubernetes operator that orchestrates the deployment and management of distributed workload infrastructure for AI/ML applications. It provides reconciliation controllers for RayClusters and AppWrappers, implementing security enhancements such as mTLS, OAuth-based authentication, network policies, and integration with Kueue for job queueing. The operator automatically provisions supporting resources including Services, Routes/Ingresses, Secrets for TLS certificates, ServiceAccounts, and RBAC resources. It supports both OpenShift (with Routes) and vanilla Kubernetes (with Ingresses) for external access to Ray dashboard and Ray client endpoints.

The operator embeds the AppWrapper controller to provide workload queueing capabilities when Kueue is available, and enhances RayClusters with OAuth proxy integration on OpenShift for secure dashboard access. It implements network isolation through NetworkPolicies and enables encrypted communication between Ray components via mTLS by default.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| RayCluster Controller | Reconciliation Controller | Watches RayCluster CRs and manages lifecycle, networking, security resources |
| AppWrapper Controller | Reconciliation Controller | Manages AppWrapper CRs for job queueing and resource bundling |
| RayCluster Webhook | Mutating/Validating Webhook | Validates and mutates RayCluster resources on CREATE/UPDATE |
| AppWrapper Webhook | Mutating/Validating Webhook | Validates and mutates AppWrapper resources on CREATE/UPDATE |
| Certificate Manager | Cert Rotator | Manages webhook TLS certificates and CA certificates for mTLS |
| Metrics Server | Prometheus Exporter | Exposes operator metrics on port 8080 |
| Health Probe Server | HTTP Server | Provides liveness (/healthz) and readiness (/readyz) endpoints on port 8081 |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| workload.codeflare.dev | v1beta2 | AppWrapper | Namespaced | Wraps multiple Kubernetes resources as a single schedulable unit with Kueue integration |

**Note**: RayCluster CRDs are managed by KubeRay operator. CodeFlare operator watches and reconciles them but doesn't own the CRD definition.

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe |
| /mutate-workload-codeflare-dev-v1beta2-appwrapper | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (client cert) | Mutating webhook for AppWrapper |
| /validate-workload-codeflare-dev-v1beta2-appwrapper | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (client cert) | Validating webhook for AppWrapper |
| /mutate-ray-io-v1-raycluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (client cert) | Mutating webhook for RayCluster |
| /validate-ray-io-v1-raycluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (client cert) | Validating webhook for RayCluster |

### Services Managed for RayClusters

| Service | Port | Target Port | Protocol | Encryption | Auth | Purpose |
|---------|------|-------------|----------|------------|------|---------|
| OAuth Service (OpenShift) | 443/TCP | oauth-proxy | HTTPS | TLS (service-ca) | OAuth proxy | Secure access to Ray dashboard |
| Ray Dashboard Service | 8265/TCP | 8265 | HTTP | mTLS | Client cert | Ray dashboard UI |
| Ray Client Service | 10001/TCP | 10001 | HTTP | mTLS | Client cert | Ray client API endpoint |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| KubeRay | v1.1.0 | Yes | Provides RayCluster CRD and base Ray operator functionality |
| AppWrapper | v0.26.0 | No | Embedded controller for job queueing and resource bundling |
| Kueue | v0.8.1 (ODH fork) | No | Job queue management system, activates AppWrapper controller |
| cert-controller | v0.10.1 | Yes | Manages webhook certificate rotation |
| OpenShift Service CA | N/A | No (OpenShift only) | Generates TLS certificates for OAuth service |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| opendatahub-operator | DSCInitialization CRD | Reads DSCInitialization for platform configuration |
| OpenShift Route API | route.openshift.io/v1 | Creates Routes for external access on OpenShift |
| Prometheus (ODH) | ServiceMonitor | Metrics collection via ServiceMonitor CR |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| codeflare-operator-webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | mTLS | Internal (API Server) |
| codeflare-operator-manager-metrics | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (Prometheus) |
| {raycluster}-head-svc (OAuth) | ClusterIP | 443/TCP | oauth-proxy | HTTPS | TLS (service-ca) | OAuth | Internal/External via Route |
| {raycluster}-head-svc | ClusterIP | 8265/TCP | 8265 | HTTP | mTLS | Client cert | Internal |
| {raycluster}-head-svc | ClusterIP | 10001/TCP | 10001 | HTTP | mTLS | Client cert | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {raycluster}-ingress (Dashboard) | Ingress | {cluster}.{domain} | 8265/TCP | HTTPS | TLS 1.2+ | Edge | External (non-OpenShift) |
| {raycluster}-ingress (Ray Client) | Ingress | rayclient-{cluster}.{domain} | 10001/TCP | HTTPS | TLS 1.2+ | Edge | External (non-OpenShift) |
| {raycluster}-route (Dashboard) | Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External (OpenShift) |
| {raycluster}-route (Ray Client) | Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External (OpenShift) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token | CRD reconciliation, resource management |
| OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth token | User authentication for Ray dashboard (OpenShift only) |
| Kueue API | N/A | In-cluster API | TLS 1.2+ | ServiceAccount token | Workload queue management |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | "" | pods, services, secrets, serviceaccounts, events, nodes | get, list, watch, create, update, patch, delete |
| manager-role | apps | deployments, statefulsets | get, list, watch, create, update, patch, delete |
| manager-role | batch | jobs | get, list, watch, create, update, patch, delete |
| manager-role | networking.k8s.io | ingresses, networkpolicies | get, list, watch, create, update, patch, delete |
| manager-role | rbac.authorization.k8s.io | clusterrolebindings | get, list, watch, create, update, patch, delete |
| manager-role | route.openshift.io | routes, routes/custom-host | get, list, watch, create, update, patch, delete |
| manager-role | ray.io | rayclusters, rayclusters/status, rayclusters/finalizers, rayjobs | get, list, watch, create, update, patch, delete |
| manager-role | workload.codeflare.dev | appwrappers, appwrappers/status, appwrappers/finalizers | get, list, watch, create, update, patch, delete |
| manager-role | kueue.x-k8s.io | workloads, workloads/status, workloads/finalizers, clusterqueues, resourceflavors, workloadpriorityclasses | get, list, watch, create, update, patch, delete |
| manager-role | kubeflow.org | pytorchjobs | get, list, watch, create, update, patch, delete |
| manager-role | scheduling.sigs.k8s.io, scheduling.x-k8s.io | podgroups | get, list, watch, create, update, patch, delete |
| manager-role | scheduling.k8s.io | priorityclasses | get, list, watch |
| manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | get, list, watch, update |
| manager-role | apiextensions.k8s.io | customresourcedefinitions | get, list, watch |
| manager-role | config.openshift.io | ingresses | get |
| manager-role | dscinitialization.opendatahub.io | dscinitializations | get, list, watch |
| manager-role | authentication.k8s.io | tokenreviews | create |
| manager-role | authorization.k8s.io | subjectaccessreviews | create |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | Cluster-wide | manager-role (ClusterRole) | controller-manager (operator namespace) |
| {raycluster}-oauth-binding | Cluster-wide | system:auth-delegator (ClusterRole) | {raycluster}-oauth-sa |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| codeflare-operator-webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificate | cert-controller | Yes |
| {raycluster}-ca-secret | Opaque | CA certificate and private key for mTLS | CodeFlare operator | No |
| {raycluster}-oauth-config | Opaque | OAuth proxy configuration | CodeFlare operator | No |
| {raycluster}-oauth-sa-token | kubernetes.io/service-account-token | ServiceAccount token for OAuth | Kubernetes | Yes |
| {raycluster}-tls | kubernetes.io/tls | Service CA certificate for OAuth service | OpenShift service-ca-operator | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| Webhook endpoints | POST | mTLS (client certificates) | Kubernetes API Server | API server validates client cert from webhook config |
| Metrics endpoint | GET | None | N/A | Internal network only, no authentication |
| Ray Dashboard (OpenShift) | ALL | OAuth proxy (OpenShift OAuth) | OAuth sidecar container | OpenShift user authentication |
| Ray Dashboard (vanilla K8s) | ALL | Basic ingress | Ingress controller | No authentication by default |
| Ray Client API | ALL | mTLS (client certificates) | Ray head node | Client must present valid certificate signed by cluster CA |
| Health probes | GET | None | N/A | Internal only |

### Network Policies

| Policy Name | Target | Ingress Rules | Egress Rules |
|-------------|--------|---------------|--------------|
| {raycluster}-head-nwp | Ray head pods | Allow from: Ray cluster pods (all ports), same namespace pods (8265, 10001), KubeRay namespaces (8265, 10001) | Not restricted |
| {raycluster}-workers-nwp | Ray worker pods | Allow from: Ray cluster pods (all ports) | Not restricted |

**Secured Ports** (mTLS enabled):
- 8443/TCP: OAuth proxy HTTPS endpoint
- 10001/TCP: Ray client API (when mTLS enabled)

**Dashboard Access Ports**:
- 8265/TCP: Ray dashboard HTTP
- 10001/TCP: Ray client API HTTP

## Data Flows

### Flow 1: User Accesses Ray Dashboard (OpenShift)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | OpenShift Router | {raycluster}-route | 443/TCP | HTTPS | TLS 1.2+ (reencrypt) | None |
| 3 | Route | {raycluster}-head OAuth Service | 443/TCP | HTTPS | TLS (service-ca) | None |
| 4 | OAuth Service | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth flow |
| 5 | OAuth Proxy | Ray Dashboard Container | 8265/TCP | HTTP | None (localhost) | Validated session |

### Flow 2: RayCluster Creation and Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | API Server | CodeFlare Webhook | 9443/TCP | HTTPS | TLS 1.2+ | mTLS |
| 3 | API Server | CodeFlare Controller (watch) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 4 | CodeFlare Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |

### Flow 3: Ray Client Connection (mTLS)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Ray Client Pod | Ray Client Service | 10001/TCP | HTTP | mTLS | Client certificate |
| 2 | Ray Client Service | Ray Head Pod | 10001/TCP | HTTP | mTLS | Client certificate |

### Flow 4: AppWrapper Job Submission with Kueue

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/SDK | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | API Server | AppWrapper Webhook | 9443/TCP | HTTPS | TLS 1.2+ | mTLS |
| 3 | API Server | AppWrapper Controller (watch) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 4 | AppWrapper Controller | Kueue API (Workload CRD) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 5 | Kueue | AppWrapper status update | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 6 | AppWrapper Controller | Wrapped resources creation | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |

### Flow 5: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | ServiceMonitor | N/A | N/A | N/A | N/A |
| 2 | Prometheus | manager-metrics Service | 8080/TCP | HTTPS | TLS (service-ca on OpenShift) | Bearer token |
| 3 | manager-metrics Service | Operator metrics endpoint | 8080/TCP | HTTP | None | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| KubeRay Operator | CRD Watch/Reconcile | 6443/TCP | HTTPS (K8s API) | TLS 1.2+ | Monitor RayCluster CRs, reconcile networking and security |
| Kueue | CRD Watch/Create | 6443/TCP | HTTPS (K8s API) | TLS 1.2+ | Create Workload CRs for AppWrappers, queue management |
| OpenShift OAuth | OAuth API | 443/TCP | HTTPS | TLS 1.2+ | User authentication for Ray dashboard |
| OpenShift Service CA | Service annotation | N/A | N/A | N/A | Automatic TLS certificate provisioning for services |
| Kubernetes API Server | Webhook callback | 9443/TCP | HTTPS | TLS 1.2+ (mTLS) | Admission control for RayCluster and AppWrapper |
| Prometheus | Metrics scrape | 8080/TCP | HTTPS | TLS (service-ca) | Operator metrics collection |
| ODH Operator | DSCInitialization read | 6443/TCP | HTTPS (K8s API) | TLS 1.2+ | Platform configuration discovery |

## Container Images

| Image Purpose | Built By | Base Image | Key Features |
|---------------|----------|------------|--------------|
| codeflare-operator | Konflux | ubi8/ubi-minimal | FIPS-compliant build, runs as non-root (65532:65532) |

## Configuration

### ConfigMap: codeflare-operator-config

| Parameter | Default | Purpose |
|-----------|---------|---------|
| clientConnection.qps | 50 | API client QPS limit |
| clientConnection.burst | 100 | API client burst limit |
| metrics.bindAddress | :8080 | Metrics server bind address |
| health.bindAddress | :8081 | Health probe server bind address |
| kuberay.rayDashboardOAuthEnabled | true | Enable OAuth proxy for Ray dashboard on OpenShift |
| kuberay.mTLSEnabled | true | Enable mTLS for Ray cluster communication |
| kuberay.ingressDomain | Auto-detected | Domain for Ingress resources |
| appwrapper.enabled | false | Enable embedded AppWrapper controller |

## Recent Changes

| Commit | Date | Changes |
|---------|------|---------|
| 9d7b418 | 2024-10-17 | - Merge upstream changes |
| 067c47b | 2024-10-17 | - Update dependency versions for release v1.10.0 |
| 5c7c6d2 | 2024-10-16 | - Update appwrappers to v0.26.0 |
| ae20544 | 2024-10-16 | - Add renovate.json config for dependency management |
| 607e669 | 2024-10-16 | - Review Dockerfile and RPMs for Konflux build |
| a54b426 | 2024-09-30 | - Update codeflare-common version to remove replace for prometheus/common |
| 6d6206e | 2024-09-27 | - Update release tag prompts |
| f500555 | 2024-09-26 | - Create Kueue resources as part of test execution |

## Deployment Architecture

### Operator Deployment

- **Replicas**: 1
- **Resources**:
  - CPU: 1 core (request and limit)
  - Memory: 1Gi (request and limit)
- **Security Context**:
  - Run as non-root
  - No privilege escalation
  - Drop all capabilities
- **Probes**:
  - Liveness: HTTP GET /healthz:8081 (15s initial delay, 20s period)
  - Readiness: HTTP GET /readyz:8081 (5s initial delay, 10s period)

### High Availability

- **Leader Election**: Configurable (default: disabled)
- **Multiple Replicas**: Not recommended - controller uses optimistic concurrency
- **Webhook Availability**: Certificate rotation continues without leader election

### Monitoring

- **ServiceMonitor**: Exposes metrics to Prometheus
- **Metrics Endpoint**: /metrics on port 8080
- **Dashboard**: Operator metrics available in Grafana/OpenShift console

## Development Notes

- **Built with**: Kubebuilder framework, controller-runtime
- **Konflux Build**: Container built entirely through Konflux pipeline with FIPS compliance
- **Testing**: E2E tests support both OpenShift and vanilla Kubernetes
- **Webhooks**: Require valid TLS certificates managed by cert-controller
- **Platform Detection**: Automatically detects OpenShift vs vanilla Kubernetes
- **Dynamic Configuration**: Operator can reconfigure based on ConfigMap changes
