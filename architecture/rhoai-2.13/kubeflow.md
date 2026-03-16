# Component: Notebook Controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kubeflow.git
- **Version**: v1.27.0-rhods-376-g66806c00
- **Branch**: rhoai-2.13
- **Distribution**: RHOAI (forked from upstream Kubeflow)
- **Languages**: Go (Kubebuilder-based operator)
- **Deployment Type**: Kubernetes Operator
- **Build System**: Konflux (Dockerfile.konflux)

## Purpose
**Short**: Manages lifecycle of Jupyter notebook server instances as Kubernetes custom resources.

**Detailed**: The Notebook Controller is a Kubernetes operator that enables users to create and manage Jupyter notebook servers through a declarative custom resource. The controller watches Notebook CRDs and reconciles them by creating StatefulSets for the notebook server pods and Services for network access. It supports automatic culling of idle notebooks to optimize resource usage, integration with Istio service mesh for advanced routing, and provides comprehensive metrics for monitoring notebook usage. The controller is adapted from upstream Kubeflow for use in Red Hat OpenShift AI (RHOAI) and Open Data Hub (ODH), with specific patches for OpenShift compatibility including optional fsGroup settings and Konflux-based builds.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| NotebookReconciler | Controller | Main reconciliation loop that manages Notebook CR lifecycle, creates/updates StatefulSets and Services |
| CullingReconciler | Controller | Optional controller that monitors notebook activity and culls idle notebooks based on kernel/terminal activity |
| Metrics Collector | Prometheus Exporter | Exposes Prometheus metrics about notebook creation, failures, and culling events |
| VirtualService Manager | Istio Integration | Creates Istio VirtualService resources for notebook access when USE_ISTIO=true |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kubeflow.org | v1alpha1 | Notebook | Namespaced | Legacy version for Notebook CR (supports conversion) |
| kubeflow.org | v1beta1 | Notebook | Namespaced | Beta version with webhook support |
| kubeflow.org | v1 | Notebook | Namespaced | Primary storage version for managing Jupyter notebook instances |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /notebook/{namespace}/{name}/api/kernels | GET | 80/TCP | HTTP | None | Istio mTLS (optional) | Jupyter kernel status API (for culling) |
| /notebook/{namespace}/{name}/api/terminals | GET | 80/TCP | HTTP | None | Istio mTLS (optional) | Jupyter terminal status API (for culling) |
| /notebook/{namespace}/{name}/ | ALL | 80/TCP | HTTP | None | Istio mTLS (optional) | Jupyter notebook web interface |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | No gRPC services exposed |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.22.0+ | Yes | Platform for running the operator and notebook workloads |
| StatefulSet API | apps/v1 | Yes | Managing notebook pod instances with stable identity |
| Service API | v1 | Yes | Exposing notebook servers on the network |
| Istio | networking.istio.io/v1alpha3 | No | Optional service mesh integration for VirtualServices and AuthorizationPolicies |
| Prometheus | N/A | No | Optional metrics collection |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | UI/API | Creates and manages Notebook CRs through web interface |
| Kubeflow Profiles | CRD | Provides namespace isolation and multi-tenancy (when running in Kubeflow mode) |
| Notebook Images | Container Registry | Provides Jupyter notebook container images referenced in Notebook specs |
| OAuth Proxy | Sidecar Container | Optional authentication for notebook access in OpenShift environments |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| notebook-controller-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | webhook | Internal |
| {notebook-name} | ClusterIP | 80/TCP | 8888 | HTTP | None | None | Internal |

**Note**: Each Notebook CR creates its own Service with name matching the Notebook name. The service uses port 80 externally (DefaultServingPort) and routes to port 8888 (DefaultContainerPort) on the notebook container.

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| notebook-{namespace}-{name} | Istio VirtualService | * | 80/TCP | HTTP | None | N/A | Internal |

**Note**: VirtualServices are only created when USE_ISTIO=true. They route traffic from the Istio Gateway to notebook Services based on URI prefix `/notebook/{namespace}/{name}/`.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch and manage CRDs, StatefulSets, Services |
| Notebook Services | 80/TCP | HTTP | None | None | Query Jupyter API for kernel/terminal activity (culling) |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| notebook-controller-role | apps | statefulsets | * |
| notebook-controller-role | "" (core) | events | get, list, watch, create, patch |
| notebook-controller-role | "" (core) | pods | get, list, watch, delete |
| notebook-controller-role | "" (core) | services | * |
| notebook-controller-role | kubeflow.org | notebooks, notebooks/status, notebooks/finalizers | * |
| notebook-controller-role | networking.istio.io | virtualservices | * |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| notebook-controller-role-binding | cluster-wide | notebook-controller-role | notebook-controller-service-account |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| webhook-server-cert | kubernetes.io/tls | TLS certificate for webhook server | cert-manager or cert injection | Yes |

**Note**: ConfigMaps are used for configuration (not secrets):
- `config`: Contains USE_ISTIO, ISTIO_GATEWAY settings
- `notebook-controller-culler-config`: Contains ENABLE_CULLING, CULL_IDLE_TIME, IDLENESS_CHECK_PERIOD

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None | N/A | Publicly accessible within cluster |
| /healthz, /readyz | GET | None | N/A | Publicly accessible for probes |
| /notebook/{ns}/{name}/api/kernels | GET | None (or Istio mTLS) | Istio AuthorizationPolicy (optional) | Allow GET from kube-proxy service account (dev mode) |
| Kubernetes API | ALL | ServiceAccount Token (JWT) | Kubernetes RBAC | ClusterRole permissions |
| Notebook Services | ALL | Istio mTLS (optional) | Istio PeerAuthentication | Configured per-namespace |

## Data Flows

### Flow 1: Notebook Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Dashboard | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Kubernetes API | Notebook Controller | N/A | Watch Event | N/A | ServiceAccount |
| 3 | Notebook Controller | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Notebook Controller | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

**Description**: User creates Notebook CR → Controller watches event → Creates StatefulSet → Creates Service → (Optional) Creates VirtualService

### Flow 2: Idle Notebook Culling

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Culling Controller | Notebook Service | 80/TCP | HTTP | None | None |
| 2 | Notebook Service | Jupyter Pod | 8888/TCP | HTTP | None | None |
| 3 | Jupyter Pod | Culling Controller | 80/TCP | HTTP | None | None |
| 4 | Culling Controller | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

**Description**: Controller queries `/api/kernels` and `/api/terminals` → Checks last activity → Updates annotation if idle → Scales StatefulSet to 0 replicas

### Flow 3: User Accessing Notebook

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | Istio Gateway | 443/TCP | HTTPS | TLS 1.2+ | OAuth/JWT |
| 2 | Istio Gateway | VirtualService | 80/TCP | HTTP | mTLS (optional) | Istio Policy |
| 3 | VirtualService | Notebook Service | 80/TCP | HTTP | mTLS (optional) | None |
| 4 | Notebook Service | Notebook Pod | 8888/TCP | HTTP | None | None |

**Description**: User accesses `/notebook/{ns}/{name}/` → Istio routes to VirtualService → Routes to Service → Proxies to Jupyter pod

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 443/TCP | HTTPS | TLS 1.2+ | CRUD operations on StatefulSets, Services, Notebooks, Events |
| Istio Control Plane | CRD (VirtualService) | N/A | N/A | N/A | Create routing rules for notebook access |
| Prometheus | Metrics Scrape | 8080/TCP | HTTP | None | Collect notebook usage metrics |
| Jupyter Notebook Pods | HTTP API | 8888/TCP | HTTP | None | Query kernel/terminal status for culling |

## Deployment Variants

### Kubeflow Variant (kf-notebook-controller)
- Deployed in `kubeflow` namespace
- Istio integration enabled by default (USE_ISTIO=true)
- KFAM (Kubeflow Access Management) integration
- Uses upstream Kubeflow Gateway

### ODH/OpenShift Variant (odh-notebook-controller)
- Deployed in ODH operator-managed namespace
- Istio integration disabled by default (USE_ISTIO=false)
- fsGroup setting disabled by default (ADD_FSGROUP=false) for OpenShift compatibility
- Resource limits configured for production use
- Built with Konflux pipeline using UBI8 base images

## Configuration

### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| USE_ISTIO | false (OpenShift) | Enable/disable Istio VirtualService creation |
| ISTIO_GATEWAY | kubeflow/kubeflow-gateway | Istio Gateway resource to use for VirtualServices |
| ENABLE_CULLING | false | Enable/disable automatic culling of idle notebooks |
| CULL_IDLE_TIME | 1440 (minutes) | Time before idle notebook is culled (24 hours) |
| IDLENESS_CHECK_PERIOD | 1 (minute) | Frequency of idleness checks |
| ADD_FSGROUP | false (OpenShift) | Add fsGroup:100 to pod security context |
| CLUSTER_DOMAIN | cluster.local | Kubernetes cluster domain for service DNS |
| DEV | false | Enable development mode (uses kubectl proxy for culling) |

### Command-line Flags

| Flag | Default | Purpose |
|------|---------|---------|
| --metrics-addr | :8080 | Address for Prometheus metrics endpoint |
| --probe-addr | :8081 | Address for health/readiness probes |
| --enable-leader-election | false | Enable leader election for HA deployments |
| --leader-election-namespace | "" | Namespace for leader election ConfigMap |
| --burst | 0 | Kubernetes API client burst rate |
| --qps | 0 | Kubernetes API client QPS limit |

## Metrics

### Prometheus Metrics Exposed

| Metric Name | Type | Labels | Purpose |
|-------------|------|--------|---------|
| notebook_running | Gauge | namespace | Current count of running notebooks per namespace |
| notebook_create_total | Counter | namespace | Total number of notebook creations |
| notebook_create_failed_total | Counter | namespace | Total number of failed notebook creations |
| notebook_culling_total | Counter | namespace, name | Total number of notebook culling events |
| last_notebook_culling_timestamp_seconds | Gauge | namespace, name | Unix timestamp of last culling event |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 66806c00 | 2024 | - Update Konflux references (#416) |
| a9f692d4 | 2024 | - Update Konflux references to d00d159 (#409) |
| 14be42c7 | 2024 | - Update Konflux references (#399) |
| 11c6bf9a | 2024 | - Update Konflux references (#391) |
| ca8ea95b | 2024 | - Update Konflux references to 493a872 (#380) |
| f8ff7daf | 2024 | - [2.25] Bump golang version from 1.24 to 1.25 (#1066) |
| 692c49dd | 2024 | - [RHOAIENG-12107] fix some linter issues in odh-nbc component |

**Note**: Recent commits focus on Konflux pipeline updates and dependency management. The component is in maintenance mode with regular dependency updates.

## Known Issues and Limitations

1. **CRD Validation**: Uses patched CRD with relaxed validation for backward compatibility (see config/README.md)
2. **Conversion Webhook**: Webhook code exists but is commented out in main.go (line 136-139)
3. **Istio Dependency**: Full functionality requires Istio when USE_ISTIO=true
4. **Culling Network Access**: Culling feature requires network access to notebook service endpoints
5. **Single Controller**: No HA support by default (leader election available but disabled)

## Testing

### Test Suites
- Unit tests: `make test`
- Integration tests: GitHub Actions workflows
  - `notebook_controller_integration_test.yaml`
  - `odh_notebook_controller_integration_test.yaml`
- BDD tests: `controllers/notebook_controller_bdd_test.go`

### Load Testing
- Load test scripts available in `loadtest/` directory
- Python script for creating multiple notebooks: `start_notebooks.py`
