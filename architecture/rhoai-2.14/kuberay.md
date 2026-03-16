# Component: KubeRay

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kuberay.git
- **Version**: d490ea60 (rhoai-2.14 branch)
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator with optional API Server

## Purpose
**Short**: KubeRay is a Kubernetes operator that simplifies deployment and management of Ray distributed computing clusters on Kubernetes.

**Detailed**: KubeRay provides production-ready lifecycle management for Ray applications on Kubernetes through custom resource definitions and controllers. It offers three core CRDs: RayCluster for managing Ray cluster infrastructure with autoscaling and fault tolerance, RayJob for automated job submission with cluster lifecycle management, and RayService for zero-downtime deployments with high availability support. The operator automatically provisions Ray head and worker pods, manages networking services, handles scaling operations, and integrates with Kubernetes ecosystem tools. An optional API server component provides simplified REST/gRPC interfaces for managing Ray resources programmatically, enabling integration with custom user interfaces and automation workflows.

The component is specifically configured for OpenShift environments with Security Context Constraints (SCC) and supports Red Hat's Open Data Hub and RHOAI distributions. It enables data scientists and ML engineers to run distributed Ray workloads including training, batch inference, and model serving on Kubernetes infrastructure.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| KubeRay Operator | Kubernetes Operator | Reconciles RayCluster, RayJob, and RayService CRDs; manages Ray cluster lifecycle |
| KubeRay API Server (Optional) | gRPC/HTTP API Server | Provides simplified REST and gRPC APIs for managing Ray resources |
| Ray Head Pod | Application Pod | Ray cluster control plane; runs GCS, dashboard, and client server |
| Ray Worker Pods | Application Pod | Ray cluster compute nodes; execute distributed workloads |
| Ray Autoscaler | Sidecar Container | Automatically scales worker pods based on resource demands |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| ray.io | v1 | RayCluster | Namespaced | Defines a Ray cluster with head and worker groups; supports autoscaling and fault tolerance |
| ray.io | v1 | RayJob | Namespaced | Defines a Ray job submission; automatically creates RayCluster and manages job lifecycle |
| ray.io | v1 | RayService | Namespaced | Defines a Ray Serve deployment; provides zero-downtime upgrades and HA for serving workloads |

### HTTP Endpoints

#### KubeRay Operator

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint for operator monitoring |
| /healthz | GET | 8081/TCP | HTTP | None | None | Health check endpoint for operator liveness |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness check endpoint for operator startup |

#### KubeRay API Server (Optional)

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /apis/v1/namespaces/{ns}/clusters | POST, GET | 8888/TCP | HTTP | None | None | Create and list Ray clusters |
| /apis/v1/namespaces/{ns}/clusters/{name} | GET, DELETE | 8888/TCP | HTTP | None | None | Get and delete specific Ray cluster |
| /apis/v1/namespaces/{ns}/jobs | POST, GET | 8888/TCP | HTTP | None | None | Create and list Ray jobs |
| /apis/v1/namespaces/{ns}/services | POST, GET | 8888/TCP | HTTP | None | None | Create and list Ray services |

#### Ray Head Pod Services

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /api/jobs/ | POST, GET, DELETE | 8265/TCP | HTTP | None | None | Ray job submission API |
| / | GET | 8265/TCP | HTTP | None | None | Ray dashboard UI |
| /api/serve/applications/ | GET, PUT, DELETE | 8265/TCP | HTTP | None | None | Ray Serve application management |
| /{route_prefix} | POST | 8000/TCP | HTTP | None | None | Ray Serve inference endpoints |

### gRPC Services

#### KubeRay API Server (Optional)

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ClusterService | 8887/TCP | gRPC | None | None | CRUD operations for RayCluster resources |
| RayJobService | 8887/TCP | gRPC | None | None | CRUD operations for RayJob resources |
| RayServeService | 8887/TCP | gRPC | None | None | CRUD operations for RayService resources |
| ComputeTemplateService | 8887/TCP | gRPC | None | None | Manage compute templates for Ray clusters |
| RayJobSubmissionService | 8887/TCP | gRPC | None | None | Submit jobs to existing Ray clusters |

#### Ray Cluster Internal

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| GCS (Global Control Service) | 6379/TCP | Ray Protocol | None | None | Ray cluster coordination and metadata storage |
| Client Server | 10001/TCP | Ray Protocol | None | None | Ray client connection endpoint for job submission |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.19+ | Yes | Orchestration platform for Ray clusters |
| Ray | 2.9.0+ | Yes | Distributed computing framework (container image) |
| Prometheus (Optional) | Any | No | Metrics collection from operator and Ray clusters |
| Volcano Scheduler (Optional) | Any | No | Gang scheduling for batch workloads |
| External Redis (Optional) | 6.0+ | No | GCS fault tolerance for production clusters |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| OpenShift Route API | CRD | Creates Routes for external access to Ray dashboard and services |
| cert-manager (Optional) | CRD | TLS certificate provisioning for Ray services |

## Network Architecture

### Services

#### KubeRay Operator

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kuberay-operator | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |

#### KubeRay API Server (Optional)

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kuberay-apiserver-service | ClusterIP | 8888/TCP | 8888 | HTTP | None | None | Internal |
| kuberay-apiserver-service | ClusterIP | 8887/TCP | 8887 | gRPC | None | None | Internal |

#### Ray Cluster (Per RayCluster CR)

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {cluster}-head-svc | ClusterIP | 6379/TCP | 6379 | Ray Protocol | None | None | Internal |
| {cluster}-head-svc | ClusterIP | 8265/TCP | 8265 | HTTP | None | None | Internal |
| {cluster}-head-svc | ClusterIP | 10001/TCP | 10001 | Ray Protocol | None | None | Internal |
| {cluster}-head-svc | ClusterIP | 8000/TCP | 8000 | HTTP | None | None | Internal |
| {cluster}-serve-svc (RayService) | ClusterIP | 8000/TCP | 8000 | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {cluster}-ingress (Optional) | Kubernetes Ingress | User-defined | 8265/TCP, 8000/TCP | HTTP/HTTPS | TLS (Optional) | SIMPLE | External |
| {cluster}-route (Optional) | OpenShift Route | Auto-generated | 8265/TCP, 8000/TCP | HTTP/HTTPS | TLS (Optional) | edge/passthrough | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch and manage Kubernetes resources |
| External Redis (Optional) | 6379/TCP | Redis Protocol | TLS (Optional) | Password | GCS fault tolerance storage |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret | Pull Ray container images |
| Git Repositories (Optional) | 443/TCP | HTTPS | TLS 1.2+ | None | Download Ray Serve runtime environments |
| S3/Cloud Storage (Optional) | 443/TCP | HTTPS | TLS 1.2+ | Cloud IAM | Store Ray cluster artifacts and checkpoints |

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
| kuberay-operator | opendatahub (default) | kuberay-operator (ClusterRole) | kuberay-operator |
| leader-election-rolebinding | opendatahub (default) | leader-election-role (Role) | kuberay-operator |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| kuberay-operator-token | kubernetes.io/service-account-token | ServiceAccount token for API access | Kubernetes | Yes |
| {cluster}-redis-password (Optional) | Opaque | Redis authentication for GCS FT | User | No |
| ray-image-pull-secret (Optional) | kubernetes.io/dockerconfigjson | Pull private Ray images | User | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| KubeRay Operator Metrics | GET | None | None | Internal network only |
| KubeRay API Server | ALL | None (default) | Application | Can be configured with custom auth |
| Ray Dashboard | GET, POST | None (default) | None | Network isolation recommended |
| Ray Client | ALL | None (default) | None | Network isolation recommended |
| Ray Serve Endpoints | POST | None (default) | Application | App-specific auth possible |
| Kubernetes API | ALL | ServiceAccount Token (Bearer) | Kubernetes API Server | RBAC policies |

### Security Context Constraints (OpenShift)

| SCC Name | Run As User | Capabilities | Privilege Escalation | SELinux |
|----------|-------------|--------------|---------------------|---------|
| run-as-ray-user | MustRunAs (UID 1000) | Drop ALL | false | MustRunAs |

### Pod Security

| Component | runAsNonRoot | allowPrivilegeEscalation | capabilities | seccompProfile |
|-----------|--------------|--------------------------|--------------|----------------|
| kuberay-operator | true | false | Not set | runtime/default |
| Ray Head/Worker Pods | Recommended | false (enforced by SCC) | Drop ALL (enforced by SCC) | runtime/default (enforced by SCC) |

## Data Flows

### Flow 1: RayCluster Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | kubeconfig credentials |
| 2 | KubeRay Operator | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | KubeRay Operator | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Ray Head Pod | GCS (localhost) | 6379/TCP | Ray Protocol | None | None |
| 5 | Ray Worker Pods | Ray Head GCS | 6379/TCP | Ray Protocol | None | None |

**Flow Description**: User creates RayCluster CR → Operator watches CR → Operator creates head pod, service, worker pods → Head pod starts GCS → Workers connect to GCS

### Flow 2: RayJob Submission

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | kubeconfig credentials |
| 2 | KubeRay Operator | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Job Submitter Pod | Ray Dashboard API | 8265/TCP | HTTP | None | None |
| 4 | Ray Dashboard | Ray GCS | 6379/TCP | Ray Protocol | None | None |
| 5 | Ray Head | Ray Workers | 10001/TCP | Ray Protocol | None | None |

**Flow Description**: User creates RayJob CR → Operator creates RayCluster and Job submitter pod → Submitter pod submits job via dashboard API → Ray executes distributed workload

### Flow 3: Ray Serve Inference

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client Application | Ingress/Route | 443/TCP | HTTPS | TLS 1.2+ | None/Custom |
| 2 | Ingress/Route | Ray Serve Service | 8000/TCP | HTTP | None | None |
| 3 | Ray Serve Service | Ray Head Pod | 8000/TCP | HTTP | None | None |
| 4 | Ray Serve (Head) | Ray Serve (Workers) | Internal | Ray Protocol | None | None |
| 5 | Ray Serve | Ray GCS | 6379/TCP | Ray Protocol | None | None |

**Flow Description**: External client → Ingress/Route → Serve service → Ray Serve application → Distributed inference across Ray actors

### Flow 4: Operator Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | KubeRay Operator | 8080/TCP | HTTP | None | None |
| 2 | Prometheus | Ray Head Dashboard | 8265/TCP | HTTP | None | None |

**Flow Description**: Prometheus scrapes metrics from operator and Ray clusters for monitoring

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Watch CRDs, manage pods/services/ingresses |
| Prometheus | Metrics Scraping | 8080/TCP | HTTP | None | Operator and Ray cluster monitoring |
| Volcano Scheduler | Kubernetes Scheduler Plugin | N/A | N/A | N/A | Gang scheduling for batch jobs |
| OpenShift Routes | CRD | N/A | N/A | N/A | External access to Ray services |
| External Redis | Redis Protocol | 6379/TCP | Redis/TLS | Optional | GCS fault tolerance persistence |
| S3/Object Storage | REST API | 443/TCP | HTTPS | TLS 1.2+ | Ray cluster state and checkpoint storage |
| Container Registry | REST API | 443/TCP | HTTPS | TLS 1.2+ | Pull Ray operator and workload images |

## Deployment Architecture

### Operator Deployment

- **Deployment Strategy**: Recreate (single replica for leader election)
- **Replicas**: 1
- **Resources**:
  - CPU: 100m request/limit
  - Memory: 512Mi request/limit
- **Health Checks**: HTTP liveness/readiness on /metrics (port 8080)
- **Security**: runAsNonRoot, no privilege escalation, seccompProfile runtime/default

### Ray Cluster Deployment (Per RayCluster CR)

- **Head Pod**: 1 replica (stateful)
- **Worker Pods**: Variable (0 to maxReplicas, autoscales based on workload)
- **Autoscaler**: Optional sidecar container in head pod
- **Resources**: User-defined (CPU, memory, GPU, TPU)
- **Scheduling**: Default Kubernetes scheduler or optional Volcano gang scheduling

## Configuration

### Operator Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| ENABLE_INIT_CONTAINER_INJECTION | true | Inject init container to wait for Ray GCS |
| CLUSTER_DOMAIN | cluster.local | Kubernetes cluster domain for service DNS |
| RAYCLUSTER_DEFAULT_REQUEUE_SECONDS_ENV | 300 | Default reconciliation requeue interval |

### Deployment Manifests Location

- **Base Manifests**: `ray-operator/config/default`
- **OpenShift Overlay**: `ray-operator/config/openshift` (deployed in RHOAI)
- **Kustomization**: Uses kustomize for manifest management
- **Namespace**: opendatahub (default for RHOAI deployments)

## Recent Changes

| Commit | Changes |
|--------|---------|
| d490ea60 | PATCH: Raise head pod memory limit to avoid test instability |
| b0225b36 | DROP: Upgrade go version to 1.22.2 |
| 9234fa92 | PATCH: Add SecurityContext to ray pods to function with restricted pod-security |
| 7bc7505d | CARRY: Updated KubeRay image to v1.1.0 |
| d97a60c9 | DROP: CVE fix - Upgrade golang.org/x/net (#2081) |
| fe6fe205 | CARRY: Add delete patch to remove default namespace (#16) |
| 59ca3cdf | CARRY: Add workflow to release ODH/Kuberay with compiled test binaries |
| c338e54a | PATCH: add aggregator role for admin and editor |
| c65bd46c | PATCH: CVE fix - Replace go-sqlite3 version to upgraded version |
| 8586365d | PATCH: Upgrade google.golang.org/grpc to fix CVE-2023-44487 |
| b7d9a95a | PATCH: openshift kustomize overlay for odh operator |
| 8adc5387 | [release v1.1.0] Update tags and versions (#2036) |
| 32f56c34 | [Cherry-pick][Refactor][RayCluster] RayClusterHeadPodsAssociationOptions and RayClusterWorkerPodsAssociationOptions (#2023) (#2035) |
| 7440579e | [Cherry-pick][Test][RayCluster] Test redis cleanup job in the e2e compatibility test (#2026) (#2034) |
| 9c4768ff | [Cherry-pick][Bug] Reconciler error when changing the value of nameOverride in values.yaml of helm installation for Ray Cluster (#1966) (#2033) |
| 36076e51 | [Cherry-pick][Telemetry] KubeRay version and CRD (#2024) (#2032) |
| c8150767 | [Cherry-pick] Add seccompProfile.type=RuntimeDefault to kuberay-operator. (#1955) (#2031) |
| 780c3548 | ray-operator: parameterize Test_ShouldDeletePod (#2000) (#2030) |
| d2a65c0c | [release v1.1.0-rc.1] Update tags and versions (#2022) |
| 58a4e2c6 | [Cherry-pick] Bump google.golang.org/protobuf from 1.32.0 to 1.33.0 in /experimental (#1992) (#2021) |

## Key Features

### Production Readiness
- **Autoscaling**: Automatic worker pod scaling based on Ray autoscaler decisions
- **Fault Tolerance**: GCS fault tolerance with external Redis support
- **Zero Downtime**: RayService supports zero-downtime upgrades for serving workloads
- **High Availability**: RayService provides HA through active-standby cluster management

### OpenShift Integration
- **Security Context Constraints**: Custom SCC for Ray workloads (UID 1000)
- **Routes**: Native OpenShift Route support for external access
- **Restricted Pod Security**: Compatible with OpenShift restricted SCC

### Observability
- **Metrics**: Prometheus metrics from operator and Ray clusters
- **Dashboard**: Ray dashboard UI for cluster monitoring and job management
- **Events**: Kubernetes events for lifecycle operations

### Extensibility
- **Batch Schedulers**: Plugin support for Volcano gang scheduling
- **Custom Images**: Support for custom Ray container images
- **Volume Mounts**: Flexible volume configuration for data access
- **Init Containers**: Customizable init containers for setup tasks

## Limitations and Considerations

1. **Security**: Default Ray services have no authentication; network policies or service mesh recommended for production
2. **Resource Management**: Ray clusters should be sized to fit Kubernetes nodes efficiently
3. **Storage**: Ephemeral storage by default; external storage required for persistence
4. **Networking**: Ray Protocol communication requires network connectivity between pods
5. **Scaling**: Large-scale deployments (500+ pods) may require operator memory tuning
6. **Multi-tenancy**: RayCluster resources are namespaced; RBAC recommended for isolation

## Performance Characteristics

- **Operator Reconciliation**: Default 300-second requeue interval
- **API Server Response Time**: Depends on Kubernetes API latency
- **Ray Cluster Startup**: Typically 30-60 seconds for small clusters
- **Autoscaling Response**: Ray autoscaler evaluates every 10 seconds (default)
- **Job Submission Latency**: Depends on dashboard API readiness (10-20 seconds initial delay)
