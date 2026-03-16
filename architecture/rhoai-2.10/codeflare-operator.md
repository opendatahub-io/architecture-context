# Component: CodeFlare Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/codeflare-operator.git
- **Version**: rhoai-2.10 branch (1d122da)
- **Distribution**: RHOAI
- **Languages**: Go 1.21
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Operator for installation and lifecycle management of CodeFlare distributed workload stack, managing Ray clusters and AppWrappers for ML/AI distributed computing.

**Detailed**: The CodeFlare Operator provides lifecycle management for distributed AI/ML workloads in Kubernetes environments. It manages two primary custom resources: RayClusters (for Ray distributed computing framework) and AppWrappers (for batch workload scheduling with Kueue integration). The operator enhances RayCluster deployments with security features including mTLS, OAuth-based authentication for Ray dashboards, and network policies. It integrates with Kueue for advanced workload scheduling and resource management, supporting various ML frameworks including PyTorch jobs. The operator is designed to work on both vanilla Kubernetes and OpenShift, providing platform-specific optimizations such as OpenShift Routes for ingress on OpenShift clusters.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Manager Deployment | Kubernetes Deployment | Main operator controller managing RayCluster and AppWrapper lifecycle |
| Webhook Server | Admission Webhooks | Mutating and validating webhooks for AppWrapper and RayCluster resources |
| RayCluster Controller | Controller | Reconciles RayCluster resources, manages OAuth, mTLS, network policies, and ingress |
| AppWrapper Controller | Controller | Manages AppWrapper resources for batch workload scheduling with Kueue integration |
| Metrics Server | HTTP Service | Prometheus metrics endpoint for operator monitoring |
| Health Probes | HTTP Service | Liveness and readiness probe endpoints |
| Certificate Controller | cert-controller | Manages webhook TLS certificates with auto-rotation |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| workload.codeflare.dev | v1beta2 | AppWrapper | Namespaced | Wraps Kubernetes resources for batch workload scheduling with Kueue |

### Watched External CRDs

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| ray.io | v1 | RayCluster | Namespaced | Ray distributed computing cluster (managed by KubeRay operator) |
| kueue.x-k8s.io | v1beta1 | Workload | Namespaced | Kueue workload for resource quota management |
| dscinitialization.opendatahub.io | v1 | DSCInitialization | Cluster | ODH data science cluster configuration |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | Bearer Token (ServiceAccount) | Prometheus metrics scraping |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe |
| /mutate-workload-codeflare-dev-v1beta2-appwrapper | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (webhook) | AppWrapper mutation webhook |
| /validate-workload-codeflare-dev-v1beta2-appwrapper | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (webhook) | AppWrapper validation webhook |
| /mutate-ray-io-v1-raycluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (webhook) | RayCluster mutation webhook |
| /validate-ray-io-v1-raycluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (webhook) | RayCluster validation webhook |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| KubeRay Operator | v1.1.0 | Yes | Provides RayCluster CRD and base Ray cluster management |
| Kueue | v0.6.2 | Conditional | Required for AppWrapper workload scheduling and quota management |
| cert-controller | v0.10.1 | Yes | Webhook certificate rotation and management |
| Ray | 2.5.0 | Yes | Distributed computing framework runtime |
| AppWrapper | v0.12.0 | Embedded | AppWrapper controller embedded in operator |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| opendatahub-operator | CRD Watch | Reads DSCInitialization for platform configuration |
| OAuth Proxy (OpenShift) | Sidecar Injection | Provides authentication for Ray dashboard on OpenShift |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| codeflare-operator-manager-metrics | ClusterIP | 8080/TCP | 8080 | HTTP | None | Bearer Token | Internal |
| codeflare-operator-webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | mTLS | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| RayCluster Route (OpenShift) | Route | {cluster}-{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | edge | External (conditional) |
| RayCluster Ingress (Kubernetes) | Ingress | {cluster}-{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | edge | External (conditional) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Resource reconciliation, CRD watches |
| RayCluster Pods | 8443/TCP | HTTPS | mTLS | Client Certificates | Secure Ray cluster communication (when mTLS enabled) |
| RayCluster Pods | 10001/TCP | HTTPS | mTLS | Client Certificates | Ray client server (when mTLS enabled) |
| RayCluster Dashboard | 8265/TCP | HTTP | None | OAuth (OpenShift) | Ray dashboard access |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | "" | events | create, patch, update, watch |
| manager-role | "" | pods, services | create, delete, get, list, patch, update, watch |
| manager-role | "" | secrets | get, list, update, watch, create, delete, patch |
| manager-role | "" | serviceaccounts | create, delete, get, patch, update |
| manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | get, list, update, watch |
| manager-role | apiextensions.k8s.io | customresourcedefinitions | get, list, watch |
| manager-role | apps | deployments, statefulsets | create, delete, get, list, patch, update, watch |
| manager-role | authentication.k8s.io | tokenreviews | create |
| manager-role | authorization.k8s.io | subjectaccessreviews | create |
| manager-role | batch | jobs | create, delete, get, list, patch, update, watch |
| manager-role | ray.io | rayclusters | create, delete, get, list, patch, update, watch |
| manager-role | ray.io | rayclusters/status | get, patch, update |
| manager-role | ray.io | rayclusters/finalizers | update |
| manager-role | workload.codeflare.dev | appwrappers | create, delete, get, list, patch, update, watch |
| manager-role | workload.codeflare.dev | appwrappers/status | get, patch, update |
| manager-role | workload.codeflare.dev | appwrappers/finalizers | update |
| manager-role | kueue.x-k8s.io | workloads | create, delete, get, list, patch, update, watch |
| manager-role | kueue.x-k8s.io | workloads/status | get, patch, update |
| manager-role | kueue.x-k8s.io | workloads/finalizers | update |
| manager-role | kueue.x-k8s.io | resourceflavors, workloadpriorityclasses | get, list, watch |
| manager-role | networking.k8s.io | ingresses, networkpolicies | create, delete, get, patch, update |
| manager-role | route.openshift.io | routes, routes/custom-host | create, delete, get, patch, update |
| manager-role | rbac.authorization.k8s.io | clusterrolebindings | create, delete, get, patch, update |
| manager-role | config.openshift.io | ingresses | get |
| manager-role | dscinitialization.opendatahub.io | dscinitializations | get, list, watch |
| manager-role | kubeflow.org | pytorchjobs | create, delete, get, list, patch, update, watch |
| manager-role | scheduling.k8s.io | priorityclasses | get, list, watch |
| manager-role | scheduling.sigs.k8s.io | podgroups | create, delete, get, list, patch, update, watch |
| manager-role | scheduling.x-k8s.io | podgroups | create, delete, get, list, patch, update, watch |
| leader-election-role | "" | configmaps | get, list, watch, create, update, patch |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch |
| leader-election-role | "" | events | create, patch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | Cluster-wide | manager-role (ClusterRole) | controller-manager |
| leader-election-rolebinding | operator namespace | leader-election-role (Role) | controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| codeflare-operator-webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificate | cert-controller | Yes |
| {raycluster}-ca | Opaque | Ray cluster CA certificate and key for mTLS | RayCluster controller | No |
| {raycluster}-tls | kubernetes.io/tls | Ray cluster TLS certificates for mTLS | Ray init container | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | Bearer Token (ServiceAccount) | ServiceMonitor | ServiceAccount must have metrics read permission |
| /mutate-*, /validate-* | POST | mTLS (client certificate) | Kubernetes API Server | API server validates webhook client cert |
| Ray Dashboard (OpenShift) | ALL | OAuth Proxy | OAuth sidecar | OpenShift OAuth with RBAC |
| Ray Dashboard (Kubernetes) | ALL | None (NetworkPolicy) | NetworkPolicy | Restricted by NetworkPolicy to same namespace |
| Ray Cluster mTLS | ALL | mTLS (client certificate) | Ray nodes | Client cert signed by cluster CA |

## Data Flows

### Flow 1: AppWrapper Admission

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Kubernetes API Server | codeflare-operator-webhook-service | 443/TCP | HTTPS | TLS 1.2+ | mTLS (API server client cert) |
| 2 | Webhook Server | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: RayCluster Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Operator Manager | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Operator Manager | Kubernetes API Server (create NetworkPolicy) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Operator Manager | Kubernetes API Server (create Route/Ingress) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Operator Manager | Kubernetes API Server (create Service) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 3: AppWrapper Workload Scheduling

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | AppWrapper Controller | Kubernetes API Server (create Kueue Workload) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Kueue | Kubernetes API Server (update Workload status) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | AppWrapper Controller | Kubernetes API Server (watch Workload) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | AppWrapper Controller | Kubernetes API Server (deploy wrapped resources) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 4: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | codeflare-operator-manager-metrics | 8080/TCP | HTTP | None | Bearer Token (ServiceAccount) |

### Flow 5: Ray Cluster mTLS Communication (Optional)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Ray Worker | Ray Head | 8443/TCP | HTTPS | mTLS (TLS 1.2+) | Client Certificate |
| 2 | Ray Client | Ray Head | 10001/TCP | HTTPS | mTLS (TLS 1.2+) | Client Certificate |

## Network Policies Created

The operator dynamically creates NetworkPolicies for each RayCluster to restrict traffic:

### RayCluster Head NetworkPolicy

| Direction | Source | Destination | Port | Protocol | Purpose |
|-----------|--------|-------------|------|----------|---------|
| Ingress | Same RayCluster Pods | Head Pod | All | TCP | Allow worker-to-head communication |
| Ingress | Same Namespace Pods | Head Pod | 10001/TCP | TCP | Allow Ray client access |
| Ingress | Same Namespace Pods | Head Pod | 8265/TCP | TCP | Allow Ray dashboard access |
| Ingress | KubeRay Operator Namespaces | Head Pod | 8265/TCP, 10001/TCP | TCP | Allow operator management |
| Ingress | Prometheus Namespaces | Head Pod | 8080/TCP | TCP | Allow metrics scraping |
| Ingress | Same Namespace Pods (mTLS enabled) | Head Pod | 8443/TCP, 10001/TCP | TCP | Secure Ray communication |

### RayCluster Workers NetworkPolicy

| Direction | Source | Destination | Port | Protocol | Purpose |
|-----------|--------|-------------|------|----------|---------|
| Ingress | Same RayCluster Pods | Worker Pods | All | TCP | Allow intra-cluster communication |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 443/TCP | HTTPS | TLS 1.2+ | Resource reconciliation, watches |
| KubeRay Operator | CRD Management | N/A | N/A | N/A | Manages RayCluster CRD and base lifecycle |
| Kueue | CRD/API | 443/TCP | HTTPS | TLS 1.2+ | Workload scheduling and quota management |
| Prometheus | Metrics Scraping | 8080/TCP | HTTP | None | Operator observability |
| OpenShift OAuth | OAuth Proxy | 443/TCP | HTTPS | TLS 1.2+ | Ray dashboard authentication (OpenShift only) |
| cert-controller | Certificate Management | N/A | N/A | N/A | Webhook certificate lifecycle |

## Configuration

The operator is configured via a ConfigMap (`codeflare-operator-config`) with the following key settings:

| Setting | Default | Purpose |
|---------|---------|---------|
| kuberay.rayDashboardOAuthEnabled | true | Enable OAuth proxy for Ray dashboard (OpenShift) |
| kuberay.mTLSEnabled | true | Enable mTLS for Ray cluster communication |
| kuberay.ingressDomain | auto-detected | Domain for Route/Ingress creation |
| kuberay.certGeneratorImage | registry.redhat.io/ubi9@sha256:770cf... | Image for generating Ray cluster certificates |
| appwrapper.enabled | false | Enable embedded AppWrapper controller |
| clientConnection.qps | 50 | Kubernetes API client QPS limit |
| clientConnection.burst | 100 | Kubernetes API client burst limit |
| metrics.bindAddress | :8080 | Metrics server bind address |
| health.bindAddress | :8081 | Health probe bind address |

## Container Security

| Setting | Value | Purpose |
|---------|-------|---------|
| runAsNonRoot | true | Prevents running as root user |
| runAsUser | 65532 | Runs as non-privileged user |
| allowPrivilegeEscalation | false | Prevents privilege escalation |
| capabilities.drop | ALL | Drops all Linux capabilities |
| securityContext | Restricted | Pod security standard compliance |

## Resource Requirements

| Container | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| manager | 1 core | 1 core | 1Gi | 1Gi |

## Recent Changes

Based on the rhoai-2.10 branch, this version includes:

| Component | Version | Key Features |
|-----------|---------|--------------|
| CodeFlare Operator | v1.4.3 (upstream) | RayCluster and AppWrapper management |
| AppWrapper | v0.12.0 | Embedded controller for batch workload scheduling |
| KubeRay | v1.1.0 | Ray v1 API support |
| Kueue | v0.6.2 | Resource quota and scheduling |

Note: The checkout appears to be a snapshot from the rhoai-2.10 branch without recent commit history. For the most up-to-date changes, consult the upstream repository.

## Deployment Notes

### For RHOAI Deployment

1. The operator is deployed via the ODH operator when the CodeFlare component is enabled
2. Manifests are located in `config/` directory with kustomize overlays
3. The `config/codeflare` directory (referenced in the task) should contain the kustomization for RHOAI deployment
4. AppWrapper support is conditional based on Kueue CRD availability
5. OpenShift-specific features (Routes, OAuth) are auto-detected and enabled

### Platform Detection

The operator automatically detects the platform:
- **OpenShift**: Creates Routes, enables OAuth proxy for Ray dashboard
- **Kubernetes**: Creates Ingress resources, basic authentication only

### Dynamic CRD Detection

The operator watches for CRD availability and adjusts functionality:
- **RayCluster CRD**: Waits for KubeRay installation before enabling RayCluster controller
- **Kueue Workload CRD**: Enables AppWrapper controller only when Kueue is available
- Triggers restart if critical CRDs become available after operator startup
