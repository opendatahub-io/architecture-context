# Component: KubeRay

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kuberay
- **Version**: e603d04d (rhoai-2.8 branch)
- **Distribution**: RHOAI
- **Languages**: Go, Protocol Buffers (gRPC)
- **Deployment Type**: Kubernetes Operator + Optional API Server

## Purpose
**Short**: KubeRay is a Kubernetes operator that simplifies deployment and management of Ray applications on Kubernetes.

**Detailed**: KubeRay provides a comprehensive platform for running Ray (distributed computing framework) workloads on Kubernetes. It consists of a core operator that manages three custom resource types (RayCluster, RayJob, RayService) and an optional API server that provides simplified gRPC/HTTP APIs for resource management. The operator handles the complete lifecycle of Ray clusters including creation, deletion, autoscaling, and fault tolerance. RayCluster manages Ray cluster infrastructure, RayJob automatically creates clusters and submits jobs, and RayService provides zero-downtime upgrades and high availability for serving workloads. The component integrates with OpenShift through SecurityContextConstraints and Routes, and is built via Konflux for RHOAI distribution.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| KubeRay Operator | Kubernetes Operator | Manages lifecycle of RayCluster, RayJob, and RayService custom resources |
| KubeRay APIServer | gRPC/HTTP API Server | Optional component providing simplified APIs for managing KubeRay resources |
| RayCluster Controller | Reconciliation Controller | Manages Ray cluster pods, services, autoscaling, and fault tolerance |
| RayJob Controller | Reconciliation Controller | Manages batch job execution on Ray clusters with automatic lifecycle management |
| RayService Controller | Reconciliation Controller | Manages Ray Serve deployments with zero-downtime upgrades and high availability |
| CLI | Command-line Tool | Provides kubectl-style interface for managing KubeRay resources |
| Python Client | Python SDK | Python library for programmatic management of Ray clusters |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| ray.io | v1 | RayCluster | Namespaced | Defines Ray cluster specification including head and worker groups, autoscaling, and resource requirements |
| ray.io | v1 | RayJob | Namespaced | Defines batch jobs that run on Ray clusters with automatic cluster creation and cleanup |
| ray.io | v1 | RayService | Namespaced | Defines Ray Serve deployments with zero-downtime updates and multi-cluster serving |
| ray.io | v1alpha1 | RayCluster | Namespaced | Legacy v1alpha1 API for RayCluster (deprecated) |
| ray.io | v1alpha1 | RayJob | Namespaced | Legacy v1alpha1 API for RayJob (deprecated) |
| ray.io | v1alpha1 | RayService | Namespaced | Legacy v1alpha1 API for RayService (deprecated) |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint for operator monitoring |
| /apis/v1/namespaces/{namespace}/clusters | POST | 8888/TCP | HTTP | None | Bearer Token | Create Ray cluster via APIServer |
| /apis/v1/namespaces/{namespace}/clusters/{name} | GET | 8888/TCP | HTTP | None | Bearer Token | Get Ray cluster details via APIServer |
| /apis/v1/namespaces/{namespace}/clusters | GET | 8888/TCP | HTTP | None | Bearer Token | List Ray clusters in namespace via APIServer |
| /apis/v1/clusters | GET | 8888/TCP | HTTP | None | Bearer Token | List all Ray clusters via APIServer |
| /apis/v1/namespaces/{namespace}/clusters/{name} | DELETE | 8888/TCP | HTTP | None | Bearer Token | Delete Ray cluster via APIServer |
| /apis/v1/namespaces/{namespace}/jobs | POST | 8888/TCP | HTTP | None | Bearer Token | Create Ray job via APIServer |
| /apis/v1/namespaces/{namespace}/jobs/{name} | GET | 8888/TCP | HTTP | None | Bearer Token | Get Ray job details via APIServer |
| /apis/v1/namespaces/{namespace}/services | POST | 8888/TCP | HTTP | None | Bearer Token | Create Ray service via APIServer |
| /apis/v1/namespaces/{namespace}/services/{name} | GET | 8888/TCP | HTTP | None | Bearer Token | Get Ray service details via APIServer |
| /healthz | GET | 8888/TCP | HTTP | None | None | APIServer health check endpoint |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ClusterService | 8887/TCP | gRPC | None | Bearer Token | Manage Ray clusters (CRUD operations) |
| RayJobService | 8887/TCP | gRPC | None | Bearer Token | Manage Ray jobs (CRUD operations) |
| RayServeService | 8887/TCP | gRPC | None | Bearer Token | Manage Ray services (CRUD operations) |
| ComputeTemplateService | 8887/TCP | gRPC | None | Bearer Token | Manage compute templates for cluster configuration |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.19+ | Yes | Platform for running operator and Ray workloads |
| Ray | 2.0.0+ | Yes | Distributed computing framework managed by operator |
| Prometheus | Any | No | Metrics collection from operator and Ray clusters |
| Grafana | Any | No | Visualization of Ray cluster metrics |
| Volcano | Any | No | Optional batch scheduler integration for gang scheduling |
| Istio/Ingress Controller | Any | No | Optional for exposing Ray dashboard and services externally |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| OpenShift Routes | OpenShift API | Expose Ray dashboard and services on OpenShift |
| cert-manager | Certificate API | Optional TLS certificate management for Ray services |
| Monitoring Stack | ServiceMonitor CRD | Integration with ODH monitoring for Ray metrics |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kuberay-operator | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |
| kuberay-apiserver | NodePort | 8888/TCP | 8888 | HTTP | None | Bearer Token | External |
| kuberay-apiserver | NodePort | 8887/TCP | 8887 | gRPC | None | Bearer Token | External |
| {raycluster-name}-head-svc | ClusterIP | 6379/TCP | 6379 | TCP | None | Redis Password | Internal |
| {raycluster-name}-head-svc | ClusterIP | 8265/TCP | 8265 | HTTP | None | None | Internal |
| {raycluster-name}-head-svc | ClusterIP | 10001/TCP | 10001 | TCP | None | None | Internal |
| {raycluster-name}-head-svc | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |
| {raycluster-name}-head-svc | ClusterIP | 8000/TCP | 8000 | HTTP | None | None | Internal |
| {raycluster-name}-head-svc | ClusterIP | 52365/TCP | 52365 | HTTP | None | None | Internal |
| {rayservice-name}-serve-svc | ClusterIP | 8000/TCP | 8000 | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {raycluster-name}-ingress | Kubernetes Ingress | Custom | 8265/TCP | HTTP | TLS 1.2+ | SIMPLE | External |
| {raycluster-name}-route | OpenShift Route | Auto-generated | 8265/TCP | HTTPS | TLS 1.2+ | edge | External |
| {rayservice-name}-ingress | Kubernetes Ingress | Custom | 8000/TCP | HTTP | TLS 1.2+ | SIMPLE | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Manage Kubernetes resources (Pods, Services, Ingresses) |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret | Pull Ray container images |
| External Storage (S3/GCS) | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/GCP SA | Ray GCS fault tolerance and object storage |
| External Redis | 6379/TCP | TCP | Optional TLS | Redis Password | External Redis for Ray GCS fault tolerance |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kuberay-operator | batch | jobs | create, delete, get, list, patch, update, watch |
| kuberay-operator | coordination.k8s.io | leases | create, get, list, update |
| kuberay-operator | "" | events | create, delete, get, list, patch, update, watch |
| kuberay-operator | "" | pods | create, delete, get, list, patch, update, watch |
| kuberay-operator | "" | pods/status | create, delete, get, list, patch, update, watch |
| kuberay-operator | "" | serviceaccounts | create, delete, get, list, watch |
| kuberay-operator | "" | services | create, delete, get, list, patch, update, watch |
| kuberay-operator | "" | services/status | get, patch, update |
| kuberay-operator | extensions, networking.k8s.io | ingresses | create, delete, get, list, patch, update, watch |
| kuberay-operator | networking.k8s.io | ingressclasses | get, list, watch |
| kuberay-operator | ray.io | rayclusters, rayclusters/finalizers, rayclusters/status | create, delete, get, list, patch, update, watch |
| kuberay-operator | ray.io | rayjobs, rayjobs/finalizers, rayjobs/status | create, delete, get, list, patch, update, watch |
| kuberay-operator | ray.io | rayservices, rayservices/finalizers, rayservices/status | create, delete, get, list, patch, update, watch |
| kuberay-operator | rbac.authorization.k8s.io | roles, rolebindings | create, delete, get, list, update, watch |
| kuberay-operator | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| kuberay-apiserver | ray.io | rayclusters, rayjobs, rayservices | create, delete, get, list, patch, update, watch |
| kuberay-apiserver | "" | configmaps | create, delete, get, list, patch, update, watch |
| kuberay-apiserver | "" | namespaces | list |
| kuberay-apiserver | "" | events | get, list |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kuberay-operator | system | kuberay-operator (ClusterRole) | kuberay-operator |
| kuberay-operator-leader-election | system | kuberay-operator-leader-election (Role) | kuberay-operator |
| kuberay-apiserver | ray-system | kuberay-apiserver (ClusterRole) | kuberay-apiserver |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {raycluster-name}-redis-password | Opaque | Redis password for Ray GCS authentication | KubeRay Operator | No |
| {raycluster-name}-tls | kubernetes.io/tls | TLS certificates for Ray dashboard HTTPS | cert-manager | Yes |
| external-storage-secret | Opaque | Credentials for S3/GCS external storage (GCS FT) | User | No |
| image-pull-secret | kubernetes.io/dockerconfigjson | Container registry credentials | User/Platform | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| KubeRay APIServer gRPC/HTTP | All | Bearer Token (ServiceAccount) | Kubernetes RBAC | ClusterRole: kuberay-apiserver |
| Operator Metrics | GET | None | None | Publicly accessible within cluster |
| Ray GCS (6379) | TCP | Redis Password | Ray Head Node | Password in environment variable |
| Ray Dashboard (8265) | HTTP | None (default) | Optional Ingress/Route | Can be secured with external auth proxy |
| Ray Client (10001) | TCP | None | Network Policy | Internal cluster access only |
| Ray Serve (8000) | HTTP | Application-level | Application Code | Custom authentication in serve deployments |

## Data Flows

### Flow 1: Ray Cluster Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Platform | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | KubeRay Operator | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | KubeRay Operator | Kubernetes API (Pod Creation) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Ray Head Pod | Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret |
| 5 | Ray Worker Pods | Ray Head GCS | 6379/TCP | TCP | None | Redis Password |

### Flow 2: Ray Job Submission via APIServer

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | KubeRay APIServer | 8887/TCP | gRPC | None | Bearer Token |
| 2 | KubeRay APIServer | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | KubeRay APIServer | Ray Head Dashboard | 8265/TCP | HTTP | None | None |
| 4 | Ray Head | Ray Workers | 6379/TCP | TCP | None | Redis Password |

### Flow 3: Ray Serve Traffic

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | Ingress/Route | 443/TCP | HTTPS | TLS 1.2+ | Optional |
| 2 | Ingress/Route | Ray Serve Service | 8000/TCP | HTTP | None | None |
| 3 | Ray Serve Service | Ray Head/Worker Pods | 8000/TCP | HTTP | None | Application-level |

### Flow 4: Monitoring and Metrics

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | KubeRay Operator | 8080/TCP | HTTP | None | None |
| 2 | Prometheus | Ray Head Pods | 8080/TCP | HTTP | None | None |
| 3 | Grafana | Prometheus | 9090/TCP | HTTP | None | Basic Auth |

### Flow 5: Ray GCS Fault Tolerance (External Storage)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Ray Head Pod | External Redis | 6379/TCP | TCP | Optional TLS | Redis Password |
| 2 | Ray Head Pod | S3/GCS | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/GCP SA |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API | REST API | 443/TCP | HTTPS | TLS 1.2+ | Create and manage Pods, Services, Ingresses, Jobs |
| Prometheus | Metrics Scraping | 8080/TCP | HTTP | None | Collect operator and Ray cluster metrics |
| OpenShift Routes | CRD API | 443/TCP | HTTPS | TLS 1.2+ | Expose Ray dashboard and services externally |
| Volcano Scheduler | CRD API | 443/TCP | HTTPS | TLS 1.2+ | Gang scheduling for Ray clusters |
| cert-manager | Certificate CRD | 443/TCP | HTTPS | TLS 1.2+ | Automatic TLS certificate provisioning |
| External Redis | TCP Connection | 6379/TCP | TCP | Optional TLS | Ray GCS fault tolerance storage backend |
| S3/GCS Storage | HTTP API | 443/TCP | HTTPS | TLS 1.2+ | Object storage for Ray and GCS fault tolerance |
| Container Registry | HTTP API | 443/TCP | HTTPS | TLS 1.2+ | Pull Ray operator and workload container images |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| e603d04d | 2025-09-01 | - chore(deps): update konflux references (#585) |
| d5d1df89 | 2025-08-26 | - chore(deps): update registry.access.redhat.com/ubi8/ubi-minimal docker digest to 43dde01 (#576) |
| 01dce956 | 2025-08-20 | - chore(deps): update registry.access.redhat.com/ubi8/ubi-minimal docker digest to 89f2c97 (#556) |
| 4322d204 | 2025-08-15 | - Update registry.access.redhat.com/ubi8/ubi-minimal Docker digest to 395dec1 (#508) |
| cfacd21b | 2025-08-01 | - Update Konflux references (#513) |
| a1f45d32 | 2025-07-31 | - Update registry.access.redhat.com/ubi8/ubi-minimal Docker digest to af9b4a2 (#494) |
| 6152ce63 | 2025-07-29 | - Update registry.access.redhat.com/ubi8/ubi-minimal Docker digest to 7957d61 (#493) |
| 548390f9 | 2025-07-28 | - Update registry.access.redhat.com/ubi8/ubi-minimal Docker digest to 8075621 (#470) |
| eb57e0ef | 2025-07-15 | - Update registry.access.redhat.com/ubi8/ubi-minimal Docker digest to 5b195cf (#469) |
| 310d0646 | 2025-07-10 | - Update registry.access.redhat.com/ubi8/ubi-minimal Docker digest to 9746f7a (#451) |

## Deployment Configuration

### Container Images

| Image | Base | Purpose | Build Method |
|-------|------|---------|--------------|
| odh-kuberay-operator-controller-container | UBI8 Minimal | Ray operator controller | Konflux (Dockerfile.konflux) |
| kuberay-apiserver | UBI8 Minimal | Optional API server for simplified management | Standard Dockerfile |

### Kustomize Deployment

**Manifests Location**: `ray-operator/config`

The operator is deployed via kustomize with the following structure:
- **Base**: `ray-operator/config/default` - Default operator deployment
- **OpenShift**: `ray-operator/config/openshift` - OpenShift-specific configurations including SecurityContextConstraints
- **CRDs**: `ray-operator/config/crd/bases` - Custom Resource Definitions
- **RBAC**: `ray-operator/config/rbac` - ClusterRoles and RoleBindings
- **Manager**: `ray-operator/config/manager` - Operator deployment and service
- **Samples**: `ray-operator/config/samples` - Example RayCluster, RayJob, RayService configurations

### OpenShift Specific Configuration

| Component | Type | Purpose |
|-----------|------|---------|
| run-as-ray-user | SecurityContextConstraints | Allows operator service account to run Ray pods with UID 1000 |
| Route Support | OpenShift Route API | Operator automatically creates Routes for Ray dashboard when enabled |
| Image References | ConfigMap Patch | Override container images for disconnected environments |

## Operational Notes

### Autoscaling
- Ray Autoscaler sidecar can be enabled via `enableInTreeAutoscaling: true`
- Autoscaler manages worker pod scaling based on Ray resource demands
- Supports Conservative and Aggressive upscaling modes
- Configurable idle timeout for scale-down (default: 60s)

### Fault Tolerance
- Ray GCS fault tolerance requires external Redis or cloud storage (S3/GCS)
- Enabled via annotation `ray.io/ft-enabled: "true"`
- External storage namespace annotation: `ray.io/external-storage-namespace`
- Automatic Redis cleanup job for GCS fault tolerance

### High Availability (RayService)
- Zero-downtime upgrades through multi-cluster serving
- Automatic health checking and traffic switching
- Configurable serve deployment health check intervals

### Resource Management
- Operator manages CPU/memory limits for autoscaler sidecar
- Default operator resources: 100m CPU, 512Mi memory
- Supports custom resource annotations for Ray nodes
- GPU support through Kubernetes device plugins

### Monitoring
- Prometheus metrics exposed on port 8080 for operator
- Ray cluster metrics exposed via ServiceMonitor CRDs
- Dashboard agent metrics on port 52365 (when enabled)
- Built-in Grafana dashboard templates available
