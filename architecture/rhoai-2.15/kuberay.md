# Component: KubeRay Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kuberay.git
- **Version**: v1.1.0 (rhoai-2.15 branch, commit 6ffcf96c)
- **Distribution**: RHOAI
- **Languages**: Go 1.22.2
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes operator that manages the lifecycle of Ray distributed computing clusters, jobs, and services.

**Detailed**: KubeRay is a powerful, open-source Kubernetes operator that simplifies the deployment and management of Ray applications on Kubernetes. Ray is a distributed computing framework designed for ML workloads, parallel processing, and distributed applications. KubeRay provides three custom resources (RayCluster, RayJob, RayService) that enable users to run distributed Ray workloads with autoscaling, fault tolerance, and zero-downtime upgrades. The operator manages Ray cluster lifecycle including creation, scaling, job submission, and service deployment with high availability. It integrates with OpenShift/Kubernetes RBAC, supports GCS fault tolerance, and provides comprehensive monitoring through Prometheus metrics. This component is essential for RHOAI users who need to run distributed ML training, batch inference, or serve ML models at scale.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kuberay-operator | Deployment | Main operator controller managing Ray CRDs and Kubernetes resources |
| RayCluster Controller | Reconciler | Manages lifecycle of Ray clusters including head and worker pods |
| RayJob Controller | Reconciler | Manages Ray job submission and execution on Ray clusters |
| RayService Controller | Reconciler | Manages Ray Serve deployments with zero-downtime upgrades |
| Ray Head Pod | Managed Pod | Ray cluster head node running GCS, dashboard, and client server |
| Ray Worker Pods | Managed Pods | Ray cluster worker nodes for distributed computation |
| Autoscaler Sidecar | Container | Optional Ray autoscaler for dynamic worker scaling |
| Batch Scheduler Integration | Optional | Integration with Volcano for gang scheduling |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| ray.io | v1 | RayCluster | Namespaced | Defines a Ray distributed computing cluster with head and worker nodes |
| ray.io | v1 | RayJob | Namespaced | Submits and manages Ray batch jobs with automatic cluster lifecycle |
| ray.io | v1 | RayService | Namespaced | Deploys Ray Serve applications with HA and zero-downtime upgrades |
| config.kuberay.io | v1alpha1 | Configuration | Cluster | Operator configuration (structured config file support) |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for operator health and CRD statistics |
| /healthz | GET | 8080/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8080/TCP | HTTP | None | None | Readiness probe endpoint |

### Ray Cluster Services (Created by Operator)

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| Ray GCS | 6379/TCP | Redis Protocol | None | Internal | Ray Global Control Store for cluster state |
| Ray Dashboard | 8265/TCP | HTTP | None | Optional | Ray cluster monitoring and debugging UI |
| Ray Client | 10001/TCP | gRPC | None | Optional | Ray client API for job submission |
| Ray Serve | 8000/TCP | HTTP | None | Optional | HTTP endpoint for Ray Serve inference |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.25+ | Yes | Container orchestration platform |
| Ray | 2.9.0+ | Yes | Distributed computing framework (runs in managed pods) |
| controller-runtime | v0.16.3 | Yes | Kubernetes controller framework |
| OpenShift Route API | v0.0.0-20211209135129 | No | OpenShift ingress support |
| Volcano | v1.6.0-alpha | No | Gang scheduling for distributed workloads |
| Redis | Latest | No | External Redis for GCS fault tolerance |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Operator | CRD Management | Installs and manages KubeRay operator deployment |
| Prometheus | Metrics Scraping | Collects operator metrics via /metrics endpoint |
| OpenShift Service CA | TLS Certificates | Optional TLS for webhooks and services |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kuberay-operator | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |
| {raycluster}-head-svc | ClusterIP | 6379/TCP, 8265/TCP, 10001/TCP, 8000/TCP | 6379, 8265, 10001, 8000 | Redis/HTTP/gRPC | None | Optional | Internal |
| {rayservice}-serve-svc | ClusterIP | 8000/TCP | 8000 | HTTP | None | Optional | Internal/External |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {raycluster}-ingress | Ingress/Route | User-defined | 8265/TCP | HTTP/HTTPS | Optional TLS | SIMPLE | External |
| {rayservice}-ingress | Ingress/Route | User-defined | 8000/TCP | HTTP/HTTPS | Optional TLS | SIMPLE | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch and manage Kubernetes resources |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secrets | Pull Ray container images |
| External Redis | 6379/TCP | Redis Protocol | Optional TLS | Password | GCS fault tolerance external storage |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kuberay-operator | ray.io | rayclusters, rayclusters/status, rayclusters/finalizers | create, delete, get, list, patch, update, watch |
| kuberay-operator | ray.io | rayjobs, rayjobs/status, rayjobs/finalizers | create, delete, get, list, patch, update, watch |
| kuberay-operator | ray.io | rayservices, rayservices/status, rayservices/finalizers | create, delete, get, list, patch, update, watch |
| kuberay-operator | "" (core) | pods, pods/status | create, delete, deletecollection, get, list, patch, update, watch |
| kuberay-operator | "" (core) | services, services/status | create, delete, get, list, patch, update, watch |
| kuberay-operator | "" (core) | serviceaccounts | create, delete, get, list, watch |
| kuberay-operator | "" (core) | events | create, delete, get, list, patch, update, watch |
| kuberay-operator | "" (core) | endpoints | get, list |
| kuberay-operator | batch | jobs | create, delete, get, list, patch, update, watch |
| kuberay-operator | rbac.authorization.k8s.io | roles, rolebindings | create, delete, get, list, update, watch |
| kuberay-operator | networking.k8s.io | ingresses, ingressclasses | create, delete, get, list, patch, update, watch |
| kuberay-operator | extensions | ingresses | create, delete, get, list, patch, update, watch |
| kuberay-operator | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| kuberay-operator | coordination.k8s.io | leases | create, get, list, update |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kuberay-operator | opendatahub | kuberay-operator (ClusterRole) | kuberay-operator |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {raycluster}-redis-auth | Opaque | Redis authentication for GCS FT | User/Operator | No |
| kuberay-operator-token | kubernetes.io/service-account-token | ServiceAccount token | Kubernetes | Yes |
| ray-pull-secret | kubernetes.io/dockerconfigjson | Pull Ray container images | User | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None | N/A | Prometheus scrapes internal service |
| /healthz, /readyz | GET | None | N/A | Health checks are unauthenticated |
| Kubernetes API | ALL | ServiceAccount Token | kube-apiserver | RBAC ClusterRole permissions |
| Ray Dashboard | GET, POST | Optional (configured by user) | Ray | User-defined auth |
| Ray Serve | POST | Optional (configured by user) | Ray | User-defined auth |

### Security Context Constraints (OpenShift)

| SCC Name | RunAsUser | Capabilities | Privilege Escalation | FSGroup |
|----------|-----------|--------------|----------------------|---------|
| run-as-ray-user | MustRunAs (UID 1000) | Drop ALL | false | Default |

### Pod Security

| Component | runAsNonRoot | allowPrivilegeEscalation | seccompProfile | Capabilities |
|-----------|--------------|--------------------------|----------------|--------------|
| kuberay-operator | true | false | N/A | Default |
| Ray Pods (with SCC) | true (UID 1000) | false | runtime/default | Drop ALL |

## Data Flows

### Flow 1: RayCluster Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/ODH | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | User Credentials |
| 2 | Operator | Kubernetes API (watch) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Operator | Kubernetes API (create pods) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Operator | Kubernetes API (create services) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | Ray Workers | Ray Head (GCS) | 6379/TCP | Redis Protocol | None | Internal |

### Flow 2: RayJob Submission

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API (create RayJob) | 443/TCP | HTTPS | TLS 1.2+ | User Credentials |
| 2 | Operator | Kubernetes API (create RayCluster) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Operator | Ray Dashboard (submit job) | 8265/TCP | HTTP | None | Optional |
| 4 | Job Submitter Pod | Ray Dashboard | 8265/TCP | HTTP | None | Optional |
| 5 | Operator | Ray Dashboard (poll status) | 8265/TCP | HTTP | None | Optional |

### Flow 3: RayService Inference

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API (create RayService) | 443/TCP | HTTPS | TLS 1.2+ | User Credentials |
| 2 | Operator | Kubernetes API (create RayCluster) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Operator | Ray Dashboard (deploy Serve app) | 8265/TCP | HTTP | None | Optional |
| 4 | Client | RayService Serve Endpoint | 8000/TCP | HTTP | None | Optional |
| 5 | Operator | Ray Dashboard (health check) | 8265/TCP | HTTP | None | Optional |

### Flow 4: Autoscaling

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Autoscaler Sidecar | Ray GCS | 6379/TCP | Redis Protocol | None | Internal |
| 2 | Autoscaler Sidecar | Kubernetes API (scale workers) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Operator | Kubernetes API (reconcile) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API | REST API | 443/TCP | HTTPS | TLS 1.2+ | Watch CRDs, manage pods/services/RBAC |
| Prometheus | Metrics Scraping | 8080/TCP | HTTP | None | Monitor operator health and performance |
| Ray Dashboard | HTTP API | 8265/TCP | HTTP | None | Job submission, cluster status, Serve deployment |
| Ray GCS | Redis Protocol | 6379/TCP | Redis | None | Ray cluster coordination and state |
| Volcano (optional) | CRD API | 443/TCP | HTTPS | TLS 1.2+ | Gang scheduling for distributed training |
| OpenShift Routes | CRD API | 443/TCP | HTTPS | TLS 1.2+ | External ingress for Ray services |
| External Redis (optional) | Redis Protocol | 6379/TCP | Redis | Optional TLS | GCS fault tolerance storage |

## Recent Changes

Based on recent commits from the rhoai-2.15 branch:

| Date | Commit | Changes |
|------|--------|---------|
| 2024-10-16 | 6ffcf96c | - Merged Konflux 2.16 updates<br>- Added renovate.json config for dependency management |
| 2024-10-08 | ffd64c82 | - Reviewed Dockerfile and RPM files for Konflux builds<br>- Optimized odh-kuberay-operator-controller container |
| 2024-08-14 | d490ea60 | - Raised head pod memory limit to improve test stability |
| 2024-06-26 | b0225b36 | - Upgraded Go version to 1.22.2 |
| 2024-06-21 | 9234fa92 | - Added SecurityContext to Ray pods for restricted pod-security compliance<br>- Enhanced OpenShift security posture |
| 2024-04-24 | 7bc7505d | - Updated KubeRay image to v1.1.0 |
| 2024-04-16 | d97a60c9 | - CVE fix: Upgraded golang.org/x/net<br>- Security improvements |
| 2024-04-16 | fe6fe205 | - Added delete patch to remove default namespace<br>- OpenShift/ODH specific customization |
| 2024-01-25 | c338e54a | - Added aggregator roles for admin and editor<br>- Improved RBAC integration |
| 2024-01-18 | c65bd46c | - CVE fix: Replaced go-sqlite3 version<br>- Security patch |
| 2023-10-24 | 8586365d | - Upgraded google.golang.org/grpc for CVE-2023-44487<br>- Security enhancement |
| 2023-10-06 | b7d9a95a | - Added OpenShift kustomize overlay for ODH operator<br>- RHOAI integration foundation |

## Deployment Architecture

### Kustomize Structure

The operator is deployed via Kustomize with OpenShift-specific overlays:

- **Base**: `ray-operator/config/default`
- **OpenShift Overlay**: `ray-operator/config/openshift`
  - Namespace: `opendatahub`
  - Custom SCC: `run-as-ray-user`
  - Image patch for ODH-specific image
  - Namespace removal patch
  - ConfigMap-based configuration

### Container Images

| Image | Purpose | Build System | Base Image |
|-------|---------|--------------|------------|
| odh-kuberay-operator-controller | Main operator | Konflux | registry.access.redhat.com/ubi8/ubi-minimal |
| rayproject/ray:2.9.0+ | Ray runtime | Upstream | User-configurable |

### Resource Requirements

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| kuberay-operator | 100m | 100m | 512Mi | 512Mi |
| Ray Head (example) | 500m | 1 | 2Gi | 2Gi |
| Ray Worker (example) | User-defined | User-defined | User-defined | User-defined |
| Autoscaler (default) | 500m | 500m | 512Mi | 512Mi |

### High Availability

| Feature | Implementation | Notes |
|---------|----------------|-------|
| Leader Election | Enabled (coordination.k8s.io/leases) | Single active operator replica |
| RayService HA | Zero-downtime upgrades | Pending/Active cluster model |
| GCS Fault Tolerance | External Redis storage | Optional feature for cluster recovery |
| Ray Head HA | GCS FT + Redis cleanup | Automatic recovery from head pod failures |

## Configuration

### Operator Configuration Options

| Option | Default | Purpose |
|--------|---------|---------|
| metrics-addr | :8080 | Prometheus metrics bind address |
| health-probe-bind-address | :8081 | Health probe endpoint |
| enable-leader-election | true | Enable HA leader election |
| reconcile-concurrency | 1 | Max concurrent reconciliations |
| watch-namespace | "" (all) | Namespaces to watch (comma-separated) |
| forced-cluster-upgrade | false | Force cluster upgrades |
| enable-batch-scheduler | false | Enable Volcano integration |
| log-file-path | "" | Optional log file path |

### Feature Flags

| Feature | Flag | Status |
|---------|------|--------|
| Batch Scheduler (Volcano) | enable-batch-scheduler | Optional |
| Forced Cluster Upgrade | forced-cluster-upgrade | Optional |
| Webhooks | ENABLE_WEBHOOKS=true | Optional |
| Init Container Injection | ENABLE_INIT_CONTAINER_INJECTION=true | Default enabled |

## Monitoring & Observability

### Metrics

The operator exposes Prometheus metrics on port 8080:

- **Controller Metrics**: Reconciliation duration, queue depth, error rates
- **CRD Metrics**: RayCluster count, RayJob count, RayService count
- **Resource Metrics**: Worker replicas (desired/available), CPU/Memory/GPU allocations
- **Custom Metrics**: Ray-specific cluster state, job status, service health

### Logging

| Component | Format | Encoder | Destination |
|-----------|--------|---------|-------------|
| Operator | JSON/Console | Configurable (zap) | stdout + optional file |
| Log Rotation | Lumberjack | 500MB max, 10 backups, 30 days retention | File system |

### Health Checks

| Endpoint | Type | Port | Purpose |
|----------|------|------|---------|
| /healthz | Liveness | 8080 | Operator process health |
| /readyz | Readiness | 8080 | Operator ready to reconcile |
| /metrics | Metrics | 8080 | Prometheus endpoint (used for probes) |

## Limitations & Considerations

1. **Security**: Ray Dashboard and Serve endpoints have no built-in authentication by default - users must configure auth separately
2. **Network**: Ray uses plaintext protocols internally (Redis, HTTP) - requires network policies for isolation
3. **Scaling**: Operator manages up to ~500 Ray pods effectively (per anecdotal resource limits)
4. **Storage**: GCS fault tolerance requires external Redis - not managed by operator
5. **OpenShift**: Requires custom SCC (run-as-ray-user) for UID 1000
6. **Upgrades**: RayService zero-downtime upgrades create temporary dual clusters - requires 2x resources

## Future Enhancements

Based on upstream KubeRay roadmap and recent development:

1. **Autoscaler Improvements**: Better integration with cluster autoscaler
2. **Multi-cluster Support**: Federation across Kubernetes clusters
3. **Enhanced Security**: Built-in mTLS for Ray communication
4. **Observability**: Better integration with distributed tracing
5. **Job Queue**: Enhanced job queuing and priority scheduling
6. **Configuration API**: Graduate Configuration CRD from v1alpha1 to v1
