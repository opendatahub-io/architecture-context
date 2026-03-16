# Component: KubeRay Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kuberay.git
- **Version**: v1.1.0 (commit b0225b36)
- **Distribution**: RHOAI
- **Languages**: Go 1.22.2
- **Deployment Type**: Kubernetes Operator
- **Manifests Location**: ray-operator/config/openshift

## Purpose
**Short**: Kubernetes operator that simplifies deployment and management of Ray distributed computing clusters on Kubernetes.

**Detailed**:
KubeRay is a powerful Kubernetes operator that manages the complete lifecycle of Ray applications on Kubernetes. Ray is a distributed computing framework for Python that enables parallel and distributed execution of workloads including machine learning training, batch inference, and model serving. The operator provides three Custom Resource Definitions (CRDs): RayCluster for managing Ray cluster infrastructure with autoscaling and fault tolerance; RayJob for automated job submission with automatic cluster lifecycle management; and RayService for zero-downtime deployments of Ray Serve applications with high availability.

The operator handles all aspects of cluster management including pod creation, service configuration, RBAC setup, ingress/route management, and integration with OpenShift security constraints. It supports advanced features like GCS fault tolerance with external Redis, batch scheduling integration with Volcano, and custom service configurations. The operator is specifically configured for OpenShift/RHOAI deployment with appropriate Security Context Constraints (SCC) to run Ray workloads securely in restricted environments.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| KubeRay Operator | Go Controller | Reconciles RayCluster, RayJob, and RayService CRs to manage Ray infrastructure |
| RayCluster Controller | Reconciliation Loop | Manages Ray cluster lifecycle including head/worker pods, services, and autoscaling |
| RayJob Controller | Reconciliation Loop | Creates RayCluster, submits jobs, manages job lifecycle and cleanup |
| RayService Controller | Reconciliation Loop | Manages Ray Serve deployments with zero-downtime upgrades and HA |
| Admission Webhook | Validation Webhook | Validates RayCluster CR specifications on create/update operations |
| Metrics Server | HTTP Endpoint | Exposes Prometheus metrics on port 8080 for operator health and performance |
| Batch Scheduler Manager | Integration Layer | Optional integration with Volcano for gang scheduling |
| Service Builder | Service Generator | Creates Kubernetes Services for Ray head nodes and serving endpoints |
| RBAC Manager | Resource Controller | Creates ServiceAccounts, Roles, and RoleBindings for Ray pods |
| Route Manager | OpenShift Integration | Creates OpenShift Routes for external access to Ray clusters |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| ray.io | v1 | RayCluster | Namespaced | Defines Ray cluster with head and worker groups, autoscaling, resource specs |
| ray.io | v1 | RayJob | Namespaced | Defines Ray job with cluster template, entrypoint, and lifecycle management |
| ray.io | v1 | RayService | Namespaced | Defines Ray Serve deployment with cluster config and serve application graph |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for operator health and performance |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness probe endpoint |

### Admission Webhooks

| Path | Type | Resources | Operations | Purpose |
|------|------|-----------|------------|---------|
| /validate-ray-io-v1-raycluster | Validating | rayclusters.ray.io | CREATE, UPDATE | Validates cluster name format and worker group uniqueness |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.28+ | Yes | Platform for operator and Ray cluster deployment |
| OpenShift API | v0.0.0-20211209135129 | Yes (for RHOAI) | OpenShift Route and SCC support |
| controller-runtime | v0.16.3 | Yes | Kubernetes controller framework |
| Volcano | v1.6.0-alpha+ | No | Optional gang scheduling for batch workloads |
| cert-manager | Latest | No | Optional TLS certificate management for webhooks |
| Prometheus | Latest | No | Optional metrics collection and monitoring |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | UI Integration | Display and manage Ray clusters through ODH UI |
| ODH Monitoring | Metrics Collection | Collect operator and Ray cluster metrics |

## Network Architecture

### Services

#### Operator Service

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kuberay-operator | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |

#### Ray Head Service (Created by Operator)

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {cluster}-head-svc | ClusterIP | 6379/TCP | 6379 | TCP | None | Optional Redis password | Internal |
| {cluster}-head-svc | ClusterIP | 8265/TCP | 8265 | HTTP | Optional TLS | Optional auth | Internal/External |
| {cluster}-head-svc | ClusterIP | 10001/TCP | 10001 | TCP | Optional TLS | Optional auth | Internal |
| {cluster}-head-svc | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |

#### Ray Serve Service (Created by Operator for RayService)

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {service}-serve-svc | ClusterIP | 8000/TCP | 8000 | HTTP | Optional TLS | Optional | External |

### Port Reference

| Port | Name | Protocol | Purpose | TLS Support |
|------|------|----------|---------|-------------|
| 6379/TCP | gcs | TCP | Ray Global Control Service - cluster metadata and coordination | No |
| 8265/TCP | dashboard | HTTP | Ray Dashboard web UI for cluster monitoring and management | Optional |
| 10001/TCP | client | TCP | Ray client connection port for submitting tasks | Optional |
| 8000/TCP | serve | HTTP | Ray Serve application serving endpoint | Optional |
| 8080/TCP | metrics | HTTP | Prometheus metrics endpoint | No |
| 52365/TCP | dashboard-agent | HTTP | Dashboard agent for worker node metrics | No |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {cluster}-ingress | Ingress/Route | User-defined | 8265/TCP | HTTP/HTTPS | Optional TLS | SIMPLE | External |
| {service}-serve-ingress | Ingress/Route | User-defined | 8000/TCP | HTTP/HTTPS | Optional TLS | SIMPLE | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch and reconcile CRs, manage resources |
| External Redis (optional) | 6379/TCP | TCP | Optional TLS | Password | GCS fault tolerance storage |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull credentials | Pull Ray container images |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kuberay-operator | "" | pods, pods/status | create, delete, deletecollection, get, list, patch, update, watch |
| kuberay-operator | "" | services, services/status | create, delete, get, list, patch, update, watch |
| kuberay-operator | "" | serviceaccounts | create, delete, get, list, watch |
| kuberay-operator | "" | endpoints | get, list |
| kuberay-operator | "" | events | create, delete, get, list, patch, update, watch |
| kuberay-operator | batch | jobs | create, delete, get, list, patch, update, watch |
| kuberay-operator | coordination.k8s.io | leases | create, get, list, update |
| kuberay-operator | networking.k8s.io | ingresses, ingressclasses | create, delete, get, list, patch, update, watch |
| kuberay-operator | extensions | ingresses | create, delete, get, list, patch, update, watch |
| kuberay-operator | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| kuberay-operator | rbac.authorization.k8s.io | roles, rolebindings | create, delete, get, list, update, watch |
| kuberay-operator | ray.io | rayclusters, rayclusters/status, rayclusters/finalizers | create, delete, get, list, patch, update, watch |
| kuberay-operator | ray.io | rayjobs, rayjobs/status, rayjobs/finalizers | create, delete, get, list, patch, update, watch |
| kuberay-operator | ray.io | rayservices, rayservices/status, rayservices/finalizers | create, delete, get, list, patch, update, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kuberay-operator | opendatahub | kuberay-operator | kuberay-operator |
| leader-election-role-binding | opendatahub | leader-election-role | kuberay-operator |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificate | cert-manager (optional) | Yes |
| ray-redis-password | Opaque | Redis authentication for external GCS | User/External system | No |

### OpenShift Security Context Constraints

| SCC Name | Run As User | Allow Privilege Escalation | Capabilities | seccompProfile | Applied To |
|----------|-------------|---------------------------|--------------|----------------|------------|
| run-as-ray-user | 1000 (MustRunAs) | false | DROP ALL | runtime/default | kuberay-operator ServiceAccount |

### Pod Security

| Component | runAsNonRoot | runAsUser | allowPrivilegeEscalation | capabilities | seccompProfile |
|-----------|--------------|-----------|-------------------------|--------------|----------------|
| kuberay-operator | true | 65532 | false | Not set | runtime/default |
| Ray Head Pod | true | 1000 | false | DROP ALL | runtime/default |
| Ray Worker Pod | true | 1000 | false | DROP ALL | runtime/default |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None | None | Public metrics endpoint |
| Kubernetes API | ALL | ServiceAccount Token (JWT) | Kubernetes API Server | RBAC ClusterRole permissions |
| Ray Dashboard | GET, POST | Optional custom auth | Ray Dashboard | User-configured |
| Ray GCS | TCP | Optional Redis password | Ray GCS Server | User-configured |

## Data Flows

### Flow 1: RayCluster Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/ODH Dashboard | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Kubernetes API | Admission Webhook | 443/TCP | HTTPS | TLS 1.2+ | Kubernetes internal |
| 3 | Admission Webhook | Kubernetes API | N/A | N/A | N/A | Validation response |
| 4 | KubeRay Operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | KubeRay Operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 6 | Kubelet | Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull credentials |
| 7 | Ray Workers | Ray Head GCS | 6379/TCP | TCP | None | Optional password |

### Flow 2: RayJob Submission

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | KubeRay Operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Job Submitter Pod | Ray Dashboard | 8265/TCP | HTTP | Optional TLS | Optional |
| 4 | Ray Dashboard | Ray GCS | 6379/TCP | TCP | None | Optional password |
| 5 | Ray GCS | Ray Workers | Various | TCP | None | Internal |

### Flow 3: Ray Serve Request

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | Ingress/Route | 443/TCP | HTTPS | TLS 1.2+ | Optional |
| 2 | Ingress/Route | Ray Serve Service | 8000/TCP | HTTP | None | Optional |
| 3 | Ray Serve Service | Ray Head Pod | 8000/TCP | HTTP | None | Optional |
| 4 | Ray Head | Ray Workers | Various | TCP | None | Internal |

### Flow 4: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | kuberay-operator | 8080/TCP | HTTP | None | None |
| 2 | Prometheus | Ray Head Pods | 8080/TCP | HTTP | None | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | CR reconciliation, resource management |
| Prometheus | Scrape | 8080/TCP | HTTP | None | Metrics collection from operator and Ray clusters |
| OpenShift Routes | Resource Management | N/A | N/A | N/A | External exposure of Ray services |
| Volcano Scheduler | Batch Scheduling API | N/A | N/A | N/A | Gang scheduling for Ray workloads |
| ODH Dashboard | UI/API | 6443/TCP | HTTPS | TLS 1.2+ | Display and manage Ray clusters |
| Container Registry | Image Pull | 443/TCP | HTTPS | TLS 1.2+ | Pull Ray and operator images |
| External Redis (optional) | TCP | 6379/TCP | TCP | Optional TLS | GCS fault tolerance storage |

## Deployment Configuration

### Operator Deployment

| Parameter | Value | Purpose |
|-----------|-------|---------|
| Replicas | 1 | Single operator instance (leader election disabled by default) |
| Strategy | Recreate | Prevent multiple operator instances during upgrades |
| Resource Requests | CPU: 100m, Memory: 512Mi | Minimum resources for operator |
| Resource Limits | CPU: 100m, Memory: 512Mi | Maximum resources for operator |
| Image | quay.io/kuberay/operator:v1.1.0 | Official KubeRay operator image |
| Namespace | opendatahub | RHOAI installation namespace |

### Controller Configuration

| Feature | Default | Configurable | Purpose |
|---------|---------|--------------|---------|
| Leader Election | Disabled | Yes | Prevent split-brain with multiple replicas |
| Reconcile Concurrency | Default | Yes | Number of concurrent reconciliation loops |
| Watch Namespace | All | Yes | Limit operator scope to specific namespaces |
| Forced Cluster Upgrade | false | Yes | Allow forced upgrades of Ray clusters |
| Batch Scheduler | false | Yes | Enable Volcano integration |
| Probe Injection | false | Yes | Auto-inject health probes into Ray containers |

## Operational Aspects

### Health Checks

| Check Type | Path | Port | Initial Delay | Period | Timeout | Failure Threshold |
|------------|------|------|---------------|--------|---------|-------------------|
| Liveness | /metrics | 8080/TCP | 10s | 5s | N/A | 5 |
| Readiness | /metrics | 8080/TCP | 10s | 5s | N/A | 5 |

### Logging

| Component | Format | Destination | Encoder | Rotation |
|-----------|--------|-------------|---------|----------|
| Operator | JSON/Console | stdout | Configurable | N/A |
| Operator (optional) | JSON/Console | File | Configurable | 500MB, 10 backups, 30 days |

### Monitoring Metrics

| Metric | Type | Purpose |
|--------|------|---------|
| controller_runtime_* | Various | Controller-runtime framework metrics |
| workqueue_* | Various | Reconciliation queue depth and latency |
| raycluster_* | Custom | Ray cluster status and resources |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| b0225b36 | 2024-06-26 | - DROP: Upgrade go version to 1.22.2 |
| 9234fa92 | 2024-06-21 | - PATCH: Add SecurityContext to ray pods to function with restricted pod-security |
| 7bc7505d | 2024-04-24 | - CARRY: Updated KubeRay image to v1.1.0 |
| d97a60c9 | 2024-04-16 | - DROP: CVE fix - Upgrade golang.org/x/net (#2081) |
| fe6fe205 | 2024-04-16 | - CARRY: Add delete patch to remove default namespace (#16) |
| 59ca3cdf | 2024-03-14 | - CARRY: Add workflow to release ODH/Kuberay with compiled test binaries |
| c338e54a | 2024-01-25 | - PATCH: add aggregator role for admin and editor |
| c65bd46c | 2024-01-18 | - PATCH: CVE fix - Replace go-sqlite3 version to upgraded version |
| 8586365d | 2023-10-24 | - PATCH: Upgrade google.golang.org/grpc to fix CVE-2023-44487 |
| b7d9a95a | 2023-10-06 | - PATCH: openshift kustomize overlay for odh operator |
| 8adc5387 | 2024-03-21 | - [release v1.1.0] Update tags and versions (#2036) |
| 32f56c34 | 2024-03-21 | - [Cherry-pick][Refactor][RayCluster] RayClusterHeadPodsAssociationOptions and RayClusterWorkerPodsAssociationOptions (#2023) (#2035) |
| 7440579e | 2024-03-21 | - [Cherry-pick][Test][RayCluster] Test redis cleanup job in the e2e compatibility test (#2026) (#2034) |
| 9c4768ff | 2024-03-21 | - [Cherry-pick][Bug] Reconciler error when changing the value of nameOverride in values.yaml of helm installation for Ray Cluster (#1966) (#2033) |
| 36076e51 | 2024-03-21 | - [Cherry-pick][Telemetry] KubeRay version and CRD (#2024) (#2032) |
| c8150767 | 2024-03-21 | - [Cherry-pick] Add seccompProfile.type=RuntimeDefault to kuberay-operator. (#1955) (#2031) |
| 780c3548 | 2024-03-21 | - ray-operator: parameterize Test_ShouldDeletePod (#2000) (#2030) |
| d2a65c0c | 2024-03-15 | - [release v1.1.0-rc.1] Update tags and versions (#2022) |
| 58a4e2c6 | 2024-03-15 | - [Cherry-pick] Bump google.golang.org/protobuf from 1.32.0 to 1.33.0 in /experimental (#1992) (#2021) |
| aae9d22d | 2024-03-15 | - [Cherry-pick] Bump google.golang.org/protobuf from 1.32.0 to 1.33.0 in /cli (#1993) (#2020) |

## Component Relationships

### CRD Hierarchy

```
RayService
  └─> RayCluster (managed)
      ├─> Head Pod
      │   └─> Head Service (ports: 6379, 8265, 10001, 8080)
      └─> Worker Pods (auto-scaled)

RayJob
  └─> RayCluster (temporary, auto-deleted)
      ├─> Head Pod
      └─> Worker Pods
  └─> Job Submitter Pod (K8s Job)

RayCluster (standalone)
  ├─> Head Pod
  │   └─> Head Service
  └─> Worker Pods
```

### Operator Managed Resources

| CR Type | Creates | Manages |
|---------|---------|---------|
| RayCluster | Pods, Services, ServiceAccounts, Roles, RoleBindings, Ingresses/Routes | Full lifecycle, autoscaling, fault tolerance |
| RayJob | RayCluster, K8s Job, all RayCluster resources | Job submission, RayCluster lifecycle, cleanup |
| RayService | RayCluster, Services (head + serve), all RayCluster resources | Zero-downtime upgrades, serve deployment, HA |

## Known Limitations

1. **Single Operator Replica**: Default configuration runs single operator instance without leader election
2. **Redis GCS**: External Redis for GCS fault tolerance requires manual setup and credentials
3. **TLS Configuration**: Ray-to-Ray encryption requires manual certificate management
4. **Resource Limits**: Default operator limits (100m CPU, 512Mi memory) may be insufficient for large deployments managing hundreds of Ray pods
5. **Namespace Scope**: Operator watches all namespaces by default; namespace filtering requires configuration
6. **Webhook Requirement**: Production deployments should enable webhooks for validation, requiring cert-manager or manual certificate provisioning

## Best Practices

1. **Resource Configuration**: Set Ray pod requests equal to limits for both CPU and memory to ensure QoS Guaranteed class
2. **Pod Sizing**: Use fewer large Ray pods rather than many small ones; ideally size pods to consume entire Kubernetes nodes
3. **Monitoring**: Enable Prometheus scraping of operator and Ray cluster metrics
4. **Security**: Use OpenShift SCC or Pod Security Standards to enforce non-root execution and dropped capabilities
5. **Fault Tolerance**: For production, configure external Redis for GCS fault tolerance
6. **Autoscaling**: Configure appropriate min/max replicas and resource thresholds for Ray autoscaler
7. **Health Probes**: Enable probe injection for Ray containers to improve cluster robustness
