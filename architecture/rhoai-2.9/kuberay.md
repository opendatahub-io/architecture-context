# Component: KubeRay Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kuberay.git
- **Version**: v1.1.0 (commit d97a60c9)
- **Branch**: rhoai-2.9
- **Distribution**: RHOAI
- **Languages**: Go 1.20
- **Deployment Type**: Kubernetes Operator
- **Manifests Location**: ray-operator/config/openshift (kustomize)

## Purpose
**Short**: Kubernetes operator for deploying and managing Ray distributed computing clusters on Kubernetes/OpenShift.

**Detailed**: KubeRay is a powerful Kubernetes operator that simplifies the deployment and management of Ray applications on Kubernetes and OpenShift. Ray is a distributed computing framework for ML/AI workloads. KubeRay provides three primary custom resource definitions: RayCluster for managing Ray cluster lifecycle including autoscaling and fault tolerance, RayJob for automatically creating clusters and submitting jobs with cleanup, and RayService for zero-downtime ML model serving with high availability. The operator manages the full lifecycle of Ray infrastructure including head nodes, worker nodes, services, ingress/routes, and integrates with batch schedulers like Volcano for gang scheduling. This component is essential for running distributed ML training, batch inference, and ML model serving workloads in RHOAI.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kuberay-operator | Go Operator (Deployment) | Reconciles RayCluster, RayJob, and RayService custom resources |
| RayCluster Controller | Controller | Manages Ray cluster head and worker pods, services, autoscaling |
| RayJob Controller | Controller | Manages Ray job submission and lifecycle with cluster creation/deletion |
| RayService Controller | Controller | Manages Ray Serve deployments with zero-downtime upgrades |
| Validating Webhook | Admission Webhook | Validates RayCluster resource creation and updates |
| Batch Scheduler Integration | Optional Component | Integration with Volcano for gang scheduling |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| ray.io | v1 | RayCluster | Namespaced | Defines a Ray cluster with head and worker groups, autoscaling configuration |
| ray.io | v1 | RayJob | Namespaced | Defines a Ray job with cluster spec and job submission parameters |
| ray.io | v1 | RayService | Namespaced | Defines a Ray Serve deployment with cluster config and serve application |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for operator monitoring |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator health check endpoint |

### Webhooks

| Type | Path | Port | Protocol | Encryption | Operations | Purpose |
|------|------|------|----------|------------|------------|---------|
| Validating | /validate-ray-io-v1-raycluster | 443/TCP | HTTPS | TLS 1.2+ | CREATE, UPDATE | Validates RayCluster resource specifications |

### Ray Cluster Services (Managed by Operator)

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| Ray GCS | 6379/TCP | TCP | None | Optional Redis password | Ray Global Control Service for cluster coordination |
| Ray Dashboard | 8265/TCP | HTTP | None | None | Ray cluster monitoring and job management UI |
| Ray Client | 10001/TCP | TCP | None | None | Ray client connection endpoint |
| Ray Metrics | 8080/TCP | HTTP | None | None | Ray cluster metrics for Prometheus |
| Ray Serve | 8000/TCP | HTTP | None | Optional | ML model serving endpoint (RayService) |
| Dashboard Agent | 52365/TCP | HTTP | None | None | Agent for per-node metrics and health checks |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.21+ | Yes | Container orchestration platform |
| controller-runtime | 0.16.3 | Yes | Kubernetes operator framework |
| cert-manager | Latest | No | TLS certificate management for webhooks |
| Prometheus | Any | No | Metrics collection and monitoring |
| Volcano | 1.6.0+ | No | Optional gang scheduling for distributed training |
| Redis | 6.0+ | No | Optional external GCS storage for fault tolerance |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| OpenShift Routes | API (route.openshift.io/v1) | Exposes Ray dashboard and serve endpoints externally |
| Service Mesh | Network | Ray services can be integrated with Istio for mTLS |
| Monitoring Stack | Metrics | Prometheus scrapes operator and Ray cluster metrics |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kuberay-operator | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |
| {raycluster}-head-svc | ClusterIP | 6379/TCP | 6379 | TCP | None | Optional | Internal |
| {raycluster}-head-svc | ClusterIP | 8265/TCP | 8265 | HTTP | None | None | Internal |
| {raycluster}-head-svc | ClusterIP | 10001/TCP | 10001 | TCP | None | None | Internal |
| {raycluster}-head-svc | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |
| {rayservice}-serve-svc | ClusterIP | 8000/TCP | 8000 | HTTP | None | Optional | Internal/External |
| {raycluster}-headless-worker-svc | Headless | Various | Various | TCP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {raycluster}-ingress | Ingress/Route | User-defined | 8265/TCP | HTTP/HTTPS | Optional TLS | SIMPLE | External |
| {rayservice}-ingress | Ingress/Route | User-defined | 8000/TCP | HTTP/HTTPS | Optional TLS | SIMPLE | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Manage Ray cluster resources |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secrets | Pull Ray container images |
| External Redis | 6379/TCP | TCP | Optional TLS | Password | External GCS storage for fault tolerance |
| S3/GCS/Azure Storage | 443/TCP | HTTPS | TLS 1.2+ | Cloud IAM | Ray application data storage |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kuberay-operator | "" | pods, pods/status | create, delete, deletecollection, get, list, patch, update, watch |
| kuberay-operator | "" | services, services/status | create, delete, get, list, patch, update, watch |
| kuberay-operator | "" | serviceaccounts | create, delete, get, list, watch |
| kuberay-operator | "" | events | create, delete, get, list, patch, update, watch |
| kuberay-operator | "" | endpoints | get, list |
| kuberay-operator | batch | jobs | create, delete, get, list, patch, update, watch |
| kuberay-operator | ray.io | rayclusters, rayclusters/status, rayclusters/finalizers | create, delete, get, list, patch, update, watch |
| kuberay-operator | ray.io | rayjobs, rayjobs/status, rayjobs/finalizers | create, delete, get, list, patch, update, watch |
| kuberay-operator | ray.io | rayservices, rayservices/status, rayservices/finalizers | create, delete, get, list, patch, update, watch |
| kuberay-operator | networking.k8s.io, extensions | ingresses | create, delete, get, list, patch, update, watch |
| kuberay-operator | networking.k8s.io | ingressclasses | get, list, watch |
| kuberay-operator | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| kuberay-operator | rbac.authorization.k8s.io | roles, rolebindings | create, delete, get, list, update, watch |
| kuberay-operator | coordination.k8s.io | leases | create, get, list, update |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kuberay-operator | opendatahub | kuberay-operator (ClusterRole) | kuberay-operator |

### OpenShift Security Context Constraints

| SCC Name | Type | runAsUser | seLinuxContext | Service Accounts |
|----------|------|-----------|----------------|------------------|
| run-as-ray-user | Custom | MustRunAs (UID 1000) | MustRunAs | kuberay-operator |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| webhook-server-cert | kubernetes.io/tls | Webhook TLS certificate | cert-manager | Yes |
| {raycluster}-redis-secret | Opaque | Optional Redis password for GCS | User/External | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None | Kubernetes Service | Network policy controls access |
| Ray Dashboard | GET, POST | None | Application | User must configure auth if needed |
| Ray Serve | POST | Optional API Key | Application | Application-level auth |
| Webhook | POST | TLS Client Cert | Kubernetes API | API server validates webhook cert |

### Pod Security

| Setting | Value | Purpose |
|---------|-------|---------|
| runAsNonRoot | true | Prevents running as root user |
| allowPrivilegeEscalation | false | Prevents privilege escalation |
| runAsUser | 65532 (operator), 1000 (Ray pods) | Non-root user execution |
| fsGroup | Not specified | Uses default |

## Data Flows

### Flow 1: RayCluster Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (kubeconfig) |
| 2 | Kubernetes API | Validating Webhook | 443/TCP | HTTPS | TLS 1.2+ | mTLS (K8s cert) |
| 3 | Kubernetes API | kuberay-operator | Internal | Watch | N/A | ServiceAccount Token |
| 4 | kuberay-operator | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | Kubernetes | Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret |

### Flow 2: Ray Job Submission (RayJob)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | kuberay-operator | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | kuberay-operator | Ray Dashboard | 8265/TCP | HTTP | None | None |
| 3 | Submitter Job | Ray Dashboard | 8265/TCP | HTTP | None | None |
| 4 | Ray Dashboard | Ray GCS | 6379/TCP | TCP | None | Optional Password |
| 5 | Ray Workers | Ray GCS | 6379/TCP | TCP | None | Optional Password |

### Flow 3: Model Serving (RayService)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | OpenShift Route/Ingress | 443/TCP | HTTPS | TLS 1.2+ | Optional API Key |
| 2 | Route/Ingress | Ray Serve Service | 8000/TCP | HTTP | None | Optional |
| 3 | Ray Serve | Ray Head/Workers | 10001/TCP | TCP | None | Internal |
| 4 | Ray Serve | Model Storage (S3/GCS) | 443/TCP | HTTPS | TLS 1.2+ | Cloud IAM |

### Flow 4: Monitoring and Metrics

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | kuberay-operator | 8080/TCP | HTTP | None | None |
| 2 | Prometheus | Ray Head Metrics | 8080/TCP | HTTP | None | None |
| 3 | User | Ray Dashboard | 8265/TCP | HTTP/HTTPS | Optional TLS | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 443/TCP | HTTPS | TLS 1.2+ | Resource management and watches |
| Prometheus | Metrics Scraping | 8080/TCP | HTTP | None | Operator and cluster monitoring |
| Volcano Scheduler | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | Gang scheduling for distributed training |
| OpenShift Routes | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | External access to dashboard and serve endpoints |
| External Redis | Redis Protocol | 6379/TCP | TCP | Optional TLS | GCS fault tolerance backend |
| S3/GCS/Azure Blob | Object Storage API | 443/TCP | HTTPS | TLS 1.2+ | Ray application data persistence |
| Service Mesh (Istio) | Network | Various | Various | mTLS | Optional secure service-to-service communication |

## Deployment Configuration

### Kustomize Structure

| Path | Purpose |
|------|---------|
| ray-operator/config/openshift | RHOAI/ODH production deployment configuration |
| ray-operator/config/default | Base Kubernetes deployment |
| ray-operator/config/crd | CRD definitions |
| ray-operator/config/rbac | RBAC resources |
| ray-operator/config/manager | Operator deployment and service |
| ray-operator/config/webhook | Webhook configuration |
| ray-operator/config/security | Security policies and pod security |

### Configuration Parameters

| Parameter | Default | Purpose |
|-----------|---------|---------|
| namespace | opendatahub | Target namespace for operator deployment |
| replicas | 1 | Number of operator replicas (leader election enabled) |
| metrics-addr | :8080 | Metrics endpoint address |
| health-probe-bind-address | :8081 | Health probe endpoint |
| reconcile-concurrency | 1 | Max concurrent reconciliations |
| enable-leader-election | false | Enable leader election for HA |
| forced-cluster-upgrade | false | Force cluster upgrades on spec changes |
| enable-batch-scheduler | false | Enable Volcano integration |

### Container Image

| Component | Base Image | Build Method | Registry |
|-----------|------------|--------------|----------|
| kuberay-operator | gcr.io/distroless/base-debian11:nonroot | Multi-stage Dockerfile with Go 1.20.10 | Konflux/Quay.io |

### Resource Requirements

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| kuberay-operator | 100m | 100m | 512Mi | 512Mi |

## Autoscaling and High Availability

### Operator HA

| Feature | Status | Configuration |
|---------|--------|---------------|
| Leader Election | Supported | Disabled by default, can be enabled with --enable-leader-election |
| Multiple Replicas | Supported | Set replicas > 1 with leader election enabled |
| Rolling Updates | Supported | Deployment strategy: Recreate |

### Ray Cluster Autoscaling

| Feature | Status | Configuration |
|---------|--------|---------------|
| Worker Autoscaling | Supported | Configure minReplicas/maxReplicas in workerGroupSpecs |
| Resource-based Scaling | Supported | Ray autoscaler monitors CPU/GPU/memory usage |
| Custom Metrics | Supported | Ray autoscaler can use custom application metrics |

## Observability

### Metrics

| Metric Source | Port | Path | Format | Purpose |
|---------------|------|------|--------|---------|
| kuberay-operator | 8080/TCP | /metrics | Prometheus | Operator reconciliation metrics, error rates |
| Ray Head | 8080/TCP | /metrics | Prometheus | Ray cluster resource usage, job statistics |
| Ray Dashboard | 8265/TCP | /api/... | JSON | Real-time cluster state and job information |

### Logging

| Component | Level | Format | Destination |
|-----------|-------|--------|-------------|
| kuberay-operator | Configurable (--zap-log-level) | JSON/Console | stdout/file (--log-file-path) |
| Ray Head/Workers | Configurable via Ray params | Text | /tmp/ray/session_*/logs/* |

### Health Checks

| Component | Type | Endpoint | Port | Protocol |
|-----------|------|----------|------|----------|
| kuberay-operator | Liveness | /metrics | 8080/TCP | HTTP |
| kuberay-operator | Readiness | /metrics | 8080/TCP | HTTP |
| Ray Head | Liveness | /api/gcs_healthz | 8265/TCP | HTTP |
| Ray Head | Readiness | /api/gcs_healthz | 8265/TCP | HTTP |
| Ray Worker | Liveness | /api/local_raylet_healthz | 52365/TCP | HTTP |
| Ray Worker | Readiness | /api/local_raylet_healthz | 52365/TCP | HTTP |
| Ray Serve | Readiness | /-/healthz | 8000/TCP | HTTP |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| d97a60c9 | 2024 | - DROP: CVE fix - Upgrade golang.org/x/net (#2081) |
| fe6fe205 | 2024 | - CARRY: Add delete patch to remove default namespace (#16) |
| 59ca3cdf | 2024 | - CARRY: Add workflow to release ODH/Kuberay with compiled test binaries |
| c338e54a | 2024 | - PATCH: add aggregator role for admin and editor |
| c65bd46c | 2024 | - PATCH: CVE fix - Replace go-sqlite3 version to upgraded version |
| 8586365d | 2024 | - PATCH: Upgrade google.golang.org/grpc to fix CVE-2023-44487 |
| b7d9a95a | 2024 | - PATCH: openshift kustomize overlay for odh operator |
| 8adc5387 | 2024 | - [release v1.1.0] Update tags and versions (#2036) |
| 32f56c34 | 2024 | - [Cherry-pick][Refactor][RayCluster] RayClusterHeadPodsAssociationOptions and RayClusterWorkerPodsAssociationOptions (#2023) (#2035) |
| 7440579e | 2024 | - [Cherry-pick][Test][RayCluster] Test redis cleanup job in the e2e compatibility test (#2026) (#2034) |

## Known Limitations and Considerations

### Security Considerations

1. **Dashboard Authentication**: Ray dashboard has no built-in authentication. Must be secured via network policies or external auth proxy.
2. **GCS Password**: Redis password for GCS is optional but recommended for production deployments.
3. **TLS Configuration**: Ray internal communication is not encrypted by default. Consider service mesh for mTLS.
4. **Route/Ingress Security**: Configure TLS termination and authentication at ingress layer for external access.

### Operational Considerations

1. **Resource Sizing**: Ray pods should be sized to use entire Kubernetes nodes for optimal performance.
2. **Storage**: Ray uses ephemeral storage by default. Configure PVCs for persistent object storage.
3. **Fault Tolerance**: Enable GCS fault tolerance with external Redis for production RayService deployments.
4. **Autoscaling**: Ray autoscaler requires metrics server and proper RBAC for pod scaling.
5. **Namespace Scope**: Operator can watch all namespaces or specific namespaces (configurable).

### Version Compatibility

| Component | Version | Notes |
|-----------|---------|-------|
| Kubernetes | 1.21+ | Required minimum version |
| OpenShift | 4.10+ | For Route support and SCC |
| Ray | 2.9.0 | Default Ray version in samples |
| Go | 1.20 | Operator build requirement |

## Architecture Diagrams Reference

This component integrates with the following RHOAI platform components:
- **Monitoring Stack**: Prometheus metrics collection
- **Service Mesh**: Optional mTLS and traffic management
- **OpenShift Routing**: External access to Ray services
- **Data Science Pipelines**: Ray clusters can be created for pipeline steps
- **Notebook Environments**: Users can create Ray clusters from notebooks

## Additional Resources

- **Upstream Documentation**: https://docs.ray.io/en/latest/cluster/kubernetes/index.html
- **KubeRay Repository**: https://github.com/ray-project/kuberay
- **Ray Documentation**: https://docs.ray.io/
- **Sample Configurations**: ray-operator/config/samples/
