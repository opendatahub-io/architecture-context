# Component: Ray Operator (KubeRay)

## Metadata
- **Repository**: https://github.com/opendatahub-io/kuberay.git
- **Version**: 1.4.4
- **Distribution**: ODH and RHOAI (both)
- **Languages**: Go, YAML
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes operator that manages the lifecycle of Ray clusters for distributed computing and machine learning workloads.

**Detailed**: KubeRay is a Kubernetes operator that simplifies the deployment and management of Ray applications on Kubernetes. Ray is a distributed computing framework used for parallel processing, distributed training, hyperparameter tuning, reinforcement learning, and model serving. The operator provides three core custom resources: RayCluster for managing Ray cluster lifecycles including autoscaling and fault tolerance, RayJob for automatically creating clusters and submitting batch jobs, and RayService for zero-downtime serving deployments with high availability. KubeRay handles complex orchestration tasks like cluster creation/deletion, autoscaling worker nodes based on workload demands, ensuring fault tolerance with GCS (Global Control Store) persistence, and managing the Ray head and worker pod lifecycle. It integrates with the Kubernetes ecosystem including Prometheus for monitoring, Volcano/Kueue for job queuing, and service mesh for security.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Ray Operator | Go Controller | Reconciles RayCluster, RayJob, and RayService custom resources |
| RayCluster Controller | Reconciler | Manages Ray cluster lifecycle, head/worker pods, autoscaling |
| RayJob Controller | Reconciler | Creates RayCluster and submits batch jobs, handles cleanup |
| RayService Controller | Reconciler | Manages zero-downtime serving deployments with HA |
| Authentication Controller | Reconciler | Manages ServiceAccounts and RBAC for Ray clusters |
| NetworkPolicy Controller | Reconciler | Creates NetworkPolicies for Ray cluster communication |
| mTLS Controller | Reconciler | Manages mutual TLS certificates for secure Ray cluster communication |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| ray.io | v1 | RayCluster | Namespaced | Define and manage a Ray cluster with head and worker nodes |
| ray.io | v1 | RayJob | Namespaced | Submit batch jobs to a Ray cluster (creates cluster automatically) |
| ray.io | v1 | RayService | Namespaced | Deploy Ray Serve applications with zero-downtime upgrades and HA |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint for operator health |
| / | GET, POST | 8265/TCP | HTTP | TLS 1.2+ (optional) | mTLS (optional) | Ray Dashboard web interface |
| /api | GET, POST | 8265/TCP | HTTP | TLS 1.2+ (optional) | mTLS (optional) | Ray Dashboard API |
| /api/serve | GET, POST | 8000/TCP | HTTP | TLS 1.2+ (optional) | mTLS (optional) | Ray Serve application endpoints |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| RayletService | 6379/TCP | gRPC | mTLS (optional) | cert | Inter-node communication (raylet to raylet) |
| GCS | 6379/TCP | gRPC | mTLS (optional) | cert | Global Control Store for cluster metadata |
| ObjectManager | 2384/TCP | gRPC | mTLS (optional) | cert | Object store communication between nodes |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Ray | 2.x | Yes | Distributed computing runtime deployed in pods |
| Redis | 6.x+ | No | External storage for GCS fault tolerance (optional) |
| Prometheus | 2.x | No | Metrics collection and monitoring |
| Kueue | 0.5+ | No | Job queuing and resource management integration |
| Volcano | 1.8+ | No | Batch scheduling and job queuing integration |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | UI Integration | Provides UI for creating and managing Ray clusters |
| Notebooks | Cluster Access | Submit jobs to Ray clusters from workbench notebooks |
| Data Science Pipelines | Job Submission | Execute distributed training as pipeline steps |
| Model Registry | API | Register models trained on Ray clusters |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| ray-head-svc | ClusterIP | 8265/TCP | 8265 | HTTP | TLS 1.2+ (optional) | mTLS (optional) | Internal |
| ray-head-svc | ClusterIP | 6379/TCP | 6379 | gRPC | mTLS (optional) | cert | Internal |
| ray-head-svc | ClusterIP | 8000/TCP | 8000 | HTTP | TLS 1.2+ (optional) | mTLS (optional) | Internal |
| ray-head-svc | ClusterIP | 10001/TCP | 10001 | gRPC | mTLS (optional) | cert | Internal |
| ray-operator-metrics | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| ray-dashboard-ingress | OpenShift Route | *.apps.cluster | 443/TCP | HTTPS | TLS 1.2+ | Edge Termination | External |
| ray-serve-ingress | OpenShift Route | *.apps.cluster | 443/TCP | HTTPS | TLS 1.2+ | Edge Termination | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| S3-compatible storage | 443/TCP | HTTPS | TLS 1.2+ | AWS credentials | Access training datasets and checkpoints |
| Redis (external) | 6379/TCP | TCP | TLS 1.2+ (optional) | Password | GCS fault tolerance storage |
| PyPI / pip index | 443/TCP | HTTPS | TLS 1.2+ | None | Install Python dependencies in Ray runtime |
| Container registry | 443/TCP | HTTPS | TLS 1.2+ | Token | Pull Ray container images |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kuberay-operator | "" | pods, services, configmaps, serviceaccounts, events | create, delete, get, list, patch, update, watch |
| kuberay-operator | "" | secrets | delete, get, list, watch |
| kuberay-operator | apps | deployments | get, list, patch, update, watch |
| kuberay-operator | batch | jobs | create, delete, get, list, patch, update, watch |
| kuberay-operator | ray.io | rayclusters, rayjobs, rayservices | create, delete, get, list, patch, update, watch |
| kuberay-operator | networking.k8s.io | networkpolicies, ingresses | create, delete, get, list, patch, update, watch |
| kuberay-operator | route.openshift.io | routes | create, delete, get, list, patch, update, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kuberay-operator | opendatahub | kuberay-operator | kuberay-operator |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| ray-mtls-ca-secret | kubernetes.io/tls | CA certificate for mTLS between Ray nodes | KubeRay Operator | Yes |
| ray-mtls-cert-secret | kubernetes.io/tls | mTLS certificates for Ray head and worker nodes | cert-manager / KubeRay | Yes |
| ray-redis-password | Opaque | Redis password for external GCS storage | User-provided | No |
| aws-s3-credentials | Opaque | S3 access credentials for data and checkpoints | User-provided | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| Ray Dashboard | GET, POST | mTLS (optional) | Ray Head Service | Mutual TLS client certificates |
| Ray Serve API | GET, POST | Bearer Token (optional) | Ray Serve | Token-based authentication |
| Inter-node gRPC | gRPC | mTLS (optional) | GCS / Raylet | Mutual TLS with operator-managed certificates |
| Kubernetes API | All | ServiceAccount | Kubernetes | RBAC-based pod permissions |

## Data Flows

### Flow 1: RayCluster Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Dashboard | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | KubeRay Operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | KubeRay Operator | Ray Head Pod (create) | N/A | N/A | N/A | N/A |
| 4 | Ray Head Pod | GCS (Redis) | 6379/TCP | TCP | TLS 1.2+ (optional) | Password |
| 5 | KubeRay Operator | Ray Worker Pods (create) | N/A | N/A | N/A | N/A |
| 6 | Ray Worker Pods | Ray Head Service | 6379/TCP | gRPC | mTLS (optional) | cert |

### Flow 2: Job Submission and Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client (Notebook/CLI) | Ray Dashboard API | 8265/TCP | HTTP | TLS 1.2+ (optional) | mTLS (optional) |
| 2 | Ray Head | Ray Worker Nodes | 6379/TCP | gRPC | mTLS (optional) | cert |
| 3 | Ray Workers | S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM |
| 4 | Ray Workers | Object Store | 2384/TCP | gRPC | mTLS (optional) | cert |
| 5 | Ray Head | Client | 8265/TCP | HTTP | TLS 1.2+ (optional) | mTLS (optional) |

### Flow 3: Autoscaling

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Ray Autoscaler | Ray GCS | 6379/TCP | gRPC | mTLS (optional) | cert |
| 2 | Ray Autoscaler | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | KubeRay Operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | KubeRay Operator | New Worker Pods (create) | N/A | N/A | N/A | N/A |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Manage Ray cluster resources (Pods, Services, etc.) |
| Prometheus | Metrics scraping | 8080/TCP | HTTP | None | Collect operator and Ray cluster metrics |
| Redis (external) | TCP | 6379/TCP | TCP | TLS 1.2+ (optional) | GCS fault tolerance and persistence |
| S3 Storage | HTTP API | 443/TCP | HTTPS | TLS 1.2+ | Store checkpoints, datasets, and training artifacts |
| Kueue | CRD Integration | 6443/TCP | HTTPS | TLS 1.2+ | Job queuing and resource quota management |
| ODH Dashboard | REST API | 8080/TCP | HTTP | None | UI for cluster management |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 1.4.4 | 2025-01 | - Update Tekton and params.env to v1.4.4<br>- Fix status subresource handling in fake client for proper updates<br>- Eliminate ServiceAccount creation race condition with AuthenticationReady condition<br>- Remove route/ingress when enableIngress is false<br>- Add necessary PR protection for midstream stable branch |
| 1.4.3 | 2024-12 | - Release version 1.4.3<br>- Set enableIngress to false by default<br>- Update component names<br>- Move most testing to post-merge on larger runners<br>- Add pipelineruns for ODH CI builds |
