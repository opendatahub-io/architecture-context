# Component: KubeRay

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kuberay.git
- **Version**: v1.1.0 (branch rhoai-2.11, commit b0225b36)
- **Distribution**: RHOAI
- **Languages**: Go 1.22.2
- **Deployment Type**: Kubernetes Operator
- **Manifests Location**: ray-operator/config (kustomize), with OpenShift overlay at ray-operator/config/openshift

## Purpose
**Short**: KubeRay is a Kubernetes operator that manages the lifecycle of Ray distributed computing clusters on Kubernetes.

**Detailed**: KubeRay provides a comprehensive solution for deploying and managing Ray applications on Kubernetes through custom resource definitions (CRDs). It offers three primary resources: RayCluster for creating and managing Ray compute clusters with autoscaling and fault tolerance, RayJob for automatically creating clusters and submitting batch jobs with automatic cleanup, and RayService for deploying Ray Serve applications with zero-downtime upgrades and high availability. The operator manages the complete lifecycle including cluster provisioning, pod management, service creation, autoscaling, and cleanup. It integrates with OpenShift through SecurityContextConstraints and Route support, and includes an optional community-maintained API server component that provides gRPC and HTTP APIs for simplified resource management.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kuberay-operator | Go Operator | Reconciles RayCluster, RayJob, and RayService CRDs, managing Ray infrastructure |
| RayCluster Controller | Controller | Manages Ray cluster lifecycle, autoscaling, and fault tolerance |
| RayJob Controller | Controller | Manages batch job submission and cluster lifecycle for jobs |
| RayService Controller | Controller | Manages Ray Serve deployments with zero-downtime upgrades |
| kuberay-apiserver | Optional Go Service | Community-maintained gRPC/HTTP API server for simplified resource management |
| Ray Head Pod | Managed Pod | Ray cluster head node running GCS, dashboard, and client server |
| Ray Worker Pods | Managed Pods | Ray cluster worker nodes that execute distributed workloads |
| Ray Autoscaler | Sidecar Container | Manages dynamic scaling of Ray worker pods |
| Redis Cleanup Job | Batch Job | Cleans up Redis storage when GCS fault tolerance is enabled |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| ray.io | v1 | RayCluster | Namespaced | Defines a Ray compute cluster with head and worker node specifications |
| ray.io | v1 | RayJob | Namespaced | Defines a Ray batch job with automatic cluster provisioning and cleanup |
| ray.io | v1 | RayService | Namespaced | Defines a Ray Serve deployment for model serving with HA and zero-downtime upgrades |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for operator monitoring |
| /healthz | GET | 8080/TCP | HTTP | None | None | Operator health check endpoint |
| /readyz | GET | 8080/TCP | HTTP | None | None | Operator readiness check endpoint |

### Ray Head Pod Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| / | GET | 8265/TCP | HTTP | Optional TLS | Optional | Ray Dashboard for cluster monitoring and management |
| /api/* | GET/POST | 8265/TCP | HTTP | Optional TLS | Optional | Ray Dashboard REST API for job submission and status |
| N/A | N/A | 10001/TCP | Ray Protocol | Optional TLS | Optional | Ray client connection endpoint for remote job submission |
| N/A | N/A | 6379/TCP | Redis Protocol | None | None | Ray Global Control Service (GCS) for cluster coordination |
| / | GET/POST | 8000/TCP | HTTP | Optional TLS | Optional | Ray Serve HTTP endpoint for model inference (RayService only) |

### gRPC Services (KubeRay APIServer - Optional Component)

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ClusterService | 8887/TCP | gRPC | Optional TLS | Optional Bearer | Create, get, list, update, delete Ray clusters |
| JobService | 8887/TCP | gRPC | Optional TLS | Optional Bearer | Manage Ray batch jobs |
| ServeService | 8887/TCP | gRPC | Optional TLS | Optional Bearer | Manage Ray Serve deployments |
| ComputeTemplateService | 8887/TCP | gRPC | Optional TLS | Optional Bearer | Manage compute templates for resource configuration |
| RayJobSubmissionService | 8887/TCP | gRPC | Optional TLS | Optional Bearer | Submit jobs directly to Ray Dashboard |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.19+ | Yes | Container orchestration platform |
| Redis | Any | No | External storage for GCS fault tolerance (optional) |
| Prometheus | Any | No | Metrics collection and monitoring |
| cert-manager | Any | No | Certificate management for webhooks and TLS |
| Volcano | Any | No | Batch scheduler for gang scheduling support |
| Kueue | Any | No | Job queueing system for resource quotas |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| OpenShift Routes | CRD Management | Operator creates Routes for external access to Ray services |
| Prometheus Operator | ServiceMonitor | Operator metrics scraped by cluster Prometheus |
| OpenShift OAuth | Optional | Authentication for Ray Dashboard access (when configured) |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kuberay-operator | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |
| {raycluster-name}-head-svc | ClusterIP | 6379/TCP | 6379 | Redis | None | None | Internal |
| {raycluster-name}-head-svc | ClusterIP | 8265/TCP | 8265 | HTTP/HTTPS | Optional TLS | Optional | Internal/External via Route |
| {raycluster-name}-head-svc | ClusterIP | 10001/TCP | 10001 | Ray Protocol | Optional TLS | Optional | Internal/External via Route |
| {raycluster-name}-head-svc | ClusterIP | 8000/TCP | 8000 | HTTP/HTTPS | Optional TLS | Optional | Internal/External via Ingress/Route |
| {rayservice-name}-serve-svc | ClusterIP | 8000/TCP | 8000 | HTTP/HTTPS | Optional TLS | Optional | Internal/External via Ingress/Route |
| kuberay-apiserver | ClusterIP | 8887/TCP | 8887 | gRPC/HTTP | Optional TLS | Optional Bearer | Internal |
| kuberay-apiserver | ClusterIP | 8888/TCP | 8888 | HTTP | Optional TLS | Optional Bearer | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {raycluster-name}-ingress | Kubernetes Ingress | User-defined | 8265/TCP | HTTP/HTTPS | Optional TLS | SIMPLE | External |
| {rayservice-name}-ingress | Kubernetes Ingress | User-defined | 8000/TCP | HTTP/HTTPS | Optional TLS | SIMPLE | External |
| {raycluster-name}-route | OpenShift Route | Auto-generated | 8265/TCP | HTTPS | Edge/Passthrough | N/A | External (OpenShift only) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch and manage Kubernetes resources |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret | Pull Ray container images |
| External Redis | 6379/TCP | Redis Protocol | Optional TLS | Optional Password | GCS fault tolerance storage (if external Redis configured) |
| PyPI/Conda Mirrors | 443/TCP | HTTPS | TLS 1.2+ | None | Download Python packages in Ray containers (user workloads) |
| S3/GCS/Azure Blob | 443/TCP | HTTPS | TLS 1.2+ | Cloud IAM/Keys | Object storage access for Ray applications (user workloads) |

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
| kuberay-operator | networking.k8s.io | ingresses, ingressclasses | create, delete, get, list, patch, update, watch |
| kuberay-operator | extensions | ingresses | create, delete, get, list, patch, update, watch |
| kuberay-operator | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| kuberay-operator | rbac.authorization.k8s.io | roles, rolebindings | create, delete, get, list, update, watch |
| kuberay-operator | coordination.k8s.io | leases | create, get, list, update |
| kuberay-rayjob-editor | ray.io | rayjobs | create, delete, get, list, patch, update, watch |
| kuberay-rayjob-viewer | ray.io | rayjobs | get, list, watch |
| kuberay-rayservice-editor | ray.io | rayservices | create, delete, get, list, patch, update, watch |
| kuberay-rayservice-viewer | ray.io | rayservices | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kuberay-operator | opendatahub (RHOAI) | kuberay-operator (ClusterRole) | kuberay-operator |
| leader-election-rolebinding | opendatahub (RHOAI) | leader-election-role | kuberay-operator |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {raycluster-name}-tls | kubernetes.io/tls | TLS certificates for Ray Dashboard/Client (optional) | cert-manager or manual | Yes (cert-manager) / No (manual) |
| {raycluster-name}-redis-password | Opaque | Redis password for external Redis (optional) | User | No |
| ray-image-pull-secret | kubernetes.io/dockerconfigjson | Pull Ray container images from private registry | User | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None | None | Operator metrics exposed without auth |
| Ray Dashboard | GET/POST | Optional OAuth/OIDC | Ingress/Route | Configured via annotations, not enforced by operator |
| Ray Client (10001/TCP) | Ray Protocol | Optional mTLS | Ray Runtime | Configured via TLS certificates in RayCluster spec |
| Ray Serve (8000/TCP) | GET/POST | Application-defined | Application Code | User application implements auth logic |
| Kubernetes API | All | ServiceAccount JWT | kube-apiserver | RBAC policies defined above |
| KubeRay APIServer | gRPC/HTTP | Optional Bearer Token | APIServer Interceptor | Community-maintained, optional authentication |

### OpenShift Security

| Resource | Type | Purpose |
|----------|------|---------|
| run-as-ray-user | SecurityContextConstraints | Allows kuberay-operator to run as UID 1000 with restricted privileges |

**SCC Details**:
- SELinux: MustRunAs
- RunAsUser: MustRunAs (UID 1000)
- AllowPrivilegeEscalation: false
- RequiredDropCapabilities: ALL
- SeccompProfile: runtime/default

## Data Flows

### Flow 1: RayCluster Creation and Lifecycle Management

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Kubernetes API | kuberay-operator | N/A | Watch Stream | TLS 1.2+ | ServiceAccount Token |
| 3 | kuberay-operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Kubernetes | Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret |
| 5 | Ray Worker | Ray Head (GCS) | 6379/TCP | Redis Protocol | None | None |
| 6 | Autoscaler (sidecar) | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 7 | Prometheus | kuberay-operator | 8080/TCP | HTTP | None | None |

### Flow 2: RayJob Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | kuberay-operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | kuberay-operator | Ray Dashboard API | 8265/TCP | HTTP | Optional TLS | None |
| 4 | Job Submitter Pod | Ray Dashboard API | 8265/TCP | HTTP | Optional TLS | None |
| 5 | Ray Dashboard | Ray Head (GCS) | 6379/TCP | Redis Protocol | None | None |
| 6 | Job Submitter Pod | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 3: RayService Model Serving

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | kuberay-operator | Ray Dashboard API | 8265/TCP | HTTP | Optional TLS | None |
| 2 | kuberay-operator | Ray Serve Proxy | 8000/TCP | HTTP | Optional TLS | None |
| 3 | External Client | Ingress/Route | 443/TCP | HTTPS | TLS 1.3 | Application-defined |
| 4 | Ingress/Route | Ray Serve Service | 8000/TCP | HTTP/HTTPS | Optional TLS | Application-defined |
| 5 | Ray Serve Replica | Ray Head (GCS) | 6379/TCP | Redis Protocol | None | None |

### Flow 4: Ray Autoscaling

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Autoscaler Sidecar | Ray Head (GCS) | 6379/TCP | Redis Protocol | None | None |
| 2 | Autoscaler Sidecar | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | kuberay-operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Kubernetes Scheduler | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Watch CRDs, manage Pods, Services, Ingresses, Jobs |
| Prometheus | Metrics Scraping | 8080/TCP | HTTP | None | Collect operator and Ray cluster metrics |
| Ray Dashboard | HTTP API | 8265/TCP | HTTP/HTTPS | Optional TLS | Query cluster status, submit jobs, manage Serve deployments |
| Ray GCS | Redis Protocol | 6379/TCP | Redis | None | Cluster state coordination and worker registration |
| Container Registry | Image Pull | 443/TCP | HTTPS | TLS 1.2+ | Pull Ray operator and runtime images |
| OpenShift Route API | CRD Management | 6443/TCP | HTTPS | TLS 1.2+ | Create and manage Routes for external access |
| Volcano Scheduler | Batch Scheduling | N/A | CRD | N/A | Gang scheduling for Ray clusters (optional) |
| Kueue | Job Queueing | N/A | CRD | N/A | Resource quota management for RayJobs (optional) |
| cert-manager | Certificate Management | N/A | CRD | N/A | Provision TLS certificates for Ray services (optional) |
| External Redis | Redis Protocol | 6379/TCP | Redis | Optional TLS | GCS fault tolerance storage (optional) |

## Deployment Architecture

### Operator Deployment

- **Replicas**: 1 (leader election enabled for HA)
- **Resources**: 100m CPU / 512Mi memory (requests and limits)
- **Strategy**: Recreate
- **SecurityContext**: runAsNonRoot: true, allowPrivilegeEscalation: false
- **Probes**: Liveness and readiness on /metrics endpoint (8080/TCP)

### Ray Cluster Topology

**Head Node**:
- Single replica (HA with GCS fault tolerance requires external Redis)
- Runs Ray GCS, Dashboard, Client Server, and optional Autoscaler
- Always present in cluster

**Worker Nodes**:
- Dynamic replicas (min/max defined in workerGroupSpecs)
- Multiple worker groups supported with heterogeneous resource specs
- Autoscaler manages scaling within min/max bounds
- Workers register with head node GCS on startup

## Recent Changes

Based on git history from rhoai-2.11 branch:

| Commit | Date | Changes |
|--------|------|---------|
| b0225b36 | Recent | - Upgrade Go version to 1.22.2 for security and compatibility |
| 9234fa92 | Recent | - Add SecurityContext to Ray pods for restricted pod-security compliance |
| 7bc7505d | Recent | - Update KubeRay image to v1.1.0 |
| d97a60c9 | Recent | - CVE fix: Upgrade golang.org/x/net dependency |
| fe6fe205 | Recent | - Add delete patch to remove default namespace for ODH deployment |
| 59ca3cdf | Recent | - Add workflow to release ODH/KubeRay with compiled test binaries |
| c338e54a | Recent | - Add aggregator role for admin and editor RBAC |
| c65bd46c | Recent | - CVE fix: Replace go-sqlite3 with upgraded version |
| 8586365d | Recent | - Upgrade google.golang.org/grpc to fix CVE-2023-44487 |
| b7d9a95a | Recent | - Add OpenShift kustomize overlay for ODH operator integration |

### Notable Features in v1.1.0 Release

- **GCS Fault Tolerance**: Redis cleanup jobs, improved HA support, better handling of sidecar containers
- **RayService Improvements**: Zero-downtime upgrades, high availability support, health check enhancements
- **RayJob Enhancements**: Runtime environment support, improved job status reconciliation, log streaming
- **Autoscaling**: Operator-controlled pod deletion, random pod deletion during scale-down, improved replica management
- **Security**: Seccomp profile support, restricted pod security compliance
- **OpenShift Integration**: Route support, SecurityContextConstraints, namespace customization

## Configuration

### Environment Variables (Operator)

| Variable | Default | Purpose |
|----------|---------|---------|
| ENABLE_INIT_CONTAINER_INJECTION | true | Auto-inject init container waiting for Ray GCS |
| CLUSTER_DOMAIN | cluster.local | Kubernetes cluster domain |
| RAYCLUSTER_DEFAULT_REQUEUE_SECONDS_ENV | 300 | Reconciliation requeue interval |
| ENABLE_WEBHOOKS | false | Enable validation webhooks for RayCluster CRD |

### Command-Line Flags (Operator)

| Flag | Default | Purpose |
|------|---------|---------|
| --metrics-addr | :8080 | Metrics endpoint bind address |
| --health-probe-bind-address | :8081 | Health probe endpoint bind address |
| --enable-leader-election | false | Enable leader election for HA |
| --leader-election-namespace | (pod namespace) | Namespace for leader election lease |
| --reconcile-concurrency | 1 | Max concurrent reconciliation goroutines |
| --watch-namespace | "" (all) | Comma-separated list of namespaces to watch |
| --forced-cluster-upgrade | false | Force cluster upgrades even with running jobs |
| --enable-batch-scheduler | false | Enable Volcano batch scheduler integration |
| --log-file-path | "" | Path to log file for persistent logging |

## Known Limitations

1. **Single Head Node**: RayCluster runs a single head pod; HA requires GCS fault tolerance with external Redis
2. **Network Isolation**: Ray GCS (6379/TCP) uses unencrypted Redis protocol; not suitable for multi-tenant environments without network policies
3. **Authentication**: Ray Dashboard and Client endpoints do not enforce authentication by default; rely on Ingress/Route for auth
4. **Resource Limits**: Autoscaler cannot scale beyond Kubernetes cluster capacity; may require manual intervention
5. **OpenShift Routes**: Route creation requires route.openshift.io API group; not available on vanilla Kubernetes
6. **Webhook Support**: Validation webhooks are opt-in and not enabled by default in RHOAI deployment

## Troubleshooting

### Common Issues

1. **Worker pods not joining cluster**: Check GCS connectivity on port 6379, verify DNS resolution of head service
2. **Autoscaler not scaling**: Verify RBAC permissions, check autoscaler container logs, ensure min/max replicas are set
3. **Jobs stuck in PENDING**: Check Ray Dashboard readiness, verify job submitter pod status, review RayJob events
4. **RayService zero-downtime upgrade failing**: Verify Serve application health checks, review serve-svc endpoint readiness
5. **Operator reconciliation loops**: Check for resource conflicts, review operator logs for error patterns, verify CRD versions

### Debug Commands

```bash
# Check operator logs
kubectl logs -n opendatahub deployment/kuberay-operator

# Check RayCluster status
kubectl describe raycluster -n <namespace> <cluster-name>

# Check Ray head pod logs
kubectl logs -n <namespace> <raycluster-name>-head-xxxxx

# Check autoscaler logs (if enabled)
kubectl logs -n <namespace> <raycluster-name>-head-xxxxx -c autoscaler

# View operator metrics
kubectl port-forward -n opendatahub svc/kuberay-operator 8080:8080
curl http://localhost:8080/metrics

# Check Ray Dashboard
kubectl port-forward -n <namespace> <raycluster-name>-head-xxxxx 8265:8265
# Navigate to http://localhost:8265
```
