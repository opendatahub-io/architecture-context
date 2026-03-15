# Component: CodeFlare Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/codeflare-operator.git
- **Version**: cff798d (rhoai-2.6 branch)
- **Distribution**: RHOAI
- **Languages**: Go 1.20
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Manages the CodeFlare distributed workload stack including MCAD queue scheduling and InstaScale auto-scaling for AI/ML workloads.

**Detailed**: The CodeFlare Operator is a Kubernetes operator that provides installation and lifecycle management for the CodeFlare distributed workload stack. It embeds two main controllers: MCAD (Multi-Cluster App Dispatcher) for intelligent queue-based workload scheduling, and InstaScale for automatic cluster scaling based on workload demands. The operator manages AppWrapper resources that wrap user workloads (like Ray clusters, Jobs, Deployments) with scheduling policies, priority, and resource quotas. MCAD queues these workloads and dispatches them when resources are available, while InstaScale (when enabled) can automatically scale OpenShift MachineSets to provision additional compute capacity for pending workloads. This provides a complete solution for managing batch and distributed AI/ML workloads on Kubernetes/OpenShift with gang scheduling, quota management, and elastic scaling capabilities.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| MCAD Queue Controller | Embedded Controller | Manages AppWrapper queueing, scheduling, and lifecycle |
| InstaScale Controller | Optional Embedded Controller | Auto-scales OpenShift MachineSets based on AppWrapper resource demands |
| Manager Deployment | Kubernetes Deployment | Single-replica operator deployment hosting both controllers |
| Metrics Service | ClusterIP Service | Exposes Prometheus metrics on port 8080 |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| workload.codeflare.dev | v1beta1 | AppWrapper | Namespaced | Wraps generic Kubernetes resources (Pods, Jobs, Deployments, RayClusters) with scheduling spec, priority, and quota management |
| quota.codeflare.dev | v1alpha1 | QuotaSubtree | Namespaced | Defines hierarchical quota trees for resource allocation across namespaces and workloads |
| workload.codeflare.dev | v1beta1 | SchedulingSpec | Namespaced | Standalone scheduling specification including requeuing strategy, dispatch duration, and node selectors |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint for controller metrics |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |

### gRPC Services

No gRPC services exposed.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Multi-Cluster App Dispatcher (MCAD) | v1.38.1 | Yes | Embedded queue controller for workload scheduling and dispatching |
| InstaScale | v0.3.1 | No | Embedded auto-scaler for OpenShift MachineSets (optional, disabled by default) |
| KubeRay Operator | v1.0.0-rc.0 | Yes | Creates and manages Ray clusters wrapped by AppWrappers |
| CodeFlare-SDK | v0.12.1 | No | Python SDK for users to create and manage CodeFlare resources |
| OpenShift Machine API | N/A | No | Required only when InstaScale is enabled for auto-scaling |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KubeRay | CRD (RayCluster) | MCAD creates/manages RayCluster resources within AppWrappers |
| OpenShift Ingress/Routes | API | MCAD creates Routes/Ingresses for Ray dashboard access |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| codeflare-operator-manager-metrics | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| N/A | N/A | N/A | N/A | N/A | N/A | N/A | None - No ingress configured for operator itself |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch/manage AppWrappers, Pods, Deployments, Jobs, Services |
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | InstaScale: manage Nodes, Machines, MachineSets (when enabled) |
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | MCAD: create/manage RayClusters, Routes, Ingresses |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | workload.codeflare.dev | appwrappers, appwrappers/finalizers, appwrappers/status, schedulingspecs | create, delete, deletecollection, get, list, patch, update, watch |
| manager-role | quota.codeflare.dev | quotasubtrees | create, delete, deletecollection, get, list, patch, update, watch |
| manager-role | "" (core) | pods, pods/status, services, configmaps, secrets, serviceaccounts, persistentvolumes, persistentvolumeclaims, nodes | create, delete, get, list, patch, update, watch |
| manager-role | "" (core) | pods/binding, bindings | create |
| manager-role | "" (core) | events | create, patch, update |
| manager-role | apps | deployments, replicasets, statefulsets | create, delete, get, list, patch, update, watch |
| manager-role | batch | jobs | create, delete, list, patch, update, watch |
| manager-role | coordination.k8s.io | leases | create, get, update |
| manager-role | scheduling.sigs.k8s.io | podgroups | create, delete, deletecollection, get, list, patch, update, watch |
| manager-role | config.openshift.io | clusterversions | get, list |
| instascale-role | "" (core) | nodes | get, list, patch, update |
| instascale-role | "" (core) | secrets | get |
| instascale-role | machine.openshift.io | machines, machinesets | create, delete, get, list, patch, update, watch |
| instascale-role | config.openshift.io | clusterversions | get, list, watch |
| mcad-controller-ray-clusterrole | ray.io | rayclusters, rayclusters/finalizers, rayclusters/status | create, delete, get, list, patch, update, watch |
| mcad-controller-ray-clusterrole | networking.k8s.io | ingresses | create, delete, get, list, patch, update, watch |
| mcad-controller-ray-clusterrole | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| leader-election-role | "" (core) | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| codeflare-operator-manager-rolebinding | opendatahub | manager-role (ClusterRole) | controller-manager |
| codeflare-operator-instascale-rolebinding | opendatahub | instascale-role (ClusterRole) | controller-manager |
| codeflare-operator-mcad-controller-ray-clusterrolebinding | opendatahub | mcad-controller-ray-clusterrole (ClusterRole) | controller-manager |
| codeflare-operator-leader-election-rolebinding | opendatahub | leader-election-role (ClusterRole) | controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| controller-manager-token | kubernetes.io/service-account-token | ServiceAccount token for API authentication | Kubernetes | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None | None | Internal network access only via ClusterIP |
| /healthz | GET | None | None | Internal network access for kubelet probes |
| /readyz | GET | None | None | Internal network access for kubelet probes |
| Kubernetes API | ALL | ServiceAccount Token (Bearer JWT) | Kubernetes API Server | RBAC policies enforced via ClusterRoles |

## Data Flows

### Flow 1: AppWrapper Creation and Scheduling

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CodeFlare-SDK | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | User credentials (Bearer Token) |
| 2 | Kubernetes API Server | MCAD Controller (watch) | N/A | Internal | N/A | N/A |
| 3 | MCAD Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | MCAD Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

**Description**: User creates AppWrapper CR → MCAD watches and queues it → MCAD checks resource availability → MCAD dispatches by creating wrapped resources (Pods, Jobs, RayClusters).

### Flow 2: InstaScale Auto-Scaling (When Enabled)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | InstaScale Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | InstaScale Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | InstaScale Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Machine API Operator | Cloud Provider API | 443/TCP | HTTPS | TLS 1.2+ | Cloud credentials |

**Description**: InstaScale watches pending AppWrappers → Calculates resource gap → Scales MachineSet replicas → Machine API provisions new nodes from cloud provider.

### Flow 3: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | manager-metrics service | 8080/TCP | HTTP | None | None |

**Description**: Prometheus scrapes controller metrics for monitoring AppWrapper queue depth, dispatch rate, and controller performance.

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | CRUD operations on AppWrappers, Pods, Jobs, Deployments, StatefulSets, Services |
| KubeRay Operator | CRD (RayCluster) | 6443/TCP | HTTPS | TLS 1.2+ | MCAD creates RayCluster resources for distributed Ray workloads |
| OpenShift Machine API | CRD (MachineSet) | 6443/TCP | HTTPS | TLS 1.2+ | InstaScale scales MachineSets to add/remove compute capacity |
| Prometheus | HTTP Metrics | 8080/TCP | HTTP | None | Scrapes controller metrics via ServiceMonitor |
| OpenShift Routes/Ingress | API | 6443/TCP | HTTPS | TLS 1.2+ | MCAD creates Routes for Ray dashboard external access |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| cff798d | 2024-01-26 | - Merged RHODS roles for admin and editor<br>- Added ClusterRoles for AppWrapper management by cluster admins |
| a6031fd | 2024-01-25 | - DROP: Add roles for admin and editor to operator |
| d4efdc5 | 2023-11-07 | - CARRY: Documentation for migrating from RHODS CFO to RHODS DSC |
| e6630c3 | 2023-11-22 | - Add Makefile and configuration files for e2e execution on OpenShift CI |
| b74652a | 2023-11-15 | - Remove CodeFlare notebook imagestream |
| 512e0d3 | 2023-11-03 | - Fix: Update image version |
| e88422d | 2023-10-30 | - Remove e2e and OLM upgrade tests |
| c9e9666 | 2023-10-25 | - Update manifests: use default namespace from ODH |
| ba2ddc3 | 2023-10-19 | - Replaced source repo for RHOAI fork |
| 0f42f1f | 2023-10-17 | - Added Sync Fork workflow for upstream synchronization |

## Configuration

### ConfigMap

The operator reads configuration from a ConfigMap named `codeflare-operator-config` in the operator namespace. If the ConfigMap does not exist, the operator creates it with default values.

**Key Configuration Options:**
- **clientConnection.qps**: API server QPS limit (default: 50)
- **clientConnection.burst**: API server burst limit (default: 100)
- **metrics.bindAddress**: Metrics server bind address (default: `:8080`)
- **health.bindAddress**: Health probe bind address (default: `:8081`)
- **instascale.enabled**: Enable/disable InstaScale controller (default: `false`)
- **instascale.maxScaleoutAllowed**: Maximum number of machines to scale out (default: 5)
- **leaderElection**: Leader election configuration for HA deployments

### Environment Variables

| Variable | Required | Purpose | Default |
|----------|----------|---------|---------|
| NAMESPACE | Yes | Operator namespace for leader election and config lookup | Set via downward API |

## Deployment Architecture

### Deployment Manifest Location

The kustomize deployment manifests are located in `config/` with the following structure:

- **config/default/**: Base deployment with CRDs, RBAC, manager, and metrics service
- **config/crd/**: CRD definitions (AppWrapper, QuotaSubtree, SchedulingSpec)
- **config/rbac/**: RBAC resources (ClusterRoles, ClusterRoleBindings, ServiceAccount)
- **config/manager/**: Operator Deployment manifest
- **config/prometheus/**: ServiceMonitor for Prometheus integration
- **config/odh-operator/**: Integration with OpenDataHub operator

### Container Image

Built using multi-stage Dockerfile:
- **Builder stage**: UBI8 Go toolset 1.20.10 with FIPS-compliant build
- **Runtime stage**: UBI8 minimal 8.8
- **User**: Runs as non-root user 65532:65532
- **Security**: Drops all capabilities, disables privilege escalation

### Resource Limits

| Container | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| manager | 1 core | 1 core | 1Gi | 1Gi |

## Monitoring & Observability

### Metrics Exposed

The operator exposes controller-runtime metrics on `/metrics` endpoint including:

- AppWrapper queue depth and state distribution
- Reconciliation duration and rate
- API client request metrics (QPS, errors, latency)
- Workqueue depth and processing latency
- Go runtime metrics (goroutines, memory, GC)

### Health Checks

- **Liveness**: `/healthz` on port 8081 - checks if controller manager is responsive
- **Readiness**: `/readyz` on port 8081 - checks if controller manager is ready to serve requests

### ServiceMonitor

When Prometheus operator is available, a ServiceMonitor resource enables automatic metrics discovery:
- **Path**: `/metrics`
- **Port**: `https` (note: config shows HTTPS but service uses HTTP on 8080)
- **Scheme**: HTTPS with insecureSkipVerify
- **Auth**: Bearer token from ServiceAccount

## Notes

- **MCAD Controller**: Embedded from multi-cluster-app-dispatcher v1.38.1, runs as a goroutine within the operator process
- **InstaScale**: Optional feature disabled by default; requires OpenShift Machine API for auto-scaling
- **Gang Scheduling**: AppWrappers support gang scheduling via `minAvailable` - all-or-nothing pod scheduling
- **Requeuing**: AppWrappers can be automatically requeued with exponential/linear backoff when resources are unavailable
- **Priority**: AppWrappers support priority-based scheduling with dynamic priority slopes
- **Quota Management**: QuotaSubtree enables hierarchical quota trees across namespaces
- **Ray Integration**: Primary workload type is Ray clusters for distributed AI/ML workloads
- **Migration**: This operator replaced an earlier RHODS-specific CodeFlare component, now integrated via DSC (DataScienceCluster)
