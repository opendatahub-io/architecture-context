# Component: ODH Dashboard

## Metadata
- **Repository**: https://github.com/red-hat-data-services/odh-dashboard.git
- **Version**: v1.21.0-18-rhods-2393-gcb94ecb33
- **Branch**: rhoai-2.14
- **Distribution**: RHOAI
- **Languages**: TypeScript, JavaScript, Node.js 18+
- **Deployment Type**: Web Application (Frontend + Backend API)

## Purpose
**Short**: Web-based dashboard providing a unified user interface for managing and interacting with RHOAI/ODH data science components and workflows.

**Detailed**: The ODH Dashboard is the central web console for Red Hat OpenShift AI (RHOAI) and Open Data Hub (ODH) platforms. It provides data scientists and administrators with a comprehensive interface to manage data science workloads including Jupyter notebooks, model serving deployments, data science pipelines, model registries, and distributed workloads. The dashboard integrates with underlying Kubernetes resources through a Node.js backend API and presents a React-based frontend using PatternFly components. It handles user authentication via OpenShift OAuth, enforces role-based access control, and provides real-time monitoring of workload status. The dashboard serves as the primary entry point for users to explore available components, launch development environments, deploy models, and monitor AI/ML operations across the platform.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| odh-dashboard container | Node.js/Fastify Backend + React Frontend | Serves static frontend assets and provides REST API for managing ODH/RHOAI resources |
| oauth-proxy container | OpenShift OAuth Proxy | Handles authentication via OpenShift OAuth and proxies authenticated requests to backend |
| Frontend | React/TypeScript SPA | User interface built with PatternFly components for dashboard interactions |
| Backend API | Fastify REST API | Provides 39+ API endpoints for resource management and Kubernetes integration |
| Kubernetes Client | @kubernetes/client-node | Communicates with Kubernetes API server for resource operations |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| dashboard.opendatahub.io | v1 | OdhApplication | Namespaced | Defines installable applications/components displayed in the dashboard catalog |
| opendatahub.io | v1alpha | OdhDashboardConfig | Namespaced | Configures dashboard feature flags, group permissions, and UI customizations |
| dashboard.opendatahub.io | v1 | OdhDocument | Namespaced | Defines documentation links and resources displayed in dashboard |
| console.openshift.io | v1 | OdhQuickStart | Cluster | Provides guided quick-start tutorials for ODH components |
| dashboard.opendatahub.io | v1 | AcceleratorProfile | Namespaced | Defines GPU/accelerator profiles with tolerations for workload scheduling |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /api/health | GET | 8080/TCP | HTTP | None | None | Backend health check endpoint |
| /oauth/healthz | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | OAuth proxy health check |
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics (bypasses OAuth) |
| /api/config | GET, PATCH | 8080/TCP | HTTP | None | OAuth | Dashboard configuration management |
| /api/namespaces/:name/:context | GET | 8080/TCP | HTTP | None | OAuth | Namespace/project management |
| /api/notebooks | GET, POST, PATCH | 8080/TCP | HTTP | None | OAuth | Jupyter notebook lifecycle management |
| /api/k8s/* | DELETE, GET, HEAD, PATCH, POST, PUT | 8080/TCP | HTTP | None | OAuth + K8s RBAC | Kubernetes API passthrough proxy |
| /api/prometheus/query | POST | 8080/TCP | HTTP | None | OAuth | Prometheus query proxy for metrics |
| /api/prometheus/queryRange | POST | 8080/TCP | HTTP | None | OAuth | Prometheus range query for time-series data |
| /api/accelerator-profiles | GET, POST, PUT, DELETE | 8080/TCP | HTTP | None | OAuth | Accelerator profile management |
| /api/builds | GET | 8080/TCP | HTTP | None | OAuth | OpenShift build status |
| /api/cluster-settings | GET | 8080/TCP | HTTP | None | OAuth | Cluster configuration information |
| /api/components | GET | 8080/TCP | HTTP | None | OAuth | ODH component status |
| /api/connection-types | GET | 8080/TCP | HTTP | None | OAuth | Data connection type management |
| /api/console-links | GET | 8080/TCP | HTTP | None | OAuth | Console link management |
| /api/dashboardConfig | GET, PATCH | 8080/TCP | HTTP | None | OAuth + Admin | Dashboard configuration CRUD |
| /api/docs | GET | 8080/TCP | HTTP | None | OAuth | Documentation resource listing |
| /api/dsc | GET | 8080/TCP | HTTP | None | OAuth | DataScienceCluster resource access |
| /api/dsci | GET | 8080/TCP | HTTP | None | OAuth | DSCInitialization resource access |
| /api/images | GET | 8080/TCP | HTTP | None | OAuth | Notebook image management |
| /api/modelRegistries | GET, POST, PUT, DELETE | 8080/TCP | HTTP | None | OAuth | Model registry management |
| /api/quickstarts | GET | 8080/TCP | HTTP | None | OAuth | Quick-start tutorial listing |
| /api/rolebindings | GET, POST, DELETE | 8080/TCP | HTTP | None | OAuth | RBAC role binding management |
| /api/route | GET | 8080/TCP | HTTP | None | OAuth | OpenShift route information |
| /api/servingRuntimes | GET, POST, PUT, DELETE | 8080/TCP | HTTP | None | OAuth | Model serving runtime management |
| /api/status | GET | 8080/TCP | HTTP | None | OAuth | Component installation status |
| /api/storage-class | GET | 8080/TCP | HTTP | None | OAuth | StorageClass information |
| /api/templates | GET | 8080/TCP | HTTP | None | OAuth | Notebook template management |
| /api/validate-isv | POST | 8080/TCP | HTTP | None | OAuth | ISV validation |
| /api/nim-serving | GET | 8080/TCP | HTTP | None | OAuth | NVIDIA NIM model serving management |
| / | GET | 8080/TCP | HTTP | None | None | Static frontend assets (React SPA) |
| /* | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth | All routes proxied through OAuth with TLS |

### WebSocket Endpoints

| Path | Port | Protocol | Encryption | Auth | Purpose |
|------|------|----------|------------|------|---------|
| /wss/k8s/* | 8080/TCP | WebSocket | None (internal) | OAuth + K8s RBAC | Real-time Kubernetes resource event streaming |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Node.js | >=18.0.0 | Yes | Runtime for backend and build process |
| OpenShift OAuth | N/A | Yes | User authentication and authorization |
| Kubernetes API Server | 1.24+ | Yes | Resource management and RBAC enforcement |
| Prometheus/Thanos | N/A | No | Metrics collection and querying for model serving |
| OpenShift Image Registry | N/A | No | Custom notebook image management |
| OpenShift Builds | N/A | No | Custom notebook image building |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Notebook Controller | CRD (kubeflow.org/v1/Notebook) | Managing Jupyter notebook lifecycles |
| KServe | CRD (serving.kserve.io) | Monitoring and managing inference services |
| Model Registry | CRD (modelregistry.opendatahub.io) | Model registry integration |
| Data Science Cluster Operator | CRD (datasciencecluster.opendatahub.io) | Reading cluster configuration |
| Data Science Pipelines | API/K8s proxy | Pipeline management and execution |
| ODH Operator | CRD watches | Component status and configuration |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-dashboard | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ (service cert) | OAuth + K8s RBAC | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| odh-dashboard | OpenShift Route | Cluster-specific | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Resource management via client-go |
| Thanos Querier | 9092/TCP | HTTP | None | ServiceAccount Token | Prometheus metrics queries |
| OpenShift Image Registry | 5000/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Image metadata retrieval |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-dashboard | "" | nodes | get, list |
| odh-dashboard | "" | configmaps, secrets, persistentvolumeclaims | create, delete, get, list, patch, update, watch |
| odh-dashboard | "" | namespaces | create, delete, get, list, patch, update, watch |
| odh-dashboard | "" | pods, serviceaccounts, services | get, list, watch |
| odh-dashboard | "", events.k8s.io | events | get, list, watch |
| odh-dashboard | storage.k8s.io | storageclasses | update, patch |
| odh-dashboard | machine.openshift.io, autoscaling.openshift.io | machineautoscalers, machinesets | get, list |
| odh-dashboard | "", config.openshift.io | clusterversions | get, watch, list |
| odh-dashboard | operators.coreos.com | clusterserviceversions, subscriptions | get, list, watch |
| odh-dashboard | "", image.openshift.io | imagestreams/layers | get |
| odh-dashboard | route.openshift.io | routes | get, list, watch |
| odh-dashboard | console.openshift.io | consolelinks | get, list, watch |
| odh-dashboard | operator.openshift.io | consoles | get, list, watch |
| odh-dashboard | "", integreatly.org | rhmis | get, watch, list |
| odh-dashboard | user.openshift.io | groups, users | get, list, watch |
| odh-dashboard | rbac.authorization.k8s.io | rolebindings, clusterrolebindings, roles | create, delete, get, list, patch, update, watch |
| odh-dashboard | kubeflow.org | notebooks | create, delete, get, list, patch, update, watch |
| odh-dashboard | datasciencecluster.opendatahub.io | datascienceclusters | get, list, watch |
| odh-dashboard | dscinitialization.opendatahub.io | dscinitializations | get, list, watch |
| odh-dashboard | serving.kserve.io | inferenceservices | get, list, watch |
| odh-dashboard | modelregistry.opendatahub.io | modelregistries | create, delete, get, list, patch, update, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-dashboard | odh-dashboard namespace | ClusterRole/odh-dashboard | odh-dashboard |
| odh-dashboard | odh-dashboard namespace | Role/odh-dashboard | odh-dashboard |
| odh-dashboard-auth-delegator | kube-system | ClusterRole/system:auth-delegator | odh-dashboard |
| odh-dashboard-cluster-monitoring | openshift-monitoring | ClusterRole/cluster-monitoring-view | odh-dashboard |

### RBAC - Namespaced Roles

| Role Name | Namespace | API Group | Resources | Verbs |
|-----------|-----------|-----------|-----------|-------|
| odh-dashboard | odh-dashboard | dashboard.opendatahub.io | acceleratorprofiles | create, delete, get, list, patch, update |
| odh-dashboard | odh-dashboard | route.openshift.io | routes | get, list, watch |
| odh-dashboard | odh-dashboard | kfdef.apps.kubeflow.org | kfdefs | get, list, watch |
| odh-dashboard | odh-dashboard | batch | cronjobs, jobs, jobs/status | create, delete, get, list, patch, update, watch |
| odh-dashboard | odh-dashboard | image.openshift.io | imagestreams | create, delete, get, list, patch, update |
| odh-dashboard | odh-dashboard | build.openshift.io | builds, buildconfigs, buildconfigs/instantiate | create, delete, get, list, patch, watch |
| odh-dashboard | odh-dashboard | apps | deployments | patch, update |
| odh-dashboard | odh-dashboard | apps.openshift.io | deploymentconfigs, deploymentconfigs/instantiate | create, delete, get, list, patch, update, watch |
| odh-dashboard | odh-dashboard | opendatahub.io | odhdashboardconfigs | create, delete, get, list, patch, update, watch |
| odh-dashboard | odh-dashboard | kubeflow.org | notebooks | create, delete, get, list, patch, update, watch |
| odh-dashboard | odh-dashboard | dashboard.opendatahub.io | odhapplications, odhdocuments | get, list |
| odh-dashboard | odh-dashboard | console.openshift.io | odhquickstarts | get, list |
| odh-dashboard | odh-dashboard | template.openshift.io | templates | * (all) |
| odh-dashboard | odh-dashboard | serving.kserve.io | servingruntimes | * (all) |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| dashboard-proxy-tls | kubernetes.io/tls | TLS certificate for OAuth proxy | service.alpha.openshift.io/serving-cert | Yes |
| dashboard-oauth-config-generated | Opaque | OAuth cookie secret | Dashboard operator | No |
| dashboard-oauth-client-generated | Opaque | OAuth client secret | Dashboard operator | No |

### ConfigMaps

| ConfigMap Name | Purpose | Provisioned By |
|----------------|---------|----------------|
| odh-trusted-ca-bundle | Trusted CA certificates for API calls | Cluster CA injection |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None | OAuth proxy (bypassed) | Unauthenticated for Prometheus scraping |
| /api/health | GET | None | Backend | Unauthenticated health check |
| /oauth/healthz | GET | None | OAuth proxy | Unauthenticated health check |
| /api/* | ALL | OAuth Bearer Token | OAuth proxy → Backend | User must have project list permission in OpenShift |
| /api/dashboardConfig | PATCH | OAuth Bearer Token + Admin Group | Backend (secureAdminRoute) | User must be in admin groups defined in OdhDashboardConfig |
| /api/k8s/* | ALL | OAuth Bearer Token + K8s RBAC | Kubernetes API Server | Per-resource RBAC enforced by K8s |
| /wss/k8s/* | WebSocket | OAuth Bearer Token + K8s RBAC | Kubernetes API Server | Per-resource RBAC enforced by K8s |
| / (Frontend) | GET | OAuth Bearer Token | OAuth proxy | Authenticated users only |

## Data Flows

### Flow 1: User Login and Dashboard Access

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | odh-dashboard Route | 443/TCP | HTTPS | TLS 1.2+ | None (initial) |
| 2 | OpenShift Router | oauth-proxy (Pod) | 8443/TCP | HTTPS | TLS 1.2+ (service cert) | None (redirect) |
| 3 | oauth-proxy | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | Client secret |
| 4 | User Browser | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 5 | OpenShift OAuth Server | oauth-proxy | N/A | N/A | N/A | OAuth code |
| 6 | oauth-proxy | odh-dashboard (Pod) | 8080/TCP | HTTP | None (pod-local) | OAuth token (header) |
| 7 | odh-dashboard | User Browser | 8080→8443→443/TCP | HTTP→HTTPS | TLS 1.2+ (via proxy) | OAuth cookie |

### Flow 2: API Request to Kubernetes

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | odh-dashboard Route | 443/TCP | HTTPS | TLS 1.2+ | OAuth cookie |
| 2 | oauth-proxy (Pod) | odh-dashboard (Pod) | 8080/TCP | HTTP | None (pod-local) | Bearer token (header) |
| 3 | odh-dashboard | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 4 | Kubernetes API Server | odh-dashboard | 6443/TCP | HTTPS | TLS 1.2+ | Response data |
| 5 | odh-dashboard → oauth-proxy | User Browser | 8080→8443→443/TCP | HTTP→HTTPS | TLS 1.2+ | JSON response |

### Flow 3: Notebook Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser (POST /api/notebooks) | odh-dashboard Route | 443/TCP | HTTPS | TLS 1.2+ | OAuth cookie |
| 2 | oauth-proxy | odh-dashboard | 8080/TCP | HTTP | None (pod-local) | Bearer token |
| 3 | odh-dashboard | Kubernetes API (Namespace creation) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 4 | odh-dashboard | Kubernetes API (RoleBinding creation) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 5 | odh-dashboard | Kubernetes API (Notebook CR creation) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 6 | odh-dashboard | User Browser | 8080→8443→443/TCP | HTTP→HTTPS | TLS 1.2+ | Success response |

### Flow 4: Metrics Monitoring

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | odh-dashboard Service | 8443/TCP | HTTPS | TLS 1.2+ (service cert) | None (bypassed by oauth-proxy) |
| 2 | oauth-proxy | odh-dashboard (Pod) | 8080/TCP | HTTP | None (pod-local) | None (skip-auth-regex) |
| 3 | odh-dashboard | Thanos Querier | 9092/TCP | HTTP | None | ServiceAccount token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Resource CRUD operations, watches, and RBAC |
| OpenShift OAuth Server | OAuth 2.0 | 443/TCP | HTTPS | TLS 1.2+ | User authentication and token management |
| Thanos Querier | HTTP API | 9092/TCP | HTTP | None | Prometheus metrics for model serving dashboards |
| Notebook Controller | Kubernetes Watch | 6443/TCP | HTTPS | TLS 1.2+ | Notebook CR lifecycle management |
| KServe Controller | Kubernetes Watch | 6443/TCP | HTTPS | TLS 1.2+ | InferenceService status monitoring |
| Model Registry | REST API (via K8s) | 6443/TCP | HTTPS | TLS 1.2+ | Model registry CRUD operations |
| OpenShift Console | ConsoleLink CR | 6443/TCP | HTTPS | TLS 1.2+ | Dashboard links in OpenShift console |
| ODH Operator | CRD watches | 6443/TCP | HTTPS | TLS 1.2+ | Component configuration and status |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| cb94ecb33 | 2024-10-02 | - Merge v2.27.0 fixes |
| f52855403 | 2024-10-02 | - Fix NIM model name fetch from ConfigMap |
| 167dc385d | 2024-09-30 | - Version bump for Dashboard v2.27.0 |
| 330dfdfb8 | 2024-09-27 | - Fix double window and NIM modal for KServe<br>- Add NIM project link |
| 250c5555a | 2024-09-27 | - Fix pipeline creation redirect to detail page |
| 50a1054e6 | 2024-09-27 | - Add storage class support for notebook PVCs |
| a3d4b1bd1 | 2024-09-27 | - Optimize project list notebook fetch (lazy load) |
| 6565ca984 | 2024-09-27 | - Fix vLLM metrics error stack trace |
| 3783c3f66 | 2024-09-27 | - Model registry architecture review fixes |
| 73b0c4ce8 | 2024-09-27 | - NIM deployment implementation |
| f1dfe7b15 | 2024-09-27 | - Use K8sNameDescriptionField in connection types |
| 947c09b84 | 2024-09-27 | - List connected notebooks per connection |
| 296dceb31 | 2024-09-27 | - Fix label group truncation |
| 053909f9c | 2024-09-27 | - Update error message for custom notebook image import |
| a0d40fd04 | 2024-09-26 | - Update DELETE modelRegistryRoleBindings return type |
| c4ce86c3a | 2024-09-26 | - Enable model registry feature by default |
| 42c4f3d48 | 2024-09-26 | - Fix layout issues on notebook controller |
| 3ec224f63 | 2024-09-27 | - Fix event ordering in workbench status |
| 063d974d6 | 2024-09-27 | - Optimize schedule rerender performance |

## Deployment Architecture

### Container Images

| Container | Base Image | Build Method | Purpose |
|-----------|------------|--------------|---------|
| odh-dashboard | registry.access.redhat.com/ubi8/nodejs-18 | Multi-stage Dockerfile | Serves React frontend and Fastify backend |
| oauth-proxy | OpenShift OAuth Proxy | External | Handles OpenShift authentication |

### Pod Specification

| Setting | Value | Purpose |
|---------|-------|---------|
| Replicas | 2 | High availability |
| Service Account | odh-dashboard | Kubernetes API access with RBAC |
| Anti-Affinity | Preferred (zone-based) | Spread across availability zones |
| CPU Request | 500m (per container) | Resource allocation |
| CPU Limit | 1000m (per container) | Resource cap |
| Memory Request | 1Gi (per container) | Resource allocation |
| Memory Limit | 2Gi (per container) | Resource cap |
| Liveness Probe | TCP 8080 (dashboard), HTTPS 8443 (oauth) | Pod health |
| Readiness Probe | HTTP /api/health (dashboard), HTTPS /oauth/healthz (oauth) | Traffic routing |

### Volume Mounts

| Mount Path | Source | Purpose |
|------------|--------|---------|
| /etc/tls/private | Secret: dashboard-proxy-tls | OAuth proxy TLS certificate |
| /etc/oauth/config | Secret: dashboard-oauth-config-generated | OAuth cookie secret |
| /etc/oauth/client | Secret: dashboard-oauth-client-generated | OAuth client credentials |
| /etc/pki/tls/certs/odh-trusted-ca-bundle.crt | ConfigMap: odh-trusted-ca-bundle | Trusted CA certificates |
| /etc/pki/tls/certs/odh-ca-bundle.crt | ConfigMap: odh-trusted-ca-bundle | ODH CA certificates |

## Monitoring & Observability

### Health Checks

| Endpoint | Type | Protocol | Port | Purpose |
|----------|------|----------|------|---------|
| /api/health | HTTP | HTTP | 8080/TCP | Backend readiness check |
| TCP :8080 | TCP Socket | TCP | 8080/TCP | Backend liveness check |
| /oauth/healthz | HTTPS | HTTPS | 8443/TCP | OAuth proxy health check |

### Metrics

| Endpoint | Format | Auth | Purpose |
|----------|--------|------|---------|
| /metrics | Prometheus | None (skipped by oauth-proxy) | Application and Node.js runtime metrics |

### Logging

| Component | Level | Format | Output |
|-----------|-------|--------|--------|
| Backend | Configurable (LOG_LEVEL env) | Pino JSON (production), Pino Pretty (dev) | stdout |
| Admin Activity | INFO | Custom log file | /usr/src/app/logs/adminActivity.log |
