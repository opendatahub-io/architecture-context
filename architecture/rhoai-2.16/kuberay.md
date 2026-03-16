# Component: KubeRay Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kuberay.git
- **Version**: v-2160-148-ge95b9d97
- **Branch**: rhoai-2.16
- **Distribution**: RHOAI
- **Languages**: Go 1.22.2
- **Deployment Type**: Kubernetes Operator
- **Deployment Namespace**: opendatahub

## Purpose
**Short**: Kubernetes operator that manages the lifecycle of Ray clusters for distributed computing and machine learning workloads.

**Detailed**:
KubeRay is a Kubernetes operator that simplifies deployment and management of Ray applications on Kubernetes. It provides three core custom resource definitions (RayCluster, RayJob, RayService) that enable users to run distributed computing workloads, batch jobs, and serving applications using the Ray framework. The operator handles cluster lifecycle management including creation, deletion, autoscaling, and fault tolerance. It manages Ray head nodes and worker nodes as Kubernetes pods, creates necessary services for inter-node communication, and integrates with OpenShift/Kubernetes security features. An optional APIServer component provides gRPC and HTTP APIs for simplified management, though direct kubectl/kustomize management is the primary supported method.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| KubeRay Operator | Go Controller | Manages lifecycle of Ray clusters via custom resources |
| RayCluster Controller | Reconciler | Reconciles RayCluster CRs, manages head and worker pods |
| RayJob Controller | Reconciler | Reconciles RayJob CRs, creates clusters and submits jobs |
| RayService Controller | Reconciler | Reconciles RayService CRs, manages serving deployments |
| APIServer (Optional) | gRPC/HTTP Service | Community-managed API layer for KubeRay resources |
| Metrics Exporter | Prometheus Endpoint | Exposes operator metrics on port 8080 |
| Webhook Server | Validation | Validates RayCluster resources (when enabled) |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| ray.io | v1 | RayCluster | Namespaced | Defines a Ray cluster with head and worker node specifications |
| ray.io | v1 | RayJob | Namespaced | Defines a Ray job that creates a cluster and submits work |
| ray.io | v1 | RayService | Namespaced | Defines a Ray Serve deployment with zero-downtime upgrades |

### HTTP Endpoints

#### Operator Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for operator monitoring |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator health check endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness check endpoint |

#### APIServer Endpoints (Optional Component)

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /apis/v1/clusters | GET, POST | 8888/TCP | HTTP | TLS optional | Bearer optional | List/create clusters across namespaces |
| /apis/v1/namespaces/{ns}/clusters | GET, POST | 8888/TCP | HTTP | TLS optional | Bearer optional | List/create clusters in namespace |
| /apis/v1/namespaces/{ns}/clusters/{name} | GET, DELETE | 8888/TCP | HTTP | TLS optional | Bearer optional | Get/delete specific cluster |
| /apis/v1/namespaces/{ns}/jobs | GET, POST | 8888/TCP | HTTP | TLS optional | Bearer optional | Manage RayJobs |
| /apis/v1/namespaces/{ns}/services | GET, POST | 8888/TCP | HTTP | TLS optional | Bearer optional | Manage RayServices |

### gRPC Services

#### APIServer gRPC (Optional Component)

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ClusterService | 8887/TCP | gRPC | mTLS optional | cert optional | CRUD operations for RayCluster resources |
| RayJobService | 8887/TCP | gRPC | mTLS optional | cert optional | CRUD operations for RayJob resources |
| RayServeService | 8887/TCP | gRPC | mTLS optional | cert optional | CRUD operations for RayService resources |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.28+ | Yes | Core platform for operator deployment |
| controller-runtime | v0.16.3 | Yes | Kubernetes operator framework |
| OpenShift API | v0.0.0-20211209135129 | Yes (RHOAI) | OpenShift Route support |
| Prometheus | N/A | No | Metrics collection from operator |
| Volcano Scheduler | v1.6.0-alpha | No | Optional gang scheduling for Ray workloads |
| Redis/External Storage | N/A | No | Optional for GCS fault tolerance |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | CRD | Users create RayCluster resources via dashboard |
| Monitoring Stack | Metrics | Operator exports metrics to Prometheus |
| Authorization | RBAC | Uses Kubernetes/OpenShift RBAC for access control |

## Network Architecture

### Services

#### Operator Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kuberay-operator | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |

#### Ray Cluster Services (Created by Operator)

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {cluster}-head-svc | ClusterIP | 6379/TCP | 6379 | TCP | None | None | Internal |
| {cluster}-head-svc | ClusterIP | 8265/TCP | 8265 | HTTP | TLS optional | None | Internal |
| {cluster}-head-svc | ClusterIP | 10001/TCP | 10001 | TCP | None | None | Internal |
| {cluster}-head-svc | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |
| {cluster}-head-svc | ClusterIP | 8000/TCP | 8000 | HTTP | None | None | Internal |
| {cluster}-serve-svc | ClusterIP | 8000/TCP | 8000 | HTTP | None | None | Internal |
| {cluster}-headless-worker-svc | ClusterIP (None) | N/A | N/A | TCP | None | None | Internal |

#### APIServer Services (Optional)

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kuberay-apiserver | ClusterIP | 8888/TCP | 8888 | HTTP | TLS optional | Bearer optional | Internal |
| kuberay-apiserver | ClusterIP | 8887/TCP | 8887 | gRPC | mTLS optional | cert optional | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {cluster}-dashboard | OpenShift Route | cluster-specific | 8265/TCP | HTTPS | TLS 1.2+ | SIMPLE | External (optional) |
| {cluster}-serve | OpenShift Route | cluster-specific | 8000/TCP | HTTPS | TLS 1.2+ | SIMPLE | External (optional) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Manage Ray cluster resources |
| Ray Head Node | 6379/TCP | TCP | None | None | Worker nodes connect to GCS |
| Ray Head Node | 8265/TCP | HTTP | None | None | Job submission and cluster monitoring |
| External Storage (optional) | 443/TCP | HTTPS | TLS 1.2+ | Provider-specific | GCS fault tolerance with external Redis/S3 |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kuberay-operator | ray.io | rayclusters, rayjobs, rayservices | create, delete, get, list, patch, update, watch |
| kuberay-operator | ray.io | rayclusters/finalizers, rayjobs/finalizers, rayservices/finalizers | update |
| kuberay-operator | ray.io | rayclusters/status, rayjobs/status, rayservices/status | get, patch, update |
| kuberay-operator | "" | pods, services, serviceaccounts, events | create, delete, get, list, patch, update, watch |
| kuberay-operator | "" | pods/status | create, delete, get, list, patch, update, watch |
| kuberay-operator | "" | endpoints | get, list |
| kuberay-operator | batch | jobs | create, delete, get, list, patch, update, watch |
| kuberay-operator | networking.k8s.io | ingresses | create, delete, get, list, patch, update, watch |
| kuberay-operator | networking.k8s.io | ingressclasses | get, list, watch |
| kuberay-operator | rbac.authorization.k8s.io | roles, rolebindings | create, delete, get, list, update, watch |
| kuberay-operator | coordination.k8s.io | leases | create, get, list, update |
| kuberay-operator | route.openshift.io | routes | create, delete, get, list, patch, update, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kuberay-operator | opendatahub | kuberay-operator (ClusterRole) | kuberay-operator |
| leader-election-role-binding | opendatahub | leader-election-role | kuberay-operator |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| Ray TLS certs (optional) | kubernetes.io/tls | TLS encryption for Ray dashboard/serve | User/cert-manager | No |
| Redis credentials (optional) | Opaque | GCS fault tolerance with external Redis | User | No |
| S3 credentials (optional) | Opaque | External storage for GCS fault tolerance | User | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| Kubernetes API | All | ServiceAccount JWT | API Server | RBAC based on kuberay-operator SA |
| /metrics | GET | None | N/A | Open for Prometheus scraping |
| Ray Dashboard (optional) | All | None/Bearer Token | Ray Dashboard | Optional authentication in Ray |
| Ray GCS | Internal | None | Ray Head | Internal cluster communication |
| APIServer (optional) | All | None/Bearer Token | APIServer | Optional authentication |

### SecurityContextConstraints (OpenShift)

| SCC Name | RunAsUser | FSGroup | Capabilities | Privileged | Service Accounts |
|----------|-----------|---------|--------------|------------|------------------|
| run-as-ray-user | MustRunAs (UID 1000) | MustRunAs | Drop ALL | No | kuberay-operator |

### Pod Security

| Component | runAsNonRoot | allowPrivilegeEscalation | seccompProfile | Capabilities |
|-----------|--------------|--------------------------|----------------|--------------|
| Operator | true | false | runtime/default | DROP ALL |
| Ray Head Pod | true | false (recommended) | runtime/default (recommended) | User-configurable |
| Ray Worker Pod | true | false (recommended) | runtime/default (recommended) | User-configurable |

## Data Flows

### Flow 1: RayCluster Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Dashboard | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Kubernetes API | Operator | N/A | Watch | N/A | N/A |
| 3 | Operator | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Kubernetes | Ray Head Pod | N/A | N/A | N/A | N/A |
| 5 | Kubernetes | Ray Worker Pods | N/A | N/A | N/A | N/A |
| 6 | Operator | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: Ray Worker to Head Communication

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Ray Worker Pod | {cluster}-head-svc | 6379/TCP | TCP | None | None |
| 2 | Ray Worker Pod | {cluster}-head-svc | 8265/TCP | HTTP | None | None |

### Flow 3: RayJob Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Operator | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Operator | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Job Submitter Pod | Ray Head | 8265/TCP | HTTP | None | None |
| 4 | Ray Head | Ray Workers | 6379/TCP | TCP | None | None |

### Flow 4: RayService Serving (ML Inference)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | OpenShift Route | 443/TCP | HTTPS | TLS 1.2+ | None/Bearer Token |
| 2 | Route | {cluster}-serve-svc | 8000/TCP | HTTP | None | None |
| 3 | Service | Ray Head/Worker | 8000/TCP | HTTP | None | None |

### Flow 5: Operator Monitoring

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | kuberay-operator | 8080/TCP | HTTP | None | None |
| 2 | User | Prometheus/Grafana | 443/TCP | HTTPS | TLS 1.2+ | User credentials |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 443/TCP | HTTPS | TLS 1.2+ | Manage all Kubernetes resources |
| Prometheus | Metrics scrape | 8080/TCP | HTTP | None | Monitor operator health and performance |
| Ray Dashboard | HTTP API | 8265/TCP | HTTP | None | Job submission and cluster monitoring |
| Ray GCS | TCP | 6379/TCP | TCP | None | Ray cluster coordination and metadata |
| External Redis (optional) | TCP | 6379/TCP | TCP | TLS optional | GCS fault tolerance storage |
| S3-compatible storage (optional) | HTTPS | 443/TCP | HTTPS | TLS 1.2+ | GCS fault tolerance storage |
| Volcano Scheduler (optional) | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | Gang scheduling for Ray workloads |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| v-2160-148 | 2026-03 | - Dependency updates for UBI8 base images<br>- Go toolset 1.25 updates<br>- Konflux pipeline synchronization |
| v1.0.0 | 2023-11-06 | - General Availability release<br>- CRD version bump from v1alpha1 to v1<br>- Improved RayJob UX<br>- Enhanced GCS fault tolerance with Redis cleanup<br>- Relocated documentation to Ray website |
| v1.0.0 | 2023 | - Added readiness/liveness probe injection feature<br>- Improved GCS FT cleanup UX<br>- Fixed RAY_REDIS_ADDRESS parsing<br>- End-to-end tests for Redis cleanup<br>- Sidecar container support for GCS FT |

## Deployment Architecture

### Kustomize Structure

The operator is deployed via Kustomize with the following structure:
- **Base**: `ray-operator/config/default` - Core operator deployment
- **OpenShift**: `ray-operator/config/openshift` - OpenShift-specific configurations
  - Namespace: `opendatahub`
  - Image patching for RHOAI registry
  - SecurityContextConstraints (SCC)
  - Parameter configuration via ConfigMap

### Container Images

| Image | Registry | Tag Pattern | Build System |
|-------|----------|-------------|--------------|
| odh-kuberay-operator-controller | RHOAI Registry | rhoai-2.16-* | Konflux |

### Build Process

The operator is built using:
1. **Base Image**: `registry.access.redhat.com/ubi8/go-toolset:1.25`
2. **Runtime Image**: `registry.access.redhat.com/ubi8/ubi-minimal`
3. **Build Flags**: CGO_ENABLED=1, FIPS mode enabled (`-tags strictfipsruntime`)
4. **User**: Runs as UID 65532 (non-root)

## Resource Management

### Operator Resources

| Resource Type | CPU Request | CPU Limit | Memory Request | Memory Limit |
|---------------|-------------|-----------|----------------|--------------|
| Operator Pod | 100m | 100m | 512Mi | 512Mi |

### Ray Cluster Resources (User-Configurable)

Ray cluster resources are fully configurable by users in the RayCluster CR. Recommendations:
- Production: Integer CPU requests/limits, equal requests and limits
- Memory: Minimum 8Gi per Ray container for production
- GPU/TPU: Configurable per worker group

## Autoscaling

The operator supports Ray Autoscaler which can:
- Scale worker groups between `minReplicas` and `maxReplicas`
- Add/remove workers based on resource demand
- Support heterogeneous worker groups with different resource profiles
- Integrate with Kubernetes Horizontal Pod Autoscaling

## High Availability

### Operator HA
- Single replica with leader election (via coordination.k8s.io/leases)
- Deployment strategy: Recreate
- Health checks: liveness and readiness probes on /metrics

### Ray Cluster HA (GCS Fault Tolerance)
- Optional external Redis for GCS state persistence
- Automatic Redis cleanup on cluster deletion
- Configurable reconnection timeouts
- Head node recovery support

## Observability

### Metrics
- **Operator Metrics**: Exposed on port 8080 at `/metrics` endpoint
- **Ray Metrics**: Each Ray pod exposes metrics on port 8080
- **Format**: Prometheus format

### Logging
- Structured logging via zap logger
- Log levels: info, debug, error
- Optional file logging with rotation (lumberjack)
- Configurable encoders: JSON or console

### Health Checks
- **Operator**: `/healthz` and `/readyz` endpoints
- **Ray Head**: GCS health check via dashboard agent API
- **Ray Workers**: Raylet health check via dashboard agent API
- **Ray Serve**: HTTP proxy health check at `/-/healthz`

## Batch Scheduling Integration

Optional integration with:
- **Volcano**: Gang scheduling for improved resource utilization
- **Kueue**: Job queueing and resource quotas
- Configuration via annotations on RayCluster/RayJob resources

## Notes

- The KubeRay APIServer is an **optional community-managed component** and is not officially endorsed by Ray maintainers
- Primary supported management methods: kubectl, kustomize, Helm charts
- Ray worker-to-head communication is **unencrypted by default** - users should configure TLS for production
- The operator watches specific namespaces or all namespaces (configurable)
- FIPS mode is enabled in RHOAI builds via strictfipsruntime tag
- OpenShift Routes are used for external access instead of Kubernetes Ingress
