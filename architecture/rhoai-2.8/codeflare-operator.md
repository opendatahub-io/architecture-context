# Component: CodeFlare Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/codeflare-operator.git
- **Version**: rhoai-2.8 (commit c7e38f8)
- **Distribution**: RHOAI
- **Languages**: Go 1.21
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Manages lifecycle of MCAD and InstaScale for distributed ML workload scheduling and auto-scaling.

**Detailed**: The CodeFlare Operator is a Kubernetes operator that provides lifecycle management for distributed workload orchestration components in Red Hat OpenShift AI. It manages two primary controllers: Multi-Cluster App Dispatcher (MCAD) for batch job queuing and scheduling, and InstaScale for automatic cluster scaling based on workload demand. The operator enables data scientists to submit distributed training jobs wrapped in AppWrapper resources, which are then queued, scheduled, and auto-scaled according to resource availability and quota policies. It integrates with KubeRay to support Ray-based distributed computing workloads and manages hierarchical quota allocation through QuotaSubtree resources.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Manager | Deployment | Main operator controller running MCAD and InstaScale reconcilers |
| MCAD Controller | In-process | Multi-Cluster App Dispatcher for batch job queuing and scheduling |
| InstaScale Controller | In-process | Auto-scaling controller for machine pools and node pools (optional) |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| workload.codeflare.dev | v1beta1 | AppWrapper | Namespaced | Wraps Kubernetes resources (Jobs, RayClusters, etc.) for batch scheduling with priority and quota management |
| quota.codeflare.dev | v1alpha1 | QuotaSubtree | Namespaced | Defines hierarchical quota trees for managing resource allocation across teams/projects |
| workload.codeflare.dev | v1beta1 | SchedulingSpec | Namespaced | Specifies scheduling parameters including requeuing strategy and dispatch duration limits |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for operator and MCAD queue statistics |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |

### gRPC Services

No gRPC services exposed.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Multi-Cluster App Dispatcher | v1.40.0 | Yes | Batch job scheduling and queue management |
| InstaScale | v0.4.0 | No | Auto-scaling for compute resources (optional, platform-dependent) |
| KubeRay | v1.0.0 | No | Ray cluster management for distributed workloads |
| Kubernetes | v1.27.x | Yes | Core platform APIs |
| controller-runtime | v0.15.3 | Yes | Operator framework |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KubeRay Operator | CRD (ray.io/rayclusters) | Watches and manages RayCluster resources wrapped in AppWrappers |
| Prometheus | ServiceMonitor | Exports metrics for monitoring MCAD queue depth and job states |
| OpenShift Machine API | CRD (machine.openshift.io) | InstaScale creates/deletes MachineSets for auto-scaling compute |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| manager-metrics | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |

### Ingress

No ingress resources managed by this operator.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch and reconcile AppWrapper, QuotaSubtree, Pod, Deployment resources |
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Create/delete MachineSets for InstaScale auto-scaling |
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Manage RayCluster, Ingress, Route resources for MCAD workloads |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | workload.codeflare.dev | appwrappers, appwrappers/finalizers, appwrappers/status, schedulingspecs | create, delete, deletecollection, get, list, patch, update, watch |
| manager-role | quota.codeflare.dev | quotasubtrees | create, delete, deletecollection, get, list, patch, update, watch |
| manager-role | "" | pods, pods/status, pods/binding | create, delete, deletecollection, get, list, patch, update, watch |
| manager-role | "" | configmaps, secrets, services, serviceaccounts, persistentvolumes, persistentvolumeclaims, nodes | create, delete, get, list, patch, update, watch |
| manager-role | apps | deployments, replicasets, statefulsets | create, delete, get, list, patch, update, watch |
| manager-role | batch | jobs | create, delete, list, patch, update, watch |
| manager-role | scheduling.sigs.k8s.io | podgroups | create, delete, deletecollection, get, list, patch, update, watch |
| manager-role | coordination.k8s.io | leases | create, get, update |
| manager-role | config.openshift.io | clusterversions | get, list |
| instascale-role | "" | nodes | get, list, patch, update |
| instascale-role | "" | secrets | get |
| instascale-role | machine.openshift.io | machines, machinesets | create, delete, get, list, patch, update, watch |
| instascale-role | config.openshift.io | clusterversions | get, list, watch |
| mcad-controller-ray-clusterrole | ray.io | rayclusters, rayclusters/finalizers, rayclusters/status | create, delete, get, list, patch, update, watch |
| mcad-controller-ray-clusterrole | networking.k8s.io | ingresses | create, delete, get, list, patch, update, watch |
| mcad-controller-ray-clusterrole | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| leader-election-role | "" | events | create, patch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| role-binding | opendatahub | manager-role (ClusterRole) | controller-manager |
| instascale-role-binding | opendatahub | instascale-role (ClusterRole) | controller-manager |
| mcad-controller-ray-clusterrolebinding | opendatahub | mcad-controller-ray-clusterrole (ClusterRole) | controller-manager |
| leader-election-role-binding | opendatahub | leader-election-role (Role) | controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| controller-manager-token | kubernetes.io/service-account-token | ServiceAccount token for Kubernetes API authentication | Kubernetes | Yes |
| codeflare-operator-config | ConfigMap | Operator configuration (MCAD, InstaScale settings) | Operator | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None | None | Open for Prometheus scraping |
| /healthz | GET | None | None | Open for kubelet probes |
| /readyz | GET | None | None | Open for kubelet probes |
| Kubernetes API | ALL | ServiceAccount Token (JWT) | Kubernetes API Server | RBAC ClusterRoles/Bindings |

## Data Flows

### Flow 1: AppWrapper Submission and Scheduling

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/SDK | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Kubernetes API | Manager (MCAD) | N/A | Watch | N/A | ServiceAccount Token |
| 3 | Manager (MCAD) | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

**Description**: User creates AppWrapper CR → MCAD controller watches AppWrapper → MCAD queues job, checks quotas, schedules when resources available → Creates wrapped resources (Pods, Jobs, RayClusters).

### Flow 2: InstaScale Auto-Scaling (OpenShift only)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Manager (MCAD) | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Kubernetes API | Manager (InstaScale) | N/A | Watch | N/A | ServiceAccount Token |
| 3 | Manager (InstaScale) | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

**Description**: AppWrapper queued with unmet resources → InstaScale watches AppWrapper status → Scales up MachineSets/MachinePools → New nodes join cluster → MCAD schedules AppWrapper.

### Flow 3: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | manager-metrics Service | 8080/TCP | HTTP | None | Bearer Token |

**Description**: Prometheus scrapes /metrics endpoint → Collects MCAD queue metrics, AppWrapper counts, and controller runtime metrics.

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Watch and reconcile CRDs, manage pods, deployments, services |
| KubeRay Operator | CRD Watch | 6443/TCP | HTTPS | TLS 1.2+ | Manage RayCluster lifecycle through AppWrappers |
| OpenShift Machine API | CRD Watch | 6443/TCP | HTTPS | TLS 1.2+ | Auto-scale compute via MachineSet creation/deletion |
| Prometheus | HTTP Scrape | 8080/TCP | HTTP | None | Export metrics for monitoring and alerting |
| CodeFlare SDK | Kubernetes Client | 6443/TCP | HTTPS | TLS 1.2+ | Python SDK creates AppWrapper CRs for distributed jobs |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| c7e38f8 | 2024 | - Update Konflux references<br>- Update UBI8 base images<br>- Update registry.access.redhat.com/ubi8/ubi-minimal digest<br>- Update Go toolset to 1.21 |
| e8983c1 | 2024 | - Update Konflux pipeline references |
| 3e51c65 | 2024 | - Update Konflux references |
| 48cbeb6 | 2024 | - Update Konflux references |
| 5a858f7 | 2024 | - Update registry.access.redhat.com/ubi8/ubi-minimal Docker digest to 43dde01 |

**Note**: Recent commits focus on build infrastructure updates (Konflux CI/CD) and base image security updates. No major functional changes in recent history.

## Deployment Configuration

### Kustomize Structure

The operator uses Kustomize for deployment with the following overlays:

- **config/default**: Base deployment (namespace: opendatahub)
- **config/manager**: Operator deployment manifest
- **config/rbac**: RBAC rules for manager, InstaScale, and MCAD
- **config/crd**: Custom Resource Definitions
- **config/prometheus**: ServiceMonitor for metrics
- **config/e2e**: End-to-end test configuration

### Resource Requirements

| Resource | Requests | Limits |
|----------|----------|--------|
| CPU | 1 core | 1 core |
| Memory | 1Gi | 1Gi |

### Container Image

Built using **Dockerfile.konflux** (RHOAI production builds):
- Base: registry.access.redhat.com/ubi8/go-toolset:1.21
- Runtime: registry.access.redhat.com/ubi8/ubi-minimal
- User: 65532 (non-root)
- FIPS-compliant build: `-tags strictfipsruntime`

## Operational Notes

### InstaScale Platform Support

InstaScale is **optional** and only enabled on supported platforms:
- **OpenShift**: Enabled by default (uses Machine API)
- **Other Kubernetes**: Disabled (no Machine API available)

Configuration via ConfigMap `codeflare-operator-config`:
```yaml
instascale:
  enabled: true/false
  maxScaleoutAllowed: 5  # Max concurrent machine scale-ups
```

### MCAD Queue Configuration

MCAD controller runs embedded in the operator with configurable parameters:
- Queue scheduling policies (FIFO, Priority-based)
- Quota enforcement mechanisms
- Dispatch duration limits
- Requeuing strategies (exponential, linear, none)

### Health and Monitoring

- **Liveness Probe**: `/healthz` on port 8081 (checks every 20s, initial delay 15s)
- **Readiness Probe**: `/readyz` on port 8081 (checks every 10s, initial delay 5s)
- **Metrics**: Prometheus metrics on port 8080 (queue depth, job states, reconciliation latency)
