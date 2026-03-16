# Component: CodeFlare Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/codeflare-operator
- **Version**: rhoai-2.11 (commit 7460aa9)
- **Distribution**: RHOAI
- **Languages**: Go 1.22
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes operator for installation and lifecycle management of CodeFlare distributed workload stack, providing Ray cluster orchestration with enhanced security and workload queueing capabilities.

**Detailed**: The CodeFlare Operator extends KubeRay functionality by adding enterprise-grade security features including OAuth authentication, mTLS encryption, and network policies to Ray clusters. It manages the lifecycle of distributed AI/ML workloads through integration with Kueue for resource quotas and gang scheduling via AppWrappers. The operator automatically injects security components into Ray clusters, manages TLS certificates, configures OAuth proxy sidecars for the Ray Dashboard on OpenShift, and enforces network isolation policies. It serves as a critical component in the RHOAI platform for enabling secure, multi-tenant distributed computing environments.

The operator embeds the AppWrapper controller which provides workload queueing, resource reservation, and gang scheduling capabilities through Kueue integration, allowing batch jobs to wait for sufficient resources before deployment and ensuring all components of a distributed workload start simultaneously.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| CodeFlare Operator Manager | Go Binary | Main operator process managing RayCluster and AppWrapper resources |
| RayCluster Controller | Controller | Reconciles RayCluster resources, adds OAuth proxy, mTLS, network policies |
| AppWrapper Controller | Controller | Manages AppWrapper CRDs for workload queueing and gang scheduling |
| RayCluster Webhook | Mutating/Validating Webhook | Mutates RayCluster resources to inject OAuth proxy containers and TLS configuration |
| AppWrapper Webhook | Mutating/Validating Webhook | Validates and mutates AppWrapper resources for Kueue integration |
| Certificate Rotator | Certificate Manager | Manages webhook TLS certificates and Ray cluster CA certificates |
| Metrics Server | HTTP Server | Exposes Prometheus metrics on port 8080 |
| Health Probe Server | HTTP Server | Provides liveness and readiness endpoints on port 8081 |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| workload.codeflare.dev | v1beta2 | AppWrapper | Namespaced | Wraps Kubernetes resources for gang scheduling and workload queueing with Kueue |

**Note**: The operator watches but does not own the RayCluster CRD (ray.io/v1), which is provided by KubeRay operator.

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe |
| /mutate-workload-codeflare-dev-v1beta2-appwrapper | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (K8s API server) | AppWrapper mutating webhook |
| /validate-workload-codeflare-dev-v1beta2-appwrapper | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (K8s API server) | AppWrapper validating webhook |
| /mutate-ray-io-v1-raycluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (K8s API server) | RayCluster mutating webhook |
| /validate-ray-io-v1-raycluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (K8s API server) | RayCluster validating webhook |

### Webhook Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| codeflare-operator-webhook-service | 443/TCP | HTTPS | TLS 1.2+ (cert-manager) | mTLS | Webhook admission endpoint |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| KubeRay Operator | v1.1.0+ | Yes | Provides RayCluster CRD and base Ray cluster management |
| Kueue | v0.7.0+ | Yes (for AppWrapper) | Workload queueing and resource quota management |
| AppWrapper Library | v0.20.2+ | Yes | Gang scheduling implementation |
| cert-controller | v0.10.1+ | Yes | TLS certificate rotation for webhooks |
| Kubernetes | 1.29+ | Yes | Container orchestration platform |
| OpenShift | 4.x | No (optional) | OAuth proxy integration and Route API support |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Operator | CRD Watch | Monitors DSCInitialization for platform configuration |
| Ray Dashboard OAuth Proxy | Sidecar Injection | Secures Ray Dashboard with OAuth authentication (OpenShift only) |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| codeflare-operator-manager-metrics | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |
| codeflare-operator-webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | mTLS | Internal (K8s API server only) |

### Services Created by Operator (for RayClusters)

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {raycluster}-head-svc | ClusterIP | 8265/TCP | 8265 | HTTPS | TLS 1.2+ (mTLS) | OAuth Proxy | Internal |
| {raycluster}-oauth-proxy | ClusterIP | 443/TCP | 8443 | HTTPS | TLS 1.2+ (service-ca) | OAuth | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {raycluster}-ingress | Kubernetes Ingress | {cluster}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | Edge/Passthrough | External |
| {raycluster}-route (OpenShift) | OpenShift Route | {cluster}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch resources, apply configurations |
| KubeRay Operator | N/A | N/A | N/A | N/A | RayCluster CRD availability check |
| Kueue API | N/A | N/A | N/A | N/A | Workload API availability check |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| codeflare-operator-manager-role | "" | secrets | get, list, watch, update, create, delete, patch |
| codeflare-operator-manager-role | "" | services | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | "" | serviceaccounts | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | "" | pods | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | "" | events | create, patch, update, watch |
| codeflare-operator-manager-role | apps | deployments, statefulsets | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | batch | jobs | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | ray.io | rayclusters | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | ray.io | rayclusters/status | get, patch, update |
| codeflare-operator-manager-role | ray.io | rayclusters/finalizers | update |
| codeflare-operator-manager-role | ray.io | rayjobs | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | workload.codeflare.dev | appwrappers | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | workload.codeflare.dev | appwrappers/status | get, patch, update |
| codeflare-operator-manager-role | workload.codeflare.dev | appwrappers/finalizers | update |
| codeflare-operator-manager-role | kueue.x-k8s.io | workloads | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | kueue.x-k8s.io | workloads/status | get, patch, update |
| codeflare-operator-manager-role | kueue.x-k8s.io | workloads/finalizers | update |
| codeflare-operator-manager-role | kueue.x-k8s.io | resourceflavors | get, list, watch |
| codeflare-operator-manager-role | kueue.x-k8s.io | workloadpriorityclasses | get, list, watch |
| codeflare-operator-manager-role | networking.k8s.io | ingresses | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | networking.k8s.io | networkpolicies | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | route.openshift.io | routes, routes/custom-host | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | rbac.authorization.k8s.io | clusterrolebindings | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations | get, list, watch, update |
| codeflare-operator-manager-role | admissionregistration.k8s.io | validatingwebhookconfigurations | get, list, watch, update |
| codeflare-operator-manager-role | apiextensions.k8s.io | customresourcedefinitions | get, list, watch |
| codeflare-operator-manager-role | config.openshift.io | ingresses | get |
| codeflare-operator-manager-role | dscinitialization.opendatahub.io | dscinitializations | get, list, watch |
| codeflare-operator-manager-role | authentication.k8s.io | tokenreviews | create |
| codeflare-operator-manager-role | authorization.k8s.io | subjectaccessreviews | create |
| codeflare-operator-manager-role | scheduling.k8s.io | priorityclasses | get, list, watch |
| codeflare-operator-manager-role | scheduling.sigs.k8s.io | podgroups | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | scheduling.x-k8s.io | podgroups | get, list, watch, create, update, patch, delete |
| codeflare-operator-manager-role | kubeflow.org | pytorchjobs | get, list, watch, create, update, patch, delete |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| codeflare-operator-manager-rolebinding | opendatahub | codeflare-operator-manager-role (ClusterRole) | codeflare-operator-controller-manager |
| codeflare-operator-leader-election-rolebinding | opendatahub | codeflare-operator-leader-election-role (Role) | codeflare-operator-controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| codeflare-operator-webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificates | cert-controller | Yes |
| {raycluster}-ca-secret | Opaque | Ray cluster mTLS CA certificate and private key | CodeFlare Operator | No |
| {raycluster}-oauth-proxy | Opaque | OAuth proxy cookie secret | CodeFlare Operator | No |
| {raycluster}-oauth-tls | kubernetes.io/tls | OAuth service TLS certificate | service-ca-operator (OpenShift) | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None | None | Open to cluster network |
| /healthz, /readyz | GET | None | None | Open to cluster network |
| Webhook endpoints | POST | mTLS client certs | Kubernetes API server | Only K8s API server can call |
| Ray Dashboard (via OAuth proxy) | ALL | Bearer Token (OAuth) | OAuth Proxy sidecar | OpenShift OAuth |
| Ray Dashboard (direct) | ALL | mTLS client certs | Ray Dashboard | Ray cluster CA required |

### Network Policies Created by Operator

The operator creates NetworkPolicy resources for Ray clusters to enforce:
- Ingress: Allow from pods with matching Ray cluster label
- Egress: Allow to Kubernetes API and cluster DNS

## Data Flows

### Flow 1: RayCluster Creation and Security Enhancement

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Application | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (ServiceAccount) |
| 2 | Kubernetes API | CodeFlare Webhook | 9443/TCP | HTTPS | TLS 1.2+ | mTLS |
| 3 | CodeFlare Webhook | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 4 | RayCluster Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 5 | RayCluster Controller | Ray Cluster Pods | N/A | N/A | N/A | N/A |

**Description**: When a RayCluster is created, the mutating webhook intercepts the request, injects OAuth proxy containers (OpenShift) and mTLS configuration. The controller then reconciles the cluster, creating OAuth service, secrets, routes/ingresses, and network policies.

### Flow 2: AppWrapper Workload Admission

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Application | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Kubernetes API | CodeFlare Webhook | 9443/TCP | HTTPS | TLS 1.2+ | mTLS |
| 3 | AppWrapper Controller | Kueue API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 4 | Kueue | AppWrapper Controller | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 5 | AppWrapper Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |

**Description**: AppWrapper resources are validated by webhook, then AppWrapper controller creates a Kueue Workload. When Kueue admits the workload, controller deploys all wrapped resources atomically.

### Flow 3: Ray Dashboard Access (OpenShift with OAuth)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | End User Browser | OpenShift Route | 443/TCP | HTTPS | TLS 1.2+ (edge) | None |
| 2 | Route | OAuth Proxy Service | 443/TCP | HTTPS | TLS 1.2+ (reencrypt) | None |
| 3 | OAuth Proxy | OpenShift OAuth | 443/TCP | HTTPS | TLS 1.2+ | OAuth flow |
| 4 | OAuth Proxy | Ray Dashboard | 8265/TCP | HTTPS | TLS 1.2+ (mTLS) | Client cert |
| 5 | Ray Dashboard | Ray Head Pod | 8265/TCP | HTTPS | TLS 1.2+ | mTLS |

**Description**: External users access Ray Dashboard through OpenShift Route, which terminates at OAuth proxy. OAuth proxy authenticates via OpenShift OAuth, then forwards authenticated requests to Ray Dashboard over mTLS.

### Flow 4: Certificate Generation and Rotation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | cert-controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | cert-controller | Secret (webhook-server-cert) | N/A | N/A | N/A | N/A |
| 3 | RayCluster Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 4 | RayCluster Controller | Secret (ca-secret) | N/A | N/A | N/A | N/A |

**Description**: cert-controller rotates webhook certificates. RayCluster controller generates CA certificates for Ray cluster mTLS on cluster creation.

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Resource reconciliation, event creation |
| KubeRay Operator | CRD Watch | 6443/TCP | HTTPS | TLS 1.2+ | Monitor RayCluster CRD availability |
| Kueue | CRD API | 6443/TCP | HTTPS | TLS 1.2+ | Workload admission and resource quotas |
| Prometheus | HTTP scrape | 8080/TCP | HTTP | None | Metrics collection |
| OpenShift OAuth | OAuth 2.0 | 443/TCP | HTTPS | TLS 1.2+ | User authentication for Ray Dashboard |
| service-ca-operator (OpenShift) | Certificate injection | N/A | N/A | N/A | TLS certificate provisioning for services |
| ODH Operator | CRD Watch | 6443/TCP | HTTPS | TLS 1.2+ | Platform configuration monitoring |

## Configuration

### ConfigMap

| Name | Purpose | Key Parameters |
|------|---------|----------------|
| codeflare-operator-config | Operator configuration | rayDashboardOAuthEnabled, mTLSEnabled, ingressDomain, certGeneratorImage |

### Default Configuration Values

- **RayDashboardOAuthEnabled**: `true` (enables OAuth proxy injection on OpenShift)
- **MTLSEnabled**: `true` (enables mTLS for Ray cluster communication)
- **CertGeneratorImage**: `registry.redhat.io/ubi9@sha256:770cf0...` (init container for cert generation)
- **Metrics BindAddress**: `:8080`
- **Health BindAddress**: `:8081`
- **Client QPS**: `50`
- **Client Burst**: `100`
- **AppWrapper Enabled**: `false` (disabled by default, requires Kueue)

## Deployment Architecture

### Deployment Manifest

- **Replicas**: 1
- **Strategy**: RollingUpdate
- **SecurityContext**: runAsNonRoot: true, allowPrivilegeEscalation: false, capabilities dropped: ALL
- **Resources**: CPU: 1 core, Memory: 1Gi (requests and limits)
- **Container Image**: Built from `Dockerfile` using UBI8 base

### Container Ports

| Port | Protocol | Name | Purpose |
|------|----------|------|---------|
| 8080 | TCP | metrics | Prometheus metrics |
| 9443 | TCP | webhook | Webhook server (internal) |

### Health Checks

| Type | Path | Port | Initial Delay | Period |
|------|------|------|---------------|--------|
| Liveness | /healthz | 8081 | 15s | 20s |
| Readiness | /readyz | 8081 | 5s | 10s |

## Observability

### Metrics Exposed

- Standard controller-runtime metrics
- Webhook latency and error rates
- Reconciliation duration and counts
- Certificate rotation status

### ServiceMonitor

- **Enabled**: Optional (commented out in default config)
- **Endpoint**: `/metrics`
- **Port**: `https`
- **Scheme**: HTTPS
- **Auth**: Bearer token from ServiceAccount
- **TLS**: insecureSkipVerify: true

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| rhoai-2.11 | 2024 | - RHOAI 2.11 release branch<br>- Stability improvements<br>- Security enhancements |

**Note**: This is the RHOAI-specific branch. Detailed commit history from the last 3 months was not available as no recent commits were found in this checkout. This appears to be a stable release branch synced from the upstream project-codeflare repository.

## Special Considerations

### OpenShift vs Kubernetes Differences

1. **OAuth Proxy**: Only deployed on OpenShift clusters (detected via API group discovery)
2. **Routes**: Used on OpenShift; Ingresses used on vanilla Kubernetes
3. **service-ca-operator**: Leveraged for TLS certificate injection on OpenShift

### Multi-Tenancy

- Each RayCluster gets isolated network policies
- OAuth proxy enforces user-level authentication on OpenShift
- ServiceAccounts created per RayCluster for pod identity

### High Availability

- Leader election disabled by default (single replica)
- Webhook server runs in all instances (no leader election required)
- Certificate rotation continues during operator restarts

## Build Information

- **Base Image**: UBI8 (registry.access.redhat.com/ubi8/ubi-minimal:8.8)
- **Go Version**: 1.22
- **Build Tool**: Make with CGO enabled
- **Security**: Non-root user (65532), minimal capabilities

## Upstream Relationship

- **Upstream Project**: project-codeflare/codeflare-operator
- **Downstream Repository**: red-hat-data-services/codeflare-operator (RHOAI)
- **Release Process**: Changes from upstream are merged to RHOAI branches
- **Related Repositories**:
  - opendatahub-io/codeflare-operator (ODH variant)
  - project-codeflare/appwrapper (embedded controller)
  - project-codeflare/codeflare-sdk (Python SDK for users)
