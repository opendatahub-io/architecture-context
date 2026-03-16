# Component: KubeRay Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kuberay.git
- **Version**: c61e5a05 (rhoai-2.17 branch)
- **Distribution**: RHOAI
- **Languages**: Go, Protocol Buffers (gRPC)
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: KubeRay is a Kubernetes operator that simplifies deployment and management of Ray applications on Kubernetes.

**Detailed**: KubeRay provides a comprehensive operator framework for running Ray—a distributed computing framework for machine learning and AI workloads—on Kubernetes. It offers three core Custom Resource Definitions (RayCluster, RayJob, RayService) that manage the full lifecycle of Ray workloads including cluster creation/deletion, autoscaling, fault tolerance, job submission, and service deployment. The operator automatically manages Ray cluster components (head and worker nodes), handles networking between components, and provides integration with Kubernetes-native features like ingress, monitoring, and RBAC. An optional API server component provides simplified REST/gRPC APIs for programmatic cluster management. This component is essential for RHOAI users running distributed ML training, batch inference, and model serving workloads at scale.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kuberay-operator | Kubernetes Operator (Deployment) | Watches and reconciles RayCluster, RayJob, RayService CRDs; manages Ray cluster lifecycle |
| kuberay-apiserver | gRPC/HTTP API Server (optional) | Provides simplified REST/gRPC APIs for managing Ray resources programmatically |
| Ray Head Node | Pod (managed by operator) | Ray cluster control plane, runs GCS (Global Control Service), dashboard, and client server |
| Ray Worker Nodes | Pods (managed by operator) | Ray cluster compute nodes that execute distributed tasks and actors |
| Ray Autoscaler | Sidecar Container | Monitors cluster load and scales worker nodes up/down based on resource demands |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| ray.io | v1 | RayCluster | Namespaced | Manages Ray cluster lifecycle with head and worker node groups, autoscaling, and fault tolerance |
| ray.io | v1 | RayJob | Namespaced | Manages batch job submission to Ray clusters; automatically creates/deletes clusters for jobs |
| ray.io | v1 | RayService | Namespaced | Manages Ray Serve deployments with zero-downtime upgrades and high availability |

### HTTP Endpoints

#### KubeRay Operator

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for operator health and performance monitoring |
| /healthz | GET | 8080/TCP | HTTP | None | None | Liveness/readiness probe endpoint for operator health checks |

#### KubeRay API Server (Optional Component)

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /apis/v1/namespaces/{namespace}/clusters | POST, GET | 8888/TCP | HTTP | None | Bearer Token (optional) | Create and list Ray clusters via REST API |
| /apis/v1/namespaces/{namespace}/clusters/{name} | GET, DELETE | 8888/TCP | HTTP | None | Bearer Token (optional) | Get and delete specific Ray cluster |
| /apis/v1/clusters | GET | 8888/TCP | HTTP | None | Bearer Token (optional) | List all Ray clusters across namespaces |
| /apis/v1/namespaces/{namespace}/jobs | POST, GET | 8888/TCP | HTTP | None | Bearer Token (optional) | Submit and list Ray jobs |
| /apis/v1/namespaces/{namespace}/services | POST, GET | 8888/TCP | HTTP | None | Bearer Token (optional) | Create and list Ray services |
| /metrics | GET | 8888/TCP | HTTP | None | None | Prometheus metrics for API server |
| /healthz | GET | 8888/TCP | HTTP | None | None | Health check endpoint |
| /swagger/ | GET | 8888/TCP | HTTP | None | None | OpenAPI/Swagger documentation |

#### Ray Head Node (Created by Operator)

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| / | N/A | 6379/TCP | Ray Protocol | None | None | Ray GCS (Global Control Service) for cluster coordination |
| / | GET | 8265/TCP | HTTP | None | None | Ray Dashboard UI for cluster monitoring and job management |
| / | N/A | 10001/TCP | Ray Protocol | None | None | Ray Client server for remote job submission |

### gRPC Services

#### KubeRay API Server

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ClusterService | 8887/TCP | gRPC/HTTP2 | None | Bearer Token (optional) | Create, get, list, delete Ray clusters |
| ComputeTemplateService | 8887/TCP | gRPC/HTTP2 | None | Bearer Token (optional) | Manage compute templates for cluster configuration |
| RayJobService | 8887/TCP | gRPC/HTTP2 | None | Bearer Token (optional) | Submit and manage Ray batch jobs |
| RayJobSubmissionService | 8887/TCP | gRPC/HTTP2 | None | Bearer Token (optional) | Ray job submission API compatible with Ray client |
| RayServeService | 8887/TCP | gRPC/HTTP2 | None | Bearer Token (optional) | Manage Ray Serve deployments |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.19+ | Yes | Container orchestration platform; operator requires apiextensions, apps, batch, RBAC APIs |
| Ray | 2.0+ | Yes | Distributed computing framework; container images deployed by operator |
| Prometheus | N/A | No | Metrics collection from operator and Ray clusters |
| OpenShift Routes | N/A | No | External access to Ray dashboard and services (OpenShift only) |
| Ingress Controller | N/A | No | External access to Ray services (generic Kubernetes) |
| cert-manager | N/A | No | TLS certificate management for webhooks (if webhooks enabled) |
| Volcano/Yunikorn | N/A | No | Gang scheduling and batch scheduling for Ray pods |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Model Mesh | Ray Serve Integration | Ray Serve can be used as inference runtime for serving models |
| Notebook Controller | Job Submission | Submit Ray jobs from Jupyter notebooks via Ray client |
| Dashboard | Monitoring Integration | Display Ray cluster status and metrics in ODH dashboard |

## Network Architecture

### Services

#### KubeRay Operator Service

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kuberay-operator | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (Prometheus scraping) |

#### Ray Head Service (Created per RayCluster)

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {cluster-name}-head-svc | ClusterIP | 6379/TCP | 6379 | TCP | None | None | Internal (Ray GCS) |
| {cluster-name}-head-svc | ClusterIP | 8265/TCP | 8265 | HTTP | None | None | Internal (Dashboard) |
| {cluster-name}-head-svc | ClusterIP | 10001/TCP | 10001 | TCP | None | None | Internal (Client server) |
| {cluster-name}-head-svc | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (Metrics) |

#### KubeRay API Server Service (Optional)

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kuberay-apiserver | ClusterIP | 8888/TCP | 8888 | HTTP | None | Bearer Token | Internal |
| kuberay-apiserver | ClusterIP | 8887/TCP | 8887 | TCP | None | Bearer Token | Internal (gRPC) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {cluster-name}-ingress | Kubernetes Ingress | configurable | 8265/TCP | HTTP/HTTPS | TLS 1.2+ (optional) | SIMPLE | External (Dashboard) |
| {cluster-name}-ingress | Kubernetes Ingress | configurable | 10001/TCP | TCP/TLS | TLS 1.2+ (optional) | SIMPLE | External (Client) |
| {cluster-name}-route | OpenShift Route | auto-generated | 8265/TCP | HTTP/HTTPS | TLS 1.2+ (optional) | edge/passthrough | External (Dashboard, OpenShift only) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch/reconcile Ray CRDs and managed resources |
| Container Registries | 443/TCP | HTTPS | TLS 1.2+ | Pull Secrets | Pull Ray container images for head and worker pods |
| S3/Object Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Access Keys | Ray workloads accessing training data and model artifacts |
| External Redis (optional) | 6379/TCP | TCP | TLS (optional) | Password | External Redis for Ray GCS backend |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kuberay-operator | "" (core) | pods, pods/status, pods/proxy | create, delete, deletecollection, get, list, patch, update, watch |
| kuberay-operator | "" (core) | services, services/status, services/proxy | create, delete, get, list, patch, update, watch |
| kuberay-operator | "" (core) | serviceaccounts | create, delete, get, list, watch |
| kuberay-operator | "" (core) | endpoints | get, list, watch |
| kuberay-operator | "" (core) | events | create, delete, get, list, patch, update, watch |
| kuberay-operator | batch | jobs | create, delete, get, list, patch, update, watch |
| kuberay-operator | ray.io | rayclusters, rayclusters/status, rayclusters/finalizers | create, delete, get, list, patch, update, watch |
| kuberay-operator | ray.io | rayjobs, rayjobs/status, rayjobs/finalizers | create, delete, get, list, patch, update, watch |
| kuberay-operator | ray.io | rayservices, rayservices/status, rayservices/finalizers | create, delete, get, list, patch, update, watch |
| kuberay-operator | rbac.authorization.k8s.io | roles, rolebindings | create, delete, get, list, update, watch |
| kuberay-operator | networking.k8s.io | ingresses, ingressclasses | create, delete, get, list, patch, update, watch |
| kuberay-operator | extensions | ingresses | create, delete, get, list, patch, update, watch |
| kuberay-operator | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| kuberay-operator | coordination.k8s.io | leases | create, get, list, update |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kuberay-operator | opendatahub (configurable) | kuberay-operator (ClusterRole) | kuberay-operator |
| kuberay-operator-leader-election | opendatahub (configurable) | kuberay-operator-leader-election (Role) | kuberay-operator |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {cluster-name}-{worker-group}-token | kubernetes.io/service-account-token | ServiceAccount token for Ray worker pods | Kubernetes | Yes |
| ray-image-pull-secret | kubernetes.io/dockerconfigjson | Pull secrets for Ray container images from private registries | Admin/CI | No |
| webhook-server-cert | kubernetes.io/tls | TLS certificate for validating/mutating webhooks (if enabled) | cert-manager | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| Kubernetes API (CRD operations) | GET, POST, PATCH, DELETE | ServiceAccount Token (kuberay-operator) | kube-apiserver RBAC | ClusterRole: kuberay-operator |
| KubeRay API Server (optional) | All gRPC/HTTP | Bearer Token (optional) | API Server Interceptor | Configurable per deployment |
| Ray Dashboard | GET, POST | None (default) | Application | Should be behind ingress with authentication |
| Ray Client API | RPC | None (default) | Application | Should use network policies or mTLS for security |
| Operator Metrics (/metrics) | GET | None | Application | Internal only via ClusterIP |

### Security Context Constraints (OpenShift)

| SCC Name | RunAsUser | SELinux | Capabilities | Privilege Escalation | Applied To |
|----------|-----------|---------|--------------|---------------------|------------|
| run-as-ray-user | MustRunAs (UID 1000) | MustRunAs | Drop ALL | false | kuberay-operator ServiceAccount |
| anyuid (Ray pods) | RunAsAny | MustRunAs | Drop ALL | false | Ray head/worker pods (default) |

### Pod Security

- **Operator Pod**: runAsNonRoot: true, allowPrivilegeEscalation: false, user: 65532:65532
- **Ray Head/Worker Pods**: Configurable via RayCluster spec; default UID 1000, no privilege escalation
- **Seccomp**: runtime/default (OpenShift SCC)
- **Capabilities**: All dropped by default

## Data Flows

### Flow 1: RayCluster Creation and Lifecycle Management

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | kubeconfig credentials |
| 2 | Kubernetes API | kuberay-operator | N/A | Watch Stream | TLS 1.2+ | ServiceAccount Token |
| 3 | kuberay-operator | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Kubernetes API | kubelet | 10250/TCP | HTTPS | TLS 1.2+ | Node certificate |
| 5 | kubelet | Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Image pull secret |
| 6 | Ray Worker Pod | Ray Head Pod (GCS) | 6379/TCP | TCP | None | None |

### Flow 2: Ray Job Submission via Client

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Notebook | Ray Head Service | 10001/TCP | TCP (Ray Protocol) | None (default) | None (default) |
| 2 | Ray Head | Ray GCS | 6379/TCP | TCP | None | None |
| 3 | Ray Head | Ray Worker(s) | Dynamic | TCP | None | None |
| 4 | Ray Worker | Object Storage (S3) | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Access Key |

### Flow 3: Monitoring and Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | kuberay-operator | 8080/TCP | HTTP | None | None |
| 2 | Prometheus | Ray Head Pod | 8080/TCP | HTTP | None | None |
| 3 | User | Ray Dashboard Service | 8265/TCP | HTTP | None (or TLS via Ingress) | None (or via Ingress) |
| 4 | Ingress Controller | Ray Head Service | 8265/TCP | HTTP | None | None |

### Flow 4: KubeRay API Server (Optional)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | kuberay-apiserver | 8888/TCP | HTTP | None | Bearer Token (optional) |
| 2 | kuberay-apiserver | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | External Client | kuberay-apiserver | 8887/TCP | gRPC/HTTP2 | None | Bearer Token (optional) |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 443/TCP | HTTPS | TLS 1.2+ | Watch/reconcile CRDs, manage pods, services, jobs |
| Prometheus | HTTP Metrics Scraping | 8080/TCP | HTTP | None | Collect operator and Ray cluster metrics |
| Ingress Controller | HTTP Proxy | 8265/TCP, 10001/TCP | HTTP/TCP | TLS 1.2+ (termination) | External access to Ray dashboard and client API |
| OpenShift Router | HTTP Proxy | 8265/TCP | HTTP/HTTPS | TLS 1.2+ (edge/passthrough) | External access to Ray services (OpenShift only) |
| Object Storage (S3/GCS) | S3 API | 443/TCP | HTTPS | TLS 1.2+ | Ray workloads read/write training data and models |
| Container Registry | OCI Registry API | 443/TCP | HTTPS | TLS 1.2+ | Pull Ray head/worker container images |
| External Redis (optional) | Redis Protocol | 6379/TCP | TCP/TLS | TLS (optional) | Alternative Ray GCS backend for HA |
| cert-manager (optional) | Certificate CRDs | N/A | N/A | N/A | Provision TLS certificates for webhooks |
| Volcano/Yunikorn (optional) | Batch Scheduler API | N/A | N/A | N/A | Gang scheduling for Ray pods |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| c61e5a05 | 2025-03-05 | - Update Konflux references<br>- Update UBI8 base images to latest digests<br>- Registry and build configuration updates |
| b672e292 | 2025-03-05 | - Update Konflux references for image builds |
| 17ebc12f | 2025-03-04 | - Update registry.access.redhat.com/ubi8/go-toolset:1.22 digest<br>- Security and stability improvements |
| f8ec1243 | 2025-03-03 | - Update Konflux references<br>- CI/CD pipeline improvements |
| 2d1cc2ce | 2025-03-02 | - Update Konflux references to b9cb1e1<br>- Build and release automation updates |
| 664490be | 2025-02-28 | - Update Konflux references to 944e769<br>- Image build and security updates |
| 4c84e002 | 2025-02-27 | - Update Konflux references<br>- Container build improvements |
| 88faef75 | 2025-02-27 | - Update Konflux references to 8b6f22f<br>- Build system enhancements |
| a2d8631a | 2025-02-26 | - Update Konflux references<br>- RHOAI 2.17 release preparation |
| c2ef5c34 | 2025-02-26 | - Update UBI8 go-toolset base image<br>- Security patches and dependency updates |
| 1210ad17 | 2025-02-25 | - Update UBI8 minimal base image digest<br>- Runtime security improvements |
| 27d55305 | 2025-02-24 | - Update Konflux references to 5bc6129<br>- CI/CD and build optimizations |

## Deployment Architecture

### Operator Deployment

The KubeRay operator is deployed as a single-replica Deployment in the `opendatahub` namespace with a Recreate strategy to ensure only one operator instance is active. The operator container runs as non-root user 65532 with strict security context (no privilege escalation, all capabilities dropped). It exposes port 8080 for Prometheus metrics and health checks.

### Resource Topology

```
Namespace: opendatahub
├── Deployment: kuberay-operator (1 replica)
│   └── Pod: kuberay-operator-xxx
│       └── Container: kuberay-operator (image: odh-kuberay-operator-controller-container)
├── Service: kuberay-operator (ClusterIP, port 8080)
├── ServiceAccount: kuberay-operator
├── ClusterRole: kuberay-operator
└── ClusterRoleBinding: kuberay-operator

User Namespace: {user-namespace}
├── RayCluster: {cluster-name} (CRD)
│   ├── Pod: {cluster-name}-head-xxx (Ray head node)
│   │   ├── Container: ray-head (GCS, Dashboard, Client)
│   │   └── Container: autoscaler (optional)
│   ├── Pods: {cluster-name}-worker-{group}-xxx (Ray workers)
│   │   └── Container: ray-worker
│   ├── Service: {cluster-name}-head-svc (ClusterIP)
│   ├── ServiceAccount: {cluster-name}-ray-worker
│   └── Role/RoleBinding: {cluster-name}-* (managed by operator)
├── RayJob: {job-name} (CRD, optional)
└── RayService: {service-name} (CRD, optional)
```

### Build and Deployment (Konflux)

The operator is built using **Dockerfile.konflux** via the Konflux build system:
- Base image: UBI8 go-toolset 1.22 (builder), UBI8 minimal (runtime)
- Build tags: `strictfipsruntime` for FIPS compliance
- CGO enabled for strict FIPS mode
- Multi-stage build for minimal runtime image
- Runs as UID 65532 (non-root)
- Component label: `odh-kuberay-operator-controller-container`

### Configuration

Deployment configuration is managed via kustomize:
- **Base**: `ray-operator/config/default` (generic Kubernetes)
- **OpenShift overlay**: `ray-operator/config/openshift` (adds SCC, namespace, image overrides)
- **ConfigMap**: `ray-config` with deployment parameters (namespace, image)
- **Patches**: Namespace removal, image replacement for RHOAI builds

## Operational Notes

### Autoscaling

Ray clusters support horizontal autoscaling via the Ray Autoscaler component:
- Monitors cluster resource utilization and pending tasks
- Scales worker groups between `minReplicas` and `maxReplicas`
- Configurable via `autoscalerOptions` in RayCluster spec
- Supports CPU, memory, GPU, and custom resource scaling

### High Availability

- **Operator**: Single replica with leader election support (disabled by default)
- **Ray GCS**: Single instance per cluster (can use external Redis for HA)
- **RayService**: Supports zero-downtime upgrades with blue-green deployment strategy
- **Worker Fault Tolerance**: Ray automatically retries tasks on worker failure

### Monitoring

- **Operator Metrics**: Exposed on `/metrics` endpoint (port 8080)
- **Ray Metrics**: Prometheus-compatible metrics from Ray head/workers
- **Dashboard**: Ray Dashboard UI on port 8265 for visual monitoring
- **Logs**: Operator logs to stdout (JSON format), Ray logs to `/tmp/ray` in pods

### Security Recommendations

1. **Network Policies**: Implement NetworkPolicies to restrict Ray cluster communication
2. **Ingress Authentication**: Secure Ray Dashboard with OAuth/OIDC proxy (e.g., oauth2-proxy)
3. **mTLS**: Enable mutual TLS for Ray cluster internal communication in production
4. **Image Signing**: Verify Ray container image signatures before deployment
5. **Resource Limits**: Set appropriate CPU/memory limits to prevent resource exhaustion
6. **RBAC**: Restrict user permissions to create RayCluster CRDs in multi-tenant environments

### Troubleshooting

- **Operator Logs**: `kubectl logs -n opendatahub deployment/kuberay-operator`
- **Ray Head Logs**: `kubectl logs -n {namespace} {cluster-name}-head-xxx -c ray-head`
- **CRD Status**: `kubectl describe raycluster -n {namespace} {cluster-name}`
- **Events**: `kubectl get events -n {namespace} --sort-by='.lastTimestamp'`
- **Dashboard Access**: Port-forward to Ray head: `kubectl port-forward -n {namespace} svc/{cluster-name}-head-svc 8265:8265`
