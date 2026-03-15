# Component: KubeRay Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kuberay
- **Version**: 1.4.2 (branch: rhoai-3.3, commit: 3bfe37ca)
- **Distribution**: RHOAI
- **Languages**: Go 1.24.0
- **Deployment Type**: Kubernetes Operator
- **Build**: Konflux (FIPS-compliant)

## Purpose
**Short**: Kubernetes operator that manages the lifecycle of Ray clusters, jobs, and services for distributed computing workloads.

**Detailed**: KubeRay is a Kubernetes operator that simplifies the deployment and management of Ray applications on Kubernetes. Ray is an open-source framework for distributed computing, enabling machine learning, data processing, and general-purpose distributed applications. The operator provides three core Custom Resource Definitions (RayCluster, RayJob, RayService) that abstract the complexity of deploying and managing Ray clusters. It handles cluster lifecycle management including creation, deletion, autoscaling, fault tolerance with GCS (Global Control Service) high availability, zero-downtime upgrades for services, and integration with Kubernetes ecosystem components like cert-manager, OpenShift Routes, Gateway API, and batch schedulers. The operator also manages authentication, network policies, and service mesh integration for secure multi-tenant deployments.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kuberay-operator | Deployment | Main operator managing Ray CRDs and creating/reconciling Ray resources |
| RayCluster Controller | Controller | Manages RayCluster lifecycle, autoscaling, and resource reconciliation |
| RayJob Controller | Controller | Manages batch job execution on Ray clusters |
| RayService Controller | Controller | Manages Ray Serve deployments with high availability and zero-downtime upgrades |
| NetworkPolicy Controller | Controller | Creates and manages network policies for Ray cluster isolation |
| Authentication Controller | Controller | Manages mTLS certificates, OAuth integration, and Gateway API authentication |
| Mutating Webhook | Admission Webhook | Mutates RayCluster resources with defaults and security configurations |
| Validating Webhook | Admission Webhook | Validates RayCluster resources before creation/update |
| Ray Head Pod | Managed Workload | Ray cluster head node with GCS, dashboard, and client server |
| Ray Worker Pods | Managed Workload | Ray cluster worker nodes for distributed computation |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| ray.io | v1 | RayCluster | Namespaced | Defines a Ray cluster with head and worker groups, autoscaling, and fault tolerance |
| ray.io | v1 | RayJob | Namespaced | Defines a batch job to run on a Ray cluster with automatic cluster lifecycle |
| ray.io | v1 | RayService | Namespaced | Defines a Ray Serve deployment for model serving with HA and zero-downtime upgrades |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for operator monitoring |
| /healthz | GET | 8080/TCP | HTTP | None | None | Operator health check endpoint |
| /readyz | GET | 8080/TCP | HTTP | None | None | Operator readiness probe endpoint |
| /mutate-ray-io-v1-raycluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes admission | Mutating webhook for RayCluster resources |
| /validate-ray-io-v1-raycluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes admission | Validating webhook for RayCluster resources |

### Ray Cluster Endpoints (Managed by Operator)

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| Ray GCS Server | 6379/TCP | Redis Protocol | Optional mTLS | Optional cert-based | Global Control Service for cluster metadata |
| Ray Dashboard | 8265/TCP | HTTP/HTTPS | Optional TLS | Optional OAuth/bearer | Web UI for cluster monitoring and management |
| Ray Client Server | 10001/TCP | gRPC | Optional mTLS | Optional cert-based | Client connection endpoint for job submission |
| Ray Serve | 8000/TCP | HTTP | Optional TLS | Optional | Model serving endpoints (RayService) |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.30+ | Yes | Container orchestration platform |
| controller-runtime | v0.22.1 | Yes | Kubernetes controller framework |
| cert-manager | v1.x | Optional | TLS certificate management for mTLS |
| Gateway API | v1/v1beta1 | Optional | Advanced ingress and routing with authentication |
| OpenShift Route API | v1 | Optional | OpenShift ingress integration |
| Prometheus | Any | Optional | Metrics collection and monitoring |
| Redis | Any | Optional | External storage for Ray GCS fault tolerance |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | Integration | May display Ray cluster resources and status |
| Model Registry | Integration | May use Ray for distributed model training |
| Data Science Pipelines | Integration | May execute Ray jobs in pipeline steps |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kuberay-operator | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |
| kuberay-webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | Kubernetes admission | Internal |
| {cluster}-head-svc | ClusterIP | 6379/TCP, 8265/TCP, 10001/TCP | 6379, 8265, 10001 | Multiple | Optional mTLS/TLS | Optional | Internal/External |
| {service}-serve-svc | ClusterIP | 8000/TCP | 8000 | HTTP/HTTPS | Optional TLS | Optional | External |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {cluster}-ingress | Ingress/Route | User-defined | 80/443/TCP | HTTP/HTTPS | Optional TLS | SIMPLE | External |
| {cluster}-gateway-route | HTTPRoute | User-defined | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE/MUTUAL | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token | Resource management and status updates |
| External Redis | 6379/TCP | Redis | Optional TLS | Password | GCS fault tolerance external storage |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull secrets | Pull Ray container images |
| Object Storage (S3/GCS) | 443/TCP | HTTPS | TLS 1.2+ | Cloud credentials | Ray working directory and data access |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kuberay-operator | "" | pods, services, serviceaccounts, configmaps, events, secrets, endpoints | get, list, watch, create, update, patch, delete |
| kuberay-operator | "" | pods/status, pods/proxy, services/status, services/proxy | get, patch, update |
| kuberay-operator | apps | deployments | get, list, watch, patch, update |
| kuberay-operator | batch | jobs | get, list, watch, create, update, patch, delete |
| kuberay-operator | ray.io | rayclusters, rayjobs, rayservices | get, list, watch, create, update, patch, delete |
| kuberay-operator | ray.io | rayclusters/status, rayjobs/status, rayservices/status | get, patch, update |
| kuberay-operator | ray.io | rayclusters/finalizers, rayjobs/finalizers, rayservices/finalizers | update |
| kuberay-operator | networking.k8s.io | ingresses, networkpolicies, ingressclasses | get, list, watch, create, update, patch, delete |
| kuberay-operator | route.openshift.io | routes | get, list, watch, create, update, patch, delete |
| kuberay-operator | cert-manager.io | certificates, issuers | get, list, watch, create, update, patch, delete |
| kuberay-operator | gateway.networking.k8s.io | httproutes, referencegrants, gateways | get, list, watch, create, update, patch, delete |
| kuberay-operator | rbac.authorization.k8s.io | roles, rolebindings, clusterroles, clusterrolebindings | get, list, watch, create, update, delete |
| kuberay-operator | coordination.k8s.io | leases | get, list, create, update |
| kuberay-operator | config.openshift.io | authentications, oauths | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kuberay-operator | system/operator namespace | kuberay-operator | kuberay-operator |
| leader-election-rolebinding | system/operator namespace | leader-election-role | kuberay-operator |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| kuberay-webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificate | cert-manager/OpenShift service-ca | Yes |
| {cluster}-ca-cert | kubernetes.io/tls | Ray cluster CA for mTLS | cert-manager | Yes |
| {cluster}-tls-cert | kubernetes.io/tls | Ray head/worker mTLS certificates | cert-manager | Yes |
| redis-password-secret | Opaque | Redis password for GCS fault tolerance | User/External | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None | None | Public within cluster |
| Webhook endpoints | POST | Kubernetes admission | API server | System only |
| Ray GCS (6379) | ALL | Optional mTLS client certs | Ray GCS | Certificate-based when enabled |
| Ray Dashboard (8265) | ALL | Optional OAuth/bearer token | Ray Dashboard | Token-based when enabled |
| Ray Client (10001) | ALL | Optional mTLS client certs | Ray Client Server | Certificate-based when enabled |
| Ray Serve (8000) | ALL | Optional bearer token | Ingress/Gateway | Policy-based when enabled |

### Security Context Constraints (OpenShift)

| SCC Name | UID | Capabilities | Privilege Escalation | SELinux |
|----------|-----|--------------|---------------------|---------|
| run-as-ray-user | 1000 | Drop ALL | false | MustRunAs |

## Data Flows

### Flow 1: RayCluster Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) |
| 2 | Kubernetes API | Mutating Webhook | 443/TCP | HTTPS | TLS 1.2+ | Kubernetes admission |
| 3 | Kubernetes API | Validating Webhook | 443/TCP | HTTPS | TLS 1.2+ | Kubernetes admission |
| 4 | RayCluster Controller | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) |
| 5 | RayCluster Controller | cert-manager API | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) |
| 6 | Kubernetes API | Ray Head Pod | N/A | N/A | N/A | N/A |
| 7 | Ray Workers | Ray GCS | 6379/TCP | Redis | Optional mTLS | Optional cert |

### Flow 2: RayJob Submission

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | RayJob Controller | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) |
| 3 | RayJob Controller | Ray Client Server | 10001/TCP | gRPC | Optional mTLS | Optional cert |
| 4 | Ray Client | Ray GCS | 6379/TCP | Redis | Optional mTLS | Optional cert |
| 5 | Ray Head | Ray Workers | Dynamic | Ray Protocol | Optional mTLS | Optional cert |

### Flow 3: RayService Model Serving

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | Ingress/Gateway | 443/TCP | HTTPS | TLS 1.3 | Optional bearer |
| 2 | Ingress/Gateway | Ray Serve Service | 8000/TCP | HTTP | Optional TLS | Optional |
| 3 | Ray Serve | Ray Workers | Dynamic | Ray Protocol | Optional mTLS | Optional cert |
| 4 | RayService Controller | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) |

### Flow 4: Operator Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | kuberay-operator | 8080/TCP | HTTP | None | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API | REST API | 443/TCP | HTTPS | TLS 1.2+ | Resource management and reconciliation |
| cert-manager | CRD API | 443/TCP | HTTPS | TLS 1.2+ | TLS certificate provisioning for mTLS |
| Prometheus | Scraping | 8080/TCP | HTTP | None | Operator and Ray cluster metrics |
| OpenShift Service CA | Certificate injection | N/A | N/A | N/A | Webhook certificate management |
| Gateway API | CRD API | 443/TCP | HTTPS | TLS 1.2+ | Advanced routing and authentication |
| Batch Schedulers (Volcano, Kueue) | CRD API | 443/TCP | HTTPS | TLS 1.2+ | Advanced scheduling and resource queuing |

## Configuration

### Operator Configuration

| Parameter | Default | Purpose |
|-----------|---------|---------|
| metrics-addr | :8080 | Metrics endpoint bind address |
| health-probe-bind-address | :8081 | Health probe endpoint address |
| enable-leader-election | false | Enable leader election for HA |
| reconcile-concurrency | 1 | Maximum concurrent reconciliation operations |
| watch-namespace | "" (all) | Namespaces to watch for Ray resources |
| feature-gates | Various | Enable/disable experimental features |
| enable-batch-scheduler | false | Enable batch scheduler integration |

### Ray Cluster Configuration

| Parameter | Purpose |
|-----------|---------|
| rayVersion | Ray framework version to deploy |
| headGroupSpec | Configuration for Ray head pod (resources, image, ray start params) |
| workerGroupSpecs | Configuration for Ray worker groups (replicas, resources, autoscaling) |
| autoscalerOptions | Ray autoscaler configuration (idle timeout, upscaling mode) |
| gcsFaultToleranceOptions | GCS fault tolerance with external Redis |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 3bfe37ca | 2025-03 | - Update UBI9 go-toolset base image digest<br>- Maintain FIPS compliance |
| 28558da1 | 2025-03 | - Update UBI9 minimal base image for runtime |
| 8f06c52b | 2025-03 | - Update dependencies for security patches |
| 8f1ebd6e | 2025-01 | - Merge RHOAI 3.3 branch updates |
| 6f430001 | 2025-01 | - RHOAIENG-49123: Update to v1.4.4 in Tekton files |
| 7ec30d4a | 2025-01 | - RHOAIENG-49123: Update params.env to v1.4.4 |
| 83a170c2 | 2025-01 | - Fix authentication ready condition handling |
| 4aa5699e | 2025-01 | - Add status subresource to fake client for proper status updates |
| e414321c | 2025-01 | - Fix generation issue in cluster refetch logic |

## Deployment Architecture

### Operator Deployment

- **Replicas**: 1 (Recreate strategy for singleton operation)
- **Resource Requests**: 100m CPU, 512Mi memory
- **Resource Limits**: 100m CPU, 512Mi memory
- **Security**: runAsNonRoot, no privilege escalation, drop all capabilities
- **Probes**: HTTP liveness and readiness on /metrics endpoint

### Managed Ray Clusters

- **Head Pod**: Single pod running Ray head node with GCS, dashboard, and client server
- **Worker Pods**: Horizontally scalable worker pods based on autoscaler configuration
- **Autoscaling**: Automatic scaling based on Ray autoscaler metrics (CPU, memory, custom resources)
- **Fault Tolerance**: Optional external Redis for GCS fault tolerance and cluster recovery

## Observability

### Metrics

- Operator metrics exposed at `:8080/metrics` in Prometheus format
- Ray cluster metrics available via Ray dashboard and Prometheus exporters
- Custom metrics for Ray resource counts, reconciliation latency, and errors

### Logging

- Structured JSON logging to stdout (configurable encoder)
- Optional file logging with rotation (lumberjack)
- Configurable log levels per component

### Health Checks

- Liveness probe: HTTP GET /metrics on port 8080
- Readiness probe: HTTP GET /metrics on port 8080
- Health endpoint: /healthz on port 8081

## High Availability

- **Operator HA**: Optional leader election for multi-replica deployments
- **Ray GCS HA**: External Redis backend for fault tolerance
- **RayService HA**: Zero-downtime upgrades with traffic switching between cluster versions
- **Autoscaling**: Automatic worker scaling based on workload demand

## Scalability

- Operator manages 500 Ray pods with ~512Mi memory (documented anecdotal guidance)
- Concurrent reconciliation configurable (default: 1)
- Namespace-scoped or cluster-wide operation
- Worker group autoscaling from minReplicas to maxReplicas per group

## Known Limitations

- Operator runs as single replica by default (Recreate strategy)
- Forced cluster upgrade flag is deprecated
- Memory usage scales with number of managed Ray pods (~1MB per pod)
- External Redis required for GCS fault tolerance in production
