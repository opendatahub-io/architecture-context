# Component: Notebook Controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kubeflow.git
- **Version**: v-2160-150-g6dfa5610
- **Branch**: rhoai-2.16
- **Distribution**: RHOAI
- **Languages**: Go 1.25.7
- **Deployment Type**: Kubernetes Operator (Kubebuilder-based)
- **Component Path**: components/notebook-controller
- **Manifests**: components/notebook-controller/config (overlays: openshift, service-mesh, kubeflow, standalone)

## Purpose
**Short**: Manages Jupyter notebook server lifecycle as Kubernetes custom resources.

**Detailed**: The Notebook Controller is a Kubernetes operator that enables users to create and manage Jupyter notebook servers declaratively using the Notebook CRD (Custom Resource Definition). When a user creates a Notebook resource, the controller automatically provisions the underlying infrastructure including a StatefulSet for the notebook pod, a ClusterIP Service for network access, and optionally an Istio VirtualService for service mesh integration. The controller also provides intelligent idle notebook culling to optimize resource usage, automatically stopping notebooks that have been idle for a configurable period. Built with Kubebuilder, it supports multiple API versions (v1, v1alpha1, v1beta1) and integrates with OpenShift and Istio service mesh for production deployments in the Red Hat OpenShift AI platform.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| NotebookReconciler | Controller | Main reconciliation loop that creates/updates StatefulSets and Services for Notebook CRs |
| CullingReconciler | Controller | Monitors notebook activity and culls idle notebooks to save resources |
| Notebook CRD | API | Defines the Notebook custom resource with PodSpec template |
| StatefulSet Generator | Logic | Creates StatefulSet resources from Notebook specs with proper labels and annotations |
| Service Generator | Logic | Creates ClusterIP Services for notebook network access |
| VirtualService Generator | Logic | Creates Istio VirtualService resources for service mesh integration (when USE_ISTIO=true) |
| Metrics Collector | Component | Prometheus metrics for notebook creation, failures, and culling events |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kubeflow.org | v1 | Notebook | Namespaced | Storage version - defines Jupyter notebook instances with PodSpec template |
| kubeflow.org | v1alpha1 | Notebook | Namespaced | Legacy version - supports conversion to v1 |
| kubeflow.org | v1beta1 | Notebook | Namespaced | Beta version with webhook support - supports conversion to v1 |

**Notebook Spec Fields**:
- `template.spec`: PodSpec defining the notebook container image, resources, and configuration
- Required fields: `containers[0].image` and (`containers[0].command` or `containers[0].args`)

**Notebook Status Fields**:
- `conditions`: Array of current conditions (Running/Waiting/Terminated)
- `readyReplicas`: Number of ready pods created by the StatefulSet
- `containerState`: State of underlying container

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics scraping endpoint |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe for controller health |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe for controller startup |
| /api/kernels | GET | 8888/TCP | HTTP | None | Service Mesh | Jupyter kernel status API for culling checks (on notebook pods) |

### gRPC Services

No gRPC services exposed.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | v1.22.0+ | Yes | Platform for running the operator and notebook workloads |
| controller-runtime | v0.17.0 | Yes | Kubebuilder framework for operator logic |
| Istio | v1alpha3 API | No | Service mesh integration for VirtualService resources |
| Prometheus | client_golang v1.18.0 | Yes | Metrics collection and exposure |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| kubeflow/common | Go module import | Shared reconciliation helper utilities |
| Istio Gateway | VirtualService reference | Routes external traffic to notebook services (when USE_ISTIO=true) |
| ConfigMap (config) | Environment variables | Configuration for USE_ISTIO, ISTIO_GATEWAY, ISTIO_HOST, ADD_FSGROUP |
| ConfigMap (notebook-controller-culler-config) | Environment variables | Configuration for ENABLE_CULLING, CULL_IDLE_TIME, IDLENESS_CHECK_PERIOD |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| notebook-controller-service | ClusterIP | 443/TCP | 443 | HTTPS | TLS (webhook) | mTLS (service mesh) | Internal |
| notebook-controller-service (metrics) | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |
| {notebook-name} (generated) | ClusterIP | 80/TCP | 8888 | HTTP | None | Service Mesh | Internal |

**Note**: For each Notebook CR created, the controller generates a Service named after the notebook with port 80 (serving port) mapping to the container's port (default 8888).

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| notebook-{namespace}-{name} | Istio VirtualService | ISTIO_HOST (configurable, default: *) | 80/TCP | HTTP | TLS 1.2+ (at gateway) | SIMPLE | External (via Istio Gateway) |

**VirtualService Configuration** (when USE_ISTIO=true):
- API Version: networking.istio.io/v1alpha3
- Gateway: ISTIO_GATEWAY (default: kubeflow/kubeflow-gateway)
- Path rewrite: Configured via `notebooks.kubeflow.org/http-rewrite-uri` annotation
- Headers: Configured via `notebooks.kubeflow.org/http-headers-request-set` annotation

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch and reconcile Notebook, StatefulSet, Service, Pod, Event resources |
| Notebook Pods | 8888/TCP | HTTP | None | None | Culling controller checks /api/kernels endpoint for activity |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| notebook-controller-role | "" (core) | events | create, get, list, patch, watch |
| notebook-controller-role | "" (core) | pods | delete, get, list, watch |
| notebook-controller-role | "" (core) | services | * (all) |
| notebook-controller-role | apps | statefulsets | * (all) |
| notebook-controller-role | kubeflow.org | notebooks, notebooks/finalizers, notebooks/status | * (all) |
| notebook-controller-role | networking.istio.io | virtualservices | * (all) |
| notebook-controller-leader-election-role | "" (core) | configmaps, configmaps/status | get, list, watch, create, update, patch, delete |
| notebook-controller-leader-election-role | "" (core) | events | create |
| kubeflow-notebooks-edit | kubeflow.org | notebooks, notebooks/status | get, list, watch, create, delete, deletecollection, patch, update |
| kubeflow-notebooks-view | kubeflow.org | notebooks, notebooks/status | get, list, watch |
| kubeflow-notebooks-admin | kubeflow.org | (aggregated role) | (aggregates kubeflow-notebooks-edit) |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| notebook-controller-role-binding | (cluster-wide) | notebook-controller-role (ClusterRole) | notebook-controller-service-account |
| notebook-controller-leader-election-role-binding | notebook-controller-system | notebook-controller-leader-election-role (Role) | notebook-controller-service-account |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| notebook-controller-webhook-cert | kubernetes.io/tls | TLS certificate for webhook server (when enabled) | cert-manager | Yes |
| (generated per notebook) | Opaque | Pulled from user namespace based on PodSpec | User/Admin | No |

**Note**: Notebook pods inherit secrets specified in their PodSpec template. The controller does not provision secrets directly.

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics (controller) | GET | None | N/A | Open for Prometheus scraping |
| /healthz, /readyz | GET | None | N/A | Open for kubelet probes |
| Kubernetes API | GET, LIST, WATCH, CREATE, UPDATE, PATCH, DELETE | ServiceAccount Token (JWT) | API Server | RBAC policies via ClusterRole |
| /api/kernels (notebook pods) | GET | None (in dev), mTLS (service mesh) | Istio AuthorizationPolicy | Culling controller granted access via policy |

## Data Flows

### Flow 1: Notebook Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/API | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | User credentials (OIDC/cert) |
| 2 | Kubernetes API | NotebookReconciler (watch event) | N/A | Internal | N/A | ServiceAccount token |
| 3 | NotebookReconciler | Kubernetes API Server (create StatefulSet) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 4 | NotebookReconciler | Kubernetes API Server (create Service) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 5 | NotebookReconciler | Kubernetes API Server (create VirtualService) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token (if USE_ISTIO=true) |

### Flow 2: Idle Notebook Culling

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | CullingReconciler | Kubernetes API Server (list Notebooks) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 2 | CullingReconciler | Notebook Pod Service | 80/TCP | HTTP | None (mTLS if service mesh) | mTLS client cert (service mesh) |
| 3 | Notebook Pod Service | Notebook Pod | 8888/TCP | HTTP | None | None |
| 4 | Notebook Pod | CullingReconciler (kernel status response) | N/A | HTTP response | None | None |
| 5 | CullingReconciler | Kubernetes API Server (update Notebook annotation) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |

### Flow 3: Metrics Scraping

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | notebook-controller-service | 8080/TCP | HTTP | None | None |
| 2 | Controller | Kubernetes API Server (list StatefulSets) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 3 | Controller | Prometheus (metrics response) | N/A | HTTP response | None | None |

### Flow 4: External User Access to Notebook

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | Istio Ingress Gateway | 443/TCP | HTTPS | TLS 1.3 | User session (OAuth2/OIDC) |
| 2 | Istio Gateway | VirtualService routing | N/A | Internal | mTLS | Service mesh mTLS |
| 3 | VirtualService | Notebook Service | 80/TCP | HTTP | mTLS | Service mesh mTLS |
| 4 | Notebook Service | Notebook Pod | 8888/TCP | HTTP | None | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API (client-go) | 6443/TCP | HTTPS | TLS 1.2+ | Watch/manage Notebook, StatefulSet, Service, Pod, Event resources |
| Prometheus | HTTP scrape | 8080/TCP | HTTP | None | Metrics collection for notebook lifecycle events |
| Istio Pilot | xDS API | N/A | gRPC | mTLS | VirtualService configuration sync (when USE_ISTIO=true) |
| Notebook Pods | HTTP API | 8888/TCP | HTTP | None (mTLS via mesh) | Kernel activity monitoring for culling |
| ConfigMaps | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Read configuration for Istio and culling settings |

## Configuration

### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| USE_ISTIO | false | Enable Istio VirtualService creation for notebooks |
| ISTIO_GATEWAY | kubeflow/kubeflow-gateway | Istio Gateway reference for VirtualServices |
| ISTIO_HOST | * | Host header for VirtualService routing |
| ENABLE_CULLING | false | Enable automatic culling of idle notebooks |
| CULL_IDLE_TIME | 1440 (minutes) | Time in minutes before an idle notebook is culled (default: 1 day) |
| IDLENESS_CHECK_PERIOD | 1 (minute) | Frequency of idleness checks in minutes |
| ADD_FSGROUP | true | Add fsGroup: 100 to pod security context (set to false for OpenShift) |
| DEV | false | Development mode for local testing |

### Command-line Flags

| Flag | Default | Purpose |
|------|---------|---------|
| --metrics-addr | :8080 | Address for metrics endpoint |
| --probe-addr | :8081 | Address for health/readiness probes |
| --enable-leader-election | false | Enable leader election for HA deployments |
| --leader-election-namespace | (empty) | Namespace for leader election ConfigMap |
| --burst | 0 | Kubernetes client burst (0 = default) |
| --qps | 0 | Kubernetes client QPS (0 = default) |

### Resource Limits (OpenShift Overlay)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 500m | 500m |
| Memory | 256Mi | 4Gi |

## Deployment Variants

### OpenShift Overlay
- Path: `config/overlays/openshift`
- Sets `ADD_FSGROUP=false` (OpenShift handles fsGroup via SCC)
- Sets `USE_ISTIO=false`
- Adds component labels: `app.kubernetes.io/part-of: odh-notebook-controller`, `component.opendatahub.io/name: kf-notebook-controller`
- Removes namespace from manifests (managed by operator)
- Resource limits configured

### Service Mesh Overlay
- Path: `config/overlays/service-mesh`
- Extends OpenShift overlay
- Loads Istio configuration from `ossm.env` ConfigMap

### Kubeflow Overlay
- Path: `config/overlays/kubeflow`
- Vanilla Kubeflow deployment
- Removes namespace patch

### Standalone Overlay
- Path: `config/overlays/standalone`
- Minimal standalone deployment

## Monitoring & Observability

### Prometheus Metrics

| Metric Name | Type | Labels | Description |
|-------------|------|--------|-------------|
| notebook_running | Gauge | namespace | Current number of running notebooks in the cluster |
| notebook_create_total | Counter | namespace | Total number of notebook creation events |
| notebook_create_failed_total | Counter | namespace | Total number of failed notebook creations |
| notebook_culling_total | Counter | namespace, name | Total number of notebook culling events |
| last_notebook_culling_timestamp_seconds | Gauge | namespace, name | Unix timestamp of last notebook culling event |

### Health Probes

| Probe | Endpoint | Port | Initial Delay | Period |
|-------|----------|------|---------------|--------|
| Liveness | /healthz | 8081/TCP | 5s | 10s |
| Readiness | /readyz | 8081/TCP | 5s | 10s |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| v-2160-150-g6dfa5610 | 2025-01-16 | - Enforce minimum Go version 1.25.7<br>- Update UBI8 base images to latest digests<br>- Update ose-oauth-proxy image (RHOAIENG-31065) |
| (6b37bc23) | 2025-01-15 | - Update go-toolset:1.25 to e20b9b4 digest |
| (6034842d, 857a96d5) | 2025-01-10 | - Update go-toolset:1.25 to 10bd7b9 digest |
| (dfb54590) | 2024-12-20 | - Update ubi-minimal to b880e16 digest |
| (476d1fd3, 2a16cd7f) | 2024-12-18 | - Patch outdated ose-oauth-proxy image for 2.16 release |
| (6303d70c, 5e92fd62) | 2024-12-15 | - Update go-toolset and ubi-minimal base images |
| (12d87f03, 40cc6340) | 2024-12-10 | - Dependency updates for UBI base images |
| (efb6ebe1, 42995074) | 2024-12-05 | - Update go-toolset and ubi-minimal digests |
| (12629606) | 2024-11-28 | - Update go-toolset:1.25 digest |
| (f281c5a5, 2443036b) | 2024-11-25 | - Add PR template<br>- Sync PipelineRuns with konflux-central |
| (ee31c705) | 2024-11-20 | - Add PipelineRun configuration for odh-notebook-controller and odh-kf-notebook-controller for rhoai-2.16 |
| (0ae7f9bf, 9a926e9a, a8e6c578) | 2024-11-15 | - Multiple ubi-minimal dependency updates |

## Build & Container

### Dockerfile.konflux (Primary Build)
- Base image: `registry.access.redhat.com/ubi8/go-toolset:1.25@sha256:e20b9b4796b727680ad135a060706c1ac47c59dd49302efeb7d7202b0c130986`
- Runtime image: `registry.access.redhat.com/ubi8/ubi-minimal@sha256:b880e16b888f47bc3fae64e67cd9776b24372f2e7ec2051f5a9386de6f5a75ac`
- Build flags: `CGO_ENABLED=1 GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH} -tags strictfipsruntime`
- Binary location: `/manager`
- User: UID 1001 (non-root)
- Labels: `com.redhat.component=odh-notebook-controller-container`

### Image Variants
- **odh-notebook-controller**: RHOAI-specific notebook controller
- **odh-kf-notebook-controller**: Kubeflow-compatible notebook controller for RHOAI

Both variants are built from the same source with different PipelineRun configurations in Konflux.

## Known Limitations & Future Work

### Current Limitations
1. Webhook support is disabled by default (commented out in main.go and kustomization)
2. Conversion between CRD versions (v1alpha1, v1beta1, v1) is supported but not actively used
3. Status field does not fully reflect errors (tracked in kubeflow/kubeflow#2269)
4. Culling checks require HTTP access to notebook pods (not suitable for all network policies)

### Future Enhancements (from TODO)
- Complete e2e test coverage
- Full error reporting in Notebook status field
- Enhanced Istio integration with automatic AuthorizationPolicy generation
- Webhook validation for CRD changes
- ttlSecondsAfterFinished support for automatic cleanup
- Improved local development tooling

## Testing

### Unit Tests
- Location: `controllers/*_test.go`
- Framework: Ginkgo + Gomega
- Run: `make test`

### BDD Tests
- Location: `controllers/notebook_controller_bdd_test.go`
- Covers reconciliation scenarios

### Load Tests
- Location: `loadtest/`
- For performance validation

## Additional Resources

- **Developer Guide**: `components/notebook-controller/developer_guide.md`
- **Kubebuilder Docs**: https://book.kubebuilder.io/
- **Kubeflow Notebooks**: https://www.kubeflow.org/docs/components/notebooks/
- **RHOAI Documentation**: https://access.redhat.com/documentation/en-us/red_hat_openshift_ai/

---

**Generated**: 2026-03-16
**Generator**: Claude Code Architecture Analysis
**Component**: notebook-controller (RHOAI 2.16)
