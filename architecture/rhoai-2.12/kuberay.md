# Component: KubeRay Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kuberay
- **Version**: b0225b36 (rhoai-2.12 branch)
- **Distribution**: RHOAI
- **Languages**: Go 1.22.2
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes operator for deploying and managing Ray clusters on Kubernetes for distributed ML/AI workloads.

**Detailed**: KubeRay is a powerful Kubernetes operator that simplifies the deployment and management of Ray applications on Kubernetes. Ray is an open-source unified compute framework for distributed computing and machine learning workloads. The KubeRay operator provides three custom resource definitions (RayCluster, RayJob, and RayService) to manage the full lifecycle of Ray applications. RayCluster manages Ray cluster creation/deletion, autoscaling, and fault tolerance. RayJob automatically creates a RayCluster and submits jobs when ready. RayService provides zero-downtime upgrades and high availability for Ray Serve deployments. The operator handles all Kubernetes resources including pods, services, ingress/routes, RBAC, and integrates with OpenShift security contexts and optional batch schedulers like Volcano.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kuberay-operator | Go Operator | Main controller managing RayCluster, RayJob, RayService lifecycle |
| RayCluster Controller | Controller | Reconciles RayCluster CRs, manages head/worker pods, services, autoscaling |
| RayJob Controller | Controller | Manages batch job execution on Ray clusters |
| RayService Controller | Controller | Manages Ray Serve deployments with HA and zero-downtime updates |
| Validating Webhook | Admission Webhook | Validates RayCluster CR CREATE/UPDATE operations |
| Ray Head Pod | Workload Pod | Ray cluster head node with GCS server, dashboard, and client interface |
| Ray Worker Pod(s) | Workload Pod | Ray cluster worker nodes that connect to head node |
| Head Service | Kubernetes Service | ClusterIP service exposing Ray head node (GCS, dashboard, client ports) |
| Serve Service | Kubernetes Service | Service for Ray Serve HTTP endpoints |
| Headless Worker Service | Kubernetes Service | Headless service for multi-host worker groups |
| Metrics Service | Kubernetes Service | ClusterIP service exposing operator metrics on port 8080 |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| ray.io | v1 | RayCluster | Namespaced | Defines a Ray cluster with head and worker groups, autoscaling, and resource specs |
| ray.io | v1 | RayJob | Namespaced | Defines a batch job to run on a Ray cluster with automatic cluster lifecycle |
| ray.io | v1 | RayService | Namespaced | Defines a Ray Serve deployment with HA and zero-downtime upgrade capabilities |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for operator health and performance |
| /healthz | GET | 8080/TCP | HTTP | None | None | Operator health check endpoint |
| /readyz | GET | 8080/TCP | HTTP | None | None | Operator readiness check endpoint |
| /validate-ray-io-v1-raycluster | POST | 443/TCP | HTTPS | TLS 1.2+ | K8s API Auth | Validating webhook for RayCluster resources |

### Ray Cluster Services (Created by Operator)

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| Ray GCS Server | 6379/TCP | TCP | None | None | Global Control Service - cluster metadata and coordination |
| Ray Dashboard | 8265/TCP | HTTP | None | None | Web UI for monitoring Ray cluster status and jobs |
| Ray Client | 10001/TCP | TCP | None | None | Ray client connection port for remote job submission |
| Ray Serve | 8000/TCP | HTTP | None | None | HTTP endpoint for Ray Serve model serving deployments |
| Ray Metrics | 8080/TCP | HTTP | None | None | Ray cluster metrics export to Prometheus |
| Dashboard Agent | 52365/TCP | HTTP | None | None | Ray dashboard agent on each node for health checks |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.28.4 | Yes | Container orchestration platform |
| controller-runtime | 0.16.3 | Yes | Kubernetes controller framework |
| Go | 1.22.2 | Yes | Programming language and runtime |
| OpenShift API | 0.0.0-20211209135129 | No | OpenShift Route and SCC support |
| Volcano Scheduler | 1.6.0-alpha | No | Gang scheduling and batch job scheduling |
| cert-manager | any | No | TLS certificate management for webhooks |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| None | N/A | KubeRay operates independently; Ray clusters can be used by other ODH components |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kuberay-operator | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |
| {raycluster-name}-head-svc | ClusterIP | 6379/TCP | 6379 | TCP | None | None | Internal |
| {raycluster-name}-head-svc | ClusterIP | 8265/TCP | 8265 | HTTP | None | None | Internal |
| {raycluster-name}-head-svc | ClusterIP | 10001/TCP | 10001 | TCP | None | None | Internal |
| {raycluster-name}-head-svc | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |
| {rayservice-name}-serve-svc | ClusterIP | 8000/TCP | 8000 | HTTP | None | None | Internal |
| {raycluster-name}-headless-worker-svc | Headless | Various | Various | TCP | None | None | Internal |
| webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | K8s API | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {custom-ingress} | Kubernetes Ingress | Custom | 8265/TCP | HTTP/HTTPS | Optional TLS | SIMPLE | External (Optional) |
| {custom-ingress} | Kubernetes Ingress | Custom | 8000/TCP | HTTP/HTTPS | Optional TLS | SIMPLE | External (Optional) |
| {custom-route} | OpenShift Route | Auto-generated | 8265/TCP | HTTP/HTTPS | Optional TLS | Edge/Passthrough | External (Optional) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | CR reconciliation, resource management |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret | Pull Ray container images |
| External Storage | 443/TCP | HTTPS | TLS 1.2+ | Varies | Ray GCS fault tolerance external storage (optional) |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kuberay-operator | batch | jobs | create, delete, get, list, patch, update, watch |
| kuberay-operator | coordination.k8s.io | leases | create, get, list, update |
| kuberay-operator | "" | pods, pods/status | create, delete, deletecollection, get, list, patch, update, watch |
| kuberay-operator | "" | services, services/status | create, delete, get, list, patch, update, watch |
| kuberay-operator | "" | serviceaccounts | create, delete, get, list, watch |
| kuberay-operator | "" | events | create, delete, get, list, patch, update, watch |
| kuberay-operator | "" | endpoints | get, list |
| kuberay-operator | networking.k8s.io | ingresses, ingressclasses | create, delete, get, list, patch, update, watch |
| kuberay-operator | extensions | ingresses | create, delete, get, list, patch, update, watch |
| kuberay-operator | ray.io | rayclusters, rayclusters/status, rayclusters/finalizers | create, delete, get, list, patch, update, watch |
| kuberay-operator | ray.io | rayjobs, rayjobs/status, rayjobs/finalizers | create, delete, get, list, patch, update, watch |
| kuberay-operator | ray.io | rayservices, rayservices/status, rayservices/finalizers | create, delete, get, list, patch, update, watch |
| kuberay-operator | rbac.authorization.k8s.io | roles, rolebindings | create, delete, get, list, update, watch |
| kuberay-operator | route.openshift.io | routes | create, delete, get, list, patch, update, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kuberay-operator | Cluster-wide | kuberay-operator (ClusterRole) | kuberay-operator |
| leader-election-role-binding | Operator namespace | leader-election-role | kuberay-operator |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {raycluster-name}-redis-secret | Opaque | Redis/GCS password (optional) | User/External | No |
| webhook-server-cert | kubernetes.io/tls | TLS certificate for validating webhook | cert-manager | Yes |
| {custom-tls-secret} | kubernetes.io/tls | TLS for Ray Dashboard/Serve ingress (optional) | User/cert-manager | Varies |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None | None | Unauthenticated (internal only) |
| /healthz, /readyz | GET | None | None | Unauthenticated (internal only) |
| /validate-ray-io-v1-raycluster | POST | K8s API Server Auth | API Server | Webhook called by API server with ServiceAccount auth |
| Ray Dashboard (8265) | ALL | None (by default) | None | Unauthenticated - should be behind ingress/auth proxy |
| Ray Serve (8000) | ALL | None (by default) | None | Unauthenticated - application-level auth recommended |

### OpenShift Security

| Resource Type | Name | Purpose |
|---------------|------|---------|
| SecurityContextConstraints | run-as-ray-user | Allows Ray pods to run as UID 1000 with restricted security |
| securityContext | runAsNonRoot: true | Operator pod runs as non-root user (65532) |
| securityContext | allowPrivilegeEscalation: false | Prevents privilege escalation in operator pod |

## Data Flows

### Flow 1: RayCluster Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API | 443/TCP | HTTPS | TLS 1.3 | Bearer Token |
| 2 | Kubernetes API | Validating Webhook | 443/TCP | HTTPS | TLS 1.2+ | K8s ServiceAccount |
| 3 | Validating Webhook | Kubernetes API | N/A | N/A | N/A | Response |
| 4 | Kubernetes API | KubeRay Operator | Watch | HTTPS | TLS 1.3 | ServiceAccount Token |
| 5 | KubeRay Operator | Kubernetes API | 443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |
| 6 | Kubelet | Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret |
| 7 | Ray Worker Pods | Ray Head Pod | 6379/TCP | TCP | None | None |

### Flow 2: Ray Job Submission

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Ray Client | Ray Head Service | 10001/TCP | TCP | None | None |
| 2 | Ray Client | Ray Dashboard | 8265/TCP | HTTP | None | None |
| 3 | Ray Head | Ray Workers | 6379/TCP | TCP | None | None |
| 4 | Ray Workers | Ray Head | 6379/TCP | TCP | None | None |

### Flow 3: Ray Serve Inference

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | Ingress/Route | 443/TCP | HTTPS | TLS 1.2+ | Application-level |
| 2 | Ingress/Route | Ray Serve Service | 8000/TCP | HTTP | None | None |
| 3 | Ray Serve Service | Ray Head/Worker Pods | 8000/TCP | HTTP | None | None |

### Flow 4: Operator Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | KubeRay Operator | Kubernetes API | 443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |
| 2 | KubeRay Operator | Ray Dashboard | 8265/TCP | HTTP | None | None |
| 3 | Prometheus | Operator Metrics Service | 8080/TCP | HTTP | None | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 443/TCP | HTTPS | TLS 1.3 | Resource management and CR reconciliation |
| Ray Dashboard | HTTP API | 8265/TCP | HTTP | None | Cluster health checks, job status queries |
| Prometheus | Metrics Scrape | 8080/TCP | HTTP | None | Operator metrics collection |
| Volcano Scheduler | CRD API | N/A | K8s API | TLS 1.3 | Gang scheduling for Ray pods (optional) |
| cert-manager | Certificate API | N/A | K8s API | TLS 1.3 | TLS certificate provisioning (optional) |
| OpenShift Router | Route API | N/A | K8s API | TLS 1.3 | External exposure via Routes (OpenShift only) |

## Deployment Architecture

### Operator Deployment

- **Deployment**: kuberay-operator (1 replica, Recreate strategy)
- **Container Image**: Built from Dockerfile using Go 1.22.2 on distroless/base-debian11
- **Resource Limits**: CPU 100m, Memory 512Mi
- **Security**: Runs as non-root (UID 65532), no privilege escalation
- **Probes**: Liveness and readiness on /metrics endpoint (port 8080)
- **Leader Election**: Enabled via coordination.k8s.io/leases

### Ray Cluster Architecture (Managed by Operator)

- **Head Pod**: Single pod running Ray head node with GCS, dashboard, client server
- **Worker Pods**: 0-N pods based on RayCluster spec (supports autoscaling)
- **Services**: Head service (ClusterIP), optional serve service, optional headless worker service
- **Autoscaler**: Optional Ray autoscaler sidecar in head pod
- **Init Container**: Injected to wait for GCS before starting workers
- **Volumes**: EmptyDir for Ray logs by default

### Configuration Options

| Parameter | Type | Default | Purpose |
|-----------|------|---------|---------|
| metrics-addr | String | :8080 | Metrics endpoint bind address |
| health-probe-bind-address | String | :8081 | Health probe bind address |
| enable-leader-election | Boolean | false | Enable leader election |
| reconcile-concurrency | Integer | 1 | Max concurrent reconciliations |
| watch-namespace | String | "" (all) | Namespaces to watch (comma-separated) |
| enable-batch-scheduler | Boolean | false | Enable Volcano batch scheduler integration |
| forced-cluster-upgrade | Boolean | false | Force cluster upgrades |

## Recent Changes

Based on git history (rhoai-2.12 branch, commits from 2024-2025):

| Date | Type | Changes |
|------|------|---------|
| 2024-2025 | Dependency Updates | - Multiple updates to UBI9 base images and Go toolset<br>- Konflux CI/CD pipeline updates<br>- Security and vulnerability patches |
| 2024 | RHOAI Integration | - Merge from upstream KubeRay main branch<br>- OpenShift-specific configurations<br>- Integration with RHOAI distribution |
| Ongoing | Maintenance | - Regular dependency updates via automated PRs<br>- Base image security updates<br>- Konflux pipeline synchronization |

## Notable Features

### KubeRay v1.1.0 Features
- **Autoscaling**: Ray autoscaler integration with Kubernetes HPA
- **Fault Tolerance**: GCS fault tolerance with external storage (Redis)
- **Batch Scheduling**: Optional Volcano scheduler for gang scheduling
- **Multi-host Workers**: Headless services for multi-host worker groups
- **Webhooks**: Validation webhook for RayCluster resources
- **Probes Injection**: Automatic readiness/liveness probe injection
- **OpenShift Support**: Routes and SecurityContextConstraints
- **Monitoring**: Prometheus metrics and Grafana dashboard integration

### RHOAI-Specific Enhancements
- **Konflux Build**: Built using Red Hat Konflux CI/CD
- **UBI Base Images**: Uses Red Hat Universal Base Images (UBI9)
- **FIPS Compliance**: Compiled with strict FIPS runtime tags
- **Security Hardening**: Distroless base, non-root execution, SCC integration
- **OpenShift Integration**: Native Route support and OpenShift-aware configurations

## Architecture Diagrams

### Component Hierarchy
```
KubeRay Operator
├── RayCluster Controller
│   ├── Head Pod (GCS + Dashboard + Client)
│   ├── Worker Pod(s)
│   ├── Head Service
│   ├── Autoscaler (optional)
│   └── RBAC (ServiceAccount, Role, RoleBinding)
├── RayJob Controller
│   ├── RayCluster (ephemeral)
│   ├── Job Submitter (K8s Job)
│   └── Job Cleanup
└── RayService Controller
    ├── RayCluster (active + standby)
    ├── Serve Service
    └── Zero-downtime Updates
```

### Network Flow
```
User → Ingress/Route (443) → Ray Serve Service (8000) → Ray Pods
     → Ray Client (10001) → Ray Head Pod → Ray Workers (6379)
     → Ray Dashboard (8265) → Ray Head Pod

Prometheus → Operator Metrics (8080)
KubeRay Operator → K8s API (443) → Pod/Service Management
```

## Known Limitations

1. **Default Security**: Ray cluster services have no authentication by default - requires ingress/auth proxy
2. **Network Encryption**: Internal Ray communication (port 6379) is unencrypted by default
3. **Single Operator**: Operator runs single replica (leader election available but Recreate strategy)
4. **Resource Intensive**: Ray clusters can be resource-intensive; careful sizing required
5. **Storage**: No persistent storage for Ray by default; uses emptyDir volumes

## Recommendations

1. **Production Deployment**:
   - Enable TLS for Ray Dashboard and Serve endpoints via ingress
   - Implement authentication proxy (OAuth2, OIDC) for external access
   - Use NetworkPolicies to restrict Ray pod communication
   - Enable leader election for operator high availability
   - Configure resource limits based on workload requirements

2. **Security**:
   - Never expose Ray GCS port (6379) externally
   - Use RBAC to restrict RayCluster creation to authorized users
   - Enable webhook validation to enforce security policies
   - Regularly update to latest RHOAI version for security patches

3. **Monitoring**:
   - Configure Prometheus to scrape operator and Ray metrics
   - Set up alerts for Ray cluster health and resource usage
   - Use Ray Dashboard for job monitoring and debugging

4. **Scaling**:
   - Use Ray autoscaler for dynamic worker scaling
   - Size head pod appropriately (controls entire cluster)
   - Consider Volcano scheduler for multi-tenant environments
   - Monitor GCS memory usage on head pod
