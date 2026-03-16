# Component: Notebook Controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kubeflow.git
- **Version**: v1.27.0-rhods-1345-gec07741f
- **Branch**: rhoai-3.0
- **Distribution**: RHOAI
- **Languages**: Go (1.24.3+)
- **Deployment Type**: Kubernetes Operator (Controller)
- **Build System**: Konflux (FIPS-compliant)

## Purpose
**Short**: Manages Jupyter Notebook lifecycle as StatefulSets in Kubernetes via custom resources.

**Detailed**: The Notebook Controller is a Kubernetes operator built with Kubebuilder that enables users to create and manage Jupyter notebook instances declaratively through a custom resource called "Notebook". When a Notebook CR is created, the controller automatically provisions a StatefulSet to run the notebook instance and a corresponding Service to expose it. The controller supports advanced features like idle notebook culling to optimize resource utilization, automatic pod restart on ConfigMap updates, and Istio VirtualService integration for service mesh routing. It maintains continuous reconciliation to ensure the actual state matches the desired state defined in the Notebook CR, handling StatefulSet updates, status synchronization, and event propagation. The controller exposes Prometheus metrics for observability and includes health/readiness probes for reliability in production deployments.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| NotebookReconciler | Controller | Main reconciliation loop that watches Notebook CRs and manages StatefulSet/Service lifecycle |
| CullingReconciler | Controller | Optional controller that monitors notebook idle time and culls inactive notebooks to save resources |
| Notebook CRD | API | Custom resource definition for kubeflow.org/v1 Notebook kind with PodSpec template |
| Metrics Collector | Exporter | Prometheus metrics for notebook creation, failures, culling events, and running notebook counts |
| Health/Readiness Probes | HTTP Endpoints | /healthz and /readyz endpoints on port 8081 for Kubernetes liveness/readiness checks |
| VirtualService Generator | Istio Integration | Creates Istio VirtualService resources when USE_ISTIO=true for ingress routing |
| Event Recorder | Event Emitter | Propagates Pod/StatefulSet events to parent Notebook CR for visibility |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kubeflow.org | v1 (storage version) | Notebook | Namespaced | Defines Jupyter notebook instances with PodSpec template and status tracking |
| kubeflow.org | v1beta1 | Notebook | Namespaced | Legacy API version for backward compatibility |
| kubeflow.org | v1alpha1 | Notebook | Namespaced | Alpha API version for backward compatibility |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint for monitoring notebook lifecycle and culling |
| /healthz | GET | 8081/TCP | HTTP | None | None | Kubernetes liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Kubernetes readiness probe endpoint |
| /api/kernels | GET | 8888/TCP | HTTP | None | Bearer/AuthorizationPolicy | Jupyter kernel status API (polled by culler for idle detection) |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | No gRPC services exposed |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | v1.22.0+ | Yes | Target platform for operator deployment and CRD management |
| controller-runtime | v0.21.0 | Yes | Kubernetes controller framework for reconciliation and caching |
| Istio | v1.x (optional) | No | Service mesh integration for VirtualService routing when USE_ISTIO=true |
| Prometheus | v2.x | No | Metrics collection and alerting (metrics exposed but scraping optional) |
| kube-rbac-proxy | latest (optional) | No | Optional auth proxy for securing /metrics endpoint with RBAC |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| odh-notebook-controller | CRD Extension | ODH-specific notebook controller annotations (notebooks.opendatahub.io/notebook-restart) |
| jupyter-web-app | CRD Consumer | Creates Notebook CRs based on user requests from UI |
| odh-dashboard | Status Monitoring | Displays Notebook CR status and conditions in ODH dashboard |
| notebook-images | Container Images | Provides base Jupyter notebook container images referenced in Notebook spec |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| notebook-controller-service | ClusterIP | 443/TCP | 443 | HTTPS | TLS 1.2+ | None | Internal |
| notebook-controller-controller-manager-metrics-service | ClusterIP | 8443/TCP | https | HTTPS | TLS 1.2+ | TokenReview/SubjectAccessReview | Internal |
| <notebook-name>-<hash> | ClusterIP | 80/TCP | 8888 | HTTP | None | None | Internal (per notebook) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| <notebook-name>-vs | Istio VirtualService | ${ISTIO_HOST} | 80/TCP | HTTP | None | N/A | External (when USE_ISTIO=true) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch Notebook/Pod/StatefulSet/Service resources for reconciliation |
| Notebook Pods | 8888/TCP | HTTP | None | None | Poll /api/kernels endpoint for idle detection during culling |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| notebook-controller-role | "" | pods | get, list, watch, delete |
| notebook-controller-role | "" | services | * (all) |
| notebook-controller-role | "" | events | get, list, watch, create, patch |
| notebook-controller-role | apps | statefulsets | * (all) |
| notebook-controller-role | kubeflow.org | notebooks, notebooks/status, notebooks/finalizers | * (all) |
| notebook-controller-role | networking.istio.io | virtualservices | * (all) |
| notebook-controller-proxy-role | authentication.k8s.io | tokenreviews | create |
| notebook-controller-proxy-role | authorization.k8s.io | subjectaccessreviews | create |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| notebook-controller-role-binding | opendatahub (cluster-scoped) | notebook-controller-role (ClusterRole) | notebook-controller-service-account |
| notebook-controller-leader-election-rolebinding | opendatahub | notebook-controller-leader-election-role (Role) | notebook-controller-service-account |
| notebook-controller-proxy-rolebinding | opendatahub (cluster-scoped) | notebook-controller-proxy-role (ClusterRole) | notebook-controller-service-account |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| (none required) | N/A | Controller uses ServiceAccount token mounted by Kubernetes | Kubernetes | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None (or TokenReview via kube-rbac-proxy) | kube-rbac-proxy (optional) | Allow ServiceAccounts with metrics-reader role |
| /healthz, /readyz | GET | None | Controller (unauthenticated) | Public within cluster |
| Kubernetes API | GET, LIST, WATCH, CREATE, UPDATE, PATCH, DELETE | ServiceAccount Bearer Token | Kubernetes API Server | ClusterRole notebook-controller-role |
| /api/kernels (Notebook Pods) | GET | Bearer Token or Istio AuthorizationPolicy | Istio (when enabled) | AuthorizationPolicy grants notebook-controller-sa access |

## Data Flows

### Flow 1: Notebook Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/jupyter-web-app | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | User Bearer Token |
| 2 | Kubernetes API | Notebook Controller (watch) | N/A | Internal | N/A | ServiceAccount Token |
| 3 | Notebook Controller | Kubernetes API (create StatefulSet) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Notebook Controller | Kubernetes API (create Service) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | Notebook Controller | Kubernetes API (create VirtualService) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token (if USE_ISTIO=true) |
| 6 | Notebook Controller | Kubernetes API (update Notebook status) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: Idle Notebook Culling

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | CullingReconciler | Notebook Pod | 8888/TCP | HTTP | None | Bearer Token or AuthorizationPolicy |
| 2 | Notebook Pod /api/kernels | CullingReconciler | Response | HTTP | None | N/A |
| 3 | CullingReconciler | Kubernetes API (add STOP_ANNOTATION) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | NotebookReconciler (triggered) | Kubernetes API (scale StatefulSet to 0) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 3: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | Controller /metrics | 8080/TCP | HTTP | None | None (or TokenReview if using auth proxy) |
| 2 | Controller | Kubernetes API (list StatefulSets) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Controller | Prometheus (metrics response) | Response | HTTP | None | N/A |

### Flow 4: Notebook Restart on ConfigMap Update

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External System | Kubernetes API (update ConfigMap) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | External System | Kubernetes API (annotate Notebook with notebooks.opendatahub.io/notebook-restart=true) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 3 | NotebookReconciler (triggered) | Kubernetes API (delete Pod) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | StatefulSet Controller | Kubernetes API (recreate Pod) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | NotebookReconciler | Kubernetes API (remove restart annotation) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | CRUD operations on Notebook/StatefulSet/Service/Pod resources |
| Istio Control Plane | CRD Creation | 6443/TCP | HTTPS | TLS 1.2+ | Create VirtualService for notebook ingress routing when USE_ISTIO=true |
| Prometheus | Metrics Pull | 8080/TCP | HTTP | None | Expose notebook creation/failure/culling metrics for monitoring |
| Jupyter Notebook Pods | HTTP API | 8888/TCP | HTTP | None | Poll /api/kernels endpoint for idle detection and culling |
| kube-rbac-proxy | HTTP Proxy | 8443/TCP | HTTPS | TLS 1.2+ | Optional auth proxy for securing metrics endpoint with Kubernetes RBAC |

## Configuration

### Environment Variables

| Variable | Default | Required | Purpose |
|----------|---------|----------|---------|
| METRICS_ADDR | :8080 | No | Address for Prometheus metrics endpoint binding |
| PROBE_ADDR | :8081 | No | Address for health/readiness probe endpoint binding |
| ENABLE_LEADER_ELECTION | false | No | Enable leader election for HA deployment (one active controller) |
| LEADER_ELECTION_NAMESPACE | "" | No | Namespace for leader election ConfigMap (defaults to controller namespace) |
| USE_ISTIO | false | No | Enable Istio VirtualService creation for notebooks |
| ISTIO_GATEWAY | kubeflow-gateway | No | Istio Gateway name for VirtualService routing |
| ISTIO_HOST | * | No | Hostname for VirtualService routing rules |
| ENABLE_CULLING | false | No | Enable idle notebook culling controller |
| CULL_IDLE_TIME | 1440 | No | Minutes of idle time before notebook is culled (default: 1 day) |
| IDLENESS_CHECK_PERIOD | 1 | No | Minutes between idle checks (default: 1 minute) |
| ADD_FSGROUP | true | No | Automatically add fsGroup: 100 to notebook pod security context |
| DEV | false | No | Enable development mode (proxies traffic via kubectl proxy for local dev) |
| BURST | 0 | No | Kubernetes client burst rate (0 = use default) |
| QPS | 0 | No | Kubernetes client QPS limit (0 = use default) |

### ConfigMaps

| ConfigMap Name | Key | Purpose |
|----------------|-----|---------|
| config | USE_ISTIO | Control Istio VirtualService creation |
| config | ISTIO_GATEWAY | Specify Istio Gateway name |
| config | ISTIO_HOST | Specify Istio VirtualService host |
| config | ADD_FSGROUP | Control automatic fsGroup addition to pod security context |
| notebook-controller-culler-config | ENABLE_CULLING | Enable/disable culling controller |
| notebook-controller-culler-config | CULL_IDLE_TIME | Idle time threshold in minutes |
| notebook-controller-culler-config | IDLENESS_CHECK_PERIOD | Check interval in minutes |

### Annotations

| Annotation | Target | Purpose |
|------------|--------|---------|
| notebooks.kubeflow.org/http-rewrite-uri | Notebook CR | Control HTTP URI rewriting in VirtualService |
| notebooks.kubeflow.org/http-headers-request-set | Notebook CR | Set HTTP headers in VirtualService routing |
| notebooks.opendatahub.io/notebook-restart | Notebook CR | Trigger pod restart when set to "true" (removed after restart) |
| kubeflow-resource-stopped | Notebook CR | Timestamp when notebook was culled (triggers replicas=0) |
| notebooks.kubeflow.org/last-activity | Notebook CR | Timestamp of last kernel/terminal activity for culling |
| notebooks.kubeflow.org/last_activity_check_timestamp | Notebook CR | Timestamp of last culling check |

### Labels

| Label | Value | Purpose |
|-------|-------|---------|
| app | notebook-controller | Selector for controller deployment and services |
| kustomize.component | notebook-controller | Component identification in kustomize deployments |
| component.opendatahub.io/name | kf-notebook-controller | ODH component identification |
| opendatahub.io/component | "true" | Mark as ODH component for discovery |
| app.kubernetes.io/part-of | odh-notebook-controller | Application grouping |
| notebook-name | <notebook-name> | Label on StatefulSet/Pod for notebook identification |
| opendatahub.io/workbenches | "true" | Mark notebook pods as workbenches in ODH |

## Deployment Architecture

### Deployment Specifications

| Resource | Replicas | Update Strategy | Resource Limits | Resource Requests |
|----------|----------|-----------------|-----------------|-------------------|
| notebook-controller-deployment | 1 | RollingUpdate (maxSurge: 0, maxUnavailable: 100%) | CPU: 500m, Memory: 4Gi | CPU: 500m, Memory: 256Mi |

### Container Images

| Container | Image | Build System | FIPS Compliant |
|-----------|-------|--------------|----------------|
| manager | rhoai/odh-kf-notebook-controller-rhel9 | Konflux | Yes (strictfipsruntime) |

### Health Checks

| Check Type | Path | Port | Initial Delay | Period |
|------------|------|------|---------------|--------|
| Liveness | /healthz | 8081/TCP | 5s | 10s |
| Readiness | /readyz | 8081/TCP | 5s | 10s |

## Metrics

### Prometheus Metrics

| Metric Name | Type | Labels | Purpose |
|-------------|------|--------|---------|
| notebook_running | Gauge | namespace | Current count of running notebooks per namespace |
| notebook_create_total | Counter | namespace | Total number of notebook creation attempts |
| notebook_create_failed_total | Counter | namespace | Total number of failed notebook creations |
| notebook_culling_total | Counter | namespace, name | Total number of notebooks culled for idleness |
| last_notebook_culling_timestamp_seconds | Gauge | namespace, name | Unix timestamp of last culling event per notebook |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| ec07741f | 2026-03 | chore(deps): update registry.access.redhat.com/ubi9/ubi-minimal docker digest to 759f5f4 |
| 57398d38 | 2026-03 | chore(deps): update registry.access.redhat.com/ubi9/ubi-minimal docker digest to ecd4751 |
| ce0d01f6 | 2026-02 | chore(deps): update registry.access.redhat.com/ubi9/ubi-minimal docker digest to bb08f23 |
| bd004f3e | 2026-01 | chore(deps): update registry.access.redhat.com/ubi9/ubi-minimal docker digest to 90bd85d |

## Technical Implementation Details

### Controller Logic

**NotebookReconciler** (notebook_controller.go ~800 lines):
- Watches: Notebook CRs, StatefulSets (owned), Services (owned), Pods (owned), Events (for re-emission)
- Reconciles StatefulSet with notebook PodSpec template, ensuring replicas=1 (or 0 if STOP_ANNOTATION set)
- Generates Service with selector matching StatefulSet pods, port 80→8888 mapping
- Conditionally creates Istio VirtualService when USE_ISTIO=true
- Updates Notebook status with pod conditions, container state, and ready replicas
- Handles notebook restart annotation by deleting pod and removing annotation
- Re-emits Pod/StatefulSet events to Notebook CR for centralized event visibility
- Validates notebook name length (max 52 chars due to StatefulSet name + hash constraints)

**CullingReconciler** (culling_controller.go ~500 lines):
- Watches: Notebook CRs (periodic requeue based on IDLENESS_CHECK_PERIOD)
- Polls notebook pod /api/kernels endpoint via HTTP to get kernel execution states
- Checks all kernels and terminals for last_activity timestamps
- Compares idle time against CULL_IDLE_TIME threshold (default 1440 minutes = 1 day)
- Adds STOP_ANNOTATION to Notebook CR when idle threshold exceeded
- Removes annotations when notebook is stopping or pod doesn't exist
- Maintains last_activity and last_activity_check_timestamp annotations for tracking
- Uses DEV mode to proxy requests via kubectl proxy for local development

### StatefulSet Generation

Default PodSpec modifications applied by controller:
- Adds `NB_PREFIX` environment variable for notebook base URL path
- Sets `fsGroup: 100` in security context (unless ADD_FSGROUP=false)
- Adds label `notebook-name: <name>` for identification
- Configures container port 8888 (DefaultContainerPort)
- Applies pod affinity/tolerations/node selectors from Notebook spec

### Service Generation

Service spec:
- ClusterIP type
- Port 80 (DefaultServingPort) → TargetPort 8888
- Selector: `notebook-name: <name>`
- Name pattern: `<notebook-name>-<hash>`

### VirtualService Generation (Istio)

When USE_ISTIO=true:
- Gateway: ${ISTIO_GATEWAY}
- Host: ${ISTIO_HOST}
- HTTP match: prefix `/notebook/<namespace>/<notebook-name>/`
- Rewrite: URI prefix stripping based on annotations
- Headers: Request header manipulation based on annotations
- Destination: notebook Service on port 80

## Known Limitations & Constraints

1. **StatefulSet Name Length**: Notebook names limited to 52 characters due to Kubernetes label value limits (63 chars - 11 char hash suffix)
2. **Culling Accuracy**: Idle detection relies on polling /api/kernels which may miss non-kernel activity (terminal-only usage)
3. **Leader Election Default**: Leader election disabled by default; HA deployments need ENABLE_LEADER_ELECTION=true
4. **VirtualService Updates**: Istio VirtualService configuration changes require controller restart to pick up new ISTIO_GATEWAY/ISTIO_HOST values
5. **Event Reconciliation**: Controller reconciles both Notebook CRs and Events in same queue, which may cause unnecessary reconciliation loops
6. **Status Field Incomplete**: Status field doesn't always reflect errors (see upstream issue #2269)
7. **No Conversion Webhook**: Multi-version support (v1/v1beta1/v1alpha1) without conversion webhook may cause issues if specs diverge
8. **HTTP-Only Kernel Polling**: Culling controller polls notebook /api/kernels over HTTP without TLS, requires Istio AuthorizationPolicy to secure

## Development & Testing

### Prerequisites
- Go 1.24.3+
- Docker 20.10+
- kubectl 1.22.0+
- kustomize 3.8.7+
- kubebuilder 3.3.0+
- Kubernetes cluster v1.22.0+

### Local Development
```bash
# Install CRDs
make install

# Run controller locally (requires kubectl proxy for culling)
kubectl proxy &
export DEV="true"
make run

# Run tests
make test
```

### Build & Deploy
```bash
# Build Docker image
make docker-build docker-push IMG=<registry>/notebook-controller TAG=<tag>

# Deploy to cluster
make deploy IMG=<registry>/notebook-controller TAG=<tag>

# Verify deployment
kubectl get pods -l app=notebook-controller -n notebook-controller-system
```

### Testing Culling
```bash
# Start kubectl proxy for /api/kernels access
kubectl proxy

# Apply AuthorizationPolicy for culler access
kubectl apply -f hack/dev_culling_authorization_policy.yaml

# Run with culling enabled
make run-culling
```

## References

- [Kubebuilder Book](https://book.kubebuilder.io/quick-start.html)
- [Kubeflow Notebooks Documentation](https://www.kubeflow.org/docs/components/notebooks/)
- [Developer Guide](components/notebook-controller/developer_guide.md)
- [Upstream Kubeflow Repository](https://github.com/kubeflow/kubeflow)
