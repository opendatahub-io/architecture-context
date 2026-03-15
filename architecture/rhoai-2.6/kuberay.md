# Component: KubeRay

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kuberay.git
- **Version**: 43912490 (rhoai-2.6 branch)
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: KubeRay is a Kubernetes operator that simplifies the deployment and management of Ray applications on Kubernetes through custom resources for clusters, jobs, and services.

**Detailed**: KubeRay provides a Kubernetes-native way to deploy and manage Ray, a distributed computing framework for ML workloads. The operator manages the complete lifecycle of Ray deployments including cluster creation/deletion, autoscaling, fault tolerance, and zero-downtime upgrades. It defines three core custom resources: RayCluster for managing Ray cluster infrastructure, RayJob for automated job submission and cluster lifecycle management, and RayService for deploying Ray Serve applications with high availability. The operator watches these custom resources and reconciles the desired state by creating and managing pods, services, ingresses, and other Kubernetes resources. An optional community-maintained APIServer component provides gRPC and HTTP APIs for simplified programmatic access to KubeRay resources.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kuberay-operator | Kubernetes Operator | Reconciles RayCluster, RayJob, and RayService custom resources to manage Ray deployments |
| RayCluster Controller | Controller | Manages Ray cluster lifecycle including head/worker pods, services, autoscaling, and fault tolerance |
| RayJob Controller | Controller | Automates Ray job submission and manages associated RayCluster lifecycle |
| RayService Controller | Controller | Manages Ray Serve deployments with zero-downtime upgrades and high availability |
| kuberay-apiserver (optional) | API Server | Provides gRPC and HTTP APIs for simplified KubeRay resource management |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| ray.io | v1 | RayCluster | Namespaced | Defines a Ray cluster with head and worker node specifications, autoscaling config, and Ray version |
| ray.io | v1 | RayJob | Namespaced | Defines a Ray job with entrypoint, resources, and automatic RayCluster creation/deletion |
| ray.io | v1 | RayService | Namespaced | Defines a Ray Serve deployment with RayCluster config and serve application graph |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for operator performance monitoring |
| /healthz | GET | 8082/TCP | HTTP | None | None | Operator health check endpoint |
| /readyz | GET | 8082/TCP | HTTP | None | None | Operator readiness check endpoint |
| /apis/v1/namespaces/{namespace}/clusters | POST, GET | 8888/TCP | HTTP | None | K8s RBAC | APIServer cluster management (optional component) |
| /apis/v1/namespaces/{namespace}/jobs | POST, GET | 8888/TCP | HTTP | None | K8s RBAC | APIServer job management (optional component) |
| /apis/v1/namespaces/{namespace}/services | POST, GET, PUT, PATCH | 8888/TCP | HTTP | None | K8s RBAC | APIServer Ray Serve management (optional component) |
| /healthz | GET | 8888/TCP | HTTP | None | None | APIServer health check (optional component) |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ClusterService | 8887/TCP | gRPC | None | K8s RBAC | APIServer cluster CRUD operations (optional component) |
| RayJobService | 8887/TCP | gRPC | None | K8s RBAC | APIServer job CRUD operations (optional component) |
| RayServeService | 8887/TCP | gRPC | None | K8s RBAC | APIServer Ray Serve CRUD operations (optional component) |
| ComputeTemplateService | 8887/TCP | gRPC | None | K8s RBAC | APIServer compute template management (optional component) |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.28.3+ | Yes | Platform for operator and Ray cluster deployment |
| Ray | 2.7.0+ | Yes | Distributed computing framework managed by the operator |
| OpenShift Routes | v1 | No | Optional ingress for Ray dashboard and services on OpenShift |
| Volcano Scheduler | - | No | Optional batch scheduler for gang scheduling |
| Prometheus | - | No | Optional metrics collection and monitoring |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | UI Integration | Potential integration for Ray cluster management UI |
| Monitoring Stack | Metrics API | Exports Prometheus metrics for platform monitoring |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kuberay-operator | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (metrics) |
| kuberay-apiserver | NodePort | 8888/TCP | 8888 | HTTP | None | K8s RBAC | External (optional) |
| kuberay-apiserver | NodePort | 8887/TCP | 8887 | gRPC | None | K8s RBAC | External (optional) |
| {raycluster}-head-svc | ClusterIP | 6379/TCP | 6379 | TCP | None | None | Internal (Ray GCS) |
| {raycluster}-head-svc | ClusterIP | 8265/TCP | 8265 | HTTP | None | None | Internal (Ray Dashboard) |
| {raycluster}-head-svc | ClusterIP | 10001/TCP | 10001 | TCP | None | None | Internal (Ray Client) |
| {rayservice}-serve-svc | ClusterIP | 8000/TCP | 8000 | HTTP | None | None | Internal (Ray Serve endpoint) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {raycluster}-ingress | Ingress/Route | User-defined | 8265/TCP | HTTP/HTTPS | Optional TLS | SIMPLE | External (Ray Dashboard) |
| {rayservice}-ingress | Ingress/Route | User-defined | 8000/TCP | HTTP/HTTPS | Optional TLS | SIMPLE | External (Ray Serve) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token | Operator watches and manages Kubernetes resources |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret | Pull Ray container images |
| External Storage (optional) | 443/TCP | HTTPS | TLS 1.2+ | Cloud Provider Auth | Ray clusters access S3/GCS for data |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kuberay-operator | ray.io | rayclusters, rayjobs, rayservices | create, delete, get, list, patch, update, watch |
| kuberay-operator | ray.io | rayclusters/status, rayjobs/status, rayservices/status | get, patch, update |
| kuberay-operator | ray.io | rayclusters/finalizers, rayjobs/finalizers, rayservices/finalizers | update |
| kuberay-operator | "" (core) | pods, services, events, serviceaccounts | create, delete, get, list, patch, update, watch |
| kuberay-operator | "" (core) | pods/status, services/status | create, delete, get, list, patch, update, watch |
| kuberay-operator | batch | jobs | create, delete, get, list, patch, update, watch |
| kuberay-operator | rbac.authorization.k8s.io | roles, rolebindings | create, delete, get, list, update, watch |
| kuberay-operator | networking.k8s.io | ingresses, ingressclasses | create, delete, get, list, patch, update, watch |
| kuberay-operator | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| kuberay-operator | coordination.k8s.io | leases | create, get, list, update |
| kuberay-apiserver | ray.io | rayclusters, rayjobs, rayservices | create, delete, get, list, patch, update, watch |
| kuberay-apiserver | "" (core) | configmaps, namespaces, events | create, delete, get, list, patch, update, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kuberay-operator | All (ClusterRoleBinding) | kuberay-operator | kuberay-operator |
| kuberay-apiserver | All (ClusterRoleBinding) | kuberay-apiserver | kuberay-apiserver |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {raycluster}-image-pull-secret | kubernetes.io/dockerconfigjson | Pull private Ray container images | User | No |
| {raycluster}-redis-password | Opaque | External Redis authentication (optional) | User | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics (operator) | GET | None | None | Metrics are unauthenticated |
| /healthz, /readyz | GET | None | None | Health checks are unauthenticated |
| APIServer HTTP/gRPC | All | Kubernetes RBAC | Kubernetes API Server | ClusterRole-based access control |
| Ray Dashboard | All | None (default) | Application | Can be configured with authentication |
| Ray GCS | TCP | None | Internal | Internal Ray cluster communication |

### Security Context Constraints (OpenShift)

| SCC Name | Type | Run As User | Purpose |
|----------|------|-------------|---------|
| run-as-ray-user | MustRunAs | UID 1000 | Allows kuberay-operator to run Ray pods as UID 1000 |

### Pod Security

| Component | runAsNonRoot | allowPrivilegeEscalation | Capabilities |
|-----------|--------------|--------------------------|--------------|
| kuberay-operator | true | false | None |
| kuberay-apiserver | default | default | None |
| Ray head/worker pods | User-defined | User-defined | User-defined |

## Data Flows

### Flow 1: RayCluster Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | kubeconfig |
| 2 | Kubernetes API | kuberay-operator | - | Watch API | TLS 1.2+ | Service Account Token |
| 3 | kuberay-operator | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 4 | Kubelet | Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret |
| 5 | Ray worker | Ray head (GCS) | 6379/TCP | TCP | None | Internal |

### Flow 2: RayJob Submission

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | kubeconfig |
| 2 | kuberay-operator | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 3 | kuberay-operator | Ray head | 8265/TCP | HTTP | None | None |
| 4 | Ray head | Ray workers | 6379/TCP | TCP | None | Internal |

### Flow 3: APIServer Cluster Management (Optional)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | kuberay-apiserver | 8888/TCP | HTTP | None | K8s RBAC |
| 2 | kuberay-apiserver | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 3 | Kubernetes API | kuberay-operator | - | Watch API | TLS 1.2+ | Service Account Token |

### Flow 4: Ray Serve Request

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | Ingress/Route | 443/TCP | HTTPS | TLS 1.2+ | Application-defined |
| 2 | Ingress/Route | {rayservice}-serve-svc | 8000/TCP | HTTP | None | None |
| 3 | Ray Serve | Ray head (GCS) | 6379/TCP | TCP | None | Internal |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API (Watch/CRUD) | 443/TCP | HTTPS | TLS 1.2+ | Operator watches CRDs and manages Kubernetes resources |
| Prometheus | Metrics Scrape | 8080/TCP | HTTP | None | Operator metrics collection for monitoring |
| Ray Head Node | HTTP API | 8265/TCP | HTTP | None | Job submission and cluster status queries |
| Ray GCS | TCP | 6379/TCP | TCP | None | Ray global control store for cluster state |
| Container Registry | Image Pull | 443/TCP | HTTPS | TLS 1.2+ | Pull Ray container images for pods |
| Volcano Scheduler (optional) | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | Gang scheduling for Ray pods |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 43912490 | 2024 | - Merge pull request #4: RHOAIENG-2184 DS pipeline support<br>- Added aggregator role for admin and editor<br>- Upgraded to address High CVEs (#1731)<br>- Upgraded Kubernetes dependencies to v0.28.3 and Golang to 1.20 (#1648) |
| 972b5e2b | 2023 | - Upgraded google.golang.org/grpc to fix CVE-2023-44487<br>- Added OpenShift kustomize overlay for ODH operator |
| 1add258f | 2023 | - Release v1.0.0: Updated tags and versions (#1627) |
| fe815277 | 2023 | - Release v1.0.0-rc.2: Updated tags and versions (#1620) |
| 1e45ed71 | 2023 | - Fixed odd number of arguments bug (#1594) (#1619) |
| 14a7b9e4 | 2023 | - Improved observability for flaky RayJob test (#1587) (#1618) |
| bbbe7fee | 2023 | - Improved GCS fault tolerance cleanup UX (#1592) (#1617) |
| 0725be35 | 2023 | - Added Python API server client (#1561) (#1616) |
| 1cddad3c | 2023 | - Fixed flaky sample YAML tests (#1590) (#1615) |
| ae6d47c5 | 2023 | - Allowed install and remove operator via scripts (#1545) (#1614) |
| 23055200 | 2023 | - Fixed RayJob FailedToGetJobStatus by allowing transition to Running (#1583) (#1613) |
| df50ef14 | 2023 | - Updated URL to use v1 (#1577) (#1612) |
| 09c70d22 | 2023 | - Fixed bug to avoid unnecessary zero-downtime upgrade (#1581) (#1611) |
| f31d57da | 2023 | - Fixed RayCluster RAY_REDIS_ADDRESS parsing with redis scheme (#1556) (#1610) |

## Deployment Configuration

### Operator Deployment

- **Namespace**: opendatahub (configurable)
- **Replicas**: 1 (leader election enabled)
- **Strategy**: Recreate
- **Container Image**: Built from ray-operator/Dockerfile using UBI9 Go toolset
- **Resource Limits**: CPU 100m, Memory 512Mi
- **Health Checks**: HTTP probes on /metrics endpoint (port 8080)
- **Metrics Collection**: Prometheus annotations enabled
- **Leader Election**: Enabled via coordination.k8s.io/leases

### Feature Flags

| Flag | Default | Purpose |
|------|---------|---------|
| --enable-leader-election | true | Enable leader election for HA operator deployment |
| --reconcile-concurrency | 1 | Maximum concurrent reconcile loops |
| --watch-namespace | "" (all) | Comma-separated list of namespaces to watch |
| --forced-cluster-upgrade | false | Enable forced cluster upgrade capability |
| --enable-batch-scheduler | false | Enable Volcano gang scheduler integration |
| --metrics-addr | :8080 | Metrics endpoint bind address |
| --health-probe-bind-address | :8082 | Health probe endpoint bind address |

### APIServer Deployment (Optional)

- **Namespace**: ray-system (default)
- **Replicas**: 1
- **Container Image**: Built from apiserver/Dockerfile
- **Resource Limits**: CPU 500m, Memory 500Mi
- **Ports**: 8887 (gRPC), 8888 (HTTP)
- **Service Type**: NodePort (NodePort 31887/31888 in default config)

## Ray Cluster Architecture

When a RayCluster CR is created, the operator deploys:

### Head Node Pod

- **Ports**: 6379 (GCS), 8265 (Dashboard), 10001 (Client)
- **Containers**: ray-head (rayproject/ray image)
- **Command**: `ray start --head` with configurable rayStartParams
- **Service**: ClusterIP service exposing all head ports
- **Volumes**: emptyDir for /tmp/ray logs

### Worker Node Pods

- **Replicas**: Configurable (minReplicas/maxReplicas for autoscaling)
- **Worker Groups**: Multiple worker groups with different resource configs
- **Containers**: ray-worker (rayproject/ray image)
- **Command**: `ray start` (connects to head via service discovery)
- **Autoscaling**: Optional Ray autoscaler sidecar for dynamic scaling

### Autoscaler (Optional)

- **Sidecar Container**: Ray autoscaler in head pod
- **Purpose**: Monitors Ray workload and scales worker groups
- **Configuration**: autoscalerOptions in RayCluster spec
