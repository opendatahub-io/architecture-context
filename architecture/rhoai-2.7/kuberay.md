# Component: KubeRay Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kuberay.git
- **Version**: 63106681 (rhoai-2.7 branch)
- **Distribution**: RHOAI
- **Languages**: Go 1.20
- **Deployment Type**: Kubernetes Operator
- **Build**: Multi-stage container build using UBI9 Go toolset and UBI9 minimal

## Purpose
**Short**: Kubernetes operator that manages the lifecycle of Ray clusters, jobs, and services for distributed computing workloads.

**Detailed**: KubeRay is a Kubernetes operator that simplifies the deployment and management of Ray applications on Kubernetes. Ray is a distributed computing framework designed for machine learning, data processing, and model serving workloads. KubeRay provides three custom resource definitions (RayCluster, RayJob, RayService) that enable users to declaratively define Ray clusters with autoscaling capabilities, submit batch jobs, and deploy ML model serving applications with zero-downtime upgrades and high availability. The operator manages the complete lifecycle including cluster creation, scaling, fault tolerance, ingress/route configuration, and cleanup. It supports both vanilla Kubernetes and OpenShift, with specific features like OpenShift Routes and SecurityContextConstraints integration.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kuberay-operator | Go Controller Manager | Reconciles RayCluster, RayJob, and RayService custom resources |
| RayCluster Controller | Kubernetes Controller | Manages Ray cluster lifecycle, head/worker pods, services, autoscaling |
| RayJob Controller | Kubernetes Controller | Manages batch job submission and RayCluster lifecycle for jobs |
| RayService Controller | Kubernetes Controller | Manages Ray Serve deployments with zero-downtime upgrades |
| Batch Scheduler Manager | Integration Component | Optional integration with batch schedulers (Volcano) for gang scheduling |
| Service Builder | Utility Component | Creates Kubernetes Services and OpenShift Routes for Ray clusters |
| RBAC Manager | Utility Component | Creates ServiceAccounts, Roles, and RoleBindings for Ray pods |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| ray.io | v1 | RayCluster | Namespaced | Defines a Ray cluster with head and worker node specifications, autoscaling configuration |
| ray.io | v1 | RayJob | Namespaced | Defines a batch job that creates a RayCluster, submits work, and optionally cleans up |
| ray.io | v1 | RayService | Namespaced | Defines a Ray Serve deployment with RayCluster configuration and serve application graph |
| ray.io | v1alpha1 | RayCluster | Namespaced | Legacy API version for RayCluster (deprecated) |
| ray.io | v1alpha1 | RayJob | Namespaced | Legacy API version for RayJob (deprecated) |
| ray.io | v1alpha1 | RayService | Namespaced | Legacy API version for RayService (deprecated) |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for operator |
| /healthz | GET | 8082/TCP | HTTP | None | None | Liveness probe for operator |
| /readyz | GET | 8082/TCP | HTTP | None | None | Readiness probe for operator |

### Ray Cluster Services (Created by Operator)

| Service Type | Port | Protocol | Encryption | Purpose |
|--------------|------|----------|------------|---------|
| Ray Head Service (per cluster) | 6379/TCP | Ray GCS | Optional TLS | Ray Global Control Service - cluster coordination |
| Ray Dashboard (per cluster) | 8265/TCP | HTTP | Optional TLS | Ray cluster dashboard UI and metrics |
| Ray Client (per cluster) | 10001/TCP | gRPC | Optional TLS | Ray client connections for job submission |
| Ray Serve (per RayService) | 8000/TCP | HTTP | Optional TLS | ML model inference serving endpoint |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.28+ | Yes | Container orchestration platform |
| Go | 1.20 | Yes | Operator build and runtime |
| controller-runtime | 0.16.3 | Yes | Kubernetes controller framework |
| OpenShift API | Compatible | No | OpenShift Route support (when on OpenShift) |
| Volcano | 1.6.0-alpha+ | No | Optional batch scheduler for gang scheduling |
| Ray | 2.7.0+ | Yes | Ray runtime containers (user-provided) |
| Prometheus | Any | No | Optional metrics scraping |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| None | - | KubeRay operates independently; Ray clusters can integrate with other RHOAI components via standard APIs |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kuberay-operator | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |
| <cluster>-head-svc | ClusterIP/LoadBalancer | 6379/TCP | 6379 | Ray GCS | Optional TLS | Optional mTLS | Internal/External |
| <cluster>-head-svc | ClusterIP/LoadBalancer | 8265/TCP | 8265 | HTTP | Optional TLS | None | Internal/External |
| <cluster>-head-svc | ClusterIP/LoadBalancer | 10001/TCP | 10001 | gRPC | Optional TLS | Optional Token | Internal/External |
| <service>-serve-svc | ClusterIP/LoadBalancer | 8000/TCP | 8000 | HTTP | Optional TLS | Optional Token | Internal/External |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| <cluster>-ingress | Kubernetes Ingress | User-defined | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External |
| <cluster>-route | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ | Edge/Reencrypt | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | CRD reconciliation, pod/service management |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secrets | Ray container image pulls |
| External Storage (S3/GCS) | 443/TCP | HTTPS | TLS 1.2+ | Cloud IAM | Optional: Ray object storage, checkpointing |
| External Redis | 6379/TCP | Redis Protocol | Optional TLS | Password/ACL | Optional: External GCS backing store |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kuberay-operator | ray.io | rayclusters, rayclusters/status, rayclusters/finalizers | get, list, watch, create, update, patch, delete |
| kuberay-operator | ray.io | rayjobs, rayjobs/status, rayjobs/finalizers | get, list, watch, create, update, patch, delete |
| kuberay-operator | ray.io | rayservices, rayservices/status, rayservices/finalizers | get, list, watch, create, update, patch, delete |
| kuberay-operator | "" (core) | pods, pods/status | get, list, watch, create, update, patch, delete |
| kuberay-operator | "" (core) | services, services/status | get, list, watch, create, update, patch, delete |
| kuberay-operator | "" (core) | events | get, list, watch, create, update, patch, delete |
| kuberay-operator | "" (core) | serviceaccounts | get, list, watch, create, delete |
| kuberay-operator | batch | jobs | get, list, watch, create, update, patch, delete |
| kuberay-operator | coordination.k8s.io | leases | get, list, create, update |
| kuberay-operator | networking.k8s.io | ingresses, ingressclasses | get, list, watch, create, update, patch, delete |
| kuberay-operator | extensions | ingresses | get, list, watch, create, update, patch, delete |
| kuberay-operator | route.openshift.io | routes | get, list, watch, create, update, patch, delete |
| kuberay-operator | rbac.authorization.k8s.io | roles, rolebindings | get, list, watch, create, update, delete |
| ray-rayjob-editor | ray.io | rayjobs | get, list, watch, create, update, patch, delete |
| ray-rayjob-viewer | ray.io | rayjobs | get, list, watch |
| ray-rayservice-editor | ray.io | rayservices | get, list, watch, create, update, patch, delete |
| ray-rayservice-viewer | ray.io | rayservices | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kuberay-operator | Cluster-wide | kuberay-operator (ClusterRole) | kuberay-operator |
| leader-election-rolebinding | Operator namespace | leader-election-role (Role) | kuberay-operator |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| ray-tls-cert | kubernetes.io/tls | TLS certificates for Ray cluster components | User/cert-manager | No |
| ca-tls | Opaque | CA certificate for Ray cluster TLS | User/cert-manager | No |
| ray-image-pull-secret | kubernetes.io/dockerconfigjson | Container image pull credentials | User/cluster admin | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None | Operator Service | Prometheus scraper network access only |
| /healthz, /readyz | GET | None | Operator Pod | Kubernetes health probes |
| Ray GCS (6379) | TCP | Optional mTLS | Ray Head Pod | Ray TLS configuration (RAY_USE_TLS env) |
| Ray Dashboard (8265) | HTTP/HTTPS | Optional Token | Ray Head Pod | Ray dashboard authentication |
| Ray Client (10001) | gRPC | Optional Token | Ray Head Pod | Ray client authentication |
| Ray Serve (8000) | HTTP/HTTPS | Optional Bearer Token | Ray Serve Deployment | Application-level auth |

### SecurityContext Constraints (OpenShift)

| SCC Name | Run As User | SELinux | Purpose |
|----------|-------------|---------|---------|
| run-as-ray-user | MustRunAs (UID 1000) | MustRunAs | Allows Ray pods to run as UID 1000 |

### Pod Security

| Component | runAsNonRoot | allowPrivilegeEscalation | User |
|-----------|--------------|--------------------------|------|
| kuberay-operator | true | false | 65532 |
| Ray Head Pod | Configurable | Configurable | 1000 (default) |
| Ray Worker Pod | Configurable | Configurable | 1000 (default) |

## Data Flows

### Flow 1: RayCluster Creation and Pod Lifecycle

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Kubernetes API | kuberay-operator | - | Controller Watch | - | ServiceAccount Token |
| 3 | kuberay-operator | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Kubernetes Scheduler | Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secrets |
| 5 | Ray Head Pod | Ray Head Pod | - | Local | - | - |
| 6 | Ray Worker Pods | Ray Head Pod (GCS) | 6379/TCP | Ray Protocol | Optional TLS | Optional mTLS |

### Flow 2: RayJob Submission

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | kuberay-operator | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | kuberay-operator | Kubernetes API (Job) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Job Submitter Pod | Ray Head (Client) | 10001/TCP | gRPC | Optional TLS | Optional Token |
| 5 | Job Submitter Pod | Ray Head (GCS) | 6379/TCP | Ray Protocol | Optional TLS | Optional mTLS |

### Flow 3: Ray Serve Model Inference

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | Ingress/Route | 443/TCP | HTTPS | TLS 1.2+ | Optional Bearer |
| 2 | Ingress/Route | Ray Serve Service | 8000/TCP | HTTP/HTTPS | Optional TLS | Optional Bearer |
| 3 | Ray Serve Service | Ray Serve Replica Pods | 8000/TCP | HTTP/HTTPS | Optional TLS | Internal |
| 4 | Ray Serve Replica | Ray Head (GCS) | 6379/TCP | Ray Protocol | Optional TLS | Optional mTLS |

### Flow 4: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | kuberay-operator | 8080/TCP | HTTP | None | Network Policy |
| 2 | Prometheus | Ray Dashboard | 8265/TCP | HTTP/HTTPS | Optional TLS | Optional Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 443/TCP | HTTPS | TLS 1.2+ | CRD management, resource reconciliation |
| Prometheus | Metrics Scraping | 8080/TCP | HTTP | None | Operator metrics collection |
| Ray Dashboard | HTTP API | 8265/TCP | HTTP/HTTPS | Optional TLS | Cluster monitoring and job status |
| Ray Client | gRPC | 10001/TCP | gRPC | Optional TLS | Remote job submission and management |
| S3/GCS/Azure Blob | Object Storage API | 443/TCP | HTTPS | TLS 1.2+ | Ray object storage, checkpointing, logs |
| External Redis | Redis Protocol | 6379/TCP | Redis | Optional TLS | External GCS fault tolerance backend |
| Volcano Scheduler | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | Optional gang scheduling for Ray workloads |
| OpenShift Routes | OpenShift API | 443/TCP | HTTPS | TLS 1.2+ | External access on OpenShift |
| Ingress Controllers | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | External access on vanilla Kubernetes |

## Deployment Configuration

### Kustomize Manifests Location
- **Base Path**: `ray-operator/config`
- **Deployment Overlays**:
  - `ray-operator/config/default` - Default Kubernetes deployment
  - `ray-operator/config/openshift` - OpenShift-specific overlay with Route and SCC
  - `ray-operator/config/samples` - Example RayCluster, RayJob, RayService manifests

### Key Configuration Files
- **CRDs**: `ray-operator/config/crd/bases/`
- **RBAC**: `ray-operator/config/rbac/`
- **Manager Deployment**: `ray-operator/config/manager/manager.yaml`
- **Service**: `ray-operator/config/manager/service.yaml`

## Operational Considerations

### Resource Requirements

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| kuberay-operator | 100m | 100m | 512Mi | 512Mi |

**Note**: Ray head and worker pod resources are user-configurable via RayCluster spec.

### High Availability
- **Operator**: Leader election enabled by default (single active replica)
- **Ray Clusters**: Head node is single point of failure; GCS fault tolerance available with external Redis
- **RayService**: Zero-downtime upgrades via dual-cluster promotion strategy

### Autoscaling
- **Ray Autoscaler**: In-tree autoscaler sidecar on Ray head pod scales worker groups based on resource demands
- **Operator**: Does not autoscale itself (single replica with leader election)

### Monitoring
- Prometheus metrics exposed on `/metrics` endpoint (port 8080)
- Ray Dashboard provides cluster-level metrics and job status
- Annotations for automatic Prometheus scraping configured on operator service

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 63106681 | 2024-01-18 | - PATCH: CVE fix - Replace go-sqlite3 version to upgraded version |
| 742adbc5 | 2023-12-12 | - DROP: Upgrade to address High CVEs |
| e9fb86a9 | 2023-11-22 | - DROP: Upgrade Kubernetes dependencies to v0.28.3 and Golang to 1.20 |
| 972b5e2b | 2023-10-24 | - PATCH: Upgrade google.golang.org/grpc to fix CVE-2023-44487 |
| 38fb23d6 | 2023-10-06 | - PATCH: openshift kustomize overlay for odh operator |
| 1add258f | 2023-11-05 | - Release v1.0.0: Update tags and versions |
| fe815277 | 2023-11-02 | - Release v1.0.0-rc.2: Update tags and versions |
| bbbe7fee | 2023-11-02 | - Feature: Improve GCS FT cleanup UX |
| 23055200 | 2023-11-02 | - Bug: Fix FailedToGetJobStatus by allowing transition to Running |
| 09c70d22 | 2023-11-02 | - Hotfix: Avoid unnecessary zero-downtime upgrade |

## Known Limitations

1. **Ray Head Single Point of Failure**: Without external Redis GCS fault tolerance, Ray head pod failure requires cluster recreation
2. **No Multi-Tenancy Isolation**: Ray clusters in same namespace can potentially interfere if resource quotas not set
3. **TLS Configuration Complexity**: Requires manual certificate provisioning and configuration via init containers
4. **Limited Network Policy Support**: No default NetworkPolicy manifests provided; users must create custom policies
5. **Autoscaler Limitations**: Ray autoscaler is eventually consistent and may over-provision during rapid scaling events

## Future Enhancements

Based on recent development activity:
- Enhanced observability for debugging flaky RayJob executions
- Improved high availability for RayService with GCS fault tolerance
- Python client library for programmatic RayCluster management
- Better integration with batch schedulers (Volcano, Yunikorn)
- Extended RayJob APIs for fine-grained job control

## References

- **Upstream Documentation**: https://docs.ray.io/en/latest/cluster/kubernetes/index.html
- **KubeRay GitHub**: https://github.com/ray-project/kuberay
- **RHOAI Fork**: https://github.com/red-hat-data-services/kuberay
- **Development Guide**: `ray-operator/DEVELOPMENT.md`
- **Ray Project**: https://github.com/ray-project/ray
