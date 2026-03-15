# Component: KubeRay Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kuberay
- **Version**: 72c07895 (rhoai-3.2 branch)
- **Distribution**: RHOAI
- **Languages**: Go 1.24.0
- **Deployment Type**: Kubernetes Operator
- **Build System**: Konflux (FIPS-enabled)

## Purpose
**Short**: Kubernetes operator that manages the lifecycle of Ray clusters, jobs, and services for distributed computing and ML workloads.

**Detailed**: KubeRay is a Kubernetes operator that simplifies the deployment and management of Ray applications on Kubernetes. It provides three core Custom Resource Definitions (RayCluster, RayJob, RayService) that enable users to run distributed computing workloads including machine learning training, batch inference, and online serving. The operator fully manages the lifecycle of Ray clusters including creation, deletion, autoscaling, fault tolerance, and zero-downtime upgrades. In RHOAI, it integrates deeply with OpenShift features including OAuth authentication, Routes for external access, NetworkPolicies for secure multi-tenant environments, and mTLS via cert-manager for encrypted inter-pod communication.

KubeRay acts as a control plane for Ray workloads, watching custom resources and reconciling the desired state by creating and managing underlying Kubernetes resources (Pods, Services, Jobs, ConfigMaps, Secrets, NetworkPolicies, Routes, and Certificates). It includes specialized controllers for authentication (OAuth/OIDC on OpenShift), network isolation (NetworkPolicy), and mTLS certificate management. The operator exposes Prometheus metrics for observability and includes validating/mutating webhooks for admission control.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| KubeRay Operator | Go Kubernetes Operator | Main controller managing RayCluster, RayJob, RayService CRDs |
| RayCluster Controller | Reconciliation Controller | Manages lifecycle of Ray clusters (head + worker pods) |
| RayJob Controller | Reconciliation Controller | Creates RayCluster and submits jobs, optionally deletes cluster on completion |
| RayService Controller | Reconciliation Controller | Manages RayCluster with Ray Serve deployment for zero-downtime upgrades |
| Authentication Controller | Reconciliation Controller | Manages OAuth/OIDC authentication on OpenShift (Routes, HTTPRoutes, ServiceAccounts) |
| NetworkPolicy Controller | Reconciliation Controller | Creates and manages NetworkPolicies for secure Ray cluster communication |
| mTLS Controller | Reconciliation Controller | Manages cert-manager Certificates and Issuers for Ray cluster mTLS |
| Validating Webhook | Admission Webhook | Validates RayCluster CR modifications before admission |
| Mutating Webhook | Admission Webhook | Mutates RayCluster CRs to inject defaults and init containers |
| APIServer (Optional) | gRPC/HTTP Service | Provides simplified REST API for KubeRay resource management (not deployed in RHOAI) |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| ray.io | v1 | RayCluster | Namespaced | Defines a Ray cluster with head and worker pods, autoscaling, GCS fault tolerance |
| ray.io | v1 | RayJob | Namespaced | Defines a Ray job with automatic RayCluster lifecycle management and job submission |
| ray.io | v1 | RayService | Namespaced | Defines a Ray Serve deployment with zero-downtime upgrades and HA |
| ray.io | v1alpha1 | RayCluster | Namespaced | Legacy version of RayCluster (deprecated, use v1) |
| ray.io | v1alpha1 | RayJob | Namespaced | Legacy version of RayJob (deprecated, use v1) |
| ray.io | v1alpha1 | RayService | Namespaced | Legacy version of RayService (deprecated, use v1) |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for operator health and performance |
| /healthz | GET | 8080/TCP | HTTP | None | None | Liveness probe for operator health check |
| /readyz | GET | 8080/TCP | HTTP | None | None | Readiness probe for operator startup check |
| /mutate-ray-io-v1-raycluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Mutating webhook for RayCluster CRs |
| /validate-ray-io-v1-raycluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Validating webhook for RayCluster CRs |

### gRPC Services (APIServer - Optional, Not Deployed in RHOAI)

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ClusterService | 8887/TCP | gRPC/HTTP2 | TLS (optional) | Bearer Token (optional) | CRUD operations for RayCluster resources |
| JobService | 8887/TCP | gRPC/HTTP2 | TLS (optional) | Bearer Token (optional) | CRUD operations for RayJob resources |
| ServeService | 8887/TCP | gRPC/HTTP2 | TLS (optional) | Bearer Token (optional) | CRUD operations for RayService resources |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.26+ | Yes | Operator runtime platform |
| OpenShift | 4.12+ | No (RHOAI) | Route, OAuth, SCC support (RHOAI-specific) |
| cert-manager | v1.11+ | No | TLS certificate management for mTLS between Ray pods |
| Gateway API | v1/v1beta1 | No | HTTPRoute for advanced ingress routing and OAuth |
| Ray | 2.0+ | Yes | Distributed computing framework (runs in Ray pods managed by operator) |
| Prometheus | Any | No | Metrics collection from operator /metrics endpoint |
| Redis | 6.0+ | No | External storage for Ray GCS fault tolerance (optional) |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH/RHOAI Operator | Parent Operator | Deploys and configures KubeRay operator via component CRD |
| OpenShift OAuth | OAuth/OIDC Provider | Provides authentication for Ray dashboard and client endpoints |
| OpenShift Routes | Ingress | Exposes Ray dashboard and client endpoints externally |
| OpenShift Service CA | Certificate Authority | Issues certificates for OAuth proxy TLS |
| Authorino (future) | Authorization | May be used for advanced authorization policies |
| Kueue (optional) | Batch Scheduler | Queue management for Ray jobs in multi-tenant environments |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kuberay-operator | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (metrics/health) |
| webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | K8s API mTLS | Internal (webhooks) |
| {raycluster}-head-svc | ClusterIP | 6379/TCP, 8265/TCP, 10001/TCP | 6379, 8265, 10001 | TCP/HTTP | None (or mTLS if enabled) | None (or OAuth if enabled) | Internal (Ray GCS, dashboard, client) |
| {raycluster}-head-svc (with auth) | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.3 | OAuth proxy | Internal (authenticated dashboard) |
| {rayservice}-serve-svc | ClusterIP | 8000/TCP | 8000 | HTTP | None (or TLS if configured) | None (or Bearer if configured) | Internal (Ray Serve inference) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {raycluster}-dashboard | OpenShift Route | {cluster}-{namespace}.apps.{domain} | 443/TCP | HTTPS | TLS 1.2+ | Edge (Route reencrypt if OAuth) | External |
| {raycluster}-client | OpenShift Route | {cluster}-client-{namespace}.apps.{domain} | 443/TCP | HTTPS | TLS 1.2+ | Edge | External (optional) |
| {raycluster}-dashboard-http | Gateway API HTTPRoute | {gateway-host} | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External (Gateway API mode) |
| {raycluster}-dashboard-auth | Gateway API HTTPRoute | {gateway-host} | 443/TCP | HTTPS | TLS 1.3 | SIMPLE | External (Gateway API + OAuth) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch CRDs, create/update/delete resources |
| OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | Client credentials | Validate OAuth tokens for authenticated Ray clusters |
| Container Registry (quay.io, registry.redhat.io) | 443/TCP | HTTPS | TLS 1.2+ | Pull secret | Pull Ray container images |
| External Redis (optional) | 6379/TCP | Redis | TLS 1.2+ (optional) | Username/Password | Ray GCS fault tolerance external storage |
| Webhook Service (self) | 9443/TCP | HTTPS | TLS 1.2+ | K8s API mTLS | Validate/mutate RayCluster CRs |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kuberay-operator | "" | pods, services, events, configmaps, serviceaccounts, secrets, endpoints, pods/status, pods/proxy, services/status, services/proxy | create, delete, get, list, patch, update, watch |
| kuberay-operator | apps | deployments | get, list, patch, update, watch |
| kuberay-operator | batch | jobs | create, delete, get, list, patch, update, watch |
| kuberay-operator | ray.io | rayclusters, rayjobs, rayservices | create, delete, get, list, patch, update, watch |
| kuberay-operator | ray.io | rayclusters/status, rayjobs/status, rayservices/status | get, patch, update |
| kuberay-operator | ray.io | rayclusters/finalizers, rayjobs/finalizers, rayservices/finalizers | update |
| kuberay-operator | networking.k8s.io | ingresses, networkpolicies, ingressclasses | create, delete, get, list, patch, update, watch |
| kuberay-operator | extensions | ingresses | create, delete, get, list, patch, update, watch |
| kuberay-operator | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| kuberay-operator | rbac.authorization.k8s.io | roles, rolebindings | create, delete, get, list, update, watch |
| kuberay-operator | rbac.authorization.k8s.io | clusterroles, clusterrolebindings | get, list, watch |
| kuberay-operator | cert-manager.io | certificates, issuers | create, delete, get, list, patch, update, watch |
| kuberay-operator | cert-manager.io | certificates/status | get, patch, update |
| kuberay-operator | gateway.networking.k8s.io | gateways | get, list, watch |
| kuberay-operator | gateway.networking.k8s.io | httproutes, referencegrants | create, delete, get, list, patch, update, watch |
| kuberay-operator | config.openshift.io | authentications, authentications/status, oauths, oauths/status | get, list, watch |
| kuberay-operator | operator.openshift.io | kubeapiservers, kubeapiservers/status | get, list, watch |
| kuberay-operator | authentication.k8s.io | tokenreviews | create |
| kuberay-operator | authorization.k8s.io | subjectaccessreviews | create |
| kuberay-operator | coordination.k8s.io | leases | create, get, list, update |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kuberay-operator | {operator-namespace} | kuberay-operator (ClusterRole) | kuberay-operator |
| leader-election-rolebinding | {operator-namespace} | leader-election-role (Role) | kuberay-operator |
| gateway-api-role-binding | {operator-namespace} | gateway-api-role (ClusterRole) | kuberay-operator |
| configmap-role-binding | {operator-namespace} | configmap-role (Role) | kuberay-operator |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| webhook-server-cert | kubernetes.io/tls | TLS certificate for validating/mutating webhooks | cert-manager or K8s cert controller | Yes (cert-manager) |
| {raycluster}-proxy-tls-secret | kubernetes.io/tls | TLS certificate for OAuth proxy serving HTTPS | OpenShift Service CA | Yes (Service CA) |
| {raycluster}-ca-secret | Opaque | mTLS CA certificate and key for Ray pod certificates | cert-manager or operator | No |
| {raycluster}-tls-secret | kubernetes.io/tls | mTLS certificate for Ray head/worker pods | cert-manager | Yes (cert-manager) |
| oauth-config | Opaque | OAuth client configuration (cookie secret, client ID) | Authentication controller | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| Ray Dashboard (/dashboard) | GET, POST | OAuth/OIDC Bearer Token (OpenShift) | oauth-proxy sidecar | Authenticated OpenShift users |
| Ray Dashboard (unauthenticated) | GET, POST | None | N/A | Open access (default, not recommended for production) |
| Ray Client API (:10001) | TCP | mTLS client certificates (optional) | Ray GCS server | Authorized Ray clients with valid certs |
| Ray GCS (:6379) | TCP | mTLS (optional) | Ray GCS server | Ray head/worker pods with cluster certificates |
| Ray Serve HTTP (:8000) | GET, POST | Bearer Token (optional, app-defined) | Ray Serve application | Application-specific authorization |
| Webhook Endpoints | POST | Kubernetes API Server mTLS | webhook-service | Only K8s API server can call |
| Operator Metrics (/metrics) | GET | None | N/A | Internal network access only |

### NetworkPolicy Support

NetworkPolicies are created when RayCluster has annotation `ray.io/enable-secure-trusted-network: "true"`:

**Head Pod NetworkPolicy:**
- **Ingress**: Allow from Ray worker pods (same cluster), KubeRay operator namespace, same namespace
- **Egress**: Allow to Kubernetes DNS, Kubernetes API server, Ray worker pods

**Worker Pod NetworkPolicy:**
- **Ingress**: Allow from Ray head pod (same cluster), other worker pods (same cluster)
- **Egress**: Allow to Kubernetes DNS, Ray head pod, other worker pods

## Data Flows

### Flow 1: RayCluster Creation and Pod Lifecycle

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (user) |
| 2 | Kubernetes API Server | webhook-service | 9443/TCP | HTTPS | TLS 1.2+ | K8s API mTLS |
| 3 | webhook-service | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | RayCluster Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | RayCluster Controller | Kubernetes API Server (create head pod) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 6 | RayCluster Controller | Kubernetes API Server (create head service) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 7 | RayCluster Controller | Kubernetes API Server (create worker pods) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 8 | Ray Worker Pods | Ray Head Service | 6379/TCP | TCP | None (or mTLS) | None (or mTLS) |

### Flow 2: RayJob Submission

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (user) |
| 2 | RayJob Controller | Kubernetes API Server (create RayCluster) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | RayJob Controller | Ray Head Service (submit job) | 8265/TCP | HTTP | None | None |
| 4 | Ray Head Pod | Ray Head GCS | 6379/TCP | TCP | None (or mTLS) | None (or mTLS) |
| 5 | Ray Worker Pods | Ray Head GCS | 6379/TCP | TCP | None (or mTLS) | None (or mTLS) |
| 6 | RayJob Controller | Ray Head Service (poll job status) | 8265/TCP | HTTP | None | None |
| 7 | RayJob Controller | Kubernetes API Server (update RayJob status) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 3: Ray Dashboard Access with OAuth (OpenShift)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Route | 443/TCP | HTTPS | TLS 1.2+ (Route edge) | None |
| 2 | OpenShift Route | oauth-proxy sidecar (head pod) | 8443/TCP | HTTPS | TLS 1.3 | None |
| 3 | oauth-proxy sidecar | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | Client credentials |
| 4 | oauth-proxy sidecar | Ray Dashboard (head pod) | 8265/TCP | HTTP | None | None (localhost) |
| 5 | Ray Dashboard | User Browser | 443/TCP (via Route) | HTTPS | TLS 1.2+ | OAuth session cookie |

### Flow 4: mTLS Certificate Provisioning

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | mTLS Controller | Kubernetes API Server (create Issuer) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | mTLS Controller | Kubernetes API Server (create Certificate) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | cert-manager | Kubernetes API Server (create Secret) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Ray Head/Worker Pods | Kubernetes API Server (mount Secret) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 5: NetworkPolicy Enforcement

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | NetworkPolicy Controller | Kubernetes API Server (create NetworkPolicy) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Ray Worker Pod | Ray Head Pod | 6379/TCP | TCP | Allowed by NetworkPolicy | None (or mTLS) |
| 3 | External Pod (blocked) | Ray Head Pod | 6379/TCP | TCP | Denied by NetworkPolicy | N/A (blocked) |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API (client-go) | 6443/TCP | HTTPS | TLS 1.2+ | Watch CRDs, create/update/delete resources, list/watch pods |
| Prometheus | HTTP Pull (scrape /metrics) | 8080/TCP | HTTP | None | Collect operator and Ray cluster metrics |
| cert-manager | Kubernetes CRD API | 6443/TCP | HTTPS | TLS 1.2+ | Create Certificate and Issuer resources for mTLS |
| OpenShift OAuth Server | OAuth 2.0 | 443/TCP | HTTPS | TLS 1.2+ | Token validation for Ray dashboard authentication |
| OpenShift Route API | Kubernetes CRD API | 6443/TCP | HTTPS | TLS 1.2+ | Create Routes for external Ray dashboard/client access |
| Gateway API | Kubernetes CRD API | 6443/TCP | HTTPS | TLS 1.2+ | Create HTTPRoutes for advanced ingress routing |
| Ray Head Pod (Dashboard API) | HTTP API | 8265/TCP | HTTP | None | Submit jobs, query cluster status, monitor Ray Serve |
| Ray Head Pod (GCS) | TCP (Ray protocol) | 6379/TCP | TCP | None (or mTLS) | Distributed object store and cluster metadata |
| Ray Worker Pods | TCP (Ray protocol) | Random/Ephemeral | TCP | None (or mTLS) | Distributed task execution and data transfer |
| External Redis (optional) | Redis Protocol | 6379/TCP | TCP | TLS 1.2+ (optional) | GCS fault tolerance external storage |
| Kueue (optional) | Kubernetes CRD API | 6443/TCP | HTTPS | TLS 1.2+ | Batch job queuing and resource quotas |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 72c07895 | Recent | - chore(deps): update registry.access.redhat.com/ubi9/go-toolset docker digest to 82b82ec |
| 891079fd | Recent | - chore(deps): update registry.access.redhat.com/ubi9/go-toolset docker digest to 6983c6e |
| ad296f9b | Recent | - chore(deps): update registry.access.redhat.com/ubi9/ubi-minimal docker digest to 759f5f4 |
| 82cd3367 | Recent | - chore(deps): update registry.access.redhat.com/ubi9/ubi-minimal docker digest to ecd4751 |
| 616d2733 | Recent | - chore(deps): update registry.access.redhat.com/ubi9/go-toolset docker digest to 359dd4c |
| 4a1bc8b6 | Recent | - chore(deps): update konflux references |
| 2afd438d | Recent | - chore(deps): update konflux references |
| b6db3fb1 | Recent | - chore(deps): update konflux references |
| f1717c24 | Recent | - Merge remote-tracking branch 'upstream/main' into rhoai-3.2 |

**Summary**: Recent changes focus primarily on dependency updates for UBI9 base images and Konflux build system references, maintaining FIPS compliance and security patches. The rhoai-3.2 branch includes periodic merges from upstream KubeRay main branch to incorporate community features and bug fixes.

## Additional Notes

### Ray Pod Architecture

Each RayCluster creates:
- **1 Head Pod**: Runs Ray head node with GCS (Global Control Service) on port 6379, dashboard on port 8265, and client server on port 10001
- **N Worker Pods**: Run Ray worker nodes that connect to head GCS, number controlled by `workerGroupSpecs[].replicas`

### Autoscaling

RayCluster supports:
- **Manual scaling**: Setting `workerGroupSpecs[].replicas`
- **Autoscaling**: Ray autoscaler (in-tree) monitors resource usage and scales workers within `minReplicas`/`maxReplicas`
- **External autoscaling**: Integration with Kubernetes HPA or Karpenter (future)

### High Availability

- **RayService**: Provides zero-downtime upgrades by creating new RayCluster before deleting old one
- **GCS Fault Tolerance**: Optional external Redis backend for GCS metadata to survive head pod crashes
- **Head Pod Recovery**: Operator automatically recreates head pod if deleted/failed when GCS FT enabled

### Multi-Tenancy

- **Namespace Isolation**: RayClusters are namespace-scoped
- **NetworkPolicy**: Optional network isolation between RayClusters in same namespace
- **RBAC**: Cluster-scoped operator with per-namespace RayCluster resources
- **Resource Quotas**: Kubernetes ResourceQuotas apply to Ray pods
- **Kueue Integration**: Optional queue-based scheduling for fair sharing across tenants

### Observability

- **Operator Metrics**: Prometheus metrics at `:8080/metrics` (reconciliation time, queue depth, errors)
- **Ray Metrics**: Ray head exposes Prometheus metrics, scraped via ServiceMonitor
- **Logging**: Structured JSON logs via zap logger, configurable verbosity
- **Events**: Kubernetes Events for RayCluster lifecycle (created, scaled, deleted, errors)

### RHOAI-Specific Features

- **Konflux Build Pipeline**: Uses `Dockerfile.konflux` with FIPS-enabled Go builds on UBI9
- **OpenShift OAuth Integration**: Automatic OAuth proxy injection for Ray dashboard authentication
- **OpenShift Routes**: First-class support for Route-based external access (preferred over Ingress)
- **SecurityContextConstraints**: Custom SCC `run-as-ray-user` for Ray pod security context
- **Gateway API Support**: HTTPRoute integration for advanced routing with OpenShift Service Mesh
- **NetworkPolicy Defaults**: Annotation-driven NetworkPolicy creation for secure multi-tenant deployments
