# Component: Notebook Controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kubeflow
- **Version**: v1.27.0-rhods-1295-g1a264972
- **Branch**: rhoai-2.25
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Manages lifecycle of Jupyter notebook instances in Kubernetes as custom resources.

**Detailed**: The Notebook Controller is a Kubernetes operator that enables users to create and manage Jupyter notebook servers through a declarative Notebook CRD. It translates Notebook custom resources into StatefulSets and Services, managing the full lifecycle including creation, updates, and deletion of notebook instances. The controller also provides optional notebook culling functionality to automatically stop idle notebooks based on kernel activity, helping optimize cluster resource utilization. When deployed with Istio service mesh, it automatically creates VirtualService resources for secure notebook access. The controller exposes Prometheus metrics for monitoring notebook creation, failures, and culling operations.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| NotebookReconciler | Controller | Reconciles Notebook CRDs to create/update StatefulSets and Services for notebook instances |
| CullingReconciler | Controller | Monitors notebook kernel activity and stops idle notebooks after configurable timeout period |
| Metrics Server | HTTP Endpoint | Exposes Prometheus metrics for notebook operations (creation, failures, culling) |
| Health Probe | HTTP Endpoint | Provides liveness and readiness health checks for the controller |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kubeflow.org | v1 | Notebook | Namespaced | Primary API for defining Jupyter notebook instances with PodSpec template |
| kubeflow.org | v1beta1 | Notebook | Namespaced | Beta API version with conversion webhook support for notebook instances |
| kubeflow.org | v1alpha1 | Notebook | Namespaced | Alpha API version for backward compatibility with older notebook definitions |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint for scraping notebook controller metrics |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint for Kubernetes health checks |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint for Kubernetes readiness checks |

### gRPC Services

None - This component does not expose gRPC services.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.22.0+ | Yes | Platform for running the operator and managed notebook workloads |
| Prometheus | - | No | Metrics collection for notebook operations monitoring |
| Istio Service Mesh | - | No | Optional integration for VirtualService creation and traffic management |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Istio Gateway | VirtualService CRD | Creates VirtualService resources when USE_ISTIO=true for notebook ingress routing |
| Kubeflow Dashboard | Notebook CRD | Consumed by dashboard UI for displaying and managing notebook instances |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| notebook-controller-service | ClusterIP | 443/TCP | - | HTTPS | TLS | None | Internal |
| notebook-{name} | ClusterIP | 80/TCP | 8888 | HTTP | None | None | Internal per-notebook service |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|----------|----------|----------|
| notebook-{name}-vs | Istio VirtualService | Configured via ISTIO_HOST | 80/TCP | HTTP | Varies | Varies | Conditional (USE_ISTIO=true) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Controller operations on notebooks, pods, services, statefulsets |
| Notebook Pod /api/kernels | 8888/TCP | HTTP | None | None | Culling controller queries kernel status for idle detection |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| notebook-controller-role | "" | events | create, get, list, patch, watch |
| notebook-controller-role | "" | pods | delete, get, list, watch |
| notebook-controller-role | "" | services | * |
| notebook-controller-role | apps | statefulsets | * |
| notebook-controller-role | kubeflow.org | notebooks, notebooks/finalizers, notebooks/status | * |
| notebook-controller-role | networking.istio.io | virtualservices | * |
| leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role | "" | configmaps/status | get, update, patch |
| kubeflow-notebooks-edit | kubeflow.org | notebooks, notebooks/status | get, list, watch, create, delete, deletecollection, patch, update |
| kubeflow-notebooks-view | kubeflow.org | notebooks, notebooks/status | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| notebook-controller-role-binding | All | notebook-controller-role | notebook-controller-service-account |
| leader-election-role-binding | Controller namespace | leader-election-role | notebook-controller-service-account |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| notebook-controller-webhook-cert | kubernetes.io/tls | Optional webhook TLS certificate for conversion webhooks | cert-manager or manual | Varies |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None | None | Cluster-internal access only via ClusterIP |
| /healthz, /readyz | GET | None | None | Cluster-internal access only via ClusterIP |
| Kubernetes API | GET, POST, PUT, PATCH, DELETE | ServiceAccount Token (JWT) | Kubernetes API Server | RBAC ClusterRole permissions |

## Data Flows

### Flow 1: Notebook Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Dashboard | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Kubernetes API Server | Notebook Controller | - | Watch | - | ServiceAccount Token |
| 3 | Notebook Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Kubernetes API Server | Kubelet | 10250/TCP | HTTPS | TLS 1.2+ | mTLS |

### Flow 2: Notebook Culling (Idle Detection)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Culling Controller | Notebook Pod | 8888/TCP | HTTP | None | None |
| 2 | Notebook Pod | Culling Controller | - | HTTP Response | None | None |
| 3 | Culling Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 3: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | Notebook Controller | 8080/TCP | HTTP | None | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Create/update/delete StatefulSets, Services, Pods; watch Notebook CRDs |
| Istio Pilot | VirtualService CRD | 6443/TCP | HTTPS | TLS 1.2+ | Create VirtualService resources for notebook ingress (when USE_ISTIO=true) |
| Prometheus | HTTP Metrics | 8080/TCP | HTTP | None | Export notebook creation, failure, and culling metrics |
| Jupyter Notebook Pods | HTTP API | 8888/TCP | HTTP | None | Query /api/kernels endpoint for kernel activity status during culling |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| v1.27.0-rhods-1295 | 2026-03-13 | - Update registry.access.redhat.com/ubi9/go-toolset:1.25 docker digest to 3cdf0d1<br>- Sync pipelineruns with konflux-central |
| v1.27.0-rhods-1293 | 2026-03-11 | - Update registry.access.redhat.com/ubi9/ubi-minimal docker digest to 69f5c98 |
| v1.27.0-rhods-1291 | 2026-03-10 | - Update registry.access.redhat.com/ubi9/go-toolset:1.25 docker digest to 6da1160 |
| v1.27.0-rhods-1289 | 2026-02-25 | - Bump golang version from 1.24 to 1.25 for RHOAI 2.25 |
| v1.27.0-rhods-1288 | 2026-02-20 | - Add govulncheck target to component Makefiles<br>- Update CI for vulnerability scanning |
| v1.27.0-rhods-1287 | 2026-02-18 | - Sync pipelineruns with konflux-central |
| v1.27.0-rhods-1286 | 2026-02-15 | - Update registry.access.redhat.com/ubi9/ubi-minimal docker digest to c7d4414 |
| v1.27.0-rhods-1285 | 2026-02-12 | - Sync pipelineruns with konflux-central |
| v1.27.0-rhods-1284 | 2026-02-10 | - Update registry.access.redhat.com/ubi9/ubi-minimal docker digest to 759f5f4 |
| v1.27.0-rhods-1283 | 2026-02-08 | - Update registry.access.redhat.com/ubi9/ubi-minimal docker digest to ecd4751 |

## Configuration

### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| USE_ISTIO | false | Enable Istio VirtualService creation for notebook instances |
| ISTIO_GATEWAY | - | Istio Gateway name to use in VirtualService specs |
| ISTIO_HOST | - | Host pattern for VirtualService routing rules |
| ENABLE_CULLING | false | Enable automatic culling of idle notebook instances |
| CULL_IDLE_TIME | 1440 | Minutes of inactivity before notebook is stopped (default: 1 day) |
| IDLENESS_CHECK_PERIOD | 1 | Minutes between idle checks for notebook culling |
| ADD_FSGROUP | true | Add fsGroup: 100 to notebook pod security context |
| DEV | false | Enable developer mode for local controller execution |

### Command-Line Parameters

| Parameter | Default | Purpose |
|-----------|---------|---------|
| --metrics-addr | :8080 | Address for Prometheus metrics endpoint |
| --probe-addr | :8081 | Address for health and readiness probes |
| --enable-leader-election | false | Enable leader election for high availability |
| --leader-election-namespace | - | Namespace for leader election ConfigMap |
| --burst | 0 | Kubernetes API client burst limit (0 = default) |
| --qps | 0 | Kubernetes API client QPS limit (0 = default) |

## Deployment Details

### Container Image

**Built with**: Konflux CI/CD
**Base Image**: registry.access.redhat.com/ubi9/ubi-minimal:latest
**Build Image**: registry.access.redhat.com/ubi9/go-toolset:1.25
**Build Type**: CGO_ENABLED=1 with strictfipsruntime for FIPS compliance
**User**: 1001 (non-root)

### Resource Management

The controller does not specify default resource requests/limits in manifests. These are typically configured via kustomize overlays or at deployment time based on cluster size and notebook workload requirements.

### High Availability

- Supports leader election via `--enable-leader-election` flag
- Only one active controller reconciles resources at a time
- Leader election uses ConfigMap in controller namespace
- Rolling update strategy: maxUnavailable 100%, maxSurge 0

## Operational Notes

### Reconciliation Logic

1. **Notebook CR Created/Updated**:
   - Validates notebook name length (max 52 chars for StatefulSet compatibility)
   - Creates or updates StatefulSet with pod template from Notebook spec
   - Creates or updates ClusterIP Service targeting StatefulSet pods
   - Creates VirtualService if USE_ISTIO=true
   - Updates Notebook status with ready replicas and container state

2. **Culling Logic** (when ENABLE_CULLING=true):
   - Checks notebook pods every IDLENESS_CHECK_PERIOD
   - Queries /api/kernels endpoint for kernel last_activity timestamps
   - Marks notebook for culling if idle longer than CULL_IDLE_TIME
   - Adds `kubeflow-resource-stopped` annotation to stop notebook
   - NotebookReconciler reduces StatefulSet replicas to 0 when annotation present

3. **Event Handling**:
   - Re-emits Pod/StatefulSet events on Notebook CR for visibility
   - Updates Notebook status based on underlying resource conditions

### Annotations

| Annotation | Purpose |
|------------|---------|
| notebooks.kubeflow.org/http-rewrite-uri | URI rewrite configuration for notebook routing |
| notebooks.kubeflow.org/http-headers-request-set | HTTP header injection for notebook requests |
| notebooks.opendatahub.io/notebook-restart | Triggers notebook pod restart when set to "true" |
| kubeflow-resource-stopped | Marks notebook for culling (added by CullingReconciler) |
| notebooks.kubeflow.org/last-activity | Timestamp of last notebook kernel activity |
| notebooks.kubeflow.org/last_activity_check_timestamp | Timestamp of last culling check |

### Labels

| Label | Purpose |
|-------|---------|
| notebook-name | Links StatefulSet to parent Notebook CR |
| app=notebook-controller | Selector for controller deployment |
| kustomize.component=notebook-controller | Kustomization tracking |
| app.kubernetes.io/part-of=odh-notebook-controller | ODH component grouping |
| component.opendatahub.io/name=kf-notebook-controller | ODH component identification |
| opendatahub.io/workbenches | Marks workbench notebook instances |

## Known Limitations

1. **StatefulSet Name Length**: Notebook names limited to 52 characters due to Kubernetes StatefulSet naming constraints
2. **Culling Authentication**: Culling feature requires unauthenticated access to /api/kernels endpoint on notebook pods
3. **No TLS for Metrics**: Metrics endpoint exposed over unencrypted HTTP (relies on network policies for security)
4. **Single Container**: Notebook CRD spec requires exactly one container (containers[0]) to be specified
5. **No Built-in Backup**: Notebook data persistence depends on user-configured PersistentVolumeClaims in pod spec
