# Component: Notebook Controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kubeflow.git
- **Version**: 1.27.0-rhods-1401-gfa6368ce
- **Branch**: rhoai-3.2
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator
- **Component Path**: components/notebook-controller
- **Manifests Location**: components/notebook-controller/config

## Purpose
**Short**: Kubernetes operator that manages Jupyter notebook instances via a custom Notebook CRD.

**Detailed**: The Notebook Controller is a Kubernetes operator built with Kubebuilder and controller-runtime that enables users to declaratively create and manage Jupyter notebook instances through a Notebook Custom Resource. It reconciles Notebook CRs by creating and managing underlying StatefulSets for running notebook instances and Services for network access. The controller supports multiple API versions (v1alpha1, v1beta1, v1) for backward compatibility, integrates with Istio service mesh for traffic management, and provides optional notebook culling functionality to automatically stop idle notebooks and optimize resource utilization. It exposes Prometheus metrics for monitoring notebook creation, failures, and active instances across the cluster.

The controller is part of the Kubeflow ecosystem and serves as the foundational infrastructure for notebook-based data science workloads in both Open Data Hub and Red Hat OpenShift AI. It abstracts away the complexity of managing StatefulSets, Services, and Istio VirtualServices, providing data scientists with a simple declarative API to launch and manage their notebook environments.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| NotebookReconciler | Controller | Reconciles Notebook CRs by creating/updating StatefulSets, Services, and Istio VirtualServices |
| CullingReconciler | Controller | Optional controller that monitors notebook kernel activity and stops idle notebooks |
| Notebook CRD | API Resource | Defines the schema for Jupyter notebook instances with PodSpec template |
| Metrics Exporter | Metrics | Exposes Prometheus metrics for notebook operations and running instances |
| Manager | Deployment | Main controller manager process that runs reconciliation loops |
| kube-rbac-proxy | Sidecar | Optional RBAC proxy for securing metrics endpoint |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kubeflow.org | v1 | Notebook | Namespaced | Primary API for defining Jupyter notebook instances with full PodSpec |
| kubeflow.org | v1beta1 | Notebook | Namespaced | Beta API version with conversion support |
| kubeflow.org | v1alpha1 | Notebook | Namespaced | Alpha API version with conversion support |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Controller manager metrics (internal) |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | RBAC SubjectAccessReview | Proxied metrics endpoint via kube-rbac-proxy |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /api/kernels | GET | 8888/TCP | HTTP | Varies | None | Jupyter kernel API (on notebook pods, accessed by culler) |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | No gRPC services exposed |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.22.0+ | Yes | Platform for running the operator and managed notebooks |
| controller-runtime | Latest | Yes | Kubernetes operator framework and reconciliation engine |
| Kubebuilder | 3.3.0+ | No | Development framework (build-time only) |
| Istio | Latest | No | Service mesh for VirtualService creation (optional via USE_ISTIO) |
| Prometheus | Latest | No | Metrics collection and monitoring |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| components/common | Go Library | Shared reconciliation helpers and utilities |
| Istio Gateway | Istio VirtualService | Routes external traffic to notebook instances when Istio is enabled |
| jupyter-web-app | API Consumer | Creates and manages Notebook CRs for user notebook spawning |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| service | ClusterIP | 443/TCP | 8443 | HTTPS | TLS 1.2+ | RBAC proxy | Internal |
| controller-manager-metrics-service | ClusterIP | 8443/TCP | https (8443) | HTTPS | TLS 1.2+ | RBAC proxy | Internal |
| notebook-{name} | ClusterIP | 80/TCP | 8888 | HTTP | None | Varies | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|----------|----------|----------|
| notebook-{name}-vs | Istio VirtualService | Configured via ISTIO_HOST | 80/TCP | HTTP | Varies | N/A | External (when USE_ISTIO=true) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch Notebook CRs, manage StatefulSets/Services |
| Notebook Pods | 8888/TCP | HTTP | None | None | Culler checking kernel activity via /api/kernels |
| kube-proxy | Various | HTTP | None | None | Proxy access to notebook services for culling (DEV mode) |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| role | "" (core) | events | create, get, list, patch, watch |
| role | "" (core) | pods | delete, get, list, watch |
| role | "" (core) | services | * (all) |
| role | apps | statefulsets | * (all) |
| role | kubeflow.org | notebooks, notebooks/finalizers, notebooks/status | * (all) |
| role | networking.istio.io | virtualservices | * (all) |
| auth-proxy-role | authorization.k8s.io | subjectaccessreviews | create |
| auth-proxy-role | authentication.k8s.io | tokenreviews | create |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| role-binding | Cluster-wide | ClusterRole/role | service-account (in deployment namespace) |
| auth-proxy-role-binding | Cluster-wide | ClusterRole/auth-proxy-role | service-account |
| leader-election-role-binding | Deployment namespace | Role/leader-election-role | service-account |

### RBAC - Namespace Roles

| Role Name | API Group | Resources | Verbs | Purpose |
|-----------|-----------|-----------|-------|---------|
| leader-election-role | "" (core) | configmaps | get, list, watch, create, update, patch, delete | Leader election coordination |
| leader-election-role | "" (core) | configmaps/status | get, update, patch | Leader election status updates |
| leader-election-role | "" (core) | events | create | Leader election event logging |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| None | N/A | No secrets directly managed by controller | N/A | N/A |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics (8443) | GET | RBAC SubjectAccessReview | kube-rbac-proxy sidecar | Requires appropriate RBAC permissions |
| /api/kernels | GET | None (or Istio mTLS) | Notebook Pod / Istio | Optional AuthorizationPolicy for culling access |
| Kubernetes API | ALL | ServiceAccount JWT Token | kube-apiserver | ServiceAccount RBAC permissions |

## Data Flows

### Flow 1: Notebook Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/jupyter-web-app | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | User credentials/SA token |
| 2 | Kubernetes API | NotebookReconciler | Watch stream | HTTPS | TLS 1.2+ | ServiceAccount token |
| 3 | NotebookReconciler | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 4 | NotebookReconciler creates | StatefulSet, Service, (VirtualService) | N/A | N/A | N/A | N/A |
| 5 | StatefulSet | Notebook Pod | N/A | N/A | N/A | N/A |

### Flow 2: Notebook Culling (when ENABLE_CULLING=true)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | CullingReconciler | Notebook Service | 8888/TCP | HTTP | None | None |
| 2 | CullingReconciler queries | /api/kernels endpoint | 8888/TCP | HTTP | None | None (or Istio AuthorizationPolicy) |
| 3 | CullingReconciler | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 4 | Updates Notebook CR with | STOP_ANNOTATION | N/A | N/A | N/A | N/A |
| 5 | NotebookReconciler | StatefulSet (replicas=0) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |

### Flow 3: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | kube-rbac-proxy | 8443/TCP | HTTPS | TLS 1.2+ | RBAC SubjectAccessReview |
| 2 | kube-rbac-proxy | Manager /metrics | 8080/TCP | HTTP | None | Localhost |
| 3 | Manager | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 4 | Manager scrapes | StatefulSet list | N/A | N/A | N/A | N/A |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API (watch/create/update) | 443/TCP | HTTPS | TLS 1.2+ | Watch Notebook CRs, manage StatefulSets/Services |
| Istio VirtualServices | CRD creation | 443/TCP | HTTPS | TLS 1.2+ | Create routing rules for notebook access |
| Prometheus | Metrics scraping | 8443/TCP | HTTPS | TLS 1.2+ | Monitor notebook operations and health |
| Notebook Pods | HTTP API | 8888/TCP | HTTP | None | Query kernel activity for culling decisions |
| jupyter-web-app | CRD creation | 443/TCP | HTTPS | TLS 1.2+ | Frontend that creates Notebook CRs |

## Configuration

### Environment Variables

| Variable | Default | Purpose | Configured Via |
|----------|---------|---------|----------------|
| USE_ISTIO | true (kubeflow) / false (openshift) | Enable Istio VirtualService creation | ConfigMap/config |
| ISTIO_GATEWAY | kubeflow/kubeflow-gateway | Istio gateway for VirtualServices | ConfigMap/config |
| ISTIO_HOST | * | Host pattern for VirtualServices | ConfigMap/config |
| ENABLE_CULLING | false | Enable notebook culling controller | ConfigMap/notebook-controller-culler-config |
| CULL_IDLE_TIME | 1440 (minutes) | Time before idle notebooks are culled | ConfigMap/notebook-controller-culler-config |
| IDLENESS_CHECK_PERIOD | 1 (minute) | Frequency of idle checks | ConfigMap/notebook-controller-culler-config |
| ADD_FSGROUP | true | Add fsGroup:100 to pod security context | Environment variable |
| DEV | false | Developer mode for local testing | Environment variable |
| CLUSTER_DOMAIN | cluster.local | Kubernetes cluster domain | ConfigMap/config |

### Command-line Flags

| Flag | Default | Purpose |
|------|---------|---------|
| --metrics-addr | :8080 | Address for metrics endpoint binding |
| --probe-addr | :8081 | Address for health probe endpoints |
| --enable-leader-election | false | Enable leader election for HA |
| --leader-election-namespace | "" | Namespace for leader election ConfigMap |
| --burst | 0 | Kubernetes client burst rate (0=default) |
| --qps | 0 | Kubernetes client QPS limit (0=default) |

## Deployment Architecture

### Deployment Strategy

| Parameter | Value | Purpose |
|-----------|-------|---------|
| Strategy | RollingUpdate | Deployment update strategy |
| MaxSurge | 0 | No additional pods during update |
| MaxUnavailable | 100% | Allow complete pod replacement |

### Resource Requests/Limits

| Resource | Request | Limit | Notes |
|----------|---------|-------|-------|
| Not specified | N/A | N/A | Default to namespace/cluster defaults |

### Container Images

| Container | Image | Build Method |
|-----------|-------|--------------|
| manager | rhoai/odh-kf-notebook-controller-rhel9 | Konflux (FIPS-compliant, UBI9-based) |
| kube-rbac-proxy | quay.io/brancz/kube-rbac-proxy:v0.4.0 | External (optional sidecar) |

### Health Probes

| Probe | Path | Port | Initial Delay | Period |
|-------|------|------|---------------|--------|
| Liveness | /healthz | 8081 | 5s | 10s |
| Readiness | /readyz | 8081 | 5s | 10s |

## Prometheus Metrics

### Exposed Metrics

| Metric Name | Type | Labels | Purpose |
|-------------|------|--------|---------|
| notebook_running | Gauge | namespace | Current running notebooks in the cluster |
| notebook_create_total | Counter | namespace | Total times notebooks have been created |
| notebook_create_failed_total | Counter | namespace | Total failures creating notebooks |
| notebook_culling_total | Counter | namespace, name | Total times notebooks have been culled |
| last_notebook_culling_timestamp_seconds | Gauge | namespace, name | Timestamp of last notebook culling |

## Key Design Decisions

### StatefulSet vs Deployment
- **Decision**: Use StatefulSets for notebook instances
- **Rationale**: Provides stable pod identity and persistent storage association for notebook workloads

### Istio Integration
- **Decision**: Optional Istio VirtualService creation (USE_ISTIO flag)
- **Rationale**: Supports both Istio-enabled (Kubeflow) and non-Istio (OpenShift) deployments

### Culling Controller
- **Decision**: Optional separate reconciler for notebook culling
- **Rationale**: Separates concerns and allows enabling/disabling culling independently

### Multiple API Versions
- **Decision**: Support v1alpha1, v1beta1, and v1 with conversion
- **Rationale**: Maintains backward compatibility while evolving the API

### Default fsGroup
- **Decision**: Automatically add fsGroup:100 to pod security context
- **Rationale**: Ensures proper file permissions for Jupyter notebooks (configurable via ADD_FSGROUP)

## Annotations and Labels

### Notebook Annotations

| Annotation | Purpose | Set By |
|------------|---------|--------|
| notebooks.kubeflow.org/http-rewrite-uri | URI rewriting for HTTP routing | User/jupyter-web-app |
| notebooks.kubeflow.org/http-headers-request-set | HTTP header injection | User/jupyter-web-app |
| notebooks.opendatahub.io/notebook-restart | Trigger notebook restart | User/UI |
| kubeflow-resource-stopped | Mark notebook as stopped/culled (timestamp) | CullingReconciler |
| notebooks.kubeflow.org/last-activity | Last kernel activity timestamp | CullingReconciler |
| notebooks.kubeflow.org/last_activity_check_timestamp | Last activity check timestamp | CullingReconciler |

### Pod Labels

| Label | Value | Purpose |
|-------|-------|---------|
| app | notebook-controller | Selector for controller pods |
| kustomize.component | notebook-controller | Kustomize component identification |
| notebook-name | {notebook-name} | Associate StatefulSet with Notebook CR |
| opendatahub.io/workbenches | true | Mark as ODH workbench resource |

## Recent Changes

| Commit | Date | Changes |
|---------|------|---------|
| fa6368ce | 2026 | - Update UBI9 go-toolset base image digest |
| d360d605 | 2026 | - Update UBI9 go-toolset base image digest |
| 16c88502 | 2026 | - Update UBI9 ubi-minimal base image digest |
| 3dc8b7b4 | 2026 | - Update UBI9 ubi-minimal base image digest |
| 54925875 | 2026 | - Update UBI9 go-toolset base image digest |
| 73bf51e5 | 2026 | - Update UBI9 go-toolset base image digest |
| 03b33840 | 2026 | - Update Konflux references |
| 211a77d7 | 2026 | - Update component Go dependencies |

**Note**: Recent changes primarily focus on dependency updates and base image security patches, with emphasis on maintaining FIPS compliance through UBI9 images and Konflux build system integration.

## Security Considerations

### FIPS Compliance
- Built with FIPS-enabled Go toolchain (GOEXPERIMENT=strictfipsruntime)
- Uses Red Hat UBI9 minimal base images with FIPS-validated cryptography

### Non-root Execution
- Container runs as UID 1001 (non-root user 'rhods')
- Compatible with OpenShift restricted SCC

### Service Account Permissions
- Requires cluster-wide permissions for managing StatefulSets, Services, and Notebooks
- Optional Istio VirtualService creation requires networking.istio.io API access

### Notebook Isolation
- Each notebook runs in its own StatefulSet with namespace-level isolation
- No built-in multi-tenancy controls (relies on Kubernetes namespace isolation)

### Culling Security
- Culler accesses notebook /api/kernels endpoint without authentication by default
- Optional Istio AuthorizationPolicy required for production deployments (see hack/dev_culling_authorization_policy.yaml)

## Known Limitations

1. **Notebook Name Length**: Maximum 52 characters due to StatefulSet naming constraints
2. **Foreground Deletion**: Notebook CR remains until all owned resources are deleted (prevents recreation during deletion)
3. **No Automatic Cleanup**: ttlSecondsAfterFinished not implemented (notebooks persist indefinitely unless manually deleted or culled)
4. **Single Container**: Notebook CR template supports multiple containers but controller assumes first container is the notebook
5. **Culling HTTP Access**: Requires network access to notebook pods on port 8888 (may conflict with network policies)

## Future Enhancements

Based on README TODO items:

- E2E testing infrastructure
- Enhanced status field for error reporting (issue #2269)
- Improved Istio integration with automatic resource generation
- CRD validation implementation
- ttlSecondsAfterFinished support for automatic cleanup

## Build and Container Information

### Dockerfile.konflux Details

- **Base Image (builder)**: registry.access.redhat.com/ubi9/go-toolset:1.25
- **Base Image (runtime)**: registry.access.redhat.com/ubi9/ubi-minimal
- **Build Flags**: CGO_ENABLED=1, GOEXPERIMENT=strictfipsruntime, -tags strictfipsruntime
- **Binary Path**: /manager
- **User**: 1001:0 (rhods user)
- **Red Hat Component**: odh-kf-notebook-controller-container
- **Image Name**: rhoai/odh-kf-notebook-controller-rhel9

## Testing

### Unit Tests
- Controllers have unit test coverage (notebook_controller_test.go, culling_controller_test.go)
- BDD-style tests for notebook controller behavior

### Development Testing
- Local development mode via DEV=true environment variable
- Requires kubectl proxy for notebook service access during local testing

### Test Command
```bash
make test
```

## Related Components

| Component | Relationship | Description |
|-----------|--------------|-------------|
| odh-notebook-controller | Variant | ODH-specific customizations of the notebook controller |
| jupyter-web-app | Consumer | Web UI that creates Notebook CRs for users |
| notebook-images | Runtime | Container images used by Notebook pods (specified in CR spec.template.spec.containers[0].image) |
| Istio | Integration | Optional service mesh integration for VirtualServices |
