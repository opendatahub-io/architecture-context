# Component: Notebook Controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kubeflow.git
- **Version**: v1.27.0-rhods-282-g1bca6de7
- **Branch**: rhoai-2.9
- **Distribution**: RHOAI
- **Languages**: Go 1.19
- **Deployment Type**: Kubernetes Operator (Controller)
- **Manifests Location**: components/notebook-controller/config:odh-notebook-controller/kf-notebook-controller

## Purpose
**Short**: Manages Jupyter notebook instances as Kubernetes custom resources with lifecycle management and optional idle culling.

**Detailed**: The Notebook Controller is a Kubernetes operator that manages Jupyter notebook server instances through a custom resource definition (CRD). When users create a Notebook CR specifying a container image and PodSpec, the controller automatically provisions the underlying infrastructure including a StatefulSet for the notebook pod, a ClusterIP Service for network access, and optionally an Istio VirtualService for ingress routing. The controller supports multi-version CRDs (v1alpha1, v1beta1, v1) with conversion webhooks for API compatibility. An optional culling controller monitors notebook activity through the Jupyter Server API, tracking kernel and terminal activity to automatically stop idle notebooks after a configurable timeout period, helping optimize cluster resource utilization.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| NotebookReconciler | Controller | Main reconciliation loop managing Notebook CR lifecycle, creating/updating StatefulSets, Services, and VirtualServices |
| CullingReconciler | Controller | Optional controller that monitors Jupyter kernel/terminal activity and stops idle notebooks |
| Metrics Collector | Prometheus Exporter | Exposes notebook creation, running count, and culling metrics on port 8080 |
| Webhook Server | Admission Controller | Handles conversion between CRD versions (v1alpha1, v1beta1, v1) - currently disabled |
| Health Probes | HTTP Endpoints | Liveness (/healthz) and readiness (/readyz) probes on port 8081 |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kubeflow.org | v1alpha1 | Notebook | Namespaced | Legacy API version for Jupyter notebook instances |
| kubeflow.org | v1beta1 | Notebook | Namespaced | Beta API version with webhook support for notebook instances |
| kubeflow.org | v1 | Notebook | Namespaced | Stable storage version for notebook instances with PodSpec template |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics scraping endpoint |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe for controller health |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe for controller startup |

### gRPC Services

_No gRPC services exposed._

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.22.0+ | Yes | Platform for CRD registration and workload orchestration |
| controller-runtime | v0.15.0 | Yes | Framework for building Kubernetes controllers |
| Prometheus | N/A | No | Metrics collection from /metrics endpoint |
| Istio | N/A | No | Optional service mesh integration for VirtualService routing |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| kubeflow/components/common | Go Module Import | Shared reconciliation helpers and utilities |
| Jupyter Notebook Images | Container Images | Runtime environment for user notebook workloads |
| Istio Gateway | VirtualService Reference | External ingress routing when USE_ISTIO=true |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| notebook-controller-service | ClusterIP | 443/TCP | 443 | HTTPS | TLS (webhook) | None | Internal |
| {notebook-name} (generated) | ClusterIP | 80/TCP | 8888 | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {notebook-name}-virtualservice (optional) | Istio VirtualService | From ISTIO_GATEWAY | 80/TCP | HTTP | Depends on Gateway | N/A | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | CRD and resource management |
| {notebook-name}.{namespace}.svc.cluster.local | 8888/TCP | HTTP | None | None | Culler checks notebook /api/kernels and /api/terminals |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| notebook-controller-role | apps | statefulsets | * |
| notebook-controller-role | "" | events | create, get, list, patch, watch |
| notebook-controller-role | "" | pods | delete, get, list, watch |
| notebook-controller-role | "" | services | * |
| notebook-controller-role | kubeflow.org | notebooks, notebooks/finalizers, notebooks/status | * |
| notebook-controller-role | networking.istio.io | virtualservices | * |
| leader-election-role | "" | configmaps, configmaps/status | get, list, watch, create, update, patch, delete |
| leader-election-role | "" | events | create |
| kubeflow-notebooks-edit | kubeflow.org | notebooks, notebooks/status | get, list, watch, create, delete, deletecollection, patch, update |
| kubeflow-notebooks-view | kubeflow.org | notebooks, notebooks/status | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| notebook-controller-role-binding | kubeflow (configurable) | notebook-controller-role | notebook-controller-service-account |
| leader-election-role-binding | kubeflow (configurable) | leader-election-role | notebook-controller-service-account |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| webhook-server-cert (optional) | kubernetes.io/tls | TLS certificate for conversion webhook | cert-manager | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| Kubernetes API | ALL | ServiceAccount Token (JWT) | kube-apiserver | RBAC ClusterRole |
| /metrics | GET | None | None | Open for Prometheus scraping |
| /healthz, /readyz | GET | None | None | Open for kubelet probes |
| Notebook Pods /api/kernels | GET | None | HTTP (in-cluster) | None - internal service mesh |

## Data Flows

### Flow 1: Notebook Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/JupyterHub | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Kubernetes API | Notebook Controller | N/A | Watch | N/A | ServiceAccount Token |
| 3 | Notebook Controller | Kubernetes API (StatefulSet) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Notebook Controller | Kubernetes API (Service) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | Notebook Controller | Kubernetes API (VirtualService) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token (if USE_ISTIO=true) |
| 6 | StatefulSet | Container Registry | 443/TCP | HTTPS | TLS 1.2+ | ImagePullSecrets |

### Flow 2: Idle Notebook Culling

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Culling Controller (timer) | Notebook Controller | N/A | In-Process | N/A | N/A |
| 2 | Culling Controller | Notebook Pod Service | 8888/TCP | HTTP | None | None |
| 3 | Culling Controller | Kubernetes API (Notebook CR update) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Notebook Controller | Kubernetes API (StatefulSet scale to 0) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 3: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | Notebook Controller /metrics | 8080/TCP | HTTP | None | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API Client | 6443/TCP | HTTPS | TLS 1.2+ | CRUD operations on StatefulSets, Services, VirtualServices, Notebooks |
| Prometheus | HTTP Scrape Target | 8080/TCP | HTTP | None | Expose notebook creation, running, and culling metrics |
| Jupyter Notebook Pods | HTTP Client | 8888/TCP | HTTP | None | Query /api/kernels and /api/terminals for activity tracking |
| Istio Gateway | VirtualService CRD | N/A | N/A | N/A | Optional ingress routing configuration |
| JupyterHub / ODH Dashboard | CRD Client | 6443/TCP | HTTPS | TLS 1.2+ | Create/delete Notebook CRs via Kubernetes API |

## Configuration

### Environment Variables

| Variable | Default | Required | Purpose |
|----------|---------|----------|---------|
| USE_ISTIO | N/A | No | Enable Istio VirtualService creation |
| ISTIO_GATEWAY | N/A | No | Gateway name for VirtualService routing |
| ENABLE_CULLING | false | No | Enable idle notebook culling controller |
| CULL_IDLE_TIME | 1440 (minutes) | No | Maximum idle time before culling (24 hours) |
| IDLENESS_CHECK_PERIOD | 1 (minute) | No | Frequency of activity checks |
| ADD_FSGROUP | true | No | Add fsGroup:100 to pod security context |
| CLUSTER_DOMAIN | cluster.local | No | Kubernetes cluster domain for service DNS |
| DEV | false | No | Development mode for local testing |

### ConfigMaps

| ConfigMap Name | Key | Purpose |
|----------------|-----|---------|
| config | USE_ISTIO | Controls VirtualService generation |
| config | ISTIO_GATEWAY | Specifies gateway for VirtualServices |
| config | ADD_FSGROUP | Controls fsGroup injection |
| notebook-controller-culler-config | ENABLE_CULLING | Enables/disables culling controller |
| notebook-controller-culler-config | CULL_IDLE_TIME | Idle timeout in minutes |
| notebook-controller-culler-config | IDLENESS_CHECK_PERIOD | Check frequency in minutes |

### Command-Line Flags

| Flag | Default | Purpose |
|------|---------|---------|
| --metrics-addr | :8080 | Metrics endpoint bind address |
| --probe-addr | :8081 | Health probe endpoint bind address |
| --enable-leader-election | false | Enable leader election for HA |
| --leader-election-namespace | "" | Namespace for leader election ConfigMap |
| --burst | 0 (default) | Kubernetes client burst rate |
| --qps | 0 (default) | Kubernetes client QPS limit |

## Resource Annotations

| Annotation | Applied To | Purpose |
|------------|------------|---------|
| kubeflow-resource-stopped | Notebook CR | Marks notebook for culling with timestamp |
| notebooks.kubeflow.org/last-activity | Notebook CR | Tracks last kernel/terminal activity (RFC3339) |
| notebooks.kubeflow.org/http-rewrite-uri | VirtualService | URI rewrite configuration |
| notebooks.kubeflow.org/http-headers-request-set | VirtualService | Custom HTTP headers |
| notebooks.opendatahub.io/notebook-restart | Notebook CR | Triggers notebook restart |
| opendatahub.io/workbenches | Notebook Pod | Labels workbench pods |

## Deployment Architecture

### Deployment Strategy

| Attribute | Value |
|-----------|-------|
| Deployment Type | Kubernetes Deployment |
| Replicas | 1 |
| Update Strategy | RollingUpdate (maxSurge: 0, maxUnavailable: 100%) |
| Restart Policy | Always |

### Resource Requirements

| Container | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| manager | 500m | 500m | 256Mi | 4Gi |

### Container Image

| Component | Image |
|-----------|-------|
| Notebook Controller | $(odh-kf-notebook-controller-image) - set via kustomize |

## Observability

### Prometheus Metrics

| Metric Name | Type | Labels | Description |
|-------------|------|--------|-------------|
| notebook_running | Gauge | namespace | Current running notebooks in the cluster |
| notebook_create_total | Counter | namespace | Total times of creating notebooks |
| notebook_create_failed_total | Counter | namespace | Total failure times of creating notebooks |
| notebook_culling_total | Counter | namespace, name | Total times of culling notebooks |
| last_notebook_culling_timestamp_seconds | Gauge | namespace, name | Timestamp of the last notebook culling in seconds |

### Health Probes

| Probe Type | Path | Port | Initial Delay | Period |
|------------|------|------|---------------|--------|
| Liveness | /healthz | 8081/TCP | 5s | 10s |
| Readiness | /readyz | 8081/TCP | 5s | 10s |

### Logging

| Component | Log Level | Format |
|-----------|-----------|--------|
| Controller | Configurable (zap) | Structured JSON |
| Reconciler | Info/Error | Key-value pairs |
| Culler | Info/Error | Key-value pairs |

## Generated Resources

For each Notebook CR, the controller creates:

| Resource Type | Naming Pattern | Purpose |
|---------------|----------------|---------|
| StatefulSet | {notebook-name} | Runs single-replica notebook pod |
| Service | {notebook-name} | ClusterIP service exposing port 80 -> 8888 |
| VirtualService | {notebook-name} | Istio routing (if USE_ISTIO=true) |

### StatefulSet Characteristics

| Attribute | Value |
|-----------|-------|
| Replicas | 1 (0 if kubeflow-resource-stopped annotation set) |
| Service Name | {notebook-name} |
| Update Strategy | RollingUpdate |
| Pod Labels | notebook-name={notebook-name} |
| Container Port | 8888 (default, configurable via PodSpec) |
| Security Context | fsGroup: 100 (if ADD_FSGROUP != false) |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 4f29d67b | Recent | - Add nil checks to prevent unit tests from failing |
| 9dcbe64d | Recent | - Remove replace from go.mod file |
| 7ae9c601 | Recent | - Update logic to add notebook label on create and restart |
| ad8239d1 | Recent | - Bump controller-runtime version in odh-notebook-controller |
| dc36ace7 | Recent | - Adjust go mod download as per go version 1.19 rules |
| a7e2abd7 | Recent | - Point the default patch image to the stable tag |
| f25d2c70 | Recent | - Fix: patch images of notebook-controller in its components |
| d411a26d | Recent | - Fix: Upgrade the golang version and indirect dep net, grpc |
| 5fdfa8d0 | Recent | - Chores: fix the unit test for notebook-controller |
| 07ef442e | Recent | - Adjust the manifests based on the RHODS odh-manifests |

## Known Limitations

1. **Culling HTTP Security**: Culling controller communicates with notebook pods over unencrypted HTTP without authentication
2. **Single Replica**: StatefulSet always creates single replica (not designed for horizontal scaling)
3. **Webhook Disabled**: Conversion webhook is implemented but commented out in main.go
4. **No mTLS**: Internal service-to-service communication does not use mutual TLS
5. **Metrics Unprotected**: /metrics endpoint exposed without authentication

## Security Considerations

1. **Notebook Pod Communication**: Culler makes HTTP requests to notebook pods at `http://{name}.{namespace}.svc.cluster.local:8888/notebook/{namespace}/{name}/api/kernels` without encryption or authentication
2. **Network Policy**: No NetworkPolicy resources defined - relies on cluster defaults
3. **Service Mesh**: Optional Istio integration for external access, but internal traffic remains plaintext
4. **RBAC Scope**: ClusterRole grants broad permissions (* verbs) on StatefulSets, Services, and VirtualServices across all namespaces
5. **Metrics Exposure**: Prometheus metrics on port 8080 are unauthenticated and may leak notebook creation/usage patterns

## Future Enhancements

Based on TODO comments in README.md:
- End-to-end testing
- Enhanced status field error reporting
- CRD validation rules
- TTL-based cleanup of finished notebooks
- Improved Istio security integration
