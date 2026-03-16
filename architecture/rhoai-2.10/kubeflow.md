# Component: Kubeflow Notebook Controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kubeflow.git
- **Version**: v1.27.0-rhods-305-g6f06686a
- **Branch**: rhoai-2.10
- **Distribution**: RHOAI
- **Languages**: Go (Golang)
- **Deployment Type**: Kubernetes Operator (Controller)

## Purpose
**Short**: Manages the lifecycle of Jupyter notebook servers as Kubernetes custom resources.

**Detailed**: The Kubeflow Notebook Controller is a Kubernetes operator that automates the deployment and management of Jupyter notebook instances. When users create Notebook custom resources, the controller provisions the underlying infrastructure including StatefulSets for persistent notebook pods, Services for network access, and optionally Istio VirtualServices for ingress routing. The controller also includes an intelligent culling mechanism that monitors notebook kernel and terminal activity to automatically stop idle notebooks, optimizing cluster resource utilization. It supports multi-version CRD conversion (v1alpha1, v1beta1, v1) and integrates with OpenShift and Istio service mesh environments.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| NotebookReconciler | Go Controller | Reconciles Notebook CRs by creating/updating StatefulSets, Services, and VirtualServices |
| CullingReconciler | Go Controller | Monitors notebook activity and culls idle notebooks based on kernel/terminal usage |
| Manager Binary | Deployment | Main controller process running reconciliation loops |
| Metrics Collector | HTTP Endpoint | Exposes Prometheus metrics on controller operations |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kubeflow.org | v1 | Notebook | Namespaced | Primary API for defining Jupyter notebook instances with PodSpec template |
| kubeflow.org | v1beta1 | Notebook | Namespaced | Beta API version with conversion webhook support |
| kubeflow.org | v1alpha1 | Notebook | Namespaced | Alpha API version for backward compatibility |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for controller operations |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /notebook/{ns}/{name}/api/kernels | GET | 80/TCP | HTTP | None | Istio mTLS (optional) | Jupyter kernel status for culling checks |
| /notebook/{ns}/{name}/api/terminals | GET | 80/TCP | HTTP | None | Istio mTLS (optional) | Jupyter terminal status for culling checks |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | No gRPC services exposed |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | v1.22.0+ | Yes | Cluster runtime for operator deployment |
| controller-runtime | v0.8.0+ | Yes | Kubernetes controller framework |
| Istio | v1alpha3 | No | Service mesh for VirtualService routing and mTLS |
| Prometheus | N/A | No | Metrics collection and monitoring |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard (jupyter-web-app) | Creates Notebook CRs | User interface for creating and managing notebooks |
| Istio Gateway | VirtualService reference | Routes external traffic to notebook services |
| Image Registry | Container images | Provides Jupyter notebook container images |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| notebook-controller-service | ClusterIP | 443/TCP | 443 | HTTPS | TLS 1.2+ | None | Internal |
| {notebook-name} | ClusterIP | 80/TCP | 8888 | HTTP | None | Istio mTLS (optional) | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| notebook-{namespace}-{name} | Istio VirtualService | * | 80/TCP | HTTP | TLS 1.2+ (at gateway) | SIMPLE | External (via Istio Gateway) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token | CRD and resource management |
| Notebook Pods | 8888/TCP | HTTP | None | None | Health checks and culling activity queries |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| role | apps | statefulsets | * |
| role | "" (core) | services | * |
| role | "" (core) | pods | get, list, watch, delete |
| role | "" (core) | events | get, list, watch, create, patch |
| role | kubeflow.org | notebooks, notebooks/finalizers, notebooks/status | * |
| role | networking.istio.io | virtualservices | * |
| proxy-role | authentication.k8s.io | tokenreviews | create |
| proxy-role | authorization.k8s.io | subjectaccessreviews | create |
| kubeflow-notebooks-edit | kubeflow.org | notebooks, notebooks/status | get, list, watch, create, delete, deletecollection, patch, update |
| kubeflow-notebooks-view | kubeflow.org | notebooks, notebooks/status | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| leader-election-role-binding | notebook-controller-system | leader-election-role | service-account |
| auth-proxy-role-binding | notebook-controller-system | proxy-role | service-account |
| role-binding | notebook-controller-system | role | service-account |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| N/A | N/A | No secrets managed by controller | N/A | N/A |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| Kubernetes API | ALL | ServiceAccount token (JWT) | kube-apiserver | RBAC ClusterRole/RoleBinding |
| /metrics | GET | None | N/A | Unauthenticated (internal only) |
| /healthz, /readyz | GET | None | N/A | Unauthenticated (internal only) |
| Notebook Services | ALL | Istio mTLS (optional) | Istio sidecar | AuthorizationPolicy (when Istio enabled) |

## Data Flows

### Flow 1: Notebook Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Dashboard | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (JWT) |
| 2 | Kubernetes API | NotebookReconciler | N/A | Internal | N/A | Watch event |
| 3 | NotebookReconciler | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 4 | Kubernetes API | Kubelet | 10250/TCP | HTTPS | TLS 1.2+ | mTLS |
| 5 | Kubelet | Notebook Pod | N/A | N/A | N/A | Container runtime |

### Flow 2: Idle Notebook Culling

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | CullingReconciler | Notebook Service | 80/TCP | HTTP | None | None |
| 2 | Notebook Service | Notebook Pod | 8888/TCP | HTTP | None | None |
| 3 | Notebook Pod | CullingReconciler | N/A | HTTP | None | None |
| 4 | CullingReconciler | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |

### Flow 3: Istio VirtualService Routing

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External User | Istio Gateway | 443/TCP | HTTPS | TLS 1.3 | None/OAuth2 (gateway) |
| 2 | Istio Gateway | Notebook Service | 80/TCP | HTTP | mTLS | Istio peer authentication |
| 3 | Notebook Service | Notebook Pod | 8888/TCP | HTTP | mTLS | Istio peer authentication |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Resource management (StatefulSets, Services, Pods) |
| Istio Control Plane | CRD (VirtualService) | 6443/TCP | HTTPS | TLS 1.2+ | Create/update VirtualServices for notebook routing |
| Jupyter Notebook Pods | HTTP API | 8888/TCP | HTTP | None | Query kernel/terminal activity for culling |
| Prometheus | Metrics scrape | 8080/TCP | HTTP | None | Export controller metrics |

## Configuration

### ConfigMaps

| ConfigMap Name | Keys | Purpose |
|----------------|------|---------|
| config | USE_ISTIO | Enable/disable Istio VirtualService creation |
| config | ISTIO_GATEWAY | Istio gateway name for VirtualService (default: kubeflow/kubeflow-gateway) |
| config | ADD_FSGROUP | Enable/disable automatic fsGroup:100 addition to pod security context |
| notebook-controller-culler-config | ENABLE_CULLING | Enable/disable idle notebook culling (default: false) |
| notebook-controller-culler-config | CULL_IDLE_TIME | Minutes before idle notebook is culled (default: 1440 = 1 day) |
| notebook-controller-culler-config | IDLENESS_CHECK_PERIOD | Minutes between culling checks (default: 1) |

### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| USE_ISTIO | false | Enable Istio VirtualService reconciliation |
| ISTIO_GATEWAY | kubeflow/kubeflow-gateway | Gateway for VirtualService routing |
| ADD_FSGROUP | true | Add fsGroup:100 to pod security context |
| ENABLE_CULLING | false | Enable idle notebook culling |
| CULL_IDLE_TIME | 1440 | Idle time in minutes before culling |
| IDLENESS_CHECK_PERIOD | 1 | Check interval in minutes for culling |
| CLUSTER_DOMAIN | cluster.local | Kubernetes cluster domain for service DNS |
| DEV | false | Development mode (use kubectl proxy for API access) |

### Command-Line Flags

| Flag | Default | Purpose |
|------|---------|---------|
| --metrics-addr | :8080 | Metrics endpoint bind address |
| --probe-addr | :8081 | Health probe endpoint bind address |
| --enable-leader-election | false | Enable leader election for HA deployments |
| --leader-election-namespace | "" | Namespace for leader election ConfigMap |
| --burst | 0 | REST client burst limit (0 = default) |
| --qps | 0 | REST client QPS limit (0 = default) |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| v1.27.0-rhods-305 | 2024-11-01 | - Upgrade x/net package to v0.23.0 for security fixes<br>- Sync Dockerfiles with CPaaS repository for clean CI<br>- Specify numeric UID in Dockerfiles for security compliance |
| v1.27.0-rhods-304 | 2024-10-29 | - Add GitHub Actions workflow files from opendatahub-io/kubeflow<br>- Rename helper.go to fix govulncheck failure |
| v1.27.0-rhods-303 | 2024-10-26 | - RHOAIENG-14150: Synchronize with upstream Kubeflow changes<br>- Update CI/CD configurations |

## Deployment Architecture

### Container Image Build

- **Base Image**: registry.access.redhat.com/ubi8/go-toolset:1.20 (builder)
- **Runtime Image**: registry.access.redhat.com/ubi8/ubi-minimal:latest
- **Binary**: `/manager` (Go binary compiled from main.go)
- **User**: UID 1001 (non-root)
- **Build Tool**: Multi-stage Dockerfile with Cachito support

### Deployment Strategy

- **Type**: Kubernetes Deployment
- **Replicas**: 1 (default, HA with leader election)
- **Rolling Update**: maxSurge=0, maxUnavailable=100%
- **Container**: kf-notebook-controller manager
- **Image**: docker.io/kubeflownotebookswg/notebook-controller (upstream) or ODH/RHOAI registry
- **Labels**:
  - app: notebook-controller
  - kustomize.component: notebook-controller
  - app.kubernetes.io/part-of: odh-notebook-controller
  - component.opendatahub.io/name: kf-notebook-controller

### Resource Requirements

| Resource | Request | Limit | Notes |
|----------|---------|-------|-------|
| CPU | Not specified | Not specified | Define in overlay/production |
| Memory | Not specified | Not specified | Define in overlay/production |

## Troubleshooting

### Common Issues

1. **Notebooks not starting**: Check StatefulSet events and pod logs
   - Verify image pull secrets
   - Check resource quotas
   - Verify PVC provisioning (if using)

2. **VirtualService not created**: Check USE_ISTIO environment variable
   - Ensure Istio CRDs are installed
   - Verify ISTIO_GATEWAY configuration
   - Check controller logs for VirtualService reconciliation errors

3. **Culling not working**: Verify culling configuration
   - Check ENABLE_CULLING is set to "true"
   - Verify notebook service is accessible from controller
   - Check /api/kernels and /api/terminals endpoints are responsive
   - Review CullingReconciler logs

4. **Controller not reconciling**: Check leader election
   - Verify only one controller has leadership
   - Check leader-election ConfigMap
   - Review controller logs for reconciliation errors

### Logs and Monitoring

- **Controller Logs**: `kubectl logs -n <namespace> deployment/notebook-controller-deployment`
- **Metrics**: Scrape `/metrics` endpoint on port 8080
  - `notebook_creation_total`: Counter for notebook creations
  - `notebook_fail_creation_total`: Counter for failed creations
  - `notebook_culling_count`: Counter for culled notebooks
  - `notebook_culling_timestamp`: Timestamp of last culling action

## Notes

- The controller creates one StatefulSet per Notebook CR for persistent storage support
- Each notebook gets a ClusterIP Service for internal access
- Istio VirtualService is optional and controlled by USE_ISTIO environment variable
- Culling mechanism queries Jupyter's /api/kernels and /api/terminals endpoints
- Controller supports conversion webhooks for CRD version migration (currently commented out)
- OpenShift overlay disables fsGroup addition and Istio by default
- Pod label "notebook-name" is used for event correlation and pod discovery
- Annotation "kubeflow-resource-stopped" triggers StatefulSet replica scaling to 0
- Annotation "notebooks.opendatahub.io/notebook-restart" triggers pod restart
