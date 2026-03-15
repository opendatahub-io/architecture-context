# Component: CodeFlare Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/codeflare-operator.git
- **Version**: 9cfde69 (rhoai-2.7 branch)
- **Distribution**: RHOAI
- **Languages**: Go 1.20
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Operator for installation and lifecycle management of CodeFlare distributed workload stack, including MCAD and InstaScale controllers.

**Detailed**: The CodeFlare Operator manages the lifecycle of distributed workload scheduling components in Kubernetes clusters. It integrates two primary controllers: Multi-Cluster App Dispatcher (MCAD) for queue-based workload scheduling and resource management, and InstaScale for dynamic cluster scaling. The operator provides Custom Resource Definitions (CRDs) for defining application wrappers, scheduling specifications, and quota management, enabling users to submit and manage complex distributed workloads such as Ray clusters, PyTorch jobs, and other AI/ML training jobs. The operator watches AppWrapper resources and coordinates with MCAD to schedule workloads based on resource availability, priorities, and quota constraints. When InstaScale is enabled, it can automatically scale OpenShift cluster nodes (MachineSets) to meet workload demands.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| codeflare-operator manager | Go Operator | Main operator controller managing MCAD and InstaScale lifecycle |
| MCAD Controller | Queue Controller | Multi-Cluster App Dispatcher for workload queuing and scheduling |
| InstaScale Controller | Scaling Controller | Optional controller for dynamic cluster node scaling |
| Metrics Server | HTTP Server | Prometheus metrics endpoint for operator monitoring |
| Health Probe Server | HTTP Server | Liveness and readiness probe endpoints |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| workload.codeflare.dev | v1beta1 | AppWrapper | Namespaced | Wraps generic Kubernetes resources for batch scheduling with MCAD queue management |
| workload.codeflare.dev | v1beta1 | SchedulingSpec | Namespaced | Defines scheduling parameters for workload requeuing and dispatch duration |
| quota.codeflare.dev | v1alpha1 | QuotaSubtree | Namespaced | Hierarchical quota management for multi-tenant resource allocation |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | Bearer Token | Prometheus metrics scraping endpoint |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe for Kubernetes health checks |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe for Kubernetes health checks |

### gRPC Services

No gRPC services exposed.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Multi-Cluster App Dispatcher (MCAD) | v1.39.0 | Yes | Embedded controller for queue-based workload scheduling |
| InstaScale | v0.4.0 | No | Optional embedded controller for cluster autoscaling |
| KubeRay | v1.0.0 | No | External dependency for Ray cluster management (MCAD integrates with Ray) |
| controller-runtime | v0.15.3 | Yes | Kubernetes controller framework |
| Kubernetes API | v1.27.8 | Yes | Kubernetes cluster API server |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KubeRay Operator | CRD Management | MCAD creates and manages RayCluster CRs for distributed Ray workloads |
| Prometheus | ServiceMonitor | Operator metrics are scraped by cluster Prometheus for monitoring |
| OpenShift Machine API | API Calls | InstaScale creates/deletes MachineSets for cluster scaling (OpenShift only) |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| codeflare-operator-manager-metrics | ClusterIP | 8080/TCP | 8080 | HTTP | None | Bearer Token | Internal |

### Ingress

No ingress resources defined. Operator is internal-only.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch and manage Kubernetes resources (Pods, Services, Deployments, etc.) |
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Create/update AppWrapper, QuotaSubtree CRDs |
| OpenShift Machine API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | InstaScale manages MachineSets (when enabled, OpenShift only) |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | workload.codeflare.dev | appwrappers, appwrappers/finalizers, appwrappers/status, schedulingspecs | create, delete, deletecollection, get, list, patch, update, watch |
| manager-role | quota.codeflare.dev | quotasubtrees | create, delete, deletecollection, get, list, patch, update, watch |
| manager-role | "" (core) | pods, pods/status | create, delete, deletecollection, get, list, patch, update, watch |
| manager-role | "" (core) | services, deployments, configmaps, secrets, serviceaccounts, persistentvolumeclaims, persistentvolumes, nodes | create, delete, get, list, patch, update, watch |
| manager-role | "" (core) | bindings, pods/binding | create |
| manager-role | apps | deployments, replicasets, statefulsets | create, delete, get, list, patch, update, watch |
| manager-role | batch | jobs | create, delete, list, patch, update, watch |
| manager-role | scheduling.sigs.k8s.io | podgroups | create, delete, deletecollection, get, list, patch, update, watch |
| manager-role | coordination.k8s.io | leases | create, get, update |
| manager-role | machine.openshift.io | * | create, delete, get, list, patch, update, watch |
| manager-role | storage.k8s.io | csidrivers, csinodes, csistoragecapacities | get, list, watch |
| instascale-role | "" (core) | nodes | get, list, patch, update |
| instascale-role | "" (core) | secrets | get |
| instascale-role | machine.openshift.io | machines, machinesets | create, delete, get, list, patch, update, watch |
| instascale-role | config.openshift.io | clusterversions | get, list, watch |
| mcad-controller-ray-clusterrole | ray.io | rayclusters, rayclusters/finalizers, rayclusters/status | create, delete, get, list, patch, update, watch |
| mcad-controller-ray-clusterrole | networking.k8s.io | ingresses | create, delete, get, list, patch, update, watch |
| mcad-controller-ray-clusterrole | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| leader-election-role | "" (core) | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| clusterrole-admin | quota.codeflare.dev | quotasubtrees | create, delete, deletecollection, get, list, patch, update, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| codeflare-operator-manager-rolebinding | Cluster-wide | manager-role (ClusterRole) | controller-manager (opendatahub namespace) |
| codeflare-operator-instascale-rolebinding | Cluster-wide | instascale-role (ClusterRole) | controller-manager (opendatahub namespace) |
| codeflare-operator-mcad-controller-ray-rolebinding | Cluster-wide | mcad-controller-ray-clusterrole (ClusterRole) | controller-manager (opendatahub namespace) |
| codeflare-operator-leader-election-rolebinding | opendatahub | leader-election-role (Role) | controller-manager (opendatahub namespace) |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| ServiceAccount Token | kubernetes.io/service-account-token | Kubernetes API authentication | Kubernetes | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | Bearer Token (ServiceAccount) | Prometheus ServiceMonitor | ServiceAccount token from Prometheus scraper |
| /healthz | GET | None | Kubernetes kubelet | Public health endpoint for liveness probes |
| /readyz | GET | None | Kubernetes kubelet | Public health endpoint for readiness probes |
| Kubernetes API | All | ServiceAccount Token | Kubernetes RBAC | RBAC enforced via ClusterRole bindings |

## Data Flows

### Flow 1: AppWrapper Submission and Scheduling

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Client | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Kubernetes API | MCAD Controller (via watch) | In-process | In-memory | N/A | N/A |
| 3 | MCAD Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | MCAD Controller | Kubernetes API (Pod creation) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: InstaScale Node Scaling (when enabled)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | InstaScale Controller | Kubernetes API (watch AppWrappers) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | InstaScale Controller | Kubernetes API (read nodes) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | InstaScale Controller | OpenShift Machine API (create MachineSet) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Machine API | Cloud Provider API | 443/TCP | HTTPS | TLS 1.2+ | Cloud credentials |

### Flow 3: Prometheus Metrics Scraping

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | codeflare-operator manager | 8080/TCP | HTTP | None | Bearer Token |

### Flow 4: MCAD RayCluster Management

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | MCAD Controller | Kubernetes API (create RayCluster CR) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | KubeRay Operator | Kubernetes API (watch RayClusters) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | KubeRay Operator | Kubernetes API (create Ray Pods) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Watch and manage all Kubernetes resources including CRDs |
| KubeRay Operator | CRD API | 6443/TCP | HTTPS | TLS 1.2+ | MCAD creates RayCluster CRs for Ray workload scheduling |
| Prometheus | HTTP Metrics | 8080/TCP | HTTP | None | Operator metrics collection via ServiceMonitor |
| OpenShift Machine API | REST API | 6443/TCP | HTTPS | TLS 1.2+ | InstaScale manages MachineSets for cluster autoscaling (OpenShift only) |
| Cloud Provider API | REST API | 443/TCP | HTTPS | TLS 1.2+ | Indirect via Machine API for node provisioning (AWS, GCP, Azure, etc.) |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 9cfde69 | 2024 | - DROP: add roles for admin and editor to operator |
| a6b1249 | 2024 | - PATCH: Adjust DSC source path for CodeFlare |
| 5a2b3c5 | 2024 | - CARRY: update(manifests): use default namespace from ODH |
| db76a72 | 2024 | - CARRY: Generate CodeFlare stack config map |
| 1403b68 | 2024 | - CARRY: Add Makefile and configuration files for e2e execution on OpenShift CI |
| 74fb5ec | 2024 | - CARRY: Added Sync Fork workflow |
| 7bfaea6 | 2024 | - CARRY: Added automated workflow for pushing opendatahub/codeflare-operator image |
| 8db15b1 | 2024 | - CARRY: Remove e2e and OLM upgrade tests |
| 003d61b | 2023-12 | - Update dependency versions for release v1.1.0 |
| 4416347 | 2023 | - Update project-codeflare-release.yml |
| 233de7e | 2023 | - Added Workflow job to update CFO image |
| 0e7bd88 | 2023 | - Remove SDK e2e test |
| 35fed67 | 2023 | - Upgrade Kuberay to version v1.0.0 |
| c5cc868 | 2023 | - Remove auto add issue workflow |
| 575ac74 | 2023 | - Fix MCAD version in Makefile |

## Deployment Configuration

### Container Image
- **Base Image**: registry.access.redhat.com/ubi8/ubi-minimal:8.8
- **Build Image**: registry.access.redhat.com/ubi8/go-toolset:1.20.10
- **Build Flags**: CGO_ENABLED=1, FIPS mode enabled (strictfipsruntime tag)
- **Runtime User**: 65532:65532 (non-root)

### Resource Requirements
- **CPU Request**: 1 core
- **CPU Limit**: 1 core
- **Memory Request**: 1Gi
- **Memory Limit**: 1Gi

### High Availability
- **Replicas**: 1
- **Leader Election**: Supported via ConfigMaps and Leases
- **Graceful Shutdown**: 10 seconds termination grace period

## Configuration

### ConfigMap: codeflare-operator-config

The operator loads configuration from a ConfigMap (default: `codeflare-operator-config`) in the operator namespace. If not present, the operator creates a default configuration.

**Configuration Structure**:
- **ClientConnection**: API server client QPS (50) and Burst (100) settings
- **Metrics**: Bind address (`:8080`)
- **Health**: Bind address (`:8081`), readiness endpoint (`/readyz`), liveness endpoint (`/healthz`)
- **LeaderElection**: Leader election configuration
- **MCAD**: MCAD controller configuration
- **InstaScale**: InstaScale controller configuration (enabled: false by default)

## Observability

### Metrics
- **Endpoint**: `/metrics` on port 8080/TCP
- **Format**: Prometheus format
- **Collection**: Via ServiceMonitor CRD for Prometheus Operator
- **Metrics Include**: Controller-runtime default metrics (reconciliation latency, queue depth, etc.)

### Logging
- **Format**: Structured JSON logging via zap
- **Level**: Configurable via command-line flags
- **Timestamp Format**: RFC3339

### Health Checks
- **Liveness**: `/healthz` on port 8081/TCP (15s initial delay, 20s period)
- **Readiness**: `/readyz` on port 8081/TCP (5s initial delay, 10s period)

## Operational Notes

### Deployment Namespace
- **Default**: `opendatahub` (configurable via kustomization)
- **Namespace Detection**: Via NAMESPACE environment variable or ServiceAccount namespace

### MCAD Integration
- MCAD controller is embedded and runs in the same process as the operator
- MCAD manages AppWrapper lifecycle: Queued → HeadOfLine → Dispatched → Running → Completed/Failed
- Supports priority-based scheduling and requeuing strategies

### InstaScale Integration
- **Default State**: Disabled
- **Platform Support**: OpenShift only (requires Machine API)
- **Scaling Logic**: Monitors AppWrapper resource requirements and scales MachineSets
- **MaxScaleoutAllowed**: 5 (default, configurable)

### KubeRay Integration
- MCAD controller can create and manage RayCluster resources
- Requires KubeRay operator to be installed separately
- MCAD monitors RayCluster status for AppWrapper completion

## Security Considerations

### Container Security
- Runs as non-root user (UID 65532)
- No privilege escalation allowed
- All capabilities dropped
- FIPS mode enabled for cryptographic operations

### RBAC Scope
- Requires extensive cluster-wide permissions for resource management
- Separate roles for MCAD, InstaScale, and leader election
- Admin aggregation role for QuotaSubtree management

### Network Security
- Metrics endpoint exposed on HTTP (consider using HTTPS with cert injection)
- ServiceMonitor uses bearer token authentication for Prometheus
- All external communication via HTTPS to Kubernetes API

### Secrets Management
- Uses ServiceAccount token for API authentication (auto-rotated)
- InstaScale may require cloud provider credentials (stored in Secrets)
- No application secrets managed by the operator itself
