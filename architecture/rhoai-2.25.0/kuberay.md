# Component: KubeRay Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kuberay
- **Version**: f10d68b1
- **Branch**: rhoai-2.25
- **Distribution**: RHOAI
- **Languages**: Go 1.24.2
- **Deployment Type**: Kubernetes Operator
- **Build System**: Konflux (Dockerfile.konflux)

## Purpose
**Short**: KubeRay is a Kubernetes operator that manages the lifecycle of Ray clusters, jobs, and services for distributed computing and ML workloads.

**Detailed**: KubeRay Operator simplifies the deployment and management of Ray applications on Kubernetes through custom resource definitions (CRDs). It provides three core resources: RayCluster for managing distributed Ray compute clusters with autoscaling and fault tolerance, RayJob for automatically creating clusters and submitting batch jobs, and RayService for serving ML models with zero-downtime upgrades and high availability. The operator manages the complete lifecycle including cluster creation/deletion, autoscaling workers, health monitoring, and integration with Kubernetes networking (Services, Ingress, OpenShift Routes). It supports advanced features like gang scheduling with Volcano/YuniKorn, GCS fault tolerance with external Redis, and Ray Serve for production ML inference workloads.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kuberay-operator | Kubernetes Operator | Main controller managing RayCluster, RayJob, RayService lifecycle |
| RayCluster Controller | Controller | Reconciles RayCluster resources, manages head/worker pods, services, autoscaling |
| RayJob Controller | Controller | Reconciles RayJob resources, creates RayClusters and submitter K8s Jobs |
| RayService Controller | Controller | Reconciles RayService resources, manages Ray Serve deployments with HA |
| Admission Webhook | ValidatingWebhook | Validates RayCluster CR create/update operations |
| Metrics Exporter | Prometheus Exporter | Exposes operator and Ray cluster metrics |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| ray.io | v1 | RayCluster | Namespaced | Defines a Ray distributed computing cluster with head and worker node groups |
| ray.io | v1 | RayJob | Namespaced | Defines a batch job that creates a RayCluster and submits work to it |
| ray.io | v1 | RayService | Namespaced | Defines a Ray Serve deployment for ML model serving with zero-downtime updates |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for operator and Ray clusters |
| /healthz | GET | 8080/TCP | HTTP | None | None | Operator liveness probe endpoint |
| /readyz | GET | 8080/TCP | HTTP | None | None | Operator readiness probe endpoint |
| /validate-ray-io-v1-raycluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (K8s API server) | Admission webhook for RayCluster validation |

### Ray Cluster Services (Dynamically Created)

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| Ray Head GCS | 6379/TCP | TCP | None | Optional Redis password | Ray Global Control Service for cluster coordination |
| Ray Dashboard | 8265/TCP | HTTP | None | Optional token auth | Ray cluster monitoring dashboard and job submission API |
| Ray Client | 10001/TCP | TCP | None | None | Ray client connection port for remote job submission |
| Ray Serve | 8000/TCP | HTTP | None | None | ML model serving HTTP endpoint (RayService only) |
| Ray Metrics | 8080/TCP | HTTP | None | None | Ray cluster internal metrics |
| Ray Dashboard Agent | 52365/TCP | HTTP | None | None | Per-node dashboard agent for metrics collection |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.21+ | Yes | Container orchestration platform |
| cert-manager | 1.0+ | No | TLS certificate management for admission webhooks (optional) |
| Prometheus | 2.x | No | Metrics collection and monitoring |
| Grafana | 7.x+ | No | Metrics visualization |
| Redis | 6.x+ | No | External GCS storage for fault tolerance |
| Volcano | 1.x | No | Gang scheduling for distributed workloads |
| YuniKorn | 1.x | No | Alternative batch scheduler |
| Kueue | 0.x | No | Job queuing and resource management |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| OpenShift API | API | Creates Routes for external cluster access |
| OpenShift SCC | RBAC | Security context constraints for Ray pods |
| ODH Dashboard | UI | Optional integration for cluster management |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kuberay-operator | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |
| webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | mTLS | Internal (K8s API server) |
| {cluster}-head-svc | ClusterIP | 6379/TCP | 6379 | TCP | None | Optional | Internal |
| {cluster}-head-svc | ClusterIP | 8265/TCP | 8265 | HTTP | None | Optional | Internal |
| {cluster}-head-svc | ClusterIP | 10001/TCP | 10001 | TCP | None | None | Internal |
| {cluster}-serve-svc | ClusterIP | 8000/TCP | 8000 | HTTP | None | None | Internal |
| {cluster}-headless | Headless | Multiple | Multiple | TCP | None | None | Internal (StatefulSet) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {cluster}-ingress | Ingress | Configurable | 8265/TCP | HTTP/HTTPS | Optional TLS | SIMPLE | External (Dashboard) |
| {cluster}-ingress | Ingress | Configurable | 8000/TCP | HTTP/HTTPS | Optional TLS | SIMPLE | External (Serve) |
| {cluster}-route | OpenShift Route | Auto-generated | 8265/TCP | HTTP/HTTPS | Optional TLS | Edge/Passthrough | External (Dashboard) |
| {cluster}-route | OpenShift Route | Auto-generated | 8000/TCP | HTTP/HTTPS | Optional TLS | Edge/Passthrough | External (Serve) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token | Manage K8s resources (Pods, Services, Jobs) |
| External Redis | 6379/TCP | TCP | Optional TLS | Password | GCS fault tolerance storage |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull secrets | Pull Ray container images |
| Ray Package Index | 443/TCP | HTTPS | TLS 1.2+ | None | Download Ray runtime dependencies |
| Git/S3/GCS | 443/TCP | HTTPS | TLS 1.2+ | Configurable | Fetch Ray application code and data |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kuberay-operator | "" | pods | create, delete, deletecollection, get, list, patch, update, watch |
| kuberay-operator | "" | pods/proxy, services/proxy | create, get, patch, update |
| kuberay-operator | "" | pods/status | create, delete, get, list, patch, update, watch |
| kuberay-operator | "" | services | create, delete, get, list, patch, update, watch |
| kuberay-operator | "" | services/status | get, patch, update |
| kuberay-operator | "" | serviceaccounts | create, delete, get, list, watch |
| kuberay-operator | "" | events | create, delete, get, list, patch, update, watch |
| kuberay-operator | "" | endpoints | get, list, watch |
| kuberay-operator | batch | jobs | create, delete, get, list, patch, update, watch |
| kuberay-operator | ray.io | rayclusters, rayjobs, rayservices | create, delete, get, list, patch, update, watch |
| kuberay-operator | ray.io | rayclusters/status, rayjobs/status, rayservices/status | get, patch, update |
| kuberay-operator | ray.io | rayclusters/finalizers, rayjobs/finalizers, rayservices/finalizers | update |
| kuberay-operator | networking.k8s.io | ingresses | create, delete, get, list, patch, update, watch |
| kuberay-operator | networking.k8s.io | ingressclasses | get, list, watch |
| kuberay-operator | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| kuberay-operator | rbac.authorization.k8s.io | roles | create, delete, get, list, update, watch |
| kuberay-operator | rbac.authorization.k8s.io | rolebindings | create, delete, get, list, watch |
| kuberay-operator | coordination.k8s.io | leases | create, get, list, update |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kuberay-operator | Cluster-wide | kuberay-operator (ClusterRole) | kuberay-operator |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| webhook-server-cert | kubernetes.io/tls | TLS certificate for admission webhook | cert-manager | Yes |
| {cluster}-redis-password | Opaque | Redis authentication for GCS fault tolerance | User/External system | No |
| {cluster}-auth-token | Opaque | Ray dashboard authentication token | User | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None | Service | Open for Prometheus scraping |
| /validate-ray-io-v1-raycluster | POST | mTLS (client cert) | Webhook Service | Kubernetes API server authenticated |
| Ray Dashboard (8265) | All | Optional Bearer Token | Ray Dashboard | Configurable per cluster |
| Ray GCS (6379) | All | Optional Redis password | Ray Head | Configurable per cluster |
| Ray Serve (8000) | All | None (application-level) | Ray Serve | Application-defined |

## Data Flows

### Flow 1: RayCluster Creation and Lifecycle Management

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/System | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (user credentials) |
| 2 | Kubernetes API | Admission Webhook | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (K8s API server cert) |
| 3 | Operator Controller | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 4 | Operator Controller | Kubernetes API (create Pod) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 5 | Operator Controller | Kubernetes API (create Service) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 6 | Ray Worker Pods | Ray Head GCS | 6379/TCP | TCP | None | Optional Redis password |
| 7 | Prometheus | kuberay-operator | 8080/TCP | HTTP | None | None |

### Flow 2: RayJob Submission and Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API (create RayJob) | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | RayJob Controller | Kubernetes API (create RayCluster) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 3 | RayJob Controller | Kubernetes API (create K8s Job) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 4 | Submitter Job Pod | Ray Dashboard | 8265/TCP | HTTP | None | Optional token |
| 5 | Submitter Job Pod | Ray Dashboard (submit job) | 8265/TCP | HTTP | None | Optional token |
| 6 | Submitter Job Pod | Ray Dashboard (poll status) | 8265/TCP | HTTP | None | Optional token |

### Flow 3: RayService Model Serving with Zero-Downtime Update

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | RayService Controller | Kubernetes API (create RayCluster v1) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 2 | RayService Controller | Ray Dashboard (deploy Serve apps) | 8265/TCP | HTTP | None | Optional token |
| 3 | External Client | Ray Serve (via Service) | 8000/TCP | HTTP | None | Application-level |
| 4 | RayService Controller | Kubernetes API (create RayCluster v2) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 5 | RayService Controller | Ray Serve (health check v2) | 8000/TCP | HTTP | None | None |
| 6 | RayService Controller | Kubernetes API (update Service selector) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 7 | RayService Controller | Kubernetes API (delete RayCluster v1) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |

### Flow 4: Autoscaling Worker Nodes

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Ray Autoscaler (Head Pod) | Ray GCS | 6379/TCP | TCP | None | Optional Redis password |
| 2 | Ray Autoscaler (Head Pod) | Kubernetes API (list Pods) | 443/TCP | HTTPS | TLS 1.2+ | Ray SA token |
| 3 | Ray Autoscaler (Head Pod) | Kubernetes API (create/delete Pods) | 443/TCP | HTTPS | TLS 1.2+ | Ray SA token |
| 4 | New Worker Pod | Ray Head GCS (register) | 6379/TCP | TCP | None | Optional Redis password |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 443/TCP | HTTPS | TLS 1.2+ | Manage all K8s resources, watch CRDs |
| Prometheus | Pull metrics | 8080/TCP | HTTP | None | Operator and Ray cluster metrics collection |
| cert-manager | Certificate CR | N/A | N/A | N/A | Webhook TLS certificate provisioning |
| External Redis | Redis protocol | 6379/TCP | TCP | Optional TLS | GCS fault tolerance external storage |
| Volcano Scheduler | Pod annotations | N/A | N/A | N/A | Gang scheduling for distributed training |
| YuniKorn Scheduler | Pod annotations | N/A | N/A | N/A | Alternative batch scheduling |
| Kueue | Pod labels/annotations | N/A | N/A | N/A | Job queuing and multi-tenancy |
| OpenShift Routes | Route CR | N/A | N/A | N/A | External access to Ray Dashboard and Serve |
| Ingress Controllers | Ingress CR | N/A | N/A | N/A | External access on vanilla Kubernetes |
| Container Registry | HTTPS | 443/TCP | HTTPS | TLS 1.2+ | Pull Ray and application images |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| f10d68b1 | 2025-01-13 | - Update UBI9 go-toolset digest to 3cdf0d1<br>- Dependency update for RHOAI 2.25 |
| b81c2b33 | 2025-01-10 | - Sync pipeline runs with konflux-central (19bdad4) |
| 1262fef6 | 2025-01-08 | - Update UBI9 ubi-minimal digest to 69f5c98<br>- Security patch updates |
| bf4f1784 | 2025-01-07 | - Update UBI9 go-toolset digest to 6da1160<br>- Routine dependency maintenance |
| 5744f7ee | 2025-01-06 | - Update UBI9 go-toolset digest to 71101fd |
| 28a7a51d | 2025-01-05 | - Update UBI9 go-toolset digest to e421039 |
| 5bfb4ec0 | 2025-01-03 | - Update UBI9 go-toolset digest to b3b98e0 |
| 1a76b31e | 2025-01-02 | - Update UBI9 go-toolset digest to 3efce46 |
| 4f7051e7 | 2024-12-30 | - Sync pipeline runs with konflux-central (e68c3cf) |
| 03244d9e | 2024-12-29 | - Update UBI9 go-toolset digest to 799cc02 |
| a90e5ffd | 2024-12-27 | - Update UBI9 ubi-minimal digest to c7d4414 |
| 606f96fe | 2024-12-26 | - Update UBI9 go-toolset digest to 4c0a6ea |
| 46662e72 | 2024-12-24 | - Sync pipeline runs with konflux-central (07ea5e7) |
| 96758fea | 2024-12-23 | - Update UBI9 go-toolset digest to 82b82ec |
| 84c7562c | 2024-12-20 | - Update UBI9 go-toolset digest to 6983c6e |
| f4db2aa7 | 2024-12-18 | - Update UBI9 ubi-minimal digest to 759f5f4 |
| 6dbd95e9 | 2024-12-17 | - Update UBI9 ubi-minimal digest to ecd4751 |
| a32bf9db | 2024-12-16 | - Update UBI9 ubi-minimal digest to ecd4751 |
| b02f016b | 2024-12-15 | - Update UBI9 ubi-minimal digest to ecd4751 |
| 1fed2686 | 2024-12-14 | - Sync pipeline runs with konflux-central (2ebf2ad) |

## Deployment Configuration

### Kustomize Manifests Location

The primary deployment manifests are located in `ray-operator/config/` with the following structure:

- **Base Configuration**: `ray-operator/config/default/`
- **OpenShift/RHOAI Configuration**: `ray-operator/config/openshift/`
  - Deployed to `opendatahub` namespace by default
  - Includes OpenShift-specific SecurityContextConstraints (SCC)
  - Image configuration via ConfigMap and kustomize patches
  - Uses UBI-based container images built with Konflux

### Container Images

| Image | Base | Purpose |
|-------|------|---------|
| odh-kuberay-operator-controller | registry.access.redhat.com/ubi9/ubi-minimal | Main operator controller built with FIPS-compliant Go |

### Resource Requirements

| Component | CPU Request | Memory Request | CPU Limit | Memory Limit |
|-----------|-------------|----------------|-----------|--------------|
| kuberay-operator | 100m | 512Mi | 100m | 512Mi |

### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| ENABLE_INIT_CONTAINER_INJECTION | true | Inject init container for Ray GCS readiness |
| CLUSTER_DOMAIN | cluster.local | Kubernetes cluster domain for service DNS |
| RAYCLUSTER_DEFAULT_REQUEUE_SECONDS_ENV | 300 | Default reconciliation requeue interval |
| ENABLE_RANDOM_POD_DELETE | false | Enable random pod deletion for autoscaling |
| ENABLE_GCS_FT_REDIS_CLEANUP | false | Enable Redis cleanup job for GCS FT |
| ENABLE_PROBES_INJECTION | false | Enable readiness/liveness probe injection |
| USE_INGRESS_ON_OPENSHIFT | false | Use Ingress instead of Routes on OpenShift |
| ENABLE_RAY_HEAD_CLUSTER_IP_SERVICE | false | Create ClusterIP service instead of Headless |

## Monitoring and Observability

### Prometheus Metrics

The operator exposes Prometheus metrics on port 8080 at `/metrics`:

**Operator Metrics:**
- Controller reconciliation duration and success/failure rates
- CRD watch event counts
- Webhook validation latency and error rates

**RayCluster Metrics:**
- Desired vs available worker replicas
- Cluster state transitions
- Resource allocation (CPU, memory, GPU, TPU)
- Pod creation/deletion events

**RayJob Metrics:**
- Job submission success/failure rates
- Job execution duration
- Cluster creation latency for jobs

**RayService Metrics:**
- Serve deployment health status
- Zero-downtime upgrade transitions
- Serve endpoint availability

### Health Checks

| Probe | Path | Port | Initial Delay | Period | Timeout | Failure Threshold |
|-------|------|------|---------------|--------|---------|-------------------|
| Liveness | /metrics | 8080 | 10s | 5s | 5s | 5 |
| Readiness | /metrics | 8080 | 10s | 5s | 5s | 5 |

## High Availability and Fault Tolerance

### Operator HA
- Single replica deployment (Recreate strategy)
- Leader election supported (disabled by default)
- Can be enabled with `--enable-leader-election` flag

### Ray Cluster HA
- **GCS Fault Tolerance**: External Redis for GCS storage (optional)
- **Worker Fault Tolerance**: Automatic pod recreation on failure
- **Head Fault Tolerance**: Requires external GCS (Redis) with FT enabled
- **Autoscaling**: Dynamic worker scaling based on resource demand

### RayService HA
- **Zero-Downtime Updates**: Blue-green deployment pattern
- **Health Monitoring**: Continuous health checks of Serve endpoints
- **Automatic Rollback**: Failed deployments don't affect serving traffic
- **Multi-Replica Serve**: Load balancing across Serve replicas

## Security Context Constraints (OpenShift)

The operator creates an OpenShift SCC for Ray workloads:

```yaml
kind: SecurityContextConstraints
allowHostDirVolumePlugin: false
allowHostIPC: false
allowHostNetwork: false
allowHostPID: false
allowHostPorts: false
allowPrivilegedContainer: false
allowedCapabilities: []
runAsUser:
  type: MustRunAsRange
seLinuxContext:
  type: MustRunAs
fsGroup:
  type: RunAsAny
supplementalGroups:
  type: RunAsAny
```
